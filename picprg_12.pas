{   Target driver routines that are specific to the 12 bit core.
}
module picprg_12;
define picprg_erase_12;
%include 'picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_12 (PR, STAT)
*
*   Erase all non-volatile memory in the target chip.
*
*   This version is for generic 12 bit core devices that do not have any
*   oscillator calibration value that must be preserved or otherwise handled.
}
procedure picprg_erase_12 (            {erase routine for generic 12 bit core}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  tera = 10.0;                         {erase wait time, milliseconds}

var
  v: picprg_dat_t;                     {scratch PIC data value}

begin
  picprg_vddlev (pr, picprg_vdd_norm_k, stat); {select normal Vdd}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_read (                        {read to force address to first user config}
    pr,                                {state for this use of the library}
    pr.id_p^.nprog,                    {address to read}
    1,                                 {number of locations to read}
    pr.id_p^.maskprg,                  {mask for valid data bits}
    v,                                 {returned data, ignored}
    stat);
  if sys_error(stat) then return;

  picprg_send6 (pr, 9, stat);          {send BULK ERASE PROGRAM MEMORY command}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, tera/1000.0, stat); {insert wait for erase to finish}
  if sys_error(stat) then return;
  end;
