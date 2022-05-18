module.exports = {
    parserOpts: {
        headerPattern: /^([\w\-]*)(?:\(([\w\-\*]*)\))?:\s+((?:.*(?=\())|.*)(?:\(#(\d*)\))?$/,
        headerCorrespondence: ['type', 'scope', 'subject', 'ticket']
    },
};
