import * as vscode from "vscode";
import { Lang } from "../config";

export interface FormatState {
	lang: Lang;
	indentSize: number;
	useSpaces: boolean;

	indentLevel: number;
	globalIndent: number;

	inCfscript: boolean;
	inCfquery: boolean;
	inString: boolean;
	inMultiLineComment: boolean;

	sqlCaseStack: number[];
	sqlSubqueryStack: number[];
    tagStack: string[];
	bracketStack: string[];

}

export function createInitiaLState(): FormatState {
	return {
		lang: vscode.env.language as Lang,
		indentSize: 4,
		useSpaces: false,
		indentLevel: 0,
		globalIndent: 0,
		inCfscript: false,
		inCfquery: false,
		inString: false,
		inMultiLineComment: false,
		sqlCaseStack: [],
		sqlSubqueryStack: [],
        tagStack: [],
        bracketStack: [],
	};
}
