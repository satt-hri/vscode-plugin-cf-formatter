import { FormatState } from "@/core/FormatState";
import { CSSBeautifyOptions, css_beautify } from "js-beautify";
import { writeLog } from "@/utils/log";
import { coreOptions } from "./base_opitons";

const cssOptions: CSSBeautifyOptions = {
	...coreOptions,
	//css配置开始
};


export function formatRangeCss(state: FormatState, scriptContent: string): string {
	try {
		let formattedCode = css_beautify(scriptContent, cssOptions);
		writeLog("formatRangeCss_formattedCode:" + formattedCode);

		// 为格式化后的每行添加适当的缩进
		const indentedLines = formattedCode
			.split("\n")
			.map((line) => (line.trim() ? state.rangeLeftSpace + line : line))
			.join("\n");

		return indentedLines;
	} catch (error) {
		console.error("格式化 formatRangeCss 时出错:", error);
		writeLog("formatRangeCss_error:" + String(error));
		return "";
	}
}
