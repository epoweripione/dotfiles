// npm install --save-dev lodash

import add from 'lodash/add';

const sum = (...param) => [...param].reduce((a, b) => add(a, b), 0);

window.sum = sum;
