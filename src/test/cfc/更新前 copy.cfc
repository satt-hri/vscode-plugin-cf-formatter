<!---
	Name         : manager\import\teacher_delete_sample_csv_out.cfm
	Author       : EN
	Created      : 2025/09/07
	Last Updated : 
	History      : 
	Purpose      : 教員一括削除情報リストインポートのサンプルExcel出力処理
--->

<cfprocessingdirective pageencoding="UTF-8">
<cfprocessingdirective suppresswhitespace="yes">

<cftry>
	<cfset DSN = Application.DSN />
	<cfset SERVICE_ADDRESS = Application.SERVICE_ADDRESS />
	<cfset COMMON_SERVICE_ADDRESS = Application.COMMON_SERVICE_ADDRESS />
	<cfquery>
		SELECT
			123
	</cfquery>
	<cfscript>
		LogOutputcfc = CreateObject("component", "#COMMON_SERVICE_ADDRESS#.LogOutput").init();
	</cfscript>

	<cfscript>
		// 識別情報 取得用
		FiscalYearId = '';
		UserId = '';
		SchoolId = '';
		// 年度
		if (StructKeyExists(FORM, "search-fiscal-year-id")) {
			FiscalYearId = FORM['search-fiscal-year-id'];
		}
		// 学校ID
		if (StructKeyExists(FORM, "search-school_id")) {
			SchoolId = FORM['search-school_id'];
		}
		// 識別情報を取得するコンポーネント
		shoolIdentification = CreateObject("component", "#DSN#.manager.ajax_gateway.SchoolIdentificationAjaxGateway");
		Identification = shoolIdentification.getDisplayInfo(fiscal_year_id = FiscalYearId, school_id = schoolID);
		IdentificationData = DeserializeJSON(Identification);
		IdentificationList = IdentificationData.data.list;
		// 一時ファイル名
		output_file_name = "教員一括削除_サンプル_" & #DateFormat(Now(), "yyyymmdd") # & #TimeFormat(Now(), "HHmmss") # & ".xlsx";
		// テンプレートファイルパス
		fileName = "教員一括削除_サンプル.xlsx";
		filePath = ExpandPath("./template");
		filePath = filePath & "\" & fileName;
		filePath = replace(filePath, "￥", "\","All");
				// 書き込み対象シート名
				sheet_name = "Sheet1";
				// テンプレートExcelを元にスプレッドシートオブジェクトを作成
				spObj = spreadsheetread(filePath, sheet_name);
				// 識別情報を書き込む
				column = 21;
				for (idx in IdentificationList) {
					if (column neq 31) {
						SpreadsheetSetCellValue(spObj, idx.item_name, 1, column);
						column = column + 1;
					}
				}
				//対象が存在しない場合
				if (column eq 23) {
					// 入力例を空に
					SpreadsheetSetCellValue(spObj, '', 2, column);
				}
	</cfscript>

	<!--- ダウンロード --->
	<cfset session.ComPercent = 100 />
	<cfheader name="Content-Disposition" value="attachment;filename=#output_file_name#">
	<cfcontent type="application/msexcel" variable="#spreadsheetReadBinary(spObj)#">


	<cfcatch type="any">
		<cfscript>
			//cfcatch時、cflogを出力する
			LogOutputcfc.outputCFCatchToCFLog(application_name = Application.applicationname, script_name = CGI.SCRIPT_NAME, cfcatch_var = cfcatch);
		</cfscript>
		<cfdump var="#cfcatch#" />
	</cfcatch>
</cftry>

</cfprocessingdirective>
