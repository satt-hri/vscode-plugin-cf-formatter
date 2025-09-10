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
		<cfquery name="store_scorm_log" Datasource="#Application.DSN#">
			INSERT INTO
				sco_progress_log (
					rec_date,
					user_id,
					<cfif arguments.log_data[1] neq "null">
						completion_status,
					</cfif>
					exec_flag
				)
			VALUES
				(<cfqueryparam cfsqltype="cf_sql_timestamp" value="#currentDateTime#" />, <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.user_id#" />,)
		</cfquery>
			<cfquery datasource="#Application.DSN#">
SELECT
					<cfqueryparam value="#DateFormat(fixed_now,"yyyy/mm/dd")# #TimeFormat(fixed_now,"HH:nn:ss.l")#" cfsqltype="cf_sql_timestamp" />
					,'rireki'
					,NULL

					
						,<cfqueryparam value="#arguments.caller_sco_id#" cfsqltype="cf_sql_integer" />
					
					
					,ins_data.completion_status


				FROM sco_progress ins_data
				WHERE		user_id		= <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer" />
					AND		course_id	= <cfqueryparam value="#arguments.course_id#" cfsqltype="cf_sql_integer" />
					AND		sco_id		= <cfqueryparam value="#arguments.sco_id#" cfsqltype="cf_sql_integer" />
			</cfquery>
