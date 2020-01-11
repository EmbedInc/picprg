{   Routines for reading data from the target chip.
}
module picprg_read;
define picprg_read;
define picprg_read_gen;
%include 'picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_READ (PR, ADR, N, MASK, DAT, STAT)
*
*   Read N consecutive locations starting at ADR from the target chip.
*   The data will be returned in the array DAT.  MASK identifies the
*   valid data bits within each data word.  Zeros are returned in all
*   unused data bits.
*
*   This routine performs overlapped commands to read large blocks of
*   data efficiently.
*
*   The library must have previously been configured to this target chip,
*   and the chip must be enabled for programming (Vpp on and Vdd set to
*   normal).
}
procedure picprg_read (                {read data from target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to read from}
  in      n: picprg_adr_t;             {number of locations to read from}
  in      mask: picprg_maskdat_t;      {mask for valid data bits}
  out     dat: univ picprg_datar_t;    {the returned data array, unused bits 0}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if pr.read_p = nil then begin        {no read routine installed ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_nread_k, stat);
    return;
    end;

  pr.read_p^ (addr(pr), adr, n, mask, dat, stat);
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_READ_GEN (PR, ADR, N, MASK, DAT, STAT)
*
*   Generic array READ routine.  This routine uses commands READ, RBYTE8, READ64,
*   or R30PGM depending on what is available, the target PIC type, and what is
*   most efficient for the connection type.
}
procedure picprg_read_gen (            {generic read, uses READ and RBYTE8 commands}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to read from}
  in      n: picprg_adr_t;             {number of locations to read from}
  in      mask: picprg_maskdat_t;      {mask for valid data bits}
  out     dat: univ picprg_datar_t;    {the returned data array, unused bits 0}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ovl: picprg_cmdovl_t;                {overlapped commands control state}
  cmd_p: picprg_cmd_p_t;               {pointer to current command descriptor}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  dati: picprg_adr_t;                  {current DAT index}
  d: picprg_dat_t;                     {scratch target chip data word}
  adrc: picprg_adr_t;                  {address for next command}
  adrr: picprg_adr_t;                  {address for next response}
  adrl: picprg_adr_t;                  {last address to return data for}
  adrw: picprg_adr_t;                  {address of current data word}
  m: picprg_dat_t;                     {scratch data word mask}
  maske, masko: picprg_dat_t;          {mask for even and odd words}
  blksz: sys_int_machine_t;            {number of addresses read in one block}
  buf8: picprg_8byte_t;                {buffer for RBYTE8 command data}
  buf64: array[0 .. 63] of picprg_dat_t; {buffer for READ64 command data}
  bufds: array[0 .. 1] of sys_int_conv24_t; {buffer for dsPIC program memory words}
  dsd: sys_int_conv24_t;               {scratch dsPIC program memory data word}
  hilat: boolean;                      {I/O connection has high round trip latency}

label
  word1, loop_word, rd64, rd64_send, bits8, b8_send, r30pgm, r30pgm_send;

begin
  sys_error_none (stat);               {init to no error encountered}

  if n <= 0 then return;               {no locations to do, nothing to read ?}
  picprg_cmdovl_init (ovl);            {init overlapped commands state}
  adrl := adr + n - 1;                 {make last address to return data for}
  dati := 0;                           {init next DAT array index to fill in}
  m := (mask.maske ! mask.masko);      {make mask for any bits used at all}
  case pr.devconn of                   {what type of I/O connection to the programmer ?}
picprg_devconn_usb_k: begin            {high round trip latency}
      hilat := true;
      end;
otherwise
    hilat := false;                    {low round trip latency}
    end;
{
*   Determine which read command to use.
}
  if pr.fwinfo.cmd[69] and hilat       {use READ64 if available and high I/O latency}
    then goto rd64;

  case pr.id_p^.fam of
picprg_picfam_30f_k: begin             {dsPIC target chip}
  if pr.fwinfo.cmd[58] and (pr.space = picprg_space_prog_k) {prog space and R30PGM avail ?}
    then goto r30pgm;
  goto word1;                          {default to use READ command}
      end;                             {end of dsPIC target case}
    end;                               {end of target type cases}

  if pr.fwinfo.cmd[69] then begin      {READ64 command available ?}
    if (m ! 255) <> 255 then goto rd64; {need to read more than just byte anyway ?}
    end;

  if pr.fwinfo.cmd[37] then begin      {RBYTE8 command available ?}
    if (m ! 255) = 255 then goto bits8; {only 8 data bits in data word ?}
    end;
{
*   Use READ command to read individual data words.
}
word1:
  adrc := adr;                         {init address for first read request}
  picprg_cmdw_adr (pr, adrc, stat);    {set the target to address of first read}
  if sys_error(stat) then return;

loop_word:                             {back here to request or read another word}
  if adrc <= adrl then begin           {need to request more data ?}
    picprg_cmdovl_out (pr, ovl, cmd_p, stat); {try to get output command descriptor}
    if sys_error(stat) then return;
    if cmd_p <> nil then begin         {got descriptor for new command ?}
      picprg_cmd_read (pr, cmd_p^, stat); {send another READ command}
      if sys_error(stat) then return;
      adrc := adrc + 1;                {update address of next command}
      goto loop_word;                  {try sending another command}
      end;
    end;

  picprg_cmdovl_in (pr, ovl, cmd_p, stat); {get next command with response data}
  if sys_error(stat) then return;
  picprg_rsp_read (pr, cmd_p^, d, stat); {get the data from the command}
  if sys_error(stat) then return;
  dat[dati] := picprg_maskit (d, mask, adr + dati); {return data with unused bits 0}
  dati := dati + 1;                    {advance DAT array index}
  if dati >= n then return;            {done returning all data into DAT ?}
  goto loop_word;                      {back for next command and/or response}
{
*   Use READ64 command to read blocks of 64 data words.
}
rd64:
  blksz := 64;                         {block size}
  adrc := (adr div blksz) * blksz;     {init address for next read request}
  adrr := adrc;                        {init address of next read response}
  picprg_cmdw_adr (pr, adrc, stat);    {set the target to address of first read}
  if sys_error(stat) then return;

