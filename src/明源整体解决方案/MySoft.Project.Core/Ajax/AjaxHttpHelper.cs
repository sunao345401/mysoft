using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Web;
using System.Collections;
using Mysoft.Project.Core;
using System.IO;
using Mysoft.Project.Core.DataAnnotations;

namespace Mysoft.Project.Expand
{

    public static class AjaxHttpHanler
    {
        static BindingFlags _bindingFlags = BindingFlags.Public | BindingFlags.GetProperty | BindingFlags.Instance | BindingFlags.Static;
        static Dictionary<Type, string> _cacheScript = new Dictionary<Type, string>();
        static Dictionary<string, Assembly> _assmblyCache = new Dictionary<string, Assembly>();
        static Assembly FindAssembly(string typeName)
        {
            if (_assmblyCache.ContainsKey(typeName))
                return _assmblyCache[typeName];

            string assmblyName = typeName;
            while (assmblyName.LastIndexOf('.') > 0)
            {

                assmblyName = assmblyName.Substring(0, assmblyName.LastIndexOf('.'));
                var assembly = Assembly.Load(assmblyName);
                if (assembly != null)
                {
                    _assmblyCache[typeName] = assembly;
                    return assembly;
                }
            }
            return null;

        }
        public static void Run()
        {
            HttpContext context = HttpContext.Current;
            context.Response.ContentEncoding = System.Text.Encoding.UTF8;
            var mess = Handle(context);
            if (mess is string)
            {
                context.Response.Write(mess);
            }
            else
                context.Response.Write(JsonConvert.SerializeObject(mess));

        }

        private static object Handle(HttpContext context)
        {

            HttpRequest request = context.Request;
            var typeName = request.QueryString["type"];
            var callMethod = request.QueryString["callmethod"];
            string methodName = string.Empty;
            if (request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase) && !string.IsNullOrEmpty(callMethod))
            {
                var lastDotIndex = callMethod.LastIndexOf(".");
                typeName = callMethod.Substring(0, lastDotIndex );
                methodName = callMethod.Substring(lastDotIndex + 1);
            }
            if (string.IsNullOrEmpty(typeName))
            {
                return "alert('" + request.RawUrl + "需要传入type类型参数')";
            }
            Assembly assembly = FindAssembly(typeName);
            if (assembly == null)
            {

                return "alert('" + string.Format("无法找到类型{0}的程序集，请指定assembly参数！", typeName) + "')";
            }
            Type type = assembly.GetType(typeName);
            if (type == null)
            {
                return "alert('" + string.Format("无法找到{0}类型", typeName) + "')";
            }
            //请求前端脚本
            if (!string.IsNullOrEmpty(request.QueryString["type"]) && request.HttpMethod.Equals("GET", StringComparison.OrdinalIgnoreCase))
            {
                context.Response.AddHeader("Content-Type", "application/x-javascript");
                return BuildScript(type, context.Request.Path);
            }
            object mess = null;
            MethodInfo methodInfo = type.GetMethod(methodName, BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static);
            if (methodInfo == null)
            {
                mess = new { __error__ = "无法调用方法'" + callMethod + "'，请检查后台是否存在此方法" };
                return JsonConvert.SerializeObject(mess);
            }
            try
            {

                ParameterInfo[] paramterInfos = methodInfo.GetParameters();
                object[] paramters = new object[paramterInfos.Length];
                for (int i = 0; i < paramterInfos.Length; i++)
                {
                    Type parameterType = paramterInfos[i].ParameterType;
                    string parameterName = paramterInfos[i].Name;
                    string parameterValue = null;
                    parameterValue = request[parameterName];
                    if (parameterType.IsPrimitive || typeof(string) == parameterType)
                        paramters[i] = Convert.ChangeType(parameterValue, parameterType);
                    else
                        paramters[i] = JsonConvert.DeserializeObject(parameterValue, parameterType);
                }
                object instance = null;
                if (!methodInfo.IsStatic)
                    instance = Activator.CreateInstance(type, new object[] { });
                //是否开启事务
                var transAttribute = methodInfo.GetCustomAttributes(typeof(TransactionAttribute), true);
                var isOpenTrans = true;
                if (transAttribute.Length > 0 )                  
                {
                    isOpenTrans = ((TransactionAttribute)transAttribute[0]).IsOpen;
                }
                else if (methodInfo.Name.StartsWith("get", StringComparison.OrdinalIgnoreCase))
                {
                    isOpenTrans = false;
                }

               

                if (isOpenTrans)
                {
                    using (var trans = DBHelper.BeginTransaction())
                    {
                        mess = new { result = methodInfo.Invoke(instance, paramters) };
                        trans.Complete();
                    }
                }
                else
                {
                    mess = new { result = methodInfo.Invoke(instance, paramters) };
                }

            }
            catch (Exception ex)
            {
                var innerEx = ex.InnerException ?? ex;
                mess = new { __error__ = innerEx.Message + innerEx.StackTrace };

            }

