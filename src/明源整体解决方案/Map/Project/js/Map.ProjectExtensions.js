/*如果需要对平台的MapExt进行扩展，请将扩展的函数放在此处，以免对升级平台js造成不便*/
(function() {
    MapExt.getUrlParameter = function(sParam) {
        var sPageURL = window.location.search.substring(1);
        var sURLVariables = sPageURL.split('&');
        for (var i = 0; i < sURLVariables.length; i++) {
            var sParameterName = sURLVariables[i].split('=');
            if (sParameterName[0] == sParam) {
                return sParameterName[1];
            }
        }
    };

    function openStandardWindow(url, name, width, height) {
        if (!name) name = "";
        if (!width) width = 800;
        if (!height) height = 552;
        var iL = (window.screen.width - width) / 2;
        var iT = (window.screen.height - height - 80) / 2;
        var sFeatures = "left=" + iL + ",top=" + iT + ",width=" + width + ",height=" + height + ",status=1,resizable=1";
        return window.open(url, name, sFeatures);
    }

    function openMarginWindow(url, name, horizontalMargin, verticalMargin) {
        if (!name) name = "";
        if (!horizontalMargin) horizontalMargin = 100;
        if (!verticalMargin) verticalMargin = 100;
        var iX = window.screen.width - horizontalMargin * 2 - 20;
        var iY = window.screen.height - verticalMargin * 2 - 80;
        var sFeatures = "left=" + horizontalMargin + ",top=" + verticalMargin + ",width=" + iX + ",height=" + iY + ",status=1,resizable=1";
        return window.open(url, name, sFeatures);
    }

    function creatAndSubmitForm(url, data, name) {
        var tempForm = document.createElement("form");
        tempForm.id = "tempForm1";
        tempForm.method = "post";
        tempForm.action = url;
        tempForm.target = name;
        for (var key in data) {
            var hideInput = document.createElement("input");
            hideInput.type = "hidden";
            hideInput.name = key
            hideInput.value = data[key];
            tempForm.appendChild(hideInput);
        }
        document.body.appendChild(tempForm);
        tempForm.submit();
        document.body.removeChild(tempForm);
    }

    MapExt.openMarginWindow = function(option) {
        ///	<summary>
        ///     打开一个非模态窗口，窗口距左右有一定边距
        ///     var option = {
        ///         url: "/xxxx/abc.aspx",			// （必埴）文件路径，不带任何查询字符串参数
        ///         data: { a: 1, b: 2, c: 3 },		// （可选）查询字符串参数对象，注意：是一个对象，不是字符串。
        ///         name: "windowName",				// （必埴）窗口名称
        ///         horizontalMargin: 100,			// （必埴）水平边距
        ///         verticalMargin: 100,			// （必埴）垂直边距
        ///     };
        ///	</summary>

        var url = MapExt.param(option.url, option.data);
        return openMarginWindow(url, option.name, option.horizontalMargin, option.verticalMargin);
    }

    //以当前窗口地址打开新窗口
    MapExt.openNewCurrentWindow = function(option) {
        if (!option) option = {};
        option.name = "";
        option.url = window.location.href;
        if (!option.data) option.data = {};
        option.url = option.url.replace("?x-charset=utf-8", "?");
        option.url = option.url.replace("&x-charset=utf-8", "");
        var url = MapExt.param(option.url, option.data);
        return openMarginWindow(url, option.name, option.horizontalMargin, option.verticalMargin);
    }

    MapExt.openStandardWindow = function(option) {
        ///	<summary>
        ///     打开一个非模态窗口，指定宽高
        ///     var option = {
        ///         url: "/xxxx/abc.aspx",			// （必埴）文件路径，不带任何查询字符串参数
        ///         data: { a: 1, b: 2, c: 3 },		// （可选）查询字符串参数对象，注意：是一个对象，不是字符串。
        ///         name: "windowName",				// （必埴）窗口名称
        ///         width: 800,			            // （可选）宽度
        ///         height: 552,			        // （可选）高度
        ///     };
        ///	</summary>
        var url = MapExt.param(option.url, option.data);
        return openStandardWindow(url, option.name, option.width, option.height);
    }

    MapExt.postStandardWindow = function(option) {
        if (!option.name) {
            option.name = Math.random().toString().replace(".", "");
        }
        openStandardWindow("about:blank", option.name, option.width, option.height);
        creatAndSubmitForm(option.url, option.data, option.name);
    }

    MapExt.postMarginWindow = function(option) {
        if (!option.name) {
            option.name = Math.random().toString().replace(".", "");
        }
        openMarginWindow("about:blank", option.name, option.horizontalMargin, option.verticalMargin);
        creatAndSubmitForm(option.url, option.data, option.name);
    }

    MapExt.openDownloadWinow = function(filename, fileUrl) {
        MapExt.openStandardWindow({
            url: "/_controls/upfile/DownloadWin.aspx",
            data: { filename: filename, fileurl: fileUrl },
            name: "",
            width: 360,
            height: 160
        });
    }
})();

