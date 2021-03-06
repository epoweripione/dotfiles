module.exports = {
    headerPattern: /^([\w\-]*)(?:\(([\w\-\*]*)\))?:\s+((?:.*(?=\())|.*)(?:\(#(\d*)\))?$/,
    headerCorrespondence: ['type', 'scope', 'subject', 'ticket'],
    displayTypes: [
        'feat',
        'fix',
        'hotfix',
        'patch',
        'style',
        'docs',
        'perf',
        'chore',
        'build',
        'ui',
        'refactor',
        'config',
        'i18n',
        'typo',
        'revert',
        'merge',
        'break',
        'api',
        'lint',
        'test',
        'prune',
        'move',
        'data',
        'db',
        'ux',
        'business',
        'arch',
        'texts',
        'assets',
        'auth',
        'access',
        'review',
        'experiment',
        'flags',
        'animation',
        'responsive',
        'types',
        'mock',
        'script',
        'error',
        'healthcheck',
        'package',
        'dep-add',
        'dep-rm',
        'dep-down',
        'dep-up',
        'pushpin',
        'init',
        'wip',
        'deploy',
        'release',
        'analytics',
        'security',
        'ci',
        'fixci',
        'clean',
        'deadcode',
        'docker',
        'k8s',
        'osx',
        'linux',
        'windows',
        'android',
        'ios',
        'ignore',
        'comment',
        'snapshot',
        'addlog',
        'rmlog',
        'seed',
        'seo',
        'contrib',
        'license',
        'egg',
        'beer',
        'poo',
    ],
    displayTypeEmojis: {
        'feat': '✨',
        'fix': '🐛',
        'hotfix': '🚑',
        'patch': '🩹',
        'style': '🎨',
        'docs': '📝',
        'perf': '🌠',
        'chore': '🎫',
        'build': '🏭',
        'ui': '💄',
        'refactor': '🌀',
        'config': '🔧',
        'i18n': '🌐',
        'typo': '✎',
        'revert': '⏪',
        'merge': '🔀',
        'break': '💥',
        'api': '👽',
        'lint': '🚨',
        'test': '✅',
        'prune': '🔥',
        'move': '🚚',
        'data': '📡',
        'db': '💽',
        'ux': '🚸',
        'business': '👔',
        'arch': '🏠',
        'texts': '💬',
        'assets': '🍱',
        'auth': '🛂',
        'access': '♿',
        'review': '👌',
        'experiment': '🧪',
        'flags': '🚩',
        'animation': '💫',
        'responsive': '📱',
        'types': '📔',
        'mock': '🤡',
        'script': '🔨',
        'error': '🥅',
        'healthcheck': '🩺',
        'package': '📦',
        'dep-add': '➕',
        'dep-rm': '➖',
        'dep-down': '⬇',
        'dep-up': '⬆',
        'pushpin': '📌',
        'init': '🎉',
        'wip': '🚧',
        'deploy': '🚀',
        'release': '🔖',
        'analytics': '📈',
        'security': '🔒',
        'ci': '👷',
        'fixci': '💚',
        'clean': '🧹',
        'deadcode': '🚮',
        'docker': '🐳',
        'k8s': '🎡',
        'osx': '🍎',
        'linux': '🐧',
        'windows': '🏁',
        'android': '🤖',
        'ios': '🍏',
        'ignore': '🙈',
        'comment': '💡',
        'snapshot': '📸',
        'addlog': '🔊',
        'rmlog': '🔇',
        'seed': '🌱',
        'seo': '🔍',
        'contrib': '👥',
        'license': '📄',
        'egg': '🥚',
        'beer': '🍻',
        'poo': '💩',
    },
    displayScopes: ['*'],
    displayTitles: {
        'feat': 'Features',
        'fix': 'Bug Fixes',
        'hotfix': 'Bug Fixes',
        'patch': 'Bug Fixes',
        'style': 'Styles',
        'docs': 'Documentation',
        'perf': 'Performance Improvements',
        'chore': 'Chores',
        'build': 'Build System',
        'prune': 'Prune & Move & Rename',
        'ui': 'UI',
        'test': 'Tests',
        'lint': 'Lint',
        'refactor': 'Code Refactoring',
        'config': 'Configuration',
        'i18n': 'Internationalization & Localization',
        'typo': 'Typos',
        'revert': 'Reverts',
        'merge': 'Merge',
        'break': 'BREAKING CHANGES',
        'api': 'API',
        'move': 'Move & Rename',
        'data': 'Data',
        'db': 'Database',
        'ux': 'User experience & Usability',
        'business': 'Business Logic',
        'arch': 'Architecture',
        'texts': 'Text & Literals',
        'assets': 'Assets',
        'auth': 'Authorization',
        'access': 'Accessibility',
        'review': 'Review Changes',
        'experiment': 'Experiments',
        'flags': 'Feature Flags',
        'animation': 'Animations',
        'responsive': 'Responsive Design',
        'types': 'Types',
        'mock': 'Mock',
        'script': 'Scripts',
        'error': 'Errors',
        'healthcheck': 'Healthcheck',
        'package': 'Packages',
        'dep-add': 'Dependencies',
        'dep-rm': 'Dependencies',
        'dep-down': 'Dependencies',
        'pushpin': 'Dependencies',
        'dep-up': 'Dependencies',
        'init': 'Init Project',
        'wip': 'Work in Progress',
        'deploy': 'Deploy',
        'release': 'Release & Version tags',
        'analytics': 'Analytics',
        'security': 'Security',
        'ci': 'Continuous Integration',
        'fixci': 'Continuous Integration',
        'clean': 'Clean',
        'deadcode': 'Clean',
        'docker': 'Docker',
        'k8s': 'Kubernetes',
        'osx': 'macOS',
        'linux': 'Linux',
        'windows': 'Windows',
        'android': 'Android',
        'ios': 'iOS',
        'ignore': 'Git',
        'comment': 'Comments',
        'snapshot': 'Snapshots',
        'addlog': 'Logs',
        'rmlog': 'Logs',
        'seed': 'Seed files',
        'seo': 'SEO',
        'contrib': 'Contributors',
        'license': 'License',
        'egg': 'Easter Egg',
        'beer': 'Bad Code',
        'poo': 'Bad Code',
    },
    displayTitleEmojis: {
        'Features': '✨',
        'Bug Fixes': '🐛',
        'Styles': '🎨',
        'Documentation': '📝',
        'Performance Improvements': '🌠',
        'Chores': '🎫',
        'Build System': '🏭',
        'Prune & Move & Rename': '🔥',
        'UI': '💄',
        'Tests': '✅',
        'Lint': '🚨',
        'Code Refactoring': '🌀',
        'Configuration': '🔧',
        'Internationalization & Localization': '🌐',
        'Typos': '✎',
        'Reverts': '⏪',
        'Merge': '🔀',
        'BREAKING CHANGES': '💥',
        'API': '👽',
        'Move & Rename': '🚚',
        'Data': '📡',
        'Database': '💽',
        'User experience & Usability': '🚸',
        'Business Logic': '👔',
        'Architecture': '🏠',
        'Text & Literals': '💬',
        'Assets': '🍱',
        'Authorization': '🛂',
        'Accessibility': '♿',
        'Review Changes': '👌',
        'Experiments': '🧪',
        'Feature Flags': '🚩',
        'Animations': '💫',
        'Responsive Design': '📱',
        'Types': '📔',
        'Mock': '🤡',
        'Scripts': '🔨',
        'Errors': '🥅',
        'Healthcheck': '🩺',
        'Packages': '📦',
        'Dependencies': '📌',
        'Init Project': '🎉',
        'Work in Progress': '🚧',
        'Deploy': '🚀',
        'Release & Version tags': '🔖',
        'Analytics': '📈',
        'Security': '🔒',
        'Continuous Integration': '👷',
        'Clean': '🧹',
        'Docker': '🐳',
        'Kubernetes': '🎡',
        'macOS': '🍎',
        'Linux': '🐧',
        'Windows': '🏁',
        'Android': '🤖',
        'iOS': '🍏',
        'Git': '🙈',
        'Comments': '💡',
        'Snapshots': '📸',
        'Logs': '🔊',
        'Seed files': '🌱',
        'SEO': '🔍',
        'Contributors': '👥',
        'License': '📄',
        'Easter Egg': '🥚',
        'Bad Code': '💩',
    },
    scopeDisplayName: {},
    withEmoji: true,
    showAuthor: false,
}
