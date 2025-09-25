import * as vscode from "vscode";
import { parseCFMLTags } from "./TagParser";
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
