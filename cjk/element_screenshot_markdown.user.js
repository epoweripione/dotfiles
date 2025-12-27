// ==UserScript==
// @name              Inspector DOM Element - Screenshot / Markdown
// @name:zh-CN        检查 DOM 元素 - 点击截图或转为 Markdown
// @namespace         https://github.com/epoweripione/dotfiles
// @version           1.0.0
// @description       Inspector DOM Element - click to take screenshot or convert to markdown
// @description:zh-cn 检查 DOM 元素 - 点击截图或转为 Markdown
// @author            epoweripione
// @license           MIT
// @match             http://*/*
// @match             https://*/*
// @require           https://cdn.jsdelivr.net/npm/jquery/dist/jquery.min.js
// @require           https://cdn.jsdelivr.net/gh/hsynlms/theroomjs/dist/theroom.min.js
// @require           https://cdn.jsdelivr.net/npm/html2canvas/dist/html2canvas.min.js
// @require           https://cdn.jsdelivr.net/npm/html-to-image/dist/html-to-image.min.js
// @require           https://cdn.jsdelivr.net/npm/dom-to-image-more/dist/dom-to-image-more.min.js
// @require           https://cdn.jsdelivr.net/npm/@zumer/snapdom/dist/snapdom.min.js
// @require           https://cdn.jsdelivr.net/npm/dompdf.js@latest/dist/dompdf.js
// @require           https://cdn.jsdelivr.net/gh/lmn1919/dompdf.js@main/examples/SourceHanSansSC-Normal-Min-normal.js
// @require           https://cdn.jsdelivr.net/npm/viewerjs/dist/viewer.min.js
// @require           https://cdn.bootcdn.net/ajax/libs/js-beautify/1.15.4/beautify-html.min.js
// @require           https://unpkg.com/turndown/dist/turndown.js
// @require           https://unpkg.com/@guyplusplus/turndown-plugin-gfm/dist/turndown-plugin-gfm.js
// @require           https://cdn.jsdelivr.net/npm/html-to-md/dist/index.js
// @require           https://cdn.jsdelivr.net/npm/img-previewer/dist/img-previewer.min.js
// @grant             GM_getValue
// @grant             GM_setValue
// @grant             GM_xmlhttpRequest
// @grant             GM_registerMenuCommand
// @grant             GM_unregisterMenuCommand
// ==/UserScript==

'use strict';

const browserLanguage = navigator.language;
const siteOrigin = location.origin;
const siteDomain = location.host;
const siteHref = location.href;
const siteTitle = document.title;

const FONT_DEFAULT = 'Noto Sans'; // 默认字体
const FONT_EMOJI = 'emoji'; // Emoji 字体
const FONT_FALLBACK = 'sans-serif'; // 备用字体
const FONT_MONO = 'JetBrainsMono Nerd Font'; // 等宽字体

const MARKDOWN_FLAVOR = 'commonmark'; // 转为 Markdown 默认格式: commonmark, gfm, ghost
const MARKDOWN_URL_FORMAT = 'absolute'; // 转为 Markdown 的 URL 默认格式: original, absolute, relative, root-relative

const DOM2IMAGE = 'snapdom'; // 元素转图片：dom-to-image, html-to-image, snapdom
const IMAGE_VIEWER = 'image-viewer'; // 图片查看器：image-viewer, img-previewer

// TamperMonkey 选项菜单
// 菜单编码、启用标识、禁用标识、域名列表、命令类型
// 命令类型：enable - 默认启用（域名列表=禁用列表）、disable - 默认禁用（域名列表=启用列表）、direct - 直接执行命令
let registeredMenuCommand = [];
let menuCommand = [
    ['menu_Inspector_Screenshot', '📡 - 检查元素 - 点击截图', 'screenshot', '', 'direct'],
    ['menu_Inspector_Markdown', '📡 - 检查元素 - 点击转为 Markdown', 'markdown', '', 'direct'],
    ['menu_Inspector_PDF', '📡 - 检查元素 - 点击转为 PDF', 'pdf', '', 'direct'],
    ['menu_Selection_to_Markdown', '📋 - 选择内容转为 Markdown', 'selection2md', '', 'direct'],
];

// --------------------------函数及功能定义--------------------------
// 监听键盘事件
// Use https://keycode.info/ to get keys
function onKeydown(evt) {
    // Esc
    if (evt.keyCode == 27) {
        stopElementInspector();
    }
}

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
                    case 'menu_Selection_to_Markdown':
                        registeredMenuCommand.push(GM_registerMenuCommand(`${menuCommand[id][1]}`,
                                function(){selectionToMarkdown()})
                            );
                        break;
                    default:
                        registeredMenuCommand.push(GM_registerMenuCommand(`${menuCommand[id][1]}`,
                                function(){startElementInspector(elementInspectorOptions, `${menuCommand[id][2]}`)})
                            );
                        break;
                }
                break;
        }
    }
}

// 删除元素
const removeElement = (el) => document.querySelectorAll(el).forEach(node => node.remove());

