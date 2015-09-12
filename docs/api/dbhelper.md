## API

+ [Entity](/docs/api/entity.md)

+ [DBHelper](/docs/api/dbhelper.md)

+ [Ajax](/docs/api/ajax.md)


## dbhelper
+ 定义后台服务类和方法，（不限语言，没有小平台项目名称约束）

```C#
namespace Mysoft.Cbgl.Services
{
    public class MonthPlanService
    {
        public string GetWorkflowProcessGUID(string planMonth, string buguid)
        {
            string sql = @"select ProcessGUID from myWorkflowProcessEntity where  IsHistory=0 and BusinessGUID in
                        ( select top 1 MpProcessGUID from  cb_MonthPlan  where planmonth=@0 and buguid=@1)";
            string mpProcessGUID = DBHelper.ExecuteScalarString(sql, planMonth, buguid);
            return mpProcessGUID;
        }
    }
    //more...
}
```

+ 在头部添加jquery和需要调用的后台服务类型
`<head>`:

```html
<script type="text/javascript" src="/Project/js/jquery.js" ></script>
<script type="text/javascript" src="/Project/ajax.aspx?type=Mysoft.Cbgl.Services.MonthPlanService"></script>
```

+ 在前台脚步调用服务 **注意区分大小写**

```javascript
function doSendProcess() {
		var mpProcessGUID = MonthPlanService.GetMpProcessGUID($('#__planMonth').val(), $('#txtBUGUID').val());
		initiateBusinessProcess(mpProcessGUID, '资金计划审批');
	}
```