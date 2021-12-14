{   Subroutine PICPRG_ID (PR, ID_P, IDSPACE, ID, STAT)
*
*   Determine or validate the hard coded ID of the target chip.  Some PICs have
*   a unique hard-coded ID.  IDSPACE indicates the ID namespace, and ID is
*   returned the raw ID value as hard coded into the chip.  Note that IDs are
*   not unique accross namespaces, only within each namespace.  Different PICs
*   have different sized ID words.  The ID word is returned in the least
*   significant bits of ID with unused upper bits set to 0.
*
*   If the target chip ID could not be determined, then IDSPACE is returned
*   PICPRG_IDSPACE_UNK_K and ID is returned 0.  Possible causes for this include
*   no chip in the socket, a chip with a programming algorithm not supported by
*   this routine, or the particular target chip does not contain a device ID.
*
*   The target chip will be off (no power, no programming voltage) when this
*   routine returns.  The RESET algorithm will be selected appropriately for the
*   target chip when a valid ID is returned.
*
*   ID_P may be passed in NIL or pointing to the ID block for a particular PIC.
*   If NIL, it must be possible to determine the identity of the target PIC by
*   interacting with it.  An error is returned if ID_P is NIL and the target PIC
*   identity could not be determined.  When returning without error, IDSPACE and
*   ID will identify the specific target PIC.  Note that it is not possible to
*   uniquely identify all PICs by interacting with them.  PICs with the 12 bit
*   core, for example, do not have unique IDs.
*
*   When ID_P is passed in pointing to the ID block of a specific PIC, then the
*   existance of this PIC is verified to the extent possible.  An error is
*   returned only if it can be reliably determined that the target PIC does not
*   adhere to the parameters in the ID block.  When not returning with an error,
*   IDSPACE and ID will be copied from the information in the ID block.
*
*   When this routine is called to verify a specific PIC (ID_P <> nil), then the
*   library is configured to that PIC if it is not already.
}
module picprg_id;
define picprg_id;
%include 'picprg2.ins.pas';

