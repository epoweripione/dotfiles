// ==UserScript==
// @name              CJK Text Optimization
// @name:zh-CN        中日韩文字优化
// @namespace         https://github.com/epoweripione/dotfiles
// @version           1.0.0
// @description       Set font-family by html.lang; add spaces between CJK characters and Latin letters
// @description:zh-cn 根据网页 html.lang 设置默认字体；自动在汉字与英文字符间添加空格等
// @author            epoweripione
// @license           MIT
// @match             http://*/*
// @match             https://*/*
// @require           https://cdn.jsdelivr.net/npm/jquery/dist/jquery.min.js
// @require           https://cdn.jsdelivr.net/npm/findandreplacedomtext/src/findAndReplaceDOMText.min.js
// @require           https://cdn.jsdelivr.net/npm/darkreader/darkreader.min.js
// @require           https://cdn.jsdelivr.net/npm/darkmode-js/lib/darkmode-js.min.js
// @require           https://cdn.jsdelivr.net/npm/file-saver/dist/FileSaver.min.js
// @require           https://openuserjs.org/src/libs/sizzle/GM_config.js
// @grant             GM_getValue
// @grant             GM_setValue
// @grant             GM_xmlhttpRequest
// @grant             GM_registerMenuCommand
// @grant             GM_unregisterMenuCommand
// ==/UserScript==

// [Console Importer](https://chrome.google.com/webstore/detail/console-importer/hgajpakhafplebkdljleajgbpdmplhie)
// $i('https://cdn.jsdelivr.net/npm/jquery/dist/jquery.min.js');
// $i('https://cdn.jsdelivr.net/npm/findandreplacedomtext/src/findAndReplaceDOMText.min.js');
// $i('https://cdn.jsdelivr.net/npm/chinese-characters-codepoints-converter/index.js');

// Unicode Code Points
// '©'.codePointAt(0).toString(16);
// '😍'.codePointAt(0).toString(16);
// String.fromCodePoint(128525); // '😍'
// String.fromCodePoint(0x1f60d); // '😍'

'use strict';

const browserLanguage = navigator.language;
const siteOrigin = location.origin;
const siteDomain = location.host;
const siteHref = location.href;
const siteTitle = document.title;

const cssStyleID = 'CJK_Text_Optimize_TamperMonkey';

const FONT_DEFAULT = 'Noto Sans'; // 默认字体
const FONT_EMOJI = 'emoji'; // Emoji 字体
const FONT_FALLBACK = 'sans-serif'; // 备用字体
const FONT_MONO = 'JetBrainsMono Nerd Font'; // 等宽字体

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

const DARK_MODE = 'DarkReader'; // 暗黑模式：DarkReader, Darkmodejs

// 地区、CJK 字体、CJK 等宽字体
let FONT_LOCALE, FONT_CJK, FONT_MONO_CJK;
// html 字体族、等宽字体族
let htmlFontFamily, monoFontFamily;
// CJK 字体样式、汉字合英文字符空格样式、附加到网页内的样式
let cssFontStyle, cssSpaceStyle, cssAddStyle;

// 等待元素出现再执行的匹配规则：链接正则,获取元素表达式
let waitElementRules = [
    ['http[s]\:\/\/juejin\.cn\/post\/', '.markdown-body'],
];

// 删除不可见的混淆字符
let obfuscateCharactersElements = [
    'span[style="display:none"]',
    'font[color="#e7f2fA"]',
    '.jammer',
];

// 代码块优化
let codeBlockElements = [
    '.copy-code-btn',
    '.crayon-num',
    '.hljs.hljs-line-numbers',
    '.hljs-ln-numbers',
    '.linenum.hljs-number',
    '.pre-numbering',
];

