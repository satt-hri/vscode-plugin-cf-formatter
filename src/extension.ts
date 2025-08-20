import * as vscode from "vscode";
import { messages, Lang } from "./config";

export function activate(context: vscode.ExtensionContext) {
	//console.log("CFML Auto Formatter 插件已激活");

	// 检查注册的语言
	//console.log("支持的语言:", vscode.languages.getLanguages());
	const lang = vscode.env.language.toLowerCase() as Lang;

	const provider: vscode.DocumentFormattingEditProvider = {
		provideDocumentFormattingEdits(
			document: vscode.TextDocument,
			options: vscode.FormattingOptions,
			token: vscode.CancellationToken
		): vscode.TextEdit[] {
			// console.log("格式化器被调用！");
			// console.log("文档语言ID:", document.languageId);
			// console.log("文档行数:", document.lineCount);
			// console.log("文档文件名:", document.fileName);
			// console.log("格式化选项:", options);
			const edits: vscode.TextEdit[] = [];
			let indentLevel = 0;
			let inCfscript = false;
			let inCfquery = false;
			let inString = false;
			let stringChar = "";
			let inMultiLineComment = false; // 新增：跟踪多行注释状态

			// SQL CASE WHEN 结构跟踪
			let sqlCaseStack: number[] = []; // 跟踪CASE语句的嵌套层级
			let sqlSubqueryStack: number[] = []; // 跟踪子查询的嵌套层级

			// 使用格式化选项中的缩进设置
			const indentSize = options.tabSize || 2;
			const useSpaces = false; // 強制使用 tab 縮進

			// 使用栈来跟踪嵌套结构
			const tagStack: string[] = []; // 跟踪未闭合的标签
			const bracketStack: string[] = []; // 在 CFScript 中跟踪 {} 嵌套

			// 扩展的标签定义
			const blockTags = {
				opening: [
					"cffunction",
					"cfif",
					"cfloop",
					"cfquery",
					"cftry",
					"cfcatch",
					"cfscript",
					"cfcomponent",
					"cfoutput",
					"cfswitch",
					"cfcase",
					"cfsavecontent",
					"cfthread",
					"cflock",
					"cftransaction",
					"cfform",
					"cftable",
					"cfselect",
					"div",
					"span",
					"table",
					"tr",
					"td",
				],
				closing: [
					"cffunction",
					"cfif",
					"cfloop",
					"cfquery",
					"cftry",
					"cfcatch",
					"cfcomponent",
					"cfoutput",
					"cfswitch",
					"cfcase",
					"cfsavecontent",
					"cfthread",
					"cflock",
					"cftransaction",
					"cfform",
					"cftable",
					"cfselect",
					"div",
					"span",
					"table",
					"tr",
					"td",
				],
				elselike: ["cfelse", "cfelseif", "cfdefaultcase"],
				selfClosing: [
					"cfreturn",
					"cfbreak",
					"cfcontinue",
					"cfthrow",
					"cfinclude",
					"cfmodule",
					"cfinvoke",
					"cfparam",
					"cfheader",
					"cfcookie",
					"cflocation",
					"cfmail",
					"cffile",
					"cfdirectory",
					"cfhttp",
					"cfzip",
					"cfimage",
					"cfdocument",
					"cfpdf",
				],
				// 新增：需要特殊處理的標籤
				functionParam: ["cfargument"], // 函数参数标签
				functionContent: ["cfset"], // 函数内容标签
			};

			const sqlKeywords = [
				"SELECT",
				"FROM",
				"WHERE",
				"AND",
				"OR",
				"INNER JOIN",
				"LEFT JOIN",
				"RIGHT JOIN",
				"FULL JOIN",
				"ORDER BY",
				"GROUP BY",
				"HAVING",
				"INSERT",
				"UPDATE",
				"DELETE",
				"VALUES",
				"SET",
				"INTO",
				"UNION",
				"UNION ALL",
				"CASE",
				"WHEN",
				"THEN",
				"ELSE",
				"END",
			];

			// 检查是否是文件开头的注释（在任何实际代码之前）
			function isFileHeaderComment(lineIndex: number): boolean {
				// 检查从第一行到当前行之间是否只有注释或空行
				for (let j = 0; j < lineIndex; j++) {
					const previousLine = document.lineAt(j).text.trim();
					if (previousLine === "") continue; // 跳过空行

					// 如果遇到非注释内容，说明不是文件头注释
					if (!inMultiLineComment) {
						//&& !previousLine.startsWith("<!---") && !previousLine.endsWith("--->") 這個條件是很奇怪的。
						// 應該是在這之前 如果發現有了---> 説明已經處理過了。
						if (previousLine.endsWith("--->")) {
							return false;
						}
					}
				}
				return true;
			}

			// 检查多行注释状态（仅对文件头注释）
			function updateCommentState(text: string, lineIndex: number): void {
				// 只处理文件开头的注释
				if (!isFileHeaderComment(lineIndex)) {
					return;
				}

				// 检查注释开始
				if (!inMultiLineComment && text.includes("<!---")) {
					inMultiLineComment = true;
				}

				// 检查注释结束
				if (inMultiLineComment && text.includes("--->")) {
					inMultiLineComment = false;
				}
			}

			// 格式化注释内容以实现对齐（仅文件头注释）
			function formatCommentLine(text: string, lineIndex: number): string {
				// 只格式化文件开头的注释
				if (!isFileHeaderComment(lineIndex)) {
					return text; // 方法内注释保持原样
				}

				const trimmed = text.trim();
				const indentChar = useSpaces ? " " : "\t";
				const indentUnit = useSpaces ? indentSize : 1;

				// 注释开始行：保持0缩进
				if (trimmed.startsWith("<!---")) {
					return trimmed;
				}

				// 注释结束行：保持0缩进
				if (trimmed.endsWith("--->")) {
					return trimmed;
				}

				// 注释内容行的格式化
				if (inMultiLineComment && trimmed !== "") {
					// 检查是否是标准的字段行（Name, Author, Created等）
					const fieldMatch = trimmed.match(/^(Name|Author|Created|Last Updated|History|Purpose)\s*:\s*(.*)$/);
					//　其他的内容的話 用這個正規表現。const fieldMatch = trimmed.match(/^([A-Z][A-Za-z\s]*?)\s*:\s*(.*)$/);
					if (fieldMatch) {
						const fieldName = fieldMatch[1];
						const fieldValue = fieldMatch[2];
						// 使用tab对齐，字段名后跟固定格式
						return indentChar.repeat(1 * indentUnit) + fieldName.padEnd(12) + " : " + fieldValue;
					}

					// 检查是否是History的续行（以日期开头）
					const historyMatch = trimmed.match(/^(\d{4}\/\d{2}\/\d{2})\s+(.*)$/);
					if (historyMatch) {
						const date = historyMatch[1];
						const content = historyMatch[2];
						// History续行：对齐到History字段的值位置
						return indentChar.repeat(1 * indentUnit) + "".padEnd(12) + "   " + date + " " + content;
					}

					// 检查是否是Author的续行（不以日期开头但可能是作者名）
					if (trimmed && !trimmed.includes(":") && !trimmed.match(/^\d{4}\/\d{2}\/\d{2}/)) {
						// 可能是Author的续行或其他字段的续行
						// 检查前一行是否是Author
						if (lineIndex > 0) {
							const prevLine = document.lineAt(lineIndex - 1).text.trim();
							if (prevLine.includes("Author") || prevLine.match(/^\s+\w+/)) {
								// 这可能是Author的续行，对齐到Author值的位置
								return indentChar.repeat(1 * indentUnit) + "".padEnd(12) + "   " + trimmed;
							}
						}
					}

					// 普通注释内容行
					return indentChar.repeat(1 * indentUnit) + trimmed;
				}

				return text;
			}

			// 解析标签名
			function parseTagName(line: string): { tagName: string; isClosing: boolean; isSelfClosing: boolean } {
				const trimmed = line.trim();

				// 处理结束标签
				if (trimmed.startsWith("</")) {
					const match = trimmed.match(/<\/([^>\s]+)/);
					return {
						tagName: match ? match[1].toLowerCase() : "",
						isClosing: true,
						isSelfClosing: false,
					};
				}

				// 处理开始标签
				if (trimmed.startsWith("<")) {
					const match = trimmed.match(/<([^>\s]+)/);
					const tagName = match ? match[1].toLowerCase() : "";
					const isSelfClosing =
						trimmed.endsWith("/>") ||
						blockTags.selfClosing.includes(tagName) ||
						blockTags.functionParam.includes(tagName) ||
						blockTags.functionContent.includes(tagName) ||
						(tagName.startsWith("cf") &&
							(trimmed.includes(" />") ||
								(!trimmed.includes(">") && !blockTags.opening.includes(tagName))));

					return {
						tagName,
						isClosing: false,
						isSelfClosing,
					};
				}

				return { tagName: "", isClosing: false, isSelfClosing: false };
			}

			// 检查字符串状态
			function updateStringState(text: string) {
				for (let i = 0; i < text.length; i++) {
					const char = text[i];

					if (!inString) {
						if (char === '"' || char === "'") {
							inString = true;
							stringChar = char;
						}
					} else {
						if (char === stringChar && text[i - 1] !== "\\") {
							inString = false;
							stringChar = "";
						}
					}
				}
			}

			// 处理cfscript内的大括号
			function processCfscriptBrackets(text: string): number {
				if (!inCfscript || inString) return 0;

				let bracketChange = 0;
				updateStringState(text);

				for (let i = 0; i < text.length; i++) {
					if (!inString) {
						const char = text[i];
						if (char === "{") {
							bracketStack.push("{");
							bracketChange++;
						} else if (char === "}") {
							if (bracketStack.length > 0 && bracketStack[bracketStack.length - 1] === "{") {
								bracketStack.pop();
								bracketChange--;
							}
						}
					}
				}

				return bracketChange;
			}

			// 改进的SQL缩进处理
			function getSqlIndent(text: string, lineIndex: number): number {
				if (!inCfquery) return 0;

				const originalText = text;
				const upperText = text.toUpperCase().trim();
				//let baseIndent =  0; // SQL基础缩进
				let baseIndent =  sqlSubqueryStack.length; // SQL基础缩进

				// 检查是否是SQL注释行
				if (originalText.trim().startsWith("<!---") || originalText.trim().endsWith("--->")) {
					return baseIndent; // 注释缩进与字段对齐
				}

				// 子查询的左括号 - 与FROM对齐
				if (upperText.includes("(") && !upperText.includes(")")) {
					sqlSubqueryStack.push(baseIndent);
					return baseIndent + 1;
				}
				if (upperText.includes(")") && !upperText.includes("(")) {
					sqlSubqueryStack.pop();
					return baseIndent ;
				}

				// 子查询的右括号和别名 - 与FROM对齐
				if (upperText === ") AS D" || upperText.startsWith(") AS ") || upperText === ")") {
					sqlSubqueryStack.pop();
					return baseIndent + 1;
				}

				// 处理CASE WHEN ELSE END结构
				const caseDepth = sqlCaseStack.length;

				// CASE语句开始 - 与字段列表对齐
				if (upperText === "CASE" || upperText.startsWith(",CASE")) {
					const currentLevel = baseIndent + 2; // 与字段对齐
					sqlCaseStack.push(currentLevel);
					return currentLevel;
				}

				// WHEN 和 ELSE 与 CASE 对齐
				if (upperText.startsWith("WHEN ") || upperText === "ELSE") {
					if (caseDepth > 0) {
						return sqlCaseStack[sqlCaseStack.length - 1] + 1; // 比CASE多缩进1层
					}
					return baseIndent + 3;
				}

				// THEN 后面的值在同一行，但如果单独成行则缩进
				if (upperText.startsWith("THEN ") || (upperText.startsWith("ELSE ") && upperText !== "ELSE")) {
					// 这些通常不会单独成行，但如果有则与WHEN对齐
					if (caseDepth > 0) {
						return sqlCaseStack[sqlCaseStack.length - 1] + 1;
					}
					return baseIndent + 3;
				}

				// END语句 - 与CASE对齐
				if (upperText === "END" || upperText.startsWith("END ")) {
					if (sqlCaseStack.length > 0) {
						return sqlCaseStack.pop() || baseIndent;
					}
					return baseIndent + 2;
				}

				// 在CASE结构内的数值
				if (caseDepth > 0) {
					// 检查是否是纯数值或简单值
					if (/^\d+$/.test(upperText) || upperText === "''" || upperText.match(/^'.*'$/)) {
						return sqlCaseStack[sqlCaseStack.length - 1] + 1;
					}
				}

				// 主要SQL关键字与cfquery标签对齐
				const mainKeywords = ["SELECT", "INSERT", "UPDATE", "DELETE", "WITH"];
				if (mainKeywords.some((keyword) => upperText.startsWith(keyword))) {
					// baseIndent + 1; // SELECT缩进  20250819 這個地方有點奇怪。
					return baseIndent;
				}

				// FROM子句
				if (upperText.startsWith("FROM")) {
					return baseIndent;
				}

				// WHERE子句
				if (upperText.startsWith("WHERE")) {
					return baseIndent;
				}

				// ORDER BY等子句
				const subKeywords = ["ORDER BY", "GROUP BY", "HAVING", "UNION"];
				if (subKeywords.some((keyword) => upperText.startsWith(keyword))) {
					return baseIndent;
				}

				// JOIN语句
				if (
					upperText.includes("JOIN") &&
					(upperText.startsWith("INNER ") ||
						upperText.startsWith("LEFT ") ||
						upperText.startsWith("RIGHT ") ||
						upperText.startsWith("FULL ") ||
						upperText.startsWith("CROSS ") ||
						upperText.startsWith("JOIN"))
				) {
					return baseIndent;
				}

				// ON子句（JOIN条件）
				if (upperText.startsWith("ON(") || upperText.startsWith("ON ")) {
					return baseIndent + 1;
				}

				// AND/OR条件
				if (upperText.startsWith("AND ") || upperText.startsWith("OR ")) {
					return baseIndent + 1;
				}

				// 字段列表 - 所有字段（包括第一个）都缩进到相同层级
				if (upperText.startsWith(",")) {
					return baseIndent + 1;
				}

				// 检查是否是第一个字段（紧接在SELECT后面）
				if (lineIndex > 0) {
					const prevLine = document
						.lineAt(lineIndex - 1)
						.text.toUpperCase()
						.trim();
					if (prevLine === "SELECT") {
						// baseIndent + 2; // 第一个字段也缩进
						return baseIndent + 1; // 20250819 這個地方有點奇怪。
					}
				}

				// 表名等其他内容
				return baseIndent + 1;
			}

			// 新增：判斷是否在 cffunction 內部
			function isInCffunction(): boolean {
				return tagStack.includes("cffunction");
			}

			// 新增：獲取特殊標籤的額外縮進
			function getSpecialTagIndent(tagName: string): number {
				if (blockTags.functionParam.includes(tagName)) {
					// cfargument 應該與 cffunction 同級縮進 (實際上是 cffunction 的參數)
					return 0;
				} else if (blockTags.functionContent.includes(tagName)) {
					// cfset 應該作為 cffunction 的內容，額外縮進一層
					return isInCffunction() && false ? 1 : 0; // 緊急修正：暫時不處理多參數的 cfset
				}
				return 0;
			}

			// 新增：檢查是否是多參數函數調用的 cfset
			function isCfsetWithMultipleParams(text: string): boolean {
				console.log("檢查 cfset:", text);

				// 檢查是否是 cfset 且包含函數調用
				if (!text.toLowerCase().includes("<cfset ")) {
					console.log("不包含 <cfset");
					return false;
				}

				// 提取 cfset 內容部分
				const cfsetMatch = text.match(/<cfset\s+(.+?)(?:\s*\/?>|$)/i);
				if (!cfsetMatch) {
					console.log("cfset 正則匹配失敗");
					return false;
				}

				const content = cfsetMatch[1];
				console.log("cfset 內容:", content);

				// 檢查是否包含函數調用（有括號）
				if (!content.includes("(")) {
					console.log("不包含函數調用");
					return false;
				}

				// 計算參數數量（簡單計算逗號數量）
				const commaCount = (content.match(/,/g) || []).length;
				console.log("逗號數量:", commaCount);

				// 如果有2個或以上的逗號，表示有2個以上的參數
				const result = commaCount >= 2 && false; // 緊急修正：暫時不處理多參數的 cfset
				console.log("是否需要多行格式化:", result);
				return result;
			}

			// 新增：格式化多參數的 cfset
			function formatCfsetMultiParams(text: string, baseIndent: number): string[] {
				console.log("開始格式化多參數 cfset:", text);
				console.log("基礎縮進:", baseIndent);

				const cfsetMatch = text.match(/^(\s*<cfset\s+)(.+?)(\s*\/?>?\s*)$/i);
				if (!cfsetMatch) {
					console.log("cfset 格式化正則匹配失敗");
					return [text];
				}

				const prefix = cfsetMatch[1].trim();
				const content = cfsetMatch[2];
				const suffix = cfsetMatch[3].trim();

				console.log("prefix:", prefix);
				console.log("content:", content);
				console.log("suffix:", suffix);

				// 找到函數調用部分
				const funcMatch = content.match(/^(.+?)\.([^(]+)\s*\(\s*(.+?)\s*\)\s*(.*)$/);
				if (!funcMatch) {
					console.log("函數調用正則匹配失敗");
					return [text];
				}

				const objName = funcMatch[1];
				const funcName = funcMatch[2];
				const params = funcMatch[3];
				const afterFunc = funcMatch[4];

				console.log("objName:", objName);
				console.log("funcName:", funcName);
				console.log("params:", params);
				console.log("afterFunc:", afterFunc);

				// 分割參數
				const paramList = params.split(",").map((p) => p.trim());
				console.log("參數列表:", paramList);

				// 如果參數少於2個，保持原格式
				if (paramList.length < 2) {
					console.log("參數少於2個，保持原格式");
					return [text];
				}

				const indentChar = useSpaces ? " " : "\t";
				const indentUnit = useSpaces ? indentSize : 1;
				const currentIndent = indentChar.repeat(baseIndent * indentUnit);
				const paramIndent = indentChar.repeat((baseIndent + 1) * indentUnit);

				const lines: string[] = [];

				// 第一行：cfset + 對象.函數名(
				lines.push(currentIndent + `${prefix}${objName}.${funcName}(`);

				// 參數行
				paramList.forEach((param, index) => {
					const isLast = index === paramList.length - 1;
					const paramLine = isLast ? param : param + ",";
					lines.push(paramIndent + paramLine);
				});

				// 最後一行：) + suffix
				const lastLine = currentIndent + `)${afterFunc ? " " + afterFunc : ""}${suffix ? " " + suffix : " />"}`;
				lines.push(lastLine);

				console.log("格式化結果:", lines);
				return lines;
			}

			for (let i = 0; i < document.lineCount; i++) {
				const line = document.lineAt(i);
				let text = line.text.trim();

				// 更新注释状态（仅文件头注释）
				updateCommentState(line.text, i);

				// 跳过空行
				if (text.length === 0) {
					edits.push(vscode.TextEdit.replace(line.range, ""));
					continue;
				}

				// 处理多行注释（仅文件头注释）
				if (
					(inMultiLineComment || text.startsWith("<!---") || text.endsWith("--->")) &&
					isFileHeaderComment(i)
				) {
					const formattedLine = formatCommentLine(text, i);
					edits.push(vscode.TextEdit.replace(line.range, formattedLine));
					continue; // 跳过其他处理，直接处理下一行
				}

				const { tagName, isClosing, isSelfClosing } = parseTagName(text);
				let currentIndentLevel = indentLevel;

				// 檢查是否是多參數的 cfset，需要特殊處理
				if (tagName === "cfset" && isCfsetWithMultipleParams(text)) {
					// 計算基礎縮進
					let bracketIndent = 0;
					if (inCfscript) {
						if (text.includes("}") && !text.includes("{")) {
							bracketIndent = Math.max(bracketStack.length - 1, 0);
						} else {
							bracketIndent = bracketStack.length;
						}
					}

					// cfset 不會在 cfquery 內，所以 sqlIndent 為 0
					let sqlIndent = 0;

					let specialIndent = getSpecialTagIndent(tagName);
					let baseIndentLevel = currentIndentLevel + bracketIndent + sqlIndent + specialIndent;

					// 格式化多行 cfset
					const formattedLines = formatCfsetMultiParams(text, baseIndentLevel);

					// 為每一行創建編輯
					if (formattedLines.length > 1) {
						// 替換原行為第一行
						edits.push(vscode.TextEdit.replace(line.range, formattedLines[0]));

						// 在後面插入其他行
						for (let j = 1; j < formattedLines.length; j++) {
							const insertPosition = new vscode.Position(i + j, 0);
							edits.push(vscode.TextEdit.insert(insertPosition, formattedLines[j] + "\n"));
						}

						// 跳過後續的常規處理
						continue;
					}
				}

				// 处理结束标签
				if (isClosing) {
					// 特殊处理cfscript和cfquery
					if (tagName === "cfscript") {
						inCfscript = false;
						bracketStack.length = 0;
					} else if (tagName === "cfquery") {
						inCfquery = false;
						// 清空SQL CASE栈
						sqlCaseStack.length = 0;
						sqlSubqueryStack.length = 0;
					}

					// 弹出标签栈并调整缩进
					if (tagStack.length > 0) {
						const lastTag = tagStack.pop();
						indentLevel = Math.max(indentLevel - 1, 0);
						currentIndentLevel = indentLevel;
					}
				}
				// 处理else类标签
				else if (blockTags.elselike.includes(tagName)) {
					currentIndentLevel = Math.max(indentLevel - 1, 0);
				}

				// 处理cfscript内的大括号缩进
				let bracketIndent = 0;
				if (inCfscript) {
					// 如果这行有闭合大括号，先减少缩进
					if (text.includes("}") && !text.includes("{")) {
						bracketIndent = Math.max(bracketStack.length - 1, 0);
					} else {
						bracketIndent = bracketStack.length;
					}
				}

				// 处理SQL缩进
				let sqlIndent = 0;
				if (inCfquery && tagName !== "cfquery") {
					sqlIndent = getSqlIndent(text, i);
				}

				// 新增：处理特殊标签的缩进
				let specialIndent = 0;
				if (isSelfClosing) {
					specialIndent = getSpecialTagIndent(tagName);
				}

				// 计算最终缩进
				const totalIndent = currentIndentLevel + bracketIndent + sqlIndent + specialIndent;
				const indentChar = useSpaces ? " " : "\t";
				const indentUnit = useSpaces ? indentSize : 1;
				const indent = indentChar.repeat(totalIndent * indentUnit);

				// 应用格式化
				edits.push(vscode.TextEdit.replace(line.range, indent + text));

				// 处理cfscript大括号变化
				if (inCfscript) {
					processCfscriptBrackets(text);
				}

				// 处理开始标签
				if (!isClosing && !isSelfClosing && blockTags.opening.includes(tagName)) {
					// 特殊处理cfscript和cfquery
					if (tagName === "cfscript") {
						inCfscript = true;
					} else if (tagName === "cfquery") {
						inCfquery = true;
						// 重置SQL CASE栈
						sqlCaseStack.length = 0;
					}

					tagStack.push(tagName);
					indentLevel++;
				}

				// 处理else类标签后的缩进恢复
				if (blockTags.elselike.includes(tagName)) {
					// else类标签本身不增加缩进，但后续内容需要缩进
					// 这里不需要特殊处理，因为缩进在下一轮循环中会正确计算
				}
			}

			return edits;
		},
	};

	// 添加调试命令
	const debugCommand = vscode.commands.registerCommand("satt.cfml.debug", () => {
		const editor = vscode.window.activeTextEditor;
		if (editor) {
			console.log("当前文件语言ID:", editor.document.languageId);
			console.log("当前文件路径:", editor.document.fileName);
			const val = messages.langInfo[lang];
			vscode.window.showInformationMessage(
				typeof val === "function" ? val(editor.document.languageId, editor.document.fileName) : val
			);
		}
	});

	// 注册多个可能的语言ID
	const languageIds = ["coldfusion", "cfml", "cfm", "cfc", "plaintext"];

	languageIds.forEach((langId) => {
		const registration = vscode.languages.registerDocumentFormattingEditProvider(langId, provider);
		context.subscriptions.push(registration);
		console.log(`已为语言ID "${langId}" 注册格式化器`);
	});

	context.subscriptions.push(debugCommand);

	const formatCommand = vscode.commands.registerCommand("hri.cfml.formatDocument", async () => {
		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			vscode.window.showErrorMessage(messages.noEditor[lang] as string);
			return;
		}

		console.log("手动格式化命令被调用");
		console.log("文档语言ID1:", editor.document.languageId);

		try {
			// 直接调用我们的格式化器，提供所需的参数y
			const options: vscode.FormattingOptions = {
				tabSize: 4,
				insertSpaces: true,
			};
			const token = new vscode.CancellationTokenSource().token;

			const editsResult = provider.provideDocumentFormattingEdits(editor.document, options, token);

			// 处理可能的Promise返回值
			const edits = await Promise.resolve(editsResult);

			if (edits && edits.length > 0) {
				await editor.edit((editBuilder: vscode.TextEditorEdit) => {
					edits.forEach((edit: vscode.TextEdit) => {
						editBuilder.replace(edit.range, edit.newText);
					});
				});
				vscode.window.showInformationMessage(messages.formatDone[lang] as string);
			} else {
				vscode.window.showInformationMessage(messages.noContent[lang] as string);
			}
		} catch (error) {
			const val = messages.formatError[lang];
			console.error("格式化错误:", error);
			vscode.window.showErrorMessage(typeof val === "function" ? val(error) : val);
		}
	});

	context.subscriptions.push(formatCommand);
}

export function deactivate() {}
