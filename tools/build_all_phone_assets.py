"""Build all phone TXD + DFF files for SA-MP 0.3.DL."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image
from png_to_txd import build_txd, check_has_alpha
from build_flat_dff import build_flat_dff

ROOT = os.path.join(os.path.dirname(__file__), '..')
MODELS = os.path.join(ROOT, 'models')

assets = [
    # (png_path, texture_name, resize_to)
    ('phone-frame.png', 'phoneframe', (128, 256)),
    ('wallpaper.png',   'phonewp',    (128, 128)),
    ('whatsapp.png',    'iconwa',     (64, 64)),
    ('twitter.png',     'icontw',     (64, 64)),
]

for png_name, tex_name, size in assets:
    png_path = os.path.join(ROOT, png_name)
    if not os.path.exists(png_path):
        print(f'SKIP: {png_path} not found')
        continue

    img = Image.open(png_path).convert('RGBA')
    if img.size != size:
        img = img.resize(size, Image.LANCZOS)
    print(f'{tex_name}: {img.size}, alpha={check_has_alpha(img)}')

    # TXD
    txd_data = build_txd([(img, tex_name)])
    txd_path = os.path.join(MODELS, f'{tex_name}.txd')
    with open(txd_path, 'wb') as f:
        f.write(txd_data)
    print(f'  -> {txd_path} ({os.path.getsize(txd_path):,} bytes)')

    # DFF
    dff_data = build_flat_dff(tex_name)
    dff_path = os.path.join(MODELS, f'{tex_name}.dff')
    with open(dff_path, 'wb') as f:
        f.write(dff_data)
    print(f'  -> {dff_path} ({os.path.getsize(dff_path):,} bytes)')

print('\nAll done!')
