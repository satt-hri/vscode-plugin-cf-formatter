<cfquery name="q" datasource="#Application.DSN#" result="qResult">
	INSERT INTO
		file (
			uuid,
			create_date,
			description,
			file_info,
			file_image,
			row()
		)
	VALUES
		(
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#CreateUUID()#">,
			now (),
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.description#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON(fileStatus)#">,
			<cfqueryparam cfsqltype="cf_sql_blob" value="#file_read_binary#">
		)
</cfquery>