// ==UserScript==
// @name              CJK text Optimization
// @name:zh-CN        中日韩文字优化
// @namespace         https://github.com/epoweripione/dotfiles
// @version           1.0.0
// @description       Set font-family by html.lang; add spaces between CJK characters and Latin letters
// @description:zh-cn 根据网页 html.lang 设置默认字体；自动在汉字与拉丁字母间添加空格等
// @author            epoweripione
// @license           MIT
// @match             http://*/*
// @match             https://*/*
// @require           https://cdn.bootcss.com/jquery/3.6.0/jquery.min.js
// @require           https://cdn.bootcdn.net/ajax/libs/findAndReplaceDOMText/0.4.6/findAndReplaceDOMText.min.js
// @require           https://cdn.jsdelivr.net/npm/chinese-characters-codepoints-converter/index.js
// @grant             none
// ==/UserScript==

// [Console Importer](https://chrome.google.com/webstore/detail/console-importer/hgajpakhafplebkdljleajgbpdmplhie)
// $i('https://cdn.bootcss.com/jquery/3.6.0/jquery.min.js');
// $i('https://cdn.bootcdn.net/ajax/libs/findAndReplaceDOMText/0.4.6/findAndReplaceDOMText.min.js');
// $i('https://cdn.jsdelivr.net/npm/chinese-characters-codepoints-converter/index.js');

// Unicode Code Points
// '©'.codePointAt(0).toString(16);
// '😍'.codePointAt(0).toString(16);
// String.fromCodePoint(128525); // '😍'
// String.fromCodePoint(0x1f60d); // '😍'

