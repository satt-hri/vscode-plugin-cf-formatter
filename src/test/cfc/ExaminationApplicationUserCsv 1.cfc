<!---
    Name         : zenms/zenms_cfc/ExaminationApplicationUserCsv.cfc
    Author       : Hiroyuki Kuboki
    Created      : 2024/03/23
    Last Updated : 
    History      : 2025/01/29 CBT対応処理を追加(Seina Aihara)
    : 2025/05/20 CBT簿記対応(Seina Aihara)
    Purpose      : 受験者管理情報インポート処理（受験申込）
--->
<cfcomponent>
    <cfprocessingdirective pageencoding="utf-8">
    <cfprocessingdirective suppresswhitespace="yes">

    <cffunction name="init" access="public" returntype="ExaminationApplicationUserCsv" output="no" hint="[public]コンストラクタ">
        <cfargument name="DSN" type="string" required="yes" hint="Application.DSN" />
        <cfargument name="SERVICE_ADDRESS" type="string" required="yes" hint="Application.SERVICE_ADDRESS" />
        <cfargument name="COMMON_SERVICE_ADDRESS" type="string" required="yes" hint="Application.COMMON_SERVICE_ADDRESS" />
        <cfscript>
            Variables.DSN = arguments.DSN;
            Variables.SA = arguments.SERVICE_ADDRESS;
            Variables.CSA = arguments.COMMON_SERVICE_ADDRESS;

            // 入力チェック処理利用
            Variables.crnUserImport = CreateObject("component", "#Variables.SA#.CRNUserImport").init(DSN = Variables.DSN, SERVICE_ADDRESS = Variables.SA, COMMON_SERVICE_ADDRESS = Variables.CSA);

            //バリデーション処理
            Variables.validation = CreateObject("component", "#Variables.CSA#.Validation").init();
            Variables.StringUtil = CreateObject("component", "#Variables.CSA#.StringUtil").init();

            Variables.examinationMasterGateway = CreateObject("component", "#Variables.SA#.ExaminationMasterGateway").init(DSN = DSN);

            // 試験形式IDの設定
            Variables.ConfigExaminationFormatId = CreateObject("component", "#Variables.SA#.ConfigExaminationFormatId").init();
            Variables.configPaymentStatusId = CreateObject("component", "#Variables.SA#.ConfigPaymentStatusId").init(DSN = DSN);
        </cfscript>
        <cfreturn this />
    </cffunction>

    <!--- CSVファイルからデータチェック処理 --->
    <cffunction name="CheckInputData" access="public" returntype="string" output="true"  hint="データチェック処理">
        <cfargument name="info_data" type="array" required="yes" hint="CSVデータ" />
        <cfargument name="entry_data" type="string" required="yes" hint="更新データ" />
        <cfargument name="fiscal_year_id" type="string" required="no" hint="抽出条件の年度ID" />
        <cfargument name="school_id" type="string" required="no" hint="試験場校ID" />
        <cfargument name="examination_id" type="string" required="no" hint="試験ID" />
        <cfargument name="examination_level_id" type="string" required="no" hint="級ID" />
        <cfargument name="number_of_applications" type="string" required="no" hint="申込回数" />
        <cfargument name="examination_format_id" type="string" required="no" default="0" hint="試験形式ID" />

        <cfscript>
            var userSchoolMasterGateway = CreateObject("component", "#Variables.SA#.SchoolMasterGateway").init(DSN = Variables.DSN);

            var infoData = arguments.info_data;
            var entryData = arguments.entry_data;

            // 画面から取得した情報
            var searchFiscalYearId = arguments.fiscal_year_id;
            var searchSchoolId = arguments.school_id;
            var searchExaminationId = arguments.examination_id;
            var searchExaminationLevelID = arguments.examination_level_id;
            var searchNumberOfApplications = arguments.number_of_applications;
            var searchexaminationFormatId = arguments.examination_format_id;

            var entryDataStruct = structNew();
            var updateFlag = false;
            if (entryData neq "") {
                entryDataStruct = DeserializeJSON(entryData);
                updateFlag = true;
            }

            /*
            1.  検定試験ID          必須
            2.  級                  必須
            3.  在籍学校コード
            4.  ユーザID            必須
            5.  個人ID
            6.  姓
            7.  名
            8.  支払方法
            以下可変
            9. 受験番号
            */

            // 受験申込データ
            var examinationID = Trim(infoData[1]);
            var examinationLevelID = Trim(infoData[2]);
            var schoolCode = Trim(infoData[3]);
            var userID = Trim(infoData[4]);
            var loginID = Trim(infoData[5]);
            var lastName = Trim(infoData[6]);
            var firstName = Trim(infoData[7]);
            var paymentTypeName = Trim(infoData[8]);

            var errorMessage = "";
            var setTxt = "";
            // --- ユーザID必須チェックを先に ---
            if (userID eq "") {
                return "「ユーザID」は必須です。";
            }
            if (NOT Variables.validation.doValidation('halfNum', userID)) {
                return "「ユーザID」には半角数字を入力してください。";
            }

            var checkExamineesNumberResult = checkExamineesNumber(
                info_data = infoData,
                fiscal_year_id = searchFiscalYearId,
                examination_id = searchExaminationId,
                examination_level_id = searchExaminationLevelID,
                school_id = searchSchoolId,
                user_id = userID,
                examination_format_id = searchexaminationFormatId,
                number_of_applications = searchNumberOfApplications
            );
            //決済方法取得
            var qExaminationApplicationInfo = getExaminationApplicationQuery(
                fiscal_year_id = searchFiscalYearId,
                school_id = searchSchoolId,
                examination_id = searchExaminationId,
                number_of_applications = searchNumberOfApplications,
                examination_format_id = searchexaminationFormatId
            );

            mainPaymentTypeID = qExaminationApplicationInfo.payment_type_id;
            mainPaymentTypeName = qExaminationApplicationInfo.payment_type_name;
        </cfscript>

        <!--- 検定試験ID --->
        <cfif examinationID eq "">
            <cfset errorMessage = "「検定試験ID」は必須です。" />
        <cfelseif examinationID neq "" and NOT Variables.validation.doValidation('halfNum',examinationID) >
            <cfset errorMessage = "「検定試験ID」には半角数字を入力してください。" />
        <cfelseif  Len(examinationID) gt 9 >
            <cfset errorMessage = "「検定試験ID」は9文字以下で入力してください。" />

        <cfelseif examinationID neq "" and  IsRegisteredExaminationID(fiscal_year_id=searchFiscalYearId ,examination_id=examinationID)>
            <cfset errorMessage = "「検定試験ID」に該当する試験IDが存在しません。" />
        <cfelseif examinationID neq searchExaminationId >
            <cfset errorMessage = "「検定試験ID」と「検定試験名」リストで選択された検定試験が異なります。" />

            <!--- 級 --->
        <cfelseif examinationLevelID eq "">
            <cfset errorMessage = "「級」は必須です。" />
        <cfelseif examinationLevelID neq "" and NOT Variables.validation.doValidation('halfNum',examinationLevelID) >
            <cfset errorMessage = "「級」には半角数字を入力してください。" />
        <cfelseif  Len(examinationLevelID) gt 9 >
            <cfset errorMessage = "「級」は9文字以下で入力してください。" />

        <cfelseif examinationLevelID neq "" and  IsRegisteredExaminationLevelID(examination_level_id=examinationLevelID)>
            <cfset errorMessage = "「級」に該当する試験IDが存在しません。" />
        <cfelseif examinationLevelID neq searchExaminationLevelID >
            <cfset errorMessage = "「級」と「級」リストで選択された級が異なります。" />

            <!--- 在籍学校コード --->
        <cfelseif  Len(schoolCode) gt 6 >
            <cfset errorMessage = "「在籍学校コード」は6文字以下で入力してください。" />
        <cfelseif schoolCode neq "" and  IsRegisteredSchoolCode(fiscal_year_id=searchFiscalYearId ,school_code=schoolCode)>
            <cfset errorMessage = "「在籍学校コード」に該当する学校コードが存在しません。" />

            <!--- 個人ID --->
        <cfelseif loginID eq "">
            <cfset errorMessage = "「個人ID」は必須です。" />
        <cfelseif  Len(loginID) lt 6 >
            <cfset errorMessage = "「個人ID」は6文字以上で入力してください。" />
        <cfelseif  Len(loginID) gt 80 >
            <cfset errorMessage = "「個人ID」は80文字以下で入力してください。" />
        <cfelseif NOT Variables.validation.doValidation('loginID',loginID) >
            <cfset errorMessage = '「個人ID」には半角英数字か以下の記号を入力してください。<br>. ! ## $ % & @ '' * + / = ? ^ _ ` { | } ~ - ' />
        <cfelseif   loginID neq "" and  IsRegisteredUser(user_id=userID ,login_id=loginID)>
            <cfset errorMessage = "「ユーザID」、「個人ID」に該当するユーザが存在しません。" />

            <!--- 受験番号・決済済 --->
        <cfelseif  NOT checkExamineesNumberResult.result >
            <cfset errorMessage = checkExamineesNumberResult.error_message />

            <!--- 支払方法 --->
        <cfelseif paymentTypeName eq "">
            <cfset errorMessage = "「支払方法」は必須です。" />
        <cfelseif getPaymentTypeIdByName(payment_type_name=paymentTypeName) eq ''>
            <cfset errorMessage = "「支払方法」に該当する支払方法が存在しません。" />
            <!--- 団体支払の場合は団体支払か --->
        <cfelseif mainPaymentTypeID eq 1 AND mainPaymentTypeName neq paymentTypeName>
            <cfset errorMessage = "「支払方法」が異なります。" />
            <!--- 個人支払の場合は個人支払か --->
        <cfelseif mainPaymentTypeID eq 2 AND mainPaymentTypeName neq paymentTypeName>
            <cfset errorMessage = "「支払方法」が異なります。" />
            <!--- 併用支払の場合は併用支払以外か --->
        <cfelseif mainPaymentTypeID eq 3 AND mainPaymentTypeName eq paymentTypeName>
            <cfset errorMessage = "支払方法」が異なります。" />
            <!--- 二重申込確認 --->
        <cfelseif examinationLevelID eq searchExaminationLevelID >

            <cfscript>
                var deptCheckResult = firstcheckDepartment(
                    info_Data = infoData,
                    fiscal_year_id = searchFiscalYearId,
                    number_of_applications = searchNumberOfApplications,
                    school_id = searchSchoolId,
                    examination_level_id = searchExaminationLevelID
                )

                if (NOT deptCheckResult.result) {
                    errorMessage = deptCheckResult.errorMessage
                }
            </cfscript>
        </cfif>

        <cfreturn errorMessage />
    </cffunction>


    <!--- CSVファイルからデータチェック処理 --->
    <cffunction name="insertInputData" access="public" returntype="boolean" output="false"  hint="データチェック処理">
        <cfargument name="info_data" type="array" required="yes" hint="CSVデータ" />
        <cfargument name="entry_data" type="string" required="yes" hint="更新データ" />
        <cfargument name="fiscal_year_id" type="string" required="no" hint="抽出条件の年度ID" />
        <cfargument name="school_id" type="string" required="no" hint="試験場校ID" />
        <cfargument name="examination_id" type="string" required="no" hint="試験ID" />
        <cfargument name="examination_level_id" type="string" required="no" hint="級ID" />
        <cfargument name="number_of_applications" type="string" required="no" hint="申込回数" />
        <cfscript>
            // CSVデータ
            var infoData = arguments.info_data;

            // 画面から取得した情報
            var searchFiscalYearId = arguments.fiscal_year_id;
            var searchSchoolId = arguments.school_id;
            var searchExaminationId = arguments.examination_id;
            var searchExaminationLevelID = arguments.examination_level_id;
            var searchNumberOfApplications = arguments.number_of_applications;

            // 成功フラグ
            var result = false;

            // 更新日
            var updateDate = Now();

            // 更新者
            var updateUserID = 0;
            if (StructKeyExists(Session, "userID")) {
                updateUserID = Session.userID;
            }

            // 登録済みデータ
            var entryData = arguments.entry_data;
            var entryDataStruct = structNew();
            var updateFlag = false;
            if (entryData neq "") {
                entryDataStruct = DeserializeJSON(entryData);
                updateFlag = true;
            }

            // 入力値
            var examinationID = Trim(infoData[1]); //使用しない
            var examinationLevelID = Trim(infoData[2]); //使用しない
            var schoolCode = Trim(infoData[3]); //使用しない
            var userID = Trim(infoData[4]);
            var loginID = Trim(infoData[5]); //使用しない
            var lastName = Trim(infoData[6]); //使用しない
            var firstName = Trim(infoData[7]); //使用しない
            var paymentTypeName = Trim(infoData[8]);
            var eNumNo = 9;
            var examineesArrsy = ArrayNew(1);
            var examineesStr = StructNew();
            var userApplicationsNo = 0;
            var refurndTarget = 0;

            var numberOfApplications = 1; //申込回数
            if (searchNumberOfApplications neq "") {
                numberOfApplications = searchNumberOfApplications;
            }

            var paymentTypeID = 0; //支払方法
            paymentTypeID = getPaymentTypeIdByName(payment_type_name = paymentTypeName);

            //部門別受験番号取得
            qExaminationDetailDepartmentInfo = Variables.examinationMasterGateway.getExaminationDetailDepartmentInfo(
                fiscal_year_id = searchFiscalYearId,
                examination_id = searchExaminationId,
                examination_level_id = searchExaminationLevelID
            );
            //部門の数を取得
            departmentCount = qExaminationDetailDepartmentInfo.recordCount;
            if (departmentCount eq 0) {
                examineesStr = StructNew();
                StructInsert(examineesStr, "examinees_number", Trim(infoData[eNumNo]));
                StructInsert(examineesStr, "examination_department_id", 0);
                ArrayAppend(examineesArrsy, examineesStr);
            } else {
                for (val in qExaminationDetailDepartmentInfo) {
                    examineesStr = StructNew();
                    StructInsert(examineesStr, "examinees_number", Trim(infoData[eNumNo]));
                    StructInsert(examineesStr, "examination_department_id", val.examination_department_id);
                    eNumNo++;
                    ArrayAppend(examineesArrsy, examineesStr);
                }
            }
            // writeDump(examineesArrsy);

            // 更新の場合、登録済みデータから取得
            if (updateFlag) {
                //一先ずやらない
            }

            var eauDAO = CreateObject("component", "#Variables.SA#.dao.ExaminationApplicationUserDAO").init(COMMON_SERVICE_ADDRESS = Variables.CSA, DSN = Variables.DSN);
            var eauDTO = CreateObject("component", "#Variables.SA#.dao.ExaminationApplicationUserDTO").init(COMMON_SERVICE_ADDRESS = Variables.CSA);
            var eauDelDTO = CreateObject("component", "#Variables.SA#.dao.ExaminationApplicationUserDTO").init(COMMON_SERVICE_ADDRESS = Variables.CSA);

            var qSelect = "";

            //対象者の受験者情報削除
            eauDelDTO.init(
                fiscal_year_id = searchFiscalYearId, school_id = searchSchoolId, examination_id = searchExaminationId, number_of_applications = numberOfApplications, examination_level_id = searchExaminationLevelID, user_id = userId, COMMON_SERVICE_ADDRESS = Variables.CSA
            )
            result = eauDAO.deleteLevelUserID(eauDelDTO);

            var examineesLen = ArrayLen(examineesArrsy);
            for (i = 1; i <= examineesLen; i = i + 1) {
                examineesInfo = examineesArrsy[i];
                departmentID = examineesInfo.examination_department_id;
                examineesNumber = examineesInfo.examinees_number;
                userApplicationsNo = 0;

                //受験番号が登録されていた場合登録
                if (examineesNumber neq '') {

                    //受講料取得
                    var examinationDetailDepartmentInfo = Variables.examinationMasterGateway.getExaminationDetailDepartmentInfo(
                        fiscal_year_id = searchFiscalYearId,
                        examination_id = searchExaminationId,
                        examination_level_id = searchExaminationLevelID,
                        examination_department_id = departmentID);
                    var examinationFee = examinationDetailDepartmentInfo['EXAMINATION_FEE_TOTAL'];

                    eauDTO.init(
                        fiscal_year_id = searchFiscalYearId, school_id = searchSchoolId, examination_id = searchExaminationId, number_of_applications = numberOfApplications, user_id = userId, user_applications_no = userApplicationsNo, COMMON_SERVICE_ADDRESS = Variables.CSA
                    )
                    if (eauDAO.read(eauDTO)) {
                        // eauDTO.setExamineesNumber(examineesNumber);
                        // eauDTO.setExaminationFee(examinationFee);
                        // eauDTO.setPersonalPaymentTypeId(paymentType);
                        // eauDTO.setIsRefundTarget(refurndTarget);
                        // eauDTO.setIsAbsolvedTarget(refurndTarget);
                        // eauDTO.setUpdateDate(updateDate);
                        // result = eauDAO.update(eauDTO);
                    } else {
                        userApplicationsNo = eauDAO.getExaminationUserApplicationsNoInfo(
                            fiscal_year_id = searchFiscalYearId,
                            school_id = searchSchoolId,
                            examination_id = searchExaminationId,
                            number_of_applications = numberOfApplications,
                            user_id = userID);

                        eauDTO.setExaminationFee(examinationFee);
                        eauDTO.setFiscalYearId(searchFiscalYearId);
                        eauDTO.setSchoolId(searchSchoolId);
                        eauDTO.setExaminationId(searchExaminationId);
                        eauDTO.setNumberOfApplications(numberOfApplications);
                        eauDTO.setUserId(userId);
                        eauDTO.setUserApplicationsNo(userApplicationsNo);
                        eauDTO.setExaminationLevelId(searchExaminationLevelID);
                        eauDTO.setExaminationDepartmentId(departmentId);
                        eauDTO.setExamineesNumber(examineesNumber);
                        eauDTO.setPersonalPaymentTypeId(paymentTypeID);
                        eauDTO.setIsRefundTarget(refurndTarget);
                        eauDTO.setIsAbsolvedTarget(refurndTarget);
                        eauDTO.setEntryDate(updateDate);
                        eauDTO.setUpdateDate(updateDate);

                        result = eauDAO.create(eauDTO);
                    }

                }

            }
        </cfscript>


        <cfreturn result />
    </cffunction>

    <!--- 受験番号チェック ・決済済みチェック--->
    <cffunction name="checkExamineesNumber" access="public" returntype="struct" output="false"  hint="[private]学校IDが登録済みか">
        <cfargument name="info_data" type="array" required="yes" hint="CSVデータ" />
        <cfargument name="fiscal_year_id" type="string" required="no" hint="年度ID" />
        <cfargument name="examination_id" type="string" required="no" hint="試験ID" />
        <cfargument name="examination_level_id" type="string" required="no" hint="級ID" />
        <cfargument name="school_id" type="string" required="no" hint="試験場校ID" />
        <cfargument name="user_id" type="string" required="no" hint="ユーザID" />
        <cfargument name="examination_format_id" type="string" required="no" default="0" hint="試験形式ID" />
        <cfargument name="number_of_applications" type="string" required="no" hint="申込回数" />

        <cfscript>
            // CSVデータ
            var infoData = arguments.info_data;
            var result = true;
            var errorMessage = "";
            var eNumNo = 9;
            var examineesArrsy = ArrayNew(1);
            var examineesStr = StructNew();
            var resultStr = StructNew();

            //部門別受験番号取得
            qExaminationDetailDepartmentInfo = Variables.examinationMasterGateway.getExaminationDetailDepartmentInfo(
                fiscal_year_id = arguments.fiscal_year_id,
                examination_id = arguments.examination_id,
                examination_level_id = arguments.examination_level_id
            );
            //部門の数を取得
            departmentCount = qExaminationDetailDepartmentInfo.recordCount;
            if (departmentCount eq 0) {

                infoDataLen = arrayLen(infoData);
                if (infoDataLen gte eNumNo) {
                    examineesStr = StructNew();
                    StructInsert(examineesStr, "examinees_number", Trim(infoData[eNumNo]));
                    StructInsert(examineesStr, "examination_department_id", 0);
                    ArrayAppend(examineesArrsy, examineesStr);
                } else {
                    errorMessage = "入力データが正しくありません。";
                    result = false;
                    break;
                }

            } else {
                for (val in qExaminationDetailDepartmentInfo) {
                    infoDataLen = arrayLen(infoData);
                    if (infoDataLen gte eNumNo) {
                        examineesStr = StructNew();
                        StructInsert(examineesStr, "examinees_number", Trim(infoData[eNumNo]));
                        StructInsert(examineesStr, "examination_item_id", val.examination_item_id);
                        StructInsert(examineesStr, "examination_department_id", val.examination_department_id);
                        eNumNo++;
                        ArrayAppend(examineesArrsy, examineesStr);
                    } else {
                        errorMessage = "入力データが正しくありません。";
                        result = false;
                        break;
                    }
                }
            }

            if (result) {
                var examineesLen = ArrayLen(examineesArrsy);
                for (i = 1; i <= examineesLen; i = i + 1) {
                    examineesInfo = examineesArrsy[i];
                    departmentID = examineesInfo.examination_department_id;
                    itemID = examineesInfo.examination_item_id;
                    examineesNumber = examineesInfo.examinees_number;

                    //受験番号チェック
                    if (examineesNumber neq "") {
                        if (IsRegisteredExaminationDepartment(fiscal_year_id = arguments.fiscal_year_id, examination_id = arguments.examination_id, school_id = arguments.school_id, examination_item_id = itemID, examination_level_id = arguments.examination_level_id, examination_department_id = departmentID)) {
                            errorMessage = "試験場校に設定されていない級（部門）に受験番号が入力されています。";
                            result = false;
                            break;
                        }

                        if (NOT Variables.validation.doValidation('halfNum', examineesNumber)) {
                            errorMessage = "「受験番号」には半角数字を入力してください。";
                            result = false;
                            break;
                        }

                        if (Len(examineesNumber) gt 6) {
                            errorMessage = "「受験番号」は6文字以下で入力してください。";
                            result = false;
                            break;
                        }

                        //決済済チェック
                        var checkExamineesPaymentResult = checkExamineesPayment(
                            fiscal_year_id = arguments.fiscal_year_id,
                            examination_id = arguments.examination_id,
                            examination_level_id = arguments.examination_level_id,
                            school_id = arguments.school_id,
                            user_id = arguments.user_id,
                            examination_department_id = departmentID
                        );
                        if (checkExamineesPaymentResult) {
                            errorMessage = "既に同じ部門に決済済で受験申込されています。";
                            result = false;
                            break;
                        }

                        if (arguments.examination_format_id eq Variables.ConfigExaminationFormatId.CBT) {
                            // 他の試験校、他の申し込み回で申し込んでいないかをチェックする(CBTのみ)
                            var DuplicatedCheck = checkDuplicatedApplicationCbt(
                                fiscal_year_id = arguments.fiscal_year_id,
                                examination_id = arguments.examination_id,
                                user_id = arguments.user_id,
                                examination_level_id = arguments.examination_level_id,
                                examination_department_id = departmentID,
                                number_of_applications = arguments.number_of_applications
                            );
                            if (DuplicatedCheck) {
                                errorMessage = "既に同じ検定試験の部門に登録されています。";
                                result = false;
                                break;
                            }
                        }
                    }

                }

            }

            StructInsert(resultStr, "result", result);
            StructInsert(resultStr, "error_message", errorMessage);
        </cfscript>

        <cfreturn resultStr />
    </cffunction>

    <!--- 試験場校で承認されている部門か --->
    <cffunction name="IsRegisteredExaminationDepartment" access="public" returntype="boolean" output="false"  hint="">
        <cfargument name="fiscal_year_id" type="string" required="no" hint="年度ID" />
        <cfargument name="examination_id" type="numeric" required="no" default="0" hint="検定試験ID" />
        <cfargument name="school_id" type="string" required="no" hint="試験場校ID" />
        <cfargument name="examination_item_id" type="string" required="no" hint="種目ID" />
        <cfargument name="examination_level_id" type="string" required="no" hint="級ID" />
        <cfargument name="examination_department_id" type="string" required="no" hint="部門ID" />
        <cfscript>
            var result = true;
            var qSelect = "";
        </cfscript>

        <cfquery name="qSelect" datasource="#Variables.DSN#">
            SELECT
                stced.examination_department_id
            FROM
                SCHOOL_TESTING_CENTRE_EXAMINATION_DEPARTMENT AS stced
            WHERE
                (1 = 1)
                AND stced.fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND stced.school_id = <cfqueryparam value="#arguments.school_id#" cfsqltype="cf_sql_integer" />
                AND stced.examination_id = <cfqueryparam value="#arguments.examination_id#" cfsqltype="cf_sql_integer" />
                AND stced.examination_item_id = <cfqueryparam value="#arguments.examination_item_id#" cfsqltype="cf_sql_integer" />
                AND stced.examination_department_id = <cfqueryparam value="#arguments.examination_department_id#" cfsqltype="cf_sql_integer" />
        </cfquery>

        <cfif qSelect.RecordCount GT 0>
            <cfset result = false />
        </cfif>
        <cfreturn result />
    </cffunction>


    <!--- 検定試験IDが存在するか --->
    <cffunction name="IsRegisteredExaminationID" access="public" returntype="boolean" output="no"  hint="[private]学校IDが登録済みか">
        <cfargument name="fiscal_year_id" type="string" required="no" hint="年度ID" />
        <cfargument name="examination_id" type="numeric" required="no" default="0" hint="検定試験ID" />
        <cfscript>
            var result = true;
            var qSelect = "";
        </cfscript>
        <cfquery name="qSelect" datasource="#Variables.DSN#">
            SELECT
                examination_id
            FROM
                EXAMINATION_MASTER
            WHERE
                fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND examination_id = <cfqueryparam value="#arguments.examination_id#" cfsqltype="cf_sql_integer" />
        </cfquery>
        <cfif qSelect.RecordCount GT 0>
            <cfset result = false />
        </cfif>
        <cfreturn result />
    </cffunction>

    <!--- 級IDが存在するか --->
    <cffunction name="IsRegisteredExaminationLevelID" access="public" returntype="boolean" output="no"  hint="[private]学校IDが登録済みか">
        <cfargument name="examination_level_id" type="string" required="no" hint="級ID" />
        <cfscript>
            var result = true;
            var qSelect = "";
        </cfscript>
        <cfquery name="qSelect" datasource="#Variables.DSN#">
            SELECT
                examination_level_id
            FROM
                EXAMINATION_LEVEL_MASTER
            WHERE
                examination_level_id = <cfqueryparam value="#arguments.examination_level_id#" cfsqltype="cf_sql_integer" />
        </cfquery>
        <cfif qSelect.RecordCount GT 0>
            <cfset result = false />
        </cfif>
        <cfreturn result />
    </cffunction>

    <!--- 学校コードが存在するか --->
    <cffunction name="IsRegisteredSchoolCode" access="public" returntype="boolean" output="no"  hint="[private]学校IDが登録済みか">
        <cfargument name="fiscal_year_id" type="string" required="no" hint="年度ID" />
        <cfargument name="school_code" type="string" required="no" hint="学校ID" />
        <cfscript>
            var result = true;
            var qSelect = "";
        </cfscript>
        <cfquery name="qSelect" datasource="#Variables.DSN#">
            SELECT
                school_id
            FROM
                SCHOOL_MASTER
            WHERE
                fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                -- 先頭0付の文字列の場合0を削除して比較する
                AND STUFF (
                    school_code,
                    1,
                    PATINDEX ('%[^0]%', school_code) - 1,
                    ''
                ) = STUFF (
                    <cfqueryparam value="#arguments.school_code#" cfsqltype="cf_sql_varchar" />,
                    1,
                    PATINDEX ('%[^0]%', <cfqueryparam value="#arguments.school_code#" cfsqltype="cf_sql_varchar" />) - 1,
                    ''
                )
        </cfquery>
        <cfif qSelect.RecordCount GT 0>
            <cfset result = false />
        </cfif>
        <cfreturn result />
    </cffunction>

    <!--- ユーザが存在するか --->
    <cffunction name="IsRegisteredUser" access="public" returntype="boolean" output="no"  hint="[private]学校IDが登録済みか">
        <cfargument name="user_id" type="string" required="no" hint="ユーザID" />
        <cfargument name="login_id" type="string" required="no" hint="個人ID" />
        <cfscript>
            var result = true;
            var qSelect = "";
        </cfscript>
        <cfquery name="qSelect" datasource="#Variables.DSN#">
            SELECT
                user_id
            FROM
                UTH_USER_DELETOR_VALID_VIEW
            WHERE
                user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer" />
                AND login_id = <cfqueryparam value="#arguments.login_id#" cfsqltype="cf_sql_varchar" /> COLLATE Japanese_CS_AS_KS_WS
        </cfquery>
        <cfif qSelect.RecordCount GT 0>
            <cfset result = false />
        </cfif>
        <cfreturn result />
    </cffunction>



    <!--- 支払方法名称からID取得 --->
    <cffunction name="getPaymentTypeIdByName" access="public" returntype="string" output="false"  hint="性別名称からID取得">
        <cfargument name="payment_type_name" type="string" required="yes" hint="文字列" />
        <cfscript>
            var paymentTypeName = arguments.payment_type_name;
            var qSelect = "";
            var returnId = "";
        </cfscript>

