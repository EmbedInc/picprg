{   Program TEST_PPDAT [options]
*
*   This program provides a command line interface for the debug protocol of
*   the data port of a USBProg PIC programmer.  The USBProg serial port must be
*   configured as a data port, not as another source of programming commands.
}
program test_ppdat;
%include 'base.ins.pas';
%include 'pic.ins.pas';
%include 'builddate.ins.pas';

const
  baud_k = file_baud_115200_k;         {serial line baud rate}
  outbuf_size = 32;                    {size of buffer for bytes to remote unit}
  datar_size = 256;                    {number of entries in DATAR}
  n_cmdnames_k = 5;                    {number of command names in the list}
  cmdname_maxchars_k = 7;              {max chars in any command name}
  max_msg_parms = 2;                   {max parameters we can pass to a message}
{
*   Response opcodes.
}
  rsp_nop_k = 0;                       {NOP, ignored}
  rsp_opc6_k = 1;                      {6 bit opcode being sent}
  rsp_dat14_k = 2;                     {14 bit data in 16 bit word}
  rsp_dat22_k = 3;                     {22 bit data in 24 bit word}
{
*   Derived constants.
}
  datar_last = datar_size - 1;         {last valid DATAR index}
  cmdname_len_k = cmdname_maxchars_k + 1; {number of chars to reserve per cmd name}

type
  cmdname_t =                          {one command name in the list}
    array[1..cmdname_len_k] of char;
  cmdnames_t =                         {list of all the command names}
    array[1..n_cmdnames_k] of cmdname_t;

var
  cmdnames: cmdnames_t := [            {list of all the command names}
    'HELP   ',                         {1}
    '?      ',                         {2}
    'QUIT   ',                         {3}
    'Q      ',                         {4}
    'SHOW   ',                         {5}
    ];

var
  sio: sys_int_machine_t;              {number of system serial line to use}
  conn: file_conn_t;                   {connection to the system serial line}
  ii: sys_int_machine_t;               {scratch integer and loop counter}
  prompt:                              {prompt string for entering command}
    %include '(cog)lib/string4.ins.pas';
  cmdv: array[0 .. 255] of boolean;    {TRUE for valid commands}
  quit: boolean;                       {TRUE when trying to exit the program}
  isopen: boolean;                     {connection to remote unit is open}
  pst: string_index_t;                 {scratch command parse index}
  b1: boolean;                         {boolean command parameter}
  datar:                               {scratch array for processing commands}
    array[0..datar_last] of sys_int_machine_t;
  datarn: sys_int_machine_t;           {number of entries in DATAR}
  show_nop: boolean;                   {show NOP responses}
  show_in, show_out: boolean;          {show input and outut raw bytes}

  opt:                                 {upcased command line option}
    %include '(cog)lib/string_treename.ins.pas';
  parm:                                {command parameter}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_opt, err_parm, parm_bad, done_opts, loop_cmd,
  done_cmd, err_extra, bad_cmd, bad_parm, err_cmparm, cmd_nsupp, leave;

%include '(cog)lib/wout_local.ins.pas'; {define std out writing routines}
%include '(cog)lib/nextin_local.ins.pas'; {define command reading routines}
%include '(cog)lib/send_local.ins.pas'; {define routines for sending to device}
{
********************************************************************************
*
*   Subroutine SENDALL
*
*   Send all buffered bytes, if any.  This routine does nothing if the output
*   buffer is empty.  The output buffer is reset to empty after its content is
*   sent.
*
*   This routine is required by the SEND_LOCAL include file.
*
*   The output lock must be held when this routine is called.
}
procedure sendall;                     {send all buffered output bytes, if any}
  val_param; internal;

var
  ii: sys_int_machine_t;               {scratch integer}
  stat: sys_err_t;                     {completion status}

begin
  if outbuf.len <= 0 then return;      {buffer is empty, nothing to send ?}

  if show_out then begin               {show each output byte ?}
    lockout;
    write ('>');
    for ii := 1 to outbuf.len do begin
      write (' ', ord(outbuf.str[ii]));
      end;
    writeln;
    unlockout;
    end;

  file_write_sio_rec (outbuf, conn, stat); {send the bytes over the serial line}
  sys_error_abort (stat, '', '', nil, 0);
  outbuf.len := 0;                     {reset output buffer to empty}
  end;
{
********************************************************************************
*
*   Subroutine THREAD_IN (ARG)
*
*   This routine is run in a separate thread.  It reads the response stream from
*   the host unit and processes the indiviual responses.
}
procedure thread_in (                  {get data bytes from serial line}
  in      arg: sys_int_adr_t);         {unused argument}
  val_param; internal;

