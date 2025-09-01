import { FormatState } from "../core/FormatState";

// 改进的SQL缩进处理
export function getSqlIndent(text: string, lineIndex: number, state: FormatState): number {
	if (!state.inCfquery) return 0;

	const originalText = text;
	const upperText = text.toUpperCase().trim();
	let baseIndent = state.sqlSubqueryStack.length * 2;

	const caseDepth = state.sqlCaseStack.length; // 处理CASE WHEN ELSE END结构

	// 检查是否是SQL注释行
	if (originalText.trim().startsWith("<!---") || originalText.trim().endsWith("--->")) {
		return baseIndent;
	}

	const temp = compareBracket(text);
	if (temp === 1) {
		state.sqlSubqueryStack.push(baseIndent);
		//return baseIndent;
	} else if (temp === -1) {
		state.sqlSubqueryStack.pop();
		baseIndent = state.sqlSubqueryStack.length * 2;
	} else {
		if (/(.?)*\($/.test(text)) {
			return Math.max(baseIndent - 1, 0);
		}
	}

	const mainnKeywordsRegex = /^(SELECT|INSERT|UPDATE|DELETE|WITH)(?=\s|$)/i;
	if (
		mainnKeywordsRegex.test(upperText) ||
		upperText.startsWith("FROM") ||
		upperText.startsWith("WHERE") ||
		["ORDER BY", "GROUP BY", "HAVING", "UNION"].some((keyword) => upperText.startsWith(keyword))
	) {
		return baseIndent;
	}

	// CASE语句开始 - 与字段列表对齐
	if (upperText === "CASE" || upperText.startsWith(",CASE")) {
		state.sqlCaseStack.push(baseIndent);
	} else if (/\bEND\s+AS\b/.test(upperText)) {
		state.sqlCaseStack.pop();
	}

	// 表名等其他内容
	return baseIndent + 1 + caseDepth;
}

function compareBracket(text: string): number {
	const leftCount = (text.match(/\(/g) || []).length;
	const rightCount = (text.match(/\)/g) || []).length;

	if (leftCount > rightCount) {
		return 1; // 有更多左括号
	} else if (leftCount < rightCount) {
		return -1; // 有更多右括号
	} else {
		return 0; // 左右括号数量相等
	}
}
/*
	// 处理CASE WHEN ELSE END结构
	const caseDepth = state.sqlCaseStack.length;



	// WHEN 和 ELSE 与 CASE 对齐
	if (upperText.startsWith("WHEN ") || upperText === "ELSE") {
		if (caseDepth > 0) {
			return state.sqlCaseStack[state.sqlCaseStack.length - 1] + 1; // 比CASE多缩进1层
		}
		return baseIndent + 3;
	}

	// THEN 后面的值在同一行，但如果单独成行则缩进
	if (upperText.startsWith("THEN ") || (upperText.startsWith("ELSE ") && upperText !== "ELSE")) {
		// 这些通常不会单独成行，但如果有则与WHEN对齐
		if (caseDepth > 0) {
			return state.sqlCaseStack[state.sqlCaseStack.length - 1] + 1;
		}
		return baseIndent + 3;
	}

	// END语句 - 与CASE对齐
	if (upperText === "END" || upperText.startsWith("END ")) {
		if (state.sqlCaseStack.length > 0) {
			return state.sqlCaseStack.pop() || baseIndent;
		}
		return baseIndent + 2;
	}

	// 在CASE结构内的数值
	if (caseDepth > 0) {
		// 检查是否是纯数值或简单值
		if (/^\d+$/.test(upperText) || upperText === "''" || upperText.match(/^'.*'$/)) {
			return state.sqlCaseStack[state.sqlCaseStack.length - 1] + 1;
		}
	}


	// JOIN语句 mysqlを参照
	// if (
	// 	upperText.includes("JOIN") &&
	// 	(upperText.startsWith("INNER ") ||
	// 		upperText.startsWith("LEFT ") ||
	// 		upperText.startsWith("RIGHT ") ||
	// 		upperText.startsWith("FULL ") ||
	// 		upperText.startsWith("CROSS ") ||
	// 		upperText.startsWith("JOIN"))
	// ) {
	// 	return baseIndent + 1;
	// }

	// // ON子句（JOIN条件）
	// if (upperText.startsWith("ON(") || upperText.startsWith("ON ")) {
	// 	return baseIndent + 1;
	// }

	// // AND/OR条件
	// if (upperText.startsWith("AND ") || upperText.startsWith("OR ")) {
	// 	return baseIndent + 1;
	// }

	// // 字段列表 - 所有字段（包括第一个）都缩进到相同层级
	// if (upperText.startsWith(",")) {
	// 	return baseIndent + 1;
	// }


*/
