const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
puppeteer.use(StealthPlugin());

// Fix Error: An `executablePath` or `channel` must be specified for `puppeteer-core`
const {executablePath} = require('puppeteer');

// const stealth = StealthPlugin();
// stealth.enabledEvasions.delete('user-agent-override');
// stealth.enabledEvasions.delete('sourceurl');
// puppeteer.use(stealth);

const url = "https://nodejs.org/en/";
const CaptureElement = "#logo > img";

const os = require("os");

const userHomeDir = os.homedir();

const ScreenshotDir = `${userHomeDir}/puppeteer/screenshots`;
const UserDataDir = `${userHomeDir}/puppeteer/userdata`;

const OutputFileFullPage = `${ScreenshotDir}/screenshot_fullpage.png`;
const OutputFileElement = `${ScreenshotDir}/screenshot_element.png`;

const PuppeteerScreenshotTest = async () => {
    const browser = await puppeteer.launch({
        headless: true,
        // defaultViewport: {
        //     width: 800,
        //     height: 600
        // },
        dumpio: true,
        userDataDir: `${UserDataDir}`,
		executablePath: executablePath(),
    });
    const page = await browser.newPage();
    // await page.setViewport({width: 1024, height: 768});
    await page.goto(url);
    await page.waitForSelector(CaptureElement);

    // fullpage
    // await page.screenshot({
    //     path: `${OutputFileFullPage}`,
    //     fullPage: true,
    // });

    // element
    const pageElement = await page.$(CaptureElement);
    await pageElement.screenshot({
        path: `${OutputFileElement}`,
    });

    await page.close();
    await browser.close();
}

PuppeteerScreenshotTest();
