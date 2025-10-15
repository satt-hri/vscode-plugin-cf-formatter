下面给你一份**Peggy.js（Peggy）语法全集速查表**，全部用 Markdown 编好，覆盖语法结构、所有解析表达式类型、标识符与注释、动作与谓词、导入、错误消息命名等，并附最小可跑例子。所列内容以官方文档为准。([peggyjs.org][1])

---

# Peggy.js 语法全集（Markdown 版）

> 适用对象：Peggy v3 系列文档中描述的语法（Peggy 是 PEG.js 的后继）。([peggyjs.org][1])

## 顶层结构 / 规则

| 构造          | 语法                                      | 作用                                                               | 示例                                                                           |
| ----------- | --------------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| 全局初始化（一次执行） | `{{ ... }}`                             | 生成的解析器**加载时**执行（可 `import/require`、定义工具函数）。                      | `{{ function toInt(d){return parseInt(d.join(""),10)} }}` ([peggyjs.org][1]) |
| 每次解析初始化     | `{ ... }`（在规则之前、紧跟在全局初始化之后）             | **每次调用 `parse()` 前**执行，可访问 `input` 与 `options`。                  | `{ if (options.wrap) input = "(" + input + ")" }` ([peggyjs.org][1])         |
| 规则定义        | `ruleName = expression`                 | 定义一个解析规则；第一个规则是默认起始规则。可选分号结尾。                                    | `start = integer` ([peggyjs.org][1])                                         |
| 规则的人类可读名    | `ruleName "readable name" = expression` | 影响报错消息、错误定位策略。                                                   | `integer "simple number" = [0-9]+` ([peggyjs.org][1])                        |
| 规则引用        | 在表达式中直接写 `ruleName`                     | 递归或调用其他规则。                                                       | `start = child; child = "foo"` ([peggyjs.org][1])                            |
| 导入其它语法文件的规则 | 多种 ES 风格写法，置于顶层初始化之前的 special import 段  | 将其它 `.peggy` 文件的规则引入到当前语法中（需使用 CLI 的 `output:"source"` 生成等高级用法）。 | 见下表“导入写法”一览。([peggyjs.org][1])                                               |
| 注释与空白       | `// ...`、`/* ... */`，以及任意空白             | 忽略空白与注释，语法非行导向。                                                  | — ([peggyjs.org][1])                                                         |

### 导入写法一览（进阶用法）

| 写法                                                  | 含义/说明                            |
| --------------------------------------------------- | -------------------------------- |
| `import * as num from "number.js"`                  | 以命名空间方式导入；调用 `num.number`。       |
| `import num from "number.js"`                       | 导入默认规则。                          |
| `import {number, float} "number.js"`                | 按名导入多个规则。                        |
| `import {number as NUM} "number.js"`                | 本地重命名避免冲突。                       |
| `import {"number" as NUM} "number.js"`              | ES6 形式同上。                        |
| `import integer, {float} "number.js"`               | 同时导入默认与具名。                       |
| `import from "number.js"` / `import {} "number.js"` | 只要顶层副作用（初始化）。 ([peggyjs.org][1]) |

---

## 解析表达式（Parsing Expression Types）

> 这些是 Peggy 的**全部**表达式类型；可以递归组合。官方文档逐一给出定义与示例，以下表格汇总其语法、语义与最小例子。([peggyjs.org][1])

### 原子匹配

| 表达式                | 语法                                         | 作用                                                    | 示例（可独立作为规则右侧）                                                            |
| ------------------ | ------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------------------ |
| 字面量（可忽略大小写）        | `"lit"` / `'lit'`，可加 `i`                   | 精确匹配字面量；`i` 忽略大小写；支持 JS 转义（`\u{...}` 等）               | `literal = "foo"`；`literal_i = "foo"i` ([peggyjs.org][1])                |
| 任意字符               | `.`                                        | 匹配**单个** JS 字符（UTF-16 码元）；返回该字符                       | `any = .` ([peggyjs.org][1])                                             |
| 结束断言（EOI）          | `!.`                                       | 匹配输入**结束**（不消耗输入）；常与前项结合验证末尾                          | `end = "f" !.` ([peggyjs.org][1])                                        |
| 字符类（含 Unicode）     | `[... ]`，可加 `i`/`u`，支持 `\p{...}`/`\P{...}` | 匹配集合内单字符；`^` 取反；`u` 表示按 Unicode 码点匹配；包含非 BMP 自动启用 `u` | `cls = [a-z]`；`not_i = [^a-z]i`；`prop = [\\p{ASCII}]` ([peggyjs.org][1]) |
| “非空集”类（Unicode 码点） | `[^]u`                                     | 在 `u` 模式下等价“任意**码点**”，避免匹配孤立代理项                       | `anyCodePoint = [^]u` ([peggyjs.org][1])                                 |
| 规则引用               | `ruleName`                                 | 调用某个规则的表达式                                            | `rule = child; child = "foo"` ([peggyjs.org][1])                         |
| 分组                 | `( expression )`                           | 建立**局部**作用域（影响动作、`@` 抓取的返回值边界）                        | `paren = ("1" { return 2; })+` → 规则返回 `[2,2,...]` ([peggyjs.org][1])     |