            return mess;
        }
        /// <summary>
        /// 创建类型的脚本
        /// </summary>
        /// <param name="type"></param>
        /// <param name="xmlHttpUrl"></param>
        /// <returns></returns>
        public static string BuildScript(Type type, string xmlHttpUrl)
        {
            string script;
            if (_cacheScript.TryGetValue(type, out script)) { return script; }
            StringBuilder sb = new StringBuilder();
            sb.AppendLine(@";(function(window,type,serverUrl) { ");
            sb.AppendLine("if(!window.$) {alert('人生苦短，我用jquery ');} ");
            sb.AppendLine("var service={}; window.__ajaxUrl=serverUrl;");

            script = @"
    function ajax(callMethod, data, ajaxUrl) {
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
                returnValue= data.callback(json.result);
            }
            returnValue= json.result;
        }
        $.ajax({ url: ajaxUrl + '?callMethod=' + callMethod, contentType: 'application/x-www-form-urlencoded; charset=UTF-8', data: data, async: async, type: 'POST', cache: false, dataType: 'json' }).done(ajaxdone);
        return returnValue;

    };
    function parseParam(data, paramName, paramVal) {
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
    //扩展，兼容小平台ajax调用
    window.__ajax = ajax;
    window.my = window.my || {};
    my.ajax = my.ajax || {};
    my.ajax.callMethod = function(option) {
        option = option || {}
        data = option.data || option;
        var serviceInfo = option.serviceInfo;
        var ajaxUrl = option.ajaxUrl;
        return window.__ajax(serviceInfo, data, ajaxUrl);

    }

";
            sb.AppendLine(script);
            object instance = (object)Activator.CreateInstance(type, new object[] { });
            foreach (PropertyInfo propertyInfo in type.GetProperties(_bindingFlags))
            {
                sb.AppendLine("service." + propertyInfo.Name + "='" + propertyInfo.GetValue(instance, null) + "';");
            }

            foreach (MethodInfo methodInfo in type.GetMethods(_bindingFlags))
            {
                var obj = new object();

                ParameterInfo[] paramterInfos = methodInfo.GetParameters();
                //只处理有返回值的方法
                if (methodInfo.DeclaringType == typeof(object))
                    continue;
                sb.Append("service." + methodInfo.Name + " = function(");
                List<string> paramterNames = new List<string>();
                for (int i = 0; i < paramterInfos.Length; i++)
                {

                    paramterNames.Add(paramterInfos[i].Name);
                }

                sb.Append(string.Join(",", paramterNames.ToArray()));
                sb.AppendLine("){var data={};");
                foreach (string paramterName in paramterNames)
                {
                    string parseParam = "parseParam(data,'{0}',{0});\r\n";
                    sb.AppendFormat(parseParam, paramterName);
                }

                sb.AppendLine(" if (arguments.length > 0 &&   $.isFunction(arguments[arguments.length-1])){data.callback=arguments[arguments.length-1];}");
                string callMethod = type.FullName + "." + methodInfo.Name;
                sb.AppendLine(" var sRtn =ajax('" + callMethod + "',data);");
                sb.AppendLine("return sRtn;");
                sb.AppendLine("};");

            }
            //支持amd和commonjs
            var moduleJS = @"
if ( typeof module === 'object' && module && typeof module.exports === 'object' ) { module.exports = service;}
if ( typeof define === 'function' ) {  define( function () { return service; } );}
  serviceNames = type.split('.');
window[serviceNames[serviceNames.length-1]] = service;";
            sb.AppendLine(moduleJS);
         
            sb.AppendLine("})(this,'"+type.FullName+"','"+ xmlHttpUrl+"');");
            script = sb.ToString();
            _cacheScript[type] = script;
            return script;
        }
    }
}
