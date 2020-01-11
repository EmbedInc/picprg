{   Subroutine PICPRG_THREAD_IN (PR)
*
*   This routine is run in a separate thread created by PICPRG_OPEN.
*   It reads and processes input received from the remote unit.
}
module picprg_thread_in;
define picprg_thread_in;
%include 'picprg2.ins.pas';

procedure picprg_thread_in (           {root thread routine, receives from remote}
  in out  pr: picprg_t);               {state for this use of the library}
  val_param;

var
  ibuf: array [0 .. 63] of char;       {raw input buffer}
  ibufi: sys_int_machine_t;            {index of next byte to read from IBUF}
  ibufn: sys_int_adr_t;                {number of bytes left to read from IBUF}
  vbuf: string_var4_t;                 {var string input buffer}
  b: int8u_t;                          {the input byte being processed}
  stat: sys_err_t;                     {completion status}

label
  loop, unlock_loop;
{
******************************
*
*   Local function IBYTE_USB
*
*   Return the next byte from the USB input stream.  Up to 64 bytes are read
*   from the USB at a time, then returned one by one by this function.
}
function ibyte_usb                     {return next byte from remote system}
  :sys_int_machine_t;                  {0-255 byte value}

var
  i: sys_int_machine_t;                {loop counter}
  stat: sys_err_t;                     {completion status}

label
  retry;

begin
  if pr.quit then begin                {trying to exit the program ?}
    sys_thread_exit;
    end;

retry:                                 {back here after reading new chunk into buffer}
  if ibufn > 0 then begin              {byte is available in local buffer ?}
    ibyte_usb := ord(ibuf[ibufi]);     {fetch the next buffer byte and return it}
    ibufi := ibufi + 1;                {advance buffer index for next time}
    ibufn := ibufn - 1;                {count one less byte left in the buffer}
    return;
    end;

  picprg_sys_usb_read (                {read next chunk of data from remote device}
    pr.conn,                           {connection to the device}
    sizeof(ibuf),                      {max amount of data allowed to read}
    ibuf,                              {input buffer to return data in}
    ibufn,                             {number of bytes actually read}
    stat);
  if pr.quit then begin                {trying to exit the program ?}
    sys_thread_exit;
    end;
  if sys_error(stat) then begin        {hard error occurred}
    for i := 1 to 10 do begin          {give time for app to close library}
      sys_wait (0.050);
      if pr.quit then sys_thread_exit;
      end;
    sys_error_abort (stat, '', '', nil, 0); {bomb whole app with hard error}
    end;

  ibufi := 0;                          {reset to fetch from start of buffer}
  goto retry;                          {back to return byte from new chunk}
  end;
{
******************************
*
*   Start of main routine.
}
begin
  vbuf.max := 1;                       {only read one character at a time}
  ibufi := 0;                          {init input buffer to empty}
  ibufn := 0;
  sys_error_none (stat);               {init to no error encountered}

loop:                                  {back here to read each new input byte}
  if pr.quit then return;              {trying to shut down this use of library ?}
  case pr.devconn of
picprg_devconn_sio_k: begin            {input is coming from SIO line}
      file_read_sio_rec (pr.conn, vbuf, stat); {read next input byte}
      b := ord(vbuf.str[1]);           {get the new input byte into B}
      end;
picprg_devconn_usb_k: begin            {input is coming from the USB}
      b := ibyte_usb;
      end;
otherwise
    sys_stat_set (picprg_subsys_k, picprg_stat_baddevconn_k, stat);
    sys_stat_parm_int (ord(pr.devconn), stat);
    return;
    end;
  if pr.quit then return;              {trying to shut down this use of library ?}
  sys_error_abort (stat, '', '', nil, 0);
{
*   The next input byte is in B.
}
  if picprg_flag_showin_k in pr.flags then begin
    writeln ('< ', b);
    end;

  sys_thread_lock_enter (pr.lock_cmd); {lock exclusive access to command pointers}

  if pr.cmd_inq_p = nil                {no command waiting for input, ignore this byte ?}
    then goto unlock_loop;

  if not pr.cmd_inq_p^.recv.ack
    then begin                         {not yet received ACK for this command}
      if b <> ord(picprg_rsp_ack_k) then goto unlock_loop; {ignore bytes until ACK}
      pr.cmd_inq_p^.recv.ack := true;  {indicate ACK now received}
      sys_event_notify_bool (pr.ready); {signal OK to send next command}
      end
    else begin                         {ACK already received for this command}
      pr.cmd_inq_p^.recv.nbuf := pr.cmd_inq_p^.recv.nbuf + 1; {count one more input byte}
      pr.cmd_inq_p^.recv.buf[pr.cmd_inq_p^.recv.nbuf] := b; {add new byte to buffer}
      end
    ;

  if
      (pr.cmd_inq_p^.recv.lenby <> 0) and {variable length response ?}
      (pr.cmd_inq_p^.recv.nbuf = pr.cmd_inq_p^.recv.nresp) {just got last fixed byte ?}
      then begin
    pr.cmd_inq_p^.recv.nresp :=        {add number of remaining var len bytes}
      pr.cmd_inq_p^.recv.nresp +
      pr.cmd_inq_p^.recv.buf[pr.cmd_inq_p^.recv.lenby];
    pr.cmd_inq_p^.recv.lenby := 0;     {no longer a variable length response}
    end;

  if pr.cmd_inq_p^.recv.nbuf < pr.cmd_inq_p^.recv.nresp {more bytes expected this command ?}
    then goto unlock_loop;
{
*   All the input bytes for the current command have been received.  We are holding
*   the lock on the command descriptor pointers.
}
  sys_event_notify_bool (pr.cmd_inq_p^.done); {signal that this command has completed}

  if pr.cmd_inq_p^.next_p = nil
    then begin                         {done with last command in the queue}
      pr.cmd_inq_last_p := nil;
      end
    else begin                         {there is another command after this one}
      pr.cmd_inq_p^.next_p^.prev_p := nil; {next command will be first in list}
      end
    ;
  pr.cmd_inq_p := pr.cmd_inq_p^.next_p; {point to next command waiting on input}

unlock_loop:                           {release cmd pointers lock, back for next byte}
  sys_thread_lock_leave (pr.lock_cmd); {release exclusive lock on command pointers}
  goto loop;                           {back for next input byte}
  end;
