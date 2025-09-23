
<cfprocessingdirective pageencoding="UTF-8" suppresswhitespace="yes">
<!--- エスケープ文字の置換処理 --->
<cffunction name="xmlEscapeString" access="private" returntype="string" output="false" hint="エスケープ文字変換">
<!---123　--->  
<cfargument name="target" type="string" required="yes" hint="文字列" />
<!---456　--->
<cfscript>
<!---789　--->
var str = arguments.target;
            //xmlエスケープ文字(&を最初に置換しておく)
            str = Replace(str, '&', "&amp;", "all");
            str = Replace(str, '&', "\", "all");

//<br>タグがあった場合は改行する(コース名で使用されるため)
str = Replace(str, '<br>', "&##xA;", "all");LogOutputcfc = CreateObject("component", "#COMMON_SERVICE_ADDRESS#.LogOutput").init();

</cfscript>
<cfreturn str />
</cffunction>

<cfquery name="qSelect" datasource="#Variables.DSN#">
        	SELECT 
            	um.user_id
                ,um.user_type_id
                ,um.mailaddress
                ,um.password
				,pu.place_id
            FROM 
            	UTH_USER_MASTER AS um    
				LEFT JOIN YMS_PLACE_USER AS pu ON(um.user_id=pu.user_id)   
				LEFT JOIN YMS_PLACE_MASTER AS pm ON (pu.place_id=pm.place_id)
            WHERE 
            	um.is_delete = 0     
				<!--- 会場IDがない（通常ユーザ）　または受講形式がライブの会場ユーザ --->
				AND (pu.place_id is NULL
					OR (pu.place_id is NOT NULL AND pm.attendance_style_id =2)
				)        
<cfif loginID neq "">
            AND	
            (
			<!--- 共通 ---> 
um.login_id  = 
<cfqueryparam value="#loginID#" cfsqltype="cf_sql_varchar" />
				<!---大文字・小文字区別--->
				COLLATE Japanese_CS_AS_KS_WS 

            )             
<cfelse>
            AND 1 = 0 
</cfif>
<cfif loginPasswordExists>
<cfif loginPassword neq "">
AND um.password = 
<cfqueryparam value="#loginPassword#" cfsqltype="cf_sql_varchar" >
			<!---大文字・小文字区別--->
			COLLATE Japanese_CS_AS_KS_WS 
<cfelse>
            AND 1 = 0 
</cfif>
</cfif>

</cfquery>

				<cfquery datasource="#Application.DSN#">
					UPDATE sco_progress
					SET    <cfif coreLog_array[1] neq "null">completion_status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#coreLog_array[1]#" />,</cfif>
						<cfif coreLog_array[2] neq "null">location = <cfqueryparam cfsqltype="cf_sql_varchar" value="#coreLog_array[2]#" />,</cfif>
						<cfif coreLog_array[3] neq "null" and coreLog_array[3] neq "">raw_score = <cfqueryparam cfsqltype="cf_sql_float" value="#coreLog_array[3]#" />,</cfif>
						<cfif coreLog_array[4] neq "null">session_time = <cfqueryparam cfsqltype="cf_sql_varchar" value="#coreLog_array[4]#" />,
															total_time = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ScoTotalTime#" />,
						</cfif>
						<cfif coreLog_array[5] neq "null">suspend = <cfqueryparam cfsqltype="cf_sql_varchar" value="#coreLog_array[5]#" />,</cfif>
						<cfif coreLog_array[6] neq "suspend">entry = '', <cfelse>entry = <cfqueryparam cfsqltype="cf_sql_varchar" value="resume" />,</cfif>
						<cfif coreLog_array[7] neq "null" and coreLog_array[7] neq "">max_score = <cfqueryparam cfsqltype="cf_sql_float" value="#coreLog_array[7]#" />,</cfif>
						<cfif coreLog_array[8] neq "null" and coreLog_array[8] neq "">min_score = <cfqueryparam cfsqltype="cf_sql_float" value="#coreLog_array[8]#" />,</cfif>
						<cfif save_complete_date eq true>complete_date = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#" />,</cfif>
						sco_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#sco_id#" />
					WHERE  user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_id#" />
					AND	   course_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#course_id#" />
					AND	   sco_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#sco_id#" />
				</cfquery>

</cfprocessingdirective>