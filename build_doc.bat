@echo off
rem
rem   Build and install the documentation from this source directory.
rem
setlocal
call build_vars

call src_doc picprg_env
call src_doc picprg_prot


