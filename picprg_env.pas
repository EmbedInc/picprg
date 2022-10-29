{   Routines that deal with environment file descriptors.
}
module picprg_env;
define picprg_env_read;
%include 'picprg2.ins.pas';

const
  env_name = 'picprg.env';             {environment file set name}

type
  adradd_k_t = (                       {how to add address to list}
    adradd_asc_k,                      {insert by ascending address order}
    adradd_end_k);                     {add to end of list}
{
*******************************************************************************
*
*   Subroutine PICPRG_ENV_READ (PR, STAT)
*
*   Read the PICPRG.ENV environment file set and save the information in
*   PR.ENV.  PR.ENV is assumed to be completely uninitialized before this
*   call.
}
procedure picprg_env_read (            {read env file, save info in PR}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  conn: file_conn_t;                   {connection to the environment file set}
  buf: string_var8192_t;               {one line input buffer}
  lnam: string_leafname_t;             {scratch file leafname}
  p: string_index_t;                   {BUF parse index}
  i: sys_int_machine_t;                {scratch integer}
  r: real;                             {scratch floating point value}
  adr: picprg_adr_t;                   {scratch target address}
  dat: picprg_dat_t;                   {scratch target address word}
  i8: int8u_t;                         {scratch 8 bit unsigned integer}
  idspace: picprg_idspace_k_t;         {chip ID name space}
  org: picprg_org_k_t;                 {software/firmware creating organization ID}
  idblock_p: picprg_idblock_p_t;       {pointer to currently open ID block}
  cmd: string_var32_t;                 {command name, upper case}
  tk: string_var80_t;                  {scratch token}
  pick: sys_int_machine_t;             {number of keyword picked from list}
  name_p: picprg_idname_p_t;           {pointer to current chip name descriptor}
  name_pp: ^picprg_idname_p_t;         {points to where to link next name descr}
  vdd: picprg_vddvals_t;               {scratch Vdd voltage levels descriptor}
  cmds: string_var8192_t;              {list of all the command keywords}
  famnames: string_var1024_t;          {list of family names for TYPE command}
  adrres_set: boolean;                 {ADRRES explicitly set this block}

label
  loop_line, loop_name, done_names, loop_vdd, done_vdd,
  done_cmd, eof, err_parm, err_noid, err_missing, err_atline, abort;
{
**********
*
*   Subroutine INSERT_ADR (LIST_P, ADRADD, ADR, MASK, STAT)
*   This routine is internal to PICPRG_ENV_READ.
*
*   Insert the address ADR into the list of address specifications.  ADRADD
*   specifies how the address is to be added to the list.  LIST_P is the start
*   of list pointer, which may be updated.
}
procedure insert_adr (                 {insert new address into list}
  in out  list_p: picprg_adrent_p_t;   {pointer to first list entry, may be updated}
  in      adradd: adradd_k_t;          {where to add new entry to list}
  in      adr: picprg_adr_t;           {address to insert}
  in      mask: picprg_dat_t;          {mask of valid bits at this address}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ent_p: picprg_adrent_p_t;            {pointer to the new list entry}
  ent_pp: ^picprg_adrent_p_t;          {pointer to chain link to the new entry}
  e_p: picprg_adrent_p_t;              {pointer to current list entry}

begin
  sys_error_none (stat);               {init to no error encountered}

  util_mem_grab (                      {allocate memory for the new list entry}
    sizeof(ent_p^), pr.mem_p^, false, ent_p);
  ent_p^.adr := adr;                   {save address in list entry}
  ent_p^.mask := mask;                 {save valid bits mask in list entry}
  ent_p^.val := 0;                     {init to value in target of this word is unknown}
  ent_p^.kval := false;

  ent_pp := addr(list_p);              {init pointer to where to link in new entry}
  e_p := list_p;                       {init the next list entry pointer}
  while e_p <> nil do begin            {scan the existing list}
    if e_p^.adr = adr then begin       {entry with this address already exists ?}
      sys_stat_set (picprg_subsys_k, picprg_stat_dupadr_k, stat);
      return;
      end;
    case adradd of                     {what is strategy for adding new address to list ?}
adradd_asc_k: begin                    {add in ascending address order}
        if e_p^.adr < adr then begin   {new entry goes after this one}
          ent_pp := addr(e_p^.next_p); {update pointer to link new entry to}
          end;
        end;
adradd_end_k: begin                    {add to end of list}
        ent_pp := addr(e_p^.next_p);
        end;
      end;
    e_p := e_p^.next_p;                {advance to next list entry}
    end;
{
*   ENT_PP is pointing to the chain link where the new entry is to be
*   inserted.
}
  ent_p^.next_p := ent_pp^;            {insert the new entry into the chain}
  ent_pp^ := ent_p;
  end;
{
***************************************************************************
*
*   Start of main routine.
}
begin
  buf.max := size_char(buf.str);       {init local var strings}
  lnam.max := size_char(lnam.str);
  cmd.max := size_char(cmd.str);
  tk.max := size_char(tk.str);
  cmds.max := size_char(cmds.str);
  famnames.max := size_char(famnames.str);

  string_vstring (lnam, env_name, size_char(env_name)); {make var string env name}
  file_open_read_env (                 {open the environment file set for reading}
    lnam,                              {environment file set name}
    '',                                {file name suffix}
    true,                              {read file set in global to local order}
    conn,                              {returned connection to the file set}
    stat);
  if sys_error(stat) then return;
{
*   Initialize ENV in the library state.
}
  for org := picprg_org_min_k to picprg_org_max_k do begin {once each possible ORG}
    pr.env.org[org].name.max := size_char(pr.env.org[org].name.str);
    pr.env.org[org].name.len := 0;     {init to no organization with this ID}
    pr.env.org[org].webpage.max := size_char(pr.env.org[org].webpage.str);
    pr.env.org[org].webpage.len := 0;
    end;

  pr.env.idblock_p := nil;             {init device ID blocks chain to empty}
{
*   Initialize local state before reading all the commands.
}
  idblock_p := nil;                    {init to not currently within an ID block}

  cmds.len := 0;                       {set list of command name keywords}
  string_appends (cmds, 'ORG'(0));     {1}
  string_appends (cmds, ' ID'(0));     {2}
  string_appends (cmds, ' NAMES'(0));  {3}
  string_appends (cmds, ' VDD'(0));    {4}
  string_appends (cmds, ' REV'(0));    {5}
  string_appends (cmds, ' TYPE'(0));   {6}
  string_appends (cmds, ' ENDID'(0));  {7}
  string_appends (cmds, ' PINS'(0));   {8}
  string_appends (cmds, ' NPROG'(0));  {9}
  string_appends (cmds, ' NDAT'(0));   {10}
  string_appends (cmds, ' MASKPRG'(0)); {11}
  string_appends (cmds, ' MASKDAT'(0)); {12}
  string_appends (cmds, ' TPROG'(0));  {13}
  string_appends (cmds, ' DATMAP'(0)); {14}
  string_appends (cmds, ' CONFIG'(0)); {15}
  string_appends (cmds, ' OTHER'(0));  {16}
  string_appends (cmds, ' TPROGD'(0)); {17}
  string_appends (cmds, ' MASKPRGE'(0)); {18}
  string_appends (cmds, ' MASKPRGO'(0)); {19}
  string_appends (cmds, ' WRITEBUF'(0)); {20}
  string_appends (cmds, ' WBUFRANGE'(0)); {21}
  string_appends (cmds, ' VPP'(0));    {22}
  string_appends (cmds, ' RESADR'(0)); {23}
  string_appends (cmds, ' EECON1'(0)); {24}
  string_appends (cmds, ' EEADR'(0));  {25}
  string_appends (cmds, ' EEADRH'(0)); {26}
  string_appends (cmds, ' EEDATA'(0)); {27}
  string_appends (cmds, ' VISI'(0));   {28}
  string_appends (cmds, ' TBLPAG'(0)); {29}
  string_appends (cmds, ' NVMCON'(0)); {30}
  string_appends (cmds, ' NVMKEY'(0)); {31}
  string_appends (cmds, ' NVMADR'(0)); {32}
  string_appends (cmds, ' NVMADRU'(0)); {33}

  famnames.len := 0;                   {set list of family names for TYPE command}
  string_appends (famnames, '10F'(0)); {1}
  string_appends (famnames, ' 16F'(0)); {2}
  string_appends (famnames, ' 12F6XX'(0)); {3}
  string_appends (famnames, ' 16F62X'(0)); {4}
  string_appends (famnames, ' 16F62XA'(0)); {5}
  string_appends (famnames, ' 16F716'(0)); {6}
  string_appends (famnames, ' 16F87XA'(0)); {7}
  string_appends (famnames, ' 18F'(0)); {8}
  string_appends (famnames, ' 30F'(0)); {9}
  string_appends (famnames, ' 18F2520'(0)); {10}
  string_appends (famnames, ' 16F688'(0)); {11}
  string_appends (famnames, ' 16F88'(0)); {12}
  string_appends (famnames, ' 16F77'(0)); {13}
  string_appends (famnames, ' 16F84'(0)); {14}
  string_appends (famnames, ' 18F6680'(0)); {15}
  string_appends (famnames, ' 18F6310'(0)); {16}
  string_appends (famnames, ' 18F2523'(0)); {17}
  string_appends (famnames, ' 16F7X7'(0)); {18}
  string_appends (famnames, ' 16F88X'(0)); {19}
  string_appends (famnames, ' 16F61X'(0)); {20}
  string_appends (famnames, ' 18J'(0)); {21}
  string_appends (famnames, ' 24H'(0)); {22}
  string_appends (famnames, ' 12F'(0)); {23}
  string_appends (famnames, ' 16F72X'(0)); {24}
  string_appends (famnames, ' 24F'(0)); {25}
  string_appends (famnames, ' 18F14K22'(0)); {26}
  string_appends (famnames, ' 16F182X'(0)); {27}
  string_appends (famnames, ' 16F720'(0)); {28}
  string_appends (famnames, ' 18F14K50'(0)); {29}
  string_appends (famnames, ' 24FJ'(0)); {30}
  string_appends (famnames, ' 12F1501'(0)); {31}
  string_appends (famnames, ' 18K80'(0)); {32}
  string_appends (famnames, ' 33EP'(0)); {33}
  string_appends (famnames, ' 16F15313'(0)); {34}
  string_appends (famnames, ' 16F183XX'(0)); {35}
  string_appends (famnames, ' 18F25Q10'(0)); {36}
{
*   Loop back here to read each new line from the environment file set.
}
loop_line:
  file_read_env (conn, buf, stat);     {read next env file set line into BUF}
  if file_eof(stat) then goto eof;     {hit end of file set ?}
  p := 1;                              {init parse index for the new line}
  string_token (buf, p, cmd, stat);    {get the command name}
  string_upcase (cmd);
  string_tkpick (cmd, cmds, pick);     {pick the command name from keywords list}
  case pick of
{
*********************
*
*   ORG id name webpage
}
1: begin
  string_token_int (buf, p, i, stat);  {get ID number into I}
  if sys_error(stat) then goto err_parm;
  i8 := i;                             {convert to 8 bit unsigned integer}
  org := picprg_org_k_t(i8);           {make ID for the selected organization}

  string_token (buf, p, pr.env.org[org].name, stat); {get organization name string}
  if sys_error(stat) then goto err_parm;
  string_token (buf, p, pr.env.org[org].webpage, stat); {get web page address}
  if sys_error(stat) then goto err_parm;
  string_downcase (pr.env.org[org].webpage); {save web address in lower case}
  end;
{
*********************
*
*   ID namespace binid
}
2: begin
  if idblock_p <> nil then begin       {already within an ID block ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_idid_k, stat);
    goto err_atline;
    end;

  string_token (buf, p, tk, stat);     {get ID namespace name string}
  string_upcase (tk);                  {make upper case for keyword matching}
  string_tkpick80 (tk,                 {pick namespace name from list}
    '16 16B 18 12 30 18B',
    pick);                             {number of name picked from the list}
  case pick of
1:  idspace := picprg_idspace_16_k;
2:  idspace := picprg_idspace_16b_k;
3:  idspace := picprg_idspace_18_k;
4:  idspace := picprg_idspace_12_k;
5:  idspace := picprg_idspace_30_k;
6:  idspace := picprg_idspace_18b_k;
otherwise
    goto err_parm;                     {invalid ID namespace name, parameter error}
    end;

  string_token (buf, p, tk, stat);     {get binary ID pattern token}
  if sys_error(stat) then goto err_parm;

  util_mem_grab (                      {allocate memory for the new ID block}
    sizeof(idblock_p^), pr.mem_p^, false, idblock_p);
  idblock_p^.next_p := pr.env.idblock_p; {insert new block at the start of the chain}
  pr.env.idblock_p := idblock_p;

  idblock_p^.idspace := idspace;       {initialize the new ID block descriptor}
  idblock_p^.mask := 0;
  idblock_p^.id := 0;
  idblock_p^.vdd.low := 4.5;
  idblock_p^.vdd.norm := 5.0;
  idblock_p^.vdd.high := 5.5;
  idblock_p^.vdd.twover :=
    abs(idblock_p^.vdd.high - idblock_p^.vdd.low) > 0.010;
  idblock_p^.vppmin := 12.5;
  idblock_p^.vppmax := 13.5;
  idblock_p^.name_p := nil;
  idblock_p^.rev_mask := 2#11111;
  idblock_p^.rev_shft := 0;
  idblock_p^.wbufsz := 1;
  idblock_p^.wbstrt := 0;
  idblock_p^.wblen := 0;
  idblock_p^.pins := 0;
  idblock_p^.nprog := 0;
  idblock_p^.ndat := 0;
  idblock_p^.adrres := 0;
  idblock_p^.adrreskn := true;
  idblock_p^.maskprg.maske := 0;
  idblock_p^.maskprg.masko := 0;
  idblock_p^.maskdat.maske := 0;
  idblock_p^.maskdat.masko := 0;
  idblock_p^.datmap := lastof(idblock_p^.datmap);
  idblock_p^.tprogp := 0.0;
  idblock_p^.tprogd := 0.0;
  idblock_p^.config_p := nil;
  idblock_p^.other_p := nil;
  idblock_p^.fam := picprg_picfam_unknown_k;
  idblock_p^.eecon1 := 16#FA6;
  idblock_p^.eeadr := 16#FA9;
  idblock_p^.eeadrh := 16#FAA;
  idblock_p^.eedata := 16#FA8;
  idblock_p^.visi := 16#0784;
  idblock_p^.tblpag := 16#0032;
  idblock_p^.nvmcon := 16#0760;
  idblock_p^.nvmkey := 16#0766;
  idblock_p^.nvmadr := 16#0762;
  idblock_p^.nvmadru := 16#0764;
  idblock_p^.hdouble := false;
  idblock_p^.eedouble := false;

  adrres_set := false;                 {init to ADRRES not explicitly set from command}

  string_upcase (tk);                  {make upper case for pattern matching}
  if string_equal (tk, string_v('NONE'(0))) then begin {this chip has no ID ?}
    idblock_p^.mask := ~0;             {set all bits to significant}
    goto done_cmd;                     {done with this command}
    end;

  for i := 1 to tk.len do begin        {once for each character in binary pattern}
    idblock_p^.mask := lshft(idblock_p^.mask, 1); {make room for this new bit}
    idblock_p^.id := lshft(idblock_p^.id, 1);
    case tk.str[i] of                  {what is specified for this bit ?}
'0':  begin                            {bit must be 0}
        idblock_p^.mask := idblock_p^.mask ! 1;
        end;
'1':  begin                            {bit must be 1}
        idblock_p^.mask := idblock_p^.mask ! 1;
        idblock_p^.id := idblock_p^.id ! 1;
        end;
'X':  begin                            {bit is "don't care"}
        end;
otherwise
      goto err_parm;                   {this parameter is invalid}
      end;
    end;                               {back to process next binary pattern char}
  end;
{
*********************
*
*   NAMES name ... name
}
3: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  if idblock_p^.name_p <> nil then begin {list of names already exists ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_names2_k, stat);
    goto err_atline;
    end;

  name_pp := addr(idblock_p^.name_p);  {init where to link next name descriptor}

loop_name:                             {back here each new name token}
  string_token (buf, p, tk, stat);     {get this name token into TK}
  if string_eos(stat) then goto done_names; {exhausted the name tokens ?}
  if sys_error(stat) then goto err_parm;

  util_mem_grab (                      {allocate memory for this new name descriptor}
    sizeof(name_p^), pr.mem_p^, false, name_p);
  name_pp^ := name_p;                  {link new descriptor to end of chain}
  name_pp := addr(name_p^.next_p);     {update end of chain pointer}

  name_p^.next_p := nil;               {init to no chain entry after this one}
  name_p^.name.max := size_char(name_p^.name.str); {set name string for this entry}
  string_copy (tk, name_p^.name);
  string_upcase (name_p^.name);        {names are stored in upper case}
  name_p^.vdd := idblock_p^.vdd;       {set Vdd levels for this name to defaults}
  goto loop_name;                      {back to get and process next name token}

done_names:                            {hit end of command line}
  end;
{
*********************
*
*   VDD low normal high [name ... name]
}
4: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_fpm (buf, p, vdd.low, stat);
  if sys_error(stat) then goto err_parm;
  string_token_fpm (buf, p, vdd.norm, stat);
  if sys_error(stat) then goto err_parm;
  string_token_fpm (buf, p, vdd.high, stat);
  if sys_error(stat) then goto err_parm;
 vdd.twover := abs(vdd.high - vdd.low) > 0.010;

  i := 0;                              {init number of names processed}
loop_vdd:                              {back here to get each new name token}
  string_token (buf, p, tk, stat);     {get this name token into TK}
  if string_eos(stat) then goto done_vdd; {exhausted the name tokens ?}
  if sys_error(stat) then goto err_parm;
  i := i + 1;                          {count one more name processed}
  string_upcase (tk);                  {all names are stored upper case}
  name_p := idblock_p^.name_p;         {init pointer to start of names chain}
  while name_p <> nil do begin         {once for each name in the list}
    if string_equal (tk, name_p^.name) then begin {this name matches the token ?}
      name_p^.vdd := vdd;              {set the Vdd levels for this name}
      goto loop_vdd;                   {back to get next name token}
      end;
    name_p := name_p^.next_p;          {advance to next name in the list}
    end;                               {back and test this new name for a match}
  sys_stat_set (picprg_subsys_k, picprg_stat_badvddname_k, stat);
  sys_stat_parm_vstr (tk, stat);
  goto err_atline;

done_vdd:                              {done with all name tokens}
  if i = 0 then begin                  {no names supplied at all ?}
    name_p := idblock_p^.name_p;       {init pointer to start of names chain}
    while name_p <> nil do begin       {once for each name in the list}
      name_p^.vdd := vdd;              {set the Vdd levels for this name}
      name_p := name_p^.next_p;        {advance to next name in the list}
      end;                             {back and test this new name for a match}
    end;
  end;
{
*********************
*
*   REV mask shift
}
5: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);  {get mask}
  if sys_error(stat) then goto err_parm;
  idblock_p^.rev_mask := i;

  string_token_int (buf, p, idblock_p^.rev_shft, stat); {get shift count}
  if sys_error(stat) then goto err_parm;
  end;
{
*********************
*
*   TYPE family
}
6: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  idblock_p^.wbstrt := 0;              {init to write buffer not apply to this fam}
  idblock_p^.wblen := 0;
  string_token (buf, p, tk, stat);     {get family name token}
  if sys_error(stat) then goto err_parm;
  string_upcase (tk);                  {make upper case for keyword matching}
  string_tkpick (tk, famnames, pick);  {pick family name from the list}
  case pick of
1:  begin
      idblock_p^.fam := picprg_picfam_10f_k;
      end;
2:  begin
      idblock_p^.fam := picprg_picfam_16f_k;
      idblock_p^.wblen := 8192;
      end;
3:  begin
      idblock_p^.fam := picprg_picfam_12f6xx_k;
      idblock_p^.wblen := 8192;
      end;
4:  begin
      idblock_p^.fam := picprg_picfam_16f62x_k;
      idblock_p^.wblen := 8192;
      end;
5:  begin
      idblock_p^.fam := picprg_picfam_16f62xa_k;
      idblock_p^.wblen := 8192;
      end;
6:  begin
      idblock_p^.fam := picprg_picfam_16f716_k;
      idblock_p^.wblen := 8192;
      end;
7:  begin
      idblock_p^.fam := picprg_picfam_16f87xa_k;
      idblock_p^.wblen := 8192;
      end;
8:  begin
      idblock_p^.fam := picprg_picfam_18f_k;
      idblock_p^.wblen := 16#200000;
      end;
9:  begin
      idblock_p^.fam := picprg_picfam_30f_k;
      idblock_p^.wbufsz := 64;
      idblock_p^.wblen := 16#F80000;
      end;
10: begin
      idblock_p^.fam := picprg_picfam_18f2520_k;
      idblock_p^.wblen := 16#200000;
      end;
11: begin
      idblock_p^.fam := picprg_picfam_16f688_k;
      idblock_p^.wblen := 8192;
      end;
12: begin
      idblock_p^.fam := picprg_picfam_16f88_k;
      idblock_p^.wblen := 8192 + 4;    {user ID locations also use write buffer}
      end;
13: begin
      idblock_p^.fam := picprg_picfam_16f77_k;
      idblock_p^.wblen := 8192 + 4;    {user ID locations also use write buffer}
      end;
14:  begin
      idblock_p^.fam := picprg_picfam_16f84_k;
      idblock_p^.wblen := 8192;
      end;
15: begin
      idblock_p^.fam := picprg_picfam_18f6680_k;
      idblock_p^.wblen := 16#200000;
      end;
16: begin
      idblock_p^.fam := picprg_picfam_18f6310_k;
      idblock_p^.wblen := 16#200000;
      end;
17: begin
      idblock_p^.fam := picprg_picfam_18f2523_k;
      idblock_p^.wblen := 16#200000;
      end;
18: begin
      idblock_p^.fam := picprg_picfam_16f7x7_k;
      idblock_p^.wblen := 8192;
      end;
19: begin
      idblock_p^.fam := picprg_picfam_16f88x_k;
      idblock_p^.wblen := 8192;
      end;
20: begin
      idblock_p^.fam := picprg_picfam_16f61x_k;
      idblock_p^.wblen := 8192;
      end;
21: begin
      idblock_p^.fam := picprg_picfam_18j_k;
      idblock_p^.wblen := 16#200000;
      end;
22: begin
      idblock_p^.fam := picprg_picfam_24h_k;
      idblock_p^.wbufsz := 128;
      idblock_p^.wblen := 16#F80000;
      end;
23: begin
      idblock_p^.fam := picprg_picfam_12f_k;
      end;
24: begin
      idblock_p^.fam := picprg_picfam_16f72x_k;
      idblock_p^.wblen := 8192;
      end;
25: begin
      idblock_p^.fam := picprg_picfam_24f_k;
      idblock_p^.wbufsz := 64;
      idblock_p^.wblen := 16#F80000;
      end;
26: begin
      idblock_p^.fam := picprg_picfam_18f14k22_k;
      idblock_p^.wblen := 16#200000;
      end;
27: begin
      idblock_p^.fam := picprg_picfam_16f182x_k;
      idblock_p^.wblen := 16#8000;
      end;
28: begin
      idblock_p^.fam := picprg_picfam_16f720_k;
      idblock_p^.wblen := 8192;
      end;
29: begin
      idblock_p^.fam := picprg_picfam_18f14k50_k;
      idblock_p^.wblen := 16#200000;
      end;
30: begin
      idblock_p^.fam := picprg_picfam_24fj_k;
      idblock_p^.wbufsz := 64;
      idblock_p^.wblen := 16#F80000;
      end;
31: begin
      idblock_p^.fam := picprg_picfam_12f1501_k;
      idblock_p^.wblen := 16#8000;
      end;
32: begin
      idblock_p^.fam := picprg_picfam_18k80_k;
      idblock_p^.wblen := 16#200000;
      end;
33: begin
      idblock_p^.fam := picprg_picfam_33ep_k;
      idblock_p^.wblen := 16#F80000;
      end;
34: begin
      idblock_p^.fam := picprg_picfam_16f15313_k;
      idblock_p^.wblen := 16#8000;
      idblock_p^.adrres := 0;          {reset sets address to 0}
      idblock_p^.adrreskn := true;
      end;
35: begin
      idblock_p^.fam := picprg_picfam_16f183xx_k;
      idblock_p^.wblen := 16#8000;
      idblock_p^.adrres := 0;          {reset sets address to 0}
      idblock_p^.adrreskn := true;
      end;
36: begin
      idblock_p^.fam := picprg_picfam_18f25q10_k;
      idblock_p^.wblen := 0;
      idblock_p^.adrreskn := false;
      end;
otherwise
    sys_stat_set (picprg_subsys_k, picprg_stat_badfam_k, stat);
    sys_stat_parm_vstr (tk, stat);
    goto err_atline;
    end;
  end;
{
*********************
*
*   ENDID
}
7: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  if idblock_p^.name_p = nil then begin {no name specified ?}
    string_vstring (tk, 'NAME'(0), -1);
    goto err_missing;
    end;
  if idblock_p^.fam = picprg_picfam_unknown_k then begin {no family type specified ?}
    string_vstring (tk, 'TYPE'(0), -1);
    goto err_missing;
    end;
  if idblock_p^.pins = 0 then begin    {number of pins not specified ?}
    string_vstring (tk, 'PINS'(0), -1);
    goto err_missing;
    end;
  if idblock_p^.nprog = 0 then begin
    string_vstring (tk, 'NPROG'(0), -1);
    goto err_missing;
    end;
  if (idblock_p^.maskprg.maske = 0) and (idblock_p^.maskprg.masko = 0) then begin
    string_vstring (tk, 'MASKPRG'(0), -1);
    goto err_missing;
    end;
  if
      (idblock_p^.ndat > 0) and        {this chip has data memory ?}
      (idblock_p^.datmap = lastof(idblock_p^.datmap)) {no mapping specified ?}
      then begin
    string_vstring (tk, 'DATMAP'(0), -1);
    goto err_missing;
    end;

  if not adrres_set then begin         {ADRRES not explicitly set from a command ?}
    case idblock_p^.fam of
picprg_picfam_10f_k, picprg_picfam_12f_k: begin {12 bit core}
        idblock_p^.adrres := (idblock_p^.nprog * 2) - 1;
        end;
      end;                             {end of PIC family type cases}
    end;

  idblock_p^.hdouble :=                {determine whether HEX file addresses doubled}
    (idblock_p^.maskprg.maske > 255) or (idblock_p^.maskprg.masko > 255);
  idblock_p^.eedouble :=               {determine EEPROM adr doubled beyond HDOUBLE}
    ( (not idblock_p^.hdouble) and
      (idblock_p^.maskdat.maske > 255) or (idblock_p^.maskdat.masko > 255)
      ) or
    (idblock_p^.maskprg.maske <> idblock_p^.maskprg.masko);

  idblock_p := nil;                    {indicate not currently in an ID block}
  end;
{
*********************
*
*   PINS n
}
8: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, idblock_p^.pins, stat);
  end;
{
*********************
*
*   NPROG n
}
9: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  idblock_p^.nprog := i;
  end;
{
*********************
*
*   NDAT n
}
10: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  idblock_p^.ndat := i;
  end;
{
*********************
*
*   MASKPROG mask
}
11: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  idblock_p^.maskprg.maske := i;
  idblock_p^.maskprg.masko := i;
  end;
{
*********************
*
*   MASKDAT mask
}
12: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  idblock_p^.maskdat.maske := i;
  idblock_p^.maskdat.masko := i;
  end;
{
*********************
*
*   TPROG ms
}
13: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_fpm (buf, p, r, stat);
  r := r / 1000.0;                     {convert to seconds}
  idblock_p^.tprogp := r;              {set program memory write delay time}
  idblock_p^.tprogd := r;              {set data memory write delay time}
  end;
{
*********************
*
*   DATMAP adr
}
14: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  idblock_p^.datmap := i;
  end;
{
*********************
*
*   CONFIG adr mask
}
15: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);  {get address}
  if sys_error(stat) then goto err_parm;
  adr := i;
  string_token_int (buf, p, i, stat);  {get mask}
  if sys_error(stat) then goto err_parm;
  dat := i;

  insert_adr (idblock_p^.config_p, adradd_end_k, adr, dat, stat);
  if sys_error(stat) then goto err_atline;
  end;
{
*********************
*
*   OTHER adr mask
}
16: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);  {get address}
  if sys_error(stat) then goto err_parm;
  adr := i;
  string_token_int (buf, p, i, stat);  {get mask}
  if sys_error(stat) then goto err_parm;
  dat := i;

  insert_adr (idblock_p^.other_p, adradd_asc_k, adr, dat, stat);
  if sys_error(stat) then goto err_atline;
  end;
{
*********************
*
*   TPROGD ms
}
17: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_fpm (buf, p, r, stat);
  r := r / 1000.0;                     {convert to seconds}
  idblock_p^.tprogd := r;              {set data memory write delay time}
  end;
{
*********************
*
*   MASKPROGE mask
}
18: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  idblock_p^.maskprg.maske := i;
  end;
{
*********************
*
*   MASKPROGO mask
}
19: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  idblock_p^.maskprg.masko := i;
  end;
{
*********************
*
*   WRITEBUF n
}
20: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  idblock_p^.wbufsz := i;
  end;
{
*********************
*
*   WBUFRANGE start len
}
21: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.wbstrt := i;
  string_token_int (buf, p, i, stat);
  idblock_p^.wblen := i;
  end;
{
*********************
*
*   VPP min max
}
22: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_fpm (buf, p, r, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.vppmin := r;
  string_token_fpm (buf, p, r, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.vppmax := r;
  end;
{
*********************
*
*   RESADR (adr | NONE)
}
23: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}
  string_token (buf, p, tk, stat);
  if sys_error(stat) then goto err_parm;
  string_upcase (tk);
  if string_equal (tk, string_v('NONE'(0)))
    then begin                         {NONE}
      idblock_p^.adrres := 0;
      idblock_p^.adrreskn := false;
      end
    else begin                         {address}
      string_t_int (tk, i, stat);
      if sys_error(stat) then goto err_parm;
      idblock_p^.adrres := i;
      end
    ;
  adrres_set := true;
  end;
{
*********************
*
*   EECON1 adr
}
24: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.eecon1 := i;
  end;
{
*********************
*
*   EEADR adr
}
25: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.eeadr := i;
  end;
{
*********************
*
*   EEADRH adr
}
26: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.eeadrh := i;
  end;
{
*********************
*
*   EEDATA adr
}
27: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.eedata := i;
  end;
{
*********************
*
*   VISI adr
}
28: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.visi := i;
  end;
{
*********************
*
*   TBLPAG adr
}
29: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.tblpag := i;
  end;
{
*********************
*
*   NVMCON adr
}
30: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.nvmcon := i;
  end;
{
*********************
*
*   NVMKEY adr
}
31: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.nvmkey := i;
  end;
{
*********************
*
*   NVMADR adr
}
32: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.nvmadr := i;
  end;
{
*********************
*
*   NVMADRU adr
}
33: begin
  if idblock_p = nil then goto err_noid; {no ID block currently open ?}

  string_token_int (buf, p, i, stat);
  if sys_error(stat) then goto err_parm;
  idblock_p^.nvmadru := i;
  end;
{
*********************
*
*   Unrecognized command.
}
otherwise
    sys_stat_set (picprg_subsys_k, picprg_stat_badcmd_k, stat);
    sys_stat_parm_vstr (cmd, stat);
    goto err_atline;
    end;
{
*   Done processing this command.  Check for error status.
}
done_cmd:                              {command may jump here when done}
  if sys_error(stat) then goto err_parm;

  string_token (buf, p, tk, stat);     {try go get another token from cmd line}
  if string_eos(stat) then goto loop_line; {hit end of line, back for next line}
  sys_stat_set (picprg_subsys_k, picprg_stat_tkextra_k, stat);
  goto err_atline;
{
*   The end of the environment file set has been reached.
}
eof:
  file_close (conn);                   {close the environment file set}
  if idblock_p <> nil then begin       {an ID block is currently open ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_ideof_k, stat);
    return;
    end;

  return;                              {normal return with no error}
{
*   Jump here on error with a parameter.  STAT will be overwritten with
*   a generic parameter error message giving the file and line number.
}
err_parm:
  sys_stat_set (picprg_subsys_k, picprg_stat_barg_atline_k, stat);
  goto err_atline;
{
*   Jump here if the command is only allowed within an ID block and no
*   ID block is currently open.
}
err_noid:                              {not within an ID block}
  sys_stat_set (picprg_subsys_k, picprg_stat_nidblock_k, stat);
  sys_stat_parm_vstr (cmd, stat);      {add command name}
  goto err_atline;
{
*   A required value was not supplied in an ID block.  TK is set to the
*   name of the command that sets the parameter.
}
err_missing:
  sys_stat_set (picprg_subsys_k, picprg_stat_idmissing_k, stat);
  sys_stat_parm_vstr (tk, stat);       {name of missing command}
  goto err_atline;
{
*   An error has occurred on this line.  STAT must already be set to the
*   appropriate status.  The line number and file name of the error will
*   be added as two STAT parameters, in that order.
}
err_atline:
  sys_stat_parm_int (conn.lnum, stat); {add line number within file}
  sys_stat_parm_vstr (conn.tnam, stat); {add file pathname}
{
*   Common error abort point.  STAT is already fully set.  The connection to
*   the environment file set is closed.
}
abort:
  file_close (conn);                   {close connection to the environment file set}
  end;                                 {return with error status}
