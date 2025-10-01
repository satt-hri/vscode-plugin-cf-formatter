import { FormatState } from "@/core/FormatState";
import { HTMLBeautifyOptions, html_beautify } from "js-beautify";
import { writeLog } from "@/utils/log";
import { coreOptions } from "./base_opitons";

export const htmlOptions: HTMLBeautifyOptions = {
	...coreOptions,
	//html配置开始
};

export function formatRangeHtml(state: FormatState, scriptContent: string): string {
	try {
		let formattedCode = html_beautify(scriptContent, htmlOptions);
		writeLog("formatRangeHtml_script_formattedCode:" + formattedCode);

		// 为格式化后的每行添加适当的缩进
		const indentedLines = formattedCode
			.split("\n")
			.map((line) => (line.trim() ? state.rangeLeftSpace + line : line))
			.join("\n");

		return indentedLines;
	} catch (error) {
		console.error("格式化 formatRangeHtml 时出错:", error);
		writeLog("formatRangeHtml__script_error:" + String(error));
		return "";
	}
}
