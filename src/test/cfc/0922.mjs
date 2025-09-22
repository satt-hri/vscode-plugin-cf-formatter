// 统一的CFML标签正则表达式
const cfAllTagsRegex = /<\s*(\/?)(cf\w+)\b([\s\S]*?)(\/?)>/gi;

function parseCFMLTags(cfmlCode) {
    const tags = [];
    let match;
    
    // 重置正则表达式的lastIndex
    cfAllTagsRegex.lastIndex = 0;
    
    while ((match = cfAllTagsRegex.exec(cfmlCode)) !== null) {
        const [fullMatch, isClosing, tagName, attributes, isSelfClosing] = match;
        
        const tagInfo = {
            fullMatch: fullMatch,
            tagName: tagName,
            isClosing: isClosing === '/',
            isSelfClosing: isSelfClosing === '/',
            attributes: attributes.trim(),
            startIndex: match.index,
            endIndex: match.index + fullMatch.length
        };
        
        // 解析属性（仅对开始标签）
        if (!tagInfo.isClosing && tagInfo.attributes) {
            tagInfo.parsedAttributes = parseAttributes(tagInfo.attributes);
        }
        
        tags.push(tagInfo);
    }
    
    return tags;
}

function parseAttributes(attrString) {
    const attributes = {};
    
    // 支持多种属性格式的正则表达式
    const attrRegex = /([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|(\w+))/gi;
    let attrMatch;
    
    while ((attrMatch = attrRegex.exec(attrString)) !== null) {
        const [, name, doubleQuoted, singleQuoted, unquoted] = attrMatch;
        const value = doubleQuoted || singleQuoted || unquoted || '';
        attributes[name] = value;
    }
    
    return attributes;
}

// 测试代码
const testCFML = `
<cfprocessingdirective pageencoding="UTF-8" suppresswhitespace=true><cffunction name="calculateTax" returntype="numeric">
    <cfargument name="amount" type="numeric" required="true">
    <cfargument name="rate" type="numeric" default="0.08" /><cfif amount GT 0>
        <cfset tax = amount * rate>
        <cfreturn tax>
    <cfelse>
        <cfreturn 0>
    </cfif></cffunction></cfprocessingdirective>
`;

console.log('=== 解析所有CFML标签 ===');
const allTags = parseCFMLTags(testCFML);

allTags.forEach((tag, index) => {
    console.log(`${index + 1}. ${tag.fullMatch}`);
    console.log(`   标签名: ${tag.tagName}`);
    console.log(`   类型: ${tag.isClosing ? '结束标签' : (tag.isSelfClosing ? '自闭合标签' : '开始标签')}`);
    
    if (tag.parsedAttributes) {
        console.log(`   属性:`, tag.parsedAttributes);
    }
    console.log('');
});

// 配对标签的函数
function pairTags(tags) {
    const stack = [];
    const pairs = [];
    
    for (const tag of tags) {
        if (tag.isClosing) {
            // 找到匹配的开始标签
            for (let i = stack.length - 1; i >= 0; i--) {
                if (stack[i].tagName === tag.tagName) {
                    const openTag = stack.splice(i, 1)[0];
                    pairs.push({
                        openTag: openTag,
                        closeTag: tag,
                        content: testCFML.substring(openTag.endIndex, tag.startIndex)
                    });
                    break;
                }
            }
        } else if (!tag.isSelfClosing) {
            // 添加到栈中等待配对
            stack.push(tag);
        }
        // 自闭合标签不需要配对
    }
    
    return pairs;
}

console.log('=== 标签配对结果 ===');
const tagPairs = pairTags(allTags);

tagPairs.forEach((pair, index) => {
    console.log(`${index + 1}. <${pair.openTag.tagName}> ... </${pair.closeTag.tagName}>`);
    console.log(`   开始位置: ${pair.openTag.startIndex}`);
    console.log(`   结束位置: ${pair.closeTag.endIndex}`);
    console.log(`   内容长度: ${pair.content.length} 字符`);
    if (pair.openTag.parsedAttributes && Object.keys(pair.openTag.parsedAttributes).length > 0) {
        console.log(`   属性:`, pair.openTag.parsedAttributes);
    }
    console.log('');
});

// 更精确的版本 - 处理嵌套和特殊情况
function advancedCFMLParser(cfmlCode) {
    const result = {
        tags: [],
        errors: []
    };
    
    const regex = /<\s*(\/?)(cf\w+)\b((?:[^>]|>(?!\s*<))*)(\/?)>/gi;
    let match;
    
    while ((match = regex.exec(cfmlCode)) !== null) {
        try {
            const [fullMatch, isClosing, tagName, attributes, isSelfClosing] = match;
            
            // 验证标签名
            const validCFTags = [
                'cfprocessingdirective', 'cfcomponent', 'cffunction', 'cfargument', 
                'cfreturn', 'cfset', 'cfif', 'cfelseif', 'cfelse', 'cfloop', 
                'cfquery', 'cfoutput', 'cfscript', 'cfproperty', 'cfparam'
            ];
            
            if (!validCFTags.includes(tagName.toLowerCase())) {
                result.errors.push(`未知的CF标签: ${tagName} 在位置 ${match.index}`);
            }
            
            const tagInfo = {
                fullMatch,
                tagName,
                isClosing: isClosing === '/',
                isSelfClosing: isSelfClosing === '/',
                attributes: attributes.trim(),
                startIndex: match.index,
                endIndex: match.index + fullMatch.length,
                parsedAttributes: null
            };
            
            // 解析属性
            if (!tagInfo.isClosing && tagInfo.attributes) {
                tagInfo.parsedAttributes = parseAttributes(tagInfo.attributes);
            }
            
            result.tags.push(tagInfo);
            
        } catch (error) {
            result.errors.push(`解析错误在位置 ${match.index}: ${error.message}`);
        }
    }
    
    return result;
}

console.log('=== 高级解析器结果 ===');
const advancedResult = advancedCFMLParser(testCFML);

console.log(`找到 ${advancedResult.tags.length} 个标签`);
if (advancedResult.errors.length > 0) {
    console.log('错误:');
    advancedResult.errors.forEach(error => console.log('  ' + error));
}