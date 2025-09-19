# VSCode 扩展命令配置完整指南

## 🎯 菜单分组的具体位置

### 1. `"editor/context"` - 编辑器右键菜单

```json
{
    "command": "satt.cfml.formatDocumentHri",
    "when": "editorLangId == cfml",
    "group": "navigation"
}
```

**在右键菜单中的实际位置**：

```
┌─────────────────────────────┐
│ ↗ Undo                 Ctrl+Z │  ← navigation 组
│ ↘ Redo                 Ctrl+Y │
├─────────────────────────────┤
│ Cut                    Ctrl+X │  ← 1_modification 组  
│ Copy                   Ctrl+C │
│ Paste                  Ctrl+V │
├─────────────────────────────┤
│ Format CFML (satt)           │  ← 你的命令在这里！
├─────────────────────────────┤
│ ...更多选项...               │  ← z_more 组
└─────────────────────────────┘
```

### 2. `"commandPalette"` - 命令面板 (Ctrl+Shift+P)

```json
{
    "command": "satt.cfml.formatDocumentHri",
    "when": "editorLangId == cfml"
}
```

**在命令面板中的显示**：

```
> CFML: Format CFML (satt)     ← 因为有 category: "CFML"
> Other Extension: Some Command
> Another Command
```

## 🔍 分组的具体含义

### `"navigation"` 组
- **位置**：右键菜单的最顶部
- **典型命令**：撤销、重做、转到定义等
- **适合**：导航类操作

### `"1_modification"` 组
- **位置**：在导航组下面
- **典型命令**：剪切、复制、粘贴
- **适合**：内容修改操作

### `"9_cutcopypaste"` 组
- **位置**：在修改组下面
- **典型命令**：高级剪贴板操作
- **适合**：格式化、代码操作

### `"z_more"` 组
- **位置**：右键菜单的最底部
- **典型命令**：不太常用的功能
- **适合**：辅助功能

## 💡 配置建议

对于格式化命令，推荐使用：

```json
{
    "command": "satt.cfml.formatDocumentHri",
    "when": "editorLangId == cfml",
    "group": "9_cutcopypaste@1"
}
```

或者：

```json
{
    "command": "satt.cfml.formatDocumentHri", 
    "when": "editorLangId == cfml",
    "group": "1_modification@2"
}
```

## ⚙️ 完整配置示例

```json
"contributes": {
    "commands": [
        {
            "command": "satt.cfml.formatDocumentHri",
            "title": "Format CFML (satt)",
            "category": "CFML"
        },
        {
            "command": "satt.cfml.debug",
            "title": "CFML: Debug Info",
            "category": "CFML"
        }
    ],
    "menus": {
        "editor/context": [
            {
                "command": "satt.cfml.formatDocumentHri",
                "when": "editorLangId == cfml || editorLangId == cfm || editorLangId == cfc",
                "group": "9_cutcopypaste"
            }
        ],
        "commandPalette": [
            {
                "command": "satt.cfml.formatDocumentHri",
                "when": "editorLangId == cfml || editorLangId == cfm || editorLangId == cfc"
            },
            {
                "command": "satt.cfml.debug",
                "when": "true"
            }
        ]
    },
    "keybindings": [
        {
            "command": "satt.cfml.debug",
            "key": "ctrl+shift+d ctrl+i",
            "when": "editorTextFocus"
        }
    ]
}
```

## 📋 常用条件表达式

- `"editorTextFocus"` - 编辑器有焦点时
- `"editorLangId == javascript"` - 特定语言文件
- `"resourceScheme == file"` - 只对文件系统文件
- `"true"` - 始终显示
- `"resourceExtname == .cfc"` - 特定文件扩展名

## 🔧 调试技巧

```javascript
// 检查实际语言ID
const editor = vscode.window.activeTextEditor;
if (editor) {
    console.log("实际语言ID:", editor.document.languageId);
    console.log("文件名:", editor.document.fileName);
}

// 检查所有已注册命令
const commands = await vscode.commands.getCommands();
console.log(commands.filter(cmd => cmd.includes('cfml')));
```


---

这些是 VSCode 扩展配置中非常重要的部分！我来详细解释：

## 📋 `"categories"` - 扩展分类

```json
"categories": [
    "Formatters"
]
```

**作用**：告诉 VSCode 和市场你的扩展属于什么类别

**常用分类**：
- `"Formatters"` - 代码格式化工具
- `"Linters"` - 代码检查工具
- `"Snippets"` - 代码片段
- `"Themes"` - 主题
- `"Programming Languages"` - 编程语言支持
- `"Debuggers"` - 调试器
- `"Other"` - 其他类别

**好处**：
- 在 VSCode 市场中更容易被发现
- 用户可以根据分类筛选扩展
- 帮助用户理解扩展的主要功能

---

## ⚡ `"activationEvents"` - 激活事件

