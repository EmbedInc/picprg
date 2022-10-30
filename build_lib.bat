@echo off
rem   Build the PICPRG linkable library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_10 %1
call src_pas %srcdir% %libname%_12 %1
call src_pas %srcdir% %libname%_12f6 %1
call src_pas %srcdir% %libname%_16 %1
call src_pas %srcdir% %libname%_16fb %1
call src_pas %srcdir% %libname%_18 %1
call src_pas %srcdir% %libname%_18b %1
call src_pas %srcdir% %libname%_30 %1
call src_pas %srcdir% %libname%_close %1
call src_pas %srcdir% %libname%_cmdovl %1
call src_pas %srcdir% %libname%_config %1
call src_pas %srcdir% %libname%_convert %1
call src_pas %srcdir% %libname%_cmd %1
call src_pas %srcdir% %libname%_cmds %1
call src_pas %srcdir% %libname%_cmdw %1
call src_pas %srcdir% %libname%_devs %1
call src_pas %srcdir% %libname%_env %1
call src_pas %srcdir% %libname%_fw %1
call src_pas %srcdir% %libname%_id %1
call src_pas %srcdir% %libname%_init %1
call src_pas %srcdir% %libname%_open %1
call src_pas %srcdir% %libname%_prog %1
call src_pas %srcdir% %libname%_read %1
call src_pas %srcdir% %libname%_rsp %1
call src_pas %srcdir% %libname%_sys %1
call src_pas %srcdir% %libname%_tdat %1
call src_pas %srcdir% %libname%_thread_in %1
call src_pas %srcdir% %libname%_tinfo %1
call src_pas %srcdir% %libname%_util %1
call src_pas %srcdir% %libname%_write %1

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%
call src_msg %srcdir% %libname%_org1
call src_env %srcdir% %libname%.env
