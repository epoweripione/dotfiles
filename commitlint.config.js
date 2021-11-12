module.exports = {
  extends: ['gitmoji'],
  parserPreset: {
    parserOpts: {
      headerPattern: /^([\w\-]*)(?:\(([\w\-\*]*)\))?:\s+((?:.*(?=\())|.*)(?:\(#(\d*)\))?$/,
      headerCorrespondence: ['type', 'scope', 'subject', 'ticket']
    }
  },
  rules: {
    'start-with-gitmoji': [0, 'always'],
    'body-leading-blank': [1, 'always'],
    'body-max-line-length': [2, 'always', 100],
    'footer-leading-blank': [1, 'always'],
    'footer-max-line-length': [2, 'always', 100],
    'header-max-length': [2, 'always', 100],
    'subject-case': [2, 'never', ['sentence-case', 'start-case', 'pascal-case', 'upper-case']],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'type-enum': [
      2,
      'always',
      [
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
        'ingnore',
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
    ],
  },
}