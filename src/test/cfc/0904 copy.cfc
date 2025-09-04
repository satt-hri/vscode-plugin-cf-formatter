<!--- 現時点でのレコード作成 --->

<cfquery name="insupd_login_limit_management" datasource="#Application.DSN#">
	INSERT INTO
		login_limit_management (
			user_id,
			password_failed_count,
			password_failed_time
		)
	VALUES
		(
			<cfqueryparam cfsqltype="cf_sql_integer" value="#this.user_id#" />,
			1,
			<cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#" />
		)
	ON DUPLICATE KEY UPDATE
		password_failed_count = password_failed_count + 1
</cfquery>

			<cfquery datasource="#Application.DSN#">
				INSERT INTO sco_progress_log(
					rec_datetime
					,log_type
					,exec_scorm_api
					,exec_cf_method
					,user_id
					,login_id
					,course_id
					,course_name
					,sco_id
					,sco_name
					,sco_type
					,sco_type_name
					,content_type_id
					,content_type_name
					<cfif arguments.caller_sco_id neq 0>
						,caller_sco_id
					</cfif>

					,completion_status
					,success_status
					,progress_measure
					,lecture_count
					,entry
					,exit_flag
					,location
					,raw_score
					,max_score
					,min_score
					,session_time
					,total_time
					,suspend
					,last_lecture_date
					,complete_date
				)SELECT
					<cfqueryparam value="#DateFormat(fixed_now,"yyyy/mm/dd")# #TimeFormat(fixed_now,"HH:nn:ss.l")#" cfsqltype="cf_sql_timestamp" />
					,'rireki'
					,NULL
					,<cfqueryparam value="#arguments.exec_cf_method#" cfsqltype="cf_sql_varchar" />
					,ins_data.user_id
					,<cfqueryparam value="#q_get_user.login_id#" cfsqltype="cf_sql_varchar" />
					,ins_data.course_id
					,<cfqueryparam value="#q_get_course.course_name#" cfsqltype="cf_sql_varchar" />
					,ins_data.sco_id
					,<cfqueryparam value="#q_get_sco.sco_name#" cfsqltype="cf_sql_varchar" />
					,<cfqueryparam value="#q_get_sco.sco_type#" cfsqltype="cf_sql_integer" />
					,<cfqueryparam value="#q_get_sco.sco_type_name#" cfsqltype="cf_sql_varchar" />
					,<cfqueryparam value="#q_get_sco.content_type_id#" cfsqltype="cf_sql_integer" />
					,<cfqueryparam value="#q_get_sco.content_type_name#" cfsqltype="cf_sql_varchar" />
					<cfif arguments.caller_sco_id neq 0>
						,<cfqueryparam value="#arguments.caller_sco_id#" cfsqltype="cf_sql_integer" />
					</cfif>
					
					,ins_data.completion_status
					,ins_data.success_status
					,ins_data.progress_measure
					,ins_data.lecture_count
					,ins_data.entry
					,ins_data.exit_flag
					,ins_data.location
					,ins_data.raw_score
					,ins_data.max_score
					,ins_data.min_score
					,ins_data.session_time
					,ins_data.total_time
					,ins_data.suspend
					,ins_data.last_lecture_date
					,ins_data.complete_date
				FROM sco_progress ins_data
				WHERE		user_id		= <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer" />
					AND		course_id	= <cfqueryparam value="#arguments.course_id#" cfsqltype="cf_sql_integer" />
					AND		sco_id		= <cfqueryparam value="#arguments.sco_id#" cfsqltype="cf_sql_integer" />
			</cfquery>
