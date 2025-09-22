import * as vscode from "vscode";
import { FormatState } from "./FormatState";

//coldfusion 的话 下面的代码也是有效的。
// <   cfoutput>
//     123
// <   /           cfoutput    >

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

export function createAst(
	// line: vscode.TextLine,
	// lineIndex: number,
	edits: vscode.TextEdit[],
	state: FormatState,
	document: vscode.TextDocument
): boolean {
	const root = new CFCNode();

	// 开始标签（包括自闭合）
	const cfOpenTagRegex = /<\s*(cf\w+)\b[\s\S]*?(\/?)>/gi;

	// 结束标签
	const cfCloseTagRegex = /<\s*\/(cf\w+)\s*>/gi;

	const cfAllTagsRegex = /<\s*(\/?)(cf\w+)\b([\s\S]*?)(\/?)>/gi;

	let currentTag = root;

	let stack: ASTNode[] = [root];
	for (let i = 0; i < document.lineCount; i++) {
		const originalText = document.lineAt(i).text;
		const trimText = originalText.trim();
		if (!trimText) continue;
		const matches = [...trimText.matchAll(cfOpenTagRegex)];
		let lastIndex = 0;
		if (matches.length) {
			matches.forEach((match) => {
				console.log(match);

				// 1. 取标签前面的“非标签内容”
				if (match.index > lastIndex) {
					const before = trimText.slice(0, match.index);
					console.log("前面非标签:", before);

					currentTag.context = currentTag.context + before;
				}
				// 2. 更新 lastIndex
				lastIndex = match.index + match[0].length;

				const fullText = match[0];
				const tagName = match[1];
				const tagNode = new ASTNode(tagName, "cf-tag");
				tagNode.context = tagNode.context + fullText;
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
			currentTag.context = currentTag.context + trimText;
		}
	}

	return true;
}
