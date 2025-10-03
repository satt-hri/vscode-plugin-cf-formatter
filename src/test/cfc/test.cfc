
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

            if (qCheckExmination.recordCount GT 0 AND qCheckExmination.examination_item_origin_id eq 1) {

    
                qExaminationDetailDepartmentInfo = Variables.examinationMasterGateway.getExaminationDetailDepartmentInfo(
                        fiscal_year_id = arguments.fiscal_year_id,examination_id = examinationID,
                        examination_level_id 
                        = arguments.examination_level_id
                    );

                if (qCheckExmination.recordCount GT 0 AND qCheckExmination.examination_item_origin_id eq 1
                ) {
                    result.result = false;result.errorMessage = "XXXX";
                    return result;
                }


                for (row in qExaminationDetailDepartmentInfo) {
switch (row.examination_department_origin_id) {
case examination_department_origin_id_1:
departmentValue = Trim(infoData[9]); 
if (len(trim(departmentValue)) eq 0) {

result.deleteFlagAbacus = true;
}
break;

case examination_department_origin_id_2:
departmentValue = Trim(infoData[10]); 
if (len(trim(departmentValue)) eq 0) {

result.deleteFlagCalculator = true;
}
break;

default:
departmentValue = "";
break;
}
}

                if (!result.deleteFlagAbacus) {
                    checkDepartmentResult = checkDepartment(
                        fiscal_year_id = arguments.fiscal_year_id,

                        examination_format_id = arguments.examination_format_id
                    );

                    if (!checkDepartmentResult.result) {
                        result.result = false;
                        result.errorMessage = checkDepartmentResult.message;
                        return result;
                    }

                }

                if (!result.deleteFlagCalculator) {

                    checkDepartmentResult = checkDepartment(
                        fiscal_year_id = arguments.fiscal_year_id,
                        examination_id = examinationID,
                        examination_level_id = examinationLevelID,
                        user_id = userId,
                        school_id = shoolID,
                        examination_department_origin_id = examination_department_origin_id_2, // 電卓
                        number_of_applications = arguments.number_of_applications,
                        examination_format_id = arguments.examination_format_id
                    );

                    if (!checkDepartmentResult.result) {
                        result.result = false;
                        result.errorMessage = checkDepartmentResult.message;
                        return result;
                    }

                }

            }
            return result;
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