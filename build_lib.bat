@echo off
rem   Build the PICPRG linkable library.
rem
setlocal
set srcdir=picprg
set buildname=picprg

call src_get picprg picprg.ins.pas
call src_get picprg picprg2.ins.pas
call src_getfrom sys sys.ins.pas
call src_getfrom util util.ins.pas
call src_getfrom string string.ins.pas
call src_getfrom file file.ins.pas
call src_getfrom stuff stuff.ins.pas

call src_insall picprg picprg

call src_pas picprg picprg_10 %1
call src_pas picprg picprg_12 %1
call src_pas picprg picprg_12f6 %1
call src_pas picprg picprg_16 %1
call src_pas picprg picprg_18 %1
call src_pas picprg picprg_30 %1
call src_pas picprg picprg_close %1
call src_pas picprg picprg_cmdovl %1
call src_pas picprg picprg_config %1
call src_pas picprg picprg_convert %1
call src_pas picprg picprg_cmd %1
call src_pas picprg picprg_cmds %1
call src_pas picprg picprg_cmdw %1
call src_pas picprg picprg_devs %1
call src_pas picprg picprg_env %1
call src_pas picprg picprg_fw %1
call src_pas picprg picprg_id %1
call src_pas picprg picprg_init %1
call src_pas picprg picprg_open %1
call src_pas picprg picprg_prog %1
call src_pas picprg picprg_read %1
call src_pas picprg picprg_rsp %1
call src_pas picprg picprg_sys %1
call src_pas picprg picprg_tdat %1
call src_pas picprg picprg_thread_in %1
call src_pas picprg picprg_tinfo %1
call src_pas picprg picprg_util %1
call src_pas picprg picprg_write %1

call src_lib picprg picprg
call src_msg picprg picprg
call src_msg picprg picprg_org1
call src_env picprg picprg.env
