# ملاحظات عرض مساهمتي في ScaleFlow

هذه الملاحظات للتحضير الشخصي فقط، وليست جزءًا من العرض الذي سيشاهده المدير. مدة العرض المستهدفة نحو **4 دقائق و40 ثانية**.

## Slide 1 — My Backend Contribution

**الفكرة:** أعرّف بنفسي ودوري وحدود مساهمتي. لم أبنِ المشروع كاملًا، بل نفذت أجزاء محددة في الـBackend.

**ما يجب فهمه:** المشروع مبني بـ`ASP.NET Core Web API`. مساهمتي امتدت من تنظيم الباك إند وقاعدة البيانات إلى APIs المشاريع والمهام والفرق، ثم تجهيز نقطة الربط مع ML.

**نقاط عربية مقترحة:** أنا Backend Developer. عملي ركّز على بناء طبقة API منظمة وقابلة للاختبار، مع قواعد وصول واضحة.

**مصطلحات:** `Backend Developer`, `ASP.NET Core Web API`, `API Action`.

**المدة:** 20 ثانية.

## Slide 2 — Backend Work Overview

**الفكرة:** أوضح تسلسل التاسكات الخمس بدون الدخول في التفاصيل.

**ما يجب فهمه:** كل مرحلة اعتمدت على السابقة: الهيكل أولًا، ثم CRUD، ثم منطق العلاقات، ثم التقدم والفرق، وأخيرًا ML integration boundary.

**نقاط عربية مقترحة:** لم تكن التاسكات منفصلة تمامًا؛ هي طبقات متتابعة داخل Backend واحد. الأرقام المعروضة مأخوذة من النسخة الحالية، وليس من وصف التاسك القديم.

**مصطلحات:** `EF Core Migration`, `Foreign Key`, `Check Constraint`.

**المدة:** 25 ثانية.

## Slide 3 — Backend Foundation

**الفكرة:** أشرح المعمارية العامة وحدود كل طبقة.

**ما يجب فهمه:** الـController يستقبل الطلب، والـService يحتوي منطق العمل، والـDTO يمنع كشف الـEntity مباشرة، وEF Core يتعامل مع SQL Server. الوصول للبيانات مقيّد بالمؤسسة والمشروع.

**نقاط عربية مقترحة:** فصلت Interfaces عن Services، واستخدمت DTOs للمدخلات والمخرجات. المصادقة تعتمد JWT وASP.NET Core Identity. الـMulti-Tenancy هنا مبني على `OrganizationId`.

**مصطلحات:** `Controller`, `Service`, `Interface`, `DTO`, `Entity`, `Multi-Tenancy`, `JWT`, `RBAC`, `Soft Delete`.

**المدة:** 35 ثانية.

## Slide 4 — Database and Core APIs

**الفكرة:** أوضح Project وTask CRUD وطريقة التحقق والاستجابة.

**ما يجب فهمه:** الحذف في Project وTask هو Soft Delete. تغيير حالة المهمة يضيف سجلًا في `TaskStatusHistories`. `FluentValidation` يتحقق من البيانات قبل وصولها لمنطق الخدمة، و`ApiResponse` يوحّد شكل النتيجة.

**نقاط عربية مقترحة:** ركز على أن المنطق موزع بوضوح: Validator للمدخلات، Service للقواعد، Middleware للأخطاء. لا تقرأ كل endpoint.

**مصطلحات:** `CRUD`, `FluentValidation`, `ApiResponse`, `Middleware`, `Status History`, `Pagination`.

**المدة:** 35 ثانية.

## Slide 5 — Task Dependency Management

**الفكرة:** هذه أقوى نقطة تقنية في العرض؛ اشرح حماية الرسم البياني للمهام من العلاقات الخاطئة.

**ما يجب فهمه:** عند إضافة Dependency، يتأكد النظام أن المهمة لا تعتمد على نفسها، وأن المهمة المطلوبة داخل المشروع، وأن العلاقة غير مكررة. ثم يتتبع العلاقات الموجودة لاكتشاف أي دورة مباشرة أو غير مباشرة.