// TamperMonkey 选项菜单
// 菜单编码、启用标识、禁用标识、域名列表、命令类型
// 命令类型：enable - 默认启用（域名列表=禁用列表）、disable - 默认禁用（域名列表=启用列表）、direct - 直接执行命令
let registeredMenuCommand = [];
let menuCommand = [
    ['menu_CJK_Font', '✅ 已启用 - CJK 字体替换', '❌ 已禁用 - CJK 字体替换', [], 'disable'],
    ['menu_CJK_Latin_Space', '✅ 已启用 - 在汉字与英文字符间添加空格', '❌ 已禁用 - 在汉字与英文字符间添加空格', [], 'enable'],
    ['menu_Pretty_Code_Block', '✅ 已启用 - 优化代码块', '❌ 已禁用 - 优化代码块', [], 'enable'],
    ['menu_Obfuscate_Character', '✅ 已启用 - 删除不可见的混淆字符', '❌ 已禁用 - 删除不可见的混淆字符', [], 'disable'],
    // ['menu_Darkmode', '✅ 已启用 - 暗黑模式', '❌ 已禁用 - 暗黑模式', [], 'disable'],
    ['menu_Link_Redirect', '🔗 - 移除外链重定向', '', '', 'direct'],
];

// 替换字体
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
    '\\u31C0-\\u31EF', // CJK Strokes
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

// 空白字符正则
const reWhiteSpace = new RegExp(/\s/);

// --------------------------函数及功能定义--------------------------
// 语言
const getLang = () => navigator.language || navigator.browserLanguage || (navigator.languages || ["en"])[0];

// 将当前时间转为 YYYYMMDD-HH24MISS 的形式
function getDateTimeString() {
    const date = new Date();
    const year = date.getFullYear();
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day =`${date.getDate()}`.padStart(2, '0');

    const hour =`${date.getHours()}`.padStart(2, '0');
    const minute =`${date.getMinutes()}`.padStart(2, '0');
    const second =`${date.getSeconds()}`.padStart(2, '0');

    return `${year}${month}${day}-${hour}${minute}${second}`
}

// TamperMonkey 选项菜单
// 初始化选项菜单存储
for (let id in menuCommand) {
    if (!GM_getValue(menuCommand[id][0])) {
        GM_setValue(menuCommand[id][0], menuCommand[id][3]);
    }
}

// 根据菜单名称获取菜单 ID
function getMenuIdByName(name) {
    for (let id in menuCommand) {
        if (menuCommand[id][0] == name) return id;
    }

    return -1;
}

// 根据当前网站域名是否在存储的域名列表内来启用/禁用菜单项
function currentDomainOperation(menuCode, menuType, operation) {
    switch (operation) {
        case 'check':
            return checkExists();
        case 'add':
            if (menuType != 'direct') addToList();
            break;
        case 'delete':
            if (menuType != 'direct') deleteFromList();
            break;
    }

    function checkExists() {
        return GM_getValue(menuCode).includes(siteDomain);
    }

    function addToList() {
        if (checkExists()) return;

        let list = GM_getValue(menuCode);
        list.push(siteDomain);
        GM_setValue(menuCode, list);
        location.reload();
    }

    function deleteFromList() {
        if (!checkExists()) return;

        let list = GM_getValue(menuCode),
            index = list.indexOf(siteDomain);
        list.splice(index, 1);
        GM_setValue(menuCode, list);
        location.reload();
    }
}

