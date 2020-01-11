{   Routines that write data to the target chip.
}
module picprg_write;
define picprg_write;
define picprg_write8b;
define picprg_write_targw;
%include 'picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_WRITE (PR, ADR, N, DAT, MASK, STAT)
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
*   erased.  An actual write is avoided when the data value for a word
*   matches the erased value, which is all implemented bits 1.  MASK is
*   used to determine which bits are implemented.
*
*   This is a low level routine that does not check whether the address
*   range is valid for this target.  The write operations are performed
*   as requested but not verified.  The current address is left at the
*   last address written plus 1.
*
*   This routine calls the specific WRITE routine that is currently
*   configured.  It is an error if no WRITE routine has been selected.
}
procedure picprg_write (               {write array of data to the target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if pr.write_p = nil then begin       {no write routine installed ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_nwrite_k, stat);
    return;
    end;

  pr.write_p^ (addr(pr), adr, n, dat, mask, stat);
  pr.flags := pr.flags - [picprg_flag_w1_k]; {reset write single words override}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_WRITE8B (PR, OVL, DAT, STAT)
*
*   Write 8 bytes to the target.  Only the low 8 bits of the first 8 words
*   of DAT are used.
*
*   This subroutine uses the WRITE8 command if available, otherwise it
*   uses the WRITE command 8 times.  This is a low level write routine,
*   and various restrictions may exist or setup need to be performed
*   depending on the target chip.
}
procedure picprg_write8b (             {write 8 bytes, uses WRITE or WRITE8 cmd}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  ovl: picprg_cmdovl_t;        {overlapped commands state}
  in      dat: univ picprg_datar_t;    {8 data words to write, only low bytes used}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}
  d: picprg_dat_t;                     {scratch data word}
  cmd_p: picprg_cmd_p_t;               {pointer to command descriptor to fill in}

begin
  if pr.fwinfo.cmd[60] then begin      {WRITE8 command is available ?}
    picprg_cmdovl_outw (pr, ovl, cmd_p, stat); {get next command descriptor}
    if sys_error(stat) then return;
    picprg_cmd_write8 (pr, cmd_p^, dat, stat); {use single WRITE8 command}
    return;
    end;
{
*   WRITE8 command is not available, use successive WRITE commands.
}
  for i := 0 to 7 do begin             {once for each word to write}
    d := dat[i] ! ~255;                {make word with all high bits 1}
    picprg_cmdovl_outw (pr, ovl, cmd_p, stat); {get next command descriptor}
    if sys_error(stat) then return;
    picprg_cmd_write (pr, cmd_p^, d, stat);
    if sys_error(stat) then return;
    end;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_WRITE_TARGW (PR, ADR, N, DAT, MASK, STAT)
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
*   erased.  An actual write is avoided when the data value for a word
*   matches the erased value, which is all implemented bits 1.  MASK is
*   used to determine which bits are implemented.
*
*   This is a low level routine that does not check whether the address
*   range is valid for this target.  The write operations are performed
*   as requested but not verified.  The current address is left at the
*   last address written plus 1.
*
*   This version of the array write routine sends a ADR command to the
*   target followed by one WRITE command for each word.  The commands
*   are overlapped to the extent possible.  The overlapping pipeline
*   is drained before this routine returns, so it is more efficient
*   to call it once with a large array than several times with smaller
*   arrays.
*
*   Whole write buffers full are always written.  If the supplied information
*   does not completely cover a write buffer, then the remaining words are
*   sent as all 1s.  Since this is the erased value and write operations can
*   generally only change 1 bits to 0, sending all 1s has the effect of
*   leaving the original value intact.
*
*   If all supplied bits in a write buffer are 1, write buffer applies
*   to the address, and write buffer is enabled, then the write is skipped.
*   If PICPRG_FLAG_W1_K is set in PR.FLAGS, then write buffer use is
*   disabled, all writes are performed as single words, and no writes are
*   skipped if all bits are 1.
*
*   The write buffer, if used, must be a power of 2 in size.
}
procedure picprg_write_targw (         {array write using programmer WRITE command}
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

var
  ovl: picprg_cmdovl_t;                {overlapped commands control state}
  cmd_p: picprg_cmd_p_t;               {pointer to command descriptor to fill in}
  d: picprg_dat_t;                     {scratch data word}
  a: picprg_adr_t;                     {current address}
  adrlast: picprg_adr_t;               {address of last word in DAT}
  mv: picprg_dat_t;                    {mask of valid bits for this word}
  wbuf: array[0 .. buflast_k] of picprg_dat_t; {local copy of write buffer}
  wbsz: sys_int_machine_t;             {write buffer size in use}
  abst, aben: picprg_adr_t;            {start and end addresses of write buffer}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  tadr: picprg_adr_t;                  {current target chip address}
  adrset: boolean;                     {target chip address is set for next write}
  z: boolean;                          {at least one zero data bit in write buf}

label
  have_wbsz, next_adr;

begin
  sys_error_none(stat);                {init to no error encountered}
  picprg_cmdovl_init (ovl);            {init overlapped commands state}

  adrset := false;                     {init to target address is not set}
  tadr := 0;                           {init target chip address (but still invalid)}
  adrlast := adr + n - 1;              {address for last word in DAT}

  a := adr;                            {init current address to first word in DAT}
  while a <= adrlast do begin          {keep looping until all words in DAT used}
{
*   Set WBSZ to the size of the write buffer for the current conditions
*   at address A.
}
    wbsz := 1;                         {init to single word writes}
    if pr.space <> picprg_space_prog_k {not in program memory address space ?}
      then goto have_wbsz;
    if picprg_flag_w1_k in pr.flags    {buffered writes explicitly disabed ?}
      then goto have_wbsz;
    if adr < pr.id_p^.wbstrt           {before start of write buffered range ?}
      then goto have_wbsz;
    if adr >= (pr.id_p^.wbstrt + pr.id_p^.wblen) {past end of write buffered range ?}
      then goto have_wbsz;
    wbsz := pr.id_p^.wbufsz;           {use write buffer size of this target}
have_wbsz:                             {WBSZ is size of write buffer to use}
    if wbsz > bufmax_k then begin      {write buffer larger than supported here ?}
      sys_stat_set (picprg_subsys_k, picprg_stat_wbufbig_k, stat);
      sys_stat_parm_int (wbsz, stat);
      sys_stat_parm_str ('PICPRG_WRITE_TARGW', stat);
      return;
      end;
    i := a div wbsz;                   {make number of write buffer chunk}
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

    if not z then begin                {no zero bits to write ?}
      adrset := false;                 {indicate address in target chip needs to be set}
      goto next_adr;                   {skip the actual write}
      end;
{
*   Write the values in the local write buffer to the target chip.
}
    if (not adrset) or (tadr <> abst) then begin {need to set target chip address ?}
      picprg_cmdovl_outw (pr, ovl, cmd_p, stat); {get next command descriptor}
      if sys_error(stat) then return;
      picprg_cmd_adr (pr, cmd_p^, abst, stat); {set target to write buf start adr}
      if sys_error(stat) then return;
      adrset := true;
      end;

    for a := abst to aben do begin     {once for each word in the write buffer}
      picprg_cmdovl_outw (pr, ovl, cmd_p, stat); {get next command descriptor}
      if sys_error(stat) then return;
      picprg_cmd_write (pr, cmd_p^, wbuf[a - abst], stat); {send this word}
      if sys_error(stat) then return;
      end;
    tadr := aben + 1;                  {update local copy of target chip curr adr}

next_adr:                              {advance to the next address}
    a := aben + 1;                     {start next loop right after this write buf}
    end;                               {back to write next chunk containing adr A}
{
*   Done with all the writes.  Now wait for any pending commands to complete.
}
  picprg_cmdovl_flush (pr, ovl, stat); {wait for all buffered commands to complete}
  end;
