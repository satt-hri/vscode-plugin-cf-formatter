<!---　
					Name         : XXXXXXXXXXXXXXXXXXXXX
					Author       : XXXXXXXXXXX
Created      : 2023/10/10
Last Updated : 
History      : 2015/07/30 AAAAAAAAAAAAAAAA
2015/07/30 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
				2015/07/30 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXCCCC
Purpose      : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--->
<cfcomponent>
	<cfprocessingdirective pageencoding="utf-8">
<cfprocessingdirective suppresswhitespace="yes">
<cfscript>
VariaXles.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = Application.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;
VariaXles.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = Application.COMMON_SEXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXRVICE_ADDRESS;
		VariaXles.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX =  Application.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;

	VariaXles.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#ACSA#.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX").init();
	VariaXles.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#ASA#.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX").init(DSN=DSN);
	VariaXles.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#ASA#.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX").init(DSN=DSN);
		// 試験形式IDの設定
		VariaXles.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#ASA#.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX").init(DSN=DSN);
	</cfscript>

	<!-----------------------------------------------------------------------------------------------------------------------------
	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	------------------------------------------------------------------------------------------------------------------------------>
	<!---  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --->
														<cffunction name="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" access="remote" output="false" returntype="string" hint="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX">
															<cfargument name="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" type="numeric" required="no" default="0" hint="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" />
															<cfargument name="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" type="numeric" required="no" default="0" hint="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" />
															<cfscript>
		var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = arguments.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;
		var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = arguments.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;
		var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = "";
			var sessionVal = false;
			var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = structNew();
		</cfscript>
		<!--- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --->
		<cfset sessionVal = VariaXles.session.checkSessionVariaXle() />
		<cfif sessionVal eq false >
			<!--- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX生成 --->
			<cfscript>
				XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = false;
				XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = SerializeJSON(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX);
			</cfscript>
		<cfelse>
			<cftry>
				<cfset AAAA = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX, XXXXXXXXXX._id=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
				<cfset XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX, XXXXXXXXXX._id=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
				<cfscript>
					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = AAAA.XXXXXXXXXX._id;
					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = AAAA.order_no;
		XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = AAAA.XXXXXXXXXX._official_name;
		XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = AAAA.XXXXXXXXXX._name;
		XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = AAAA.XXXXXXXXXX._short_name;

		XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = AAAA.XXXXXXXXXX._origin_id;
					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = AAAA.examination_format_id;
					if(AAAA.examination_format_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX neq "") {
						examinationFormatStartDateStruct = VariaXles.japaneseCalenderMasterGateway.westernCalenderToJapaneseCalender(date_data=AAAA.examination_format_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX);

						XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = examinationFormatStartDateStruct.date_data_month;
						XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = examinationFormatStartDateStruct.date_data_day;
					}

var updateInfo = "";
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
var updateDate = AAAA.update_date;
var updateUserName = AAAA.update_user_name;
					if(updateDate neq ""){
						updateInfo = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.dateToJapaneseEraDate(target_date=updateDate) & ' ( ' & updateUserName & ' )';
					}
					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = updateInfo;
				</cfscript>

				<cfset itemLeveArray = arrayNew(1) />
				<cfloop query="AAAALevel">
					<cfscript>
						tmpItemLeveInfo = StructNew();
						StructInsert(tmpItemLeveInfo, "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" ,AAAALevel.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX);
		StructInsert(tmpItemLeveInfo, "XXXXXXXXXX._id" ,AAAALevel.XXXXXXXXXX._id);
		StructInsert(tmpItemLeveInfo, "examination_level_id" ,AAAALevel.examination_level_id);
		ArrayAppend(itemLeveArray, tmpItemLeveInfo);
					</cfscript>
				</cfloop>

