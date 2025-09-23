<cffunction name="getscoreinfor" access="public" returntype="query" output="true" hint="採点結果をクエリで返す">
    <cfargument name="fiscal_year_id" type="string" required="yes" default="" hint="年度" />
    <cfargument name="examination_id" type="string" required="no" default="" hint="検定試験ID" />
    <cfargument name="school_id" type="string" required="no" default="" hint="試験場校学校ID" />


    <cfquery name="qApUserCount" datasource="#Variables.DSN#">
        SELECT
            ud.examination_level,
            ud.user_id,
            gis.grade_in_school_name,
            si.class,
            si.student_number,
            CASE
                WHEN ud.passing_flag = '1' THEN '〇'
                WHEN ud.passing_flag = '0' THEN '×'
                ELSE ''
            END AS passing_flag_mark,
        REPLACE
            (
                TRIM(
                    LTRIM(
                        RTRIM(
                            SUBSTRING(
                                ud.kana_name,
                                1,
                                CHARINDEX (' ', ud.kana_name) - 1
                            )
                        )
                    )
                ),
                '　',
                ''
            ) AS last_name,
        REPLACE
            (
                TRIM(
                    LTRIM(
                        RTRIM(
                            SUBSTRING(
                                ud.kana_name,
                                CHARINDEX (' ', ud.kana_name) + 1,
                                LEN (ud.kana_name)
                            )
                        )
                    )
                ),
                '　',
                ''
            ) AS farst_name,
        REPLACE
            (
                TRIM(
                    LTRIM(
                        RTRIM(
                            SUBSTRING(
                                ud.roman_name,
                                1,
                                CHARINDEX (' ', ud.roman_name) - 1
                            )
                        )
                    )
                ),
                '　',
                ''
            ) AS last_name_roman,
        REPLACE
            (
                TRIM(
                    LTRIM(
                        RTRIM(
                            SUBSTRING(
                                ud.roman_name,
                                CHARINDEX (' ', ud.roman_name) + 1,
                                LEN (ud.roman_name)
                            )
                        )
                    )
                ),
                '　',
                ''
            ) AS farst_name_roman,
            LEFT(ud.birthday, 4) + '/' + SUBSTRING(ud.birthday, 5, 2) + '/' + RIGHT(ud.birthday, 2) AS birthday,
            jcyn.japanese_calendar_year_name + '/' + SUBSTRING(ud.birthday, 5, 2) + '/' + RIGHT(ud.birthday, 2) AS birthday_wareki,
            ud.answer_sheet_number AS answer_sheet_number,
            ISNULL(
                ese_esl.certificate_number,
                ''
            ) AS certificate_number,
            ISNULL(ese_esl.grade_in_school, '') AS grade_in_school,
            ISNULL(ese_esl.class, '') AS class,
            CAST(ud.area_l_s AS int) AS area_l_s,
            CAST(ud.area_r AS int) AS area_r,
            CAST(ud.area_w AS int) AS area_w,
            CAST(ud.total_score AS int) AS total_score,
            CASE
                WHEN ud.right_or_wrong_01 = '1' THEN '〇'
                ELSE '×'
            END AS right_or_wrong_01,
            CASE
                WHEN ud.right_or_wrong_02 = '1' THEN '〇'
                ELSE '×'
            END AS right_or_wrong_02,
            CASE
                WHEN ud.right_or_wrong_03 = '1' THEN '〇'
                ELSE '×'
            END AS right_or_wrong_03,
            CASE
                WHEN ud.right_or_wrong_04 = '1' THEN '〇'
                ELSE '×'
            END AS right_or_wrong_04,
            CASE
                WHEN ud.right_or_wrong_05 = '1' THEN '〇'
                ELSE '×'
            END AS right_or_wrong_05
        FROM
            ENGLISH_EXAMINATION_SCORING_DATA_INPUT_UPLOAD_HISTORY_UPLOAD_DATA AS ud
            INNER JOIN ENGLISH_EXAMINATION_DATA_LINKING AS eedl ON (
                ud.fiscal_year_id = eedl.fiscal_year_id
                AND ud.history_number = eedl.history_number
                AND ud.history_data_number = eedl.history_data_number
            )
            LEFT JOIN (
                SELECT
                    ese.fiscal_year_id,
                    ese.school_id,
                    ese.examination_id,
                    ese.user_id,
                    ese.certificate_number,
                    esl.kyuu,
                    ese.grade_in_school,
                    ese.class
                FROM
                    EXAMINATION_SUCCESSFUL_EXAMINEE AS ese
                    INNER JOIN EXAMINATION_SUCCESSFUL_LEVEL AS esl ON (
                        ese.fiscal_year_id = esl.fiscal_year_id
                        AND ese.gou_kyuu_cd = esl.gou_kyuu_cd
                    )
                WHERE
                    ese.fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                    AND ese.examination_id = <cfqueryparam value="#arguments.examination_id#" cfsqltype="cf_sql_integer" />
            ) AS ese_esl ON (
                eedl.fiscal_year_id = ese_esl.fiscal_year_id
                AND eedl.school_id = ese_esl.school_id
                AND eedl.examination_id = ese_esl.examination_id
                AND TRY_CAST (eedl.user_id AS int) = ese_esl.user_id
                AND eedl.examination_level_id = ese_esl.kyuu
            )
            LEFT JOIN STUDENTS_INFORMATION AS si ON TRY_CAST (ud.user_id AS int) = si.user_id
            LEFT JOIN GRADE_IN_SCHOOL_MASTER AS gis ON (
                gis.grade_in_school_id = si.grade_in_school_id
            )
            --和暦
            LEFT JOIN (
                SELECT
                    jcm.western_year,
                    enm.era_name_name + CAST(
                        jcm.japanese_calendar_year AS nvarchar (MAX)
                    ) AS japanese_calendar_year_name
                FROM
                    JAPANESE_CALENDAR_MASTER AS jcm
                    INNER JOIN ERA_NAME_MASTER AS enm ON (
                        jcm.era_name_id = enm.era_name_id
                    )
            ) AS jcyn ON (
                LEFT(ud.birthday, 4) = LEFT(
                    CAST(
                        jcyn.western_year AS varchar(4)
                    ),
                    4
                )
            )
        WHERE
            1 = 1
            AND eedl.fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
            AND eedl.school_id = <cfqueryparam value="#arguments.school_id#" cfsqltype="cf_sql_integer" />
            AND eedl.examination_id = <cfqueryparam value="#arguments.examination_id#" cfsqltype="cf_sql_integer" />
        ORDER BY
            eedl.fiscal_year_id,
            eedl.examination_id,
            eedl.school_id,
            CAST(ud.examination_level AS int),
            eedl.user_id;
    </cfquery>
    <cfscript>
        if (sessionVal) {
            try {
                structJsonData["session"] = true;
                var canUpdate = true;
                var addCanUpdate = true;

                if (numberOfApplications eq "") {
                    appNum = getMaxAppNum(fiscalYearId, schoolId, examinationId, examinationFormatId);
                } else {
                    appNum = numberOfApplications
                }

                // 申請済みチェック
                if (examinationFormatId eq Variables.ConfigExaminationFormatId.CBT) {
                    qWorkflowStat = getWorkflowState(fiscalYearId, schoolId, examinationId, appNum, Variables.configWorkflowTypeID.EXAM_APPLICANTS_APPLICATION_CBT);
                    if (qWorkflowStat.recordCount eq 1) {
                        if (qWorkflowStat.workflow_outcome_id eq configWorkflowOutcomeID.WORKFLOW_OUTCOME_APPLICATION OR qWorkflowStat.workflow_outcome_id eq configWorkflowOutcomeID.WORKFLOW_OUTCOME_APPROVAL) {
                            canUpdate = false;
                        }
                    }
                } else {
                    qWorkflowStat = getWorkflowState(fiscalYearId, schoolId, examinationId, appNum, Variables.configWorkflowTypeID.EXAM_APPLICANTS_APPLICATION);
                    qAddWorkflowStat = getWorkflowState(fiscalYearId, schoolId, examinationId, appNum, Variables.configWorkflowTypeID.ADDITIONAL_EXAM_APPLICANTS_APPLICATION);

                    if (qWorkflowStat.recordCount eq 1) {
                        if (qWorkflowStat.workflow_outcome_id eq configWorkflowOutcomeID.WORKFLOW_OUTCOME_APPLICATION OR qWorkflowStat.workflow_outcome_id eq configWorkflowOutcomeID.WORKFLOW_OUTCOME_APPROVAL) {
                            canUpdate = false;
                        }
                    }

                    if (qAddWorkflowStat.recordCount eq 1) {
                        if (qAddWorkflowStat.workflow_outcome_id eq configWorkflowOutcomeID.WORKFLOW_OUTCOME_APPLICATION OR qAddWorkflowStat.workflow_outcome_id eq configWorkflowOutcomeID.WORKFLOW_OUTCOME_APPROVAL) {
                            addCanUpdate = false;
                        }
                    }
                }

                structJsonData["can_update"] = canUpdate;
                structJsonData["add_can_update"] = addCanUpdate;

                //追加申込チェック
                var addReasonCanUpdate = false;
                if (examinationFormatId neq Variables.ConfigExaminationFormatId.CBT) {
                    qAddReasonWorkflowStat = getWorkflowState(fiscalYearId, schoolId, examinationId, appNum, Variables.configWorkflowTypeID.ADDITIONAL_EXAM_APPLICANTS_REASON_APPLICATION);
                    //追加理由申請が承認されているか
                    if (qAddReasonWorkflowStat.recordCount eq 1) {
                        if (
                            qAddReasonWorkflowStat.workflow_outcome_id eq configWorkflowOutcomeID.WORKFLOW_OUTCOME_APPROVAL
                        ) {
                            addReasonCanUpdate = true;
                        }
                    }
                }
                structJsonData["add_reason_can_update"] = addReasonCanUpdate;

                if (qSelect.RecordCount eq 1) {
                    if (qSelect.number_of_applications eq "") {
                        structJsonData["number_of_applications"] = 1;
                    } else {
                        structJsonData["number_of_applications"] = qSelect.number_of_applications;
                    }

                    if (qSelect.number_of_applications eq "") {
                        structJsonData["payment_method_name"] = '銀行振込(バーチャル口座)';
                    } else {
                        structJsonData["payment_method_name"] = qSelect.payment_method_name;
                    }
                    structJsonData["payment_type_name"] = qSelect.payment_type_name;
                    structJsonData["testing_centre_general_accepted_status_name"] = qSelect.testing_centre_general_accepted_status_name;

                    var testingSchoolApplicationPeriodEndDate = "";
                    // 試験形式CBT選択中かつ入金締切日(試験期間開始日基点日数)の場合
                    if (examinationFormatId eq Variables.ConfigExaminationFormatId.CBT and qSelect.payment_deadline_type eq Variables.ConfigPaymentDeadlineType.EXAMINATION_DATE_START_BASE) {
                        testingSchoolApplicationPeriodEndDate = '(申込締切：' & qSelect.testing_school_application_period_end_date & ')';
                    }

                    if (qSelect.is_now_accepting eq 1) {
                        structJsonData["is_school_application_period"] = '受付中' & testingSchoolApplicationPeriodEndDate;
                    } else {
                        structJsonData["is_school_application_period"] = '受付期日終了' & testingSchoolApplicationPeriodEndDate;
                    }

                    structJsonData["application_status"] = qSelect.application_status
                    structJsonData["authorize_status"] = qSelect.workflow_outcome_name

                    if (isNumeric(qSelect.minimum_number_of_people)) {

                        // 規定人数は申込回数関係なく検定試験ごとの合計人数
                        if (qSelect.minimum_number_of_people <= qApplicatedUsers.applicated_users) {
                            structJsonData["is_fulfilled_requirement"] = '以上';
                        } else {
                            structJsonData["is_fulfilled_requirement"] = '未満';
                        }

                    } else {
                        structJsonData["is_fulfilled_requirement"] = ''
                    }
                    structJsonData["minimum_number_of_people"] = qSelect.minimum_number_of_people;

                    structJsonData["is_now_accepting"] = qSelect.is_now_accepting;
                    structJsonData["is_after_acceptinge"] = qSelect.is_after_acceptinge; //申込期間（試験場校）を過ぎているか
                    structJsonData["is_after_payment_deadline"] = qSelect.is_after_payment_deadline; //受験料入金締切日を過ぎているか

                    //英検か
                    structJsonData["is_eiken"] = false;
                    if (qSelect.examination_item_origin_id eq Variables.ConfigExaminationItemOriginID.ENGLISH) {
                        structJsonData["is_eiken"] = true;
                    }
                }
                structJsonData["application_status_struct"] = getCurrentStatus(fiscalYearId, schoolId, examinationId, examinationFormatId)
                //申込回数を選択していない場合は最大値の回数で取得する
                if (numberOfApplications eq "") {
                    selectNumberOfApplications = structJsonData["application_status_struct"]["current_number_of_applications"];
                }
                structJsonData["select_application_status_struct"] = getSelectCurrentStatus(fiscalYearId, schoolId, examinationId, selectNumberOfApplications, examinationFormatId)
                if (numberOfApplications eq "") {
                    structJsonData["is_history_data"] = false;
                } else {
                    structJsonData["is_history_data"] = true;
                }

            } catch (any e) {
                return Variables.ajaxError.cfcatchToJson(e);
            }
        }

    </cfscript>
    <cfreturn qApUserCount />
</cffunction>
