import * as vscode from "vscode";

export function activate(context: vscode.ExtensionContext) {
	console.log("CFML Auto Formatter 插件已激活");

	const indentSize = 2;

	const provider: vscode.DocumentFormattingEditProvider = {
		provideDocumentFormattingEdits(document: vscode.TextDocument): vscode.TextEdit[] {
			const edits: vscode.TextEdit[] = [];
			let indentLevel = 0;
			let inCfscript = false;
			let inCfquery = false;
			let cfscriptIndent = 0;
			let cfqueryIndent = 0;

			const openingTags = [
				"<cffunction",
				"<cfif",
				"<cfloop",
				"<cfquery",
				"<cftry",
				"<cfcatch",
				"<cfscript",
				"<cfcomponent",
			];
			const closingTags = [
				"</cffunction>",
				"</cfif>",
				"</cfloop>",
				"</cfquery>",
				"</cftry>",
				"</cfcatch>",
				"</cfcomponent>",
			];
			const elseTags = ["<cfelse", "<cfelseif"];
			const selfClosingTags = ["<cfset", "<cfreturn>", "<cfbreak", "<cfcontinue"];

			const isOpening = (line: string) =>
				openingTags.some((tag) => line.startsWith(tag)) && !selfClosingTags.some((tag) => line.startsWith(tag));
			const isClosing = (line: string) => closingTags.some((tag) => line.startsWith(tag));
			const isElse = (line: string) => elseTags.some((tag) => line.startsWith(tag));

			for (let i = 0; i < document.lineCount; i++) {
				const line = document.lineAt(i);
				let text = line.text.trim();

				if (text.length === 0) {
					edits.push(vscode.TextEdit.replace(line.range, ""));
					continue;
				}

				// cfscript 结束
				if (text.startsWith("</cfscript>")) {
					inCfscript = false;
					cfscriptIndent = 0;
					indentLevel = Math.max(indentLevel - 1, 0);
				}

				// cfquery 结束
				if (text.startsWith("</cfquery>")) {
					inCfquery = false;
					cfqueryIndent = 0;
					indentLevel = Math.max(indentLevel - 1, 0);
				}

				// else 标签缩进
				if (isElse(text)) {
					indentLevel = Math.max(indentLevel - 1, 0);
				}

				// closing 标签缩进
				if (isClosing(text)) {
					indentLevel = Math.max(indentLevel - 1, 0);
				}

				// 计算缩进
				let currentIndent = indentLevel;
				if (inCfscript) currentIndent += cfscriptIndent;
				if (inCfquery) currentIndent += cfqueryIndent;
				const indent = " ".repeat(currentIndent * indentSize);

				// 替换行
				edits.push(vscode.TextEdit.replace(line.range, indent + text));

				// cfscript 内部大括号缩进
				if (inCfscript) {
					if (text.includes("{")) cfscriptIndent += 1;
					if (text.includes("}")) cfscriptIndent = Math.max(cfscriptIndent - 1, 0);
				}

				// cfquery 内部缩进（遇到 SQL 关键字换行）
				if (inCfquery) {
					const sqlKeywords = [
						"SELECT",
						"FROM",
						"WHERE",
						"AND",
						"OR",
						"INNER JOIN",
						"LEFT JOIN",
						"RIGHT JOIN",
						"ORDER BY",
						"GROUP BY",
						"VALUES",
					];
					sqlKeywords.forEach((keyword) => {
						if (text.toUpperCase().startsWith(keyword)) cfqueryIndent = 1;
					});
				}

				// 开始标签
				if (isOpening(text)) {
					if (text.startsWith("<cfscript")) {
						inCfscript = true;
						cfscriptIndent = 0;
					}
					if (text.startsWith("<cfquery")) {
						inCfquery = true;
						cfqueryIndent = 1; // SQL 内缩进
					}
					indentLevel += 1;
				}
			}

			return edits;
		},
	};

	context.subscriptions.push(vscode.languages.registerDocumentFormattingEditProvider("coldfusion", provider));

	const formatCommand = vscode.commands.registerCommand("satt.cfml.formatDocumentHri", async () => {
		const editor = vscode.window.activeTextEditor;
		if (!editor) return;
		await vscode.commands.executeCommand("editor.action.formatDocument");
	});

	context.subscriptions.push(formatCommand);
}

export function deactivate() {}
