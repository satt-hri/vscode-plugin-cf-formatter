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
			<!--- course_masterの履歴表示情報を取得 --->
			<cfquery name="get_hide" datasource="#Application.DSN#">
SELECT
  hide_score,
  hide_result
FROM
  course_master
WHERE
  course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#course_id#" />
</cfquery>
			<!--- sco_guideやidentifier（マニフェスト対応）を追加した --->
			<cfquery name="get_sco_detail" datasource="#Application.DSN#">
SELECT
  sco_master.sco_id,
  sco_master.sco_name,
  sco_master.sco_type,
  sco_master.sco_guide,
  sco_master.lecture_time_min,
  sco_master.identifier,
  sco_master.enabled_pc,
  sco_master.enabled_sf,
  sco_master.url,
  sco_master.url_sf,
  construct.order_no
FROM
  construct
  INNER JOIN sco_master ON construct.sco_id = sco_master.sco_id
WHERE
  construct.course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#course_id#" />
  AND construct.parent_sco_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#parent_sco_id#" />
ORDER BY
  construct.order_no
</cfquery>
			<cfloop query="get_sco_detail">
				<cfset workStruct = StructNew() />
				<cfif get_sco_detail.sco_type eq 2>
					<!--- フォルダ --->
					<cfscript>
						childTreeArray = getCourseTreeCustom(course_id, item_list, get_sco_detail
						    .sco_id);
					</cfscript>
					<cfset StructInsert( workStruct, "id", get_sco_detail.sco_id ) />
					<cfset StructInsert( workStruct, "name", " "&get_sco_detail.sco_name ) />
					<cfset StructInsert( workStruct, "sco_guide", " "&get_sco_detail.sco_guide ) />
					<cfset StructInsert( workStruct, "lecture_time_min", get_sco_detail.lecture_time_min ) />
					<cfset StructInsert( workStruct, "identifier", get_sco_detail.identifier ) />
					<cfset StructInsert( workStruct, "enabled_pc", "1" ) />
					<cfset StructInsert( workStruct, "pc_mark", false ) />
					<cfset StructInsert( workStruct, "sp_mark", false ) />
					<cfset StructInsert( workStruct, "order_no", get_sco_detail.order_no ) />
					<cfset StructInsert( workStruct, "children", childTreeArray ) />
				<cfelse>
					<!--- SCO --->
					<cfset StructInsert( workStruct, "id", get_sco_detail.sco_id ) />
					<cfset StructInsert( workStruct, "name", " "&get_sco_detail.sco_name ) />
					<cfset StructInsert( workStruct, "sco_guide", " "&get_sco_detail.sco_guide ) />
					<cfset StructInsert( workStruct, "lecture_time_min", get_sco_detail.lecture_time_min ) />
					<cfset StructInsert( workStruct, "identifier", get_sco_detail.identifier ) />
					<cfset StructInsert( workStruct, "order_no", get_sco_detail.order_no ) />
					<cfif get_sco_detail.enabled_pc eq "1" and get_sco_detail.url neq "">
						<cfset StructInsert( workStruct, "enabled_pc", "1" ) />
					<cfelse>
						<cfset StructInsert( workStruct, "enabled_pc", "0" ) />
					</cfif>
					<cfif get_sco_detail.enabled_pc eq "1" and get_sco_detail.url neq "">
						<cfif get_sco_detail.enabled_sf eq "1" and get_sco_detail.url_sf neq "">
							<cfset StructInsert( workStruct, "pc_mark", true ) />
							<cfset StructInsert( workStruct, "sp_mark", true ) />
						<cfelse>
							<cfset StructInsert( workStruct, "pc_mark", true ) />
							<cfset StructInsert( workStruct, "sp_mark", false ) />
						</cfif>
					<cfelseif get_sco_detail.enabled_sf eq "1" and get_sco_detail.url_sf neq "">
						<cfset StructInsert( workStruct, "pc_mark", false ) />
						<cfset StructInsert( workStruct, "sp_mark", true ) />
					<cfelse>
						<cfset StructInsert( workStruct, "pc_mark", false ) />
						<cfset StructInsert( workStruct, "sp_mark", false ) />
					</cfif>
				</cfif>
				<!--- 履歴を返すかどうかをチェック--->
				<cfif user_id neq -1 and item_list neq "">
					<cfquery name="get_sco_progress" datasource="#Application.DSN#">