var
  ibuf: string_var80_t;                {raw input buffer}
  ibufi: sys_int_machine_t;            {index of next byte to read from IBUF}
  ibufn: sys_int_adr_t;                {number of bytes left to read from IBUF}
  b: sys_int_machine_t;                {data byte value}
  i1:                                  {scratch integers for processing a response}
    sys_int_conv32_t;
  tk: string_var32_t;                  {scratch tokens}

label
  loop, err_locked, done_rsp;
{
******************************
*
*   Function IBYTE
*   This function is local to THREAD_IN.
*
*   Return the next byte from the remote unit.
}
function ibyte                         {return next byte from remote system}
  :sys_int_machine_t;                  {0-255 byte value}
  val_param;

const
  chunksize = 64;                      {maximum bytes to read at a time}

var
  b: sys_int_machine_t;                {the returned byte value}
  stat: sys_err_t;                     {completion status}

label
  retry;

begin
  if quit then begin                   {trying to exit the program ?}
    sys_thread_exit;
    end;

retry:                                 {back here after reading new chunk into buffer}
  if ibufn > 0 then begin              {byte is available in local buffer ?}
    b := ord(ibuf.str[ibufi+1]);       {get the data byte to return}
    ibufi := ibufi + 1;                {advance buffer index for next time}
    ibufn := ibufn - 1;                {count one less byte left in the buffer}
    if show_in then begin              {show each individual input byte ?}
      lockout;                         {acquire exclusive lock on standard output}
      write ('Received byte: ');
      wchar (chr(b));                  {show the byte in HEX, decimal, and character}
      writeln;
      unlockout;                       {release lock on standard output}
      end;
    ibyte := b;                        {return the data byte}
    return;
    end;

  ibuf.max := min(chunksize, size_char(ibuf.str));
  file_read_sio_rec (conn, ibuf, stat); {read next chunk from serial line}
  if quit then begin                   {trying to exit the program ?}
    sys_thread_exit;
    end;
  sys_error_abort (stat, '', '', nil, 0);
  ibufn := ibuf.len;                   {init number of bytes left to read from buffer}
  ibufi := 0;                          {reset to fetch from start of buffer}
  goto retry;                          {back to return byte from new chunk}
  end;
{
******************************
*
*   Function GETI16U
*   This function is local to THREAD_IN.
*
*   Returns the next two input bytes interpreted as a unsigned 16 bit integer.
}
function geti16u                       {get next 2 bytes as unsigned integer}
  :sys_int_machine_t;

var
  ii: sys_int_machine_t;

begin
  ii := lshft(ibyte, 8);               {get the high byte}
  ii := ii ! ibyte;                    {get the low byte}
  geti16u := ii;
  end;
{
******************************
*
*   Function GETI24U
*   This function is local to THREAD_IN.
*
*   Returns the next three input bytes interpreted as a unsigned 24 bit integer.
}
function geti24u                       {get next 3 bytes as unsigned integer}
  :sys_int_machine_t;

var
  ii: sys_int_machine_t;

begin
  ii := lshft(ibyte, 16);              {get the high byte}
  ii := ii ! lshft(ibyte, 8);          {get the middle byte}
  ii := ii ! ibyte;                    {get the low byte}
  geti24u := ii;
  end;
{
******************************
*
*   Executable code for subroutine THREAD_IN.
}
begin
  tk.max := size_char(tk.str);         {init local var strings}
  ibufn := 0;                          {init the input buffer to empty}

loop:                                  {back here each new response opcode}
  b := ibyte;                          {get response opcode byte}
  case b of
{
*   NOP
}
rsp_nop_k: begin
  if show_nop then begin
    lockout;
    writeln ('NOP');
    unlockout;
    end;
  end;
{
*   OPC6 opc
}
rsp_opc6_k: begin
  i1 := ibyte;                         {get the opcode}

  lockout;
  writeln ('OPC ', i1);
  unlockout;
  end;
{
*   DAT14 dat
}
rsp_dat14_k: begin
  i1 := geti16u;                       {get the 16 bit data word}

  i1 := rshft(i1, 1) & 16#3FFF;        {extract the 14 bit payload}
  lockout;
  write ('Data ');
  whex16 (i1);
  writeln;
  unlockout;
  end;
{
*   DAT22 dat
}
rsp_dat22_k: begin
  i1 := geti24u;                       {get the 24 bit data word}

  i1 := rshft(i1, 1) & 16#3FFFFF;      {extract the 22 bit payload}
  lockout;
  write ('Adr ');
  whex24 (i1);
  writeln;
  unlockout;
  end;
{
*   Unrecognized response opcode.
}
otherwise
    lockout;                           {get exclusive use of standard output}
    write ('Rsp: ');
    whex (b);
    writeln ('h  ', b);