```json
"activationEvents": [
    "onLanguage:cfml",
    "onLanguage:cfm", 
    "onLanguage:cfc"
]
```

**作用**：控制扩展何时被加载和激活（为了性能优化）

### 常用激活事件：

#### 1. **语言相关激活**
```json
"onLanguage:javascript",
"onLanguage:typescript",
"onLanguage:python"
// 当打开特定语言文件时激活
```

#### 2. **命令相关激活**  
```json
"onCommand:extension.formatDocument"
// 当用户执行特定命令时激活
```

#### 3. **工作区相关激活**
```json
"onWorkspaceContains:package.json",
"onFileSystem:file",
"onFileSystem:ssh"
```

#### 4. **其他激活事件**
```json
"onStartupFinished",          // VSCode 启动完成后
"onDebug",                    // 调试会话开始时
"onTerminalProfile",          // 终端配置时
"onAuthenticationRequest",    // 认证请求时
```

---

## 🎯 你的配置含义

```json
"activationEvents": [
    "onLanguage:cfml",    // 当打开 .cfml 文件时
    "onLanguage:cfm",     // 当打开 .cfm 文件时
    "onLanguage:cfc"      // 当打开 .cfc 文件时
]
```

这意味着：
- ✅ **只有当用户打开 CFML 相关文件时**，你的扩展才会被加载
- ❌ 用户打开其他类型文件（如.js、.html）时，扩展不会被加载
- ⚡ **大幅提升性能**，避免不必要的内存占用

---

## 🔧 性能优化对比

### 不好的做法（性能差）：
```json
"activationEvents": ["*"]  // 启动时就加载所有扩展
```

### 好的做法（性能优）：
```json
"activationEvents": [
    "onLanguage:cfml",
    "onCommand:satt.cfml.formatDocument"
]
// 按需加载，节省资源
```

---

## 💡 最佳实践建议

```json
{
    "categories": ["Formatters", "Programming Languages"],
    "activationEvents": [
        "onLanguage:cfml",
        "onLanguage:cfm",
        "onLanguage:cfc",
        "onCommand:satt.cfml.formatDocument",
        "onCommand:satt.cfml.debugInfo"
    ],
    "main": "./out/extension.js"
}
```

这样配置确保你的扩展：
1. **正确分类**便于用户发现
2. **按需激活**提升性能
3. **及时响应**用户操作




# 正則表達式前瞻/後瞻完整指南

## 什麼是前瞻/後瞻（Lookaround）

前瞻/後瞻是**零寬度斷言**，它們不消費字符，只檢查條件是否滿足。

## 四種類型

| 語法 | 名稱 | 說明 |
|------|------|------|
| `(?=...)` | 正向前瞻 | 後面必須是... |
| `(?!...)` | 負向前瞻 | 後面不能是... |
| `(?<=...)` | 正向後瞻 | 前面必須是... |
| `(?<!...)` | 負向後瞻 | 前面不能是... |

## 1. 正向前瞻 `(?=...)`

**語法：** `x(?=y)` - 匹配 x，但要求 x 後面緊跟 y

```javascript
// 匹配後面跟著數字的字母
/\w(?=\d)/.exec("a1b2c3");  // 匹配 "a" (後面是1)

// 匹配Java但後面必須是Script
/Java(?=Script)/.test("JavaScript");  // true
/Java(?=Script)/.test("JavaBean");    // false

// 找密碼，要求後面有數字
/\w+(?=\d)/.exec("password123");  // 匹配 "password"
```

## 2. 負向前瞻 `(?!...)`

**語法：** `x(?!y)` - 匹配 x，但要求 x 後面不能是 y

```javascript
// 匹配Java但後面不能是Script
/Java(?!Script)/.test("JavaScript");  // false
/Java(?!Script)/.test("JavaBean");    // true

// 匹配不以.com結尾的網址
/https?:\/\/[^\/]+(?!\.com)/.test("https://example.org");  // true
/https?:\/\/[^\/]+(?!\.com)/.test("https://example.com");  // false
```

## 3. 正向後瞻 `(?<=...)`

**語法：** `(?<=y)x` - 匹配 x，但要求 x 前面是 y

```javascript
// 匹配前面是$的數字
/(?<=\$)\d+/.exec("價格$100元");  // 匹配 "100"

// 匹配前面是@的用戶名
/(?<=@)\w+/.exec("聯繫 @張三 討論");  // 匹配 "張三"

// 只匹配HTML標籤中的內容
/(?<=<h1>)[^<]+/.exec("<h1>標題</h1>");  // 匹配 "標題"
```

## 4. 負向後瞻 `(?<!...)`

**語法：** `(?<!y)x` - 匹配 x，但要求 x 前面不能是 y