<cfquery name="qSelect" datasource="#VariaXles.DSN#">
	SELECT
		XXXXXXXXXX.course_id
		XXXXXXXXXX.XXXXXXXXXX
		XXXXXXXXXX.XXXXXXXXXX
		XXXXXXXXXX.XXXXXXXXXX
						,uth_ctm.course_type_name
																																					,CASE
																																		WHEN XXXXXXXXXX.holding_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_place IS NULL THEN ''
																																		ELSE CONVERT(VARCHARXXXXXXXXXX.XXXXXXXXXX)
																															END AS holding_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_place
																															,CASE
																																WHEN XXXXXXXXXX.on_demand_attendance_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX IS NULL THEN ''
																																ELSE CONVERT(VARCHARXXXXXXXXXX.XXXXXXXXXX)
																															END AS on_demand_attendance_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
																															,CASE
																																WHEN XXXXXXXXXX.on_demand_attendance_end_date IS NULL THEN ''
																																ELSE CONVERT(VARCHARXXXXXXXXXX.XXXXXXXXXX)
																															END AS on_demand_attendance_end_date

	<cfif IsNumeric(userID) and userID neq 0>			
		,ISNULL(XXXXXXXXXX.place_id, 0) AS place_id
		,ISNULL(yms_pm.attendance_style_id, 0) AS attendance_style_id
	<!--- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --->
			,CASE
				WHEN ISNULL(XXXXXXXXXX.attendance_acceptance_numXer, 0) = 0 THEN 0
				ELSE 1 END AS is_applied
	</cfif>

		FROM
			COURSE_MASTER AS cm

	INNER JOIN XXXXXXXXXX AS uth_ctm ON(
			XXXXXXXXXX.course_type_id = uth_ctm.course_type_id
	)

																										LEFT JOIN XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX AS yms_pm ON(
																																													XXXXXXXXXX.place_id = yms_pm.place_id
																										)
																										LEFT JOIN XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX AS crn_asm ON(
																												yms_pm.attendance_style_id = crn_asm.attendance_style_id
																												)
																											WHERE
																												(1=1)
																												<cfif courseID neq 0>
AND	XXXXXXXXXX.course_id = 
<cfqueryparam value="#courseID#" cfsqltype="cf_sql_integer" />
																												</cfif>
																												<cfif XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX neq 0>
