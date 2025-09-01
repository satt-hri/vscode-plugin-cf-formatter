<cfcomponent>
	<cfprocessingdirective pageencoding="utf-8" suppresswhitespace="yes">


	<cffunction name="getCourseTreeCustom" access="remote" returntype="any" hint="コース構成を取得します。">
		<cfargument name="course_id" type="numeric" required="yes" default="-1" hint="コースID" />
		<cfargument name="item_list" type="string" required="yes" default="" hint="取得項目" />
		<cfargument name="parent_sco_id" type="numeric" required="no" default="0" hint="親のSCO ID（隠しパラメータ）" />


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
					AND sm.attendance_style_id =
					(
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
        <cfquery NAME="q_SetlectureCount1" Datasource="#application.DSN#">
			UPDATE COURSE_PROGRESS
			SET    course_count = course_count + 1,
			       course_last_lecture_date = <cfqueryparam value="#nowDate#" cfsqltype="cf_sql_timestamp" />
			WHERE  (user_id     = <cfqueryparam value="#Param1#" cfsqltype="cf_sql_integer" />)
			AND    (course_id   = <cfqueryparam value="#Param2#" cfsqltype="cf_sql_integer" />)
		</cfquery>
		<cfquery name="store_scorm_log" Datasource="#Application.DSN#">
			INSERT INTO sco_progress_log (
						rec_date,
						user_id,

						<cfif arguments.log_data[1] neq "null">completion_status,</cfif>

							exec_flag
							) VALUES (
									<cfqueryparam cfsqltype="cf_sql_timestamp" value="#currentDateTime#" />,
									<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.user_id#" />,

							)
			</cfquery>
			
		</cffunction>



	</cfprocessingdirective>
</cfcomponent>
