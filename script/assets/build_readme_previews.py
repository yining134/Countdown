from pathlib import Path
import json
from PIL import Image

root = Path(__file__).resolve().parents[2]
output = root / 'docs/images/themes'
output.mkdir(parents=True, exist_ok=True)
for directory, filename in [
    ('PixelSprout', 'sprout.gif'),
    ('PixelChick', 'chick.gif'),
    ('SteamJourney', 'train.gif'),
    ('BlackCat', 'cat.gif'),
]:
    source = root / 'Examples/Skins' / directory
    manifest = json.loads((source / 'skin.json').read_text())
    sheet = Image.open(source / manifest['spritesheet']).convert('RGBA')
    width, height = manifest['frameSize']['width'], manifest['frameSize']['height']
    columns = sheet.width // width
    frames, durations = [], []
    sequence = [stage['animation'] for stage in manifest['stages']] + [manifest['completed']]
    for name in sequence:
        animation = manifest['animations'][name]
        for index in range(animation['startFrame'], animation['startFrame'] + animation['frameCount']):
            x, y = index % columns * width, index // columns * height
            sprite = sheet.crop((x, y, x + width, y + height))
            canvas = Image.new('RGBA', (128, 128), '#f3f1eb')
            sprite.thumbnail((128, 128), Image.Resampling.NEAREST)
            canvas.alpha_composite(sprite, ((128 - sprite.width) // 2, (128 - sprite.height) // 2))
            frames.append(canvas.resize((256, 256), Image.Resampling.NEAREST).convert('RGB'))
            durations.append(max(10, round(100 / animation['fps']) * 10))
    frames[0].save(output / filename, save_all=True, append_images=frames[1:],
                   duration=durations, loop=0, disposal=2)
    with Image.open(output / filename) as result:
        assert result.size == (256, 256)
    print(f'{filename}: {len(frames)} source frames, sequential stages, 256x256')
