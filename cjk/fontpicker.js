// [Fix CJK fonts/punctuations for Chrome and Firefox (Windows AND Linux!)](https://github.com/stecue/fixcjk)
// [字体字重测试 · Font Weight Test](https://zonovo.sinaapp.com/design/robotosc.html)
// [中文网字计划 (Chinese Webfont Project)](https://github.com/KonghaYao/chinese-free-web-font-storage)
// [动态加载字体](https://tate-young.github.io/2020/08/26/css-font-face.html)
// [字体加载最佳实践](https://xiaoiver.github.io/coding/2018/03/22/%E5%AD%97%E4%BD%93%E5%8A%A0%E8%BD%BD%E6%9C%80%E4%BD%B3%E5%AE%9E%E8%B7%B5.html)
// [JS FontFace API 字体加载失败或完毕的检测](https://www.zhangxinxu.com/wordpress/2022/04/js-font-face-load/)
// [如何校验某个字符是否存在于字体文件？](https://juejin.cn/post/7430681137830133801)
// [CSS 自定义字体实践](https://juejin.cn/post/7328621062727680000)
// [检测浏览器是否支持某种字体的方法](https://juejin.cn/post/7319903396542578715)

// CSS fonts
// - ttf to ttc: [Transfonter - Unpack TTC](https://transfonter.org/ttc-unpack)
// - ttf to woff2: if ttf filesize > 15MB: [Baidu EFE - FontEditor](https://kekee000.github.io/fonteditor/index.html)
// - ttf/woff2 to CSS: [Transfonter - Webfont generator](https://transfonter.org/)
//   * Disable `Family support` if display wrong font style
//   * Enable `Base64 encode`
//   * Formats: `WOFF2` only
//   * Demo page language：Without demo page
//   * Font display：auto
// - Convert
// - stylesheet.css: `@font-face`

const sampleTextElement = [
    "sampletext-basic",
    "sampletext-mono",
    "sampletext-confuse",
    "sampletext-punctuation",
    "sampletext-cjk-punctuation",
    "sampletext-symbols",
    "sampletext-emoji",
    "sampletext-flags",
    "sampletext-cjk",
    "sample-textarea-left",
    "sample-textarea-right",
];

let elementDefaultFonts = {};

let localFontsType = 'woff2';
let localFontsUrl = 'fonts/';
let localFonts = {};
// let localFonts = {
//     // curl -fSL -o "fonts/Twemoji Country Flags.woff2" "https://github.com/matthijs110/chromium-country-flags/blob/master/src/assets/TwemojiCountryFlags.woff2?raw=true"
//     "Twemoji Country Flags": {
//         "category": "sans-serif",
//         "variants": "400",
// 		"subsets": "emoji",
//     },
// };

let systemFonts = {};

//Load fonts
function loadFonts() {
    let isSystemFonts = $("#systemfonts").is(":checked");
    let isGoogleFonts = $("#googlefonts").is(":checked");
    let fontSize = $("#select-fontsize").val();

    // Get system font list
    let promise;

    if (isSystemFonts) {
        promise = getSystemFonts(false);
        promise.then(data => {
            systemFonts = data;
            // console.log(systemFonts);
            // console.log(JSON.stringify(data));

            setFontPicker(systemFonts, localFonts, isGoogleFonts, localFontsType, localFontsUrl, fontSize);
        });
    } else {
        setFontPicker(systemFonts, localFonts, isGoogleFonts, localFontsType, localFontsUrl, fontSize);
    }
}

// Setting fontpicker
function setFontPicker(systemfonts, localfonts, googlefonts, localfontstype, localfontsurl, fontSize) {
    sampleTextElement.forEach(function(ele) {
        // Picker fonts
        $('#' + ele + '-font').fontpicker({
            localFonts: localfonts,
            localFontsType: localfontstype,
            localFontsUrl: localfontsurl,
            googleFonts: googlefonts,
            systemFonts: systemfonts,
        }).on('change', function() {
            applyFont('#' + ele, this.value, fontSize);
            applyFont('#' + ele + '-detect', this.value, '');
            $('#' + ele + "-select").text(this.value);
            getElementFonts(ele);
        });
    });
}

