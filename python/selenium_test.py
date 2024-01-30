#!/usr/bin/env python
# -*- coding: UTF-8 -*-

## Run selenium and chrome driver to scrape data from cloudbytes.dev
import sys, time
import os.path

import utils

# pip install selenium argparse pathlib
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options

## Setup chrome options
chrome_options = Options()
chrome_options.add_argument("--headless") # Ensure GUI is off
chrome_options.add_argument("--no-sandbox")

# Set path to chrome/chromedriver as per your configuration
homedir = os.path.expanduser("~")
chrome_options.binary_location = f"{homedir}/selenium/chrome-linux64/chrome"
webdriver_service = Service(f"{homedir}/selenium/chromedriver-linux64/chromedriver")

# Choose Chrome Browser
browser = webdriver.Chrome(service=webdriver_service, options=chrome_options)


# [Finding web elements](https://www.selenium.dev/documentation/webdriver/elements/finders/)
# [Locating Elements](https://selenium-python.readthedocs.io/locating-elements.html)
def getPageElement(url:str, selecor:str, selecortype:str, outfile:str):
    browser.get(url)

    # elements = browser.find_elements(By.ID, "fruits")
    # elements = browser.find_elements(By.CLASS_NAME, "tomatoes")
    # elements = browser.find_elements(By.CSS_SELECTOR, "#fruits .tomatoes")
    # elements = browser.find_elements(By.NAME, "description")
    # elements = browser.find_elements(By.TAG_NAME, 'p')
    # elements = browser.find_elements(By.XPATH, "//div")
    # elements = browser.find_elements(By.LINK_TEXT, "link text")
    # elements = browser.find_elements(By.PARTIAL_LINK_TEXT, "partial link text")
    match selecortype.upper():
        case "ID":
            elements = browser.find_elements(By.ID, selecor)
        case "CLASS_NAME":
            elements = browser.find_elements(By.CLASS_NAME, selecor)
        case "CSS_SELECTOR":
            elements = browser.find_elements(By.CSS_SELECTOR, selecor)
        case "NAME":
            elements = browser.find_elements(By.NAME, selecor)
        case "TAG_NAME":
            elements = browser.find_elements(By.TAG_NAME, selecor)
        case "XPATH":
            elements = browser.find_elements(By.XPATH, selecor)
        case "LINK_TEXT":
            elements = browser.find_elements(By.LINK_TEXT, selecor)
        case "PARTIAL_LINK_TEXT":
            elements = browser.find_elements(By.PARTIAL_LINK_TEXT, selecor)
        case _:
            elements = browser.find_elements(By.ID, selecor)

    outText = ""
    for e in elements:
        outText = outText + os.linesep + e.text

    if (outfile):
        utils.WriteText2File(outfile, outText)
    else:
        print(f"{outText}")

    ## Wait for 10 seconds
    # time.sleep(10)

    browser.quit()


def main(args):
    getPageElement(args.url, args.selector, args.type, args.outfile)


if __name__ == '__main__':
    args = utils.GetParser()
    try:
        main(args)
    except Exception as e:
        print(e)
