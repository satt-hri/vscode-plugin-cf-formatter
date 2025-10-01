export type Lang = "en" | "zh-cn" | "ja";

type MessageValue = string | ((...args: any[]) => string);
type MessageMap = {
	[key: string]: Record<Lang, MessageValue>;
};

export const messages: MessageMap = {
	langInfo: {
		en: (languageId: string, fileName: string) => `Language ID: ${languageId}, File: ${fileName}`,
		"zh-cn": (languageId: string, fileName: string) => `语言ID: ${languageId}, 文件: ${fileName}`,
		ja: (languageId: string, fileName: string) => `言語ID: ${languageId}, ファイル: ${fileName}`,
	},
	noEditor: {
		en: "No active editor",
		"zh-cn": "没有活动的编辑器",
		ja: "アクティブなエディターがありません",
	},
	formatDone: {
		en: "Format completed!",
		"zh-cn": "格式化完成！",
		ja: "フォーマットが完了しました！",
	},
	noContent: {
		en: "No content to format",
		"zh-cn": "没有需要格式化的内容",
		ja: "フォーマットする内容がありません",
	},
	formatError: {
		en: (error: any) => `Format failed: ${error}`,
		"zh-cn": (error: any) => `格式化失败: ${error}`,
		ja: (error: any) => `フォーマットに失敗しました: ${error}`,
	},
	warnMsg: {
		en: "If you execute full formatting, CFM files containing HTML(xml), CSS, JS, etc. may not be formatted effectively. Are you sure you want to proceed? Alternatively, you can choose partial formatting for more controlled scope.",
		"zh-cn": "执行全部格式化的话，CFM文件中如果含有html(xml),css,js等，可能不能有效的格式化，你确定要执行吗？或者可以选择局部格式化，范围更加可控",
		ja: "全体フォーマットを実行すると、CFMファイルにHTML(xml)、CSS、JSなどが含まれている場合、効果的にフォーマットできない可能性があります。本当に実行しますか？あるいは部分的なフォーマットを選択して、範囲をより制御することもできます。",
	},
	blockTagWarn: {
		en: "Since formatting is applied by block tags, please select within the block CF tag range.",
		"zh-cn": "由于是按块标签进行格式化的，请选择块级 CF 标签范围。",
		ja: "ブロックタグ単位でフォーマットしているため、ブロックCFタグの範囲を選択してください。",
	},
};
