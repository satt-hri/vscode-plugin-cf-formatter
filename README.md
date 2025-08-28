# 🐧🎈ᓚᘏᗢ&nbsp;&nbsp;&nbsp;&nbsp;CFML Auto Formatter 

## 👘日本語

VS Code 用 **CFML コード自動整形拡張機能**。  
この拡張機能は **インデント整形に特化** しており、余計なコードスタイルの変更は行いません。

---

###  機能
- **CFML (.cfc)** コードの自動インデント整形（安定動作）
- `.cfm` ファイルも試せますが、対応は不十分
- 元のコードスタイルを保持
- 手動実行 & 保存時自動整形に対応

---

###  使い方
1. 拡張機能をインストール
2. CFML ファイルを開く（推奨: `.cfc`）
3. ショートカット **`Shift + Alt + M`** または右クリック → **`Format CFML (satt)` ドキュメントのフォーマット**

---

###  注意点
- `.cfc` ファイルの整形は安定動作  
- `.cfm` ファイルは整形が乱れる場合あり → 今後改善予定  

---

###  フォーマット前後の例
<div align="center">
  <img src="./images/2025-08-22_17h57_00.gif" alt="插件演示">
</div>

---

### ⚙️ CFML フォーマッタ デフォルト設定

<style>
table {
  font-size: 10px; /* 字体更小 */
}
</style>

| 設定項目 | デフォルト値 | 型 | 説明 |
| -------- | ------------ | ---- | ---- |
| `hri.cfml.formatter.indentWithTabs` | `true` | boolean | インデントにスペースではなくタブを使用する。 |
| `hri.cfml.formatter.indentSize` | `4` | number | スペースでインデントする場合のスペース数（1–10）。 |
| `hri.cfml.formatter.indentChar` | `" "` | string | インデント文字：スペース `" "` または `\t`。`indentWithTabs` で上書きされる。 |
| `hri.cfml.formatter.wrapLineLength` | `0` | number | この文字数を超えると改行。`0` は制限なし。 |
| `hri.cfml.formatter.maxPreserveNewlines` | `2` | number | 連続して保持する改行の最大数（0–10）。 |
| `hri.cfml.formatter.preserveNewlines` | `true` | boolean | 既存の改行を保持するかどうか。 |
| `hri.cfml.formatter.keepArrayIndentation` | `false` | boolean | 配列の元のインデントを保持するかどうか。 |
| `hri.cfml.formatter.braceStyle` | `"collapse"` | string | 波括弧スタイル：`collapse` / `expand` / `end-expand` / `none`。 |
| `hri.cfml.formatter.breakChainedMethods` | `false` | boolean | メソッドチェーンを複数行に分割するかどうか。 |
| `hri.cfml.formatter.spaceBeforeConditional` | `true` | boolean | 条件文（if, while, for）の前にスペースを入れるか。 |
| `hri.cfml.formatter.endWithNewline` | `false` | boolean | ファイル末尾に改行を追加するかどうか。 |

💡 **設定変更方法**  
VSCode で **`Ctrl + ,`** を押し、検索欄に **「Format CFML (satt)」** と入力すると変更可能。変更があったら、再起動みたいな操作でウィンドウをリロードするのを忘れないでね

---

## 🏈English

A VS Code extension for **automatic formatting of CFML code**.  
This extension focuses only on indentation formatting and does not change your coding style.

---

###  Features
- Automatically formats **CFML (.cfc)** code
- `.cfm` files are also supported (experimental)
- Keeps original code style
- Supports both manual trigger & format-on-save

---

###  Usage
1. Install the extension  
2. Open a CFML file (recommended: `.cfc`)  
3. Use **`Shift+Alt+M`** or right-click → **`Format CFML (satt)` → Format Document**  

---

###  Notes
- `.cfc` files → fully supported  
- `.cfm` files → formatting may be unstable (will improve in future)  

---

## 🐼中文

一个用于 **CFML 代码自动格式化** 的 VS Code 插件。  
本插件专注于 **缩进格式化**，不会修改代码风格。

---

### 🔧 功能特点
- 自动缩进 **CFML (.cfc)** 代码
- `.cfm` 文件也支持，但格式化可能不够完善
- 保持原有代码风格
- 支持手动触发 & 保存时自动格式化

---

###  使用方法
1. 安装插件  
2. 打开 CFML 文件（推荐 `.cfc`）  
3. 使用快捷键 **`Shift+Alt+M`** 或右键 → **`Format CFML (satt)` → 格式化文档**  

---

###  注意事项
- `.cfc` 文件格式化支持稳定  
- `.cfm` 文件缩进可能不准确，将在后续优化  
