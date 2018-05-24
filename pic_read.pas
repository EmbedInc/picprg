{   Program PIC_READ [options]
*
*   Read the programmed data from a PIC plugged into the PICPRG programmer
*   and write it to a HEX file.
}
program pic_prog;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'stuff.ins.pas';
%include 'picprg.ins.pas';

const
  max_msg_args = 2;                    {max arguments we can pass to a message}

var
  fnam_out:                            {HEX output file name}
    %include '/cognivision_links/dsee_libs/string/string_treename.ins.pas';
  oname_set: boolean;                  {TRUE if the output file name already set}
  name:                                {PIC name selected by user}
    %include '/cognivision_links/dsee_libs/string/string32.ins.pas';
  pr: picprg_t;                        {PICPRG library state}
  tinfo: picprg_tinfo_t;               {configuration info about the target chip}
  dat_p: picprg_datar_p_t;             {pnt to data array for max size data region}
  dat: picprg_dat_t;                   {scratch target data value}
  adr: picprg_adr_t;                   {scratch target address}
  ent_p: picprg_adrent_p_t;            {pointer to address list entry}
  iho: ihex_out_t;                     {HEX file writing state}
  timer: sys_timer_t;                  {stopwatch timer}
  mskinfo: picprg_maskdat_t;           {info about mask of valid bits}
  sz: sys_int_adr_t;                   {memory size}
  i: sys_int_machine_t;                {scratch integer and loop counter}
  r: real;                             {scratch floating point number}
  datwid: sys_int_machine_t;           {data EEPROM word width, bits}
  hdouble: boolean;                    {addresses in HEX file are doubled}
  eedouble: boolean;                   {EEPROM addresses doubled after HDOUBLE appl}
  hexopen: boolean;                    {TRUE when HEX file is open}

  opt:                                 {upcased command line option}
    %include '/cognivision_links/dsee_libs/string/string_treename.ins.pas';
  parm:                                {command line option parameter}
    %include '/cognivision_links/dsee_libs/string/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_opt, done_opt, err_parm, err_conflict, parm_bad, done_opts,
  abort, leave_all;
{
******************************************************************
*
*   Subroutine WRITE_WORD (ADR, W, STAT)
*
*   Write the target data word W at target address ADR to the HEX file.
}
procedure write_word (                 {write one target word to the HEX file}
  in      adr: picprg_adr_t;           {target address of the word}
  in      w: picprg_dat_t;             {the data word}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  hadr: picprg_adr_t;                  {HEX file address of this word}

begin
  hadr := adr;                         {init to write word to its address}
{
*   The address to write this word to in the HEX file is in HADR.
}
  if hdouble
    then begin                         {HEX file addresses are doubled}
      ihex_out_byte (iho, hadr * 2, w & 255, stat); {write low byte}
      if sys_error(stat) then return;
      ihex_out_byte (iho, (hadr * 2) + 1, rshft(w, 8) & 255, stat); {write high byte}
      end
    else begin                         {HEX file addresses are same as target}
      ihex_out_byte (iho, hadr, w & 255, stat); {write low byte of word}
      end
    ;
  end;
{
******************************************************************
*
*   Start of main routine.
}
begin
  sys_timer_init (timer);              {initialize the stopwatch}
  sys_timer_start (timer);             {start the stopwatch}

  string_cmline_init;                  {init for reading the command line}
{
*   Initialize our state before reading the command line options.
}
  picprg_init (pr);                    {select defaults for opening PICPRG library}
  oname_set := false;                  {no output file name specified}
  hexopen := false;                    {init to HEX output file not open}

  sys_envvar_get (                     {init programmer name from environment variable}
    string_v('PICPRG_NAME'),           {environment variable name}
    parm,                              {returned environment variable value}
    stat);
  if not sys_error(stat) then begin    {envvar exists and got its value ?}
    string_copy (parm, pr.prgname);    {initialize target programmer name}
    end;
{
*   Back here each new command line option.
}
next_opt:
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_opts; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  if (opt.len >= 1) and (opt.str[1] <> '-') then begin {implicit pathname token ?}
    if not oname_set then begin        {output file name not set yet ?}
      string_copy (opt, fnam_out);     {set output file name}
      oname_set := true;               {output file name is now set}
      goto next_opt;
      end;
    goto err_conflict;
    end;
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (opt,                {pick command line option name from list}
    '-HEX -SIO -PIC -N -LVP',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -HEX filename
}
1: begin
  if oname_set then goto err_conflict; {output file name already set ?}
  string_cmline_token (fnam_out, stat);
  oname_set := true;
  end;
{
*   -SIO n
}
2: begin
  string_cmline_token_int (pr.sio, stat);
  pr.devconn := picprg_devconn_sio_k;
  end;
{
*   -PIC name
}
3: begin
  string_cmline_token (name, stat);
  string_upcase (name);
  end;
{
*   -N name
}
4: begin
  string_cmline_token (pr.prgname, stat); {get programmer name}
  if sys_error(stat) then goto err_parm;
  end;
{
*   -LVP
}
5: begin
  pr.hvpenab := false;                 {disallow high voltage program mode entry}
  end;
{
*   Unrecognized command line option.
}
otherwise
    string_cmline_opt_bad;             {unrecognized command line option}
    end;                               {end of command line option case statement}
done_opt:                              {done handling this command line option}

err_parm:                              {jump here on error with parameter}
  string_cmline_parm_check (stat, opt); {check for bad command line option parameter}
  goto next_opt;                       {back for next command line option}

err_conflict:                          {this option conflicts with a previous opt}
  sys_msg_parm_vstr (msg_parm[1], opt);
  sys_message_bomb ('string', 'cmline_opt_conflict', msg_parm, 1);

parm_bad:                              {jump here on got illegal parameter}
  string_cmline_reuse;                 {re-read last command line token next time}
  string_cmline_token (parm, stat);    {re-read the token for the bad parameter}
  sys_msg_parm_vstr (msg_parm[1], parm);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);

