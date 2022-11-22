const puppeteer = require('puppeteer');

const args = process.argv.slice(2);

const url = args[0];
const element = args[1];//"#logo > img";

const PuppeteerHTML = async () => {
    // const browser = await puppeteer.launch({
    //     bindAddress: "0.0.0.0",
    //     args: [
    //         "--headless",
    //         "--disable-gpu",
    //         "--disable-dev-shm-usage",
    //         "--remote-debugging-port=9222",
    //         "--remote-debugging-address=0.0.0.0"
    //     ]
    // });

    const browser = await puppeteer.launch({headless: true});

    const page = await browser.newPage();

    // await page.setViewport({width: 1024, height: 768});

    // await page.goto(url);
    await page.goto(url, {waitUntil: 'load'});

    // await page.waitForTimeout(3000);
    if (element) {
        await page.waitForSelector(element);
    }

    let html;
    if (element) {
        const pageElement = await page.$(element);
        html = await pageElement.content();
    } else {
        html = await page.content();
    }

    console.log(html);

    await page.close();
    await browser.close();
}

PuppeteerHTML();
