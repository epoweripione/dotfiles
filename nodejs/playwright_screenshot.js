// [Migrating from Puppeteer](https://playwright.dev/docs/puppeteer)
// pnpm create playwright
// pnpm add @playwright/test yargs-parser
// pnpm exec playwright --version

// [Playwright 浏览器安装慢？一文搞定国内加速方案](https://docs.huancode.com/blog/playwright-install-slow)
// export PLAYWRIGHT_DOWNLOAD_HOST="https://npmmirror.com/mirrors/playwright"
// export PLAYWRIGHT_DOWNLOAD_HOST="https://cdn.playwright.dev"
// pnpm exec playwright install chromium --dry-run

// install dependencies
// pnpm exec playwright install --with-deps
// pnpm exec playwright install --list

// archlinux
// yay --noconfirm -S chromium aur/playwright aur/playwright-cli

// node nodejs/playwright_screenshot.js --url="https://developer.mozilla.org/" --Element="#content" --Output="$HOME/screenshot.png"
// node nodejs/playwright_screenshot.js --url="file://$HOME/.config/conky/hybrid/weather_wttr.html" --Element="#weather" --Output="$HOME/.config/conky/hybrid/weather_wttr.png"
// node nodejs/playwright_screenshot.js --url="https://wannianli.tianqi.com/" \
//     --Element="#cal_body" \
//     --RemoveElement=".xcx_erweima,.info,.elevator-module,.more,.ming_ci_jie_shi,.copy,#cal_funcbar" \
//     --ReplaceElement=".hd.li_history" \
//     --ReplaceWithHTML="<span>历史上的今天</span>" \
//     --Output="$HOME/.config/conky/hybrid/calendar.png"

const args = require('yargs-parser')(process.argv.slice(2));

const url = args.url;
const CaptureElement = args.Element;
const RemoveElement = args.RemoveElement;
const AcceptCookies = args.AcceptCookies;
const ReplaceElement = args.ReplaceElement;
const ReplaceWithHTML = args.ReplaceWithHTML;
const Output = args.Output;

// [Patches for undetectable browser automation](https://github.com/rebrowser/rebrowser-patches)
// const chromium = require('rebrowser-playwright');

const { chromium } = require('@playwright/test');

const os = require("node:os");
const fs = require('node:fs');

const userHomeDir = os.homedir();
const ScreenshotDir = `${userHomeDir}/playwright/screenshots`;

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

let OutputFile = ""
if (Output) {
    OutputFile = Output;
} else {
    if (! fs.existsSync(ScreenshotDir)) {
        fs.mkdirSync(ScreenshotDir, {recursive: true});
    }
    OutputFile = `${ScreenshotDir}/screenshot-${getDateTimeString()}.png`;
}

const chromiumPath = fs.existsSync("/usr/bin/chromium")
    ? "/usr/bin/chromium"
    : undefined;

// Accept Cookies and Other Information
const playwrightAcceptCookies = async () => {
    const browser = await chromium.launch({
		headless: false,
        executablePath: chromiumPath,
		// slowMo: 50,
        // args: ['--window-size=1280,720']
	});
    const page = await browser.newPage();

    // await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto(url);
}

// Take Screenshot for a given website
// https://developer.chrome.com/articles/new-headless/
const playwrightScreenshotFull = async () => {
    const browser = await chromium.launch({
		headless: true,
        executablePath: chromiumPath,
		// slowMo: 50,
        // args: ['--window-size=1280,720']
	});
    const page = await browser.newPage();

    // await page.setViewportSize({ width: 1280, height: 800 });

    await page.goto(url);

    // Remove element before screenshot
    if (RemoveElement) {
        await page.evaluate((selector) => {
            const elementToRemove = selector.split(',');
            for (let i = 0; i < elementToRemove.length; i++) {
                const elements = document.querySelectorAll(elementToRemove[i]);
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
                const elements = document.querySelectorAll(selector);
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
const playwrightScreenshotElement = async () => {
    const browser = await chromium.launch({
		headless: true,
        executablePath: chromiumPath,
		// slowMo: 50,
        // args: ['--window-size=1280,720']
	});
    const page = await browser.newPage();

    await page.setViewportSize({ width: 1280, height: 800 });

    await page.goto(url);

    await page.locator(CaptureElement).waitFor({ state: 'visible' });

    // Remove element before screenshot
    if (RemoveElement) {
        await page.evaluate((selector) => {
            const elementToRemove = selector.split(',');
            for (let i = 0; i < elementToRemove.length; i++) {
                const elements = document.querySelectorAll(elementToRemove[i]);
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
                const elements = document.querySelectorAll(selector);
                for(let j=0; j < elements.length; j++){
                    elements[j].innerHTML = `${replace}`;
                }
            }
        }, ReplaceElement, ReplaceWithHTML);
    }

    const pageElement = await page.locator(CaptureElement);
    await pageElement.screenshot({
        path: `${OutputFile}`,
    });

    await page.close();
    await browser.close();
}

if (AcceptCookies) {
    playwrightAcceptCookies();
}

if (CaptureElement) {
    playwrightScreenshotElement();
} else {
    playwrightScreenshotFull();
}
