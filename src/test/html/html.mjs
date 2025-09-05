import { format } from "sql-formatter";
import {html_beautify} from "js-beautify"
import fs from "fs"
import path from "path";

try {

    let sql = ``

    const outputFile = path.resolve("", "temp.cfm");

    const result = format(sql, { language: "n1ql" })

    fs.writeFileSync(outputFile, result, "utf-8")
    console.log(result)
} catch (error) {
  console.log(error)
}