{   Routines that are specific to the PICs that use 8 bit programming opcodes
*   and transfer programming data in 24 bit words.  These include the PIC
*   16F15313 and related.
}
module picprg_16fb;
define picprg_send16mss24;
define picprg_send14mss24;
define picprg_recv8mss24;
define picprg_recv14mss24;
define picprg_erase_16fb;
%include 'picprg2.ins.pas';

const
  {
  *   Command opcodes understood by this chip.
  }
  opc_adr = 16#80;                     {LOAD PC ADRESS}
  opc_ebulk = 16#18;                   {BULK ERASE PROGRAM MEMORY}
  (*
  *   These opcodes are not used in the code below.  Their definitions are
  *   commented out to avoid unused symbol errors.
  *
  opc_erow = 16#F0;                    {ROW ERASE PROGRAM MEMORY}
  opc_ldat = 16#00;                    {LOAD DATA FOR NVM}
  opc_ldat_inc = 16#02;                {LOAD DATA FOR NVM, increment address}
  opc_rdat = 16#FC;                    {READ DATA FROM NVM}
  opc_rdat_inc = 16#FE;                {READ DATA FROM NMV, increment address}
  opc_inc = 16#F8;                     {INCREMENT ADDRESS}
  opc_pgint = 16#E0;                   {BEGIN INTERNALLY TIMED PROGRAMMING}
  opc_pgext = 16#C0;                   {BEGIN EXTERNALLY TIMED PROGRAMMING}
  opc_pgextend = 16#82;                {END EXTERNALLY TIMED PROGRAMMING}
  *)
{
********************************************************************************
*
*   Subroutine PICPRG_SEND16MSS24 (PR, DAT, STAT)
*
*   Send the 16 bit data in the low bits of DAT to the target in a 24 bit data
*   word.  The word is sent in most to least significant bit order.
}
procedure picprg_send16mss24 (         {send 16 bits of data in 24 bit word, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_machine_t;      {data to send in the low 16 bits}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_cmdw_send24m (pr, lshft(dat & 16#FFFF, 1), stat);
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_SEND14MSS24 (PR, DAT, STAT)
*
*   Send the 14 bit data in the low bits of DAT to the target in a 24 bit data
*   word.  The word is sent in most to least significant bit order.
}
procedure picprg_send14mss24 (         {send 14 bits of data in 24 bit word, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_machine_t;      {data to send in the low 14 bits}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_cmdw_send24m (pr, lshft(dat & 16#3FFF, 1), stat);
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_RECV8MSS24 (PR, DAT, STAT)
*
*   Receive a 24 bit word from the target in most to least significant bit
*   order.  Return the 8 bit payload in DAT.
}
procedure picprg_recv8mss24 (          {receive 24 bit MSB-first word, get 8 bit payload}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: sys_int_machine_t;      {returned 8 bit payload}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ii: sys_int_machine_t;

begin
  picprg_cmdw_recv24m (pr, ii, stat);
  dat := rshft(ii, 1) & 16#FF;
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_RECV14MSS24 (PR, DAT, STAT)
*
*   Receive a 24 bit word from the target in most to least significant bit
*   order.  Return the 14 bit payload in DAT.
}
procedure picprg_recv14mss24 (         {receive 24 bit MSB-first word, get 14 bit payload}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: sys_int_machine_t;      {returned 14 bit payload}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ii: sys_int_machine_t;

begin
  picprg_cmdw_recv24m (pr, ii, stat);
  dat := rshft(ii, 1) & 16#3FFF;
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_ERASE_16FB (PR, STAT)
*
*   Erase 16F15313 and related.
}
procedure picprg_erase_16fb(           {erase routine for 16F15313 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_cmdw_send8m (pr, opc_adr, stat); {set address to 8000h}
  if sys_error(stat) then return;
  picprg_send16mss24 (pr, 16#8000, stat);
  if sys_error(stat) then return;

  picprg_cmdw_send8m (pr, opc_ebulk, stat); {do the bulk erase}
  if sys_error(stat) then return;

  picprg_cmdw_wait (pr, 0.015, stat);  {wait for bulk erase to complete}
  if sys_error(stat) then return;

  picprg_cmdw_reset (pr, stat);
  end;
