"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
function activate(context) {
    console.log('CFML Auto Formatter 插件已激活');
    const formatterProvider = vscode.languages.registerDocumentFormattingEditProvider('coldfusion', {
        provideDocumentFormattingEdits(document) {
            const edits = [];
            let indentLevel = 0;
            const indentSize = 2;
            let inCfscript = false;
            // CFML 标签
            const openingTags = ['<cffunction', '<cfif', '<cfloop', '<cfquery', '<cftry', '<cfscript', '<cfcomponent'];
            const closingTags = ['</cffunction>', '</cfif>', '</cfloop>', '</cfquery>', '</cftry>', '</cfscript>', '</cfcomponent>'];
            const selfClosingTags = ['<cfelse', '<cfelseif', '<cfset', '<cfreturn>'];
            for (let i = 0; i < document.lineCount; i++) {
                const line = document.lineAt(i);
                let text = line.text.trim();
                // 检测 cfscript 块
                if (text.startsWith('<cfscript')) {
                    inCfscript = true;
                }
                if (text.startsWith('</cfscript>')) {
                    inCfscript = false;
                    indentLevel = Math.max(indentLevel - 1, 0);
                }
                // 闭合标签减少缩进（除 cfscript 内部）
                if (!inCfscript && closingTags.some(tag => text.startsWith(tag))) {
                    indentLevel = Math.max(indentLevel - 1, 0);
                }
                const isSelfClosing = selfClosingTags.some(tag => text.startsWith(tag));
                const indent = ' '.repeat(indentLevel * indentSize);
                edits.push(vscode.TextEdit.replace(line.range, indent + text));
                // 开始标签增加缩进
                if (openingTags.some(tag => text.startsWith(tag)) && !isSelfClosing) {
                    indentLevel += 1;
                }
            }
            return edits;
        }
    });
    context.subscriptions.push(formatterProvider);
    // toggleLineComment 命令
    const toggleCommentCommand = vscode.commands.registerCommand('satt.cfml.toggleLineComment', () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor)
            return;
        editor.edit(editBuilder => {
            for (const selection of editor.selections) {
                const line = editor.document.lineAt(selection.start.line);
                const text = line.text;
                if (text.trim().startsWith('<!---')) {
                    // 去掉注释
                    const newText = text.replace('<!---', '').replace('--->', '');
                    editBuilder.replace(line.range, newText);
                }
                else {
                    // 添加注释
                    editBuilder.replace(line.range, `<!---${text}--->`);
                }
            }
        });
    });
    context.subscriptions.push(toggleCommentCommand);
}
function deactivate() { }
//# sourceMappingURL=extension.js.map