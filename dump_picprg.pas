{   Program DUMP_PICPRG
*
*   Write all the information in the global PICPRG.ENV file to PICPRG.ENV in the
*   current directory.  The data is sorted by PIC name and written in a
*   consistend format.  This program is intended for cleaning up the PICPRG.ENV
*   file after manual editing.
}
program dump_picprg;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'stuff.ins.pas';
%include 'picprg.ins.pas';

type
  pics_t = array[1 .. 1] of picprg_idblock_p_t; {array of pointers to PIC descriptors}
  pics_p_t = ^pics_t;

var
  pr: picprg_t;                        {PICPRG library state}
  pic_p: picprg_idblock_p_t;           {info about one PIC}
  prev_p: picprg_idblock_p_t;          {points to previous PIC in list}
  npics: sys_int_machine_t;            {number of PICs}
  nunique: sys_int_machine_t;          {numer of unique PICs found}
  org: picprg_org_k_t;                 {organization ID}
  ii, jj, kk: sys_int_machine_t;       {scratch integers}
  conn: file_conn_t;                   {connection to the output file}
  obuf:                                {one line output buffer}
    %include '(cog)lib/string256.ins.pas';
  pics_p: pics_p_t;                    {points to dynamically allocated array of PIC pointers}
  idname_p: picprg_idname_p_t;
  idname2_p: picprg_idname_p_t;
  adr_p: picprg_adrent_p_t;            {pointer to address descriptor}
  adr2_p: picprg_adrent_p_t;
  pbits: sys_int_machine_t;            {bits in widest program memory word}
  diffs:
    %include '(cog)lib/string80.ins.pas';
  tk:                                  {scratch token}
    %include '(cog)lib/string32.ins.pas';
  hasid: boolean;                      {PIC has chip ID}
  stat: sys_err_t;

label
  dupdiff;
{
********************************************************************************
*
*   Subroutine WLINE
*
*   Write the string in the output buffer OBUF as the next output file line,
*   then reset the output buffer to empty.
}
procedure wline;
  val_param;

var
  stat: sys_err_t;

begin
  file_write_text (obuf, conn, stat);  {write the line to the output file}
  sys_error_abort (stat, '', '', nil, 0);
  obuf.len := 0;                       {reset the output buffer to empty}
  end;
{
********************************************************************************
*
*   Subroutine WSTR (STR)
*
*   Add the string STR to the end of the current output file line.
}
procedure wstr (                       {write string to output file line}
  in      str: univ string_var_arg_t); {the string to write}
  val_param;

begin
  string_append (obuf, str);
  end;
{
********************************************************************************
*
*   Subroutine WS (S)
*
*   Write the string S to the end of the current output file line.
}
procedure ws (                         {write token to output file line}
  in      s: string);                  {the token string}
  val_param;

var
  tk: string_var256_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_vstring (tk, s, size_char(s)); {convert to to var string}
  wstr (tk);                           {write the var string as the next token}
  end;
{
********************************************************************************
*
*   Subroutine WTK (TK)
*
*   Write the string TK as the next token to the current output file line.
}
procedure wtk (                        {write token to output file line}
  in      tk: univ string_var_arg_t);  {token to add}
  val_param;

begin
  string_append_token (obuf, tk);
  end;
{
********************************************************************************
*
*   Subroutine WTKS (S)
*
*   Write the string S as the next output line token.
}
procedure wtks (                       {write token to output file line}
  in      s: string);                  {the token string}
  val_param;

var
  tk: string_var256_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_vstring (tk, s, size_char(s)); {convert to to var string}
  wtk (tk);                            {write the var string as the next token}
  end;
{
********************************************************************************
*
*   Subroutine WINT (I, BASE, ND)
*
*   Write the integer value I as the next token to the current output line.  The
*   value will be written using the number base (radix) BASE.  ND is the number
*   of digits.  Leading zeros will be added as needed to fill the field.  ND = 0
*   indicates to use only the mininum number of digits necessary with no leading
*   zeros.
}
procedure wint (                       {write integer to output file line}
  in      i: sys_int_machine_t;        {the integer value}
  in      base: sys_int_machine_t;     {number base (radix)}
  in      nd: sys_int_machine_t);      {fixed number of digits}
  val_param;

var
  tk: string_var80_t;                  {scratch token}
  tki: string_var80_t;                 {integer string}
  flags: string_fi_t;                  {string conversion modifier flags}
  stat: sys_err_t;                     {completion status}

