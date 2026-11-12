from pathlib import Path
import json
import zipfile
from PIL import Image

root = Path(__file__).resolve().parent
output = root / 'BlackCat'
output.mkdir(exist_ok=True)
source = Image.open(root / 'animation-source.png').convert('RGBA')
sheet = Image.new('RGBA', (512, 512))
frames = []
for row in range(4):
    row_frames = []
    for column in range(4):
        box = tuple(round(value) for value in (
            column * source.width / 4, row * source.height / 4,
            (column + 1) * source.width / 4, (row + 1) * source.height / 4))
        sprite = source.crop(box).resize((56, 56), Image.Resampling.NEAREST)
        sprite.putalpha(sprite.getchannel('A').point(lambda a: 255 if a >= 200 else 0))
        sprite = sprite.resize((112, 112), Image.Resampling.NEAREST)
        frame = Image.new('RGBA', (128, 128))
        frame.alpha_composite(sprite, (8, 8))
        sheet.alpha_composite(frame, (column * 128, row * 128))
        row_frames.append(frame)
    assert len({f.tobytes() for f in row_frames}) == 4
    frames.append(row_frames)
sheet.save(output / 'spritesheet.png')
manifest = {
    'schemaVersion': 1,
    'id': 'countdown.black-cat',
    'name': 'Pixel Black Cat',
    'author': 'Countdown',
    'spritesheet': 'spritesheet.png',
    'frameSize': {'width': 128, 'height': 128},
    'animations': {
        name: {'startFrame': row * 4, 'frameCount': 4, 'fps': fps}
        for row, (name, fps) in enumerate([
            ('ready', 3), ('work', 5), ('stretch', 4), ('play', 6)])
    },
    'idle': 'ready',
    'stages': [
        {'from': 0, 'animation': 'ready'},
        {'from': 0.33, 'animation': 'work'},
        {'from': 0.67, 'animation': 'stretch'}
    ],
    'completed': 'play'
}
(output / 'skin.json').write_text(json.dumps(manifest, indent=2) + '\n')
with zipfile.ZipFile(root / 'BlackCat.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for name in ['skin.json', 'spritesheet.png']:
        archive.write(output / name, name)
preview_frames = []
for index in range(24):
    preview = Image.new('RGB', (512, 128), '#e8eaf0')
    for row, fps in enumerate([3, 5, 4, 6]):
        frame = frames[row][int(index * fps / 6) % 4]
        preview.paste(frame, (row * 128, 0), frame)
    preview_frames.append(preview)
preview_frames[0].save(root / 'animation-preview.gif', save_all=True,
                      append_images=preview_frames[1:], duration=166, loop=0)
preview_frames[0].save(root / 'preview.png')
assert sheet.mode == 'RGBA' and sheet.size == (512, 512)
assert set(sheet.getchannel('A').get_flattened_data()) == {0, 255}
with zipfile.ZipFile(root / 'BlackCat.zip') as archive:
    assert sorted(archive.namelist()) == ['skin.json', 'spritesheet.png']
    assert archive.testzip() is None
print('Validated 512x512 RGBA, 16 distinct frames, transparent margins, and ZIP structure')
