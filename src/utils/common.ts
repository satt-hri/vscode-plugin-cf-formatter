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
		"cfinvoke",
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
		"cfinvoke",
	],
	elselike: ["cfelse", "cfelseif", "cfdefaultcase"],
	selfClosing: [
		"cfargument",
		"cfreturn",
		"cfbreak",
		"cfcontinue",
		"cfthrow",
		"cfinclude",
		"cfmodule",
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
		"cfinvokearguments",
		"cfset",
	],
	//functionContent: ["cfset"], // 函数内容标签
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
export function parseTagName(line: string): {
	tagName: string;
	isClosing: boolean;
	isSelfClosing: boolean;
	selfLineClosing: boolean; //query 中的cfif
} {
	const trimmed = line.trim();

	// 处理结束标签
	if (trimmed.startsWith("</")) {
		const match = trimmed.match(/<\/([^>\s]+)/);
		const tagName = match ? match[1].toLowerCase() : "";
		const selfLineClosing = trimmed.startsWith(`<${tagName}`) && trimmed.endsWith(`${tagName}/>`);

		return {
			tagName: tagName,
			isClosing: true,
			isSelfClosing: false,
			selfLineClosing: selfLineClosing,
		};
	}

	// 处理开始标签
	if (trimmed.startsWith("<")) {
		const match = trimmed.match(/<([^>\s]+)/);
		const tagName = match ? match[1].toLowerCase() : "";
		const isSelfClosing =
			blockTags.selfClosing.includes(tagName) || /^\s*<(cf\w+)\b[^>]*>.*<\/\1>\s*$/i.test(trimmed);
		const selfLineClosing = trimmed.startsWith(`<${tagName}`) && trimmed.endsWith(`</${tagName}>`);

		return {
			tagName,
			isClosing: false,
			isSelfClosing,
			selfLineClosing: selfLineClosing,
		};
	}

	return { tagName: "", isClosing: false, isSelfClosing: false, selfLineClosing: false };
}
