{   Target driver routines that are specific to the PIC10 family.
}
module picprg_10;
define picprg_erase_10;
%include '/cognivision_links/dsee_libs/pics/picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_10 (PR, STAT)
*
*   Erase all non-volatile memory in the target chip.
*
*   This version is for 10Fxxx devices.  The backup OSCCAL MOVLW instruction
*   in configuration space is preserved.  The OSCCAL MOVLW instruction at the
*   reset vector (last location in program memory) is erased, since the
*   application may decide to write other information there.
}
procedure picprg_erase_10 (            {erase routine for generic 10Fxxx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  tera = 0.010;                        {erase wait time, seconds}
  max_msg_args = 1;                    {max arguments we can pass to a message}

type
  cal_k_t = (                          {indicates where OSCCAL value came from}
    cal_back_k,                        {backup OSCCAL location}
    cal_last_k,                        {from last instruction word}
    cal_def_k);                        {default value}

var
  lastpgm: picprg_dat_t;               {saved last location of program memory}
  osccal: picprg_dat_t;                {saved backup oscillator calibration MOVLW}
  tk: string_var32_t;
  cal: cal_k_t;                        {indicates where OSCCAL value came from}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;

begin
  tk.max := size_char(tk.str);

  picprg_vddlev (pr, picprg_vdd_norm_k, stat); {select normal Vdd}
  if sys_error(stat) then return;
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;
{
*   Read and save the backup OSCCAL data and the last instruction in memory.
*   These should both be MOVLW instruction, which are Cxxh.
}
  picprg_read (                        {read the last executable location}
    pr,                                {state for this use of the library}
    pr.id_p^.nprog - 1,                {address to read}
    1,                                 {number of locations to read}
    pr.id_p^.maskprg,                  {mask for valid data bits}
    lastpgm,                           {returned data}
    stat);
  if sys_error(stat) then return;

  picprg_read (                        {read the backup OSCCAL MOVLW instruction}
    pr,                                {state for this use of the library}
    pr.id_p^.nprog + pr.id_p^.ndat + 4, {address to read}
    1,                                 {number of locations to read}
    pr.id_p^.maskprg,                  {mask for valid data bits}
    osccal,                            {returned data}
    stat);
  if sys_error(stat) then return;
{
*   Erase with PC at the configuration word.  The config word is first set to 0,
*   which turns on code protection, which causes additional things to get erased
*   when the config word is erased.  Erasing the config word disables code
*   protection.
}
  {
  *   Write 0 to the config word.
  }
  picprg_reset (pr, stat);             {put the PC at the config word}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2, stat);          {LOAD DATA}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {0 data word}
  if sys_error(stat) then return;

  picprg_send6 (pr, 8, stat);          {BEGIN PROGRAMMING}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, pr.id_p^.tprogp, stat); {wait the programming time}
  if sys_error(stat) then return;
  picprg_send6 (pr, 14, stat);         {END PROGRAMMING}
  if sys_error(stat) then return;
  {
  *   Erase.  The PC is currently at the config word.
  }
  picprg_send6 (pr, 9, stat);          {send BULK ERASE PROGRAM MEMORY command}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, tera, stat);   {insert wait for erase to finish}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target after bulk erase}
  if sys_error(stat) then return;
{
*   If the backup OSCCAL word was 0, then try reading it again because it might
*   have been reported as 0 due to code protection, which is now off.  Code
*   protection doesn't actually cover the backup OSCCAL value, but on some PICs
*   it reads 0 anyway as long as code protection is on.
}
  if osccal = 0 then begin             {backup cal 0, could be read protected ?}
    picprg_read (                      {read the backup OSCCAL MOVLW instruction}
      pr,                              {state for this use of the library}
      pr.id_p^.nprog + pr.id_p^.ndat + 4, {address to read}
      1,                               {number of locations to read}
      pr.id_p^.maskprg,                {mask for valid data bits}
      osccal,                          {returned data}
      stat);
    if sys_error(stat) then return;
    end;
{
*   Determine what to consider the calibration value, and record where it came
*   from.  Normally this comes from the backup OSCCAL location, but if that is
*   is not a valid MOVLW instruction (Cxxh), then we try to use what was read
*   from the last location of program memory.  If that is not a valid MOVLW
*   instruction either, then the stored calibration value for this chip has been
*   lost, and we substitute the middle value of 0, which results in a MOVLW
*   instruction of C00h.
}
  cal := cal_back_k;                   {init to using backup OSCCAL value}
  if (osccal & 16#F00) <> 16#C00 then begin {backup OSCCAL not MOVLW instruction ?}
    if (lastpgm & 16#F00) = 16#C00
      then begin                       {last executable location contains MOVLW}
        osccal := lastpgm;             {use value from last executable location}
        cal := cal_last_k;
        end
      else begin                       {last instruction not MOVLW either}
        osccal := 16#C00;              {pick center value}
        cal := cal_def_k;
        end
      ;
    end;

  string_f_int_max_base (              {make HEX value string}
    tk, osccal, 16, 3, [string_fi_leadz_k, string_fi_unsig_k], stat);
  if sys_error(stat) then return;
  sys_msg_parm_vstr (msg_parm[1], tk);
  case cal of
cal_last_k: sys_message_parms ('picprg', 'osccal_last', msg_parm, 1);
cal_def_k:  sys_message_parms ('picprg', 'osccal_default', msg_parm, 1);
otherwise
    sys_message_parms ('picprg', 'osccal_backup', msg_parm, 1);
    end;
{
*   Erase the user ID locations.  This is done with the PC at one of the user
*   ID locations.
}
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_adr (                    {set address to first user ID word}
    pr,                                {state for this use of the library}
    pr.id_p^.nprog + pr.id_p^.ndat,    {address to set}
    stat);
  if sys_error(stat) then return;

  picprg_send6 (pr, 9, stat);          {send BULK ERASE PROGRAM MEMORY command}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, tera, stat);   {insert wait for erase to finish}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);
  if sys_error(stat) then return;
{
*   Erase non-volatile data memory if this chip has any.  This is done with the
*   PC in the non-volatile data space.
}
  if pr.id_p^.ndat > 0 then begin      {this chip has non-volatile data memory ?}
    picprg_reset (pr, stat);           {reset target to put it into known state}
    if sys_error(stat) then return;

    picprg_cmdw_adr (                  {set address to first data memory word}
      pr,                              {state for this use of the library}
      pr.id_p^.nprog,                  {address to set}
      stat);
    if sys_error(stat) then return;

    picprg_send6 (pr, 9, stat);        {send BULK ERASE PROGRAM MEMORY command}
    if sys_error(stat) then return;
    picprg_cmdw_wait (pr, tera, stat); {insert wait for erase to finish}
    if sys_error(stat) then return;
    picprg_reset (pr, stat);
    if sys_error(stat) then return;
    end;
{
*   Restore the backup OSCCAL MOVLW instruction.
}
  picprg_write (                       {write the backup OSCCAL MOVLW instruction}
    pr,                                {state for this use of the library}
    pr.id_p^.nprog + pr.id_p^.ndat + 4, {address to write}
    1,                                 {number of locations to write}
    osccal,                            {the data to write}
    pr.id_p^.maskprg,                  {mask for the valid data bits}
    stat);
  end;