// 注册 TamperMonkey 菜单
function registerMenuCommand() {
    for (let menu in registeredMenuCommand) {
        GM_unregisterMenuCommand(menu);
    }

    for (let id in menuCommand) {
        menuCommand[id][3] = GM_getValue(menuCommand[id][0]);
        switch (menuCommand[id][4]) {
            case 'enable':
                if (currentDomainOperation(menuCommand[id][0], menuCommand[id][4], 'check')) {
                    // 当前网站域名在禁用列表中，则点击菜单项目=启用
                    registeredMenuCommand.push(GM_registerMenuCommand(`${menuCommand[id][2]}`,
                        function(){currentDomainOperation(menuCommand[id][0], menuCommand[id][4], 'delete')})
                    );
                }
                else {
                    // 当前网站域名不在禁用列表中，则点击菜单项目=禁用
                    registeredMenuCommand.push(GM_registerMenuCommand(`${menuCommand[id][1]}`,
                        function(){currentDomainOperation(menuCommand[id][0], menuCommand[id][4], 'add')})
                    );
                }
                break;
            case 'disable':
                if (currentDomainOperation(menuCommand[id][0], menuCommand[id][4], 'check')) {
                    // 当前网站域名在启用列表中，则点击菜单项目=禁用
                    registeredMenuCommand.push(GM_registerMenuCommand(`${menuCommand[id][1]}`,
                        function(){currentDomainOperation(menuCommand[id][0], menuCommand[id][4], 'delete')})
                    );
                }
                else {
                    // 当前网站域名不在启用列表中，则点击菜单项目=启用
                    registeredMenuCommand.push(GM_registerMenuCommand(`${menuCommand[id][2]}`,
                        function(){currentDomainOperation(menuCommand[id][0], menuCommand[id][4], 'add')})
                    );
                }
                break;
            case 'direct':
                switch (menuCommand[id][0]) {
                    case 'menu_Link_Redirect':
                        registeredMenuCommand.push(GM_registerMenuCommand(`${menuCommand[id][1]}`,
                                function(){removeLinkRedirect()})
                            );
                        break;
                    case 'menu_Inspector_Screenshot':
                        registeredMenuCommand.push(GM_registerMenuCommand(`${menuCommand[id][1]}`,
                                function(){startElementInspector(elementInspectorOptions, `${menuCommand[id][2]}`)})
                            );
                        break;
                    case 'menu_Inspector_Markdown':
                        registeredMenuCommand.push(GM_registerMenuCommand(`${menuCommand[id][1]}`,
                                function(){startElementInspector(elementInspectorOptions, `${menuCommand[id][2]}`)})
                            );
                        break;
                }
                break;
        }
    }
}

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
function CJKFontStyle() {
    let html, lang, body, fontfamily;

    html = document.getElementsByTagName('html')[0];
    lang = html.getAttribute('lang');

    if (!lang) {
        if (checkCJK()) {
            // lang = checkCJKLocale();
            lang = 'zh-CN';
        } else {
            lang = getLang();
        }
    }
    if (!lang) lang = 'en';

    body = document.getElementsByTagName('body')[0];
    fontfamily = getComputedStyle(body).getPropertyValue('font-family');
    fontfamily = fontfamily.replaceAll('"','').replaceAll("'",'').replaceAll(', ',',');

    let bodyFirstFont = '';
    if (fontfamily) {
        // 如果 body 设置的第一个字体不在替换字体列表里面，表示网页使用了专用字体，则把该字体放在默认字体的首位
        const bodyFonts = fontfamily.split(",");
        const fontFilter = FONTS_REPLACE.filter((str) => str.toLowerCase() == bodyFonts[0].trim().toLowerCase());
        // if (!FONTS_REPLACE.includes(bodyFonts[0].trim())) {
        if (fontFilter.length == 0) {
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

// 在汉字与英文字符间添加空格
// https://github.com/mastermay/text-autospace.js/blob/master/text-autospace.js
function LatinCJKSpaceStyle() {
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
    $('hanla').remove();

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
            const reFind = new RegExp(exp, 'gui');
            findAndReplaceDOMText(this, {
                // find: eval(exp),
                find: reFind,
                replace: '$1<hanla>$2',
                filterElements: function(el) {
                    let name = el.nodeName.toLowerCase(),
                        classes = (el.nodeType == 1) ? el.getAttribute('class') : '',
                        charized = (classes && classes.match(/han-js-charized/) != null) ? true : false;
                    return name !== 'style' && name !== 'script' && !charized;
                }
            })
        }, this);

        findAndReplaceDOMText(this, {
            find: '<hanla>',
            replace: function() {
                return document.createElement('hanla');
            }
        });

        this.normalize();

        $('* > hanla:first-child').parent().each(function() {
            // An Element node like <p> or <div>
            if (this.firstChild.nodeType == 1) {
                // $(this).before($('<hanla/>'));
                $(this).find('hanla:first-child').remove();
            }
        });
    })
}