done_opts:                             {done with all the command line options}
{
*   All done reading the command line.
}
  picprg_open (pr, stat);              {open the PICPRG programmer library}
  sys_error_abort (stat, 'picprg', 'open', nil, 0);
{
*   Get the firmware info and check the version.
}
  picprg_fw_show1 (pr, pr.fwinfo, stat); {show version and organization to user}
  sys_error_abort (stat, '', '', nil, 0);
  picprg_fw_check (pr, pr.fwinfo, stat); {check firmware version for compatibility}
  sys_error_abort (stat, '', '', nil, 0);
{
*   Configure to the specific target chip.
}
  picprg_config (pr, name, stat);      {configure the library to the target chip}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;
  picprg_tinfo (pr, tinfo, stat);      {get detailed info about the target chip}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  sys_msg_parm_vstr (msg_parm[1], tinfo.name);
  sys_msg_parm_int (msg_parm[2], tinfo.rev);
  sys_message_parms ('picprg', 'target_type', msg_parm, 2); {show target name}

  ihex_out_open_fnam (                 {open the HEX output file}
    fnam_out,                          {output file name}
    '.hex',                            {mandatory file name suffix}
    iho,                               {returned HEX file writing state}
    stat);
  if sys_error_check (stat, '', '', nil, 0) then goto abort;
  hexopen := true;                     {indicate the HEX output file is open}
{
*   Allocate an array for holding the maximum size program memory or data
*   memory area.
}
  hdouble :=                           {set flag if HEX file addresses doubled}
    (tinfo.maskprg.maske ! tinfo.maskprg.masko ! 255) <> 255;
  eedouble := not hdouble;             {data adr still doubled after HDOUBLE applied}
  datwid := 8;                         {init size of data EEPROM word}
  case tinfo.fam of                    {special handling for some PIC families}
picprg_picfam_18f_k,                   {PIC 18}
picprg_picfam_18f2520_k,
picprg_picfam_18f2523_k,
picprg_picfam_18f6680_k,
picprg_picfam_18f6310_k,
picprg_picfam_18j_k,
picprg_picfam_18f14k22_k,
picprg_picfam_18f14k50_k: begin
      eedouble := false;
      end;
