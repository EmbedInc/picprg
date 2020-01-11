{   Program TEST_USBPROG
*
*   Program to test low level USB communication with a USBPROG PIC
*   programmer.
}
program test_usbprog;
%include 'picprg2.ins.pas';

const
  max_msg_parms = 2;                   {max parameters we can pass to a message}

var
  name:                                {name of device to open, empty = first available}
    %include '(cog)lib/string80.ins.pas';
  conn: file_conn_t;                   {connection to the remote unit}
  wrlock: sys_sys_threadlock_t;        {lock for writing to standard output}
  thid_in: sys_sys_thread_id_t;        {ID of read input thread}
  prompt:                              {prompt string for entering command}
    %include '(cog)lib/string4.ins.pas';
  buf:                                 {one line command buffer}
    %include '(cog)lib/string8192.ins.pas';
  obuf:                                {output bytes data buffer}
    %include '(cog)lib/string8192.ins.pas';
  p: string_index_t;                   {BUF parse index}
  quit: boolean;                       {TRUE when trying to exit the program}
  newline: boolean;                    {STDOUT stream is at start of new line}
  devconn: picprg_devconn_k_t;         {connection type to programmer}

  i1: sys_int_machine_t;               {integer command parameters}

  opt:                                 {upcased command line option}
    %include '(cog)lib/string_treename.ins.pas';
  parm:                                {command line option parameter}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_opt, err_parm, parm_bad, done_opts,
  loop_iline, loop_hex, tkline, loop_tk,
  done_cmd, err_cmparm, leave;
{
****************************************************************************
*
*   Subroutine LOCKOUT
*
*   Acquire exclusive lock for writing to standard output.
}
procedure lockout;

begin
  sys_thread_lock_enter (wrlock);
  if not newline then writeln;         {start on a new line}
  newline := true;                     {init to STDOUT will be at start of line}
  end;
{
****************************************************************************
*
*   Subroutine UNLOCKOUT
*
*   Release exclusive lock for writing to standard output.
}
procedure unlockout;

begin
  sys_thread_lock_leave (wrlock);
  end;
{
****************************************************************************
*
*   Subroutine WHEX (B)
*
*   Write the byte value in the low 8 bits of B as two hexadecimal digits
*   to standard output.
}
procedure whex (                       {write hex byte to standard output}
  in      b: sys_int_machine_t);       {byte value in low 8 bits}
  val_param; internal;

var
  tk: string_var16_t;                  {hex string}
  stat: sys_err_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_int_max_base (              {make the hex string}
    tk,                                {output string}
    b & 255,                           {input integer}
    16,                                {radix}
    2,                                 {field width}
    [ string_fi_leadz_k,               {pad field on left with leading zeros}
      string_fi_unsig_k],              {the input integer is unsigned}
    stat);
  write (tk.str:tk.len);               {write the string to standard output}
  end;
{
****************************************************************************
*
*   Subroutine WDEC (B)
*
*   Write the byte value in the low 8 bits of B as an unsigned decimal
*   integer to standard output.  Exactly 3 characters are written with
*   leading zeros as blanks.
}
procedure wdec (                       {write byte to standard output in decimal}
  in      b: sys_int_machine_t);       {byte value in low 8 bits}
  val_param; internal;

var
  tk: string_var16_t;                  {hex string}
  stat: sys_err_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_f_int_max_base (              {make the hex string}
    tk,                                {output string}
    b & 255,                           {input integer}
    10,                                {radix}
    3,                                 {field width}
    [string_fi_unsig_k],               {the input integer is unsigned}
    stat);
  write (tk.str:tk.len);               {write the string to standard output}
  end;
{
****************************************************************************
*
*   Subroutine WPRT (B)
*
*   Show the byte value in the low 8 bits of B as a character, if it is
*   a valid character code.  If not, write a description of the code.
}
procedure wprt (                       {show printable character to standard output}
  in      b: sys_int_machine_t);       {byte value in low 8 bits}
  val_param; internal;

var
  c: sys_int_machine_t;                {character code}

begin
  c := b & 255;                        {extract the character code}

  case c of                            {check for a few special handling cases}