// 移除外链重定向
function removeLinkRedirect() {
    document.querySelectorAll('a').forEach( node => {
        if (node.href.indexOf("=http") > 0) {
            node.href = decodeURIComponent(node.href.slice(node.href.indexOf("=http") + 1));
        }

        if (node.href.indexOf("target") > 0) {
            node.href = decodeURIComponent(node.href.slice(node.href.indexOf("target") + 7));
        }
    });
}

// 删除元素
const removeElement = (el) => document.querySelectorAll(el).forEach(node => node.remove());

// 删除不可见的混淆字符
function removeHideObfuscateCharacters() {
    obfuscateCharactersElements.forEach((el) => removeElement(el));
}

// 代码块优化
function prettyCodeBlock() {
    codeBlockElements.forEach((el) => removeElement(el));
}

// https://stackoverflow.com/questions/494143/creating-a-new-dom-element-from-an-html-string-using-built-in-dom-methods-or-pro
// single element
// td = htmlToElement('<td>foo</td>')
// div = htmlToElement('<div><span>nested</span> <span>stuff</span></div>')
function htmlToElement(html) {
    const template = document.createElement('template');
    template.innerHTML = html.trim();
    return template.content.firstChild;
}

// NodeList[]: any number of sibling elements
// rows = htmlToNodeList('<tr><td>foo</td></tr><tr><td>bar</td></tr>')
function htmlToNodeList(html) {
    const template = document.createElement('template');
    template.innerHTML = html.trim();
    return template.content.childNodes;
}

// 等待指定元素出现然后执行指定函数
// https://gist.github.com/BrockA/2625891
// https://gist.github.com/chrisjhoughton/7890303
// waitForKeyElements(element, max, timeout, callback)
// myFunc = () => { //Do something }
// waitForKeyElements("element", 30, 500, myFunc);
const waitForKeyElements = (e, m, t, c) => {
    let i = +m,
    loop = () => { $(e).length ? c() : --i && setTimeout(() => { loop() }, t) };
    loop();
}

// 设置元素的 CSS 样式
const setStylesOnElement = function(styles, element) {
    Object.assign(element.style, styles);
}

// setStyle('myElement', {'fontsize':'12px', 'left':'200px'});
function setStyle(objId, propertyObject) {
    let elem = document.getElementById(objId);
    for (let property in propertyObject)
        elem.style[property] = propertyObject[property];
}

// 根据 CSS 样式设置 HTML 相关属性
function setHtmlProperty() {
    const html = document.getElementsByTagName('html');
    const htmlList = Array.from(html);
    htmlList.forEach(node => {
        //设置 html 默认字体
        if (htmlFontFamily) {
            // node.style.setProperty("font-family", htmlFontFamily);
            node.setAttribute('style',`font-family: ${htmlFontFamily} !important`);
        }

        // 设置汉字与英文字符间添加空格相关的 CSS 样式
        if (cssSpaceStyle) {
            const htmlClasses = Array.from(node.classList);
            // node.classList.remove(...htmlClasses);
            if (!htmlClasses.includes('han-la')) node.classList.add('han-la');
        }
    });

    // 附加新样式到网页内的 head
    if (cssAddStyle) {
        const cssStyle = document.createElement('style');
        cssStyle.id = cssStyleID;
        cssStyle.innerHTML = cssAddStyle;

        const head = document.getElementsByTagName('head');
        const headList = Array.from(head);
        headList.forEach(node => {
            node.appendChild(cssStyle);
        });
    }

    // 设置 body 默认字体为 inherit
    const body = document.getElementsByTagName('body');
    const bodyList = Array.from(body);
    bodyList.forEach(node => {
        // node.style.setProperty("font-family", "inherit");
        node.setAttribute('style','font-family: inherit !important');
    });
}

