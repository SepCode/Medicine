document.addEventListener( "plusready",  function()
{
    var _BARCODE = 'plugintest',
		B = window.plus.bridge;
    var plugintest = 
    {
    	PluginTestFunction : function (Argus1, Argus2, Argus3, Argus4, successCallback, errorCallback ) 
		{
			var success = typeof successCallback !== 'function' ? null : function(args) 
			{
				successCallback(args);
			},
			fail = typeof errorCallback !== 'function' ? null : function(code) 
			{
				errorCallback(code);
			};
			callbackID = B.callbackId(success, fail);

			return B.exec(_BARCODE, "PluginTestFunction", [callbackID, Argus1, Argus2, Argus3, Argus4]);
		},
		PluginTestFunctionArrayArgu : function (Argus, successCallback, errorCallback ) 
		{
			var success = typeof successCallback !== 'function' ? null : function(args) 
			{
				successCallback(args);
			},
			fail = typeof errorCallback !== 'function' ? null : function(code) 
			{
				errorCallback(code);
			};
			callbackID = B.callbackId(success, fail);
			return B.exec(_BARCODE, "PluginTestFunctionArrayArgu", [callbackID, Argus]);
		},		
        PluginTestFunctionSync : function (Argus1, Argus2, Argus3, Argus4) 
        {                                	
            return B.execSync(_BARCODE, "PluginTestFunctionSync", [Argus1, Argus2, Argus3, Argus4]);
        },
        PluginTestFunctionSyncArrayArgu : function (Argus) 
        {                                	
            return B.execSync(_BARCODE, "PluginTestFunctionSyncArrayArgu", [Argus]);
        },
                          // 用户名，签名，成功回调，失败回调
          loginILive : function (Argus1, Argus2, successCallback, errorCallback )
          {
          var success = typeof successCallback !== 'function' ? null : function(args)
          {
          successCallback(args);
          },
          fail = typeof errorCallback !== 'function' ? null : function(code)
          {
          errorCallback(code);
          };
          callbackID = B.callbackId(success, fail);
          
          return B.exec(_BARCODE, "loginILive", [callbackID, Argus1, Argus2]);
          },
          openMap : function ()
          {
          return B.execSync(_BARCODE, "openMap", null);
          },
          joinRoom : function (Argus1, Argus2, successCallback, errorCallback )
          {
          var success = typeof successCallback !== 'function' ? null : function(args)
          {
          successCallback(args);
          },
          fail = typeof errorCallback !== 'function' ? null : function(code)
          {
          errorCallback(code);
          };
          callbackID = B.callbackId(success, fail);
          
          return B.exec(_BARCODE, "joinRoom", [callbackID, Argus1, Argus2]);
          }
    };
    window.plus.plugintest = plugintest;
}, true );