err_locked:                            {jump here on error while output locked}
    unlockout;                         {release lock on standard output}
    end;

done_rsp:                              {done processing this response}
  goto loop;                           {back to read next byte from serial line}
  end;
{
********************************************************************************
*
*   Subroutine DATAR_ADD (V)
*
*   Add the value V as the next word in the scratch data array DATAR.  DATARN is
*   updated to indicate the number of entries in DATAR.  Nothing is done if the
*   array is already full.
}
(*
procedure datar_add (                  {add value to DATAR array}
  in      v: sys_int_machine_t);       {the value to add}
  val_param; internal;

begin
  if datarn < datar_size then begin    {array isn't already full ?}
    datar[datarn] := v;                {stuff this value into the array}
    datarn := datarn + 1;              {count one more value in the array}
    end;
  end;
*)
{
********************************************************************************
*
*   Subroutine OPEN_CONN
*
*   Open the connection to the remote unit.
*
*   Nothing is done if the connection to the remote unit is already open.
}
procedure open_conn;                   {make sure connection to remote unit is open}
  val_param; internal;

var
  thid: sys_sys_thread_id_t;           {thread ID}
  tk: string_var32_t;                  {scratch token}
  stat: sys_err_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  if isopen then return;               {connection previously opened ?}

  file_open_sio (                      {open connection to the serial line}
    sio,                               {number of serial line to use}
    baud_k,                            {baud rate}
    [],                                {no flow control}
    conn,                              {returned connection to the serial line}
    stat);
  sys_error_abort (stat, '', '', nil, 0);
  file_sio_set_eor_read (conn, '', 0); {no special input end of record sequence}
  file_sio_set_eor_write (conn, '', 0); {no special output end of record sequence}
  isopen := true;                      {connection to remote unit is now open}

  outbuf.len := 0;                     {init to no buffered data for the device}
{
*   Perform some system initialization.
}
  sys_thread_create (                  {start thread for reading serial line input}
    addr(thread_in),                   {address of thread root routine}
    0,                                 {argument passed to thread (unused)}
    thid,                              {returned thread ID}
    stat);
  sys_error_abort (stat, '', '', nil, 0);
  end;
{
****************************************************************************
*
*   Start of main routine.
}
begin
  wout_init;                           {init output writing state}
  send_init;                           {init state for sending to remote unit}
  send_high_low;                       {send multi-byte data in high to low order}
  isopen := false;                     {indicate connection to remote unit not open}
  quit := false;                       {init to not trying to exit the program}
  writeln ('TEST_PPDAT built ', build_dtm_str:size_char(build_dtm_str));
{
*   Initialize our state before reading the command line options.
}
  sio := 1;                            {init to default serial line number}
  sys_envvar_get (string_v('SIO_DEFAULT'), parm, stat);
  if not sys_error(stat) then begin
    string_t_int (parm, ii, stat);
    if not sys_error(stat) then begin
      sio := ii;
      end;
    end;
  sys_envvar_get (string_v('TEST_PPDAT_SIO'), parm, stat);
  if not sys_error(stat) then begin
    string_t_int (parm, ii, stat);
    if not sys_error(stat) then begin
      sio := ii;
      end;
    end;

  show_nop := false;                   {init to not show NOP responses}
  show_in := false;                    {init to not show raw input bytes}
  show_out := false;                   {init to not show raw output bytes}
  string_cmline_init;                  {init for reading the command line}
{
*   Back here each new command line option.
}
next_opt:
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_opts; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (opt,                {pick command line option name from list}
    '-SIO -SHOWIN -SHOWOUT',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -SIO n
}
1: begin
  string_cmline_token_int (sio, stat);
  end;
{
*   -SHOWIN
}
2: begin
  show_in := true;
  end;
{
*   -SHOWOUT
}
3: begin
  show_out := true;
  end;
{
*   Unrecognized command line option.
}
otherwise
    string_cmline_opt_bad;             {unrecognized command line option}
    end;                               {end of command line option case statement}

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
*   All done reading the command line.
}
  for ii := 0 to 255 do begin          {init all remote commands to unimplemented}
    cmdv[ii] := false;
    end;

  for ii := 0 to datar_last do begin   {init the scratch data array}
    datar[ii] := 0;
    end;

  open_conn;                           {open the connection to the remote unit}
{
***************************************
*
*   Process user commands.
*
*   Initialize before command processing.
}
  string_vstring (prompt, ': '(0), -1); {set command prompt string}

