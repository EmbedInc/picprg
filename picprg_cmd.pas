{   Routines that manipulate and use the command descriptor structure
*   PICPRG_CMD_T.
}
module picprg_cmd;
define picprg_init_cmd;
define picprg_cmd_start;
define picprg_add_i8u;
define picprg_add_i16u;
define picprg_add_i24u;
define picprg_add_i32u;
define picprg_cmd_expect;
define picprg_send_cmd;
define picprg_wait_cmd;
define picprg_wait_cmd_tout;
%include '/cognivision_links/dsee_libs/pics/picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_INIT_CMD (CMD)
*
*   Initialize a command descriptor.  This will allocate resources that are
*   released by PICPRG_WAIT_CMD.
}
procedure picprg_init_cmd (            {initialize a command descriptor}
  out     cmd: picprg_cmd_t);          {returned initialized}
  val_param;

begin
  cmd.prev_p := nil;                   {init to no previous command queued for input}
  cmd.next_p := nil;                   {init to no following command queued for input}
  cmd.send.nbuf := 0;                  {init to no bytes to send}
  cmd.recv.lenby := 0;                 {init to no length byte (fixed length response)}
  cmd.recv.nresp := 0;                 {init to no response data bytes expected}
  cmd.recv.nbuf := 0;                  {init to no response data byte received}
  cmd.recv.ack := false;               {init to ACK not yet received}
  sys_event_create_bool (cmd.done);    {create event to signal when cmd completed}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_CMD_START (PR, CMD, OPC, STAT)
*
*   Start for sending a command.  The command descriptor CMD is initialize and
*   the command opcode is set to OPC.  STAT is returned PICPRG_STAT_CMDNIMP_K if
*   the command OPC is not implemented in this firmware.
}
procedure picprg_cmd_start (           {start for sending a command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {returned command descriptor, will be initialized}
  in      opc: sys_int_machine_t;      {0-255 command opcode}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  tk: string_var32_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  if  (opc < 0) or (opc > 255)         {opcode outside valid range ?}
      or else not pr.fwinfo.cmd[opc]   {this opcode not implemented ?}
      then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    string_f_int (tk, opc);
    sys_stat_parm_vstr (tk, stat);     {pass the illegal opcode name}
    return;
    end;
  sys_error_none (stat);               {indicate no error}

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, opc);           {set opcode as first byte to send}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_ADD_I8U (CMD, VAL)
*
*   Append an unsigned 8 bit integer value to the byte stream to send for the
*   command CMD.
}
procedure picprg_add_i8u (             {add 8 bit unsigned int to cmd out stream}
  in out  cmd: picprg_cmd_t;           {the command to add data to}
  in      val: sys_int_machine_t);     {the value to add}
  val_param;

begin
  if cmd.send.nbuf >= picprg_maxlen_cmd_k {ignore if output buffer already full}
    then return;

  cmd.send.nbuf := cmd.send.nbuf + 1;  {count one more byte in output buffer}
  cmd.send.buf[cmd.send.nbuf] := val & 255; {append to command output bytes}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ADD_I16U (CMD, VAL)
*
*   Append an unsigned 16 bit integer value to the byte stream to send for the
*   command CMD.
}
procedure picprg_add_i16u (            {add 16 bit unsigned int to cmd out stream}
  in out  cmd: picprg_cmd_t;           {the command to add data to}
  in      val: int16u_t);              {the value to add}
  val_param;

begin
  picprg_add_i8u (cmd, val & 255);     {add the low byte}
  picprg_add_i8u (cmd, rshft(val, 8) & 255); {add the high byte}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ADD_I24U (CMD, VAL)
*
*   Append an unsigned 24 bit integer value to the byte stream to send for the
*   command CMD.
}
procedure picprg_add_i24u (            {add 24 bit unsigned int to cmd out stream}
  in out  cmd: picprg_cmd_t;           {the command to add data to}
  in      val: sys_int_conv24_t);      {the value to add}
  val_param;

