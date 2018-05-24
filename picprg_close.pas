{   Subroutine PICPRG_CLOSE (PR, STAT)
*
*   Close this use of the PICPRG library.  All system resources allocated
*   to the library use are released and the library use state PR will be
*   returned invalid.
}
module picprg_close;
define picprg_close;
%include '/cognivision_links/dsee_libs/pics/picprg2.ins.pas';

procedure picprg_close (               {end a use of this library}
  in out  pr: picprg_t;                {library use state, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ev_thin: sys_sys_event_id_t;         {signalled when input thread exits}
  cmd_p: picprg_cmd_p_t;               {scratch command descriptor pointer}

begin
  pr.quit := true;                     {indicate trying to shut down}
  file_close (pr.conn);                {close the I/O connection}

  sys_thread_event_get (pr.thid_in, ev_thin, stat);
  if sys_error(stat) then return;
  discard(                             {wait for thread to exit or timeout}
    sys_event_wait_tout (ev_thin, 0.500, stat) );
  if sys_error(stat) then return;
  sys_thread_release (pr.thid_in, stat); {release all thread state}
  if sys_error(stat) then return;

  sys_thread_lock_enter (pr.lock_cmd); {lock exclusive access to command pointers}
  cmd_p := pr.cmd_inq_p;               {pointer to first command in input queue}
  while cmd_p <> nil do begin          {once for each queued command}
    sys_event_notify_bool (cmd_p^.done); {signal this command has completed}
    cmd_p := cmd_p^.next_p;            {advance to next queued command}
    end;
  sys_thread_lock_leave (pr.lock_cmd); {release exclusive lock on command pointers}

  sys_event_notify_bool (pr.ready);    {release any thread waiting to send command}
  sys_thread_lock_delete (pr.lock_cmd, stat); {delete cmd pointers interlock};
  if sys_error(stat) then return;
  sys_event_del_bool (pr.ready);       {delete the OK to send command event}

  util_mem_context_del (pr.mem_p);     {dealloc all dynamic memory and mem context}
  end;
