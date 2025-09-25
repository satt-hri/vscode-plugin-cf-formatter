<cfcomponent>
    <cfproperty name="test" default='[<>]' />
    <cfset var pattern = '[\\\\/:*?\\"<>|]' />
    <cfset var pattern = "A \B > A" />
    <cfset var pattern =  'He said > \"hi\"' />

    <cfset var invalidPattern = '[\\/:*?"<>|]' />
    <cfset x = "a > b">
    <cffunction name="test">
        <cfif condition EQ 'value with "quotes" and <brackets>'>
            <cfoutput>
                Hello World
            </cfoutput>
        </cfif>
    </cffunction>

     <cfquery name="queryUpdateUserMaster" datasource="#Application.DSN#">
        UPDATE user_master
        SET PASSWORD = <cfqueryparam cfsqltype="cf_sql_varchar" value="#password#" />,
        last_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lastName#" />,
        first_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#firstName#" />,
        last_name_kana = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lastNameKana#" />,
        first_name_kana = <cfqueryparam cfsqltype="cf_sql_varchar" value="#firstNameKana#" />,
        mailaddress = <cfqueryparam cfsqltype="cf_sql_varchar" value="#mailaddress#" />,
        management_cord = <cfqueryparam cfsqltype="cf_sql_varchar" value="#managementCord#" />,
        role_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#roleID#" />,
        login_start_date =
        <cfif loginStartDate neq "">
            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#loginStartDate#" />,
        <cfelse>
            NULL,
        </cfif>
        login_end_date =
        <cfif loginEndDate neq "">
            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#loginEndDate#" />,
        <cfelse>
            NULL,
        </cfif>
        login_stop = <cfqueryparam cfsqltype="cf_sql_char" value="#loginStopFlag#" />,
        user_note = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userNote#" />,
        <cfif themaID gt 0>
            user_thema_id = <cfqueryparam value="#themaID#" cfsqltype="cf_sql_integer" />,
        </cfif>
        change_date = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#uploadEntryDate#" />
        WHERE
            user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#userID#" />
    </cfquery>
    <cfquery name="queryUpdateUserMaster" datasource="#Application.DSN#">
        UPDATE user_master
        SET PASSWORD = <cfqueryparam cfsqltype="cf_sql_varchar" value="#password#" />,
        last_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lastName#" />,
        first_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#firstName#" />,
        last_name_kana = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lastNameKana#" />,
        first_name_kana = <cfqueryparam cfsqltype="cf_sql_varchar" value="#firstNameKana#" />,
        mailaddress = <cfqueryparam cfsqltype="cf_sql_varchar" value="#mailaddress#" />,
        management_cord = <cfqueryparam cfsqltype="cf_sql_varchar" value="#managementCord#" />,
        role_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#roleID#" />,
        login_start_date =
        <cfif loginStartDate neq "">
            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#loginStartDate#" />,
        <cfelse>
            NULL,
        </cfif>
        login_end_date =
        <cfif loginEndDate neq "">
            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#loginEndDate#" />,
        <cfelse>
            NULL,
        </cfif>
        login_stop = <cfqueryparam cfsqltype="cf_sql_char" value="#loginStopFlag#" />,
        user_note = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userNote#" />,
        <cfif themaID gt 0>
            user_thema_id = <cfqueryparam value="#themaID#" cfsqltype="cf_sql_integer" />,
        </cfif>
        change_date = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#uploadEntryDate#" />
        WHERE
            user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#userID#" />
    </cfquery>
</cfcomponent>