(function() {
    'use strict';

    const siteHost = location.host;

    const FONT_DEFAULT = 'Noto Sans'; // 默认字体
    const FONT_EMOJI = 'emoji'; // Emoji 字体
    const FONT_FALLBACK = 'sans-serif'; // 备用字体
    const FONT_MONO = 'FiraCode Nerd Font Mono'; // 等宽字体

    const FONT_CJK_SC = 'Noto Sans CJK SC'; // 简体中文字体
    const FONT_MONO_CJK_SC = 'Noto Sans Mono CJK SC'; // 简体中文等宽字体

    const FONT_CJK_TC = 'Noto Sans CJK TC'; // 繁体中文（台湾）字体
    const FONT_MONO_CJK_TC = 'Noto Sans Mono CJK TC'; // 繁体中文（台湾）等宽字体

    const FONT_CJK_HK = 'Noto Sans CJK HK'; // 繁体中文（港澳）字体
    const FONT_MONO_CJK_HK = 'Noto Sans Mono CJK HK'; // 繁体中文（港澳）等宽字体

    const FONT_CJK_JP = 'Noto Sans CJK JP'; // 日文字体
    const FONT_MONO_CJK_JP = 'Noto Sans Mono CJK JP'; // 日文等宽字体

    const FONT_CJK_KR = 'Noto Sans CJK KR'; // 韩文字体
    const FONT_MONO_CJK_KR = 'Noto Sans Mono CJK KR'; // 韩文等宽字体

    // 地区、CJK 字体、CJK 等宽字体
    let FONT_LOCALE,FONT_CJK,FONT_MONO_CJK;

    // https://stackoverflow.com/questions/23683439/gm-addstyle-equivalent-in-tampermonkey
    function GM_addStyle(css) {
        const style = document.getElementById("CJK_Text_Optimize_TamperMonkey") || (function() {
            const style = document.createElement('style');
            style.type = 'text/css';
            style.id = "FontStyle_TamperMonkey";
            document.head.appendChild(style);
            return style;
        })();
        const sheet = style.sheet;
        sheet.insertRule(css, (sheet.rules || sheet.cssRules || []).length);
    }

    function GM_addStyleInnerHTML(css) {
        const style = document.createElement('style');
        style.type = 'text/css';
        style.id = "CJK_Text_Optimize_TamperMonkey";
        style.innerHTML = css;
        document.head.appendChild(style);
    }

    // let selectors = [
    //     'body',
    //     '.markdown-body',
    //     '.tooltipped::after',
    //     '.default-label .sha .ellipses'
    // ];
    // let styleNode = document.createElement('style');
    // let styleText = document.createTextNode(selectors.join(', ') + ' { font-family: ' + fontfamily + ' !important; }');
    // styleNode.type = "text/css";
    // styleNode.appendChild(styleText);
    // document.head.appendChild(styleNode);

    const FONTS_REPLACE = [
        'Noto Sans CJK SC',
        'Noto Sans CJK TC',
        'Noto Sans CJK HK',
        'Noto Sans CJK JP',
        'Noto Sans CJK KR',
        'Noto Serif CJK SC',
        'Noto Serif CJK TC',
        'Noto Serif CJK HK',
        'Noto Serif CJK JP',
        'Noto Serif CJK KR',
        'Noto Sans SC',
        'Noto Sans TC',
        'Noto Sans HK',
        'Noto Sans JP',
        'Noto Sans KR',
        'Noto Serif SC',
        'Noto Serif TC',
        'Noto Serif HK',
        'Noto Serif JP',
        'Noto Serif KR',
        'PingFang',
        'PingFangSC',
        'PingFangTC',
        'PingFangHK',
        'PingFang SC',
        'PingFang TC',
        'PingFang HK',
        'PingFang-SC',
        'PingFang-TC',
        'PingFang-HK',
        'Arial',
        'Arial Black',
        'Calibri',
        'Candara',
        'Comic Sans MS',
        'Corbel',
        'Helvetica',
        'Helvetica Neue',
        'Impact',
        'Lato',
        'Lucida Grande',
        'Roboto',
        'Segoe UI',
        'Tahoma',
        'Tahoma Bold',
        'Trebuchet MS',
        'Verdana',
        'sans-serif',
        '-apple-system',
        '-webkit-standard',
        'BlinkMacSystemFont',
        'Open Sans',
        'standard',
        'Source Sans 3',
        'Cambria',
        'Georgia',
        'Constantia',
        'Mceinline',
        'Palatino Linotype',
        'Times CY',
        'Times New Roman',
        'Times',
        'serif',
        'Source Serif 4',
        'FZLanTingHei-R-GBK',
        'Heiti SC',
        'Hiragino Sans GB',
        'Microsoft YaHei',
        'Microsoft YaHei UI',
        'STHeiti',
        'Simhei',
        'Source Han Sans CN',
        'WenQuanYi Micro Hei',
        'WenQuanYi Zen Hei',
        '微软雅黑',
        '瀹嬩綋',
        '黑体',
        '华文黑体',
        '����',
        'Apple LiGothic',
        'Apple LiGothic Medium',
        'Heiti TC',
        '黑體-繁',
        'Microsoft Jhenghei',
        'Microsoft JhengHei UI',
        'Custom-MS-JhengHei',
        '微軟正黑體',
        'Hiragino Sans',
        'Meiryo',
        'Meiryo UI',
        'MS PGothic',
        'ＭＳ Ｐゴシック',
        'Yu Gothic',
        'Yu Gothic Medium',
        'Yu Gothic UI',
        '游ゴシック',
        '游ゴシック Medium',
        '游ゴシック体',
        'メイリオ',
        'ヒラギノ角ゴ Pro W3',
        'Gulim',
        '굴림',
        'dotum',
        '돋움',
        '고딕',
        'Arial SimSun',
        'simsun Arial',
        'Simsun',
        '宋体',
        '宋體',
        'PMingLiU',
        'PMingLiU-ExtB',
        '新细明体',
        '新細明體',
        'Yu Mincho',
        'Myungjo',
        '명조',
        'Batang',
        '바탕',
        'Andale Mono',
        'Consolas',
        'Courier',
        'Courier New',
        'FantasqueSansMonoRegular',
        'Lucida Console',
        'Menlo',
        'Monaco',
        'mono',
        'monospace',
        'NSimsun',
        '新宋体',
        '细明体',
        'MingLiU',
        'MingLiU-ExtB',
        '新宋體',
        '細明體',
        'MingLiU_HKSCS',
        'MingLiU_HKSCS-ExtB',
    ];

    // CJK Unicode Characters
    // [Unicode 字符平面映射](https://zh.wikipedia.org/wiki/Unicode%E5%AD%97%E7%AC%A6%E5%B9%B3%E9%9D%A2%E6%98%A0%E5%B0%84)
    // [Unicode Character Database](https://www.unicode.org/Public/UCD/latest/)
    // [Unicode Character Ranges](http://jrgraphix.net/r/Unicode/)
    // [What every JavaScript developer should know about Unicode](https://dmitripavlutin.com/what-every-javascript-developer-should-know-about-unicode/)
    // 所有 CJK 字符
    const UNICODE_CJK_ALL = [
        '\\u1100-\\u11FF', // Hangul Jamo
        // '\\u2600-\\u26FF', // Miscellaneous Symbols
        // '\\u2700-\\u27BF', // Dingbats
        // '\\u2800-\\u28FF', // Braille Patterns
        '\\u2E80-\\u2EFF', // CJK Radicals Supplement
        '\\u2F00-\\u2FDF', // Kangxi Radicals
        '\\u2FF0-\\u2FFF', // Ideographic Description Characters
        '\\u3000-\\u303F', // CJK Symbols and Punctuation
        '\\u3040-\\u309F', // Hiragana
        '\\u30A0-\\u30FF', // Katakana
        '\\u3100-\\u312F', // Bopomofo
        '\\u3130-\\u318F', // Hangul Compatibility Jamo
        '\\u3190-\\u319F', // Kanbun
        '\\u31A0-\\u31BF', // Bopomofo Extended
        '\\u31F0-\\u31FF', // Katakana Phonetic Extensions
        '\\u3200-\\u32FF', // Enclosed CJK Letters and Months
        '\\u3300-\\u33FF', // CJK Compatibility
        '\\u3400-\\u4DBF', // CJK Unified Ideographs Extension A
        '\\u4DC0-\\u4DFF', // Yijing Hexagram Symbols
        '\\u4E00-\\u9FFF', // CJK Unified Ideographs
        '\\uA000-\\uA48F', // Yi Syllables
        '\\uA490-\\uA4CF', // Yi Radicals
        '\\uAC00-\\uD7AF', // Hangul Syllables
        // '\\uD800-\\uDB7F', // High Surrogates
        // '\\uDB80-\\uDBFF', // High Private Use Surrogates
        // '\\uDC00-\\uDFFF', // Low Surrogates
        // '\\uE000-\\uF8FF', // Private Use Area
        '\\uF900-\\uFAFF', // CJK Compatibility Ideograph
        // '\\uFB00-\\uFB4F', // Alphabetic Presentation Forms
        // '\\uFB50-\\uFDFF', // Arabic Presentation Forms-A
        // '\\uFE00-\\uFE0F', // Variation Selectors
        // '\\uFE20-\\uFE2F', // Combining Half Marks
        '\\uFE30-\\uFE4F', // CJK Compatibility Forms
        // '\\uFE50-\\uFE6F', // Small Form Variants
        // '\\uFE70-\\uFEFF', // Arabic Presentation Forms-B
        '\\uFF00-\\uFFEF', // Halfwidth and Fullwidth Forms
        // '\\uFFF0-\\uFFFF', // Specials
        // '\\u{10000}-\\u{1007F}', // Linear B Syllabary
        // '\\u{10080}-\\u{100FF}', // Linear B Ideograms
        // '\\u{10100}-\\u{1013F}', // Aegean Numbers
        // '\\u{10300}-\\u{1032F}', // Old Italic
        // '\\u{10330}-\\u{1034F}', // Gothic
        // '\\u{10380}-\\u{1039F}', // Ugaritic
        // '\\u{10400}-\\u{1044F}', // Deseret
        // '\\u{10450}-\\u{1047F}', // Shavian
        // '\\u{10480}-\\u{104AF}', // Osmanya
        // '\\u{10800}-\\u{1083F}', // Cypriot Syllabary
        // '\\u{1D000}-\\u{1D0FF}', // Byzantine Musical Symbols
        // '\\u{1D100}-\\u{1D1FF}', // Musical Symbols
        '\\u{1D300}-\\u{1D35F}', // Tai Xuan Jing Symbols
        // '\\u{1D400}-\\u{1D7FF}', // Mathematical Alphanumeric Symbols
        '\\u{20000}-\\u{2A6DF}', // CJK Unified Ideographs Extension B
        '\\u{2A700}-\\u{2B73F}', // CJK Unified Ideographs Extension C
        '\\u{2B740}-\\u{2B81F}', // CJK Unified Ideographs Extension D
        '\\u{2B820}-\\u{2CEAF}', // CJK Unified Ideographs Extension E
        '\\u{2CEB0}-\\u{2EBEF}', // CJK Unified Ideographs Extension F
        '\\u{2F800}-\\u{2FA1F}', // CJK Compatibility Ideographs Supplement
    ];

    // 汉字（不包括日文平假名、片假名、片假名注音扩展、韩文 Jamo） + 标点符号
    const UNICODE_CJK_HAN = [
        '\\u3400-\\u4DBF', // CJK Unified Ideographs Extension A
        '\\u4E00-\\u9FFF', // CJK Unified Ideographs
        '\\uF900-\\uFAFF', // CJK Compatibility Ideograph
        '\\uD840-\\uD87A', // High Surrogates
        '\\uD880-\\uD884', // High Surrogates
        '\\uDC00-\\uDFFF', // Low Surrogates
    ];

    // 日文平假名、片假名、片假名注音扩展
    const UNICODE_CJK_JP = [
        '\\u3040-\\u309F', // Hiragana
        '\\u30A0-\\u30FF', // Katakana
        '\\uDC00-\\uDC01',
        '\\u31F0-\\u31FF', // Katakana Phonetic Extensions
        '\\uFF66-\\uFF9F',
        '\\uD82C',
    ];

    // 韩文 Jamo
    const UNICODE_CJK_KR = [
        '\\u1100-\\u11FF', // Hangul Jamo
        '\\u3130-\\u318F', // Hangul Compatibility Jamo
        '\\uA960-\\uA97C',
        '\\uAC00-\\uD7A3',
        '\\uD7B0-\\uD7FB',
        '\\uFFA1-\\uFFDC'
    ];

    // CJK 符号、CJK 扩展等
    const UNICODE_CJK_SYMBOLS_EXT = [
        '\\u2E80-\\u2EFF', // CJK Radicals Supplement
        '\\u2F00-\\u2FDF', // CJK Radicals Supplement
        '\\u2FF0-\\u2FFF', // CJK Radicals Supplement
        '\\u3100-\\u312F', // Bopomofo
        '\\u31A0-\\u31BF', // Bopomofo Extended
        '\\u31C0-\\u31EF', // 
        '\\u3300-\\u33FF', // CJK Compatibility
        '\\uFE30-\\uFE4F', // CJK Compatibility Forms
        '\\uFF00-\\uFFEF', // Halfwidth and Fullwidth Forms
        '\\u{1D300}-\\u{1D35F}', // Tai Xuan Jing Symbols
        '\\u{20000}-\\u{2A6DF}', // CJK Unified Ideographs Extension B
        '\\u{2A700}-\\u{2B73F}', // CJK Unified Ideographs Extension C
        '\\u{2B740}-\\u{2B81F}', // CJK Unified Ideographs Extension D
        '\\u{2B820}-\\u{2CEAF}', // CJK Unified Ideographs Extension E
        '\\u{2CEB0}-\\u{2EBEF}', // CJK Unified Ideographs Extension F
        '\\u{2F800}-\\u{2FA1F}', // CJK Compatibility Ideographs Supplement
        '\\u3007', // IDEOGRAPHIC NUMBER ZERO
    ];

    // CJK 所有字符
    // const CJK_RANGE_ALL = UNICODE_CJK_ALL.join(',').replaceAll('\\u','U+').replaceAll('-U+','-').replaceAll('{','').replaceAll('}','');

    // 中日韩汉字（包括日文平假名、片假名、片假名注音扩展、韩文 Jamo） + 标点符号
    // const CJK_RANGE_HAN = "U+3400-4DBF,U+4E00-9FFF,U+F900-FAFF,U+D840-D87A,U+D880-D884,U+DC00-DFFF,U+3040-309F,U+30A0-30FF,U+DC00-DC01,U+31F0-31FF,U+FF66-FF9F,U+D82C,U+1100-11FF,U+3130-318F,U+A960-A97C,U+AC00-D7A3,U+D7B0-D7FB,U+FFA1-FFDC";
    const CJK_RANGE_HAN = '' + 
        UNICODE_CJK_HAN.join(',').replaceAll('\\u','U+').replaceAll('-U+','-').replaceAll('{','').replaceAll('}','') + ',' + 
        UNICODE_CJK_JP.join(',').replaceAll('\\u','U+').replaceAll('-U+','-').replaceAll('{','').replaceAll('}','') + ',' + 
        UNICODE_CJK_KR.join(',').replaceAll('\\u','U+').replaceAll('-U+','-').replaceAll('{','').replaceAll('}','');

    const reWhiteSpace = new RegExp(/\s/);

    // 检查网页内容是否包含 CJK 字符
    // [JavaScript 正则表达式匹配汉字](https://zhuanlan.zhihu.com/p/33335629)
    // [在正则表达式中使用 Unicode 属性转义](https://keqingrong.cn/blog/2020-01-29-regexp-unicode-property-escapes/)
    // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Unicode_Property_Escapes
    // https://www.regular-expressions.info/unicode.html
    function checkCJK() {
        const bodyText = document.body.innerText;
        const reCJK = new RegExp(`[${UNICODE_CJK_ALL.join('')}]`, 'u');

        // const hasCJK = bodyText.match(reCJK);
        // return Boolean(hasCJK);

        const matchCount = (bodyText.match(reCJK) || []).length;
        return matchCount > 0 ? true : false;
    }

    // 如果 html.lang 没有设置，根据网页内容包含的 CJK 字符数量判断所属地区（不精确，简繁体、CJK 汉字的码点有重叠）
    function checkCJKLocale() {
        const bodyText = document.body.innerText;

        // 汉字（不包括日文平假名、片假名、片假名注音扩展、韩文 Jamo）
        // [transpiler ES2015 Unicode regular expressions](https://github.com/mathiasbynens/regexpu)
        // npm install regexpu -g
        // echo 'const reExpHAN = /[\p{Unified_Ideograph}]/u;' | regexpu
        const reExpHAN = /[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]|[\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872\uD874-\uD879\uD880-\uD883][\uDC00-\uDFFF]|\uD869[\uDC00-\uDEDF\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF38\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|\uD873[\uDC00-\uDEA1\uDEB0-\uDFFF]|\uD87A[\uDC00-\uDFE0]|\uD884[\uDC00-\uDF4A]/;

        // [regular expression for matching CJK text](https://github.com/ikatyang/cjk-regex)
        // [中文繁简体对照表](https://zh.wikipedia.org/zh-cn/Wikipedia:%E4%B8%AD%E6%96%87%E7%B9%81%E7%AE%80%E4%BD%93%E5%AF%B9%E7%85%A7%E8%A1%A8)
        // [五笔字型 Unicode CJK 超大字符集编码数据库](https://github.com/CNMan/UnicodeCJK-WuBi)
        // [功能全面的汉字工具库(拼音 笔画 偏旁 成语 语音 可视化等)](https://github.com/theajack/cnchar)
        const reExpEmoji = /\p{Emoji_Modifier_Base}\p{Emoji_Modifier}?|\p{Emoji_Presentation}|\p{Emoji}\uFE0F/;
        const reEmoji = new RegExp(reExpEmoji, 'gu');

        // const reExpCJK = /[\p{Ideographic}\p{Unified_Ideograph}]/;
        // const reExpCJK = /[\p{Script=Han}\p{Script_Extensions=Han}]/;

        // const reCJK = new RegExp(reExpCJK, 'gu');
        // const reCJK = new RegExp(`[${UNICODE_CJK_ALL.slice(0, 23).join('')}]`, 'gu');
        const reCJK = new RegExp(`[${UNICODE_CJK_ALL.join('')}]`, 'gu');

        const reHAN = new RegExp(reExpHAN, 'gu');
        const reHAN_PUN = new RegExp(`[${UNICODE_CJK_HAN.join('')}]`, 'gu');
        const reHAN_SYMBOL = new RegExp(`[${UNICODE_CJK_HAN.join('')}${UNICODE_CJK_SYMBOLS_EXT.join('')}]`, 'gu');

        const reSYMBOL_EXT = new RegExp(`[${UNICODE_CJK_SYMBOLS_EXT.join('')}]`, 'gu');

        const reSC = new RegExp(`[${CHINESE_UNICODE_RANGE_SIMPLFIED}]`, 'gu');
        const reTC = new RegExp(`[${CHINESE_UNICODE_RANGE_TRADITIONAL}]`, 'gu');

        const reJP = new RegExp(`[${UNICODE_CJK_JP.join('')}]`, 'gu');
        const reKR = new RegExp(`[${UNICODE_CJK_KR.join('')}]`, 'gu');

        const matchEmoji = (bodyText.match(reEmoji) || []).length;
        const matchCJK = (bodyText.match(reCJK) || []).length;
        const matchHAN = (bodyText.match(reHAN) || []).length;
        const matchHAN_PUN = (bodyText.match(reHAN_PUN) || []).length;
        const matchHAN_SYMBOL = (bodyText.match(reHAN_SYMBOL) || []).length;
        const match_SYMBOL_EXT = (bodyText.match(reSYMBOL_EXT) || []).length;
        const matchSC = (bodyText.match(reSC) || []).length;
        const matchTC = (bodyText.match(reTC) || []).length;
        const matchJP = (bodyText.match(reJP) || []).length;
        const matchKR = (bodyText.match(reKR) || []).length;

        const matchAll = `Emoji: ${matchEmoji} CJK: ${matchCJK} Han: ${matchHAN} Han+Punctuation: ${matchHAN_PUN} Han+Symbol: ${matchHAN_SYMBOL} Symbol+CJK Extension: ${match_SYMBOL_EXT} SC: ${matchSC} TC: ${matchTC} JP: ${matchJP} KR: ${matchKR}`;
        console.log(matchAll);

        let matchLang = 'zh-CN';
        if (matchTC > 0 && matchTC > matchSC) matchLang = 'zh-TW';
        if (matchJP > 0 && matchTC > matchSC) matchLang = 'ja';
        if (matchKR > 0 && matchTC > matchSC) matchLang = 'kr';

        return matchLang;
    }

    // 16 进制转 10 进制
    const hexToDecimal = hex => parseInt(hex, 16);

    // 打印 UNICODE 范围数组内的所有字符，如：
    // printUnicodeRangeCharacters(['\\u3300-\\u33FF','\\uFE30-\\uFE4F']);
    function printUnicodeRangeCharacters(unicodeRange) {
        unicodeRange.forEach(function(range) {
            range = range.replaceAll('\\u','').replaceAll('{','').replaceAll('}','');
            let outputStr = `${range}:`;
    
            if (range.includes('-')) {
                for(let i = hexToDecimal(range.split('-')[0]); i <= hexToDecimal(range.split('-').pop()); i++) {
                    outputStr = outputStr + ' ' + String.fromCodePoint(i);
                }
            } else {
                outputStr = outputStr + ' ' + String.fromCodePoint(hexToDecimal(range));
            }
    
            console.log(outputStr);
        })
    }

    // 根据 html.lang 设置默认字体
    // [CSS unicode-range 特定字符使用 font-face 自定义字体](https://www.zhangxinxu.com/wordpress/2016/11/css-unicode-range-character-font-face/)
    // [前端如何实现中文、英文、数字使用不同字体](https://keqingrong.cn/blog/2019-11-30-different-fonts-in-different-locales/)
    // [显示特定 charcode 范围内的字符内容实例页面](https://www.zhangxinxu.com/study/201611/show-character-by-charcode.php?range=4E00-9FA5)
    // [Fix CJK fonts/punctuations for Chrome and Firefox](https://github.com/stecue/fixcjk)
    // [emoji-unicode-range demo](https://bl.ocks.org/nolanlawson/61e10fab056e75b02b5c6a0a223a5ad7)
    // [mozilla twemoji-color emoji demo](https://bl.ocks.org/nolanlawson/6b6b026804aafa1e583ae7a9d7c7c32f)
    // [what can my font do?](https://wakamaifondue.com/beta/)
    function htmlFontStyle() {
        let html, lang, body, fontfamily;

        html = document.getElementsByTagName('html')[0];
        lang = html.getAttribute('lang');

        if (!lang) {
            if (checkCJK()) {
                lang = 'zh-CN';
            } else {
                lang = 'en';
            }
        }

        body = document.getElementsByTagName('body')[0];
        fontfamily = getComputedStyle(body).getPropertyValue('font-family');
        fontfamily = fontfamily.replaceAll('"','').replaceAll("'",'').replaceAll(', ',',');

        let bodyFirstFont = '';
        if (fontfamily) {
            // 如果 body 设置的第一个字体不在替换字体列表里面，表示网页使用了专用字体，则把该字体放在默认字体的首位
            let bodyFonts = fontfamily.split(",");
            if (!FONTS_REPLACE.includes(bodyFonts[0].trim())) {
                bodyFirstFont = bodyFonts[0].trim();
            }
        }

        switch (lang.toLowerCase()) {
            case 'cn':
            case 'zh-cn':
            case 'zh_cn':
            case 'zh-hans':
            case 'zh-hans-cn':
            case 'zh-hans-hk':
            case 'zh-hans-mo':
            case 'zh-hans-tw':
            case 'zh-sg':
            case 'zh_sg':
            case 'zh-hans-sg':
            case 'zh-my':
            case 'zh_my':
            case 'zh-hans-my':
                FONT_LOCALE = 'SC';
                FONT_CJK = FONT_CJK_SC;
                FONT_MONO_CJK = FONT_MONO_CJK_SC;
                break;
            case 'tw':
            case 'zh-tw':
            case 'zh_tw':
            case 'zh-hant':
            case 'zh-hant-cn':
            case 'zh-hant-tw':
            case 'zh-hant-sg':
            case 'zh-hant-my':
                FONT_LOCALE = 'TC';
                FONT_CJK = FONT_CJK_TC;
                FONT_MONO_CJK = FONT_MONO_CJK_TC;
                break;
            case 'hk':
            case 'zh-hk':
            case 'zh_hk':
            case 'zh-hant-hk':
            case 'zh-mo':
            case 'zh_mo':
            case 'zh-hant-mo':
                FONT_LOCALE = 'HK';
                FONT_CJK = FONT_CJK_HK;
                FONT_MONO_CJK = FONT_MONO_CJK_HK;
                break;
            case 'ja':
                FONT_LOCALE = 'JP';
                FONT_CJK = FONT_CJK_JP;
                FONT_MONO_CJK = FONT_MONO_CJK_JP;
                break;
            case 'ko':
                FONT_LOCALE = 'KR';
                FONT_CJK = FONT_CJK_KR;
                FONT_MONO_CJK = FONT_MONO_CJK_KR;
                break;
            default:
                FONT_LOCALE = 'SC';
                FONT_CJK = FONT_CJK_SC;
                FONT_MONO_CJK = FONT_MONO_CJK_SC;
        }

        let htmlFontFamily, monoFontFamily;

        htmlFontFamily = reWhiteSpace.test(FONT_DEFAULT) ? "'" + FONT_DEFAULT + "'" : FONT_DEFAULT;
        htmlFontFamily += ", " + (reWhiteSpace.test(FONT_CJK) ? "'" + FONT_CJK + "'" : FONT_CJK);
        htmlFontFamily += ", " + (reWhiteSpace.test(FONT_EMOJI) ? "'" + FONT_EMOJI + "'" : FONT_EMOJI);
        htmlFontFamily += ", " + (reWhiteSpace.test(FONT_FALLBACK) ? "'" + FONT_FALLBACK + "'" : FONT_FALLBACK);
        if (bodyFirstFont) {
            if (reWhiteSpace.test(bodyFirstFont)) {
                htmlFontFamily = bodyFirstFont + ", " + htmlFontFamily;
            } else {
                htmlFontFamily = "'" + bodyFirstFont + "', " + htmlFontFamily;
            }
        }

        monoFontFamily = reWhiteSpace.test(FONT_MONO) ? "'" + FONT_MONO + "'" : FONT_MONO;
        monoFontFamily += ", " + (reWhiteSpace.test(FONT_MONO_CJK) ? "'" + FONT_MONO_CJK + "'" : FONT_MONO_CJK);
        monoFontFamily += ", " + (reWhiteSpace.test(FONT_EMOJI) ? "'" + FONT_EMOJI + "'" : FONT_EMOJI);
        monoFontFamily += ", " + (reWhiteSpace.test(FONT_FALLBACK) ? "'" + FONT_FALLBACK + "'" : FONT_FALLBACK);


        //设置 html 默认字体
        html.style.setProperty("font-family", htmlFontFamily);

        // 设置 body 默认字体为 inherit
        // body.style.setProperty("font-family", "inherit");
        // body.setAttribute('style','font-weight:400 !important');

        // 字体 CSS 配置
        let cssBody, cssFontFaceDefault, cssFontFaceCJK, cssFontFaceMono;

        // cssBody = `body { -webkit-font-smoothing: subpixel-antialiased !important; -moz-osx-font-smoothing: grayscale !important; text-rendering: optimizeLegibility !important; font-family: inherit; }`;
        // cssFontFaceDefault = `@font-face { font-family: '${FONT_CJK}'; src: local('${FONT_DEFAULT}'); }`;
        // cssFontFaceCJK = `@font-face { font-family: '${FONT_CJK}'; src: local('${FONT_CJK}'); unicode-range: ${CJK_RANGE_HAN}; }`;
        // cssFontFaceMono = `pre,code,kbd,samp { font-family: ${monoFontFamily} !important; }`;
        // GM_addStyle(cssBody);
        // GM_addStyle(cssFontFaceDefault);
        // GM_addStyle(cssFontFaceCJK);
        // GM_addStyle(cssFontFaceMono);

        // https://developer.mozilla.org/en-US/docs/Web/CSS/font-variant-east-asian
        // body { font-variant-east-asian: simplified; }
        // body { font-variant-east-asian: traditional; }
        cssBody = `
            body {
                -webkit-font-smoothing: subpixel-antialiased !important;
                -moz-osx-font-smoothing: grayscale !important;
                text-rendering: optimizeLegibility !important;
                font-family: inherit;
            }`;

        cssFontFaceDefault = `
            @font-face {
                font-family: '${FONT_CJK}';
                src: local('${FONT_DEFAULT}');
            }`;

        cssFontFaceCJK = `
            @font-face {
                font-family: '${FONT_CJK}';
                src: local('${FONT_CJK}');
                unicode-range: ${CJK_RANGE_HAN};
            }`;

        cssFontFaceMono = `
            pre,code,kbd,samp {
                font-family: ${monoFontFamily} !important;
            }`;

        let cssStyle = `${cssBody}\n${cssFontFaceDefault}\n${cssFontFaceCJK}\n${cssFontFaceMono}`;
        cssStyle = cssStyle.replaceAll('            ','');

        //with jquery
        // $('pre,code,kbd,samp').css('cssText', `font-family: ${monoFontFamily} !important;`);
        // switch (siteHost) {
        //     case 'github.com':
        //         $('.h1, .h2, .h3, .h4, .h5, .h6, p, a').css('cssText', 'font-weight:400 !important');
        //         $('.text-bold').css('cssText', 'font-weight:400 !important');
        //         break;
        //     case 'member.bilibili.com':
        //         $('#app *').css('cssText', 'font-weight:400 !important');
        //         break;
        //     default:
        // }

        return cssStyle;
    }

    // 在汉字与拉丁字母间添加空格
    // https://github.com/mastermay/text-autospace.js/blob/master/text-autospace.js
    function LatinCJKSpaceStyle() {
        let html = document.getElementsByTagName('html')[0];
        html.classList.add('han-la');

        let cssStyle = `
            html.han-la hanla:after {
                content: " ";
                display: inline;
                font-family: '${FONT_DEFAULT}';
                font-size: 0.89em;
            }

            html.han-la code hanla,
            html.han-la pre hanla,
            html.han-la kbd hanla,
            html.han-la samp hanla {
                display: none;
            }

            html.han-la ol > hanla,
            html.han-la ul > hanla {
                display: none;
            }
            `;

        cssStyle = cssStyle.replaceAll('            ','');

        return cssStyle;
    }

    // [findAndReplaceDOMText](https://github.com/padolsey/findAndReplaceDOMText)
    function addSpaceBetweenLatinCJK() {
        $('body').each(function() {
            // let hanzi = `[${UNICODE_CJK_ALL.join('')}]`,
            // let hanzi = '[\u2E80-\u2FFF\u31C0-\u31EF\u3300-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF\uFE30-\uFE4F]',
            let hanzi = '[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]|[\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872\uD874-\uD879\uD880-\uD883][\uDC00-\uDFFF]|\uD869[\uDC00-\uDEDF\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF38\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|\uD873[\uDC00-\uDEA1\uDEB0-\uDFFF]|\uD87A[\uDC00-\uDFE0]|\uD884[\uDC00-\uDF4A]',
                punc = {
                    base: "[@&=_\\$%\\^\\*-\\+/]",
                    open: "[\\(\\[\\{<‘“]",
                    close: "[,\\.\\?!:\\)\\]\\}>’”]"
                },
                latin = '[A-Za-z0-9\u00C0-\u00FF\u0100-\u017F\u0180-\u024F\u1E00-\u1EFF]' + '|' + punc.base,
                patterns = [
                    '(' + hanzi + ')(' + latin + '|' + punc.open + ')',
                    '(' + latin + '|' + punc.close + ')(' + hanzi + ')'
                ];
                // patterns = [
                //     '/(' + hanzi + ')(' + latin + '|' + punc.open + ')/ig',
                //     '/(' + latin + '|' + punc.close + ')(' + hanzi + ')/ig'
                // ];

            patterns.forEach(function(exp) {
                const reFind = new RegExp(exp,'gui');
                findAndReplaceDOMText(this, {
                    // find: eval(exp),
                    find: reFind,
                    replace: '$1<hanla>$2',
                    filterElements: function(el) {
                        var name = el.nodeName.toLowerCase(),
                            classes = (el.nodeType == 1) ? el.getAttribute('class') : '',
                            charized = (classes && classes.match(/han-js-charized/) != null) ? true : false;
        
                        return name !== 'style' && name !== 'script' && !charized;
                    }
                })
            }, this);

            findAndReplaceDOMText(this, {
                find: '<hanla>',
                replace: function() {
                    return document.createElement('hanla')
                }
            });

            this.normalize();

            $('* > hanla:first-child').parent().each(function() {
                if (this.firstChild.nodeType == 1) {
                    $(this).before($('<hanla/>'));
                    $(this).find('hanla:first-child').remove();
                }
            });
        })
    }

    // 移除外链重定向
    function fixLinkRedirect() {
        document.querySelectorAll('a').forEach( node => {
            if (node.href.indexOf("=http") > 0) {
                node.href = decodeURIComponent(node.href.slice(node.href.indexOf("=http") + 1));
            }

            if (node.href.indexOf("target") > 0) {
                node.href = decodeURIComponent(node.href.slice(node.href.indexOf("target") + 7));
            }
        });
    }

    // 主程序
    // 设置 CSS 规则
    let cssFontStyle, cssSpaceStyle, cssInnerHTML

    cssFontStyle = htmlFontStyle();
    cssSpaceStyle = LatinCJKSpaceStyle();

    if (cssFontStyle && cssSpaceStyle) {
        cssInnerHTML = `${cssFontStyle}\n${cssSpaceStyle}`;
    } else {
        if (cssFontStyle) cssInnerHTML = `${cssFontStyle}`;
        if (cssSpaceStyle) cssInnerHTML = `${cssSpaceStyle}`;
    }
    GM_addStyleInnerHTML(cssInnerHTML);

    //在汉字与拉丁字母间添加空格
    addSpaceBetweenLatinCJK();

    // 移除外链重定向
    // fixLinkRedirect();
})();
