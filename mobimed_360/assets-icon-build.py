from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parent
(root/'assets').mkdir(exist_ok=True)
(root/'assets'/'app-icon.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><rect width="1024" height="1024" fill="#087F75"/><circle cx="512" cy="512" r="315" fill="none" stroke="#BCE9DE" stroke-width="38"/><path d="M430 305h164v125h125v164H594v125H430V594H305V430h125z" fill="white"/></svg>')
def icon(size,path):
    image=Image.new('RGB',(1024,1024),'#087F75'); d=ImageDraw.Draw(image)
    d.ellipse((197,197,827,827),outline='#BCE9DE',width=38)
    d.polygon([(430,305),(594,305),(594,430),(719,430),(719,594),(594,594),(594,719),(430,719),(430,594),(305,594),(305,430),(430,430)],fill='white')
    image.resize((size,size),Image.Resampling.LANCZOS).save(path)
for directory,size in [('mipmap-mdpi',48),('mipmap-hdpi',72),('mipmap-xhdpi',96),('mipmap-xxhdpi',144),('mipmap-xxxhdpi',192)]:
    icon(size,root/'android'/'app'/'src'/'main'/'res'/directory/'ic_launcher.png')
for path in (root/'ios'/'Runner'/'Assets.xcassets'/'AppIcon.appiconset').glob('*.png'):
    with Image.open(path) as old: size=old.width
    icon(size,path)
for path in (root/'web'/'icons').glob('*.png'):
    with Image.open(path) as old: size=old.width
    icon(size,path)
icon(32,root/'web'/'favicon.png')
print('Medical app icon generated for Android, iOS and web from editable SVG source.')