// 获取页面背景颜色
function getPageBackgroundColor() {
    // Get the computed style of the body element
    const bodyElement = document.body;
    const computedStyle = window.getComputedStyle(bodyElement);
    const bgColor = computedStyle.getPropertyValue("background-color");
    
    // The color will typically be returned as an RGB or RGBA value (e.g., "rgb(255, 255, 255)")
    //console.log("Computed background color:", bgColor); 

    // If the body's background is transparent, it might inherit from the html element
    if (bgColor === "rgba(0, 0, 0, 0)" || bgColor === "transparent") {
        const htmlElement = document.documentElement;
        const computedHtmlStyle = window.getComputedStyle(htmlElement);
        const htmlBgColor = computedHtmlStyle.getPropertyValue("background-color");
        //console.log("Body is transparent, HTML background color:", htmlBgColor);
        return htmlBgColor;
    }

    return bgColor;
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

// 鼠标滑动高亮元素
// [A vanilla javascript plugin that allows you to outline dom elements like web inspectors](https://github.com/hsynlms/theroomjs)
// https://www.cssscript.com/demo/highlight-dom-elements-on-hover-theroom
const elementInspectorInfoTemplate = `
    <div id="theroom-info">
        <span id="theroom-tag"></span>
        <span id="theroom-id"></span>
        <span id="theroom-class"></span>
    </div>

    <style>
        #theroom-info {
            position: fixed;
            bottom: 0;
            width: 100%;
            left: 0;
            font-family: '${FONT_DEFAULT}';
            font-weight: bold;
            background-color: rgba(177,213,200,0.5);
            padding: 10px;
            color: #fafafa;
            text-align: center;
            box-shadow: 0px 4px 20px rgba(0,0,0,0.3);
        }

        #theroom-tag {
            color: #C2185B;
        }

        #theroom-id {
            color: #5D4037;
        }

        #theroom-class {
            color: #607D8B;
        }
    </style>
`;

const elementInspectorOptions = {
    inspector: null,
    createInspector: true,
    htmlClass: true,
    blockRedirection: false,
    excludes: [],
    started: function (element) {
        const node = document.getElementsByClassName('inspector-element')[0];
        node.style.backgroundColor = "rgba(255,0,0,0.5)";
        node.style.transition = "all 200ms";
        node.style.pointerEvents = "none";
        node.style.zIndex = "2147483647";
        node.style.position = "absolute";
        node.innerHTML = `${elementInspectorInfoTemplate}`;
    },
    click: function (element) {
        const node = document.getElementsByClassName('inspector-element')[0];
        elementInspectorClick(element, node.getAttribute('click-action'));
    },
    mouseover: function (element) {
        const elementInfo = document.querySelector("#theroom-info");
        if (elementInfo) {
            elementInfo.querySelector("#theroom-tag").innerText = element.tagName;
            elementInfo.querySelector("#theroom-id").innerText = (element.id ? ("#" + element.id) : "");
            elementInfo.querySelector("#theroom-class").innerText = (element.className ? ("." + element.className.split(/\s+/).join(".")) : "");
        }
    },
}

const startElementInspector = (options, clickAction) => {
    theRoom.start(options);

    const node = document.getElementsByClassName('inspector-element')[0];
    node.setAttribute('click-action', clickAction);
}

const stopElementInspector = () => {
    theRoom.stop(true);
}

function elementInspectorClick(element, action) {
    switch (action) {
        case 'screenshot':
            if (element) {
                elementInspectorScreenshot(element);
            } else {
                if (element.id) {
                    elementSelectorScreenshot("#" + element.id);
                } else if (element.className) {
                    elementSelectorScreenshot("." + element.className.split(/\s+/).join("."));
                }
            }
            break;
        case 'markdown':
            if (element) {
                elementInspectorToMarkdown(element);
            } else {
                if (element.id) {
                    elementSelectorToMarkdown("#" + element.id);
                } else if (element.className) {
                    elementSelectorToMarkdown("." + element.className.split(/\s+/).join("."));
                }
            }
            break;
        case 'pdf':
            if (element) {
                elementInspectorToPDF(element);
            } else {
                if (element.id) {
                    elementSelectorToPDF("#" + element.id);
                } else if (element.className) {
                    elementSelectorToPDF("." + element.className.split(/\s+/).join("."));
                }
            }
            break;
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

    bar.text.style.fontFamily = 'Helvetica, sans-serif';
    bar.text.style.fontSize = '2rem';

    bar.animate(1.0);  // Number from 0.0 to 1.0
}

function removeProgressbar() {
    const node = document.querySelector("#progressbar");
    if (node) {
        node.parentNode.remove();
    }
}

// tooltips
const tooltipsTemplate = `
    <div id="tooltips-info">
        <span id="tooltips-text"></span>
    </div>

    <style>
        #tooltips-info {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 300px;
            height: 20px;
            font-family: '${FONT_DEFAULT}';
            font-size: 1em;
            font-weight: bold;
            text-align: center;
        }

        #tooltips-text {
            color: #ED6A5A;
        }
    </style>
`;

function addTooltips() {
    const tooltips = document.createElement('div');
    tooltips.innerHTML = tooltipsTemplate.trim();
    tooltips.querySelector("#tooltips-text").innerText = 'Capturing element screenshot...';
    document.getElementsByTagName("body")[0].appendChild(tooltips);
}

function removeTooltips() {
    const node = document.querySelector("#tooltips-info");
    if (node) {
        node.parentNode.remove();
    }
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

// 获取指定元素的截图
// https://stackoverflow.com/questions/4912092/using-html5-canvas-javascript-to-take-in-browser-screenshots
// [7 ways to take website screenshots with node.js and JavaScript](https://www.urlbox.io/7-ways-website-screenshots-nodejs-javascript)
// [Take real screenshot with JS](https://github.com/amiad/screenshot.js)
// [将网页元素生成图片保存](https://blog.51cto.com/u_14209124/2884171)
// Open image in new window
function openImageInWindow(base64URL) {
    let win = window.open("");
    win.document.write("<img style=\"display: block; -webkit-user-select: none; margin: auto;\" src=\""+ base64URL +"\" >");
    // win.document.write('<iframe src="' + base64URL + '" frameborder="0" ' +
    //     'style="border:0; top:0px; left:0px; bottom:0px; right:0px; width:100%; height:100%;" ' +
    //     'allowfullscreen></iframe>'
    // );
    win.document.title = 'screenshot-' + getDateTimeString();
}

// 使用 html2canvas 获取元素截图的 DataURL
// getElementScreenshotHtml2Canvas(document.querySelector('.hljs.bash'), openImageInWindow);
function getElementScreenshotHtml2Canvas(element, useCORS, callback) {
    // 创建图片画布
    const elementID = 'canvas_element_screenshot';

    const pageBackgroundColor = getPageBackgroundColor();

    const eleCanvas = document.createElement('canvas');
    // const w = $(selector).outerWidth();
    // const h = $(selector).outerHeight();
    const w = element.offsetWidth;
    const h = element.offsetHeight;
    // const w = element.clientWidth;
    // const h = element.clientHeight;

    eleCanvas.id = elementID;
    eleCanvas.width = w;
    eleCanvas.height = h;
    eleCanvas.style.width = w + 'px';
    eleCanvas.style.height = h + 'px';
    eleCanvas.style.display = 'none';
    // eleCanvas.style.backgroundColor = "rgb(29, 31, 32)";
    // eleCanvas.style.backgroundColor = pageBackgroundColor;
    // eleCanvas.setAttribute('hidden', 'hidden');

    //先放大2倍，然后缩小，处理模糊问题
    // eleCanvas.width = w * 2;
    // eleCanvas.height = h * 2;
    // const ctx = eleCanvas.getContext('2d');
    // ctx.scale(2,2);
    // ctx.fillStyle = pageBackgroundColor;
    // ctx.fillRect(0, 0, w, h);

    html2canvas(element,{
        canvas: eleCanvas,
        allowTaint: true, //允许污染
        taintTest: true, //在渲染前测试图片
        // foreignObjectRendering: true, // 如果浏览器支持，使用 ForeignObject 渲染
        useCORS: useCORS, //使用跨域
        backgroundColor: pageBackgroundColor, //背景色
        foreignObjectRendering: true, // 如果浏览器支持，使用 ForeignObject 渲染
    }).then(canvas => {
        // document.body.appendChild(canvas);
        // const eleDataUrl = document.getElementById('canvas_element_screenshot').toDataURL('image/png');
        // removeElement('#' + elementID);
        try {
            const eleDataUrl = canvas.toDataURL('image/png');
            callback(eleDataUrl);
        } catch (e) {
            callback('');
        }
    });
}

// [DOM to Image](https://github.com/1904labs/dom-to-image-more)
function getElementScreenshotDomToImage(element, callback) {
    const pageBackgroundColor = getPageBackgroundColor();
    domtoimage.toPng(element, {
        bgcolor: pageBackgroundColor
    }).then(dataUrl => {
            callback(dataUrl);
        })
        .catch(error => {
            callback('');
        });
}

// [html-to-image](https://github.com/bubkoo/html-to-image)
function getElementScreenshotHtmlToImage(element, callback) {
    const pageBackgroundColor = getPageBackgroundColor();
    htmlToImage.toPng(element, {
        backgroundColor: pageBackgroundColor
    }).then(dataUrl => {
            callback(dataUrl);
        })
        .catch(error => {
            callback('');
        });
}

// [Snapdom](https://github.com/zumerlab/snapdom)
async function getElementScreenshotSnapdom(element, callback) {
    const pageBackgroundColor = getPageBackgroundColor();

    const imgElement = await snapdom.toPng(element, {
        backgroundColor: pageBackgroundColor
    });

    const dataUrl = imgElement.src;
    if (!dataUrl || dataUrl.length < 100) {
        callback('');
    } else {
        callback(dataUrl);
    }
}

function elementInspectorScreenshot(element) {
    // 停止鼠标滑动高亮元素
    stopElementInspector();

    // 提示
    addLoadingIndicator('curtain', '处理中...', 'data-colorful');

    const renderScreenshotHtmlSnapdom = function(dataUrl) {
        // 移除提示
        removeLoadingIndicator();
        if (dataUrl) {
            // 显示截图
            // openImageInWindow(dataUrl);
            renderImageViewer(dataUrl, 'screenshot-' + getDateTimeString(), IMAGE_VIEWER);
        } else {
            getElementScreenshotHtmlToImage(element, false, renderScreenshotHtmlToImage);
        }
    }

    const renderScreenshotHtmlToImage = function(dataUrl) {
        // 移除提示
        removeLoadingIndicator();
        if (dataUrl) {
            // 显示截图
            // openImageInWindow(dataUrl);
            renderImageViewer(dataUrl, 'screenshot-' + getDateTimeString(), IMAGE_VIEWER);
        } else {
            getElementScreenshotDomToImage(element, false, renderScreenshotDom2Image);
        }
    }

    const renderScreenshotDom2Image = function(dataUrl) {
        // 移除提示
        removeLoadingIndicator();
        if (dataUrl) {
            // 显示截图
            // openImageInWindow(dataUrl);
            renderImageViewer(dataUrl, 'screenshot-' + getDateTimeString(), IMAGE_VIEWER);
        } else {
            getElementScreenshotHtml2Canvas(element, false, renderScreenshotHtml2CanvasCORS);
        }
    }

    const renderScreenshotHtml2Canvas = function(dataUrl) {
        // 移除提示
        removeLoadingIndicator();
        if (dataUrl) {
            // 显示截图
            renderImageViewer(dataUrl, 'screenshot-' + getDateTimeString(), IMAGE_VIEWER);
        }
    }

    const renderScreenshotHtml2CanvasCORS = function(dataUrl) {
        // 移除提示
        removeLoadingIndicator();
        if (dataUrl) {
            // 显示截图
            renderImageViewer(dataUrl, 'screenshot-' + getDateTimeString(), IMAGE_VIEWER);
        } else {
            getElementScreenshotHtml2Canvas(element, true, renderScreenshotHtml2Canvas);
        }
    }

    switch (DOM2IMAGE) {
        case 'html-to-image':
            getElementScreenshotHtmlToImage(element, false, renderScreenshotHtmlToImage);
            break; 
        case 'dom-to-image':
            getElementScreenshotDomToImage(element, false, renderScreenshotDom2Image);
            break;
        case 'snapdom':
            getElementScreenshotSnapdom(element, renderScreenshotHtmlSnapdom);
            break;
        default:
            getElementScreenshotHtml2Canvas(element, false, renderScreenshotHtml2Canvas);
    }
}

function elementSelectorScreenshot(selector) {
    const element = document.querySelector(selector);

    if (!element) {
        console.log('Can not find the element: ' + selector);
        return;
    }

    elementInspectorScreenshot(element);
}

// 获取图像的 DataURL
// getSelectorImageBase64('#my-image', openImageInWindow);
// getSelectorImageBase64('#my-image', logDataURL);
const logDataURL = (dataUrl) => console.log(dataUrl);

function getSelectorImageBase64(selector, callback) {
    const image = document.querySelector(selector);
    if (!image) callback('');

    const timestamp = new Date().getTime();
    const imageUrl = image.src;

    let img = new Image();

    img.onload = function() {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');

        canvas.width = img.naturalWidth || img.width;
        canvas.height = img.naturalHeight || img.height;

        ctx.drawImage(img, 0, 0);
        callback(canvas.toDataURL('image/png'));
    }

    img.setAttribute('crossOrigin', 'anonymous');
    img.src = imageUrl + '?v=' + timestamp;

    // make sure the load event fires for cached images too
    if ( img.complete || img.complete === undefined ) {
        img.src = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==";
        img.src = imageUrl;
    }
}

// getBase64FromUrl(url).then(console.log)
// https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
const getImageBase64FromUrl = async (url) => {
    const data = await fetch(url);
    const blob = await data.blob();
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => {
            const base64 = reader.result;
            if (base64.startsWith("data:image")) {
                resolve(base64);
            } else {
                reject(base64);
            }
        }
        reader.readAsDataURL(blob);
    });
}

// 根据图片 URL 获取图片 base64 编码
// https://wiki.greasespot.net/GM.xmlHttpRequest
// fetchImageBase64FromUrl(url).then(console.log)
const fetchImageBase64FromUrl = async (url) => {
    return new Promise((resolve, reject) => {
        let host = window.location.origin + "/";
        GM_xmlhttpRequest({
            method: "get",
            url: url,
            headers: {referer: host},
            responseType: "blob",
            onload: (res) => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    const base64 = reader.result;
                    if (base64.startsWith("data:image")) {
                        resolve(base64);
                    } else {
                        reject(base64);
                    }
                }
                reader.readAsDataURL(res.response);
            },
            onerror: (error) => {
                reject(error);
            }
        });
    });
}

// fetchImageBase64(document.querySelector('#my-image').src, openImageInWindow);
function fetchImageBase64(url, callback) {
    if (url.startsWith("data:image")) callback(url);

    try {
        let host = window.location.origin + "/";
        GM_xmlhttpRequest({
            method: "get",
            url: url,
            headers: {referer: host},
            responseType: "blob",
            onload: (res) => {
                let blob = res.response;
                let oFileReader = new FileReader();
                oFileReader.onloadend = (e) => {
                    let base64 = e.target.result;
                    if (base64.startsWith("data:image")) {
                        callback(base64);
                    }
                };
                oFileReader.readAsDataURL(blob);
            }
        });
    } catch (error) {
        console.log(error);
    }
}

// 仅保留 base64 编码的图片数组
function cutoffNotBase64Images(imgsUrlArray) {
    let resultArr = [];

    imgsUrlArray.forEach((imgUrl, urlIndex) => {
        if (imgUrl.startsWith("data:image") && imgUrl.includes("base64")) {
            resultArr.push(imgUrl);
        }
    });

    return resultArr;
}

// image viewer
// [10 Best JavaScript Image Viewer Libraries in 2022](https://openbase.com/categories/js/best-javascript-image-viewer-libraries)
// [Best Free image viewer In JavaScript & CSS](https://www.cssscript.com/tag/image-viewer/)
// [Viewer.js](https://github.com/fengyuanchen/viewerjs)
// addLinkStylesheetToHead('https://cdn.jsdelivr.net/npm/viewerjs/dist/viewer.min.css');
const imageViewerTemplate = `
    <div id="image-viewer-container">
        <img id="image-viewer-img" src="" alt="">
    </div>
`;

function removeImageViewer() {
    const node = document.querySelector("#image-viewer-container");
    if (node) {
        node.parentNode.remove();
    }
}