**نقاط عربية مقترحة:** مثال بسيط: إذا كانت A تعتمد على B، وB تعتمد على C، فلا يمكن جعل C تعتمد على A. هذا يصنع Circular Dependency. الحفظ يستخدم `Serializable Transaction` في قواعد البيانات العلاقية حتى يبقى الفحص والحفظ ضمن عملية آمنة.

**مصطلحات:** `Task Graph`, `Circular Dependency`, `Direct Cycle`, `Indirect Cycle`, `Serializable Transaction`, `Dependency Type`.

**المدة:** 45 ثانية.

## Slide 6 — Project Progress and Team Management

**الفكرة:** أشرح حساب التقدم وإدارة Project Members وTeams.

**ما يجب فهمه:** التقدم هو متوسط نسبة إنجاز المهام غير الملغاة. المهمة `Done` تحسب 100%. القراءة مسموحة لمن لديه وصول للمشروع، بينما التعديل على الأعضاء والفرق للمالك فقط.

**نقاط عربية مقترحة:** الـDTOs ترجع بيانات مناسبة للتطبيق مثل الاسم والدور وعدد الأعضاء واسم القائد، من دون إرسال User Entity كاملة. حظر العضو أو حذفه يزيل روابطه من الفرق ويلغي قيادته عند الحاجة.

**مصطلحات:** `Progress Calculation`, `Project Owner`, `Project Member`, `Team Lead`, `Project-Scoped Access`.

**المدة:** 45 ثانية.

## Slide 7 — AI and ML Integration Boundary

**الفكرة:** أفرق بوضوح بين تجهيز التكامل وبين وجود ML Service حقيقية.

**ما يجب فهمه:** توجد أربعة endpoints وعقود DTO وواجهة `IMlService`. `ProjectAiService` يجمع بيانات المشروع ومهامه وعلاقاته بعد التحقق من الصلاحية. التطبيق الحالي يسجل `UnavailableMlService` الذي يرجع HTTP 503 لأن خدمة ML غير متصلة.

**نقاط عربية مقترحة:** لا تقل إن النظام يتنبأ فعليًا الآن. قل إن Backend contract والـadapter boundary جاهزان، والاختبارات تستخدم Fake ML adapter للتأكد من نجاح مسار الاستجابة عند توفر المزود الحقيقي.

**مصطلحات:** `Integration Boundary`, `Adapter`, `IMlService`, `Project-Scoped DTO`, `HTTP 503 Service Unavailable`, `Fake Adapter`.

**المدة:** 50 ثانية.

## Slide 8 — Backend Contribution Summary

**الفكرة:** ألخص ما يعمل الآن وما بقي للتكامل النهائي.

**ما يجب فهمه:** جميع الاختبارات الحالية نجحت: 63 من 63. المتبقي هو ML adapter الحقيقي والعقد النهائي مع ML، ثم ربط Flutter بالـendpoints.

**نقاط عربية مقترحة:** اختم بأن مساهمتي بنت أساسًا منظمًا واختبرت القواعد الحساسة. اقترح Demo قصيرًا: إنشاء Dependency، إظهار Progress، ثم استدعاء AI endpoint وشرح 503 المتوقعة.

**مصطلحات:** `Automated Test`, `Integration Step`, `Verified Endpoint`, `Expected Failure`.

**المدة:** 25 ثانية.

---

# Final Accuracy Check

## A. Verified Implemented Features

- هيكل Backend يحتوي Controllers وService Interfaces وServices وDTOs وValidators وMiddleware وEF Core.
- JWT Authentication وASP.NET Core Identity والأدوار القياسية موجودة.
- Project وTask CRUD موجودان، مع Soft Delete وتسجيل تغيّر حالة المهمة.
- Dependency APIs موجودة للعرض والإضافة والتعديل والحذف.
- فحص Self-dependency والتكرار والمشروع الصحيح والدورات المباشرة وغير المباشرة موجود.
- Progress API تحسب المتوسط الفعلي من المهام.
- APIs إدارة Project Members وTeams وTeam Members موجودة مع قواعد المالك.
- أربعة AI endpoints وDTOs و`IMlService` و`ProjectAiService` موجودة.
- الاختبارات الحالية: **63 Passed, 0 Failed**.

