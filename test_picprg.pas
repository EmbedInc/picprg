{   Program TEST_PICPRG
*
*   Low level test program for the PICPRG library.  This library is a
*   procedural interface to various Embed Inc PIC programmers adhering to
*   the protocol described in the PICPRG_PROT documentation file.
}
program test_picprg;
%include 'picprg2.ins.pas';
%include 'math.ins.pas';

const
  n_cmdnames_k = 80;                   {number of command names in the list}
  cmdname_maxchars_k = 7;              {max chars in any command name}
  max_msg_args = 4;                    {max arguments we can pass to a message}
  datarsize_k = 16#20000;              {size of test data array}

  datarlast_k = datarsize_k - 1;       {last test data array index}
{
*   Derived constants.
}
  cmdname_len_k = cmdname_maxchars_k + 1; {number of chars to reserve per cmd name}

type
  cmdname_t =                          {one command name in the list}
    array[1..cmdname_len_k] of char;
  cmdnames_t =                         {list of all the command names}
    array[1..n_cmdnames_k] of cmdname_t;

var
  cmdnames: cmdnames_t := [            {list of all the command names}
    'HELP   ',                         {1}
    'EXIT   ',                         {2}
    'NOP    ',                         {3}
    'OFF    ',                         {4}
    'ID     ',                         {5}
    'SEND   ',                         {6}
    'RECV   ',                         {7}
    'CLKH   ',                         {8}
    'CLKL   ',                         {9}
    'DATH   ',                         {10}
    'DATL   ',                         {11}
    'DATR   ',                         {12}
    'TDRIVE ',                         {13}
    'WAIT   ',                         {14}
    'FWINFO ',                         {15}
    'VDDVALS',                         {16}
    'VDDLOW ',                         {17}
    'VDDNORM',                         {18}
    'VDDHIGH',                         {19}
    'VDDOFF ',                         {20}
    'VPPON  ',                         {21}
    'VPPOFF ',                         {22}
    'IDRESET',                         {23}
    'IDWRITE',                         {24}
    'IDREAD ',                         {25}
    'RESET  ',                         {26}
    'T1     ',                         {27}
    'X1     ',                         {28}
    'PINS   ',                         {29}
    'TINFO  ',                         {30}
    'ADR    ',                         {31}
    'RD     ',                         {32}
    'WR     ',                         {33}
    'CONFIG ',                         {34}
    'ERASE  ',                         {35}
    'WTEST  ',                         {36}
    'TPROG  ',                         {37}
    'SPPROG ',                         {38}
    'SPDATA ',                         {39}
    'W      ',                         {40}
    'RESADR ',                         {41}
    'CHKCMD ',                         {42}
    'GETV   ',                         {43}
    'LED    ',                         {44}
    'BUTT   ',                         {45}
    'RUN    ',                         {46}
    'HIGHZ  ',                         {47}
    'NTOUT  ',                         {48}
    'GETCAP ',                         {49}
    'T2     ',                         {50}
    'SHOWIN ',                         {51}
    'SHOWOUT',                         {52}
    'QUIT   ',                         {53}
    'VDD    ',                         {54}
    'VPP    ',                         {55}
    'LT     ',                         {56}
    'NAME   ',                         {57}
    'RD64   ',                         {58}
    'CMD    ',                         {59}
    'P-ANA  ',                         {60}
    'P-LED  ',                         {61}
    'P-CAL  ',                         {62}
    'P-WCAL ',                         {63}
    'P-SER  ',                         {64}
    'P-SNEXT',                         {65}
    'P-SSET ',                         {66}
    'P-SW   ',                         {67}
    'VPPHIZ ',                         {68}
    'T      ',                         {69}
    'TESTGET',                         {70}
    'TESTSET',                         {71}
    'P-PWR  ',                         {72}
    'P-T5V  ',                         {73}
    'P-SEG  ',                         {74}
    'P-OCC  ',                         {75}
    'P-LID  ',                         {76}
    'P-TAD  ',                         {77}
    'DATADR ',                         {78}
    'PB     ',                         {79}
    'GB     ',                         {80}
    ];

type
  space_k_t = (                        {IDs for the different target address spaces}
    space_prog_k,                      {program memory}
    space_data_k);                     {data (EEPROM) memory}

  devtype_k_t = (                      {remote unit device type ID}
    devtype_unk_k,                     {unknown}
    devtype_easyprog_k,                {Embed Inc EasyProg}
    devtype_proprog_k,                 {Embed Inc ProProg}
    devtype_usbprog_k,                 {Embed Inc USBProg}
    devtype_lprog_k,                   {Embed Inc LProg}
    devtype_360t_k,                    {Radianse 360 tag tester}
    devtype_oc1t_k);                   {OC1 production test jig}

var
  pr: picprg_t;                        {PICPRG library use state}
  cmd: picprg_cmd_t;                   {descriptor for one remote unit command}
  i32: sys_int_conv32_t;               {scratch 32 bit integer}
  i, i1, i2, i3, i4, i5: sys_int_machine_t; {scratch integers}
  idwidth: sys_int_machine_t;          {width of ID word in current ID namespace}
  idspace: picprg_idspace_k_t;         {namespace of target chip ID}
  id: picprg_chipid_t;                 {hard coded target chip ID}
  pinfo: picprg_pininfo_t;             {info about target chip pins}
  b: boolean;                          {scratch boolean}
  ntout: boolean;                      {host timeout disabled by this command}
  dover: boolean;                      {verify enabled}
  i8: int8u_t;                         {scratch 8 bit integer}
  r, r1, r2, r3, r4, r5: real;         {scratch floating point numbers}
  tinfo: picprg_tinfo_t;               {specific target chip info}
  adr: picprg_adr_t;                   {target chip address value}
  dat: picprg_dat_t;                   {target data word}
  mask_p: picprg_maskdat_p_t;          {pnt to mask info for current space}
  maxmask: picprg_dat_t;               {max mask for any words in current space}
  datbitse, datbitso: sys_int_machine_t; {bits in even/odd data words}
  maxbits: sys_int_machine_t;          {max bits for any word in current space}
  timer, timer2: sys_timer_t;          {stopwatch timer}
  rand: math_rand_seed_t;              {random number generator seed}
  space: space_k_t;                    {ID for address space currently set to}
  devtype: devtype_k_t;                {ID for the remote device type}
  ent_p: picprg_adrent_p_t;            {pointer to list of config word addresses}
  datar: array[0 .. datarlast_k] of picprg_dat_t; {data array for writing, reference}
  bytes: picprg_bytes_t;               {array of arbitrary bytes}
  twover: boolean;                     {do two verify passes at the Vdd limits}

  buf:                                 {one line command buffer}
    %include '(cog)lib/string8192.ins.pas';
  p: string_index_t;                   {BUF parse index}
  opt:                                 {upcased command line option}
    %include '(cog)lib/string_treename.ins.pas';
  parm:                                {command line option parameter}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_opt, done_opt, err_parm, parm_bad, done_opts,
  loop_cmd, wrver, p_ser, show_rsp,
  done_cmd, err_extra, done_waitchk, bad_cmd, err_cmparm, leave;
{
***************************************************************************
*
*   Subroutine INSPACE (SP)
*
*   Indicate the new address space setting.
}
procedure inspace (                    {indicate the current address space setting}
  in      sp: space_k_t);              {ID for the current address space setting}
  val_param;

var
  m: picprg_dat_t;

begin
  case sp of
space_prog_k: begin                    {program memory address space}
      mask_p := addr(tinfo.maskprg);
      end;
space_data_k: begin                    {data memory address space}
      mask_p := addr(tinfo.maskdat);
      end;
