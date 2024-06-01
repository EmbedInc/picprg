@echo off
rem
rem   Initialize for building Pascal modules from this library.
rem
call build_vars

call src_getbase
call src_getfrom math math.ins.pas
call src_getfrom pic pic.ins.pas
call src_getfrom stuff stuff.ins.pas

call src_get %srcdir% %libname%.ins.pas
call src_get %srcdir% %libname%2.ins.pas

call src_builddate "%srcdir%"
