
<cfprocessingdirective pageencoding="UTF-8" suppresswhitespace="yes">
                <!--- aaaa
                sdfasdfasd
                ssddfdddddddd

                sdfasdfasd--->
        <cfcomponent>
    <cfset a =123 /><cfif true><cfset a =456 /></cfif>
            <cfswitch expression="#sponsorshipDisplayID#"><cfcase value="1"><cfset result = "su" />
            </cfcase><cfdefaultcase>
				<cfset result = "su" />
            </cfdefaultcase>
        </cfswitch> 
<cffunction name="xmlEscapeString" access="private" returntype="string" output="false" hint="エスケープ文字変換">
    <!---123　--->  <cfargument name="target" type="string" required="yes" hint="文字列" /><!---456　---><cfscript><!---789　--->
var str = arguments.target;
 
            str = Replace(str, '&', "&amp;", "all");
            str = Replace(str, '&', "\", "all");

str = Replace(str, '<br>', "&##xA;", "all");LogOutputcfc = CreateObject("component", "#COMMON_SERVICE_ADDRESS#.LogOutput").init();
    </cfscript><cfreturn str />
				<cfquery datasource="#Application.DSN#">UPDATE sco_progress
					SET    <cfif coreLog_array[1] neq "null">completion_status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#coreLog_array[1]#" />,</cfif>
						<cfif coreLog_array[4] neq "null">session_time = <cfqueryparam cfsqltype="cf_sql_varchar" value="#coreLog_array[4]#" />,
															total_time = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ScoTotalTime#" />,
						</cfif>

						sco_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#sco_id#" />
					WHERE  user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_id#" />
		
				</cfquery></cffunction>
</cfcomponent>
                </cfprocessingdirective>