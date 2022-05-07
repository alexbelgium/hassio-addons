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

## 5.7.5 (05-05-2022)
- Update to latest version from firefly-iii/firefly-iii

## 5.7.4 (03-05-2022)
- Update to latest version from firefly-iii/firefly-iii

## 5.7.2 (12-04-2022)
- Update to latest version from firefly-iii/firefly-iii

## 5.7.1 (05-04-2022)
- Update to latest version from firefly-iii/firefly-iii
- Add codenotary sign

## 5.6.16 (01-03-2022)

- Update to latest version from firefly-iii/firefly-iii
- Allow base64 keys
- Show cron jobs messages in log

## 5.6.14 (07-02-2022)

- Update to latest version from firefly-iii/firefly-iii

## 5.6.13 (31-01-2022)

- Update to latest version from firefly-iii/firefly-iii
- Silent mode added : hides output of the app if no errors
- Correct permissions
- Allowed automatic update in hourly, daily or weekly setting from addon options

## 5.6.10 (09-01-2022)

- Update to latest version from firefly-iii/firefly-iii

## 5.6.9 (04-01-2022)

- Update to latest version from firefly-iii/firefly-iii

## 5.6.8 (29-12-2021)

- Update to latest version from firefly-iii/firefly-iii
- Initial release
