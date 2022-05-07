Open Issue : "body": "<!-- markdownlint-disable MD036 -->

**Which addon?**

Firefly

<!-- The title of the addon this issue is for. -->

- Addon name : Firefly iii
- Addon version : 5.7.5 

**Describe the bug**

The newly updated version doesn't work out of the box. It seems to be this error
https://github.com/firefly-iii/firefly-iii/issues/6058

<!-- A clear and concise description of what the bug is. -->

**To Reproduce**

Update to latest version I guess

**Full addon log**

```
Password grant client created successfully.
Client ID: 14
Client secret: hyJA8vzPP86rOJiyQMdJa9uuVsE1wnkithpAni8t
Updated version.
+------------------------------------------------------------------------------+
|                                                                              |
| Thank you for installing Firefly III, v5.7.5!                                |
|                                                                              |
|                                                                              |
+------------------------------------------------------------------------------+
Go!
[Fri May 06 21:01:00.031536 2022] [mpm_prefork:notice] [pid 224] AH00163: Apache/2.4.38 (Debian) configured -- resuming normal operations
[Fri May 06 21:01:00.031846 2022] [core:notice] [pid 224] AH00094: Command line: 'apache2 -D FOREGROUND'
[2022-05-06T21:01:12.804152+00:00] local.INFO: AUDIT: User visits homepage. (192.168.100.68 (tilman@baumann.name) -> GET:http://homeassistant.local:3473) [] []
[2022-05-06 21:01:12] local.INFO: Update check is not enabled.  
[2022-05-06 21:01:13] local.ERROR: Exception is: {"class":"TypeError","errorMessage":"bcadd(): Argument #2 ($num2) must be of type string, float given","time":"Fri, 06 May 2022 21:01:13 +0000","file":"\/var\/www\/html\/app\/Support\/Steam.php","line":102,"code":0,"version":"5.7.5","url":"http:\/\/homeassistant.local:3473","userAgent":"Mozilla\/5.0 (X11; Linux x86_64; rv:100.0) Gecko\/20100101 Firefox\/100.0","json":true,"method":"GET"}  
[2022-05-06 21:01:13] local.ERROR: bcadd(): Argument #2 ($num2) must be of type string, float given {"userId":1,"exception":"[object] (TypeError(code: 0): bcadd(): Argument #2 ($num2) must be of type string, float given at /var/www/html/app/Support/Steam.php:102)
[stacktrace]
#0 /var/www/html/app/Support/Steam.php(102): bcadd()
#1 /var/www/html/app/Support/Steam.php(231): FireflyIII\\Support\\Steam->sumTransactions()
#2 /var/www/html/app/Support/Twig/General.php(72): FireflyIII\\Support\\Steam->balance()
#3 /var/www/html/storage/framework/views/twig/f7/f7862c4c87f78f94af80270f9d96fbfe.php(262): FireflyIII\\Support\\Twig\\General::FireflyIII\\Support\\Twig\\{closure}()
#4 /var/www/html/vendor/twig/twig/src/Template.php(171): __TwigTemplate_d9b61c450b6373d17f53a3c82c3c44ee->block_content()
#5 /var/www/html/storage/framework/views/twig/51/5196fbc4950297fb2d8ae79d5c75baf3.php(306): Twig\\Template->displayBlock()
#6 /var/www/html/vendor/twig/twig/src/Template.php(394): __TwigTemplate_af06cec3c1baf37b229ab03531436705->doDisplay()
#7 /var/www/html/vendor/twig/twig/src/Template.php(367): Twig\\Template->displayWithErrorHandling()
#8 /var/www/html/storage/framework/views/twig/f7/f7862c4c87f78f94af80270f9d96fbfe.php(46): Twig\\Template->display()
#9 /var/www/html/vendor/twig/twig/src/Template.php(394): __TwigTemplate_d9b61c450b6373d17f53a3c82c3c44ee->doDisplay()
#10 /var/www/html/vendor/twig/twig/src/Template.php(367): Twig\\Template->displayWithErrorHandling()
#11 /var/www/html/vendor/twig/twig/src/Template.php(379): Twig\\Template->display()
#12 /var/www/html/vendor/twig/twig/src/TemplateWrapper.php(40): Twig\\Template->render()
#13 /var/www/html/vendor/rcrowe/twigbridge/src/Engine/Twig.php(92): Twig\\TemplateWrapper->render()
#14 /var/www/html/vendor/laravel/framework/src/Illuminate/View/View.php(139): TwigBridge\\Engine\\Twig->get()
#15 /var/www/html/vendor/laravel/framework/src/Illuminate/View/View.php(122): Illuminate\\View\\View->getContents()
#16 /var/www/html/vendor/laravel/framework/src/Illuminate/View/View.php(91): Illuminate\\View\\View->renderContents()
#17 /var/www/html/vendor/laravel/framework/src/Illuminate/Http/Response.php(69): Illuminate\\View\\View->render()
#18 /var/www/html/vendor/laravel/framework/src/Illuminate/Http/Response.php(35): Illuminate\\Http\\Response->setContent()
#19 /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(833): Illuminate\\Http\\Response->__construct()
#20 /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(802): Illuminate\\Routing\\Router::toResponse()
#21 /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(725): Illuminate\\Routing\\Router->prepareResponse()
#22 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(141): Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()
#23 /var/www/html/app/Http/Middleware/Installer.php(79): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#24 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): FireflyIII\\Http\\Middleware\\Installer->handle()
#25 /var/www/html/app/Http/Controllers/Controller.php(112): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#26 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(162): FireflyIII\\Http\\Controllers\\Controller->FireflyIII\\Http\\Controllers\\{closure}()
#27 /var/www/html/app/Http/Middleware/InterestingMessage.php(67): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#28 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): FireflyIII\\Http\\Middleware\\InterestingMessage->handle()
#29 /var/www/html/app/Http/Middleware/Binder.php(78): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#30 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): FireflyIII\\Http\\Middleware\\Binder->handle()
#31 /var/www/html/app/Http/Middleware/Range.php(62): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#32 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): FireflyIII\\Http\\Middleware\\Range->handle()
#33 /var/www/html/vendor/jc5/google2fa-laravel/src/Middleware.php(29): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#34 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): PragmaRX\\Google2FALaravel\\Middleware->handle()
#35 /var/www/html/app/Http/Middleware/Authenticate.php(75): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#36 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): FireflyIII\\Http\\Middleware\\Authenticate->handle()

#37 /var/www/html/vendor/laravel/passport/src/Http/Middleware/CreateFreshApiToken.php(50): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#38 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Laravel\\Passport\\Http\\Middleware\\CreateFreshApiToken->handle()
#39 /var/www/html/vendor/laravel/framework/src/Illuminate/Session/Middleware/AuthenticateSession.php(59): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#40 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\Session\\Middleware\\AuthenticateSession->handle()
#41 /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/VerifyCsrfToken.php(78): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#42 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\Foundation\\Http\\Middleware\\VerifyCsrfToken->handle()
#43 /var/www/html/vendor/laravel/framework/src/Illuminate/View/Middleware/ShareErrorsFromSession.php(49): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#44 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\View\\Middleware\\ShareErrorsFromSession->handle()
#45 /var/www/html/vendor/laravel/framework/src/Illuminate/Session/Middleware/StartSession.php(121): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#46 /var/www/html/vendor/laravel/framework/src/Illuminate/Session/Middleware/StartSession.php(64): Illuminate\\Session\\Middleware\\StartSession->handleStatefulRequest()
#47 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\Session\\Middleware\\StartSession->handle()
#48 /var/www/html/vendor/laravel/framework/src/Illuminate/Cookie/Middleware/AddQueuedCookiesToResponse.php(37): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#49 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\Cookie\\Middleware\\AddQueuedCookiesToResponse->handle()
#50 /var/www/html/vendor/laravel/framework/src/Illuminate/Cookie/Middleware/EncryptCookies.php(67): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#51 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\Cookie\\Middleware\\EncryptCookies->handle()
#52 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(116): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#53 /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(726): Illuminate\\Pipeline\\Pipeline->then()
#54 /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(703): Illuminate\\Routing\\Router->runRouteWithinStack()
#55 /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(667): Illuminate\\Routing\\Router->runRoute()
#56 /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(656): Illuminate\\Routing\\Router->dispatchToRoute()
#57 /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php(167): Illuminate\\Routing\\Router->dispatch()
#58 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(141): Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()
#59 /var/www/html/app/Http/Middleware/InstallationId.php(52): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#60 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): FireflyIII\\Http\\Middleware\\InstallationId->handle()
#61 /var/www/html/vendor/laravel/framework/src/Illuminate/Http/Middleware/TrustProxies.php(39): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#62 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\Http\\Middleware\\TrustProxies->handle()
#63 /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/TransformsRequest.php(21): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#64 /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/ConvertEmptyStringsToNull.php(31): Illuminate\\Foundation\\Http\\Middleware\\TransformsRequest->handle()
#65 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\Foundation\\Http\\Middleware\\ConvertEmptyStringsToNull->handle()
#66 /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/TransformsRequest.php(21): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#67 /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/TrimStrings.php(40): Illuminate\\Foundation\\Http\\Middleware\\TransformsRequest->handle()
#68 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\Foundation\\Http\\Middleware\\TrimStrings->handle()
#69 /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/ValidatePostSize.php(27): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#70 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\Foundation\\Http\\Middleware\\ValidatePostSize->handle()
#71 /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php(86): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#72 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()
#73 /var/www/html/app/Http/Middleware/SecureHeaders.php(51): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#74 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180): FireflyIII\\Http\\Middleware\\SecureHeaders->handle()
#75 /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(116): Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
#76 /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php(142): Illuminate\\Pipeline\\Pipeline->then()
#77 /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php(111): Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()
#78 /var/www/html/public/index.php(76): Illuminate\\Foundation\\Http\\Kernel->handle()
#79 {main}
"} 
192.168.100.68 - - [06/May/2022:21:01:11 +0000] "GET / HTTP/1.1" 500 6729 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:100.0) Gecko/20100101 Firefox/100.0"
```
<!-- The full log that appears when starting the addon -->

