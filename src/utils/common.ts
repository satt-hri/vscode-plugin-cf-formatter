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
		"cfdefaultcase",
		"cfsavecontent",
		"cfthread",
		"cflock",
		"cftransaction",
		"cfform",
		"cftable",
		"cfselect",
		"cfinvoke",
		"cfhttp",
		"cfmail",
		"cfsilent",
		"cfstoredproc",
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
		"cfdefaultcase",
		"cfsavecontent",
		"cfthread",
		"cflock",
		"cftransaction",
		"cfform",
		"cftable",
		"cfselect",
		"cfinvoke",
		"cfhttp",
		"cfmail",
		"cfsilent",
		"cfstoredproc",
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
		"cffile",
		"cfdirectory",
		"cfzip",
		"cfimage",
		"cfdocument",
		"cfpdf",
		"cfinvokearguments",
		"cfset",
		"cfhttpparam",
		"cfprocparam",
		"cfzipparam",
	],
	onlyIndex: ["cfprocessingdirective"], // 函数内容标签
};

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
		const selfLineClosing =
			trimmed.startsWith(`<${tagName}`) &&
			(trimmed.endsWith(`</${tagName}>`) || trimmed.endsWith(`</${tagName}>,`));

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
			blockTags.selfClosing.includes(tagName) ||
			/^\s*<(cf\w+)\b[^>]*>.*<\/\1>\s*$/i.test(trimmed) ||
			/^<cf\w+\b[^>]*\/>$/i.test(trimmed);
		const selfLineClosing =
			trimmed.startsWith(`<${tagName}`) &&
			(trimmed.endsWith(`</${tagName}>`) || trimmed.endsWith(`</${tagName}>,`));

		return {
			tagName,
			isClosing: false,
			isSelfClosing,
			selfLineClosing: selfLineClosing,
		};
	}

	return { tagName: "", isClosing: false, isSelfClosing: false, selfLineClosing: false };
}

export function getLeadingSpacesCount(str: string): number {
	return str.length - str.trimStart().length;
}
