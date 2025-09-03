<cfcomponent>
	<cfprocessingdirective pageencoding="utf-8" suppresswhitespace="yes">

	<!--------------------------------------------------------------->
	<!--- SCO一覧画面を表示（受講者画面）                         --->
	<!--- コース構成を返す関数 履修条件を付けたので、CUSTOMとした --->
	<!--------------------------------------------------------------->
	<cffunction name="getCourseTreeCustom" access="remote" returntype="any" hint="コース構成を取得します。">
		<cfargument name="course_id" type="numeric" required="yes" default="-1" hint="コースID" />
		<cfargument name="item_list" type="string" required="yes" default="" hint="取得項目" />
		<cfargument name="parent_sco_id" type="numeric" required="no" default="0" hint="親のSCO ID（隠しパラメータ）" />



		<cftry>
								<cfquery name="get_sco_progress" datasource="#Application.DSN#">
						SELECT #ArrayToList( itemList )#,
							<cfif get_hide.hide_score eq "0">
								raw_score,
							<cfelse>
								'' as raw_score,
							</cfif>
							<cfif get_hide.hide_result eq "0">
								<cfif item_list eq "*">
									DATE_FORMAT(last_lecture_date,'%Y/%m/%d %k:%i:%s') as latestDate,
								</cfif>
							<!--- 合否を隠さない --->
								CASE

									WHEN sco_progress.success_status = 'unknown' THEN 'unknown'
									END AS total_status
							<cfelse>
								<cfif item_list eq "*">
									DATE_FORMAT(last_lecture_date,'%Y/%m/%d %k:%i:%s') as latestDate,
								</cfif>
							<!--- 合否を隠す --->
								CASE
									WHEN sco_progress.success_status = 'passed' THEN 'completed'
									WHEN sco_progress.success_status = 'failed' THEN 'completed'

									END AS total_status
							</cfif>
						FROM   sco_progress WHERE  user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_id#" />
							AND	   course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#course_id#" />
							AND	   sco_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#get_sco_detail.sco_id#" />
					</cfquery>



			<cfreturn returnArray />
			<cfcatch type="any">
				<cfset Variables.resultCFC.GetResult( cfcatch ) />

				<cfreturn returnStruct />
			</cfcatch>
		</cftry>
	</cffunction>



	</cfprocessingdirective>
</cfcomponent>
