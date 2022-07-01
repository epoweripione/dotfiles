// puppeteer run js
// https://xiday.com/2019/09/21/puppeteer-run-js/
// npm install --save-dev webpack memfs @babel/core @babel/preset-env babel-loader typescript ts-loader

const webpack = require('webpack');
const memfs = require('memfs');

const fs = require('fs');
const path = require("path");

// List all files in a directory in Node.js recursively in a synchronous fashion
// https://gist.github.com/kethinov/6658166
const getFilePaths = (folderPath) => {
    const entryPaths = fs.readdirSync(folderPath).map(entry => path.join(folderPath, entry));
    const filePaths = entryPaths.filter(entryPath => fs.statSync(entryPath).isFile());
    const dirPaths = entryPaths.filter(entryPath => !filePaths.includes(entryPath));
    const dirFiles = dirPaths.reduce((prev, curr) => prev.concat(getFilePaths(curr)), []);
    return [...filePaths, ...dirFiles];
};

const getMemfsFilePaths = (folderPath) => {
    const entryPaths = memfs.readdirSync(folderPath).map(entry => path.join(folderPath, entry));
    const filePaths = entryPaths.filter(entryPath => memfs.statSync(entryPath).isFile());
    const dirPaths = entryPaths.filter(entryPath => !filePaths.includes(entryPath));
    const dirFiles = dirPaths.reduce((prev, curr) => prev.concat(getMemfsFilePaths(curr)), []);
    return [...filePaths, ...dirFiles];
};

const compileJavascript = file => {
    const compiler = webpack({
        mode: 'production',
        // mode: 'development',
        // devtool: 'inline-source-map',
        entry: require.resolve(file),
        output: {
            filename: 'bundle.js',
            path: '/build',
        },
        module: {
            rules: [
                {
                    test: /\.m?js$/,
                    exclude: /(node_modules|bower_components)/,
                    loader: 'babel-loader',
                },
            ],
        },
    });

    // direct webpack to output to memfs rather than to disk
    compiler.outputFileSystem = memfs;

    return new Promise((resolve, reject) => {
        compiler.run(error => {
            if (error) {
                reject(error);
                return;
            }
            const content = memfs.readFileSync('/build/bundle.js');
            resolve(content.toString());
        });
    });
}


const compileTypescript = file => {
    // create a directory structure in memfs that matches the real filesystem
    // const rootDir = __dirname;

    // const entryBase = path.parse(file).base; // compile_test_ts.ts
    // const entryName = path.parse(file).name; // compile_test_ts
    // const entryExt = path.parse(file).ext; // .ts

    // const entry = path.join(rootDir, entryBase);

    // const outputPath = path.join(rootDir, 'dist');
    // const outputName = entryName + ".js";
    // const outputFilename = path.join(outputPath, outputName);

    // const rootExists = memfs.existsSync(rootDir);
    // if (!rootExists) {
    //     memfs.mkdirpSync(rootDir);
    // }

    // const code = fs.readFileSync(entry);
    // memfs.writeFileSync(entry, code);

    const compiler = webpack({
        mode: 'production',
        // mode: 'development',
        // devtool: 'inline-source-map',
        // entry: entry,
        // output: {
        //     filename: outputName,
        //     path: outputPath,
        // },
        entry: require.resolve(file),
        output: {
            filename: 'bundle.js',
            path: '/build',
        },
        module: {
            rules: [
                {
                    test: /\.tsx?$/,
                    exclude: /(node_modules|bower_components)/,
                    loader: 'ts-loader',
                },
            ],
        },
    });

    // direct webpack to use memfs for file input
    // compiler.inputFileSystem = memfs;

    // direct webpack to output to memfs rather than to disk
    compiler.outputFileSystem = memfs;

    return new Promise((resolve, reject) => {
        compiler.run(error => {
            if (error) {
                reject(error);
                return;
            }
            //console.log(getMemfsFilePaths('/'));
            const content = memfs.readFileSync('/build/bundle.js');
            resolve(content.toString());
        });
    });
}

exports.compileJavascript = compileJavascript;
exports.compileTypescript = compileTypescript;
