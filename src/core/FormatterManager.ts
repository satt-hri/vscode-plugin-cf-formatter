import * as vscode from "vscode";
import { createInitiaLState, FormatState } from "./FormatState";
import { getSqlIndent } from "../formatter/cf_query";
import { formatComment } from "../formatter/cf_comment";
import { formatCfset, getSpecialTagIndent } from "../formatter/cf_set";
import { formatCfscript } from "../formatter/cf_script";
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
		let i = this.state.globalIndent || 0;

		for (; i < document.lineCount; i++) {
			const line = document.lineAt(i);
			let text = line.text.trim();

			//
			if (this.state.globalIndent > i) {
				i = this.state.globalIndent;
				continue;
			}

			// 1. 跳过空行
			if (text.length === 0) {
				edits.push(vscode.TextEdit.replace(line.range, ""));
				continue;
			}

			let rest = false;
			// 2. 處理注释行
			rest = formatComment(line, i, edits, this.state, document);
			if (rest) {
				continue; // 已經處理過注释行，跳过后续处理
			}

			const { tagName, isClosing, isSelfClosing } = parseTagName(text);
			let currentIndentLevel = this.state.indentLevel;

			// 3. 处理标签名
			// 3.1 檢查是否是多參數的 cfset，需要特殊處理
			if (tagName === "cfset") {
				rest = formatCfset(line, i, edits, this.state, document);
				if (rest) {
					continue; // 已經處理過注释行，跳过后续处理
				}
			}

			// 3.2 如果是结束标签，调整缩进
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
					//const lastTag = this.state.tagStack.pop();
					this.state.indentLevel = Math.max(this.state.indentLevel - 1, 0);
					currentIndentLevel = this.state.indentLevel;
				}
			} else if (blockTags.elselike.includes(tagName)) {
				currentIndentLevel = Math.max(this.state.indentLevel - 1, 0);
			}

			// 3.3处理cfscript内的大括号缩进
			let bracketIndent = 0;
			if (this.state.inCfscript) {
				// 如果这行有闭合大括号，先减少缩进
				rest = formatCfscript(line, i, edits, this.state, document);
				if (rest) {
					continue; // 已經處理過 cfscript 行，跳过后续处理
				}
				// if (text.includes("}") && !text.includes("{")) {
				// 	bracketIndent = Math.max(this.state.bracketStack.length - 1, 0);
				// } else {
				// 	bracketIndent = this.state.bracketStack.length;
				// }
			}

			// 3.4 处理SQL缩进
			let sqlIndent = 0;
			if (this.state.inCfquery && tagName !== "cfquery") {
				sqlIndent = getSqlIndent(text, i, this.state);
			}

			// 3.5 新增：处理特殊标签的缩进
			let specialIndent = 0;
			if (isSelfClosing) {
				specialIndent = getSpecialTagIndent(tagName, this.state);
			}

			// 3.6 计算最终缩进
			const totalIndent = currentIndentLevel + bracketIndent + sqlIndent + specialIndent;
			const indentChar = this.state.useSpaces ? " " : "\t";
			const indentUnit = this.state.useSpaces ? this.state.indentSize : 1;
			const indent = indentChar.repeat(totalIndent * indentUnit);

			// 应用格式化
			edits.push(vscode.TextEdit.replace(line.range, indent + text));

			// // 处理cfscript大括号变化
			// if (this.state.inCfscript) {
			// 	processCfscriptBrackets(text, this.state);
			// }

			// 3.7 处理开始标签
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
			// if (blockTags.elselike.includes(tagName)) {
			// 	// else类标签本身不增加缩进，但后续内容需要缩进
			// 	// 这里不需要特殊处理，因为缩进在下一轮循环中会正确计算
			// }
		}

		return edits;
	}
}