// Apply font to element
function applyFont(element, fontSpec, fontSize) {
    if (!fontSpec) {
        // Font was cleared
        // console.log('You cleared font');
        $(element).css({
            fontFamily: 'inherit',
            fontWeight: 'normal',
            fontStyle: 'normal'
        });
        return;
    }

    // console.log('You selected font: ' + fontSpec);

    // Split font into family and weight/style
    let tmp = fontSpec.split(':'),
        family = tmp[0],
        variant = tmp[1] || '400',
        weight = parseInt(variant,10),
        italic = /i$/.test(variant);

    // Apply selected font to element
    $(element).css({
        fontFamily: "'" + family + "'",
        fontWeight: weight,
        fontStyle: italic ? 'italic' : 'normal',
        fontSize: fontSize || '16px',
    });
}

// Change sample text font size
function changeSampleTextFontSize(fontSize) {
    sampleTextElement.forEach(function(ele) {
        document.getElementById(ele).style.fontSize = fontSize + "px";
        getElementFonts(ele);
    });
}

// Determine font weight
function getFontWeight(fontName, fontVariant) {
    let fontStyle, fontWeight, compareName;
    let calcRound, calcFactor, calcTotal;

    fontWeight = "400";
    compareName = fontName.toLowerCase();

    fontStyle = fontVariant.toLowerCase();
    if (fontStyle.includes("normal") || fontStyle.includes("regular")) {
        fontWeight = "400";
    } else if (fontStyle.includes("extralight") || fontStyle.includes("ultralight") || fontStyle.includes("Semilight")) {
        fontWeight = "200";
    } else if (fontStyle.includes("light") || fontStyle.includes("demilight")) {
        fontWeight = "300";
    } else if (fontStyle.includes("semibold") || fontStyle.includes("demibold")) {
        fontWeight = "600";
    } else if (fontStyle.includes("extrabold")) {
        fontWeight = "800";
    } else if (fontStyle.includes("bold")) {
        fontWeight = "700";
    } else if (fontStyle.includes("medium")) {
        fontWeight = "500";
    } else if (fontStyle.includes("thin")) {
        fontWeight = "100";
    } else if (fontStyle.includes("black") || fontStyle.includes("heavy") || fontStyle.includes("fat") || fontStyle.includes("poster")) {
        fontWeight = "900";
    }

    // [梦源字体](https://github.com/Pal3love/dream-han-cjk)
    if (compareName.includes("dream han serif") ||
        compareName.includes("梦源宋体") ||
        compareName.includes("夢源明體")) {
        calcRound = parseInt(fontVariant.match(/\d+/)[0]);
        calcTotal = (calcRound - 1) * 25;
        fontWeight = (250 + calcTotal).toString();
    }

    if (compareName.includes("dream han sans") ||
        compareName.includes("梦源黑体") ||
        compareName.includes("夢源黑體")) {
        calcRound = parseInt(fontVariant.match(/\d+/)[0]);
        calcTotal = 0;
        for (let step = 1; step < calcRound; step++) {
            calcFactor = 1 + 0.1 * (step - 1);
            calcFactor = calcFactor * calcFactor;
            calcTotal = calcTotal + calcFactor;
        }
        calcTotal = calcTotal + 19.4 * (calcRound - 1);
        fontWeight = parseInt((250 + calcTotal)).toString();
    }

    if (!fontWeight) {
        fontWeight = "400";
    }

    return fontWeight
}

// Determine font stretch
function getFontStretch(fontName, fontVariant) {
    let fontStyle, fontStretch, compareName;

    fontStretch = "normal";
    compareName = fontName.toLowerCase();

    fontStyle = fontVariant.toLowerCase();
    if (fontStyle.includes("ultra-condensed") || fontStyle.includes("ultracondensed")) {
        fontStretch = "ultra-condensed";
    } else if (fontStyle.includes("extra-condensed") || fontStyle.includes("extracondensed")) {
        fontStretch = "extra-condensed";
    } else if (fontStyle.includes("semi-condensed") || fontStyle.includes("semicondensed")) {
        fontStretch = "semi-condensed";
    } else if (fontStyle.includes("ultra-expanded") || fontStyle.includes("ultra-expanded")) {
        fontStretch = "ultra-expanded";
    } else if (fontStyle.includes("extra-expanded") || fontStyle.includes("extra-expanded")) {
        fontStretch = "extra-expanded";
    } else if (fontStyle.includes("semi-expanded") || fontStyle.includes("semi-expanded")) {
        fontStretch = "ultra-expanded";
    } else if (fontStyle.includes("condensed")) {
        fontStretch = "condensed";
    } else if (fontStyle.includes("expanded")) {
        fontStretch = "expanded";
    }

    if (!fontStretch) {
        fontStretch = "normal";
    }

    return fontStretch
}

