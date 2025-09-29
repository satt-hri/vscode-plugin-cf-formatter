import { FormatState } from "@/core/FormatState";
import { parseTagName } from "@/utils/common";
import * as vscode from "vscode";
import { coreOptions } from "./beautify/base_opitons";

export function formatCfset(
	line: vscode.TextLine,
	lineIndex: number,
	edits: vscode.TextEdit[],
	state: FormatState,
	document: vscode.TextDocument
): boolean {
	// 計算基礎縮進
	let text = line.text.trim();
	const { tagName } = parseTagName(text);
	if (tagName !== "cfset" || text.length == 0) {
		return false; // 只處理 cfset 標籤
	}

	const totalIndent = state.indentLevel;
	const baseIndent = coreOptions.indent_char!.repeat(totalIndent * coreOptions.indent_size!);

	//原來内容是一行
	if (/^<cfset\b.*\/?\s*>$/i.test(text)) {
		//console.log("cfset 單行:", lineIndex,text);
		edits.push(vscode.TextEdit.replace(line.range, baseIndent + text));
		return true; // 如果是单行 cfset，直接返回
	}
	// 只處理多參數的 cfset
	///^<cfset\b(?!.*>\s*$)/i
	if (/^<cfset\b(?!.*\/?\s*>\s*$)/i.test(text)) {
		//console.log("cfset d多行開始:", lineIndex, text);
		edits.push(vscode.TextEdit.replace(line.range, baseIndent + text));
		let index = lineIndex + 1;
		for (; index < document.lineCount; index++) {
			const templine = document.lineAt(index);
			const temText = templine.text.trim();

			if (/(?<!-)>$/.test(temText)) {
				edits.push(vscode.TextEdit.replace(templine.range, baseIndent + temText));
				//console.log("cfset 多行結束:", index, temText);
				break;
			}

			//console.log("cfset", index, temText);
			edits.push(
				vscode.TextEdit.replace(
					templine.range,
					baseIndent + coreOptions.indent_char!.repeat(coreOptions.indent_size!) + temText
				)
			);
		}
		(state.lastProcessLine = index), lineIndex;
		return true; // 如果是多行 cfset，直接返回
	}
	return false; // 緊急修正：暫時不處理多參數的 cfset
}

// 新增：檢查是否是多參數函數調用的 cfset
function isCfsetWithMultipleParams(text: string): boolean {
	console.log("檢查 cfset:", text);

	// 檢查是否是 cfset 且包含函數調用
	if (!text.toLowerCase().includes("<cfset ")) {
		console.log("不包含 <cfset");
		return false;
	}

	// 提取 cfset 內容部分
	const cfsetMatch = text.match(/<cfset\s+(.+?)(?:\s*\/?>|$)/i);
	if (!cfsetMatch) {
		console.log("cfset 正則匹配失敗");
		return false;
	}

	const content = cfsetMatch[1];
	console.log("cfset 內容:", content);

	// 檢查是否包含函數調用（有括號）
	if (!content.includes("(")) {
		console.log("不包含函數調用");
		return false;
	}

	// 計算參數數量（簡單計算逗號數量）
	const commaCount = (content.match(/,/g) || []).length;
	console.log("逗號數量:", commaCount);

	// 如果有2個或以上的逗號，表示有2個以上的參數
	const result = commaCount >= 2 && false; // 緊急修正：暫時不處理多參數的 cfset
	console.log("是否需要多行格式化:", result);
	return result;
}

// 新增：判斷是否在 cffunction 內部
function isInCffunction(state: FormatState): boolean {
	return state.tagStack.includes("cffunction");
}

// 新增：獲取特殊標籤的額外縮進
export function getSpecialTagIndent(tagName: string, state: FormatState): number {
	return 0; // 緊急修正：暫時不處理多參數的 cfset
	// if (blockTags.functionParam.includes(tagName)) {
	// 	// cfargument 應該與 cffunction 同級縮進 (實際上是 cffunction 的參數)
	// 	return 0;
	// } else if (blockTags.functionContent.includes(tagName)) {
	// 	// cfset 應該作為 cffunction 的內容，額外縮進一層
	// 	return isInCffunction(state) && false ? 1 : 0; // 緊急修正：暫時不處理多參數的 cfset
	// }
	// return 0;
}

// 新增：格式化多參數的 cfset
function formatCfsetMultiParams(text: string, baseIndent: number, state: FormatState): string[] {
	console.log("開始格式化多參數 cfset:", text);
	console.log("基礎縮進:", baseIndent);

	const cfsetMatch = text.match(/^(\s*<cfset\s+)(.+?)(\s*\/?>?\s*)$/i);
	if (!cfsetMatch) {
		console.log("cfset 格式化正則匹配失敗");
		return [text];
	}

	const prefix = cfsetMatch[1].trim();
	const content = cfsetMatch[2];
	const suffix = cfsetMatch[3].trim();

	console.log("prefix:", prefix);
	console.log("content:", content);
	console.log("suffix:", suffix);

	// 找到函數調用部分
	const funcMatch = content.match(/^(.+?)\.([^(]+)\s*\(\s*(.+?)\s*\)\s*(.*)$/);
	if (!funcMatch) {
		console.log("函數調用正則匹配失敗");
		return [text];
	}

	const objName = funcMatch[1];
	const funcName = funcMatch[2];
	const params = funcMatch[3];
	const afterFunc = funcMatch[4];

	console.log("objName:", objName);
	console.log("funcName:", funcName);
	console.log("params:", params);
	console.log("afterFunc:", afterFunc);

	// 分割參數
	const paramList = params.split(",").map((p) => p.trim());
	console.log("參數列表:", paramList);

	// 如果參數少於2個，保持原格式
	if (paramList.length < 2) {
		console.log("參數少於2個，保持原格式");
		return [text];
	}

	const indentChar = state.useSpaces ? " " : "\t";
	const indentUnit = state.useSpaces ? state.indentSize : 1;
	const currentIndent = indentChar.repeat(baseIndent * indentUnit);
	const paramIndent = indentChar.repeat((baseIndent + 1) * indentUnit);

	const lines: string[] = [];

	// 第一行：cfset + 對象.函數名(
	lines.push(currentIndent + `${prefix}${objName}.${funcName}(`);

	// 參數行
	paramList.forEach((param, index) => {
		const isLast = index === paramList.length - 1;
		const paramLine = isLast ? param : param + ",";
		lines.push(paramIndent + paramLine);
	});

	// 最後一行：) + suffix
	const lastLine = currentIndent + `)${afterFunc ? " " + afterFunc : ""}${suffix ? " " + suffix : " />"}`;
	lines.push(lastLine);

	console.log("格式化結果:", lines);
	return lines;
}
