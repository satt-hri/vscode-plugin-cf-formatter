import * as vscode from "vscode";
import { createInitiaLState, FormatState } from "./FormatState";
import { getSqlIndent } from "../formatter/cf_query";
import { formatComment, formatCommentLine, isFileHeaderComment, updateCommentState } from "../formatter/cf_comment";
import { formatCfsetMultiParams, getSpecialTagIndent, isCfsetWithMultipleParams } from "../formatter/cf_set";
import { processCfscriptBrackets } from "../formatter/cf_script";
import { blockTags, parseTagName } from "../utils/common";

export default class FormatterManager {
	private state: FormatState;
	constructor() {
		this.state = createInitiaLState();
	}
	resetState() {
		this.state = createInitiaLState();
	}
	formatDocument(
		document: vscode.TextDocument,
		options: vscode.FormattingOptions,
		token: vscode.CancellationToken
	): vscode.TextEdit[] {
		const edits: vscode.TextEdit[] = [];
		this.resetState();

		for (let i = 0; i < document.lineCount; i++) {
			const line = document.lineAt(i);
			let text = line.text.trim();

			// 跳过空行
			if (text.length === 0) {
				edits.push(vscode.TextEdit.replace(line.range, ""));
				continue;
			}

			// 處理注释行
			const rest = formatComment(line, i, edits, this.state, document);
			if (rest) {
				continue; // 已經處理過注释行，跳过后续处理
			}

			const { tagName, isClosing, isSelfClosing } = parseTagName(text);
			let currentIndentLevel = this.state.indentLevel;

			// 檢查是否是多參數的 cfset，需要特殊處理
			if (tagName === "cfset" && isCfsetWithMultipleParams(text)) {
				// 計算基礎縮進
				let bracketIndent = 0;
				if (this.state.inCfscript) {
					if (text.includes("}") && !text.includes("{")) {
						bracketIndent = Math.max(this.state.bracketStack.length - 1, 0);
					} else {
						bracketIndent = this.state.bracketStack.length;
					}
				}

				// cfset 不會在 cfquery 內，所以 sqlIndent 為 0
				let sqlIndent = 0;

				let specialIndent = getSpecialTagIndent(tagName, this.state);
				let baseIndentLevel = currentIndentLevel + bracketIndent + sqlIndent + specialIndent;

				// 格式化多行 cfset
				const formattedLines = formatCfsetMultiParams(text, baseIndentLevel, this.state);

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
					this.state.inCfscript = false;
					this.state.bracketStack.length = 0;
				} else if (tagName === "cfquery") {
					this.state.inCfquery = false;
					// 清空SQL CASE栈
					this.state.sqlCaseStack.length = 0;
					this.state.sqlSubqueryStack.length = 0;
				}

				// 弹出标签栈并调整缩进
				if (this.state.tagStack.length > 0) {
					const lastTag = this.state.tagStack.pop();
					this.state.indentLevel = Math.max(this.state.indentLevel - 1, 0);
					currentIndentLevel = this.state.indentLevel;
				}
			}
			// 处理else类标签
			else if (blockTags.elselike.includes(tagName)) {
				currentIndentLevel = Math.max(this.state.indentLevel - 1, 0);
			}

			// 处理cfscript内的大括号缩进
			let bracketIndent = 0;
			if (this.state.inCfscript) {
				// 如果这行有闭合大括号，先减少缩进
				if (text.includes("}") && !text.includes("{")) {
					bracketIndent = Math.max(this.state.bracketStack.length - 1, 0);
				} else {
					bracketIndent = this.state.bracketStack.length;
				}
			}

			// 处理SQL缩进
			let sqlIndent = 0;
			if (this.state.inCfquery && tagName !== "cfquery") {
				sqlIndent = getSqlIndent(text, i, this.state);
			}

			// 新增：处理特殊标签的缩进
			let specialIndent = 0;
			if (isSelfClosing) {
				specialIndent = getSpecialTagIndent(tagName, this.state);
			}

			// 计算最终缩进
			const totalIndent = currentIndentLevel + bracketIndent + sqlIndent + specialIndent;
			const indentChar = this.state.useSpaces ? " " : "\t";
			const indentUnit = this.state.useSpaces ? this.state.indentSize : 1;
			const indent = indentChar.repeat(totalIndent * indentUnit);

			// 应用格式化
			edits.push(vscode.TextEdit.replace(line.range, indent + text));

			// 处理cfscript大括号变化
			if (this.state.inCfscript) {
				processCfscriptBrackets(text, this.state);
			}

			// 处理开始标签
			if (!isClosing && !isSelfClosing && blockTags.opening.includes(tagName)) {
				// 特殊处理cfscript和cfquery
				if (tagName === "cfscript") {
					this.state.inCfscript = true;
				} else if (tagName === "cfquery") {
					this.state.inCfquery = true;
					// 重置SQL CASE栈
					this.state.sqlCaseStack.length = 0;
				}

				this.state.tagStack.push(tagName);
				this.state.indentLevel++;
			}

			// 处理else类标签后的缩进恢复
			if (blockTags.elselike.includes(tagName)) {
				// else类标签本身不增加缩进，但后续内容需要缩进
				// 这里不需要特殊处理，因为缩进在下一轮循环中会正确计算
			}
		}

		return edits;
	}
}
