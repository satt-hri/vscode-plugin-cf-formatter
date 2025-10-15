import * as peggy from "peggy";
import { readFileSync } from "fs";
import { join } from 'path';
import { examples } from "../../ast/test";

declare const __dirname: string;

try {
    // 文件就在当前目录下
    const grammarPath = join(__dirname, "cf_grammar.pegjs");
    const grammar = readFileSync(grammarPath, "utf8");
    console.log(peggy.VERSION)
    console.log(examples[1])
    const parser = peggy.generate(grammar);
    const ast = parser.parse(examples[6]);
    console.log(JSON.stringify(ast, null, 2));
    //console.log(ast);
} catch (error) {
    console.error("Parsing error:", error);
}