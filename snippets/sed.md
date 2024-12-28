# Add newline after a fixed number of characters
```bash
sed "s/.\{80\}/&\n/g" file.txt

awk '{print $1}' Chinese_SC_TC.txt | tr -d '\n' | sed "s/.\{80\}/&\n/g" | sed '$ ! s/$/\\/g' > Chinese_SC.txt
awk '{print $2}' Chinese_SC_TC.txt | tr -d '\n' | sed "s/.\{80\}/&\n/g" | sed '$ ! s/$/\\/g' > Chinese_TC.txt
```

# Add `\` to the end of each line
`sed 's/$/\\/g' file.txt`

# Add  `\` to the end of each line except the last line
`sed '$ ! s/$/\\/g' file.txt`

# [Convert from hex to decimal](https://stackoverflow.com/questions/13280131/hexadecimal-to-decimal-in-shell-script)
```bash
echo $((16#FF))

echo "ibase=16; FF" | bc

hexNum=2f
echo $((0x${hexNum}))

printf "%d\n" 0xFF

python -c 'print(int("FF", 16))'

ruby -e 'p "FF".to_i(16)'

node <<< "console.log(parseInt('FF', 16))"

# [Rhino](https://github.com/mozilla/rhino)
# sudo pacman -S rhino
rhino<<EOF
print(parseInt('FF', 16))
EOF

groovy -e 'println Integer.parseInt("FF",16)'
```

# [How to trim whitespace from a Bash variable?](https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable)
```bash
# remove leading whitespace only
echo ' test test test ' | sed -e 's/^[[:space:]]*//'

# remove trailing whitespace only
echo ' test test test ' | sed -e 's/[[:space:]]*$//'

# remove both leading and trailing spaces
echo ' test test test ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
```

# [View unicode codepoints](https://superuser.com/questions/377793/view-unicode-codepoints-for-all-letters-in-file-on-bash)
```bash
echo -n 'Hi! 😊' | iconv -f utf8 -t utf32le | hexdump -v -e '8/4 "0x%04x " "\n"' | sed -re"s/0x /   /g"

echo -n "😊" | iconv -f utf8 -t utf32be | xxd -p | sed -r 's/^0+/0x/' | xargs printf 'U+%04X\n'

echo -n "😊" |              # -n ignore trailing newline                     \
    iconv -f utf8 -t utf32be |  # UTF-32 big-endian happens to be the code point \
    xxd -p |                    # -p just give me the plain hex                  \
    sed -r 's/^0+/0x/' |        # remove leading 0's, replace with 0x            \
    xargs printf 'U+%04X\n'     # pretty print the code point
```

# add line before match line
`echo -e "line1\nline2\nline4" | sed '/^line4/i\line3'`

# add line after match line
`echo -e "line1\nline2\nline4" | sed '/^line2/a\line3'`

# comment lines
`echo -e "line1\nline2" | sed 's/^line1/# &/g'`

# [Appending 0's to a file in unix/bash if the line is less than a fixed length](https://stackoverflow.com/questions/46443750/appending-0s-to-a-file-in-unix-bash-if-the-line-is-less-than-a-fixed-length)
`awk 'length<66{ printf "%s%0*d\n",$0,66-length,0;next }' input.txt`

# [How to trim whitespace from a Bash variable?](https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable)
`echo ' test test ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`

# control characters
```bash
printf '123\nabc\n\001foo\002\u0080\u0084中文\n汉语888\u0084\n中OK' | tee input.txt

NOT_VALID_LINE=$(grep -n -P "[\x80-\xFF]" input.txt | cut -d: -f1 | sort -nr)
while read -r line; do
    [[ ${line} -gt 0 ]] && sed -i "${line}d" input.txt
done <<< "${NOT_VALID_LINE}"
```

## check which control character in `yaml` file using python
- save following script to file `check_control_characters.py`
```python
#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# pip install pyyaml
import yaml

try:
    with open('input.yml', 'r') as file:
        data = yaml.safe_load(file)
except yaml.YAMLError as e:
    print("Parsing YAML string failed")
    print("Reason:", e.reason)
    print("At position: {0} with encoding {1}".format(e.position, e.encoding))
    print("Invalid char code: ", e.character, hex(e.character))
```

- run `python check_control_characters.py` to check invalid control characters
```bash
# >> Invalid char code:  132 0x84
grep -n -P "[\x84]" input.yml
```

## [How to insert a new line character after a fixed number of characters in a file](https://stackoverflow.com/questions/1187078/how-to-insert-a-new-line-character-after-a-fixed-number-of-characters-in-a-file)
```bash
#  remove duplicate lines before rearrange lines
# 80 characters perline
awk '!seen[$0]++' input.txt | tr -d '\n' | sed -e "s/.\{80\}/&\n/g" > output.txt
```
