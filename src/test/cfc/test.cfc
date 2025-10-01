
<cfcomponent>
    <cfprocessingdirective pageencoding="utf-8">
    <cfprocessingdirective suppresswhitespace="yes">

    <cffunction name="test1" access="private" returntype="struct" output="false" hint="xxx">
        <cfargument name="fiscal_year_id" type="numeric" required="yes" hint="" />
        <cfargument name="examination_department_id" type="numeric" required="no" hint="" />


        <cfscript>
                            var qCheckExmination = "";
     var qExaminationDetailDepartmentInfo = "";

            var result = {result: true,
                errorMessage: "",
                deleteFlagAbacus: false,
                deleteFlagCalculator: false
            };
        </cfscript>

        <!--- ビジネス計算試験かどうかを判定 --->

        <cfquery name="qCheckExmination" datasource="#Variables.DSN#">
            SELECT ei.examination_item_origin_id,
                em.examination_id
            FROM
EXAMINATION_MASTER AS em
                INNER JOIN EXAMINATION_DEPARTMENT_MASTER AS edm ON edm.fiscal_year_id = em.fiscal_year_id
                AND edm.examination_item_id = em.examination_item_id  INNER JOIN EXAMINATION_ITEM AS ei ON ei.fiscal_year_id = edm.fiscal_year_id
            WHERE
                em.fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND em.examination_id = <cfqueryparam value="#examinationID#" cfsqltype="cf_sql_integer" />
        </cfquery>

    </cffunction>

    <cffunction name="test2" access="private" returntype="struct" output="false" hint="xxx">
        <cfargument name="fiscal_year_id" type="numeric" required="yes" hint="" />
        <cfargument name="examination_department_id" type="numeric" required="no" hint="" />

        <cfscript>
                            var qCheckExmination = "";
     var qExaminationDetailDepartmentInfo = "";

            var result = {result: true,
                errorMessage: "",
                deleteFlagAbacus: false,
                deleteFlagCalculator: false
            };
        </cfscript>

        <!--- ビジネス計算試験かどうかを判定 --->

        <cfquery name="qCheckExmination" datasource="#Variables.DSN#">
            SELECT ei.examination_item_origin_id,
                em.examination_id
            FROM
EXAMINATION_MASTER AS em
                INNER JOIN EXAMINATION_DEPARTMENT_MASTER AS edm ON edm.fiscal_year_id = em.fiscal_year_id
                AND edm.examination_item_id = em.examination_item_id  INNER JOIN EXAMINATION_ITEM AS ei ON ei.fiscal_year_id = edm.fiscal_year_id
            WHERE
                em.fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
                AND em.examination_id = <cfqueryparam value="#examinationID#" cfsqltype="cf_sql_integer" />
        </cfquery>

    </cffunction>

    </cfprocessingdirective>
</cfcomponent>