function imageViewer(dataUrl, altText) {
    const template = document.createElement('div');
    template.innerHTML = imageViewerTemplate.trim();

    template.querySelector("#image-viewer-img").src = dataUrl;
    template.querySelector("#image-viewer-img").alt = altText;

    document.getElementsByTagName("body")[0].appendChild(template);

    function loaded() {
        const zIndex = getMaxZIndex() + 1;
        const viewer = new Viewer(document.getElementById('image-viewer-img'), {
            // inline: true,
            // zIndexInline: `${zIndex}`,
            zIndex: `${zIndex}`,
            // viewed() {
            //     viewer.zoomTo(1);
            // },
            hidden() {
                document.querySelector("#image-viewer-container").parentNode.remove();
                document.querySelector(".viewer-container").remove();
            },
        });

        viewer.show();
    }

    const img = document.querySelector('#image-viewer-img');
    if (img.complete) {
        loaded();
    } else {
        img.addEventListener('load', loaded);
    }
}

// [img-previewer](https://github.com/yue1123/img-previewer)
// https://cdn.jsdelivr.net/npm/img-previewer/dist/img-previewer.min.js
// addLinkStylesheetToHead('https://cdn.jsdelivr.net/npm/img-previewer/dist/index.css');
const imagePreviewerTemplate = `
    <div id="image-viewer-container">
        <img id="image-viewer-img" src="" alt="">
    </div>
`;

function imagePreviewer(dataUrl, altText) {
    const template = document.createElement('div');
    template.innerHTML = imagePreviewerTemplate.trim();

    template.querySelector("#image-viewer-img").src = dataUrl;
    template.querySelector("#image-viewer-img").alt = altText;

    document.getElementsByTagName("body")[0].appendChild(template);

    function loaded() {
        const zIndex = getMaxZIndex() + 1;
        const imgPreviewer = new ImgPreviewer('#image-viewer-container', {
            scrollbar: true,
            style: {
                modalOpacity: 0.8,
                headerOpacity: 0,
                zIndex: `${zIndex}`,
            },
            i18n: {
                RESET: '重置',
                ROTATE_LEFT: '向左旋转',
                ROTATE_RIGHT: '向右旋转',
                CLOSE: '关闭',
                NEXT: '下一张',
                PREV: '上一张',
            },
            onHide() {
                document.querySelector("#image-viewer-container").parentNode.remove();
                document.querySelector("#J_container").remove();
            }
        });

        imgPreviewer.show(0);

        // document.querySelector("#image-viewer-container").style.overflow = 'hidden';
        // document.querySelector("#image-viewer-container").style.zIndex = -99999;
        document.querySelector("#image-viewer-container").style.display = 'none';
    }

    const img = document.querySelector('#image-viewer-img');
    if (img.complete) {
        loaded();
    } else {
        img.addEventListener('load', loaded);
    }
}

function renderImageViewer(dataUrl, altText, viewer) {
    switch (viewer) {
        case 'image-viewer':
            imageViewer(dataUrl, altText);
            break;
        default: // 'img-previewer'
            imagePreviewer(dataUrl, altText);
    }
}

// HTML 转 Markdown
function getSelectionHTML() {
    const userSelection = window.getSelection();
    const range = userSelection.getRangeAt(0);
    const clonedSelection = range.cloneContents();

    const divSelection = document.createElement('div');
    divSelection.appendChild(clonedSelection);
    const selectionHTML = divSelection.innerHTML;

    divSelection.remove();

    return selectionHTML;
}

function getSelectionText() {
    return window.getSelection().toString();
}

function getActiveElementContent() {
    return document.activeElement.textContent || '';
}

function getDocumentTitle() {
    return document.title;
}

async function writeTextToClipboard(text) {
    try {
        return await navigator.clipboard.writeText(text);
    } catch (e) {
        const textarea = document.createElement('textarea');
        textarea.textContent = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('Copy', false);
        document.body.removeChild(textarea);
    }
}

function convertHtmlToSafeHTML(html) {
    const template = document.createElement('template');
    template.innerHTML = html;
    const fragment = template.content;
    fragment.querySelectorAll(['script', 'style', 'link', 'meta'].join(', ')).forEach(ele => ele.remove());

    const templateHTML = template.innerHTML;

    template.remove();

    return templateHTML;
}

function convertUrlToAbsoluteURL(relativeUrl, baseUrl) {
    try {
        return new URL(relativeUrl, baseUrl).href;
    } catch (e) {
        return relativeUrl;
    }
}

function isRelativeUrl(url) {
    try {
        const obj = new URL(url);
        return false;
    } catch (e) {
        return true;
    }
}

function isAbsoluteURL(url) {
    try {
        const obj = new URL(url);
        return true;
    } catch (e) {
        return false;
    }
}

function convertHtmlToAbsoluteLinkHTML(html, baseUrl) {
    const template = document.createElement('template');
    template.innerHTML = html;
    const fragment = template.content;

    fragment.querySelectorAll('[href]').forEach(ele => {
        const url = ele.getAttribute('href');
        if (isRelativeUrl(url)) {
            ele.setAttribute('href', convertUrlToAbsoluteURL(url, baseUrl));
        }
    });

    fragment.querySelectorAll('[src]').forEach(ele => {
        const url = ele.getAttribute('src');
        if (isRelativeUrl(url)) {
            ele.setAttribute('src', convertUrlToAbsoluteURL(url, baseUrl));
        }
    });

    const templateHTML = template.innerHTML;

    template.remove();

    return templateHTML;
}

function convertHtmlToRelativeLinkHTML(html, baseUrl) {
    const template = document.createElement('template');
    template.innerHTML = html;
    const fragment = template.content;

    fragment.querySelectorAll('[href]').forEach(ele => {
        const url = ele.getAttribute('href');
        if (isAbsoluteURL(url)) {
            ele.setAttribute('href', convertUrlToRelativeURL(url, baseUrl));
        }
    });

    fragment.querySelectorAll('[src]').forEach(ele => {
        const url = ele.getAttribute('src');
        if (isAbsoluteURL(url)) {
            ele.setAttribute('src', convertUrlToRelativeURL(url, baseUrl));
        }
    });

    const templateHTML = template.innerHTML;

    template.remove();

    return templateHTML;
}

function convertHtmlToRootRelativeLinkHTML(html, baseUrl) {
    const template = document.createElement('template');
    template.innerHTML = html;
    const fragment = template.content;

    fragment.querySelectorAll('[href]').forEach(ele => {
        const url = ele.getAttribute('href');
            ele.setAttribute('href', convertUrlToRootRelativeURL(url, baseUrl));
    });

    fragment.querySelectorAll('[src]').forEach(ele => {
        const url = ele.getAttribute('src');
        ele.setAttribute('src', convertUrlToRootRelativeURL(url, baseUrl));
    });

    const templateHTML = template.innerHTML;

    template.remove();

    return templateHTML;
}

function convertHtmlToFormattedLinkHTML(html, baseUrl, urlFormat) {
    switch (urlFormat) {
        case 'absolute':
            return convertHtmlToAbsoluteLinkHTML(html, baseUrl);
        case 'relative':
            return convertHtmlToRelativeLinkHTML(html, baseUrl);
        case 'root-relative':
            return convertHtmlToRootRelativeLinkHTML(html, baseUrl);
        default: // original
            return html;
    }
}

// https://github.com/beautify-web/js-beautify
function convertHtmlToBeautifyHTML(html) {
    return html_beautify(html);
}

// [An HTML to Markdown converter written in JavaScript](https://github.com/mixmark-io/turndown)
function createTurndownServiceCommonmarkMarkdown() {
    return new TurndownService({
        headingStyle: 'atx',
        hr: '---',
        bulletListMarker: '*',
        codeBlockStyle: 'fenced',
        fence: '```',
        emDelimiter: '*',
        strongDelimiter: '**',
        linkStyle: 'inlined',
        keepReplacement(content) {
            return content
        }
    }).addRule('strikethrough', {
        filter: ['del', 's', 'strike'],
        replacement(content) {
            return '~~' + content + '~~'
        }
    });
}

function createTurndownServiceGfmMarkdown() {
    return new TurndownService({
        headingStyle: 'atx',
        hr: '---',
        bulletListMarker: '*',
        codeBlockStyle: 'fenced',
        fence: '```',
        emDelimiter: '*',
        strongDelimiter: '**',
        linkStyle: 'inlined',
        keepReplacement(content) {
            return content
        }
    });
}

function createTurndownServiceGhostMarkdown() {
    return new TurndownService({
        headingStyle: 'atx',
        hr: '---',
        bulletListMarker: '*',
        codeBlockStyle: 'fenced',
        fence: '```',
        emDelimiter: '*',
        strongDelimiter: '**',
        linkStyle: 'inlined',
        keepReplacement(content) {
            return content
        }
    }).addRule('strikethrough', {
            filter: ['del', 's', 'strike'],
            replacement(content) {
                return '~~' + content + '~~'
            }
        }
    );
}

// convertHtmlToCommonmarkMarkdown('<h1>Hello world!</h1>')
function convertHtmlToCommonmarkMarkdown(html) {
    const turndownService = createTurndownServiceCommonmarkMarkdown();
    return turndownService.turndown(html);
}

function convertHtmlToGfmMarkdown(html) {
    const turndownService = createTurndownServiceGfmMarkdown();
    TurndownPluginGfmService.gfm(turndownService);
    return turndownService.turndown(html);
}

function convertHtmlToGhostMarkdown(html) {
    const turndownService = createTurndownServiceGhostMarkdown();
    TurndownPluginGfmService.gfm(turndownService);
    return turndownService.turndown(html);
}

function removeExtraLine(text) {
    return text.replace(/^\s+^/mg, '\n').replace(/$\s+$/mg, '\n');
}

function removeLineTailBlank(text) {
    return text.split('\n').map(line => line.trimRight()).join('\n');
}

function convertMarkdownToBeautifyMarkdown(text) {
    return removeExtraLine(removeLineTailBlank(text));
}

// https://github.com/stonehank/html-to-md
function convertHtmlToMD(html) {
    return html2md(html);
}

// 等待图片加载完成
const waitForImageLoaded = (img) => {
    return new Promise((resolve, reject) => {
        if (img.complete) {
            return resolve();
        }
        img.onload = () => resolve();
        img.onerror = () => reject(img);
    });
}

// 将指定元素的图片替换为 base64 格式
function replaceElementImageWithBase64(element, baseUrl, callback) {
    images = Array.from(element.querySelectorAll('img'));

    return Promise.all(
        images.map(async (img) => {
            let imgBase64;
            let imgUrl = img.src;

            if (imgUrl.startsWith("data:image")) {
                imgBase64 = imgUrl;
            } else {
                imgUrl = convertUrlToAbsoluteURL(imgUrl, baseUrl);

                try {
                    // imgBase64 = await getImageBase64FromUrl(imgUrl);
                    imgBase64 = await fetchImageBase64FromUrl(imgUrl);
                } catch(error) {
                    console.log(error);
                }

                try {
                    img.src = imgBase64;
                    await waitForImageLoaded(img);
                } catch(error) {
                    console.log(error);
                }
            }
        })
    ).then(() => {
        callback();
    });
}

