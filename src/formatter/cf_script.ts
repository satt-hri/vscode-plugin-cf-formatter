import { FormatState } from "../core/FormatState";
import beautify from "js-beautify";
import * as vscode from "vscode";
import { parseTagName } from "../utils/common";

const jsOptions: js_beautify.JSBeautifyOptions = {
	indent_size: 4,
	indent_char: " ",
	max_preserve_newlines: 2,
	preserve_newlines: true,
	keep_array_indentation: false,
	break_chained_methods: false,
	//indent_scripts: "normal",
	brace_style: "collapse",
	space_before_conditional: true,
	unescape_strings: false,
	jslint_happy: false,
	end_with_newline: false,
	wrap_line_length: 80,
	//indent_inner_html: false,
	comma_first: false,
	e4x: false,
	indent_empty_lines: false,
};

export function formatCfscript(
	line: vscode.TextLine,
	lineIndex: number,
	edits: vscode.TextEdit[],
	state: FormatState,
	document: vscode.TextDocument
): boolean {
	if (!state.inCfscript) {
		return false; // 如果不在 cfscript 内，直接返回
	}
	const lines: string[] = [];
	let endLineIndex = -1;
	for (let i = lineIndex; i < document.lineCount; i++) {
		const line = document.lineAt(i);
		let text = line.text.trim();
		const { tagName, isClosing, isSelfClosing } = parseTagName(text);

		if (isClosing && tagName === "cfscript") {
			endLineIndex = i;
			state.inCfscript = false;
			//state.bracketStack.length = 0;
			break; // 退出循环
		} else {
			lines.push(text);
		}
	}

	// 如果没有找到结束标签，返回 false
	if (endLineIndex === -1) {
		return false;
	}

	const scriptContent = lines.join("\n");
	if (scriptContent.trim() === "") {
		return false; // 如果 cfscript 内容为空，直接返回
	}

	try {
		const formattedCode = beautify.js(scriptContent, jsOptions);

		const totalIndent = state.indentLevel;
		const indentChar = state.useSpaces ? " " : "\t";
		const indentUnit = state.useSpaces ? state.indentSize : 1;
		const baseIndent = indentChar.repeat(totalIndent * indentUnit);

		// 为格式化后的每行添加适当的缩进
		const indentedLines = formattedCode
			.split("\n")
			.map((line) => (line.trim() ? baseIndent + line : ""))
			.join("\n");

		// 创建替换范围：从当前行到结束标签的前一行
		const startPos = new vscode.Position(lineIndex, 0);
		const lastContentLine = document.lineAt(endLineIndex - 1);
		const endPos = new vscode.Position(endLineIndex - 1, lastContentLine.text.length);
		const replaceRange = new vscode.Range(startPos, endPos);

		// 添加编辑操作
		edits.push(vscode.TextEdit.replace(replaceRange, indentedLines));

		state.globalIndent = Math.max(endLineIndex - 1, lineIndex); // 更新全局缩进位置，跳过已处理的行
		return true;
	} catch (error) {}

	return false;
}
