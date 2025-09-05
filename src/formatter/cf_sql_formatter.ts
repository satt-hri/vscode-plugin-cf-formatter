import * as vscode from "vscode";
// import path from "path";
// import fs from "fs";
import { format, FormatOptionsWithLanguage } from "sql-formatter";
import { FormatState } from "../core/FormatState";
import { blockTags, parseTagName } from "../utils/common";
import { jsOptions } from "./cf_script";
import { writeLog } from "../utils/log";

const config = vscode.workspace.getConfiguration("hri.cfml.formatter");
//tab缩进 が優先
const useTab = config.get<boolean>("indentWithTabs", true);

const formatOption: FormatOptionsWithLanguage = {
	language: "sql",
	useTabs: useTab,
	tabWidth: useTab ? 1 : config.get<number>("indentSize", 4),
	keywordCase: "upper",
	expressionWidth: config.get<number>("expressionWidth", 30),
};

function formatCFQuery(cfqueryContent: string) {
	let placeholders: { key: string; value: string }[] = [];
	let index = 0;

	// 1. 替换 CF 标签为占位符
	const sqlWithPlaceholders = cfqueryContent
		.replace(/<!---[\s\S]*?--->/g, (match) => {
			const key = `/* __CFC_COMMENT${index}__ */`;
			placeholders.push({ key, value: match });
			index++;
			return key;
		})
		.replace(/<cfqueryparam\b[^>]*\/?\s*>/gi, (match) => {
			const key = `__CF_PARAM${index}__`;
			placeholders.push({ key, value: match });
			index++;
			return key;
		})
		.replace(/<(\/)?(cfif|cfelse|cfelseif)\b[^>]*>/gi, (match) => {
			const key = `-- __CF_IF${index}__`;
			placeholders.push({ key, value: match });
			index++;
			return key;
		})
		.replace(/<(\/)?cf\w+\b[^>]*\/?\s*>/gi, (match) => {
			const key = `/* __CF_Other${index}__ */`;
			placeholders.push({ key, value: match });
			index++;
			return key;
		})
		//すべてのcfタグを修理するのは、危ないね！！！！
		// .replace(/<cf.*?>[\s\S]*?<\/cf.*?>|<cf.*?\/>/gi, (match) => {
		// 	const key = `__CFBLOCK${index}__`;
		// 	placeholders.push({ key, value: match });
		// 	index++;
		// 	return key;
		// })
		.replace(/#[^#]+#/gi, (match) => {
			const key = `__CF_EXPR${index}__`;
			placeholders.push({ key, value: match });
			index++;
			return key;
		});
	// 2. 格式化 SQL
	let formattedSQL: string = "";
	console.log("sqlWithPlaceholders", sqlWithPlaceholders);
	console.log("placeholders", placeholders);
	try {
		formattedSQL = format(sqlWithPlaceholders, formatOption);
	} catch (e) {
		console.error("SQL 格式化失败，返回原始内容");
		console.log(e);
		formattedSQL = sqlWithPlaceholders;
		return cfqueryContent;
	} finally {
		writeLog("cfqueryContent:" + cfqueryContent);
		writeLog("sqlWithPlaceholders:" + sqlWithPlaceholders);
		writeLog("placeholders:" + JSON.stringify(placeholders));
		writeLog("formattedSQL:" + formattedSQL);
	}

	// 3. 替换回 CF 标签
	placeholders.forEach(({ key, value }) => {
		formattedSQL = formattedSQL.replace(key, value);
	});

	//4. cfif 再進行一次 tab
	let ifIndex: string[] = [];
	let lastSql = formattedSQL
		.split("\n")
		.map((item) => {
			const { tagName, isClosing, selfLineClosing } = parseTagName(item);
			let tempText = ifIndex.length
				? jsOptions.indent_char!.repeat(jsOptions.indent_size! * ifIndex.length) + item
				: item;
			//cfif cfswitch cfcase cfdefaultcase等
			//!selfLineClosing  if 在一條綫等問題上很複雜，假如是一行的 if  endif 這種 就不處理了。
			if (blockTags.opening.includes(tagName) && !selfLineClosing) {
				if (isClosing) {
					ifIndex.pop();
					tempText = ifIndex.length
						? jsOptions.indent_char!.repeat(jsOptions.indent_size! * ifIndex.length) + item
						: item;
				} else {
					ifIndex.push(item);
				}
			} else if (tagName == "cfelse" || tagName == "cfelseif") {
				tempText = ifIndex.length
					? jsOptions.indent_char!.repeat(jsOptions.indent_size! * (ifIndex.length - 1)) + item
					: item;
			}
			return tempText;
		})
		.join("\n");

	return lastSql;
}

const SkipTags = ["cfloop", "cfscript"];

export function formatSql(
	line: vscode.TextLine,
	lineIndex: number,
	edits: vscode.TextEdit[],
	state: FormatState,
	document: vscode.TextDocument
): boolean {
	const totalIndent = state.indentLevel;
	const baseIndent = jsOptions.indent_char!.repeat(totalIndent * jsOptions.indent_size!);

	const lines: { text: string; range: vscode.Range; lineIndex: number }[] = [];
	let startQuery = line.text.trim();
	let endQuery = "";
	let index = lineIndex + 1;
	for (; index < document.lineCount; index++) {
		const templine = document.lineAt(index);
		const temText = templine.text.trim();
		const { tagName, isClosing } = parseTagName(temText);

		//cfqueryに cfscirpt cfloop等存在的話就 跳過
		if (SkipTags.includes(tagName)) {
			return false;
		}

		if (isClosing && tagName === "cfquery") {
			endQuery = temText;
			break;
		}
		lines.push({ text: temText, lineIndex: index, range: templine.range });
	}
	state.lastProcessLine = index;

	if (lines.length === 0) return false;

	edits.push(vscode.TextEdit.replace(document.lineAt(lineIndex).range, baseIndent + startQuery));
	let formattedContent = lines.map((item) => item.text).join("\n");
	//console.log("formattedContent", formattedContent);
	let formattedSQL = formatCFQuery(formattedContent);
	//console.log("formattedSQL", formattedSQL);

	const indentedLines = formattedSQL
		.split("\n")
		.map((line) => (line.trim() ? baseIndent + jsOptions.indent_char!.repeat(jsOptions.indent_size!) + line : ""))
		.join("\n");

	const startPos = new vscode.Position(lineIndex + 1, 0);
	const lastContentLine = document.lineAt(index - 1);
	const endPos = new vscode.Position(index - 1, lastContentLine.text.length);
	const replaceRange = new vscode.Range(startPos, endPos);
	edits.push(vscode.TextEdit.replace(replaceRange, indentedLines));

	edits.push(vscode.TextEdit.replace(document.lineAt(index).range, baseIndent + endQuery));

	return true;
}
