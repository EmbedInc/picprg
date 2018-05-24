{   Routines for managing and using the data to be programmed into a target.
}
module picprg_tdat;
define picprg_tdat_alloc;
define picprg_tdat_dealloc;
define picprg_tdat_hex_byte;
define picprg_tdat_hex_read;
define picprg_tdat_vdd1;
define picprg_tdat_vddlev;
define picprg_tdat_prog;
define picprg_tdat_verify;
%include '/cognivision_links/dsee_libs/pics/picprg2.ins.pas';
{
********************************************************************************
*
*   Subroutine PICPRG_TDAT_ALLOC (PR, TDAT_P, STAT)
*
*   Allocates a target data descriptor and returns TDAT_P pointing to it.  This
*   descriptor holds data to be programmed into the target and parameters
*   modifying how it is to be programmed.  The specific target chip type must
*   have been previously set in PR, meaning the ID_P field must be pointing to
*   the description of the particular target chip.
*
*   The newly created structure will be set up for the particular use of the
*   PICPRG library PR and the specific target chip.  It may not be used with
*   different instances of the library or different target chips.  It will
*   automatically be deallocated when this use of the library is closed, but can
*   also be deliberately deallocated.
}
procedure picprg_tdat_alloc (          {allocate target address data descriptor}
  in out  pr: picprg_t;                {state for this use of the library}
  out     tdat_p: picprg_tdat_p_t;     {pnt to newly created and initialized descriptor}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  mem_p: util_mem_context_p_t;         {pointer to private memory context for new structure}
  adr: picprg_adr_t;                   {scratch address index}
  ent_p: picprg_adrent_p_t;            {pointer to current special word list entry}
  ii: sys_int_machine_t;               {scratch integer and loop counter}
  dat: picprg_dat_t;                   {scratch single data value}

label
  abort;

begin
  tdat_p := nil;                       {init to not returning with new structure}
  if picprg_nconfig (pr, stat) then return; {not configured to a specific target chip ?}

  util_mem_context_get (pr.mem_p^, mem_p); {create private mem context for new structure}
  util_mem_grab (sizeof(tdat_p^), mem_p^, false, tdat_p); {allocate memory for new structure}
  tdat_p^.pr_p := addr(pr);            {set pointer to associated use of the library}
  tdat_p^.mem_p := mem_p;              {save pointer to private memory context}
{
*   Allocate arrays for program memory.
}
  tdat_p^.val_prog_p := nil;
  if pr.id_p^.nprog > 0 then begin
    util_mem_grab (
      sizeof(tdat_p^.val_prog_p^[0]) * pr.id_p^.nprog, mem_p^, false, tdat_p^.val_prog_p);
    util_mem_grab (
      sizeof(tdat_p^.used_prog_p^[0]) * pr.id_p^.nprog, mem_p^, false, tdat_p^.used_prog_p);
    end;

  for adr := 0 to pr.id_p^.nprog-1 do begin {once for each address of this type}
    tdat_p^.val_prog_p^[adr] := picprg_mask (pr.id_p^.maskprg, adr);
    tdat_p^.used_prog_p^[adr] := false; {init to this word not specified in HEX file}
    end;
  {
  *   Special hack for devices that start at the last location of program
  *   memory (instead of 0 like most) and that locations contains a MOVLW
  *   instruction with the oscillator calibration value.  These are 12 bit core
  *   devices where MOVLW is Cxx with XX being the data to move into W.
  *
  *   As far as we know, these devices also have a "backup OSCCAL" location
  *   where the proper MOVLW instruction is stored during production.  These
  *   have program memory first, then data memory immediately following when
  *   present, then 4 user ID locations, then the backup OSCCAL instruction.
  *   The address of the backup OSCCAL instruction is therefore NPROG + NDAT +
  *   4.
  *
  *   In case the chip got incorrectly erased or corrupted, the calibration
  *   value MOVLW instruction is derived from, in order of priority:
  *
  *     1 - The word at the backup OSCCAL location.
  *
  *     2 - The word at the last address of program memory.  This is where the
  *         processor starts executing after a reset.
  *
  *     3 - C00h.  No information is available about what the calibration word
  *         should be, so it is set to MOVLW 0, which is the middle setting.
  *
  *   A calibration word is considered valid if is is a MOVLW instruction, which
  *   means its value is Cxx.
  }
  if pr.id_p^.fam = picprg_picfam_10f_k then begin {special case for PIC 10F ?}
    picprg_read (                      {read the backup OSCCAL location}
      pr,                              {state for this use of the library}
      pr.id_p^.nprog + pr.id_p^.ndat + 4, {address of backup OSCCAL instruction}
      1,                               {number of locations to read}
      pr.id_p^.maskprg,                {mask for the valid data bits}
      dat,                             {the returned data value}
      stat);
    if sys_error(stat) then goto abort;
    if (dat & 16#F00) <> 16#C00 then begin {backup OSCCAL isn't MOVLW ?}
      picprg_read (                    {read last instruction location (reset vector)}
        pr,                            {state for this use of the library}
        pr.id_p^.nprog - 1,            {address of first executed instruction}
        1,                             {number of locations to read}
        pr.id_p^.maskprg,              {mask for the valid data bits}
        dat,                           {the returned data value}
        stat);
      if sys_error(stat) then goto abort;
      end;
    if (dat & 16#F00) <> 16#C00 then begin {still not a MOVLW instruction ?}
      dat := 16#C00;                   {set to default of MOVLW 0}
      end;
    tdat_p^.val_prog_p^[pr.id_p^.nprog-1] := dat; {init reset vector instruction}
    end;
{
*   Allocate arrays for non-volatile data memory (EEPROM).
}
  tdat_p^.val_data_p := nil;
  if pr.id_p^.ndat > 0 then begin
    util_mem_grab (
      sizeof(tdat_p^.val_data_p^[0]) * pr.id_p^.ndat, mem_p^, false, tdat_p^.val_data_p);
    util_mem_grab (
      sizeof(tdat_p^.used_data_p^[0]) * pr.id_p^.ndat, mem_p^, false, tdat_p^.used_data_p);
    end;

  for adr := 0 to pr.id_p^.ndat-1 do begin {once for each address of this type}
    tdat_p^.val_data_p^[adr] := picprg_mask (pr.id_p^.maskdat, adr);
    tdat_p^.used_data_p^[adr] := false; {init to this word not specified in HEX file}
    end;
{
*   Allocate array for the configuration words.
}
  tdat_p^.ncfg := 0;                   {determine the number of words in the list}
  ent_p := pr.id_p^.config_p;
  while ent_p <> nil do begin
    tdat_p^.ncfg := tdat_p^.ncfg + 1;
    ent_p := ent_p^.next_p;
    end;

  tdat_p^.val_cfg_p := nil;
  if tdat_p^.ncfg > 0 then begin
    util_mem_grab (
      sizeof(tdat_p^.val_cfg_p^[0]) * tdat_p^.ncfg, mem_p^, false, tdat_p^.val_cfg_p);
    end;

  ent_p := pr.id_p^.config_p;          {init pointer to first list entry}
  ii := 0;                             {init values array index for this list entry}
  while ent_p <> nil do begin          {once for each list entry}
    tdat_p^.val_cfg_p^[ii] := ent_p^.mask; {init data to the erased value}
    ent_p := ent_p^.next_p;            {advance to next list entry}
    ii := ii + 1;                      {update values array index for new entry}
    end;
{
*   Allocate arrays for the "other" program memory words.  These are generally
*   the user ID locations.
}
  tdat_p^.noth := 0;                   {determine the number of words in the list}
  ent_p := pr.id_p^.other_p;
  while ent_p <> nil do begin
    tdat_p^.noth := tdat_p^.noth + 1;
    ent_p := ent_p^.next_p;
    end;

  tdat_p^.val_oth_p := nil;
  if tdat_p^.noth > 0 then begin
    util_mem_grab (
      sizeof(tdat_p^.val_oth_p^[0]) * tdat_p^.noth, mem_p^, false, tdat_p^.val_oth_p);
    end;

  ent_p := pr.id_p^.other_p;           {init pointer to first list entry}
  ii := 0;                             {init values array index for this list entry}
  while ent_p <> nil do begin          {once for each list entry}
    tdat_p^.val_oth_p^[ii] := ent_p^.mask; {init data to the erased value}
    ent_p := ent_p^.next_p;            {advance to next list entry}
    ii := ii + 1;                      {update values array index for new entry}
    end;
{
*   Init remaining fields to default or benign values.
}
  tdat_p^.vdd := pr.vdd.norm;          {default to normal Vdd for this target}
  tdat_p^.vdd1 := not pr.vdd.twover;   {single Vdd if set by target chip or programmer}
  tdat_p^.hdouble := pr.id_p^.hdouble;
  tdat_p^.eedouble := pr.id_p^.eedouble;
  return;
{
*   Error encountered with TDAT allocated.  STAT is set indicating the error.
}
abort:
  util_mem_context_del (mem_p);        {deallocate TDAT and any memory associated with it}
  tdat_p := nil;                       {indicate target data structure not allocated}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_TDAT_DEALLOC (TDAT_P)
*
*   Release all resources associated with the target chip data structure pointed
*   to by TDAT_P.  TDAT_P will be returned NIL since the data structure will no
*   longer exist.
}
procedure picprg_tdat_dealloc (        {deallocate target address data descriptor}
  in out  tdat_p: picprg_tdat_p_t);    {pointer to descriptor to deallocate, returned NIL}
  val_param;

var
  mem_p: util_mem_context_p_t;         {pointer to private memory context for new structure}

begin
  mem_p := tdat_p^.mem_p;              {get pointer to memory context}
  util_mem_context_del (mem_p);        {deallocate TDAT and any memory associated with it}
  tdat_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_TDAT_HEX_BYTE (TDAT, DAT, ADR, STAT)
*
*   Update the target chip data according to one HEX file byte.  TDAT is the
*   target chip data descriptor to update.  DAT is the HEX file byte, and ADR is
*   the HEX file address of the byte.
}
procedure picprg_tdat_hex_byte (       {add one byte from HEX file to target data to program}
  in out  tdat: picprg_tdat_t;         {target data to add the byte to}
  in      dat: int8u_t;                {the data byte from the HEX file}
  in      adr: int32u_t;               {the address from the HEX file}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  tadr: picprg_adr_t;                  {target chip address}
  tval: picprg_dat_t;                  {data value in position within target word}
  mask: picprg_dat_t;                  {mask for this value within target word}
  ofs: picprg_adr_t;                   {offset within specific data array}
  a: picprg_adr_t;                     {scratch target address}
  ent_p: picprg_adrent_p_t;            {pointer to address list entry}
  tk: string_var32_t;                  {scratch token}

begin
  sys_error_none (stat);               {init to no error encountered}
  tk.max := size_char(tk.str);         {init local var string}

  if tdat.hdouble
    then begin                         {HEX file addresses are doubled ?}
      tadr := rshft(adr, 1);           {make address of target chip word}
      if odd(adr)
        then begin                     {this is high byte of target data word}
          tval := lshft(dat, 8);       {move data byte into target word position}
          mask := 16#FF00;             {init mask for whole byte within target word}
          end
        else begin                     {this is low byte of target word}
          tval := dat;                 {data byte in target word position}
          mask := 16#FF;               {init mask for whole byte within target word}
          end
        ;
      end
    else begin                         {HEX file addresses match target addresses}
      tadr := adr;                     {target address is HEX file address}
      tval := dat;
      mask := 16#FF;                   {init mask for whole HEX file data byte}
      end
    ;
{
*   TADR is the target address containing the data byte, TVAL is the data
*   byte shifted into position within the target word, and MASK is the mask
*   for the data byte in position within the target word.
*
*   Now do special check for 10F parts.  These have the config word in the
*   HEX file at address FFFh regardless of where it really goes in the
*   chip.
}
  if                                   {check for 10F config word}
      (tdat.pr_p^.id_p^.fam = picprg_picfam_10f_k) and {target PIC is a 10F ?}
      (tadr = 16#FFF) and              {special HEX file config word address ?}
      (tdat.pr_p^.id_p^.config_p <> nil) {config location defined for this target ?}
      then begin
    tadr := tdat.pr_p^.id_p^.config_p^.adr; {switch to real config word address}
    end;
{
*   Check for address is in normal program memory space.
}
  ofs := tadr;                         {offset into array for this address space}
  if ofs < tdat.pr_p^.id_p^.nprog then begin {address is within this space ?}
    mask :=                            {clip mask to actual program memory word}
      picprg_maskit (mask, tdat.pr_p^.id_p^.maskprg, ofs);
    tdat.val_prog_p^[ofs] :=           {merge data byte into this word}
      (tdat.val_prog_p^[ofs] & ~mask) ! (tval & mask);
    tdat.used_prog_p^[ofs] := true;    {indicate this word specified in HEX file}
    return;
    end;
{
*   Check for data memory address space.
}
  ofs := tadr - tdat.pr_p^.id_p^.datmap; {offset into array for this address space}
  a := ofs;                            {init offset into data memory space}
  if tdat.eedouble then begin          {data addresses doubled ?}
    a := rshft(ofs, 1);                {make true offset into data memory space}
    end;
  if a < tdat.pr_p^.id_p^.ndat then begin {address is within this space ?}
    if tdat.eedouble and odd(ofs) then return; {ignore second word of doubled pair}
    mask :=                            {clip mask to actual program memory word}
      picprg_maskit (mask, tdat.pr_p^.id_p^.maskdat, a);
    tdat.val_data_p^[a] :=             {merge data byte into this word}
      (tdat.val_data_p^[a] & ~mask) ! (tval & mask);
    tdat.used_data_p^[a] := true;      {indicate this word specified in HEX file}
    return;
    end;
{
*   Check for address is for a configuration word.
}
  ent_p := tdat.pr_p^.id_p^.config_p;  {init pointer to first list entry}
  ofs := 0;                            {init offset into values array}
  while ent_p <> nil do begin          {scan the list entries}
    if ent_p^.adr = tadr then begin    {address matches this word ?}
      mask := mask & ent_p^.mask;      {clip mask to actual target word}
      tdat.val_cfg_p^[ofs] :=          {merge data byte into this word}
        (tdat.val_cfg_p^[ofs] & ~mask) ! (tval & mask);
      return;
      end;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    ofs := ofs + 1;                    {update values array offset for new entry}
    end;                               {back to process this new list entry}
{
*   Check for address is for an "other" data word.
}
  ent_p := tdat.pr_p^.id_p^.other_p;   {init pointer to first list entry}
  ofs := 0;                            {init offset into values array}
  while ent_p <> nil do begin          {scan the list entries}
    if ent_p^.adr = tadr then begin    {address matches this word ?}
      mask := mask & ent_p^.mask;      {clip mask to actual target word}
      tdat.val_oth_p^[ofs] :=          {merge data byte into this word}
        (tdat.val_oth_p^[ofs] & ~mask) ! (tval & mask);
      return;
      end;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    ofs := ofs + 1;                    {update values array offset for new entry}
    end;                               {back to process this new list entry}
{
*   The target address is not valid for this chip.
}
  string_f_int_max_base (              {make HEX address string}
    tk,                                {output string}
    tadr,                              {input integer}
    16,                                {radix}
    0,                                 {field width, use free form}
    [string_fi_unsig_k],               {input number is unsigned}
    stat);
  sys_stat_set (picprg_subsys_k, picprg_stat_adr_bad_k, stat);
  sys_stat_parm_vstr (tk, stat);
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_TDAT_HEX_READ (TDAT, IHN, STAT)
*
*   Read a HEX file and write the information from that HEX file that is to be
*   programmed into the target chip into TDAT.  IHN is the existing connection
*   to the HEX file.  This routine will start reading at the current position
*   of the HEX file.
}
procedure picprg_tdat_hex_read (       {read HEX file data, build info about what to program}
  in out  tdat: picprg_tdat_t;         {program target info to update}
  in out  ihn: ihex_in_t;              {connection to input HEX file}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  adr: int32u_t;                       {address from HEX file}
  dat: ihex_dat_t;                     {data for sequential bytes from HEX file}
  ndat: sys_int_machine_t;             {number of data bytes}
  ii: sys_int_machine_t;               {scratch integer and loop counter}

begin
  while true do begin                  {keep reading until end of HEX file}
    ihex_in_dat (ihn, adr, ndat, dat, stat);
    if file_eof(stat) then return;     {hit end of HEX file, normal exit condition ?}
    if sys_error(stat) then return;    {hard error reading HEX file ?}
    for ii := 0 to ndat-1 do begin     {once for each byte in this data chunk}
      picprg_tdat_hex_byte (tdat, dat[ii], adr, stat); {update target data to this byte}
      if sys_error(stat) then return;
      adr := adr + 1;                  {make address of next byte}
      end;                             {back to do next byte in this HEX file chunk}
    end;                               {back to get next chunk of data from HEX file}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_TDAT_VDD1 (TDAT, VDD)
*
*   Set to perform all operations at the single Vdd level of VDD volts.
}
procedure picprg_tdat_vdd1 (           {indicate to perform program and verify at single Vdd level}
  in out  tdat: picprg_tdat_t;         {target programming information}
  in      vdd: real);                  {the single Vdd level for all operations}
  val_param;

begin
  tdat.vdd := vdd;
  tdat.vdd1 := true;
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_TDAT_VDDLEV (TDAT, VDDID, VDD, STAT)
*
*   Set the Vdd level to the low, normal, or high value as identified by VDDID.
*   VDD is returned the actual resulting Vdd level in volts.  The new Vdd level
*   may not take effect until the next reset.
}
procedure picprg_tdat_vddlev (         {set one of selected Vdd levels}
  in      tdat: picprg_tdat_t;         {target programming information}
  in      vddid: picprg_vdd_k_t;       {ID for the selected Vdd level}
  out     vdd: real;                   {actual resulting Vdd level in volts}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  r: real;

begin
  if tdat.vdd1
    then begin                         {forced to use a single Vdd level}
      r := tdat.vdd;                   {get the single Vdd level}
      end
    else begin                         {multiple Vdd levels in use}
      case vddid of
picprg_vdd_low_k: r := tdat.pr_p^.vdd.low;
picprg_vdd_high_k: r := tdat.pr_p^.vdd.high;
otherwise
        r := tdat.pr_p^.vdd.norm;
        end;
      end
    ;
  picprg_vddset (tdat.pr_p^, r, vdd, stat); {set Vdd, get actual voltage in VDD}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_TDAT_PROG (TDAT, FLAGS, STAT)
*
*   Program the data described in TDAT into the target.  By default, all data in
*   TDAT is programmed, and all programmable target memory is read back.  FLAGS
*   is a set of flags that modifies the default behavior.  The following flags
*   are supported:
*
*     PICPRG_PROGFLAG_STDOUT_K
*
*       Write progress information to standard output.
*
*     PICPRG_PROGFLAG_NOVER_K
*
*       Do not perform any verification after the programming operation.
*
*     PICPRG_PROGFLAG_VERHEX_K
*
*       Only need to verify those locations where explicit data in TDAT is
*       provided.  By default, all data is verified.  Data not explicitly set
*       in TDAT is verified to be in the erased state.
}
procedure picprg_tdat_prog (           {perform complete program and verify operations}
  in      tdat: picprg_tdat_t;         {info about what to program}
  in      flags: picprg_progflags_t;   {set of option flags}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ent_p: picprg_adrent_p_t;            {pointer to address list entry}
  ii: sys_int_machine_t;               {scratch integer and loop counter}
  mskinfo: picprg_maskdat_t;           {info about mask of valid bits}
  verflags: picprg_verflags_t;         {option flags for verification}
  vdd: real;                           {Vdd level}

begin
  picprg_vddset (tdat.pr_p^, tdat.vdd, vdd, stat); {set Vdd level to use for erase and write}
  if sys_error(stat) then return;
{
*   Erase the target chip.
}
  if picprg_progflag_stdout_k in flags then begin
    sys_message ('picprg', 'erasing');
    end;

  picprg_erase (tdat.pr_p^, stat);     {completely erase the target chip}
  if sys_error(stat) then return;
{
*   Write the regular program memory.
}
  if tdat.pr_p^.id_p^.nprog > 0 then begin {there is program memory ?}
    if picprg_progflag_stdout_k in flags then begin
      sys_message ('picprg', 'prog_prog');
      end;

    picprg_write (                     {write an array to the target chip}
      tdat.pr_p^,                      {PICPRG library state}
      0,                               {starting address}
      tdat.pr_p^.id_p^.nprog,          {number of words to write}
      tdat.val_prog_p^,                {array of data values}
      tdat.pr_p^.id_p^.maskprg,        {mask for valid data bits within word}
      stat);
    if sys_error(stat) then return;
    end;
{
*   Write to the data memory.
}
  if tdat.pr_p^.id_p^.ndat > 0 then begin {there is data memory ?}
    if picprg_progflag_stdout_k in flags then begin
      sys_message ('picprg', 'prog_data');
      end;

    picprg_space_set (                 {switch to data memory address space}
      tdat.pr_p^, picprg_space_data_k, stat);
    if sys_error(stat) then return;
    picprg_write (                     {write an array to the target chip}
      tdat.pr_p^,                      {PICPRG library state}
      0,                               {starting address}
      tdat.pr_p^.id_p^.ndat,           {number of words to write}
      tdat.val_data_p^,                {array of data values}
      tdat.pr_p^.id_p^.maskdat,        {mask for valid data bits within word}
      stat);
    if sys_error(stat) then return;
    picprg_space_set (                 {switch back to program memory address space}
      tdat.pr_p^, picprg_space_prog_k, stat);
    if sys_error(stat) then return;
    end;
{
*   Write to other locations, like ID words, except configuration bits.
}
  if tdat.noth > 0 then begin          {there are "other" words to write ?}
    if picprg_progflag_stdout_k in flags then begin
      sys_message ('picprg', 'prog_other');
      end;

    ent_p := tdat.pr_p^.id_p^.other_p; {init pointer to first list entry}
    ii := 0;                           {init values array index for this list entry}
    while ent_p <> nil do begin        {once for each list entry}
      picprg_mask_same (ent_p^.mask, mskinfo); {make mask info for this word}
      picprg_write (                   {write one word to the target chip}
        tdat.pr_p^,                    {PICPRG library state}
        ent_p^.adr,                    {address of this word}
        1,                             {number of words to write}
        tdat.val_oth_p^[ii],           {the data word to write}
        mskinfo,                       {mask info for this data word}
        stat);
      if sys_error(stat) then return;
      ent_p := ent_p^.next_p;          {advance to next list entry}
      ii := ii + 1;                    {update values array index for new entry}
      end;
    end;
{
*   All but the configuration bits have been written.  Now verify everything
*   written so far.  This must be done before the configuration bits
*   are written because these could enable memory protection.  Once memory
*   protection has been enabled, the regular program and data memories
*   can no longer be read.
}
  if not (picprg_progflag_nover_k in flags) then begin {verification enabled ?}
    verflags := [                      {set fixed verify options}
      picprg_verflag_prog_k,           {verify program memory}
      picprg_verflag_data_k,           {verify data EEPROM}
      picprg_verflag_other_k];         {verify other locations}
    if picprg_progflag_stdout_k in flags then begin {show progress on STD out ?}
      verflags := verflags + [picprg_verflag_stdout_k];
      end;
    if picprg_progflag_verhex_k in flags then begin {verify only explicitly set data ?}
      verflags := verflags + [picprg_verflag_hex_k];
      end;
    discard( picprg_tdat_verify (tdat, verflags, stat) ); {perform the verify operations}
    if sys_error(stat) then return;
    end;
{
*   Write and then verify the configuration bits.
}
  if tdat.ncfg > 0 then begin          {there are config words to write ?}
    if picprg_progflag_stdout_k in flags then begin
      sys_message ('picprg', 'writing_config');
      end;

    ent_p := tdat.pr_p^.id_p^.config_p; {init pointer to first list entry}
    ii := 0;                           {init values array index for this list entry}
    picprg_vddlev (tdat.pr_p^, picprg_vdd_norm_k, stat);
    if sys_error(stat) then return;
    picprg_reset (tdat.pr_p^, stat);   {reset to start up at new voltage}
    if sys_error(stat) then return;
    while ent_p <> nil do begin        {once for each list entry}
      if                               {only write this config word if necessary}
          (not ent_p^.kval) or         {value in target chip not known ?}
          ((xor(tdat.val_cfg_p^[ii], ent_p^.val) & ent_p^.mask) <> 0) {desired value different ?}
          then begin
        picprg_mask_same (ent_p^.mask, mskinfo); {make mask info for this word}
        picprg_write (                 {write one word to the target chip}
          tdat.pr_p^,                  {PICPRG library state}
          ent_p^.adr,                  {address of this word}
          1,                           {number of words to write}
          tdat.val_cfg_p^[ii],         {the data word to write}
          mskinfo,                     {mask info for this data word}
          stat);
        if sys_error(stat) then return;
        end;
      ent_p := ent_p^.next_p;          {advance to next list entry}
      ii := ii + 1;                    {update values array index for new entry}
      end;

    if not (picprg_progflag_nover_k in flags) then begin {verification enabled ?}
      verflags := [picprg_verflag_config_k]; {set fixed verify options}
      if picprg_progflag_stdout_k in flags then begin {show progress on STD out ?}
        verflags := verflags + [picprg_verflag_stdout_k];
        end;
      discard( picprg_tdat_verify (tdat, verflags, stat) ); {do the verify}
      if sys_error(stat) then return;
      end;
    end;                               {end of config words exist case}
  end;
{
********************************************************************************
*
*   Local subroutine VERIFY_ERROR (PROG, ADR, EDAT, ADAT, STAT)
*
*   Set STAT to indicate a verification error.  PROG is TRUE for program memory
*   address space and FALSE for data (EEPROM) address space.  ADR is the address
*   of the mismatch.  EDAT is the expected value at that address, and ADAT is
*   the actual value found at that address.
}
procedure verify_error (               {set STAT to indicate verification error}
  in      prog: boolean;               {program memory, not data EEPROM address space}
  in      adr: picprg_adr_t;           {address at which mismatch was found}
  in      edat: picprg_dat_t;          {expected value}
  in      adat: picprg_dat_t;          {actual value}
  out     stat: sys_err_t);            {returned status to indicate the error}
  val_param; internal;

var
  tk: string_var32_t;                  {scratch token}
  ii: sys_int_machine_t;               {scratch integer}
  stat2: sys_err_t;                    {completion status of subordinate routines}

begin
  tk.max := size_char(tk.str);         {init local var string}

  if prog
    then ii := picprg_stat_verr_prog_k {error is in program memory address space}
    else ii := picprg_stat_verr_data_k; {error is in data EEPROM address space}
  sys_stat_set (picprg_subsys_k, ii, stat); {set STAT to the base error status}

  string_f_int_max_base (              {add HEX address string parameter}
    tk, adr, 16, 0, [string_fi_unsig_k], stat2);
  if sys_error(stat2) then begin
    string_vstring (tk, '???', 3);
    end;
  sys_stat_parm_vstr (tk, stat);

  string_f_int_max_base (              {add expected value parameter}
    tk, edat, 16, 0, [string_fi_unsig_k], stat2);
  if sys_error(stat2) then begin
    string_vstring (tk, '???', 3);
    end;
  sys_stat_parm_vstr (tk, stat);

  string_f_int_max_base (              {add actual value parameter}
    tk, adat, 16, 0, [string_fi_unsig_k], stat2);
  if sys_error(stat2) then begin
    string_vstring (tk, '???', 3);
    end;
  sys_stat_parm_vstr (tk, stat);
  end;
{
********************************************************************************
*
*   Function PICPRG_TDAT_VERIFY (TDAT, FLAGS, STAT)
*
*   Verify that the data described in TDAT is stored in the target chip.  FLAGS
*   is a set of option flags.  The following flags are supported:
*
*     PICPRG_VERFLAG_STDOUT_K
*
*       Write progress information to standard output.
*
*     PICPRG_VERFLAG_PROG_K
*
*       Verify program memory.
*
*     PICPRG_VERFLAG_DATA_K
*
*       Verify data EEPROM.
*
*     PICPRG_VERFLAG_OTHER_K
*
*       Verify other locations.
*
*     PICPRG_VERFLAG_CONFIG_K
*
*       Verify configuration words.
*
*     PICPRG_VERFLAG_HEX_K
*
*       Only need to verify data explicitly set in TDAT.
*
*   The function returns TRUE when all selected data contained the expected
*   values.  The function returns false on error or when a mismatch between
*   the data in the target chip and the expected value is found.  In that case
*   STAT always indicates a error.
}
function picprg_tdat_verify (          {verify actual target data against desired}
  in      tdat: picprg_tdat_t;         {info about what to program}
  in      flags: picprg_verflags_t;    {set of option flags}
  out     stat: sys_err_t)             {completion status}
  :boolean;                            {all verified memory matched expected value}
  val_param;

const
  max_msg_args = 1;                    {max arguments we can pass to a message}

var
  adr: picprg_adr_t;                   {starting address of current verify block}
  nadr: sys_int_machine_t;             {number of address in current verify block}
  ii: sys_int_machine_t;               {scratch integer and loop counter}
  dat_p: picprg_datar_p_t;             {pointer to array to read data into}
  dat: picprg_dat_t;                   {scratch target word data value}
  ent_p: picprg_adrent_p_t;            {pointer to address list entry}
  passn: sys_int_machine_t;            {1-N number of pass}
  vdd: real;                           {Vdd level of the current pass}
  r: real;                             {scratch floating point}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;
  tk: string_var32_t;                  {scratch token}

label
  done_prog, done_data, done_other, done_config, error;

begin
  tk.max := size_char(tk.str);         {init local var string}
  sys_error_none (stat);               {init to no error encountered}
  picprg_tdat_verify := false;         {init to data mismatch or error}
{
*   Allocate one data array that can hold the data from any of the
*   two regions that will be read as whole arrays in one operation.
}
  ii := max(tdat.pr_p^.id_p^.nprog, tdat.pr_p^.id_p^.ndat); {max entries in either array}
  sys_mem_alloc (sizeof(dat_p^[0]) * ii, dat_p); {allocate the readback data array}
{
*   Set up for multiple passes at different voltage levels, or a single pass if
*   only verifying at one voltage.
}
  for passn := 1 to 2 do begin         {once for each pass}
    {
    *   Set the Vdd level if doing multiple verify passes as different Vdd
    *   levels.
    }
    case passn of                      {which pass is this ?}
1:    r := tdat.pr_p^.vdd.high;
2:    r := tdat.pr_p^.vdd.low;
      end;
    if tdat.vdd1 then begin            {single Vdd level ?}
      r := tdat.vdd;                   {get that Vdd level}
      end;
    picprg_vddset (tdat.pr_p^, r, vdd, stat); {set Vdd, get actual voltage in VDD}
    if sys_error(stat) then goto error;

    if not tdat.vdd1 then begin        {actually setting to different Vdd level ?}
      picprg_reset (tdat.pr_p^, stat); {make sure new Vdd level takes effect}
      if sys_error(stat) then goto error;
      end;

    if picprg_verflag_stdout_k in flags then begin
      sys_msg_parm_real (msg_parm[1], vdd);
      sys_message_parms ('picprg', 'verifying', msg_parm, 1);
      end;
{
*   Verify normal program memory.
}
    if not (picprg_verflag_prog_k in flags) then goto done_prog; {don't verify program memory ?}

    adr := 0;                          {init where to start verifying first block}
    while adr < tdat.pr_p^.id_p^.nprog do begin {keep doing blocks until all program memory covered}
      nadr := tdat.pr_p^.id_p^.nprog - adr; {init size of this block to all remaining memory}
      if picprg_verflag_hex_k in flags then begin {only verify data explicitly set ?}
        while not tdat.used_prog_p^[adr] do begin {skip over unspecified locations}
          adr := adr + 1;              {advance to next location}
          if adr >= tdat.pr_p^.id_p^.nprog then goto done_prog; {hit end of this memory space ?}
          end;
        nadr := 1;                     {init number of addresses in this block}
        for ii := 1 to tdat.pr_p^.id_p^.nprog - adr - 1 do begin {scan up to end of address space}
          if not tdat.used_prog_p^[adr + ii] then exit; {hit first unused location after block ?}
          nadr := nadr + 1;            {expand block to include this location}
          end;
        if picprg_verflag_stdout_k in flags then begin
          string_f_int24h (tk, adr);
          write ('  Prog ', tk.str:tk.len);
          string_f_int24h (tk, adr + nadr - 1);
          writeln (' - ', tk.str:tk.len);
          end;
        end;                           {end of only verify specifically set locations}
      picprg_read (                    {read this block}
        tdat.pr_p^,                    {PICPRG library state}
        adr,                           {first address to read}
        nadr,                          {number of locations to read}
        tdat.pr_p^.id_p^.maskprg,      {mask info for valid data bits}
        dat_p^,                        {array to read the values into}
        stat);
      if sys_error(stat) then goto error;
      for ii := 0 to nadr-1 do begin   {once for each word this block}
        if dat_p^[ii] <> tdat.val_prog_p^[ii+adr] then begin {found a mismatch ?}
          verify_error (               {set STAT to indicate the error}
            true, ii+adr, tdat.val_prog_p^[ii+adr], dat_p^[ii], stat);
          goto error;
          end;
        end;
      adr := adr + nadr + 1;           {first address next block could start on}
      end;                             {back to do next block starting at or after ADR}

done_prog:
{
*   Verify data EEPROM.
}
    if picprg_verflag_data_k in flags then begin {verification of this memory enabled ?}

      picprg_space_set (               {switch to data memory address space}
        tdat.pr_p^, picprg_space_data_k, stat);
      if sys_error(stat) then goto error;
      adr := 0;                        {init where to start verifying first block}
      while adr < tdat.pr_p^.id_p^.ndat do begin {keep doing blocks until all data memory covered}
        nadr := tdat.pr_p^.id_p^.ndat - adr; {init size of this block to all remaining memory}
        if picprg_verflag_hex_k in flags then begin {only verify data explicitly set ?}
          while not tdat.used_data_p^[adr] do begin {skip over unspecified locations}
            adr := adr + 1;            {advance to next location}
            if adr >= tdat.pr_p^.id_p^.ndat then goto done_data; {hit end of this memory space ?}
            end;
          nadr := 1;                   {init number of addresses in this block}
          for ii := 1 to tdat.pr_p^.id_p^.ndat - adr - 1 do begin {scan up to end of address space}
            if not tdat.used_data_p^[adr + ii] then exit; {hit first unused location after block ?}
            nadr := nadr + 1;          {expand block to include this location}
            end;
          if picprg_verflag_stdout_k in flags then begin
            string_f_int24h (tk, adr);
            write ('  Data ', tk.str:tk.len);
            string_f_int24h (tk, adr + nadr - 1);
            writeln (' - ', tk.str:tk.len);
            end;
          end;
        picprg_read (                  {read this block}
          tdat.pr_p^,                  {PICPRG library state}
          adr,                         {first address to read}
          nadr,                        {number of locations to read}
          tdat.pr_p^.id_p^.maskdat,    {mask info for valid data bits}
          dat_p^,                      {array to read the values into}
          stat);
        if sys_error(stat) then goto error;
        for ii := 0 to nadr-1 do begin {once for each word this block}
          if dat_p^[ii] <> tdat.val_data_p^[ii+adr] then begin {found a mismatch ?}
            verify_error (             {set STAT to indicate the error}
              false, ii+adr, tdat.val_data_p^[ii+adr], dat_p^[ii], stat);
            goto error;
            end;
          end;
        adr := adr + nadr + 1;         {first address next block could start on}
        end;                           {back to do next block starting at or after ADR}

done_data:                             {done verifying data memory}
      picprg_space_set (               {switch back to program memory address space}
        tdat.pr_p^, picprg_space_prog_k, stat);
      if sys_error(stat) then goto error;
      end;                             {end of data memory verification enabled}
{
*   Verify "other" memory.
}
    if not (picprg_verflag_other_k in flags) then goto done_other; {don't verify this mem ?}

    ent_p := tdat.pr_p^.id_p^.other_p; {init to first entry in list}
    ii := 0;                           {init data values array index}
    while ent_p <> nil do begin        {once for each address in the list}
      picprg_cmdw_adr (tdat.pr_p^, ent_p^.adr, stat); {set to address of this word}
      if sys_error(stat) then goto error;
      picprg_cmdw_read (tdat.pr_p^, dat, stat); {read the data at this address}
      if sys_error(stat) then goto error;
      dat := dat & ent_p^.mask;        {mask in only the valid data bits}
      if dat <> tdat.val_oth_p^[ii] then begin
        verify_error (                 {set STAT to indicate the error}
          true, ent_p^.adr, tdat.val_oth_p^[ii], dat, stat);
        goto error;
        end;
      ent_p := ent_p^.next_p;          {advance to next list entry}
      ii := ii + 1;                    {update values array offset for new entry}
      end;                             {back to check next location}

done_other:
{
*   Verify the configuration words.
}
    if not (picprg_verflag_config_k in flags) then goto done_config; {don't verify this mem ?}

    ent_p := tdat.pr_p^.id_p^.config_p; {init to first entry in list}
    ii := 0;                           {init data values array index}
    while ent_p <> nil do begin        {once for each address in the list}
      picprg_cmdw_adr (tdat.pr_p^, ent_p^.adr, stat); {set to address of this word}
      if sys_error(stat) then goto error;
      picprg_cmdw_read (tdat.pr_p^, dat, stat); {read the data at this address}
      if sys_error(stat) then goto error;
      dat := dat & ent_p^.mask;        {mask in only the valid data bits}
      if dat <> tdat.val_cfg_p^[ii] then begin
        verify_error (                 {set STAT to indicate the error}
          true, ent_p^.adr, tdat.val_cfg_p^[ii], dat, stat);
        return;
        end;
      ent_p := ent_p^.next_p;          {advance to next list entry}
      ii := ii + 1;                    {update values array offset for new entry}
      end;                             {back to check next location}

done_config:
{
*   Done verify pass at one Vdd level.
}
    if tdat.vdd1 then exit;            {verifying at single Vdd, don't do more passes ?}
    end;                               {back to do next pass}

  sys_mem_dealloc (dat_p);             {deallocate the readback array}
  picprg_tdat_verify := true;          {indicate everything checked}
  return;
{
*   Error detected with DAT array allocated.  STAT is indicating the error.
}
error:
  sys_mem_dealloc (dat_p);             {deallocate the readback array}
  end;                                 {return with error}
