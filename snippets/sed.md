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

nodejs <<< "console.log(parseInt('FF', 16))"

rhino<<EOF
print(parseInt('FF', 16))
EOF

groovy -e 'println Integer.parseInt("FF",16)'
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
