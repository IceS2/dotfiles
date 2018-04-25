var lastpass,LPFormParser,LPUtils,__extends=this&&this.__extends||function(){var e=Object.setPrototypeOf||{__proto__:[]}instanceof Array&&function(e,t){e.__proto__=t}||function(e,t){for(var r in t)t.hasOwnProperty(r)&&(e[r]=t[r])};return function(t,r){function s(){this.constructor=t}e(t,r),t.prototype=null===r?Object.create(r):(s.prototype=r.prototype,new s)}}();!function(e){(LPUtils||(LPUtils={})).stringContains=function(e,t){if(e&&t){Array.isArray(t)||(t=[t]);for(var r=0;r<t.length;++r)if(e.indexOf(t[r])>-1)return!0}return!1}}(),function(e){var t=function(){function e(){this.operations=[]}return e.regexMatches=function(e,t){var r=!1;if(e){var s=function(e,t){return"string"==typeof t&&e.test(t.toLowerCase())};Array.isArray(t)?t.forEach(function(t){return r=r||s(e,t)}):r=s(e,t)}return r},e.getFormFieldRegex=function(e){var t=get_ff_translation(e);if(t)return new RegExp(t)},e.prototype.parse=function(e,t,r){for(var s=null,i=0,n=this.operations;i<n.length;i++){if((s=(0,n[i])(e,t,r))||!1===s)break}return s},e}();e.FieldParser=t}(LPFormParser||(LPFormParser={})),function(e){var t=function(t){function r(){var s=t.call(this)||this;return r.excludedFields.length||(r.excludedFields=[{type:"attr",regex:e.FieldParser.getFormFieldRegex("ff_ssn_regexp")},{type:"attr",regex:e.FieldParser.getFormFieldRegex("ff_cccsc_regexp")},{type:"attr",regex:e.FieldParser.getFormFieldRegex("ff_securityanswer_regexp")},{type:"attr",regex:e.FieldParser.getFormFieldRegex("ff_captcha_regexp")},{type:"text",regex:e.FieldParser.getFormFieldRegex("ff_text_ssn_regexp")},{type:"text",regex:e.FieldParser.getFormFieldRegex("ff_text_cccsc_regexp")}]),s.operations=[r.excludedFieldOperation,r.singlePasswordFieldOperation,r.multiplePasswordOperation,r.multiplePasswordsOneExistingOperation,r.passwordLikeAttribute],s}return __extends(r,t),r.excludedFieldOperation=function(t,s,i){for(var n=0;n<t.fields.length;++n)for(var a=t.fields[n],o=0;o<r.excludedFields.length;++o){var u=r.excludedFields[o];if(u.regex){if("attr"===u.type&&e.FieldParser.regexMatches(u.regex,[a.id,a.attributes.name]))return!1;if("text"===u.type&&e.FieldParser.regexMatches(u.regex,a.label))return!1}}return null},r.singlePasswordFieldOperation=function(e,t,r){if(1===t.uniquePasswords.length){var s=t.uniquePasswords[0];return 2===t.passwordsByValue[s].count&&(2===e.fields.length?e.passwordChangeForm=!0:e.createAccountForm=!0),s}return null},r.multiplePasswordOperation=function(e,t,r){for(var s=0,i=t.uniquePasswords;s<i.length;s++){var n=i[s];if(t.passwordsByValue[n].count>1)return 2===t.uniquePasswords.length?(e.passwordChangeForm=!0,e.originalPassword=t.uniquePasswords[0]===n?t.uniquePasswords[1]:t.uniquePasswords[0]):e.createAccountForm=!0,n}return null},r.multiplePasswordsOneExistingOperation=function(e,t,s){if(2===t.uniquePasswords.length){var i=r.findMatchingPassword(s.getSites(),t.uniquePasswords);if(i)return e.passwordChangeForm=!0,e.originalPassword=i,t.uniquePasswords[0]===i?t.uniquePasswords[1]:t.uniquePasswords[0]}return null},r.passwordLikeAttribute=function(e,t,r){for(var s=0,i=t.uniquePasswords;s<i.length;s++){var n=i[s],a=t.passwordsByValue[n].field,o=["pw","pass"];if(LPUtils.stringContains(a.attributes.name,o)||LPUtils.stringContains(a.id,o))return n}},r.findMatchingPassword=function(e,t){for(var r=0;r<e.length;++r){var s=LPUtils.SiteParser.findMatchingSitePassword(e[r],t);if(s)return s}return null},r.excludedFields=[],r}(e.FieldParser);e.PasswordFieldParser=t}(LPFormParser||(LPFormParser={})),function(e){var t=function(t){function r(e){var s=t.call(this)||this;return s.isStrict=e,s.isStrict?s.operations=[r.userNameLikeLabelOperation,r.userNameLikeAttributeOperation]:s.operations=[r.userNameLikeLabelOperation,r.singleTextFieldOperation,r.multipleTextFieldOperation,r.nearPasswordFieldOpeartion,r.existingUserNameOperation,r.uniqueEmailFieldOperation,r.userNameLikeAttributeOperation],s}return __extends(r,t),r.userNameLikeLabelOperation=function(t,s,i){if(r.userNameRegEx)for(var n=0,a=t.fields;n<a.length;n++){var o=a[n];if(e.FieldParser.regexMatches(r.userNameRegEx,o.label))return o.value}return null},r.userNameLikeAttributeOperation=function(e,t,r){for(var s=0,i=t.uniqueTextValues;s<i.length;s++){var n=i[s],a=t.textFieldsByValue[n].field;if(LPUtils.stringContains(a.attributes.name,"user")||LPUtils.stringContains(a.id,"user"))return n}return null},r.singleTextFieldOperation=function(e,t,r){if(1===t.uniqueTextValues.length){var s=t.uniqueTextValues[0];return 2===t.textFieldsByValue[s].count&&(e.createAccountForm=!0),s}return null},r.multipleTextFieldOperation=function(e,t,r){for(var s=0,i=t.uniqueTextValues;s<i.length;s++){var n=i[s];if(t.textFieldsByValue[n].count>1)return e.createAccountForm=!0,n}return null},r.nearPasswordFieldOpeartion=function(e,t,r){for(var s=e.fields,i=1;i<s.length;++i){if("password"===s[i].type){var n=s[i-1];if("password"!==n.type)return n.value}}return null},r.existingUserNameOperation=function(e,t,r){for(var s in g_sites)if(t.uniqueTextValues.indexOf(g_sites[s].unencryptedUsername)>-1)return g_sites[s].unencryptedUsername;return null},r.uniqueEmailFieldOperation=function(e,t,s){for(var i=[],n=0,a=t.uniqueTextValues;n<a.length;n++){var o=a[n],u=o.match(r.emailRegex);u&&1===u.length&&i.push(o)}return 1===i.length?i[0]:null},r.emailRegex=/[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*/g,r.userNameRegEx=e.FieldParser.getFormFieldRegex("ff_username_regexp"),r}(e.FieldParser);e.UserNameFieldParser=t}(LPFormParser||(LPFormParser={})),function(e){var t=function(){return function(e,t,r,s){void 0===t&&(t=""),void 0===r&&(r=""),void 0===s&&(s=!1),this.url=e,this.userName=t,this.password=r,this.suppliedBefore=s,this.cancelled=!1}}();e.AuthCredential=t}(lastpass||(lastpass={})),function(e){var t=function(){function t(){this.authCredentials={},this.subscribeEvents()}return t.prototype.subscribeEvents=function(){var t=this;LPPlatform.onAuthRequired(function(r,s){if(g_basicauth_feature_enabled&&"basic"===r.scheme){var i=t.authCredentials[r.tabId];if(i&&!i.cancelled&&!i.suppliedBefore)return t.authCredentials[r.tabId]=new e.AuthCredential(r.url,i.userName,i.password,!0),t.removeAuth(s),{authCredentials:{username:i.userName,password:i.password}};if(!i)return t.authCredentials[r.tabId]=new e.AuthCredential(r.url),{cancel:!0}}}),LPPlatform.onTabClosed(function(e){t.removeAuth(e)})},t.prototype.removeAuth=function(e){this.authCredentials[e]&&delete this.authCredentials[e]},t.prototype.isBasicAuth=function(e,t){var r=this.authCredentials[t.tabID];if(r){if(r.url!==t.tabURL)return e(!1,!1),void this.removeAuth(t.tabID);if(!r.cancelled)return void e(!0,r.suppliedBefore)}e(!1,!1)},t.prototype.setAuthCredential=function(e,t,r,s){var i=this.authCredentials[s.tabID];i.userName=e,i.password=t,r()},t.prototype.cancelBasicAuth=function(e){this.authCredentials[e.tabID]&&(this.authCredentials[e.tabID].cancelled=!0)},t.prototype.hasFeature=function(e){e(!0)},t.prototype.isNotificationClosed=function(e){e("closed"===localStorage_getItem("basicAuthPopupState"))},t.prototype.closeNotification=function(){localStorage_setItem("basicAuthPopupState","closed")},t}();e.BasicAuth=t}(lastpass||(lastpass={})),this.basicAuth=new lastpass.BasicAuth,function(e){var t=function(){function e(e){var t=this;this.passwordsByValue={},this.textFieldsByValue={},this.textFieldsByType={},this.uniqueTextValues=[],this.uniquePasswords=[],e.fields&&(e.fields.forEach(function(e){"password"===e.type?t.aggregateField(e,e.value,t.passwordsByValue):(t.aggregateField(e,e.value,t.textFieldsByValue),t.aggregateField(e,e.type,t.textFieldsByType))}),this.uniqueTextValues=Object.keys(this.textFieldsByValue),this.uniquePasswords=Object.keys(this.passwordsByValue))}return e.prototype.aggregateField=function(e,t,r){var s=r[t];s?++s.count:r[t]={field:e,count:1}},e}();e.FormMetaData=t}(LPFormParser||(LPFormParser={})),function(e){var t=function(){function t(t,r,s){this._formData=null,this._userNameField=null,this._succeeded=!1,this._submitted=!1,r.fields=r.fields||[];var i=new e.FormMetaData(r);if(!r.password)if(r.generatedPassword)r.password=r.generatedPassword;else{var n=(new e.PasswordFieldParser).parse(r,i,t);"string"==typeof n&&(r.password=n)}var a=new e.UserNameFieldParser(s&&s.strict).parse(r,i,t),o=[];"string"==typeof a&&(o=t.getSites().filter(function(e){return LPUtils.SiteParser.hasMatchingSiteUserName(e,a)}),r.username&&0===o.length&&!r.createAccountForm||(r.username=a));if(r.username&&!r.createAccountForm)for(var u=0,l=r.fields;u<l.length;u++){var d=l[u];if(d.value===r.username){this._userNameField=d;break}}this._formData=r,this._submitted=!r.generatedPassword}return t.prototype.submitted=function(e){return"boolean"==typeof e&&(this._submitted=e),this._submitted},t.prototype.succeeded=function(e){return"boolean"==typeof e&&(this._succeeded=e),this._succeeded},t.prototype.getUsernameField=function(){return this._userNameField},t.prototype.getUsername=function(){return this._formData.username},t.prototype.getPassword=function(){return this._formData.password},t.prototype.getOriginalPassword=function(){return this._formData.originalPassword},t.prototype.getFormData=function(){return this._formData},t.prototype.getFields=function(){return this._formData.fields},t.prototype.isChangePasswordForm=function(){return!!this._formData.passwordChangeForm},t.prototype.isCreateAccountForm=function(){return!!this._formData.passwordChangeForm},t.prototype.isBasicAuthentication=function(){return!!this._formData.basicAuthentication},t.prototype.shouldSaveFields=function(){return!this.isChangePasswordForm()&&!this.isCreateAccountForm()},t.prototype.getURL=function(){return this._formData.url},t}();e.FormParser=t}(LPFormParser||(LPFormParser={})),function(e){(LPUtils||(LPUtils={})).decrypt=function(e,t){return lpmdec_acct(t,!0,e,g_shares)}}(),function(e){var t=function(){function t(){}return t.findMatchingSitePassword=function(t,r){Array.isArray(r)||(r=[r]);var s=r.indexOf(e.decrypt(t,t.password));if(-1===s&&t.fields&&t.fields.length>0)for(var i=0;i<t.fields.length;++i){var n=t.fields[i];if("password"===n.type&&(s=r.indexOf(e.decrypt(t,n.value)))>-1)break}return s>-1?r[s]:null},t.hasMatchingSiteUserName=function(t,r){if(!r)return!1;if(this.userNamesMatch(t.unencryptedUsername,r))return!0;if(t.fields&&t.fields.length)for(var s=0,i=t.fields;s<i.length;s++){var n=i[s];switch(n.type){case"text":case"email":case"tel":if(this.userNamesMatch(e.decrypt(t,n.value),r))return!0}}return!1},t.userNamesMatch=function(e,t){return e===t||this.userNameInEmail(e,t)||this.userNameInEmail(t,e)||this.isMaskedUsername(e,t)},t.userNameInEmail=function(e,t){if(t&&t.indexOf("@")>-1){var r=t.split("@");return 2===r.length&&e===r[0]}return!1},t.isMaskedUsername=function(e,t){return(t.indexOf("*")>-1||t.indexOf(String.fromCharCode(8226))>-1)&&(e.length===t.length&&(e[0]===t[0]||e[e.length-1]===t[t.length-1]))},t}();e.SiteParser=t}(LPUtils||(LPUtils={}));
//# sourceMappingURL=sourcemaps/modules-background.js.map