<cfquery name="qSelect" datasource="#Variables.DSN#">
    SELECT
        *
    FROM
        PAYMENT_TYPE_MASTER
    WHERE
        payment_type_name = <cfqueryparam value="#paymentTypeName#" cfsqltype="cf_sql_varchar" />
</cfquery>

<cfif qSelect.recordCount eq 1>
    <cfset returnId = qSelect.payment_type_id />
</cfif>
<cfreturn returnId/>
</cffunction>

    <!--- 受験申込情報取得 --->
    <cffunction name="getExaminationApplicationQuery" access="public" returntype="query" output="no" hint="受験申込のクエリを返す">
        <cfargument name="fiscal_year_id" type="string" required="no" hint="年度ID" />
        <cfargument name="school_id" type="string" required="no" hint="試験場校ID" />
        <cfargument name="examination_id" type="string" required="no" hint="試験ID" />
        <cfargument name="number_of_applications" type="string" required="no" hint="申込回数" />
        <cfargument name="examination_format_id" type="string" required="no" default="0" hint="試験形式ID" />
        <cfscript>
            var qSelect = "";
        </cfscript>
        <cfquery name="qSelect"  datasource="#Variables.DSN#">
            SELECT
                ep.fiscal_year_id,
                ep.school_id,
                ep.examination_id,
                ep.number_of_applications,
                ep.payment_type_id,
                ptm.payment_type_name
            FROM
                <!--- 試験形式によって取得元を分岐 --->
                <cfif arguments.examination_format_id eq Variables.ConfigExaminationFormatId.CBT>
                    EXAMINATION_APPLICATION_CBT AS ep
                <cfelse>
                    EXAMINATION_APPLICATION AS ep
                </cfif>
                INNER JOIN PAYMENT_TYPE_MASTER AS ptm ON (
                    ep.payment_type_id = ptm.payment_type_id
                )
            WHERE
                ep.fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND ep.school_id = <cfqueryparam value="#arguments.school_id#" cfsqltype="cf_sql_integer" />
                AND ep.number_of_applications = <cfqueryparam value="#arguments.number_of_applications#" cfsqltype="cf_sql_integer" />
                AND ep.examination_id = <cfqueryparam value="#arguments.examination_id#" cfsqltype="cf_sql_integer" />
        </cfquery>
        <cfreturn qSelect />
    </cffunction>


    <!--- 申込期間か --->
    <cffunction name="checkApplicationPeriod" access="public" returntype="boolean" output="no"  hint="[private]学校IDが登録済みか">
        <cfargument name="fiscal_year_id" type="string" required="no" hint="年度ID" />
        <cfargument name="examination_id" type="string" required="no" hint="試験ID" />
        <cfscript>
            var result = true;
            var qSelect = "";
            var nowDate = Now();
        </cfscript>
        <cfquery name="qSelect" datasource="#Variables.DSN#">
            SELECT
                examination_id
            FROM
                EXAMINATION_MASTER
            WHERE
                fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND examination_id = <cfqueryparam value="#arguments.examination_id#" cfsqltype="cf_sql_varchar" />
                AND <cfqueryparam value="#nowDate#" cfsqltype="cf_sql_timestamp" /> BETWEEN school_application_period_start_date AND school_application_period_end_date
        </cfquery>
        <cfif qSelect.RecordCount GT 0>
            <cfset result = false />
        </cfif>
        <cfreturn result />
    </cffunction>

    <!--- 決済済みの部門かチェック --->
    <cffunction name="checkExamineesPayment" access="public" returntype="boolean" output="false"  hint="[private]ユーザが該当部門に決済済か">
        <cfargument name="fiscal_year_id" type="string" required="true" hint="年度ID" />
        <cfargument name="examination_id" type="string" required="true" hint="試験ID" />
        <cfargument name="examination_level_id" type="string" required="true" hint="級ID" />
        <cfargument name="school_id" type="string" required="true" hint="試験場校ID" />
        <cfargument name="user_id" type="string" required="true" hint="ユーザID" />
        <cfargument name="examination_department_id" type="string" required="true" hint="部門ID" />
        <cfscript>
            var result = false;
        </cfscript>

        <cfquery name="qSelect" datasource="#Variables.DSN#">
            SELECT
                user_id
            FROM
                EXAMINATION_APPLICATION_USER
            WHERE
                fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND school_id = <cfqueryparam value="#arguments.school_id#" cfsqltype="cf_sql_integer" />
                AND examination_id = <cfqueryparam value="#arguments.examination_id#" cfsqltype="cf_sql_integer" />
                AND user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer" />
                AND examination_level_id = <cfqueryparam value="#arguments.examination_level_id#" cfsqltype="cf_sql_integer" />
                AND examination_department_id = <cfqueryparam value="#arguments.examination_department_id#" cfsqltype="cf_sql_integer" />
                AND personal_payment_status_id = <cfqueryparam value="#configPaymentStatusId.PAID#" cfsqltype="cf_sql_integer" />
        </cfquery>
        <cfif qSelect.RecordCount GT 0>
            <cfset result = true />
        </cfif>

        <cfreturn result />
    </cffunction>

    <!--- 同一級部門内重複チェック(CBTのみ) --->
    <cffunction name="checkDuplicatedApplicationCbt" access="private" returntype="boolean" output="false" hint="">
        <cfargument name="fiscal_year_id" type="string" required="yes" hint="" />
        <cfargument name="examination_id" type="string" required="yes" hint="" />
        <cfargument name="user_id" type="string" required="yes" hint="" />
        <cfargument name="examination_level_id" type="string" required="yes" hint="" />
        <cfargument name="examination_department_id" type="string" required="yes" hint="" />
        <cfargument name="number_of_applications" type="numeric" required="no"  hint="申込回数" />

        <cfscript>
            var result = false;
        </cfscript>

        <cfquery name="qSelect" datasource="#Variables.DSN#">
            SELECT
                *
            FROM
                EXAMINATION_APPLICATION_USER AS eau
            WHERE
                eau.fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND eau.examination_id = <cfqueryparam value="#arguments.examination_id#" cfsqltype="cf_sql_integer" />
                AND eau.user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer" />
                AND eau.examination_level_id = <cfqueryparam value="#arguments.examination_level_id#" cfsqltype="cf_sql_integer" />
                AND eau.examination_department_id = <cfqueryparam value="#arguments.examination_department_id#" cfsqltype="cf_sql_integer" />
                AND eau.number_of_applications != <cfqueryparam value="#arguments.number_of_applications#" cfsqltype="cf_sql_integer" />
        </cfquery>

        <cfif qSelect.RecordCount GT 0>
            <cfset result = true />
        </cfif>

        <cfreturn result />
    </cffunction>

       <!--- 部門（電卓か珠算）二重申込のチェック --->
    <!--- 部門（電卓か珠算）二重申込のチェック --->
    <cffunction name="checkDepartment" access="public" returntype="struct" output="false" hint="">
        <cfargument name="fiscal_year_id" type="numeric" required="yes" hint="" />
        <cfargument name="examination_id" type="numeric" required="yes" hint="" />
        <cfargument name="examination_level_id" type="numeric" required="yes" hint="" />
        <cfargument name="user_id" type="numeric" required="yes" />
        <cfargument name="school_id" type="numeric" required="no" default="0" hint="学校ID">
        <cfargument name="examination_department_origin_id" type="numeric" required="yes" hint="" />
        <cfargument name="number_of_applications" type="numeric" required="yes" hint="" />
        <cfargument name="examination_format_id" type="numeric" required="no" default="0" hint="試験形式ID" />

        <!--- 対象部門情報を取得（ユーザーが申し込もうとしている部門） --->
        <cfquery name="qTargetDepartment" datasource="#Variables.DSN#">
            SELECT
                edm.examination_level_id,
                edom.examination_department_origin_id,
                edm.examination_department_name
            FROM
                EXAMINATION_MASTER AS em
                INNER JOIN EXAMINATION_ITEM_MASTER AS eim ON (
                    em.fiscal_year_id = eim.fiscal_year_id
                    AND em.examination_item_id = eim.examination_item_id
                )
                INNER JOIN EXAMINATION_DEPARTMENT_MASTER AS edm ON (
                    eim.fiscal_year_id = edm.fiscal_year_id
                    AND eim.examination_item_id = edm.examination_item_id
                )
                INNER JOIN EXAMINATION_DEPARTMENT AS ed ON (
                    edm.fiscal_year_id = ed.fiscal_year_id
                    AND edm.examination_department_id = ed.examination_department_id
                    AND edm.examination_item_id = ed.examination_item_id
                )
                INNER JOIN EXAMINATION_DEPARTMENT_ORIGIN_MASTER AS edom ON (
                    ed.examination_department_origin_id = edom.examination_department_origin_id
                )
            WHERE
                em.fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND em.examination_id = <cfqueryparam value="#arguments.examination_id#" cfsqltype="cf_sql_integer" />
                AND edom.examination_department_origin_id = <cfqueryparam value="#arguments.examination_department_origin_id#" cfsqltype="cf_sql_integer" />
                AND edm.examination_level_id = <cfqueryparam value="#arguments.examination_level_id#" cfsqltype="cf_sql_integer" />
        </cfquery>

        <!--- ユーザーの既存申し込みチェック（異なる回・支払い済み） --->
        <cfquery name="qCheckOtherApplications" datasource="#Variables.DSN#">
            SELECT
                eau.examination_department_id,
                edm.examination_department_name,
                edom.examination_department_origin_id,
                eau.examination_level_id,
                um.last_name,
                um.first_name
            FROM
                EXAMINATION_APPLICATION_USER AS eau
                INNER JOIN EXAMINATION_MASTER AS em ON em.fiscal_year_id = eau.fiscal_year_id
                AND em.examination_id = eau.examination_id
                INNER JOIN EXAMINATION_DEPARTMENT_MASTER AS edm ON edm.fiscal_year_id = eau.fiscal_year_id
                AND edm.examination_department_id = eau.examination_department_id
                AND edm.examination_level_id = eau.examination_level_id
                AND edm.examination_item_id = em.examination_item_id
                INNER JOIN EXAMINATION_DEPARTMENT AS ed ON edm.fiscal_year_id = ed.fiscal_year_id
                AND edm.examination_department_id = ed.examination_department_id
                AND edm.examination_item_id = ed.examination_item_id
                INNER JOIN EXAMINATION_DEPARTMENT_ORIGIN_MASTER AS edom ON ed.examination_department_origin_id = edom.examination_department_origin_id
                INNER JOIN UTH_USER_MASTER AS um ON um.user_id = eau.user_id
                <cfif arguments.examination_format_id eq Variables.ConfigExaminationFormatId.CBT>
                    INNER JOIN EXAMINATION_APPLICATION_CBT AS eac ON (
                        eau.fiscal_year_id = eac.fiscal_year_id
                        AND eau.school_id = eac.school_id
                        AND eau.examination_id = eac.examination_id
                        AND eau.number_of_applications = eac.number_of_applications
                    )
                </cfif>
            WHERE
                eau.fiscal_year_id = <cfqueryparam value="#fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND eau.examination_id = <cfqueryparam value="#examination_id#" cfsqltype="cf_sql_integer" />
                AND eau.examination_level_id = <cfqueryparam value="#examination_level_id#" cfsqltype="cf_sql_integer" />
                AND eau.user_id = <cfqueryparam value="#user_id#" cfsqltype="cf_sql_integer" />
                AND edom.examination_department_origin_id IN (1, 2) <!--- 電卓、珠算の部門のみ --->
                AND eau.number_of_applications <> <cfqueryparam value="#number_of_applications#" cfsqltype="cf_sql_integer" />
                AND eau.personal_payment_status_id = <cfqueryparam value="#Variables.configPaymentStatusId.PAID#" cfsqltype="cf_sql_integer" />
        </cfquery>

        <cfscript>
            var result = {
                result: true,
                message: ""
            };
            var isDuplicate = false;
            var userQuery = "";
            //同じ回も異なる回も同じクエリで確認できるので、同じ回のチェックは削除した
            // 異なる回での申し込みをチェック //異部門のみ NG
            if (qCheckOtherApplications.recordCount > 0) {
                isDuplicate = true;
                userQuery = qCheckOtherApplications;
            }

            if (isDuplicate) {
                var targetDeptName = qTargetDepartment.examination_department_name;
                var targetLevel = qTargetDepartment.examination_level_id;
                var existingDeptName = userQuery.examination_department_name;
                var existingLevel = userQuery.examination_level_id;

                result.result = false;
                result.message = "既に" & existingLevel & "級" & existingDeptName & "に申し込んでいるため、" &
                    targetLevel & "級" & targetDeptName & "には申込できません。";
            }
        </cfscript>
        <cfreturn result />
    </cffunction>

    <!--- 二重申込を防ぐ --->
    <cffunction name="firstcheckDepartment" access="private" returntype="struct" output="false" hint="ビジネス計算試験の部門重複チェック">
        <cfargument name="fiscal_year_id" type="numeric" required="yes" hint="" />
        <cfargument name="examination_department_id" type="numeric" required="no" hint="" />
        <cfargument name="number_of_applications" type="numeric" required="no" hint="申込回数" />
        <cfargument name="examination_level_id" type="numeric" required="no" hint="級" />
        <cfargument name="examination_format_id" type="numeric" required="no" default="0" hint="試験形式ID" />
        <cfargument name="school_id" type="numeric" required="no" default="0" hint="学校ID">
        <cfargument name="info_Data" type="array" required="yes" hint="CSVデータ" />

        <cfscript>
            // 受験申込データ
            var infoData = arguments.info_Data;
            var examinationID = Trim(infoData[1]);
            var examinationLevelID = Trim(infoData[2]);
            var schoolCode = Trim(infoData[3]);
            var userID = Trim(infoData[4]);
            var loginID = Trim(infoData[5]);
            var paymentTypeName = Trim(infoData[8]);

            // ビジネス計算試験用(部門データ初期化)
            var shoolID = arguments.school_id
            var abacus = "";
            var calculator = "";

            var qCheckExmination = "";
            var qExaminationDetailDepartmentInfo = "";
            var departmentValue = "";
            var checkDepartmentResult = "";

            // 申込情報を削除するを含めてのフラグを初期化
            var result = {
                result: true,
                errorMessage: "",
                deleteFlagAbacus: false,
                deleteFlagCalculator: false
            };
        </cfscript>

        <!--- ビジネス計算試験かどうかを判定 --->
        <cfquery name="qCheckExmination" datasource="#Variables.DSN#">
            SELECT
                ei.examination_item_origin_id,
                em.examination_id
            FROM
                EXAMINATION_MASTER AS em
                INNER JOIN EXAMINATION_DEPARTMENT_MASTER AS edm ON edm.fiscal_year_id = em.fiscal_year_id
                AND edm.examination_item_id = em.examination_item_id
                INNER JOIN EXAMINATION_ITEM AS ei ON ei.fiscal_year_id = edm.fiscal_year_id
                AND ei.examination_item_id = edm.examination_item_id
            WHERE
                em.fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND em.examination_id = <cfqueryparam value="#examinationID#" cfsqltype="cf_sql_integer" />
        </cfquery>

        <cfscript>
            // ビジネス計算試験の場合のみチェックを実行
            if (qCheckExmination.recordCount GT 0 AND qCheckExmination.examination_item_origin_id eq 1) {

                // 部門別情報を取得
                qExaminationDetailDepartmentInfo = Variables.examinationMasterGateway.getExaminationDetailDepartmentInfo(
                    fiscal_year_id = arguments.fiscal_year_id,
                    examination_id = examinationID,
                    examination_level_id = arguments.examination_level_id
                );

                // 部門ごとの申し込みデータを取得
                for (row in qExaminationDetailDepartmentInfo) {
                    switch (row.examination_department_origin_id) {
                        case 1: // 珠算
                            abacus = Trim(infoData[9]);
                            break;
                        case 2: // 電卓
                            calculator = Trim(infoData[10]);
                            break;
                        default:
                            // 何もしない
                            break;
                    }
                }

                // CSV入力時点で珠算と電卓の同時申し込みを禁止
                if (abacus != ""
                    and calculator != "") {
                    result.result = false;
                    result.errorMessage = "普通計算（珠算）と普通計算（電卓）を同時に申込できません。";
                    return result;
                }
                // CSV中の部門カラムに値があるかないかを確認、なければユーザー情報を削除として扱う・珠算と電卓の両方に対してチェックを行う
                //珠算1 電卓2
                var examination_department_origin_id_1 = 1;
                var examination_department_origin_id_2 = 2;

                for (row in qExaminationDetailDepartmentInfo) {
                    switch (row.examination_department_origin_id) {
                        case examination_department_origin_id_1:
                            departmentValue = Trim(infoData[9]); // CSV値を直接使用
                            if (len(trim(departmentValue)) eq 0) {
                                // 珠算が空 → 削除予定フラグをON
                                result.deleteFlagAbacus = true;
                            }
                            break;

                        case examination_department_origin_id_2:
                            departmentValue = Trim(infoData[10]); // CSV値を直接使用
                            if (len(trim(departmentValue)) eq 0) {
                                // 電卓が空 → 削除予定フラグをON
                                result.deleteFlagCalculator = true;
                            }
                            break;

                        default:
                            departmentValue = "";
                            break;
                    }
                }
                //削除か更新（受験番号書き換え）かを同時に確認するために、両方のフラグを確認
                if (!result.deleteFlagAbacus) {
                    //珠算と電卓に対して既に申し込んでいるかを確認、申し込んでいればエラーとする

                    // 申し込みがない部門は削除対象なのでチェックしない 申し込みがある部門のみチェック
                    checkDepartmentResult = checkDepartment(
                        fiscal_year_id = arguments.fiscal_year_id,
                        examination_id = examinationID,
                        examination_level_id = examinationLevelID,
                        user_id = userId,
                        school_id = shoolID,
                        examination_department_origin_id = examination_department_origin_id_1, // 珠算
                        number_of_applications = arguments.number_of_applications,
                        examination_format_id = arguments.examination_format_id
                    );

                    if (!checkDepartmentResult.result) {
                        result.result = false;
                        result.errorMessage = checkDepartmentResult.message;
                        return result;
                    }

                }

                if (!result.deleteFlagCalculator) {
                    //珠算と電卓に対して既に申し込んでいるかを確認、申し込んでいればエラーとする

                    checkDepartmentResult = checkDepartment(
                        fiscal_year_id = arguments.fiscal_year_id,
                        examination_id = examinationID,
                        examination_level_id = examinationLevelID,
                        user_id = userId,
                        school_id = shoolID,
                        examination_department_origin_id = examination_department_origin_id_2, // 電卓
                        number_of_applications = arguments.number_of_applications,
                        examination_format_id = arguments.examination_format_id
                    );

                    if (!checkDepartmentResult.result) {
                        result.result = false;
                        result.errorMessage = checkDepartmentResult.message;
                        return result;
                    }

                }

            }
            return result;
        </cfscript>
    </cffunction>

    </cfprocessingdirective>
</cfcomponent>