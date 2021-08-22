@echo off
rem
rem   Build all the executable programs from this source library.
rem
setlocal
call build_pasinit

call src_prog %srcdir% dump_picprg %1
call src_prog %srcdir% pic_prog %1
call src_prog %srcdir% pic_read %1
call src_prog %srcdir% pic_ctrl %1
call src_prog %srcdir% picprg_list %1
call src_prog %srcdir% test_picprg %1
call src_prog %srcdir% test_ppdat %1
call src_prog %srcdir% test_usbprog %1