### 量词与重复

| 表达式                 | 语法             | 语义                 | 示例                                 |          |     |                  |     |                     |   |                                                                                              |            |           |                     |       |        |                           |                      |
| ------------------- | -------------- | ------------------ | ---------------------------------- | -------- | --- | ---------------- | --- | ------------------- | - | -------------------------------------------------------------------------------------------- | ---------- | --------- | ------------------- | ----- | ------ | ------------------------- | -------------------- |
| 0 次或多次              | `expression *` | 贪婪，返回数组            | `zeros = "a"*` ([peggyjs.org][1])  |          |     |                  |     |                     |   |                                                                                              |            |           |                     |       |        |                           |                      |
| 1 次或多次              | `expression +` | 贪婪，返回数组            | `ones = "a"+` ([peggyjs.org][1])   |          |     |                  |     |                     |   |                                                                                              |            |           |                     |       |        |                           |                      |
| 0 次或 1 次            | `expression ?` | 成功返回结果，失败返回 `null` | `maybeA = "a"?` ([peggyjs.org][1]) |          |     |                  |     |                     |   |                                                                                              |            |           |                     |       |        |                           |                      |
| **区间/定次重复 + 可选分隔符** | `expression    | count              | `/`                                | min..max | `/` | count, delimiter | `/` | min..max, delimiter | ` | Peggy 专有语法：精确或区间重复，可用分隔符；`..` 两端可省略（与 `*`/`+`/`?` 等价）；`count`/`min`/`max` 可为**整数、前面标签名或代码块** | `rep = "a" | 2..3, "," | `；`n = count:n1 "a" | count | `；`"a" | { return options.count; } | ` ([peggyjs.org][1]) |

### 断言（前瞻）与谓词

| 表达式   | 语法                | 语义                              | 示例                                                                 |
| ----- | ----------------- | ------------------------------- | ------------------------------------------------------------------ |
| 正向断言  | `& expression`    | 不消耗输入；成功返回 `undefined`，否则失败     | `pos = "a" &"b"`（匹配 `"ab"`） ([peggyjs.org][1])                     |
| 负向断言  | `! expression`    | 不消耗输入；表达式**不**成功则成功             | `neg = "a" !"b"`（匹配 `"a"`、`"ac"`） ([peggyjs.org][1])               |
| 语义正谓词 | `& { predicate }` | 执行 JS 代码返回布尔；`true` 视为成功（不消耗输入） | `@num:$[0-9]+ &{ return parseInt(num,10)<100 }` ([peggyjs.org][1]) |
| 语义负谓词 | `! { predicate }` | 返回 `false` 视为成功（不消耗输入）          | `@num:$[0-9]+ !{ return parseInt(num,10)<100 }` ([peggyjs.org][1]) |

### 取文本 / 标记 / “掐出值”返回

| 表达式             | 语法                                    | 语义                                                    | 示例                                                                                                          |
| --------------- | ------------------------------------- | ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| 取匹配文本           | `$ expression`                        | 返回**匹配到的原串**而非结构化结果                                   | `dollar = $"a"+` → `"a"`/`"aa"` ([peggyjs.org][1])                                                          |
| 标记（命名子匹配）       | `label : expression`                  | 将子匹配结果存入同名局部变量（供动作/谓词使用）                              | `label = x:"bar"i { return {x}; }` ([peggyjs.org][1])                                                       |
| **掐出（pluck）返回** | `@ expression` 或 `@label: expression` | **直接将此子表达式的值作为规则返回值**；规则**不可**再带动作；可多次使用则返回数组；常配合分组使用 | `pluck1 = @$"a"+ " " @$"b"+`；`pluck2 = @$"a"+ " " @two:$"b"+ &{ return two.length < 3 }` ([peggyjs.org][1]) |

### 组合