// https://www.reddit.com/r/GreaseMonkey/comments/87wnsd/create_a_function_that_can_be_triggered_from/
// This function will insert the function you want wrapped by a <script></script> tag on the page.
// You can also just give it the function text directly or the
// url to a script you want to include (If you want to insert Jquery or some
// other library, this function could do that too!
// Say we want this function to be available in the console
// function callMeFromConsole() {console.log('I was written in a greasemonkey script!');}
// We add it to the DOM with a <script></script> tag and we're good to go!
// addDOMScriptNode(null, null, callMeFromConsole);
function addDOMScriptNode(funcText, funcSrcUrl, funcToRun) {
    const scriptNode = document.createElement('script');
    scriptNode.type = 'text/javascript';

    if (funcText) {
        scriptNode.textContent = funcText;
    } else if (funcSrcUrl) {
        scriptNode.src = funcSrcUrl;
    } else if (funcToRun) {
        scriptNode.textContent = funcToRun.toString();
    }

    const target = document.getElementsByTagName('head')[0] || document.body || document.documentElement;
    target.appendChild(scriptNode);
}

// add script link to HEAD
function addLinkScriptToHead(link) {
    const scriptNode = document.createElement('script');
    scriptNode.type = 'text/javascript';
    scriptNode.src = link;
    scriptNode.setAttribute('crossOrigin', 'anonymous');

    const head = document.getElementsByTagName('head');
    const headList = Array.from(head);
    headList.forEach(node => {
        node.appendChild(scriptNode);
    });
}

// add css stylesheet link to HEAD
function addLinkStylesheetToHead(link) {
    const cssNode = document.createElement('link');
    cssNode.rel = 'stylesheet';
    cssNode.href = link;
    cssNode.setAttribute('crossOrigin', 'anonymous');

    const head = document.getElementsByTagName('head');
    const headList = Array.from(head);
    headList.forEach(node => {
        node.appendChild(cssNode);
    });
}

// 包含文本最多的 DIV
function getMostTextDivSelectorAll() {
    const skipSelectors = [
        'top',
        'left',
        'right',
        'bottom',
        'foot',
        'side',
        'nav',
    ];

    let divMostTextSelector = '', divMostTextLength = 0, divTextLength = 0;

    for (const div of document.querySelectorAll('div')) {
        divSelector = '';
        if (div.id) {
            divSelector = "#" + div.id;
        } else if (div.className) {
            divSelector = "." + div.className.split(/\s+/).join(".");
        }
        if (!divSelector) continue;

        // 跳过包含特定选择器的 div
        if (skipSelectors.some(v => divSelector.includes(v))) continue;

        divTextLength = div.innerText.replace(/[\s\t\r\n]+/g,'').trim().length;

        if (divTextLength > parseInt(divMostTextLength * 0.9)) {
            divMostTextLength = divTextLength;
            divMostTextSelector = divSelector;
        }
    }

    return divMostTextSelector;
}

// [Dark Reader](https://github.com/darkreader/darkreader)
// [Darkmode.js](https://github.com/sandoche/Darkmode.js)
// const addDarkmodeWidget = () => new Darkmode().showWidget();
// window.addEventListener('load', addDarkmodeWidget);
const darkModeOptions = {
    bottom: 'calc(30%)',
    right: '10px',
    left: 'unset',
    time: '0.3s',
    mixColor: '#fff',
    backgroundColor: '#fff',
    buttonColorDark: '#100f2c',
    buttonColorLight: '#fff',
    saveInCookies: false,
    label: '🌓',
    autoMatchOsTheme: true,
}

