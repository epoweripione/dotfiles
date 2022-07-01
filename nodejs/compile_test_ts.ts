// npm install --save-dev lodash @types/lodash

import padStart from "lodash/padStart";

declare global {
    interface Window {
        padStart: Function;
    }
}

// (<any>window).padStart = padStart;
window.padStart = padStart;
