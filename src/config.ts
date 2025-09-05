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
		en: "CFM files containing HTML, CSS, JS, etc. may not be formatted effectively. Are you sure you want to proceed?",
		"zh-cn": "CFM文件中如果含有html,css,js等，可能不能有效的格式化，你確定要執行嗎？",
		ja: "CFMファイルにHTML、CSS、JSなどが含まれている場合、効果的にフォーマットできない可能性があります。実行してもよろしいですか？",
	},
};
