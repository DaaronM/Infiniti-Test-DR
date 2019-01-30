CSCRIPT.EXE C:\InetPub\adminscripts\ADSUTIL.VBS SET W3Svc/Filters/Compression/GZIP/HcFileExtensions "htm" "html" "txt" "application" "manifest" "deploy" "exe" "dll"
CSCRIPT.EXE C:\InetPub\adminscripts\ADSUTIL.VBS SET W3Svc/Filters/Compression/DEFLATE/HcFileExtensions "htm" "html" "txt" "application" "manifest" "deploy" "exe" "dll"

CSCRIPT.EXE C:\InetPub\adminscripts\ADSUTIL.VBS SET W3Svc/Filters/Compression/GZIP/HcScriptFileExtensions "asp" "dll" "exe" "aspx" "asmx" "ashx"
CSCRIPT.EXE C:\InetPub\adminscripts\ADSUTIL.VBS SET W3Svc/Filters/Compression/DEFLATE/HcScriptFileExtensions "asp" "dll" "exe" "aspx" "asmx" "ashx"

iisreset