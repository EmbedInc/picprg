{   Routines that perform higher level functions on a PIC18 target chip.
}
module picprg_18;
define picprg_18_write;
define picprg_18_read;
define picprg_18_setadr;
define picprg_erase_18f;
define picprg_erase_18f2520;
define picprg_erase_18f6310;
define picprg_erase_18f2523;
define picprg_erase_18f25j10;
define picprg_erase_18f14k22;
define picprg_erase_18k80;
define picprg_write_18;
define picprg_write_18f2520;
define picprg_18_test;
define picprg_read_18d;
define picprg_write_18d;
%include 'picprg2.ins.pas';

const
  eepgd = 7;                           {number of EEPGD bit in EECON1}
  cfgs = 6;                            {number of CFGS bit in EECON1}
  wren = 2;                            {number of WREN bit in EECON1}
(*
  free = 4;                            {number of FREE bit in EECON1}
  wr = 1;                              {number of WR bit in EECON1}
*)
{
*******************************************************************************
*
*   Subroutine PICPRG_18_WRITE (PR, CMD, DATW, STAT)
*
*   Send the 4 bit command CMD to the target chip followed by the 16 bit
*   data in DATW.  This is the format of all commands that send data to
*   the chip.
}
procedure picprg_18_write (            {send command with write data to PIC18}
  in out  pr: picprg_t;                {state for this use of the library}
  in      cmd: sys_int_machine_t;      {4 bit command opcode}
  in      datw: sys_int_machine_t;     {16 bit data to write to the chip}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_send (pr, 4, cmd, stat);      {send the command opcode}
  if sys_error(stat) then return;
  picprg_send (pr, 16, datw, stat);    {send the data word}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_18_READ (PR, CMD, DATW, DATR, STAT)
*
*   Send the 4 bit command CMD to the target chip.  This is assumed to be
*   a read command, so the 8 bit data in DATW is sent, then 8 data bits
*   are read and returned in DATR.  This is the format of all commands that
*   read data from the chip, although many of them ignore the write data
*   in DATW.
}
procedure picprg_18_read (             {send command to read from PIC18}
  in out  pr: picprg_t;                {state for this use of the library}
  in      cmd: sys_int_machine_t;      {4 bit command opcode}
  in      datw: sys_int_machine_t;     {8 bit data written to chip after opcode}
  out     datr: sys_int_machine_t;     {8 bit data read from the chip}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i32: sys_int_conv32_t;               {scratch 32 bit integer}

begin
  picprg_send (pr, 4, cmd, stat);      {send the command opcode}
  if sys_error(stat) then return;
  picprg_send (pr, 8, datw, stat);     {send the write data byte}
  if sys_error(stat) then return;
  picprg_recv (pr, 8, i32, stat);      {receive the read data byte}
  datr := i32;                         {return the data read from the chip}
  end;
{
*******************************************************************************
*
*   Subroutine COREINST (PR, INSTR, STAT)
*
*   Cause the target chip CPU core to execute the instruction INSTR.
}
procedure coreinst (                   {execute instruction in CPU core}
  in out  pr: picprg_t;                {state for this use of the library}
  in      instr: int16u_t;             {instruction to execute}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_18_write (                    {write a command to the target}
    pr,                                {library state}
    0,                                 {CORE INSTRUCTION command}
    instr,                             {the instruction to execute}
    stat);
  end;
{
*******************************************************************************
*
*   Subroutine SETSFR (PR, ADR, VAL, STAT)
*
*   Set the target chip special function register at address ADR to the
*   value VAL.
}
procedure setsfr (                     {set special function register}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {address of the special function register}
  in      val: int8u_t;                {value to set the special funcion register to}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  coreinst (pr, 16#0E00 ! (val & 255), stat); {MOVLW val}
  if sys_error(stat) then return;
  coreinst (pr, 16#6E00 ! (adr & 255), stat); {MOVWF adr}
  end;
{
*******************************************************************************
*
*   Local subroutine BITCLR (PR, ADR, BIT, STAT)
*
*   Clear the bit BIT of the SFR address ADR.  ADR is assumed to be in the
*   access bank.
}
procedure bitclr (                     {clear bit of RAM byte}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {address of the special function register}
  in      bit: sys_int_machine_t;      {0-7 bit number}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

var
  inst: sys_int_machine_t;             {instruction to execute}

begin
  inst := 16#9000;                     {init BCF opcode}
  inst := inst ! lshft(bit & 7, 9);    {merge in bit number field}
  inst := inst ! (adr & 16#FF);        {merge in address within access bank}
  coreinst (pr, inst, stat);           {execute the instruction}
  end;
{
*******************************************************************************
*
*   Local subroutine BITSET (PR, ADR, BIT, STAT)
*
*   Set the bit BIT of the SFR address ADR.  ADR is assumed to be in the access
*   bank.
}
procedure bitset (                     {set bit of RAM byte}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {address of the special function register}
  in      bit: sys_int_machine_t;      {0-7 bit number}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

var
  inst: sys_int_machine_t;             {instruction to execute}

begin
  inst := 16#8000;                     {init BSF opcode}
  inst := inst ! lshft(bit & 7, 9);    {merge in bit number field}
  inst := inst ! (adr & 16#FF);        {merge in address within access bank}
  coreinst (pr, inst, stat);           {execute the instruction}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_18_SETADR (PR, ADR, STAT)
*
*   Set the TBLPTR register to the address ADR.  This effectively sets the
*   address of the next program memory read.
}
procedure picprg_18_setadr (           {set TBLPTR address register in PIC18}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_conv32_t;       {the address}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  setsfr (pr, 16#F8, rshft(adr, 16) & 255, stat);
  if sys_error(stat) then return;
  setsfr (pr, 16#F7, rshft(adr, 8) & 255, stat);
  if sys_error(stat) then return;
  setsfr (pr, 16#F6, adr & 255, stat);
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Local subroutine PICPRG_18_WPROG (PR, ADR, B, STAT)
*
*   Write the byte in the low 8 bits of B to the program memory address ADR.
*   TBLPTR is set to ADR, then a table write performed.
}
procedure picprg_18_wprog (            {write byte to program memory address}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_conv32_t;       {the address}
  in      b: sys_int_machine_t;        {value to write in low 8 bits}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

var
  wval: sys_int_machine_t;             {word value to pas to TABLE WRITE serial inst}

begin
  picprg_18_setadr (pr, adr, stat);    {set TBLPTR to the address}
  if sys_error(stat) then return;

  wval := b & 255;                     {get the byte value}
  wval := wval ! lshft(wval, 8);       {replicate into both bytes of the data word}
  picprg_18_write (pr, 2#1100, wval, stat);
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_18_ERASE_WAIT (PR, SEC, STAT)
*
*   Perform a PIC 18 timed erase cycle.  This is a NOP command with a
*   minimum delay of SEC seconds between the the 4 bit opcode and the
*   16 bit payload.
}
procedure picprg_18_erase_wait (       {do erase cycle with timed wait}
  in out  pr: picprg_t;                {state for this use of the library}
  in      sec: real;                   {minimum delay time after 4th bit}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_send (pr, 4, 0, stat);        {do 4 clock cycles into NOP}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, sec, stat);    {force minimum wait}
  if sys_error(stat) then return;
  picprg_send (pr, 16, 0, stat);       {do remaining cycles of NOP}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_18_WRITE_WAIT (PR, SHI, SLO, STAT)
*
*   Perform a PIC 18 write cycle.  This is a NOP command where PGC of the
*   the fourth clock is held high for the write time SHI, then held low for
*   the high voltage discharge time SLO, then the 16 bit payload of 0
*   is sent.
}
procedure picprg_18_write_wait (       {do write cycle with appropriate waits}
  in out  pr: picprg_t;                {state for this use of the library}
  in      shi: real;                   {PGC high time in seconds}
  in      slo: real;                   {PGC low time in seconds}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_send (pr, 3, 0, stat);        {send first 3 clock pulses as usual}
  if sys_error(stat) then return;
  picprg_cmdw_clkh (pr, stat);         {raise the clock line}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, shi, stat);    {insert wait for minimum high time}
  if sys_error(stat) then return;
  picprg_cmdw_clkl (pr, stat);         {lower clock line to end the write}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, slo, stat);    {insert wait for minimum low time}
  if sys_error(stat) then return;
  picprg_send (pr, 16, 0, stat);       {do the remaining 16 clock pulses of NOP}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_18F (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This is the generic version for 18Fxxx devices.
}
procedure picprg_erase_18f (           {erase routine for generic 18Fxxx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cfg_p: picprg_adrent_p_t;            {pointer to current config word entry}
  mask: picprg_maskdat_t;              {mask info for current config word}

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  coreinst (pr, 16#8EA6, stat);        {BSF EECON1, EEPGD}
  if sys_error(stat) then return;
  coreinst (pr, 16#8CA6, stat);        {BSF EECON1, CFGS}
  if sys_error(stat) then return;

  picprg_18_setadr (pr, 16#3C0004, stat); {set erase command address}
  if sys_error(stat) then return;
  picprg_18_write (pr, 12, 16#0080, stat); {write command to erase whole chip}
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
{
*   Read the erased state of the config bytes.  This is to work around a bug in
*   some PICs (like 18F2431) where some of the config bits are set to 0 even when
*   written to 1 after some of the code protection bits have been set.  Knowing
*   the erased state can avoid a write later to work around this bug.
}
  cfg_p := pr.id_p^.config_p;          {init to first config word in list}
  while cfg_p <> nil do begin          {once for each config word}
    picprg_mask_same (cfg_p^.mask, mask); {make mask info for this config word}
    picprg_read (                      {read this config word}
      pr, cfg_p^.adr, 1, mask, cfg_p^.val, stat);
    if sys_error(stat) then return;
    cfg_p^.kval := true;               {indicate current state is known for this cfg word}
    cfg_p := cfg_p^.next_p;            {advance to next config word}
    end;                               {back to do next config word in the list}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_18F2520 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for the 18F2520 and related.  As of 5 June 2005 there
*   were 32 PICs covered by this programming spec (DS29622E).
}
procedure picprg_erase_18f2520 (       {erase routine for 18F2520 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_18_setadr (pr, 16#3C0005, stat); {perform the chip erase sequence}
  if sys_error(stat) then return;
  picprg_18_write (pr, 2#1100, 16#FFFF, stat);
  if sys_error(stat) then return;
  picprg_18_setadr (pr, 16#3C0004, stat);
  if sys_error(stat) then return;
  picprg_18_write (pr, 2#1100, 16#8787, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_18F6310 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for the 18F6310 and related.  As of 20 Jan 2007 there are
*   eight chips of this type covered by the programmer specification DS39624B.
}
procedure picprg_erase_18f6310 (       {erase routine for 18F6310 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_18_setadr (pr, 16#3C0005, stat); {perform the chip erase sequence}
  if sys_error(stat) then return;
  picprg_18_write (pr, 2#1100, 16#018A, stat);
  if sys_error(stat) then return;
  picprg_18_setadr (pr, 16#3C0004, stat);
  if sys_error(stat) then return;
  picprg_18_write (pr, 2#1100, 16#018A, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.030, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_18F2523 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for the 18F2523 and related.  As of 22 Jan 2007 there are
*   4 chips of this type covered by the programmer specification DS39759A.
}
procedure picprg_erase_18f2523 (       {erase routine for 18F2523 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_18_setadr (pr, 16#3C0005, stat); {perform the chip erase sequence}
  if sys_error(stat) then return;
  picprg_18_write (pr, 2#1100, 16#3F3F, stat);
  if sys_error(stat) then return;
  picprg_18_setadr (pr, 16#3C0004, stat);
  if sys_error(stat) then return;
  picprg_18_write (pr, 2#1100, 16#8F8F, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_18F25J10 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for the 18F25J10 and related.  This erase procedure is
*   described in DS39687B.
}
procedure picprg_erase_18f25j10 (      {erase routine for 18F25J10 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_18_setadr (pr, 16#3C0005, stat); {perform the chip erase sequence}
  if sys_error(stat) then return;
  picprg_18_write (pr, 2#1100, 16#0101, stat);
  if sys_error(stat) then return;
  picprg_18_setadr (pr, 16#3C0004, stat);
  if sys_error(stat) then return;
  picprg_18_write (pr, 2#1100, 16#8080, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.475, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_18F14K22 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for the 18F14K22 and related.
}
procedure picprg_erase_18f14k22 (      {erase routine for 18F14k22 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;

  picprg_18_setadr (pr, 16#3C0005, stat); {perform the chip erase sequence}
  if sys_error(stat) then return;
  picprg_18_write (pr, 2#1100, 16#0F0F, stat);
  if sys_error(stat) then return;
  picprg_18_setadr (pr, 16#3C0004, stat);
  if sys_error(stat) then return;
  picprg_18_write (pr, 2#1100, 16#8F8F, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.015, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_18K80 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for the 18FxxK80 and related.
}
procedure picprg_erase_18k80 (         {erase routine for 18FxxK80}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset target to put it into known state}
  if sys_error(stat) then return;

  picprg_cmdw_writing (pr, stat);      {indicate the target is being written to}
  if sys_error(stat) then return;
{
*   Erase config bits.
}
  picprg_18_wprog (pr, 16#3C0004, 16#02, stat); {3C0006h:3C0004h <-- 800002h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#00, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Erase boot block.
}
  picprg_18_wprog (pr, 16#3C0004, 16#05, stat); {3C0006h:3C0004h <-- 800005h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#00, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Erase code block 0.
}
  picprg_18_wprog (pr, 16#3C0004, 16#04, stat); {3C0006h:3C0004h <-- 800104h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#01, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Erase code block 1.
}
  picprg_18_wprog (pr, 16#3C0004, 16#04, stat); {3C0006h:3C0004h <-- 800204h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#02, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Erase code block 2.
}
  picprg_18_wprog (pr, 16#3C0004, 16#04, stat); {3C0006h:3C0004h <-- 800404h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#04, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Erase code block 3.
}
  picprg_18_wprog (pr, 16#3C0004, 16#04, stat); {3C0006h:3C0004h <-- 800804h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#08, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Erase code block 4.
}
  picprg_18_wprog (pr, 16#3C0004, 16#04, stat); {3C0006h:3C0004h <-- 801004h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#10, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Erase code block 5.
}
  picprg_18_wprog (pr, 16#3C0004, 16#04, stat); {3C0006h:3C0004h <-- 802004h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#20, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Erase code block 6.
}
  picprg_18_wprog (pr, 16#3C0004, 16#04, stat); {3C0006h:3C0004h <-- 804004h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#40, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Erase code block 7.
}
  picprg_18_wprog (pr, 16#3C0004, 16#04, stat); {3C0006h:3C0004h <-- 808004h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#80, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Erase user ID locations.
}
  picprg_18_wprog (pr, 16#3C0004, 16#08, stat); {3C0006h:3C0004h <-- 800008h}
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0005, 16#00, stat);
  if sys_error(stat) then return;
  picprg_18_wprog (pr, 16#3C0006, 16#80, stat);
  if sys_error(stat) then return;

  coreinst (pr, 0, stat);              {execute NOP instruction}
  if sys_error(stat) then return;
  picprg_18_erase_wait (pr, 0.010, stat); {send the NOP with special stretched timing}
  if sys_error(stat) then return;
{
*   Reset the target and leave it ready for use.
}
  picprg_reset (pr, stat);             {reset target to guaranteed known state}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_WRITE_18 (PR, ADR, N, DAT, MASK, STAT)
*
*   Write an array of N values to consecutive target chip locations starting
*   at the address ADR.  DAT is the array of input values.  MASK describes
*   the valid bits within each data word of DAT.
*
*   The library must have previously been configured to this target chip,
*   and the chip must be enabled for programming (Vpp on and Vdd set to
*   normal).  The locations should also have not been programmed since
*   last erased.  This routine does not perform an erase before write
*   cycle on each word.  It assumes that the entire chip has been bulk
*   erased.  An actual write may be avoided when the data value for a word
*   matches the erased value, which is all implemented bits 1.  MASK is
*   used to determine which bits are implemented.
*
*   This is a low level routine that does not check whether the address
*   range is valid for this target.  The write operations are performed
*   as requested but not verified.
*
*   This version of the array write routine is specific to the PIC18
*   family.  It performs "single panel" writes, 8 bytes at a time.
*   If DAT does not completely cover an 8 byte region, then the erased
*   value (FFh) is substituted for the unspecified bytes.
*
*   A different write algorithm is required for the configuration bits.
*   It is an error if this routine is called with an address range that
*   includes both configuration and non-configuration locations.
}
procedure picprg_write_18 (            {array write for program space of PIC18 parts}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  config_start_k = 16#300000;          {start of config bits range}
  config_end_k = 16#310000;            {first address past config bits range}

var
  ovl: picprg_cmdovl_t;                {overlapped commands control state}
  cmd_p: picprg_cmd_p_t;               {pointer to current command descriptor}
  buf: picprg_pandat8_t;               {8 data bytes to write at a time}
  adrl: picprg_adr_t;                  {last address for which data is available}
  adrb: picprg_adr_t;                  {start address for the current write buffer}
  a: picprg_adr_t;                     {scratch address}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  d: picprg_dat_t;                     {one data word}
  blank: boolean;                      {all bytes in buffer set to erased value}
  adrcurr: boolean;                    {target address is current}
  b: int8u_t;                          {scratch data byte}
  m: int8u_t;                          {mask for valid data byte bits}
  mr: int8u_t;                         {reverse mask, for invalid data byte bits}

label
  config_bits;

begin
  if n <= 0 then begin                 {nothing to write ?}
    sys_error_none (stat);             {indicate no error}
    return;
    end;
  picprg_cmdovl_init (ovl);            {init overlapped commands control state}
{
*   Configure for single panel writes.
}
  coreinst (pr, 16#8EA6, stat);        {BSF     EECON1, EEPGD}
  if sys_error(stat) then return;
  coreinst (pr, 16#8CA6, stat);        {BSF     EECON1, CFGS}
  if sys_error(stat) then return;
  coreinst (pr, 16#86A6, stat);        {BSF     EECON1, WREN}
  if sys_error(stat) then return;

  picprg_18_setadr (pr, 16#3C0006, stat); {set address to write to}
  if sys_error(stat) then return;
  case pr.id_p^.fam of                 {different code for some PIC types}
picprg_picfam_18f_k: i := 2#1100;      {18F252 and related}
picprg_picfam_18f6680_k: i := 0;       {18F6680 and related}
otherwise
    sys_stat_set (picprg_subsys_k, picprg_stat_unkfamrt_k, stat);
    sys_stat_parm_int (ord(pr.id_p^.fam), stat);
    sys_stat_parm_str ('PICPRG_WRITE_18', stat);
    return;
    end;
  picprg_18_write (pr, i, 0, stat);    {set up for single panel writes}
  if sys_error(stat) then return;

  picprg_cmdovl_outw (pr, ovl, cmd_p, stat); {get new command descriptor}
  if sys_error(stat) then return;
  picprg_cmd_adrinv (pr, cmd_p^, stat); {assumed target address is now invalid}
  if sys_error(stat) then return;

  if (adr >= config_start_k) and (adr < config_end_k) {writing configuation bits ?}
    then goto config_bits;

  coreinst (pr, 16#9CA6, stat);        {BCF     EECON1, CFGS}
  if sys_error(stat) then return;

  adrl := adr + n - 1;                 {last address with data in DAT}
  a := adr & ~7;                       {make starting address for first buffer}
  picprg_cmdovl_outw (pr, ovl, cmd_p, stat); {get new command descriptor}
  if sys_error(stat) then return;
  picprg_cmd_adr (pr, cmd_p^, a, stat); {set starting address}
  if sys_error(stat) then return;
  adrcurr := true;                     {indicate the target address is current}
{
*   The target has been set up for single panel writes.  "A" is the start
*   address of the first buffer, and ADRL is address of the last data byte.
*   The target address has been set to the start of the first buffer.
}
  while a <= adrl do begin             {do buffers until used up all input data}
    adrb := a;                         {set start address for this buffer}
    blank := true;                     {init to all buffer data is erased value}
    for i := 0 to 7 do begin           {once for each byte in this buffer}
      m := picprg_mask (mask, adrb + i); {mask for valid bits this byte}
      mr := ~m;                        {mask for unused bits this byte}
      if (a >= adr) and (a <= adrl)    {check address within DAT range}
        then begin                     {data was passed in for this byte}
          b := dat[a - adr] ! mr;      {fetch byte with unused bits set to 1}
          buf[i] := b;                 {stuff this byte into the write buffer}
          blank := blank and ((b & m) = m); {leave BLANK set if byte is erased value}
          end
        else begin                     {no data was passed in for this byte}
          buf[i] := 16#FF;             {stuff erased value for this byte}
          end
        ;
      a := a + 1;                      {update address for next byte}
      end;                             {back to set next byte in this write buffer}
    if blank
      then begin                       {the whole buffer is set to erased value}
        adrcurr := false;              {indicate target address no longer current}
        end
      else begin                       {buffer not all erased, must do the write}
        if not adrcurr then begin      {target address not current ?}
          picprg_cmdovl_outw (pr, ovl, cmd_p, stat); {get new command descriptor}
          if sys_error(stat) then return;
          picprg_cmd_adr (pr, cmd_p^, adrb, stat); {set adr to this buf start}
          if sys_error(stat) then return;
          adrcurr := true;             {target address is now current}
          end;
        picprg_cmdovl_outw (pr, ovl, cmd_p, stat); {get new command descriptor}
        if sys_error(stat) then return;
        picprg_cmd_pan18 (pr, cmd_p^, buf, stat); {write this buffer}
        if sys_error(stat) then return;
        end
      ;
    end;                               {back to write next buffer full}

  picprg_cmdovl_flush (pr, ovl, stat); {wait for all outstanding commands to finish}
  return;
{
*   The address range starts in the configuration bits region.  Writing the
*   configuration bits requires a different algorithm than writing other
*   program memory locations.
}
config_bits:
  if (adr + n) > config_end_k then begin {end address not in config range ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cfgmix_k, stat);
    return;
    end;

  picprg_cmdovl_flush (pr, ovl, stat); {wait for all overlapped commands to complete}
  if sys_error(stat) then return;
  coreinst (pr, 16#8EA6, stat);        {BSF     EECON1, EEPGD}
  if sys_error(stat) then return;
  coreinst (pr, 16#8CA6, stat);        {BSF     EECON1, CFGS}
  if sys_error(stat) then return;

  for i := 0 to n-1 do begin           {once for each byte to write}
    a := adr + i;                      {make address of this byte}
    m := picprg_mask (mask, a);        {mask for valid bits this byte}
    mr := ~m;                          {mask for unused bits this byte}
    picprg_18_setadr (pr, a, stat);    {set TBLPTR to the target address}
    if sys_error(stat) then return;
    d := (dat[i] ! mr) & 255;          {set data word assuming even address}
    if odd(a) then begin               {really at an odd address ?}
      d := lshft(d, 8);                {move data byte into position for odd address}
      end;
    picprg_18_write (pr, 2#1111, d, stat); {start the write}
    if sys_error(stat) then return;

    picprg_send (pr, 3, 0, stat);      {send first 3 clock pulses as usual}
    if sys_error(stat) then return;
    picprg_cmdw_clkh (pr, stat);       {raise the clock line}
    if sys_error(stat) then return;
    picprg_cmdw_wait (pr, 0.001, stat); {guarantee wait for the 1mS write time}
    if sys_error(stat) then return;
    picprg_cmdw_clkl (pr, stat);       {lower clock line to end the write}
    if sys_error(stat) then return;
    picprg_send (pr, 16, 0, stat);     {do the remaining 16 clock pulses of NOP}
    if sys_error(stat) then return;
    end;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_WRITE_18f2520 (PR, ADR, N, DAT, MASK, STAT)
*
*   This subroutine is unique to the 18F2520 and related PICs.  As of 25
*   June 2005 the programming specification was described in DS39622E.
}
procedure picprg_write_18f2520 (       {array write for 18F2520 family}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  bufmax_k = 256;                      {max supported write buffer size}
  buflast_k = bufmax_k - 1;            {last valid write buffer index}

type
  setup_k_t = (                        {the different target chip setup types}
    setup_none_k,                      {target chip is no set up}
    setup_prog_k,                      {program memory}
    setup_id_k,                        {user ID locations}
    setup_config_k,                    {chip configuration bits}
    setup_eeprom_k);                   {data EEPROM}

var
  ovl: picprg_cmdovl_t;                {state for managing overlapped commands}
  d: picprg_dat_t;                     {scratch data word}
  a: picprg_adr_t;                     {current address}
  adrlast: picprg_adr_t;               {address of last word in DAT}
  mv: picprg_dat_t;                    {mask of valid bits for this word}
  wbuf: array[0 .. buflast_k] of picprg_dat_t; {local copy of write buffer}
  out_p: picprg_cmd_p_t;               {pointer to current command for output}
  wbsz: sys_int_machine_t;             {write buffer size in use}
  npan: sys_int_machine_t;             {number of 8 byte panels in write buffer}
  p: sys_int_machine_t;                {0-N panel number within write buffer}
  abst, aben: picprg_adr_t;            {start and end addresses of write buffer}
  cset: setup_k_t;                     {current target chip setup}
  nset: setup_k_t;                     {new required target chip setup}
  i: sys_int_machine_t;                {scratch integers and loop counter}
  tadr: picprg_adr_t;                  {current target chip address}
  adrset: boolean;                     {target chip address is set for next write}
  z: boolean;                          {at least one zero data bit in write buf}

label
  have_nset, next_adr;

begin
  sys_error_none(stat);                {init to no error encountered}
  picprg_cmdovl_init (ovl);            {init overlapped commands state}
  adrset := false;                     {init to target address is not set}
  tadr := 0;                           {init target chip address (but still invalid)}
  adrlast := adr + n - 1;              {address for last word in DAT}
  cset := setup_none_k;                {init to target chip not set up}

  a := adr;                            {init current address to first word in DAT}
  while a <= adrlast do begin          {keep looping until all words in DAT used}
{
*   Determine the setup required for writing to address A, and make sure
*   the target chip is set up accordingly.
}
    if pr.space = picprg_space_data_k then begin {data EEPROM ?}
      nset := setup_eeprom_k;
      goto have_nset;
      end;
    if (a >= 0) and (a < 16#200000) then begin {normal program memory ?}
      nset := setup_prog_k;
      goto have_nset;
      end;
    if (a >= 16#200000) and (a < 16#300000) then begin {user ID locations ?}
      nset := setup_id_k;
      goto have_nset;
      end;
    nset := setup_config_k;            {assume anything else is config bits}
have_nset:                             {NSET is set to desired setup}
    if cset <> nset then begin         {setup needs to change ?}
      case nset of                     {switch to which setup ?}
setup_prog_k: begin                    {set up for program memory}
  picprg_cmdovl_flush (pr, ovl, stat); {make sure all overlapped commands done}
  if sys_error(stat) then return;
  bitset (pr, pr.id_p^.eecon1, eepgd, stat); {BSF EECON1, EEPGD}
  if sys_error(stat) then return;
  bitclr (pr, pr.id_p^.eecon1, cfgs, stat); {BCF EECON1, CFGS}
  if sys_error(stat) then return;
  bitclr (pr, pr.id_p^.eecon1, wren, stat); {BCF EECON1, WREN}
  if sys_error(stat) then return;
  wbsz := pr.id_p^.wbufsz;             {fully use the target's write buffer}
  end;
setup_id_k: begin                      {user ID locations}
  picprg_cmdovl_flush (pr, ovl, stat); {make sure all overlapped commands done}
  if sys_error(stat) then return;
  bitset (pr, pr.id_p^.eecon1, eepgd, stat); {BSF EECON1, EEPGD}
  if sys_error(stat) then return;
  bitclr (pr, pr.id_p^.eecon1, cfgs, stat); {BCF EECON1, CFGS}
  if sys_error(stat) then return;
  bitclr (pr, pr.id_p^.eecon1, wren, stat); {BCF EECON1, WREN}
  if sys_error(stat) then return;
  wbsz := 8;                           {always write 8 bytes at a time}
  picprg_cmdw_adrinv (pr, stat);       {target address will be manipulated directly}
  if sys_error(stat) then return;
  end;
setup_config_k: begin                  {config bits}
  picprg_cmdovl_flush (pr, ovl, stat); {make sure all overlapped commands done}
  if sys_error(stat) then return;
  bitset (pr, pr.id_p^.eecon1, eepgd, stat); {BSF EECON1, EEPGD}
  if sys_error(stat) then return;
  bitset (pr, pr.id_p^.eecon1, cfgs, stat); {BSF EECON1, CFGS}
  if sys_error(stat) then return;
  bitclr (pr, pr.id_p^.eecon1, wren, stat); {BCF EECON1, WREN}
  if sys_error(stat) then return;
  wbsz := 1;                           {all bytes written individually}
  picprg_cmdw_adrinv (pr, stat);       {target address will be manipulated directly}
  if sys_error(stat) then return;
  end;
setup_eeprom_k: begin                  {data EEPROM}
  picprg_cmdovl_flush (pr, ovl, stat); {make sure all overlapped commands done}
  if sys_error(stat) then return;
  bitclr (pr, pr.id_p^.eecon1, eepgd, stat); {BCF EECON1, EEPGD}
  if sys_error(stat) then return;
  bitclr (pr, pr.id_p^.eecon1, cfgs, stat); {BCF EECON1, CFGS}
  if sys_error(stat) then return;
  bitset (pr, pr.id_p^.eecon1, wren, stat); {BSF EECON1, WREN}
  if sys_error(stat) then return;
  wbsz := 1;                           {all bytes written individually}
  end;
otherwise
        writeln ('INTERNAL ERROR: Unexpected NSET value in PICPRG_WRITE_18F2520.');
        sys_bomb;
        end;
      cset := nset;                    {update current setup ID}
      if wbsz > bufmax_k then begin    {write buffer larger than supported here ?}
        sys_stat_set (picprg_subsys_k, picprg_stat_wbufbig_k, stat);
        sys_stat_parm_int (wbsz, stat);
        sys_stat_parm_str ('PICPRG_WRITE_TARGW', stat);
        return;
        end;
      npan := wbsz div 8;              {make number of 8 byte panels in write buf}
      if (wbsz <> 1) and (npan * 8 <> wbsz) then begin
        sys_stat_set (picprg_subsys_k, picprg_stat_wbufn8_k, stat);
        sys_stat_parm_int (wbsz, stat);
        return;
        end;
      adrset := false;                 {invalidate target address on setup change}
      end;                             {done switching to a new target setup}
{
*   The target chip is set up for the type of write associated with address
*   A.
}
    i := a div wbsz;                   {make number of write buffer chunks}
    abst := i * wbsz;                  {this write buffer chunk start address}
    aben := abst + wbsz - 1;           {this write buffer chunk end address}
{
*   Fill in local copy of the write buffer with the appropriate data words.
*   The Z flag will be set if one or more valid data bits are zero.
}
    z := false;                        {init to no zero data bits}
    for a := abst to aben do begin     {once for each adr covered by this write buf}
      mv := picprg_mask (mask, a);     {get mask of valid bits for this word}
      if (a >= adr) and (a <= adrlast)
        then begin                     {data for this address is in DAT}
          d := dat[a - adr];           {fetch data word from DAT array}
          d := d ! ~mv;                {set all unused bits to the erased value}
          z := z or ((d & mv) <> mv);  {set Z on any valid data bits zero}
          end
        else begin                     {address is outside DAT array range}
          d := ~0;                     {set all bits to 1}
          end
        ;
      wbuf[a - abst] := d;             {save this data value in local write buffer}
      end;                             {back to get next write buffer word}
{
*   Don't bother doing the write if no bits will be set to zero and this is
*   the erased value.  All but some of the config bits erase to 1, so config
*   write are always performed.
}
    if (not z) and (cset <> setup_config_k) then begin
      goto next_adr;                   {skip the actual write}
      end;
{
*   A write will be performed.  Make sure the target address is correct.
}
    if (not adrset) or (tadr <> abst) then begin {need to set target chip address ?}
      picprg_cmdovl_outw (pr, ovl, out_p, stat); {make command descriptor available}
      if sys_error(stat) then return;
      picprg_cmd_adr (pr, out_p^, abst, stat); {set target to write buf start adr}
      if sys_error(stat) then return;
      adrset := true;
      end;

    case cset of                       {what setup is in use ?}
{
*   Writing to normal program memory or EEPROM.  High level WRITE or WRITE8
*   commands can be used.
}
setup_prog_k,                          {ordinary program memory}
setup_eeprom_k: begin                  {data EEPROM}
  if wbsz = 1
    then begin                         {single word write}
      picprg_cmdovl_outw (pr, ovl, out_p, stat); {make command descriptor available}
      if sys_error(stat) then return;
      picprg_cmd_write (pr, out_p^, wbuf[0], stat);
      if sys_error(stat) then return;
      end
    else begin                         {multiples of 8 byte panels}
      for p := 0 to npan-1 do begin    {once for each panel of 8 bytes to write}
        picprg_write8b (pr, ovl, wbuf[p * 8], stat);
        if sys_error(stat) then return;
        end;
      end
    ;
  tadr := aben + 1;                    {update local copy of target chip curr adr}
  end;
{
*   Writing to user ID locations.  A write buffer size of 8 is used regardless
*   of the normal value for this target.  WBSZ is set to 8 to reflect this.
}
setup_id_k: begin                      {writing user ID locations}
  picprg_cmdovl_flush (pr, ovl, stat); {make sure all overlapped commands done}
  if sys_error(stat) then return;
  picprg_18_setadr (pr, abst, stat);   {set address to start of write buffer}
  if sys_error(stat) then return;
  d := (wbuf[0] & 255) ! lshft(wbuf[1] & 255, 8); {bytes 0 and 1}
  picprg_18_write (pr, 2#1101, d, stat);
  if sys_error(stat) then return;
  d := (wbuf[2] & 255) ! lshft(wbuf[3] & 255, 8); {bytes 2 and 3}
  picprg_18_write (pr, 2#1101, d, stat);
  if sys_error(stat) then return;
  d := (wbuf[4] & 255) ! lshft(wbuf[5] & 255, 8); {bytes 4 and 5}
  picprg_18_write (pr, 2#1101, d, stat);
  if sys_error(stat) then return;
  d := (wbuf[6] & 255) ! lshft(wbuf[7] & 255, 8); {bytes 6 and 7}
  picprg_18_write (pr, 2#1111, d, stat);
  if sys_error(stat) then return;
  picprg_18_write_wait (pr, pr.id_p^.tprogp, 0.0001, stat); {do the write cycle}
  if sys_error(stat) then return;
  tadr := aben;                        {update local copy of target chip address}
  end;
{
*   Writing to config locations.  These are written a byte at a time, so
*   WBSZ is 1.  The address must be set separtely for each write.  The
*   data byte is sent in the low half of the 16 bit payload for even
*   addresses and in the upper half for odd addresses.
}
setup_config_k: begin                  {writing ID locations}
  picprg_cmdovl_flush (pr, ovl, stat); {make sure all overlapped commands done}
  if sys_error(stat) then return;
  picprg_18_setadr (pr, abst, stat);   {set target address for this data byte}
  if sys_error(stat) then return;
  if odd(abst)
    then begin                         {writing byte at odd address}
      d := lshft(wbuf[0] & 255, 8) ! 16#FF;
      end
    else begin                         {writing byte at even address}
      d := 16#FF00 ! wbuf[0];
      end
    ;
  picprg_18_write (pr, 2#1111, d, stat); {issue the write command}
  if sys_error(stat) then return;
  picprg_18_write_wait (pr, 0.010, 0.001, stat); {do the write cycle}
  if sys_error(stat) then return;
  tadr := abst;                        {update local copy of target chip address}
  end;

otherwise                              {unexpected current setup ID}
      writeln ('INTERNAL ERROR: Unexpected CSET value of ', ord(cset),
        ' in PICPRG_WRITE_18F2520.');
      sys_bomb;
      end;                             {end of current setup type cases}

next_adr:                              {advance to the next address}
    a := aben + 1;                     {start next loop right after this write buf}
    end;                               {back to write next chunk containing adr A}
{
*   Done with all the writes.
}
  picprg_cmdovl_flush (pr, ovl, stat); {wait for all pending commands to complete}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_WRITE_18D (PR, ADR, N, DAT, MASK, STAT)
*
*   Specialized array write routine for writing to the data EEPROM of a
*   PIC18.
}
procedure picprg_write_18d (           {array write for data space of PIC18 parts}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ofs: picprg_adr_t;                   {offset from start of data array}
  m: picprg_dat_t;                     {mask of valid bits of data word}
  d: picprg_dat_t;                     {data word for current location}
  a: picprg_adr_t;                     {current address}

begin
{
*   Set up for accessing the EEPROM.
}
  coreinst (pr, 16#9EA6, stat);        {BCF     EECON1, EEPGD}
  if sys_error(stat) then return;
  coreinst (pr, 16#9CA6, stat);        {BCF     EECON1, CFGS}
  if sys_error(stat) then return;
{
*   Loop thru each byte to write.
}
  for ofs := 0 to n-1 do begin         {once for each data byte}
    a := adr + ofs;                    {address of this data word}
    m := picprg_mask (mask, a);        {make mask of used bits}
    d := dat[ofs];                     {get data value for this location}
    d := d ! ~m;                       {set all unused bits to 1}
    if (ofs & 15) = 0 then begin       {once every few bytes}
      picprg_cmdw_writing (pr, stat);  {indicate the target is being written to}
      if sys_error(stat) then return;
      end;
    setsfr (pr, 16#A9, a, stat);       {write low address byte to EEADR}
    if sys_error(stat) then return;
    setsfr (pr, 16#AA, rshft(a, 8), stat); {write high address byte to EEADRH}
    if sys_error(stat) then return;
    setsfr (pr, 16#A8, d, stat);       {write the data value to EEDATA}
    if sys_error(stat) then return;
    coreinst (pr, 16#84A6, stat);      {BSF     EECON1, WREN}
    if sys_error(stat) then return;
    setsfr (pr, 16#A7, 16#55, stat);   {write 55h to EECON2}
    if sys_error(stat) then return;
    setsfr (pr, 16#A7, 16#AA, stat);   {write AAh to EECON2}
    if sys_error(stat) then return;
    coreinst (pr, 16#82A6, stat);      {BSF     EECON1, WR ;start the write}
    if sys_error(stat) then return;
    coreinst (pr, 0, stat);            {execute NOP instruction}
    if sys_error(stat) then return;
    picprg_send (pr, 4, 0, stat);      {do 4 clock cycles into another NOP}
    if sys_error(stat) then return;
    picprg_cmdw_wait (pr, pr.id_p^.tprogd, stat); {force wait before next operation}
    if sys_error(stat) then return;
    picprg_send (pr, 16, 0, stat);     {do remaining cycles of NOP}
    if sys_error(stat) then return;
    coreinst (pr, 16#94A6, stat);      {BCF     EECON1, WREN}
    if sys_error(stat) then return;
    end;                               {back for next location to write}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_READ_18D (PR, ADR, N, MASK, DAT, STAT)
*
*   Array read routine for reading from 18xxx devices in data space.
}
procedure picprg_read_18d (            {read routine for 18xxx data space}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to read from}
  in      n: picprg_adr_t;             {number of locations to read from}
  in      mask: picprg_maskdat_t;      {mask for valid data bits}
  out     dat: univ picprg_datar_t;    {the returned data array, unused bits 0}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ofs: picprg_adr_t;                   {offset from start of data array}
  a: sys_int_machine_t;                {address}
  d: sys_int_machine_t;                {scratch data value}

begin
{
*   Set up for accessing the EEPROM.
}
  coreinst (pr, 16#9EA6, stat);        {BCF     EECON1, EEPGD}
  if sys_error(stat) then return;
  coreinst (pr, 16#9CA6, stat);        {BCF     EECON1, CFGS}
  if sys_error(stat) then return;
{
*   Loop thru each byte to read.
}
  for ofs := 0 to n-1 do begin         {once for each data byte}
    a := adr + ofs;                    {address of this byte}
    setsfr (pr, 16#A9, a, stat);       {set address low byte}
    if sys_error(stat) then return;
    setsfr (pr, 16#AA, rshft(a, 8), stat); {set address high byte}
    if sys_error(stat) then return;
    coreinst (pr, 16#80A6, stat);      {BSF     EECON1, RD}
    if sys_error(stat) then return;
    coreinst (pr, 16#50A8, stat);      {MOVF    EEDATA, W, 0}
    if sys_error(stat) then return;
    coreinst (pr, 16#6EF5, stat);      {MOVWF   TABLAT}
    if sys_error(stat) then return;
    coreinst (pr, 0, stat);            {NOP}
    if sys_error(stat) then return;
    picprg_18_read (pr, 2#0010, 0, d, stat); {read TABLAT register}
    if sys_error(stat) then return;
    dat[ofs] := picprg_maskit(d, mask, a); {stuff byte into return array}
    end;                               {back for next location to read}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_18_TEST (PR, STAT)
*
*   Perform a test.  This routine is intended to be rewritten as needed.
*   It is not intended for normal operation.
}
procedure picprg_18_test (             {test a PIC18 algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  tk: string_var32_t;                  {scratch token}

begin
  tk.max := size_char(tk.str);         {init local var string}

  picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
  if sys_error(stat) then return;

  while true do begin
    picprg_cmdw_reset (pr, stat);
    if sys_error(stat) then return;
    end;

(*
  while true do begin
    picprg_cmdw_reset (pr, stat);
    if sys_error(stat) then return;

    for i := 1 to 8 do begin
      picprg_cmdw_clkh (pr, stat);
      if sys_error(stat) then return;
      picprg_cmdw_clkl (pr, stat);
      if sys_error(stat) then return;
      end;
    end;
*)
  end;
