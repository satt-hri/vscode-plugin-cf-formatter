<cffunction name="deleteInfo" access="private" returntype="boolean" output="no"  hint="削除前チェック">
	<cfargument name="user_id" type="string" required="yes" default="0" hint="ユーザーID" />
    <cfquery>
    </cfquery>
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