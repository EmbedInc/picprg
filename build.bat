@echo off
rem
rem   Build all the PICPRG library and various apps and test programs directly
rem   related to it.
rem
setlocal
set srcdir=picprg
set buildname=picprg

call godir (cog)source/picprg/picprg
call build_lib
call build_progs

copya picprg_env.txt (cog)doc/picprg_env.txt
copya picprg_prot.txt (cog)doc/picprg_prot.txt