begin
  tk.max := size_char(tk.str);         {init local var string}
  tki.max := size_char(tki.str);

  if (i = 0) and (nd = 0) then begin   {special case of free format zero ?}
    tk.str[1] := '0';
    tk.len := 1;
    wtk (tk);
    return;
    end;

  tk.len := 0;                         {init output token to empty}
  if base <> 10 then begin             {not decimal, need radix prefix ?}
    string_f_int (tk, base);           {init token with number base string}
    string_append1 (tk, '#');          {separator before integer digits}
    end;

  flags := [string_fi_leadz_k];        {add leading zeros as needed to fill field}
  if base <> 10 then begin             {not decimal ?}
    flags := flags + [string_fi_unsig_k]; {treat the input number as unsigned}
    end;
  string_f_int_max_base (              {convert integer to string representation}
    tki,                               {output string}
    i,                                 {input integer}
    base,                              {number base (radix)}
    nd,                                {number of digits, 0 = free form}
    flags,                             {modifier flags}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  string_append (tk, tki);             {make final integer token}
  wtk (tk);                            {write it to the output line}
  end;
{
********************************************************************************
*
*   Subroutine WFP (FP, ND)
*
*   Write the floating point value FP as the next token to the current output
*   line.  ND is the number of digits to write right of the decimal point.
}
procedure wfp (                        {write floating point token to output file line}
  in      fp: real;                    {the floating point value}
  in      nd: sys_int_machine_t);      {number of digits right of decimal point}
  val_param;

var
  tk: string_var32_t;                  {scratch token}

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_fp_fixed (tk, fp, nd);      {make string representation of FP number}
  wtk (tk);                            {write it to the output line}
  end;
{
********************************************************************************
*
*   Subroutine WCFG (ADR, MASK, NBITS)
*
*   Write the CONFIG command for the word at address ADR with the mask MASK.
*   The mask will be written in binary with NBITS bits.
}
procedure wcfg (                       {write one CONFIG command}
  in      adr: picprg_adr_t;           {address of the config word}
  in      mask: picprg_dat_t;          {the mask for this config word}
  in      nbits: sys_int_machine_t);   {config word width in bits}
  val_param;

begin
  ws ('  '(0));                        {indent into this ID block}
  wtks ('config');                     {command name}
  wint (adr, 16, 0);                   {address}
  if mask = 0
    then begin                         {this config word isn't really used}
      wtks ('0');
      end
    else begin                         {at least one bit is used in this config word}
      wint (mask, 2, nbits);           {show the mask in binary}
      end
    ;
  wline;
  end;
{
********************************************************************************
*
*   Subroutine DOCONFIG_18 (PIC)
*
*   Write the CONFIG commands for a PIC 18.
}
procedure doconfig_18 (                {write config commands for PIC 18}
  in      pic: picprg_idblock_t);      {descriptor for the particular PIC}
  val_param;

var
  cfg: array[0 .. 15] of picprg_dat_t; {mask values for each config word}
  cfgst, cfgen: picprg_adr_t;          {config word start and end addresses}
  cfgn: sys_int_machine_t;             {number of config words}
  a: picprg_adr_t;                     {config word address}
  alast: picprg_adr_t;                 {config word that must be written last, 0 = none}
  adr_p: picprg_adrent_p_t;            {pointer to address descriptor}

begin
  if pic.config_p = nil then return;   {no config addresses, nothing to write ?}

  a := pic.config_p^.adr;              {get address of first listed config word}
  alast := 0;                          {init to no word needs to be written last}
  if a >= 16#300000
    then begin                         {normal 18F config address range}
      cfgst := 16#300000;
      cfgn := 16;
      alast := 16#30000B;
      end
    else begin                         {special 18FJ config address range}
      cfgst := a & 16#FFFFF8;
      cfgn := 8;
      end
    ;
  cfgen := cfgst + cfgn - 1;           {last config word address}

  for a := 0 to 15 do begin            {init all config words to unused (mask = 0)}
    cfg[a] := 0;
    end;

  adr_p := pic.config_p;
  while adr_p <> nil do begin          {scan the list of defined config words}
    a := adr_p^.adr;                   {get the address of this config word}
    if (a < cfgst) or (a > cfgen) then begin
      writeln ('Config address of ', a, ' is out of range for PIC 18.');
      sys_bomb;
      end;
    cfg[a - cfgst] := adr_p^.mask;     {set mask for this config address}
    adr_p := adr_p^.next_p;
    end;

  for a := cfgst to cfgen do begin     {write all but the word that must be last}
    if a = alast then next;
    wcfg (a, cfg[a - cfgst], 8);
    end;

  if alast <> 0 then begin             {a word must be written last ?}
    wcfg (alast, cfg[alast - cfgst], 8);
    end;
  end;
{
********************************************************************************
*
*   Subroutine DOCONFIG_30 (PIC)
*
*   Write the CONFIG commands for a PIC 30.
}
procedure doconfig_30 (                {write config commands for PIC 30}
  in      pic: picprg_idblock_t);      {descriptor for the particular PIC}
  val_param;

const
  cfgst = 16#F80000;                   {config words start address}
  cfgn = 32;                           {number of config words}
  cfgen = cfgst + cfgn - 1;            {config words end address}

var
  cfg: array[cfgst .. cfgen] of picprg_dat_t; {mask values for each config word}
  a: picprg_adr_t;                     {config word address}
  adr_p: picprg_adrent_p_t;            {pointer to address descriptor}
  nbits: sys_int_machine_t;            {width of mask value}
  lastu: sys_int_machine_t;            {last used address}
  tk: string_var32_t;                  {scratch token}

begin
  if pic.config_p = nil then return;   {no config addresses, nothing to write ?}
  tk.max := size_char(tk.str);         {init local var string}

  for a := cfgst to cfgen do begin     {init all config words to unused (mask = 0)}
    cfg[a] := 0;
    end;

  nbits := 8;                          {init to masks are only 8 bits wide}
  lastu := cfgst + 14;                 {init minimum last used config address}
  adr_p := pic.config_p;               {init to first config word in list}
  while adr_p <> nil do begin          {scan the list of defined config words}
    a := adr_p^.adr;                   {get the address of this config word}
    if (a < cfgst) or (a > cfgen) then begin
      string_f_int32h (tk, a);
      writeln ('Config address of ', tk.str:tk.len, 'h is out of range');
      writeln ('in definition of ', pic.name_p^.name.str:pic.name_p^.name.len);
      sys_bomb;
      end;
    cfg[a] := adr_p^.mask;             {set mask for this config address}
    if (adr_p^.mask & ~255) <> 0 then begin {this mask wider than 8 bits ?}
      nbits := 16;
      end;
    lastu := max(lastu, a);            {update last used address}
    adr_p := adr_p^.next_p;
    end;
  lastu := lastu ! 1;                  {always end on odd address}

  for a := cfgst to lastu do begin     {write the CONFIG commands}
    wcfg (a, cfg[a], nbits);
    end;
  end;
{
********************************************************************************
*
*   Subroutine DOOTHER_30 (PIC)
*
*   Write the OTHER commands for a PIC 30 and related.
}
procedure doother_30 (                 {write OTHER commands for PIC 30}
  in      pic: picprg_idblock_t);      {descriptor for the particular PIC}
  val_param;

var
  adr_p: picprg_adrent_p_t;            {pointer to address descriptor}
  bitw: sys_int_machine_t;             {width of data for curr address, bits}

begin
  adr_p := pic.other_p;                {point to first OTHER word}
  while adr_p <> nil do begin          {once for each OTHER list entry}
    if odd(adr_p^.adr)                 {determine number of bits at this address}
      then bitw := 8
      else bitw := 16;
    ws ('  '(0));
    wtks ('other');
    wint (adr_p^.adr, 16, 0);          {write address}
    wint (adr_p^.mask, 16, (bitw + 3) div 4);
    wline;
    if not odd(adr_p^.adr) then begin  {just wrote even (low) adr of prog mem word ?}
      if                               {need implicit 0 for high byte ?}
          (adr_p^.next_p = nil) or else
          (adr_p^.next_p^.adr <> adr_p^.adr+1)
          then begin
        ws ('  '(0));
        wtks ('other');
        wint (adr_p^.adr+1, 16, 0);    {write address of high byte}
        wint (0, 16, 2);
        wline;
        end;
      end;
    adr_p := adr_p^.next_p;            {advance to next entry in list}
    end;
  end;
{
********************************************************************************
*
*   Start of main routine.
}
begin
  string_cmline_init;                  {init for reading the command line}
  string_cmline_end_abort;             {no command line parameters allowed}

  picprg_init (pr);                    {init library state}
  picprg_open (pr, stat);              {open the PICPRG library}
  sys_error_abort (stat, '', '', nil, 0);

  npics := 0;                          {init number of PICs found config info for}
  pic_p := pr.env.idblock_p;           {init to first PIC in list}
  while pic_p <> nil do begin          {once for each PIC in list}
    npics := npics + 1;                {count one more PIC}
    pic_p := pic_p^.next_p;            {advance to next PIC in list}
    end;

  writeln (npics, ' PICs in list');
  if npics <= 0 then return;

  file_open_write_text (string_v('picprg'), '.env', conn, stat); {open the output file}
  sys_error_abort (stat, '', '', nil, 0);
{
*   Make the PICs list.  This is a list of pointers to the PIC descriptors.
}
  sys_mem_alloc (                      {allocate memory for the list}
    sizeof(pics_p^[1]) * npics,        {amount of memory to allocate}
    pics_p);                           {returned pointer to the new memory}

  ii := 0;                             {init number of PICs written to list}
  pic_p := pr.env.idblock_p;           {init to first PIC in list}
  while pic_p <> nil do begin          {once for each PIC in list}
    ii := ii + 1;                      {make list index of this PIC}
    pics_p^[ii] := pic_p;              {fill in this list entry}
    pic_p := pic_p^.next_p;            {advance to next PIC in list}
    end;
{
*   Sort the PICs list by ascending PIC name.
}
  for ii := 1 to npics-1 do begin      {outer sort loop}
    for jj := ii+1 to npics do begin   {inner sort loop}
      if string_compare_opts (         {entries out of order ?}
          pics_p^[ii]^.name_p^.name,   {first entry in list}
          pics_p^[jj]^.name_p^.name,   {second entry in list}
          [])
          > 0 then begin
        pic_p := pics_p^[ii];          {swap the two list entries}
        pics_p^[ii] := pics_p^[jj];
        pics_p^[jj] := pic_p;
        end;
      end;
    end;
{
*   Write the organization ID defintions to the output file.
}
  for org := picprg_org_min_k to picprg_org_max_k do begin {once each possible organization ID}
    if pr.env.org[org].name.len > 0 then begin {this organization ID is defined ?}
      wtks ('org'(0));                 {ORG command}
      wint (ord(org), 10, 0);          {organization ID}
      wtk (pr.env.org[org].name);      {organization name}
      wtk (pr.env.org[org].webpage);   {organization's web page}
      wline;
      end;
    end;
{
*   Write out the information about each PIC to the output file.
}
  prev_p := nil;                       {init to no previous PIC to compare against}
  nunique := 0;                        {init number of unique PICs found}

  for ii := 1 to npics do begin        {scan the list of PIC definitions}
    with pics_p^[ii]^:pic do begin     {PIC is abbreviation for this PIC definition}
{
*   Check for this PIC is a duplicate of the previous PIC.  Duplicates are
*   always adjacent since the list is sorted.
}
    if                                 {this PIC is duplicate of previous ?}
        (prev_p <> nil) and then       {previous PIC exists ?}
        string_equal (pic.name_p^.name, prev_p^.name_p^.name) {name matches previous}
        then begin
      string_vstring (diffs, 'IDSPACE', 80);
      if pic.idspace <> prev_p^.idspace
        then goto dupdiff;
      string_vstring (diffs, 'MASK', 80);
      if pic.mask <> prev_p^.mask
        then goto dupdiff;
      string_vstring (diffs, 'ID', 80);
      if pic.id <> prev_p^.id
        then goto dupdiff;
      string_vstring (diffs, 'VDD LOW', 80);
      if pic.vdd.low <> prev_p^.vdd.low
        then goto dupdiff;
      string_vstring (diffs, 'VDD NORM', 80);
      if pic.vdd.norm <> prev_p^.vdd.norm
        then goto dupdiff;
      string_vstring (diffs, 'VDD HIGH', 80);
      if pic.vdd.high <> prev_p^.vdd.high
        then goto dupdiff;
      string_vstring (diffs, 'VPP MIN', 80);
      if pic.vppmin <> prev_p^.vppmin
        then goto dupdiff;
      string_vstring (diffs, 'VPP MAX', 80);
      if pic.vppmax <> prev_p^.vppmax
        then goto dupdiff;
      string_vstring (diffs, 'REV MASK', 80);
      if pic.rev_mask <> prev_p^.rev_mask
        then goto dupdiff;
      string_vstring (diffs, 'REV SHIFT', 80);
      if pic.rev_shft <> prev_p^.rev_shft
        then goto dupdiff;
      string_vstring (diffs, 'WBUF SIZE', 80);
      if pic.wbufsz <> prev_p^.wbufsz
        then goto dupdiff;
      string_vstring (diffs, 'WBUF START', 80);
      if pic.wbstrt <> prev_p^.wbstrt
        then goto dupdiff;
      string_vstring (diffs, 'WBUF REGION LEN', 80);
      if pic.wblen <> prev_p^.wblen
        then goto dupdiff;
      string_vstring (diffs, 'PINS', 80);
      if pic.pins <> prev_p^.pins
        then goto dupdiff;
      string_vstring (diffs, 'NPROG', 80);
      if pic.nprog <> prev_p^.nprog
        then goto dupdiff;
      string_vstring (diffs, 'NDAT', 80);
      if pic.ndat <> prev_p^.ndat
        then goto dupdiff;
      string_vstring (diffs, 'ADRRES', 80);
      if pic.adrres <> prev_p^.adrres
        then goto dupdiff;
      string_vstring (diffs, 'MASK PRG E', 80);
      if pic.maskprg.maske <> prev_p^.maskprg.maske
        then goto dupdiff;
      string_vstring (diffs, 'MASK PRG O', 80);
      if pic.maskprg.masko <> prev_p^.maskprg.masko
        then goto dupdiff;
      string_vstring (diffs, 'MASK DAT E', 80);
      if pic.maskdat.maske <> prev_p^.maskdat.maske
        then goto dupdiff;
      string_vstring (diffs, 'MASK DAT O', 80);
      if pic.maskdat.masko <> prev_p^.maskdat.masko
        then goto dupdiff;
      string_vstring (diffs, 'DATMAP', 80);
      if pic.datmap <> prev_p^.datmap
        then goto dupdiff;
      string_vstring (diffs, 'TPROGP', 80);
      if pic.tprogp <> prev_p^.tprogp
        then goto dupdiff;
      string_vstring (diffs, 'TPROGD', 80);
      if pic.tprogd <> prev_p^.tprogd
        then goto dupdiff;
      string_vstring (diffs, 'FAM', 80);
      if pic.fam <> prev_p^.fam
        then goto dupdiff;
      string_vstring (diffs, 'EECON1', 80);
      if pic.eecon1 <> prev_p^.eecon1
        then goto dupdiff;
      string_vstring (diffs, 'EEADR', 80);
      if pic.eeadr <> prev_p^.eeadr
        then goto dupdiff;
      string_vstring (diffs, 'EEADRH', 80);
      if pic.eeadrh <> prev_p^.eeadrh
        then goto dupdiff;
      string_vstring (diffs, 'EEDATA', 80);
      if pic.eedata <> prev_p^.eedata
        then goto dupdiff;
      string_vstring (diffs, 'VISI', 80);
      if pic.visi <> prev_p^.visi
        then goto dupdiff;
      string_vstring (diffs, 'TBLPAG', 80);
      if pic.tblpag <> prev_p^.tblpag
        then goto dupdiff;
      string_vstring (diffs, 'NVMCON', 80);
      if pic.nvmcon <> prev_p^.nvmcon
        then goto dupdiff;
      string_vstring (diffs, 'NVMKEY', 80);
      if pic.nvmkey <> prev_p^.nvmkey
        then goto dupdiff;
      string_vstring (diffs, 'NVMADR', 80);
      if pic.nvmadr <> prev_p^.nvmadr
        then goto dupdiff;
      string_vstring (diffs, 'NVMADRU', 80);
      if pic.nvmadru <> prev_p^.nvmadru
        then goto dupdiff;
      string_vstring (diffs, 'HDOUBLE', 80);
      if pic.hdouble <> prev_p^.hdouble
        then goto dupdiff;
      string_vstring (diffs, 'EEDOUBLE', 80);
      if pic.eedouble <> prev_p^.eedouble
        then goto dupdiff;
      string_vstring (diffs, 'ADRRESKN', 80);
      if pic.adrreskn <> prev_p^.adrreskn
        then goto dupdiff;

      string_vstring (diffs, 'NAMES', 80);
      idname_p := prev_p^.name_p;
      idname2_p := pic.name_p;
      while true do begin              {compare names lists}
        if not string_equal (idname2_p^.name, idname_p^.name) then goto dupdiff;
        if idname2_p^.vdd.low <> idname_p^.vdd.low then goto dupdiff;
        if idname2_p^.vdd.norm <> idname_p^.vdd.norm then goto dupdiff;
        if idname2_p^.vdd.high <> idname_p^.vdd.high then goto dupdiff;
        idname_p := idname_p^.next_p;
        idname2_p := idname2_p^.next_p;
        if idname_p = nil then begin
          if idname2_p <> nil then goto dupdiff;
          exit;
          end;
        if idname2_p = nil then goto dupdiff;
        end;

      string_vstring (diffs, 'CONFIG', 80);
      adr_p := prev_p^.config_p;
      adr2_p := pic.config_p;
      while true do begin              {compare config addresses list}
        if adr_p = nil then begin
          if adr2_p <> nil then begin
            string_f_int32h (tk, adr2_p^.adr);
            string_appends (diffs, ' address '(0));
            string_append (diffs, tk);
            goto dupdiff;
            end;
          exit;
          end;
        if adr2_p = nil then begin
          string_f_int32h (tk, adr_p^.adr);
          string_appends (diffs, ' address '(0));
          string_append (diffs, tk);
          goto dupdiff;
          end;
        if adr2_p^.adr <> adr_p^.adr then begin
          string_f_int32h (tk, adr_p^.adr);
          string_appends (diffs, ' mask at address '(0));
          string_append (diffs, tk);
          goto dupdiff;
          end;
        if adr2_p^.mask <> adr_p^.mask then begin
          string_f_int32h (tk, adr_p^.adr);
          string_appends (diffs, ' mask at address '(0));
          string_append (diffs, tk);
          goto dupdiff;
          end;
        adr_p := adr_p^.next_p;
        adr2_p := adr2_p^.next_p;
        end;

      string_vstring (diffs, 'OTHER', 80);
      adr_p := prev_p^.other_p;
      adr2_p := pic.other_p;
      while true do begin              {compare config addresses list}
        while (adr_p <> nil) and then (adr_p^.mask = 0) {skip words with 0 mask}
          do adr_p := adr_p^.next_p;
        while (adr2_p <> nil) and then (adr2_p^.mask = 0) {skip words with 0 mask}
          do adr2_p := adr2_p^.next_p;
        if adr_p = nil then begin
          if adr2_p <> nil then goto dupdiff;
          exit;
          end;
        if adr2_p = nil then goto dupdiff;
        if adr2_p^.adr <> adr_p^.adr then goto dupdiff;
        if adr2_p^.mask <> adr_p^.mask then goto dupdiff;
        adr_p := adr_p^.next_p;
        adr2_p := adr2_p^.next_p;
        end;

      next;                            {new PIC is duplicate, silently skip it}

dupdiff:                               {duplicate, but different from previous}
      writeln ('Multiple but different definitions for ',
        pic.name_p^.name.str:pic.name_p^.name.len, ' found.');
      if diffs.len > 0 then begin
        writeln ('Difference: ', diffs.str:diffs.len);
        end;
      sys_bomb;
      end;                             {done handling duplicate PIC}

    prev_p := pics_p^[ii];             {this PIC will be previous next time}
    nunique := nunique + 1;            {count one more unique PIC found}
{
*   Write the info about this PIC to the output file.
}
    writeln (pic.name_p^.name.str:pic.name_p^.name.len); {show this pic on STD out}
    wline;                             {blank line after previous PIC definition}

    hasid :=                           {TRUE if this PIC has a chip ID}
      (pic.id <> 0) or ((pic.mask & 16#FFFFFFFF) <> 16#FFFFFFFF);

    pbits := 0;                        {init bits in widest program memory word}
    while rshft(pic.maskprg.maske ! pic.maskprg.masko, pbits) <> 0 do begin
      pbits := pbits + 1;
      end;

    wtks ('id');
    case pic.idspace of
picprg_idspace_12_k: wtks ('12');
picprg_idspace_16_k: wtks ('16');
picprg_idspace_16b_k: wtks ('16B');
picprg_idspace_18_k: wtks ('18');
picprg_idspace_30_k: wtks ('30');
otherwise
      writeln ('Encountered unexpected namespace ID of ', ord(pic.idspace));
      sys_bomb;
      end;
    if hasid
      then begin                       {ID is chip ID with valid bits indicated by MASK}
        ws (' '(0));
        for jj := 31 downto 0 do begin {look for first valid ID bit}
          if rshft(pic.mask, jj) <> 0 then exit; {found it ?}
          end;
        for kk := jj downto 0 do begin {loop thru the bits starting with highest valid}
          if (rshft(pic.mask, kk) & 1) = 0
            then begin                 {this is a don't care bit}
              ws ('x');
              end
            else begin                 {this is a defined bit}
              if (rshft(pic.id, kk) & 1) = 0
                then ws ('0')
                else ws ('1');
              end
            ;
          end;
        end
      else begin                       {no chip ID}
        wtks ('none');
        end
      ;
    wline;

    if hasid then begin
      ws ('  '(0));                    {REV command}
      wtks ('rev');
      if (pic.rev_mask & ~255) = 0
        then wint (pic.rev_mask, 2, 0) {8 bits or less, write in binary}
        else wint (pic.rev_mask, 16, 0); {more than 8 bits, write in HEX}
      wint (pic.rev_shft, 10, 0);
      wline;
      end;

    ws ('  '(0));                      {NAMES command}
    wtks ('names');
    idname_p := pic.name_p;
    while idname_p <> nil do begin
      wtk (idname_p^.name);
      idname_p := idname_p^.next_p;
      end;
    wline;

    ws ('  '(0));
    wtks ('type');                     {TYPE  command}
    case pic.fam of                    {which PIC family type is this ?}
picprg_picfam_10f_k: wtks ('10F');
picprg_picfam_12f_k: wtks ('12F');
picprg_picfam_16f_k: wtks ('16F');
picprg_picfam_12f6xx_k: wtks ('12F6XX');
picprg_picfam_12f1501_k: wtks ('12F1501');
picprg_picfam_16f77_k: wtks ('16F77');
picprg_picfam_16f88_k: wtks ('16F88');
picprg_picfam_16f61x_k: wtks ('16F61X');
picprg_picfam_16f62x_k: wtks ('16F62X');
picprg_picfam_16f62xa_k: wtks ('16F62XA');
picprg_picfam_16f688_k: wtks ('16F688');
picprg_picfam_16f716_k: wtks ('16F716');
picprg_picfam_16f7x7_k: wtks ('16F7X7');
picprg_picfam_16f720_k: wtks ('16F720');
picprg_picfam_16f72x_k: wtks ('16F72X');
picprg_picfam_16f84_k: wtks ('16F84');
picprg_picfam_16f87xa_k: wtks ('16F87XA');
picprg_picfam_16f88x_k: wtks ('16F88X');
picprg_picfam_16f182x_k: wtks ('16F182X');
picprg_picfam_16f15313_k: wtks ('16F15313');
picprg_picfam_16f183xx_k: wtks ('16F183XX');
picprg_picfam_18f_k: wtks ('18F');
picprg_picfam_18f2520_k: wtks ('18F2520');
picprg_picfam_18f2523_k: wtks ('18F2523');
picprg_picfam_18f6680_k: wtks ('18F6680');
picprg_picfam_18f6310_k: wtks ('18F6310');
picprg_picfam_18j_k: wtks ('18J');
picprg_picfam_18k80_k: wtks ('18K80');
picprg_picfam_18f14k22_k: wtks ('18F14K22');
picprg_picfam_18f14k50_k: wtks ('18F14K50');
picprg_picfam_30f_k: wtks ('30F');
picprg_picfam_24h_k: wtks ('24H');
picprg_picfam_24f_k: wtks ('24F');
picprg_picfam_24fj_k: wtks ('24FJ');
picprg_picfam_33ep_k: wtks ('33EP');
otherwise
      writeln ('Encountered unexpected PIC family ID of ', ord(pic.fam));
      sys_bomb;
      end;
    wline;

    idname_p := pic.name_p;
    while idname_p <> nil do begin
      ws ('  '(0));
      wtks ('vdd');                    {VDD command for specific name}
      wfp (idname_p^.vdd.low, 1);
      wfp (idname_p^.vdd.norm, 1);
      wfp (idname_p^.vdd.high, 1);
      if                               {only write name if multiple names defined}
          (pic.name_p^.next_p <> nil)
          then begin
        wtk (idname_p^.name);
        end;
      wline;
      idname_p := idname_p^.next_p;
      end;

    ws ('  '(0));
    wtks ('vpp');                      {VPP command}
    wfp (pic.vppmin, 1);
    wfp (pic.vppmax, 1);
    wline;

    ws ('  '(0));
    wtks ('resadr');                   {RESADR command}
    if pic.adrreskn
      then begin                       {reset address is known}
        wint (pic.adrres, 16, 0);
        end
      else begin                       {reset address is unknown}
        wtks ('none');
        end
      ;
    wline;

    ws ('  '(0));
    wtks ('pins');                     {PINS command}
    wint (pic.pins, 10, 0);
    wline;

    ws ('  '(0));
    wtks ('nprog');                    {NPROG command}
    wint (pic.nprog, 10, 0);
    wline;

    if pic.maskprg.maske = pic.maskprg.masko
      then begin                       {no odd/even program memory mask distinction}
        ws ('  '(0));
        wtks ('maskprg');
        wint (pic.maskprg.maske, 16, 0);
        wline;
        end
      else begin                       {different masks for odd/even prog memory words}
        ws ('  '(0));
        wtks ('maskprge');
        wint (pic.maskprg.maske, 16, 0);
        wline;
        ws ('  '(0));
        wtks ('maskprgo');
        wint (pic.maskprg.masko, 16, 0);
        wline;
        end
      ;

    ws ('  '(0));
    wtks ('tprog');                    {TPROG command}
    wfp (pic.tprogp * 1000.0, 3);
    wline;

    ws ('  '(0));
    wtks ('writebuf');                 {WRITEBUF command}
    wint (pic.wbufsz, 10, 0);
    wline;

    if pic.wblen > 0 then begin
      ws ('  '(0));
      wtks ('wbufrange');              {WBUFRANGE command}
      wint (pic.wbstrt, 16, 0);
      wint (pic.wblen, 16, 0);
      wline;
      end;

    ws ('  '(0));
    wtks ('ndat');                     {NDAT command}
    wint (pic.ndat, 10, 0);
    wline;

    if pic.ndat > 0 then begin
      if pic.maskdat.maske = pic.maskdat.masko
        then begin                     {no odd/even EEPROM mask distinction}
          ws ('  '(0));
          wtks ('maskdat');
          wint (pic.maskdat.maske, 16, 0);
          wline;
          end
        else begin                     {different masks for odd/even EEPROM words}
          ws ('  '(0));
          wtks ('maskdate');
          wint (pic.maskdat.maske, 16, 0);
          wline;
          ws ('  '(0));
          wtks ('maskdato');
          wint (pic.maskdat.masko, 16, 0);
          wline;
          end
        ;

      ws ('  '(0));
      wtks ('tprogd');
      wfp (pic.tprogd * 1000.0, 3);
      wline;

      ws ('  '(0));
      wtks ('datmap');
      wint (pic.datmap, 16, 0);
      wline;
      end;

    if                                 {write PIC 18 register addresses ?}
        (pic.idspace = picprg_idspace_18_k) and {this is a PIC 18 ?}
        ( (pic.eecon1 <> 16#FA6) or    {any reg not at the default address ?}
          (pic.eeadr <> 16#FA9) or
          (pic.eeadrh <> 16#FAA) or
          (pic.eedata <> 16#FA8))
        then begin
      ws ('  '(0));                    {write addresses of all variable registers}
      wtks ('eecon1');
      wint (pic.eecon1, 16, 3);
      wline;
      ws ('  '(0));
      wtks ('eeadr');
      wint (pic.eeadr, 16, 3);
      wline;
      ws ('  '(0));
      wtks ('eeadrh');
      wint (pic.eeadrh, 16, 3);
      wline;
      ws ('  '(0));
      wtks ('eedata');
      wint (pic.eedata, 16, 3);
      wline;
      end;

    if                                 {write PIC 30 register addresses ?}
        (pic.idspace = picprg_idspace_30_k) and {this is a PIC 80 ?}
        ( (pic.visi <> 16#784) or      {any reg not at the default address ?}
          (pic.tblpag <> 16#032) or
          (pic.nvmcon <> 16#760) or
          (pic.nvmkey <> 16#766) or
          (pic.nvmadr <> 16#762) or
          (pic.nvmadru <> 16#764))
        then begin
      ws ('  '(0));                    {write addresses of all variable registers}
      wtks ('visi');
      wint (pic.visi, 16, 3);
      wline;
      ws ('  '(0));
      wtks ('tblpag');
      wint (pic.tblpag, 16, 3);
      wline;
      ws ('  '(0));
      wtks ('nvmcon');
      wint (pic.nvmcon, 16, 3);
      wline;
      ws ('  '(0));
      wtks ('nvmkey');
      wint (pic.nvmkey, 16, 3);
      wline;
      ws ('  '(0));
      wtks ('nvmadr');
      wint (pic.nvmadr, 16, 3);
      wline;
      ws ('  '(0));
      wtks ('nvmadru');
      wint (pic.nvmadru, 16, 3);
      wline;
      end;

    case pic.idspace of                {check for special handling of OTHER words}
picprg_idspace_18_k: begin
        doconfig_18 (pic);
        end;
picprg_idspace_30_k: begin
        doconfig_30 (pic);
        end;
otherwise                              {normal config word handling}
      adr_p := pic.config_p;
      while adr_p <> nil do begin      {loop thru the CONFIG addresses}
        wcfg (adr_p^.adr, adr_p^.mask, pbits);
        adr_p := adr_p^.next_p;
        end;
      end;

    case pic.idspace of                {check for special handling of OTHER words}
picprg_idspace_30_k: begin
        doother_30 (pic);
        end;
otherwise                              {normal config word handling}
      adr_p := pic.other_p;
      while adr_p <> nil do begin      {loop thru the OTHER addresses}
        ws ('  '(0));
        wtks ('other');
        wint (adr_p^.adr, 16, 0);
        wint (adr_p^.mask, 16, (pbits + 3) div 4);
        adr_p := adr_p^.next_p;
        wline;
        end;
      end;

    ws ('  '(0));
    wtks ('endid');
    wline;

    end;                               {done with PIC abbreviation}
    end;                               {back to do next PIC in list}

  picprg_close (pr, stat);
  sys_error_abort (stat, '', '', nil, 0);

  writeln;
  writeln (npics, ' PIC definitions found, ', nunique, ' unique, ',
    npics - nunique, ' duplicates.');
  end.