procedure picprg_id (                  {get the hard coded ID of the target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  in      id_p: picprg_idblock_p_t;    {pointer to descriptor for this target chip}
  out     idspace: picprg_idspace_k_t; {namespace the chip ID is within}
  out     id: picprg_chipid_t;         {returned chip ID in low bits, 0 = none}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  resp: boolean;                       {a response was received from the target chip}

label
  done_18j, done_24h, done_33ep, done_16f182x, done_16f153xx, done_16f72x,
  done_16fb, done_18lv, done_18k, done_62x, done_16f18f, done_30f,
  have_idblock, wrongpic, leave;
{
****************************************
*
*   Local subroutine CONFIG (RES, VDD, VPP, STAT)
*
*   Configure for a particular reset algorithm, Vdd voltage, and Vpp voltage.
*   The nearest possible values are silently substituted if the programmer is
*   not capable of the requested Vdd and Vpp voltages.  An error is returned if
*   the programmer is not capable of the selected reset algorithm.
}
procedure config (                     {set configuration for communicating with target}
  in      res: picprg_reset_k_t;       {reset algorithm ID}
  in      vdd: real;                   {Vdd voltage}
  in      vpp: real;                   {Vpp voltage}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

var
  vddvppoff: boolean;                  {Vdd off before Vpp}

begin
  pr.vdd.norm := vdd;                  {set the Vdd to use after next reset}

  if pr.fwinfo.cmd[61] then begin
    picprg_cmdw_vpp (pr, vpp, stat);   {set Vpp voltage to use}
    if sys_error(stat) then return;
    end;

  case res of
picprg_reset_62x_k: vddvppoff := true;
otherwise
    vddvppoff := false;
    end;
  picprg_cmdw_idreset (pr, res, vddvppoff, stat); {try to set the reset algorithm}
  end;
{
****************************************
*
*   Local subroutine CHECK_16 (RESP, STAT)
*
*   Check for target chip responds to normal PIC16 programming commands.
*   RESP will be returned TRUE if it does and FALSE if it does not.
*   The target chip will be reset according to the current reset algorithm
*   before an attempt is made to communicate with it.  The target chip
*   will be left partway thru a programming command and should be reset
*   before further attempts are made to communicate with it.
}
procedure check_16 (                   {check for response to normal PIC16 prog}
  out     resp: boolean;               {TRUE iff received a response from the chip}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_vddlev (pr, picprg_vdd_norm_k, stat); {configure for normal Vdd level}
  if sys_error(stat) then return;
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
{
*   Send a READ DATA FROM PROGRAM MEMORY command and verify that the
*   chip responds to it by driving and not driving the PGD line at
*   appropriate places in the handshake.  According to the programming
*   specs, the target PIC should start driving the PGD line one clock
*   into the 16 readback bits, since the first and last are unused
*   dummy bits.  However some PICs drive the line (like 16F636 for
*   example) drive the PGD line immediately after the 6 bit command
*   opcode, contrary to the programming spec.  We therefore check
*   that the line is not driven just before the end of the 6 bit
*   opcode, then verify it is driven 1 bit into the readback.
}
  picprg_send (pr, 5, 2#00100, stat);  {first 5 bits of read data opcode}
  if sys_error(stat) then return;

  picprg_cmdw_tdrive (pr, resp, stat); {check whether target is driving data line}
  if sys_error(stat) then return;
  if resp then begin                   {target driving PGD when it shouldn't be ?}
    resp := false;                     {indicate not valid PIC 16 response}
    return;
    end;

  picprg_send (pr, 1, 0, stat);        {send last bit of read data opcode}
  if sys_error(stat) then return;

  picprg_cmdw_clkh (pr, stat);         {do clock pulse for dummy start bit}
  if sys_error(stat) then return;
  picprg_cmdw_clkl (pr, stat);
  if sys_error(stat) then return;

  picprg_cmdw_clkh (pr, stat);         {raise clock for first real data bit}
  if sys_error(stat) then return;

  picprg_cmdw_tdrive (pr, resp, stat); {check for target driving data line}
  if sys_error(stat) then return;
  end;
{
****************************************
*
*   Local subroutine CHECK_16B (RESP, STAT)
*
*   Check for target chip responds to the 8 bit programming commands for a PIC
*   16.
*
*   RESP will be returned TRUE if it does and FALSE if it does not.  The target
*   chip will be reset according to the current reset algorithm before an
*   attempt is made to communicate with it.  The target chip will be left
*   partway thru a programming command and should be reset before further
*   attempts are made to communicate with it.
}
procedure check_16b (                  {check for response to 8 bit PIC 16 commands}
  out     resp: boolean;               {TRUE iff received a response from the chip}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_vddlev (pr, picprg_vdd_norm_k, stat); {configure for normal Vdd level}
  if sys_error(stat) then return;
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
{
*   Send a READ DATA FROM NVM command and verify that the chip responds to it by
*   driving and not driving the PGD line at appropriate places in the handshake.
*
*   Note that the PICPRG_SEND routine is used to send the opcode.  That routine
*   sends in least to most significant bit order.  On the 16B PICs, data is sent
*   in most to least significant bit order.  The opcode is therefore flipped.
*   The opcode to read data from the target is FCh.  Flipping this around yields
*   3Fh.
}
  picprg_send (pr, 7, 16#3F, stat);    {send all but last bit of opcode}
  if sys_error(stat) then return;

  picprg_cmdw_tdrive (pr, resp, stat); {check whether target is driving data line}
  if sys_error(stat) then return;
  if resp then begin                   {target driving PGD when it shouldn't be ?}
    resp := false;                     {indicate not valid PIC 16 response}
    return;
    end;

  picprg_send (pr, 1, 0, stat);        {send last bit of the opcode}
  if sys_error(stat) then return;

  picprg_cmdw_clkh (pr, stat);         {do clock pulse for dummy start bit}
  if sys_error(stat) then return;
  picprg_cmdw_clkl (pr, stat);
  if sys_error(stat) then return;

  picprg_cmdw_clkh (pr, stat);         {raise clock for first real data bit}
  if sys_error(stat) then return;

  picprg_cmdw_tdrive (pr, resp, stat); {check for target driving data line}
  if sys_error(stat) then return;
  end;
{
****************************************
*
*   Local subroutine CHECK_18 (RESP, STAT)
*
*   Check for target chip responds to normal PIC18 programming commands.
*   RESP will be returned TRUE if it does and FALSE if it does not.
*   The target chip will be reset according to the current reset algorithm
*   before an attempt is made to communicate with it.  The target chip
*   will be left partway thru a programming command and should be reset
*   before further attempts are made to communicate with it.
}
procedure check_18 (                   {check for response to normal PIC18 prog}
  out     resp: boolean;               {TRUE iff received a response from the chip}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_vddlev (pr, picprg_vdd_norm_k, stat); {configure for normal Vdd level}
  if sys_error(stat) then return;
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;

  picprg_send (pr, 4, 2#0010, stat);   {SHIFT OUT TABLAT REGISTER}
  if sys_error(stat) then return;
  picprg_send (pr, 8, 0, stat);        {do 8 dummy write data clock cycles}
  if sys_error(stat) then return;

  picprg_cmdw_tdrive (pr, resp, stat); {check for target driving data line}
  if sys_error(stat) then return;
  if resp then begin                   {got response where not expected ?}
    resp := false;                     {indicate no response}
    return;
    end;

  picprg_cmdw_clkh (pr, stat);         {raise clock for first read data bit}
  if sys_error(stat) then return;
  picprg_cmdw_tdrive (pr, resp, stat); {check for target driving data line}
  if sys_error(stat) then return;
  end;
{
****************************************
*
*   Local subroutine CHECK_30 (RESP, STAT)
*
*   Check for target chip responds to normal dsPIC programming commands.
*   RESP will be returned TRUE if it does and FALSE if it does not.
*   The target chip will be reset according to the current reset algorithm
*   before an attempt is made to communicate with it.  The target chip
*   will be left partway thru a programming command and should be reset
*   before further attempts are made to communicate with it.
}
procedure check_30 (                   {check for response to normal PIC30 prog}
  out     resp: boolean;               {TRUE iff received a response from the chip}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_vddlev (pr, picprg_vdd_norm_k, stat); {configure for normal Vdd level}
  if sys_error(stat) then return;
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  if pr.fwinfo.cvhi <  25 then begin   {reset doesn't set PC ?}
    picprg_30_goto100 (pr, stat);      {set PC to 100h}
    if sys_error(stat) then return;
    end;

  picprg_send (pr, 11, 1, stat);       {send REGOUT instruction plus 7 of 8 clocks}
  if sys_error(stat) then return;
{
*   The REGOUT command has been sent with 7 extra clocks following.  This
*   command requires one additional clock, after which a dsPIC will start
*   returning data.  It seems that dsPIC 24H and 33F start driving the data
*   line after the last clock pulse, contrary to the programming spec.  The
*   dsPIC 30F drive the data line on the leading edge of the first clock
*   for the return data word.
*
*   Make sure the data line is not driven now, and that it is driven after
*   the leading edge of the first clock pulse for the return data word.
}
  picprg_cmdw_tdrive (pr, resp, stat); {check for target driving data line}
  if sys_error(stat) then return;
  if resp then begin                   {got response where not expected ?}
    resp := false;                     {indicate no response}
    return;
    end;
{
*   Do the final clock pulse and then raise the clock line to start the first
*   clock pulse of the return data value.
}
  picprg_send (pr, 1, 0, stat);        {last whole clock pulse of REGOUT instruction}
  if sys_error(stat) then return;
  picprg_cmdw_clkh (pr, stat);         {raise clock for first read data bit}
  if sys_error(stat) then return;
  picprg_cmdw_tdrive (pr, resp, stat); {check for target driving data line}
  if sys_error(stat) then return;
  end;
{
****************************************
*
*   Local subroutine GETID_16 (ID, STAT)
*
*   Get the chip ID using the normal PIC16 command set and assuming the
*   current reset algorithm selection is appropriate.
*
*   These chips have the ID word 6 locations into the configuration space.
*   Some of the PICs in this catagory (like the 12F1571) have the ID word
*   6 locations into the config space as usual, but the revision is in the
*   previous word and not part of the ID word.  Therefore, the words at
*   5 and 6 addresses into the config space are read, with the data at
*   offset 6 being returned in the low 14 bits, and the data from offset 5
*   in the next higher 14 bits.  This does no harm for PICs where the data
*   at offset 5 is irrelevant since these bits will be masked off in
*   determining the device ID and the revision.
}
procedure getid_16 (                   {try get ID using PIC16 prog commands}
  out     id: picprg_chipid_t;         {returned chip ID in low bits, 0 = none}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ii, jj: sys_int_conv32_t;            {scratch integers and loop counter}

begin
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;

  picprg_send (pr, 6, 2#000000, stat); {LOAD CONFIGURATION, to start of config space}
  if sys_error(stat) then return;
  picprg_send (pr, 16, 0, stat);       {dummy data for LOAD CONFIGURATION}
  if sys_error(stat) then return;

  for ii := 1 to 5 do begin            {once for each address increment}
    picprg_send (pr, 6, 2#000110, stat); {INCREMENT ADDRESS}
    if sys_error(stat) then return;
    end;
{
*   Read the word at 5 addresses into the config space.
}
  picprg_send (pr, 6, 2#000100, stat); {READ DATA FROM PROGRAM MEMORY}
  if sys_error(stat) then return;
  picprg_recv (pr, 16, ii, stat);      {read the word including start/stop}
  if sys_error(stat) then return;
  ii := rshft(ii, 1) & 16#3FFF;        {mask in just the 14 bit data word}
{
*   Read the word at 6 addresses into the config space.
}
  picprg_send (pr, 6, 2#000110, stat); {INCREMENT ADDRESS}
  picprg_send (pr, 6, 2#000100, stat); {READ DATA FROM PROGRAM MEMORY}
  if sys_error(stat) then return;
  picprg_recv (pr, 16, jj, stat);      {read the word including start/stop}
  if sys_error(stat) then return;
  jj := rshft(jj, 1) & 16#3FFF;        {mask in just the 14 bit data word}

  id := lshft(ii, 14) ! jj;            {return data from both ID words}
  end;
{
****************************************
*
*   Local subroutine GETID_16B (ID, STAT)
*
*   Get the chip ID using the 8 bit PIC 16 command set and assuming the
*   current reset algorithm selection is appropriate.
*
*   These parts have the ID word at 8006h, and a revision word at 8005h.  We
*   return the ID in the high 14 bits and the revision in the low 14 bits.
}
procedure getid_16b (                  {get ID using 8 bit PIC 16 prog commands}
  out     id: picprg_chipid_t;         {returned chip ID in low bits, 0 = none}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ii, jj: sys_int_machine_t;           {scratch integers and loop counter}

begin
  id := 0;                             {init to not returning with valid ID}

  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;

  picprg_cmdw_send8m (pr, 16#80, stat); {set address to revision word}
  if sys_error(stat) then return;
  picprg_send16mss24 (pr, 16#8005, stat);
  if sys_error(stat) then return;

  picprg_cmdw_send8m (pr, 16#FE, stat); {read revision word into II, inc address}
  if sys_error(stat) then return;
  picprg_recv14mss24 (pr, ii, stat);
  if sys_error(stat) then return;

  picprg_cmdw_send8m (pr, 16#FC, stat); {read ID word into JJ}
  if sys_error(stat) then return;
  picprg_recv14mss24 (pr, jj, stat);
  if sys_error(stat) then return;

  id := lshft(jj, 14) ! ii;            {return combined ID and revision}
  end;
{
****************************************
*
*   Local subroutine GETID_18 (ID, STAT)
*
*   Get the chip ID using the normal PIC18 command set and assuming the
*   current reset algorithm selection is appropriate.
*
*   These chips have the ID mapped to program memory address 3FFFFEh.
}
procedure getid_18 (                   {try get ID using PIC18 prog commands}
  out     id: picprg_chipid_t;         {returned chip ID in low bits, 0 = none}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i1, i2: sys_int_machine_t;           {scratch integer}

begin
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;

  picprg_18_setadr (pr, 16#3FFFFE, stat); {set next address to read from}
  if sys_error(stat) then return;

  picprg_18_read (pr, 2#1001, 0, i1, stat); {read first byte and increment adr}
  if sys_error(stat) then return;
  picprg_18_read (pr, 2#1001, 0, i2, stat); {read second byte and increment adr}
  if sys_error(stat) then return;
  id := i1 ! lshft(i2, 8);
  end;
{
****************************************
*
*   Local subroutine GETID_30 (ID, VISI, TBLPAG, STAT)
*
*   Get the chip ID using the normal PIC30 command set and assuming the
*   current reset algorithm selection is appropriate.
*
*   VISI is the address of the VISI register in the target, and TBLPAG the
*   address of the TBLPAG register.
*
*   These chips have the ID mapped to program memory addresses FF0000h
*   and FF0002h.
}
procedure getid_30 (                   {try get ID using PIC30 prog commands}
  out     id: picprg_chipid_t;         {returned chip ID in low bits, 0 = none}
  in      visi: sys_int_machine_t;     {address of Visi register}
  in      tblpag: sys_int_machine_t;   {address of Tblpag register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  val16: sys_int_conv16_t;             {16 bit register value}
  i32: sys_int_conv32_t;

begin
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;
  if pr.fwinfo.cvhi <  25 then begin   {reset doesn't set PC ?}
    picprg_30_goto100 (pr, stat);      {set PC to 100h}
    if sys_error(stat) then return;
    end;

  picprg_30_setreg (pr, 16#00FF, 14, stat); {get high word of adr into W14}
  if sys_error(stat) then return;
  picprg_30_wram (pr, 14, tblpag, stat); {write it to Tblpag}
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_setreg (pr, 16#0000, 13, stat); {get low word of adr into W13}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;

  picprg_30_xinst (pr, 16#BA003D, stat); {tblrd [w13++], w0 ;low ID into W0}
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_wram (pr, 0, visi, stat);  {mov w0, Visi}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_getvisi (pr, val16, stat); {get Visi register into VAL16}
  if sys_error(stat) then return;
  id := val16;                         {init ID to low ID word value}

  picprg_30_xinst (pr, 16#BA001D, stat); {tblrd [w13], w0 ;high ID into W0}
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_wram (pr, 0, visi, stat);  {mov w0, Visi}
  if sys_error(stat) then return;
  picprg_30_xinst (pr, 0, stat);       {nop}
  if sys_error(stat) then return;
  picprg_30_getvisi (pr, val16, stat); {get Visi register into VAL16}
  if sys_error(stat) then return;
  i32 := val16;
  id := id ! lshft(i32, 16);           {merge to make full chip ID}
  end;
{
****************************************
*
*   Start of main routine.
}
begin
  idspace := picprg_idspace_unk_k;     {init to valid ID not found}
  id := 0;

  if id_p <> nil then goto have_idblock; {expecting a particular PIC ?}
{
********************
*
*   No specific PIC is expected.  Try to determine the PIC type and ID from
*   scratch.
}
{
*   Check for those PICs with Vdd and Vpp limited to 3.3V.  We have to check for
*   these first so that if it is one of them we never apply higher voltage.
}
  config (picprg_reset_18j_k, 3.3, 3.3, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_18j; {this PIC type not supported by programmer}
  check_18 (resp, stat);               {check for response from PIC18 prog commands}
  if sys_error(stat) then return;
  if resp then begin                   {the proper response was received ?}
    getid_18 (id, stat);               {get the chip ID using PIC18 method}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_18_k;  {indicate PIC18 ID namespace}
      end;
    goto leave;                        {return with the ID}
    end;
done_18j:

  config (picprg_reset_24h_k, 3.3, 3.3, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_24h; {this PIC type not supported by programmer}
  check_30 (resp, stat);               {check for dsPIC 24H, 33F}
  if sys_error(stat) then return;
  if resp then begin                   {the proper response was received ?}
    getid_30 (id, 16#784, 16#032, stat); {get the chip ID using dsPIC method}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_30_k;  {indicate dsPIC ID namespace}
      goto leave;                      {return with the ID}
      end;
    end;
done_24h:

  config (picprg_reset_33ep_k, 3.3, 3.3, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_33ep; {this PIC type not supported by programmer}
  check_30 (resp, stat);               {check for dsPIC 24EP, 33EP}
  if sys_error(stat) then return;
  if resp then begin                   {the proper response was received ?}
    getid_30 (id, 16#F88, 16#054, stat); {get the chip ID using dsPIC method}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_30_k;  {indicate dsPIC ID namespace}
      end;
    goto leave;                        {return with the ID}
    end;
done_33ep:

  config (picprg_reset_16f182x_k, 3.3, 3.3, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_16f182x; {this PIC type not supported by programmer}
  check_16 (resp, stat);               {check for response to PIC16 prog commands}
  if sys_error(stat) then return;
  if resp then begin                   {a response was received from the chip ?}
    getid_16 (id, stat);               {try to read the chip ID}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_16_k;  {indicate PIC16 ID namespace}
      goto leave;
      end;
    end;
done_16f182x:

  config (picprg_reset_16f153xx_k, 3.3, 3.3, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_16f153xx; {this PIC type not supported by programmer}
  check_16b (resp, stat);              {check for response to PIC16 prog commands}
  if sys_error(stat) then return;
  if resp then begin                   {a response was received from the chip ?}
    getid_16b (id, stat);              {try to read the chip ID}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_16b_k; {indicate PIC16B ID namespace}
      goto leave;
      end;
    end;
done_16f153xx:
{
*   Check for PICs with Vdd of 3.3V and Vpp of 8.5V.
}

(*
  config (picprg_reset_62x_k, 3.3, 8.5, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_16f72x; {this PIC type not supported by programmer}
  check_16 (resp, stat);               {check for response to PIC16 prog commands}
  if sys_error(stat) then return;
  if resp then begin                   {a response was received from the chip ?}
    getid_16 (id, stat);               {try to read the chip ID}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_16_k;  {indicate PIC16 ID namespace}
      goto leave;
      end;
    end;
*)
done_16f72x:

  config (picprg_reset_62x_k, 3.3, 8.5, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_16fb; {this PIC type not supported by programmer}
  check_16b (resp, stat);              {check for response to readback command}
  if sys_error(stat) then return;
  if resp then begin                   {a response was received from the chip ?}
    getid_16b (id, stat);              {try to read the chip ID}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_16b_k; {indicate PIC16 ID namespace}
      goto leave;
      end;
    end;
done_16fb:

  config (picprg_reset_18f_k, 3.3, 8.5, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_18lv; {this PIC type not supported by programmer}
  check_18 (resp, stat);               {check for response from PIC18 prog commands}
  if sys_error(stat) then return;
  if resp then begin                   {the proper response was received ?}
    getid_18 (id, stat);               {get the chip ID using PIC18 method}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_18_k;  {indicate PIC18 ID namespace}
      end;
    goto leave;                        {return with the ID}
    end;
done_18lv:
{
*   Check for PICs with Vdd limited to 5.0V and Vpp to 11V.
}
  config (picprg_reset_18f_k, 5.0, 11.0, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_18k; {this PIC type not supported by programmer}
  check_18 (resp, stat);               {check for response from PIC18 prog commands}
  if sys_error(stat) then return;
  if resp then begin                   {the proper response was received ?}
    getid_18 (id, stat);               {get the chip ID using PIC18 method}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_18_k;  {indicate PIC18 ID namespace}
      end;
    goto leave;                        {return with the ID}
    end;
done_18k:
{
*   Look for PIC 16 that uses the Vpp before Vdd program mode entry method, 5V
*   Vdd, and 13V Vpp.
}
  config (picprg_reset_62x_k, 5.0, 13.0, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_62x; {these PICs not supported by this programmer ?}
  check_16 (resp, stat);               {check for response to PIC16 prog commands}
  if sys_error(stat) then return;
  if resp then begin                   {a response was received from the chip ?}
    getid_16 (id, stat);               {try to read the chip ID}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_16_k;  {indicate PIC16 ID namespace}
      goto leave;
      end;
    end;
done_62x:
{
*   Look for PICs with Vdd before Vpp program mode entry, 5V Vdd, 13V Vpp.  This
*   includes many PIC 16 and PIC 18.
}
  config (picprg_reset_18f_k, 5.0, 13.0, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_16f18f; {these PICs not supported by this programmer ?}

  check_16 (resp, stat);               {check for response to PIC16 prog commands}
  if sys_error(stat) then return;
  if resp then begin                   {a response was received from the chip ?}
    getid_16 (id, stat);               {try to read the chip ID}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_16_k;  {indicate PIC16 ID namespace}
      end;
    goto leave;                        {return with the ID}
    end;

  check_18 (resp, stat);               {check for response to PIC18 prog commands}
  if sys_error(stat) then return;
  if resp then begin                   {the proper response was received ?}
    getid_18 (id, stat);               {get the chip ID using PIC18 method}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_18_k;  {indicate PIC18 ID namespace}
      end;
    goto leave;                        {return with the ID}
    end;

done_16f18f:
{
*   Try PIC30 programming commands.
}
  config (picprg_reset_30f_k, 5.0, 13.0, stat); {select reset method and voltages}
  if sys_error(stat) then goto done_30f; {these PICs not supported by this programmer ?}

  check_30 (resp, stat);               {check for response to PIC30 prog commands}
  if sys_error(stat) then return;
  if resp then begin                   {the proper response was received ?}
    getid_30 (id, 16#784, 16#032, stat); {get the chip ID using PIC30 method}
    if sys_error(stat) then return;
    if id <> 0 then begin              {got the ID ?}
      idspace := picprg_idspace_30_k;  {indicate PIC30 ID namespace}
      end;
    goto leave;                        {return with the ID}
    end;

done_30f:
  goto leave;                          {couldn't find PIC ID}
{
********************
*
*   ID_P is pointing to the ID block of a specific PIC.  Look for any evidence
*   that the target PIC is not the same as described in the ID block.  If so,
*   then this routine will return with error status.
}
have_idblock:
  if pr.id_p <> id_p then begin        {not currently configured for this PIC ?}
    picprg_config_idb (pr, id_p^, id_p^.name_p^, stat); {configure to this PIC}
    if sys_error(stat) then return;
    end;

  case id_p^.idspace of
{
*   12 bit core.
}
picprg_idspace_12_k: begin
  check_16 (resp, stat);               {check for responds to read command}
  if sys_error(stat) then return;
  if not resp then goto wrongpic;
  end;
{
*   14 bit core.
}
picprg_idspace_16_k: begin
  if id_p^.id = 0
    then begin                         {this PIC doesn't have a chip ID}
      check_16 (resp, stat);           {test for responding to PIC 16 read command}
      if sys_error(stat) then return;
      if not resp then goto wrongpic;
      end
    else begin                         {this PIC has a known chip ID}
      picprg_vddlev (pr, picprg_vdd_norm_k, stat); {configure for normal Vdd level}
      if sys_error(stat) then return;
      getid_16 (id, stat);             {read the chip ID}
      if sys_error(stat) then return;
      if (id & id_p^.mask) <> id_p^.id {check the device ID bits only}
        then goto wrongpic;
      end
    ;
  end;
{
*   PIC 16 using 8 bit programming opcodes.
}
picprg_idspace_16b_k: begin
  check_16b (resp, stat);              {check for responds to the right read command}
  if sys_error(stat) then return;
  if not resp then goto wrongpic;
  getid_16b (id, stat);                {read the chip ID}
  if sys_error(stat) then return;
  if (id & id_p^.mask) <> id_p^.id     {check the device ID bits only}
    then goto wrongpic;
  end;
{
*   16 bit core of 18 family.
}
picprg_idspace_18_k: begin
  check_18 (resp, stat);               {check for responds to PIC18 read command}
  if sys_error(stat) then return;
  if not resp then goto wrongpic;
  getid_18 (id, stat);                 {read the chip ID}
  if sys_error(stat) then return;
  if (id & id_p^.mask) <> id_p^.id     {check the device ID bits only}
    then goto wrongpic;
  end;
{
*   dsPIC.
}
picprg_idspace_30_k: begin
  check_30 (resp, stat);               {check for response to PIC30 prog commands}
  if sys_error(stat) then return;
  if not resp then goto wrongpic;
  getid_30 (id, id_p^.visi, id_p^.tblpag, stat); {read the chip ID}
  if sys_error(stat) then return;
  if (id & id_p^.mask) <> id_p^.id     {check the device ID bits only}
    then goto wrongpic;
  end;
{
*   Unexpected IDSPACE found in the ID block.
}
otherwise
    sys_stat_set (picprg_subsys_k, picprg_stat_badidspace_k, stat);
    sys_stat_parm_int (ord(id_p^.idspace), stat);
    sys_stat_parm_str ('PICPRG_ID', stat);
    return;
    end;

  idspace := id_p^.idspace;            {return ID namespace}
  goto leave;                          {all done, return normally}

wrongpic:                              {not the expected target chip}
  sys_stat_set (picprg_subsys_k, picprg_stat_wrongpic_k, stat);
  sys_stat_parm_vstr (id_p^.name_p^.name, stat);
  return;
{
********************
*
*   Common exit point.  Make sure the target chip is powered down.
}
leave:
  picprg_cmdw_off (pr, stat);          {turn off power to the target chip}
  end;
