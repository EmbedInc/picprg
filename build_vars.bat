@echo off
rem
rem   Define the shell variables for running builds from this source library.
rem
set srcdir=picprg
set buildname=picprg
set libname=picprg
call treename_var "(cog)source/%srcdir%/%buildname%" sourcedir
set t_parms=
call treename_var "(cog)src/%srcdir%/debug_%fwname%.bat" tnam
make_debug "%tnam%"
call "%tnam%"
