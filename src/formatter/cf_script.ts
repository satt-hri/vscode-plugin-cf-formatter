import { FormatState } from "../core/FormatState";

// 处理cfscript内的大括号
export function processCfscriptBrackets(text: string, state: FormatState): number {
	if (!state.inCfscript || state.inString) return 0;

	let bracketChange = 0;
	updateStringState(text, state);

	for (let i = 0; i < text.length; i++) {
		if (!state.inString) {
			const char = text[i];
			if (char === "{") {
				state.bracketStack.push("{");
				bracketChange++;
			} else if (char === "}") {
				if (state.bracketStack.length > 0 && state.bracketStack[state.bracketStack.length - 1] === "{") {
					state.bracketStack.pop();
					bracketChange--;
				}
			}
		}
	}

	return bracketChange;
}
let stringChar = "";
// 检查字符串状态
export function updateStringState(text: string, state: FormatState) {
	for (let i = 0; i < text.length; i++) {
		const char = text[i];

		if (!state.inString) {
			if (char === '"' || char === "'") {
				state.inString = true;
				stringChar = char;
			}
		} else {
			if (char === stringChar && text[i - 1] !== "\\") {
				state.inString = false;
				stringChar = "";
			}
		}
	}
}