| 表达式        | 语法                   | 语义                         | 示例                                                   |
| ---------- | -------------------- | -------------------------- | ---------------------------------------------------- |
| 序列         | `e1 e2 ... en`       | 依次匹配，返回各自结果数组              | `seq = "a" "b" "c"` ([peggyjs.org][1])               |
| 选择（有序备选）   | `e1 / e2 / ... / en` | 自左向右尝试，首个成功为准              | `alt = "a" / "b" / "c"` ([peggyjs.org][1])           |
| 动作（Action） | `expression { js }`  | 前式成功则执行 JS，`return` 的值作为结果 | `" "+ "a" { return location(); }` ([peggyjs.org][1]) |

---

## 动作与谓词的执行环境

> 在动作 `{ ... }` 与语义谓词 `&{...}`/`!{...}` 内可用以下工具与变量（**全局初始化**中声明的变量/函数也可用；**但全局初始化自身不能**用这些运行时函数）。([peggyjs.org][1])

| 名称                                                     | 说明                                                     |
| ------------------------------------------------------ | ------------------------------------------------------ |
| `input`                                                | 传入的原始字符串。                                              |
| `options`                                              | `parse(input, options)` 里的对象（可自定义传参）。                  |
| `location()` / `range()` / `offset()`                  | 位置信息（带行列；仅偏移；或起始偏移）。                                   |
| `text()`                                               | 返回本规则当前匹配的源文本（谓词中为空串）；若只是要返回文本，优先用 `$`。                |
| `error(message, where?)` / `expected(message, where?)` | 主动抛错并带定位（`where` 省略则取 `location()`）。                   |
| **标签可见性规则**                                            | 仅在**已匹配**的标记之后可见；子表达式内的标记只在该子表达式内有效。([peggyjs.org][1]) |

---

## 标识符与命名规则

| 项      | 规定                                                                                                   | 示例                                                                             |
| ------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| 允许的标识符 | 规则名、标签名、引用名必须是**Peggy 标识符**，且同时满足目标语言（默认 JS）的限制；仅允许 **BMP** 码位；不能以 `$` 开头；标签还必须是合法函数形参名（不可用 JS 保留字）。 | ✅ `Foo`、`Bär`、`_foo`、`foo$bar`；❌ `const`、`$Bar`、`foo bar` 等。([peggyjs.org][1]) |

---

## 错误消息与“人类可读名”

* 给规则加 `"readable name"` 会改变错误提示文本及其定位偏好（倾向将命名规则整体视作原子）。示例见下：([peggyjs.org][1])

```pegjs
integer "simple number" = [0-9]+
-- 当输入为 a --
-- 提示：Expected simple number but "a" found. --
```

---

## 最小可运行示例（综合）

```pegjs
{{
  function toInt(d) { return parseInt(d.join(""), 10); }
}}

{
  if (options.multiplier) input = `(${input})*(${options.multiplier})`;
}

start           = expr !.                      // 必须到达输入末尾
expr "additive" = left:term "+" right:expr
                  { return left + right; }
                / term
term            = left:primary "*" right:term
                  { return left * right; }
                / primary
primary         = integer
                / "(" @inner:expr ")"          // 用 @ 直接“掐出”返回 inner 的值
integer "int"   = digits:$[0-9]+ &{ return +digits < 1000 }  // 语义谓词
                  { return toInt(digits); }
```

调用：

```js
import parser from "./arith.js";
parser.parse("2*(3+4)");                     // 14
parser.parse("14", { multiplier: 2 });       // 28（因 per-parse 初始化改写了 input）
```

（示例与语法要点源自官方“Grammar Syntax and Semantics / Parsing Expression Types / Action Execution Environment”等章节整理。）([peggyjs.org][1])

---

## 速查小贴士

* **结束校验**：习惯在起始规则末尾加 `!.`，保证完全消费输入。([peggyjs.org][1])
* **取文本更易读**：若只需要原文片段，优先用 `$` 而不是动作里 `text()`。([peggyjs.org][1])
* **列表解析**：优先使用 Peggy 的**重复语法带分隔符**：`item |.., delimiter|`，更高效也更清晰。([peggyjs.org][1])

---

### 参考

* 官方文档主页、**Grammar Syntax and Semantics / Parsing Expression Types / Action Execution Environment / Identifiers / Error Messages** 等章节。([peggyjs.org][1])

> 如果你想要，我也可以把上面这份**转成独立的 `.md` 文件**或**加上更多例子（例如 JSON、CSV、算术表达式等）**。

[1]: https://peggyjs.org/documentation.html "Documentation » Peggy – Parser Generator for JavaScript"
