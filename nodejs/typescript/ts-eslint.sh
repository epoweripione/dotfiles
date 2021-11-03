#!/usr/bin/env bash

# https://ts.xcatliu.com/engineering/lint
# https://standardjs.com/rules-zhcn.html

# install typescript, eslint global
npm i -g typescript eslint

# init project
mkdir -p ts-eslint
npm init

# create tsconfig.json
tsc -init

# add depends
npm i --save-dev typescript eslint
npm i --save-dev @typescript-eslint/parser @typescript-eslint/eslint-plugin
npm i --save-dev eslint-config-alloy
npm i --save-dev prettier

## init eslint
# eslint --init

# AlloyTeam ESLint Rules
# https://github.com/AlloyTeam/eslint-config-alloy
tee .eslintrc.js >/dev/null <<-'EOF'
module.exports = {
    extends: [
        'alloy',
        'alloy/typescript',
    ],
    env: {
        // Your environments (which contains several predefined global variables)
        // browser: true,
        // node: true,
        // mocha: true,
        // jest: true,
        // jquery: true
    },
    globals: {
        // Your global variables (setting to false means it's not allowed to be reassigned)
        // myGlobal: false
    },
    rules: {
        // Customize your rules
    }
};
EOF

# Prettier config
tee .prettierrc.js >/dev/null <<-'EOF'
module.exports = {
    // max 100 characters per line
    printWidth: 100,
    // use 4 spaces for indentation
    tabWidth: 4,
    // use spaces instead of indentations
    useTabs: false,
    // semicolon at the end of the line
    semi: true,
    // use single quotes
    singleQuote: true,
    // object's key is quoted only when necessary
    quoteProps: 'as-needed',
    // use double quotes instead of single quotes in jsx
    jsxSingleQuote: false,
    // no comma at the end
    trailingComma: 'none',
    // spaces are required at the beginning and end of the braces
    bracketSpacing: true,
    // end tag of jsx need to wrap
    jsxBracketSameLine: false,
    // brackets are required for arrow function parameter, even when there is only one parameter
    arrowParens: 'always',
    // format the entire contents of the file
    rangeStart: 0,
    rangeEnd: Infinity,
    // no need to write the beginning @prettier of the file
    requirePragma: false,
    // No need to automatically insert @prettier at the beginning of the file
    insertPragma: false,
    // use default break criteria
    proseWrap: 'preserve',
    // decide whether to break the html according to the display style
    htmlWhitespaceSensitivity: 'css',
    // lf for newline
    endOfLine: 'lf'
};
EOF