import path from "path";
import * as vscode from "vscode";
import * as fs from "fs";

let logDir: string;
export function initLog(context: vscode.ExtensionContext) {
	logDir = vscode.Uri.joinPath(context.logUri, "logs").fsPath;
	if (!fs.existsSync(logDir)) {
		fs.mkdirSync(logDir, { recursive: true });
	}
}

function getLogFilePath(): string {
	const dateStr = new Date().toISOString().slice(0, 10);
	return path.join(logDir, `${dateStr}.log`);
}
export function writeLog(message: string) {
	const logFilePath = getLogFilePath();
	const timeStamp = new Date().toISOString();
	fs.appendFile(logFilePath, `[${timeStamp}:] ${message} \n`, (error) => {
		if (error) console.error("log的記錄不對", error);
	});
}
