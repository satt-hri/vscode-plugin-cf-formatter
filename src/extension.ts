import * as vscode from "vscode";

export function activate(context: vscode.ExtensionContext) {
	//console.log("CFML Auto Formatter 插件已激活");
	
	// 检查注册的语言
	//console.log("支持的语言:", vscode.languages.getLanguages());

	const provider: vscode.DocumentFormattingEditProvider = {
		provideDocumentFormattingEdits(
			document: vscode.TextDocument,
			options: vscode.FormattingOptions,
			token: vscode.CancellationToken
		): vscode.TextEdit[] {
			// console.log("🚀 格式化器被调用！");
			// console.log("文档语言ID:", document.languageId);
			// console.log("文档行数:", document.lineCount);
			// console.log("文档文件名:", document.fileName);
			// console.log("格式化选项:", options);
			const edits: vscode.TextEdit[] = [];
			let indentLevel = 0;
			let inCfscript = false;
			let inCfquery = false;
			let inString = false;
			let stringChar = '';
			
			// 使用格式化选项中的缩进设置
			const indentSize = options.tabSize || 2;
			const useSpaces = options.insertSpaces !== false;
			
			// 使用栈来跟踪嵌套结构
			const tagStack: string[] = [];
			const bracketStack: string[] = [];

			// 扩展的标签定义
			const blockTags = {
				opening: [
					'cffunction', 'cfif', 'cfloop', 'cfquery', 'cftry', 'cfcatch', 
					'cfscript', 'cfcomponent', 'cfoutput', 'cfswitch', 'cfcase',
					'cfsavecontent', 'cfthread', 'cflock', 'cftransaction',
					'cfform', 'cftable', 'cfselect', 'div', 'span', 'table', 'tr', 'td'
				],
				closing: [
					'cffunction', 'cfif', 'cfloop', 'cfquery', 'cftry', 'cfcatch',
					'cfcomponent', 'cfoutput', 'cfswitch', 'cfcase',
					'cfsavecontent', 'cfthread', 'cflock', 'cftransaction',
					'cfform', 'cftable', 'cfselect', 'div', 'span', 'table', 'tr', 'td'
				],
				elselike: ['cfelse', 'cfelseif', 'cfdefaultcase'],
				selfClosing: [
					'cfset', 'cfreturn', 'cfbreak', 'cfcontinue', 'cfthrow',
					'cfinclude', 'cfmodule', 'cfinvoke', 'cfparam', 'cfheader',
					'cfcookie', 'cflocation', 'cfmail', 'cffile', 'cfdirectory',
					'cfhttp', 'cfzip', 'cfimage', 'cfdocument', 'cfpdf'
				]
			};

			const sqlKeywords = [
				'SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'INNER JOIN', 'LEFT JOIN', 
				'RIGHT JOIN', 'FULL JOIN', 'ORDER BY', 'GROUP BY', 'HAVING',
				'INSERT', 'UPDATE', 'DELETE', 'VALUES', 'SET', 'INTO',
				'UNION', 'UNION ALL', 'CASE', 'WHEN', 'THEN', 'ELSE', 'END'
			];

			// 解析标签名
			function parseTagName(line: string): { tagName: string; isClosing: boolean; isSelfClosing: boolean } {
				const trimmed = line.trim();
				
				// 处理结束标签
				if (trimmed.startsWith('</')) {
					const match = trimmed.match(/<\/([^>\s]+)/);
					return {
						tagName: match ? match[1].toLowerCase() : '',
						isClosing: true,
						isSelfClosing: false
					};
				}
				
				// 处理开始标签
				if (trimmed.startsWith('<')) {
					const match = trimmed.match(/<([^>\s]+)/);
					const tagName = match ? match[1].toLowerCase() : '';
					const isSelfClosing = trimmed.endsWith('/>') || 
						blockTags.selfClosing.includes(tagName) ||
						(tagName.startsWith('cf') && (
							trimmed.includes(' />') ||
							(!trimmed.includes('>') && !blockTags.opening.includes(tagName))
						));
					
					return {
						tagName,
						isClosing: false,
						isSelfClosing
					};
				}
				
				return { tagName: '', isClosing: false, isSelfClosing: false };
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
						if (char === stringChar && text[i - 1] !== '\\') {
							inString = false;
							stringChar = '';
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
						if (char === '{') {
							bracketStack.push('{');
							bracketChange++;
						} else if (char === '}') {
							if (bracketStack.length > 0 && bracketStack[bracketStack.length - 1] === '{') {
								bracketStack.pop();
								bracketChange--;
							}
						}
					}
				}
				
				return bracketChange;
			}

			// 处理SQL缩进
			function getSqlIndent(text: string): number {
				if (!inCfquery) return 0;
				
				const upperText = text.toUpperCase().trim();
				
				// 主要SQL关键字应该与cfquery标签对齐
				const mainKeywords = ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'WITH'];
				if (mainKeywords.some(keyword => upperText.startsWith(keyword))) {
					return 1;
				}
				
				// 子句关键字稍微缩进
				const subKeywords = ['FROM', 'WHERE', 'ORDER BY', 'GROUP BY', 'HAVING', 'UNION'];
				if (subKeywords.some(keyword => upperText.startsWith(keyword))) {
					return 1;
				}
				
				// AND/OR 条件
				if (upperText.startsWith('AND ') || upperText.startsWith('OR ')) {
					return 2;
				}
				
				// JOIN 语句
				if (upperText.includes('JOIN')) {
					return 1;
				}
				
				// 其他SQL内容
				return 2;
			}

			for (let i = 0; i < document.lineCount; i++) {
				const line = document.lineAt(i);
				let text = line.text.trim();

				// 跳过空行
				if (text.length === 0) {
					edits.push(vscode.TextEdit.replace(line.range, ""));
					continue;
				}

				const { tagName, isClosing, isSelfClosing } = parseTagName(text);
				let currentIndentLevel = indentLevel;

				// 处理结束标签
				if (isClosing) {
					// 特殊处理cfscript和cfquery
					if (tagName === 'cfscript') {
						inCfscript = false;
						bracketStack.length = 0;
					} else if (tagName === 'cfquery') {
						inCfquery = false;
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
					if (text.includes('}') && !text.includes('{')) {
						bracketIndent = Math.max(bracketStack.length - 1, 0);
					} else {
						bracketIndent = bracketStack.length;
					}
				}

				// 处理SQL缩进
				let sqlIndent = 0;
				if (inCfquery && tagName !== 'cfquery') {
					sqlIndent = getSqlIndent(text);
				}

				// 计算最终缩进
				const totalIndent = currentIndentLevel + bracketIndent + sqlIndent;
				const indentChar = useSpaces ? ' ' : '\t';
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
					if (tagName === 'cfscript') {
						inCfscript = true;
					} else if (tagName === 'cfquery') {
						inCfquery = true;
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
			vscode.window.showInformationMessage(
				`语言ID: ${editor.document.languageId}, 文件: ${editor.document.fileName}`
			);
		}
	});

	// 注册多个可能的语言ID
	const languageIds = ["coldfusion", "cfml", "cfm", "cfc", "plaintext"];
	
	languageIds.forEach(langId => {
		const registration = vscode.languages.registerDocumentFormattingEditProvider(langId, provider);
		context.subscriptions.push(registration);
		console.log(`已为语言ID "${langId}" 注册格式化器`);
	});

	context.subscriptions.push(debugCommand);

	const formatCommand = vscode.commands.registerCommand(
		"satt.cfml.formatDocumentHri", 
		async () => {
			const editor = vscode.window.activeTextEditor;
			if (!editor) {
				vscode.window.showErrorMessage("没有活动的编辑器");
				return;
			}
			
			console.log("手动格式化命令被调用");
			console.log("文档语言ID:", editor.document.languageId);
			
			try {
				// 直接调用我们的格式化器，提供所需的参数y
				const options: vscode.FormattingOptions = {
					tabSize: 4,
					insertSpaces: true
				};
				const token = new vscode.CancellationTokenSource().token;
				
				const editsResult = provider.provideDocumentFormattingEdits(
					editor.document, 
					options, 
					token
				);
				
				// 处理可能的Promise返回值
				const edits = await Promise.resolve(editsResult);
				
				if (edits && edits.length > 0) {
					await editor.edit((editBuilder: vscode.TextEditorEdit) => {
						edits.forEach((edit: vscode.TextEdit) => {
							editBuilder.replace(edit.range, edit.newText);
						});
					});
					vscode.window.showInformationMessage("格式化完成！");
				} else {
					vscode.window.showInformationMessage("没有需要格式化的内容");
				}
			} catch (error) {
				console.error("格式化错误:", error);
				vscode.window.showErrorMessage(`格式化失败: ${error}`);
			}
		}
	);

	context.subscriptions.push(formatCommand);
}

export function deactivate() {}