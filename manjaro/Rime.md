# [RIME - 中州韻輸入法引擎](https://rime.im/)

## 输入方案
### [Oh-my-rime | 薄荷输入法](https://github.com/Mintimate/oh-my-rime)
### [雾凇拼音 | 长期维护的简体词库](https://github.com/iDvel/rime-ice)
### [四叶草拼音输入方案](https://github.com/fkxxyz/rime-cloverpinyin)
### [粵語拼音輸入方案](https://github.com/rime/rime-cantonese)
### [具备码元提示功能的 98五笔 配置文件](https://github.com/yanhuacuo/98wubi)


## [小狼毫輸入法 for Windows](https://github.com/rime/weasel)
### [安装](https://github.com/rime/weasel/releases/latest)
### 配置
- 备份 Rime 原用户目录：将 `$HOME\AppData\Roaming\Rime` 中的所有文件复制到目录 `$HOME\AppData\Roaming\Rime.old`
- 按需下载输入方案
```bash
git clone https://github.com/iDvel/rime-ice
git clone https://github.com/rime/rime-cantonese
curl -fSL -o clover.schema-1.1.4.zip https://github.com/fkxxyz/rime-cloverpinyin/releases/download/1.1.4/clover.schema-1.1.4.zip
```
- 删除 `$HOME\AppData\Roaming\Rime` 中的所有文件/文件夹
- 复制目录 `rime-ice` 中的所有文件/文件夹到目录 `$HOME\AppData\Roaming\Rime`
- 复制文件 `default.custom.yaml` 到目录 `$HOME\AppData\Roaming\Rime`
- 复制文件 `weasel.custom.yaml` 到目录 `$HOME\AppData\Roaming\Rime`

### 增加输入方案
- 四叶草拼音：将文件 `clover.schema-1.1.4.zip` 解压到目录 `$HOME\AppData\Roaming\Rime`
- 粵語拼音：将目录 `rime-cantonese` 中的文件复制到目录 `$HOME\AppData\Roaming\Rime`

### 重新部署输入法
- `Ctrl+Space` 切换中文输入模式→`Ctrl+Shift` 切换到 `小狼毫输入法`→右键→重启算法服务→重新部署


## [鼠鬚管輸入法 for macOS](https://github.com/rime/squirrel)
### [安装](https://github.com/rime/squirrel/releases)


## [小企鹅输入法 5 (Fcitx 5) for Android](https://github.com/fcitx5-android/fcitx5-android)
### [安装](https://f-droid.org/packages/org.fcitx.fcitx5.android)


## 配置文件夹
- Windows: `$HOME\AppData\Roaming\Rime`
- iBus: `$HOME/.config/ibus/rime`
- Fcitx5: `$HOME/.local/share/fcitx5/rime`
- macOS: `$HOME/Library/Rime`
- Android: `/storage/emulated/0/Android/data/org.fcitx.fcitx5.android/files/data/rime/`


## 快捷键
- `Ctrl+~` 切换输入方案
- Ctrl+Alt+Shift+u: Unicode encoding & emoji & special characters
- 快速输入带声调的汉语拼音：切换至 `拼音符号(M17N)` 输入法，然后用 拼音 + 数字1234
- Restart Fcitx5
```bash
kill `ps -A | grep fcitx5 | awk '{print $1}'` && fcitx5&
```

## [白霜拼音](https://github.com/iDvel/rime-ice)
- 默认英文模式：`Ctrl+~`→2→2
- 特殊符号：`/`模式，见 `$HOME\AppData\Roaming\Rime\symbols_v.yaml`
  + 符号 `/fh`
  + 电脑 `/dn`
  + 天气 `/tq`
  + 星号 `/xh`
  + 方块 `/fk`
  + 几何 `/jh`
  + 箭头 `/jt`
  + 数学 `/sx`
  + 数字+圈/弧/点 `/szq、/szh、/szd`
  + 字母+圈/弧 `/zmq、/zmh`
  + 汉字+圈/弧 `/hzq、/hzh`
  + 数字 `/0.../9`
  + 分数 `/fs`
  + 罗马数字 `/lm、/lmd`
  + 拉丁 `/a...z、/A...Z、/aa.../ww`
  + 希腊 `/xl、/xld`
  + 上标、下标 `/sb、/xb`
  + 月份、日期、曜日等 `/yf、/rq、/yr`
  + 时间 `/sj`
  + 天干、地支、干支 `/tg、/dz、/gz`
  + 节气 `/jq`
  + 单位 `/dw`
  + 货币 `/hb`
  + 结构、偏旁、康熙（部首）、笔画、标点 `/jg、/pp、/kx、/bh、/bd、/bdz`
  + 中文标点符号：点号、非夹、夹注、行间 `/dh、/fj、/jz、/hj`
  + 中英标点 `/bdzy`
  + 拼音、注音、声调 `/py、/zy、/sd`
  + 带调韵母：`/a、/e、/u...`
  + 音乐 `/yy`
  + 两性 `/lx`
  + 八卦、八卦名、六十四卦、六十四卦名、太玄经 `/bg、/bgm、/lssg、/lssgm、/txj`
  + 天体、星座、星座名、十二宫 `/tt、/xz、/xzm、/xzg`
  + ...
