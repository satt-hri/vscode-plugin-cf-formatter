# CFML Auto Formatter
## 日本語

VS Code 用 **CFML コード自動整形拡張機能**。  
この拡張機能はインデントの自動整形に特化しており、コードスタイルを変更しません。

### 機能
- **CFML (.cfc)** コードの自動インデント整形（安定して動作）
- `.cfm` ファイルも試せますが、対応はまだ不十分です
- 元のコードスタイルを保持
- 手動実行や保存時自動整形に対応

### 使い方
1. 拡張機能をインストール
2. CFML ファイルを開く（推奨: `.cfc`）
3. ショートカット `Shift+Alt+M` または右クリック → `Format CFML (satt)` **ドキュメントのフォーマット** を使用

### 注意点
- `.cfc` ファイルのインデント整形は安定して動作
- `.cfm` ファイルは整形が不正確な場合あり、今後改善予定

### フォーマット前後の例
<div align="center">
  <img src="./images/2025-08-22_17h45_38.gif" alt="插件演示">
</div>

## English

A VS Code extension for **automatic formatting of CFML code**.  
This extension focuses on indentation formatting and does not change your coding style.

### Features
- Automatically formats **CFML (.cfc)** code with good results
- `.cfm` files are also supported, but formatting may not be perfect
- Keeps the original code style unchanged
- Supports manual trigger and format-on-save

### Usage
1. Install the extension
2. Open a CFML file (recommended: `.cfc`)
3. Use the shortcut `Shift+Alt+M` or right-click → `Format CFML (satt)` **Format Document**

### Notes
- Indentation formatting is fully supported for `.cfc` files
- `.cfm` files may have inaccurate formatting; improvements will come in future versions

---

## 中文

一个用于 **CFML 代码自动格式化** 的 VS Code 插件。  
本插件专注于缩进格式化功能，不会改动你的代码风格。

### 功能特点
- 自动缩进 **CFML (.cfc)** 代码，效果较好
- `.cfm` 文件也可尝试，但目前支持还不够完善
- 保持原有代码风格（不会随意改换）
- 支持手动触发和保存时自动触发

### 使用方法
1. 安装插件
2. 打开 CFML 文件（推荐 `.cfc`）
3. 使用快捷键 `Shift+Alt+M` 或右键选择`Format CFML (satt)` **格式化文档**

### 注意事项
- 对 `.cfc` 文件的缩进格式化支持较完整
- `.cfm` 文件可能出现缩进不准确的情况，后续版本将逐步改进
