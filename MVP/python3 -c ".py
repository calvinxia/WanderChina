
from PIL import Image
img = Image.open('ios/Runner/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png')
if img.mode == 'RGBA':
    bg = Image.new('RGB', img.size, (26, 26, 30))  # ink900 背景色
    bg.paste(img, mask=img.split()[3])
    bg.save('ios/Runner/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png')
    print('Fixed: removed alpha channel')
else:
    print('Already RGB, no fix needed')
