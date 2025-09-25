<cfcomponent>
    <cfset var pattern = '[\\\\/:*?\\"<>|]' />
    <cfset var pattern = "A \B > A" >
    <cfset var pattern =  'He said > \"hi\"' />
    <cfif  pattern = '[\\\\/:*?\\"<>|]'>
        <cfset var pattern = '[\\\\/:*?\\"<>|]' />
        <cfset var pattern = "A \B > A" >
    <cfelseif>
        <cfset var pattern = '[\\\\/:*?\\"<>|]' />
        <cfset var pattern = "A \B > A" >
    </cfif>


    <cfquery name="get_user_detail" datasource="#Application.DSN#">
        UPDATE user_master
            SET
            <cfloop index="i" from="1" to="#ArrayLen( itemList )#" step="1">
                <cfswitch expression="#itemList[i]#">
                    <cfcase value="logon,password,last_name,first_name,last_name_kana,first_name_kana,mailaddress,login_stop,user_note">
                        #itemList[i]# =
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#dataList[i]#" />
                        ,
                    </cfcase>
                    <cfcase value="login_start_date,login_end_date">
                        #itemList[i]# =
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#dataList[i]#" />
                        ,
                    </cfcase>
                    <cfcase value="role_id">
                        #itemList[i]# =
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#dataList[i]#" />
                        ,
                    </cfcase>
                </cfswitch>
            </cfloop>
            change_date =
            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#" />
        WHERE  user_id =
            <cfqueryparam cfsqltype="cf_sql_integer" value="#user_id#" />
    </cfquery>


    <cflog type="information"
     text="#ssoCheckAssign.recordcount# #login_check.user_id#, #course_id#, "", "", #ssoSssignDate#">
</cfcomponent>

