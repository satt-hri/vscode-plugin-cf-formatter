import { format } from "sql-formatter";
import jsBeautify from "js-beautify";

// 您的混合代码
const mixedCode = `var q_get_course = queryNew("");
{
    // SQLを加工する
    var sql = "";
sql = sql & "
SELECT  c.course_id
,c.course_no
,c.course_name
,c.course_guide
,DATE_FORMAT(c.course_start_date, '%Y/%m/%d') as course_start_date
,DATE_FORMAT(c.course_end_date, '%Y/%m/%d') as course_end_date
,   CASE c.course_open
WHEN 1 THEN '公開'
WHEN 0 THEN '非公開'
END as course_open
,cate.category_name
,repo.report_name
,cer.certification_name
,   CASE c.manifest_flag
WHEN 1 THEN '有り'
WHEN 0 THEN '無し'
END as manifest_flag
,c.scorm_ver
,   CASE c.hide_score
WHEN 1 THEN '表示'
WHEN 0 THEN '非表示'
END as hide_score
,   CASE c.hide_result
WHEN 1 THEN '修了表示'
WHEN 0 THEN 'そのまま'
END as hide_result
,GROUP_CONCAT(DISTINCT pre_c.course_name SEPARATOR '$') as precondition_course_name
,coalesce(ass.user_count,0) as user_count
FROM    course_master c
LEFT JOIN category_master cate
ON  c.category_id = cate.category_id
LEFT JOIN report_template repo
ON  c.report_id = repo.report_id
LEFT JOIN certification_template_master cer
ON  c.certification_id = cer.certification_id
LEFT JOIN precondition_course pre
ON  c.course_id = pre.course_id
LEFT JOIN course_master pre_c
ON  pre.pre_course_id = pre_c.course_id
LEFT JOIN (
SELECT  course_id
        ,count(*)   as user_count
FROM    assign
GROUP BY
        course_id
) ass
ON  c.course_id = ass.course_id
WHERE   1=1
";
// all じゃないときは course_id で絞り込む
if(arguments.course_id neq "all"){
sql = sql & "
AND c.course_id = :course_id
";
}
sql = sql & "
GROUP BY
c.course_id
";
// 加工したSQLを実行
q_get_course = queryExecute(
sql=sql
,params={
course_id={value=arguments.course_id, cfsqltype="CF_SQL_INTEGER"}
}
,options={
datasource=Application.DSN
,result="resultset"
}
);
}`;

// 第一步：使用 js-beautify 格式化整个代码
const beautifiedCode = jsBeautify(mixedCode, {
  indent_size: 2,
  indent_char: " ",
  indent_with_tabs: false,
  eol: "\n",
  end_with_newline: false,
  indent_level: 0,
  preserve_newlines: true,
  max_preserve_newlines: 10,
  space_in_paren: false,
  space_in_empty_paren: false,
  jslint_happy: false,
  space_after_anon_function: false,
  brace_style: "collapse",
  break_chained_methods: false,
  keep_array_indentation: false,
  keep_function_indentation: false,
  space_before_conditional: true,
  unescape_strings: false,
  wrap_line_length: 0,
  wrap_attributes: "auto",
  wrap_attributes_indent_size: 4,
});

// 第二步：提取 SQL 部分并格式化
// 使用正则表达式匹配 SQL 部分
const sqlRegex = /sql = sql & "([\s\S]*?)";/g;
let formattedCode = beautifiedCode;
let match;

while ((match = sqlRegex.exec(beautifiedCode)) !== null) {
  const originalSql = match[1];
  
  // 清理 SQL 字符串（移除换行和多余空格）
  let cleanSql = originalSql
    .replace(/\\\n\s*/g, " ") // 处理行继续符
    .replace(/\s+/g, " ") // 将多个空格合并为一个
    .trim();
  
  // 格式化 SQL
  let formattedSql;
  try {
    formattedSql = format(cleanSql, { language: "mysql" });
  } catch (error) {
    console.error("SQL 格式化错误:", error);
    formattedSql = cleanSql; // 如果格式化失败，使用原始 SQL
  }
  
  // 将格式化后的 SQL 放回代码中
  formattedCode = formattedCode.replace(
    originalSql,
    `\n${formattedSql}\n        `
  );
}

console.log(formattedCode);