**Full addon config**
defaults, sqlite
<!-- The addon config in yaml, please remove your passwords-->

**System**

<!-- Those information can be found under the Supervisor page on the System tab. -->

- Supervisor version: 2022.5.1
- Host system version: 7.6",
Open Issue : "title": "[Fireflyiii] No ui in 5.7.5",
# Home assistant add-on: fireflyiii
Open Issue : 7.6",
Open Issue : version:
Open Issue : system
Open Issue : Host
Open Issue : -
Open Issue : 2022.5.1
Open Issue : version:
Open Issue : Supervisor
Open Issue : -
Open Issue : 
Open Issue : -->
Open Issue : tab.
Open Issue : System
Open Issue : the
Open Issue : on
Open Issue : page
Open Issue : Supervisor
Open Issue : the
Open Issue : under
Open Issue : found
Open Issue : be
Open Issue : can
Open Issue : information
Open Issue : Those
Open Issue : <!--
Open Issue : 
Open Issue : **System**
Open Issue : 
Open Issue : passwords-->
Open Issue : your
Open Issue : remove
Open Issue : please
Open Issue : yaml,
Open Issue : in
Open Issue : config
Open Issue : addon
Open Issue : The
Open Issue : <!--
Open Issue : sqlite
Open Issue : defaults,
Open Issue : config**
Open Issue : addon
Open Issue : **Full
Open Issue : 
Open Issue : -->
Open Issue : addon
Open Issue : the
Open Issue : starting
Open Issue : when
Open Issue : appears
Open Issue : that
Open Issue : log
Open Issue : full
Open Issue : The
Open Issue : <!--
Open Issue : ```
Open Issue : Firefox/100.0"
Open Issue : Gecko/20100101
Open Issue : rv:100.0)
Open Issue : x86_64;
Open Issue : Linux
Open Issue : (X11;
Open Issue : "Mozilla/5.0
Open Issue : "-"
Open Issue : 6729
Open Issue : 500
Open Issue : HTTP/1.1"
Open Issue : /
Open Issue : "GET
Open Issue : +0000]
Open Issue : [06/May/2022:21:01:11
Open Issue : -
Open Issue : -
Open Issue : 192.168.100.68
Open Issue : 
Open Issue : "}
Open Issue : {main}
Open Issue : #79
Open Issue : Illuminate\\Foundation\\Http\\Kernel->handle()
Open Issue : /var/www/html/public/index.php(76):
Open Issue : #78
Open Issue : Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php(111):
Open Issue : #77
Open Issue : Illuminate\\Pipeline\\Pipeline->then()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php(142):
Open Issue : #76
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(116):
Open Issue : #75
Open Issue : FireflyIII\\Http\\Middleware\\SecureHeaders->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #74
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/app/Http/Middleware/SecureHeaders.php(51):
Open Issue : #73
Open Issue : Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #72
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php(86):
Open Issue : #71
Open Issue : Illuminate\\Foundation\\Http\\Middleware\\ValidatePostSize->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #70
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/ValidatePostSize.php(27):
Open Issue : #69
Open Issue : Illuminate\\Foundation\\Http\\Middleware\\TrimStrings->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #68
Open Issue : Illuminate\\Foundation\\Http\\Middleware\\TransformsRequest->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/TrimStrings.php(40):
Open Issue : #67
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/TransformsRequest.php(21):
Open Issue : #66
Open Issue : Illuminate\\Foundation\\Http\\Middleware\\ConvertEmptyStringsToNull->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #65
Open Issue : Illuminate\\Foundation\\Http\\Middleware\\TransformsRequest->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/ConvertEmptyStringsToNull.php(31):
Open Issue : #64
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/TransformsRequest.php(21):
Open Issue : #63
Open Issue : Illuminate\\Http\\Middleware\\TrustProxies->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #62
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Http/Middleware/TrustProxies.php(39):
Open Issue : #61
Open Issue : FireflyIII\\Http\\Middleware\\InstallationId->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #60
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/app/Http/Middleware/InstallationId.php(52):
Open Issue : #59
Open Issue : Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(141):
Open Issue : #58
Open Issue : Illuminate\\Routing\\Router->dispatch()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php(167):
Open Issue : #57
Open Issue : Illuminate\\Routing\\Router->dispatchToRoute()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(656):
Open Issue : #56
Open Issue : Illuminate\\Routing\\Router->runRoute()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(667):
Open Issue : #55
Open Issue : Illuminate\\Routing\\Router->runRouteWithinStack()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(703):
Open Issue : #54
Open Issue : Illuminate\\Pipeline\\Pipeline->then()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(726):
Open Issue : #53
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(116):
Open Issue : #52
Open Issue : Illuminate\\Cookie\\Middleware\\EncryptCookies->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #51
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Cookie/Middleware/EncryptCookies.php(67):
Open Issue : #50
Open Issue : Illuminate\\Cookie\\Middleware\\AddQueuedCookiesToResponse->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #49
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Cookie/Middleware/AddQueuedCookiesToResponse.php(37):
Open Issue : #48
Open Issue : Illuminate\\Session\\Middleware\\StartSession->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #47
Open Issue : Illuminate\\Session\\Middleware\\StartSession->handleStatefulRequest()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Session/Middleware/StartSession.php(64):
Open Issue : #46
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Session/Middleware/StartSession.php(121):
Open Issue : #45
Open Issue : Illuminate\\View\\Middleware\\ShareErrorsFromSession->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #44
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/View/Middleware/ShareErrorsFromSession.php(49):
Open Issue : #43
Open Issue : Illuminate\\Foundation\\Http\\Middleware\\VerifyCsrfToken->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #42
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/VerifyCsrfToken.php(78):
Open Issue : #41
Open Issue : Illuminate\\Session\\Middleware\\AuthenticateSession->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #40
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Session/Middleware/AuthenticateSession.php(59):
Open Issue : #39
Open Issue : Laravel\\Passport\\Http\\Middleware\\CreateFreshApiToken->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #38
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/laravel/passport/src/Http/Middleware/CreateFreshApiToken.php(50):
Open Issue : #37
Open Issue : 
Open Issue : FireflyIII\\Http\\Middleware\\Authenticate->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #36
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/app/Http/Middleware/Authenticate.php(75):
Open Issue : #35
Open Issue : PragmaRX\\Google2FALaravel\\Middleware->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #34
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/vendor/jc5/google2fa-laravel/src/Middleware.php(29):
Open Issue : #33
Open Issue : FireflyIII\\Http\\Middleware\\Range->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #32
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/app/Http/Middleware/Range.php(62):
Open Issue : #31
Open Issue : FireflyIII\\Http\\Middleware\\Binder->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #30
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/app/Http/Middleware/Binder.php(78):
Open Issue : #29
Open Issue : FireflyIII\\Http\\Middleware\\InterestingMessage->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #28
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/app/Http/Middleware/InterestingMessage.php(67):
Open Issue : #27
Open Issue : FireflyIII\\Http\\Controllers\\Controller->FireflyIII\\Http\\Controllers\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(162):
Open Issue : #26
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/app/Http/Controllers/Controller.php(112):
Open Issue : #25
Open Issue : FireflyIII\\Http\\Middleware\\Installer->handle()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(180):
Open Issue : #24
Open Issue : Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()
Open Issue : /var/www/html/app/Http/Middleware/Installer.php(79):
Open Issue : #23
Open Issue : Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php(141):
Open Issue : #22
Open Issue : Illuminate\\Routing\\Router->prepareResponse()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(725):
Open Issue : #21
Open Issue : Illuminate\\Routing\\Router::toResponse()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(802):
Open Issue : #20
Open Issue : Illuminate\\Http\\Response->__construct()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Routing/Router.php(833):
Open Issue : #19
Open Issue : Illuminate\\Http\\Response->setContent()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Http/Response.php(35):
Open Issue : #18
Open Issue : Illuminate\\View\\View->render()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/Http/Response.php(69):
Open Issue : #17
Open Issue : Illuminate\\View\\View->renderContents()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/View/View.php(91):
Open Issue : #16
Open Issue : Illuminate\\View\\View->getContents()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/View/View.php(122):
Open Issue : #15
Open Issue : TwigBridge\\Engine\\Twig->get()
Open Issue : /var/www/html/vendor/laravel/framework/src/Illuminate/View/View.php(139):
Open Issue : #14
Open Issue : Twig\\TemplateWrapper->render()
Open Issue : /var/www/html/vendor/rcrowe/twigbridge/src/Engine/Twig.php(92):
Open Issue : #13
Open Issue : Twig\\Template->render()
Open Issue : /var/www/html/vendor/twig/twig/src/TemplateWrapper.php(40):
Open Issue : #12
Open Issue : Twig\\Template->display()
Open Issue : /var/www/html/vendor/twig/twig/src/Template.php(379):
Open Issue : #11
Open Issue : Twig\\Template->displayWithErrorHandling()
Open Issue : /var/www/html/vendor/twig/twig/src/Template.php(367):
Open Issue : #10
Open Issue : __TwigTemplate_d9b61c450b6373d17f53a3c82c3c44ee->doDisplay()
Open Issue : /var/www/html/vendor/twig/twig/src/Template.php(394):
Open Issue : #9
Open Issue : Twig\\Template->display()
Open Issue : /var/www/html/storage/framework/views/twig/f7/f7862c4c87f78f94af80270f9d96fbfe.php(46):
Open Issue : #8
Open Issue : Twig\\Template->displayWithErrorHandling()
Open Issue : /var/www/html/vendor/twig/twig/src/Template.php(367):
Open Issue : #7
Open Issue : __TwigTemplate_af06cec3c1baf37b229ab03531436705->doDisplay()
Open Issue : /var/www/html/vendor/twig/twig/src/Template.php(394):
Open Issue : #6
Open Issue : Twig\\Template->displayBlock()
Open Issue : /var/www/html/storage/framework/views/twig/51/5196fbc4950297fb2d8ae79d5c75baf3.php(306):
Open Issue : #5
Open Issue : __TwigTemplate_d9b61c450b6373d17f53a3c82c3c44ee->block_content()
Open Issue : /var/www/html/vendor/twig/twig/src/Template.php(171):
Open Issue : #4
Open Issue : FireflyIII\\Support\\Twig\\General::FireflyIII\\Support\\Twig\\{closure}()
Open Issue : /var/www/html/storage/framework/views/twig/f7/f7862c4c87f78f94af80270f9d96fbfe.php(262):
Open Issue : #3
Open Issue : FireflyIII\\Support\\Steam->balance()
Open Issue : /var/www/html/app/Support/Twig/General.php(72):
Open Issue : #2
Open Issue : FireflyIII\\Support\\Steam->sumTransactions()
Open Issue : /var/www/html/app/Support/Steam.php(231):
Open Issue : #1
Open Issue : bcadd()
Open Issue : /var/www/html/app/Support/Steam.php(102):
Open Issue : #0
Open Issue : [stacktrace]
Open Issue : /var/www/html/app/Support/Steam.php:102)
Open Issue : at
Open Issue : given
Open Issue : float
Open Issue : string,
Open Issue : type
Open Issue : of
Open Issue : be
Open Issue : must
Open Issue : ($num2)
Open Issue : #2
Open Issue : Argument
Open Issue : bcadd():
Open Issue : 0):
Open Issue : (TypeError(code:
Open Issue : {"userId":1,"exception":"[object]
Open Issue : given
Open Issue : float
Open Issue : string,
Open Issue : type
Open Issue : of
Open Issue : be
Open Issue : must
Open Issue : ($num2)
Open Issue : #2
Open Issue : Argument
Open Issue : bcadd():
Open Issue : local.ERROR:
Open Issue : 21:01:13]
Open Issue : [2022-05-06
Open Issue : 
Open Issue : Firefox\/100.0","json":true,"method":"GET"}
Open Issue : Gecko\/20100101
Open Issue : rv:100.0)
Open Issue : x86_64;
Open Issue : Linux
Open Issue : (X11;
Open Issue : +0000","file":"\/var\/www\/html\/app\/Support\/Steam.php","line":102,"code":0,"version":"5.7.5","url":"http:\/\/homeassistant.local:3473","userAgent":"Mozilla\/5.0
Open Issue : 21:01:13
Open Issue : 2022
Open Issue : May
Open Issue : 06
Open Issue : given","time":"Fri,
Open Issue : float
Open Issue : string,
Open Issue : type
Open Issue : of
Open Issue : be
Open Issue : must
Open Issue : ($num2)
Open Issue : #2
Open Issue : Argument
Open Issue : {"class":"TypeError","errorMessage":"bcadd():
Open Issue : is:
Open Issue : Exception
Open Issue : local.ERROR:
Open Issue : 21:01:13]
Open Issue : [2022-05-06
Open Issue : 
Open Issue : enabled.
Open Issue : not
Open Issue : is
Open Issue : check
Open Issue : Update
Open Issue : local.INFO:
Open Issue : 21:01:12]
Open Issue : [2022-05-06
Open Issue : []
Open Issue : []
Open Issue : GET:http://homeassistant.local:3473)
Open Issue : ->
Open Issue : (tilman@baumann.name)
Open Issue : (192.168.100.68
Open Issue : homepage.
Open Issue : visits
Open Issue : User
Open Issue : AUDIT:
Open Issue : local.INFO:
Open Issue : [2022-05-06T21:01:12.804152+00:00]
Open Issue : FOREGROUND'
Open Issue : -D
Open Issue : 'apache2
Open Issue : line:
Open Issue : Command
Open Issue : AH00094:
Open Issue : 224]
Open Issue : [pid
Open Issue : [core:notice]
Open Issue : 2022]
Open Issue : 21:01:00.031846
Open Issue : 06
Open Issue : May
Open Issue : [Fri
Open Issue : operations
Open Issue : normal
Open Issue : resuming
Open Issue : --
Open Issue : configured
Open Issue : (Debian)
Open Issue : Apache/2.4.38
Open Issue : AH00163:
Open Issue : 224]
Open Issue : [pid
Open Issue : [mpm_prefork:notice]
Open Issue : 2022]
Open Issue : 21:01:00.031536
Open Issue : 06
Open Issue : May
Open Issue : [Fri
Open Issue : Go!
Open Issue : +------------------------------------------------------------------------------+
Open Issue : |
Open Issue : |
Open Issue : |
Open Issue : |
Open Issue : |
Open Issue : v5.7.5!
Open Issue : III,
Open Issue : Firefly
Open Issue : installing
Open Issue : for
Open Issue : you
Open Issue : Thank
Open Issue : |
Open Issue : |
Open Issue : |
Open Issue : +------------------------------------------------------------------------------+
Open Issue : version.
Open Issue : Updated
Open Issue : hyJA8vzPP86rOJiyQMdJa9uuVsE1wnkithpAni8t
Open Issue : secret:
Open Issue : Client
Open Issue : 14
Open Issue : ID:
Open Issue : Client
Open Issue : successfully.
Open Issue : created
Open Issue : client
Open Issue : grant
Open Issue : Password
Open Issue : ```
Open Issue : 
Open Issue : log**
Open Issue : addon
Open Issue : **Full
Open Issue : 
Open Issue : guess
Open Issue : I
Open Issue : version
Open Issue : latest
Open Issue : to
Open Issue : Update
Open Issue : 
Open Issue : Reproduce**
Open Issue : **To
Open Issue : 
Open Issue : -->
Open Issue : is.
Open Issue : bug
Open Issue : the
Open Issue : what
Open Issue : of
Open Issue : description
Open Issue : concise
Open Issue : and
Open Issue : clear
Open Issue : A
Open Issue : <!--
Open Issue : 
Open Issue : https://github.com/firefly-iii/firefly-iii/issues/6058
Open Issue : error
Open Issue : this
Open Issue : be
Open Issue : to
Open Issue : seems
Open Issue : It
Open Issue : box.
Open Issue : the
Open Issue : of
Open Issue : out
Open Issue : work
Open Issue : doesn't
Open Issue : version
Open Issue : updated
Open Issue : newly
Open Issue : The
Open Issue : 
Open Issue : bug**
Open Issue : the
Open Issue : **Describe
Open Issue : 
Open Issue : 
Open Issue : 5.7.5
Open Issue : :
Open Issue : version
Open Issue : Addon
Open Issue : -
Open Issue : iii
Open Issue : Firefly
Open Issue : :
Open Issue : name
Open Issue : Addon
Open Issue : -
Open Issue : 
Open Issue : -->
Open Issue : for.
Open Issue : is
Open Issue : issue
Open Issue : this
Open Issue : addon
Open Issue : the
Open Issue : of
Open Issue : title
Open Issue : The
Open Issue : <!--
Open Issue : 
Open Issue : Firefly
Open Issue : 
Open Issue : addons_updater
Open Issue : **Which
Open Issue : 
Open Issue : -->
Open Issue : MD036
Open Issue : markdownlint-disable
Open Issue : "<!--
Open Issue : "body":
Open Issue : 5.7.5",
Open Issue : in
Open Issue : ui
Open Issue : No
Open Issue : "[Fireflyiii]
Open Issue : "title":

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffireflyiii%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffireflyiii%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffireflyiii%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

