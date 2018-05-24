{   Program PIC_CTRL options
*
*   Control the individual lines of a PIC programmer.
}
program pic_ctrl;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'stuff.ins.pas';
%include 'picprg.ins.pas';

const
  max_msg_args = 2;                    {max arguments we can pass to a message}

type
  opt_k_t = (                          {command line option internal opcode}
    opt_vdd_k,                         {set Vdd to R1 volts}
    opt_vpp_k,                         {set Vpp to R1 volts}
    opt_pgc_k,                         {set PGC to I1, either 0 or 1}
    opt_pgd_k,                         {set PGD to I1, either 0 or 1}
    opt_off_k);                        {high impedence to the extent possible}

  opt_p_t = ^opt_t;
  opt_t = record                       {info about one command line option}
    next_p: opt_p_t;                   {pointer to next sequential command line option}
    i1: sys_int_machine_t;             {integer parameter}
    r1: real;                          {floating point parameter}
    opt: opt_k_t;                      {command line option ID}
    end;

var
  pr: picprg_t;                        {PICPRG library state}
  opt_first_p: opt_p_t;                {pointer to start of command line options chain}
  opt_last_p: opt_p_t;                 {pointer to last command line option in chain}
  opt_p: opt_p_t;                      {pointer to current stored command line option}
  r1: real;                            {scratch floating point parameter}
  newname:                             {new name to set in programmer}
    %include '(cog)lib/string256.ins.pas';
  set_name: boolean;                   {set new name in programmer}

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
  done_cmd, cmd_nimp, dshow_vdd, dshow_vpp;
{
******************************************************************
*
*   Subroutine OPT_ADD (OPT, I1, R1)
*
*   Add a new command line option to the end of the chain of command line options.
}
procedure opt_add (                    {add command line option to end of chain}
  in    opt: opt_k_t;                  {ID for this command line option}
  in    i1: sys_int_machine_t;         {integer parameter}
  in    r1: real);                     {floating point parameter}
  val_param; internal;

var
  opt_p: opt_p_t;                      {pointer to new option descriptor}

begin
  sys_mem_alloc (sizeof(opt_p^), opt_p); {allocate memory for new option descriptor}
  opt_p^.next_p := nil;                {init to no option following}
  opt_p^.opt := opt;                   {fill in data about this command line option}
  opt_p^.i1 := i1;
  opt_p^.r1 := r1;
  if opt_last_p = nil
    then begin                         {this is first option in the chain}
      opt_first_p := opt_p;            {init end of chain pointer}
      end
    else begin                         {there is an existing chain to link to the end of}
      opt_last_p^.next_p := opt_p;     {link this new option to the end of the chain}
      end
    ;
  opt_last_p := opt_p;                 {update end of chain pointer}
  end;
{
******************************************************************
*
*   Function NOT_IMPLEMENTED (STAT)
*
*   Returns TRUE iff STAT indicates command not implemented within the PICPRG
*   subsystem.  In that case STAT is cleared, else it is not altered.
}
function not_implemented (             {test STAT for PIC programmer command not implemented}
  in out  stat: sys_err_t)             {status to test, reset if not implemented indicated}
  :boolean;                            {TRUE if PIC programmer command not implemented}
  val_param; internal;

begin
  not_implemented := sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
  end;
{
******************************************************************
*
*   Function OP_DONE (STAT)
*
*   Check that an operation was performed and has completed without error.
*   STAT must be the status returned from the PICPRG call to perform
*   the operation.  This function returns FALSE with no error if the operation
*   is not supported by the programmer.  The program is aborted with an
*   appropriate error message is STAT indicates a hard error.
*
*   If STAT indicates no error, then this routine waits for the operation to
*   complete and checks for resulting error to the extent supported by the
*   programmer.  If an error is encountered, the program is aborted with
*   an appropriate error message.  In that case, the operation indicated
*   by OPT_P is assumed to be what was performed.  If the operation completed
*   successfully this function returns TRUE with STAT indicating no error.
}
function op_done (                     {check for operation completed properly}
  in out  stat: sys_err_t)             {resulting status from initiating the operation}
  :boolean;                            {FALSE for not implemented, TRUE for success}
  val_param; internal;

