import * as vscode from "vscode";
import { writeLog } from "../utils/log";

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

					afterContent = afterContent + before + eol;
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
const cfAllTagsRegex = /<\s*(\/?)(cf\w+)\b([\s\S]*?)(\/?)>/gi;
function parseCFMLTags(cfmlCode: string) {
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
			isSelfClosing: isSelfClosing === "/",
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

function parseAttributes(attrString: string): Record<string, string> {
	const attributes: Record<string, string> = {};

	// 支持多种属性格式的正则表达式
	const attrRegex = /([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|(\w+))/gi;
	let attrMatch;

	while ((attrMatch = attrRegex.exec(attrString)) !== null) {
		const [, name, doubleQuoted, singleQuoted, unquoted] = attrMatch;
		const value = doubleQuoted || singleQuoted || unquoted || "";
		attributes[name] = value;
	}

	return attributes;
}

class ASTNode {
	private children: ASTNode[] = [];

	constructor(
		public readonly name: string,
		public readonly type: string,
		public range?: vscode.Range,
		public context?: string
	) {}

	// 添加子节点
	addChildren(node: ASTNode) {
		this.children.push(node);
	}

	// 删除指定索引的子节点
	removeChildren(i: number) {
		if (i >= 0 && i < this.children.length) {
			this.children.splice(i, 1);
		}
	}

	// 获取所有子节点（只读）
	getChildren(): readonly ASTNode[] {
		return this.children;
	}
}

class CFCNode extends ASTNode {
	constructor() {
		super("CFC", "cfcomponent");
	}
}

function createAST(
	// line: vscode.TextLine,
	// lineIndex: number,
	//edits: vscode.TextEdit[],
	//state: FormatState,
	document: vscode.TextDocument
): boolean {
	const root = new CFCNode();

	let currentTag = root;

	let stack: ASTNode[] = [root];
	for (let i = 0; i < document.lineCount; i++) {
		const originalText = document.lineAt(i).text;
		const trimText = originalText.trim();
		if (!trimText) continue;
		const matches = parseCFMLTags(trimText);
		let lastIndex = 0;
		if (matches.length) {
			matches.forEach((match) => {
				console.log(match);

				// 1. 取标签前面的“非标签内容”
				if (match.startIndex > lastIndex) {
					const before = trimText.slice(0, match.startIndex);
					console.log("前面非标签:", before);

					currentTag.context = currentTag.context + before;
				}
				// 2. 更新 lastIndex
				lastIndex = match.endIndex;

				const tagNode = new ASTNode(match.tagName, "cf-tag");
				tagNode.context = tagNode.context + match.fullMatch;
				currentTag.addChildren(tagNode);
				currentTag = tagNode;

				// 3. 最后可能还有剩余“非标签内容”
				if (lastIndex < trimText.length) {
					const after = trimText.slice(lastIndex);
					console.log("后面非标签:", after);
					currentTag.context = currentTag.context + after;
				}
			});
		} else {
			currentTag.context = currentTag.context + originalText;
		}
	}

	return true;
}
