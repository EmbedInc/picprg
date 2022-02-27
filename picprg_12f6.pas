{   Target driver routines that are specific to the PIC 12F6xx family.
}
module picprg_12f6;
define picprg_erase_12f6xx;
%include 'picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_12F6XX (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for the 12F6xx target devices.
}
procedure picprg_erase_12f6xx (        {erase routine for 12F6xx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  osccal: picprg_dat_t;                {saved oscillator calibration data}
  config: picprg_dat_t;                {saved configuration word}

  tk: string_var32_t;

begin
  tk.max := size_char(tk.str);

  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_read (                        {read the OSCCAL word}
    pr,                                {state for this use of the library}
    16#3FF,                            {address to read}
    1,                                 {number of words to read}
    pr.id_p^.maskprg,                  {data bits mask info}
    osccal,                            {returned data value}
    stat);
  if sys_error(stat) then return;
  string_f_int_max_base (              {make HEX value string}
    tk, osccal, 16, 4, [string_fi_leadz_k, string_fi_unsig_k], stat);
  if sys_error(stat) then return;
  writeln ('OSCCAL = ', tk.str:tk.len, 'h');

  picprg_read (                        {read the CONFIG word}
    pr,                                {state for this use of the library}
    16#2007,                           {address to read}
    1,                                 {number of words to read}
    pr.id_p^.maskprg,                  {data bits mask info}
    config,                            {returned data value}
    stat);
  if sys_error(stat) then return;
  string_f_int_max_base (              {make HEX value string}
    tk, config, 16, 4, [string_fi_leadz_k, string_fi_unsig_k], stat);
  if sys_error(stat) then return;
  writeln ('CONFIG = ', tk.str:tk.len, 'h');
  sys_flush_stdout;                    {make sure all output sent to parent program}

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION, sets adr to 2000h}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send dummy data word}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#001001, stat);   {BULK ERASE PROGRAM MEMORY}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.008, stat);  {insert wait for erase to complete}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#001011, stat);   {BULK ERASE DATA MEMORY}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.008, stat);  {insert wait for erase to complete}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset the target}
  if sys_error(stat) then return;

  picprg_write (                       {restore OSCCAL word}
    pr,                                {state for this use of the library}
    16#3FF,                            {address to write to}
    1,                                 {number of words to write}
    osccal,                            {the data word to write}
    pr.id_p^.maskprg,                  {data bits mask info}
    stat);
  if sys_error(stat) then return;

  config := config ! 16#FFF;           {set all but bandgap bits to erased value}
  picprg_write (                       {restore BG bits in config word}
    pr,                                {state for this use of the library}
    16#2007,                           {address to write to}
    1,                                 {number of words to write}
    config,                            {the data word to write}
    pr.id_p^.maskprg,                  {data bits mask info}
    stat);
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset the target}
  if sys_error(stat) then return;
  end;
