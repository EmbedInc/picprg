{   Collection of small utility routines.
}
module picprg_util;
define picprg_closing;
define picprg_erase;
define picprg_reset;
define picprg_nconfig;
define picprg_space_set;
define picprg_space;
define picprg_off;
define picprg_maskit;
define picprg_mask;
define picprg_mask_same;
define picprg_send;
define picprg_recv;
define picprg_vddlev;
define picprg_vddset;
define picprg_sendbuf;
define picprg_progtime;
%include 'picprg2.ins.pas';
{
*******************************************************************************
*
*   Function PICPRG_CLOSING (PR, STAT)
*
*   Check whether this use of the library is being closed down.  If not,
*   STAT is reset and the function returns FALSE.  If so, STAT will
*   indicate the library is being closed and the function will return TRUE.
}
function picprg_closing (              {check for library is being closed}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t)             {set to CLOSE if library being closed}
  :boolean;                            {TRUE iff library being closed}
  val_param;

begin
  if pr.quit
    then begin                         {library is closing down}
      sys_stat_set (picprg_subsys_k, picprg_stat_close_k, stat);
      picprg_closing := true;
      end
    else begin                         {library is not closing down}
      sys_error_none (stat);
      picprg_closing := false;
      end
    ;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ERASE (PR, STAT)
*
*   Erase all erasable non-volatile memory in the target chip.
}
procedure picprg_erase (               {erase all erasable non-volatile target mem}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if pr.erase_p = nil then begin       {no erase routine installed ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_nerase_k, stat);
    return;
    end;

  pr.erase_p^ (addr(pr), stat);        {call the specific erase routine}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_RESET (PR, STAT)
*
*   Reset the target chip and associated state in this library and the
*   remote unit.  All settings that are "choices" are reset to defaults.
*   The settings that are a function of the specific target chip are
*   not altered.
}
procedure picprg_reset (               {reset the target chip and associated state}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_cmdw_reset (pr, stat);        {reset the target chip}
  if sys_error(stat) then return;
  picprg_cmdw_spprog (pr, stat);       {set the address space to program, not data}
  if sys_error(stat) then return;
  picprg_cmdw_adr (pr, 0, stat);       {reset desired address of next transfer}
  end;
{
*******************************************************************************
*
*   Function PICPRG_NCONFIG (PR, STAT)
*
*   Test for the library has been configured (PICPRG_CONFIG called).
*   The function returns TRUE with an approriate error status in STAT if
*   the library has not been configured.  If the library has been configured,
*   then the function returns FALSE and STAT is return normal.
}
function picprg_nconfig (              {check for library has been configured}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t)             {set to error if library not configured}
  :boolean;                            {TRUE if library not configured}
  val_param;

begin
  if pr.id_p = nil
    then begin                         {library not configured}
      picprg_nconfig := true;
      sys_stat_set (picprg_subsys_k, picprg_stat_nconfig_k, stat);
      end
    else begin                         {library has been configured}
      picprg_nconfig := false;
      sys_error_none (stat);
      end
    ;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_SPACE_SET (PR, SPACE, STAT)
*
*   High level routine for applications to switch the memory address space.
*   Applications are encouraged to call this routine instead of issuing the low
*   level SPxxxx commands directly.
}
procedure picprg_space_set (           {select address space for future operations}
  in out  pr: picprg_t;                {state for this use of the library}
  in      space: picprg_space_k_t;     {ID for the new selected target memory space}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no error encountered}

  case space of                        {which address space switching to ?}

picprg_space_prog_k: begin             {switching to program memory address space}
      picprg_cmdw_spprog (pr, stat);   {switch remote unit and reconfigure library}
      if sys_error(stat) then return;
      if pr.id_p <> nil then begin
        picprg_progtime (pr, pr.id_p^.tprogp, stat); {set write wait time}
        if sys_error(stat) then return;
        end;
      end;

picprg_space_data_k: begin             {switching to data memory address space}
      picprg_cmdw_spdata (pr, stat);   {switch remote unit and reconfigure library}
      if sys_error(stat) then return;
      if pr.id_p <> nil then begin
        picprg_progtime (pr, pr.id_p^.tprogd, stat); {set write wait time}
        if sys_error(stat) then return;
        end;
      end;