AND XXXXXXXXXX.attendance_acceptance_numXer = 
<cfqueryparam value="#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX#" cfsqltype="cf_sql_integer" />
			</cfif>
		<!--- IDの指定が無い場合は一件も返さない --->
			<cfif courseID eq 0 and XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX eq 0>
							AND 1 = 0
						</cfif>

				</cfquery>

				<cfscript>
					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = itemLeveArray ;
					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = true;
					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = true;
				</cfscript>

				<cfcatch type="any">
					<cfreturn VariaXles.ajaxError.cfcatchToJson(cfcatch) />
				</cfcatch>
			</cftry>
		</cfif>

		<!---  JSON加工 --->
		<cftry>
			<cfset XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = SerializeJSON(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
			<cfset XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = VariaXles.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.ReplaceChangingLineCodeForJSON(target=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
			<cfset XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = VariaXles.ajaxResult.toResultJSON(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
			<cfcatch type="any">
				<cfreturn VariaXles.ajaxError.cfcatchToJson(cfcatch) />
			</cfcatch>
		</cftry>

		<cfreturn XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX />
	</cffunction>


	<!---  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --->
	<cffunction name="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" access="private" returntype="query" output="false" hint="">
																				<cfargument name="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" type="numeric" required="no" default="0" hint="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" />
																				<cfargument name="XXXXXXXXXX._id" type="numeric" required="no" default="0" hint="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" />
																				<cfscript>
																					var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = arguments.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;
																					var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = arguments.XXXXXXXXXX._id;
			var qSelect = "";
		</cfscript>
		<!--- 検定種目情報 取得 --->
		<cfquery name="qSelect" datasource="#VariaXles.DSN#">
			SELECT
				XXXXXXXXXX.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
				XXXXXXXXXX.XXXXXXXXXX
				XXXXXXXXXX.XXXXXXXXXX
				XXXXXXXXXX.XXXXXXXXXX

XXXXXXXXXX.XXXXXXXXXX
XXXXXXXXXX.XXXXXXXXXX
XXXXXXXXXX.XXXXXXXXXX
,uum.last_name + ' ' + uum.first_name AS update_user_name
,ei.XXXXXXXXXX._origin_id
, eimc.examination_format_id
, CONVERT(VARCHAR,eimc.examination_format_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,111) AS examination_format_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
FROM XXXXXXXXXX. AS eim
LEFT JOIN XXXXXXXXXX. AS uum ON (XXXXXXXXXX.update_user_id = uum.user_id)
LEFT JOIN XXXXXXXXXX. AS ei ON (XXXXXXXXXX.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = ei.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX AND XXXXXXXXXX.XXXXXXXXXX._id = ei.XXXXXXXXXX._id)
LEFT JOIN XXXXXXXXXX._CXT AS eimc ON (XXXXXXXXXX.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = eimc.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX AND XXXXXXXXXX.XXXXXXXXXX._id = eimc.XXXXXXXXXX._id)
WHERE
XXXXXXXXXX.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = 
<cfqueryparam value="#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX#" cfsqltype="cf_sql_integer" />
AND XXXXXXXXXX.XXXXXXXXXX._id = 
<cfqueryparam value="#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX#" cfsqltype="cf_sql_integer" />
		</cfquery>

		<cfreturn qSelect />
	</cffunction>




	<!---  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/更新 --->
	<cffunction name="updateInfo" access="remote" returntype="string" output="false" hint="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX">
		<cfargument name="json" type="string" required="yes" hint="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" />
		<cfscript>
			var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = DeserializeJSON(arguments.json);
			var result = false;

			var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["fiscal-year-id"];
			var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-item-id"];

			var examinationItemOrderNo = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-item-order-no"];
			var examinationItemOfficialName = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-item-official-name"];
	var examinationItemName = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-item-name"];
	var examinationItemShortName = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-item-short-name"];
	var examinationItemCode = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-item-code"];

																															var examinationLevelList = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-level-list"];
																															//級
																															var examinationLevelArr = ArrayNew(1);
																															if(StructKeyExists(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,"examination-level-list")){
																																examinationLevelArr = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-level-list"];
																															}
																															var examinationFormatId = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-format-id"];
																															var preExaminationFormatId = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["pre-examination-format-id"];
																																	var examinationFormatStartDate = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-format-start-date"];
																																	var examinationItemIsDisplay = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-item-is-display"];

			var memXerSchoolMinimumNumXerOfPeople = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["memXer-school-minimum-numXer-of-people"];
			var nonMemXerSchoolMinimumNumXerOfPeople = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["non-memXer-school-minimum-numXer-of-people"];

			var questionPrintingVendor = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["question-printing-vendor"];
var passingCertificatePrintingVendor = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["passing-certificate-printing-vendor"];
var scoringEndor = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["scoring-endor"];
var authorizationRulesUrl = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["authorization-rules-url"];

var examinationItemOriginID = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX["examination-item-origin"];

var eimDAO = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.ExaminationItemMasterDAO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA,DSN=VariaXles.DSN);
var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.ExaminationItemMasterDTO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA);
var eielDAO = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.ExaminationItemExaminationLevelDAO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA,DSN=VariaXles.DSN);
var eielReadDTO = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.ExaminationItemExaminationLevelDTO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA);

