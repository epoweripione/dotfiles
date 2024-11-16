#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# pip install pyyaml
import yaml

try:
    with open('meta.yml', 'r') as file:
        data = yaml.safe_load(file)
except yaml.YAMLError as e:
    print("Parsing YAML string failed")
    print("Reason:", e.reason)
    print("At position: {0} with encoding {1}".format(e.position, e.encoding))
    print("Invalid char code: ", e.character, hex(e.character))
