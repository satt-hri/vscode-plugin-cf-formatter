import { CoreBeautifyOptions } from "js-beautify";
import * as vscode from "vscode";

const config = vscode.workspace.getConfiguration("hri.cfml.formatter");

//tab缩进 が優先
const useTab = config.get<boolean>("indentWithTabs", true);

export const coreOptions: CoreBeautifyOptions = {
	indent_size: useTab ? 1 : config.get<number>("indentSize", 4),
	indent_char: useTab ? "\t" : " ",
	max_preserve_newlines: config.get<number>("maxPreserveNewlines", 1),
	preserve_newlines:
		config.get<number>("maxPreserveNewlines", 1) == -1 ? false : config.get<boolean>("preserveNewlines", true),
	end_with_newline: config.get<boolean>("endWithNewline", false),
	wrap_line_length: config.get<number>("wrapLineLength", 0), // 0 means no limit
	indent_empty_lines: false,
};
