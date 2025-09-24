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
</cfcomponent>