otherwise
    sys_stat_set (picprg_subsys_k, picprg_stat_badspace_k, stat);
    sys_stat_parm_int (ord(space), stat);
    end;                               {end of memory space cases}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_SPACE (PR, SPACE)
*
*   Configure the PICPRG library to the indicated target address space
*   setting.  This routine does not change the address space.  It is called
*   to notify the library that the address space was changed.
*
*   This routine is called implicitly by the SPPROG and SPDATA low level
*   command routines.
}
procedure picprg_space (               {reconfig library to new mem space selection}
  in out  pr: picprg_t;                {state for this use of the library}
  in      space: picprg_space_k_t);    {ID for the new selected target memory space}
  val_param;

begin
  pr.space := space;

  if pr.id_p = nil then return;        {not configured yet, nothing more to do ?}

  case pr.id_p^.fam of                 {which PIC family is it in ?}
{
**********
*
*   PIC 18 family.
}
picprg_picfam_18f_k,                   {18F252 and related}
picprg_picfam_18f6680_k: begin         {18F6680 and related}
      case pr.space of

picprg_space_prog_k: begin             {program memory space}
  pr.write_p :=                        {install array write routine}
    univ_ptr(addr(picprg_write_18));
  pr.read_p :=                         {install array read routine}
    univ_ptr(addr(picprg_read_gen));
  end;

picprg_space_data_k: begin             {data memory space}
  pr.write_p :=                        {install array write routine}
    univ_ptr(addr(picprg_write_18d));
  if picprg_read_18fe_k in pr.fwinfo.idread
    then begin                         {firmware can read EEPROM directly}
      pr.read_p := univ_ptr(addr(picprg_read_gen))
      end
    else begin                         {no firmware EEPROM read, use emulation}
      pr.read_p := univ_ptr(addr(picprg_read_18d));
      end
    ;
  end;

otherwise
        pr.write_p := nil;
        pr.read_p := nil;
        end;                           {end of memory space cases}
      end;                             {end of 18Fxx2 18Fxx8 family case}
{
**********
*
*  PIC 18F2520 and related.
}
picprg_picfam_18f2520_k: begin
      case pr.space of

picprg_space_prog_k: begin             {program memory space}
  pr.read_p :=                         {install array read routine}
    univ_ptr(addr(picprg_read_gen));
  end;

picprg_space_data_k: begin             {data memory space}
  if picprg_read_18fe_k in pr.fwinfo.idread
    then begin                         {firmware can read EEPROM directly}
      pr.read_p := univ_ptr(addr(picprg_read_gen))
      end
    else begin                         {no firmware EEPROM read, use emulation}
      pr.read_p := univ_ptr(addr(picprg_read_18d));
      end
    ;
  end;

