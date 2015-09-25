using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Linq.Expressions;
using System.Reflection;
using System.IO;
namespace Mysoft.Project.Core
{
    /// <summary>
    /// Type related helper methods
    /// </summary>
    public static class ReflectionHelper
    {
        static Dictionary<string, Assembly> _assmblyCache = new Dictionary<string, Assembly>();
        public static Assembly FindAssembly(string typeName)
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

        /// <summary>
        /// 获取资源文件的流
        /// </summary>
        /// <param name="resourceName">包括资源的命名空间 </param>
        /// <param name="type"></param>
        /// <returns></returns>
        public static Stream GetResourceStream(string resourceName, Type type)
        {
            Assembly assembly = Assembly.GetAssembly(type);
            var stream = assembly.GetManifestResourceStream(resourceName);
            if (stream == null)
            {
                var resName = assembly.GetManifestResourceNames().FirstOrDefault(name => name.EndsWith(resourceName, StringComparison.CurrentCultureIgnoreCase));
                if (resName != null)
                    stream = assembly.GetManifestResourceStream(resName);
            }
            return stream;
        }
        /// <summary>
        /// 获取资源文件的文本
        /// </summary>
        /// <param name="resourceName">包括资源的命名空间 </param>
        /// <param name="type"></param>
        /// <returns></returns>
        public static string GetResourceString(string resourceName, Type type)
        {
            using (StreamReader reader = new StreamReader(GetResourceStream(resourceName, type), Encoding.UTF8))
            {
                return reader.ReadToEnd();
            }
        }    
    }
}
