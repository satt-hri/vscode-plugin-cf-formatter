import * as vscode from "vscode";
import { messages, Lang } from "./config";
import path from "path";
import FormatterManager from "./core/FormatterManager";

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
			const manager = new FormatterManager();

			const ext = path.extname(document.fileName).toLowerCase();
			if (ext === ".cfm") {
				vscode.window.showWarningMessage(messages.warnMsg[lang] as string, { modal: true });
				return []; // 只处理 .cfc 文件
			}
			return manager.formatDocument(document, options, token);

			// const edits: vscode.TextEdit[] = [];
			// let indentLevel = 0;
			// let inCfscript = false;
			// let inCfquery = false;
			// let inString = false;
			// let stringChar = "";
			// let inMultiLineComment = false; // 新增：跟踪多行注释状态

			// // SQL CASE WHEN 结构跟踪
			// let sqlCaseStack: number[] = []; // 跟踪CASE语句的嵌套层级
			// let sqlSubqueryStack: number[] = []; // 跟踪子查询的嵌套层级

			// // 使用格式化选项中的缩进设置
			// const indentSize = options.tabSize || 2;
			// const useSpaces = false; // 強制使用 tab 縮進

			// // 使用栈来跟踪嵌套结构
			// const tagStack: string[] = []; // 跟踪未闭合的标签
			// const bracketStack: string[] = []; // 在 CFScript 中跟踪 {} 嵌套
		},
	};

	// 添加调试命令
	const debugCommand = vscode.commands.registerCommand("satt.cfml.debug", () => {
		const editor = vscode.window.activeTextEditor;
		if (editor) {
		//	console.log("当前文件语言ID:", editor.document.languageId);
			//console.log("当前文件路径:", editor.document.fileName);
			const val = messages.langInfo[lang];
			vscode.window.showInformationMessage(
				typeof val === "function" ? val(editor.document.languageId, editor.document.fileName) : val
			);
		}
	});
	context.subscriptions.push(debugCommand);

	// 注册多个可能的语言ID
	const languageIds = ["cfml", "cfm", "cfc"];

	languageIds.forEach((langId) => {
		const registration = vscode.languages.registerDocumentFormattingEditProvider(langId, provider);
		context.subscriptions.push(registration);
		console.log(`已为语言ID "${langId}" 注册格式化器`);
	});

	const formatCommand = vscode.commands.registerCommand("hri.cfml.formatDocument", async () => {
		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			vscode.window.showErrorMessage(messages.noEditor[lang] as string);
			return;
		}

		//console.log("手动格式化命令被调用");
		//console.log("文档语言ID1:", editor.document.languageId);

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
			//console.log("计算得到的编辑操作:", edits);

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
