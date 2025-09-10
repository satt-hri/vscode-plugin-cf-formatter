<!---
	Name         : zenmms_cfc/DeleteuserGateway.cfc
	Author       : EN
	Created      : 2025/09/05
	Last Updated : 
	History      : 
	Purpose      : 生徒と教員情報削除

--->
<cfcomponent>
	<cfprocessingdirective pageencoding="utf-8" suppresswhitespace="yes">

	<cffunction name="init" access="public" returntype="DeleteuserGateway" output="false" hint="コンストラクタ">
		<cfargument name="DSN" type="string" required="yes" hint="データソース">
		<cfscript>	
			
			Variables.ASA = Application.SERVICE_ADDRESS;
			Variables.ACSA = Application.COMMON_SERVICE_ADDRESS;
			Variables.DSN = Application.DSN;
			Variables.MIN_DATE = Application.MIN_DATE;

			Variables.ajaxError = CreateObject("component", "#ACSA#.CommonAjaxError").init();
			Variables.ajaxResult = CreateObject("component", "#ACSA#.CommonAjaxResult").init();
			Variables.session = CreateObject("component", "#ASA#.SessionConfirmation").init();

			Variables.StringUtil = CreateObject("component", "#ACSA#.StringUtil").init();

			// 在籍種別
			Variables.ConfigEnrollmentTypeId = CreateObject("component", "#Variables.ASA#.ConfigEnrollmentTypeId").init();
			// 生徒在籍状況
			Variables.ConfigStudentsEnrollmentStatusId = CreateObject("component", "#Variables.ASA#.ConfigStudentsEnrollmentStatusId").init();
			// 識別情報
			Variables.shoolIdentification = CreateObject("component", "#DSN#.manager.ajax_gateway.SchoolIdentificationAjaxGateway");

			// 一覧情報取得
			Variables.dataGateway = CreateObject("component", "#ASA#.manager.StudentsGateway").init(
				DSN = Variables.DSN,
				SERVICE_ADDRESS = Variables.ASA,
				COMMON_SERVICE_ADDRESS = Variables.ACSA
			);
		</cfscript>
	<cfreturn this>
	</cffunction>	

	<!-----------------------------------------------------------------------------------------------------------------------------
	削除処理
	------------------------------------------------------------------------------------------------------------------------------>
	<!---  削除の事前チェック --->
	<cffunction name="deleteConfirm" access="remote" returntype="string" output="false" hint="削除前チェック">
		<cfargument name="user_id" type="numeric" required="yes" hint="ユーザーID" />
		<cfscript>
			var userID = arguments.user_id;
			if (userID eq "") userID = 0;

			var result = false;
			var resultMessage = "";
			var qCheckUserExists = "";
			var structJsonData = structNew();
			var resultJson = "";
		</cfscript>

		<!--- セッション確認 --->
		<cfset sessionVal = Variables.session.checkSessionVariable() />
		<cfif sessionVal eq false>
			<cfscript>
				structJsonData['session'] = false;
			</cfscript>
		<cfelse>
			<cftransaction>
				<cftry>
					<!--- EXAMINATION_APPLICATION_USER / SUCCESSFUL_EXAMINEE に存在確認 --->
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
						<cfscript>
							result = true;
							resultMessage = "申込情報、または合格情報が存在しているため、削除できません。";
						</cfscript>
					</cfif>

					<cfcatch type="any">
						<cftransaction action="rollback" />
						<cfreturn Variables.ajaxError.cfcatchToJson(cfcatch) />
					</cfcatch>
				</cftry>
			</cftransaction>

			<cfscript>
				structJsonData['session'] = true;
				structJsonData['result'] = result;
				structJsonData['result_message'] = resultMessage;
			</cfscript>
		</cfif>

		<!--- JSON整形 --->
		<cftry>
			<cfset resultJSON = SerializeJSON(structJsonData) />
			<cfset resultJSON = Variables.StringUtil.ReplaceChangingLineCodeForJSON(target=resultJSON) />
			<cfset resultJson = Variables.ajaxResult.toResultJSON(resultJson) />
			<cfcatch type="any">
				<cfreturn Variables.ajaxError.cfcatchToJson(cfcatch) />
			</cfcatch>
		</cftry>
		<cfreturn resultJson />
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

	</cfprocessingdirective>
</cfcomponent>