SELECT
  #ArrayToList( itemList )#,
  <cfif get_hide.hide_score eq "0">
								raw_score,
							<cfelse>
								'' as raw_score,
							</cfif> <cfif get_hide.hide_result eq "0">
								<cfif item_list eq "*">
									DATE_FORMAT(last_lecture_date,'%Y/%m/%d %k:%i:%s') as latestDate,
								</cfif> <!--- 合否を隠さない ---> CASE
    WHEN sco_progress.success_status = 'passed' THEN 'passed'
    WHEN sco_progress.success_status = 'failed' THEN 'failed'
    WHEN sco_progress.completion_status = 'passed' THEN 'passed'
    WHEN sco_progress.completion_status = 'failed' THEN 'failed'
    WHEN sco_progress.completion_status = 'completed' THEN 'completed'
    WHEN sco_progress.completion_status = 'incomplete' THEN 'incomplete'
    WHEN sco_progress.completion_status = 'not attempted' THEN 'not attempted'
    WHEN sco_progress.completion_status = 'unknown' THEN 'unknown'
    WHEN sco_progress.completion_status = 'browsed' THEN 'browsed'
    WHEN sco_progress.success_status = 'unknown' THEN 'unknown'
  END AS total_status <cfelse>
								<cfif item_list eq "*">
									DATE_FORMAT(last_lecture_date,'%Y/%m/%d %k:%i:%s') as latestDate,
								</cfif> <!--- 合否を隠す ---> CASE
    WHEN sco_progress.success_status = 'passed' THEN 'completed'
    WHEN sco_progress.success_status = 'failed' THEN 'completed'
    WHEN sco_progress.completion_status = 'passed' THEN 'completed'
    WHEN sco_progress.completion_status = 'failed' THEN 'completed'
    WHEN sco_progress.completion_status = 'completed' THEN 'completed'
    WHEN sco_progress.completion_status = 'incomplete' THEN 'incomplete'
    WHEN sco_progress.completion_status = 'not attempted' THEN 'not attempted'
    WHEN sco_progress.completion_status = 'unknown' THEN 'unknown'
    WHEN sco_progress.completion_status = 'browsed' THEN 'browsed'
    WHEN sco_progress.success_status = 'unknown' THEN 'unknown'
  END AS total_status < / cfif >
FROM
  sco_progress
WHERE
  user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_id#" />
  AND course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#course_id#" />
  AND sco_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#get_sco_detail.sco_id#" />
</cfquery>
					<cfif get_sco_progress.recordcount eq 1>
						<cfloop index="i" from="1" to="#ArrayLen( itemList )#" step="1">
							<cfset StructInsert( workStruct, itemList[i], Evaluate( "get_sco_progress.#itemList[i]#" ) ) />
						</cfloop>
						<!--- CASEのtotal_statusを追加--->
						<cfset StructInsert( workStruct, "raw_score", get_sco_progress.raw_score ) />
						<cfset StructInsert( workStruct, "total_status", get_sco_progress.total_status ) />
						<cfset StructInsert( workStruct, "latestDate", get_sco_progress.latestDate ) />
					<cfelse>
						<cfloop index="i" from="1" to="#ArrayLen( itemList )#" step="1">
							<cfset StructInsert( workStruct, itemList[i], "" ) />
						</cfloop>
						<!--- CASEのtotal_statusを追加--->
						<cfset StructInsert( workStruct, "raw_score", "" ) />
						<cfset StructInsert( workStruct, "total_status", "" ) />
					</cfif>
				</cfif>
				<!--- 履修条件 教材名（pre_sco_idName）, 起動可能かどうか（pre_sco_exec："1"起動OK)を返す --->
				<cfquery name="get_precondition_sco" datasource="#Application.DSN#">
SELECT
  precondition_sco.pre_sco_id,
  sco_master.sco_name
FROM
  precondition_sco
  INNER JOIN sco_master ON precondition_sco.pre_sco_id = sco_master.sco_id
WHERE
  precondition_sco.course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#course_id#" />
  AND precondition_sco.sco_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#get_sco_detail.sco_id#" />
</cfquery>
				<cfif get_precondition_sco.recordcount gt 0>
					<cfset StructInsert( workStruct, "pre_sco_id", ValueList( get_precondition_sco.pre_sco_id ) ) />
					<cfset StructInsert( workStruct, "pre_sco_idName", ValueList( get_precondition_sco.sco_name) ) />
					<cfquery name="get_precondition_Flag" datasource="#Application.DSN#">
SELECT
  sco_progress.sco_id,
  sco_progress.completion_status,
  sco_progress.success_status,
  ASE WHEN sco_progress.completion_status = 'completed' THEN '1' WHEN sco_progress.completion_status = 'passed' THEN '1' WHEN sco_progress.success_status = 'passed' THEN '1' ELSE '0' END AS statusFlag
FROM
  sco_progress
WHERE
  sco_progress.sco_id IN (<cfqueryparam cfsqltype="cf_sql_integer" list="yes" separator="," value="#ValueList( get_precondition_sco.pre_sco_id )#" />)
  AND user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_id#" />
</cfquery>
					<cfset statusFlagList = ValueList( get_precondition_Flag.statusFlag ) />
					<cfif Find( "0", statusFlagList ) gt 0>
						<cfset StructInsert( workStruct, "pre_sco_exec", "0" ) />
					<cfelse>
						<cfset StructInsert( workStruct, "pre_sco_exec", "1" ) />
					</cfif>
				<cfelse>
					<cfset StructInsert( workStruct, "pre_sco_id", "" ) />
					<cfset StructInsert( workStruct, "pre_sco_idName", "" ) />
					<cfset StructInsert( workStruct, "pre_sco_exec", "1" ) />
				</cfif>
				<cfset ArrayAppend( returnArray, workStruct ) />
			</cfloop>

			<cfreturn returnArray />
			<cfcatch type="any">
				<cfset Variables.resultCFC.GetResult( cfcatch ) />

				<cfreturn returnStruct />
			</cfcatch>
		</cftry>
	</cffunction>



</cfprocessingdirective>
</cfcomponent>
