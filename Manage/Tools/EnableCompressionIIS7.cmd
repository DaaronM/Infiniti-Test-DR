%systemroot%\system32\inetsrv\appcmd set config -section:urlCompression /doDynamicCompression:true
%systemroot%\system32\inetsrv\appcmd set config -section:urlCompression /doStaticCompression:true
%systemroot%\system32\inetsrv\appcmd set config -section:httpCompression /+dynamicTypes.[@start,mimeType='application/msword',enabled='true']
%systemroot%\system32\inetsrv\appcmd set config -section:httpCompression /+dynamicTypes.[@start,mimeType='application/x-ms-application',enabled='true']
%systemroot%\system32\inetsrv\appcmd set config -section:httpCompression /+dynamicTypes.[@start,mimeType='application/octet-stream',enabled='true']
%systemroot%\system32\inetsrv\appcmd set config -section:httpCompression /+dynamicTypes.[@start,mimeType='image/x-icon',enabled='true']
%systemroot%\system32\inetsrv\appcmd set config -section:httpCompression /+dynamicTypes.[@start,mimeType='application/json',enabled='true']
%systemroot%\system32\inetsrv\appcmd set config -section:httpCompression /+dynamicTypes.[@start,mimeType='application/json; charset=utf-8',enabled='true']
iisreset