async function darkReaderFetch(url) {
    let host = siteOrigin + "/";

    let responseData = await new Promise((resolve, reject) => {
        GM_xmlhttpRequest({
            method: "get",
            url: url,
            headers: {referer: host},
            responseType: 'blob',
            onerror: reject,
            onload: resolve,
        });
    });

    return new Response(responseData.response);
}

function toggleDarkmode(mode) {
    switch (mode) {
        case 'DarkReader':
            if (!DarkReader.isEnabled()) {
                // DarkReader.setFetchMethod(window.fetch);
                DarkReader.setFetchMethod(darkReaderFetch);
                DarkReader.enable({
                    brightness: 100,
                    contrast: 90,
                    sepia: 10,
                });
                // Enable when the system color scheme is dark.
                // DarkReader.auto({
                //     brightness: 100,
                //     contrast: 90,
                //     sepia: 10,
                // });
            }
            // DarkReader.disable();
            break;
        default: // Darkmodejs
            const darkmode = new Darkmode(darkModeOptions);
            darkmode.showWidget();
            if (!darkmode.isActivated()) darkmode.toggle();
    }
}

// return a new function to pass to called that has a timeout wrapper on it
// $(document).ready(timeoutFn(() => console.log('timeout 5s'), 5000));
function timeoutFn(fn, t) {
    let fired = false;
    let timer;
    function run() {
        clearTimeout(timer);
        timer = null;
        if (!fired) {
            fired = true;
            fn();
        }
    }
    timer = setTimeout(run, t);
    return run;
}

// [GM_config](https://github.com/sizzlemctwizzle/GM_config/)
// https://openuserjs.org/src/libs/sizzle/GM_config.js
// https://cdn.jsdelivr.net/gh/sizzlemctwizzle/GM_config/gm_config.js
// let excludedDomains = GM_config.getValue('excludeDomains', '').split(',');
function registerMenuGMConfig() {
    const configLang = browserLanguage == 'zh-CN' ? browserLanguage : 'en';
    const configID = 'CJKTextOptimizationConfig';

    // Fields in different languages
    // You could optimize this to avoid unnecessary repetition
    let langDefs = {
        'en': {
            'currentDomain': {
                'label': 'Exclude domain: ' + siteDomain,
                'type': 'checkbox',
                'default': false,
                'save': false
            },
            'excludeDomains': {
                'label': 'Excluded domains: ',
                'type': 'textarea',
                'default': false,
                'save': false
            },
        },
        'zh-CN': {
            'currentDomain': {
                'label': '排除域名：' + siteDomain,
                'type': 'checkbox',
                'default': false,
                'save': false
            },
            'excludeDomains': {
                'label': '已排除域名：',
                'type': 'textarea',
                'default': '',
                'save': false
            },
        }
    };
    // Use field definitions for the stored language
    let configFields = langDefs[configLang];

    // The title for the settings panel in different languages
    let titleDefs = {
        'en': 'CJK Text Optimization',
        'zh-CN': '中日韩文字优化'
    };
    let configTitle = titleDefs[configLang];

    // Translations for the buttons and reset link
    const saveButton = {'en': 'Save', 'zh-CN': '保存'};
    const closeButton = {'en': 'Close', 'zh-CN': '关闭'};
    const resetLink = {'en': 'Reset fields to default values', 'zh-CN': '重置'};

    // CSS style
    let configCSS = `
        #CJKTextOptimizationConfig_buttons_holder {
            margin: 0 auto;
            text-align: center;
        }

        textarea {
            width: 95%;
            max-width: 100%;
            height: 70%;
            pointer-events: none;
        }
        `;
    configCSS = configCSS.replaceAll('        ','');

    GM_config.init({
        'id': configID,
        'title': configTitle,
        'fields': configFields,
        'css': configCSS,
        'events': {
            'init': function() {
                // manually set unsaved value
                // let excludedDomains = GM_config.getValue('excludeDomains', '').split(',');
                GM_config.fields['currentDomain'].value = excludedDomains.includes(siteDomain);
                GM_config.fields['excludeDomains'].value = excludedDomains.join('\n');
            },
            'open': function (doc) {
                let config = this;
                config.frame.style.width = "50%";
                // translate the buttons
                doc.getElementById(config.id + '_saveBtn').textContent = saveButton[configLang];
                doc.getElementById(config.id + '_closeBtn').textContent = closeButton[configLang];
                doc.getElementById(config.id + '_resetLink').textContent = resetLink[configLang];
            },
            'save': function(values) {
                // All unsaved values are passed to save
                // let excludedDomains = GM_config.getValue('excludeDomains', '').split(',');
                for (let id in values) {
                    switch (id) {
                        case 'currentDomain':
                            if (values[id]) {
                                if (!excludedDomains.includes(siteDomain)) {
                                    excludedDomains.push(siteDomain);
                                }
                            } else {
                                if (excludedDomains.includes(siteDomain)) {
                                    excludedDomains = excludedDomains.filter((el) => el != siteDomain);
                                }
                            }

                            excludedDomains = excludedDomains.filter((el) => el);
                            GM_config.fields['excludeDomains'].value = excludedDomains.join(',');
                            break;
                        case 'excludeDomains':
                            break;
                    }

                    // Re-initialize GM_config for the change
                    GM_config.init({ 'id': configID, title: configTitle, 'fields': configFields });

                    // Refresh the config panel for the new change
                    GM_config.close();
                    GM_config.open();

                    // Save the options for next time
                    GM_config.setValue('excludeDomains', excludedDomains.join(','));
                    excludedDomains = GM_config.getValue('excludeDomains', '').split(',');
                }
            }
        }
    });

    GM_registerMenuCommand('选项', () => {
        GM_config.open();
    });
}

