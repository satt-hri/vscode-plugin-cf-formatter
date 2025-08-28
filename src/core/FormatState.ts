import * as vscode from "vscode";
import { Lang } from "../config";

export interface FormatState {
	lang: Lang;
	indentSize: number;
	useSpaces: boolean;

	indentLevel: number;
	lastProcessLine: number;

	inCfquery: boolean;
	inString: boolean;
	inMultiLineComment: boolean;

	sqlCaseStack: number[];
	sqlSubqueryStack: number[];
	tagStack: string[];
}

export function createInitiaLState(): FormatState {
	// 读取用户配置
	const config = vscode.workspace.getConfiguration("hri.cfml.formatter");
	const useTab = config.get<boolean>("indentWithTabs", true);

	return {
		lang: vscode.env.language as Lang,
		indentSize: useTab ? 1 : config.get<number>("indentSize", 4),
		useSpaces: useTab ? false : true,
		indentLevel: 0,
		lastProcessLine: 0,
		inCfquery: false,
		inString: false,
		inMultiLineComment: false,
		sqlCaseStack: [],
		sqlSubqueryStack: [],
		tagStack: [],
	};
}
