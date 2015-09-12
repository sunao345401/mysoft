## API

+ [Entity](/docs/api/entity.md)

+ [DBHelper](/docs/api/dbhelper.md)

+ [Ajax](/docs/api/ajax.md)


## ajax
ajax使用的ajax.aspx作为服务中转地址

+ 后端服务方法可以直接传递实体对象，datatable，基础类型，数组等到前端，无须类型转换。

+ 前端js调用可以按位置参数传递，也可传递对象，最后一个参数传入函数将使用异步调用

```javascript
function doSendProcess() {
  var planMonth=$('#__planMonth').val();
  var BUGUID=$('#txtBUGUID').val();  
		var mpProcessGUID = MonthPlanService.GetMpProcessGUID(planMonth,BUGUID);
		initiateBusinessProcess(mpProcessGUID, '资金计划审批');
	}

```

```javascript
function doSendProcess() {
  var planMonth=$('#__planMonth').val();
  var BUGUID=$('#txtBUGUID').val();
		var mpProcessGUID = MonthPlanService.GetMpProcessGUID({planMonth:planMonth,BUGUID: BUGUID});
		initiateBusinessProcess(mpProcessGUID, '资金计划审批');
	}

```

```javascript
function doSendProcess() {
  var planMonth=$('#__planMonth').val();
  var BUGUID=$('#txtBUGUID').val();
	 MonthPlanService.GetMpProcessGUID({planMonth:planMonth,BUGUID: BUGUID},function(mpProcessGUID){
     	initiateBusinessProcess(mpProcessGUID, '资金计划审批');
   });

	}

```
