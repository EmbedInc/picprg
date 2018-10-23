@echo off
rem
rem   Build all the PICPRG library and various apps and test programs directly
rem   related to it.
rem
setlocal
call godir (cog)source/picprg/picprg
call build_vars

call build_lib
call build_progs

call src_doc %srcdir% picprg_env.txt
call src_doc %srcdir% picprg_prot.txt