rd64_send:                             {back here to try and send each new command}
  if adrc <= adrl then begin           {need to request more data ?}
    picprg_cmdovl_out (pr, ovl, cmd_p, stat); {try to get output command descriptor}
    if sys_error(stat) then return;
    if cmd_p <> nil then begin         {got descriptor for new command ?}
      picprg_cmd_read64 (pr, cmd_p^, stat); {send another command to read a block}
      if sys_error(stat) then return;
      adrc := adrc + blksz;            {update address for next command}
      goto rd64_send;                  {try sending another command}
      end;
    end;

  picprg_cmdovl_in (pr, ovl, cmd_p, stat); {get next command with response data}
  if sys_error(stat) then return;
  picprg_rsp_read64 (pr, cmd_p^, buf64, stat); {get the data from the command}
  if sys_error(stat) then return;
  for i := 0 to blksz-1 do begin       {once for each byte in this buffer}
    if (adrr + i) < adr then next;     {skip bytes before start of return data}
    dat[dati] := picprg_maskit (buf64[i], mask, adr + dati); {return cleaned word}
    dati := dati + 1;                  {advance DAT index}
    if dati >= n then return;          {done returning all DAT words ?}
    end;
  adrr := adrr + blksz;                {update address of next response}
  goto rd64_send;                      {back for next command and/or response}
{
*   Use the RBYTE8 command to read the low bytes of blocks of 8 words.
}
bits8:
  adrc := (adr div 8) * 8;             {init address for next read request}
  adrr := adrc;                        {init address of next read response}
  picprg_cmdw_adr (pr, adrc, stat);    {set the target to address of first read}
  if sys_error(stat) then return;

b8_send:                               {back here to try and send each new command}
  if adrc <= adrl then begin           {need to request more data ?}
    picprg_cmdovl_out (pr, ovl, cmd_p, stat); {try to get output command descriptor}
    if sys_error(stat) then return;
    if cmd_p <> nil then begin         {got descriptor for new command ?}
      picprg_cmd_rbyte8 (pr, cmd_p^, stat); {send another RBYTE8 command}
      if sys_error(stat) then return;
      adrc := adrc + 8;                {update address for next command}
      goto b8_send;                    {try sending another command}
      end;
    end;

  picprg_cmdovl_in (pr, ovl, cmd_p, stat); {get next command with response data}
  if sys_error(stat) then return;
  picprg_rsp_rbyte8 (pr, cmd_p^, buf8, stat); {get the data from the command}
  if sys_error(stat) then return;
  for i := 0 to 7 do begin             {once for each byte in this buffer}
    if (adrr + i) < adr then next;     {skip bytes before start of return data}
    dat[dati] := picprg_maskit (buf8[i], mask, adr + dati); {return cleaned byte}
    dati := dati + 1;                  {advance DAT index}
    if dati >= n then return;          {done returning all DAT words ?}
    end;
  adrr := adrr + 8;                    {update address of next response}
  goto b8_send;                        {back for next command and/or response}
{
*   Use the R30PGM command to read the 6 bytes of 2 consecutive program memory
*   words of dsPIC.
}
r30pgm:
  blksz := 4;
  adrc := (adr div blksz) * blksz;     {init address for next read request}
  adrr := adrc;                        {init address of next read response}
  maske := mask.maske;                 {get mask for words at even addresses}
  masko := mask.masko;                 {get mask for words at odd addresses}
  picprg_cmdw_adr (pr, adrc, stat);    {set the target to address of first read}
  if sys_error(stat) then return;

r30pgm_send:                           {back here to request or read a new block}
  if adrc <= adrl then begin           {not yet requested whole address range ?}
    picprg_cmdovl_out (pr, ovl, cmd_p, stat); {try to get unused command descriptor}
    if sys_error(stat) then return;
    if cmd_p <> nil then begin         {got unused command descriptor ?}
      picprg_cmd_r30pgm (pr, cmd_p^, stat); {request read of next block}
      if sys_error(stat) then return;
      adrc := adrc + blksz;            {update start address of next block request}
      goto r30pgm_send;
      end;
    end;

  picprg_cmdovl_in (pr, ovl, cmd_p, stat); {get next command awaiting a response}
  if sys_error(stat) then return;
  picprg_rsp_r30pgm (pr, cmd_p^, bufds[0], bufds[1], stat); {get the two prog mem words}
  if sys_error(stat) then return;
  for adrw := adrr to adrr+blksz-1 do begin {once for each address in this block}
    if adrw < adr then next;           {skip in in partial block before start address}
    dsd := bufds[(adrw - adrr) div 2]; {get full prog mem word containing data at curr adr}
    if odd(adrw)
      then begin                       {return part of word at odd address}
        dat[dati] := rshft(dsd, 16) & masko;
        end
      else begin                       {return part of word at even address}
        dat[dati] := dsd & maske;
        end
      ;
    dati := dati + 1;                  {make next DAT array index to write to}
    if dati >= n then return;          {done returning all requested data ?}
    end;                               {back to return data at next address}
  adrr := adrr + blksz;                {update start address of next block to read}
  goto r30pgm_send;                    {back to request or read next block}
  end;
