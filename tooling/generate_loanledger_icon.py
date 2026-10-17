from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SIZE = 1024
BG = (8, 27, 99, 255)
WHITE = (255, 255, 255, 255)
GREEN1 = (21, 231, 178, 255)
GREEN2 = (119, 245, 177, 255)
BLUE1 = (41, 136, 255, 255)
BLUE2 = (77, 210, 255, 255)
DARK_BLUE = (15, 45, 122, 255)
LIGHT_BLUE = (89, 132, 201, 255)
ROOT = Path('/Users/sundarrajan/StudioProjects/LoanLedger')
OUT_APP = ROOT / 'assets' / 'app_icon.png'
OUT_PLAY = ROOT / 'assets' / 'playstore-icon.png'


def gradient(size, c1, c2, horizontal=False):
    img = Image.new('RGBA', size)
    px = img.load()
    w, h = size
    for y in range(h):
        for x in range(w):
            t = (x / max(1, w - 1)) if horizontal else (y / max(1, h - 1))
            px[x, y] = tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))
    return img


def paste_masked(target, img, mask, xy=(0, 0)):
    target.paste(img, xy, mask)


def draw_grad_circle(target, box, c1, c2):
    x0, y0, x1, y1 = box
    mask = Image.new('L', (x1 - x0, y1 - y0), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, x1 - x0 - 1, y1 - y0 - 1), fill=255)
    paste_masked(target, gradient((x1 - x0, y1 - y0), c1, c2), mask, (x0, y0))


def draw_grad_roundrect(target, box, radius, c1, c2):
    x0, y0, x1, y1 = box
    mask = Image.new('L', (x1 - x0, y1 - y0), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, x1 - x0 - 1, y1 - y0 - 1), radius=radius, fill=255)
    paste_masked(target, gradient((x1 - x0, y1 - y0), c1, c2), mask, (x0, y0))


def load_font(size):
    font_paths = [
        '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
        '/System/Library/Fonts/Supplemental/Helvetica.ttc',
        '/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf',
    ]
    for fp in font_paths:
        try:
            return ImageFont.truetype(fp, size)
        except Exception:
            continue
    return ImageFont.load_default()


def main():
    base = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))

    shadow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((70, 70, 954, 954), radius=150, fill=(0, 0, 0, 82))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    base.alpha_composite(shadow, (0, 8))

    card = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle((58, 58, 966, 966), radius=150, fill=BG)
    for i in range(220):
        alpha = max(0, 18 - i // 16)
        cd.ellipse((260 - i, 120 - i, 820 + i, 720 + i), outline=(40, 90, 180, alpha), width=2)
    base.alpha_composite(card)

    for left, ctop, cbot, body in [
        (245, BLUE2, BLUE1, (220, 420, 350, 535)),
        (675, GREEN2, GREEN1, (650, 420, 780, 535)),
    ]:
        draw_grad_circle(base, (left, 330, left + 95, 425), ctop, cbot)
        draw_grad_roundrect(base, body, 30, ctop, cbot)

    layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle((365, 245, 655, 580), radius=34, fill=(0, 0, 0, 80))
    layer = layer.filter(ImageFilter.GaussianBlur(18))
    base.alpha_composite(layer, (8, 10))

    d = ImageDraw.Draw(base)
    d.rounded_rectangle((350, 235, 630, 565), radius=34, fill=WHITE)
    d.polygon([(590, 235), (630, 270), (630, 565), (590, 530)], fill=(246, 248, 255, 255))
    for y in (285, 322, 359):
        d.rounded_rectangle((400, y, 550, y + 18), radius=9, fill=LIGHT_BLUE)
    cx, cy, cr = 490, 445, 82
    d.ellipse((cx - cr, cy - cr, cx + cr, cy + cr), fill=DARK_BLUE)

    dollar_font = load_font(120)
    bbox = d.textbbox((0, 0), '$', font=dollar_font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text((cx - tw / 2, cy - th / 2 - 8), '$', font=dollar_font, fill=WHITE)

    d.arc((275, 130, 700, 390), start=205, end=345, fill=GREEN1, width=26)
    head_mask = Image.new('L', (SIZE, SIZE), 0)
    ImageDraw.Draw(head_mask).polygon([(622, 128), (672, 274), (545, 250)], fill=255)
    paste_masked(base, gradient((SIZE, SIZE), GREEN2, GREEN1, horizontal=True), head_mask)

    d.arc((280, 430, 720, 715), start=18, end=165, fill=BLUE1, width=30)
    head2_mask = Image.new('L', (SIZE, SIZE), 0)
    ImageDraw.Draw(head2_mask).polygon([(325, 535), (470, 555), (360, 650)], fill=255)
    paste_masked(base, gradient((SIZE, SIZE), BLUE2, BLUE1, horizontal=False), head2_mask)

    brand_font = load_font(106)
    text_y = 708
    loan_bbox = d.textbbox((0, 0), 'Loan', font=brand_font)
    ledger_bbox = d.textbbox((0, 0), 'Ledger', font=brand_font)
    loan_w = loan_bbox[2] - loan_bbox[0]
    ledger_w = ledger_bbox[2] - ledger_bbox[0]
    start_x = 150

    d.text((start_x, text_y), 'Loan', font=brand_font, fill=WHITE)
    mask = Image.new('L', (ledger_w, ledger_bbox[3] - ledger_bbox[1] + 20), 0)
    ImageDraw.Draw(mask).text((0, 0), 'Ledger', font=brand_font, fill=255)
    paste_masked(base, gradient(mask.size, GREEN2, GREEN1, horizontal=True), mask, (start_x + loan_w - 6, text_y))

    OUT_APP.parent.mkdir(parents=True, exist_ok=True)
    base.save(OUT_APP)
    base.save(OUT_PLAY)
    print(f'Saved {OUT_APP}')
    print(f'Saved {OUT_PLAY}')


if __name__ == '__main__':
    main()

