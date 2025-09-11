import * as vscode from "vscode";

/**
 * autoCloseTag.enable          auto-close-tag
 * html.autoClosingTags          VS Code 内置       HTML 自动闭合功能
 * cfml.autoCloseTags.enable     CFML               ColdFusion 专用扩展
 */

type AutoCloseStates = {
	autoCloseTag: boolean | undefined;
	autoCloseSelfClosing: boolean | undefined;
	cfmlAutoClose: boolean | undefined;
};

const tag1 = "auto-close-tag.enableAutoCloseTag";
const tag2 = "auto-close-tag.enableAutoCloseSelfClosingTag";
const tag3 = "cfml.autoCloseTags.enable";

// 辅助函数：禁用 auto-close-tag
export async function disableAutoCloseTag() {
	const config = vscode.workspace.getConfiguration();
	const states: AutoCloseStates = {
		autoCloseTag: config.get(tag1),
		autoCloseSelfClosing: config.get(tag2),
		cfmlAutoClose: config.get(tag3),
	};
	if (states.autoCloseTag !== undefined) {
		await config.update(tag1, false, vscode.ConfigurationTarget.Global);
	}
	if (states.autoCloseSelfClosing !== undefined) {
		// 新增
		await config.update(tag2, false, vscode.ConfigurationTarget.Global);
	}
	if (states.cfmlAutoClose !== undefined) {
		await config.update(tag3, false, vscode.ConfigurationTarget.Global);
	}
	return states;
}

export async function restoreAutoCloseTag(states: AutoCloseStates) {
	const config = vscode.workspace.getConfiguration();
	if (states.autoCloseTag !== undefined) {
		await config.update(tag1, states.autoCloseTag, vscode.ConfigurationTarget.Global);
	}
	if (states.autoCloseSelfClosing !== undefined) {
		await config.update(tag2, states.autoCloseSelfClosing, vscode.ConfigurationTarget.Global);
	}
	if (states.cfmlAutoClose !== undefined) {
		await config.update(tag3, states.cfmlAutoClose, vscode.ConfigurationTarget.Global);
	}
}
