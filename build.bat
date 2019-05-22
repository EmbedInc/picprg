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
call build_doc
