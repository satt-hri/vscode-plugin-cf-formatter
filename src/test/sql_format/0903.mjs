import { format } from "sql-formatter";

const sql = `
INSERT INTO import_group (file_id, row_no, group_code, group_name, group_parent_code, group_string, entry_date)
VALUES
  (123, 123, 123, 123, 123, 123, now())
`;

const formatted = format(sql, {
  language: "mysql",   // 或 "sql" / "mysql" / "bigquery"
  keywordCase: "upper",     // 大写关键字
  tabWidth: 4,
  expressionWidth: 50        // ⭐️ 强制每个参数/值换行
});

console.log(formatted);