// [Local Font Access API](https://developer.mozilla.org/en-US/docs/Web/API/Local_Font_Access_API)
async function getSystemFonts(useFullName) {
    let systemInstalledFonts = {};
    let systemFontInfo, fontPostscriptName, fontFullName, fontName, fontCategory, fontVariant, fontStyle;
    let fontFace, fontFaceStyle, fontFaceWeight, fontFaceStretch;
    let allStyles = [];

    if ("queryLocalFonts" in window) {
        // The Local Font Access API is supported
	} else {
        console.log('The Local Font Access API is not supported');
    }

    try {
        addLoadingIndicator('curtain', 'Loading system fonts...', 'data-colorful');

        const availableFonts = await window.queryLocalFonts();
        // console.log(availableFonts);
        for (const fontData of availableFonts) {
            // console.log(`"${fontData.postscriptName}" "${fontData.fullName}" "${fontData.family}" "${fontData.style}"`);
            systemFontInfo = {};
            if (fontData.family in systemInstalledFonts) {
                systemFontInfo = systemInstalledFonts[fontData.family];
            }

            if (useFullName) {
                fontName = fontData.fullName;
            } else {
                fontName = fontData.family;
            }

            fontPostscriptName = fontData.postscriptName;
            fontFullName = fontData.fullName;

            fontStyle = fontData.style;
            if (!allStyles.includes(fontStyle)) {
                allStyles.push(fontStyle);
            }

            fontVariant = getFontWeight(fontName, fontStyle);
            fontFaceWeight = fontVariant;
            fontFaceStyle = "normal";
            if (fontStyle.toLowerCase().includes("italic")) {
                fontFaceStyle = "italic";
                fontVariant = fontVariant + "i";
            }
            if (fontStyle.toLowerCase().includes("oblique")) {
                fontFaceStyle = "oblique";
            }

            fontCategory = "system";
            fontName = fontName.toLowerCase();
            if (fontName.includes("sans")) {
                fontCategory = "sans-serif";
            } else if (fontName.includes("serif")) {
                fontCategory = "serif";
            } else if (fontName.includes("mono")) {
                fontCategory = "monospace";
            } else if (fontName.includes("display") || fontName.includes("screen")) {
                fontCategory = "display";
            } else if (fontName.includes("handwriting") || fontName.includes("handwritten")) {
                fontCategory = "handwriting";
            }

            // [FontFace: FontFace() constructor](https://developer.mozilla.org/en-US/docs/Web/API/FontFace/FontFace)
            // source:style:weight:stretch,...
            fontFaceStretch = getFontStretch(fontName, fontStyle);
            fontFace = fontPostscriptName + ":" + fontFaceStyle + ":" + fontFaceWeight + ":" + fontFaceStretch;

            if ("category" in systemFontInfo) {
                if (! ("," + systemFontInfo["postscriptname"] + ",").includes("," + fontPostscriptName + ",")) {
                    fontPostscriptName = systemFontInfo["postscriptname"] + "," + fontPostscriptName;
                    systemFontInfo["postscriptname"] = fontPostscriptName.split(",").sort().join(",");
                }

                if (! ("," + systemFontInfo["fullname"] + ",").includes("," + fontFullName + ",")) {
                    fontFullName = systemFontInfo["fullname"] + "," + fontFullName;
                    systemFontInfo["fullname"] = fontFullName.split(",").sort().join(",");
                }

                if (! ("," + systemFontInfo["variants"] + ",").includes("," + fontVariant + ",")) {
                    fontVariant = systemFontInfo["variants"] + "," + fontVariant;
                    systemFontInfo["variants"] = fontVariant.split(",").sort().join(",");
                }

                systemFontInfo["fontface"] = systemFontInfo["fontface"] + "," + fontFace;
            } else {
                systemFontInfo["category"] = fontCategory;
                systemFontInfo["postscriptname"] = fontPostscriptName;
                systemFontInfo["fullname"] = fontFullName;
                systemFontInfo["variants"] = fontVariant;
                systemFontInfo["fontface"] = fontFace;
            }

            if (useFullName) {
                systemInstalledFonts[fontData.fullName] = systemFontInfo;
            } else {
                systemInstalledFonts[fontData.family] = systemFontInfo;
            }
        }

        removeLoadingIndicator();
    } catch (err) {
        console.error(err.name, err.message);
    }

    // console.log(systemInstalledFonts);
    // console.log(allStyles);

    return systemInstalledFonts;
}

// Get sample text element default fonts
function getSampleTextDefaultFonts() {
    sampleTextElement.forEach(function(ele) {
        getElementDefaultFonts(ele);
    });
}

