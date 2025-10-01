
import type { FormattingOptions } from 'vscode';

export type BeautifyType = "script" | "html" | "css";


export interface ExtendedFormattingOptions extends FormattingOptions {
    flag: BeautifyType;
}