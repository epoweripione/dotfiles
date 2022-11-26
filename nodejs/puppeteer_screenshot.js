// https://www.baeldung.com/linux/command-line-website-screenshots
// npm install minimist puppeteer puppeteer-extra puppeteer-extra-plugin-stealth
// npx envinfo@latest --system --binaries --npmPackages '*(puppeteer*|playwright*|automation-extra*|@extra*)'

// process.argv.forEach(function (val, index, array) {
//     console.log(index + ': ' + val);
// });
const args = require('minimist')(process.argv.slice(2));

// node nodejs/puppeteer_screenshot.js --url="https://nodejs.org/en/" --Element="#logo > img" --Output="$HOME/screenshot.png"
// node nodejs/puppeteer_screenshot.js --url="file://$HOME/.config/conky/hybrid/weather_wttr.html" --Element="#weather" --Output="$HOME/.config/conky/hybrid/weather_wttr.png"
// node nodejs/puppeteer_screenshot.js --url="https://wannianli.tianqi.com/" \
//     --Element="#cal_body" \
//     --RemoveElement=".xcx_erweima,.info,.elevator-module,.more,.ming_ci_jie_shi,.copy,#cal_funcbar" \
//     --ReplaceElement=".hd.li_history" \
//     --ReplaceWithHTML="<span>历史上的今天</span>" \
//     --Output="$HOME/.config/conky/hybrid/calendar.png"
// console.log(args.url): https://nodejs.org/en/
// console.log(args.Element): #logo > img
const url = args.url;
const CaptureElement = args.Element;
const RemoveElement = args.RemoveElement;
const AcceptCookies = args.AcceptCookies;
const ReplaceElement = args.ReplaceElement;
const ReplaceWithHTML = args.ReplaceWithHTML;
const Output = args.Output;

const DisableStealth = args.DisableStealth;

// Avoid Detection of Headless Chromium
// https://github.com/berstend/puppeteer-extra/tree/master/packages/puppeteer-extra-plugin-stealth
// puppeteer-extra is a drop-in replacement for puppeteer,
// it augments the installed puppeteer with plugin functionality
const puppeteer = require('puppeteer-extra');
// add stealth plugin and use defaults (all evasion techniques)
if (! DisableStealth) {
    const StealthPlugin = require('puppeteer-extra-plugin-stealth');
    puppeteer.use(StealthPlugin());
}

// Fix Error: An `executablePath` or `channel` must be specified for `puppeteer-core`
const {executablePath} = require('puppeteer');

const os = require("os");
const fs = require('fs');

const userHomeDir = os.homedir();
const ScreenshotDir = `${userHomeDir}/puppeteer/screenshots`;
const UserDataDir = `${userHomeDir}/puppeteer/userdata`;

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

// if (! fs.existsSync(UserDataDir)) {
//     fs.mkdirSync(UserDataDir, {recursive: true});
// }

let OutputFile = ""
if (Output) {
    OutputFile = Output;
} else {
    if (! fs.existsSync(ScreenshotDir)) {
        fs.mkdirSync(ScreenshotDir, {recursive: true});
    }
    OutputFile = `${ScreenshotDir}/screenshot-${getDateTimeString()}.png`;
}

// Accept Cookies and Other Information
const PuppeteerAcceptCookies = async () => {
    const browser = await puppeteer.launch({
		headless: false,
		userDataDir: `${UserDataDir}`,
		executablePath: executablePath(),
	});
    const page = await browser.newPage();

    // await page.setViewport({width: 360, height: 640});
    await page.goto(url);
}

// Take Screenshot for a given website
const PuppeteerScreenshotFull = async () => {
    const browser = await puppeteer.launch({
		headless: false,
		userDataDir: `${UserDataDir}`,
		executablePath: executablePath(),
	});
    const page = await browser.newPage();

    // await page.setViewport({width: 1024, height: 768});

    await page.goto(url);

    // await page.waitForTimeout(3000);

    // Remove element before screenshot
    if (RemoveElement) {
        await page.evaluate((selector) => {
            const elementToRemove = selector.split(',');
            for (let i = 0; i < elementToRemove.length; i++) {
                let elements = document.querySelectorAll(elementToRemove[i]);
                for(let j=0; j < elements.length; j++){
                    elements[j].parentNode.removeChild(elements[j]);
                }
            }
        }, RemoveElement);
    }

    // Replace element before screenshot
    if (ReplaceElement) {
        await page.evaluate((selector,replace) => {
            if (replace) {
                let elements = document.querySelectorAll(selector);
                for(let j=0; j < elements.length; j++){
                    elements[j].innerHTML = `${replace}`;
                }
            }
        }, ReplaceElement, ReplaceWithHTML);
    }

    await page.screenshot({
        path: `${OutputFile}`,
        fullPage: true,
    });

    await page.close();
    await browser.close();
}

// Take Screenshot of an Element
const PuppeteerScreenshotElement = async () => {
    const browser = await puppeteer.launch({
		headless: false,
		userDataDir: `${UserDataDir}`,
		executablePath: executablePath(),
	});
    const page = await browser.newPage();

    await page.setViewport({width: 1024, height: 768});

    await page.goto(url);

    // await page.waitForTimeout(3000);

    await page.waitForSelector(CaptureElement);

    // Remove element before screenshot
    if (RemoveElement) {
        await page.evaluate((selector) => {
            const elementToRemove = selector.split(',');
            for (let i = 0; i < elementToRemove.length; i++) {
                let elements = document.querySelectorAll(elementToRemove[i]);
                for(let j=0; j < elements.length; j++){
                    elements[j].parentNode.removeChild(elements[j]);
                }
            }
        }, RemoveElement);
    }

    // Replace element before screenshot
    if (ReplaceElement) {
        await page.evaluate((selector,replace) => {
            if (replace) {
                let elements = document.querySelectorAll(selector);
                for(let j=0; j < elements.length; j++){
                    elements[j].innerHTML = `${replace}`;
                }
            }
        }, ReplaceElement, ReplaceWithHTML);
    }

    const pageElement = await page.$(CaptureElement);
    await pageElement.screenshot({
        path: `${OutputFile}`,
    });

    await page.close();
    await browser.close();
}

if (AcceptCookies) {
    PuppeteerAcceptCookies();
}

if (CaptureElement) {
    PuppeteerScreenshotElement();
} else {
    PuppeteerScreenshotFull();
}
