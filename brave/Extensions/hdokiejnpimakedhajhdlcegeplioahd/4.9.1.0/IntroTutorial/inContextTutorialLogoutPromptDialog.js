var InContextTutorialLogoutPromptDialog=function(t){Dialog.call(this,t,{closeButtonEnabled:!1,maximizeButtonEnabled:!1,dynamicHeight:!1,hideHeader:!0,hideButtons:!0,confirmOnClose:!1})};InContextTutorialLogoutPromptDialog.prototype=Object.create(Dialog.prototype),InContextTutorialLogoutPromptDialog.prototype.constructor=InContextTutorialLogoutPromptDialog,jQuery,InContextTutorialLogoutPromptDialog.prototype.initialize=function(t){Dialog.prototype.initialize.apply(this,arguments);var o=this;t.find("#showMeHow").bind("click",function(){event.preventDefault(),bg.sendLpImprove("onboardingtour::complete_intro_auto_fill_tool_tip",{action:"showmehow",version:"incontext"}),bg.IntroTutorial.setState({firstLogin:!0,isLoginTheLastPassWay:!0,inContextOnboardingStep:"try_autofill"}),bg.IntroTutorial.getState(function(t){LPSiteService.getSite(t.domain).goToLogin(),o.close()})}),t.find("#skipThis").bind("click",function(){event.preventDefault(),bg.sendLpImprove("onboardingtour::complete_intro_auto_fill_tool_tip",{action:"skipthis",version:"incontext"}),bg.IntroTutorial.completeTutorial({textChoice:"skipped"}),o.close()}),bg.sendLpImprove("onboardingtour::view_intro_auto_fill_tool_tip",{version:"incontext"})},InContextTutorialLogoutPromptDialog.prototype.getSize=function(){return{"max-height":"100%","max-width":"100%"}};
//# sourceMappingURL=sourcemaps/IntroTutorial/inContextTutorialLogoutPromptDialog.js.map
