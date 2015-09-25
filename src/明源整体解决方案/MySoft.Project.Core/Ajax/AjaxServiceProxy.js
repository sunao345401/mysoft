function AjaxServiceProxy(window, type, serverUrl) {
    window.__ajaxUrl = serverUrl;
    window.__ajax = ajax;
    var service = {};
    service.typeName = type;
    service.ajax = function(callMethod, data, ajaxUrl) {
        data = data || {};
        var ajaxUrl = ajaxUrl || window.__ajaxUrl;
        var async = data.callback ? true : false;
        var returnValue;
        var ajaxdone = function(json) {
            if (json.__error__) {
                var parentWin = window.parent;
                while (parentWin && parentWin != window) {
                    parentWin.__error__ = json.__error__;
                    parentWin = parentWin.parent;
                }
                parentWin.__error__ = json.__error__;
                if (window.debug || window.location.host.indexOf('localhost') > -1)
                    alert(json.__error__);
                else
                    alert('操作出错，请联系系统管理员！');
                return;

            }
            if (data.callback) {
                returnValue = data.callback(json.result);
            }
            returnValue = json.result;
        }
        $.ajax({ url: ajaxUrl + '?callMethod=' + callMethod, contentType: 'application/x-www-form-urlencoded; charset=UTF-8', data: data, async: async, type: 'POST', cache: false, dataType: 'json' }).done(ajaxdone);
        return returnValue;

    };
    service.parseParam = function(data, paramName, paramVal) {
        if (!window.$ && window.location.host.indexOf('localhost') > 0) { alert('人生苦短，我用jquery '); };
        if ($.isArray(paramVal)) {
            data[paramName] = JSON.stringify(paramVal);
        }
        else if ($.isFunction(paramVal)) { }
        else if (typeof paramVal === 'object') {
            $.extend(data, paramVal);
        }
        else if (typeof data[paramName] === 'undefined') {
            data[paramName] = paramVal;
        }

    }
    service.registerMethod = function(methodName, methodParams) {
        var arrParams = methodParams.split(",");
        service[methodName] = function() {
            var data = {};
            for (var i = 0; i < arrParams.length; i++) {
                service.parseParam(data, arrParams[i], arguments[i]);
            }
            if (arguments.length > 0 && $.isFunction(arguments[arguments.length - 1])) {
                data.callback = arguments[arguments.length - 1];
            }
            var callMethod = this.typeName + '.' + methodName;
            var sRtn = this.ajax(callMethod, data);
            return sRtn;

        }
    }

    if (module && typeof module === 'object' && typeof module.exports === 'object') { module.exports = service; }
    if (typeof define === 'function') { define(function() { return service; }); }
    var serviceNames = type.split('.');
    window[serviceNames[serviceNames.length - 1]] = service;
    return service;
}


//兼容小平台传参调用
 window.my = window.my || {};
 my.ajax = my.ajax || {};
 my.ajax.callMethod = function(option) {
     option = option || {}
     data = option.data || option;
     var serviceInfo = option.serviceInfo;
     var ajaxUrl = option.ajaxUrl || window.__ajaxUrl;
     return window.__ajax(serviceInfo, data, ajaxUrl);

 }