from pathlib import Path
import json
import zipfile
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[2]
source = Image.open(root / 'Design/Skins/SteamJourney/layers-source.png').convert('RGBA')
output = root / 'Examples/Skins/SteamJourney'
output.mkdir(parents=True, exist_ok=True)

def layer(top, bottom, size):
    image = source.crop((0, top, source.width, bottom))
    image.putdata([(r, g, b, 255) if a >= 220 else (0, 0, 0, 0)
                   for r, g, b, a in image.get_flattened_data()])
    bounds = image.getbbox()
    assert bounds
    return image.crop(bounds).resize(size, Image.Resampling.NEAREST)

train = Image.open(root / 'Design/Skins/SteamJourney/passenger-train-source.png').convert('RGBA')
train.putdata([(r, g, b, 255) if a >= 220 else (0, 0, 0, 0)
               for r, g, b, a in train.get_flattened_data()])
train = train.crop(train.getbbox()).resize((112, 28), Image.Resampling.NEAREST)
scenery = [layer(top, bottom, (192, 52)) for top, bottom in
           [(320, 556), (556, 790), (790, 1018), (1018, 1250)]]
station = layer(1250, 1536, (94, 62))

def render(stage, index):
    frame = Image.new('RGBA', (128, 128))
    if stage < 4:
        strip = scenery[stage]
        offset = (index * 8) % strip.width
        for x in [-offset, strip.width - offset]:
            frame.alpha_composite(strip, (x, 56))
    else:
        frame.alpha_composite(station, (17, 46))
    draw = ImageDraw.Draw(frame)
    draw.line((0, 114, 127, 114), fill='#604737', width=2)
    shift = (index * 8) % 16 if stage < 4 else 0
    for x in range(-16 + shift, 128, 16):
        draw.rectangle((x, 116, x + 7, 117), fill='#76513a')
    frame.alpha_composite(train, (8, 86))
    # 画面边缘透明渐隐。
    pixels = frame.load()
    for x in range(128):
        opacity = min(1, x / 6, (127 - x) / 6)
        for y in range(128):
            r, g, b, a = pixels[x, y]
            pixels[x, y] = (r, g, b, round(a * opacity))
    return frame

rows = [[render(stage, index) for index in range(24)] for stage in range(5)]
sheet = Image.new('RGBA', (3072, 640))
for stage, frames in enumerate(rows):
    assert render(stage, 24).tobytes() == frames[0].tobytes()
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * 128, stage * 128))
        assert frame.getpixel((0, 0))[3] == 0
    changes = [sum(a != b for a, b in zip(frames[index].tobytes(), frames[(index + 1) % 24].tobytes()))
               for index in range(24)]
    assert changes[-1] <= max(changes[:-1]) * 1.5
sheet.save(output / 'spritesheet.png')
names = ['spring', 'summer', 'autumn', 'winter', 'arrival']
manifest = {
    'schemaVersion': 1, 'id': 'countdown.steam-journey', 'name': 'Seasonal Train', 'author': 'Countdown',
    'spritesheet': 'spritesheet.png', 'frameSize': {'width': 128, 'height': 128},
    'animations': {name: {'startFrame': stage * 24, 'frameCount': 24, 'fps': 12}
                   for stage, name in enumerate(names)},
    'idle': 'spring', 'stages': [{'from': stage / 4, 'animation': name}
                                for stage, name in enumerate(names[:4])], 'completed': 'arrival',
}
(output / 'skin.json').write_text(json.dumps(manifest, indent=2) + '\n')
with zipfile.ZipFile(output / 'SteamJourney.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for name in ['skin.json', 'spritesheet.png']:
        archive.write(output / name, name)
previews = []
for index in range(24):
    preview = Image.new('RGBA', (640, 128), '#e9e6df')
    for stage in range(5):
        preview.alpha_composite(rows[stage][index], (stage * 128, 0))
    previews.append(preview.resize((1280, 256), Image.Resampling.NEAREST).convert('RGB'))
previews[0].save(output / 'animation-preview.gif', save_all=True, append_images=previews[1:],
                 duration=[80, 80, 90] * 8, loop=0, disposal=2)
previews[0].save(output / 'preview.png')
assert sheet.size == (3072, 640) and sheet.mode == 'RGBA'
with zipfile.ZipFile(output / 'SteamJourney.zip') as archive:
    assert sorted(archive.namelist()) == ['skin.json', 'spritesheet.png']
    assert archive.testzip() is None
print('Validated: 120 RGBA frames; five periodic loops, continuous wrap, valid ZIP')