```javascript
// 匹配不在$前面的數字
/(?<!\$)\d+/.exec("數量100個，價格$50元");  // 匹配 "100"

// 你的例子：匹配不在cf前面的/>
/(?<!cf)\/>/.test("abc/>");   // true
/(?<!cf)\/>/.test("abcf/>");  // false
```

## 組合使用

```javascript
// 密碼驗證：8-16位，包含字母和數字
/^(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d]{8,16}$/

// 分解：
// ^                     - 開頭
// (?=.*[a-zA-Z])       - 前瞻：必須包含字母
// (?=.*\d)             - 前瞻：必須包含數字  
// [a-zA-Z\d]{8,16}     - 實際匹配：8-16位字母數字
// $                     - 結尾
```

## 實際應用示例

### 1. 提取特定格式的數據

```javascript
// 提取價格，但不要包含在括號中的
const text = "商品A ¥100 (原價¥200) 商品B ¥50";
const prices = text.match(/(?<!\(.*?)¥\d+(?!.*?\))/g);
console.log(prices); // ["¥100", "¥50"]
```

### 2. 匹配特定上下文的單詞

```javascript
// 匹配get但前面不能是target
/(?<!target)get/g.exec("get data, targetget, forget");  // 匹配第一個"get"

// 匹配set但後面不能是up
/set(?!up)/g.exec("set value, setup config, reset");    // 匹配第一個"set"
```

### 3. 複雜的驗證

```javascript
// 你的原始需求：以/>結尾但整行不包含cf
/^(?!.*cf).*\/>$/

// 分解：
// ^         - 行開頭
// (?!.*cf)  - 檢查整行不包含cf
// .*        - 匹配實際內容
// \/>       - 以/>結尾
// $         - 行結尾
```

## 瀏覽器支持

- **正向前瞻 `(?=...)`**：所有現代瀏覽器 ✅
- **負向前瞻 `(?!...)`**：所有現代瀏覽器 ✅  
- **正向後瞻 `(?<=...)`**：ES2018+ (較新瀏覽器) ⚠️
- **負向後瞻 `(?<!...)`**：ES2018+ (較新瀏覽器) ⚠️

## 調試技巧

```javascript
// 分步驗證
const text = "<div cf='test' />";

console.log(/^(?!.*cf)/.test(text));    // false - 前瞻檢查失敗
console.log(/.*\/>$/.test(text));       // true - 後面的模式匹配
console.log(/^(?!.*cf).*\/>$/.test(text)); // false - 整體失敗
```

這樣理解前瞻/後瞻了嗎？它們主要用於設置匹配的**前置條件**，而不是實際匹配內容。

---

1. 基于操作的生命周期钩子
```bash
# 安装流程
preinstall → install → postinstall

# 发布流程
prepublishOnly → prepack → prepare → postpack → publish → postpublish

# 卸载流程
preuninstall → uninstall → postuninstall
```
2. 基于脚本的自定义生命周期钩子
```bash
# 对于任何自定义脚本 "xyz"
prexyz → xyz → postxyz
```

实际应用示例
```json
{
  "scripts": {
    // 安装相关
    "preinstall": "echo '开始安装依赖...'",
    "postinstall": "echo '依赖安装完成!'",
    
    // 测试相关
    "pretest": "npm run lint", // 先检查代码风格再测试
    "test": "mocha tests/",
    "posttest": "echo '测试完成，覆盖率报告已生成'",
    
    // 构建相关
    "prebuild": "rimraf dist/", // 先清理旧构建文件
    "build": "webpack --mode production",
    "postbuild": "npm run size-report", // 构建后分析包大小
    
    // 自定义脚本（如您的配置）
    "prepackage": "npm run build", // 打包前先构建
    "package": "vsce package",
    
    // 发布相关
    "prepublishOnly": "npm test && npm run build",
    "postpublish": "git push && git push --tags"
  }
}
```

## 常用内置生命周期钩子
| 钩子名称 | 执行时机 | 常见用途 |
|---------|---------|---------|
| `preinstall` | 在安装包依赖之前 | 环境检查、权限设置 |
| `postinstall` | 在安装包依赖之后 | 构建项目、生成配置文件 |
| `prepublishOnly` | 在包发布到 npm 之前 | 运行测试、构建生产版本 |
| `prepare` | 在包打包和发布之前 | 编译源代码、生成类型定义 |
| `prepack` | 在打包 tarball 之前 | 清理临时文件 |
| `postpack` | 在打包 tarball 之后 | 备份、通知 |

---

| 命令                               | 说明              |
| -------------------------------- | --------------- |
| `git stash push -m "message"`    | 保存修改到 stash 栈   |
| `git stash push -u -m "message"` | 保存修改 + 未跟踪文件    |
| `git stash list`                 | 查看 stash 栈      |
| `git stash pop`                  | 恢复最新 stash 并删除  |
| `git stash apply stash@{1}`      | 恢复指定 stash，但不删除 |
| `git stash drop stash@{0}`       | 删除指定 stash      |