begin
  picprg_add_i8u (cmd, val & 255);     {add the low byte}
  picprg_add_i8u (cmd, rshft(val, 8) & 255); {add the middle byte}
  picprg_add_i8u (cmd, rshft(val, 16) & 255); {add the high byte}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_ADD_I32U (CMD, VAL)
*
*   Append an unsigned 32 bit integer value to the byte stream to send for the
*   command CMD.
}
procedure picprg_add_i32u (            {add 32 bit unsigned int to cmd out stream}
  in out  cmd: picprg_cmd_t;           {the command to add data to}
  in      val: sys_int_conv32_t);      {the value to add}
  val_param;

begin
  picprg_add_i8u (cmd, val & 255);     {add byte 0}
  picprg_add_i8u (cmd, rshft(val, 8) & 255); {add byte 1}
  picprg_add_i8u (cmd, rshft(val, 16) & 255); {add byte 2}
  picprg_add_i8u (cmd, rshft(val, 24) & 255); {add byte 3}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_CMD_EXPECT (CMD, N, LENB)
*
*   Indicate the response expected from the command.  N is the number of fixed
*   bytes that the command always sends.  If the command responds with a
*   variable number of bytes, then one of its fixed response bytes must indicate
*   the additional number of variables bytes.  LENB is the 1-N index of this
*   length byte.  A LENB value of 0 indicates the command always sends exactly
*   N response bytes.  LENB must never exceed N.
}
procedure picprg_cmd_expect (          {indicate size of response expected from command}
  in out  cmd: picprg_cmd_t;           {command descriptor}
  in      n: sys_int_machine_t;        {number of fixed bytes always sent}
  in      lenb: sys_int_machine_t);    {1-N index of length byte, 0 = fixed size response}
  val_param;

begin
  cmd.recv.nresp := max(0, n);         {set number of fixed bytes expected}
  cmd.recv.lenby := max(0, min(cmd.recv.nresp, lenb)); {identify length byte}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_SEND_CMD (PR, CMD, STAT)
