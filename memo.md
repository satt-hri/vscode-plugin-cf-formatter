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