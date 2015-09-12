## Quick start
在头部添加jquery和需要调用的后台服务类型
`<head>`:

```html
<script type="text/javascript" src="/Project/js/jquery.js" ></script>
<script type="text/javascript" src="/Project/ajax.aspx?type=Mysoft.Cbgl.Services.MonthPlanService"></script>
```
在前台脚步调用服务

```javascript
function doSendProcess() {
		var mpProcessGUID = MonthPlanService.GetMpProcessGUID($('#__planMonth').val(), $('#txtBUGUID').val());
		initiateBusinessProcess(mpProcessGUID, '资金计划审批');
			 }
```

后台服务类有对应的方法

```c#
namespace Mysoft.Cbgl.Services
{
		public class MonthPlanService
		{
				public  string GetWorkflowProcessGUID(string planMonth, string buguid)
        {
            string sql=@"select ProcessGUID from myWorkflowProcessEntity where  IsHistory=0 and BusinessGUID in
                        ( select top 1 MpProcessGUID from  cb_MonthPlan  where planmonth=@0 and buguid=@1)";
            var mpProcessGUID = DBHelper.ExecuteScalarString(sql, planMonth, buguid);
            return mpProcessGUID;
        }
			}
}
```
