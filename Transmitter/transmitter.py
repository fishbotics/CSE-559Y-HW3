import numpy as np
from PIL import Image
import cv2
import argparse


# The bit conversaion functions are inspired by https://stackoverflow.com/questions/10237926/convert-string-to-list-of-bits-and-viceversa
def tobits(s):
    result = []
    for c in s:
        bits = bin(ord(c))[2:]
        bits = '00000000'[len(bits):] + bits
        result.extend([int(b) for b in bits])
    return ''.join([str(r) for r in result])


def frombits(bits):
    chars = []
    for b in range(len(bits) / 8):
        byte = bits[b * 8: (b + 1) * 8]
        chars.append(chr(int(''.join([str(bit) for bit in byte]), 2)))
    return ''.join(chars)


def zero(base, foreground, dimness):
    mask_img = Image.fromarray(
        np.ones(
            (base.height, base.width),
            dtype=np.uint8
        ) * dimness,
    )
    img = Image.composite(foreground, base, mask_img)
    return [
        base.copy(),
        base.copy(),
        img.copy(),
        base.copy(),
        base.copy(),
        img.copy(),
        base.copy(),
        base.copy(),
        img.copy(),
        base.copy(),
        base.copy(),
        img.copy(),
    ]


def one(base, foreground, dimness):
    mask_img = Image.fromarray(
        np.ones(
            (base.height, base.width),
            dtype=np.uint8
        ) * dimness,
    )
    img = Image.composite(foreground, base, mask_img)
    return [
        base.copy(),
        img.copy(),
        base.copy(),
        img.copy(),
        base.copy(),
        img.copy(),
        base.copy(),
        img.copy(),
        base.copy(),
        img.copy(),
        base.copy(),
        img.copy(),
    ]


def run(bit_string, alpha_level=0.1, framerate=30):
    assert bit_string is not None
    bit_string = "1" + bit_string
    print(f"Encoding bits: {bit_string}")
    dimness = int(alpha_level * 255)
    base = Image.open('Siberian-Husky-Background-HD.jpg')
    data = np.zeros((base.height, base.width, 3), dtype=np.uint8)
    foreground = Image.fromarray(data, )       # Create a PIL image
    images = []
    for bit in bit_string:
        assert bit == "0" or bit == "1"
        if bit == "0":
            images.extend(zero(base, foreground, dimness))
        else:
            images.extend(one(base, foreground, dimness))

    fourcc = cv2.VideoWriter_fourcc(*'avc1')
    video = cv2.VideoWriter(f"{input_string}_{bit_string}.mp4", fourcc, framerate, (base.width, base.height))
    for img in images:
        video.write(cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR))
    video.release()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Produce a video encoding')
    parser.add_argument('--bit-string', type=str, default=None)
    parser.add_argument('--alpha', type=float, default=0.05)
    parser.add_argument('--framerate', type=int, default=60)
    args = parser.parse_args()
    run(args.input_string, args.bit_string, args.alpha, args.framerate)