var
  flags: int8u_t;                      {flags returned by WAITCHK command}

begin
  if not_implemented (stat) then begin {operation not implemented in programmer ?}
    op_done := false;
    return;
    end;
  sys_error_abort (stat, '', '', nil, 0);
  op_done := true;                     {indicate operation completed}

  picprg_cmdw_waitchk (pr, flags, stat); {try to get status after operation done}
  if not_implemented(stat) then return; {can't get completion status from this programmer ?}

  if (flags & 2#0001) <> 0 then begin  {Vdd too low ?}
    sys_message_bomb ('picprg', 'vdd_low', 0, 0);
    end;
  if (flags & 2#0010) <> 0 then begin  {Vdd too high ?}
    sys_message_bomb ('picprg', 'vdd_high', 0, 0);
    end;
  if (flags & 2#0100) <> 0 then begin  {Vpp too low ?}
    sys_message_bomb ('picprg', 'vpp_low', 0, 0);
    end;
  if (flags & 2#1000) <> 0 then begin  {Vpp too high ?}
    sys_message_bomb ('picprg', 'vpp_high', 0, 0);
    end;
  end;
{
******************************************************************
*
*   Start of main routine.
}
begin
  string_cmline_init;                  {init for reading the command line}
{
*   Initialize our state before reading the command line options.
}
  picprg_init (pr);                    {select defaults for opening PICPRG library}
  opt_first_p := nil;                  {init chain of command line options to empty}
  opt_last_p := nil;
  set_name := false;                   {init to not set programmer name string}

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
    '-SIO -VDD -VPP -CLKH -CLKL -DATH -DATL -OFF -N -SETNAME',
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
*   -VDD volts
}
2: begin
  string_cmline_token_fpm (r1, stat);
  if sys_error(stat) then goto err_parm;
  opt_add (opt_vdd_k, 0, r1);
  end;
{
*   -VPP volts
}
3: begin
  string_cmline_token_fpm (r1, stat);
  if sys_error(stat) then goto err_parm;
  opt_add (opt_vpp_k, 0, r1);
  end;
{
*   -CLKH
}
4: begin
  opt_add (opt_pgc_k, 1, 0.0);
  end;
{
*   -CLKL
}
5: begin
  opt_add (opt_pgc_k, 0, 0.0);
  end;
{
*   -DATH
}
6: begin
  opt_add (opt_pgd_k, 1, 0.0);
  end;
{
*   -DATL
}
7: begin
  opt_add (opt_pgd_k, 0, 0.0);
  end;
{
*   -OFF
}
8: begin
  opt_add (opt_off_k, 0, 0.0);
  end;
{
*   -N name
}
9: begin
  string_cmline_token (pr.prgname, stat); {get programmer name}
  if sys_error(stat) then goto err_parm;
  end;
{
*   -SETNAME name
}
10: begin
  string_cmline_token (newname, stat);
  if sys_error(stat) then goto err_parm;
  set_name := true;
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
  picprg_open (pr, stat);              {open connection to the PIC programmer}
  sys_error_abort (stat, '', '', nil, 0);
{
*   Set the user definable name in the programmer, if this was selected.
}
  if set_name then begin               {set new name in programmer ?}
    picprg_cmdw_nameset (pr, newname, stat);
    sys_error_abort (stat, '', '', nil, 0);
    end;
{
********************
*
*   Loop thru all the stored command line options in sequence and perform each
*   action in turn.
}
  opt_p := opt_first_p;                {make first command line option current}
  while opt_p <> nil do begin          {loop thru the list of command line options}
    case opt_p^.opt of
{
*   Set Vdd to voltage R1.
}
opt_vdd_k: begin
  string_vstring (opt, '-VDD '(0), -1); {make equivalent command line option string}
  string_f_fp_fixed (parm, opt_p^.r1, 3);
  string_append (opt, parm);
  if abs(opt_p^.r1) < 0.001 then begin {0V specified ?}
    picprg_cmdw_vddoff (pr, stat);
    goto done_cmd;
    end;
  if pr.fwinfo.varvdd
    then begin                         {the programmer implements variable Vdd}
      if (opt_p^.r1 < pr.fwinfo.vddmin) or (opt_p^.r1 > pr.fwinfo.vddmax) then begin
        sys_msg_parm_real (msg_parm[1], pr.fwinfo.vddmin);
        sys_msg_parm_real (msg_parm[2], pr.fwinfo.vddmax);
        sys_message_bomb ('picprg', 'unsup_vdd', msg_parm, 2);
        end;
      if pr.fwinfo.cmd[65]
        then begin                     {VDD command is implemented}
          picprg_cmdw_vddoff (pr, stat); {make sure VDD off so new values takes effect}
          if sys_error(stat) then goto done_cmd;
          picprg_cmdw_vdd (pr, opt_p^.r1, stat);
          if sys_error(stat) then goto done_cmd;
          end
        else begin                     {no VDD command, try old VDDVALS}
          picprg_cmdw_vddvals (pr, opt_p^.r1, opt_p^.r1, opt_p^.r1, stat);
          if sys_error(stat) then goto done_cmd;
          end
        ;
      if sys_error(stat) then goto done_cmd;
      picprg_cmdw_vddnorm (pr, stat);
      end
    else begin                         {the programmer does not implement variable Vdd}
      if (opt_p^.r1 >= pr.fwinfo.vddmin) and (opt_p^.r1 <= pr.fwinfo.vddmax) then begin
        picprg_cmdw_vddnorm (pr, stat); {enable the fixed Vdd level}
        goto done_cmd;
        end;
      sys_msg_parm_real (msg_parm[1], (pr.fwinfo.vddmin + pr.fwinfo.vddmax) / 2.0);
      sys_message_bomb ('picprg', 'unsup_varvdd', msg_parm, 1);
      end
    ;
  end;
{
*   Set Vpp to voltage R1.
}
opt_vpp_k: begin
  string_vstring (opt, '-VPP '(0), -1); {make equivalent command line option string}
  string_f_fp_fixed (parm, opt_p^.r1, 3);
  string_append (opt, parm);
  if abs(opt_p^.r1) < 0.001 then begin {0V specified ?}
    picprg_cmdw_vppoff (pr, stat);
    goto done_cmd;
    end;
  if (opt_p^.r1 <= pr.fwinfo.vppmax) and (opt_p^.r1 >= pr.fwinfo.vppmin) {this Vpp OK ?}
      then begin
    if pr.fwinfo.cmd[61] then begin    {VPP command is implemented ?}
      picprg_cmdw_vppoff (pr, stat);   {make sure off so that new value takes effect}
      if sys_error(stat) then goto done_cmd;
      picprg_cmdw_vpp (pr, opt_p^.r1, stat);
      if sys_error(stat) then goto done_cmd;
      end;
    picprg_cmdw_vppon (pr, stat);
    if sys_error(stat) then goto done_cmd;
    goto done_cmd;
    end;
  sys_msg_parm_real (msg_parm[1], pr.fwinfo.vppmin);
  sys_msg_parm_real (msg_parm[2], pr.fwinfo.vppmax);
  sys_message_bomb ('picprg', 'unsup_vpp', msg_parm, 2);
  end;
{
*   Set PGC high/low according to I1.
}
opt_pgc_k: begin
  if opt_p^.i1 = 0
    then begin                         {set PGC low}
      string_vstring (opt, '-CLKL'(0), -1);
      picprg_cmdw_clkl (pr, stat);
      end
    else begin                         {set PGC high}
      string_vstring (opt, '-CLKH'(0), -1);
      picprg_cmdw_clkh (pr, stat);
      end
    ;
  end;
{
*   Set PGD high/low according to I1.
}
opt_pgd_k: begin
  if opt_p^.i1 = 0
    then begin                         {set PGD low}
      string_vstring (opt, '-DATL'(0), -1);
      picprg_cmdw_datl (pr, stat);
      end
    else begin                         {set PGD high}
      string_vstring (opt, '-DATH'(0), -1);
      picprg_cmdw_dath (pr, stat);
      end
    ;
  end;
{
*   Set all lines to high impedence to the extent possible.
}
opt_off_k: begin
  string_vstring (opt, '-OFF'(0), -1);
  picprg_cmdw_off (pr, stat);
  end;
{
*   Unexpected command line option.
}
otherwise
      sys_msg_parm_int (msg_parm[1], ord(opt_p^.opt));
      sys_message_bomb ('picprg', 'pic_ctrl_bad_opt', msg_parm, 1);
      end;

done_cmd:                              {done processing the current command}
    if not op_done (stat) then begin   {command not implemented by programmer}
cmd_nimp:                              {common code to handle unimplemented command}
      {
      *   The programmer doesn't implement a feature required to perform this
      *   operation.  OPT_P points to the operation and OPT is the string to
      *   request the operation from the user's point of view.
      }
      sys_msg_parm_vstr (msg_parm[1], opt);
      sys_message_bomb ('picprg', 'pic_ctrl_unimpl', msg_parm, 1);
      end;

    opt_p := opt_p^.next_p;            {advance to next operation in the list}
    end;                               {back to perform this new operation}
{
*   Done with all the operations specifically requested by the user.
*
********************
*
*   Read back the state of the signals to the extent possible and report their values
*   on standard output.
}

{
*   Show the programmer name if available.
}
  picprg_cmdw_nameget (pr, parm, stat); {try to get user settable programmer name}
  if not not_implemented(stat) then begin {either got name or hard error ?}
    sys_error_abort (stat, '', '', nil, 0); {abort on hard error}
    writeln ('Name = "', parm.str:parm.len, '"');
    end;
{
*   Show Vdd voltage.
}
  picprg_cmdw_getvdd (pr, r1, stat);   {try to get Vdd voltage}
  if not sys_error(stat) then begin
    writeln ('Vdd =', r1:7:3);
    goto dshow_vdd;
    end;
  discard( not_implemented(stat) );    {clear command not implemented error, if any}
  sys_error_abort (stat, '', '', nil, 0);
dshow_vdd:
{
*   Show Vpp voltage.
}
  picprg_cmdw_getvpp (pr, r1, stat);   {try to get vpp voltage}
  if not sys_error(stat) then begin
    writeln ('Vpp =', r1:7:3);
    goto dshow_vpp;
    end;
  discard( not_implemented(stat) );    {clear command not implemented error, if any}
  sys_error_abort (stat, '', '', nil, 0);
dshow_vpp:
{
*   Disable the command stream timeout so that the current state will persist
*   until explicitly changed.
}
  picprg_cmdw_ntout (pr, stat);        {try to disable the command stream timeout}
  discard( not_implemented(stat) );    {silently skip it if this is not implemented}
{
*   Reboot the control processor if the name was changed.  This is cached
*   in the operating system in some cases.  For example if the programmer
*   is plugged into the USB, the old name will stay cached in the driver and
*   programs using the new name will be unable to open it.  Rebooting the
*   control processor is the same as unplugging the replugging the device,
*   which forces the driver to assume it is a different device and not
*   keep any cached data.
*
*   This is the last thing this program does, since this could break the I/O
*   connection depending on how the programmer is connected.
}
  if set_name then begin               {new name was set in programmer ?}
    picprg_cmdw_reboot (pr, stat);     {attempt to reboot, ignore errors}
    end;

  picprg_close (pr, stat);             {disconnect from the programmer}
  end.
