{   Subroutine PICPRG_OPEN (PR, STAT)
*
*   Open a new use of the PICPRG library.  PR is the state for this use of
*   the library, and must have been previously initialized with PICPRG_INIT.
*   PICPRG_INIT sets all choices for PICPRG_OPEN to default values.  The
*   application may change some fields.  These are:
*
*     SIO  -  Number of the system serial line that the PIC programmer
*       is connected to.  Serial lines are usually numbered sequentially
*       starting at 1.  On PC systems, this is the same as the COM port
*       number.  For example, an SIO value of 2 selects COM2.  The
*       default is 1.
*
*     DEVCONN  -  Type of physical connection to the programmer.  Initialized
*       to unknown.  Will attempt to open named device if set to unknown
*       on entry, then serial port SIO if no programmer found and PRGNAME not
*       set.
*
*     PRGNAME  -  User-settable name of the programmer to open.  The default
*       is the empty string, which indicates no particular programmer is
*       specified.
*
*   All other fields are private to the PICPRG library and must not be
*   accessed by the application.
*
*   System resources are allocated to a new use of the PICPRG library.
*   These are not guaranteed to be fully released until the library
*   use is closed with PICPRG_CLOSE.
}
module picprg_open;
define picprg_open;
%include 'picprg2.ins.pas';