0: write ('NULL');
7: write ('^G bell');
10: write ('^J LF');
13: write ('^M CR');
17: write ('^Q Xon');
19: write ('^S Xoff');
27: write ('Esc');
32: write ('SP');
127: write ('DEL');
otherwise
    if c >= 33 then begin              {printable character ?}
      write (chr(c));                  {let system display the character directly}
      return;
      end;
    if (c >= 1) and (c <= 26) then begin {CTRL-letter ?}
      write ('^', chr(c+64));
      return;
      end;
    end;                               {end of special handling cases}
  end;
{
****************************************************************************
*
*   Subroutine THREAD_IN (ARG)
*
*   This routine is run in a separate thread.  It reads data bytes
*   from the input and writes information about the received
*   data to standard output.
}
procedure thread_in (                  {get data bytes from serial line}
  in      arg: sys_int_adr_t);         {unused argument}
  val_param; internal;

var
  ibuf: array [0 .. 63] of char;       {raw input buffer}
  ibufi: sys_int_machine_t;            {index of next byte to read from IBUF}
  ibufn: sys_int_adr_t;                {number of bytes left to read from IBUF}
  b: sys_int_machine_t;                {data byte value}
  tk: string_var32_t;                  {scratch token}

label
  loop;
{
******************************
*
*   Local function IBYTE
*
*   Return the next byte from the input stream.
}
function ibyte                         {return next byte from remote system}
  :sys_int_machine_t;                  {0-255 byte value}

var
  stat: sys_err_t;                     {completion status}

label
  retry;

begin
  if quit then begin                   {trying to exit the program ?}
    sys_thread_exit;
    end;

retry:                                 {back here after reading new chunk into buffer}
  if ibufn > 0 then begin              {byte is available in local buffer ?}
    ibyte := ord(ibuf[ibufi]);         {fetch the next buffer byte and return it}
    ibufi := ibufi + 1;                {advance buffer index for next time}
    ibufn := ibufn - 1;                {count one less byte left in the buffer}
    return;
    end;

  picprg_sys_usb_read (                {read next chunk of data from remote device}
    conn,                              {connection to the device}
    sizeof(ibuf),                      {max amount of data allowed to read}
    ibuf,                              {input buffer to return data in}
    ibufn,                             {number of bytes actually read}
    stat);
  if quit then begin                   {trying to exit the program ?}
    sys_thread_exit;
    end;
  sys_error_abort (stat, '', '', nil, 0);
  ibufi := 0;                          {reset to fetch from start of buffer}

  goto retry;                          {back to return byte from new chunk}
  end;
{
******************************
*
*   Executable code for subroutine THREAD_IN.
}
begin
  tk.max := size_char(tk.str);         {init local var string}
  ibufn := 0;                          {init input buffer to empty}

loop:                                  {back here each new response opcode}
  b := ibyte;                          {get response opcode byte}

  lockout;                             {acquire exclusive lock on standard output}
  whex (b);                            {show byte value in HEX}
  write (' ');
  wdec (b);                            {show byte value in decimal}
  write (' ');
  wprt (b);                            {show printable character, if possible}
  writeln;
  unlockout;

  goto loop;                           {back to read next byte from serial line}
  end;
{
****************************************************************************
*
*   Start of main routine.
}
begin
{
*   Initialize our state before reading the command line options.
}
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
    '-N',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -N name
}
1: begin
  string_cmline_token (name, stat);
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
  picprg_sys_name_open (name, conn, devconn, stat); {open connection to the device}
  sys_error_abort (stat, '', '', nil, 0);
{
*   Perform some system initialization.
}
  sys_thread_lock_create (wrlock, stat); {create interlock for writing to STDOUT}
  sys_error_abort (stat, '', '', nil, 0);

  quit := false;                       {init to not trying to exit the program}
  newline := true;                     {STDOUT is currently at start of new line}

  sys_thread_create (                  {start thread for reading serial line input}
    addr(thread_in),                   {address of thread root routine}
    0,                                 {argument passed to thread (unused)}
    thid_in,                           {returned thread ID}
    stat);
  sys_error_abort (stat, '', '', nil, 0);
{
***************************************
*
*   Process user commands.
*
*   Initialize before command processing.
}
  string_vstring (prompt, ': '(0), -1); {set command prompt string}

