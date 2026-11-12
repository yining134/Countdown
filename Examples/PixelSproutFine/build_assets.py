from PIL import Image
from pathlib import Path
import json, zipfile
root = Path(__file__).resolve().parents[2]
source = Image.open(root/'Examples/PixelSproutFine/animation-source.png').convert('RGBA')
sheet = Image.new('RGBA', (512, 512))
# Normalize the generated grid into equal cells with transparent margins.
for row in range(4):
    for col in range(4):
        frame = source.crop((round(col*source.width/4),round(row*source.height/4),round((col+1)*source.width/4),round((row+1)*source.height/4)))
        frame = frame.resize((48,48), Image.Resampling.NEAREST)
        pixels = []
        palette = [(117,74,39),(54,107,48),(142,193,77),(238,127,174),(255,224,77)]
        for r,g,b,a in frame.get_flattened_data():
            if a < 220:
                pixels.append((0,0,0,0))
            else:
                color = min(palette,key=lambda p: (r-p[0])**2+(g-p[1])**2+(b-p[2])**2)
                pixels.append((*color,255))
        frame.putdata(pixels)
        frame = frame.resize((108,108),Image.Resampling.NEAREST)
        sheet.alpha_composite(frame,(col*128+10,row*128+6))
manifest = json.loads((root/'Sources/Countdown/Resources/StarterSkin/skin.json').read_text())
manifest['animations'] = {name: {'startFrame':i*4,'frameCount':4,'fps':6 if i==3 else 4} for i,name in enumerate(['seed','sprout','bud','celebrate'])}
manifest['stages'] = [{'from':0,'animation':'seed'},{'from':0.33,'animation':'sprout'},{'from':0.67,'animation':'bud'}]
for directory in [root/'Sources/Countdown/Resources/StarterSkin', root/'Examples/StarterSkin']:
    sheet.save(directory/'spritesheet.png')
    (directory/'skin.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
with zipfile.ZipFile(root/'Examples/StarterSkin.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for name in ['skin.json','spritesheet.png']:
        archive.write(root/'Examples/StarterSkin'/name,name)
frames = []
for col in range(4):
    frame = Image.new('RGBA',(512,128))
    for row in range(4):
        frame.alpha_composite(sheet.crop((col*128,row*128,(col+1)*128,(row+1)*128)),(row*128,0))
    frames.append(frame)
frames[0].save(root/'Examples/PixelSproutFine/animation-preview.gif',save_all=True,append_images=frames[1:],duration=250,loop=0,disposal=2)
assert sheet.size == (512,512) and sheet.mode == 'RGBA'
for row in range(4):
    hashes = {sheet.crop((col*128,row*128,(col+1)*128,(row+1)*128)).tobytes() for col in range(4)}
    assert len(hashes)>1, f'static row {row}'
with zipfile.ZipFile(root/'Examples/StarterSkin.zip') as archive:
    assert sorted(archive.namelist()) == ['skin.json','spritesheet.png']
print('Validated: 512x512 RGBA, 16 frames, four animated rows, valid ZIP entries')
