// https://www.baeldung.com/linux/command-line-website-screenshots
// npm install minimist puppeteer puppeteer-extra puppeteer-extra-plugin-stealth

// // print process.argv
// process.argv.forEach(function (val, index, array) {
//     console.log(index + ': ' + val);
// });
const args = require('minimist')(process.argv.slice(2));

// node nodejs/puppeteer_screenshot.js --url="https://nodejs.org/en/" --element="#logo > img" --output="$HOME/screenshot.png"
// node nodejs/puppeteer_screenshot.js --url="file://$HOME/.config/conky/hybrid/weather_wttr.html" --element="#weather" --output="$HOME/.config/conky/hybrid/weather_wttr.png"
// console.log(args.url): https://nodejs.org/en/
// console.log(args.element): #logo > img
const url = args.url;
const element = args.element;
const AcceptCookies= args.AcceptCookies;
const output = args.output;

// Avoid Detection of Headless Chromium
// https://github.com/berstend/puppeteer-extra/tree/master/packages/puppeteer-extra-plugin-stealth
// puppeteer-extra is a drop-in replacement for puppeteer,
// it augments the installed puppeteer with plugin functionality
const puppeteer = require('puppeteer-extra');
// add stealth plugin and use defaults (all evasion techniques)
const pluginStealth = require('puppeteer-extra-plugin-stealth')();
puppeteer.use(pluginStealth);

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
if (output) {
    OutputFile = output;
} else {
    if (! fs.existsSync(ScreenshotDir)) {
        fs.mkdirSync(ScreenshotDir, {recursive: true});
    }
    OutputFile = `${ScreenshotDir}/screenshot-${getDateTimeString()}.png`;
}

// Accept Cookies and Other Information
const PuppeteerAcceptCookies = async () => {
    const browser = await puppeteer.launch({headless: false, userDataDir: `${UserDataDir}`});
    const page = await browser.newPage();

    // await page.setViewport({width: 360, height: 640});
    await page.goto(url);
}

// Take Screenshot for a given website
const PuppeteerScreenshotFull = async () => {
    const browser = await puppeteer.launch({headless: true, userDataDir: `${UserDataDir}`});
    const page = await browser.newPage();

    await page.goto(url);

    await page.screenshot({
        path: `${OutputFile}`,
        fullPage: true
    });

    await page.close();
    await browser.close();
}

// Take Screenshot of an Element
const PuppeteerScreenshotElement = async () => {
    const browser = await puppeteer.launch({headless: true, userDataDir: `${UserDataDir}`});
    const page = await browser.newPage();

    await page.goto(url);

    await page.waitForSelector(element);
    const pageElement = await page.$(element);

    await pageElement.screenshot({
        path: `${OutputFile}`
    });

    await page.close();
    await browser.close();
}

if (AcceptCookies) {
    PuppeteerAcceptCookies();
}

if (element) {
    PuppeteerScreenshotElement();
} else {
    PuppeteerScreenshotFull();
}
