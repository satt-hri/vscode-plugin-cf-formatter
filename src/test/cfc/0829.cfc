<cfcomponent>
	<cfprocessingdirective pageencoding="utf-8" suppresswhitespace="yes">
	<cfloop query="qExaminationMaster" >
		<cfset XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.init(
			XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
			XXXXXXXXXX._id =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
			examination_department_id =qExaminationMaster.examination_department_id,
			COMMON_SERVICE_ADDRESS=VariaXles.ACSA
		) />

	</cfloop>

	<cffunction name="getCourseTreeCustom" access="remote" returntype="any" hint="コース構成を取得します。">
		<cfargument name="course_id" type="numeric" required="yes" default="-1" hint="コースID" />
		<cfargument name="item_list" type="string" required="yes" default="" hint="取得項目" />
		<cfargument name="parent_sco_id" type="numeric" required="no" default="0" hint="親のSCO ID（隠しパラメータ）" />

		<cfquery name="store_scorm_log" Datasource="#Application.DSN#">
			INSERT INTO sco_progress_log(
						rec_date,
						user_id,


						<cfif arguments.log_data[1] neq "null">completion_status,</cfif>
						exec_flag
				) VALUES (
						<cfqueryparam cfsqltype="cf_sql_timestamp" value="#currentDateTime#" />,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.user_id#" />,

				)
		</cfquery>
		<cfquery name="qSelect" datasource="#Variables.DSN#">
			SELECT
				sm.sco_id
				,c.order_no
				,cm.class_name
				,pre.pre_sco_id

			FROM
				SCO_MASTER AS sm
				LEFT JOIN CONSTRUCT AS c ON (c.sco_id=sm.sco_id AND course_id= <cfqueryparam value="#courseID#" cfsqltype="cf_sql_integer" /> )

			WHERE
				(1=1)
				<cfif courseID neq 0>
					AND c.course_id = <cfqueryparam value="#courseID#" cfsqltype="cf_sql_integer" />
				</cfif>

				<cfif scoID neq 0>
					AND sm.sco_id <> <cfqueryparam value="#scoID#" cfsqltype="cf_sql_integer" />
					AND sm.attendance_style_id =(
						select sm2.attendance_style_id
						from sco_master AS sm2
						where sm2.sco_id = <cfqueryparam value="#scoID#" cfsqltype="cf_sql_integer" />
					)
				</cfif>

			ORDER BY c.order_no,sm.sco_name_kana
		</cfquery>
		<cfquery NAME="q_GetCmiInteractionsEntrycount" Datasource="#application.DSN#">
			SELECT COUNT(*) as RecCount
			FROM ITEMS AS it
				INNER JOIN CONSTRUCT AS con ON(
						it.sco_id = con.sco_id
				)
			WHERE it.user_id = <cfqueryparam value="#Param1#" cfsqltype="cf_sql_integer" />
				AND   con.course_id = <cfqueryparam value="#Param2#" cfsqltype="cf_sql_integer" />
				AND   con.sco_id = <cfqueryparam value="#Param3#" cfsqltype="cf_sql_integer" />
				AND   it.entry_count = <cfqueryparam value="#Param4_array[LoopCount][1]#" cfsqltype="cf_sql_integer" />
		</cfquery>
		<cfquery Datasource="#application.DSN#">
			UPDATE SCO_PROGRESS
				SET
				<cfif Param5_array[1] neq "null">status = <cfqueryparam value="#Param5_array[1]#" cfsqltype="cf_sql_varchar" />, </cfif>
				<cfif Param5_array[2] neq "null">location = <cfqueryparam value="#Param5_array[2]#" cfsqltype="cf_sql_varchar" />, </cfif>
				<cfif Param5_array[3] neq "null" and Param5_array[3] neq "">score = <cfqueryparam value="#Param5_array[3]#" cfsqltype="cf_sql_float" />, </cfif>
				<cfif Param5_array[4] neq "null">session_time = <cfqueryparam value="#Param5_array[4]#" cfsqltype="cf_sql_varchar" />,
					total_time = <cfqueryparam value="#ScoTotalTime#" cfsqltype="cf_sql_varchar" />,
				</cfif>
				<cfif Param5_array[5] neq "null">suspend = <cfqueryparam value="#Param5_array[5]#" cfsqltype="cf_sql_varchar" />, </cfif>
				<cfif Param5_array[6] neq "suspend">entry = '', <cfelse>entry = 'resume', </cfif>
				<cfif Param5_array[7] neq "null">bookmark = <cfqueryparam value="#Param5_array[7]#" cfsqltype="cf_sql_varchar" />, </cfif>
				sco_id = <cfqueryparam value="#Param3#" cfsqltype="cf_sql_integer" />
			WHERE (user_id = <cfqueryparam value="#Param1#" cfsqltype="cf_sql_integer" />)
			<!--- AND   (course_id = #Param2#) --->
				AND   (sco_id = <cfqueryparam value="#Param3#" cfsqltype="cf_sql_integer" />)
		</cfquery>

		<cfquery name="qSelect"  datasource="#Variables.DSN#">
			SELECT
				,um.last_name + um.first_name AS user_name
				,um.address3
				,um.tel
				,CASE
					WHEN ISNULL(pm.place_id, 0) <> 0 THEN pm.place_name + '(' + asm.attendance_style_name + ')'
					ELSE '' END AS place_name
				,asm.attendance_style_name

				,CASE
					WHEN ISNULL(yms_catput.user_id, 0) <> 0 THEN 1
					ELSE 0 END AS is_course_application_time_payment_user

			FROM
				CRN_ATTENDANCE_INFORMATION AS ai
				LEFT JOIN CRN_PREFECTURE_MASTER AS prem ON(
						um.prefecture_code = prem.prefecture_code
				)
				INNER JOIN(
					SELECT
						ai.attendance_acceptance_number
						,CASE
							WHEN ISNULL(pm.attendance_style_id, 0) <> 0 THEN pm.attendance_style_id
							ELSE <cfqueryparam value="#Variables.crnConfigAttendanceStyleIDCFC.ON_DEMAND#" cfsqltype="cf_sql_integer" /> END AS attendance_style_id
					FROM
						CRN_ATTENDANCE_INFORMATION AS ai
						LEFT JOIN YMS_PLACE_MASTER AS pm ON(
								ai.place_id = pm.place_id
						)
					WHERE
						ai.attendance_acceptance_number = <cfqueryparam value="#attendanceAcceptanceNumber#" cfsqltype="cf_sql_integer" />
				) AS atts ON(
						ai.attendance_acceptance_number = atts.attendance_acceptance_number
				)
				INNER JOIN CRN_ATTENDANCE_STYLE_MASTER AS asm ON(
						atts.attendance_style_id = asm.attendance_style_id
				)
				LEFT JOIN YMS_PLACE_MASTER AS pm ON(
						ai.place_id = pm.place_id
				)

				LEFT JOIN (
					SELECT
						yms_catput.course_id
						,yms_catput.user_type_id
						,uth_um.user_id
					FROM
						YMS_COURSE_APPLICATION_TIME_PAYMENT_USER_TYPE AS yms_catput
						INNER JOIN UTH_USER_MASTER AS uth_um ON(
								yms_catput.user_type_id = uth_um.user_type_id
						)
				) AS yms_catput ON(
						ai.course_id = yms_catput.course_id
						AND ai.user_id = yms_catput.user_id
				)

			WHERE
				ai.attendance_acceptance_number = <cfqueryparam value="#attendanceAcceptanceNumber#" cfsqltype="cf_sql_integer" />
				AND ai.is_cancel = 0
		</cfquery>
	</cffunction>



	</cfprocessingdirective>
</cfcomponent>