procedure picprg_open (                {open a new use of this library}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  nnulls_k = 16;                       {number of NULL sync bytes to send}

var
  i: sys_int_machine_t;                {scratch integer and loop counter}
  buf: string_var132_t;                {scratch buffer and string}
  stat2: sys_err_t;                    {to use after STAT already indicating error}

label
  err_name, abort1, abort2, abort3;

begin
  buf.max := size_char(buf.str);       {init local var string}

  case pr.devconn of                   {what kind of connection to open to programmer?}

picprg_devconn_unk_k: begin            {no particular device connection type specified}
      pr.devconn := picprg_devconn_enum_k; {try named device}
      picprg_open (pr, stat);
      if not sys_stat_match (picprg_subsys_k, picprg_stat_noprog_k, stat) then begin
        return;                        {opened successfully or hard error}
        end;

      pr.devconn := picprg_devconn_sio_k; {try serial line connection}
      picprg_open (pr, stat);
      if not sys_error(stat) then return; {open programmer on serial line successfully ?}
      pr.devconn := picprg_devconn_unk_k; {restore original setting}
      return;                          {return with error from last open attempt}
      end;

picprg_devconn_sio_k: begin            {programmer is connected via a system serial line}
      file_open_sio (                  {open connection to the serial line}
        pr.sio,                        {system serial line number}
        file_baud_115200_k,            {baud rate}
        [],                            {no flow control}
        pr.conn,                       {returned connection to the serial line}
        stat);
      if sys_error(stat) then return;
      pr.flags := pr.flags + [picprg_flag_ack_k]; {ACK responses used for flow control}
      file_sio_set_eor_read (pr.conn, '', 0); {disable end of record detection on read}
      file_sio_set_eor_write (pr.conn, '', 0); {disable automatic end of record generation}
      for i := 1 to nnulls_k do begin  {fill BUF with the NULL sync bytes}
        buf.str[i] := chr(0);
        end;
      buf.len := nnulls_k;
      file_write_sio_rec (buf, pr.conn, stat); {send the NULL sync bytes}
      if sys_error(stat) then goto abort3;
      end;

picprg_devconn_enum_k: begin           {enumeratable named device}
      picprg_sys_name_open (           {open USB connection to named programmer}
        pr.prgname,                    {user name of specific programmer to select}
        pr.conn,                       {returned connection to the programmer}
        pr.devconn,                    {I/O connection type}
        stat);
      if sys_error(stat) then return;
      end;

otherwise
    sys_stat_set (picprg_subsys_k, picprg_stat_baddevconn_k, stat);
    sys_stat_parm_int (ord(pr.devconn), stat);
    return;
    end;

  util_mem_context_get (util_top_mem_context, pr.mem_p); {create private mem context}

  sys_event_create_bool (pr.ready);    {create event to signal ready for next cmd}
  sys_event_notify_bool (pr.ready);    {init to ready to send next command}
  pr.cmd_inq_p := nil;                 {init pending command input queue to empty}
  pr.cmd_inq_last_p := nil;
  sys_thread_lock_create (pr.lock_cmd, stat); {create CMD pointers interlock}
  if sys_error(stat) then goto abort2;
  pr.erase_p := nil;                   {init to no erase routine installed}
  pr.write_p := nil;                   {init to no write routine installed}
  pr.read_p := nil;                    {init to no read routine installed}
  pr.quit := false;                    {init to not trying to shut down}

  picprg_env_read (pr, stat);          {read environment file info into PR.ENV}
  if sys_error(stat) then goto abort1;

  sys_thread_create (                  {start thread to receive from remote unit}
    univ_ptr(addr(picprg_thread_in)),  {address of root thread routine}
    sys_int_adr_t(addr(pr)),           {pass pointer to state for this use of lib}
    pr.thid_in,                        {returned ID of this thread}
    stat);
  if sys_error(stat) then goto abort1;

  pr.id := 0;                          {init to no target chip identified}
  pr.id_p := nil;
  pr.name_p := nil;                    {init to no specific named chip chosen}
  pr.space := picprg_space_prog_k;     {init to program memory address space}
  pr.vdd.low := 5.0;                   {set default Vdd to use}
  pr.vdd.norm := 5.0;
  pr.vdd.high := 5.0;

  picprg_fwinfo (pr, pr.fwinfo, stat); {determine firmware ID and capabilities}
  if sys_error(stat) then goto abort1;

  if pr.fwinfo.cmd[67]
    then begin                         {can get name of this programmer}
      picprg_cmdw_nameget (pr, buf, stat); {get the name}
      if sys_error(stat) then goto abort1;
      if pr.prgname.len = 0
        then begin                     {no name specified by caller}
          string_copy (buf, pr.prgname); {set programmer name}
          end
        else begin                     {caller specified programmer name}
          if not string_equal (buf, pr.prgname) {not the name specified by the caller ?}
            then goto err_name;
          end
        ;
      end
    else begin                         {programmer has no name}
      if pr.prgname.len > 0 then goto err_name; {but caller specified a name ?}
      end
    ;

  if pr.fwinfo.cmd[16] then begin      {VDDVALS command implemented ?}
    picprg_cmdw_vddvals (pr, pr.vdd.low, pr.vdd.norm, pr.vdd.high, stat);
    if sys_error(stat) then goto abort1;
    end;
  if pr.fwinfo.cmd[65] then begin      {VDD command is available ?}
    picprg_cmdw_vdd (pr, pr.vdd.norm, stat); {init to normal Vdd level}
    if sys_error(stat) then goto abort1;
    end;
  return;                              {normal return point}
{
*   Error exits.  STAT is already set to indicate the error.
}
err_name:                              {programmer name not consistent with requested}
  sys_stat_set (picprg_subsys_k, picprg_stat_namprognf_k, stat); {named prog not found}
  sys_stat_parm_vstr (pr.prgname, stat);

abort1:                                {CONN, READY, LOCK_CMD created}
  pr.quit := true;                     {tell thread to shut down}
  sys_thread_lock_delete (pr.lock_cmd, stat2);

abort2:                                {CONN, READY created}
  pr.quit := true;                     {tell thread to shut down}
  sys_event_del_bool (pr.ready);       {delete the event}
  util_mem_context_del (pr.mem_p);     {delete private memory context}

abort3:                                {CONN open only}
  pr.quit := true;                     {tell thread to shut down}
  file_close (pr.conn);                {close connection to the programmer}
  end;
