import * as vscode from "vscode";
import { messages, Lang } from "./config";
import path from "path";
import FormatterManager from "./core/FormatterManager";
import { initLog, writeLog } from "./utils/log";
import { disableAutoCloseTag, restoreAutoCloseTag } from "./utils/conflicts";
import { autoTagWrapping, autoTagWrappingByRange, findBlockTag } from "./core/TagParser";

export function activate(context: vscode.ExtensionContext) {
	//console.log("CFML Auto Formatter 插件已激活");
	// 初始化日志系统
	initLog(context);
	writeLog("插件已激活");
	// 检查注册的语言
	//console.log("支持的语言:", vscode.languages.getLanguages());
	const lang = vscode.env.language.toLowerCase() as Lang;

	// 全文档格式化 Provider
	const fullDocumentProvider: vscode.DocumentFormattingEditProvider = {
		async provideDocumentFormattingEdits(
			document: vscode.TextDocument,
			options: vscode.FormattingOptions,
			token: vscode.CancellationToken
		): Promise<vscode.TextEdit[]> {
			const ext = path.extname(document.fileName).toLowerCase();
			if (ext === ".cfm") {
				const result = await vscode.window.showWarningMessage(messages.warnMsg[lang] as string, "Yes", "No");
				if (result === "No") {
					return [];
				}
			}

			const preprocessedEdits = autoTagWrapping(document);
			if (preprocessedEdits.length > 0) {
				const workspaceEdit = new vscode.WorkspaceEdit();
				workspaceEdit.set(document.uri, preprocessedEdits);
				const success = await vscode.workspace.applyEdit(workspaceEdit);
				//await new Promise((resolve) => setTimeout(resolve, 10));
				console.log(success);
			}

			const manager = new FormatterManager();

			return manager.formatDocument(document, options, token);
		},
	};
	const rangeFormattingPrvider: vscode.DocumentRangeFormattingEditProvider = {
		async provideDocumentRangeFormattingEdits(
			document: vscode.TextDocument,
			range: vscode.Range,
			options: vscode.FormattingOptions,
			token: vscode.CancellationToken
		): Promise<vscode.TextEdit[]> {
			const ext = path.extname(document.fileName).toLowerCase();
			if (ext === ".cfm") {
				const result = await vscode.window.showWarningMessage(messages.warnMsg[lang] as string, "Yes", "No");
				if (result === "No") {
					return [];
				}
			}

			const { tag } = findBlockTag(document, range);
			if (tag == "") {
				const lang = vscode.env.language.toLowerCase() as Lang;
				vscode.window.showWarningMessage(messages.blockTagWarn[lang] as string, { modal: true });
				return [];
			}

			const preprocessedEdits = autoTagWrappingByRange(document, range);
			if (preprocessedEdits.length > 0) {
				const workspaceEdit = new vscode.WorkspaceEdit();
				workspaceEdit.set(document.uri, preprocessedEdits);
				const success = await vscode.workspace.applyEdit(workspaceEdit);
				//await new Promise((resolve) => setTimeout(resolve, 10));
				console.log(success);

				const editor = vscode.window.activeTextEditor;
				if (!editor || editor.document.uri.toString() !== document.uri.toString()) {
					return [];
				}

				const eol = document.eol === vscode.EndOfLine.CRLF ? "\r\n" : "\n";
				const linesAdded = preprocessedEdits.reduce((sum, edit) => {
					return sum + edit.newText.split(eol).length - 1;
				}, 0);

				const newRange = new vscode.Range(
					range.start.line,
					0,
					range.end.line + linesAdded,
					document.lineAt(Math.min(range.end.line + linesAdded, document.lineCount - 1)).text.length
				);

				const manager = new FormatterManager();
				return manager.formatRange(document, newRange, options, token);
			}

			const manager = new FormatterManager();

			return manager.formatRange(document, range, options, token);
		},
	};

	// 注册多个可能的语言ID
	const languageIds = ["cfml", "cfm", "cfc"];

	languageIds.forEach((langId) => {
		const fullDocRegistration = vscode.languages.registerDocumentFormattingEditProvider(
			langId,
			fullDocumentProvider
		);
		context.subscriptions.push(fullDocRegistration);
		const rangeRegistration = vscode.languages.registerDocumentRangeFormattingEditProvider(
			langId,
			rangeFormattingPrvider
		);
		context.subscriptions.push(rangeRegistration);

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
			const originalStates = await disableAutoCloseTag();
			try {
				// 直接调用我们的格式化器，提供所需的参数
				const options: vscode.FormattingOptions = {
					tabSize: 4,
					insertSpaces: true,
				};
				const token = new vscode.CancellationTokenSource().token;
				const selection = editor.selection;
				let editsResult;
				if (!selection.isEmpty) {
					editsResult = rangeFormattingPrvider.provideDocumentRangeFormattingEdits(
						editor.document,
						selection,
						options,
						token
					);
				} else {
					editsResult = fullDocumentProvider.provideDocumentFormattingEdits(editor.document, options, token);
				}

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
			} finally {
				await restoreAutoCloseTag(originalStates);
			}
		} catch (error) {
			const val = messages.formatError[lang];
			console.error("格式化错误:", error);
			writeLog("格式化错误:" + String(error));
			vscode.window.showErrorMessage(typeof val === "function" ? val(error) : val);
		}
	});

	context.subscriptions.push(formatCommand);
}

export function deactivate() {}
