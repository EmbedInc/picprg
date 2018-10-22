{   Target driver routines that are specific to the PIC16 family.
}
module picprg_16;
define picprg_send6;
define picprg_send14ss;
define picprg_recv14ss;
define picprg_erase_16f;
define picprg_erase_16f62xa;
define picprg_erase_16f87xa;
define picprg_erase_16f7x;
define picprg_erase_16f688;
define picprg_erase_16f84;
define picprg_erase_16f7x7;
define picprg_erase_16f88x;
define picprg_erase_16f61x;
define picprg_write_16f72x;
define picprg_erase_16f182x;
define picprg_erase_16f183xx;
define picprg_erase_12f1501;
%include 'picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_SEND6 (PR, DAT, STAT)
*
*   Send the 6 low bits of DAT to the target.  This is the format of 16F
*   family commands.
}
procedure picprg_send6 (               {send 6 bits of data to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_conv16_t;       {the data word to send}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_send (pr, 6, dat, stat);      {send the bits}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_SEND14SS (PR, DAT, STAT)
*
*   Send the 14 bit data word in DAT as 16 bits with a leading start and trailing
*   stop bit.
}
procedure picprg_send14ss (            {send 14 data bits with start/stop bits}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_conv16_t;       {the data word to send}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_conv16_t;                 {data word with start and stop bits}

begin
  i := lshft(dat & 16#3FFF, 1);        {make data word with 0 start and stop bits}
  picprg_send (pr, 16, i, stat);       {send it}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_RECV14SS (PR, DAT, STAT)
*
*   Read a 16 bit data word that includes the start and stop bits, and return
*   the 14 bit data value in DAT.
}
procedure picprg_recv14ss (            {receive 14 data bits with start/stop bits}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: sys_int_conv16_t;       {the 14 data bits}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i32: sys_int_conv32_t;

begin
  picprg_recv (pr, 16, i32, stat);
  if sys_error(stat) then return;
  dat := rshft(i32, 1) & 16#3FFF;      {remove start/stop bits and align 14 bit data}
  end;
{
*******************************************************************************
*
*   Local subroutine LOADPC (PR, ADR, STAT)
*
*   Loads the address ADR into the PC of the target chip.  The LOAD PC ADDRESS
*   instruction is used, which is followed by a total of 24 bits.  The first
*   bit is 0, then 22 address bits, then another 0.
*
*   This is for the 16F183xx and similar.
}
procedure loadpc (                     {load address into the PC}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_conv32_t;       {the address}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

begin
  picprg_send (pr, 6, 2#011101, stat); {send LOAD PC ADDRESS command}
  if sys_error(stat) then return;
  picprg_send (                        {send the address in a 24 bit word}
    pr,                                {PICPRG library use state}
    24,                                {number of bits to send}
    lshft(adr & 16#3FFFFF, 1),         {the bits to send}
    stat);
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version first sets all the code protection bits.  It uses the
*   BULK ERASE SETUP 1 and 2 sequence.
}
procedure picprg_erase_16f (           {erase routine for generic 16Fxxx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;
{
*   Write 0 to the configuration word.  This sets all the code protection
*   bits.  The data memory is not erased unless the code protection bits
*   are actually changed from protected to unprotected, although this is
*   not documented in the Microchip programming spec.  You just gotta
*   know, I guess.
}
  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION, sets adr to 2000h}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send dummy data word}
  if sys_error(stat) then return;

  for i := 1 to 7 do begin             {advance the address to 2007h}
    picprg_send6 (pr, 2#000110, stat); {send INCREMENT ADDRESS command}
    if sys_error(stat) then return;
    end;

  picprg_send6 (pr, 2#000010, stat);   {LOAD DATA FOR PROGRAM MEMORY}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send data as all zeros}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#011000, stat);   {BEGIN PROGRAMMING ONLY CYCLE}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.015, stat);  {force delay before next operation}
  if sys_error(stat) then return;
{
*   All the code protection has been enabled.  Now perform the special erase
*   sequence to completely erase a code protected chip.
}
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION command}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 16#3FFF, stat); {send the data word for this command}
  if sys_error(stat) then return;

  for i := 1 to 7 do begin             {each time to increment the address}
    picprg_send6 (pr, 2#000110, stat); {send INCREMENT ADDRESS command}
    if sys_error(stat) then return;
    end;

  picprg_send6 (pr, 2#000001, stat);   {BULK ERASE SETUP 1}
  if sys_error(stat) then return;
  picprg_send6 (pr, 2#000111, stat);   {BULK ERASE SETUP 2}
  if sys_error(stat) then return;
  picprg_send6 (pr, 2#001000, stat);   {BEGIN ERASE/PROGRAMMING CYCLE}
  if sys_error(stat) then return;

  picprg_cmdw_wait (pr, 0.015, stat);  {force delay before next operation}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000001, stat);   {BULK ERASE SETUP 1}
  if sys_error(stat) then return;
  picprg_send6 (pr, 2#000111, stat);   {BULK ERASE SETUP 2}
  if sys_error(stat) then return;
{
*   Done performing special sequence to bulk erase a protected chip.  All
*   eraseable bits are now set to 1.
}
  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F62XA (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for 16F62xA devices.  Uses BULK ERASE PROGRAM MEMORY (9)
*   and BULK ERASE DATA MEMORY (11) commands.
}
procedure picprg_erase_16f62xa (       {erase routine for 16F62xA}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;
{
*   Erase the program memory.
}
  picprg_send6 (pr, 2#000000, stat);   {LOAD CONFIGURATION, sets address to 2000h}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 16#3FFF, stat); {data word of all 1s}
  if sys_error(stat) then return;
  picprg_send6 (pr, 2#001001, stat);   {BULK ERASE PROGRAM MEMORY}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.010, stat);  {force delay to wait for erase to complete}
  if sys_error(stat) then return;
{
*   Erase the data memory if there is any.
}
  if pr.id_p^.ndat > 0 then begin      {this target has data (EEPROM) memory ?}
    picprg_send6 (pr, 2#001011, stat); {BULK ERASE DATA MEMORY}
    if sys_error(stat) then return;
    picprg_cmdw_wait (pr, 0.010, stat); {force delay to wait for erase to complete}
    if sys_error(stat) then return;
    end;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F87XA (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is specific to devices that use the CHIP ERASE (63) command,
*   like the 16F87xA family.
}
procedure picprg_erase_16f87xa (       {erase routine for 16F87xA}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION command}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 16#3FFF, stat); {send the data word for this command}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#111111, stat);   {CHIP ERASE}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.010, stat);  {force delay before next operation}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F7X (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is specific to the 16F7x subfamily.  The erase is done by
*   setting the PC into the configuration space and executing the BULK ERASE
*   command (9).
}
procedure picprg_erase_16f7x (         {erase routine for 16F7x}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 0, stat);          {send LOAD CONFIGURATION command}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 16#3FFF, stat); {send the data word for this command}
  if sys_error(stat) then return;

  picprg_send6 (pr, 9, stat);          {BULK ERASE}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.030, stat);  {force delay before next operation}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F688 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for the 16F688 and related devices.  As of 19 June
*   2005 the programming algorithm for these were described in DS41204E.
}
procedure picprg_erase_16f688 (        {erase routine for 16F688 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;
{
*   Write 0 to the configuration word.  This sets all the code protection
*   bits.  The data memory is not erased unless the code protection bits
*   are actually changed from protected to unprotected.
}
  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION, sets adr to 2000h}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send dummy data word}
  if sys_error(stat) then return;

  for i := 1 to 7 do begin             {advance the address to 2007h}
    picprg_send6 (pr, 2#000110, stat); {send INCREMENT ADDRESS command}
    if sys_error(stat) then return;
    end;

  picprg_send6 (pr, 2#000010, stat);   {LOAD DATA FOR PROGRAM MEMORY}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send data as all zeros}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#001000, stat);   {BEGIN PROGRAMMING INTERNALLY TIMED}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.020, stat);  {force delay before next operation}
  if sys_error(stat) then return;
{
*   All the code protection has been enabled.  Now perform the special erase
*   sequence to completely erase a code protected chip.
}
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION command}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 16#3FFF, stat); {send the data word for this command}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#001001, stat);   {BULK ERASE PROGRAM MEMORY}
  if sys_error(stat) then return;

  picprg_cmdw_wait (pr, 0.030, stat);  {minimum wait time}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F84 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version first sets all the code protection bits.  It uses the
*   BULK ERASE SETUP 1 and 2 sequence and BEGIN ERASE PROGRAMMING CYCLE (8)
*   to write to the configuration word.
}
procedure picprg_erase_16f84 (         {erase routine for generic 16F84}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;
{
*   Write 0 to the configuration word.  This sets all the code protection
*   bits.  The data memory is not erased unless the code protection bits
*   are actually changed from protected to unprotected, although this is
*   not documented in the Microchip programming spec.  You just gotta
*   know, I guess.
}
  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION, sets adr to 2000h}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send dummy data word}
  if sys_error(stat) then return;

  for i := 1 to 7 do begin             {advance the address to 2007h}
    picprg_send6 (pr, 2#000110, stat); {send INCREMENT ADDRESS command}
    if sys_error(stat) then return;
    end;

  picprg_send6 (pr, 2#000010, stat);   {LOAD DATA FOR PROGRAM MEMORY}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send data as all zeros}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#001000, stat);   {BEGIN ERASE PROGRAMMING CYCLE}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.020, stat);  {force delay before next operation}
  if sys_error(stat) then return;
{
*   All the code protection has been enabled.  Now perform the special erase
*   sequence to completely erase a code protected chip.
}
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION command}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 16#3FFF, stat); {send the data word for this command}
  if sys_error(stat) then return;

  for i := 1 to 7 do begin             {each time to increment the address}
    picprg_send6 (pr, 2#000110, stat); {send INCREMENT ADDRESS command}
    if sys_error(stat) then return;
    end;

  picprg_send6 (pr, 2#000001, stat);   {BULK ERASE SETUP 1}
  if sys_error(stat) then return;
  picprg_send6 (pr, 2#000111, stat);   {BULK ERASE SETUP 2}
  if sys_error(stat) then return;
  picprg_send6 (pr, 2#001000, stat);   {BEGIN ERASE/PROGRAMMING CYCLE}
  if sys_error(stat) then return;

  picprg_cmdw_wait (pr, 0.015, stat);  {force delay before next operation}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000001, stat);   {BULK ERASE SETUP 1}
  if sys_error(stat) then return;
  picprg_send6 (pr, 2#000111, stat);   {BULK ERASE SETUP 2}
  if sys_error(stat) then return;
{
*   Done performing special sequence to bulk erase a protected chip.  All
*   eraseable bits are now set to 1.
}
  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F7X7 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version uses the BULK ERASE PROGRAM MEMORY (9) command.  Although
*   not specified in the 16F7x7 programming spec, the PC is in the configuration
*   space and the data bits set to 3FFFh when the bulk erase command is issued.
}
procedure picprg_erase_16f7x7 (        {erase routine for 16F7x7}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION command}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 16#3FFF, stat); {send the data word for this command}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#001001, stat);   {BULK ERASE PROGRAM MEMORY}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.030, stat);  {min 30mS required by 16F7x7}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F88X (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip except the
*   oscillator calibration word.
*
*   This version writes 0 to both config words to set all possible code
*   protection bits, moves the PC to the start of config space and loads 3FFFh,
*   then issues a BULK ERASE PROGRAM MEMORY (9) command.
}
procedure picprg_erase_16f88x (        {erase routine for 16F88x}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;
{
*   Write 0 to the configuration words.  This sets all the code protection
*   bits, which causes all of program memory and data EEPROM to be erased
*   on a bulk erase operation.
}
  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION, sets adr to 2000h}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send dummy data word}
  if sys_error(stat) then return;

  for i := 1 to 7 do begin             {advance the address to 2007h}
    picprg_send6 (pr, 2#000110, stat); {send INCREMENT ADDRESS command}
    if sys_error(stat) then return;
    end;

  picprg_send6 (pr, 2#000010, stat);   {LOAD DATA FOR PROGRAM MEMORY}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send data as all zeros}
  if sys_error(stat) then return;
  picprg_send6 (pr, 24, stat);         {BEGIN PROGRAMMING (24), externally timed}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.006, stat);  {force delay before next operation}
  if sys_error(stat) then return;
  picprg_send6 (pr, 10, stat);         {END PROGRAMMING (10)}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000110, stat);   {INCREMENT ADDRESS (6)}
  if sys_error(stat) then return;
  picprg_send6 (pr, 2#000010, stat);   {LOAD DATA FOR PROGRAM MEMORY}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send data as all zeros}
  if sys_error(stat) then return;
  picprg_send6 (pr, 24, stat);         {BEGIN PROGRAMMING (24), externally timed}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.005, stat);  {force delay before next operation}
  if sys_error(stat) then return;
  picprg_send6 (pr, 10, stat);         {END PROGRAMMING (10)}
  if sys_error(stat) then return;
{
*   All the code protection has been enabled.  Now erase the chip such as
*   to preserve the calibration value.
}
  picprg_reset (pr, stat);             {reset the target}
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION command}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 16#3FFF, stat); {send the data word for this command}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#001001, stat);   {BULK ERASE PROGRAM MEMORY (9)}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.030, stat);
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F61X (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip except the
*   oscillator calibration word.
}
procedure picprg_erase_16f61x (        {erase routine for 16F61x}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {send LOAD CONFIGURATION command}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 16#3FFF, stat); {send the data word for this command}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#001001, stat);   {BULK ERASE PROGRAM MEMORY (9)}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.010, stat);
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_WRITE_16F72X (PR, ADR, N, DAT, MASK, STAT)
*
*   Write routine for the PIC 16F72x.  This calls the generic write routine
*   except for config words.  These require special handling on for these PICs.
*   The subroutine interface is identical to PICPRG_WRITE_TARGW.
}
procedure picprg_write_16f72x (        {array write, special for 16F72x config words}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  adrlast: picprg_adr_t;               {last address to write to}
  npass: picprg_adr_t;                 {number of locations to pass to generic routine}
  a: picprg_adr_t;                     {current address to special write}
  d: picprg_dat_t;                     {scratch data word}
  m: picprg_dat_t;                     {valid bits mask}
  ac: picprg_dat_t;                    {current address}

begin
  adrlast := adr + n - 1;              {make last address to write to}
  npass := min(n, 16#2007 - adr);      {number of locations to pass to generic routine}
  if npass > 0 then begin              {can have generic routine do some of this write ?}
    picprg_write_targw (pr, adr, npass, dat, mask, stat);
    if sys_error(stat) then return;
    end;

  for a := max(16#2007, adr) to adrlast do begin {once for each special address}
    d := dat[a - adr];                 {get this data word}
    m := picprg_mask(mask, a);         {get valid bits mask for this word}
    d := d ! ~m;                       {set all unused bits to 1}
    d := d & 16#3FFF;                  {mask in only the 14 bit word}
    picprg_send6 (pr, 22, stat);       {RESET ADDRESS}
    if sys_error(stat) then return;
    picprg_send6 (pr, 0, stat);        {LOAD CONFIGURATION}
    if sys_error(stat) then return;
    picprg_send14ss (pr, d, stat);     {data word}
    if sys_error(stat) then return;
    ac := 16#2000;                     {address chip is now set to}
    while ac < a do begin              {bump the address until get to desired}
      picprg_send6 (pr, 6, stat);      {INCREMENT ADDRESS}
      if sys_error(stat) then return;
      ac := ac + 1;
      end;
    picprg_send6 (pr, 8, stat);        {BEGIN INTERNALLY TIMED PROGRAMMING}
    if sys_error(stat) then return;
    picprg_cmdw_wait (pr, 0.010, stat); {wait to make sure programming completed}
    if sys_error(stat) then return;
    picprg_cmdw_adrinv (pr, stat);     {invalidate address assumption in the programmer}
    end;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F182X (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip except the
*   calibration words.
}
procedure picprg_erase_16f182x(        {erase routine for 16F182x}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {LOAD CONFIGURATION, set adr to config region}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send dummy data word}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#01001, stat);    {BULK ERASE PROGRAM MEMORY (9)}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.010, stat);
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#01011, stat);    {BULK ERASE DATA MEMORY (11)}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.010, stat);
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_16F183XX (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip except the
*   calibration words.
*
*   Steps:
*
*     Reset
*     PC set to E800h
*     BULK ERASE MEMORY (9)
*     wait 10 ms
*     Reset
}
procedure picprg_erase_16f183xx (      {erase routine for 16F183xx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  loadpc (pr, 16#E800, stat);          {set the PC to special address for erasing all}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#01001, stat);    {BULK ERASE MEMORY (9)}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.010, stat);
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_12F1501 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip except the
*   calibration words.
*
*   This version is just like the 16F182X version except that is does not erase
*   EEPROM.  This appears to be the algorithm for the enhanced 14 bit core
*   devices that do not have EEPROM (as of June 2012).
}
procedure picprg_erase_12f1501 (       {erase enhanced 14 bit core without EEPROM}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#000000, stat);   {LOAD CONFIGURATION, set adr to config region}
  if sys_error(stat) then return;
  picprg_send14ss (pr, 0, stat);       {send dummy data word}
  if sys_error(stat) then return;

  picprg_send6 (pr, 2#01001, stat);    {BULK ERASE PROGRAM MEMORY (9)}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.010, stat);
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
