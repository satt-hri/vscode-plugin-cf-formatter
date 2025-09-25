import * as vscode from "vscode";
import { writeLog } from "../utils/log";
import { blockTags } from "../utils/common";

//coldfusion 的话 下面的代码也是有效的。
// <   cfoutput>
//     123
// <   /           cfoutput    >

export function autoTagWrapping(document: vscode.TextDocument): vscode.TextEdit[] {
	const edits: vscode.TextEdit[] = [];
	const eol = document.eol === vscode.EndOfLine.CRLF ? "\r\n" : "\n";

	for (let i = 0; i < document.lineCount; i++) {
		const original = document.lineAt(i);
		const trimText = original.text.trim();
		if (!trimText) continue;
		const matches = parseCFMLTags(trimText);

		let afterContent = "";
		let lastIndex = 0;

		if (matches.length) {
			matches.forEach((match, index) => {
				console.log(match);

				// 1. 取标签前面的“非标签内容”
				if (match.startIndex > lastIndex) {
					const before = trimText.slice(lastIndex, match.startIndex);
					console.log("前面非标签:", before);
					if (before.trim().length > 0) {
						afterContent = afterContent + before + eol;
					}
				}
				// 2. 更新 lastIndex
				lastIndex = match.endIndex;

				afterContent = afterContent + match.fullMatch + eol;

				// 3. 最后可能还有剩余“非标签内容”
				if (matches.length == index + 1 && lastIndex < trimText.length) {
					const after = trimText.slice(lastIndex);
					console.log("后面非标签:", after);
					afterContent = afterContent + after;
				}
			});

			writeLog("autoTagWrapping_before:" + original);
			writeLog("autoTagWrapping_after:" + afterContent);

			//假如内容没有变化的话，也就是本来就是独立的一行的情况下。
			if (trimText == afterContent.trim()) {
				continue;
			}
			edits.push(vscode.TextEdit.replace(original.range, afterContent.trim())); //因为是独立的一行，左右如果存在换行是不对的。
		}
	}

	return edits;
}

// 开始标签（包括自闭合）
const cfOpenTagRegex = /<\s*(cf\w+)\b[\s\S]*?(\/?)>/gi;
// 结束标签
const cfCloseTagRegex = /<\s*\/(cf\w+)\s*>/gi;
// 统一的CFML标签正则表达式
//const cfAllTagsRegex = /<\s*(\/?)(cf\w+)\b([\s\S]*?)(\/?)>/gi; 字符串中如果有 > 会有问题。
const cfAllTagsRegex = /<\s*(\/?)(cf\w+)\b((?:'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"|[^>"'])*)(\/?)\s*>/gi;

export function parseCFMLTags(cfmlCode: string) {
	const tags = [];
	let match;

	// 重置正则表达式的lastIndex
	cfAllTagsRegex.lastIndex = 0;

	while ((match = cfAllTagsRegex.exec(cfmlCode)) !== null) {
		const [fullMatch, isClosing, tagName, attributes, isSelfClosing] = match;

		const tagInfo = {
			fullMatch: fullMatch,
			tagName: tagName,
			isClosing: isClosing === "/",
			isSelfClosing: isSelfClosing === "/" || blockTags.selfClosing.includes(tagName),
			attributes: attributes.trim(),
			startIndex: match.index,
			endIndex: match.index + fullMatch.length,
			parsedAttributes: {},
		};

		// 解析属性（仅对开始标签）
		if (!tagInfo.isClosing && tagInfo.attributes) {
			tagInfo.parsedAttributes = parseAttributes(tagInfo.attributes);
		}

		tags.push(tagInfo);
	}

	return tags;
}