// Get element default fonts
function getElementDefaultFonts(elementName) {
    let ele = document.getElementById(elementName);

    elementDefaultFonts[elementName] ={"fonts": window.getComputedStyle(ele, null).getPropertyValue("font-family")};
}

// Detect & setting element fonts
function getElementFonts(elementName) {
    let outText = [];
    let fontFamilies, renderedFont;

    let ele = document.getElementById(elementName);

    // [css-properties](https://gist.github.com/jericepon/421600fd143efa45c801f9d88a2d8ccd#file-css-properties-txt)
    fontFamilies = window.getComputedStyle(ele, null).getPropertyValue("font-family");
    renderedFont = getRenderedFontFamilyName(elementName) || 'unknown';
    if (!fontFamilies.replaceAll('"', "") === renderedFont.replaceAll('"', "")) {
        fontFamilies = elementDefaultFonts[elementName]["fonts"];
    }

    outText.push(fontFamilies);
    outText.push(window.getComputedStyle(ele, null).getPropertyValue("font-style"));
    outText.push(window.getComputedStyle(ele, null).getPropertyValue("font-size"));
    outText.push(window.getComputedStyle(ele, null).getPropertyValue("font-weight"));

    $("#" + elementName + "-detect").text(outText.join(" "));
}

// [FontFaceSet: check() method](https://developer.mozilla.org/en-US/docs/Web/API/FontFaceSet/check)
// [How to get the rendered font in JavaScript?](https://stackoverflow.com/questions/57853292/how-to-get-the-rendered-font-in-javascript)
// getRenderedFontFamilyName(document.querySelector('body'));
function getRenderedFontFamilyName(elementName) {
    let ele = document.getElementById(elementName);

    // Font families set in CSS for the element
    const fontFamilies = window.getComputedStyle( ele, null ).getPropertyValue( "font-family" );
    // const hardcodedFamilies = '-apple-system, BlinkMacSystemFont, "Segoe UI Adjusted", "Segoe UI", "Liberation Sans", sans-serif';

    // Remove the " sign from names (font families with spaces in their names) and split names to the array
    const fontFamiliesArr = fontFamilies.replaceAll('"', "").split(", ");

    // Find the first loaded font from the array
    const d = new FontDetector();
    return fontFamiliesArr.find( e => d.detect(e) );
    // return fontFamiliesArr.find( e => document.fonts.check( `12px "${e}"`) );
}

// Detect font is available
function isFontAvailable(fontName) {
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    const text = 'abcdefghijklmnopqrstuvwxyz0123456789';
    context.font = '72px monospace';
    const baselineSize = context.measureText(text).width;

    context.font = '72px "' + fontName + '", monospace';
    const newSize = context.measureText(text).width;

    // console.log(fontName, baselineSize, newSize);

    return newSize !== baselineSize;
}

// [Detect available fonts with JS](https://gist.github.com/fijiwebdesign/3b0bf8e88ceef7518844)
// [list every font a user's browser can display](https://stackoverflow.com/questions/3368837/list-every-font-a-users-browser-can-display)
/**
 * Usage: d = new FontDetector();
 *        d.detect('font name');
 */
var FontDetector = function() {
    // a font will be compared against all the three default fonts.
    // and if it doesn't match all 3 then that font is not available.
    var baseFonts = ['monospace', 'sans-serif', 'serif'];

    //we use m or w because these two characters take up the maximum width.
    // And we use a LLi so that the same matching fonts can get separated
    var testString = "mmmmmmmmmmlli";

    //we test using 72px font size, we may use any size. I guess larger the better.
    var testSize = '72px';

    var h = document.getElementsByTagName("body")[0];

    // create a SPAN in the document to get the width of the text we use to test
    var s = document.createElement("span");
    s.style.fontSize = testSize;
    s.innerHTML = testString;
    var defaultWidth = {};
    var defaultHeight = {};
    for (var index in baseFonts) {
        //get the default width for the three base fonts
        s.style.fontFamily = baseFonts[index];
        h.appendChild(s);
        defaultWidth[baseFonts[index]] = s.offsetWidth; //width for the default font
        defaultHeight[baseFonts[index]] = s.offsetHeight; //height for the defualt font
        h.removeChild(s);
    }

    function detect(font) {
        var detected = false;
        for (var index in baseFonts) {
            s.style.fontFamily = '"' + font + '"' + ',' + baseFonts[index]; // name of the font along with the base font for fallback.
            h.appendChild(s);
            var matched = (s.offsetWidth != defaultWidth[baseFonts[index]] || s.offsetHeight != defaultHeight[baseFonts[index]]);
            h.removeChild(s);
            detected = detected || matched;
        }
        return detected;
    }

    this.detect = detect;
};

