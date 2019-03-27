@echo off
rem
rem   Initialize for building Pascal modules from this library.
rem
call build_vars

call src_go "%srcdir%"
call src_getfrom sys base.ins.pas
call src_getfrom sys sys.ins.pas
call src_getfrom util util.ins.pas
call src_getfrom string string.ins.pas
call src_getfrom file file.ins.pas
call src_getfrom pic pic.ins.pas
call src_getfrom stuff stuff.ins.pas

call src_get %srcdir% %libname%.ins.pas
call src_get %srcdir% %libname%2.ins.pas

call src_builddate "%srcdir%"