export function parseAttributes(attrString: string): Record<string, string> {
	const attributes: Record<string, string> = {};

	// 支持多种属性格式的正则表达式
	// /([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|(\w+))/gi;
	const attrRegex = /([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(?:"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)'|(\w+))/gi;
	let attrMatch;

	while ((attrMatch = attrRegex.exec(attrString)) !== null) {
		const [, name, doubleQuoted, singleQuoted, unquoted] = attrMatch;
		const value = doubleQuoted || singleQuoted || unquoted || "";
		attributes[name] = value;
	}

	return attributes;
}

class CFTagParser {
	private pos: number = 0;
	private input: string = "";
	private tags: Record<string, any>[] = [];
	constructor() {
		this.reset();
	}

	reset() {
		this.pos = 0;
		this.input = "";
		this.tags = [];
	}

	parse(input: string) {
		this.input = input;
		this.pos = 0;
		this.tags = [];

		while (this.pos < this.input.length) {
			const tagStart = this.input.indexOf("<", this.pos);
			if (tagStart === -1) break;

			this.pos = tagStart;
			const tag = this.parseTag();
			if (tag) {
				this.tags.push(tag);
			} else {
				this.pos++;
			}
		}

		return this.tags;
	}

	parseTag() {
		if (this.pos >= this.input.length || this.input[this.pos] !== "<") {
			return null;
		}

		const start = this.pos;
		this.pos++; // 跳过 <

		// 跳过空白
		this.skipWhitespace();

		// 检查是否是结束标签
		const isClosing = this.peek() === "/";
		if (isClosing) {
			this.pos++;
			this.skipWhitespace();
		}

		// 检查是否是cf标签
		const tagNameMatch = this.input.substring(this.pos).match(/^(cf\w+)/i);
		if (!tagNameMatch) {
			this.pos = start + 1;
			return null;
		}

		const tagName = tagNameMatch[1];
		this.pos += tagName.length;

		// 解析属性
		const attributes = this.parseAttributes();
		if (attributes === null) {
			// 解析失败，可能不是有效标签
			this.pos = start + 1;
			return null;
		}

		// 检查自闭合
		this.skipWhitespace();
		const isSelfClosing = this.peek() === "/" && this.peek(1) === ">";
		if (isSelfClosing) {
			this.pos += 2;
		} else if (this.peek() === ">") {
			this.pos++;
		} else {
			// 无效标签
			this.pos = start + 1;
			return null;
		}

		const end = this.pos;

		return {
			fullMatch: this.input.substring(start, end),
			isClosing,
			tagName: tagName.toLowerCase(),
			attributes: attributes.trim(),
			isSelfClosing,
			start,
			end,
		};
	}

	parseAttributes() {
		let attributes = "";

		while (this.pos < this.input.length) {
			this.skipWhitespace();

			const char = this.peek();

			if (char === ">" || (char === "/" && this.peek(1) === ">")) {
				// 标签结束
				break;
			} else if (char === '"') {
				// 双引号字符串
				const str = this.parseString('"');
				if (str === null) return null;
				attributes += str;
			} else if (char === "'") {
				// 单引号字符串
				const str = this.parseString("'");
				if (str === null) return null;
				attributes += str;
			} else if (char === "<") {
				// 遇到新的标签开始，当前标签可能无效
				return null;
			} else {
				// 普通字符
				attributes += char;
				this.pos++;
			}
		}

		return attributes;
	}

	parseString(quote: string) {
		if (this.peek() !== quote) return null;

		let result = quote;
		this.pos++; // 跳过开始引号

		while (this.pos < this.input.length) {
			const char = this.peek();

			if (char === quote) {
				result += char;
				this.pos++;
				return result;
			} else if (char === "\\") {
				// 处理转义字符
				result += char;
				this.pos++;
				if (this.pos < this.input.length) {
					result += this.peek();
					this.pos++;
				}
			} else {
				result += char;
				this.pos++;
			}
		}

		// 未闭合的字符串
		return null;
	}

	skipWhitespace() {
		while (this.pos < this.input.length && /\s/.test(this.input[this.pos])) {
			this.pos++;
		}
	}

	peek(offset = 0) {
		const pos = this.pos + offset;
		return pos < this.input.length ? this.input[pos] : "";
	}
}