otherwise
    writeln ('INTERNAL ERROR: Unexpected SP value of ', ord(sp), ' in INSPACE.');
    sys_bomb;
    end;

  space := sp;                         {set the new space current}
  maxmask := mask_p^.maske ! mask_p^.masko; {mask of valid bits any word this space}

  datbitse := 0;                       {init bits in data word at even address}
  m := mask_p^.maske;                  {init test mask}
  while m <> 0 do begin
    datbitse := datbitse + 1;          {count one more bit in word}
    m := rshft(m, 1);                  {update test mask}
    end;
  datbitso := 0;                       {init bits in data word at odd address}
  m := mask_p^.masko;                  {init test mask}
  while m <> 0 do begin
    datbitso := datbitso + 1;          {count one more bit in word}
    m := rshft(m, 1);                  {update test mask}
    end;
  maxbits := max(datbitse, datbitso);  {max bits in any word in this space}
  end;
{
***************************************************************************
*
*   Subroutine RESETSP (STAT)
*
*   Reset the target but preserve the current address space setting.
}
procedure resetsp (                    {reset, preserve address space setting}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_reset (pr, stat);             {reset the target chip}
  if sys_error(stat) then return;

  case space of                        {what was the address space setting ?}
space_prog_k: ;                        {reset always goes back to this, nothing to do}
space_data_k: begin                    {data (EEPROM) address space}
      picprg_space_set (pr, picprg_space_data_k, stat);
      if sys_error(stat) then return;
      end;
otherwise
    sys_stat_set (picprg_subsys_k, picprg_stat_badspace_k, stat);
    sys_stat_parm_int (ord(space), stat);
    return;
    end;
  end;
{
***************************************************************************
*
*   Subroutine NEXT_KEYW (TK, STAT)
*
*   Parse the next token from BUF as a keyword and return it in TK.
}
procedure next_keyw (
  in out  tk: univ string_var_arg_t;   {returned token}
  out     stat: sys_err_t);
  val_param;

begin
  string_token (buf, p, tk, stat);
  string_upcase (tk);
  end;
{
***************************************************************************
*
*   Function NEXT_INT (MN, MX, STAT)
*
*   Parse the next token from BUF and return its value as an integer.
*   MN and MX are the min/max valid range of the integer value.
}
function next_int (                    {get next token as integer value}
  in      mn, mx: sys_int_machine_t;   {valid min/max range}
  out     stat: sys_err_t)             {completion status code}
  :sys_int_machine_t;
  val_param;

var
  i: sys_int_machine_t;

begin
  string_token_int (buf, p, i, stat);  {get token value in I}
  next_int := i;                       {pass back value}
  if sys_error(stat) then return;

  if (i < mn) or (i > mx) then begin   {out of range}
    writeln ('Value ', i, ' is out of range.');
    sys_stat_set (sys_subsys_k, sys_stat_failed_k, stat);
    end;
  end;
{
***************************************************************************
*
*   Function NEXT_FP (STAT)
*
*   Parse the next token from BUF and return its value as a floating
*   point number.
}
function next_fp (                     {get next token as floating point value}
  out     stat: sys_err_t)             {completion status code}
  :real;
  val_param;

var
  r: real;

begin
  string_token_fpm (buf, p, r, stat);
  next_fp := r;
  end;
{
***************************************************************************
*
*   Function NEXT_CHOICE (NAMES, STAT)
*
*   Parse the next token from BUF and return which choice of keywords
*   from NAMES it matches.  NAMES must be an upper case list of tokens
*   separated by spaces.  If a keyword in NAMES matches the input token,
*   then STAT is returned indicating no error and the function value
*   is the 1-N number of the keyword.  If no match is found, STAT is
*   set appropriately and the function returns 0.
}
function next_choice (                 {get next token as keyword choice}
  in      names: string;               {upper case list of keywords, blank separated}
  out     stat: sys_err_t)             {completion status code}
  :sys_int_machine_t;

var
  tk: string_var80_t;                  {the input token}
  pick: sys_int_machine_t;             {number of keyword picked from list}

begin
  tk.max := size_char(tk.str);         {init local var string}
  next_choice := 0;                    {init function value}

  next_keyw (tk, stat);                {get next input token}
  if sys_error(stat) then return;
  string_upcase (tk);                  {make upper case for keyword matching}
  string_tkpick80 (tk, names, pick);
  next_choice := pick;
  if pick = 0 then begin               {no match found ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_arg_bad_k, stat);
    sys_stat_parm_vstr (tk, stat);
    end;
  end;
{
***************************************************************************
*
*   Function NOT_EOS
*
*   Returns TRUE if the input buffer BUF was is not exhausted.  This is
*   used to check for additional tokens at the end of a command.
}
function not_eos                       {check for more tokens left}
  :boolean;                            {TRUE if more tokens left in BUF}

var
  psave: string_index_t;               {saved copy of BUF parse index}
  tk: string_var4_t;                   {token parsed from BUF}
  stat: sys_err_t;                     {completion status code}

begin
  tk.max := size_char(tk.str);         {init local var string}

  not_eos := false;                    {init to BUF has been exhausted}
  psave := p;                          {save current BUF parse index}
  string_token (buf, p, tk, stat);     {try to get another token}
  if sys_error(stat) then return;      {assume normal end of line encountered ?}
  not_eos := true;                     {indicate a token was found}
  p := psave;                          {reset parse index to get this token again}
  end;
{
************************************************************************
*
*   Subroutine SHOW_BIN (VAL, NB)
*
*   Show a value in binary, hexadecimal, and decimal.  VAL is the value
*   and NB is the number of bits to show in binary.
}
procedure show_bin (                   {show value in binary, hex, and decimal}
  in      val: sys_int_conv32_t;       {the integer value}
  in      nb: sys_int_machine_t);      {number of bits to show in binary}
  val_param;

const
  dig_bit = 0.3010300;                 {decimal digits per binary bit}

var
  tk: string_var80_t;                  {scratch string}
  nd: sys_int_machine_t;               {number of digits}
  stat: sys_err_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_int_max_base (              {make binary string}
    tk,                                {output string}
    val,                               {input value}
    2,                                 {radix}
    nb,                                {field width}
    [ string_fi_leadz_k,               {pad on left with leading zeros}
      string_fi_unsig_k],              {the input number is unsigned}
    stat);
  write (tk.str:tk.len, 'b ');

  string_f_int_max_base (              {make hexadecimal string}
    tk,                                {output string}
    val,                               {input value}
    16,                                {radix}
    (nb + 3) div 4,                    {field width}
    [ string_fi_leadz_k,               {pad on left with leading zeros}
      string_fi_unsig_k],              {the input number is unsigned}
    stat);
  write (tk.str:tk.len, 'h ');

  nd := trunc(nb * dig_bit + 1.0);     {make max decimal digits required}
  string_f_int_max_base (              {make decimal string}
    tk,                                {output string}
    val,                               {input value}
    10,                                {radix}
    nd,                                {fixed field width}
    [string_fi_unsig_k],               {the input number is unsigned}
    stat);
  write (tk.str:tk.len);

  if nb = 8 then begin                 {this is a byte value ?}
    write (' ');
    if (val >= 32) and (val <= 254)
      then begin                       {printable value}
        write (' ', chr(val));
        end
      else begin                       {control character}
        case val of
10:       write ('LF');
13:       write ('CR');
otherwise
          write ('--');
          end;
        end;
      ;
    end;

  writeln;
  end;
{
************************************************************************
*
*   Subroutine SHOW_NAMESPACE (SP)
*
*   Show the chip ID namespace identified by SP.
}
procedure show_namespace (             {show chip ID namespace name}
  in      sp: picprg_idspace_k_t);     {namespace ID to show value of}
  val_param;

begin
  write ('ID Namespace ');
  case sp of
picprg_idspace_unk_k: begin            {ID space not known}
      idwidth := 16;
      write ('UNKNOWN');
      end;
picprg_idspace_16_k: begin             {generic PIC16, 14 bit ID word}
      idwidth := 14;
      write ('14 bit "midrange" core');
      end;
picprg_idspace_18_k: begin             {generic PIC18, 16 bit ID word}
      idwidth := 16;
      write ('16 bit "high end" core');
      end;
picprg_idspace_12_k: begin             {generic 12 bit core}
      idwidth := 12;
      write ('12 bit "baseline" core');
      end;
picprg_idspace_30_k: begin             {generic PIC30 (dsPIC)}
      idwidth := 32;
      write ('dsPIC');
      end;
otherwise
    write (', ID = ', ord(sp));
    end;
  end;
{
************************************************************************
*
*   Subroutine VERIFY (ADR, N, REF)
*
*   Verify the N target chip locations starting at address ADR.  REF
*   is the array of expected reference values.
}
procedure verify (                     {verify data in target memory locations}
  in      adr: picprg_adr_t;           {starting address}
  in      n: picprg_adr_t;             {number of locations to verify}
  in      ref: univ picprg_datar_t);   {array of expected reference values}
  val_param;

var
  timer: sys_timer_t;                  {stopwatch timer}
  i: sys_int_machine_t;                {array index}
  j: sys_int_machine_t;                {scratch integer and loop counter}
  show1, show2: picprg_adr_t;          {start and end addresses to show}
  dat: array[0 .. datarlast_k] of picprg_dat_t; {data read from target chip}
  sec: real;                           {elapsed seconds}
  r2, r3: real;                        {additonal floating point values for parms}
  msg_parm:                            {references arguments passed to a message}
    array[1..4] of sys_parm_msg_t;
  tk: string_var32_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  sys_timer_init (timer);              {initialize the stopwatch}
  sys_timer_start (timer);             {start the stopwatch}
  picprg_read (pr, adr, n, mask_p^, dat, stat); {read back all the data}
  sys_timer_stop (timer);              {stop the stopwatch}

  sec := sys_timer_sec (timer);        {return elapsed seconds}
  r2 := sec * 8192.0 / n;              {seconds per 8K words}
  r3 := sec * 1000.0 / n;              {mS per word}
  sys_msg_parm_int (msg_parm[1], n);
  sys_msg_parm_real (msg_parm[2], sec);
  sys_msg_parm_real (msg_parm[3], r2);
  sys_msg_parm_real (msg_parm[4], r3);
  write ('  ');
  sys_message_parms ('picprg', 'read_stats', msg_parm, 4);

  for i := 0 to n-1 do begin           {loop thru all the data values}
    if dat[i] <> ref[i] then begin     {found a discrepancy ?}
      write ('  Error at location ');
      show_bin (i + adr, 24);
      write ('    expected '); show_bin (ref[i], 16);
      write ('       found '); show_bin (dat[i], 16);
      show1 := max(0, i-4);            {start index to show at}
      show2 := min(n-1, i+16);         {end index to show at}
      writeln;
      writeln (' Address   Expected   Found');
      for j := show1 to show2 do begin {once for each location to show}
        string_f_int32h (tk, j + adr);
        write (tk.str:tk.len);
        string_f_int16h (tk, ref[j]);
        write ('       ', tk.str:tk.len);
        string_f_int16h (tk, dat[j]);
        write ('    ', tk.str:tk.len);
        writeln;
        end;
      return;
      end;
    end;                               {back to check next location}
  writeln ('  No errors.');
  end;
{
************************************************************************
*
*   Start of main routine.
}
begin
  string_cmline_init;                  {init for reading the command line}
  math_rand_init_clock (rand);         {init random number seed from system clock}
{
*   Initialize our state before reading the command line options.
}
  picprg_init (pr);                    {init PICPRG library options to defaults}
  pr.debug := 1;                       {init debug output messages level}
  pr.flags := pr.flags + [picprg_flag_nintout_k]; {disable input timeout}

  picprg_mask_same (16#FFFF, tinfo.maskprg); {init generic values before config}
  picprg_mask_same (16#FFFF, tinfo.maskdat);
  inspace (space_prog_k);              {init to program, not data, memory space}

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
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (opt,                {pick command line option name from list}
    '-SIO -N -SHOW',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -SIO n
}
1: begin
  string_cmline_token_int (pr.sio, stat);
  pr.devconn := picprg_devconn_sio_k;
  end;
{
*   -N name
}
2: begin
  string_cmline_token (pr.prgname, stat); {get programmer name}
  if sys_error(stat) then goto err_parm;
  end;
{
*   -SHOW
}
3: begin
  pr.flags := pr.flags + [picprg_flag_showin_k];
  pr.flags := pr.flags + [picprg_flag_showout_k];
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

parm_bad:                              {jump here on got illegal parameter}
  string_cmline_reuse;                 {re-read last command line token next time}
  string_cmline_token (parm, stat);    {re-read the token for the bad parameter}
  sys_msg_parm_vstr (msg_parm[1], parm);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);

done_opts:                             {done with all the command line options}
{
*   Done reading the command line.
}
  picprg_open (pr, stat);              {open the PICPRG library}
  sys_error_abort (stat, 'picprg', 'open', nil, 0);
{
*   Set system state based on the programmer firmware info.
}
  twover := false;                     {init to only one verify pass at main Vdd level}

  devtype := devtype_unk_k;            {init to unknown device type}
  case pr.fwinfo.org of                {which organization created this device ?}
picprg_org_official_k: begin           {Embed Inc}
      case pr.fwinfo.id of
0:      devtype := devtype_easyprog_k;
1:      devtype := devtype_proprog_k;
2:      devtype := devtype_usbprog_k;
3:      devtype := devtype_lprog_k;
4:      devtype := devtype_oc1t_k;
        end;
      end;
picprg_org_radianse_k: begin
      case pr.fwinfo.id of
0:      devtype := devtype_360t_k;
        end;
      end;
    end;                               {end of organization ID cases}
{
*   Get and process commands from the user.
}
loop_cmd:                              {back here to get each new command from user}
  string_prompt (string_v(': '(0)));   {prompt for the next command}
  string_readin (buf);                 {get command from the user}
  if buf.len <= 0 then goto loop_cmd;  {ignore blank lines}
  p := 1;                              {init BUF parse index}
  next_keyw (opt, stat);               {extract command name into OPT}
  if sys_error_check (stat, '', '', nil, 0) then begin
    goto loop_cmd;
    end;
  ntout := false;                      {init this command not disable host timeout}
  string_tkpick_s (                    {pick command name from list}
    opt, cmdnames, sizeof(cmdnames), pick);
  case pick of                         {which command is it}
{
**********
*
*   HELP
}
1: begin
  if not_eos then goto err_extra;
  writeln ('HELP   - Show this list of commands.');
  writeln ('QUIT   - Disconnect from target and exit the program.');
  writeln ('EXIT   - Exit program, leave target connection as is.');
  writeln ('ID     - Get target chip hard coded ID.');
  writeln ('TINFO  - Get detailed target chip info.');
  writeln ('CONFIG [name] - Configure to the specific target chip.');
  writeln ('ERASE  - Erase all eraseable non-volatile target chip memory.');
  writeln ('WTEST adr n [nv] - Write N locations at ADR, NV = no verify.');
  writeln ('SHOWIN on/off - enable/disable show raw bytes from programmer.');
  writeln ('SHOWOUT on/off - enable/xdisable show raw bytes to programmer.');
  writeln ('LT     - Local test, driven from host, no dedicated function.');
  writeln ('W adr dat ... dat - array write.');
  writeln ('GETV   - Get and show all available voltages.');
  writeln ('CMD opc [data ... data] RSP n lenb - send arbitray command.');
  writeln ('These commands directly send commands to the remote unit:');
  writeln ('  NOP    - No operation, just sends ACK.');
  writeln ('  OFF    - Turn off power to target chip.');
  writeln ('  SEND nbits data - Send serial bits to target chip.');
  writeln ('  RECV nbits - Get serial bits from target chip.');
  writeln ('  CLKH   - Set serial clock line high.');
  writeln ('  CLKL   - Set serial clock line low.');
  writeln ('  DATH   - Set serial data line high.');
  writeln ('  DATL   - Set serial data line low.');
  writeln ('  DATR   - Read serial data line from target.');
  writeln ('  TDRIVE - Check whether target driving data line.');
  writeln ('  WAIT sec - Guaranteed wait before next target operation.');
  writeln ('  FWINFO - Show firmware info.');
  writeln ('  VDDVALS Vlow Vnorm Vhigh - Set target Vdd level (volts).');
  writeln ('  VDD volts - Set Vdd level next time enabled.');
  writeln ('  VDDLOW - Set Vdd to LOW level.');
  writeln ('  VDDNORM - Set Vdd to NORMAL level.');
  writeln ('  VDDHIGH - Set Vdd to HIGH level.');
  writeln ('  VDDOFF - Turn off Vdd (drive to GND).');
  writeln ('  VDD volts - Set Vpp level next time enabled.');
  writeln ('  VPPON  - Turn on programming voltage.');
  writeln ('  VPPOFF - Turn off programming voltage.');
  writeln ('  VPPHIZ - Set Vpp to high impedence.');
  writeln ('  IDRESET name - Select reset algoritm, NAME =');
  writeln ('    NONE - Does nothing, target not accessed.');
  writeln ('    62x  - Vpp before Vdd like 16F62x.');
  writeln ('    18F  - Vdd before Vpp like 18Fxxx.');
  writeln ('    DPNA - Vdd before Vpp, adr unknown.');
  writeln ('    30F  - For 30Fxxxx (dsPIC).');
  writeln ('    DPF  - Vdd then Vpp as quickly as possible.');
  writeln ('    18J  - Special unlock sequence for 18F25J10 and others.');
  writeln ('    24H  - For 24H and 33F devices.');
  writeln ('    24F  - For 24F devices.');
  writeln ('    182x - for 16F182x key sequence.');
  writeln ('    24FJ - For 24FJ devices.');
  writeln ('    18K80');
  writeln ('    33EP');
  writeln ('    16F153 - Vpp low, "MCHP" signature MSB to LSB.');
  writeln ('  IDWRITE id - Select write algorithm, NAME =');
  writeln ('    0    - Does nothing, target not accessed.');
  writeln ('    1    - Generic 16Fxxx.');
  writeln ('    2    - 12F6xx, 16F6xxA.');
  writeln ('    3    - 12 bit core devices.');
  writeln ('    4    - dsPIC.');
  writeln ('    5    - 16F87xA.');
  writeln ('    6    - 16F716.');
  writeln ('    7    - 16F688.');
  writeln ('    8    - 18F2520.');
  writeln ('    9    - 16F87/88.');
  writeln ('    10   - 16F77.');
  writeln ('    11   - 16F88x.');
  writeln ('    12   - 16F82x.');
  writeln ('    13   - 16F15313.');
  writeln ('  IDREAD name - Select read algorithm, NAME =');
  writeln ('    NONE - Does nothing, target not accessed.');
  writeln ('    16F  - Generic 16Fxxx.');
  writeln ('    18FP - Generic 18Fxxx, program memory only.');
  writeln ('    CORE12 - 12 bit core devices.');
  writeln ('    30F  - dsPIC.');
  writeln ('    18F  - 18F program memory and EEPROM.');
  writeln ('    16FE - enhanced 16F, 16F1xxx.');
  writeln ('    16FB - 16F with 8 bit opcodes, like 16F15313');
  writeln ('  RESET  - Reset.  Vdd norm, Vpp on, SPPROG.');
  writeln ('  T1     - Run debugging test.');
  writeln ('  PINS   - Get info about target chip pins.');
  writeln ('  ADR address - Set address for next target operation.');
  writeln ('  RD [adr [n]] - Read data from target, increment address.');
  writeln ('  WR dat - Write data to target, increment address.');
  writeln ('  TPROG ms - Set program write cycle wait time in mS.');
  writeln ('  SPPROG - Switch to program memory space, def after reset.');
  writeln ('  SPDATA - Switch to data memory space.');
  writeln ('  RESADR adr - Indicate target chip address after reset.');
  writeln ('  CHKCMD opc - Check command opcode for availability.');
  writeln ('  LED bri1 t1 bri2 t2 - App LED, BRIx 0-15, Tx in seconds.');
  writeln ('  BUTT   - Get number of user button presses.');
  writeln ('  RUN [Vdd] - Let target run at Vdd, target Vdd default.');
  writeln ('  HIGHZ  - Set target lines to high impedence.');
  writeln ('  NTOUT  - Disable command stream timeout until next command.');
  writeln ('  GETCAP capID dat - Inquire about a specific capability.');
  writeln ('  NAME [newname] - Set or show user-defined name of remote unit.');
  writeln ('  RD64   - Read 64 words at current address, advance address.');
  writeln ('  DATADR adr - Set data mem start in prog mem adr space.');
  writeln ('  TESTGET - Get test mode ID.');
  writeln ('  TESTSET id - Set test mode.');
  writeln ('  PB byte...byte - Send bytes over serial data port.');
  writeln ('  GB     - Get bytes received by serial data port.');
  case devtype of
devtype_360t_k: begin                  {Radianse 360 tag tester}
      writeln ('Private commands of Radianse 360 tag tester:');
      writeln ('  P-ANA  - Get Vdd current and RSSI analog values.');
      writeln ('  P-LED on/off - Control LED on the target tag.');
      writeln ('  P-CAL  - Get non-volatile calibration data.');
      writeln ('  P-WCAL adr dat ... dat - Set calibration bytes starting at ADR.');
      writeln ('  P-SER  - Get current serial number state.');
      writeln ('  P-SNEXT - Advance to next serial number.');
      writeln ('  P-SSET start last - Set new serial number range.');
      writeln ('  P-SW   - Get external switch info.');
      end;
devtype_oc1t_k: begin                  {Olin's Depot OC1 production test jig}
      writeln ('Private command of OC1 production tester:');
      writeln ('  P-PWR on/off - Target power on or off');
      writeln ('  P-T5V  - Get Target 5 V supply level');
      writeln ('  P-SEG mask - Set simulated DCC current source on/off per segment');
      writeln ('  P-OCC  - Get value of the occupancy detection outputs');
      writeln ('  P-LID  - Get lid transitions count, even = open, odd = closed');
      writeln ('  P-TAD  - Get filtered target A/D readings');
      end;
    end;                               {end of special device type cases}
  end;
{
**********
*
*   EXIT
*
*   Exit program, leave target as is.
}
2: begin
  if not_eos then goto err_extra;
  goto leave;
  end;
{
**********
*
*   NOP
}
3: begin
  if not_eos then goto err_extra;

  picprg_cmd_nop (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_nop (pr, cmd, stat);
  end;
{
**********
*
*   OFF
}
4: begin
  if not_eos then goto err_extra;

  picprg_cmd_off (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_off (pr, cmd, stat);
  end;
{
**********
*
*   ID
}
5: begin
  if not_eos then goto err_extra;

  picprg_id (pr, nil, idspace, id, stat); {get the chip ID info}
  if sys_error(stat) then goto err_cmparm;
  inspace (space_prog_k);              {indicate now in program memory space}

  show_namespace (idspace);
  write (', ');
  show_bin (id, 32);
  end;
{
**********
*
*   SEND nbits data
}
6: begin
  i8 := next_int (1, 32, stat);
  if sys_error(stat) then goto err_cmparm;
  i32 := next_int (16#80000000, 16#7FFFFFFF, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_send (pr, i8, i32, stat);
  end;
{
**********
*
*   RECV nbits
}
7: begin
  i8 := next_int (1, 32, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_recv (pr, i8, i32, stat);
  if sys_error(stat) then goto err_cmparm;

  show_bin (i32, i8);
  end;
{
**********
*
*   CLKH
}
8: begin
  if not_eos then goto err_extra;

  picprg_cmd_clkh (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_clkh (pr, cmd, stat);
  end;
{
**********
*
*   CLKL
}
9: begin
  if not_eos then goto err_extra;

  picprg_cmd_clkl (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_clkl (pr, cmd, stat);
  end;
{
**********
*
*   DATH
}
10: begin
  if not_eos then goto err_extra;

  picprg_cmd_dath (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_dath (pr, cmd, stat);
  end;
{
**********
*
*   DATL
}
11: begin
  if not_eos then goto err_extra;

  picprg_cmd_datl (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_datl (pr, cmd, stat);
  end;
{
**********
*
*   DATR
}
12: begin
  if not_eos then goto err_extra;

  picprg_cmd_datr (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_datr (pr, cmd, b, stat);
  if sys_error(stat) then goto err_cmparm;

  if b
    then writeln ('1')
    else writeln ('0');
  end;
{
**********
*
*   TDRIVE
}
13: begin
  if not_eos then goto err_extra;

  picprg_cmd_tdrive (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_tdrive (pr, cmd, b, stat);
  if sys_error(stat) then goto err_cmparm;

  if b
    then writeln ('driven')
    else writeln ('floating');
  end;
{
**********
*
*   WAIT sec
}
14: begin
  r := next_fp (stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmd_wait (pr, cmd, r, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_wait (pr, cmd, stat);
  end;
{
**********
*
*   FWINFO
}
15: begin
  if not_eos then goto err_extra;

  writeln ('Organization ID:   ', ord(pr.fwinfo.org));
  if                                   {this organization ID is valid ?}
      (ord(pr.fwinfo.org) >= ord(picprg_org_min_k)) and
      (ord(pr.fwinfo.org) <= ord(picprg_org_max_k))
      then begin
    writeln ('Organization name: ',
      pr.env.org[pr.fwinfo.org].name.str:pr.env.org[pr.fwinfo.org].name.len);
    writeln ('Web page:          http://',
      pr.env.org[pr.fwinfo.org].webpage.str:pr.env.org[pr.fwinfo.org].webpage.len);
    end;
  if pr.fwinfo.cvlo = pr.fwinfo.cvhi
    then begin                         {compatible with only one spec version}
      writeln ('Implements protocol spec version ', pr.fwinfo.cvlo);
      end
    else begin                         {compatible with range of spec versions}
      writeln ('Implements protocol spec versions ', pr.fwinfo.cvlo,
        ' - ', pr.fwinfo.cvhi);
      end
    ;
  writeln ('Firmware type: ', pr.fwinfo.id,
    ', name: "', pr.fwinfo.idname.str:pr.fwinfo.idname.len, '"');
  writeln ('Version ', pr.fwinfo.vers);
  write ('Private data: ');
  show_bin (pr.fwinfo.info, 32);

  write ('Variable Vdd: ');
  if pr.fwinfo.varvdd
    then write ('YES')
    else write ('NO');
  writeln (', range', pr.fwinfo.vddmin:7:3, ' -', pr.fwinfo.vddmax:7:3);

  writeln ('Vpp range:', pr.fwinfo.vppmin:7:3, ' -', pr.fwinfo.vppmax:7:3);
  writeln ('Tick period:', (pr.fwinfo.ticksec * 1.0e6):8:1, 'uS');

  write ('Reset algorithms:');
  i32 := integer32(pr.fwinfo.idreset); {get set as a plain integer}
  i2 := 1;                             {init mask}
  for i := 0 to 31 do begin            {show the supported algorithms}
    if (i32 & i2) <> 0 then begin
      write (' ', i);
      end;
    i2 := lshft(i2, 1);
    end;
  writeln;

  write ('Write algorithms:');
  i32 := integer32(pr.fwinfo.idwrite); {get set as a plain integer}
  i2 := 1;                             {init mask}
  for i := 0 to 31 do begin            {show the supported algorithms}
    if (i32 & i2) <> 0 then begin
      write (' ', i);
      end;
    i2 := lshft(i2, 1);
    end;
  writeln;

  write ('Read algorithms: ');
  i32 := integer32(pr.fwinfo.idread);  {get set as a plain integer}
  i2 := 1;                             {init mask}
  for i := 0 to 31 do begin            {show the supported algorithms}
    if (i32 & i2) <> 0 then begin
      write (' ', i);
      end;
    i2 := lshft(i2, 1);
    end;
  writeln;

  write ('Private commands:');
  for i := 240 to 255 do begin
    if pr.fwinfo.cmd[i] then write (' ', i);
    end;
  writeln;
  end;
{
**********
*
*   VDDVALS vlow vnorm vhigh
}
16: begin
  r := next_fp (stat);
  if sys_error(stat) then goto err_cmparm;
  r2 := next_fp (stat);
  if sys_error(stat) then goto err_cmparm;
  r3 := next_fp (stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmd_vddvals (pr, cmd, r, r2, r3, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_vddvals (pr, cmd, stat);
  end;
{
**********
*
*   VDDLOW
}
17: begin
  if not_eos then goto err_extra;

  picprg_cmd_vddlow (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_vddlow (pr, cmd, stat);
  end;
{
**********
*
*   VDDNORM
}
18: begin
  if not_eos then goto err_extra;

  picprg_cmd_vddnorm (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_vddnorm (pr, cmd, stat);
  end;
{
**********
*
*   VDDHIGH
}
19: begin
  if not_eos then goto err_extra;

  picprg_cmd_vddhigh (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_vddhigh (pr, cmd, stat);
  end;
{
**********
*
*   VDDOFF
}
20: begin
  if not_eos then goto err_extra;

  picprg_cmd_vddoff (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_vddoff (pr, cmd, stat);
  end;
{
**********
*
*   VPPON
}
21: begin
  if not_eos then goto err_extra;

  picprg_cmd_vppon (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_vppon (pr, cmd, stat);
  end;
{
**********
*
*   VPPOFF
}
22: begin
  if not_eos then goto err_extra;

  picprg_cmd_vppoff (pr, cmd, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_vppoff (pr, cmd, stat);
  end;
{
**********
*
*   IDRESET name
}
23: begin
  i8 := next_choice (
    'NONE 62X 18F DPNA 30F DPF 18J 24H 24F 182X 24FJ 18K80 33EP 16F153',
    stat) - 1;
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  b := false;                          {init to not specify Vdd off before Vpp}
  case i8 of                           {check for Vdd off before Vpp special cases}
1:  b := true;
    end;

  picprg_cmd_idreset (pr, cmd, picprg_reset_k_t(i8), b, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_idreset (pr, cmd, stat);
  end;
{
**********
*
*   IDWRITE name
}
24: begin
  i8 := next_int (0, 255, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmd_idwrite (pr, cmd, picprg_write_k_t(i8), stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_rsp_idwrite (pr, cmd, stat);
  end;
{
**********
*
*   IDREAD name
}
25: begin
  i8 := next_choice ('NONE 16F 18FP CORE12 30F 18F 16FE 16FB', stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  case i8 of
1:  begin                              {IDREAD NONE}
      picprg_cmdw_idread (pr, picprg_read_none_k, stat); {set firmware algorithm}
      if sys_error(stat) then goto err_cmparm;
      pr.read_p := nil;                {uninstall any array read routine}
      end;
2:  begin                              {IDREAD 16F}
      picprg_cmdw_idread (pr, picprg_read_16f_k, stat); {set firmware algorithm}
      if sys_error(stat) then goto err_cmparm;
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;
3:  begin                              {IDREAD 18FP}
      picprg_cmdw_idread (pr, picprg_read_18f_k, stat); {set firmware algorithm}
      if sys_error(stat) then goto err_cmparm;
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;
4:  begin                              {IDREAD CORE12}
      picprg_cmdw_idread (pr, picprg_read_core12_k, stat); {set firmware algorithm}
      if sys_error(stat) then goto err_cmparm;
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;
5:  begin                              {IDREAD 30F}
      picprg_cmdw_idread (pr, picprg_read_30f_k, stat); {set firmware algorithm}
      if sys_error(stat) then goto err_cmparm;
      pr.read_p := nil;                {read routine installed by PICPRG_SPACE}
      end;
6:  begin                              {IDREAD 18F}
      picprg_cmdw_idread (pr, picprg_read_18fe_k, stat); {set firmware algorithm}
      if sys_error(stat) then goto err_cmparm;
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;
7:  begin
      picprg_cmdw_idread (pr, picprg_read_16fe_k, stat); {set firmware algorithm}
      if sys_error(stat) then goto err_cmparm;
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;
8:  begin
      picprg_cmdw_idread (pr, picprg_read_16fb_k, stat); {set firmware algorithm}
      if sys_error(stat) then goto err_cmparm;
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

otherwise
    writeln ('Unexpected read routine choice number.');
    end;
  end;
{
**********
*
*   RESET
}
26: begin
  if not_eos then goto err_extra;

  picprg_reset (pr, stat);             {reset the target chip and state}
  if sys_error(stat) then goto err_cmparm;
  inspace (space_prog_k);              {indicate now in program memory space}
  end;
{
**********
*
*   T1
*
*   Send special TEST command for debugging.
}
27: begin
  if not_eos then goto err_extra;

  picprg_cmdw_test1 (pr, stat);
  end;
{
**********
*
*   X1
*
*   Special experimental command.  This command is for debugging and is
*   intended to be re-written for different circumstances.
}
28: begin
  if not_eos then goto err_extra;

  while true do begin
    picprg_cmdw_off (pr, stat);
    if sys_error(stat) then goto err_cmparm;
    picprg_cmdw_vppon (pr, stat);
    if sys_error(stat) then goto err_cmparm;
    end;

  end;
{
**********
*
*   PINS
}
29: begin
  if not_eos then goto err_extra;

  picprg_cmdw_pins (pr, pinfo, stat);
  if sys_error(stat) then goto err_cmparm;
  if picprg_pininfo_le18_k in pinfo
    then write ('<=18')
    else write ('>18');
  writeln;
  end;
{
**********
*
*   TINFO [name]
}
30: begin
  if not_eos then goto err_extra;

  picprg_tinfo (pr, tinfo, stat);
  if sys_error(stat) then goto err_cmparm;

  writeln ('Name ', tinfo.name.str:tinfo.name.len);
  show_namespace (tinfo.idspace); writeln;
  write ('ID      '); show_bin (tinfo.id, 32);
  write ('RevMask '); show_bin (tinfo.rev_mask, 32);
  writeln ('RevShift ', tinfo.rev_shft);
  writeln ('Rev ', tinfo.rev);
  write ('Family ');
  case tinfo.fam of
picprg_picfam_10f_k: writeln ('10Fxxx');
picprg_picfam_12f_k: writeln ('Generic 12 bit core');
picprg_picfam_16f_k: writeln ('Generic 16F');
picprg_picfam_12f6xx_k: writeln ('12F6xx');
picprg_picfam_16f77_k: writeln ('16F77 and related');
picprg_picfam_16f88_k: writeln ('16F88 and related');
picprg_picfam_16f61x_k: writeln ('16F61x');
picprg_picfam_16f62x_k: writeln ('16F62x');
picprg_picfam_16f62xa_k: writeln ('16F6xxA');
picprg_picfam_16f688_k: writeln ('16F688 and related');
picprg_picfam_16f716_k: writeln ('16F716 and related');
picprg_picfam_16f7x7_k: writeln ('16F7x7');
picprg_picfam_16f72x_k: writeln ('16F72x');
picprg_picfam_16f84_k: writeln ('16F84, 16F83');
picprg_picfam_16f87xa_k: writeln ('16F87xA');
picprg_picfam_16f88x_k: writeln ('16F88x');
picprg_picfam_16f182x_k: writeln ('16F182x');
picprg_picfam_18f_k: writeln ('Generic 18F');
picprg_picfam_18f2520_k: writeln ('18F2520 and related');
picprg_picfam_18f2523_k: writeln ('18F2523 and related');
picprg_picfam_18f6680_k: writeln ('18F6680 and related');
picprg_picfam_18f6310_k: writeln ('18F6310 and related');
picprg_picfam_18j_k: writeln ('18F25J10 and related');
picprg_picfam_18k80_k: writeln ('18FxxK80');
picprg_picfam_18f14k22_k: writeln ('18FxxK22');
picprg_picfam_18f14k50_k: writeln ('18FxxK50');
picprg_picfam_30f_k: writeln ('dsPIC 30F');
picprg_picfam_24h_k: writeln ('dsPIC 24H and 33F');
picprg_picfam_24f_k: writeln ('24F');
otherwise
    writeln (' ID ', ord(tinfo.fam));
    end;
  writeln ('Vdd voltage:  low =', tinfo.vdd.low:5:2,
    '  normal =', tinfo.vdd.norm:5:2,
    '  high =', tinfo.vdd.high:5:2);
  writeln ('Vpp range:', tinfo.vppmin:5:1, ' -', tinfo.vppmax:5:1, ' volts');
  writeln ('Pins ', tinfo.pins);
  writeln ('NProg ', tinfo.nprog);
  if tinfo.maskprg.maske = tinfo.maskprg.masko
    then begin                         {single mask for all words}
      write ('Prog word mask '); show_bin (tinfo.maskprg.maske, 16);
      end
    else begin                         {different masks for even/odd addresses}
      writeln ('Prog word masks');
      write ('  Even '); show_bin (tinfo.maskprg.maske, 16);
      write ('  Odd  '); show_bin (tinfo.maskprg.masko, 16);
      end
    ;
  writeln ('Write buf size ', tinfo.wbufsz);
  writeln ('NData ', tinfo.ndat);

  if tinfo.idspace = picprg_idspace_18_k then begin {PIC 18 ?}
    string_f_int_max_base (buf, tinfo.eecon1, 16, 3,
      [string_fi_leadz_k, string_fi_unsig_k], stat);
    writeln ('EECON1 at ', buf.str:buf.len, 'h');
    string_f_int_max_base (buf, tinfo.eeadr, 16, 3,
      [string_fi_leadz_k, string_fi_unsig_k], stat);
    writeln ('EEADR  at ', buf.str:buf.len, 'h');
    string_f_int_max_base (buf, tinfo.eeadrh, 16, 3,
      [string_fi_leadz_k, string_fi_unsig_k], stat);
    writeln ('EEADRH at ', buf.str:buf.len, 'h');
    string_f_int_max_base (buf, tinfo.eedata, 16, 3,
      [string_fi_leadz_k, string_fi_unsig_k], stat);
    writeln ('EEDATA at ', buf.str:buf.len, 'h');
    end;

  if tinfo.maskdat.maske = tinfo.maskdat.masko
    then begin                         {single mask for all words}
      write ('Data word mask '); show_bin (tinfo.maskdat.maske, 16);
      end
    else begin                         {different masks for even/odd addresses}
      writeln ('Data word masks');
      write ('  Even '); show_bin (tinfo.maskdat.maske, 16);
      write ('  Odd  '); show_bin (tinfo.maskdat.masko, 16);
      end
    ;
  r := tinfo.tprogp * 1000.0;          {make program space wait time in mS}
  write ('Prog write wait =', r:4:1, ' mS, Data write wait =');
  r := tinfo.tprogd * 1000.0;          {make data space wait time in mS}
  writeln (r:4:1, ' mS');
  if tinfo.ndat > 0 then begin         {this chip has data memory ?}
    string_f_int_max_base (            {make address string}
      parm, tinfo.datmap, 16, 0,
      [string_fi_leadz_k, string_fi_unsig_k],
      stat);
    writeln ('Data memory at ', parm.str:parm.len, 'h in HEX file.');
    end;
  if tinfo.nconfig <= 0
    then begin
      writeln ('No CONFIG addresses.');
      end
    else begin
      writeln (tinfo.nconfig, ' CONFIG addresses:');
      ent_p := tinfo.config_p;
      while ent_p <> nil do begin
        write ('  adr ');
        string_f_int_max_base (        {make address string}
          parm, ent_p^.adr, 16, 0,
          [string_fi_leadz_k, string_fi_unsig_k],
          stat);
        if sys_error(stat) then goto err_cmparm;
        write (parm.str:parm.len, 'h, mask ');
        show_bin (ent_p^.mask, 16);
        ent_p := ent_p^.next_p;
        end;
      end
    ;
  if tinfo.nother <= 0
    then begin
      writeln ('No OTHER addresses.');
      end
    else begin
      writeln (tinfo.nother, ' OTHER addresses:');
      ent_p := tinfo.other_p;
      while ent_p <> nil do begin
        write ('  adr ');
        string_f_int_max_base (        {make address string}
          parm, ent_p^.adr, 16, 0,
          [string_fi_leadz_k, string_fi_unsig_k],
          stat);
        if sys_error(stat) then goto err_cmparm;
        write (parm.str:parm.len, 'h, mask ');
        show_bin (ent_p^.mask, 16);
        ent_p := ent_p^.next_p;
        end;
      end
    ;
  string_f_int_max_base (              {make reset address string}
    parm, tinfo.adrres, 16, 0,
    [string_fi_leadz_k, string_fi_unsig_k],
    stat);
  if sys_error(stat) then goto err_cmparm;
  writeln ('Address after reset: ', parm.str:parm.len, 'h');
  end;
{
**********
*
*   ADR address
}
31: begin
  adr := next_int (0, 16#FFFFFF, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmdw_adr (pr, adr, stat);
  end;
{
**********
*
*   RD [address [n]]
}
32: begin
  adr := next_int (0, 16#FFFFFF, stat);
  if string_eos(stat) then begin       {no address, do single read ?}
    picprg_cmdw_read (pr, dat, stat);
    if sys_error(stat) then goto err_cmparm;
    show_bin (dat & maxmask, maxbits);
    goto done_cmd;
    end;
  if sys_error(stat) then goto err_cmparm;
  i32 := next_int (1, datarsize_k, stat);
  if string_eos(stat) then begin       {N not specified, use default ?}
    i32 := 16;
    end;
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;
{
*   Read an array of data.
}
  if datbitse <> datbitso then begin   {different size even/odd words ?}
    i := adr + i32 - 1;                {make ending address}
    adr := adr & ~1;                   {always start on even address}
    i := i ! 1;                        {always end on odd address}
    i32 := i - adr + 1;                {update total number of addresses to do}
    i32 := min(i32, datarsize_k);      {clip to size of data array}
    end;

  picprg_read (pr, adr, i32, mask_p^, datar, stat); {read the data from the target}
  if sys_error(stat) then goto err_cmparm;

  if datbitse = datbitso
    then begin                         {all words the same size}
      for i := 0 to i32-1 do begin     {once for each data word}
        string_f_int_max_base (        {make address hex string}
          parm, i + adr, 16, 6, [string_fi_leadz_k, string_fi_unsig_k], stat);
        if sys_error(stat) then return;
        write (parm.str:parm.len, 'h: ');
        show_bin (datar[i] & maxmask, maxbits);
        end;                           {back for next address}
      end
    else begin                         {words at even/odd addresses different sizes}
      for i := 0 to i32-1 by 2 do begin {once for each even/odd address pair}
        i2 := datar[i] & mask_p^.maske; {init with data from even address}
        i2 := i2 ! lshft(datar[i+1] & mask_p^.masko, datbitse); {merge in from odd}
        string_f_int_max_base (        {make address hex string}
          parm, i + adr, 16, 6, [string_fi_leadz_k, string_fi_unsig_k], stat);
        if sys_error(stat) then return;
        write (parm.str:parm.len, 'h: ');
        show_bin (i2, datbitse + datbitso);
        end;                           {back for next even/odd address pair}
      end
    ;
  end;
{
**********
*
*   WR dat
}
33: begin
  dat := next_int (-32768, 65535, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  dat := dat & 16#FFFF;
  picprg_cmdw_write (pr, dat, stat);
  end;
{
**********
*
*   CONFIG [name]
}
34: begin
  next_keyw (parm, stat);
  if string_eos(stat) then parm.len := 0;
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_config (pr, parm, stat);
  if sys_error(stat) then goto err_cmparm;

  picprg_tinfo (pr, tinfo, stat);
  if sys_error(stat) then goto err_cmparm;
  writeln ('Configured to ', tinfo.name.str:tinfo.name.len,
    ' rev ', tinfo.rev);

  twover := false;                     {init to do one verify pass at main Vdd}
  r :=                                 {closest programmer can come to min Vdd}
    max(pr.fwinfo.vddmin, max(pr.fwinfo.vddmax, pr.vdd.low));
  r2 :=                                {closest programmer can come to max Vdd}
    max(pr.fwinfo.vddmin, max(pr.fwinfo.vddmax, pr.vdd.high));
  if                                   {verify at the Vdd limits ?}
      pr.vdd.twover and                {high/low Vdd verify possible for this chip ?}
      (abs(r - pr.vdd.low) < 0.1) and  {can do low Vdd ?}
      (abs(r2 - pr.vdd.high) < 0.1)    {can do high Vdd ?}
      then begin
    twover := true;
    end;

  inspace (space_prog_k);              {indicate now in program memory space}
  end;
{
**********
*
*   ERASE
}
35: begin
  if not_eos then goto err_extra;

  picprg_erase (pr, stat);             {erase all target chip memory}
  if sys_error(stat) then goto err_cmparm;
  inspace (space_prog_k);              {indicate now in program memory space}
  end;
{
**********
*
*   WTEST adr n [NV]
}
36: begin
  adr := next_int (0, 16#FFFFFF, stat); {get starting address}
  if sys_error(stat) then goto err_cmparm;
  i32 := next_int (1, datarsize_k, stat); {get number of locations to write to}
  if sys_error(stat) then goto err_cmparm;
  i := next_choice ('NV', stat);       {get NV option if present}
  if not string_eos(stat) then begin   {didn't hit end of string ?}
    if sys_error(stat) then goto err_cmparm;
    if not_eos then goto err_extra;
    end;
  dover := i <> 1;                     {indicate whether to verify result}
{
*   Write the data to the target chip.
}
  picprg_cmdw_vddnorm (pr, stat);      {make sure Vdd is at normal level}
  if sys_error(stat) then goto err_cmparm;

  for i := 0 to i32-1 do begin         {once for each address to write to}
    datar[i] :=                        {fill in random value to write this address}
      picprg_maskit(math_rand_int16(rand), mask_p^, adr + i);
    end;

wrver:                                 {write DATAR array, I32 number of words}
  sys_timer_init (timer);              {initialize the stopwatches}
  sys_timer_init (timer2);
  sys_timer_start (timer2);            {start overall operation timer}

  sys_timer_start (timer);             {start the stopwatch}
  picprg_write (pr, adr, i32, datar, mask_p^, stat); {write the whole array}
  if sys_error(stat) then goto err_cmparm;
  sys_timer_stop (timer);              {stop the stopwatch}

  r := sys_timer_sec (timer);          {get elapsed seconds}
  r2 := r * 8192.0 / i32;              {seconds per 8K words}
  r3 := r * 1000.0 / i32;              {mS per word}
  sys_msg_parm_int (msg_parm[1], i32);
  sys_msg_parm_real (msg_parm[2], r);
  sys_msg_parm_real (msg_parm[3], r2);
  sys_msg_parm_real (msg_parm[4], r3);
  sys_message_parms ('picprg', 'write_stats', msg_parm, 4);
{
*   Verify.
}
  if dover then begin                  {verify is enabled ?}

    if twover
      then begin                       {verify at the separate Vdd limits}
        writeln ('Verifying at', tinfo.vdd.low:5:2, ' volts:');
        picprg_vddlev (pr, picprg_vdd_low_k, stat);
        if sys_error(stat) then goto err_cmparm;
        resetsp (stat);
        if sys_error(stat) then goto err_cmparm;
        verify (adr, i32, datar);

        writeln ('Verifying at', tinfo.vdd.high:5:2, ' volts:');
        picprg_vddlev (pr, picprg_vdd_high_k, stat);
        if sys_error(stat) then goto err_cmparm;
        resetsp (stat);
        if sys_error(stat) then goto err_cmparm;
        verify (adr, i32, datar);
        end
      else begin                       {verify at the single main Vdd level}
        writeln ('Verifying at', tinfo.vdd.norm:5:2, ' volts:');
        picprg_vddlev (pr, picprg_vdd_norm_k, stat);
        if sys_error(stat) then goto err_cmparm;
        resetsp (stat);
        if sys_error(stat) then goto err_cmparm;
        verify (adr, i32, datar);
        end
      ;

    sys_timer_stop (timer2);           {stop the overall operation timer}
    r := sys_timer_sec (timer2);       {get total elpased seconds}
    write ('Program + ');
    if twover
      then write ('two verify passes')
      else write ('one verify pass');
    writeln (' performed in', r:5:1, ' seconds.');

    picprg_vddlev (pr, picprg_vdd_norm_k, stat);
    if sys_error(stat) then goto err_cmparm;
    resetsp (stat);
    if sys_error(stat) then goto err_cmparm;
    end;
  end;
{
**********
*
*   TPROG ms
}
37: begin
  r := next_fp (stat);                 {get delay time in mS}
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  r := r / 1000.0;                     {convert delay time to seconds}
  picprg_cmdw_tprog (pr, r, stat);     {send the command}
  end;
{
**********
*
*   SPPROG
}
38: begin
  if not_eos then goto err_extra;

  picprg_space_set (pr, picprg_space_prog_k, stat);
  if sys_error(stat) then goto err_cmparm;
  inspace (space_prog_k);              {indicate now in program memory space}
  end;
{
**********
*
*   SPDATA
}
39: begin
  if not_eos then goto err_extra;

  picprg_space_set (pr, picprg_space_data_k, stat);
  if sys_error(stat) then goto err_cmparm;
  inspace (space_data_k);              {indicate now in program memory space}
  end;
{
**********
*
*   W adr dat ... dat
}
40: begin
  adr := next_int (0, 16#FFFFFF, stat); {get starting address}
  if sys_error(stat) then goto err_cmparm;
  i := 0;                              {init number of words to write}
  while true do begin
    datar[i] := next_int(0, 16#FFFF, stat) & 16#FFFF; {get next data value}
    if string_eos(stat) then exit;     {hit end of data bytes list ?}
    if sys_error(stat) then goto err_cmparm;
    i := i + 1;                        {count one more data byte in the array}
    end;
  if i <= 0 then goto done_cmd;        {no data bytes, nothing to do ?}

  i32 := i;                            {indicate number of entries in DATAR}
  dover := false;                      {do not verify the write}
  goto wrver;                          {go write the array}
  end;
{
**********
*
*   RESADR adr
}
41: begin
  adr := next_int (0, 16#FFFFFF, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmdw_resadr (pr, adr, stat);
  end;
{
**********
*
*   CHKCMD opc
}
42: begin
  i8 := next_int (0, 255, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmdw_chkcmd (pr, i8, b, stat);
  if sys_error(stat) then goto err_cmparm;
  write ('Command', i8:4, ': ');
  if b
    then writeln ('exists')
    else writeln ('unavailable');
  end;
{
**********
*
*   GETV
*
*   Get all the voltages that can be read from the remote unit.
}
43: begin
  if not_eos then goto err_extra;

  i := 0;                              {init number of voltages received}

  picprg_cmdw_getpwr (pr, r, stat);    {try to get internal power voltage}
  if not sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) then begin
    if sys_error(stat) then goto err_cmparm;
    i := i + 1;                        {count one more voltage received}
    writeln ('Internal Vdd =', r:7:3, ' V');
    end;

  picprg_cmdw_getvdd (pr, r, stat);    {try to get target Vdd level}
  if not sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) then begin
    if sys_error(stat) then goto err_cmparm;
    i := i + 1;                        {count one more voltage received}
    writeln ('Target Vdd   =', r:7:3, ' V');
    end;

  picprg_cmdw_getvpp (pr, r, stat);    {try to get target Vpp level}
  if not sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) then begin
    if sys_error(stat) then goto err_cmparm;
    i := i + 1;                        {count one more voltage received}
    writeln ('Target Vpp   =', r:7:3, ' V');
    end;

  if i = 0 then begin                  {no voltage available ?}
    writeln ('No voltage readback supported by this firmware.');
    end;
  end;
{
**********
*
*   LED bri1 t1 bri2 t2
*
*   Configure the display of the App LED.
}
44: begin
  i := next_int (0, 15, stat);
  if sys_error(stat) then goto err_cmparm;
  r := next_fp (stat);
  if sys_error(stat) then goto err_cmparm;
  i2 := next_int (0, 15, stat);
  if sys_error(stat) then goto err_cmparm;
  r2 := next_fp (stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmdw_appled (pr, i, r, i2, r2, stat);
  end;
{
**********
*
*   BUTT
*
*   Get the number of user button presses since power up, modulo 256.
}
45: begin
  if not_eos then goto err_extra;

  picprg_cmdw_getbutt (pr, i, stat);
  if sys_error(stat) then goto err_cmparm;
  writeln (i);
  end;
{
**********
*
*   RUN [vdd]
*
*   Let the target PIC run.  The VDD parameter sets the target Vdd voltage.
*   When VDD is omitted, the target Vdd line will be set to high impedence,
*   meaning the target system must supply power.
}
46: begin
  r := next_fp (stat);
  if string_eos(stat) then r := 0.0;
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmdw_run (pr, r, stat);
  if sys_error(stat) then goto err_cmparm;
  ntout := true;                       {indicate host timeout is disabled}
  end;
{
**********
*
*   HIGHZ
*
*   Set the target lines to high impedence to the extent possible.
}
47: begin
  if not_eos then goto err_extra;

  picprg_cmdw_highz (pr, stat);
  end;
{
**********
*
*   NTOUT
*
*   Disable the host command stream timeout until the next command.
}
48: begin
  if not_eos then goto err_extra;

  picprg_cmdw_ntout (pr, stat);
  if sys_error(stat) then goto err_cmparm;
  ntout := true;                       {indicate host timeout is disabled}
  end;
{
**********
*
*   GETCAP cap dat
}
49: begin
  i8 := next_int (0, 255, stat);
  if sys_error(stat) then goto err_cmparm;
  i2 := next_int (0, 255, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmdw_getcap (pr, picprg_pcap_k_t(i8), i2, i, stat);
  if sys_error(stat) then goto err_cmparm;
  writeln (i);
  end;
{
**********
*
*   T2
}
50: begin
  if not_eos then goto err_extra;

  for i := 0 to 15 do begin            {once for each register}
    picprg_cmdw_test2 (pr, i, i2, i3, i4, i5, stat);
    i32 := i2 ! lshft(i3, 8);
    string_f_int (parm, i);            {make W register number string}
    if parm.len = 1 then write (' ');
    write ('W', parm.str:parm.len, ': ');
    string_f_int16h (parm, i32);       {make HEX register value}
    writeln (parm.str:parm.len, ' ', i32);
    end;
  end;
{
**********
*
*   SHOWIN on/off
}
51: begin
  i := next_choice ('ON OFF', stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  if i = 1
    then begin                         {enable showing stream}
      pr.flags := pr.flags + [picprg_flag_showin_k];
      end
    else begin                         {disable showing stream}
      pr.flags := pr.flags - [picprg_flag_showin_k];
      end
    ;
  end;
{
**********
*
*   SHOWOUT on/off
}
52: begin
  i := next_choice ('ON OFF', stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  if i = 1
    then begin                         {enable showoutg stream}
      pr.flags := pr.flags + [picprg_flag_showout_k];
      end
    else begin                         {disable showoutg stream}
      pr.flags := pr.flags - [picprg_flag_showout_k];
      end
    ;
  end;
{
**********
*
*   QUIT
*
*   Disengage from target and exit the program.
}
53: begin
  if not_eos then goto err_extra;

  if pr.fwinfo.cmd[49]                 {HIGHZ command available ?}
    then begin
      picprg_cmdw_highz (pr, stat);
      end
    else begin                         {no HIGHZ command, use OFF}
      picprg_cmdw_off (pr, stat);
      end
    ;
  sys_error_print (stat, '', '', nil, 0);

  goto leave;
  end;
{
**********
*
*   VDD volts
}
54: begin
  r := next_fp (stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmdw_vdd (pr, r, stat);
  end;
{
**********
*
*   VPP volts
}
55: begin
  r := next_fp (stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmdw_vpp (pr, r, stat);
  end;
{
**********
*
*   LT
*
*   Perform a local test, meaning the logic for the test is here and not
*   in the programmer.  This command has no dedicated function, and is
*   re-written as needed.
}
56: begin

  while true do begin
    picprg_reset (pr, stat);           {reset the target chip and state}
    if sys_error(stat) then goto err_cmparm;
    end;

  end;
{
**********
*
*   NAME [newname]
*
*   Get or set the user-definable name for the particular unit.
}
57: begin
  string_token (buf, p, parm, stat);   {try to get name into PARM}
  if not string_eos(stat) then begin   {other than EOS on try to get new name token ?}
    if sys_error(stat) then goto err_cmparm; {hard error ?}
    if not_eos then goto err_extra;    {nothing more allowed on command line}
    picprg_cmdw_nameset (pr, parm, stat); {set the user name of the remote unit}
    if sys_error(stat) then goto err_cmparm;
    end;

  picprg_cmdw_nameget (pr, parm, stat); {inquire the programmer name}
  if sys_error(stat) then goto err_cmparm;
  writeln ('  "', parm.str:parm.len, '"');
  end;
{
**********
*
*   RD64
*
*   Read the 64 words starting at the current address and advance the address
*   by 64 using the READ64 command.  Note that the READ64 command is only
*   specified to return the correct data if the starting address is a multiple
*   of 64.
}
58: begin
  if not_eos then goto err_extra;
  picprg_cmdw_read64 (pr, datar, stat);
  if sys_error(stat) then goto err_cmparm;
  for i := 0 to 63 do begin            {once for each data word}
    show_bin (datar[i], 16);           {show this data word}
    end;
  end;
{
**********
*
*   CMD opc [dat ... dat] [RSP n lenb]
*
*   Send a abritrary command to the remote unit.  OPC is the 0-255 opcode byte.
*   The optional DAT bytes are passed as data to the command.
*
*   The information after the RSP keyword indicates what response is expected.
*   N is the number of fixed response bytes, and LENB is the 1-N index of one of
*   the fixed bytes that gives the number of additional bytes for variable
*   length commands.  If LENB is omitted, then exactly N bytes will be expected.
*   If the RSP clause is omitted, then 0 response bytes are expected.
}
59: begin
  i := next_int (0, 255, stat);        {get opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmd_start (pr, cmd, i, stat); {start defining command to send}
  if sys_error(stat) then goto err_cmparm;

  while true do begin                  {back here each new DAT byte}
    string_token (buf, p, opt, stat);  {get next token}
    if string_eos(stat) then exit;     {exhausted the command line ?}
    if sys_error(stat) then goto err_cmparm;
    string_upcase (opt);
    if string_equal (opt, string_v('RSP'(0))) then begin {this is RSP keyword ?}
      i1 := next_int (0, picprg_maxlen_rsp_k, stat);
      if sys_error(stat) then goto err_cmparm;
      i2 := next_int (1, i1, stat);
      if string_eos(stat) then i2 := 0;
      if sys_error(stat) then goto err_cmparm;
      picprg_cmd_expect (cmd, i1, i2);
      exit;
      end;
    string_t_int (opt, i, stat);       {convert to integer data byte value}
    if sys_error(stat) then goto err_cmparm;
    picprg_add_i8u (cmd, i);           {add this data byte to command}
    end;                               {back to get next command parameter}

  picprg_send_cmd (pr, cmd, stat);     {send the command to the remote unit}
  picprg_wait_cmd (pr, cmd, stat);     {wait for command and get response}
  if cmd.recv.nbuf <= 0 then goto done_cmd; {no response bytes ?}
  writeln (cmd.recv.nbuf, ' response bytes:');
  for i := 1 to cmd.recv.nbuf do begin {once for each response byte}
    show_bin (cmd.recv.buf[i], 8);
    end;
  end;
{
**********
*
*   P-ANA
}
60: begin
  if devtype <> devtype_360t_k then goto bad_cmd;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 240, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmd_expect (cmd, 4, 0);       {2 16 bit response values}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}
  if sys_error(stat) then goto err_cmparm;

  i1 := cmd.recv.buf[1] + lshft(cmd.recv.buf[2], 8); {Vdd current in uA}
  i2 := cmd.recv.buf[3] + lshft(cmd.recv.buf[4], 8); {RSSI from RF receiver, mV}
  r := i1 / 1000.0;
  writeln ('Vdd  =', r:7:3, ' mA');
  r := i2 / 1000.0;
  writeln ('RSSI =', r:7:3, ' V');
  end;
{
**********
*
*   P-LED onoff
}
61: begin
  if devtype <> devtype_360t_k then goto bad_cmd;
  i1 := next_choice ('OFF ON', stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 241, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_add_i8u (cmd, i1-1);          {OFF = 0, ON = 1}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}
  end;
{
**********
*
*   P-CAL
}
62: begin
  if devtype <> devtype_360t_k then goto bad_cmd;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 242, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmd_expect (cmd, 1, 1);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}

  writeln (cmd.recv.buf[1], ' calibration bytes:');
  for i := 2 to cmd.recv.nbuf do begin
    write ('  ');
    show_bin (cmd.recv.buf[i], 8);
    end;
  end;
{
**********
*
*   P-WCAL adr dat ... dat
}
63: begin
  if devtype <> devtype_360t_k then goto bad_cmd;
  i1 := next_int (0, 255, stat);
  if sys_error(stat) then goto err_cmparm;

  picprg_cmd_start (pr, cmd, 243, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_add_i8u (cmd, i1);            {starting address}
  picprg_add_i8u (cmd, 0);             {init number of data bytes}
  while true do begin                  {once for each DAT command line token}
    i2 := next_int (0, 255, stat);
    if string_eos(stat) then exit;
    if sys_error(stat) then goto err_cmparm;
    picprg_add_i8u (cmd, i2);
    cmd.send.buf[3] := cmd.send.buf[3] + 1;
    end;
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}
  end;
{
**********
*
*   P-SER
}
64: begin
  if devtype <> devtype_360t_k then goto bad_cmd;
  if not_eos then goto err_extra;

p_ser:
  picprg_cmd_start (pr, cmd, 244, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmd_expect (cmd, 13, 0);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}

  writeln ('Serial number state:');

  i :=                                 {assemble 32 bit value}
    cmd.recv.buf[2] !
    lshft(cmd.recv.buf[3], 8) !
    lshft(cmd.recv.buf[4], 16) !
    lshft(cmd.recv.buf[5], 24);
  string_f_int32h (parm, i);
  write ('  Current ', parm.str:parm.len, ' (');
  if cmd.recv.buf[1] = 1
    then write ('valid')
    else write ('invalid');
  writeln (')');

  i :=                                 {assemble 32 bit value}
    cmd.recv.buf[6] !
    lshft(cmd.recv.buf[7], 8) !
    lshft(cmd.recv.buf[8], 16) !
    lshft(cmd.recv.buf[9], 24);
  string_f_int32h (parm, i);
  writeln ('  First   ', parm.str:parm.len);

  i :=                                 {assemble 32 bit value}
    cmd.recv.buf[10] !
    lshft(cmd.recv.buf[11], 8) !
    lshft(cmd.recv.buf[12], 16) !
    lshft(cmd.recv.buf[13], 24);
  string_f_int32h (parm, i);
  writeln ('  Last    ', parm.str:parm.len);
  end;
{
**********
*
*   P-SNEXT
}
65: begin
  if devtype <> devtype_360t_k then goto bad_cmd;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 245, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}

  writeln;
  goto p_ser;                          {get and dump new serial number state}
  end;
{
**********
*
*   P-SSET start last
}
66: begin
  if devtype <> devtype_360t_k then goto bad_cmd;
  picprg_cmd_start (pr, cmd, 246, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;

  string_token (buf, p, parm, stat);
  if sys_error(stat) then goto err_cmparm;
  string_t_int32h (parm, i, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_add_i32u (cmd, i);

  string_token (buf, p, parm, stat);
  if sys_error(stat) then goto err_cmparm;
  string_t_int32h (parm, i, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_add_i32u (cmd, i);
  if not_eos then goto err_extra;

  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}

  writeln;
  goto p_ser;                          {get and dump new serial number state}
  end;
{
**********
*
*   P-SW
}
67: begin
  if devtype <> devtype_360t_k then goto bad_cmd;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 247, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmd_expect (cmd, 1, 0);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}

  write ('Switch ');
  if (cmd.recv.buf[1] & 16#80) = 0
    then write ('OPEN,  ')
    else write ('CLOSED,');
  i := cmd.recv.buf[1] & 127;
  writeln (' ', i:3, ' transitions.');
  end;
{
**********
*
*   VPPHIZ
}
68: begin
  if not_eos then goto err_extra;

  picprg_cmdw_vpphiz (pr, stat);
  end;
{
**********
*
*   T
*
*   This command is re-written as needed to perform a specific one-off test.
}
69: begin
  if not_eos then goto err_extra;

  picprg_cmdw_vppoff (pr, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_cmdw_wait (pr, 0.250, stat);
  if sys_error(stat) then goto err_cmparm;
  picprg_cmdw_vpphiz (pr, stat);
  if sys_error(stat) then goto err_cmparm;
  end;
{
**********
*
*   TESTGET
}
70: begin
  if not_eos then goto err_extra;

  picprg_cmdw_testget (pr, i, stat);
  if sys_error(stat) then goto err_cmparm;
  writeln (i);
  end;
{
**********
*
*   TESTSET mode
}
71: begin
  i := next_int (0, 255, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmdw_testset (pr, i, stat);
  end;
{
**********
*
*   P-PWR on/off
}
72: begin
  if devtype <> devtype_oc1t_k then goto bad_cmd;
  i1 := next_choice ('OFF ON', stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 240, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_add_i8u (cmd, i1-1);          {OFF = 0, ON = 1}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}
  end;
{
**********
*
*   P-T5V
}
73: begin
  if devtype <> devtype_oc1t_k then goto bad_cmd;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 241, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmd_expect (cmd, 2, 0);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}
  if sys_error(stat) then goto err_cmparm;

  i1 := cmd.recv.buf[1] + lshft(cmd.recv.buf[2], 8); {mV}
  r := i1 / 1000.0;                    {make volts}
  writeln ('Target Vdd ', r:6:3, ' V');
  end;
{
**********
*
*   P-SEG mask
}
74: begin
  if devtype <> devtype_oc1t_k then goto bad_cmd;
  i1 := next_int (0, 15, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 242, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_add_i8u (cmd, i1);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}
  end;
{
**********
*
*   P-OCC
}
75: begin
  if devtype <> devtype_oc1t_k then goto bad_cmd;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 243, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmd_expect (cmd, 1, 0);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}
  if sys_error(stat) then goto err_cmparm;

  i1 := cmd.recv.buf[1];               {get mask of occupied segments}

  write ('Segment 1 ');
  if (i1 & 1) = 0
    then write ('open')
    else write ('occupied');
  writeln;

  write ('Segment 2 ');
  if (i1 & 2) = 0
    then write ('open')
    else write ('occupied');
  writeln;

  write ('Segment 3 ');
  if (i1 & 4) = 0
    then write ('open')
    else write ('occupied');
  writeln;

  write ('Segment 4 ');
  if (i1 & 8) = 0
    then write ('open')
    else write ('occupied');
  writeln;
  end;
{
**********
*
*   P-LID
}
76: begin
  if devtype <> devtype_oc1t_k then goto bad_cmd;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 244, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmd_expect (cmd, 1, 0);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}
  if sys_error(stat) then goto err_cmparm;

  i1 := cmd.recv.buf[1];               {get lid switch transistions count}
  write ('LID ');
  if odd(i1)
    then write ('closed')
    else write ('open');
  writeln (', count ', i1);
  end;
{
**********
*
*   P-TAD
}
77: begin
  if devtype <> devtype_oc1t_k then goto bad_cmd;
  if not_eos then goto err_extra;

  picprg_cmd_start (pr, cmd, 245, stat); {start command, set opcode}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmd_expect (cmd, 10, 0);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  if sys_error(stat) then goto err_cmparm;
  picprg_wait_cmd (pr, cmd, stat);     {wait for the response}
  if sys_error(stat) then goto err_cmparm;

  i1 := cmd.recv.buf[1] + lshft(cmd.recv.buf[2], 8); {get filtered A/D values}
  i2 := cmd.recv.buf[3] + lshft(cmd.recv.buf[4], 8);
  i3 := cmd.recv.buf[5] + lshft(cmd.recv.buf[6], 8);
  i4 := cmd.recv.buf[7] + lshft(cmd.recv.buf[8], 8);
  i5 := cmd.recv.buf[9] + lshft(cmd.recv.buf[10], 8);

  r := 5.0 / (1023 * 32);              {make voltage units of the I1-I5 values}
  r1 := (i1 - i5) * r;
  r2 := (i2 - i5) * r;
  r3 := (i3 - i5) * r;
  r4 := (i4 - i5) * r;
  r5 := i5 * r;

  writeln ('Curr sense', r1:7:3, r2:7:3, r3:7:3, r4:7:3,
    ' V, Zero ref', r5:7:3, ' V');
  end;
{
**********
*
*   DATADR adr
}
78: begin
  i := next_int (0, 16#FFFFFF, stat);
  if sys_error(stat) then goto err_cmparm;
  if not_eos then goto err_extra;

  picprg_cmdw_datadr (pr, i, stat);
  end;
{
**********
*
*   PB byte ... byte
*
*   Send the bytes over the serial data port.
}
79: begin
  i1 := 0;                             {init number of data bytes}
  while true do begin                  {read the data bytes from the command line}
    i := next_int (-128, 255, stat);   {try to get another data byte}
    if string_eos(stat) then exit;     {end of command line ?}
    if sys_error(stat) then goto err_cmparm;
    if i1 >= 256 then goto err_extra;
    bytes[i1] := i;                    {save this byte in the buffer}
    i1 := i1 + 1;                      {count one more data byte}
    end;                               {back to get next data byte}
  if i1 = 0 then goto done_cmd;        {nothing to send ?}

  picprg_cmdw_sendser (pr, i1, bytes, stat); {send the bytes}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmdw_wait (pr, 0.100, stat);  {leave time to receive any response bytes}
  if sys_error(stat) then goto err_cmparm;
  picprg_cmdw_recvser (pr, i1, bytes, stat); {get waiting response bytes, if any}
  if sys_error(stat) then goto err_cmparm;
  if i1 > 0 then goto show_rsp;        {got response bytes, go show them ?}
  end;
{
**********
*
*   GB
*
*   Get whatever bytes have been received by the serial data port.
}
80: begin
  if not_eos then goto err_extra;

  picprg_cmdw_recvser (pr, i1, bytes, stat); {send command, get the result}
  if sys_error(stat) then goto err_cmparm;

show_rsp:                              {show response bytes, data in I1 and BYTES}
  write (i1, ' byte');
  if i1 <> 1 then write ('s');
  if i1 <= 0 then begin
    writeln;
    goto done_cmd;
    end;
  writeln (':');

  write (' ');
  for i := 0 to i1-1 do begin          {once for each byte}
    write (' ', bytes[i]);
    end;
  writeln;
  end;
{
**********
*
*   Unrecognized command name.
}
otherwise
    goto bad_cmd;
    end;

done_cmd:                              {done processing this command}
  if sys_error(stat) then goto err_cmparm;

  if not_eos then begin                {extraneous token after command ?}
err_extra:
    writeln ('Too many parameters for this command.');
    end;

  if ntout then goto done_waitchk;     {don't send command if host timeout disabled}
  picprg_cmdw_waitchk (pr, i8, stat);
  if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
    then goto done_waitchk;
  if sys_error(stat) then goto err_cmparm;
  if (i8 & 1) <> 0 then begin
    writeln ('Vdd still too low after maximum wait time.');
    end;
  if (i8 & 2) <> 0 then begin
    writeln ('Vdd still too high after maximum wait time.');
    end;
  if (i8 & 4) <> 0 then begin
    writeln ('Vpp still too low after maximum wait time.');
    end;
  if (i8 & 8) <> 0 then begin
    writeln ('Vpp still too high after maximum wait time.');
    end;
  if (i8 & 16#FF) <> 0 then begin      {errors flagged not handled above ?}
    string_f_int_max_base (            {make binary string from WAITCHK value}
      parm, i8, 2, 8, [string_fi_leadz_k, string_fi_unsig_k], stat);
    if sys_error(stat) then goto err_cmparm;
    writeln ('WAITCHK = ', parm.str:parm.len);
    end;
done_waitchk:

  goto loop_cmd;                       {back to process next command}

bad_cmd:                               {unrecognized or illegal command}
  writeln ('Huh?');
  goto loop_cmd;

err_cmparm:                            {parameter error, STAT set accordingly}
  sys_error_print (stat, '', '', nil, 0);
  goto loop_cmd;

leave:
  picprg_close (pr, stat);             {close the PICPRG library}
  sys_error_abort (stat, '', '', nil, 0);
  end.
