// pnpm install minimist puppeteer puppeteer-extra puppeteer-extra-plugin-stealth
// npx envinfo@latest --system --binaries --npmPackages '*(puppeteer*|playwright*|automation-extra*|@extra*)'
// pnpm install htmlparser2 html-to-text

// [Troubleshooting](https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md)
// Dependencies for chrome
// ldd $HOME/.cache/puppeteer/chrome/linux-119.0.6045.105/chrome-linux64/chrome | grep not

const args = require('minimist')(process.argv.slice(2));

// node nodejs/puppeteer_text.js --url="https://nodejs.org/docs/latest/api/synopsis.html" --Element="#apicontent" --Output="$HOME/text.txt"
// console.log(args.url): https://nodejs.org/docs/latest/api/synopsis.html
// console.log(args.Element): #apicontent
const url = args.url;
const CaptureElement = args.Element;
const AcceptCookies = args.AcceptCookies;
const ContentProtectPasswordRe = args.ContentProtectPasswordRe;
const ContentProtectPassword = args.ContentProtectPassword;
const PasswordInputElement = args.PasswordInputElement;
const ContentProtectElement = args.ContentProtectElement;
const OutTextFile = args.OutTextFile;
const OutProtectFile = args.OutProtectFile;

const DisableStealth = args.DisableStealth;
const DisableLog = args.DisableLog;

// [Puppeteer Tutorial](https://www.tutorialspoint.com/puppeteer/index.htm)
// Id Selector: "#elementID"
// Name Selector: "[name='elementName']"
// Class Selector: ".elementClass"
// Attribute Selector: "li[class='heading']"

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

const { convert } = require('html-to-text');

const userHomeDir = os.homedir();
const SaveDir = `${userHomeDir}/puppeteer/text`;
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

let OutputTextFile = ""
let OutputProtectTextFile = ""

if (OutTextFile) {
    OutputTextFile = OutTextFile;
} else {
    if (! fs.existsSync(SaveDir)) {
        fs.mkdirSync(SaveDir, {recursive: true});
    }
    OutputTextFile = `${SaveDir}/text-${getDateTimeString()}.txt`;
}

if (OutProtectFile) {
    OutputProtectTextFile = OutProtectFile;
} else {
    if (! fs.existsSync(SaveDir)) {
        fs.mkdirSync(SaveDir, {recursive: true});
    }
    OutputProtectTextFile = `${SaveDir}/text-${getDateTimeString()}_protect.txt`;
}

const Html2TextOptions = {
    wordwrap: false,
    // wordwrap: 130,
};

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

const PuppeteerText = async () => {
    const browser = await puppeteer.launch({
		headless: "new",
		userDataDir: `${UserDataDir}`,
		executablePath: executablePath(),
	});
    const page = await browser.newPage();
    // page.setDefaultNavigationTimeout(0);

    // await page.setViewport({width: 1024, height: 768});

    // console.log(url);
    // try {
    //     let status = await page.goto(url);
    // } catch (e) {
    //     console.log(e);
    //     await browser.close();
    //     return;
    // }
    let status = await page.goto(url, { waitUntil: 'load', timeout: 1 * 60000 });
    // console.log(status);
    // console.log(status.status());

    // await page.waitForTimeout(3000);

    // Extract title & paragraphs from the page
    // const Article = await page.evaluate(() => {
    //     const title = document.querySelector('h1').innerText;
    //     const paragraphs = Array.from(document.querySelectorAll('p')).map(p => p.innerText);
    //     return {
    //         title,
    //         paragraphs,
    //     };
    // });
    // console.log(Article);

    let outHtml, outText;

    if (CaptureElement) {
        await page.waitForSelector(CaptureElement);

        // const pageElement = await page.$(CaptureElement);
        // outHtml = await page.evaluate(ele => ele.innerHTML, pageElement);
        // Text = await page.evaluate(ele => ele.textContent, pageElement);

        outHtml = ""
        outText = ""
        const pageElements = await page.$$(CaptureElement);
        for (const pageElement of pageElements) {
            const eleHtml = await page.evaluate(ele => ele.innerHTML, pageElement);
            const eleText = await page.evaluate(ele => ele.textContent, pageElement);
            outHtml = outHtml.length === 0 ? eleHtml : outHtml + "\n" + eleHtml;
            outText = outText.length === 0 ? eleText : outText + "\n" + eleText;
        }
    } else {
        outHtml = await page.content();
        outText = convert(outHtml, Html2TextOptions);
    }

    // Content protect by password, but the password in the same page
    let protectPwdRe, protectPwdMatch, protectPassword
    let outProtectHtml, outProtectText;

    protectPwdRe = ContentProtectPasswordRe;
    protectPassword = ContentProtectPassword;
    if (protectPwdRe) {
        //protectPwdRe = protectPwdRe.replace(/[\\]/g, "\\$&");
        const pwdRe = new RegExp(protectPwdRe, "g");
        while (r = pwdRe.exec(outText)) {
            protectPwdMatch = r[0]
            protectPassword = r[1]
            // console.log(protectPwdMatch + "   " + protectPassword)
        }
    }

    if (protectPassword && PasswordInputElement && ContentProtectElement) {
        const pwdInput = await page.$(PasswordInputElement)

        pwdInput.type(protectPassword)
        await page.waitForTimeout(1000)
        await page.keyboard.press('Enter')
    
        await page.waitForTimeout(5000)

        const protectContent = await page.$(ContentProtectElement)
        outProtectHtml = await page.evaluate(ele => ele.innerHTML, protectContent);
        outProtectText = await page.evaluate(ele => ele.textContent, protectContent);
    }

    // console.log(outHtml);
    const OutputHtmlFile = OutputTextFile.replace(/\.[^/.]+$/, ".html");
    fs.writeFileSync(`${OutputHtmlFile}`, outHtml);

    // console.log(outText);
    fs.writeFileSync(`${OutputTextFile}`, outText);

    if (outProtectHtml) {
        // console.log(outProtectHtml);
        const OutputProtectHtmlFile = OutputProtectTextFile.replace(/\.[^/.]+$/, ".html");
        fs.writeFileSync(`${OutputProtectHtmlFile}`, outProtectHtml);
    }

    if (outProtectText) {
        // console.log(outProtectText);
        fs.writeFileSync(`${OutputProtectTextFile}`, outProtectText);
    }

    await page.close();
    await browser.close();
}

if (AcceptCookies) {
    PuppeteerAcceptCookies();
}

PuppeteerText();
