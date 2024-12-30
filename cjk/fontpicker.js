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

// [Local Font Access API](https://developer.mozilla.org/en-US/docs/Web/API/Local_Font_Access_API)
async function getSystemFonts(useFullName) {
    let systemInstalledFonts = {};
    let systemFontInfo, fontName, fontCategory, fontVariant, fontStyle;
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

            fontStyle = fontData.style;
            if (!allStyles.includes(fontStyle)) {
                allStyles.push(fontStyle);
            }

            fontVariant = getFontWeight(fontName, fontStyle);
            if (fontStyle.toLowerCase().includes("italic")) {
                fontVariant = fontVariant + "i";
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

            if ("category" in systemFontInfo) {
                if (! ("," + systemFontInfo["variants"] + ",").includes("," + fontVariant + ",")) {
                    fontVariant = systemFontInfo["variants"] + "," + fontVariant;
                    systemFontInfo["variants"] = fontVariant.split(",").sort().join(",");
                }
            } else {
                systemFontInfo["category"] = fontCategory;
                systemFontInfo["variants"] = fontVariant;
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

// Detect & setting element fonts
function getElementFonts(elementName) {
    let outText = [];

    let ele = document.getElementById(elementName);

    // [css-properties](https://gist.github.com/jericepon/421600fd143efa45c801f9d88a2d8ccd#file-css-properties-txt)
    outText.push(window.getComputedStyle(ele, null).getPropertyValue("font-family"));
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
    return fontFamiliesArr.find( e => document.fonts.check( `12px ${e}`) );
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