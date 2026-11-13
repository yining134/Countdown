from pathlib import Path
import json
import zipfile
from PIL import Image

root = Path(__file__).resolve().parents[2]
source = Image.open(root / 'Design/Skins/PixelChick/animation-source.png').convert('RGBA')
output = root / 'Examples/Skins/PixelChick'
output.mkdir(parents=True, exist_ok=True)
sequence = [0, 1, 2, 1, 0, 0]
sheet = Image.new('RGBA', (768, 512))
rows = []
for row in range(4):
    originals = []
    for col in range(3):
        cell = source.crop((round(col * source.width / 4), round(row * source.height / 4),
                            round((col + 1) * source.width / 4), round((row + 1) * source.height / 4)))
        cell = cell.resize((128, 128), Image.Resampling.NEAREST)
        cell.putdata([(r, g, b, 255) if a >= 220 else (0, 0, 0, 0)
                      for r, g, b, a in cell.get_flattened_data()])
        originals.append(cell)
    frames = [originals[index] for index in sequence]
    rows.append(frames)
    for col, frame in enumerate(frames):
        sheet.alpha_composite(frame, (col * 128, row * 128))
    assert frames[0].tobytes() == frames[-1].tobytes()
    assert len({frame.tobytes() for frame in frames}) > 1
sheet.save(output / 'spritesheet.png')
names = ['egg', 'cracked', 'peek', 'celebrate']
manifest = {
    'schemaVersion': 1, 'id': 'countdown.pixel-chick', 'name': 'Pixel Chick', 'author': 'Countdown',
    'spritesheet': 'spritesheet.png', 'frameSize': {'width': 128, 'height': 128},
    'animations': {name: {'startFrame': index * 6, 'frameCount': 6, 'fps': 5}
                   for index, name in enumerate(names)},
    'idle': names[0],
    'stages': [{'from': threshold, 'animation': name}
               for threshold, name in zip([0, 0.33, 0.67], names)],
    'completed': names[-1],
}
(output / 'skin.json').write_text(json.dumps(manifest, indent=2) + '\n')
with zipfile.ZipFile(output / 'PixelChick.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for name in ['skin.json', 'spritesheet.png']:
        archive.write(output / name, name)
previews = []
for col in range(6):
    preview = Image.new('RGBA', (512, 128), '#f4f0e8')
    for row in range(4):
        preview.alpha_composite(rows[row][col], (row * 128, 0))
    previews.append(preview.resize((1024, 256), Image.Resampling.NEAREST).convert('RGB'))
previews[0].save(output / 'animation-preview.gif', save_all=True, append_images=previews[1:],
                 duration=200, loop=0, disposal=2)
previews[0].save(output / 'preview.png')
assert sheet.size == (768, 512) and sheet.getextrema()[3] == (0, 255)
with zipfile.ZipFile(output / 'PixelChick.zip') as archive:
    assert sorted(archive.namelist()) == ['skin.json', 'spritesheet.png']
    assert archive.testzip() is None
print('Validated: 24 RGBA frames, four closed loops, 128x128 frames, valid import ZIP')