["Firefly III"](https://www.firefly-iii.org) is a (self-hosted) manager for your personal finances. It can help you keep track of your expenses and income, so you can spend less and save more.
This addon is based on the docker image https://hub.docker.com/r/fireflyiii/core

## Configuration

PLEASE CHANGE YOUR APP_KEY BEFORE FIRST LAUNCH! YOU WON'T BE ABLE AFTERWRADS WITHOUT RESETTING YOUR DATABASE.

Options can be configured through two ways :

- Addon options

```yaml
"CONFIG_LOCATION": location of the config.yaml # Sets the location of the config.yaml (see below)
"DB_CONNECTION": "list(sqlite_internal|mariadb_addon|mysql|pgsql)" # Defines the type of database to use : sqlite (default, embedded in the addon) ; MariaDB (auto-detection if the MariaDB addon is installed and runs), and external databases that requires that the other DB_ fields are set (mysql and pgsql)
"APP_KEY": 12 characters # This is your encryption key, don't lose it!
"DB_HOST": "CHANGEME" # only needed if using a remote database
"DB_PORT": "CHANGEME" # only needed if using a remote database
"DB_DATABASE": "CHANGEME" # only needed if using a remote database
"DB_USERNAME": "CHANGEME" # only needed if using a remote database
"DB_PASSWORD": "CHANGEME" # only needed if using a remote database
"Updates": hourly|daily|weekly # Sets an automatic update
"silent": true # If false, show debug info
```

- Config.yaml

Additional variables can be set as ENV variables by adding them in the config.yaml in the location defined in your addon options

The complete list of ENV variables can be seen here : https://raw.githubusercontent.com/firefly-iii/firefly-iii/main/.env.example

## Installation

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and adapt the software options

## Support

Create an issue on github

## Illustration

![illustration](https://raw.githubusercontent.com/firefly-iii/firefly-iii/develop/.github/assets/img/imac-complete.png)

[repository]: https://github.com/alexbelgium/hassio-addons
