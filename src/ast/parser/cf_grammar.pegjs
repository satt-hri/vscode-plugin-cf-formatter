
{
  function buildBinaryExpression(head, tail) {
    return tail.reduce((result, element) => {
      return {
        type: 'BinaryExpression',
        operator: element[1],
        left: result,
        right: element[3]
      };
    }, head);
  }
}

Program
  = _ statements:Statement* _ {
      return {
        type: 'Program',
        body: statements
      };
    }

Statement
  = CFComponentStatement
  / CFProcessingDirectiveStatement
  / CFFunctionStatement
  / CFQueryStatement
  / CFPropertyStatement
  / CFArgumentStatement
  / CFReturnStatement
  / CFSetStatement
  / CFIfStatement
  / CFLoopStatement
  / CFOutputStatement
  / CFScriptBlock
  / CommentBlock
  / GenericCFTag

CFReturnStatement
  = "<cfreturn"i _ expr:ReturnExpression? _ "/" _ ">" _ {
      return {
        type: 'CFReturnStatement',
        expression: expr,
        selfClosing: true
      };
    }
  / "<cfreturn"i _ expr:ReturnExpression? _ ">" _ {
      return {
        type: 'CFReturnStatement',
        expression: expr,
        selfClosing: false
      };
    }

ReturnExpression
  = chars:(!("/" / ">") .)+ {
      return chars.map(function(c) { return c[1]; }).join('').trim();
    }

CommentBlock
  = "<!---" _ content:CommentContent _ "--->" _ {
      return {
        type: 'CommentBlock',
        content: content
      };
    }

CommentContent
  = parts:(CommentBlock / CommentText)* {
      return parts;
    }

CommentText
  = chars:(!("<!---" / "--->") .)+ {
      return {
        type: 'CommentText',
        value: chars.map(c => c[1]).join('')
      };
    }

CFComponentStatement
  = "<cfcomponent"i attrs:TagAttributes? ">" _
    body:Statement* _
    "</cfcomponent"i _ ">" _ {
      return {
        type: 'CFComponentStatement',
        attributes: attrs || [],
        body: body
      };
    }

CFProcessingDirectiveStatement
  = "<cfprocessingdirective"i _ attrs:TagAttributes _ ">" _ {
      return {
        type: 'CFProcessingDirectiveStatement',
        attributes: attrs
      };
    }
  / "</cfprocessingdirective"i _ ">" _ {
      return {
        type: 'CFProcessingDirectiveEnd'
      };
    }

CFFunctionStatement
  = "<cffunction"i _ attrs:TagAttributes _ ">" _
    body:Statement* _
    "</cffunction"i _ ">" _ {
      return {
        type: 'CFFunctionStatement',
        attributes: attrs,
        body: body
      };
    }

CFArgumentStatement
  = "<cfargument"i _ attrs:TagAttributes _ "/" _ ">" _ {
      return {
        type: 'CFArgumentStatement',
        attributes: attrs,
        selfClosing: true
      };
    }
  / "<cfargument"i _ attrs:TagAttributes _ ">" _ {
      return {
        type: 'CFArgumentStatement',
        attributes: attrs,
        selfClosing: false
      };
    }

CFPropertyStatement
  = "<cfproperty"i _ attrs:TagAttributes _ "/" _ ">" _ {
      return {
        type: 'CFPropertyStatement',
        attributes: attrs,
        selfClosing: true
      };
    }
  / "<cfproperty"i _ attrs:TagAttributes _ ">" _ {
      return {
        type: 'CFPropertyStatement',
        attributes: attrs,
        selfClosing: false
      };
    }

TagAttributes
  = head:TagAttribute tail:(_ TagAttribute)* {
      return [head, ...tail.map(t => t[1])];
    }

TagAttribute
  = name:Identifier _ "=" _ value:AttributeValue {
      return { name: name.name, value: value };
    }

CFQueryStatement
  = "<cfquery"i _ attrs:TagAttributes _ ">" _
    content:QueryRawContent _
    "</cfquery"i _ ">" _ {
      return {
        type: 'CFQueryStatement',
        attributes: attrs,
        content: content
      };
    }

QueryRawContent
  = content:(!"</cfquery"i .)* {
      return content.map(function(c) { return c[1]; }).join('');
    }

CFSetStatement
  = "<cfset"i _ varDecl:("var"i _)? name:Identifier _ "=" _ value:Expression _ "/" _ ">" _ {
      return {
        type: 'CFSetStatement',
        variable: name,
        value: value,
        hasVar: !!varDecl,
        selfClosing: true
      };
    }
  / "<cfset"i _ varDecl:("var"i _)? name:Identifier _ "=" _ value:Expression _ ">" _ {
      return {
        type: 'CFSetStatement',
        variable: name,
        value: value,
        hasVar: !!varDecl,
        selfClosing: false
      };
    }

