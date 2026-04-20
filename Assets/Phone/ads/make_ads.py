#!/usr/bin/env python3
"""Generate varied 90s scam popup ad PNGs."""

from PIL import Image, ImageDraw, ImageFont
import os, math

W, H = 560, 387
TITLEBAR_H = 28
OUT = os.path.dirname(os.path.abspath(__file__))


def font(size, bold=False):
    candidates = [
        f"/usr/share/fonts/truetype/dejavu/DejaVuSans{'-Bold' if bold else ''}.ttf",
        f"/usr/share/fonts/TTF/DejaVuSans{'-Bold' if bold else ''}.ttf",
        f"/usr/share/fonts/truetype/liberation/LiberationSans-{('Bold' if bold else 'Regular')}.ttf",
    ]
    for p in candidates:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def text_w(draw, text, fnt):
    bb = draw.textbbox((0, 0), text, font=fnt)
    return bb[2] - bb[0], bb[3] - bb[1]


def big_click_here(draw, y, bg, fg=(255,255,255), label="CLICK HERE"):
    """Draw a giant CLICK HERE button filling the width."""
    pad = 8
    fnt = font(44, bold=True)
    tw, th = text_w(draw, label, fnt)
    bx1, bx2 = 10, W - 10
    by1, by2 = y, y + th + pad * 2
    draw.rectangle([bx1, by1, bx2, by2], fill=bg)
    # simple bevel
    draw.line([(bx1, by1),(bx2, by1)], fill=(255,255,255), width=2)
    draw.line([(bx1, by1),(bx1, by2)], fill=(255,255,255), width=2)
    draw.line([(bx2, by1),(bx2, by2)], fill=(60,60,60),   width=2)
    draw.line([(bx1, by2),(bx2, by2)], fill=(60,60,60),   width=2)
    tx = bx1 + ((bx2 - bx1) - tw) // 2
    draw.text((tx, by1 + pad), label, font=fnt, fill=fg)
    return by2


def cx(draw, text, y, fnt, color, img_w=W, underline=False):
    tw, th = text_w(draw, text, fnt)
    x = (img_w - tw) // 2
    draw.text((x, y), text, font=fnt, fill=color)
    if underline:
        draw.line([(x, y + th + 1), (x + tw, y + th + 1)], fill=color, width=2)
    return th


def draw_titlebar(draw, title, title_bg=(0, 0, 128), close_style="normal"):
    # Bar background
    draw.rectangle([2, 2, W - 3, TITLEBAR_H], fill=title_bg)
    # Icon
    draw.rectangle([4, 5, 20, 21], fill=(255, 200, 0))
    draw.text((6, 5), "★", font=font(11, bold=True), fill=(0, 0, 0))
    # Title
    draw.text((25, 6), title, font=font(13, bold=True), fill=(255, 255, 255))

    # Close button — always prominent
    bx = W - 26
    if close_style == "red":
        draw.rectangle([bx, 4, bx + 20, 24], fill=(200, 0, 0))
        draw.rectangle([bx, 4, bx + 20, 24], outline=(255, 100, 100), width=1)
        draw.text((bx + 4, 5), "×", font=font(16, bold=True), fill=(255, 255, 255))
    elif close_style == "fat":
        draw.rectangle([bx - 2, 3, bx + 22, 25], fill=(192, 192, 192))
        draw.rectangle([bx - 2, 3, bx + 22, 25], outline=(255, 255, 255), width=1)
        draw.text((bx, 3), "X", font=font(18, bold=True), fill=(0, 0, 0))
    else:
        draw.rectangle([bx, 4, bx + 20, 24], fill=(192, 192, 192))
        draw.rectangle([bx, 4, bx + 20, 24], outline=(255, 255, 255), width=1)
        draw.text((bx + 4, 5), "×", font=font(14, bold=True), fill=(0, 0, 0))
    # Min/max
    for i, g in enumerate(["_", "□"]):
        bxi = bx - (i + 1) * 23
        draw.rectangle([bxi, 4, bxi + 19, 24], fill=(192, 192, 192), outline=(255,255,255), width=1)
        draw.text((bxi + 4, 5), g, font=font(12), fill=(0, 0, 0))


