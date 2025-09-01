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