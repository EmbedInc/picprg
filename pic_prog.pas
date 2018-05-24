{   Program PIC_PROG [options]
*
*   Program data into a PIC microcontroller using the PICPRG PIC programmer.
}
program pic_prog;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'stuff.ins.pas';
%include 'picprg.ins.pas';

const
  dblclick = 0.300;                    {max time for button double click, seconds}
  max_msg_args = 2;                    {max arguments we can pass to a message}

var
  fnam_in:                             {HEX input file name}
    %include '(cog)lib/string_treename.ins.pas';
  iname_set: boolean;                  {TRUE if the input file name already set}
  erase: boolean;                      {erase target only, don't program}
  verify: boolean;                     {verify only, don't program}
  run: boolean;                        {-RUN command line option issued}
  bend: boolean;                       {-BEND command line option}
  wait: boolean;                       {-WAIT command line option}
  loop: boolean;                       {-LOOP command line option}
  quit: boolean;                       {deliberately exiting program, but no error}
  noprog: boolean;                     {don't program the chip}
  vdd1: boolean;                       {single Vdd level specified on command line}
  vdd1lev: real;                       {the Vdd level specified on the command line}
  runvdd: real;                        {Vdd volts for -RUN}
  ntarg: sys_int_machine_t;            {number of targets operated on}
  name:                                {PIC name selected by user}
    %include '(cog)lib/string32.ins.pas';
  pr: picprg_t;                        {PICPRG library state}
  tinfo: picprg_tinfo_t;               {configuration info about the target chip}
  ihn: ihex_in_t;                      {HEX file reading state}
  d18: boolean;                        {-D18 command line option was given}
  noverify: boolean;                   {perform no verify passes}
  vhonly: boolean;                     {verify addresses in HEX file only}
  ii, jj: sys_int_machine_t;           {scratch integers and loop counters}
  r: real;                             {scratch floating point value}
  timer: sys_timer_t;                  {stopwatch timer}
  clock1: sys_clock_t;                 {scratch system clock value}
  tdat_p: picprg_tdat_p_t;             {pointer to target data info}
  verflags: picprg_verflags_t;         {set of option flags for verification}
  progflags: picprg_progflags_t;       {set of options flags for programming}

  opts:                                {all command line options separate by spaces}
    %include '(cog)lib/string256.ins.pas';
  opt:                                 {upcased command line option}
    %include '(cog)lib/string_treename.ins.pas';
  parm:                                {command line option parameter}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_opt, done_opt, err_parm, err_conflict, parm_bad, done_opts,
  loop_loop, done_wait,
  leave, abort, abort2, leave_all;

begin
  sys_timer_init (timer);              {initialize the stopwatch}
  sys_timer_start (timer);             {start the stopwatch}

  string_cmline_init;                  {init for reading the command line}
  string_append_token (opts, string_v('-HEX')); {1}
  string_append_token (opts, string_v('-SIO')); {2}
  string_append_token (opts, string_v('-PIC')); {3}
  string_append_token (opts, string_v('-ERASE')); {4}
  string_append_token (opts, string_v('-V')); {5}
  string_append_token (opts, string_v('-RUN')); {6}
  string_append_token (opts, string_v('-WAIT')); {7}
  string_append_token (opts, string_v('-LOOP')); {8}
  string_append_token (opts, string_v('-BEND')); {9}
  string_append_token (opts, string_v('-NPROG')); {10}
  string_append_token (opts, string_v('-D18')); {11}
  string_append_token (opts, string_v('-VDD')); {12}
  string_append_token (opts, string_v('-N')); {13}
  string_append_token (opts, string_v('-NOVERIFY')); {14}
  string_append_token (opts, string_v('-QV')); {15}
  string_append_token (opts, string_v('-LVP')); {16}
{
*   Initialize our state before reading the command line options.
}
  picprg_init (pr);                    {select defaults for opening PICPRG library}
  iname_set := false;                  {no input file name specified}
  erase := false;                      {init to not just erase target}
  verify := false;                     {init to not just verify}
  run := false;                        {init to no -RUN command line option}
  wait := false;                       {init to no -WAIT command line option}
  loop := false;                       {init to no -LOOP command line option}
  noprog := false;                     {init to no -NPROG command line option}
  runvdd := 0.0;
  d18 := false;                        {init to not double PIC 18 EEPROM offsets}
  quit := false;
  ntarg := 0;                          {init number of target systems operated on}
  vdd1 := false;                       {no single Vdd level specified}
  noverify := false;                   {init to verify the programmed memory}
  vhonly := false;                     {init to verify all memory not just HEX file adr}

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
    if erase then goto err_conflict;   {can't have file name with -ERASE}
    if not iname_set then begin        {input file name not set yet ?}
      string_copy (opt, fnam_in);      {set input file name}
      iname_set := true;               {input file name is now set}
      goto next_opt;
      end;
    goto err_conflict;
    end;
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick (opt, opts, pick);     {pick command line option name from list}
  case pick of                         {do routine for specific option}
{
*   -HEX filename
}
1: begin
  if iname_set then goto err_conflict; {input file name already set ?}
  if erase then goto err_conflict;     {can't have file name with -ERASE}
  string_cmline_token (fnam_in, stat);
  iname_set := true;
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
*   -ERASE
}
4: begin
  if iname_set then goto err_conflict; {can't have ERASE with input file name}
  erase := true;
  noprog := true;
  end;
{
*   -V
}
5: begin
  verify := true;
  end;
{
*   -RUN vdd
}
6: begin
  string_cmline_token_fpm (runvdd, stat); {get Vdd voltage to run at}
  if sys_error(stat) then goto err_parm;
  if (runvdd < 0.0) or (runvdd > 6.0) then begin {Vdd level out of range ?}
    sys_message_bomb ('picprg', 'vdd_outofrange', nil, 0);
    end;
  runvdd := max(runvdd, 0.024);        {minimum level instead of zero special case}
  run := true;
  bend := bend or loop;
  end;
{
*   -WAIT
}
7: begin
  wait := true;
  end;
{
*   -LOOP
}
8: begin
  loop := true;
  wait := true;
  bend := bend or run;
  end;
{
*   -BEND
}
9: begin
  bend := true;
  end;
{
*   -NPROG
}
10: begin
  noprog := true;
  end;
{
*   -D18
}
11: begin
  d18 := true;
  end;
{
*   -VDD v
}
12: begin
  string_cmline_token_fpm (vdd1lev, stat); {get Vdd level to operate at}
  if sys_error(stat) then goto err_parm;
  vdd1 := true;                        {indicate to use single Vdd level}
  end;
{
*   -N name
}
13: begin
  string_cmline_token (pr.prgname, stat); {get programmer name}
  if sys_error(stat) then goto err_parm;
  end;
{
*   -NOVERIFY
}
14: begin
  noverify := true;
  end;
{
*   -QV
}
15: begin
  vhonly := true;
  end;
{
*   -LVP
}
16: begin
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
(*
  pr.flags := pr.flags + [picprg_flag_showin_k, picprg_flag_showout_k];
*)

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
*   Verify that all requested command line options are supported by this
*   programmer and firmware.
}
  if vdd1 then begin                   {fixed Vdd level specified ?}
    if (vdd1lev < pr.fwinfo.vddmin) or (vdd1lev > pr.fwinfo.vddmax) then begin
      sys_msg_parm_real (msg_parm[1], pr.fwinfo.vddmin);
      sys_msg_parm_real (msg_parm[2], pr.fwinfo.vddmax);
      sys_message_bomb ('picprg', 'unsup_vdd', msg_parm, 2);
      end;
    end;

  if run then begin                    {-RUN specified ?}
    if not pr.fwinfo.cmd[48] then begin {RUN command not available ?}
      sys_message_bomb ('picprg', 'unsup_run', nil, 0);
      end;
    if (runvdd < pr.fwinfo.vddmin) or (runvdd > pr.fwinfo.vddmax) then begin
      sys_msg_parm_real (msg_parm[1], pr.fwinfo.vddmin);
      sys_msg_parm_real (msg_parm[2], pr.fwinfo.vddmax);
      sys_message_bomb ('picprg', 'unsup_vdd', msg_parm, 2);
      end;
    end;

  if wait then begin                   {-WAIT specified ?}
    if
        (not pr.fwinfo.cmd[47]) or     {APPLED command not available ?}
        (not pr.fwinfo.cmd[46])        {GETBUTT command not available ?}
        then begin
      sys_message_bomb ('picprg', 'unsup_wait', nil, 0);
      end;
    end;

  if bend then begin                   {-BEND specified ?}
    if (not pr.fwinfo.cmd[46]) then begin {GETBUTT command not available ?}
      sys_message_bomb ('picprg', 'unsup_bend', nil, 0);
      end;
    end;
{
*   Wait for user confirmation if -WAIT specified on the command line.
}
loop_loop:                             {loop back to here on -LOOP}
  if not wait then goto done_wait;     {-WAIT not specified ?}
  sys_timer_init (timer);              {reset the stopwatch}

  picprg_cmdw_getbutt (pr, ii, stat);  {get current number of button presses}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;
  picprg_cmdw_appled (pr, 15, 1.0, 15, 1.0, stat); {light App LED brightly}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  repeat                               {back here until button is pressed}
    picprg_cmdw_getbutt (pr, jj, stat); {check number of button presses again}
    clock1 := sys_clock;               {save time right at this button result}
    if sys_error_check (stat, '', '', nil, 0) then goto abort;
    jj := (jj - ii) & 255;             {make number of new button presses}
    until jj <> 0;                     {back if button not pressed}
  picprg_cmdw_appled (pr, 0, 1.0, 0, 1.0, stat); {turn off App LED to confirm}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  if loop then begin
    writeln;                           {blank line to separate from previous target}
    end;

  repeat                               {loop short time looking for double click}
    picprg_cmdw_getbutt (pr, jj, stat); {check number of button presses again}
    if sys_error_check (stat, '', '', nil, 0) then goto abort;
    jj := (jj - ii) & 255;             {make number of new button presses}
    if jj <> 1 then begin              {found double click ?}
      quit := true;                    {indicate exiting program but no error}
      goto abort;
      end;
    r := sys_clock_to_fp2 (            {make seconds since first button press}
      sys_clock_sub (sys_clock, clock1));
    until r >= dblclick;               {back until double click time expired}

  sys_timer_start (timer);             {start the stopwatch for this target}

done_wait:                             {done waiting for user confirmation}
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

  if not (                             {nothing more to do ?}
      erase or                         {erase the chip ?}
      iname_set)                       {program the chip ?}
    then goto leave;

  picprg_tdat_alloc (pr, tdat_p, stat); {allocate and init target data}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  if vdd1 then begin                   {operate at a single Vdd level ?}
    picprg_tdat_vdd1 (tdat_p^, vdd1lev);
    end;
{
*   Erase the chip if -ERASE was specified.
}
  if erase then begin                  {erase the chip ?}
    picprg_tdat_vddlev (tdat_p^, picprg_vdd_norm_k, r, stat);
    sys_message ('picprg', 'erasing');
    picprg_erase (pr, stat);           {erase the target chip}
    if sys_error_check (stat, '', '', nil, 0) then goto abort;
    goto leave;
    end;
{
*   Read the HEX file data and save it.
}
  if d18 then begin                    {EEPROM addresses are doubled in HEX file}
    tdat_p^.eedouble := true;
    end;

  ihex_in_open_fnam (fnam_in, '.hex .HEX'(0), ihn, stat); {open the HEX input file}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;
  string_copy (ihn.conn_p^.tnam, fnam_in); {save full treename of HEX file}

  picprg_tdat_hex_read (tdat_p^, ihn, stat); {read HEX file and save target data}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  ihex_in_close (ihn, stat);           {close the HEX file}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  if ihn.ndat = 0 then begin           {no data bytes in the HEX file ?}
    sys_msg_parm_vstr (msg_parm[1], fnam_in);
    sys_message_bomb ('picprg', 'hex_nodat', msg_parm, 1);
    end;
{
*   Verify and don't write to the target if -V was specified.
}
  if noprog then goto leave;           {not supposed to program or verify the chip ?}

  if verify then begin                 {verify only without writing to target ?}
    verflags := [                      {set fixed verify options}
      picprg_verflag_stdout_k,         {show progress on standard output}
      picprg_verflag_prog_k,           {verify program memory}
      picprg_verflag_data_k,           {verify data EEPROM}
      picprg_verflag_other_k,          {verify "other" locations}
      picprg_verflag_config_k];        {verify config words}
    if vhonly then begin
      verflags := verflags + [picprg_verflag_hex_k]; {verify only data in HEX file}
      end;
    if not picprg_tdat_verify (tdat_p^, verflags, stat) then begin {verify failed ?}
      sys_error_print (stat, '', '', nil, 0);
      goto abort;
      end;
    goto leave;
    end;                               {end of verify only case}
{
*   Perform the programming operation.
}
  progflags := [picprg_progflag_stdout_k]; {init to fixed options}
  if noverify then begin               {no verify at all ?}
    progflags := progflags + [picprg_progflag_nover_k];
    end;
  if vhonly then begin                 {verify only locations specified in HEX file ?}
    progflags := progflags + [picprg_progflag_verhex_k];
    end;
  picprg_tdat_prog (tdat_p^, progflags, stat); {program the target}
  if sys_error_check (stat, '', '', nil, 0) then goto abort;
{
*   Common point for exiting the program with the PICPRG library open
*   and no error.
}
leave:                                 {clean up and close connection to this target}
  ntarg := ntarg + 1;                  {count one more target system operated on}
  picprg_cmdw_appled (pr, 0, 1.0, 0, 1.0, stat); {make sure App LED, if any, is off}
  discard( sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) );
  if sys_error_check (stat, '', '', nil, 0) then goto abort;

  if run
    then begin                         {run the target at specified Vdd level}
      picprg_cmdw_run (pr, runvdd, stat); {set up to power and run the target}
      if sys_error_check (stat, '', '', nil, 0) then goto abort;
      end
    else begin                         {do not try to run the target}
      picprg_off (pr, stat);           {disengage from the target system}
      if sys_error_check (stat, '', '', nil, 0) then goto abort2;
      end
    ;

  sys_timer_stop (timer);              {stop the stopwatch}
  r := sys_timer_sec (timer);          {get total elapsed seconds}
  sys_msg_parm_real (msg_parm[1], r);
  sys_message_parms ('picprg', 'no_errors', msg_parm, 1);

  if bend then begin                   {wait until user button pressed ?}
    picprg_cmdw_getbutt (pr, ii, stat); {get current number of button presses}
    if sys_error_check (stat, '', '', nil, 0) then goto abort;
    repeat                             {wait until button pressed}
      picprg_cmdw_getbutt (pr, jj, stat); {check number of button presses again}
      if sys_error_check (stat, '', '', nil, 0) then goto abort;
      jj := (jj - ii) & 255;           {make number of new button presses}
      until jj <> 0;                   {back if button not pressed}
    picprg_off (pr, stat);             {disengage from the target system}
    if sys_error_check (stat, '', '', nil, 0) then goto abort2;
    end;

  if loop then goto loop_loop;         {back to do another target ?}

  picprg_close (pr, stat);             {close the PICPRG library}
  sys_error_abort (stat, 'picprg', 'close', nil, 0);
  goto leave_all;
{
*   Exit point with the PICPRG library open.  QUIT set indicates that
*   the program is being aborted deliberately and that should not be
*   considered an error.
*
*   If jumping here due to error, then the error message must already have been
*   written.
}
abort:
  picprg_off (pr, stat);               {disengage from the target system}
  sys_error_abort (stat, '', '', nil, 0);
{
*   Programmer has already disengaged from the target to the exent possible.
}
abort2:
  picprg_close (pr, stat);             {close the PICPRG library}
  sys_error_abort (stat, 'picprg', 'close', nil, 0);
  if not quit then begin               {aborting program on error ?}
    sys_bomb;                          {exit the program with error status}
    end;

  if loop then begin                   {could have done multiple target systems ?}
    sys_msg_parm_int (msg_parm[1], ntarg);
    sys_message_parms ('picprg', 'num_targets', msg_parm, 1);
    end;

leave_all:
  end.
