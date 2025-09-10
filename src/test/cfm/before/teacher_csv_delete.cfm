<!---
	Name         : zenms/manager/import/teacher_csv_delete.cfm
	Author       : EN
	Created      : 2025/09/07
	Last Updated : 
	History      : 
	Purpose      : 教員情報画面の一括削除CSVのインポート
--->

<!--- 当レスポンスの取り扱い設定 --->
<cfsetting requesttimeout="600" />

<!--- 当ページ全体の文字コード設定 --->
<cfprocessingdirective pageencoding="utf-8" suppresswhitespace="yes">

<cfcontent type="text/html; charset=utf-8">

<!---インジケーターを0％に初期化する--->
<cfset session.ComPercent = 0 />

<cfoutput>
	<!--- データソース設定 --->
	<cfset DSN = Application.DSN />

	<!--- zenms_cfcへのパス --->
	<cfset SERVICE_ADDRESS = Application.SERVICE_ADDRESS />
	<cfset COMMON_SERVICE_ADDRESS = Application.COMMON_SERVICE_ADDRESS />
	<cfset MIN_DATE_TIME = Application.MIN_DATE_TIME />

	<cfscript>
		//ログ出力処理のcfc
		LogOutputcfc = CreateObject("component", "#COMMON_SERVICE_ADDRESS#.LogOutput").init();

		//インポートの結果を生成するobj
		result = CreateObject("component", "#COMMON_SERVICE_ADDRESS#.CsvImportResult").init(DSN = DSN);

		stringUtil = CreateObject("component", "#COMMON_SERVICE_ADDRESS#.StringUtil").init();
		validation = CreateObject("component", "#COMMON_SERVICE_ADDRESS#.Validation").init();
		errorFlg = false;

		//セッションの確認
		sessionVal = result.getSession();
		ApplicationFormUtil = CreateObject("component", "#COMMON_SERVICE_ADDRESS#.ApplicationFormUtil").init();

		//CSV最大入力件数
		Variables.MAX_INPUT_COUNT = 2000;

		//CSV処理
		Variables.CSVUtil = CreateObject("component", "#COMMON_SERVICE_ADDRESS#.CSVUtil");

		searchFiscalYearId = '';
		if (StructKeyExists(Url, "search_fiscal_year_id")) {
			searchFiscalYearId = Url["search_fiscal_year_id"];
		}
	</cfscript>

	<!--- 削除情報取得 --->
	<cffunction name="deleteInfo" access="private" returntype="boolean" output="no"  hint="削除前チェック">
		<cfargument name="user_id" type="string" required="yes" default="0" hint="ユーザーID" />

		<cfquery name="qCheckUserExists" datasource="#Variables.DSN#">
			SELECT
				CASE
					WHEN EXISTS (
						SELECT
							1
						FROM
							EXAMINATION_APPLICATION_USER
						WHERE
							user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#userID#">
					)
					OR EXISTS (
						SELECT
							1
						FROM
							EXAMINATION_SUCCESSFUL_EXAMINEE
						WHERE
							user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#userID#">
					) THEN 1
					ELSE 0
				END AS exists_flag
		</cfquery>

		<cfif qCheckUserExists.exists_flag gt 0>
			<cfreturn true />
		</cfif>

		<cfreturn false />

	</cffunction>

	<!--- 削除処理 --->
	<cffunction name="deleteUser" access="remote" returntype="boolean" output="false" hint="指定したユーザーの全削除">
		<cfargument name="userID" type="numeric" required="true" hint="削除対象ユーザーID" />

		<cfset var result = true />

		<cftransaction>
			<cftry>

				<cfquery datasource="#Variables.DSN#">
					DELETE FROM ENROLLMENT_STATUS
					WHERE
						user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				</cfquery>
				<cfquery datasource="#Variables.DSN#">
					DELETE FROM ENROLLMENT_TRANSFER
					WHERE
						user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				</cfquery>
				<cfquery datasource="#Variables.DSN#">
					DELETE FROM IDENTIFICATION_INFORMATION
					WHERE
						user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				</cfquery>
				<cfquery datasource="#Variables.DSN#">
					DELETE FROM STUDENTS_INFORMATION
					WHERE
						user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				</cfquery>
				<cfquery datasource="#Variables.DSN#">
					DELETE FROM TEACHER_INFORMATION
					WHERE
						user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				</cfquery>
				<cfquery datasource="#Variables.DSN#">
					DELETE FROM USER_AUTHORITY
					WHERE
						user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				</cfquery>
				<cfquery datasource="#Variables.DSN#">
					DELETE FROM USER_TRANSFER_INFORMATION
					WHERE
						user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				</cfquery>
				<cfquery datasource="#Variables.DSN#">
					DELETE FROM UTH_USER_MASTER
					WHERE
						user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				</cfquery>

				<cfcatch type="any">
					<cftransaction action="rollback" />
					<cfset result = false />
				</cfcatch>
			</cftry>
		</cftransaction>

		<cfreturn result />
	</cffunction>

	<cftransaction>
		<cftry>
			<cflock name="STYDENT_CSV_DELETE" type="exclusive" timeout="600">
				<!--- インポート初期化 --->
				<cfset session.ComPercent = 0 />

				<!---  アップロードされたファイルに対する処理 --->
				<cfif (StructKeyExists( form, "Filedata" ) AND form.Filedata NEQ "")>

					<!--- OSよってディレクトリ区切り文字を設定 --->
					<!--- 現在のサーバOS --->
					<cfset currentOSName = Server.OS.Name>

					<!--- Windows以外(デフォルト) --->
					<cfset dirString = "/" />
					<cfif FindNoCase( "windows", currentOSName ) neq 0>
						<!--- Windows --->
						<cfset dirString = "\" />
					</cfif>

					<!--- アップロード先の位置は固定 --->
					<cfset contentsDirectoryPath = ExpandPath( "../temp/" )>

					<!--- アップロードフォルダが存在しなかったら作成 --->
					<cfif not DirectoryExists( contentsDirectoryPath )>

						<!--- なければ作成 --->
						<cfdirectory directory="#contentsDirectoryPath#" action="create" mode="777">
					</cfif>

					<!--- ファイルのアップロード --->
					<cffile action="upload" filefield="Filedata" destination="#contentsDirectoryPath#" nameConflict="MakeUnique" attributes="normal" mode="777" result="fileStatus">

					<!--- ファイルがアップロードされたディレクトリ --->
					<cfset serverDirectory = fileStatus.serverDirectory>

					<!--- アップロードされたファイルへのパス --->
					<cfset uploadedFilePath = serverDirectory & dirString & fileStatus.serverFile>

					<cfif fileStatus.serverFileExt eq "csv">
						<!--- CSVファイルを読み込み、2次元配列データに格納 --->
						<cfset allDataArray = Variables.CSVUtil.readCSVArray(filepath=uploadedFilePath) />
					<cfelse>
						<cfthrow message="データファイルはcsvではありません。" />
					</cfif>

					<cfset updateDate = Now() /><!--- レコード自体の新規・更新日時 --->

					<cfset codeCR = chr(13) />
					<cfset codeLF = chr(10) />
					<cfset codeCRLF = codeCR & codeLF />
					<cfset dataCount = ArrayLen(allDataArray) />

					<cfset FROM_INDEX = 2 /><!--- 見出しは除外する --->

					<!--- チェックと更新で件数分2回ループするので倍 --->
					<cfscript>
						alldataCount = (dataCount - (FROM_INDEX - 1)) * 2;
						allIndex = 0;
					</cfscript>

					<!--- CSVの中身がない --->
					<cfif dataCount eq 1>
						<cfset result.addError(
							row=1,
							id="",
							name="",
							message="csvにデータがありません。"
						) />
						<cfset percent = 100 />
						<cfset session.ComPercent = percent />

					<cfelseif dataCount -1 GT Variables.MAX_INPUT_COUNT>
						<cfset result.addError(
							row=Variables.MAX_INPUT_COUNT,
							id="countError",
							name="",
							message="入力対象が、" & Variables.MAX_INPUT_COUNT & "件を超えています、入力件数が" & Variables.MAX_INPUT_COUNT & "件以内になるようにしてください。"
						) />
						<cfset percent = 100 />
						<cfset session.ComPercent = percent />
					<cfelse>

						<!--- 入力内容チェックループ --->
						<cfloop index="i" from="#FROM_INDEX#" to="#dataCount#">
							<cfset infoData = allDataArray[i] />
							<cfset infoDataLen = ArrayLen(infoData) />

							<cfif infoDataLen ge 6>
								<cfscript>
									errorMessage = "";
									userID = Trim(infoData[1]);

									//削除の事前チェック
									tmpEntryInfo = deleteInfo(user_id = userID);
									if (tmpEntryInfo) {
										errorMessage = "申込情報、または合格情報が存在しているため、削除できません。";
									} else {
										deleteUser(userID = userID);

										j = i - 1; //ループ回数
										entryData[j] = tmpEntryInfo;
									}
								</cfscript>

								<!---削除チェック処理--->
								<cfif errorMessage neq "" >
									<!--- 何かしらエラー有り--->
									<cfset errorFlg = true />
									<cfset result.addError(
										row=i,
										id=userID,
										name="",
										message=errorMessage
									) />
								</cfif>
							<cfelse>
								<!--- 項目に過不足有り --->
								<cfset errorFlg = true />
								<cfset result.addError(
									row=i,
									id="",
									name="",
									message="項目に過不足があります。"
								) />
							</cfif>
							<cfscript>
								//インポート進捗率更新
								allIndex = allIndex + 1;
								percent = Round((allIndex / alldataCount) * 100);
								session.ComPercent = percent;
							</cfscript>
						</cfloop>

						<cfif NOT errorFlg>
							<!--- 更新ループ --->
							<cfloop index="i" from="#FROM_INDEX#" to="#dataCount#">
								<cfset infoData = allDataArray[i] />
								<cfscript>
									j = i - 1; //ループ回数
								</cfscript>

								<cfscript>
									//インポート進捗率更新
									allIndex = allIndex + 1;
									percent = Round((allIndex / alldataCount) * 100);
									session.ComPercent = percent;
								</cfscript>
							</cfloop>
						<cfelse>
							<cfset percent = 100 />
							<cfset session.ComPercent = percent />
						</cfif>

					</cfif>

					<!--- csvファイルを削除 --->
					<cffile action="delete" file="#uploadedFilePath#" />

				</cfif>

			</cflock>

			<cfcatch type="any">
				<cfscript>
					//cfcatch時、cflogを出力する
					csvLineRow = 0;
					csvLineID = "";
					csvLineName = "";
					if (structKeyExists(Variables, "i")) {
						csvLineRow = Variables.i;
					}
					if (structKeyExists(Variables, "schoolId")) {
						csvLineID = Variables.schoolId;
					}
					if (structKeyExists(Variables, "schoolName")) {
						csvLineName = Variables.schoolName;
					}
					LogOutputcfc.outputCFCatchToCFLog(
						application_name = Application.applicationname,
						script_name = CGI.SCRIPT_NAME,
						csv_line_row = csvLineRow,
						csv_line_id = csvLineID,
						csv_line_name = csvLineName,
						cfcatch_var = cfcatch
					);
				</cfscript>
				<cfif StructKeyExists(Variables,"uploadedFilePath") and Variables.uploadedFilePath neq "" >
					<!--- csvファイルを削除 --->
					<cfif FileExists(Variables.uploadedFilePath)>
						<cffile action="delete" file="#uploadedFilePath#" />
					</cfif>
				</cfif>
				<cfset session.ComPercent = 100 />
				<cfset result.addError(
					row=csvLineRow,
					id=csvLineID,
					name=csvLineName,
					message=cfcatch.message
				) />
				<cfset errorFlg = true />
			</cfcatch>
		</cftry>
	</cftransaction>

</cfoutput>

<cfoutput encodefor="html">#result.getResult()#</cfoutput>
</cfprocessingdirective>