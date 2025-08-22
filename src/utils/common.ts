// 扩展的标签定义
export const blockTags = {
	opening: [
		"cffunction",
		"cfif",
		"cfloop",
		"cfquery",
		"cftry",
		"cfcatch",
		"cfscript",
		"cfcomponent",
		"cfoutput",
		"cfswitch",
		"cfcase",
		"cfsavecontent",
		"cfthread",
		"cflock",
		"cftransaction",
		"cfform",
		"cftable",
		"cfselect",
	],
	closing: [
		"cffunction",
		"cfif",
		"cfloop",
		"cfquery",
		"cftry",
		"cfcatch",
		"cfcomponent",
		"cfoutput",
		"cfswitch",
		"cfcase",
		"cfsavecontent",
		"cfthread",
		"cflock",
		"cftransaction",
		"cfform",
		"cftable",
		"cfselect",
	],
	elselike: ["cfelse", "cfelseif", "cfdefaultcase"],
	selfClosing: [
		"cfreturn",
		"cfbreak",
		"cfcontinue",
		"cfthrow",
		"cfinclude",
		"cfmodule",
		"cfinvoke",
		"cfparam",
		"cfheader",
		"cfcookie",
		"cflocation",
		"cfmail",
		"cffile",
		"cfdirectory",
		"cfhttp",
		"cfzip",
		"cfimage",
		"cfdocument",
		"cfpdf",
	],
	// 新增：需要特殊處理的標籤
	functionParam: ["cfargument"], // 函数参数标签
	functionContent: ["cfset"], // 函数内容标签
};

const sqlKeywords = [
	"SELECT",
	"FROM",
	"WHERE",
	"AND",
	"OR",
	"INNER JOIN",
	"LEFT JOIN",
	"RIGHT JOIN",
	"FULL JOIN",
	"ORDER BY",
	"GROUP BY",
	"HAVING",
	"INSERT",
	"UPDATE",
	"DELETE",
	"VALUES",
	"SET",
	"INTO",
	"UNION",
	"UNION ALL",
	"CASE",
	"WHEN",
	"THEN",
	"ELSE",
	"END",
];

// 解析标签名
export function parseTagName(line: string): { tagName: string; isClosing: boolean; isSelfClosing: boolean } {
	const trimmed = line.trim();

	// 处理结束标签
	if (trimmed.startsWith("</")) {
		const match = trimmed.match(/<\/([^>\s]+)/);
		return {
			tagName: match ? match[1].toLowerCase() : "",
			isClosing: true,
			isSelfClosing: false,
		};
	}

	// 处理开始标签
	if (trimmed.startsWith("<")) {
		const match = trimmed.match(/<([^>\s]+)/);
		const tagName = match ? match[1].toLowerCase() : "";
		const isSelfClosing =
			trimmed.endsWith("/>") ||
			blockTags.selfClosing.includes(tagName) ||
			blockTags.functionParam.includes(tagName) ||
			blockTags.functionContent.includes(tagName) ||
			(tagName.startsWith("cf") &&
				(trimmed.includes(" />") || (!trimmed.includes(">") && !blockTags.opening.includes(tagName))));

		return {
			tagName,
			isClosing: false,
			isSelfClosing,
		};
	}

	return { tagName: "", isClosing: false, isSelfClosing: false };
}
