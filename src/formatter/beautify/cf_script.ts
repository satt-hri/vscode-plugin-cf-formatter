import { FormatState } from "@/core/FormatState";
import { CoreBeautifyOptions, JSBeautifyOptions, js_beautify } from "js-beautify";
import * as vscode from "vscode";
import { parseTagName } from "@/utils/common";
import { writeLog } from "@/utils/log";
import { coreOptions } from "./base_opitons";

const config = vscode.workspace.getConfiguration("hri.cfml.formatter");
//console.log("config", config);

//tab缩进 が優先
const jsOptions: JSBeautifyOptions = {
	...coreOptions,
	//js配置开始
	max_preserve_newlines: coreOptions.max_preserve_newlines! + 1, //不知道为什么js会比实际设置的行数少1 20250926
	keep_array_indentation: config.get<boolean>("keepArrayIndentation", false),
	break_chained_methods: config.get<boolean>("breakChainedMethods", false),
	brace_style: config.get<string>("braceStyle", "collapse") as any,
	space_before_conditional: config.get<boolean>("spaceBeforeConditional", true),
	unescape_strings: false,
	jslint_happy: false,
	comma_first: false,
	e4x: false,
};

const ignoreFunction = ["replace"];
const ignoreStart = "/* beautify ignore:start */";
const ignoreEnd = "/* beautify ignore:end */";
const cusIgnoreStart = "/* cf:start */";
const cusIgnoreEnd = "/* cf:end */";

function wrapIgnoreCode(code: string): string {
	const pattern = `\\b(${ignoreFunction.join("|")})\\s*\\(`;
	if (new RegExp(pattern, "i").test(code)) {
		let temp = `${ignoreStart}${code}${ignoreEnd}`;
		writeLog("wrapIgnoreCode:" + temp);
		return temp;
	}

	return code;
}
function removeIgnoreCode(code: string): string {
	writeLog("removeIgnoreCode_code:" + code);
	let temp = code.replaceAll(ignoreStart, "").replaceAll(ignoreEnd, "");
	writeLog("removeIgnoreCode_temp:" + temp);
	return temp;
}

export function formatCfscript(
	line: vscode.TextLine,
	lineIndex: number,
	edits: vscode.TextEdit[],
	state: FormatState,
	document: vscode.TextDocument
): boolean {
	// 跳过已处理的行
	let text = line.text.trim();
	const { tagName, isClosing } = parseTagName(text);
	if (tagName !== "cfscript" || text.length == 0) {
		return false; // 只處理 cfset 標籤
	}
	const totalIndent = state.indentLevel;
	const baseIndent = jsOptions.indent_char!.repeat(totalIndent * jsOptions.indent_size!) + state.rangeLeftSpace;

	console.log(`jsOptions`);
	console.log(jsOptions);

	// 開始 <cfscript> 標籤
	if (!isClosing && /^<cfscript\b.*>$/i.test(text)) {
		edits.push(vscode.TextEdit.replace(line.range, baseIndent + text));
	}
	// 中間内容
	const lines: string[] = [];
	let i = lineIndex + 1;
	for (; i < document.lineCount; i++) {
		const templine = document.lineAt(i);
		const temText = wrapIgnoreCode(templine.text.trim());
		const { tagName, isClosing } = parseTagName(temText);

		if (isClosing && tagName === "cfscript") {
			edits.push(vscode.TextEdit.replace(templine.range, baseIndent + temText));
			break; // 退出循环
		} else {
			lines.push(temText);
		}
	}

	state.lastProcessLine = i; // 更新全局缩进位置，跳过已处理的行
	const scriptContent = lines.join("\n");
	if (scriptContent.trim() === "") {
		return true; // 如果 cfscript 内容为空，直接返回
	}

	// let placeholders: { key: string; value: string }[] = [];
	// let index = 0;

	// const strWithPlaceholders = scriptContent.replace(/(['"])([^'"]*<\s*[A-Za-z][\s\S]*?>[^'"])\1/g, (match) => {
	// 	const key = `__XML_HTML_${index}_`;
	// 	placeholders.push({ key, value: match });
	// 	index++;
	// 	return key;
	// });
	// console.log(strWithPlaceholders);

	try {
		writeLog("script_Content:" + scriptContent);
		let formattedCode = js_beautify(scriptContent, jsOptions);
		writeLog("script_formattedCode:" + formattedCode);

		formattedCode = removeIgnoreCode(formattedCode);

		// placeholders.forEach(({ key, value }) => {
		// 	formattedCode = formattedCode.replace(key, value);
		// });

		// 为格式化后的每行添加适当的缩进
		const indentedLines = formattedCode
			.split("\n")
			.map((line) =>
				line.trim() ? baseIndent + jsOptions.indent_char!.repeat(jsOptions.indent_size!) + line : line
			)
			.join("\n");

		// 创建替换范围：从当前行到结束标签的前一行
		const startPos = new vscode.Position(lineIndex + 1, 0);
		const lastContentLine = document.lineAt(i - 1);
		const endPos = new vscode.Position(i - 1, lastContentLine.text.length);
		const replaceRange = new vscode.Range(startPos, endPos);

		// 添加编辑操作
		//console.log("格式化 cfscript:", lineIndex, i);
		edits.push(vscode.TextEdit.replace(replaceRange, indentedLines));

		return true;
	} catch (error) {
		console.error("格式化 cfscript 时出错:", error);
		writeLog("script_error:" + String(error));
		return false;
	}
}