def win98_border(draw):
    draw.rectangle([0, 0, W-1, H-1], outline=(255,255,255), width=3)
    draw.rectangle([3, 3, W-4, H-4], outline=(64, 64, 64), width=1)


# ── AD 1: virus — giant urgent text, progress bar ─────────────────────
def ad_virus():
    img = Image.new("RGB", (W, H), (0, 0, 160))
    d = ImageDraw.Draw(img)
    ct = TITLEBAR_H + 2
    d.rectangle([2, ct, W-3, H-3], fill=(0, 0, 160))
    # Flashing border stripes
    for i in range(0, W, 20):
        d.rectangle([i, ct, i+10, ct+6], fill=(255, 255, 0))
    d.text((10, ct + 14), "⚠ WARNING ⚠", font=font(28, bold=True), fill=(255, 60, 0))
    d.text((10, ct + 52), "YOUR COMPUTER HAS", font=font(24, bold=True), fill=(255,255,255))
    d.text((10, ct + 84), "48 VIRUSES!!!", font=font(42, bold=True), fill=(255, 60, 0))
    # Progress bar
    d.rectangle([20, ct+140, W-20, ct+165], fill=(0,0,80), outline=(255,255,0), width=2)
    d.rectangle([20, ct+140, 20 + int((W-40)*0.97), ct+165], fill=(255,0,0))
    d.text((W//2 - 60, ct+142), "SCANNING... 97%", font=font(14, bold=True), fill=(255,255,0))
    d.text((50, ct+178), "DO NOT TURN OFF YOUR PC", font=font(16, bold=True), fill=(200,200,255))
    big_click_here(d, ct+210, (255,0,0), label="CLICK HERE TO FIX NOW")
    win98_border(d)
    draw_titlebar(d, "CRITICAL SYSTEM ALERT!!!", title_bg=(180,0,0), close_style="red")
    img.save(os.path.join(OUT, "ad_virus.png"))


# ── AD 2: winner — huge number, confetti dots ──────────────────────────
def ad_winner():
    img = Image.new("RGB", (W, H), (180, 0, 0))
    d = ImageDraw.Draw(img)
    ct = TITLEBAR_H + 2
    # Confetti dots
    import random; random.seed(42)
    for _ in range(80):
        cx2 = random.randint(2, W-4)
        cy2 = random.randint(ct, H-4)
        col = random.choice([(255,255,0),(0,255,0),(255,165,0),(0,200,255),(255,255,255)])
        d.ellipse([cx2-4, cy2-4, cx2+4, cy2+4], fill=col)
    cx(d, "🎉 YOU WON! 🎉", ct+12, font(26, bold=True), (255,255,0))
    cx(d, "1,000,000th", ct+55, font(52, bold=True), (255,255,255))
    cx(d, "VISITOR PRIZE!!!", ct+115, font(34, bold=True), (255,255,0))
    cx(d, "REAL CASH • NEW CAR • VACATION", ct+162, font(15, bold=True), (255,255,255))
    cx(d, "Offer expires in: 00:02:47", ct+186, font(13), (255,200,100))
    big_click_here(d, ct+212, (255,180,0), fg=(0,0,0), label="CLICK HERE TO CLAIM")
    win98_border(d)
    draw_titlebar(d, "CONGRATULATIONS WINNER!!!", title_bg=(0,120,0), close_style="fat")
    img.save(os.path.join(OUT, "ad_winner.png"))


# ── AD 3: IQ — left-aligned, small cramped text, fake form ────────────
def ad_iq():
    img = Image.new("RGB", (W, H), (0, 80, 0))
    d = ImageDraw.Draw(img)
    ct = TITLEBAR_H + 2
    d.rectangle([2, ct, W-3, H-3], fill=(0, 80, 0))
    d.text((20, ct+10), "FREE IQ TEST — RESULTS:", font=font(20, bold=True), fill=(255,255,0))
    d.line([(20, ct+36), (W-20, ct+36)], fill=(255,255,0), width=2)
    # Fake results table
    rows = [
        ("Memory Score:",     "99th percentile"),
        ("Logic Score:",      "98th percentile"),
        ("YOUR IQ:",          "147  ← TOP 0.1%"),
        ("Status:",           "GENIUS CONFIRMED"),
    ]
    y = ct + 46
    for label, val in rows:
        d.text((25, y), label, font=font(16, bold=True), fill=(180,255,180))
        d.text((230, y), val, font=font(16, bold=True), fill=(255,255,0))
        y += 28
    d.line([(20, y+4), (W-20, y+4)], fill=(255,255,0), width=1)
    big_click_here(d, y+10, (255,180,0), fg=(0,0,0), label="CLICK HERE TO SHARE")
    d.text((20, H-22), "*Results may not reflect actual intelligence.", font=font(11), fill=(100,200,100))
    win98_border(d)
    draw_titlebar(d, "Your IQ Results Are Ready!", title_bg=(0,100,0), close_style="normal")
    img.save(os.path.join(OUT, "ad_iq.png"))


# ── AD 4: dating — pink, big heart, mixed sizing ──────────────────────
def ad_dating():
    img = Image.new("RGB", (W, H), (140, 0, 80))
    d = ImageDraw.Draw(img)
    ct = TITLEBAR_H + 2
    # Heart shapes (two circles + rotated square)
    hx, hy, hr = W//2, ct+70, 45
    d.ellipse([hx-hr-20, hy-hr, hx-20, hy+hr], fill=(255, 50, 100))
    d.ellipse([hx-hr+20, hy-hr, hx+20+hr, hy+hr], fill=(255, 50, 100))
    d.polygon([(hx-hr-20, hy+10),(hx,hy+hr*2),(hx+hr+20,hy+10)], fill=(255,50,100))
    cx(d, "❤", ct+30, font(64, bold=True), (255, 80, 120))
    cx(d, "HOT SINGLES", ct+125, font(36, bold=True), (255,255,255))
    cx(d, "in your area want to", ct+170, font(18), (255,200,220))
    cx(d, "MEET YOU TONIGHT", ct+198, font(30, bold=True), (255,255,0))
    cx(d, "no sign-up  •  no credit card  •  FREE", ct+238, font(14, bold=True), (255,200,200))
    big_click_here(d, ct+270, (255,40,100), label="CLICK HERE NOW")
    win98_border(d)
    draw_titlebar(d, "You Have (3) New Messages!", title_bg=(160, 0, 80), close_style="red")
    img.save(os.path.join(OUT, "ad_dating.png"))


# ── AD 5: weight — newspaper-style, mixed fonts ───────────────────────
def ad_weight():
    img = Image.new("RGB", (W, H), (255, 255, 255))
    d = ImageDraw.Draw(img)
    ct = TITLEBAR_H + 2
    d.rectangle([2, ct, W-3, H-3], fill=(255,255,235))
    # Newspaper header bar
    d.rectangle([2, ct, W-3, ct+30], fill=(0,0,0))
    cx(d, "★ HEALTH BREAKING NEWS ★", ct+5, font(16, bold=True), (255,255,0))
    # Headline
    cx(d, "LOCAL MAN LOSES 47 LBS", ct+40, font(30, bold=True), (180,0,0))
    cx(d, "IN JUST 3 DAYS", ct+78, font(30, bold=True), (180,0,0))
    d.line([(30, ct+116),(W-30,ct+116)], fill=(0,0,0), width=2)
    cx(d, "Using ONE WEIRD TRICK", ct+124, font(20, bold=True), (0,0,0))
    cx(d, '"Doctors are FURIOUS"', ct+152, font(17), (100,0,0))
    cx(d, "They dont want you to know this secret", ct+180, font(14), (0,0,0))
    # Price slash
    d.text((100, ct+208), "$299", font=font(28, bold=True), fill=(150,150,150))
    bb = d.textbbox((100,ct+208), "$299", font=font(28,bold=True))
    d.line([(bb[0]-2,bb[1]+12),(bb[2]+2,bb[3]-8)], fill=(255,0,0), width=3)
    d.text((220, ct+208), "FREE TODAY ONLY!!!", font=font(28, bold=True), fill=(255,0,0))
    d.rectangle([2, ct+248, W-3, H-3], fill=(200,0,0))
    big_click_here(d, ct+252, (200,0,0), label="CLICK HERE NOW")
    win98_border(d)
    draw_titlebar(d, "DOCTORS HATE HIM - See Why", title_bg=(0,0,0), close_style="fat")
    img.save(os.path.join(OUT, "ad_weight.png"))


# ── AD 6: iPhone — gradient bg, product box, tiny legal ──────────────
def ad_iphone():
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    ct = TITLEBAR_H + 2
    # Gradient blue→black
    for y in range(ct, H-2):
        t = (y - ct) / (H - ct)
        r = int(0 * (1-t))
        g = int(50 * (1-t))
        b = int(200 * (1-t) + 10 * t)
        d.line([(2, y),(W-3, y)], fill=(r,g,b))
    # Glowing box
    d.rectangle([80, ct+10, W-80, ct+80], fill=(20,20,80), outline=(100,180,255), width=3)
    cx(d, "📱 FREE iPHONE 3G 📱", ct+20, font(26, bold=True), (100,220,255))
    cx(d, "YOU HAVE BEEN SELECTED", ct+55, font(16, bold=True), (200,200,255))
    cx(d, "★ ★ ★ ★ ★", ct+95, font(28, bold=True), (255,200,0))
    cx(d, "Only 3 remaining!!!", ct+135, font(22, bold=True), (255,100,0))
    # Fake counter
    d.rectangle([120,ct+168,W-120,ct+196], fill=(0,0,50), outline=(255,200,0), width=2)
    cx(d, "00 : 04 : 12  remaining", ct+172, font(18, bold=True), (255,200,0))
    cx(d, "NO CATCH · NO CREDIT CHECK · 100% REAL", ct+210, font(13, bold=True), (100,200,255))
    big_click_here(d, ct+234, (0,120,220), label="CLICK HERE TO CLAIM")
    d.text((10, H-18), "†offer valid for residents of earth. some restrictions apply.", font=font(8), fill=(80,80,120))
    win98_border(d)
    draw_titlebar(d, "You Have Been Selected!", title_bg=(0,0,160), close_style="red")
    img.save(os.path.join(OUT, "ad_iphone.png"))


# ── AD 7: download — dark, multiple fake download buttons ─────────────
def ad_download():
    img = Image.new("RGB", (W, H), (30, 30, 30))
    d = ImageDraw.Draw(img)
    ct = TITLEBAR_H + 2
    d.rectangle([2, ct, W-3, H-3], fill=(20,20,20))
    cx(d, "YOUR DOWNLOAD IS READY", ct+10, font(24, bold=True), (0,255,0))
    d.line([(20,ct+42),(W-20,ct+42)], fill=(0,200,0), width=1)
    # Three fake download buttons — only one is "real"
    btns = [
        (30,  ct+52,  "⬇  DOWNLOAD  (Recommended)", (0,150,0),   (255,255,255)),
        (30,  ct+104, "⬇  DOWNLOAD  (Fast)",         (0,80,180),  (255,255,255)),
        (30,  ct+156, "⬇  DOWNLOAD  (Free)",          (120,0,120), (255,255,200)),
    ]
    for bx2, by2, label, bg, fg in btns:
        d.rectangle([bx2, by2, W-bx2, by2+42], fill=bg, outline=(200,200,200), width=1)
        tw, _ = text_w(d, label, font(18, bold=True))
        d.text((bx2 + ((W-bx2*2)-tw)//2, by2+10), label, font=font(18, bold=True), fill=fg)
    big_click_here(d, ct+208, (0,140,0), label="CLICK HERE")
    d.text((10, H-18), "*no viruses detected by our proprietary scanner v1.0", font=font(9), fill=(80,80,80))
    win98_border(d)
    draw_titlebar(d, "Download Manager v2.1", title_bg=(0,60,0), close_style="normal")
    img.save(os.path.join(OUT, "ad_download.png"))


if __name__ == "__main__":
    print("Generating ads...")
    ad_virus()
    ad_winner()
    ad_iq()
    ad_dating()
    ad_weight()
    ad_iphone()
    ad_download()
    print("Done!")