loop_iline:                            {back here each new input line}
  sys_wait (0.100);
  lockout;
  string_prompt (prompt);              {prompt the user for a command}
  newline := false;                    {indicate STDOUT not at start of new line}
  unlockout;

  string_readin (buf);                 {get command from the user}
  newline := true;                     {STDOUT now at start of line}
  if buf.len <= 0 then goto loop_iline; {ignore blank lines}
  p := 1;                              {init BUF parse index}
  while buf.str[p] = ' ' do begin      {skip over spaces before new token}
    if p >= buf.len then goto loop_iline; {only blanks found, ignore line ?}
    p := p + 1;                        {skip over this blank}
    end;
  obuf.len := 0;                       {init to no bytes to send from this command}
  if (buf.str[p] = '''') or (buf.str[p] = '"') {quoted string ?}
    then goto tkline;                  {this line contains data tokens}
  string_token (buf, p, opt, stat);    {get command name token into OPT}
  if string_eos(stat) then goto loop_iline; {ignore line if no command found}
  if sys_error(stat) then goto err_cmparm;
  string_t_int (opt, i1, stat);        {try to convert integer}
  if not sys_error (stat) then goto tkline; {this line contains only data tokens ?}
  sys_error_none (stat);
  string_upcase (opt);
  string_tkpick80 (opt,                {pick command name from list}
    '? HELP Q S H',
    pick);
  case pick of
{
*   HELP
}
1, 2: begin
  lockout;
  writeln;
  writeln ('? or HELP   - Show this list of commands');
  writeln ('Q           - Quit the program');
  writeln ('S chars     - Remaining characters sent as ASCII');
  writeln ('H hex ... hex - Data bytes, tokens interpreted in hexadecimal');
  writeln ('val ... val - Integer bytes or strings, strings must be quoted, "" or ''''');
  writeln ('Integer tokens have the format: [base#]value with decimal default.');
  unlockout;
  end;
{
*   Q
}
3: begin
  goto leave;
  end;
{
*   S chars
}
4: begin
  string_substr (buf, p, buf.len, obuf);
  end;
{
*   H hexval ... hexval
}
5: begin
loop_hex:                              {back here each new hex value}
  string_token (buf, p, parm, stat);   {get the next token from the command line}
  if string_eos(stat) then goto done_cmd; {exhausted the command line ?}
  string_t_int32h (parm, i1, stat);    {convert this token to integer}
  if sys_error(stat) then goto err_cmparm;
  i1 := i1 & 255;                      {force into 8 bits}
  string_append1 (obuf, chr(i1));      {one more byte to send due to this command}
  goto loop_hex;                       {back to get next command line token}
  end;
{
*   Unrecognized command.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_parms ('string', 'err_command_bad', msg_parm, 1);
    goto loop_iline;
    end;
  goto done_cmd;                       {done handling this command}
{
*   The line contains data tokens.  Process each and add the resulting bytes to OBUF.
}
tkline:
  p := 1;                              {reset to parse position to start of line}

loop_tk:                               {back here to get each new data token}
  if p > buf.len then goto done_cmd;   {exhausted command line ?}
  while buf.str[p] = ' ' do begin      {skip over spaces before new token}
    if p >= buf.len then goto done_cmd; {nothing more left on this command line ?}
    p := p + 1;                        {skip over this blank}
    end;
  if (buf.str[p] = '"') or (buf.str[p] = '''') then begin {token is a quoted string ?}
    string_token (buf, p, parm, stat); {get resulting string into PARM}
    if sys_error(stat) then goto err_cmparm;
    string_append (obuf, buf);         {add string to bytes to send}
    goto loop_tk;                      {back to get next token}
    end;

  string_token (buf, p, parm, stat);   {get this token into PARM}
  if sys_error(stat) then goto err_cmparm;
  string_t_int (parm, i1, stat);       {convert token to integer}
  if sys_error(stat) then goto err_cmparm;
  i1 := i1 & 255;                      {keep only the low 8 bits}
  string_append1 (obuf, chr(i1));
  goto loop_tk;

done_cmd:                              {done processing the current command}
  if sys_error(stat) then goto err_cmparm; {handle error, if any}
  if obuf.len > 0 then begin           {one or more bytes to send ?}
    picprg_sys_usb_write (conn, obuf.str, obuf.len, stat); {send the data bytes}
    if sys_error(stat) then goto err_cmparm;
    end;
  goto loop_iline;                     {back to process next command input line}

err_cmparm:                            {parameter error, STAT set accordingly}
  lockout;
  sys_error_print (stat, '', '', nil, 0);
  unlockout;
  goto loop_iline;

leave:
  quit := true;                        {tell all threads to shut down}
  file_close (conn);                   {close connection to the serial line}
  end.