// [FontFace: FontFace() constructor](https://developer.mozilla.org/en-US/docs/Web/API/FontFace/FontFace)
function loadSystemFont(fontFamily, fontFace, localFont) {
    // source:style:weight:stretch,...
    const fontFaceProperty = fontFace.split(",");
    const fonts = fontFaceProperty.map(function(fontface) {
        const fontFaceDescriptor = fontface.split(":");
        if (localFont) {
            return new FontFace(fontFamily, "local('" + fontFaceDescriptor[0] + "')", {
                style: fontFaceDescriptor[1],
                weight: fontFaceDescriptor[2],
                stretch: fontFaceDescriptor[3],
            });
        } else {
            return new FontFace(fontFamily, "url('" + fontFaceDescriptor[0] + "')", {
                style: fontFaceDescriptor[1],
                weight: fontFaceDescriptor[2],
                stretch: fontFaceDescriptor[3],
            });
        } 
    });
    // console.log(fonts);

    Promise.all(fonts.map(function(font) {
        font.load();
    })).then(function () {
        fonts.map(function(font) {
            document.fonts.add(font);
        });
        console.log(`"${fontFamily}" loaded.`);
    }).catch(err => {
        console.log(`"${fontFamily}" not loaded.`);
        console.log(err);
    });
}

// Loading Spinner/Indicator
// [80+ Best Pure CSS Loading Spinners For Front-end Developers](https://365webresources.com/best-pure-css-loading-spinners/)

// [CSS loader](https://github.com/raphaelfabeni/css-loader)
// addLinkStylesheetToHead('https://cdn.jsdelivr.net/npm/pure-css-loader/dist/css-loader.css');
const LoadingIndicatorTemplate = `
    <div id="loading-indicator" class="loader"></div>
`;

// addLoadingIndicator('default', '处理中...', 'data-half data-blink');
// addLoadingIndicator('curtain', '处理中...', 'data-colorful');
function addLoadingIndicator(type, text, attrs) {
    const loading = document.createElement('div');
    loading.innerHTML = LoadingIndicatorTemplate.trim();

    const node = loading.querySelector('#loading-indicator');
    if (text) {
        switch (type) {
            case 'curtain':
                node.setAttribute('data-curtain-text', text);
                break;
            case 'smartphone':
                node.setAttribute('data-screen', text);
                break;
            default:
                node.setAttribute('data-text', text);
        }
    }

    if (attrs) {
        attrs.split(' ').map(attr => node.setAttribute(attr, ''));
    }

    node.classList.add('loader-' + type);
    node.classList.add('is-active');

    document.getElementsByTagName("body")[0].appendChild(loading);
}

function removeLoadingIndicator() {
    const node = document.querySelector("#loading-indicator");
    if (node) {
        node.parentNode.remove();
    }
}

// ProgressBar
// [Responsive and slick progress bars](https://kimmobrunfeldt.github.io/progressbar.js/)
// https://cdnjs.cloudflare.com/ajax/libs/progressbar.js/1.1.0/progressbar.min.js
const progressbarTemplate = `
    <div id="progressbar"></div>

    <style>
        #progressbar {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 200px;
            height: 200px;
        }
    </style>
`;

function addProgressbar() {
    const progressbar = document.createElement('div');
    progressbar.innerHTML = progressbarTemplate.trim();
    document.getElementsByTagName("body")[0].appendChild(progressbar);

    const bar = new ProgressBar.Circle('#progressbar', {
        color: '#aaa',
        // This has to be the same size as the maximum width to
        // prevent clipping
        strokeWidth: 4,
        trailWidth: 1,
        easing: 'easeInOut',
        duration: 1400,
        text: {
            autoStyleContainer: false
        },
        from: { color: '#FFEA82', width: 1 },
        to: { color: '#ED6A5A', width: 4 },
        // Set default step function for all animate calls
        step: function(state, circle) {
            circle.path.setAttribute('stroke', state.color);
            circle.path.setAttribute('stroke-width', state.width);
            const value = Math.round(circle.value() * 100);
            if (value === 0) {
                circle.setText('');
            } else {
                circle.setText(value);
            }
        }
    });

    bar.text.style.fontName = 'Helvetica, sans-serif';
    bar.text.style.fontSize = '2rem';
    
    bar.animate(1.0);  // Number from 0.0 to 1.0
}

function removeProgressbar() {
    const node = document.querySelector("#progressbar");
    if (node) {
        node.parentNode.remove();
    }
}