// 将指定元素的图片转为 base64 格式，返回数组 imgData {src: '', dataurl: '', alt: '', title: ''}
function convertElementImageToBase64(element, baseUrl, callback) {
    images = Array.from(element.querySelectorAll('img'));

    return Promise.all(
        images.map(async (img) => {
            let imgUrl = img.src;
            let imgAlt = img.alt || '';
            let imgTitle = img.title || '';

            let imgData = {};
            let imgBase64;

            if (imgUrl.startsWith("data:image")) {
                imgBase64 = imgUrl;
            } else {
                imgUrl = convertUrlToAbsoluteURL(imgUrl, baseUrl);

                // imgBase64 = await getImageBase64FromUrl(imgUrl);
                imgBase64 = await fetchImageBase64FromUrl(imgUrl);
            }

            return new Promise((resolve, reject) => {
                if (imgBase64.startsWith("data:image")) {
                    imgData['src'] = imgUrl;
                    imgData['dataurl'] = imgBase64;
                    imgData['alt'] = imgAlt;
                    imgData['title'] = imgTitle;

                    resolve(imgData);
                } else {
                    reject('');
                }
            });
        })
    ).then((results) => {
        callback(results);
    });
}

// 将 Markdown 中的 base64 图片转移到脚注
function markdownBase64ImageToFootnote(text, imgData) {
    let mdText = text;
    let mdTitle = `# [${siteTitle}](${siteHref})\n\n`;
    let imgFoot = '\n\n';

    let altText, url, base64, imgTitle, imgFootLink;
    let usedFootLink = [], usedUrl = [];
    let emptyFootLinkCount = 0;

    // ![image description](data:image/png;base64,...)
    const reBase64 = new RegExp(/\!\[([^\[\]]*)\](\((data:image\/[^;]+;base64[^'"()]+)\s*['"]?([^'"()]*)['"]?\s*\))/gi);
    let match = reBase64.exec(text);
    do {
        if (match) {
            altText = match[1];
            url = match[2];
            base64 = match[3];
            imgTitle = match[4];

            if (!imgTitle) imgTitle = altText;

            imgFootLink = imgTitle;
            if (!imgFootLink) {
                imgFootLink = imgFootLink.replace(/[~`!@#$%^&*()+={}\[\];:\'\"<>.,\/\\\?-_\s\n]/g, '');
            }
            if (!imgFootLink || usedFootLink.includes(imgFootLink) || imgFootLink.startsWith("http") || imgFootLink.startsWith("ftp")) {
                emptyFootLinkCount++;
                imgFootLink = `图片${emptyFootLinkCount}`;
            }
            usedFootLink.push(imgFootLink);

            if (imgTitle) {
                imgFoot = `${imgFoot}[${imgFootLink}]: ${base64} "${imgTitle}"\n`;
            } else {
                imgFoot = `${imgFoot}[${imgFootLink}]: ${base64}\n`;
            }

            mdText = mdText.replaceAll(url, `[${imgFootLink}]`);
        }
    } while ((match = reBase64.exec(text)) !== null);

    // ![image description](https://...)
    // const reUrl = new RegExp(/\!\[([^\[\]]*)\](\(((?!data:image)[^'"()]+)\s*['"]?([^'"()]*)['"]?\s*\))/gi);

    // imgData[]
    for (let id in imgData) {
        url = imgData[id]['src'];

        if (usedUrl.includes(url)) {
            imgData[id]['used'] = true;
        } else {
            imgData[id]['used'] = false;
        }

        usedUrl.push(url);
    }

    for (let id in imgData) {
        if (imgData[id]['used']) continue;

        altText = imgData[id]['alt'];
        url = imgData[id]['src'];
        base64 = imgData[id]['dataurl'];
        imgTitle = imgData[id]['title'];

        if (!imgTitle) imgTitle = altText;

        imgFootLink = imgTitle;
        if (!imgFootLink) {
            imgFootLink = imgFootLink.replace(/[~`!@#$%^&*()+={}\[\];:\'\"<>.,\/\\\?-_\s\n]/g, '');
        }
        if (!imgFootLink || usedFootLink.includes(imgFootLink) || imgFootLink.startsWith("http") || imgFootLink.startsWith("ftp")) {
            emptyFootLinkCount++;
            imgFootLink = `图片${emptyFootLinkCount}`;
        }
        usedFootLink.push(imgFootLink);

        if (imgTitle) {
            imgFoot = `${imgFoot}[${imgFootLink}]: ${base64} "${imgTitle}"\n`;
        } else {
            imgFoot = `${imgFoot}[${imgFootLink}]: ${base64}\n`;
        }

        mdText = mdText.replace(`(${url})`, `[${imgFootLink}]`);
    }

    mdText = `${mdTitle}${mdText}${imgFoot}`;

    return mdText;
}

// 将 HTML 转为指定的 Markdown 格式
// convertHtmlToMarkdown(html, siteHref, MARKDOWN_FLAVOR, MARKDOWN_URL_FORMAT)
function convertHtmlToMarkdown(html, baseUrl, markdownFlavor, urlFormat) {
    let htmlText, markdownText;

    htmlText = convertHtmlToBeautifyHTML(
        convertHtmlToFormattedLinkHTML(convertHtmlToSafeHTML(html), baseUrl, urlFormat)
    );

    switch (markdownFlavor) {
        case 'commonmark':
            markdownText = convertHtmlToCommonmarkMarkdown(htmlText);
            break;
        case 'gfm':
            markdownText = convertHtmlToGfmMarkdown(htmlText);
            break;
        case 'ghost':
            markdownText = convertHtmlToGhostMarkdown(htmlText);
            break;
        default: // html2md
            markdownText = convertHtmlToMD(htmlText);
    }

    markdownText = convertMarkdownToBeautifyMarkdown(markdownText);

    return markdownText;
}

// 将指定元素转为 Markdown 格式
function convertElementToMarkdown(element) {
    return convertHtmlToMarkdown(element.innerHTML, siteHref, MARKDOWN_FLAVOR, MARKDOWN_URL_FORMAT);
}

function elementSelectorToMarkdown(selector) {
    const element = document.querySelector(selector);

    if (!element) {
        console.log('Can not find the element: ' + selector);
        return;
    }

    return convertElementToMarkdown(element);
}

// 鼠标高亮元素转为 Markdown
function elementInspectorToMarkdown(element) {
    let htmlText, markdownText;

    // 停止鼠标滑动高亮元素
    stopElementInspector();

    // 提示
    addLoadingIndicator('curtain', '处理中...', 'data-colorful');

    // 将元素的图片转为 base64 格式
    convertElementImageToBase64(element, siteHref, (imgData) => {
        // 获取元素 HTML
        htmlText = convertHtmlToBeautifyHTML(
                convertHtmlToFormattedLinkHTML(convertHtmlToSafeHTML(element.innerHTML), siteHref, MARKDOWN_URL_FORMAT)
            );

        // 获取 Markdown
        switch (MARKDOWN_FLAVOR) {
            case 'commonmark':
                markdownText = convertHtmlToCommonmarkMarkdown(htmlText);
                break;
            case 'gfm':
                markdownText = convertHtmlToGfmMarkdown(htmlText);
                break;
            case 'ghost':
                markdownText = convertHtmlToGhostMarkdown(htmlText);
                break;
            default: // html2md
                markdownText = convertHtmlToMD(htmlText);
        }

        markdownText = convertMarkdownToBeautifyMarkdown(markdownText);
        markdownText = markdownBase64ImageToFootnote(markdownText, imgData);

        // 移除提示
        removeLoadingIndicator();

        // 渲染为 Markdown
        renderHtml2MD(htmlText, markdownText);
    });
}

// Selection to Markdown
function extractSelectionText(range) {
    const fragment = range.cloneContents();
    const nodes = Array.from(fragment.childNodes);
    return nodes.map(
        node => node.textContent
    ).join('').trim();
}

function selectionToMarkdown() {
    const selection = window.getSelection();
    if (selection.isCollapsed) return;

    const currentRange = selection.getRangeAt(0);

    const divSelection = document.createElement('div');
    divSelection.appendChild(currentRange.cloneContents());

    // 提示
    addLoadingIndicator('curtain', '处理中...', 'data-colorful');

    // 将元素的图片转为 base64 格式
    convertElementImageToBase64(divSelection, siteHref, (imgData) => {
        // 获取元素 HTML
        htmlText = convertHtmlToBeautifyHTML(
                convertHtmlToFormattedLinkHTML(convertHtmlToSafeHTML(divSelection.innerHTML), siteHref, MARKDOWN_URL_FORMAT)
            );

        // 获取 Markdown
        switch (MARKDOWN_FLAVOR) {
            case 'commonmark':
                markdownText = convertHtmlToCommonmarkMarkdown(htmlText);
                break;
            case 'gfm':
                markdownText = convertHtmlToGfmMarkdown(htmlText);
                break;
            case 'ghost':
                markdownText = convertHtmlToGhostMarkdown(htmlText);
                break;
            default: // html2md
                markdownText = convertHtmlToMD(htmlText);
        }

        markdownText = convertMarkdownToBeautifyMarkdown(markdownText);
        markdownText = markdownBase64ImageToFootnote(markdownText, imgData);

        // 移除提示
        removeLoadingIndicator();

        // 渲染为 Markdown
        renderHtml2MD(htmlText, markdownText);
    });
}

// HTML to Markdown render page
const html2mdTemplate = `
    <div id="html-md-container" class="viewer-container viewer-backdrop viewer-fixed viewer-fade viewer-transition viewer-in" tabindex="-1" touch-action="none" role="dialog" style="z-index: 2015;">
        <div id="html-md" class="viewer-canvas">
            <div class="infoWrap">
                <span class="info">html</span>
                <span class="info">markdown</span>
            </div>
            <div id="wrap" class="markdown-body ">
                <textarea id="inputHTML" class="syncScrTxt"></textarea>
                <textarea id="outputMD" readonly class="syncScrTxt"></textarea>
            </div>
            <div>
                <label for="syncScrBtn" id="syncScrBtnRender">sync scroll</label>
                <input type="checkbox" id="syncScrBtn" checked style="font-size:1rem" />
            </div>
        </div>
        <div class="viewer-button viewer-close" role="button" tabindex="0"></div>
    </div>

    <style>
        .viewer-container {
            -webkit-tap-highlight-color: transparent;
            -webkit-touch-callout: none;
            bottom: 0;
            direction: ltr;
            font-size: 0;
            left: 0;
            line-height: 0;
            overflow: hidden;
            position: absolute;
            right: 0;
            top: 0;
            -ms-touch-action: none;
            touch-action: none;
            -webkit-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none
        }

        .viewer-container ::-moz-selection,.viewer-container::-moz-selection {
            background-color: transparent
        }

        .viewer-container ::selection,.viewer-container::selection {
            background-color: transparent
        }

        .viewer-container:focus {
            outline: 0
        }

        .viewer-button {
            -webkit-app-region: no-drag;
            background-color: rgba(0,0,0,0.5);
            border-radius: 50%;
            cursor: pointer;
            height: 80px;
            overflow: hidden;
            position: absolute;
            right: -40px;
            top: -40px;
            transition: background-color .15s;
            width: 80px
        }

        .viewer-button:focus,.viewer-button:hover {
            background-color: rgba(0,0,0,0.8)
        }

        .viewer-button:focus {
            box-shadow: 0 0 3px #fff;
            outline: 0
        }

        .viewer-button:before {
            bottom: 15px;
            left: 15px;
            position: absolute
        }

        .viewer-close:before,.viewer-flip-horizontal:before,.viewer-flip-vertical:before,.viewer-fullscreen-exit:before,.viewer-fullscreen:before,.viewer-next:before,.viewer-one-to-one:before,.viewer-play:before,.viewer-prev:before,.viewer-reset:before,.viewer-rotate-left:before,.viewer-rotate-right:before,.viewer-zoom-in:before,.viewer-zoom-out:before {
            background-image: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAARgAAAAUCAYAAABWOyJDAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAALEgAACxIB0t1+/AAAABx0RVh0U29mdHdhcmUAQWRvYmUgRmlyZXdvcmtzIENTNui8sowAAAQPSURBVHic7Zs/iFxVFMa/0U2UaJGksUgnIVhYxVhpjDbZCBmLdAYECxsRFBTUamcXUiSNncgKQbSxsxH8gzAP3FU2jY0kKKJNiiiIghFlccnP4p3nPCdv3p9778vsLOcHB2bfveeb7955c3jvvNkBIMdxnD64a94GHMfZu3iBcRynN7zAOI7TG15gHCeeNUkr8zaxG2lbYDYsdgMbktBsP03jdQwljSXdtBhLOmtjowC9Mg9L+knSlcD8TNKpSA9lBpK2JF2VdDSR5n5J64m0qli399hNFMUlpshQii5jbXTbHGviB0nLNeNDSd9VO4A2UdB2fp+x0eCnaXxWXGA2X0au/3HgN9P4LFCjIANOJdrLr0zzZ+BEpNYDwKbpnQMeAw4m8HjQtM6Z9qa917zPQwFr3M5KgA6J5rTJCdFZJj9/lyvGhsDvwFNVuV2MhhjrK6b9bFiE+j1r87eBl4HDwCF7/U/k+ofAX5b/EXBv5JoLMuILzf3Ap6Z3EzgdqHMCuF7hcQf4HDgeoHnccncqdK/TvSDWffFXI/exICY/xZyqc6XLWF1UFZna4gJ7q8BsRvgd2/xXpo6P+D9dfT7PpECtA3cnWPM0GXGFZh/wgWltA+cDNC7X+AP4GzjZQe+k5dRxuYPeiuXU7e1qwLpDz7dFjXKRaSwuMLvAlG8zZlG+YmiK1HoFqT7wP2z+4Q45TfEGcMt01xLoNZEBTwRqD4BLpnMLeC1A41UmVxsXgXeBayV/Wx20rpTyrpnWRft7p6O/FdqzGrDukPNtkaMoMo3FBdBSQMOnYBCReyf05s126fU9ytfX98+mY54Kxnp7S9K3kj6U9KYdG0h6UdLbkh7poFXMfUnSOyVvL0h6VtIXHbS6nOP+s/Zm9mvyXW1uuC9ohZ72E9uDmXWLJOB1GxsH+DxPftsB8B6wlGDN02TAkxG6+4D3TWsbeC5CS8CDFce+AW500LhhOW2020TRjK3b21HEmgti9m0RonxbdMZeVzV+/4tF3cBpP7E9mKHNL5q8h5g0eYsCMQz0epq8gQrwMXAgcs0FGXGFRcB9wCemF9PkbYqM/Bas7fxLwNeJPdTdpo4itQti8lPMqTpXuozVRVXPpbHI3KkNTB1NfkL81j2mvhDp91HgV9MKuRIqrykj3WPq4rHyL+axj8/qGPmTqi6F9YDlHOvJU6oYcTsh/TYSzWmTE6JT19CtLTJt32D6CmHe0eQn1O8z5AXgT4sx4Vcu0/EQecMydB8z0hUWkTd2t4CrwNEePqMBcAR4mrBbwyXLPWJa8zrXmmLEhNBmfpkuY2102xxrih+pb+ieAb6vGhuA97UcJ5KR8gZ77K+99xxeYBzH6Q3/Z0fHcXrDC4zjOL3hBcZxnN74F+zlvXFWXF9PAAAAAElFTkSuQmCC");
            background-repeat: no-repeat;
            background-size: 280px;
            color: transparent;
            display: block;
            font-size: 0;
            height: 20px;
            line-height: 0;
            width: 20px
        }

        .viewer-close:before {
            background-position: -260px 0;
            content: "Close"
        }

        .viewer-fixed {
            position: fixed
        }

        .viewer-open {
            overflow: hidden
        }

        .viewer-show {
            display: block
        }

        .viewer-hide {
            display: none
        }

        .viewer-backdrop {
            background-color: rgba(0,0,0,0.5)
        }

        .viewer-invisible {
            visibility: hidden
        }

        .viewer-move {
            cursor: move;
            cursor: -webkit-grab;
            cursor: grab
        }

        .viewer-fade {
            opacity: 0
        }

        .viewer-in {
            opacity: 1
        }

        .viewer-transition {
            transition: all 0.3s
        }

        .viewer-container img {
            display: block;
            height: auto;
            max-height: none!important;
            max-width: none!important;
            min-height: 0!important;
            min-width: 0!important;
            width: 100%
        }

        .viewer-canvas {
            bottom: 0;
            left: 0;
            overflow: hidden;
            position: absolute;
            right: 0;
            top: 0
        }

        .viewer-canvas>img {
            height: auto;
            margin: 15px auto;
            max-width: 90%!important;
            width: auto
        }

        #html-md {
            font-size: 16px;
            line-height: 1.5;
            background: lightgreen;
        }

        .infoWrap {
            display: flex;
            justify-content: space-evenly;
            height: 30px;
        }

        .info {
            font-size: 1rem;
            font-weight: bold;
        }

        #wrap {
            display: flex;
            justify-content: space-between;
            margin: 8px;
        }

        #html-md .syncScrTxt {
            font-size: 0.8rem;
            width: 48%;
            resize: horizontal;
            min-width: 20%;
            height: 85vh;
        }

        #html-md #inputHTML {
            border: 1px solid #a9a9a9;
            overflow: auto;
        }

        #html-md #outputMD {
            resize: none;
            flex: 1;
        }

        textarea {
            line-height: 1.5;
        }

        #syncScrBtnRender {
            border: 1px;
            padding: 0.2rem;
            border-radius: 4px;
            margin: 0.5rem;
            display: inline-block;
            cursor: pointer;
        }
    </style>
`;

function renderHtml2MD(html, markdown) {
    const template = document.createElement('div');
    template.innerHTML = html2mdTemplate.trim();

    template.querySelector("#inputHTML").value = html;
    template.querySelector("#outputMD").value = markdown;

    // const viewer = template.querySelector("#html-md-container");
    // const cssStyles = {
    //     backgroundcolor: "transparent",
    // };
    // for (let style in cssStyles) {
    //     viewer.style[style] = cssStyles[style];
    // }

    document.getElementsByTagName("body")[0].appendChild(template);

    // 同步滚动
    function html2MDSyncScroll() {
        let delay = false, timer = null;
        let syncScrTxt = document.getElementsByClassName('syncScrTxt'),
            syncScrBtn = document.getElementById('syncScrBtn');

        function syncScroll(ev) {
            let ele = ev.target;
            if (!delay) {
                clearTimeout(timer);
                delay = true;
                if (ele.className === 'syncScrTxt') {
                    let scrRatio = ele.scrollTop / ele.scrollHeight;
                    for (let j = 0; j < syncScrTxt.length; j++) {
                        if (syncScrTxt[j] === ele) continue;
                        syncScrTxt[j].scrollTo({
                            top: syncScrTxt[j].scrollHeight * scrRatio,
                        });
                    }
                }
                timer = setTimeout(() => {
                    delay = false;
                }, 30);
            }
        }

        function bindScr(syncScrTxt) {
            for (let i = 0; i < syncScrTxt.length; i++) {
                let ele = syncScrTxt[i];
                ele.addEventListener('scroll', syncScroll);
            }
        }

        function unbindScr(syncScrTxt) {
            for (let i = 0; i < syncScrTxt.length; i++) {
                let ele = syncScrTxt[i];
                ele.removeEventListener('scroll', syncScroll);
            }
        }

        function toggleSyncScroll(ev) {
            if (ev.target.checked) {
                bindScr(syncScrTxt);
            } else {
                unbindScr(syncScrTxt);
            }
        }

        function checkIfBindScr() {
            let checked = syncScrBtn.checked;
            if (checked) {
                bindScr(syncScrTxt);
            } else {
                unbindScr(syncScrTxt);
            }
        }

        syncScrBtn.addEventListener('change', toggleSyncScroll);
        checkIfBindScr();
    }

    // 关闭
    function closeViewer() {
        document.querySelector("#html-md-container").parentNode.remove();
    }

    document.querySelector(".viewer-button.viewer-close").addEventListener("click", closeViewer);

    html2MDSyncScroll();
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

// 转 PDF
// [dompdf](https://github.com/lmn1919/dompdf.js)
function getElementPDFDompdf(element, callback) {
    const pageBackgroundColor = getPageBackgroundColor();
    dompdf(element, {
        useCORS: true,
        backgroundColor: pageBackgroundColor,
        fontConfig: {
            fontFamily: 'SourceHanSansSC-Normal-Min',
            fontBase64: window.fontBase64,
        },
        pagination: true,
        format: "a4",
        pageConfig: {
            header: {
                content: siteTitle,
                height: 50,
                contentColor: "#333333",
                contentFontSize: 12,
                contentPosition: "center",
                padding: [0, 0, 0, 0],
            },
            footer: {
                content: "第 ${currentPage} 页/共 ${totalPages} 页",
                height: 50,
                contentColor: "#333333",
                contentFontSize: 12,
                contentPosition: "center",
                padding: [0, 0, 0, 0],
            },
        },
    }).then((blob) => {
        callback(blob);
    }).catch((err) => {
        callback('');
    });
}

// [Snapdom with pdfExport plugin](https://github.com/zumerlab/snapdom)
async function getElementPDFSnapdom(element, callback) {
    const pageBackgroundColor = getPageBackgroundColor();

    const out = await snapdom(element, {
        backgroundColor: pageBackgroundColor,
        plugins: [pdfExportPlugin()]
    });

    const pdfBlob = await out.toPdf();
    if (pdfBlob) {
        callback(pdfBlob);
    } else {
        callback('');
    }
}

function elementInspectorToPDF(element) {
    // 停止鼠标滑动高亮元素
    stopElementInspector();

    // 提示
    addLoadingIndicator('curtain', '处理中...', 'data-colorful');

    // use dompdf to convert element to pdf
    const renderDom2PDF = function(blob) {
        // 移除提示
        removeLoadingIndicator();
        if (blob) {
            // downloadPDF(blob);
            previewPDF(blob);
        }
    }

    getElementPDFDompdf(element, renderDom2PDF);
    // getElementPDFSnapdom(element, renderDom2PDF);
}

function elementSelectorToPDF(selector) {
    const element = document.querySelector(selector);

    if (!element) {
        console.log('Can not find the element: ' + selector);
        return;
    }

    elementInspectorToPDF(element);
}


//下载 PDF
function downloadPDF(blob) {
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = siteTitle.replace(/[/\\?%*:|"<>\s]/g, '-').replace(/[-]+/g,'-') + '.pdf';
    document.body.appendChild(a);
    a.click();
}

// 预览 PDF
function previewPDF(blob) {
    const url = URL.createObjectURL(blob);
    window.open(url);
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

// add css stylesheet to HEAD
function addStylesheetToHead(style, styleID) {
    const cssStyle = document.createElement('style');
    cssStyle.id = styleID;
    cssStyle.innerHTML = style;

    const head = document.getElementsByTagName('head');
    const headList = Array.from(head);
    headList.forEach(node => {
        node.appendChild(cssStyle);
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

function getMaxZIndex() {
    return Math.max(
        ...Array.from(document.querySelectorAll('body *'), el =>
            parseFloat(window.getComputedStyle(el).zIndex),
        ).filter(zIndex => !Number.isNaN(zIndex)),
        0,
    );
}

// CSS 样式
// https://cdn.jsdelivr.net/npm/pure-css-loader/dist/css-loader.css
const loderStyle = `
.loader {
	color: #fff;
	position: fixed;
	box-sizing: border-box;
	left: -9999px;
	top: -9999px;
	width: 0;
	height: 0;
	overflow: hidden;
	z-index: 999999;
}
.loader:after,
.loader:before {
	box-sizing: border-box;
	display: none;
}
.loader.is-active {
	background-color: rgba(0, 0, 0, 0.85);
	width: 100%;
	height: 100%;
	left: 0;
	top: 0;
}
.loader.is-active:after,
.loader.is-active:before {
	display: block;
}
@keyframes rotation {
	0% {
		transform: rotate(0);
	}
	to {
		transform: rotate(359deg);
	}
}
@keyframes blink {
	0% {
		opacity: 0.5;
	}
	to {
		opacity: 1;
	}
}
.loader[data-text]:before {
	position: fixed;
	left: 0;
	top: 50%;
	color: currentColor;
	font-family: Helvetica, Arial, sans-serif;
	text-align: center;
	width: 100%;
	font-size: 14px;
}
.loader[data-text='']:before {
	content: 'Loading';
}
.loader[data-text]:not([data-text='']):before {
	content: attr(data-text);
}
.loader[data-text][data-blink]:before {
	animation: blink 1s linear infinite alternate;
}
.loader-default[data-text]:before {
	top: calc(50% - 63px);
}
.loader-default:after {
	content: '';
	position: fixed;
	width: 48px;
	height: 48px;
	border: 8px solid #fff;
	border-left-color: transparent;
	border-radius: 50%;
	top: calc(50% - 24px);
	left: calc(50% - 24px);
	animation: rotation 1s linear infinite;
}
.loader-default[data-half]:after {
	border-right-color: transparent;
}
.loader-default[data-inverse]:after {
	animation-direction: reverse;
}
.loader-double:after,
.loader-double:before {
	content: '';
	position: fixed;
	border-radius: 50%;
	border: 8px solid;
	animation: rotation 1s linear infinite;
}
.loader-double:after {
	width: 48px;
	height: 48px;
	border-color: #fff;
	border-left-color: transparent;
	top: calc(50% - 24px);
	left: calc(50% - 24px);
}
.loader-double:before {
	width: 64px;
	height: 64px;
	border-color: #eb974e;
	border-right-color: transparent;
	animation-duration: 2s;
	top: calc(50% - 32px);
	left: calc(50% - 32px);
}
.loader-bar[data-text]:before {
	top: calc(50% - 40px);
	color: #fff;
}
.loader-bar:after {
	content: '';
	position: fixed;
	top: 50%;
	left: 50%;
	width: 200px;
	height: 20px;
	transform: translate(-50%, -50%);
	background: linear-gradient(
		-45deg,
		#4183d7 25%,
		#52b3d9 0,
		#52b3d9 50%,
		#4183d7 0,
		#4183d7 75%,
		#52b3d9 0,
		#52b3d9
	);
	background-size: 20px 20px;
	box-shadow: inset 0 10px 0 hsla(0, 0%, 100%, 0.2), 0 0 0 5px rgba(0, 0, 0, 0.2);
	animation: moveBar 1.5s linear infinite reverse;
}
.loader-bar[data-rounded]:after {
	border-radius: 15px;
}
.loader-bar[data-inverse]:after {
	animation-direction: normal;
}
@keyframes moveBar {
	0% {
		background-position: 0 0;
	}
	to {
		background-position: 20px 20px;
	}
}
.loader-bar-ping-pong:before {
	width: 200px;
	background-color: #000;
}
.loader-bar-ping-pong:after,
.loader-bar-ping-pong:before {
	content: '';
	height: 20px;
	position: absolute;
	top: calc(50% - 10px);
	left: calc(50% - 100px);
}
.loader-bar-ping-pong:after {
	width: 50px;
	background-color: #f19;
	animation: moveBarPingPong 0.5s linear infinite alternate;
}
.loader-bar-ping-pong[data-rounded]:before {
	border-radius: 10px;
}
.loader-bar-ping-pong[data-rounded]:after {
	border-radius: 50%;
	width: 20px;
	animation-name: moveBarPingPongRounded;
}
@keyframes moveBarPingPong {
	0% {
		left: calc(50% - 100px);
	}
	to {
		left: calc(50% - -50px);
	}
}
@keyframes moveBarPingPongRounded {
	0% {
		left: calc(50% - 100px);
	}
	to {
		left: calc(50% - -80px);
	}
}
@keyframes corners {
	6% {
		width: 60px;
		height: 15px;
	}
	25% {
		width: 15px;
		height: 15px;
		left: calc(100% - 15px);
		top: 0;
	}
	31% {
		height: 60px;
	}
	50% {
		height: 15px;
		top: calc(100% - 15px);
		left: calc(100% - 15px);
	}
	56% {
		width: 60px;
	}
	75% {
		width: 15px;
		left: 0;
		top: calc(100% - 15px);
	}
	81% {
		height: 60px;
	}
}
.loader-border[data-text]:before {
	color: #fff;
}
.loader-border:after {
	content: '';
	position: absolute;
	top: 0;
	left: 0;
	width: 15px;
	height: 15px;
	background-color: #ff0;
	animation: corners 3s ease both infinite;
}
.loader-ball:before {
	content: '';
	position: absolute;
	width: 50px;
	height: 50px;
	top: 50%;
	left: 50%;
	margin: -25px 0 0 -25px;
	background-color: #fff;
	border-radius: 50%;
	z-index: 1;
	animation: kickBall 1s infinite alternate ease-in both;
}
.loader-ball[data-shadow]:before {
	box-shadow: inset -5px -5px 10px 0 rgba(0, 0, 0, 0.5);
}
.loader-ball:after {
	content: '';
	position: absolute;
	background-color: rgba(0, 0, 0, 0.3);
	border-radius: 50%;
	width: 45px;
	height: 20px;
	top: calc(50% + 10px);
	left: 50%;
	margin: 0 0 0 -22.5px;
	z-index: 0;
	animation: shadow 1s infinite alternate ease-out both;
}
@keyframes shadow {
	0% {
		background-color: transparent;
		transform: scale(0);
	}
	40% {
		background-color: transparent;
		transform: scale(0);
	}
	95% {
		background-color: rgba(0, 0, 0, 0.75);
		transform: scale(1);
	}
	to {
		background-color: rgba(0, 0, 0, 0.75);
		transform: scale(1);
	}
}
@keyframes kickBall {
	0% {
		transform: translateY(-80px) scaleX(0.95);
	}
	90% {
		border-radius: 50%;
	}
	to {
		transform: translateY(0) scaleX(1);
		border-radius: 50% 50% 20% 20%;
	}
}
.loader-smartphone:after {
	content: '';
	color: #fff;
	font-size: 12px;
	font-family: Helvetica, Arial, sans-serif;
	text-align: center;
	line-height: 120px;
	position: fixed;
	left: 50%;
	top: 50%;
	width: 70px;
	height: 130px;
	margin: -65px 0 0 -35px;
	border: 5px solid #fd0;
	border-radius: 10px;
	box-shadow: inset 0 5px 0 0 #fd0;
	background: radial-gradient(circle at 50% 90%, rgba(0, 0, 0, 0.5) 6px, transparent 0),
		linear-gradient(0deg, #fd0 22px, transparent 0),
		linear-gradient(0deg, rgba(0, 0, 0, 0.5) 22px, rgba(0, 0, 0, 0.5));
	animation: shake 2s cubic-bezier(0.36, 0.07, 0.19, 0.97) both infinite;
}
.loader-smartphone[data-screen='']:after {
	content: 'Loading';
}
.loader-smartphone:not([data-screen='']):after {
	content: attr(data-screen);
}
@keyframes shake {
	5% {
		transform: translate3d(-1px, 0, 0);
	}
	10% {
		transform: translate3d(1px, 0, 0);
	}
	15% {
		transform: translate3d(-1px, 0, 0);
	}
	20% {
		transform: translate3d(1px, 0, 0);
	}
	25% {
		transform: translate3d(-1px, 0, 0);
	}
	30% {
		transform: translate3d(1px, 0, 0);
	}
	35% {
		transform: translate3d(-1px, 0, 0);
	}
	40% {
		transform: translate3d(1px, 0, 0);
	}
	45% {
		transform: translate3d(-1px, 0, 0);
	}
	50% {
		transform: translate3d(1px, 0, 0);
	}
	55% {
		transform: translate3d(-1px, 0, 0);
	}
}
.loader-clock:before {
	width: 120px;
	height: 120px;
	border-radius: 50%;
	margin: -60px 0 0 -60px;
	background: linear-gradient(180deg, transparent 50%, #f5f5f5 0),
		linear-gradient(90deg, transparent 55px, #2ecc71 0, #2ecc71 65px, transparent 0),
		linear-gradient(180deg, #f5f5f5 50%, #f5f5f5 0);
	box-shadow: inset 0 0 0 10px #f5f5f5, 0 0 0 5px #555, 0 0 0 10px #7b7b7b;
	animation: rotation infinite 2s linear;
}
.loader-clock:after,
.loader-clock:before {
	content: '';
	position: fixed;
	left: 50%;
	top: 50%;
	overflow: hidden;
}
.loader-clock:after {
	width: 60px;
	height: 40px;
	margin: -20px 0 0 -15px;
	border-radius: 20px 0 0 20px;
	background: radial-gradient(circle at 14px 20px, #25a25a 10px, transparent 0),
		radial-gradient(circle at 14px 20px, #1b7943 14px, transparent 0),
		linear-gradient(180deg, transparent 15px, #2ecc71 0, #2ecc71 25px, transparent 0);
	animation: rotation infinite 24s linear;
	transform-origin: 15px center;
}
.loader-curtain:after,
.loader-curtain:before {
	position: fixed;
	width: 100%;
	top: 50%;
	margin-top: -35px;
	font-size: 70px;
	text-align: center;
	font-family: Helvetica, Arial, sans-serif;
	overflow: hidden;
	line-height: 1.2;
	content: 'Loading';
}
.loader-curtain:before {
	color: #666;
}
.loader-curtain:after {
	color: #fff;
	height: 0;
	animation: curtain 1s linear infinite alternate both;
}
.loader-curtain[data-curtain-text]:not([data-curtain-text='']):after,
.loader-curtain[data-curtain-text]:not([data-curtain-text='']):before {
	content: attr(data-curtain-text);
}
.loader-curtain[data-brazilian]:before {
	color: #f1c40f;
}
.loader-curtain[data-brazilian]:after {
	color: #2ecc71;
}
.loader-curtain[data-colorful]:before {
	animation: maskColorful 2s linear infinite alternate both;
}
.loader-curtain[data-colorful]:after {
	animation: curtain 1s linear infinite alternate both, maskColorful-front 2s 1s linear infinite alternate both;
	color: #000;
}
@keyframes maskColorful {
	0% {
		color: #3498db;
	}
	49.5% {
		color: #3498db;
	}
	50.5% {
		color: #e74c3c;
	}
	to {
		color: #e74c3c;
	}
}
@keyframes maskColorful-front {
	0% {
		color: #2ecc71;
	}
	49.5% {
		color: #2ecc71;
	}
	50.5% {
		color: #f1c40f;
	}
	to {
		color: #f1c40f;
	}
}
@keyframes curtain {
	0% {
		height: 0;
	}
	to {
		height: 84px;
	}
}
.loader-music:after,
.loader-music:before {
	content: '';
	position: fixed;
	width: 240px;
	height: 240px;
	top: 50%;
	left: 50%;
	margin: -120px 0 0 -120px;
	border-radius: 50%;
	text-align: center;
	line-height: 240px;
	color: #fff;
	font-size: 40px;
	font-family: Helvetica, Arial, sans-serif;
	text-shadow: 1px 1px 0 rgba(0, 0, 0, 0.5);
	letter-spacing: -1px;
}
.loader-music:after {
	backface-visibility: hidden;
}
.loader-music[data-hey-oh]:after,
.loader-music[data-hey-oh]:before {
	box-shadow: 0 0 0 10px;
}
.loader-music[data-hey-oh]:before {
	background-color: #fff;
	color: #000;
	animation: coinBack 2.5s linear infinite, oh 5s 1.25s linear infinite both;
}
.loader-music[data-hey-oh]:after {
	background-color: #000;
	animation: coin 2.5s linear infinite, hey 5s linear infinite both;
}
.loader-music[data-no-cry]:after,
.loader-music[data-no-cry]:before {
	background: linear-gradient(45deg, #009b3a 50%, #fed100 51%);
	box-shadow: 0 0 0 10px #000;
}
.loader-music[data-no-cry]:before {
	animation: coinBack 2.5s linear infinite, cry 5s 1.25s linear infinite both;
}
.loader-music[data-no-cry]:after {
	animation: coin 2.5s linear infinite, no 5s linear infinite both;
}
.loader-music[data-we-are]:before {
	animation: coinBack 2.5s linear infinite, theWorld 5s 1.25s linear infinite both;
	background: radial-gradient(ellipse at center, #4ecdc4 0, #556270);
}
.loader-music[data-we-are]:after {
	animation: coin 2.5s linear infinite, weAre 5s linear infinite both;
	background: radial-gradient(ellipse at center, #26d0ce 0, #1a2980);
}
.loader-music[data-rock-you]:before {
	animation: coinBack 2.5s linear infinite, rockYou 5s 1.25s linear infinite both;
	background: #444;
}
.loader-music[data-rock-you]:after {
	animation: coin 2.5s linear infinite, weWill 5s linear infinite both;
	background: #96281b;
}
@keyframes coin {
	to {
		transform: rotateY(359deg);
	}
}
@keyframes coinBack {
	0% {
		transform: rotateY(180deg);
	}
	50% {
		transform: rotateY(1turn);
	}
	to {
		transform: rotateY(180deg);
	}
}
@keyframes hey {
	0% {
		content: 'Hey!';
	}
	50% {
		content: "Let's!";
	}
	to {
		content: 'Hey!';
	}
}
@keyframes oh {
	0% {
		content: 'Oh!';
	}
	50% {
		content: 'Go!';
	}
	to {
		content: 'Oh!';
	}
}
@keyframes no {
	0% {
		content: 'No...';
	}
	50% {
		content: 'no';
	}
	to {
		content: 'No...';
	}
}
@keyframes cry {
	0% {
		content: 'woman';
	}
	50% {
		content: 'cry!';
	}
	to {
		content: 'woman';
	}
}
@keyframes weAre {
	0% {
		content: 'We are';
	}
	50% {
		content: 'we are';
	}
	to {
		content: 'We are';
	}
}
@keyframes theWorld {
	0% {
		content: 'the world,';
	}
	50% {
		content: 'the children!';
	}
	to {
		content: 'the world,';
	}
}
@keyframes weWill {
	0% {
		content: 'We will,';
	}
	50% {
		content: 'rock you!';
	}
	to {
		content: 'We will,';
	}
}
@keyframes rockYou {
	0% {
		content: 'we will';
	}
	50% {
		content: '\u1F918';
	}
	to {
		content: 'we will';
	}
}
.loader-pokeball:before {
	content: '';
	position: absolute;
	width: 100px;
	height: 100px;
	top: 50%;
	left: 50%;
	margin: -50px 0 0 -50px;
	background: linear-gradient(180deg, red 42%, #000 0, #000 58%, #fff 0);
	background-repeat: no-repeat;
	background-color: #fff;
	border-radius: 50%;
	z-index: 1;
	animation: movePokeball 1s linear infinite both;
}
.loader-pokeball:after {
	content: '';
	position: absolute;
	width: 24px;
	height: 24px;
	top: 50%;
	left: 50%;
	margin: -12px 0 0 -12px;
	background-color: #fff;
	border-radius: 50%;
	z-index: 2;
	animation: movePokeball 1s linear infinite both, flashPokeball 0.5s infinite alternate;
	border: 2px solid #000;
	box-shadow: 0 0 0 5px #fff, 0 0 0 10px #000;
}
@keyframes movePokeball {
	0% {
		transform: translateX(0) rotate(0);
	}
	15% {
		transform: translatex(-10px) rotate(-5deg);
	}
	30% {
		transform: translateX(10px) rotate(5deg);
	}
	45% {
		transform: translatex(0) rotate(0);
	}
}
@keyframes flashPokeball {
	0% {
		background-color: #fff;
	}
	to {
		background-color: #fd0;
	}
}
.loader-bouncing:after,
.loader-bouncing:before {
	content: '';
	width: 20px;
	height: 20px;
	position: absolute;
	top: calc(50% - 10px);
	left: calc(50% - 10px);
	border-radius: 50%;
	background-color: #fff;
	animation: kick 0.6s infinite alternate;
}
.loader-bouncing:after {
	margin-left: -30px;
	animation: kick 0.6s infinite alternate;
}
.loader-bouncing:before {
	animation-delay: 0.2s;
}
@keyframes kick {
	0% {
		opacity: 1;
		transform: translateY(0);
	}
	to {
		opacity: 0.3;
		transform: translateY(-1rem);
	}
}
`;

// https://cdn.jsdelivr.net/npm/viewerjs/dist/viewer.min.css
const viewerStyle = `
.viewer-close:before,
.viewer-flip-horizontal:before,
.viewer-flip-vertical:before,
.viewer-fullscreen-exit:before,
.viewer-fullscreen:before,
.viewer-next:before,
.viewer-one-to-one:before,
.viewer-play:before,
.viewer-prev:before,
.viewer-reset:before,
.viewer-rotate-left:before,
.viewer-rotate-right:before,
.viewer-zoom-in:before,
.viewer-zoom-out:before {
	background-image: url("data:image/svg+xml;charset=utf-8,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 560 40'%3E%3Cpath fill='%23fff' d='M49.6 17.9h20.2v3.9H49.6zm123.1 2 10.9-11 2.7 2.8-8.2 8.2 8.2 8.2-2.7 2.7-10.9-10.9zm94 0-10.8-11-2.7 2.8 8.1 8.2-8.1 8.2 2.7 2.7 10.8-10.9zM212 9.3l20.1 10.6L212 30.5V9.3zm161.5 4.6-7.2 6 7.2 5.9v-4h12.4v4l7.3-5.9-7.3-6v4h-12.4v-4zm40.2 12.3 5.9 7.2 5.9-7.2h-4V13.6h4l-5.9-7.3-5.9 7.3h4v12.6h-4zm35.9-16.5h6.3v2h-4.3V16h-2V9.7Zm14 0h6.2V16h-2v-4.3h-4.2v-2Zm6.2 14V30h-6.2v-2h4.2v-4.3h2Zm-14 6.3h-6.2v-6.3h2v4.4h4.3v2Zm-438 .1v-8.3H9.6v-3.9h8.2V9.7h3.9v8.2h8.1v3.9h-8.1v8.3h-3.9zM93.6 9.7h-5.8v3.9h2V30h3.8V9.7zm16.1 0h-5.8v3.9h1.9V30h3.9V9.7zm-11.9 4.1h3.9v3.9h-3.9zm0 8.2h3.9v3.9h-3.9zm244.6-11.7 7.2 5.9-7.2 6v-3.6c-5.4-.4-7.8.8-8.7 2.8-.8 1.7-1.8 4.9 2.8 8.2-6.3-2-7.5-6.9-6-11.3 1.6-4.4 8-5 11.9-4.9v-3.1Zm147.2 13.4h6.3V30h-2v-4.3h-4.3v-2zm14 6.3v-6.3h6.2v2h-4.3V30h-1.9zm6.2-14h-6.2V9.7h1.9V14h4.3v2zm-13.9 0h-6.3v-2h4.3V9.7h2V16zm33.3 12.5 8.6-8.6-8.6-8.7 1.9-1.9 8.6 8.7 8.6-8.7 1.9 1.9-8.6 8.7 8.6 8.6-1.9 2-8.6-8.7-8.6 8.7-1.9-2zM297 10.3l-7.1 5.9 7.2 6v-3.6c5.3-.4 7.7.8 8.7 2.8.8 1.7 1.7 4.9-2.9 8.2 6.3-2 7.5-6.9 6-11.3-1.6-4.4-7.9-5-11.8-4.9v-3.1Zm-157.3-.6c2.3 0 4.4.7 6 2l2.5-3 1.9 9.2h-9.3l2.6-3.1a6.2 6.2 0 0 0-9.9 5.1c0 3.4 2.8 6.3 6.2 6.3 2.8 0 5.1-1.9 6-4.4h4c-1 4.7-5 8.3-10 8.3a10 10 0 0 1-10-10.2 10 10 0 0 1 10-10.2Z'/%3E%3C/svg%3E");
	background-repeat: no-repeat;
	background-size: 280px;
	color: transparent;
	display: block;
	font-size: 0;
	height: 20px;
	line-height: 0;
	width: 20px;
}
.viewer-zoom-in:before {
	background-position: 0 0;
	content: 'Zoom In';
}
.viewer-zoom-out:before {
	background-position: -20px 0;
	content: 'Zoom Out';
}
.viewer-one-to-one:before {
	background-position: -40px 0;
	content: 'One to One';
}
.viewer-reset:before {
	background-position: -60px 0;
	content: 'Reset';
}
.viewer-prev:before {
	background-position: -80px 0;
	content: 'Previous';
}
.viewer-play:before {
	background-position: -100px 0;
	content: 'Play';
}
.viewer-next:before {
	background-position: -120px 0;
	content: 'Next';
}
.viewer-rotate-left:before {
	background-position: -140px 0;
	content: 'Rotate Left';
}
.viewer-rotate-right:before {
	background-position: -160px 0;
	content: 'Rotate Right';
}
.viewer-flip-horizontal:before {
	background-position: -180px 0;
	content: 'Flip Horizontal';
}
.viewer-flip-vertical:before {
	background-position: -200px 0;
	content: 'Flip Vertical';
}
.viewer-fullscreen:before {
	background-position: -220px 0;
	content: 'Enter Full Screen';
}
.viewer-fullscreen-exit:before {
	background-position: -240px 0;
	content: 'Exit Full Screen';
}
.viewer-close:before {
	background-position: -260px 0;
	content: 'Close';
}
.viewer-container {
	-webkit-tap-highlight-color: transparent;
	-webkit-touch-callout: none;
	bottom: 0;
	direction: ltr;
	font-size: 0;
	left: 0;
	line-height: 0;
	overflow: hidden;
	position: absolute;
	right: 0;
	top: 0;
	-ms-touch-action: none;
	touch-action: none;
	-webkit-user-select: none;
	-moz-user-select: none;
	-ms-user-select: none;
	user-select: none;
}
.viewer-container ::-moz-selection,
.viewer-container::-moz-selection {
	background-color: transparent;
}
.viewer-container ::selection,
.viewer-container::selection {
	background-color: transparent;
}
.viewer-container:focus {
	outline: 0;
}
.viewer-container img {
	display: block;
	height: auto;
	max-height: none !important;
	max-width: none !important;
	min-height: 0 !important;
	min-width: 0 !important;
	width: 100%;
}
.viewer-canvas {
	bottom: 0;
	left: 0;
	overflow: hidden;
	position: absolute;
	right: 0;
	top: 0;
}
.viewer-canvas > img {
	height: auto;
	margin: 15px auto;
	max-width: 90% !important;
	width: auto;
}
.viewer-footer {
	bottom: 0;
	left: 0;
	overflow: hidden;
	position: absolute;
	right: 0;
	text-align: center;
}
.viewer-navbar {
	background-color: rgba(0, 0, 0, 0.5);
	overflow: hidden;
}
.viewer-list {
	box-sizing: content-box;
	height: 50px;
	margin: 0;
	overflow: hidden;
	padding: 1px 0;
}
.viewer-list > li {
	color: transparent;
	cursor: pointer;
	float: left;
	font-size: 0;
	height: 50px;
	line-height: 0;
	opacity: 0.5;
	overflow: hidden;
	transition: opacity 0.15s;
	width: 30px;
}
.viewer-list > li:focus,
.viewer-list > li:hover {
	opacity: 0.75;
}
.viewer-list > li:focus {
	outline: 0;
}
.viewer-list > li + li {
	margin-left: 1px;
}
.viewer-list > .viewer-loading {
	position: relative;
}
.viewer-list > .viewer-loading:after {
	border-width: 2px;
	height: 20px;
	margin-left: -10px;
	margin-top: -10px;
	width: 20px;
}
.viewer-list > .viewer-active,
.viewer-list > .viewer-active:focus,
.viewer-list > .viewer-active:hover {
	opacity: 1;
}
.viewer-player {
	background-color: #000;
	bottom: 0;
	cursor: none;
	display: none;
	right: 0;
	z-index: 1;
}
.viewer-player,
.viewer-player > img {
	left: 0;
	position: absolute;
	top: 0;
}
.viewer-toolbar > ul {
	display: inline-block;
	margin: 0 auto 5px;
	overflow: hidden;
	padding: 6px 3px;
}
.viewer-toolbar > ul > li {
	background-color: rgba(0, 0, 0, 0.5);
	border-radius: 50%;
	cursor: pointer;
	float: left;
	height: 24px;
	overflow: hidden;
	transition: background-color 0.15s;
	width: 24px;
}
.viewer-toolbar > ul > li:focus,
.viewer-toolbar > ul > li:hover {
	background-color: rgba(0, 0, 0, 0.8);
}
.viewer-toolbar > ul > li:focus {
	box-shadow: 0 0 3px #fff;
	outline: 0;
	position: relative;
	z-index: 1;
}
.viewer-toolbar > ul > li:before {
	margin: 2px;
}
.viewer-toolbar > ul > li + li {
	margin-left: 1px;
}
.viewer-toolbar > ul > .viewer-small {
	height: 18px;
	margin-bottom: 3px;
	margin-top: 3px;
	width: 18px;
}
.viewer-toolbar > ul > .viewer-small:before {
	margin: -1px;
}
.viewer-toolbar > ul > .viewer-large {
	height: 30px;
	margin-bottom: -3px;
	margin-top: -3px;
	width: 30px;
}
.viewer-toolbar > ul > .viewer-large:before {
	margin: 5px;
}
.viewer-tooltip {
	background-color: rgba(0, 0, 0, 0.8);
	border-radius: 10px;
	color: #fff;
	display: none;
	font-size: 12px;
	height: 20px;
	left: 50%;
	line-height: 20px;
	margin-left: -25px;
	margin-top: -10px;
	position: absolute;
	text-align: center;
	top: 50%;
	width: 50px;
}
.viewer-title {
	color: #ccc;
	display: inline-block;
	font-size: 12px;
	line-height: 1.2;
	margin: 5px 5%;
	max-width: 90%;
	min-height: 14px;
	opacity: 0.8;
	overflow: hidden;
	text-overflow: ellipsis;
	transition: opacity 0.15s;
	white-space: nowrap;
}
.viewer-title:hover {
	opacity: 1;
}
.viewer-button {
	-webkit-app-region: no-drag;
	background-color: rgba(0, 0, 0, 0.5);
	border-radius: 50%;
	cursor: pointer;
	height: 80px;
	overflow: hidden;
	position: absolute;
	right: -40px;
	top: -40px;
	transition: background-color 0.15s;
	width: 80px;
}
.viewer-button:focus,
.viewer-button:hover {
	background-color: rgba(0, 0, 0, 0.8);
}
.viewer-button:focus {
	box-shadow: 0 0 3px #fff;
	outline: 0;
}
.viewer-button:before {
	bottom: 15px;
	left: 15px;
	position: absolute;
}
.viewer-fixed {
	position: fixed;
}
.viewer-open {
	overflow: hidden;
}
.viewer-show {
	display: block;
}
.viewer-hide {
	display: none;
}
.viewer-backdrop {
	background-color: rgba(0, 0, 0, 0.5);
}
.viewer-invisible {
	visibility: hidden;
}
.viewer-move {
	cursor: move;
	cursor: grab;
}
.viewer-fade {
	opacity: 0;
}
.viewer-in {
	opacity: 1;
}
.viewer-transition {
	transition: all 0.3s;
}
@keyframes viewer-spinner {
	0% {
		transform: rotate(0deg);
	}
	to {
		transform: rotate(1turn);
	}
}
.viewer-loading:after {
	animation: viewer-spinner 1s linear infinite;
	border: 4px solid hsla(0, 0%, 100%, 0.1);
	border-left-color: hsla(0, 0%, 100%, 0.5);
	border-radius: 50%;
	content: '';
	display: inline-block;
	height: 40px;
	left: 50%;
	margin-left: -20px;
	margin-top: -20px;
	position: absolute;
	top: 50%;
	width: 40px;
	z-index: 1;
}
@media (max-width: 767px) {
	.viewer-hide-xs-down {
		display: none;
	}
}
@media (max-width: 991px) {
	.viewer-hide-sm-down {
		display: none;
	}
}
@media (max-width: 1199px) {
	.viewer-hide-md-down {
		display: none;
	}
}
`;

// --------------------------主程序--------------------------
(function() {
    // 注册菜单命令
    registerMenuCommand();

    // 图片查看器 CSS 样式
    // switch (IMAGE_VIEWER) {
    //     case 'image-viewer':
    //         addLinkStylesheetToHead('https://cdn.jsdelivr.net/npm/viewerjs/dist/viewer.min.css');
    //         break;
    //     case 'img-previewer':
    //         addLinkStylesheetToHead('https://cdn.jsdelivr.net/npm/img-previewer/dist/index.css');
    //         break;
    // }
    if (viewerStyle) {
        addStylesheetToHead(viewerStyle, 'css-viewer-style');
    }

    // 加载指示器 CSS 样式
    // addLinkStylesheetToHead('https://cdn.jsdelivr.net/npm/pure-css-loader/dist/css-loader.css');
    if (loderStyle) {
        addStylesheetToHead(loderStyle, 'css-loder-style');
    }

    // 监听键盘事件
    document.addEventListener('keydown', onKeydown, true);
})();
