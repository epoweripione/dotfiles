# -*- coding: UTF-8 -*-

import argparse
import pathlib

# argument parser
def GetParser():
    parser = argparse.ArgumentParser()
    parser.add_argument('-u', '--url', help='Url', required=True)
    parser.add_argument('-s', '--selector', help='Element selecor', required=True)
    parser.add_argument('-t', '--type', help='Selecor type: ID, CLASS_NAME, CSS_SELECTOR, NAME, TAG_NAME, XPATH, LINK_TEXT, PARTIAL_LINK_TEXT', default='ID', required=False)
    parser.add_argument('-o', '--outfile', help='Output file name', required=False)
    args = parser.parse_args()
    return args

# write result to file
def WriteText2File(filename:str, text:str):
    pathlib.Path(filename).write_bytes(text.encode())

def WriteLines2File(filename:str, lines):
    outfile = open(filename, "w", encoding='utf8')
    outfile.writelines(lines)
    outfile.close()
