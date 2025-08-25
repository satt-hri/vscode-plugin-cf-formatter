<cfcomponent restpath="/auth/sessions" rest="true">
<!--- 共通 --->
	<cfscript>
		libCommon = CreateObject("component","lib.common");
		libSession = CreateObject("component","lib.session");
		libLmsInfo = CreateObject("component","lib.lms_info");
	</cfscript>

	<!--- ログイン --->
	<cffunction httpmethod="POST" restpath="" name="login" access="remote" returntype="void" produces="application/json">
		<cfargument name="requestBody" type="struct" required="yes"/>

		<cfset var http_status = 500>

		<cftry>
			<!--- ↓↓↓ start API Unique processing --->

			<cfscript>
				var libLogin = CreateObject("component","lib.login");
				try{
					// パラメータチェック
					if(Not structKeyExists(arguments.requestBody, "id")
					or Not structKeyExists(arguments.requestBody, "pw")
					or Not structKeyExists(arguments.requestBody, "flg")
					){
						restSetResponse(libCommon.returnRESTResponse(400));
						return;
					}
					if(arguments.requestBody["id"] eq "" or arguments.requestBody["pw"] eq "" or arguments.requestBody["flg"] eq ""){
						restSetResponse(libCommon.returnRESTResponse(400));
						return;
					}
					if(isBoolean(arguments.requestBody["flg"]) eq false){
						restSetResponse(libCommon.returnRESTResponse(400));
						return;
					}
					// 認証チェック
					var resultAuth = libLogin.Authentication(arguments.requestBody["id"],arguments.requestBody["pw"],arguments.requestBody["flg"]);
					switch(resultAuth){
						case 0:{
							break;
						}
						case 1:{
							var restBody = {};
							restBody["cd"] = int(resultAuth);
							restBody["message"] = "上書きログインの確認が必要";
							restSetResponse(libCommon.returnRESTResponse(200, serializeJSON(restBody) ));
							return;
						}
						case -1:	// ID が存在しない or パスワードエラー
						case -2:	// 廃止レスポンス（旧 パスワードエラー）
						{
							restSetResponse(libCommon.returnRESTResponse(401));
							return;
						}
						case -3:	// IDが無効
						case -4:	// IDの有効期間外
						case -5:	// ログインロック中
						{
							restSetResponse(libCommon.returnRESTResponse(http_code=403,content="0"));
							return;
						}
					}

					// 認証成功したため、セッション作成やDBのログイン情報更新
					transaction {
						try{
							// ログインセッション作成
							libLogin.setLoginSession(arguments.requestBody["id"]);

							// ログインログ記録
							libLogin.setLoginLog(arguments.requestBody["id"]);
							transaction action="commit";
						}
	catch(any e){
		transaction action="rollback";
		rethrow;
	}
}
					// セッションハイジャック対策
					SessionRotate();
					var menuGroupData = libSession.getLoginMenuData();
					if(arrayLen(menuGroupData) eq 0){
						restSetResponse(libCommon.returnRESTResponse(http_code=403,content="1"));
						return;
						}else{
						if(arrayLen(menuGroupData[1].menu_data_array) eq 0){
							restSetResponse(libCommon.returnRESTResponse(http_code=403,content="1"));
							return;
							}else{
							if(arrayLen(menuGroupData[1].menu_data_array[1].module_data_array) eq 0){
								restSetResponse(libCommon.returnRESTResponse(http_code=403,content="1"));
								return;
							}
						}
					}
					// 遷移先のURLを取得
					restBody["user_id"] = libSession.getLoginUserID();
					restBody["last_name"] = libSession.getLoginLastName();
					restBody["first_name"] = libSession.getLoginFirstName();
					restBody["group_ids"] = libSession.getLoginGroupID();

					header_location = libLogin.getLocationURL();
					restHeader["Location"] = header_location;
					restHeader["csrf_token"] = libSession.getLoginCSRFToken();

					restSetResponse(libCommon.returnRESTResponse(201, serializeJSON(restBody), restHeader));
					return;

					}catch(any e){
					rethrow;
				}
			</cfscript>

			<!--- ↑↑↑ end API Unique processing --->
			<!--- これ以降は共通処理 --->
			<cfcatch type="any">
				<cfset restSetResponse(libCommon.returnRESTResponse(500, serializeJSON(cfcatch))) />
				<cfreturn/>
			</cfcatch>
		</cftry>
	</cffunction>


	<cffunction httpmethod="DELETE" restpath="" name="logout" access="remote" returntype="void" produces="application/json">

		<cfscript>
			libCrypt = CreateObject( "component", "lib.crypt" );
		</cfscript>

		<cfset http_status = 500>
		<cftry>
			<!--- ↓↓↓ start API Unique processing --->
			<cfscript>
				var verifyAPI = libCommon.verifyAPIAccess();

				if(verifyAPI != 200){
					restSetResponse(libCommon.returnRESTResponse(verifyAPI));
					return;
					}else{
					// 「ログインIDとパスワードの保存」を使用する場合
					if (libLmsInfo.getLMSInfo().store_login_info eq 1){
						var login_id = libCrypt.encryptString(libSession.getLoginLoginID());	// ログインIDは暗号化してCookie保存
						var password = libSession.getLoginPassword();							// パスワードは既に暗号化してセッションに保持しているので、そのままでCookie保持
						cfcookie(name="login_id", value=login_id, expires="never", httponly="yes", secure=request.sessioncookie_secure );
						cfcookie(name="password", value=password, expires="never", httponly="yes", secure=request.sessioncookie_secure );
						}else{
						// expires="now" でCookieの即時削除を行う
						cfcookie(name="login_id", value="", expires="now");
						cfcookie(name="password", value="", expires="now");
					}
					// ログインログをログアウトに変更する
					q_upd_login_log = queryExecute(
					"
					UPDATE	user_login_log
					SET		logout_time = CURRENT_TIMESTAMP
					, exaction_flag = '0'
					WHERE	1 = 1
					AND	user_id			= :user_id
					AND	session_uuid	= :session_uuid
					AND	logout_time		IS NULL
					"
					,{
					user_id = {value = libSession.getLoginUserID(), cfsqltype = 'CF_SQL_INTEGER'}
					, session_uuid = {value = libSession.getUUID(), cfsqltype = 'CF_SQL_VARCHAR'}
				}
					,{datasource = Application.DSN}
					);
					// このsessionInvalidateで 「 onSessionEnd 」 が自動発生する
					// セッション固定化攻撃 対策
					// 参照URL： https://www.samuraiz.co.jp/coldfusion/faq/dl/CFDay2014_security.pdf/
					sessionInvalidate();
					restSetResponse(libCommon.returnRESTResponse(204));
					return;
				}
			</cfscript>

			<!--- ↑↑↑ end API Unique processing --->
			<!--- これ以降は共通処理 --->
			<cfcatch type="any">
				<cfset restSetResponse(libCommon.returnRESTResponse(500, serializeJSON(cfcatch))) />
				<cfreturn/>
			</cfcatch>
		</cftry>
	</cffunction>

	<!--- GET /auth/sessions ログイン状態を取得（常に200） --->
	<cffunction httpmethod="GET" restpath="" name="LoggedIn" access="remote" returntype="void" produces="application/json">
		<cfset http_status = 200>
		<cftry>
			<!--- ↓↓↓ start API Unique processing --->
			<cfscript>
				// ログイン状態を取得
				var restBody = {};
				restBody["authenticated"] = false;

				var verifyAPI = libCommon.verifyAPIAccess();
				if(verifyAPI != 200){
				restSetResponse(libCommon.returnRESTResponse(200, serializeJSON(restBody)));
				return;
				}
				restBody["authenticated"] = true;
				restSetResponse(libCommon.returnRESTResponse(200, serializeJSON(restBody)));
			</cfscript>

			<!--- ↑↑↑ end API Unique processing --->
			<!--- これ以降は共通処理 --->
			<cfcatch type="any">
				<cfset restSetResponse(libCommon.returnRESTResponse(500, serializeJSON(cfcatch))) />
				<cfreturn/>
			</cfcatch>
		</cftry>
	</cffunction>
</cfcomponent>
