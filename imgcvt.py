

import PIL
from PIL import Image
from bitstring import BitString

# CLI
import climax


def bitlist_parse(bits):
    res = BitString(bits)
    for x in bits:
        res <<= 1
        res += bits[x]
    return res
    
    
    
def print_img(path):
    image = Image.open("logo.png")

    data = image.getdata()

    pixels = data.pixel_access()
    binimg = [BitString([pixels[x, y][0] == 0 for x in range(32)]) for y in range(32)]

    for index, row in enumerate(binimg):
        if row.all(False):
            print('\tsw\tzero,{}(x3)'.format(index * 4))
        else:
            print('\tli\tt0,0x{}'.format(row.hex))
            print('\tsw\tt0,{}(x3)'.format(index * 4))


@climax.command()
@climax.argument('path', type=str, help='Path to the image file')
def main(path):
    print_img(path)


if __name__ == '__main__':
    main()
