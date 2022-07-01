const puppeteer = require('puppeteer');

const compiler = require('./compile_in_memfs');

const PuppeteerTestCompileJS = async () => {
    const browser = await puppeteer.launch({headless: true});
    const page = await browser.newPage();

    const scriptJS = await compiler.compileJavascript('./compile_test_js.js');
    // console.log(scriptJS);

    await page.evaluate(scriptJS);
    const resultSum = await page.evaluate('window.sum(1, 2, 3, 4, 5)');
    // const resultSum = await page.evaluate(() => {
    //     return window.sum(1, 2, 3, 4, 5);
    // });
    console.log('window.sum(1, 2, 3, 4, 5) =', resultSum);

    await page.close();
    await browser.close();
}

const PuppeteerTestCompileTS = async () => {
    const browser = await puppeteer.launch({headless: true});
    const page = await browser.newPage();

    const scriptTS = await compiler.compileTypescript('./compile_test_ts.ts');
    // console.log(scriptTS);

    await page.evaluate(scriptTS);
    const resultStr = await page.evaluate('window.padStart("Hello TypeScript!", 20, ">")');
    console.log('window.padStart("Hello TypeScript!", 20, ">") =', resultStr);

    await page.close();
    await browser.close();
}

// const bundlejs = compiler.compileJavascript('./compile_test_js.js')
//     .then((result) => {
//         console.log(result)
//     })
//     .catch(error => {
//         console.error(error)
//     });

// const bundleTS = compiler.compileTypescript('./compile_test_ts.ts')
//     .then((result) => {
//         console.log(result)
//     })
//     .catch(error => {
//         console.error(error)
//     });

PuppeteerTestCompileJS();
PuppeteerTestCompileTS();
