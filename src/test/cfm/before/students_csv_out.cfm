<!---
    Name         : zenms/manager/import/students_csv_out.cfm
    Author       : Misato Morita
    Created      : 2024/01/23
    Last Updated :
    History      : 2024/03/27 一時ファイル名を変更（Misato Morita）
    Purpose      : 生徒情報確認・登録画面のCSV出力
--->
<!--- 当レスポンスの取り扱い設定 --->
<cfsetting requesttimeout="600" />

<!--- 当ページ全体の文字コード設定 --->
<cfprocessingdirective pageencoding="UTF-8" suppresswhitespace="yes">
<cftry>

    <!--- データソース設定 --->
    <cfset DSN = Application.DSN />

    <!--- zenms_cfcへのパス --->
    <cfset SERVICE_ADDRESS = Application.SERVICE_ADDRESS />
    <cfset COMMON_SERVICE_ADDRESS = Application.COMMON_SERVICE_ADDRESS />

    <!--- スクリプト --->
    <cfset session.ComPercent = 0 />
    <cfscript>
        /*
         * コンポーネント読み込み
         */
        stringUtil = CreateObject("component","#COMMON_SERVICE_ADDRESS#.StringUtil").init();

        // 検索クエリを発行するコンポーネント
        dataGateway = CreateObject("component","#SERVICE_ADDRESS#.manager.StudentsGateway").init(
            DSN=DSN,
            SERVICE_ADDRESS=SERVICE_ADDRESS,
            COMMON_SERVICE_ADDRESS=COMMON_SERVICE_ADDRESS
        );

        // 検索クエリを発行するコンポーネント
        dataAjaxGateway = CreateObject("component","#DSN#.manager.ajax_gateway.StudentsAjaxGateway");

        // 識別情報を取得するコンポーネント
        shoolIdentification = CreateObject("component","#DSN#.manager.ajax_gateway.SchoolIdentificationAjaxGateway");

        // 和暦クエリ
        japaneseCalendarMasterGateway = CreateObject("component","#SERVICE_ADDRESS#.JapaneseCalenderMasterGateway").init(DSN=DSN);

        // ユーザー権限定数
        configAuthorityId = CreateObject("component","#SERVICE_ADDRESS#.ConfigAuthorityID").init();

        // ユーザー権限取得
        userAuthorityGateway = CreateObject("component","#SERVICE_ADDRESS#.UserAuthorityGateway").init(DSN=DSN);
        quserAuthority = userAuthorityGateway.getUserAuthorityInfo(user_id=Session.userID, authority_id=configAuthorityId.ALL_COMMERCE_ASSOCIATION);
        allAuthority = (quserAuthority.RecordCount neq 0)? true: false;

        //ログ出力処理のcfc
        LogOutputcfc = CreateObject("component","#COMMON_SERVICE_ADDRESS#.LogOutput").init();

        // CSV処理
        Variables.CSVUtil = CreateObject("component","#COMMON_SERVICE_ADDRESS#.CSVUtil");

        csvFlag = true;

        // ページ番号（必須）
        current = 0;
        // 表示件数（必須）
        rowCount = 0;
        // 総件数（必須）
        total = 0;
        //検索テキスト
        searchPhrase = "";

        /*
         * 以下固有条件の初期値
         */
        sortItem = 1;
        sortOrder = "";
        // ページ番号取得
        if (StructKeyExists(FORM, "current")) {
            current = FORM["current"];
        }

        // 表示件数取得
        if (StructKeyExists(FORM, "rowCount")) {
            rowCount = FORM["rowCount"];
        }

        //total
        if(StructKeyExists(FORM, "total")) {
            total = FORM["total"];
        }

        //searchPhrase
        if(StructKeyExists(FORM, "searchPhrase")) {
            searchPhrase = FORM["searchPhrase"];
        }

        if(StructKeyExists(FORM, "sort")) {
            sortItem = FORM["sort"];
        }

        //並び替え順設定
        switch(sortItem) {
            case 1:
                sortorder = "DESC";
        break;
            case 2:
                sortorder = "ASC";
        break;
        }

        /* ここから検索条件個別各画面で引数が変わる。*/
        FiscalYearId               = '';
        SchoolCode                 = '';
        SchoolId                   = '';
        LastName                   = '';
        FirstName                  = '';
        LoginId                    = '';
        SchoolCourseId             = 'all';
        DepartmentId               = 'all';
        GradeInSchoolID            = 'all';
        class                      = '';
        StudentsEnrollmentStatusId = '1';
        TransferStatus             = '0';
        InputValue                 = arrayNew(1);

        // 年度
        if(StructKeyExists(FORM, "search-fiscal-year-id")) {
            FiscalYearId = FORM['search-fiscal-year-id'];
        }
        // 学校コード
        if(StructKeyExists(FORM, "search-school_code")) {
            SchoolCode = FORM['search-school_code'];
        }
        // 学校ID
        if(StructKeyExists(FORM, "search-school_id")) {
            SchoolId = FORM['search-school_id'];
        }
        // 氏名 姓
        if(StructKeyExists(FORM, "search-last_name")) {
            LastName = FORM['search-last_name'];
        }
        // 氏名 名
        if(StructKeyExists(FORM, "search-first_name")) {
            FirstName = FORM['search-first_name'];
        }
        // 個人ID
        if(StructKeyExists(FORM, "search-login_id")) {
            LoginId = FORM['search-login_id'];
        }
        // 課程 all:全て
        if(StructKeyExists(FORM, "search-school_course_id")) {
            SchoolCourseId = FORM['search-school_course_id'];
        }
        // 学科 all:全て
        if(StructKeyExists(FORM, "search-department_id")) {
            DepartmentId = FORM['search-department_id'];
        }
        // 学年 all:全て、11:前年度卒業
        if(StructKeyExists(FORM, "search-grade_in_school_id")) {
            GradeInSchoolID = FORM['search-grade_in_school_id'];
        }
        // 組
        if(StructKeyExists(FORM, "search-class")) {
            class = FORM['search-class'];
        }
        // 在籍情報  all:全て
        if(StructKeyExists(FORM, "search-students_enrollment_status_id")) {
            StudentsEnrollmentStatusId = FORM['search-students_enrollment_status_id'];
        }
        // 転出状況(未チェックで無取得)
        if(StructKeyExists(FORM, "search-transfer_status")) {
            TransferStatus = FORM['search-transfer_status'];
        }

        // 識別情報 存在しない場合あり
        key = StructKeyArray(FORM);
        for (name in key) {
            // 識別情報の場合
            if (find("SEARCH-INPUT_VALUE[",name) neq 0) {
                if(StructKeyExists(FORM, name)) {
                    // ID取得
                    id = replace(name,"SEARCH-INPUT_VALUE[","","all");
                    id = replace(id,"]","","all");

                    // 配列格納
                    array = StructNew();
                    StructInsert(array, "id" ,id);
                    StructInsert(array, "data" , FORM[name]);
                    ArrayAppend(InputValue, array, "true");
                }
            }
        }
    </cfscript>

    <!--- 検索処理実行 --->
    <cfset result = dataGateway.doSearch(
        current=current
        ,row_count=rowCount
        ,sort_item=sortItem
        ,sortorder=sortOrder
        ,search_phrase=searchPhrase
        ,do_count_record=false

        ,fiscal_year_id=FiscalYearId
        ,school_code=SchoolCode
        ,school_id=SchoolId
        ,last_name=LastName
        ,first_name=FirstName
        ,login_id=LoginId
        ,school_course_id=SchoolCourseId
        ,department_id=DepartmentId
        ,grade_in_school_id=GradeInSchoolID
        ,class=class
        ,students_enrollment_status_id=StudentsEnrollmentStatusId
        ,transfer_status=TransferStatus
        ,input_value=InputValue

        ,grid_flag = true
    ) />

    <cfset csvData = "" />
    <cfset changingLine = Chr(13) & Chr(10) />

    <!--- 日付の取得--->
    <cfscript>
        update = now();
        filedate = dateformat(update,"yymmdd");
        filetime = timeformat(update,"HHmm");
    </cfscript>

    <cfset csvFileName = "生徒情報_" & filedate & filetime & ".csv" />
    <cfset headerString = "ユーザID,学校名,在籍状況,氏名（姓）,氏名（名）,氏名（かな）（姓）,氏名（かな）（名）,氏名（ローマ字）（姓）,氏名（ローマ字）（名）,性別,個人ID,メールアドレス,備考（ユーザごと）,生徒情報更新日,パスワード,【英語検定以外】の合格証書氏名空欄希望,【英語検定】の合格証書氏名空欄希望,課程,学科,学年,組,番号,生年月日" />
    <cfset headerArray = listToArray(headerString) />

    <!--- 識別情報 --->
    <cfset Identification = shoolIdentification.getDisplayInfo(fiscal_year_id=FiscalYearId, school_id=schoolID) />
    <cfset IdentificationData = DeserializeJSON(Identification) />
    <cfset IdentificationList = IdentificationData.data.list />
    <cfset count = 1 />
    <cfloop array="#IdentificationList#" index="idx">
        <!--- 識別情報の数分、識別情報を出力--->
        <cfscript>
            if (count neq 11) {
                arrayPush(headerArray, idx.item_name);
                count = count + 1;
            }
        </cfscript>
    </cfloop>
    <cfloop index="i" from="#count#" to="10">
        <cfscript>
            arrayPush(headerArray, "識別情報"& i);
        </cfscript>
    </cfloop>

    <cfscript>
        arrayPush(headerArray, "口座登録があるか");
        arrayPush(headerArray, "口座情報更新日");
    </cfscript>

    <!--- 以降は、全商権限時のみ出力される --->
    <cfif allAuthority>
        <!--- 振込先種別の数分、口座情報を出力--->
        <cfscript>
            arrayPush(headerArray, "郵便番号");
            arrayPush(headerArray, "都道府県");
            arrayPush(headerArray, "住所1");
            arrayPush(headerArray, "住所2");
            arrayPush(headerArray, "住所3");
            arrayPush(headerArray, "自宅電話番号");
            arrayPush(headerArray, "自宅FAX番号");
            arrayPush(headerArray, "携帯電話番号");
        </cfscript>
    </cfif>

    <cfset affiliationUserCsvData = [] />

    <!--- タイムアウトをセット --->
    <cfsetting requesttimeout="600" />

    <!--- データの出力 --->
    <cfset csvArray = [] >
    <cfloop query="result">

        <cfscript>
            rowArray = []

            // ユーザID
            arrayPush(rowArray, result.user_id);
            // 学校名
            arrayPush(rowArray, result.school_name);
            // 在籍状況
            arrayPush(rowArray, result.students_enrollment_status_name);
            // 氏名（姓）
            arrayPush(rowArray, result.last_name);
            // 氏名（名）
            arrayPush(rowArray, result.first_name);
            // 氏名（かな）（姓）
            arrayPush(rowArray, result.last_name_kana);
            // 氏名（かな）（名）
            arrayPush(rowArray, result.first_name_kana);
            // 氏名（ローマ字）（姓）
            arrayPush(rowArray, result.last_name_roman);
            // 氏名（ローマ字）（名）
            arrayPush(rowArray, result.first_name_roman);

            // 性別
            arrayPush(rowArray, result.sex_name);
            // 個人ID
            arrayPush(rowArray, result.login_id);
            // メールアドレス
            arrayPush(rowArray, result.mailaddress);
            // 備考（ユーザごと）
            arrayPush(rowArray, result.remarks);
            // 生徒情報更新日
            arrayPush(rowArray, result.update_date_view);
            // パスワード
            arrayPush(rowArray, result.password);
            // 合格証書の氏名（姓名両方）の空欄希望
            isCertificateNameBlank = (result.is_certificate_name_blank neq 1)? '希望しない' : '希望する';
            arrayPush(rowArray, isCertificateNameBlank);
            // 合格証書の氏名(ローマ字)（姓名両方）の空欄希望
            isCertificateNameRomanBlank = (result.is_certificate_name_roman_blank neq 1)? '希望しない' : '希望する';
            arrayPush(rowArray, isCertificateNameRomanBlank);
            // 課程
            arrayPush(rowArray, result.school_course_nama);
            // 学科
            arrayPush(rowArray, result.school_department_name);
            // 学年
            arrayPush(rowArray, result.grade_in_school_name);
            // 組
            arrayPush(rowArray, result.class);
            // 番号
            arrayPush(rowArray, result.student_number);
            // 生年月日
            birthdayTxt = '';
            if (result.birthday neq '') {
                birthdayView = japaneseCalendarMasterGateway.westernCalenderToJapaneseCalender(date_data=result.birthday);
                birthdayTxt = birthdayView.era_name_name & birthdayView.japanese_calendar_year_text &'年'& birthdayView.date_data_month &'月'& birthdayView.date_data_day&'日'
            }
            arrayPush(rowArray, birthdayTxt);
        </cfscript>

        <!--- 識別情報 --->
        <cfset count = 1 />
        <cfset IdentificationInfo = dataAjaxGateway.getIdentificationInfoResult(user_id=result.user_id, fiscal_year_id=FiscalYearId, school_id=schoolID) />
        <cfloop query="IdentificationInfo">
            <cfscript>
                if (count neq 11) {
                    arrayPush(rowArray, IdentificationInfo.input_value);
                    count = count + 1;
                }
            </cfscript>
        </cfloop>
        <cfloop index="i" from="#count#" to="10">
            <cfscript>
                arrayPush(rowArray, "");
            </cfscript>
        </cfloop>

        <cfscript>
            // 口座登録があるか
            arrayPush(rowArray, result.transfer_flg);
            // 口座情報更新日
            arrayPush(rowArray, result.transfer_update_date_view);
        </cfscript>

        <!--- 以降は、全商権限時のみ出力される --->
        <cfif allAuthority>
            <cfscript>
                // 郵便番号
                arrayPush(rowArray, result.zip_code);
                // 都道府県
                arrayPush(rowArray, result.prefecture_name);
                // 住所1
                arrayPush(rowArray, result.address1);
                // 住所2
                arrayPush(rowArray, result.address2);
                // 住所3
                arrayPush(rowArray, result.address3);
                // 自宅電話番号
                arrayPush(rowArray, result.tel);
                // 自宅FAX番号
                arrayPush(rowArray, result.fax);
                // 携帯電話番号
                arrayPush(rowArray, result.tel_mobile);
            </cfscript>
        </cfif>

        <cfscript>
            // CSVデータを格納する配列に行のデータ追加
            arrayPush(csvArray, rowArray)
        </cfscript>
    </cfloop>

    <cfset tempPath = ExpandPath("../temp") />
    <!--- 一時フォルダが存在しなかったら作成 --->
    <cfif not DirectoryExists( tempPath )>
        <!--- なければ作成 --->
        <cfdirectory directory="#tempPath#" action="create" mode="777">
    </cfif>
    <cfset tempFilePath = tempPath & "/csv_out_content_check_" & Session.userID & "_" & timeformat(update,"HHmmssl") & ".csv">
    <cfset Variables.CSVUtil.writeCSVFile(filepath=tempFilePath, filecontent=csvArray, fileheader=headerArray) />

    <cfset session.ComPercent = 100 />
    <cfheader name="Content-Disposition" value="attachment;filename=#csvFileName#" >
    <cfcontent type="text/csv; charset=Windows-31J" deletefile="yes" file="#tempFilePath#">

    <cfcatch type="any">
        <cfscript>
            //cfcatch時、cflogを出力する
            LogOutputcfc.outputCFCatchToCFLog(
                application_name=Application.applicationname,
                script_name=CGI.SCRIPT_NAME,
                cfcatch_var=cfcatch
            );
        </cfscript>
        <cfdump var="#cfcatch#" />
    </cfcatch>
</cftry>
</cfprocessingdirective>