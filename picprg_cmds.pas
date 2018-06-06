{   Command sending routines.  Each routine sends the bytes of a command
*   then returns with the CMD structure for tracking the command.
}
module picprg_cmds;
define picprg_cmd_nop;
define picprg_cmd_off;
define picprg_cmd_pins;
define picprg_cmd_send1;
define picprg_cmd_send2;
define picprg_cmd_send3;
define picprg_cmd_send4;
define picprg_cmd_recv1;
define picprg_cmd_recv2;
define picprg_cmd_recv3;
define picprg_cmd_recv4;
define picprg_cmd_clkh;
define picprg_cmd_clkl;
define picprg_cmd_dath;
define picprg_cmd_datl;
define picprg_cmd_datr;
define picprg_cmd_tdrive;
define picprg_cmd_wait;
define picprg_cmd_fwinfo;
define picprg_cmd_vddvals;
define picprg_cmd_vddlow;
define picprg_cmd_vddnorm;
define picprg_cmd_vddhigh;
define picprg_cmd_vddoff;
define picprg_cmd_vppon;
define picprg_cmd_vppoff;
define picprg_cmd_vpphiz;
define picprg_cmd_idreset;
define picprg_cmd_idwrite;
define picprg_cmd_idread;
define picprg_cmd_reset;
define picprg_cmd_test1;
define picprg_cmd_test2;
define picprg_cmd_adr;
define picprg_cmd_read;
define picprg_cmd_write;
define picprg_cmd_tprog;
define picprg_cmd_spprog;
define picprg_cmd_spdata;
define picprg_cmd_incadr;
define picprg_cmd_adrinv;
define picprg_cmd_pan18;
define picprg_cmd_rbyte8;
define picprg_cmd_writing;
define picprg_cmd_fwinfo2;
define picprg_cmd_resadr;
define picprg_cmd_chkcmd;
define picprg_cmd_getpwr;
define picprg_cmd_getvdd;
define picprg_cmd_getvpp;
define picprg_cmd_waitchk;
define picprg_cmd_getbutt;
define picprg_cmd_appled;
define picprg_cmd_run;
define picprg_cmd_highz;
define picprg_cmd_ntout;
define picprg_cmd_getcap;
define picprg_cmd_w30pgm;
define picprg_cmd_r30pgm;
define picprg_cmd_datadr;
define picprg_cmd_wbufsz;
define picprg_cmd_wbufen;
define picprg_cmd_write8;
define picprg_cmd_vpp;
define picprg_cmd_gettick;
define picprg_cmd_vdd;
define picprg_cmd_nameset;
define picprg_cmd_nameget;
define picprg_cmd_reboot;
define picprg_cmd_read64;
define picprg_cmd_testget;
define picprg_cmd_testset;
define picprg_cmd_eecon1;
define picprg_cmd_eeadr;
define picprg_cmd_eeadrh;
define picprg_cmd_eedata;
define picprg_cmd_visi;
define picprg_cmd_tblpag;
define picprg_cmd_nvmcon;
define picprg_cmd_nvmkey;
define picprg_cmd_nvmadr;
define picprg_cmd_nvmadru;
define picprg_cmd_tprogf;
define picprg_cmd_ftickf;
define picprg_cmd_sendser;
define picprg_cmd_recvser;
define picprg_cmd_send8m;
define picprg_cmd_send24m;
define picprg_cmd_recv24m;

