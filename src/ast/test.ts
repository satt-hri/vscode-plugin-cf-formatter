export const examples = {
	1: `<cfset userName = "张三">
<cfset userAge = 25>
<cfoutput>
  用户名：#userName#，年龄：#userAge#
</cfoutput>`,
	2: `<cfset score = 85>
<cfif score GT 90>
  <cfset grade = "优秀">
<cfelse>
  <cfset grade = "良好">
</cfif>`,
	3: `<cfloop index="i" from="1" to="5">
  <cfset result = i * 2>
</cfloop>`,
	4: `<cfscript>
  var x = 10;
  var y = 20;
  
  function add(a, b) {
    return a + b;
  }
  
  var sum = add(x, y);
</cfscript>`,
	5: `<cfset total = 0>
<cfloop index="i" from="1" to="10">
  <cfif i GT 5>
    <cfset total = total + i>
    <cfoutput>当前i=#i#, total=#total#</cfoutput>
  </cfif>
</cfloop>`,
	6: `<cfcomponent>
  <cffunction name="checkData" access="private" returntype="struct" output="false">
    <cfargument name="fiscal_year_id" type="numeric" required="yes" />
    <cfargument name="department_id" type="numeric" required="no" />
    
    <cfscript>
      var qCheck = "";
      var result = {
        success: true,
        errorMessage: "",
        deleteFlag: false
      };
      
      if (qCheck.recordCount GT 0 AND qCheck.item_id eq 1) {
        qDetailInfo = Variables.gateway.getDetailInfo(
          fiscal_year_id = arguments.fiscal_year_id,
          examination_id = examId,
          level_id = arguments.level_id
        );
        
        for (row in qDetailInfo) {
          switch (row.department_origin_id) {
            case department_id_1:
              deptValue = Trim(data[9]);
              if (len(trim(deptValue)) eq 0) {
                result.deleteFlag = true;
              }
              break;
            case department_id_2:
              deptValue = Trim(data[10]);
              break;
            default:
              deptValue = "";
              break;
          }
        }
        
        if (!result.deleteFlag) {
          checkResult = checkDepartment(
            fiscal_year_id = arguments.fiscal_year_id,
            format_id = arguments.format_id
          );
          
          if (!checkResult.success) {
            result.success = false;
            result.errorMessage = checkResult.message;
            return result;
          }
        }
      }
      
      return result;
    </cfscript>
    
    <cfquery name="qCheck" datasource="#Variables.DSN#">
      SELECT 
        ei.item_origin_id,
        em.examination_id
      FROM EXAMINATION_MASTER AS em
      INNER JOIN DEPARTMENT_MASTER AS dm 
        ON dm.fiscal_year_id = em.fiscal_year_id
      WHERE em.fiscal_year_id = <cfqueryparam value="#arguments.fiscal_year_id#" cfsqltype="cf_sql_integer" />
        AND em.exam_id = <cfqueryparam value="#examId#" cfsqltype="cf_sql_integer" />
    </cfquery>
  </cffunction>
</cfcomponent>`,
};