CFIfStatement
  = "<cfif"i _ condition:Expression _ ">" _
    consequent:Statement* _
    alternate:CFElseClause? _
    "</cfif"i _ ">" _ {
      return {
        type: 'CFIfStatement',
        condition: condition,
        consequent: consequent,
        alternate: alternate
      };
    }

CFElseClause
  = "<cfelse"i _ ">" _ body:Statement* {
      return body;
    }
  / "<cfelseif"i _ condition:Expression _ ">" _
    consequent:Statement* _
    alternate:CFElseClause? {
      return [{
        type: 'CFIfStatement',
        condition: condition,
        consequent: consequent,
        alternate: alternate
      }];
    }

CFLoopStatement
  = "<cfloop"i _ attrs:LoopAttributes _ ">" _
    body:Statement* _
    "</cfloop"i _ ">" _ {
      return {
        type: 'CFLoopStatement',
        attributes: attrs,
        body: body
      };
    }

LoopAttributes
  = head:LoopAttribute tail:(_ LoopAttribute)* {
      return [head, ...tail.map(t => t[1])];
    }

LoopAttribute
  = name:Identifier _ "=" _ value:AttributeValue {
      return { name: name.name, value: value };
    }

CFOutputStatement
  = "<cfoutput"i _ ">" _
    content:OutputContent* _
    "</cfoutput"i _ ">" _ {
      return {
        type: 'CFOutputStatement',
        content: content
      };
    }

OutputContent
  = CFExpression
  / TextContent

CFExpression
  = "#" expr:Expression "#" {
      return {
        type: 'CFExpression',
        expression: expr
      };
    }

TextContent
  = chars:(!("</" / "#") .)+ {
      return {
        type: 'TextContent',
        value: chars.map(c => c[1]).join('')
      };
    }

CFScriptBlock
  = "<cfscript"i _ ">" _
    content:ScriptContent _
    "</cfscript"i _ ">" _ {
      return {
        type: 'CFScriptBlock',
        content: content.trim()
      };
    }

ScriptContent
  = chars:(!"</cfscript"i .)* {
      return chars.map(c => c[1]).join('');
    }

Expression
  = LogicalOrExpression

LogicalOrExpression
  = head:LogicalAndExpression
    tail:(_ ("OR"i / "||") _ LogicalAndExpression)* {
      return buildBinaryExpression(head, tail);
    }

LogicalAndExpression
  = head:AdditiveExpression
    tail:(_ ("AND"i / "&&") _ AdditiveExpression)* {
      return buildBinaryExpression(head, tail);
    }

AdditiveExpression
  = head:MultiplicativeExpression
    tail:(_ ("+" / "-") _ MultiplicativeExpression)* {
      return buildBinaryExpression(head, tail);
    }

MultiplicativeExpression
  = head:ComparisonExpression
    tail:(_ ("*" / "/") _ ComparisonExpression)* {
      return buildBinaryExpression(head, tail);
    }

ComparisonExpression
  = head:UnaryExpression
    tail:(_ ("==" / "!=" / "<=" / ">=" / "<" / ">" / "GT"i / "LT"i / "EQ"i / "NEQ"i / "GTE"i / "LTE"i) _ UnaryExpression)* {
      return buildBinaryExpression(head, tail);
    }

UnaryExpression
  = "!" _ argument:UnaryExpression {
      return {
        type: 'UnaryExpression',
        operator: '!',
        argument: argument
      };
    }
  / PrimaryExpression

PrimaryExpression
  = FunctionCall
  / MemberExpression
  / ObjectLiteral
  / ArrayLiteral
  / Identifier
  / StringLiteral
  / NumberLiteral
  / BooleanLiteral
  / "(" _ expr:Expression _ ")" { return expr; }

MemberExpression
  = object:Identifier _ "." _ property:Identifier {
      return {
        type: 'MemberExpression',
        object: object,
        property: property
      };
    }
  / object:Identifier _ "[" _ property:Expression _ "]" {
      return {
        type: 'MemberExpression',
        object: object,
        property: property,
        computed: true
      };
    }

ObjectLiteral
  = "{" _ properties:PropertyList? _ "}" {
      return {
        type: 'ObjectLiteral',
        properties: properties || []
      };
    }

PropertyList
  = head:Property tail:(_ "," _ Property)* (_ ",")? {
      return [head, ...tail.map(t => t[3])];
    }

