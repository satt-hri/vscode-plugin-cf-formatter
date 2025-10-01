import * as vscode from "vscode";
import { createInitiaLState, FormatState } from "./FormatState";
import { getSqlIndent } from "@/formatter/cf_query";
import { formatComment } from "@/formatter/cf_comment";
import { formatCfset } from "@/formatter/cf_set";
import { formatCfscript, formatRangeScript } from "@/formatter/beautify/cf_script";
import { coreOptions } from "@/formatter/beautify/base_opitons";

import { blockTags, parseTagName } from "@/utils/common";
import { formatSql } from "@/formatter/cf_sql_formatter";
import { findBlockTag } from "./TagParser";
import { ExtendedFormattingOptions } from "@/types/type";
import { formatRangeHtml } from "@/formatter/beautify/cf_html";
import { formatRangeCss } from "@/formatter/beautify/cf_css";

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

			//
			if (this.state.lastProcessLine > 0 && i <= this.state.lastProcessLine) {
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

			const { tagName, isClosing, isSelfClosing, selfLineClosing } = parseTagName(text);
			let currentIndentLevel = this.state.indentLevel;

			// 3. 处理特殊标签名
			if (blockTags.onlyIndex.includes(tagName)) {
				edits.push(
					vscode.TextEdit.replace(
						line.range,
						coreOptions.indent_char!.repeat(currentIndentLevel * coreOptions.indent_size!) + text
					)
				);
				continue;
			}

			// 3.1 檢查是否是多參數的 cfset，需要特殊處理
			if (tagName === "cfset") {
				rest = formatCfset(line, i, edits, this.state, document);
				if (rest) {
					continue; // 已經處理過注释行，跳过后续处理
				}
			}

			if (tagName === "cfscript") {
				// 如果这行有闭合大括号，先减少缩进
				rest = formatCfscript(line, i, edits, this.state, document);
				if (rest) {
					continue; // 已經處理過 cfscript 行，跳过后续处理
				}
			}
			// 先用sql-format處理 如果還不行，那就用自己寫的sql去format -> 3.4
			if (tagName === "cfquery" && !this.state.inCfquery) {
				rest = formatSql(line, i, edits, this.state, document);
				if (rest) {
					continue;
				}
			}

			// 3.2 如果是结束标签，调整缩进
			if (isClosing) {
				// 特殊处理cfquery
				if (tagName === "cfquery") {
					this.state.inCfquery = false;
					// 清空SQL CASE栈
					this.state.sqlCaseStack.length = 0;
					this.state.sqlSubqueryStack.length = 0;
				}

				// 弹出标签栈并调整缩进
				if (this.state.tagStack.length > 0) {
					this.state.tagStack.pop();
					this.state.indentLevel = Math.max(this.state.indentLevel - 1, 0);
					currentIndentLevel = this.state.indentLevel;
				}
			} else if (blockTags.elselike.includes(tagName)) {
				currentIndentLevel = Math.max(this.state.indentLevel - 1, 0);
			}

			// 3.4 处理SQL缩进
			let sqlIndent = 0;
			if (this.state.inCfquery && tagName !== "cfquery") {
				//自己寫的sqlformat處理
				sqlIndent = getSqlIndent(text, i, this.state);
			}

			// 3.6 计算最终缩进
			const totalIndent = currentIndentLevel + sqlIndent;
			const indent = coreOptions.indent_char!.repeat(totalIndent * coreOptions.indent_size!);

			// 应用格式化
			edits.push(vscode.TextEdit.replace(line.range, indent + text));

			// 3.7 处理开始标签
			if (!isClosing && !isSelfClosing && blockTags.opening.includes(tagName)) {
				// 特殊处理cfscript和cfquery
				if (tagName === "cfquery") {
					this.state.inCfquery = true;
					// 重置SQL CASE栈
					this.state.sqlCaseStack.length = 0;
					this.state.sqlSubqueryStack.length = 0;
				}

				// 自己闭合的标签不增加缩进 eg <cfif ...>...</cfif>
				if (!selfLineClosing) {
					this.state.tagStack.push(tagName);
					this.state.indentLevel++;
				}
			}
		}

		return edits;
	}

	formatRange(
		document: vscode.TextDocument,
		range: vscode.Range,
		options: vscode.FormattingOptions,
		token: vscode.CancellationToken
	): vscode.TextEdit[] {
		const edits: vscode.TextEdit[] = [];
		this.resetState();

		const { leadingSpaces } = findBlockTag(document, range);

		this.state.rangeLeftSpace = leadingSpaces;

		const startLine = range.start.line;
		const endLine = range.end.line;
		for (let i = startLine; i <= endLine; i++) {
			const line = document.lineAt(i);
			let text = line.text.trim();

			if (this.state.lastProcessLine > 0 && i <= this.state.lastProcessLine) {
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

			const { tagName, isClosing, isSelfClosing, selfLineClosing } = parseTagName(text);
			let currentIndentLevel = this.state.indentLevel;

			// 3. 处理特殊标签名
			if (blockTags.onlyIndex.includes(tagName)) {
				edits.push(
					vscode.TextEdit.replace(
						line.range,
						leadingSpaces +
							coreOptions.indent_char!.repeat(currentIndentLevel * coreOptions.indent_size!) +
							text
					)
				);
				continue;
			}

			// 3.1 檢查是否是多參數的 cfset，需要特殊處理
			if (tagName === "cfset") {
				rest = formatCfset(line, i, edits, this.state, document);
				if (rest) {
					continue; // 已經處理過注释行，跳过后续处理
				}
			}

			if (tagName === "cfscript") {
				// 如果这行有闭合大括号，先减少缩进
				rest = formatCfscript(line, i, edits, this.state, document);
				if (rest) {
					continue; // 已經處理過 cfscript 行，跳过后续处理
				}
			}
			// 先用sql-format處理 如果還不行，那就用自己寫的sql去format -> 3.4
			if (tagName === "cfquery" && !this.state.inCfquery) {
				rest = formatSql(line, i, edits, this.state, document);
				if (rest) {
					continue;
				}
			}

			// 3.2 如果是结束标签，调整缩进
			if (isClosing) {
				// 特殊处理cfquery
				if (tagName === "cfquery") {
					this.state.inCfquery = false;
					// 清空SQL CASE栈
					this.state.sqlCaseStack.length = 0;
					this.state.sqlSubqueryStack.length = 0;
				}

				// 弹出标签栈并调整缩进
				if (this.state.tagStack.length > 0) {
					this.state.tagStack.pop();
					this.state.indentLevel = Math.max(this.state.indentLevel - 1, 0);
					currentIndentLevel = this.state.indentLevel;
				}
			} else if (blockTags.elselike.includes(tagName)) {
				currentIndentLevel = Math.max(this.state.indentLevel - 1, 0);
			}

			// 3.4 处理SQL缩进
			let sqlIndent = 0;
			if (this.state.inCfquery && tagName !== "cfquery") {
				//自己寫的sqlformat處理
				sqlIndent = getSqlIndent(text, i, this.state);
			}

			// 3.6 计算最终缩进
			const totalIndent = currentIndentLevel + sqlIndent;
			const indent = coreOptions.indent_char!.repeat(totalIndent * coreOptions.indent_size!) + leadingSpaces;

			// 应用格式化
			edits.push(vscode.TextEdit.replace(line.range, indent + text));

			// 3.7 处理开始标签
			if (!isClosing && !isSelfClosing && blockTags.opening.includes(tagName)) {
				// 特殊处理cfscript和cfquery
				if (tagName === "cfquery") {
					this.state.inCfquery = true;
					// 重置SQL CASE栈
					this.state.sqlCaseStack.length = 0;
					this.state.sqlSubqueryStack.length = 0;
				}

				// 自己闭合的标签不增加缩进 eg <cfif ...>...</cfif>
				if (!selfLineClosing) {
					this.state.tagStack.push(tagName);
					this.state.indentLevel++;
				}
			}
		}

		return edits;
	}

	beautifyRange(
		document: vscode.TextDocument,
		range: vscode.Range,
		options: ExtendedFormattingOptions,
		token: vscode.CancellationToken
	): vscode.TextEdit[] {
		const edits: vscode.TextEdit[] = [];
		this.resetState();

		const startLine = range.start.line;
		const endLine = Math.min(range.end.line, document.lineCount);

		this.state.rangeLeftSpace = document.lineAt(startLine).text.match(/^(\s*)/)?.[1] || "";

		const lines: string[] = [];
		for (let i = startLine; i <= endLine; i++) {
			const line = document.lineAt(i);
			let text = line.text.trim();
			lines.push(text);
		}
		let content = lines.join("\n");
		if (content.trim() === "") {
			return edits;
		}
		if (options.flag === "script") {
			content = formatRangeScript(this.state, content);
		} else if (options.flag === "css") {
			content = formatRangeCss(this.state, content);
		} else if (options.flag === "html") {
			content = formatRangeHtml(this.state, content);
		}

		edits.push(vscode.TextEdit.replace(range, content));

		return edits;
	}
}
