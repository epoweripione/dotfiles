#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

# [Stylus](https://chrome.google.com/webstore/detail/stylus/clngdbkpkpeebahjckkjfobafhncgmne)
CSS_FILE=${1:-"$HOME/fonts_stylus.css"}

CJK_RANGE_HAN="U+3400-4DBF,U+4E00-9FFF,U+F900-FAFF,U+D840-D87A,U+D880-D884,U+DC00-DFFF,U+3040-309F,U+30A0-30FF,U+DC00-DC01,U+31F0-31FF,U+FF66-FF9F,U+D82C,U+1100-11FF,U+3130-318F,U+A960-A97C,U+AC00-D7A3,U+D7B0-D7FB,U+FFA1-FFDC"

# https://en.wikipedia.org/wiki/List_of_sans_serif_typefaces
# https://en.wikipedia.org/wiki/List_of_serif_typefaces
# https://en.wikipedia.org/wiki/List_of_monospaced_typefaces
# LOCALE;Default SRC...;CJK SRC...
declare -A CSS_FONTS=(
    # Default
    ["Noto Sans CJK SC"]="SC;Noto Sans;Noto Sans CJK SC"
    ["Noto Sans CJK TC"]="TC;Noto Sans;Noto Sans CJK TC"
    ["Noto Sans CJK HK"]="HK;Noto Sans;Noto Sans CJK HK"
    ["Noto Sans CJK JP"]="JP;Noto Sans;Noto Sans CJK JP"
    ["Noto Sans CJK KR"]="KR;Noto Sans;Noto Sans CJK KR"

    ["Noto Serif CJK SC"]="SC;Noto Serif;Noto Serif CJK SC"
    ["Noto Serif CJK TC"]="TC;Noto Serif;Noto Serif CJK TC"
    ["Noto Serif CJK HK"]="HK;Noto Serif;Noto Serif CJK HK"
    ["Noto Serif CJK JP"]="JP;Noto Serif;Noto Serif CJK JP"
    ["Noto Serif CJK KR"]="KR;Noto Serif;Noto Serif CJK KR"

    ["Noto Sans SC"]="SC;Noto Sans;Noto Sans CJK SC"
    ["Noto Sans TC"]="TC;Noto Sans;Noto Sans CJK TC"
    ["Noto Sans HK"]="HK;Noto Sans;Noto Sans CJK HK"
    ["Noto Sans JP"]="JP;Noto Sans;Noto Sans CJK JP"
    ["Noto Sans KR"]="KR;Noto Sans;Noto Sans CJK KR"

    ["Noto Serif SC"]="SC;Noto Serif;Noto Serif CJK SC"
    ["Noto Serif TC"]="TC;Noto Serif;Noto Serif CJK TC"
    ["Noto Serif HK"]="HK;Noto Serif;Noto Serif CJK HK"
    ["Noto Serif JP"]="JP;Noto Serif;Noto Serif CJK JP"
    ["Noto Serif KR"]="KR;Noto Serif;Noto Serif CJK KR"

    ["PingFang"]="SC;Noto Sans;PingFang SC"

    ["PingFangSC"]="SC;Noto Sans;PingFang SC"
    ["PingFangTC"]="TC;Noto Sans;PingFang TC"
    ["PingFangHK"]="HK;Noto Sans;PingFang HK"

    ["PingFang SC"]="SC;Noto Sans;PingFang SC"
    ["PingFang TC"]="TC;Noto Sans;PingFang TC"
    ["PingFang HK"]="HK;Noto Sans;PingFang HK"

    ["PingFang-SC"]="SC;Noto Sans;PingFang SC"
    ["PingFang-TC"]="TC;Noto Sans;PingFang TC"
    ["PingFang-HK"]="HK;Noto Sans;PingFang HK"

    # Sans-serif
    ["Arial"]="EN;Noto Sans;"
    ["Arial Black"]="EN;Noto Sans;"
    ["Calibri"]="EN;Noto Sans;"
    ["Candara"]="EN;Noto Sans;"
    ["Comic Sans MS"]="EN;Noto Sans;"
    ["Corbel"]="EN;Noto Sans;"
    ["Helvetica"]="EN;Noto Sans;"
    ["Helvetica Neue"]="EN;Noto Sans;"
    ["Impact"]="EN;Noto Sans;"
    ["Lato"]="EN;Noto Sans;"
    ["Lucida Grande"]="EN;Noto Sans;"
    ["Roboto"]="EN;Noto Sans;"
    ["Segoe UI"]="EN;Noto Sans;"
    ["Tahoma"]="EN;Noto Sans;"
    ["Tahoma Bold"]="EN;Noto Sans;"
    ["Trebuchet MS"]="EN;Noto Sans;"
    ["Verdana"]="EN;Noto Sans;"

    ["sans-serif"]="*;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["-apple-system"]="*;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["-webkit-standard"]="*;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["BlinkMacSystemFont"]="*;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["Open Sans"]="*;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["standard"]="*;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["Source Sans 3"]="*;Noto Sans;Noto Sans CJK SC,PingFang SC"

    # Serif
    ["Cambria"]="EN;Noto Serif;"
    ["Georgia"]="EN;Noto Serif;"
    ["Constantia"]="EN;Noto Serif;"
    ["Mceinline"]="EN;Noto Serif;"
    ["Palatino Linotype"]="EN;Noto Serif;"
    ["Times CY"]="EN;Noto Serif;"
    ["Times New Roman"]="EN;Noto Serif;"
    ["Times"]="EN;Noto Serif;"

    ["serif"]="*;Noto Serif;Noto Serif CJK SC"
    ["Source Serif 4"]="*;Noto Serif;Noto Serif CJK SC"

    # CJK Sans-serif
    ["FZLanTingHei-R-GBK"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["Heiti SC"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["Hiragino Sans GB"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["Microsoft YaHei"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["Microsoft YaHei UI"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["STHeiti"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["Simhei"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC;"
    ["Source Han Sans CN"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["WenQuanYi Micro Hei"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["WenQuanYi Zen Hei"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["微软雅黑"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["瀹嬩綋"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["黑体"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["华文黑体"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"
    ["����"]="SC;Noto Sans;Noto Sans CJK SC,PingFang SC"

    ["Apple LiGothic"]="TC;Noto Sans;Noto Sans CJK TC,PingFang TC"
    ["Apple LiGothic Medium"]="TC;Noto Sans;Noto Sans CJK TC,PingFang TC"
    ["Heiti TC"]="TC;Noto Sans;Noto Sans CJK TC,PingFang TC"
    ["黑體-繁"]="TC;Noto Sans;Noto Sans CJK TC,PingFang TC"
    ["Microsoft Jhenghei"]="TC;Noto Sans;Noto Sans CJK TC,PingFang TC"
    ["Microsoft JhengHei UI"]="TC;Noto Sans;Noto Sans CJK TC,PingFang TC"
    ["Custom-MS-JhengHei"]="TC;Noto Sans;Noto Sans CJK TC,PingFang TC"
    ["微軟正黑體"]="TC;Noto Sans;Noto Sans CJK TC,PingFang TC"

    ["Hiragino Sans"]="JP;Noto Sans;Noto Sans CJK JP"
    ["Meiryo"]="JP;Noto Sans;Noto Sans CJK JP"
    ["Meiryo UI"]="JP;Noto Sans;Noto Sans CJK JP"
    ["MS PGothic"]="JP;Noto Sans;Noto Sans CJK JP"
    ["ＭＳ Ｐゴシック"]="JP;Noto Sans;Noto Sans CJK JP"
    ["Yu Gothic"]="JP;Noto Sans;Noto Sans CJK JP"
    ["Yu Gothic Medium"]="JP;Noto Sans;Noto Sans CJK JP"
    ["Yu Gothic UI"]="JP;Noto Sans;Noto Sans CJK JP"
    ["游ゴシック"]="JP;Noto Sans;Noto Sans CJK JP"
    ["游ゴシック Medium"]="JP;Noto Sans;Noto Sans CJK JP"
    ["游ゴシック体"]="JP;Noto Sans;Noto Sans CJK JP"
    ["メイリオ"]="JP;Noto Sans;Noto Sans CJK JP"
    ["ヒラギノ角ゴ Pro W3"]="JP;Noto Sans;Noto Sans CJK JP"

    ["Gulim"]="KR;Noto Sans;Noto Sans CJK KR"
    ["굴림"]="KR;Noto Sans;Noto Sans CJK KR"
    ["dotum"]="KR;Noto Sans;Noto Sans CJK KR"
    ["돋움"]="KR;Noto Sans;Noto Sans CJK KR"
    ["고딕"]="KR;Noto Sans;Noto Sans CJK KR"

    # CJK Serif
    ["Arial SimSun"]="SC;Noto Serif;Noto Serif CJK SC"
    ["simsun Arial"]="SC;Noto Serif;Noto Serif CJK SC"
    ["Simsun"]="SC;Noto Serif;Noto Serif CJK SC"
    ["宋体"]="SC;Noto Serif;Noto Serif CJK SC"
    ["宋體"]="SC;Noto Serif;Noto Serif CJK SC"

    ["PMingLiU"]="TC;Noto Serif;Noto Serif CJK TC"
    ["PMingLiU-ExtB"]="TC;Noto Serif;Noto Serif CJK TC"
    ["新细明体"]="TC;Noto Serif;Noto Serif CJK TC"
    ["新細明體"]="TC;Noto Serif;Noto Serif CJK TC"

    ["Yu Mincho"]="JP;Noto Serif;Noto Serif CJK JP"

    ["Myungjo"]="KR;Noto Serif;Noto Serif CJK KR"
    ["명조"]="KR;Noto Serif;Noto Serif CJK KR"
    ["Batang"]="KR;Noto Serif;Noto Serif CJK KR"
    ["바탕"]="KR;Noto Serif;Noto Serif CJK KR"

    # mono
    ["Andale Mono"]="MONO;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["Consolas"]="MONO;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["Courier"]="MONO;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["Courier New"]="MONO;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["FantasqueSansMonoRegular"]="MONO;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["Lucida Console"]="MONO;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["Menlo"]="MONO;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["Monaco"]="MONO;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["mono"]="MONO;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["monospace"]="MONO;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"

    ["NSimsun"]="SC;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["新宋体"]="SC;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"
    ["细明体"]="SC;JetBrainsMono Nerd Font;Noto Sans Mono CJK SC"

    ["MingLiU"]="TC;JetBrainsMono Nerd Font;Noto Sans Mono CJK TC"
    ["MingLiU-ExtB"]="TC;JetBrainsMono Nerd Font;Noto Sans Mono CJK TC"
    ["新宋體"]="TC;JetBrainsMono Nerd Font;Noto Sans Mono CJK TC"
    ["細明體"]="TC;JetBrainsMono Nerd Font;Noto Sans Mono CJK TC"

    ["MingLiU_HKSCS"]="HK;JetBrainsMono Nerd Font;Noto Sans Mono CJK HK"
    ["MingLiU_HKSCS-ExtB"]="HK;JetBrainsMono Nerd Font;Noto Sans Mono CJK HK"

    ["Sarasa Fixed SC"]="SC;Sarasa Fixed SC;"
    ["Sarasa Fixed Slab SC"]="SC;Sarasa Fixed Slab SC;"
    ["Sarasa Term SC"]="SC;Sarasa Term SC;"
    ["Sarasa Term Slab SC"]="SC;Sarasa Term Slab SC;"
    ["Sarasa Gothic SC"]="SC;Sarasa Gothic SC;"
    ["Sarasa UI SC"]="SC;Sarasa UI SC;"
    ["Sarasa Mono SC"]="SC;Sarasa Mono SC;"
    ["Sarasa Mono Slab SC"]="SC;Sarasa Mono Slab SC;"
    ["更纱黑体 SC"]="SC;更纱黑体 SC;"
    ["更纱黑体 UI SC"]="SC;更纱黑体 UI SC;"
    ["等距更纱黑体 SC"]="SC;等距更纱黑体 SC;"
    ["等距更纱黑体 Slab SC"]="SC;等距更纱黑体 Slab SC;"

    ["Sarasa Fixed TC"]="TC;Sarasa Fixed TC;"
    ["Sarasa Fixed Slab TC"]="TC;Sarasa Fixed Slab TC;"
    ["Sarasa Term TC"]="TC;Sarasa Term TC;"
    ["Sarasa Term Slab TC"]="TC;Sarasa Term Slab TC;"
    ["Sarasa Gothic TC"]="TC;Sarasa Gothic TC;"
    ["Sarasa UI TC"]="TC;Sarasa UI TC;"
    ["Sarasa Mono TC"]="TC;Sarasa Mono TC;"
    ["Sarasa Mono Slab TC"]="TC;Sarasa Mono Slab TC;"
    ["更紗黑體 TC"]="TC;更紗黑體 TC;"
    ["更紗黑體 UI TC"]="TC;更紗黑體 UI TC;"
    ["等距更紗黑體 TC"]="TC;等距更紗黑體 TC;"
    ["等距更紗黑體 Slab TC"]="TC;等距更紗黑體 Slab TC;"

    ["Sarasa Fixed CL"]="CL;Sarasa Fixed CL;"
    ["Sarasa Fixed Slab CL"]="CL;Sarasa Fixed Slab CL;"
    ["Sarasa Term CL"]="CL;Sarasa Term CL;"
    ["Sarasa Term Slab CL"]="CL;Sarasa Term Slab CL;"
    ["Sarasa Gothic CL"]="CL;Sarasa Gothic CL;"
    ["Sarasa UI CL"]="CL;Sarasa UI CL;"
    ["Sarasa Mono CL"]="CL;Sarasa Mono CL;"
    ["Sarasa Mono Slab CL"]="CL;Sarasa Mono Slab CL;"
    ["更紗黑體 CL"]="CL;更紗黑體 CL;"
    ["更紗黑體 UI CL"]="CL;更紗黑體 UI CL;"
    ["等距更紗黑體 CL"]="CL;等距更紗黑體 CL;"
    ["等距更紗黑體 Slab CL"]="CL;等距更紗黑體 Slab CL;"

    ["Sarasa Fixed HC"]="HK;Sarasa Fixed HC;"
    ["Sarasa Fixed Slab HC"]="HK;Sarasa Fixed Slab HC;"
    ["Sarasa Term HC"]="HK;Sarasa Term HC;"
    ["Sarasa Term Slab HC"]="HK;Sarasa Term Slab HC;"
    ["Sarasa Gothic HC"]="HK;Sarasa Gothic HC;"
    ["Sarasa UI HC"]="HK;Sarasa UI HC;"
    ["Sarasa Mono HC"]="HK;Sarasa Mono HC;"
    ["Sarasa Mono Slab HC"]="HK;Sarasa Mono Slab HC;"
    ["更紗黑體 HC"]="HK;更紗黑體 HC;"
    ["更紗黑體 UI HC"]="HK;更紗黑體 UI HC;"
    ["等距更紗黑體 HC"]="HK;等距更紗黑體 HC;"
    ["等距更紗黑體 Slab HC"]="HK;等距更紗黑體 Slab HC;"

    ["Sarasa Fixed J"]="JP;Sarasa Fixed J;"
    ["Sarasa Fixed Slab J"]="JP;Sarasa Fixed Slab J;"
    ["Sarasa Term J"]="JP;Sarasa Term J;"
    ["Sarasa Term Slab J"]="JP;Sarasa Term Slab J;"
    ["Sarasa Gothic J"]="JP;Sarasa Gothic J;"
    ["Sarasa UI J"]="JP;Sarasa UI J;"
    ["Sarasa Mono J"]="JP;Sarasa Mono J;"
    ["Sarasa Mono Slab J"]="JP;Sarasa Mono Slab J;"
    ["更紗ゴシック J"]="JP;更紗ゴシック J;"
    ["更紗ゴシック UI J"]="JP;更紗ゴシック UI J;"
    ["更紗等幅ゴシック J"]="JP;等距更纱黑体 J;"
    ["更紗等幅ゴシック Slab J"]="JP;等距更纱黑体 Slab J;"

    ["Sarasa Fixed K"]="KR;Sarasa Fixed K;"
    ["Sarasa Fixed Slab K"]="KR;Sarasa Fixed Slab K;"
    ["Sarasa Term K"]="KR;Sarasa Term K;"
    ["Sarasa Term Slab K"]="KR;Sarasa Term Slab K;"
    ["Sarasa Gothic K"]="KR;Sarasa Gothic K;"
    ["Sarasa UI K"]="KR;Sarasa UI K;"
    ["Sarasa Mono K"]="KR;Sarasa Mono K;"
    ["Sarasa Mono Slab K"]="KR;Sarasa Mono Slab K;"

    # other
    ["kaiti"]="SC;kaiti;"
    ["隶书"]="SC;隶书;"
)

tee "${CSS_FILE}" >/dev/null <<-'EOF'
html:lang(zh-CN),html:lang(zh-SG) {
    font-family: 'Noto Sans', 'Noto Sans CJK SC', emoji;
}

html:lang(zh-TW),html:lang(zh-MO) {
    font-family: 'Noto Sans', 'Noto Sans CJK TC', emoji;
}

html:lang(zh-HK) {
    font-family: 'Noto Sans', 'Noto Sans CJK HK', emoji;
}

html:lang(ja) {
    font-family: 'Noto Sans', 'Noto Sans CJK JP', emoji;
}

html:lang(ko) {
    font-family: 'Noto Sans', 'Noto Sans CJK KR', emoji;
}

body {
    -webkit-font-smoothing: subpixel-antialiased !important;
    -moz-osx-font-smoothing: grayscale !important;
    text-rendering: optimizeLegibility !important;
    font-family: inherit;
}

EOF

for TargetFont in "${!CSS_FONTS[@]}"; do
    FONT_RULES="${CSS_FONTS["${TargetFont}"]}"

    FONT_LOCALE=$(cut -d';' -f1 <<< "${FONT_RULES}")
    FONT_DEFAULT=$(cut -d';' -f2 <<< "${FONT_RULES}")
    FONT_CJK=$(cut -d';' -f3 <<< "${FONT_RULES}")

    # Default SRC
    echo "@font-face {" >> "${CSS_FILE}"
    echo "    font-family: '${TargetFont}';" >> "${CSS_FILE}"

    FONTFACE_SRC=""
    while read -r font; do
        if [[ -z "${FONTFACE_SRC}" ]]; then
            FONTFACE_SRC="local('${font}')"
        else
            FONTFACE_SRC="${FONTFACE_SRC}, local('${font}')"
        fi
    done < <(echo "${FONT_DEFAULT}" | tr ',' '\n')

    echo "    src: ${FONTFACE_SRC};" >> "${CSS_FILE}"
    echo -e "}\n" >> "${CSS_FILE}"

    # CJK SRC
    if [[ -n "${FONT_CJK}" ]]; then
        echo "@font-face {" >> "${CSS_FILE}"
        echo "    font-family: '${TargetFont}';" >> "${CSS_FILE}"

        FONTFACE_SRC=""
        while read -r font; do
            if [[ -z "${FONTFACE_SRC}" ]]; then
                FONTFACE_SRC="local('${font}')"
            else
                FONTFACE_SRC="${FONTFACE_SRC}, local('${font}')"
            fi
        done < <(echo "${FONT_CJK}" | tr ',' '\n')

        echo "    src: ${FONTFACE_SRC};" >> "${CSS_FILE}"
        echo "    unicode-range: ${CJK_RANGE_HAN};" >> "${CSS_FILE}"
        echo -e "}\n" >> "${CSS_FILE}"
    fi
done

tee -a "${CSS_FILE}" >/dev/null <<-'EOF'
pre,code,kbd,samp {
    font-family: 'JetBrainsMono Nerd Font', 'Noto Sans Mono CJK SC', emoji !important;
}
EOF
