
const fs = require("fs");
const path = require("path");
const sqlFormatter = require("sql-formatter");

function formatCFQuery(cfqueryContent) {
    let placeholders = [];
    let index = 0;
    console.log("cfqueryContent", cfqueryContent)
    // 1. 替换 CF 标签为占位符
    const sqlWithPlaceholders = cfqueryContent.replace(
        /<cf.*?>[\s\S]*?<\/cf.*?>|<cf.*?\/>/gi,
        (match) => {
            const key = `__CFBLOCK${index}__`;
            placeholders.push({ key, value: match });
            index++;
            return key;
        }
    ).replace(
        /#[^#]+#/g,
        (match) => {
            const key = `__CFEXPR${index}__`;
            placeholders.push({ key, value: match });
            index++;
            return key;
        }
    ).replace(/<!---[\s\S]*?--->/g, (match) => {
        const key = `__CFCOMMENT${index}__`;
        placeholders.push({ key, value: match });
        index++;
        return key;
    });

    // 2. 格式化 SQL
    let formattedSQL;
    console.log("placeholders", placeholders)
    try {
        formattedSQL = sqlFormatter.format(sqlWithPlaceholders,
            { language: "mysql", keywordCase: "upper", useTabs: true, expressionWidth: 1 });
        console.log("formattedSQL", formattedSQL)
    } catch (e) {
        console.error("SQL 格式化失败，返回原始内容");
        console.log(e)
        formattedSQL = sqlWithPlaceholders;
    }

    // 3. 替换回 CF 标签
    placeholders.forEach(({ key, value }) => {
        formattedSQL = formattedSQL.replace(key, value);
    });

    return formattedSQL;
}


function formatCFMLFile(filePath) {
    const content = fs.readFileSync(filePath, "utf-8");

    // 正则匹配 <cfquery>...</cfquery>
    const formattedContent = content.replace(/<cfquery\b[^>]*>[\s\S]*?<\/cfquery>/gi, (match) => {
        console.log(match)
        const innerSQL = match
            .replace(/^<cfquery\b[^>]*>/i, "")
            .replace(/<\/cfquery>$/i, "");

        const formattedSQL = formatCFQuery(innerSQL);
        const formattedSQL1 = formattedSQL
            .split("\n")
            .map(line => "\t\t\t" + line)  // 三个 tab
            .join("\n");
        console.log("formattedSQL1", formattedSQL1);

        const openTag = match.match(/^<cfquery\b[^>]*>/i)[0];
        return `${openTag}\n${formattedSQL1}\n</cfquery>`;
    });

    return formattedContent;
}

// ------------------- 测试 -------------------
const inputFile = path.resolve(__dirname, "test.cfc");
const outputFile = path.resolve(__dirname, "example_formatted.cfm");

const result = formatCFMLFile(inputFile);
fs.writeFileSync(outputFile, result, "utf-8");

console.log("格式化完成，输出到:", outputFile);