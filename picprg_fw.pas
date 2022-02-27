{   Routines that deal with the programmer firwmare version and other
*   information about the firmware.
}
module picprg_fw;
define picprg_fwinfo;
define picprg_fw_show1;
define picprg_fw_check;
%include 'picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_FWINFO (PR, FWINFO, STAT)
*
*   Determine the firmware information and related parameters.  FWINFO will be
*   completely filled in if STAT indicates no error.  All previous values in
*   FWINFO will be lost.
}
procedure picprg_fwinfo (              {get all info about programmer firmware}
  in out  pr: picprg_t;                {state for this use of the library}
  out     fwinfo: picprg_fw_t;         {returned information about programmer FW}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  vppdef_k = 13.0;                     {default fixed Vpp, volts}
  vppres_k = 20.0 / 255.0;             {Vpp resolution, volts}
  vddres_k = 6.0 / 255.0;              {Vdd resolution, volts}
{
*   Derived constants.
}
  vpperr_k = vppres_k / 2.0;           {error in describing Vpp level, volts}
  ivppdef_k = trunc((vppdef_k / vppres_k) + 0.5); {byte value for default Vpp}
  vppidef_k = ivppdef_k * vppres_k;    {Vpp volts from default byte value}
  vppdefmin_k = vppidef_k - vpperr_k;  {minimum default programmer Vpp}
  vppdefmax_k = vppidef_k + vpperr_k;  {maximum default programmer Vpp}

var
  i, j: sys_int_machine_t;             {scratch integer and loop counter}
  dat: sys_int_machine_t;              {scratch data value}
  cmd: picprg_cmd_t;                   {single command descriptor}
  ovl: picprg_cmdovl_t;                {overlapped commands control state}
  out_p: picprg_cmd_p_t;               {pointer to command descriptor for output}
  in_p: picprg_cmd_p_t;                {pointer to command descriptor for input}
  s: integer32;                        {integer value of 32 element set}
  b: boolean;                          {scratch TRUE/FALSE}
  oldf: picprg_flags_t;                {saved global flags}
  subsys: string_var80_t;              {subsystem name to find message file}
  msg: string_var80_t;                 {name of message within message file}
  tk: string_var80_t;                  {scratch token string}

label
  spec2, spec5, loop_chkcmd, have_cmds, gc0done;

begin
  subsys.max := size_char(subsys.str); {init local var strings}
  msg.max := size_char(msg.str);
  tk.max := size_char(tk.str);
  picprg_cmdovl_init (ovl);            {init overlapped commands state}

  picprg_cmdw_fwinfo (                 {send FWINFO command and get response}
    pr,                                {state for this use of the library}
    fwinfo.org,                        {organization ID}
    fwinfo.cvlo,                       {lowest protocol spec compatible with}
    fwinfo.cvhi,                       {highest protocol spec compatible with}
    fwinfo.vers,                       {firmware version number}
    fwinfo.info,                       {arbitrary 32 bit info value from firmware}
    stat);
  if sys_error(stat) then return;
{
*   Init all remaining fields to default values.
}
  fwinfo.id := 0;                      {firmware type ID}
  fwinfo.idname.max := size_char(fwinfo.idname.str);
  fwinfo.idreset := [
    picprg_reset_none_k,
    picprg_reset_62x_k,
    picprg_reset_18f_k,
    picprg_reset_dpna_k];
  fwinfo.idwrite := [
    picprg_write_none_k,
    picprg_write_16f_k,
    picprg_write_12f6_k,
    picprg_write_core12_k];
  fwinfo.idread := [
    picprg_read_none_k,
    picprg_read_16f_k,
    picprg_read_18f_k,
    picprg_read_core12_k];
  fwinfo.varvdd := true;
  fwinfo.vddmin := 0.0;
  fwinfo.vddmax := 6.0;
  fwinfo.vppmin := vppdefmin_k;
  fwinfo.vppmax := vppdefmax_k;
  fwinfo.ticksec := 200.0e-6;          {default tick is 200uS}
  fwinfo.ftickf := 0.0;                {init to fast ticks not used}
{
*   Determine which commands are available.  All old firmware reports a maximum
*   version of 1-4 and implements commands 1-38.  Newer firmware with a maximum
*   spec version of 5 or more implements the CHKCMD command which is used to
*   determine the availability of individual commands.
}
  if fwinfo.cvhi >= 9 then goto spec5; {definitely spec version 5 or later ?}
  if fwinfo.cvhi <= 4 then goto spec2; {definitely spec version 2 ?}
  {
  *   The reported firmware version is 5-8.  This should indicate spec version 5
  *   or later, but unfortunately some EasyProg special releases for Radianse
  *   also report a version in this range although they only comply with spec
  *   version 2.  If this is a ProProg or any other unit, it must be at spec
  *   version 5 or later, but we don't know that yet.  The existance of the
  *   CHKCMD command (41) is tested, since this was first introduced in spec
  *   version 5.  The CHKCMD command is assumed to be not present if it does
  *   not respond within a short time.  Since the remote unit shouldn't be doing
  *   anything right now, it should respond to the CHKCMD command in well under
  *   1 millisecond.
  }
  fwinfo.cmd[41] := true;              {temporarily indicate CHKCMD command exists}
  picprg_cmd_chkcmd (pr, cmd, 41, stat); {send CHKCMD CHKCMD command}
  if sys_error(stat) then return;
  oldf := pr.flags;                    {save snapshot of current flags}
  pr.flags := pr.flags - [picprg_flag_nintout_k]; {make sure command timeout enabled}
  picprg_wait_cmd_tout (pr, cmd, 0.100, stat); {wait for command or short timeout}
  if picprg_flag_nintout_k in oldf then begin {timeout was disabled ?}
    pr.flags := pr.flags + [picprg_flag_nintout_k]; {restore timeout flag}
    end;
  if not sys_error(stat) then goto spec5; {CHKCMD responded, spec rev >= 5 ?}
  if not sys_stat_match (picprg_subsys_k, picprg_stat_nresp_k, stat)
    then return;
  fwinfo.cvhi := 2;                    {indicate real spec version}
  fwinfo.cvlo := min(fwinfo.cvlo, fwinfo.cvhi); {make sure lowest doesn't exceed highest ver}
  {
  *   This firmware conforms to a spec version before 5.
  }
spec2:
  for i := 0 to 255 do begin
    fwinfo.cmd[i] := (i >= 1) and (i <= 38);
    end;
  goto have_cmds;                      {done determining list of implemented commands}
  {
  *   This firmware conforms to spec version 5 or higher.
  }
spec5:
  fwinfo.cmd[41] := true;              {indicate CHKCMD command is available}

  i := 0;                              {init opcode to check with next CHKCMD command}
  j := 0;                              {init opcode checked by next CHKCMD response}
loop_chkcmd:                           {back here to handle next CHKCMD cmd and/or resp}
  if i <= 255 then begin               {at least one more command to send ?}
    picprg_cmdovl_out (pr, ovl, out_p, stat); {try to get free command descriptor}
    if sys_error(stat) then return;
    if out_p <> nil then begin         {got a command descriptor ?}
      picprg_cmd_chkcmd (pr, out_p^, i, stat); {send the command to check opcode I}
      if sys_error(stat) then return;
      i := i + 1;                      {make opcode to check with next command}
      goto loop_chkcmd;                {back to send next request if possible}
      end;
    end;
  picprg_cmdovl_in (pr, ovl, in_p, stat); {get next command waiting for input}
  if sys_error(stat) then return;
  picprg_rsp_chkcmd (pr, in_p^, fwinfo.cmd[j], stat); {get this CHKCMD response}
  if sys_error(stat) then return;
  j := j + 1;                          {make opcode checked by next CHKCMD response}
  if j <= 255 then goto loop_chkcmd;   {back for next CHKCMD command and/or response}

have_cmds:                             {done filling in FWINFO.CMD}
{
*   Get the real firmware type ID if the FWINFO2 command is supported.  The
*   IDNAME string will also be updated accordingly.  IDNAME will be the
*   name supplied in the message file PICPRG_ORGxx.MSG where XX is the
*   decimal organization ID name.  The name is the expansion of the message
*   IDNAMExx where XX is the decimal firmware ID name.
}
  if fwinfo.cmd[39] then begin         {FWINFO2 command is available ?}
    picprg_cmdw_fwinfo2 (pr, fwinfo.id, stat); {send FWINFO2 command}
    if sys_error(stat) then return;
    end;

  string_vstring (subsys, 'picprg_org'(0), -1); {init subsystem name}
  string_f_int (tk, ord(fwinfo.org));  {make decimal organization ID string}
  string_append (subsys, tk);          {make complete subsystem name}

  string_vstring (msg, 'idname'(0), -1); {init message name}
  string_f_int (tk, fwinfo.id);        {make decimal firmware type ID}
  string_append (msg, tk);             {make complete message name}

  if not string_f_messaget (           {unable to find fimware type name message ?}
      fwinfo.idname,                   {returned message expansion string}
      subsys,                          {generic message file name}
      msg,                             {name of message within message file}
      nil, 0)                          {parameters passed to the message}
      then begin
    string_f_int (fwinfo.idname, fwinfo.id); {default name to decimal ID}
    end;
{
*   Indicate variable Vdd is not available if the appropriate commands are
*   not available.
}
  fwinfo.varvdd :=                     {indicate variable Vdd only if commands avail}
    ( fwinfo.cmd[16] and               {VDDVALS available ?}
      fwinfo.cmd[17] and               {VDDLOW available ?}
      fwinfo.cmd[19])                  {VDDHIGH available ?}
    or fwinfo.cmd[65];                 {VDD available ?}
{
*   Get the programmer clock tick time if the GETTICK commnd is available.
}
  if fwinfo.cmd[64] then begin         {GETTICK command available ?}
    picprg_cmdw_gettick (pr, fwinfo.ticksec, stat); {get clock tick period}
    if sys_error(stat) then return;
    end;
{
*   Get the fast clock tick period if this programmer supports fast clock ticks.
}
  if fwinfo.cmd[84] then begin         {FTICKF command available ?}
    picprg_cmdw_ftickf (pr, fwinfo.ftickf, stat); {get fast tick frequency}
    if sys_error(stat) then return;
    end;
{
*   Get information on specific optional capabilities.  FWINFO has already
*   been set to default values.  These may be modified due to specific responses
*   from the GETCAP command, if present.
}
  if fwinfo.cmd[51] then begin         {GETCAP command available ?}
    picprg_cmdw_getcap (pr, picprg_pcap_varvdd_k, 0, i, stat); {variable Vdd ?}
    if sys_error(stat) then return;
    case i of
0:    begin                            {0-6 volts variable Vdd is implemented}
        fwinfo.varvdd := true;
        fwinfo.vddmin := 0.0;
        fwinfo.vddmax := 6.0;
        end;
1:    begin                            {programmer implements a fixed Vdd}
        fwinfo.varvdd := false;
        picprg_cmdw_getcap (pr, picprg_pcap_varvdd_k, 1, i, stat); {get fixed Vdd level}
        if sys_error(stat) then return;
        if i = 0
          then begin                   {default, reporting fixed Vdd not implemented}
            fwinfo.vddmin := 5.0 - vddres_k/2.0; {fixed Vdd is 5 volts}
            fwinfo.vddmax := 5.0 + vddres_k/2.0;
            end
          else begin                   {fixed Vdd returned}
            fwinfo.vddmin := (i - 0.5) * vddres_k;
            fwinfo.vddmax := (i + 0.5) * vddres_k;
            end
          ;
        end;
otherwise
      if                               {work around bug in LProg fiwmare before LPRG 8}
          (fwinfo.org = picprg_org_official_k) and {Embed Inc firmware ?}
          (fwinfo.id = 3) and          {firmware type is LPRG ?}
          (fwinfo.vers < 8)            {a version before GETCAP 0 0 bug fixed ?}
          then begin
        fwinfo.varvdd := false;
        fwinfo.vddmin := (140 - 0.5) * vddres_k;
        fwinfo.vddmax := (140 + 0.5) * vddres_k;
        goto gc0done;
        end;
      sys_stat_set (picprg_subsys_k, picprg_stat_getcap_bad_k, stat);
      sys_stat_parm_int (ord(picprg_pcap_varvdd_k), stat); {GETCAP parameter 1}
      sys_stat_parm_int (0, stat);     {GETCAP parameter 2}
      sys_stat_parm_int (i, stat);     {GETCAP response}
      return;
      end;
gc0done:                               {done with GETCAP 0 inquiries}

    s := 0;                            {init all IDs to unimplemented}
    for dat := 0 to 31 do begin        {once for each possible set element}
      picprg_cmdw_getcap (pr, picprg_pcap_reset_k, dat, i, stat);
      if sys_error(stat) then return;
      if dat <= 3                      {set B if this algorithm implemented}
        then b := (i = 0)              {IDs 0-3 default implemented}
        else b := (i <> 0);            {IDs >3 default unimplemented}
      if b then s := s ! lshft(1, dat); {set bit if this ID implemented}
      end;                             {back for next ID}
    fwinfo.idreset := picprg_reset_t(s); {update official set of implemented IDs}

    s := 0;                            {init all IDs to unimplemented}
    for dat := 0 to 31 do begin        {once for each possible set element}
      picprg_cmdw_getcap (pr, picprg_pcap_write_k, dat, i, stat);
      if sys_error(stat) then return;
      if dat <= 3                      {set B if this algorithm implemented}
        then b := (i = 0)              {IDs 0-3 default implemented}
        else b := (i <> 0);            {IDs >3 default unimplemented}
      if b then s := s ! lshft(1, dat); {set bit if this ID implemented}
      end;                             {back for next ID}
    fwinfo.idwrite := picprg_write_t(s); {update official set of implemented IDs}

    s := 0;                            {init all IDs to unimplemented}
    for dat := 0 to 31 do begin        {once for each possible set element}
      picprg_cmdw_getcap (pr, picprg_pcap_read_k, dat, i, stat);
      if sys_error(stat) then return;
      if dat <= 3                      {set B if this algorithm implemented}
        then b := (i = 0)              {IDs 0-3 default implemented}
        else b := (i <> 0);            {IDs >3 default unimplemented}
      if b then s := s ! lshft(1, dat); {set bit if this ID implemented}
      end;                             {back for next ID}
    fwinfo.idread := picprg_read_t(s); {update official set of implemented IDs}

    picprg_cmdw_getcap (pr, picprg_pcap_vpp_k, 0, i, stat); {ask about min Vpp}
    if sys_error(stat) then return;
    picprg_cmdw_getcap (pr, picprg_pcap_vpp_k, 1, j, stat); {ask about max Vpp}
    if sys_error(stat) then return;
    if (i <> 0) and (j <> 0) then begin {Vpp range is specified ?}
      fwinfo.vppmin := max(0.0, i * vppres_k - vpperr_k); {save min Vpp capability}
      fwinfo.vppmax := j * vppres_k + vpperr_k; {save max Vpp capability}
      end;
    end;                               {done using GETCAP}

  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_FW_SHOW1 (PR, FW, STAT)
*
*   Write information about the firmware to standard output.  This will also
*   show the user defined name of this programmer if the name is available.
}
procedure picprg_fw_show1 (            {show firmware: version, org name}
  in out  pr: picprg_t;                {state for this use of the library}
  in      fw: picprg_fw_t;             {firmware information}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  max_msg_args = 3;                    {max arguments we can pass to a message}

var
  tk: string_var32_t;                  {scratch token}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;

begin
  tk.max := size_char(tk.str);         {init local var string}
  sys_error_none (stat);               {init to no error encountered}

  sys_msg_parm_vstr (msg_parm[1], fw.idname); {firmware type name}
  sys_msg_parm_int (msg_parm[2], fw.vers); {set version number parameter}

  if
      (ord(fw.org) >= ord(picprg_org_min_k)) and
      (ord(fw.org) <= ord(picprg_org_max_k)) and then
      (pr.env.org[fw.org].name.len > 0)
    then begin                         {organization name is available}
      sys_msg_parm_vstr (msg_parm[3], pr.env.org[fw.org].name);
      sys_message_parms ('picprg', 'fw_vers_name', msg_parm, 3);
      end
    else begin                         {no organization name, use organization ID}
      sys_msg_parm_int (msg_parm[3], ord(fw.org));
      sys_message_parms ('picprg', 'fw_vers_id', msg_parm, 3);
      end
    ;

  if pr.prgname.len <> 0 then begin    {name for this unit is available ?}
    sys_msg_parm_vstr (msg_parm[1], pr.prgname);
    sys_message_parms ('picprg', 'name', msg_parm, 1);
    end;
  sys_flush_stdout;                    {make sure all output sent to parent program}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_FW_CHECK (PR, FW, STAT)
*
*   Check the programmer firmware for compatibility with this version of the
*   PICPRG library.  FW is the information about the firmware.  STAT will
*   be set to an appropriate status if the firmware is incompatible.
}
procedure picprg_fw_check (            {check firmware compatibility}
  in out  pr: picprg_t;                {state for this use of the library}
  in      fw: picprg_fw_t;             {firmware information}
  out     stat: sys_err_t);            {completion status, error if FW incompatible}
  val_param;

begin
  sys_error_none (stat);               {init to no error}

  if (fw.cvlo <= picprg_fwmax_k) and (fw.cvhi >= picprg_fwmin_k)
    then return;                       {compatible with this library version}

  if fw.cvlo = fw.cvhi
    then begin                         {firmware implements single spec version}
      if picprg_fwmin_k = picprg_fwmax_k
        then begin                     {software requires a single version}
          sys_stat_set (picprg_subsys_k, picprg_stat_fwvers1_k, stat);
          sys_stat_parm_int (picprg_fwmin_k, stat);
          sys_stat_parm_int (fw.cvhi, stat);
          end
        else begin                     {software can handle range of versions}
          sys_stat_set (picprg_subsys_k, picprg_stat_fwvers1b_k, stat);
          sys_stat_parm_int (picprg_fwmin_k, stat);
          sys_stat_parm_int (picprg_fwmax_k, stat);
          sys_stat_parm_int (fw.cvlo, stat);
          end
        ;
      end
    else begin                         {firmware is compatible with range of vers}
      if picprg_fwmin_k = picprg_fwmax_k
        then begin                     {software requires a single version}
          sys_stat_set (picprg_subsys_k, picprg_stat_fwvers2_k, stat);
          sys_stat_parm_int (picprg_fwmin_k, stat);
          sys_stat_parm_int (fw.cvhi, stat);
          sys_stat_parm_int (fw.cvlo, stat);
          end
        else begin                     {software can handle range of versions}
          sys_stat_set (picprg_subsys_k, picprg_stat_fwvers2b_k, stat);
          sys_stat_parm_int (picprg_fwmin_k, stat);
          sys_stat_parm_int (picprg_fwmax_k, stat);
          sys_stat_parm_int (fw.cvlo, stat);
          sys_stat_parm_int (fw.cvhi, stat);
          end
        ;
      end
    ;
  end;