%include 'picprg2.ins.pas';
{
*******************************************************************************
}
procedure picprg_cmd_nop (             {send NOP command, just sends ACK back}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_nop_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_off (             {turn off power to target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_off_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_pins (            {get info about target chip pins}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_pins_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('PINS', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_pins_k)); {set opcode}
  cmd.recv.nresp := 1;                 {number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_send1 (           {send up to 8 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-8 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_send1_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('SEND1', stat);
    return;
    end;
  if (n < 1) or (n > 8) then begin     {invalid number bits argument ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_badnbits_k, stat);
    sys_stat_parm_int (1, stat);
    sys_stat_parm_int (8, stat);
    sys_stat_parm_int (n, stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_send1_k)); {set opcode}
  picprg_add_i8u (cmd, n - 1);         {number of data bits - 1}
  picprg_add_i8u (cmd, dat);           {the data bits}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_send2 (           {send up to 16 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-16 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_send2_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('SEND2', stat);
    return;
    end;
  if (n < 1) or (n > 16) then begin    {invalid number bits argument ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_badnbits_k, stat);
    sys_stat_parm_int (1, stat);
    sys_stat_parm_int (16, stat);
    sys_stat_parm_int (n, stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_send2_k)); {set opcode}
  picprg_add_i8u (cmd, n - 1);         {number of data bits - 1}
  picprg_add_i16u (cmd, dat);          {the data bits}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_send3 (           {send up to 24 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-24 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_send3_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('SEND3', stat);
    return;
    end;
  if (n < 1) or (n > 24) then begin    {invalid number bits argument ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_badnbits_k, stat);
    sys_stat_parm_int (1, stat);
    sys_stat_parm_int (24, stat);
    sys_stat_parm_int (n, stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_send3_k)); {set opcode}
  picprg_add_i8u (cmd, n - 1);         {number of data bits - 1}
  picprg_add_i24u (cmd, dat);          {the data bits}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_send4 (           {send up to 32 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-32 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_send4_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('SEND4', stat);
    return;
    end;
  if (n < 1) or (n > 32) then begin    {invalid number bits argument ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_badnbits_k, stat);
    sys_stat_parm_int (1, stat);
    sys_stat_parm_int (32, stat);
    sys_stat_parm_int (n, stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_send4_k)); {set opcode}
  picprg_add_i8u (cmd, n - 1);         {number of data bits - 1}
  picprg_add_i32u (cmd, dat);          {the data bits}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_recv1 (           {read up to 8 serial bits from the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-8 number of bits to read}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_recv1_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('RECV1', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_recv1_k)); {set opcode}
  cmd.recv.nresp := 1;                 {number of response bytes}
  picprg_add_i8u (cmd, n - 1);         {number of data bits - 1}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_recv2 (           {read up to 16 serial bits from the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-8 number of bits to read}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_recv2_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('RECV2', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_recv2_k)); {set opcode}
  cmd.recv.nresp := 2;                 {number of response bytes}
  picprg_add_i8u (cmd, n - 1);         {number of data bits - 1}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_recv3 (           {read up to 24 serial bits from the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-8 number of bits to read}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_recv3_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('RECV3', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_recv3_k)); {set opcode}
  cmd.recv.nresp := 3;                 {number of response bytes}
  picprg_add_i8u (cmd, n - 1);         {number of data bits - 1}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_recv4 (           {read up to 32 serial bits from the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-8 number of bits to read}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_recv4_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('RECV4', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_recv4_k)); {set opcode}
  cmd.recv.nresp := 4;                 {number of response bytes}
  picprg_add_i8u (cmd, n - 1);         {number of data bits - 1}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_clkh (            {set the serial clock line high}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_clkh_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_clkl (            {set the serial clock line low}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_clkl_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_dath (            {set the serial data line high}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_dath_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_datl (            {ste the serial data line low}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_datl_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_datr (            {read the data line as driven by the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_datr_k)); {set opcode}
  cmd.recv.nresp := 1;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_tdrive (          {test whether target is driving data line}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_tdrive_k)); {set opcode}
  cmd.recv.nresp := 1;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_wait (            {guaranteed wait before next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      t: real;                     {time to wait in seconds, clipped and rounded}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_wait_k)); {set opcode}
  picprg_add_i16u (cmd, picprg_sec_ticks(pr, t)); {pass number of time units to wait}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_fwinfo (          {get firmware version and other info}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_fwinfo_k)); {set opcode}
  cmd.recv.nresp := 8;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_vddvals (         {set target chip Vdd levels}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      vlo: real;                   {low Vdd level, volts}
  in      vnr: real;                   {normal Vdd level, volts}
  in      vhi: real;                   {high Vdd level, volts}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_vddvals_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('VDDVALS', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_vddvals_k)); {set opcode}
  picprg_add_i8u (cmd, picprg_volt_vdd(vlo)); {low Vdd level}
  picprg_add_i8u (cmd, picprg_volt_vdd(vnr)); {normal Vdd level}
  picprg_add_i8u (cmd, picprg_volt_vdd(vhi)); {high Vdd level}

  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_vddlow (          {set target Vdd to the low level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_vddlow_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('VDDLOW', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_vddlow_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_vddnorm (         {set target Vdd to the normal level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_vddnorm_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_vddhigh (         {set target Vdd to the high level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_vddhigh_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('VDDHIGH', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_vddhigh_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_vddoff (          {set target Vdd to off (0 volts)}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_vddoff_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_vppon (           {turn on target programming voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_vppon_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_vppoff (          {turn off target programming voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_vppoff_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_vpphiz (          {set Vpp line to high impedence}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_cmd_start (pr, cmd, ord(picprg_cop_vpphiz_k), stat); {fill in cmd descriptor}
  if sys_error(stat) then return;
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_idreset (         {select reset algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      id: picprg_reset_k_t;        {reset algorithm ID}
  in      offvddvpp: boolean;          {Vdd then Vpp when turn off target}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  parm: int8u_t;                       {parameter byte for IDRESET command}

begin
  if not (id in pr.fwinfo.idreset) then begin {this ID is not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_restnimp_k, stat);
    sys_stat_parm_int (ord(id), stat);
    return;
    end;

  parm := ord(id);                     {init parameter byte with reset ID field}
  if                                   {indicate Vdd off before Vpp off ?}
      offvddvpp and                    {Vdd then Vpp off order specified ?}
      (pr.fwinfo.cvlo >= 18)           {firmware supports spec version 18 or higher ?}
      then begin
    parm := parm ! 16#80;              {set high bit to indicate Vdd off before Vpp off}
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_idreset_k)); {set opcode}
  picprg_add_i8u (cmd, parm);          {parameter byte}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_idwrite (         {select write algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      id: picprg_write_k_t;        {write algorithm ID}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not (id in pr.fwinfo.idwrite) then begin {this ID is not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_writnimp_k, stat);
    sys_stat_parm_int (ord(id), stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_idwrite_k)); {set opcode}
  picprg_add_i8u (cmd, ord(id));       {ID of the selected algorithm}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_idread (          {select read algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      id: picprg_read_k_t;         {read algorithm ID}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not (id in pr.fwinfo.idread) then begin {this ID is not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_readnimp_k, stat);
    sys_stat_parm_int (ord(id), stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_idread_k)); {set opcode}
  picprg_add_i8u (cmd, ord(id));       {ID of the selected algorithm}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_reset (           {reset target chip, ready for programming}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_reset_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_test1 (           {send debugging TEST1 command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_test1_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('TEST1', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_test1_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_test2 (           {send debugging TEST2 command}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_machine_t;      {parameter byte value}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_test2_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('TEST2', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_test2_k)); {set opcode}
  picprg_add_i8u (cmd, dat);           {pass the parameter byte}
  cmd.recv.nresp := 4;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_adr (             {set address of next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: picprg_adr_t;           {target address for next operation}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_adr_k)); {set opcode}
  picprg_add_i24u (cmd, adr);          {the address}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_read (            {read from target, increment address}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_read_k)); {set opcode}
  cmd.recv.nresp := 2;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_write (           {write to target, increment address}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      dat: picprg_dat_t;           {the data to write}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_write_k)); {set opcode}
  picprg_add_i16u (cmd, dat);          {the data to write}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_write8 (          {write 8 bytes in the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      dat: univ picprg_datar_t;    {8 data words to write, only low bytes used}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_write8_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('WRITE8', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_write8_k)); {set opcode}
  for i := 0 to 7 do begin
    picprg_add_i8u (cmd, dat[i] & 255); {the data bytes}
    end;
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_tprog (           {set the programming write cycle time}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      t: real;                     {wait time in seconds}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_tprog_k)); {set opcode}
  picprg_add_i16u (cmd, picprg_sec_ticks(pr, t)); {pass the delay time}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_spprog (          {select program memory space}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_spprog_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}

  picprg_space (pr, picprg_space_prog_k); {switch library to program memory space}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_spdata (          {select data memory space}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_spdata_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}

  picprg_space (pr, picprg_space_data_k); {switch library to data memory space}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_incadr (          {increment adr for next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_incadr_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_adrinv (          {invalidate target address assumption}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_adrinv_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_pan18 (           {specialized 8 byte panel write for 18xxx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      dat: picprg_pandat8_t;       {the 8 data bytes to write}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_pan18_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('PAN18', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_pan18_k)); {set opcode}

  for i := 0 to 7 do begin             {once for each data byte}
    picprg_add_i8u (cmd, dat[i]);      {add data byte to be sent with command}
    end;

  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_rbyte8 (          {read low bytes of next 8 target words}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_rbyte8_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('RBYTE8', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_rbyte8_k)); {set opcode}
  cmd.recv.nresp := 8;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_writing (         {indicate the target is being written to}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_writing_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_fwinfo2 (         {get additional firmware info}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_fwinfo2_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('FWINFO2', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_fwinfo2_k)); {set opcode}
  cmd.recv.nresp := 1;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_resadr (          {indicate target chip address after reset}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      resadr: picprg_adr_t;        {address to assume after target chip reset}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_resadr_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('RESADR', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_resadr_k)); {set opcode}
  picprg_add_i24u (cmd, resadr);       {the address}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_chkcmd (          {check availability of a particular command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      opcode: int8u_t;             {opcode to check availability of}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_chkcmd_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('CHKCMD', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_chkcmd_k)); {set opcode}
  picprg_add_i8u (cmd, opcode);        {opcode inquiring about}
  cmd.recv.nresp := 1;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_getpwr (          {get internal power voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_getpwr_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('GETPWR', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_getpwr_k)); {set opcode}
  cmd.recv.nresp := 2;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_getvdd (          {get target chip Vdd voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_getvdd_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('GETVDD', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_getvdd_k)); {set opcode}
  cmd.recv.nresp := 2;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_getvpp (          {get target chip Vpp voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_getvpp_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('GETVPP', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_getvpp_k)); {set opcode}
  cmd.recv.nresp := 2;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_waitchk (         {wait and return completion status}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_waitchk_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('WAITCHK', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_waitchk_k)); {set opcode}
  cmd.recv.nresp := 1;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_getbutt (         {get number of button presses since start}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_getbutt_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('GETBUTT', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_getbutt_k)); {set opcode}
  cmd.recv.nresp := 1;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_appled (          {configure display of App LED}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      bri1: sys_int_machine_t;     {0-15 brightness for phase 1}
  in      t1: real;                    {phase 1 display time, seconds}
  in      bri2: sys_int_machine_t;     {0-15 brightness for phase 2}
  in      t2: real;                    {phase 2 display time, seconds}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  b1, b2: sys_int_machine_t;           {sanitized 0-15 brightness levels}
  t: real;                             {sanitized phase time}

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_appled_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('APPLED', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_appled_k)); {set opcode}

  b1 := max(0, min(15, bri1));         {brightness levels clipped to valid range}
  b2 := max(0, min(15, bri2));
  picprg_add_i8u (cmd, b1 ! lshft(b2, 4)); {brightness values byte}

  t := max(1.0, min(255.0, t1 / 0.005));
  picprg_add_i8u (cmd, trunc(t + 0.5)); {phase 1 time in integer units of 5mS}

  t := max(1.0, min(255.0, t2 / 0.005));
  picprg_add_i8u (cmd, trunc(t + 0.5)); {phase 2 time in integer units of 5mS}

  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_run (             {allow target PIC to run}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      v: real;                     {volts Vdd, 0 = high impedence}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_run_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('RUN', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_run_k)); {set opcode}

  if v <= 0.0
    then begin                         {set Vdd to high impedence}
      i := 0;
      end
    else begin                         {drive Vdd to a specific voltage}
      i := picprg_volt_vdd (v);
      i := max(1, i);                  {at least 1 to not indicate high impedence}
      end
    ;
  picprg_add_i8u (cmd, i);             {Vdd level byte}

  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_highz (           {set target lines to high impedence}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_highz_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('HIGHZ', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_highz_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_ntout (           {disable host timeout until next command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_ntout_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('NTOUT', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_ntout_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_getcap (          {get info about a programmer capability}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      id: picprg_pcap_k_t;         {ID of capability inquiring about}
  in      dat: sys_int_machine_t;      {0-255 parameter for the specific capability}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_getcap_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('GETCAP', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_getcap_k)); {set opcode}
  picprg_add_i8u (cmd, ord(id));       {ID of capability inquiring about}
  picprg_add_i8u (cmd, dat);           {data parameter for this ID}
  cmd.recv.nresp := 1;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_w30pgm (          {write 4 words to dsPIC program memory}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      w0, w1, w2, w3: sys_int_conv24_t; {the four 24-bit words}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_w30pgm_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('W30PGM', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_w30pgm_k)); {set opcode}
  picprg_add_i24u (cmd, w0);
  picprg_add_i24u (cmd, w1);
  picprg_add_i24u (cmd, w2);
  picprg_add_i24u (cmd, w3);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_r30pgm (          {read 2 words from dsPIC program memory}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_r30pgm_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('R30PGM', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_r30pgm_k)); {set opcode}
  cmd.recv.nresp := 6;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_datadr (          {set data EEPROM mapping start}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: picprg_adr_t;           {address where start of EEPROM is mapped}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_datadr_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('DATADR', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_datadr_k)); {set opcode}
  picprg_add_i24u (cmd, adr);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_wbufsz (          {indicate size of target chip write buffer}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      sz: sys_int_machine_t;       {write buffer size in target address units}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_wbufsz_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('WBUFSZ', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_wbufsz_k)); {set opcode}
  picprg_add_i8u (cmd, sz);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_wbufen (          {write buffer coverage last address}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: picprg_adr_t;           {last address that uses write buffer method}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_wbufen_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('WBUFEN', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_wbufen_k)); {set opcode}
  picprg_add_i24u (cmd, adr);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_vpp (             {set Vpp level for when Vpp is enabled}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      vpp: real;                   {desired Vpp level}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ival: sys_int_machine_t;             {integer Vpp value}

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_vpp_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('VPP', stat);
    return;
    end;

  if (vpp < pr.fwinfo.vppmin) or (vpp > pr.fwinfo.vppmax) then begin {out of range ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_vppor_k, stat);
    sys_stat_parm_real (vpp, stat);
    sys_stat_parm_real (pr.fwinfo.vppmin, stat);
    sys_stat_parm_real (pr.fwinfo.vppmax, stat);
    return
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_vpp_k)); {set opcode}
  ival := trunc((vpp * 255.0 / 20.0) + 0.5); {make integer Vpp value}
  picprg_add_i8u (cmd, ival);          {add it to the command}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_gettick (         {get programmer clock tick period}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_gettick_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('GETTICK', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_gettick_k)); {set opcode}
  cmd.recv.nresp := 2;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_vdd (             {set single Vdd level next time enabled}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      vdd: real;                   {desired Vdd level, volts}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ival: sys_int_machine_t;             {integer vdd value}

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_vdd_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('VDD', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_vdd_k)); {set opcode}
  ival := picprg_volt_vdd (vdd);       {make integer Vdd value}
  picprg_add_i8u (cmd, ival);          {add it to the command}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_nameset (         {set user-definable name of this unit}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      name: univ string_var_arg_t; {new name}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  len: sys_int_machine_t;              {length of string to send}
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_nameset_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('NAMESET', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_nameset_k)); {set opcode}
  len := min(255, name.len);           {make length of the string to send}
  picprg_add_i8u (cmd, len);           {add string length byte}
  for i := 1 to len do begin
    picprg_add_i8u (cmd, ord(name.str[i])); {add this string character}
    end;
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_nameget (         {get user-definable name of this unit}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_nameget_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('NAMEGET', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_nameget_k)); {set opcode}
  cmd.recv.lenby := 1;                 {response byte that indicates remaining length}
  cmd.recv.nresp := 1;                 {number of fixed response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_reboot (          {restart control processor}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_reboot_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('REBOOT', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_reboot_k)); {set opcode}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_read64 (          {read block of 64 data words}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_read64_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('READ64', stat);
    return;
    end;

  picprg_init_cmd (cmd);               {initialize command descriptor}
  picprg_add_i8u (cmd, ord(picprg_cop_read64_k)); {set opcode}
  cmd.recv.nresp := 128;               {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_testget (         {get the test mode setting}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_testget_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('TESTGET', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_testget_k), stat);
  if sys_error(stat) then return;
  picprg_cmd_expect (cmd, 1, 0);       {indicate response expected}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_testset (         {set new test mode}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      tmode: sys_int_machine_t;    {ID of new test mode to set}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_testset_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('TESTSET', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_testset_k), stat);
  if sys_error(stat) then return;
  picprg_add_i8u (cmd, tmode);         {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_eecon1 (          {indicate address of EECON1 register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_eecon1_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('EECON1', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_eecon1_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, adr);          {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_eeadr (           {indicate address of EEADR register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_eeadr_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('EEADR', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_eeadr_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, adr);          {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_eeadrh (          {indicate address of EEADRH register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_eeadrh_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('EEADRH', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_eeadrh_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, adr);          {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_eedata (          {indicate address of EEDATA register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_eedata_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('EEDATA', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_eedata_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, adr);          {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_visi (            {indicate address of VISI register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_visi_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('VISI', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_visi_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, adr);          {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_tblpag (          {indicate address of TBLPAG register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_tblpag_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('TBLPAG', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_tblpag_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, adr);          {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_nvmcon (          {indicate address of NVMCON register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_nvmcon_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('NVMCON', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_nvmcon_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, adr);          {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_nvmkey (          {indicate address of NVMKEY register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_nvmkey_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('NVMKEY', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_nvmkey_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, adr);          {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_nvmadr (          {indicate address of NVMADR register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_nvmadr_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('NVMADR', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_nvmadr_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, adr);          {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_nvmadru (         {indicate address of NVMADRU register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_nvmadru_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('NVMADRU', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_nvmadru_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, adr);          {set the data bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_tprogf (          {set programming time in fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      ticks: sys_int_machine_t;    {prog time in fast ticks, clipped to 65535}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_tprogf_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('TPROGF', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_tprogf_k), stat);
  if sys_error(stat) then return;
  picprg_add_i16u (cmd, min(ticks, 65535)); {number of fast ticks}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_ftickf (          {get frequency of fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_ftickf_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('FTICKF', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_ftickf_k), stat);
  if sys_error(stat) then return;
  cmd.recv.nresp := 4;                 {set number of response bytes}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_sendser (         {send bytes out the serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      nbytes: sys_int_machine_t;   {number of bytes to send, 1-256}
  in      dat: univ picprg_bytes_t;    {the bytes to send}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ii: sys_int_machine_t;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_sendser_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('SENDSER', stat);
    return;
    end;
  if (nbytes < 1) or (nbytes > 256) then begin {invalid number of bytes ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_badnbytes_k, stat);
    sys_stat_parm_int (nbytes, stat);
    sys_stat_parm_int (1, stat);
    sys_stat_parm_int (256, stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_sendser_k), stat);

  if sys_error(stat) then return;
  picprg_add_i8u (cmd, nbytes - 1);    {number of data bytes - 1}
  for ii := 1 to nbytes do begin       {copy the data bytes}
    picprg_add_i8u (cmd, dat[ii-1]);
    end;
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_recvser (         {get unread bytes from serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_recvser_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('RECVSER', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_recvser_k), stat);
  cmd.recv.nresp := 1;                 {set number of fixed response bytes}
  cmd.recv.lenby := 1;                 {index of length byte for variable-length data}
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_send8m (          {send 8 bits to target, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      dat: sys_int_conv32_t;       {the data bits to send, MSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_send8m_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('SEND8M', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_send8m_k), stat);
  picprg_add_i8u (cmd, dat);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_send24m (         {send 24 bits to target, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      dat: sys_int_conv32_t;       {the data bits to send, MSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_send24m_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('SEND24M', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_send24m_k), stat);
  picprg_add_i24u (cmd, dat);
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
{
*******************************************************************************
}
procedure picprg_cmd_recv24m (         {read 24 bits from the target, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if not pr.fwinfo.cmd[ord(picprg_cop_recv24m_k)] then begin {cmd not implemented ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_cmdnimp_k, stat);
    sys_stat_parm_str ('RECV24M', stat);
    return;
    end;

  picprg_cmd_start (pr, cmd, ord(picprg_cop_recv24m_k), stat);
  cmd.recv.nresp := 3;
  picprg_send_cmd (pr, cmd, stat);     {send the command}
  end;