Property
  = key:PropertyKey _ ":" _ value:Expression {
      return {
        type: 'Property',
        key: key,
        value: value
      };
    }

PropertyKey
  = Identifier
  / StringLiteral

ArrayLiteral
  = "[" _ elements:ElementList? _ "]" {
      return {
        type: 'ArrayLiteral',
        elements: elements || []
      };
    }

ElementList
  = head:Expression tail:(_ "," _ Expression)* (_ ",")? {
      return [head, ...tail.map(t => t[3])];
    }

FunctionCall
  = name:MemberExpression _ "(" _ args:ArgumentList? _ ")" {
      return {
        type: 'FunctionCall',
        name: name,
        arguments: args || []
      };
    }
  / name:Identifier _ "(" _ args:ArgumentList? _ ")" {
      return {
        type: 'FunctionCall',
        name: name,
        arguments: args || []
      };
    }

ArgumentList
  = head:NamedArgument tail:(_ "," _ NamedArgument)* {
      return [head, ...tail.map(t => t[3])];
    }
  / head:Expression tail:(_ "," _ Expression)* {
      return [head, ...tail.map(t => t[3])];
    }

NamedArgument
  = name:Identifier _ "=" _ value:Expression {
      return {
        type: 'NamedArgument',
        name: name,
        value: value
      };
    }

Identifier
  = !ReservedWord [a-zA-Z_][a-zA-Z0-9_]* {
      return {
        type: 'Identifier',
        name: text()
      };
    }

StringLiteral
  = '"' chars:DoubleStringCharacter* '"' {
      return {
        type: 'StringLiteral',
        value: text().slice(1, -1)
      };
    }
  / "'" chars:SingleStringCharacter* "'" {
      return {
        type: 'StringLiteral',
        value: text().slice(1, -1)
      };
    }

DoubleStringCharacter
  = [^"\\]
  / "\\" .

SingleStringCharacter
  = [^'\\]
  / "\\" .

NumberLiteral
  = [0-9]+ ("." [0-9]+)? {
      return {
        type: 'NumberLiteral',
        value: parseFloat(text())
      };
    }

BooleanLiteral
  = "true"i {
      return {
        type: 'BooleanLiteral',
        value: true
      };
    }
  / "false"i {
      return {
        type: 'BooleanLiteral',
        value: false
      };
    }

AttributeValue
  = StringWithHash
  / StringLiteral
  / NumberLiteral
  / Identifier

StringWithHash
  = '"' content:HashStringContent* '"' {
      return {
        type: 'StringWithHash',
        parts: content
      };
    }

HashStringContent
  = "#" expr:HashExpression "#" {
      return {
        type: 'HashExpression',
        expression: expr
      };
    }
  / chars:(!("#" / '"') .)+ {
      return {
        type: 'StringPart',
        value: chars.map(c => c[1]).join('')
      };
    }

HashExpression
  = object:Identifier "." property:Identifier {
      return {
        type: 'MemberExpression',
        object: object,
        property: property
      };
    }
  / id:Identifier {
      return id;
    }

ReservedWord
  = ("var"i / "function"i / "return"i / "if"i / "else"i) ![a-zA-Z0-9_]

GenericCFTag
  = "<cf" tagName:GenericTagName _ attrs:TagAttributes? _ "/" _ ">" _ {
      return {
        type: 'GenericCFTag',
        tagName: tagName,
        attributes: attrs || [],
        selfClosing: true,
        body: null,
        hasEndTag: false
      };
    }
  / "<cf" tagName:GenericTagName _ attrs:TagAttributes? _ ">" _ 
    body:GenericTagBody 
    "</cf" endTagName:GenericTagName _ ">" _ {
      return {
        type: 'GenericCFTag',
        tagName: tagName,
        attributes: attrs || [],
        selfClosing: false,
        body: body,
        hasEndTag: true,
        endTagName: endTagName
      };
    }
  / "<cf" tagName:GenericTagName _ attrs:TagAttributes? _ ">" _ {
      return {
        type: 'GenericCFTag',
        tagName: tagName,
        attributes: attrs || [],
        selfClosing: false,
        body: null,
        hasEndTag: false
      };
    }

GenericTagName
  = !("component"i / "processingdirective"i / "function"i / "query"i / "property"i / "argument"i / "set"i / "if"i / "else"i / "elseif"i / "loop"i / "output"i / "script"i) 
    [a-zA-Z][a-zA-Z0-9_]* {
      return text();
    }

GenericTagBody
  = body:(!"</cf" Statement / !"</cf" .)* {
      return body.map(function(item) {
        if (item[1] && item[1].type) {
          return item[1];
        }
        return item[1];
      });
    }

_
  = [ \t\n\r]*