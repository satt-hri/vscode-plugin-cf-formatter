import { format } from "sql-formatter";
import fs from "fs"
import path from "path";

try {

    let sql = `SELECT c.course_id, c.course_no, c.course_name, c.course_guide, DATE_FORMAT(c.course_start_date, '%Y/%m/%d') as course_start_date, DATE_FORMAT(c.course_end_date, '%Y/%m/%d') as course_end_date, CASE c.course_open
					WHEN 1 THEN '公開'
					WHEN 0 THEN '非公開'
					END as course_open, cate.category_name, repo.report_name, cer.certification_name, CASE c.manifest_flag
					WHEN 1 THEN '有り'
					WHEN 0 THEN '無し'
					END as manifest_flag, c.scorm_ver, CASE c.hide_score
					WHEN 1 THEN '表示'
					WHEN 0 THEN '非表示'
					END as hide_score, CASE c.hide_result
					WHEN 1 THEN '修了表示'
					WHEN 0 THEN 'そのまま'
					END as hide_result, GROUP_CONCAT(DISTINCT pre_c.course_name SEPARATOR '$') as precondition_course_name, coalesce(ass.user_count, 0) as user_count
					FROM course_master c
					LEFT JOIN category_master cate
					ON c.category_id = cate.category_id
					LEFT JOIN report_template repo
					ON c.report_id = repo.report_id
					LEFT JOIN certification_template_master cer
					ON c.certification_id = cer.certification_id
					LEFT JOIN precondition_course pre
					ON c.course_id = pre.course_id
					LEFT JOIN course_master pre_c
					ON pre.pre_course_id = pre_c.course_id
					LEFT JOIN(SELECT course_id, count( * ) as user_count FROM assign GROUP BY course_id) ass
					ON c.course_id = ass.course_id
					WHERE 1 = 1 ;`

    const outputFile = path.resolve("", "temp.sql");

    const result = format(sql, { language: "n1ql" })

    fs.writeFileSync(outputFile, result, "utf-8")
    console.log(result)
} catch (error) {
  console.log(error)
}