// https://stackoverflow.com/questions/23683439/gm-addstyle-equivalent-in-tampermonkey
function GM_addStyle(css) {
    const style = document.getElementById(cssStyleID) || (function() {
        const style = document.createElement('style');
        style.id = "FontStyle_TamperMonkey";
        document.head.appendChild(style);
        return style;
    })();
    const sheet = style.sheet;
    sheet.insertRule(css, (sheet.rules || sheet.cssRules || []).length);
}

function GM_addStyleInnerHTML(css) {
    const style = document.createElement('style');
    style.id = cssStyleID;
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
// styleNode.appendChild(styleText);
// document.head.appendChild(styleNode);

// https://en.wikipedia.org/wiki/List_of_sans_serif_typefaces
// https://en.wikipedia.org/wiki/List_of_serif_typefaces
// https://en.wikipedia.org/wiki/List_of_monospaced_typefaces
function getWikiListFonts() {
    let fontNames = [], fontHrefs = [];

    // let elements = document.getElementsByClassName('wikitable');
    let elements = document.querySelectorAll('.wikitable th:first-child[width]');

    for (const element of elements) {
        fontNames.push(element.innerText.split(/\r?\n/)[0].split('(')[0].split('-')[0].trim());

        // let eleLink = element.getElementsByTagName('a')[0];
        let eleLink = element.querySelectorAll(':not(small) > a')[0];
        if (eleLink && eleLink.hasAttribute('title')) {
            fontHrefs.push(eleLink.eleLink);
        } else {
            fontHrefs.push('');
        }
    }

    console.log(fontNames);
}


// --------------------------主程序--------------------------
(function() {
    // 注册菜单命令
    // registerMenuGMConfig();
    registerMenuCommand();

    // 执行菜单命令
    for (let id in menuCommand) {
        // menuCommand[id][3] = GM_getValue(menuCommand[id][0]);
        switch (menuCommand[id][0]) {
            case 'menu_CJK_Font': // CJK 字体替换
                if (!menuCommand[id][3].includes(siteDomain)) {
                    cssFontStyle = CJKFontStyle();
                }
                break;
            case 'menu_Darkmode': // 暗黑模式
                if (!menuCommand[id][3].includes(siteDomain)) {
                    toggleDarkmode(DARK_MODE);
                }
                break;
            case 'menu_CJK_Latin_Space': // 在汉字与英文字符间添加空格
                if (!menuCommand[id][3].includes(siteDomain)) {
                    cssSpaceStyle = LatinCJKSpaceStyle();
                }
                break;
            case 'menu_Pretty_Code_Block': // 代码块优化
                if (!menuCommand[id][3].includes(siteDomain)) {
                    prettyCodeBlock();
                }
                break;
            case 'menu_Obfuscate_Character': // 删除不可见的混淆字符
                if (menuCommand[id][3].includes(siteDomain)) {
                    removeHideObfuscateCharacters();
                }
                break;
        }
    }

    // 附加的 CSS 样式
    if (cssFontStyle && cssSpaceStyle) {
        cssAddStyle = `${cssFontStyle}\n${cssSpaceStyle}`;
    } else {
        if (cssFontStyle) cssAddStyle = `${cssFontStyle}`;
        if (cssSpaceStyle) cssAddStyle = `${cssSpaceStyle}`;
    }

    // 根据 CSS 样式设置 HTML 相关属性
    setHtmlProperty();

    // 等待元素出现后执行操作
    function waitForElementOperation() {
        //在汉字与英文字符间添加空格
        if (cssSpaceStyle) addSpaceBetweenLatinCJK();
        // 移除外链重定向
        removeLinkRedirect();
    }

    let waitForElement = false;

    for (let id in waitElementRules) {
        let reHref = new RegExp(`${waitElementRules[id][0]}`);
        if ((siteHref.match(reHref) || []).length > 0) {
            waitForElement = true;
            waitForKeyElements(waitElementRules[id][1], 5, 1000, waitForElementOperation);
            break;
        }
    }

    if (!waitForElement) {
        waitForElementOperation();
        // delay the function call to fix `DOMException: Failed to execute 'removeChild' on 'Node': The node to be removed is not a child of this node` on some sites
        // setTimeout(() => waitForElementOperation(), 500);
    }

    // 监听滚动事件，以处理 自动无缝翻页（Autopager）
    // let beforeScrollTop = document.documentElement.scrollTop || document.body.scrollTop;
    // window.addEventListener('scroll', () => {
    //     let scrollTop = document.documentElement.scrollTop || document.body.scrollTop,
    //         clientHeight = document.documentElement.clientHeight || document.body.clientHeight,
    //         scrollHeight = document.documentElement.scrollHeight || document.body.scrollHeight,
    //         afterScrollTop = document.documentElement.scrollTop || document.body.scrollTop,
    //         delta = afterScrollTop - beforeScrollTop;
    //     if (delta <= 0) return false;//scroll up

    //     beforeScrollTop = afterScrollTop;
    //     if (delta > 0 && scrollTop + clientHeight + 10 <= scrollHeight) {
    //         if (cssSpaceStyle) addSpaceBetweenLatinCJK();
    //     }
    // }, false);
    let beforeScrollHeight = document.documentElement.scrollHeight || document.body.scrollHeight;
    window.addEventListener('scroll', () => {
        let afterScrollHeight = document.documentElement.scrollHeight || document.body.scrollHeight;

        if (afterScrollHeight > beforeScrollHeight) {
            waitForElementOperation();
        }

        beforeScrollHeight = afterScrollHeight;
    }, false);

    //dom is fully loaded, but maybe waiting on images & css files
    // document.addEventListener("DOMContentLoaded", () => {
    // });

    //everything is fully loaded
    // window.addEventListener("load", () => {
    // });
})();