picprg_picfam_30f_k,
picprg_picfam_24h_k,
picprg_picfam_24f_k: begin
      eedouble := true;
      datwid := 16;
      end;
    end;

  sz := max(tinfo.nprog, tinfo.ndat);  {max words required for any region}
  sz := sz * sizeof(dat_p^[0]);        {memory size needed for the number of words}
  sys_mem_alloc (sz, dat_p);           {allocate the data array}
{
*   Read the regular program memory and write it to the HEX output file.
}
  picprg_read (                        {read the program memory}
    pr,                                {PICPRG library state}
    0,                                 {starting address to read from}
    tinfo.nprog,                       {number of locations to read}
    tinfo.maskprg,                     {mask for valid data bits}
    dat_p^,                            {array to read the data into}
    stat);
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  for i := 0 to tinfo.nprog-1 do begin {once for each data word}
    write_word (i, dat_p^[i], stat);   {write this word to HEX output file}
    if sys_error_check (stat, '', '', nil, 0) then goto abort;
    end;
{
*   Read the non-volatile data memory and write it to the HEX output file.
}
  picprg_space_set (                   {switch to data memory address space}
    pr, picprg_space_data_k, stat);
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  picprg_read (                        {read the data memory}
    pr,                                {PICPRG library state}
    0,                                 {starting address to read from}
    tinfo.ndat,                        {number of locations to read}
    tinfo.maskdat,                     {mask for valid data bits}
    dat_p^,                            {array to read the data into}
    stat);
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  for i := 0 to tinfo.ndat-1 do begin  {once for each data word}
    if eedouble
      then begin                       {each word is written to two addresses}
        write_word (                   {write first byte to HEX output file}
          i * 2 + tinfo.datmap,        {target address}
          dat_p^[i] & tinfo.maskdat.maske, {word at this address}
          stat);
        write_word (                   {write second byte to HEX output file}
          i * 2 + 1 + tinfo.datmap,    {target address}
          rshft(dat_p^[i], datwid) & tinfo.maskdat.masko, {word at this address}
          stat);
        end
      else begin                       {each word goes into a single address}
        write_word (                   {write first byte to HEX output file}
          i + tinfo.datmap,            {target address}
          dat_p^[i],                   {word at this address}
          stat);
        end
      ;
    if sys_error_check (stat, '', '', nil, 0) then goto abort;
    end;

  picprg_space_set (                   {switch back to program memory address space}
    pr, picprg_space_prog_k, stat);
  if sys_error_check (stat, '', '', nil, 0) then goto abort;
{
*   Read the OTHER program memory locations and write them to the HEX
*   output file.
}
  ent_p := tinfo.other_p;              {init to first list entry}
  while ent_p <> nil do begin          {once for address in the list}
    picprg_mask_same (ent_p^.mask, mskinfo); {make mask info for this word}
    picprg_read (                      {read from this address}
      pr,                              {PICPRG library state}
      ent_p^.adr,                      {address to read from}
      1,                               {number of locations to read}
      mskinfo,                         {mask info for this data word}
      dat,                             {the returned data word}
      stat);
    if sys_error_check (stat, '', '', nil, 0) then goto abort;
    write_word (ent_p^.adr, dat, stat); {write the word to the HEX file}
    if sys_error_check (stat, '', '', nil, 0) then goto abort;
    ent_p := ent_p^.next_p;            {advance to the next address in the list}
    end;
{
*   Read the CONFIG program memory locations and write them to the HEX
*   output file.
}
  ent_p := tinfo.config_p;             {init to first list entry}
  while ent_p <> nil do begin          {once for address in the list}
    picprg_mask_same (ent_p^.mask, mskinfo); {make mask info for this word}
    picprg_read (                      {read from this address}
      pr,                              {PICPRG library state}
      ent_p^.adr,                      {address to read from}
      1,                               {number of locations to read}
      mskinfo,                         {mask info for this data word}
      dat,                             {the returned data word}
      stat);
    if sys_error_check (stat, '', '', nil, 0) then goto abort;
    {
    *   Special check for 10F config word.  This config word is always
    *   stored in the HEX file at address FFFh regardless of its real
    *   address in the chip.   Yes, we think that's stupid too, but that's
    *   the way Microchip did it.
    }
    adr := ent_p^.adr;                 {init HEX file address of this word}
    if                                 {check for 10F config word}
        (tinfo.fam = picprg_picfam_10f_k) and {target PIC is a 10F ?}
        (ent_p = tinfo.config_p)       {this is first config word in the list ?}
        then begin
      adr := 16#FFF;                   {switch to special HEX file address}
      string_f_int_max_base (          {make 4 digit HEX address}
        parm, adr, 16, 4, [string_fi_leadz_k, string_fi_unsig_k], stat);
      write ('Switching config word address, ', parm.str:parm.len, ': ');
      string_f_int_max_base (          {make 3 digit HEX contents}
        parm, dat, 16, 3, [string_fi_leadz_k, string_fi_unsig_k], stat);
      writeln (parm.str:parm.len);
      end;
    write_word (adr, dat, stat);       {write the word to the HEX file}
    if sys_error_check (stat, '', '', nil, 0) then goto abort;
    ent_p := ent_p^.next_p;            {advance to the next address in the list}
    end;
{
*   Common point for exiting the program with the PICPRG library open
*   and no error.
}
  ihex_out_close (iho, stat);          {close the HEX output file}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  picprg_cmdw_off (pr, stat);          {turn off power, etc, to the target chip}
  sys_error_abort (stat, '', '', nil, 0);
  picprg_close (pr, stat);             {close the PICPRG library}
  sys_error_abort (stat, 'picprg', 'close', nil, 0);

  sys_timer_stop (timer);              {stop the stopwatch}
  r := sys_timer_sec (timer);          {get total elapsed seconds}
  sys_msg_parm_real (msg_parm[1], r);
  sys_message_parms ('picprg', 'no_errors', msg_parm, 1);

  goto leave_all;
{
*   Error exit point with the PICPRG library open.
}
abort:
  if hexopen then begin
    ihex_out_close (iho, stat);        {close the HEX output file}
    sys_error_print (stat, '', '', nil, 0);
    end;
  picprg_cmdw_off (pr, stat);          {turn off power, etc, to the target chip}
  sys_error_print (stat, '', '', nil, 0);
  picprg_close (pr, stat);             {close the PICPRG library}
  sys_error_print (stat, 'picprg', 'close', nil, 0);
  sys_bomb;                            {exit the program with error status}
leave_all:
  end.
