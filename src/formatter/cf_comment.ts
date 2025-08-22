import { FormatState } from "../core/FormatState";
import * as vscode from "vscode";

export function formatComment(
	line: vscode.TextLine,
	lineIndex: number,
	edits: vscode.TextEdit[],
	state: FormatState,
	document: vscode.TextDocument
): boolean {
	let text = line.text.trim();

	// 更新注释状态（仅文件头注释）
	updateCommentState(text, lineIndex, state, document);

	// 处理多行注释（仅文件头注释）
	if (
		(state.inMultiLineComment || text.startsWith("<!---") || text.endsWith("--->")) &&
		isFileHeaderComment(lineIndex, state, document)
	) {
		const formattedLine = formatCommentLine(text, lineIndex, state, document);
		edits.push(vscode.TextEdit.replace(line.range, formattedLine));
		return true; // 跳过其他处理，直接处理下一行
	}

	return false;
}

// 检查是否是文件开头的注释（在任何实际代码之前）
export function isFileHeaderComment(lineIndex: number, state: FormatState, document: vscode.TextDocument): boolean {
	// 检查从第一行到当前行之间是否只有注释或空行
	for (let j = 0; j < lineIndex; j++) {
		const previousLine = document.lineAt(j).text.trim();
		if (previousLine === "") continue; // 跳过空行

		// 如果遇到非注释内容，说明不是文件头注释
		if (!state.inMultiLineComment) {
			//&& !previousLine.startsWith("<!---") && !previousLine.endsWith("--->") 這個條件是很奇怪的。
			// 應該是在這之前 如果發現有了---> 説明已經處理過了。
			if (previousLine.endsWith("--->")) {
				return false;
			}
		}
	}
	return true;
}

// 检查多行注释状态（仅对文件头注释）
function updateCommentState(text: string, lineIndex: number, state: FormatState, document: vscode.TextDocument): void {
	// 只处理文件开头的注释
	if (!isFileHeaderComment(lineIndex, state, document)) {
		return;
	}

	// 检查注释开始
	if (!state.inMultiLineComment && text.includes("<!---")) {
		state.inMultiLineComment = true;
	}

	// 检查注释结束
	if (state.inMultiLineComment && text.includes("--->")) {
		state.inMultiLineComment = false;
	}
}

// 格式化注释内容以实现对齐（仅文件头注释）
function formatCommentLine(text: string, lineIndex: number, state: FormatState, document: vscode.TextDocument): string {
	// 只格式化文件开头的注释
	if (!isFileHeaderComment(lineIndex, state, document)) {
		return text; // 方法内注释保持原样
	}

	const trimmed = text.trim();
	const indentChar = state.useSpaces ? " " : "\t";
	const indentUnit = state.useSpaces ? state.indentSize : 1;

	// 注释开始行：保持0缩进
	if (trimmed.startsWith("<!---")) {
		return trimmed;
	}

	// 注释结束行：保持0缩进
	if (trimmed.endsWith("--->")) {
		return trimmed;
	}

	// 注释内容行的格式化
	if (state.inMultiLineComment && trimmed !== "") {
		// 检查是否是标准的字段行（Name, Author, Created等）
		const fieldMatch = trimmed.match(/^(Name|Author|Created|Last Updated|History|Purpose)\s*:\s*(.*)$/);
		//　其他的内容的話 用這個正規表現。const fieldMatch = trimmed.match(/^([A-Z][A-Za-z\s]*?)\s*:\s*(.*)$/);
		if (fieldMatch) {
			const fieldName = fieldMatch[1];
			const fieldValue = fieldMatch[2];
			// 使用tab对齐，字段名后跟固定格式
			return indentChar.repeat(1 * indentUnit) + fieldName.padEnd(12) + " : " + fieldValue;
		}

		// 检查是否是History的续行（以日期开头）
		const historyMatch = trimmed.match(/^(\d{4}\/\d{2}\/\d{2})\s+(.*)$/);
		if (historyMatch) {
			const date = historyMatch[1];
			const content = historyMatch[2];
			// History续行：对齐到History字段的值位置
			return indentChar.repeat(1 * indentUnit) + "".padEnd(12) + "   " + date + " " + content;
		}

		// 检查是否是Author的续行（不以日期开头但可能是作者名）
		if (trimmed && !trimmed.includes(":") && !trimmed.match(/^\d{4}\/\d{2}\/\d{2}/)) {
			// 可能是Author的续行或其他字段的续行
			// 检查前一行是否是Author
			if (lineIndex > 0) {
				const prevLine = document.lineAt(lineIndex - 1).text.trim();
				if (prevLine.includes("Author") || prevLine.match(/^\s+\w+/)) {
					// 这可能是Author的续行，对齐到Author值的位置
					return indentChar.repeat(1 * indentUnit) + "".padEnd(12) + "   " + trimmed;
				}
			}
		}

		// 普通注释内容行
		return indentChar.repeat(1 * indentUnit) + trimmed;
	}

	return text;
}
