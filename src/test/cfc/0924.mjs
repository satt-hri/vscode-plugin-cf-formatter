// 方案1: 改进的正则表达式 - 考虑引号内的内容
const cfTagsRegexImproved = /<\s*(\/?)(cf\w+)\b((?:[^>"']|"[^"]*"|'[^']*')*)(\/?)\s*>/gi;

// 方案2: 更精确的正则 - 处理嵌套引号和转义
function createCFTagRegex() {
    // 匹配单引号字符串 (处理转义)
    const singleQuoted = `'(?:[^'\\\\]|\\\\.)*'`;
    // 匹配双引号字符串 (处理转义)
    const doubleQuoted = `"(?:[^"\\\\]|\\\\.)*"`;
    // 匹配非引号、非>的字符
    const unquoted = `[^>"']`;
    
    // 组合：属性部分可以包含字符串或非引号字符
    const attributes = `(?:${singleQuoted}|${doubleQuoted}|${unquoted})*`;
    
    return new RegExp(`<\\s*(\\/?)(cf\\w+)\\b(${attributes})(\\/?)\\s*>`, 'gi');
}

// 方案3: 状态机解析器 (最可靠)
class CFTagParser {
    constructor() {
        this.reset();
    }
    
    reset() {
        this.pos = 0;
        this.input = '';
        this.tags = [];
    }
    
    parse(input) {
        this.input = input;
        this.pos = 0;
        this.tags = [];
        
        while (this.pos < this.input.length) {
            const tagStart = this.input.indexOf('<', this.pos);
            if (tagStart === -1) break;
            
            this.pos = tagStart;
            const tag = this.parseTag();
            if (tag) {
                this.tags.push(tag);
            } else {
                this.pos++;
            }
        }
        
        return this.tags;
    }
    
    parseTag() {
        if (this.pos >= this.input.length || this.input[this.pos] !== '<') {
            return null;
        }
        
        const start = this.pos;
        this.pos++; // 跳过 <
        
        // 跳过空白
        this.skipWhitespace();
        
        // 检查是否是结束标签
        const isClosing = this.peek() === '/';
        if (isClosing) {
            this.pos++;
            this.skipWhitespace();
        }
        
        // 检查是否是cf标签
        const tagNameMatch = this.input.substring(this.pos).match(/^(cf\w+)/i);
        if (!tagNameMatch) {
            this.pos = start + 1;
            return null;
        }
        
        const tagName = tagNameMatch[1];
        this.pos += tagName.length;
        
        // 解析属性
        const attributes = this.parseAttributes();
        if (attributes === null) {
            // 解析失败，可能不是有效标签
            this.pos = start + 1;
            return null;
        }
        
        // 检查自闭合
        this.skipWhitespace();
        const isSelfClosing = this.peek() === '/' && this.peek(1) === '>';
        if (isSelfClosing) {
            this.pos += 2;
        } else if (this.peek() === '>') {
            this.pos++;
        } else {
            // 无效标签
            this.pos = start + 1;
            return null;
        }
        
        const end = this.pos;
        
        return {
            fullMatch: this.input.substring(start, end),
            isClosing,
            tagName: tagName.toLowerCase(),
            attributes: attributes.trim(),
            isSelfClosing,
            start,
            end
        };
    }
    
    parseAttributes() {
        let attributes = '';
        
        while (this.pos < this.input.length) {
            this.skipWhitespace();
            
            const char = this.peek();
            
            if (char === '>' || (char === '/' && this.peek(1) === '>')) {
                // 标签结束
                break;
            } else if (char === '"') {
                // 双引号字符串
                const str = this.parseString('"');
                if (str === null) return null;
                attributes += str;
            } else if (char === "'") {
                // 单引号字符串
                const str = this.parseString("'");
                if (str === null) return null;
                attributes += str;
            } else if (char === '<') {
                // 遇到新的标签开始，当前标签可能无效
                return null;
            } else {
                // 普通字符
                attributes += char;
                this.pos++;
            }
        }
        
        return attributes;
    }
    
    parseString(quote) {
        if (this.peek() !== quote) return null;
        
        let result = quote;
        this.pos++; // 跳过开始引号
        
        while (this.pos < this.input.length) {
            const char = this.peek();
            
            if (char === quote) {
                result += char;
                this.pos++;
                return result;
            } else if (char === '\\') {
                // 处理转义字符
                result += char;
                this.pos++;
                if (this.pos < this.input.length) {
                    result += this.peek();
                    this.pos++;
                }
            } else {
                result += char;
                this.pos++;
            }
        }
        
        // 未闭合的字符串
        return null;
    }
    
    skipWhitespace() {
        while (this.pos < this.input.length && /\s/.test(this.input[this.pos])) {
            this.pos++;
        }
    }
    
    peek(offset = 0) {
        const pos = this.pos + offset;
        return pos < this.input.length ? this.input[pos] : '';
    }
}

// 测试用例
const testCases = [
    `<cfset var invalidPattern = '[\\\\/:*?"<>|]' />`,
    `<cfset message = "Hello <world>" />`,
    `<cfif name EQ 'John "The Great" Smith'>`,
    `<cfoutput>Name: #user.name#</cfoutput>`,
    `<cfquery name="users">
        SELECT * FROM users WHERE status = 'active'
    </cfquery>`,
    `<cfloop index="i" from="1" to="10">`,
    `</cfloop>`,
    `<cfset complexString = 'It\\'s a "test" with <brackets>' />`,
    `<!-- This is not a CF tag -->`,
    `<div>This is HTML</div>`,
    `<cfcomponent extends="BaseClass" output="false">`
];

console.log('=== 原始正则表达式测试 ===');
const originalRegex = /<\s*(\/?)(cf\w+)\b([\s\S]*?)(\/?)>/gi;

testCases.forEach((test, index) => {
    console.log(`\n测试 ${index + 1}: ${test}`);
    
    // 重置正则表达式
    originalRegex.lastIndex = 0;
    const matches = [...test.matchAll(originalRegex)];
    
    if (matches.length > 0) {
        matches.forEach(match => {
            console.log(`  原始匹配: ${match[0]}`);
            console.log(`  标签名: ${match[2]}`);
            console.log(`  属性: "${match[3]}"`);
        });
    } else {
        console.log('  无匹配');
    }
});

console.log('\n\n=== 改进的正则表达式测试 ===');
const improvedRegex = createCFTagRegex();

testCases.forEach((test, index) => {
    console.log(`\n测试 ${index + 1}: ${test}`);
    
    // 重置正则表达式
    improvedRegex.lastIndex = 0;
    const matches = [...test.matchAll(improvedRegex)];
    
    if (matches.length > 0) {
        matches.forEach(match => {
            console.log(`  改进匹配: ${match[0]}`);
            console.log(`  标签名: ${match[2]}`);
            console.log(`  属性: "${match[3]}"`);
        });
    } else {
        console.log('  无匹配');
    }
});

console.log('\n\n=== 状态机解析器测试 ===');
const parser = new CFTagParser();

testCases.forEach((test, index) => {
    console.log(`\n测试 ${index + 1}: ${test}`);
    
    const tags = parser.parse(test);
    
    if (tags.length > 0) {
        tags.forEach(tag => {
            console.log(`  解析结果: ${tag.fullMatch}`);
            console.log(`  标签名: ${tag.tagName}`);
            console.log(`  属性: "${tag.attributes}"`);
            console.log(`  自闭合: ${tag.isSelfClosing}`);
            console.log(`  结束标签: ${tag.isClosing}`);
        });
    } else {
        console.log('  无CF标签');
    }
});

// console.log('\n\n=== 推荐解决方案 ===');
// console.log('1. 简单情况：使用改进的正则表达式');
// console.log('2. 复杂情况：使用状态机解析器');
// console.log('3. 生产环境：建议使用专门的HTML/XML解析器');

// 实用函数：提取所有CF标签
function extractCFTags(input, method = 'parser') {
    if (method === 'regex') {
        const regex = createCFTagRegex();
        return [...input.matchAll(regex)].map(match => ({
            fullMatch: match[0],
            isClosing: match[1] === '/',
            tagName: match[2].toLowerCase(),
            attributes: match[3].trim(),
            isSelfClosing: match[4] === '/'
        }));
    } else {
        const parser = new CFTagParser();
        return parser.parse(input);
    }
}

// 使用示例
const sampleCode = `
<cfcomponent>
    <cfproperty name="test" default='[<>]' />
    <cfset var pattern = '[\\\\/:*?\\"<>|]' />
    <cfset var pattern = "A \B > A" />
    <cfset var pattern =  'He said > \"hi\"' />

    <cfset var invalidPattern = '[\\/:*?"<>|]' />
    <cfset x = "a > b">
    <cffunction name="test">
        <cfif condition EQ 'value with "quotes" and <brackets>'>
            <cfoutput>
                Hello World
            </cfoutput>
        </cfif>
    </cffunction>
    <cfzip action = "list"
    file = "#file#"
    recurse = "yes"
    showDirectory = "yes"
    name = "listResult" />
    <cfquery name="queryUpdateUserMaster" datasource="#Application.DSN#">
        UPDATE user_master
        SET
            PASSWORD = <cfqueryparam cfsqltype="cf_sql_varchar" value="#password#" />,
            last_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lastName#" />,
            first_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#firstName#" />,
            login_start_date =
            <cfif loginStartDate neq "">
                <cfqueryparam cfsqltype="cf_sql_timestamp" value="#loginStartDate#" />,
            <cfelse>
                NULL,
            </cfif>
            login_end_date =
            <cfif loginEndDate neq "">
                <cfqueryparam cfsqltype="cf_sql_timestamp" value="#loginEndDate#" />,
            <cfelse>
                NULL,
            </cfif>
            login_stop = <cfqueryparam cfsqltype="cf_sql_char" value="#loginStopFlag#" />,
            user_note = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userNote#" />,
            <cfif themaID gt 0>
                user_thema_id = <cfqueryparam value="#themaID#" cfsqltype="cf_sql_integer" />,
            </cfif>
            change_date = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#uploadEntryDate#" />
        WHERE
            user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#userID#" />
    </cfquery>

    <cffunction name="create" returntype="boolean" access="public" hint="新規学校の申請">
        <cfargument name="dto" type="ExpensesTestingSchoolRegisterWithoutExpensesDTO"/>
        <cfquery name="qCreate" datasource="#Variables.DSN#">
            INSERT INTO
                EXPENSES_TESTING_CENTRE_NO_APPLICATION (
                    fiscal_year_id,
                    school_id,
                    examination_id,
                    update_user_id,
                    entry_date
                )
            VALUES
                (
                    <cfqueryparam value="#arguments.dto.getFiscalYearId()#" cfsqltype="cf_sql_integer"/>,
                    <cfqueryparam value="#arguments.dto.getSchoolId()#" cfsqltype="cf_sql_integer"/>,
                    <cfqueryparam value="#arguments.dto.getExaminationId()#" cfsqltype="cf_sql_integer"/>,
                    <cfqueryparam value="#arguments.dto.getUpdateUserId()#" cfsqltype="cf_sql_integer"/>,
                    <cfqueryparam value="#arguments.dto.getEntryDate()#" cfsqltype="cf_sql_timestamp"/>
                )
        </cfquery>
        <cfreturn true/>
    </cffunction>

    <cffunction name="update" returntype="boolean" access="public" hint="更新">
        <cfargument name="dto" type="ExpensesTestingSchoolRegisterWithoutExpensesDTO"/>
        <cfquery name="qUpdate" datasource="#Variables.DSN#">
            update EXPENSES_TESTING_CENTRE_NO_APPLICATION
            set update_user_id =
            <cfqueryparam value="#arguments.dto.getUpdateUserId#" cfsqltype="cf_sql_integer"/>
            ,update_date = GETDATE()
            where fiscal_year＿id = 22 AND school_id = 1322 AND examination_id = 389
        </cfquery>
    </cffunction>
</cfcomponent>
`;

// console.log('\n\n=== 实际代码测试 ===');
// console.log('代码:');
// console.log(sampleCode);

console.log('\n提取的CF标签:');
const extractedTags = extractCFTags(sampleCode, 'parser');
extractedTags.forEach((tag, index) => {
    console.log(`${index + 1}. ${tag.tagName} - ${tag.fullMatch.substring(0, 50)}...`);
});


    const tags = parser.parse(sampleCode);
    
    if (tags.length > 0) {
        tags.forEach(tag => {
            console.log(`  解析结果: ${tag.fullMatch}`);
            console.log(`  标签名: ${tag.tagName}`);
            console.log(`  属性: "${tag.attributes}"`);
            console.log(`  自闭合: ${tag.isSelfClosing}`);
            console.log(`  结束标签: ${tag.isClosing} ` + `\n`);
        });
    } else {
        console.log('  无CF标签');
    }