*
*   Send a command to the remote system.  This routine will wait, if
*   necessary, until it is permissible to send another command to the
*   remote system.  This routine will only send the command without
*   waiting for the response.  CMD is the command descriptor, which
*   must already be set up.  The CMD.DONE event will be signalled
*   asynchronously when the response has been received for the command.
}
procedure picprg_send_cmd (            {send a command to the remote unit}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {the command to send}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {scratch integer}
  nresp: sys_int_machine_t;            {total number of response bytes expected}

begin
  sys_event_wait_any (                 {wait for OK to send next command}
    pr.ready, 1,                       {list of events to wait on}
    sys_timeout_none_k,                {no timeout, wait as long as it takes}
    i,                                 {returned number of the triggered event}
    stat);
  if sys_error(stat) then return;
  if picprg_closing (pr, stat) then return; {library is being closed down ?}

  nresp := cmd.recv.nresp;             {number of real response bytes expected}
  if picprg_flag_ack_k in pr.flags
    then begin                         {ACK will be sent for commands}
      nresp := nresp + 1;              {one more total response byte expected}
      end
    else begin                         {ACK not in use}
      cmd.recv.ack := true;            {indicate not waiting for ACK for this command}
      end
    ;
{
*   NRESP is the total number of response bytes expected for this command.  Bytes
*   from the remote unit are received and handled in a separate thread.  Commands
*   awaiting responses are put onto a queue so that the receiving thread can
*   associate incoming bytes with commands, and complete the commands when all
*   response bytes have been received.  Since the queue is only for commands
*   awaiting responses, output-only commands are not queued and are completed
*   immediately here.
}
  if nresp > 0 then begin              {expecting response, queue the command ?}
    sys_thread_lock_enter (pr.lock_cmd); {lock exclusive access to command pointers}
    if pr.cmd_inq_last_p = nil
      then begin                       {adding this command to empty queue}
        pr.cmd_inq_p := addr(cmd);     {set start of queue pointer}
        end
      else begin                       {add to end of existing queue}
        cmd.prev_p := pr.cmd_inq_last_p; {link back to previous queue entry}
        pr.cmd_inq_last_p^.next_p := addr(cmd); {set forwards pointer from previous entry}
        end
      ;
    pr.cmd_inq_last_p := addr(cmd);    {update end of queue pointer}
    sys_thread_lock_leave (pr.lock_cmd); {release exclusive lock on command pointers}
    end;

  picprg_sendbuf (pr, cmd.send.buf, cmd.send.nbuf, stat); {send the command bytes}
  if sys_error(stat) then return;
  if not (picprg_flag_ack_k in pr.flags) then begin {not using ACKs ?}
    sys_event_notify_bool (pr.ready);  {another command can be queued immediately}
    end;

  if nresp = 0 then begin              {no response bytes, command was not queued ?}
    sys_event_notify_bool (cmd.done);  {indicate this command is completed}
    end;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_WAIT_CMD_TOUT (PR, CMD, TOUT, STAT)
*
*   Wait for the command CMD to complete within TOUT seconds.  All system
*   resources allocated to the command will be released.  If the response
*   is received within the timeout, then all the response bytes will be in
*   the input buffer.  If the timeout elapses before all response bytes
*   are received, then STAT will be set to PICPRG_STAT_NRESP_K status and
*   the response data returned in CMD will be invalid.
*
*   This routine must be called after the command is sent to the remote
*   unit.  It may only be called once per command.
}
procedure picprg_wait_cmd_tout (       {wait for command to complete or timeout}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {the command, system resources released}
  in      tout: real;                  {maximum time to wait, seconds}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  to: real;                            {seconds timeout or special flag value}

begin
  if picprg_closing (pr, stat) then return; {library is being closed down ?}

  to := tout;                          {init timeout to value passed in}
  if picprg_flag_nintout_k in pr.flags then begin {input timeout disabled ?}
    to := sys_timeout_none_k;          {no timeout, wait indefinitely}
    end;

  discard(                             {wait for command completed or timeout}
    sys_event_wait_tout (cmd.done, to, stat) );
  if picprg_closing (pr, stat) then return; {library is being closed down ?}
  sys_error_abort (stat, '', '', nil, 0);

  sys_thread_lock_enter (pr.lock_cmd); {lock exclusive access to command pointers}
  if (not cmd.recv.ack) or (cmd.recv.nbuf <> cmd.recv.nresp) then begin {cmd not completed ?}
    if cmd.prev_p = nil
      then begin                       {is at start of queue}
        pr.cmd_inq_p := cmd.next_p;
        end
      else begin                       {not at start of queue}
        cmd.prev_p^.next_p := cmd.next_p;
        end
      ;
    if cmd.next_p = nil
      then begin                       {is at end of queue}
        pr.cmd_inq_last_p := cmd.prev_p;
        end
      else begin                       {not at end of queue}
        cmd.next_p^.prev_p := cmd.prev_p;
        end
      ;
    sys_stat_set (                     {set return status to indicate the timeout}
      picprg_subsys_k, picprg_stat_nresp_k, stat);
    sys_stat_parm_int (pr.sio, stat);
    sys_event_notify_bool (pr.ready);  {signal OK to send next command}
    end;
  sys_thread_lock_leave (pr.lock_cmd); {release exclusive lock on command pointers}
  sys_event_del_bool (cmd.done);       {delete the system event}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_WAIT_CMD (PR, CMD, STAT)
*
*   Wait for the command CMD to complete using the default timeout.  This is
*   a special case of PICPRG_WAIT_CMD_TOUT, above, where the timeout wait
*   interval is set to infinite.
}
procedure picprg_wait_cmd (            {wait for a command to complete}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {the command, system resources released}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_wait_cmd_tout (pr, cmd, 2.000, stat);
  end;
