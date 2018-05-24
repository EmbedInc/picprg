@echo off
rem
rem   Build all the executable programs from this source library.
rem
setlocal
set srcdir=picprg
set buildname=picprg

call src_get picprg picprg.ins.pas
call src_get picprg picprg2.ins.pas
call src_getfrom stuff stuff.ins.pas

set srclib=%srcdir%
set msgname=

set prog=test_picprg
call build_prog_common %1 %2 %3 %4 %5 %6 %7 %8 %9

set prog=test_usbprog
call build_prog_common %1 %2 %3 %4 %5 %6 %7 %8 %9

set prog=pic_prog
call build_prog_common %1 %2 %3 %4 %5 %6 %7 %8 %9

set prog=pic_read
call build_prog_common %1 %2 %3 %4 %5 %6 %7 %8 %9

set prog=pic_ctrl
call build_prog_common %1 %2 %3 %4 %5 %6 %7 %8 %9

set prog=picprg_list
call build_prog_common %1 %2 %3 %4 %5 %6 %7 %8 %9

set prog=usbprog_test
call build_prog_common %1 %2 %3 %4 %5 %6 %7 %8 %9

set prog=dump_picprg
call build_prog_common %1 %2 %3 %4 %5 %6 %7 %8 %9