- 自定义短语：`custom_phrase.custom.txt`
- 以词定字：默认快捷键为左右中括号 `[ ]`，分别取第一个和最后一个字
- 日期时间：全拼的触发编码为 `rq sj xq dt ts`，双拼为 `date time week datetime timestamp`
- 部件拆字的反查：`uU`开头，如 `uUkoukou`得到`回、吕`等字
- 部件拆字的辅码：` 触发
- Unicode：大写 `U` 开头，如 `U62fc`得到`拼`
- 数字、金额大写：大写 `R` 开头，如 `R1234` 得到 `一千二百三十四、壹仟贰佰叁拾肆元整`
- 农历：`nl`
- 农历（指定日期）：大写 `N` 开头，如 `N20240210` 得到 `二〇二四年正月初一`
- 简易计算器：大写`V`开头，如`V10*10`，得到`100`
- 删除不想要的自造词：使用方向键选中要删除的候选词，再按下 `Fn+Shift+Delete` 即可删除
- 使用 Tab 键在拼音之间切换光标：拼音打错了或者想单独修改前面的某个字，按 `Tab` 键或 `Shift + Tab` 在拼音中前后切换光标到对应的拼音

## [雾凇拼音](https://github.com/iDvel/rime-ice)
- 默认英文模式：`Ctrl+~`→2→2
- 特殊符号：`v`模式，全拼 `v` 开头、双拼大写 `V` 开头，见 `$HOME\AppData\Roaming\Rime\symbols_v_ice.yaml`
  + 符号 `vfh`
  + 电脑 `vdn`
  + 天气 `vtq`
  + 星号 `vxh`
  + 方块 `vfk`
  + 几何 `vjh`
  + 箭头 `vjt`
  + 数学 `vsx`
  + 数字+圈/弧/点 `vszq/vszh/vszd`
  + 字母+圈/弧 `vzmq/vzmh`
  + 汉字+圈/弧 `vhzq/vhzh`
  + 数字 `v0...v9`
  + 分数 `vfs`
  + 罗马数字 `vlm/vlmd`
  + 拉丁 `va...z/vA...Z/vaa...vww`
  + 希腊 `vxl/vxld`
  + 上标、下标 `vsb/vxb`
  + 月份、日期、曜日等 `vyf/vrq/vyr`
  + 时间 `vsj`
  + 天干、地支、干支 `vtg/vdz/vgz`
  + 节气 `vjq`
  + 单位 `vdw`
  + 货币 `vhb`
  + 结构、偏旁、康熙（部首）、笔画、标点 `vjg/vpp/vkx/vbh/vbd/vbdz`
  + 中文标点符号：点号、非夹、夹注、行间 `vdh/vfj/vjz/vhj`
  + 中英标点 `vbdzy`
  + 拼音、注音、声调 `vpy/vzy/vsd`
  + 带调韵母：`va/ve/vu...`
  + 音乐 `vyy`
  + 两性 `vlx`
  + 八卦、八卦名、六十四卦、六十四卦名、太玄经 `vbg/vbgm/vlssg/vlssgm/vtxj`
  + 天体、星座、星座名、十二宫 `vtt/vxz/vxzm/vxzg`
  + ...
- 自定义短语： `custom_phrase.custom.txt`
- 以词定字：默认快捷键为左右中括号 `[ ]`，分别取第一个和最后一个字
- 日期时间：全拼的触发编码为 `rq sj xq dt ts`，双拼为 `date time week datetime timestamp`
- 部件拆字的反查：`uU`
- 辅助码：`\``，[墨奇辅助码拆分说明](https://moqiyinxing.chunqiujinjing.com/index/mo-qi-yin-xing-shuo-ming/fu-zhu-ma-shuo-ming/mo-qi-ma-chai-fen-shuo-ming)
- Unicode：大写 `U` 开头，如 `U62fc`得到`拼`
- 数字、金额大写：大写 `R` 开头，如 `R1234` 得到 `一千二百三十四、壹仟贰佰叁拾肆元整`
- 农历：`nl`
- 农历（指定日期）：大写 `N` 开头，如 `N20240210` 得到 `二〇二四年正月初一`
- 简易计算器：`cC`开头，如`cC10*10`，得到`100`
- 删除不想要的自造词：使用方向键选中要删除的候选词，再按下 `Fn+Shift+Delete` 即可删除
- 使用 Tab 键在拼音之间切换光标：拼音打错了或者想单独修改前面的某个字，按 `Tab` 键或 `Shift + Tab` 在拼音中前后切换光标到对应的拼音


## 四叶草
- Ctrl+.: switch between symbols ASCII Punctuation and Chinese Punctuation Marks
- ; v: QuickPhrase
- Ctrl+Shift+2: Ctrl+Shift+f: switch between Traditional Chinese and Simplified Chinese
- Ctrl+Shift+3: emoji
- Ctrl+Shift+4: special characters
- Ctrl+Shift+5: Ctrl+, Ctrl+.: switch between symbols ASCII Punctuation and Chinese Punctuation Marks
- Ctrl+Shift+6: Shift+Space: switch between halfwidth and fullwidth punctuation


## ~~[Rime auto deploy](https://github.com/Mark24Code/rime-auto-deploy)~~
```powershell
scoop install ruby msys2
ridk install # 3 - MSYS2 and MINGW development toolchain
ruby --version
git clone "https://github.com/Mark24Code/rime-auto-deploy" "C:\DevWorkSpaces\rime-auto-deploy"
Set-Location "C:\DevWorkSpaces"
ruby .\installer.rb
```