## B. Task Requirements Not Clearly Found in Code

- لا يوجد ربط فعلي بخدمة ML خارجية؛ الموجود حاليًا `UnavailableMlService`.
- لا يوجد ربط فعلي مع Flutter داخل هذا المستودع.
- وجود موديلات مثل AI snapshots وreports وnotifications لا يعني أن لكل منها API مكتملة.
- تصميم RBAC مهيأ جزئيًا عبر ASP.NET Core Identity والأدوار، لكن لا يوجد Permission Engine مخصص في النسخة الحالية.
- الأرقام القديمة 36 tables و62 foreign keys لم تعد تصف الـschema الحالية بعد حذف موديلات غير مستخدمة.

## C. Recommended Demo Points

1. افتح Swagger وسجّل الدخول للحصول على JWT.
2. أنشئ Task Dependency صحيحة، ثم جرّب Self-dependency أو Cycle لإظهار الرفض.
3. افتح Project Progress لإظهار إجمالي المهام والنسبة المحسوبة.
4. اعرض Team أو Project Member response لإظهار البيانات المجهزة للتطبيق.
5. استدعِ AI endpoint واشرح أن 503 استجابة مقصودة إلى أن تتوفر خدمة ML.

## D. Potential Claims I Should NOT Say

- لا تقل: **I built the entire ScaleFlow backend.**
- لا تقل: **The ML model is connected and producing real predictions.**
- لا تقل: **Flutter is already integrated with these APIs.**
- لا تقل: **Every database model has a complete API.**
- لا تستخدم أرقام 36 tables أو62 foreign keys على أنها الأرقام الحالية.
- لا تقل إن `RoleOverride` أو `RoleInTeam` يمنحان صلاحيات Identity؛ هما metadata داخل المشروع أو الفريق.

---

# Concise English Practice Script

## Slide 1

Hello, I am Mohammad, and I worked as a backend developer on ScaleFlow using ASP.NET Core Web API. My contribution covered the backend foundation, core project and task APIs, task dependencies, project progress and team management, and the integration boundary for a future ML service.

## Slide 2

The work progressed in five stages. I first organized the backend and data model. Then I built the project and task APIs. After that, I added safe dependency management, project progress, and team operations. Finally, I prepared a clean interface for the future ML service. The current EF model contains thirty-one tables, fifty-one foreign keys, and five database check constraints.

## Slide 3

I separated the API into controllers, interfaces, services, DTOs, validators, and EF Core persistence. Each request crosses a clear boundary instead of exposing database models directly. Data access uses the organization and project membership to limit visibility. Authentication uses ASP.NET Core Identity with JWT tokens and standard roles.

## Slide 4

For the core APIs, I implemented project and task CRUD with request and response DTOs. Project deletion and task deletion are soft deletes, so the records keep their audit history. Task updates also record status changes. FluentValidation checks request data, while one ApiResponse format and exception middleware keep success and error responses consistent.

## Slide 5

The dependency API can list, read, add, update, and remove task dependencies. Before saving, the service rejects a task that depends on itself, duplicate relationships, and tasks outside the same project. It builds the existing dependency graph and follows prerequisites to detect direct or indirect cycles. Relational writes use a serializable transaction to keep the check and save together.

## Slide 6

Project progress is calculated live from task data. Completed tasks count as one hundred percent, and cancelled tasks do not affect the average. For project members and teams, read access follows project visibility, but management actions require the project owner. A team member must already have project access. If a member becomes blocked or removed, the service also clears team membership and leadership links.

## Slide 7

I prepared four AI endpoints for delay prediction, risk analysis, bottleneck detection, and project health. The backend first checks project access, then creates an input DTO containing only that project's tasks and dependencies. It calls an IMlService interface, so a real adapter can be added later. Today, the default adapter returns HTTP 503 because the external ML service is not connected.

## Slide 8

In summary, I delivered a structured backend with clear DTO boundaries, core management APIs, safe dependency rules, live progress, and team operations. The test suite currently passes all sixty-three tests. The AI integration boundary is ready, but the real ML adapter and Flutter connection remain future integration work.
