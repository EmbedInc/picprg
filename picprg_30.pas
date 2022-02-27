{   Routines specific to the PIC30F (dsPIC) target chip type.
}
module picprg_30;
define picprg_30_xinst;
define picprg_30_getvisi;
define picprg_30_setreg;
define picprg_30_wram;
define picprg_30_goto100;
define picprg_erase_30;
define picprg_erase_24;
define picprg_erase_24f;
define picprg_erase_24fj;
define picprg_erase_33ep;
define picprg_write_30pgm;
%include 'picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_30_XINST (PR, INST, STAT)
*
*   Cause the PIC30 target to execute the instruction INST.
}
procedure picprg_30_xinst (            {execute instruction on 30F target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      inst: sys_int_conv24_t;      {opcode of instruction to execute}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_send (                        {send SIX instruction and 24 bit opcode}
    pr,                                {PICPRG library use state}
    28,                                {number of bits to send}
    lshft(inst & 16#FFFFFF, 4),        {SIX followed by 24 bit instruction}
    stat);
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_30_GETVISI (PR, VISI, STAT)
*
*   Get the contents of the PIC30 target chip VISI register into VISI.
}
procedure picprg_30_getvisi (          {read contents of PIC30 VISI register}
  in out  pr: picprg_t;                {state for this use of the library}
  out     visi: sys_int_conv16_t;      {returned VISI register contents}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i32: sys_int_conv32_t;

begin
  picprg_send (pr, 12, 1, stat);       {send REGOUT instruction plus 8 clocks}
  if sys_error(stat) then return;
  picprg_recv (pr, 16, i32, stat);     {get the readback data into VISI}
  visi := i32;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_30_SETREG (PR, K, W, STAT)
*
*   Cause the PIC30 target chip to execute an instruction to load the value
*   K into W register W.  W must be in the range of 0-15.
}
procedure picprg_30_setreg (           {set a PIC30 W register to a constant}
  in out  pr: picprg_t;                {state for this use of the library}
  in      k: sys_int_conv16_t;         {value to load into the W register}
  in      w: sys_int_machine_t;        {0-15 W register number}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_30_xinst (
    pr,                                {state for this use of the library}
    16#200000 ! lshft((k & 16#FFFF), 4) ! (w & 15), {MOV #K, Wn}
    stat);
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_30_WRAM (PR, W, ADR, STAT)
*
*   Write the W register W to the RAM address ADR.
}
procedure picprg_30_wram (             {write W register to RAM}
  in out  pr: picprg_t;                {state for this use of the library}
  in      w: sys_int_machine_t;        {0-15 W register number}
  in      adr: sys_int_machine_t;      {RAM address to write the register to}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_30_xinst (
    pr,                                {state for this use of the library}
    16#880000 ! lshft(adr & 16#FFFE, 3) ! (w & 15), {mov wN, adr}
    stat);
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_30_GOTO100 (PR, STAT)
*
*   Force the PIC30 target chip program counter to location 100h.  This is
*   the start of normal executable memory.  The PC must be at a valid address
*   when executing instructions via the programming interface, even though
*   the instruction at the PC address is not used.  The PC advances with
*   every instruction executed.  It must therefore be periodically reset
*   to 100h to ensure it points to valid executable program memory.
*
*   There is no need to call this routine with firmware that supports spec
*   version 25 or later.  The internal dsPIC instruction execution routine
*   in the firmware has always automatically inserted the NOP, NOP, GOTO 100h,
*   NOP sequence every 256 instructions.  Previous to spec level 25 the reset
*   algorithm in the firmware initialize the state so that the next attempt
*   to send a executable instruction to the target would cause the GOTO
*   sequence to be automatically inserted.  Starting at spec level 25, the first
*   GOTO sequence is sent by the reset algorithm and the state is set up so that
*   the next will be automatically inserted 256 instructions later.
}
procedure picprg_30_goto100 (          {force PIC30 program counter to 100h}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#040100, stat); {goto 0x100}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_30_GOTO200 (PR, STAT)
*
*   Same as PICPRG_30_GOTO100 except the PC is set to 200h instead of 100h.
*   This is required by 24H and 33F parts, whereas 30F parts use GOTO 100h.
}
procedure picprg_30_goto200 (          {force program counter to 200h}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#040200, stat); {goto 0x200}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {second word of GOTO instruction}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_30 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This is the generic version for dsPIC devices.
}
procedure picprg_erase_30 (            {erase routine for generic dsPIC}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}

begin
{
*   Reset the target chip.
}
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  if pr.fwinfo.cvhi < 25 then begin    {need to manually add initial GOTO 100h ?}
    picprg_30_goto100 (pr, stat);
    if sys_error(stat) then return;
    end;
  picprg_cmdw_writing (pr, stat);      {indicate target memory is being changed}
  if sys_error(stat) then return;
{
*   dsPIC register usage:
*
*     W0  - Scratch data value.
*
*     W1  - Constant 55h, for Nvmkey unlock sequence.
*
*     W2  - Constant AAh, for Nvmkey unlock sequence.
*
*     W3  - Constant FFFFh, data value to write to config registers.
*
*     W4  - NVMCON code value.
*
*     W5  - High word of program memory address.
*
*     W14 - Low 16 bits of prograrm memory address.
*
*   Load the static constants into the target registers.
}
  picprg_30_setreg (pr, 16#55, 1, stat); {mov #0x55, w1}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 16#AA, 2, stat); {mov #0xAA, w2}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 16#FFFF, 3, stat); {mov #0xFFFF, w3}
  if sys_error(stat) then return;
{
*   Do a bulk erase.  This erases normal code memory, executive code memory,
*   data EEPROM, and the code protection bits.  It does not erase the
*   configuration words except the code protection bits.
}
  picprg_30_setreg (pr, 16#407F, 0, stat); {mov #0x407F, w0}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#883B00, stat); {mov w0, Nvmcon}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#883B31, stat); {mov w1, Nvmkey ;write 55h unlock}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#883B32, stat); {mov w2, Nvmkey ;write AAh unlock}
  if sys_error(stat) then return;

  picprg_30_xinst (pr, 16#A8E761, stat); {bset Nvmcon, #Wr ;start the erase}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;

  picprg_cmdw_wait (pr, 0.002, stat);  {wait for the erase to complete}
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate target memory is being changed}
  if sys_error(stat) then return;

  picprg_30_xinst (pr, 16#A9E761, stat); {bclr Nvmcon, #Wr ;end the erase}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
{
*   Erase the configuration words.  These are at the even addresses
*   F80000 - F8000E.
}
  picprg_30_setreg (pr, 16#4008, 4, stat); {load NVMCON opcode into W4}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 16#F8, 5, stat); {mov #0xF8, w5 ;set high word of mem adr}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 0, 14, stat);  {mov #0, w14; init low word of mem adr}
  if sys_error(stat) then return;
  picprg_30_goto100 (pr, stat);        {set target PC to 100h}
  if sys_error(stat) then return;

  for i := 0 to 7 do begin             {once for each config register to clear}
    picprg_30_xinst (pr, 16#880195, stat); {mov w5, Tblpag}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;

    picprg_30_xinst (pr, 16#883B04, stat); {mov w4, Nvmcon ;code for write 1 config}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 16#BB1F03, stat); {tblwtl w3, [w14++]}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;

    picprg_30_xinst (pr, 16#883B31, stat); {mov w1, Nvmkey}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 16#883B32, stat); {mov w2, Nvmkey}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 16#A8E761, stat); {bset Nvmcon, #Wr ;start the write}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;

    picprg_cmdw_wait (pr, pr.id_p^.tprogp, stat); {wait for the write to complete}
    if sys_error(stat) then return;
    picprg_cmdw_writing (pr, stat);    {indicate target memory is being changed}
    if sys_error(stat) then return;

    picprg_30_xinst (pr, 16#A9E761, stat); {bclr Nvmcon, #Wr ;end the write}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    end;                               {back to do next config register}

  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_24 (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for dsPIC 24H and 33F.
}
procedure picprg_erase_24 (            {erase routine for dsPIC 24H and 33F}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}

begin
{
*   Reset the target chip.
}
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate target memory is being changed}
  if sys_error(stat) then return;
{
*   Do a bulk erase.  This erases normal code memory, executive code memory,
*   and the code protection bits.  It does not erase the configuration words
*   except the code protection bits.
}
  picprg_30_setreg (pr, 16#404F, 0, stat); {mov #0x404F, w0}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#883B00, stat); {mov w0, Nvmcon}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#A8E761, stat); {bset Nvmcon, #Wr ;start the erase}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate target memory is being changed}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.100, stat);
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate target memory is being changed}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.100, stat);
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate target memory is being changed}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.100, stat);
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate target memory is being changed}
  if sys_error(stat) then return;
  picprg_cmdw_wait (pr, 0.030, stat);
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate target memory is being changed}
  if sys_error(stat) then return;

  picprg_30_xinst (pr, 16#A9E761, stat); {bclr Nvmcon, #Wr ;end the erase}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {NOP}
  if sys_error(stat) then return;
{
*   Erase the configuration words.  These are at the even addresses
*   F80000 - F8000E.
*
*   Register usage:
*
*     W3  -  Value to write to target word (FFFFh).
*
*     W4  -  NVMCON value for writing to config words (4000h).
*
*     W5  -  High word of target address (F8h), to be transferred to TBLPAG.
*
*     W14 -  Low word of target address.
}
  picprg_30_setreg (pr, 16#FFFF, 3, stat); {load FFFFh write value into W3}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 16#4000, 4, stat); {load NVMCON opcode into W4}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 16#F8, 5, stat); {mov #0xF8, w5 ;set high word of mem adr}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 0, 14, stat);  {mov #0, w14; init low word of mem adr}
  if sys_error(stat) then return;

  for i := 0 to 11 do begin            {once for each config register to clear}
    picprg_cmdw_writing (pr, stat);    {indicate target memory is being changed}
    if sys_error(stat) then return;
    picprg_30_goto200 (pr, stat);      {make sure target PC is at valid address}
    if sys_error(stat) then return;

    picprg_30_xinst (pr, 16#880195, stat); {mov w5, Tblpag}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;

    picprg_30_xinst (pr, 16#883B04, stat); {mov w4, Nvmcon ;code for write 1 config}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 16#BB1F03, stat); {tblwtl w3, [w14++]}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;

    picprg_30_xinst (pr, 16#A8E761, stat); {bset Nvmcon, #Wr ;start the write}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    picprg_cmdw_wait (pr, 0.025, stat); {wait for the write to complete}
    if sys_error(stat) then return;

    picprg_30_xinst (pr, 16#A9E761, stat); {bclr Nvmcon, #Wr ;end the write}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    picprg_30_xinst (pr, 0, stat);     {NOP}
    if sys_error(stat) then return;
    end;                               {back to do next config register}

  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_24F (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for 24F parts.
}
procedure picprg_erase_24f (           {erase routine for 24F parts}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
{
*   Reset the target chip.
}
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate target memory is being changed}
  if sys_error(stat) then return;

  picprg_30_setreg (pr, 16#4064, 0, stat); {mov #0x4064, w0}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#883B00, stat); {mov w0, Nvmcon}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 16#0000, 0, stat); {mov #0, w0}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#880190, stat); {mov w0, Tblpag}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#BB0800, stat); {tblwtl w0, [w0]}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#A8E761, stat); {bset Nvmcon, #Wr}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;

  picprg_cmdw_wait (pr, 0.010, stat);  {wait for the erase to complete}
  if sys_error(stat) then return;
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_24FJ (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for 24FJ parts.
}
procedure picprg_erase_24fj (          {erase routine for 24FJ parts}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
{
*   Reset the target chip.
}
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  picprg_cmdw_writing (pr, stat);      {indicate target memory is being changed}
  if sys_error(stat) then return;

  picprg_30_setreg (pr, 16#404F, 0, stat); {mov #0x404F, w0}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#883B00, stat); {mov w0, Nvmcon}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 16#0000, 0, stat); {mov #0, w0}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#880190, stat); {mov w0, Tblpag}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#BB0800, stat); {tblwtl w0, [w0]}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#A8E761, stat); {bset Nvmcon, #Wr}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;

  picprg_cmdw_wait (pr, 0.400, stat);  {wait for the erase to complete}
  if sys_error(stat) then return;
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE_33EP (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
*
*   This version is for 24EP and 33EP parts.
}
procedure picprg_erase_33ep (          {erase routine for 24EP and 33EP parts}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_30_setreg (pr, 16#400F, 0, stat); {mov #0x400F, w0}
  if sys_error(stat) then return;
  picprg_30_wram (pr, 0, pr.id_p^.nvmcon, stat); {mov w0, Nvmcon}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;

  picprg_30_setreg (pr, 16#55, 11, stat); {mov #0x55, w11}
  if sys_error(stat) then return;
  picprg_30_wram (pr, 11, pr.id_p^.nvmkey, stat); {mov w11, Nvmkey}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 16#AA, 12, stat); {mov #0xAA, w12}
  if sys_error(stat) then return;
  picprg_30_wram (pr, 12, pr.id_p^.nvmkey, stat); {mov w12, Nvmkey}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#A8E729, stat); {bset Nvmcon, #Wr}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 16#000000, stat); {nop}
  if sys_error(stat) then return;

  picprg_cmdw_wait (pr, 0.070, stat);  {wait for the erase to complete}
  if sys_error(stat) then return;
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_WRITE_30PGM (PR, ADR, N, DAT, MASK, STAT)
*
*   Write an array of N values to consecutive target chip locations starting at
*   the address ADR.  DAT is the array of input values.  MASK describes the
*   valid bits within each data word of DAT.
*
*   The library must have previously been configured to this target chip, and
*   the chip must be enabled for programming (Vpp on and Vdd set to normal).
*   The locations should also have not been programmed since last erased.  This
*   routine does not perform an erase before write cycle on each word.  It
*   assumes that the entire chip has been bulk erased.  An actual write is
*   avoided when the data value for a word matches the erased value, which is
*   all implemented bits 1.  MASK is used to determine which bits are
*   implemented.
*
*   This is a low level routine that does not check whether the address range is
*   valid for this target.  The write operations are performed as requested but
*   not verified.  The current address is left at the last address written plus
*   1.
}
procedure picprg_write_30pgm (         {array write for dsPIC program memory}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  max_wbufsz = 256;                    {maximum size write buffer supported}
  max_msg_args = 1;                    {max arguments we can pass to a message}
{
*   Derived constants.
}
  buflast = max_wbufsz - 1;            {last value write buffer address index}

var
  ovl: picprg_cmdovl_t;                {control state for overlapped commands}
  out_p: picprg_cmd_p_t;               {pointer to command to set up for output}
  buf: array[0..buflast] of sys_int_conv24_t; {data for current write block}
  adrl: picprg_adr_t;                  {last address for which data is available}
  adrb: picprg_adr_t;                  {start address for the current write buffer}
  a: picprg_adr_t;                     {address of current word}
  d: sys_int_conv24_t;                 {current data value}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  wblast: picprg_adr_t;                {0-N last 24 bit word in write buffer}
  blank: boolean;                      {all bytes in buffer set to erased value}
  adrinv: boolean;                     {target address is invalid for block}
  maske, masko: picprg_dat_t;          {mask for even and odd words}
  wbufsz: sys_int_machine_t;           {effective write buffer size}
  tk: string_var32_t;                  {scratch token}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;

label
  next_block, wconfig, leave;

begin
  tk.max := size_char(tk.str);         {init local var string}

  if n <= 0 then begin                 {nothing to write ?}
    sys_error_none (stat);
    return;
    end;

  picprg_cmdovl_init (ovl);            {init overlapped commands state}
  adrl := adr + n - 1;                 {make last address to write to}
  maske := mask.maske;                 {get mask for words at even addresses}
  masko := mask.masko;                 {get mask for words at odd addresses}
  wbufsz := pr.id_p^.wbufsz;           {init effective write buffer size}
  if adr < 16#F80000 then begin        {will use W30PGM command ?}
    wbufsz := max(wbufsz, 8);          {make write buffer whole W30PGM commands}
    end;

  wblast := (wbufsz div 2) - 1;        {last 0-N 24 bit word offset in write buffer}

  adrb := adr & ~(wbufsz - 1);         {make address of block containing first adr}
  adrinv := true;                      {init to target chip address needs to be set}

  while adrb <= adrl do begin          {loop thru all blocks covering address range}
    if adrb >= 16#F80000 then goto wconfig; {writing to configuration words ?}

    if                                 {show progress ?}
        (pr.debug >= 1) and            {this debug message enabled ?}
        ((adrb & 16#FFF) = 0)          {starting a new 2K block ?}
        then begin
      string_f_int_max_base (          {make block start HEX address string}
        tk,                            {output string}
        adrb,                          {input integer}
        16,                            {radix}
        6,                             {fixed field width}
        [ string_fi_leadz_k,           {fill field with leading zeros}
          string_fi_unsig_k],          {input integer is unsigned}
        stat);
      if sys_error(stat) then return;
      string_append1 (tk, 'h');
      sys_msg_parm_vstr (msg_parm[1], tk);
      sys_message_parms ('picprg', 'writing_adr', msg_parm, 1);
      sys_flush_stdout;                {make sure all output sent to parent program}
      end;

    blank := true;                     {init to all data in block is blank value}
    a := adrb;                         {init current address to first in block}
    for i := 0 to wblast do begin      {once for each 24 bit word in this write block}
      {
      *   Get low 16 bits of current word.
      }
      if (a >= adr) and (a <= adrl)
        then begin                     {source address is within input array ?}
          d := dat[a - adr] & maske;   {fetch value from input array}
          blank := blank and (d = maske); {TRUE if still all blank values this block}
          end
        else begin                     {no source value at this address}
          d := maske;
          end
        ;
      buf[i] := d;                     {init this word with 16 bits from even adr}
      a := a + 1;                      {advance to next address}
      {
      *   Get high 8 bits of current word.
      }
      if (a >= adr) and (a <= adrl)
        then begin                     {source address is within input array ?}
          d := dat[a - adr] & masko;   {fetch value from input array}
          blank := blank and (d = masko); {TRUE if still all blank values this block}
          end
        else begin                     {no source value at this address}
          d := masko;
          end
        ;
      buf[i] := buf[i] ! lshft(d, 16); {merge in high 8 bits of this word}
      a := a + 1;                      {advance to next address}
      end;                             {back to get next word in this block}

    if blank then begin                {whole block is set to erased value ?}
      adrinv := true;                  {indicate target address needs to be set}
      goto next_block;                 {done with this block, advance to next}
      end;
    {
    *   At least one bit in this block is not at the erased value.  Write the
    *   whole block.
    }
    if adrinv then begin               {target address is not at block start ?}
      picprg_cmdovl_outw (pr, ovl, out_p, stat); {get next command descriptor}
      if sys_error(stat) then return;
      picprg_cmd_adr (pr, out_p^, adrb, stat); {set target adr to start of block}
      if sys_error(stat) then return;
      adrinv := false;                 {indicate target address is now current}
      end;

    for i := 0 to wblast by 4 do begin {back here each W30PGM command}
      picprg_cmdovl_outw (pr, ovl, out_p, stat); {get next command descriptor}
      if sys_error(stat) then return;
      picprg_cmd_w30pgm (              {write 4 words of block to the target}
        pr,                            {state for this use of the library}
        out_p^,                        {returned command tracking state}
        buf[i], buf[i+1], buf[i+2], buf[i+3], {the 4 words to write}
        stat);
      if sys_error(stat) then return;
      end;                             {back to send next 4 words in this block}

next_block:                            {advance to next block}
    adrb := adrb + wbufsz;             {make start address of next block}
    end;                               {back to do next block}
  goto leave;                          {wait for commands to complete and exit}
{
*   Writing to configuration words.  These are written with normal WRITE
*   commands.
}
wconfig:
  adrb := max(adrb, adr);              {make first config address to write to}
  picprg_cmdovl_outw (pr, ovl, out_p, stat); {get next command descriptor}
  if sys_error(stat) then return;
  picprg_cmd_adr (pr, out_p^, adrb, stat); {set adr of first word to write}
  if sys_error(stat) then return;

  for a := adrb to adrl do begin       {once for each address to write to}
    d := dat[a - adr];                 {get this data word}
    if odd (a)                         {set all unused bits to 1}
      then d := d ! ~masko
      else d := d ! ~maske;
    picprg_cmdovl_outw (pr, ovl, out_p, stat); {get next command descriptor}
    if sys_error(stat) then return;
    picprg_cmd_write (pr, out_p^, d, stat); {write the word}
    if sys_error(stat) then return;
    end;                               {back to write next config word}

leave:                                 {common exit point}
  picprg_cmdovl_flush (pr, ovl, stat); {make sure all pending commands completed}
  end;