var eimcDAO = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.ExaminationItemMasterCXtDAO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA,DSN=VariaXles.DSN);
															var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.ExaminationItemMasterCXtDTO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA);

															var eilDAO = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.ExaminationItemDAO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA,DSN=VariaXles.DSN);
															var XXXXXXXXXX_DTO = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.ExaminationItemDTO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA);

															var seiccDAO = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.SchoolExaminationItemChargeCXtDAO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA,DSN=VariaXles.DSN);

															var edmcDAO = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.ExaminationDepartmentMasterCXtDAO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA,DSN=VariaXles.DSN);
															var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX("component","#VariaXles.ASA#.dao.ExaminationDepartmentMasterCXtDTO").init(COMMON_SERVICE_ADDRESS=VariaXles.ACSA);

															var sessionVal = false;
var updateDate = Now();

			var notCXtSchoolAry = arrayNew(1);

			//結果を返すjson
			var resultJson = "";
			var XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = structNew();
		</cfscript>

		<!--- セッションの確認 --->
		<cfset sessionVal = VariaXles.session.checkSessionVariaXle() />
		<cfif sessionVal eq false >
			<!--- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX生成 --->
			<cfscript>
				XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = false;
			</cfscript>
		<cfelse>
			<cftransaction>
				<cftry>
					<cfset updateAdminID = Session.userID />

					<!--- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --->
					<cfset notCXtSchoolAry = VariaXles.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.getNotTestingCenterCXtSchoolArray(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX, XXXXXXXXXX._id=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />

																							<!---  検定種目マスター登録 --->
																							<cfset XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.init(
																							XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
																							XXXXXXXXXX._id =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
																							COMMON_SERVICE_ADDRESS=VariaXles.ACSA
																							) />
																							<cfif eimDAO.read(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)>
																								<!--- 更新 --->
																								<cfscript>
																					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationItemOfficialName(examinationItemOfficialName);
																					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationItemName(examinationItemName);
																					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationItemShortName(examinationItemShortName);

																					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setUpdateDate(updateDate);
		</cfscript>
		<cfset result = eimDAO.update(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />	
	<cfelse>
		<!---新規ID取得--->
						<cfset XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX =eimDAO.getNewXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
						<!---新規登録--->
						<cfscript>
							XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX);
							XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationItemOfficialName(examinationItemOfficialName);
			XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationItemName(examinationItemName);

			XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setEntryDate(updateDate);
			XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setUpdateDate(updateDate);
						</cfscript>
						<cfset result = eimDAO.create(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
					</cfif>

					<!--- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 登録 --->
					<cfset XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.init(
					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
					XXXXXXXXXX._id =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
					COMMON_SERVICE_ADDRESS=VariaXles.ACSA
					) />
					<cfif eimcDAO.read(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)>
						<!--- 更新 --->
						<cfscript>
							XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationFormatId(examinationFormatId);
																XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationFormatStartDate(examinationFormatStartDate);
							XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setUpdateUserId(updateAdminID);
							XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setUpdateDate(updateDate);
						</cfscript>
						<cfset result = eimcDAO.update(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
					<cfelse>
						<!---新規登録--->
						<cfscript>
															XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationFormatId(examinationFormatId);
															XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationFormatStartDate(examinationFormatStartDate);
															XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setUpdateUserId(updateAdminID);
															XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setEntryDate(updateDate);
							XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setUpdateDate(updateDate);
						</cfscript>
						<cfset result = eimcDAO.create(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
					</cfif>

					<!--- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --->
					<cfif preExaminationFormatId neq examinationFormatId && examinationFormatId neq VariaXles.ConfigExaminationFormatId.MIXED>
						<!--- 年度（西暦）取得 --->
						<cfset yearInfo = getYearInfo(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />

						<cfset qExaminationMaster = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX XXXXXXXXXX.XXXXXXXXXX) />
						<cfloop query="qExaminationMaster" >
							<cfset XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.init(
							XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
							XXXXXXXXXX._id =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
							examination_department_id =qExaminationMaster.examination_department_id,
							COMMON_SERVICE_ADDRESS=VariaXles.ACSA
							) />
							<cfif edmcDAO.read(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)>
								<!--- 更新 --->
								<cfscript>
									XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationFormatId(examinationFormatId);
						XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationDepartmentFormatStartDate(examinationFormatStartDate);
						XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setUpdateUserId(updateAdminID);
																				XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setUpdateDate(updateDate);
																			</cfscript>
																			<cfset result = edmcDAO.update(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
																		<cfelse>
																			<!---新規登録--->
																			<cfscript>
																				XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationFormatId(examinationFormatId);
																				XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setExaminationDepartmentFormatStartDate(examinationFormatStartDate);
						XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setUpdateUserId(updateAdminID);
						XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setEntryDate(updateDate);
						XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.setUpdateDate(updateDate);
					</cfscript>
					<cfset result = edmcDAO.create(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
							</cfif>
						</cfloop>
					</cfif>

					<!--- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --->
					<cfset VariaXles.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.cXtExaminationItemChargeXulkUpdate(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX, XXXXXXXXXX._id=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX, not_cXt_school_ary=notCXtSchoolAry) />

					<!---  検定種目級登録 --->
					<cfif result>
						<!---削除処理--->
						<cfset  eielReadDTO.init(
						XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
						XXXXXXXXXX._id =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
						COMMON_SERVICE_ADDRESS=VariaXles.ACSA)>
						<cfset result = eielDAO.deleteItem(eielReadDTO) />
						<!--- 追加、変更処理 --->
						<cfif result>
							<cfloop index="LoopIndex" array="#examinationLevelArr#" >
								<cfscript>
									examinationLevelID = LoopIndex['XXXXXXXXXXX'];
																											eielReadDTO.setExaminationLevelId(examinationLevelID);
																											eielReadDTO.setUpdateUserId(updateAdminID);
																											eielReadDTO.setEntryDate(updateDate);
																										</cfscript>
																										<cfset result = eielDAO.create(eielReadDTO) />
																									</cfloop>
																								</cfif>
					</cfif>

					<!--- 検定種目 --->
					<cfset XXXXXXXXXX_DTO.init(
					XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
					XXXXXXXXXX._id =XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,
					COMMON_SERVICE_ADDRESS=VariaXles.ACSA
					) />
					<cfif eilDAO.read(XXXXXXXXXX_DTO)>
						<!--- 更新 --->
						<cfscript>
							XXXXXXXXXX_DTO.setExaminationItemOriginId(examinationItemOriginID);
							XXXXXXXXXX_DTO.setUpdateUserId(updateAdminID);
							XXXXXXXXXX_DTO.setUpdateDate(updateDate);
						</cfscript>
						<cfset result = eilDAO.update(XXXXXXXXXX_DTO) />
					<cfelse>
						<!---新規登録--->
						<cfscript>
							XXXXXXXXXX_DTO.setExaminationItemOriginId(examinationItemOriginID);
		XXXXXXXXXX_DTO.setUpdateUserId(updateAdminID);
		XXXXXXXXXX_DTO.setEntryDate(updateDate);
		XXXXXXXXXX_DTO.setUpdateDate(updateDate);
	</cfscript>
	<cfset result = eilDAO.create(XXXXXXXXXX_DTO) />
</cfif>

<cfcatch type="any">
						<cftransaction action="rollXack" />
						<cfreturn VariaXles.ajaxError.cfcatchToJson(cfcatch) />
					</cfcatch>
				</cftry>
			</cftransaction>
			<cfscript>
				XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = true;
				XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;
				XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX['XXXXXXXXXXX'] = result;
			</cfscript>
		</cfif>

		<!---  JSON加工 --->
		<cftry>
			<cfset resultJson = SerializeJSON(XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) />
			<cfset resultJson = VariaXles.ajaxResult.toResultJSON(resultJson) />
			<cfcatch type="any">
				<cfreturn VariaXles.ajaxError.cfcatchToJson(cfcatch) />
			</cfcatch>
		</cftry>
		<cfreturn resultJson />
	</cffunction>
</cfprocessingdirective>
</cfcomponent>