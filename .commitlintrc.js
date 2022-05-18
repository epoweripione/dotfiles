"use strict";
// .commitlintrc.js
/** @type {import('cz-git').UserConfig} */
var commitTypes = [
	{
		"value": "feat",
		"name": "feat:         ✨ 新增功能 | New feature",
		"emoji": "✨"
	},
	{
		"value": "fix",
		"name": "fix:          🐛 修复缺陷 | Bug fix",
		"emoji": "🐛"
	},
	{
		"value": "hotfix",
		"name": "hotfix:       🚑 紧急修复 | Critical hotfix",
		"emoji": "🚑"
	},
	{
		"value": "patch",
		"name": "patch:        🩹 简易修复 | Simple fix for a non-critical issue",
		"emoji": "🩹"
	},
	{
		"value": "style",
		"name": "style:        🎨 代码格式 | Improve structure/format of the code",
		"emoji": "🎨"
	},
	{
		"value": "docs",
		"name": "docs:         📝 文档相关 | Add or update documentation",
		"emoji": "📝"
	},
	{
		"value": "perf",
		"name": "perf:         🌠 性能相关 | Improve performance",
		"emoji": "🌠"
	},
	{
		"value": "chore",
		"name": "chore:        🎫 其他修改 | Chores",
		"emoji": "🎫"
	},
	{
		"value": "build",
		"name": "build:        🏭 构建相关 | Add or update build system",
		"emoji": "🏭"
	},
	{
		"value": "ui",
		"name": "ui:           💄 界面相关 | Add or update UI and style files",
		"emoji": "💄"
	},
	{
		"value": "refactor",
		"name": "refactor:     🌀 代码重构 | Refactor code",
		"emoji": "🌀"
	},
	{
		"value": "config",
		"name": "config:       🔧 配置相关 | Add or update configuration files",
		"emoji": "🔧"
	},
	{
		"value": "i18n",
		"name": "i18n:         🌐 国际化和本地化 | Internationalization and localization",
		"emoji": "🌐"
	},
	{
		"value": "typo",
		"name": "typo:         ✎ 拼写修正 | Fix typos",
		"emoji": "✎"
	},
	{
		"value": "revert",
		"name": "revert:       ⏪ 回退代码 | Revert changes",
		"emoji": "⏪"
	},
	{
		"value": "merge",
		"name": "merge:        🔀 合并分支 | Merge branches",
		"emoji": "🔀"
	},
	{
		"value": "break",
		"name": "break:        💥 重大变更 | Introduce breaking changes",
		"emoji": "💥"
	},
	{
		"value": "api",
		"name": "api:          👽 外部 API 相关 | Update code due to external API changes",
		"emoji": "👽"
	},
	{
		"value": "lint",
		"name": "lint:         🚨 编译器/代码检查警告修复 | Fix compiler/linter warnings",
		"emoji": "🚨"
	},
	{
		"value": "test",
		"name": "test:         ✅ 测试相关 | Add, update, or pass tests",
		"emoji": "✅"
	},
	{
		"value": "prune",
		"name": "prune:        🔥 删除代码或文件 | Remove code or files",
		"emoji": "🔥"
	},
	{
		"value": "move",
		"name": "move:         🚚 文件/路径/路由 | Move or rename resources (e.g.: files, paths, routes)",
		"emoji": "🚚"
	},
	{
		"value": "data",
		"name": "data:         📡 数据相关 | Data exploration/inspection",
		"emoji": "📡"
	},
	{
		"value": "db",
		"name": "db:           💽 数据库相关 | Perform database related changes",
		"emoji": "💽"
	},
	{
		"value": "ux",
		"name": "ux:           🚸 用户体验相关 | Improve user experience/usability",
		"emoji": "🚸"
	},
	{
		"value": "business",
		"name": "business:     👔 业务逻辑 | Add or update business logic",
		"emoji": "👔"
	},
	{
		"value": "arch",
		"name": "arch:         🏠 架构相关 | Make architectural changes",
		"emoji": "🏠"
	},
	{
		"value": "texts",
		"name": "texts:        💬 文本相关 | Add or update text and literals",
		"emoji": "💬"
	},
	{
		"value": "assets",
		"name": "assets:       🍱 资源相关 | Add or update assets",
		"emoji": "🍱"
	},
	{
		"value": "auth",
		"name": "auth:         🛂 权限认证 | Work on code related to authorization, roles and permissions",
		"emoji": "🛂"
	},
	{
		"value": "access",
		"name": "access:       ♿ 可访问性 | Improve accessibility",
		"emoji": "♿"
	},
	{
		"value": "review",
		"name": "review:       👌 代码审查导致的更改 | Update code due to code review changes",
		"emoji": "👌"
	},
	{
		"value": "experiment",
		"name": "experiment:   🧪 实验性功能相关 | Perform experiments",
		"emoji": "🧪"
	},
	{
		"value": "flags",
		"name": "flags:        🚩 新功能相关 | Add, update, or remove feature flags",
		"emoji": "🚩"
	},
	{
		"value": "animation",
		"name": "animation:    💫 动画相关 | Add or update animations and transitions",
		"emoji": "💫"
	},
	{
		"value": "responsive",
		"name": "responsive:   📱 响应式设计 | Work on responsive design",
		"emoji": "📱"
	},
	{
		"value": "types",
		"name": "types:        📔 类型相关 | Add or update types",
		"emoji": "📔"
	},
	{
		"value": "mock",
		"name": "mock:         🤡 模拟相关 | Mock things",
		"emoji": "🤡"
	},
	{
		"value": "script",
		"name": "script:       🔨 脚本相关 | Add or update development scripts",
		"emoji": "🔨"
	},
	{
		"value": "error",
		"name": "error:        🥅 捕获错误 | Catch errors",
		"emoji": "🥅"
	},
	{
		"value": "healthcheck",
		"name": "healthcheck:  🩺 健康检查 | Add or update healthcheck",
		"emoji": "🩺"
	},
	{
		"value": "package",
		"name": "package:      📦 编译文件或包相关 | Add or update compiled files or packages",
		"emoji": "📦"
	},
	{
		"value": "dep-add",
		"name": "dep-add:      ➕ 增加依赖 | Add dependencies",
		"emoji": "➕"
	},
	{
		"value": "dep-rm",
		"name": "dep-rm:       ➖ 移除依赖 | Remove dependencies",
		"emoji": "➖"
	},
	{
		"value": "dep-down",
		"name": "dep-down:     ⬇ 降级依赖 | Downgrade dependencies",
		"emoji": "⬇"
	},
	{
		"value": "dep-up",
		"name": "dep-up:       ⬆ 升级依赖 | Upgrade dependencies",
		"emoji": "⬆"
	},
	{
		"value": "pushpin",
		"name": "pushpin:      📌 固定依赖到特定版本 | Pin dependencies to specific versions",
		"emoji": "📌"
	},
	{
		"value": "init",
		"name": "init:         🎉 开始新项目 | Begin a project",
		"emoji": "🎉"
	},
	{
		"value": "wip",
		"name": "wip:          🚧 工作进行中 | Work in progress",
		"emoji": "🚧"
	},
	{
		"value": "deploy",
		"name": "deploy:       🚀 部署相关 | Deploy stuff",
		"emoji": "🚀"
	},
	{
		"value": "release",
		"name": "release:      🔖 发布/版本标签 | Release/Version tags",
		"emoji": "🔖"
	},
	{
		"value": "analytics",
		"name": "analytics:    📈 分析跟踪代码 | Add or update analytics or track code",
		"emoji": "📈"
	},
	{
		"value": "security",
		"name": "security:     🔒 安全修复 | Fix security issues",
		"emoji": "🔒"
	},
	{
		"value": "ci",
		"name": "ci:           👷 CI 持续集成 | Add or update CI build system",
		"emoji": "👷"
	},
	{
		"value": "fixci",
		"name": "fixci:        💚 修复 CI 构建 | Fix CI Build",
		"emoji": "💚"
	},
	{
		"value": "clean",
		"name": "clean:        🧹 弃用代码 | Deprecate code that needs to be cleaned up",
		"emoji": "🧹"
	},
	{
		"value": "deadcode",
		"name": "deadcode:     🚮 移除无效代码 | Remove dead code",
		"emoji": "🚮"
	},
	{
		"value": "docker",
		"name": "docker:       🐳 Docker 相关 | Work about Docker",
		"emoji": "🐳"
	},
	{
		"value": "k8s",
		"name": "k8s:          🎡 K8S 相关 | Work about Kubernetes",
		"emoji": "🎡"
	},
	{
		"value": "osx",
		"name": "osx:          🍎 macOS 相关 | Fix something on macOS",
		"emoji": "🍎"
	},
	{
		"value": "linux",
		"name": "linux:        🐧 Linux 相关 | Fix something on Linux",
		"emoji": "🐧"
	},
	{
		"value": "windows",
		"name": "windows:      🏁 Windows 相关 | Fix something on Windows",
		"emoji": "🏁"
	},
	{
		"value": "android",
		"name": "android:      🤖 Android 相关 | Fix something on Android",
		"emoji": "🤖"
	},
	{
		"value": "ios",
		"name": "ios:          🍏 iOS 相关 | Fix something on iOS",
		"emoji": "🍏"
	},
	{
		"value": "ignore",
		"name": "ignore:       🙈 .gitignore 相关 | Add or update .gitignore file",
		"emoji": "🙈"
	},
	{
		"value": "comment",
		"name": "comment:      💡 代码注释 | Add or update comments in source code",
		"emoji": "💡"
	},
	{
		"value": "snapshot",
		"name": "snapshot:     📸 快照相关 | Add or update snapshots",
		"emoji": "📸"
	},
	{
		"value": "addlog",
		"name": "addlog:       🔊 增加或更新日志 | Add or update logs",
		"emoji": "🔊"
	},
	{
		"value": "rmlog",
		"name": "rmlog:        🔇 移除日志 | Remove logs",
		"emoji": "🔇"
	},
	{
		"value": "seed",
		"name": "seed:         🌱 种子文件 | Add or update seed files",
		"emoji": "🌱"
	},
	{
		"value": "seo",
		"name": "seo:          🔍 SEO 优化 | Improve SEO",
		"emoji": "🔍"
	},
	{
		"value": "contrib",
		"name": "contrib:      👥 贡献者 | Add or update contributor(s)",
		"emoji": "👥"
	},
	{
		"value": "license",
		"name": "license:      📄 许可证 | Add or update license",
		"emoji": "📄"
	},
	{
		"value": "egg",
		"name": "egg:          🥚 彩蛋 | Add or update an easter egg",
		"emoji": "🥚"
	},
	{
		"value": "beer",
		"name": "beer:         🍻 醉酒写代码 | Write code drunkenly",
		"emoji": "🍻"
	},
	{
		"value": "poo",
		"name": "poo:          💩 糟糕代码 | Write bad code that needs to be improved",
		"emoji": "💩"
	}
];
module.exports = {
    parserPreset: './commitlint.parser-preset',
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
