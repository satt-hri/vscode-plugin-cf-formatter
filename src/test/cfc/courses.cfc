<cfcomponent restpath="courses" rest="true">
	<!--- 共通 --->
	<cfscript>
		libCommon = CreateObject("component", "lib.common");
		libSession = CreateObject("component", "lib.session");
	</cfscript>

	<cffunction httpmethod="GET" restpath="" name="get_all" access="remote" returntype="void">
		<cfargument restargsource="query" name="format" type="string" required="no" />
		<cfargument restargsource="query" name="with_title" type="boolean" required="no" displayname="タイトル行も一緒に取得するのか" />
		<cfargument restargsource="query" name="with_sco" type="boolean" required="no" displayname="sco情報も一緒に取得するのか" />

		<cfparam name="arguments.format" default="">
		<cfparam name="arguments.with_title" default="false">
		<cfparam name="arguments.with_sco" default="false">

		<cfset var request.nest_call = true>

		<!--- コースを取得する --->
		<cftry>
			<cfset var http_status_success = 200 >
			<cfset var result = get(course_id="all", format=arguments.format, with_title=arguments.with_title, with_sco=arguments.with_sco) >
			<cfset respondByFormatForGet(responseBody=result) />
			<cfreturn/>
			<cfcatch type="api_error">
				<cfset restSetResponse(libCommon.returnRESTResponse(cfcatch.errorcode)) />
				<cfreturn/>
			</cfcatch>
			<cfcatch type="any">
				<cfset restSetResponse(libCommon.returnRESTResponse(500,serializeJSON(cfcatch))) />
				<cfreturn/>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction httpmethod="GET" restpath="/{course_id}"  name="get_course" access="remote" returntype="void">
		<cfargument restargsource="path"  name="course_id" type="any" required="no" />
		<cfargument restargsource="query" name="format" type="string" required="no" />
		<cfargument restargsource="query" name="with_title" type="boolean" required="no" displayname="タイトル行も一緒に取得するのか" />
		<cfargument restargsource="query" name="with_sco" type="boolean" required="no" displayname="sco情報も一緒に取得するのか" />

		<cfparam name="arguments.format" default="">
		<cfparam name="arguments.with_title" default="false">
		<cfparam name="arguments.with_sco" default="false">

		<!--- コースを取得する --->
		<cftry>
			<cfset var http_status_success = 200 >
			<cfset var result = get(course_id=arguments.course_id, format=arguments.format, with_title=arguments.with_title, with_sco=arguments.with_sco) >
			<cfset respondByFormatForGet(responseBody=result) />
			<cfreturn/>
			<cfcatch type="api_error">
				<cfset restSetResponse(libCommon.returnRESTResponse(cfcatch.errorcode)) />
				<cfreturn/>
			</cfcatch>
			<cfcatch type="any">
				<cfset restSetResponse(libCommon.returnRESTResponse(500,serializeJSON(cfcatch))) />
				<cfreturn/>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction httpmethod="DELETE" restpath="/{course_id}" name="delete_course" access="remote" returntype="void" produces="application/json">
		<cfargument name="course_id" type="any" required="true" restargsource="path" />

		<cftry>

			<!--- 1) Auth --->
			<cfif libCommon.verifyAPIAccess() NEQ 200>
				<cfthrow type="api_error" errorcode="401" message="Unauthorized" detail="認証失敗" />
			</cfif>

			<!--- 2) Validate input --->
			<cfset var idVal = Val(arguments.course_id) />
			<cfif NOT IsNumeric(arguments.course_id) OR idVal LTE 0>
				<cfthrow type="api_error" errorcode="400" message="Invalid input" detail="course_id must be a positive integer" />
			</cfif>

			<!--- 3) Existence check --->
			<cfquery name="qCourse" datasource="#Application.DSN#">
				SELECT course_id
				FROM course_master
				WHERE course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#idVal#" />
					LIMIT 1
			</cfquery>

			<cfif qCourse.recordCount EQ 0>
				<cfset var statusCode = 404>
			<cfelse>
				<!--- 4) Transactional delete (children first, parent last) --->
				<cftransaction>
					<!--- 4.1 SCORM roots → deleteSco --->
					<cfquery name="qRoots" datasource="#Application.DSN#">
						SELECT sco_id
						FROM construct
						WHERE course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#idVal#" />
							AND parent_sco_id = 0
					</cfquery>

					<cfloop query="qRoots">
						<!--- deleteSco should remove the full SCO subtree/resources --->
						<cfset deleteSco( { id = qRoots.sco_id } ) />
					</cfloop>

					<!--- 4.2 Children tables --->
					<cfquery datasource="#Application.DSN#">
						DELETE FROM course_progress
						WHERE course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#idVal#" />
					</cfquery>

					<cfquery datasource="#Application.DSN#">
						DELETE FROM precondition_course
						WHERE course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#idVal#" />
							OR pre_course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#idVal#" />
					</cfquery>

					<cfquery datasource="#Application.DSN#">
						DELETE FROM assign
						WHERE course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#idVal#" />
					</cfquery>

					<cfquery datasource="#Application.DSN#">
						DELETE FROM learning_log
						WHERE course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#idVal#" />
					</cfquery>

					<!--- 4.3 Parent last --->
					<cfquery datasource="#Application.DSN#">
						DELETE FROM course_master
						WHERE course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#idVal#" />
					</cfquery>
				</cftransaction>

				<cfset var statusCode = 204>
			</cfif>

			<!--- 5) Common response once --->
			<cfset restSetResponse(libCommon.returnRESTResponse(statusCode)) />
			<cfreturn />
			<cfcatch type="api_error">
				<cfset restSetResponse(libCommon.returnRESTResponse(cfcatch.errorcode)) />
				<cfreturn />
			</cfcatch>

			<cfcatch type="any">
				<cfset restSetResponse(libCommon.returnRESTResponse(500, serializeJSON(cfcatch))) />
				<cfreturn />
			</cfcatch>
		</cftry>
	</cffunction>

	<!--- GET メソッドのコントロール層 --->
	<cffunction name="get" access="private" returntype="any">
		<cfargument name="course_id" type="any" required="no" />
		<cfargument name="format" type="string" required="no" />
		<cfargument name="with_title" type="boolean" required="no" displayname="タイトル行も一緒に取得するのか" />
		<cfargument name="with_sco" type="boolean" required="no" displayname="sco情報も一緒に取得するのか" />

		<cfparam name="arguments.format" default="">
		<cftry>
			<cfscript>
				var http_status_success = 200;
				var requestHeader = GetHttpRequestData();
				var verifyAPI = libCommon.verifyAPIAccess();
				if (verifyAPI != 200) {
					throw (errorcode = verifyAPI, type = "api_error", message = "Unauthorized", detail = "認証失敗");
				}
				switch (arguments.course_id) {
					// all指定の場合は、get_all を通ってきていないとNG（直指定防止）
					case "all": {
						if (structKeyExists(request, "nest_call") eq false) {
							throw (errorcode = 400, type = "api_error", message = "Invalid input", detail = "バリデーション失敗");
						}
						break;
					}
					// それ以外の場合は、 course_id は数値であること
					default: {
						if (isNumeric(arguments.course_id) eq false) {
							throw (errorcode = 400, type = "api_error", message = "Invalid input", detail = "バリデーション失敗");
						}
						break;
					}
				}
				// format 指定しているのに、all 以外はエラー
				if (arguments.format eq "datatables"
					and arguments.course_id neq "all") {
					throw (errorcode = 400, type = "api_error", message = "Invalid input", detail = "バリデーション失敗");
				}
				// ヘッダに Content-Type が無かったら400エラー
				if (!StructKeyExists(requestHeader.headers, "Accept")) {
					libCommon.recordLog(log_type = "Info", log_object = "リクエストヘッダに「Accept」がありません。Acceptは必須です。");
					throw (errorcode = 400, type = "api_error", message = "Invalid input", detail = "バリデーション失敗");
				}
				var return_file_type = "";
				switch (requestHeader.headers["Accept"]) {
					case "text/csv":
					case "application/json": {
						break;
					}
					default: {
						libCommon.recordLog(log_type = "Info", log_object = "リクエストヘッダ「Accept」の内容が不正です。「application/json」「text/csv」を指定してください。");
						throw (errorcode = 400, type = "api_error", message = "Invalid input", detail = "バリデーション失敗");
						break;
					}
				}
				// q_get_course
				var q_get_course = queryNew("");
				{
					// SQLを加工する
					var sql = "";
					sql = sql & "
					SELECT c.course_id, c.course_no, c.course_name, c.course_guide, DATE_FORMAT(c.course_start_date, '%Y/%m/%d') as course_start_date, DATE_FORMAT(c.course_end_date, '%Y/%m/%d') as course_end_date, CASE c.course_open
					WHEN 1 THEN '公開'
					WHEN 0 THEN '非公開'
					END as course_open,
					if (a == 1) {
						cate.category_name,
					}
					repo.report_name, cer.certification_name, CASE c.manifest_flag
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
					WHERE 1 = 1 ";
					// all じゃないときは course_id で絞り込む
					if (arguments.course_id neq "all") {
						sql = sql & "
						AND c.course_id = : course_id ";
					}
					sql = sql & "
					GROUP BY
					c.course_id ";
					// 加工したSQLを実行
					q_get_course = queryExecute(sql = sql, params = {
						course_id = {
							value = arguments.course_id,
							cfsqltype = "CF_SQL_INTEGER"
						}
					}, options = {
						datasource = Application.DSN,
						result = "resultset"
					});
				}
				// CSVを作成
				var csv_array = ArrayNew(1);
				// １行目のtitle行を作成
				var title_row_array = arrayNew(1);
				if (arguments.with_title eq true) {
					{
						arrayAppend(title_row_array, "更新区分(I/U/D)");
						arrayAppend(title_row_array, "コース");
						arrayAppend(title_row_array, "コースID(*)");
						arrayAppend(title_row_array, "");
						arrayAppend(title_row_array, "");
						arrayAppend(title_row_array, "カテゴリ");
						arrayAppend(title_row_array, "コース番号(*)");
						arrayAppend(title_row_array, "コース名(*)");
						arrayAppend(title_row_array, "開講日");
						arrayAppend(title_row_array, "閉講日");
						arrayAppend(title_row_array, "説明");
						arrayAppend(title_row_array, "公開/非公開");
						arrayAppend(title_row_array, "レポート");
						arrayAppend(title_row_array, "修了証印刷");
						arrayAppend(title_row_array, "マニフェストの有無");
						arrayAppend(title_row_array, "スコームのバージョン");
						arrayAppend(title_row_array, "得点非表示");
						arrayAppend(title_row_array, "合格＆不合格を修了表記");
						arrayAppend(title_row_array, "事前受講の指定");
						arrayAppend(title_row_array, "割り当てユーザー数");
					}
					arrayAppend(csv_array, title_row_array);
					// SCOも出力する場合
					if (arguments.with_sco) {
						title_row_array = arrayNew(1);
						{
							arrayAppend(title_row_array, "更新区分(I/U/D)");
							arrayAppend(title_row_array, "SCO");
							arrayAppend(title_row_array, "コースID(*)");
							arrayAppend(title_row_array, "SCO ID(*)");
							arrayAppend(title_row_array, "親SCO ID");
							arrayAppend(title_row_array, "種別");
							arrayAppend(title_row_array, "");
							arrayAppend(title_row_array, "ユニット名(*)");
							arrayAppend(title_row_array, "URL(PC)");
							arrayAppend(title_row_array, "URL(SP)");
							arrayAppend(title_row_array, "説明");
							arrayAppend(title_row_array, "設定");
							arrayAppend(title_row_array, "画面サイズ(横)");
							arrayAppend(title_row_array, "画面サイズ(縦)");
							arrayAppend(title_row_array, "最高点");
							arrayAppend(title_row_array, "合格点");
							arrayAppend(title_row_array, "最低点");
							arrayAppend(title_row_array, "標準学習時間");
							arrayAppend(title_row_array, "事前受講の指定");
						}
						arrayAppend(csv_array, title_row_array);
					}
				}
				cfloop(query = q_get_course) {
					var data_row_array = arrayNew(1);
					arrayAppend(data_row_array, "-");
					arrayAppend(data_row_array, "コース");
					arrayAppend(data_row_array, q_get_course.course_id);
					arrayAppend(data_row_array, "");
					arrayAppend(data_row_array, "");
					arrayAppend(data_row_array, q_get_course.category_name);
					arrayAppend(data_row_array, q_get_course.course_no);
					arrayAppend(data_row_array, q_get_course.course_name);
					arrayAppend(data_row_array, q_get_course.course_start_date);
					arrayAppend(data_row_array, q_get_course.course_end_date);
					arrayAppend(data_row_array, q_get_course.course_guide);
					arrayAppend(data_row_array, q_get_course.course_open);
					arrayAppend(data_row_array, q_get_course.report_name);
					arrayAppend(data_row_array, q_get_course.certification_name);
					arrayAppend(data_row_array, q_get_course.manifest_flag);
					arrayAppend(data_row_array, q_get_course.scorm_ver);
					arrayAppend(data_row_array, q_get_course.hide_score);
					arrayAppend(data_row_array, q_get_course.hide_result);
					arrayAppend(data_row_array, q_get_course.precondition_course_name);
					arrayAppend(data_row_array, q_get_course.user_count);
					arrayAppend(csv_array, data_row_array);
					// SCOも出力する場合
					if (arguments.with_sco) {
						// q_get_sco
						var q_get_sco = queryNew("");
						{
							// SQLを加工する
							var sql = "";
							sql = sql & "
							SELECT c_sco.course_id, c_sco.sco_id,
								CASE c_sco.parent_sco_id
							WHEN 0 THEN NULL
							ELSE c_sco.parent_sco_id
							END as parent_sco_id,
							CASE sco.content_type_id
							WHEN 1 THEN 'SCORM教材'
							WHEN 2 THEN 'その他'
							END as content_type_id, sco.sco_name, sco.url, sco.url_sf, sco.sco_guide, sco.launch, sco.screen_width, sco.screen_height, sco.max_score, sco.mastery_score, sco.min_score, sco.lecture_time_min
							FROM construct c_sco
							INNER JOIN sco_master sco
							ON c_sco.sco_id = sco.sco_id
							WHERE c_sco.course_id = : course_id
							ORDER BY
							c_sco.order_no ";
							// 加工したSQLを実行
							q_get_sco = queryExecute(sql = sql, params = {
								course_id = {
									value = q_get_course.course_id,
									cfsqltype = "CF_SQL_INTEGER"
								}
							}, options = {
								datasource = Application.DSN,
								result = "resultset"
							});
							cfloop(query = q_get_sco) {
								data_row_array = arrayNew(1);
								arrayAppend(data_row_array, "-");
								arrayAppend(data_row_array, "SCO");
								arrayAppend(data_row_array, q_get_sco.course_id);
								arrayAppend(data_row_array, q_get_sco.sco_id);
								arrayAppend(data_row_array, q_get_sco.parent_sco_id);
								arrayAppend(data_row_array, q_get_sco.content_type_id);
								arrayAppend(data_row_array, "");
								arrayAppend(data_row_array, q_get_sco.sco_name);
								arrayAppend(data_row_array, replace(q_get_sco.url, "https://#cgi.http_host#/#Application.PATH.URI_ROOT_PATH#", ""));
								arrayAppend(data_row_array, replace(q_get_sco.url_sf, "https://#cgi.http_host#/#Application.PATH.URI_ROOT_PATH#", ""));
								arrayAppend(data_row_array, q_get_sco.sco_guide);
								arrayAppend(data_row_array, q_get_sco.launch);
								arrayAppend(data_row_array, q_get_sco.screen_width);
								arrayAppend(data_row_array, q_get_sco.screen_height);
								arrayAppend(data_row_array, q_get_sco.max_score);
								arrayAppend(data_row_array, q_get_sco.mastery_score);
								arrayAppend(data_row_array, q_get_sco.min_score);
								arrayAppend(data_row_array, q_get_sco.lecture_time_min);
								arrayAppend(data_row_array, "");
								arrayAppend(csv_array, data_row_array);
							}
						}
					}
				}
				var restBody = csv_array;
			</cfscript>
			<cfreturn restBody>

			<cfcatch type="any">
				<cfrethrow>
			</cfcatch>
		</cftry>
	</cffunction>

	<!--- Get メソッドのレスポンスデータ コントロール層 --->
	<cffunction name="respondByFormatForGet" access="private" returntype="any">
		<cfargument name="responseBody" type="any" required="true" />

		<cfscript>
			var requestHeader = GetHttpRequestData();
			switch (requestHeader.headers["Accept"]) {
				case "text/csv": {
					libCommon.responseCSV(arguments.responseBody);
					break;
				}
				case "application/json": {
					restSetResponse(libCommon.returnRESTResponse(200, serializeJSON(arguments.responseBody)))
					break;
				}
			}
			return;
		</cfscript>
	</cffunction>

</cfcomponent>
