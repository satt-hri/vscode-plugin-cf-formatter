import * as vscode from "vscode";
import path from "path";
import fs from "fs";
import { format, FormatOptionsWithLanguage } from "sql-formatter";
import { FormatState } from "../core/FormatState";
import { parseTagName } from "../utils/common";
import { jsOptions } from "./cf_script";

const formatOption: FormatOptionsWithLanguage = {
	language: "mysql",
	useTabs: true,
	keywordCase: "upper",
	expressionWidth: 30,
};

function formatCFQuery(cfqueryContent: string) {
	let placeholders: { key: string; value: string }[] = [];
	let index = 0;

	// 1. 替换 CF 标签为占位符
	const sqlWithPlaceholders = cfqueryContent
		.replace(/<!---[\s\S]*?--->/g, (match) => {
			const key = `__CFC_OMMENT${index}__`;
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
			const key = `/* __CF_IF${index}__ */`;
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
	let formattedSQL: string;
	console.log("placeholders", placeholders);
	try {
		formattedSQL = format(sqlWithPlaceholders, formatOption);
	} catch (e) {
		console.error("SQL 格式化失败，返回原始内容");
		console.log(e);
		formattedSQL = sqlWithPlaceholders;
		return cfqueryContent;
	}

	// 3. 替换回 CF 标签
	placeholders.forEach(({ key, value }) => {
		formattedSQL = formattedSQL.replace(key, value);
	});

	return formattedSQL;
}

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
		if (isClosing && tagName === "cfquery") {
			endQuery = temText;
			break;
		}
		lines.push({ text: temText, lineIndex: index, range: templine.range });
	}
	state.lastProcessLine = index;
	//console.log("lines", lines);

	if (lines.length === 0) return false;

	edits.push(vscode.TextEdit.replace(document.lineAt(lineIndex).range, baseIndent + startQuery));
	let formattedContent = lines.map((item) => item.text).join("\n");
	console.log("formattedContent", formattedContent);
	let formattedSQL = formatCFQuery(formattedContent);
	console.log("formattedSQL", formattedSQL);

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

// function formatCFMLFile(filePath: fs.PathOrFileDescriptor) {
//     const content = fs.readFileSync(filePath, "utf-8");

//     // 正则匹配 <cfquery>...</cfquery>
//     const formattedContent = content.replace(/<cfquery\b[^>]*>[\s\S]*?<\/cfquery>/gi, (match) => {
//         const innerSQL = match
//             .replace(/^<cfquery\b[^>]*>/i, "")
//             .replace(/<\/cfquery>$/i, "");

//         const formattedSQL = formatCFQuery(innerSQL);

//         const openTagMatch = match.match(/^<cfquery\b[^>]*>/i);
//         const openTag = openTagMatch ? openTagMatch[0] : "<cfquery>";
//         return `${openTag}\n${formattedSQL}\n</cfquery>`;
//     });

//     return formattedContent;
// }

// ------------------- 测试 -------------------
// const outputFile = path.resolve(__dirname, "example_formatted.cfm");

// const result = formatCFMLFile(inputFile);
// fs.writeFileSync(outputFile, result, "utf-8");

// console.log("格式化完成，输出到:", outputFile);
