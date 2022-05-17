"use strict";
// .commitlintrc.js
/** @type {import('cz-git').UserConfig} */
var commitTypes = [
	{
		"value": "feat",
		"name": "feat:         ✨ Introduce new features",
		"emoji": "✨"
	},
	{
		"value": "fix",
		"name": "fix:          🐛 Fix bug",
		"emoji": "🐛"
	},
	{
		"value": "hotfix",
		"name": "hotfix:       🚑 Critical hotfix",
		"emoji": "🚑"
	},
	{
		"value": "patch",
		"name": "patch:        🩹 Simple fix for a non-critical issue",
		"emoji": "🩹"
	},
	{
		"value": "style",
		"name": "style:        🎨 Improve structure / format of the code",
		"emoji": "🎨"
	},
	{
		"value": "docs",
		"name": "docs:         📝 Add or update documentation",
		"emoji": "📝"
	},
	{
		"value": "perf",
		"name": "perf:         🌠 Improve performance",
		"emoji": "🌠"
	},
	{
		"value": "chore",
		"name": "chore:        🎫 Chores",
		"emoji": "🎫"
	},
	{
		"value": "build",
		"name": "build:        🏭 Add or update build system",
		"emoji": "🏭"
	},
	{
		"value": "ui",
		"name": "ui:           💄 Add or update UI and style files",
		"emoji": "💄"
	},
	{
		"value": "refactor",
		"name": "refactor:     🌀 Refactor code",
		"emoji": "🌀"
	},
	{
		"value": "config",
		"name": "config:       🔧 Add or update configuration files",
		"emoji": "🔧"
	},
	{
		"value": "i18n",
		"name": "i18n:         🌐 Internationalization and localization",
		"emoji": "🌐"
	},
	{
		"value": "typo",
		"name": "typo:         ✎ Fix typos",
		"emoji": "✎"
	},
	{
		"value": "revert",
		"name": "revert:       ⏪ Revert changes",
		"emoji": "⏪"
	},
	{
		"value": "merge",
		"name": "merge:        🔀 Merge branches",
		"emoji": "🔀"
	},
	{
		"value": "break",
		"name": "break:        💥 Introduce breaking changes",
		"emoji": "💥"
	},
	{
		"value": "api",
		"name": "api:          👽 Update code due to external API changes",
		"emoji": "👽"
	},
	{
		"value": "lint",
		"name": "lint:         🚨 Fix compiler / linter warnings",
		"emoji": "🚨"
	},
	{
		"value": "test",
		"name": "test:         ✅ Add, update, or pass tests",
		"emoji": "✅"
	},
	{
		"value": "prune",
		"name": "prune:        🔥 Remove code or files",
		"emoji": "🔥"
	},
	{
		"value": "move",
		"name": "move:         🚚 Move or rename resources (e.g.: files, paths, routes)",
		"emoji": "🚚"
	},
	{
		"value": "data",
		"name": "data:         📡 Data exploration / inspection",
		"emoji": "📡"
	},
	{
		"value": "db",
		"name": "db:           💽 Perform database related changes",
		"emoji": "💽"
	},
	{
		"value": "ux",
		"name": "ux:           🚸 Improve user experience / usability",
		"emoji": "🚸"
	},
	{
		"value": "business",
		"name": "business:     👔 Add or update business logic",
		"emoji": "👔"
	},
	{
		"value": "arch",
		"name": "arch:         🏠 Make architectural changes",
		"emoji": "🏠"
	},
	{
		"value": "texts",
		"name": "texts:        💬 Add or update text and literals",
		"emoji": "💬"
	},
	{
		"value": "assets",
		"name": "assets:       🍱 Add or update assets",
		"emoji": "🍱"
	},
	{
		"value": "auth",
		"name": "auth:         🛂 Work on code related to authorization, roles and permissions",
		"emoji": "🛂"
	},
	{
		"value": "access",
		"name": "access:       ♿ Improve accessibility",
		"emoji": "♿"
	},
	{
		"value": "review",
		"name": "review:       👌 Update code due to code review changes",
		"emoji": "👌"
	},
	{
		"value": "experiment",
		"name": "experiment:   🧪 Perform experiments",
		"emoji": "🧪"
	},
	{
		"value": "flags",
		"name": "flags:        🚩 Add, update, or remove feature flags",
		"emoji": "🚩"
	},
	{
		"value": "animation",
		"name": "animation:    💫 Add or update animations and transitions",
		"emoji": "💫"
	},
	{
		"value": "responsive",
		"name": "responsive:   📱 Work on responsive design",
		"emoji": "📱"
	},
	{
		"value": "types",
		"name": "types:        📔 Add or update types",
		"emoji": "📔"
	},
	{
		"value": "mock",
		"name": "mock:         🤡 Mock things",
		"emoji": "🤡"
	},
	{
		"value": "script",
		"name": "script:       🔨 Add or update development scripts",
		"emoji": "🔨"
	},
	{
		"value": "error",
		"name": "error:        🥅 Catch errors",
		"emoji": "🥅"
	},
	{
		"value": "healthcheck",
		"name": "healthcheck:  🩺 Add or update healthcheck",
		"emoji": "🩺"
	},
	{
		"value": "package",
		"name": "package:      📦 Add or update compiled files or packages",
		"emoji": "📦"
	},
	{
		"value": "dep-add",
		"name": "dep-add:      ➕ Add dependencies",
		"emoji": "➕"
	},
	{
		"value": "dep-rm",
		"name": "dep-rm:       ➖ Remove dependencies",
		"emoji": "➖"
	},
	{
		"value": "dep-down",
		"name": "dep-down:     ⬇ Downgrade dependencies",
		"emoji": "⬇"
	},
	{
		"value": "dep-up",
		"name": "dep-up:       ⬆ Upgrade dependencies",
		"emoji": "⬆"
	},
	{
		"value": "pushpin",
		"name": "pushpin:      📌 Pin dependencies to specific versions",
		"emoji": "📌"
	},
	{
		"value": "init",
		"name": "init:         🎉 Begin a project",
		"emoji": "🎉"
	},
	{
		"value": "wip",
		"name": "wip:          🚧 Work in progress",
		"emoji": "🚧"
	},
	{
		"value": "deploy",
		"name": "deploy:       🚀 Deploy stuff",
		"emoji": "🚀"
	},
	{
		"value": "release",
		"name": "release:      🔖 Release / Version tags",
		"emoji": "🔖"
	},
	{
		"value": "analytics",
		"name": "analytics:    📈 Add or update analytics or track code",
		"emoji": "📈"
	},
	{
		"value": "security",
		"name": "security:     🔒 Fix security issues",
		"emoji": "🔒"
	},
	{
		"value": "ci",
		"name": "ci:           👷 Add or update CI build system",
		"emoji": "👷"
	},
	{
		"value": "fixci",
		"name": "fixci:        💚 Fix CI Build",
		"emoji": "💚"
	},
	{
		"value": "clean",
		"name": "clean:        🧹 Deprecate code that needs to be cleaned up",
		"emoji": "🧹"
	},
	{
		"value": "deadcode",
		"name": "deadcode:     🚮 Remove dead code",
		"emoji": "🚮"
	},
	{
		"value": "docker",
		"name": "docker:       🐳 Work about Docker",
		"emoji": "🐳"
	},
	{
		"value": "k8s",
		"name": "k8s:          🎡 Work about Kubernetes",
		"emoji": "🎡"
	},
	{
		"value": "osx",
		"name": "osx:          🍎 Fix something on macOS",
		"emoji": "🍎"
	},
	{
		"value": "linux",
		"name": "linux:        🐧 Fix something on Linux",
		"emoji": "🐧"
	},
	{
		"value": "windows",
		"name": "windows:      🏁 Fix something on Windows",
		"emoji": "🏁"
	},
	{
		"value": "android",
		"name": "android:      🤖 Fix something on Android",
		"emoji": "🤖"
	},
	{
		"value": "ios",
		"name": "ios:          🍏 Fix something on iOS",
		"emoji": "🍏"
	},
	{
		"value": "ignore",
		"name": "ignore:       🙈 Add or update .gitignore file",
		"emoji": "🙈"
	},
	{
		"value": "comment",
		"name": "comment:      💡 Add or update comments in source code",
		"emoji": "💡"
	},
	{
		"value": "snapshot",
		"name": "snapshot:     📸 Add or update snapshots",
		"emoji": "📸"
	},
	{
		"value": "addlog",
		"name": "addlog:       🔊 Add or update logs",
		"emoji": "🔊"
	},
	{
		"value": "rmlog",
		"name": "rmlog:        🔇 Remove logs",
		"emoji": "🔇"
	},
	{
		"value": "seed",
		"name": "seed:         🌱 Add or update seed files",
		"emoji": "🌱"
	},
	{
		"value": "seo",
		"name": "seo:          🔍 Improve SEO",
		"emoji": "🔍"
	},
	{
		"value": "contrib",
		"name": "contrib:      👥 Add or update contributor(s)",
		"emoji": "👥"
	},
	{
		"value": "license",
		"name": "license:      📄 Add or update license",
		"emoji": "📄"
	},
	{
		"value": "egg",
		"name": "egg:          🥚 Add or update an easter egg",
		"emoji": "🥚"
	},
	{
		"value": "beer",
		"name": "beer:         🍻 Write code drunkenly",
		"emoji": "🍻"
	},
	{
		"value": "poo",
		"name": "poo:          💩 Write bad code that needs to be improved",
		"emoji": "💩"
	}
];
module.exports = {
    rules: {
        // @see: https://commitlint.js.org/#/reference-rules
        "type-empty": [2, "never"],
        "type-case": [2, "always", "lower-case"],
        "type-enum": [2, "always", commitTypes.map(function (type) { return type.value; })],
        "scope-case": [2, "always", "lower-case"],
        "subject-empty": [2, "never"],
    },
    prompt: {
        messages: {
            type: "Select the type of change that you're committing 选择你要提交的类型：\n",
            scope: "Denote the SCOPE of this change (optional) 选择一个提交范围（可选）：\n",
            customScope: "Denote the SCOPE of this change 请输入自定义的提交范围：\n",
            subject: "Write a SHORT, IMPERATIVE tense description of the change 填写简短精炼的变更描述：\n",
            body: 'Provide a LONGER description of the change (optional). Use "|" to break new line 填写更加详细的变更描述（可选）。使用 "|" 换行：\n',
            breaking: 'List any BREAKING CHANGES (optional). Use "|" to break new line 列举非兼容性重大的变更（可选）。使用 "|" 换行：\n',
            footerPrefixsSelect: "Select the ISSUES type of changeList by this change (optional) 选择关联 issue 前缀类型（可选）：",
            customFooterPrefixs: "Input ISSUES prefix 输入自定义 issue 前缀：",
            footer: "List any ISSUES by this change. E.g.: #31, #34 列举关联 issue (可选) 例如: #31, #I3244：\n",
            confirmCommit: "Are you sure you want to proceed with the commit above? 确认提交以上 commit？",
        },
        types: commitTypes,
        useEmoji: true,
        scopes: [],
        allowCustomScopes: true,
        allowEmptyScopes: true,
        customScopesAlign: "bottom",
        customScopesAlias: "custom",
        emptyScopesAlias: "empty",
        upperCaseSubject: false,
        allowBreakingChanges: ["feat", "fix"],
        breaklineNumber: 100,
        breaklineChar: "|",
        skipQuestions: ["breaking", "footerPrefix"],
        issuePrefixs: [
            { value: "closed", name: "closed:   ISSUES has been processed" }
        ],
        customIssuePrefixsAlign: "top",
        emptyIssuePrefixsAlias: "skip",
        customIssuePrefixsAlias: "custom",
        allowCustomIssuePrefixs: true,
        allowEmptyIssuePrefixs: true,
        confirmColorize: true,
        maxHeaderLength: Infinity,
        maxSubjectLength: Infinity,
        minSubjectLength: 0,
        scopeOverrides: undefined,
        defaultBody: "",
        defaultIssues: "",
        defaultScope: "",
        defaultSubject: "",
    },
};
