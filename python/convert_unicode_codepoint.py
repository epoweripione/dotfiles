# -*- coding: UTF-8 -*-

import os, sys
import pathlib
import re

def WriteText2File(filename:str, text:str):
    pathlib.Path(filename).write_bytes(text.encode())

def WriteLines2File(filename:str, lines):
    outfile = open(filename, "w", encoding='utf8')
    outfile.writelines(lines)
    outfile.close()

def main(filename:str):
    # testStr = '\U0001F1FA\U0001F1F8_US'
    # outText = re.sub(r'<U\+([A-F0-9]+)>', lambda x: chr(int(x.group(1), 16)), testStr)
    # print(repr(outText.strip()))

    ## \u1203\u1208\u1208 \u0074\u00E4\u0068\u0061\u006C\u00E4\u006C\u00E4
    # with open(filename, 'rb') as fp:
    # for line in fp:
    #     print(line.decode('unicode_escape'))

    outText = ""
    with open(filename, 'r', encoding='utf8') as fp:
        while True:
            line = fp.readline()
            if not line:
                break
            utf8Text = re.sub(r'\\U([A-F0-9]+)', lambda x: chr(int(x.group(1), 16)), line)
            # print(repr(utf8Text.strip()))
            outText = outText + utf8Text.strip() + os.linesep
    WriteText2File(f"{filename}.new", outText)

if __name__ == '__main__':
    filename = sys.argv[1]
    try:
        main(filename)
    except Exception as e:
        print(e)