otherwise
        pr.write_p := nil;
        pr.read_p := nil;
        end;                           {end of memory space cases}
      end;                             {end of 18Fxx2 18Fxx8 family case}
{
**********
*
*   16 bit PICs: 24, 30, and 33 families.
}
picprg_picfam_24h_k,
picprg_picfam_24f_k,
picprg_picfam_24fj_k,
picprg_picfam_33ep_k,
picprg_picfam_30f_k: begin
      pr.write_p :=                    {init to generic array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {init to generic array read routine}
        univ_ptr(addr(picprg_read_gen));
      case pr.space of

picprg_space_prog_k: begin             {program memory space}
  if pr.fwinfo.cmd[56] then begin      {W30PGM command implemented ?}
    pr.write_p :=                      {install special program memory write routine}
      univ_ptr(addr(picprg_write_30pgm));
    end;
  end;                                 {end of program memory space}
        end;                           {end of PIC 30 memory space cases}
      end;                             {end of PIC 30 family case}

    end;                               {end of PIC family cases}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_OFF (PR, STAT)
*
*   Disengage from the target chip or circuit to the extent possible.
}
procedure picprg_off (                 {disengage from target to the extent possible}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_cmdw_highz (pr, stat);        {try to set target lines to high impedence}
  if                                   {HIGHZ command not supported ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    picprg_cmdw_off (pr, stat);        {use OFF command, is always supported}
    end;
  end;
{
*******************************************************************************
*
*   Function PICPRG_MASKIT (DAT, MASK, ADR)
*
*   Return the value in DAT with all unused bits set to 0.  MASK is the information
*   on which bits are valid, and ADR is the address of this data word.
}
function picprg_maskit (               {apply valid bits mask to data word}
  in      dat: picprg_dat_t;           {data word to mask}
  in      mask: picprg_maskdat_t;      {information about valid bits}
  in      adr: picprg_adr_t)           {target chip address of this data word}
  :picprg_dat_t;                       {returned DAT with all unused bits zero}
  val_param;

begin
  picprg_maskit := dat & picprg_mask (mask, adr);
  end;
{
*******************************************************************************
*
*   Function PICPRG_MASK (MASK, ADR)
*
*   Return the mask of valid data bits for the address ADR.  MASK specifies
*   which data bits are valid.
}
function picprg_mask (                 {get mask of valid data bits at address}
  in      mask: picprg_maskdat_t;      {information about valid bits}
  in      adr: picprg_adr_t)           {target chip address of this data word}
  :picprg_dat_t;                       {returned mask of valid data bits}
  val_param;

begin
  if odd(adr)
    then begin                         {data word is at odd address}
      picprg_mask := mask.masko;
      end
    else begin                         {data word if at even address}
      picprg_mask := mask.maske;
      end
    ;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_MASK_SAME (MASK, MASKDAT)
*
*   Set the mask information in MASKDAT to be the mask MASK in all cases.
}
procedure picprg_mask_same (           {make mask info with one mask for all cases}
  in      mask: picprg_dat_t;          {the mask to apply in all cases}
  out     maskdat: picprg_maskdat_t);  {returned mask info}
  val_param;

begin
  maskdat.maske := mask;               {set mask for even addresses}
  maskdat.masko := mask;               {set mask for odd addresses}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_SEND (PR, N, DAT, STAT)
*
*   Send the low N bits of DAT to the target chip via the serial interface.
*   The LSB of DAT is sent first.  N must not exceed 32.  The optimum
*   commands are used to send the data, depending on how many bits are being
*   sent and which commands are implemented in the programmer.  Nothing is
*   done if N is zero or negative.
}
procedure picprg_send (                {send serial bits to target, use optimum cmd}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {0-32 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  nleft: sys_int_machine_t;            {number of bits left to send}
  nt: sys_int_machine_t;               {number of bits to send with current command}
  dleft: sys_int_conv32_t;             {the data bits left to send}

label
  next_bits;

begin
  if n <= 0 then begin                 {no bits to send ?}
    sys_error_none (stat);
    return;
    end;

  if n > 32 then begin                 {invalid number of bits argument ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_badnbits_k, stat);
    sys_stat_parm_int (0, stat);
    sys_stat_parm_int (32, stat);
    sys_stat_parm_int (n, stat);
    return;
    end;

  nleft := n;                          {init number of bits left to send}
  nt := 0;                             {init number of bits sent last time}
  dleft := dat;                        {init the bits left to send}
  while nleft > 0 do begin             {keep looping until all bits sent}
    dleft := rshft(dleft, nt);         {position remaining bits into LSB}
    if (n > 24) and pr.fwinfo.cmd[53] then begin
      nt := nleft;                     {number of bits to send with this command}
      picprg_cmdw_send4 (pr, nt, dleft, stat);
      goto next_bits;
      end;
    if (n > 16) and pr.fwinfo.cmd[52] then begin
      nt := min(24, nleft);            {number of bits to send with this command}
      picprg_cmdw_send3 (pr, nt, dleft, stat);
      goto next_bits;
      end;
    if (n > 8) and pr.fwinfo.cmd[5] then begin
      nt := min(16, nleft);            {number of bits to send with this command}
      picprg_cmdw_send2 (pr, nt, dleft, stat);
      goto next_bits;
      end;

    nt := min(8, nleft);               {number of bits to send with this command}
    picprg_cmdw_send1 (pr, nt, dleft, stat);

next_bits:                             {done sending one command, on to next}
    if sys_error(stat) then return;
    nleft := nleft - nt;               {update number of bits left to send}
    end;                               {back to do another command if bits left}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_RECV (PR, N, DAT, STAT)
*
*   Receive N bits from the target chip via the serial interface.  The bits
*   are returned in the least significant end of DAT.  The first received bit
*   is written to the LSB of DAT.  Unused bits in DAT are set to 0.
}
procedure picprg_recv (                {read serial bits from targ, use optimum cmd}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {0-32 number of bits to read}
  out     dat: sys_int_conv32_t;       {returned bits shifted into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  nleft: sys_int_machine_t;            {number of bits left to receive}
  nt: sys_int_machine_t;               {number of bits to recv with current command}
  d: sys_int_conv32_t;                 {bits received with current command}

label
  next_bits;

begin
  dat := 0;                            {init all received bits to 0}
  if n <= 0 then begin                 {no bits to receive ?}
    sys_error_none (stat);
    return;
    end;

  if n > 32 then begin                 {invalid number of bits argument ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_badnbits_k, stat);
    sys_stat_parm_int (0, stat);
    sys_stat_parm_int (32, stat);
    sys_stat_parm_int (n, stat);
    return;
    end;

  nleft := n;                          {init number of bits left to receive}
  while nleft > 0 do begin             {keep looping until all bits sent}
    if (n > 24) and pr.fwinfo.cmd[55] then begin
      nt := nleft;                     {number of bits to receive with this command}
      picprg_cmdw_recv4 (pr, nt, d, stat);
      goto next_bits;
      end;
    if (n > 16) and pr.fwinfo.cmd[54] then begin
      nt := min(24, nleft);            {number of bits to receive with this command}
      picprg_cmdw_recv3 (pr, nt, d, stat);
      goto next_bits;
      end;
    if (n > 8) and pr.fwinfo.cmd[7] then begin
      nt := min(16, nleft);            {number of bits to receive with this command}
      picprg_cmdw_recv2 (pr, nt, d, stat);
      goto next_bits;
      end;

    nt := min(8, nleft);               {number of bits to receive with this command}
    picprg_cmdw_recv1 (pr, nt, d, stat);

next_bits:                             {done sending one command, on to next}
    if sys_error(stat) then return;
    dat := dat ! lshft(d, n - nleft);  {merge in new received bits}
    nleft := nleft - nt;               {update number of bits left to receive}
    end;                               {back to do another command if bits left}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_VDDLEV (PR, VDDID, STAT)
*
*   Select the Vdd level to be used on the next reset.  On old programmers that
*   do not implement the VDD command, Vdd is immediately set to the selected
*   level.  On newer programmers with the VDD command the current Vdd level is
*   not altered, but the new Vdd level will take effect the next time Vdd is
*   enabled.
*
*   Applications should use this routine instead of issuing low level programmer
*   commands.
}
procedure picprg_vddlev (              {set Vdd level for next time enabled}
  in out  pr: picprg_t;                {state for this use of the library}
  in      vddid: picprg_vdd_k_t;       {ID for the new level to set to}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  v: real;                             {new desired voltage}
  vout: real;                          {actual resulting voltage}

begin
  case vddid of                        {set V to the new selected Vdd voltage}
picprg_vdd_low_k: v := pr.vdd.low;
picprg_vdd_norm_k: v := pr.vdd.norm;
picprg_vdd_high_k: v := pr.vdd.high;
otherwise
    sys_stat_set (picprg_subsys_k, picprg_stat_badvddid_k, stat);
    sys_stat_parm_int (ord(vddid), stat);
    return;
    end;

  picprg_vddset (pr, v, vout, stat);
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_VDDSET (PR, VIN, VOUT, STAT)
*
*   Set up the target Vdd state so that it will be as close as possible to VIN
*   volts after the next reset.  Depending on the programmer capabilities, Vdd
*   may change to the new level immediately, but it is not guaranteed to
*   changed until after the next reset.  VOUT is returned the actual Vdd level
*   that the programmer will produce.
}
procedure picprg_vddset (              {set Vdd for specified level by next reset}
  in out  pr: picprg_t;                {state for this use of the library}
  in      vin: real;                   {desired Vdd level in volts}
  out     vout: real;                  {actual Vdd level selected}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no error encountered}

  if not pr.fwinfo.varvdd then begin   {programmer has fixed Vdd ?}
    vout :=                            {indicate programmer's fixed Vdd level}
      round(10.0 * (pr.fwinfo.vddmin + pr.fwinfo.vddmax) / 2.0) / 10.0;
    return;
    end;

  if pr.fwinfo.cmd[65] then begin      {VDD command is available ?}
    picprg_cmdw_vdd (pr, vin, stat);   {set to desired Vdd}
    vout := max(0.0, min(6.0, vin));   {clip to programmer's Vdd range}
    return;
    end;

  picprg_cmdw_vddvals (pr, vin, vin, vin, stat); {set low/norm/high all to selected level}
  vout := max(0.0, min(6.0, vin));     {clip to programmer's Vdd range}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_SENDBUF (PR, BUF, N, STAT)
*
*   Send N bytes from the buffer BUF to the programmer.  This is a low level routine
*   that does not interpret the bytes.  It does use the proper I/O means to send
*   to the particular programmer in use.  All data is sent to the programmer via
*   this routine in normal operation.  Some data may be sent privately during
*   initialization.
}
procedure picprg_sendbuf (             {send buffer of bytes to the programmer}
  in out  pr: picprg_t;                {state for this use of the library}
  in      buf: univ picprg_buf_t;      {buffer of bytes to send}
  in      n: sys_int_adr_t;            {number of bytes to send}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {scratch integer and loop counter}
  vbuf: string_var80_t;                {var string output buffer}
  stat2: sys_err_t;

begin
  vbuf.max := size_char(vbuf.str);     {init local var string}

  if picprg_closing (pr, stat) then return; {library is being closed down ?}

  if picprg_flag_showout_k in pr.flags then begin {show output bytes on standard output ?}
    writeln;
    write ('>');
    for i := 0 to n-1 do begin
      write (' ', buf[i]);
      end;
    writeln;
    end;

  case pr.devconn of                   {what kind of I/O connection is in use ?}

picprg_devconn_sio_k: begin            {programmer is connected via serial line}
      for i := 1 to n do begin         {once for each byte to send}
        vbuf.str[i] := chr(buf[i-1]);  {copy this char to var string output buffer}
        end;
      vbuf.len := n;                   {set number of bytes in var string output buffer}
      file_write_sio_rec (vbuf, pr.conn, stat); {send the bytes to the remote unit}
      end;

picprg_devconn_usb_k: begin            {programner is connected via USB}
      picprg_sys_usb_write (pr.conn, buf, n, stat); {send the bytes}
      end;

otherwise
    sys_stat_set (picprg_subsys_k, picprg_stat_baddevconn_k, stat);
    sys_stat_parm_int (ord(pr.devconn), stat);
    return;
    end;

  if picprg_closing (pr, stat2) then begin {library is being closed down ?}
    stat := stat2;
    return;
    end;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_PROGTIME (PR, PROGT, STAT)
*
*   Set the programming time in the programmer.  PROGT is the programming time
*   to set in units of seconds.
*
*   This routine sets the normal and fast programming times, as implemented by
*   the programmer.
}
procedure picprg_progtime (            {set programming time}
  in out  pr: picprg_t;                {state for this use of the library}
  in      progt: real;                 {programming time, seconds}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  r: real;                             {scratch floating point}
  ii: sys_int_machine_t;               {scratch integer}

begin
  picprg_cmdw_tprog (pr, progt, stat); {set time in base ticks}
  if sys_error(stat) then return;

  if pr.fwinfo.cmd[83] then begin      {programmer implements TPROGF command ?}
    r := (pr.id_p^.tprogp * pr.fwinfo.ftickf) + 0.999; {number of ticks}
    ii := trunc(min(r, 65535.5));      {clip to max possible}
    picprg_cmdw_tprogf (pr, ii, stat); {set programming time in fast ticks}
    if sys_error(stat) then return;
    end;
  end;
