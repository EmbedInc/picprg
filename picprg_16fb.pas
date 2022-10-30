{   Routines that are specific to the PICs that use 8 bit programming opcodes
*   and transfer programming data in 24 bit words.  These include the PICs
*   16F15313, 18F25Q10, and others.
}
module picprg_16fb;
define picprg_send8mss24;
define picprg_send14mss24;
define picprg_send16mss24;
define picprg_send22mss24;
define picprg_recv8mss24;
define picprg_recv14mss24;
define picprg_recv16mss24;
define picprg_erase_16fb;
%include 'picprg2.ins.pas';

const
  {
  *   Command opcodes understood by this chip.
  }
  opc_adr = 16#80;                     {LOAD PC ADRESS}
  opc_ebulk = 16#18;                   {BULK ERASE PROGRAM MEMORY}
{
********************************************************************************
*
*   Subroutine PICPRG_SEND8MSS24 (PR, DAT, STAT)
*
*   Send the 8 bit data in the low bits of DAT to the target in a 24 bit data
*   word.  The word is sent in most to least significant bit order.
}
procedure picprg_send8mss24 (          {send 8 bit payload in 24 bit word, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_machine_t;      {data to send in the low 8 bits}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_cmdw_send24m (pr, lshft(dat & 16#FF, 1), stat);
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_SEND14MSS24 (PR, DAT, STAT)
*
*   Send the 14 bit data in the low bits of DAT to the target in a 24 bit data
*   word.  The word is sent in most to least significant bit order.
}
procedure picprg_send14mss24 (         {send 14 bit payload in 24 bit word, MSB first}
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
*   Subroutine PICPRG_SEND16MSS24 (PR, DAT, STAT)
*
*   Send the 16 bit data in the low bits of DAT to the target in a 24 bit data
*   word.  The word is sent in most to least significant bit order.
}
procedure picprg_send16mss24 (         {send 16 bit payload in 24 bit word, MSB first}
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
*   Subroutine PICPRG_SEND22MSS24 (PR, DAT, STAT)
*
*   Send the 22 bit data in the low bits of DAT to the target in a 24 bit data
*   word.  The word is sent in most to least significant bit order.
}
procedure picprg_send22mss24 (         {send 22 bit payload in 24 bit word, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_machine_t;      {data to send in the low 22 bits}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_cmdw_send24m (pr, lshft(dat & 16#3FFFFF, 1), stat);
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
  picprg_cmdw_recv24m (pr, ii, stat);  {get the 24 bit word from the target}
  dat := rshft(ii, 1) & 16#FF;         {extract the 8 bit payload}
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
  picprg_cmdw_recv24m (pr, ii, stat);  {get the 24 bit word from the target}
  dat := rshft(ii, 1) & 16#3FFF;       {extract the 14 bit payload}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_RECV16MSS24 (PR, DAT, STAT)
*
*   Receive a 24 bit word from the target in most to least significant bit
*   order.  Return the 16 bit payload in DAT.
}
procedure picprg_recv16mss24 (         {receive 24 bit MSB-first word, get 16 bit payload}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: sys_int_machine_t;      {returned 16 bit payload}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ii: sys_int_machine_t;

begin
  picprg_cmdw_recv24m (pr, ii, stat);  {get the 24 bit word from the target}
  dat := rshft(ii, 1) & 16#FFFF;       {extract the 16 bit payload}
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
