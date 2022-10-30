{   High level function for PIC 18s with 8 bit programming opcodes and 24 bit
*   programming data words.
}
module picprg_18b;
define picprg_erase_18f25q10;
%include 'picprg2.ins.pas';
{
********************************************************************************
*
*   Local subroutine SEND_OPC (PR, OPC, STAT)
*
*   Send the programming command opcode OPC to the target PIC.  This routine
*   guarantees a minimum wait time after the opcode is sent.
}
procedure send_opc (                   {send programming command opcode to target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      opc: sys_int_machine_t;      {command opcode}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

const
  twait_opc = 1.0e-6;                  {wait time after opcode, seconds}

begin
  picprg_cmdw_send8m (pr, opc, stat);  {send the opcode}
  if sys_error(stat) then return;

  picprg_cmdw_wait (pr, twait_opc, stat); {guarantee min wait time after opcode}
  end;
{
********************************************************************************
*
*   Local subroutine SET_ADR (PR, ADR, STAT)
*
*   Set the address in the target to ADR.
}
procedure set_adr (                    {set address in target PIC}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_conv32_t;       {address to set to}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

const
  cmd_loadpc_k = 16#80;                {load PC}
  twait_cmd = 1.0e-6;                  {wait time after command, seconds}

begin
  send_opc (pr, cmd_loadpc_k, stat);   {send the opcode}
  if sys_error(stat) then return;

  picprg_send22mss24 (pr, adr, stat);  {send data word containing the address}
  if sys_error(stat) then return;

  picprg_cmdw_wait (pr, twait_cmd, stat); {guarantee min wait time after command}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_ERASE_18F25Q10 (PR, STAT)
*
*   Erase all the non-volatile memory of a PIC 18F25Q10 and related PICs.
}
procedure picprg_erase_18f25q10 (      {erase routine for 18F25Q10 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  cmd_erasebulk_k = 16#18;             {bulk erase, depends on current PC}
  twait_erase = 0.075;                 {bulk erase time, seconds}
  adr_erprog = 16#300000;              {address for erasing all program memory}
  adr_erdata = 16#310000;              {address for erasing all data memory}

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  set_adr (pr, adr_erprog, stat);      {set address for erasing all prog mem}
  if sys_error(stat) then return;
  send_opc (pr, cmd_erasebulk_k, stat); {do bulk erase}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, twait_erase, stat); {wait for erase to complete}
  if sys_error(stat) then return;

  set_adr (pr, adr_erdata, stat);      {set address for erasing all data mem}
  if sys_error(stat) then return;
  send_opc (pr, cmd_erasebulk_k, stat); {do bulk erase}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, twait_erase, stat); {wait for erase to complete}
  end;