loop_cmd:
  sys_wait (0.100);
  lockout;
  string_prompt (prompt);              {prompt the user for a command}
  newline := false;                    {indicate STDOUT not at start of new line}
  unlockout;

  string_readin (inbuf);               {get command from the user}
  newline := true;                     {STDOUT now at start of line}
  p := 1;                              {init BUF parse index}
  while inbuf.str[p] = ' ' do begin    {scan forwards to the first non-blank}
    p := p + 1;
    end;
  pst := p;                            {save parse index at start of command}
  next_keyw (opt, stat);               {extract command name into OPT}
  if string_eos(stat) then goto loop_cmd;
  if sys_error_check (stat, '', '', nil, 0) then begin
    goto loop_cmd;
    end;
  string_tkpick_s (                    {pick command name from list}
    opt, cmdnames, sizeof(cmdnames), pick);
  datarn := 0;                         {init scratch data array to empty}
  case pick of                         {which command is it}
{
**********
*
*   HELP
}
1, 2: begin
  if not_eos then goto err_extra;

  lockout;                             {acquire lock for writing to output}
  writeln;
  writeln ('HELP or ?      - Show this list of commands.');
  writeln ('SHOW IN|OUT ON|OFF - Show raw input/output bytes');

  if cmdv[1] then
    writeln ('PING           - Send PING command to test communication link');
  if cmdv[2] then
    writeln ('FWINFO         - Request firmware version info');

  writeln ('Q or QUIT      - Exit the program');
  unlockout;                           {release lock for writing to output}
  end;
{
**********
*
*   QUIT
}
3, 4: begin
  if not_eos then goto err_extra;

  goto leave;
  end;
{
**********
*
*   PING
}
5: begin
  if not cmdv[1] then goto cmd_nsupp;
  if not_eos then goto err_extra;

  send_acquire;
  sendb (1);                           {send PING command}
  send_release;
  sendall;                             {send command now, output buffer will be empty}
  end;
{
**********
*
*   FWINFO
}
6: begin
  if not cmdv[2] then goto cmd_nsupp;
  if not_eos then goto err_extra;

  send_acquire;
  sendb (2);                           {request the firmware version}
  send_release;
  end;
{
**********
*
*   SHOW IN onoff
*   SHOW OUT onoff
}
7: begin
  next_keyw (parm, stat);
  if sys_error(stat) then goto err_cmparm;
  string_tkpick80 (parm, 'IN OUT', pick);
  case pick of
1:  begin                              {SHOW IN}
      b1 := next_onoff(stat);
      if sys_error(stat) then goto err_cmparm;
      if not_eos then goto err_extra;
      show_in := b1;
      end;
2:  begin                              {SHOW OUT}
      b1 := next_onoff(stat);
      if sys_error(stat) then goto err_cmparm;
      if not_eos then goto err_extra;
      show_out := b1;
      end;
otherwise
    goto bad_cmd;
    end;
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
    lockout;
    writeln ('Too many parameters for this command.');
    unlockout;
    end;

  if outbuf.len > 0 then begin         {there are unsent bytes in output buffer ?}
    send_acquire;
    sendall;
    send_release;
    end;
  goto loop_cmd;                       {back to process next command}

bad_cmd:                               {unrecognized or illegal command}
  lockout;
  writeln ('Huh?');
  unlockout;
  goto loop_cmd;

bad_parm:                              {bad parameter, parmeter in PARM}
  lockout;
  writeln ('Bad parameter "', parm.str:parm.len, '"');
  unlockout;
  goto loop_cmd;

err_cmparm:                            {parameter error, STAT set accordingly}
  lockout;
  sys_error_print (stat, '', '', nil, 0);
  unlockout;
  goto loop_cmd;

cmd_nsupp:
  lockout;
  writeln ('Command not supported by this firmware.');
  unlockout;
  goto loop_cmd;

leave:
  quit := true;                        {tell all threads to shut down}
  file_close (conn);                   {close connection to the serial line}
  end.
