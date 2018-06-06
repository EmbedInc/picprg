{   Blocking command routines.  Each of these routines sends a command to
*   the remote unit and waits for the complete response to be received.
}
module picprg_cmdw;
define picprg_cmdw_nop;
define picprg_cmdw_off;
define picprg_cmdw_pins;
define picprg_cmdw_send1;
define picprg_cmdw_send2;
define picprg_cmdw_send3;
define picprg_cmdw_send4;
define picprg_cmdw_recv1;
define picprg_cmdw_recv2;
define picprg_cmdw_recv3;
define picprg_cmdw_recv4;
define picprg_cmdw_clkh;
define picprg_cmdw_clkl;
define picprg_cmdw_dath;
define picprg_cmdw_datl;
define picprg_cmdw_datr;
define picprg_cmdw_tdrive;
define picprg_cmdw_wait;
define picprg_cmdw_fwinfo;
define picprg_cmdw_fwinfo2;
define picprg_cmdw_vddvals;
define picprg_cmdw_vddlow;
define picprg_cmdw_vddnorm;
define picprg_cmdw_vddhigh;
define picprg_cmdw_vddoff;
define picprg_cmdw_vppon;
define picprg_cmdw_vppoff;
define picprg_cmdw_vpphiz;
define picprg_cmdw_idreset;
define picprg_cmdw_idwrite;
define picprg_cmdw_idread;
define picprg_cmdw_reset;
define picprg_cmdw_test1;
define picprg_cmdw_test2;
define picprg_cmdw_adr;
define picprg_cmdw_read;
define picprg_cmdw_write;
define picprg_cmdw_tprog;
define picprg_cmdw_spprog;
define picprg_cmdw_spdata;
define picprg_cmdw_incadr;
define picprg_cmdw_adrinv;
define picprg_cmdw_pan18;
define picprg_cmdw_rbyte8;
define picprg_cmdw_writing;
define picprg_cmdw_resadr;
define picprg_cmdw_chkcmd;
define picprg_cmdw_getpwr;
define picprg_cmdw_getvdd;
define picprg_cmdw_getvpp;
define picprg_cmdw_waitchk;
define picprg_cmdw_getbutt;
define picprg_cmdw_appled;
define picprg_cmdw_run;
define picprg_cmdw_highz;
define picprg_cmdw_ntout;
define picprg_cmdw_getcap;
define picprg_cmdw_w30pgm;
define picprg_cmdw_r30pgm;
define picprg_cmdw_datadr;
define picprg_cmdw_wbufsz;
define picprg_cmdw_wbufen;
define picprg_cmdw_write8;
define picprg_cmdw_vpp;
define picprg_cmdw_gettick;
define picprg_cmdw_vdd;
define picprg_cmdw_nameset;
define picprg_cmdw_nameget;
define picprg_cmdw_reboot;
define picprg_cmdw_read64;
define picprg_cmdw_testget;
define picprg_cmdw_testset;
define picprg_cmdw_eecon1;
define picprg_cmdw_eeadr;
define picprg_cmdw_eeadrh;
define picprg_cmdw_eedata;
define picprg_cmdw_visi;
define picprg_cmdw_tblpag;
define picprg_cmdw_nvmcon;
define picprg_cmdw_nvmkey;
define picprg_cmdw_nvmadr;
define picprg_cmdw_nvmadru;
define picprg_cmdw_tprogf;
define picprg_cmdw_ftickf;
define picprg_cmdw_sendser;
define picprg_cmdw_recvser;
define picprg_cmdw_send8m;
define picprg_cmdw_send24m;
define picprg_cmdw_recv24m;

%include 'picprg2.ins.pas';
{
*******************************************************************************
}
procedure picprg_cmdw_nop (            {send NOP command, just sends ACK back}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_nop (pr, cmd, stat);      {send the command}
  if sys_error(stat) then return;
  picprg_rsp_nop (pr, cmd, stat);      {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_off (            {turn off power to target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_off (pr, cmd, stat);      {send the command}
  if sys_error(stat) then return;
  picprg_rsp_off (pr, cmd, stat);      {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_pins (           {get info about target chip pins}
  in out  pr: picprg_t;                {state for this use of the library}
  out     pinfo: picprg_pininfo_t;     {returned info about target chip pins}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_pins (pr, cmd, stat);     {send the command}
  if sys_error(stat) then return;
  picprg_rsp_pins (pr, cmd, pinfo, stat); {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_send1 (          {send up to 8 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-8 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_send1 (pr, cmd, n, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_send1 (pr, cmd, stat);    {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_send2 (          {send up to 16 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-16 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_send2 (pr, cmd, n, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_send2 (pr, cmd, stat);    {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_send3 (          {send up to 24 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-24 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_send3 (pr, cmd, n, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_send3 (pr, cmd, stat);    {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_send4 (          {send up to 32 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-32 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_send4 (pr, cmd, n, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_send4 (pr, cmd, stat);    {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_recv1 (          {read up to 8 serial data bits from target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-8 number of bits to read}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_recv1 (pr, cmd, n, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_recv1 (pr, cmd, dat, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_recv2 (          {read up to 16 serial data bits from target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-16 number of bits to read}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_recv2 (pr, cmd, n, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_recv2 (pr, cmd, dat, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_recv3 (          {read up to 24 serial data bits from target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-24 number of bits to read}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_recv3 (pr, cmd, n, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_recv3 (pr, cmd, dat, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_recv4 (          {read up to 32 serial data bits from target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-32 number of bits to read}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_recv4 (pr, cmd, n, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_recv4 (pr, cmd, dat, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_clkh (           {set the serial clock line high}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_clkh (pr, cmd, stat);     {send the command}
  if sys_error(stat) then return;
  picprg_rsp_clkh (pr, cmd, stat);     {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_clkl (           {set the serial clock line low}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_clkl (pr, cmd, stat);     {send the command}
  if sys_error(stat) then return;
  picprg_rsp_clkl (pr, cmd, stat);     {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_dath (           {set the serial data line high}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_dath (pr, cmd, stat);     {send the command}
  if sys_error(stat) then return;
  picprg_rsp_dath (pr, cmd, stat);     {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_datl (           {set the serial data line low}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_datl (pr, cmd, stat);     {send the command}
  if sys_error(stat) then return;
  picprg_rsp_datl (pr, cmd, stat);     {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_datr (           {read the data line as driven by the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     high: boolean;               {TRUE if data line was high, FALSE for low}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_datr (pr, cmd, stat);     {send the command}
  if sys_error(stat) then return;
  picprg_rsp_datr (pr, cmd, high, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_tdrive (         {test whether target is driving data line}
  in out  pr: picprg_t;                {state for this use of the library}
  out     drive: boolean;              {TRUE iff target chip is driving data line}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_tdrive (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_tdrive (pr, cmd, drive, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_wait (           {guaranteed wait before next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  in      t: real;                     {time to wait in seconds, clipped and rounded}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_wait (pr, cmd, t, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_wait (pr, cmd, stat);     {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_fwinfo (         {get all firmware version and related info}
  in out  pr: picprg_t;                {state for this use of the library}
  out     org: picprg_org_k_t;         {ID of organization that created firmware}
  out     cvlo, cvhi: int8u_t;         {range of protocol versions compatible with}
  out     vers: int8u_t;               {firmware version number}
  out     info: sys_int_conv32_t;      {extra 32 bit info value}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_fwinfo (pr, cmd, stat);   {send the FWINFO command}
  if sys_error(stat) then return;
  picprg_rsp_fwinfo (pr, cmd, org, cvlo, cvhi, vers, info, stat); {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_fwinfo2 (        {get additional firmware info}
  in out  pr: picprg_t;                {state for this use of the library}
  out     fwid: int8u_t;               {firmware type ID, unique per organization}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_fwinfo2 (pr, cmd, stat);  {send the FWINFO2 command}
  if sys_error(stat) then return;
  picprg_rsp_fwinfo2 (pr, cmd, fwid, stat); {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_vddvals (        {set target chip Vdd levels}
  in out  pr: picprg_t;                {state for this use of the library}
  in      vlo: real;                   {low Vdd level, volts}
  in      vnr: real;                   {normal Vdd level, volts}
  in      vhi: real;                   {high Vdd level, volts}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_vddvals (pr, cmd, vlo, vnr, vhi, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_vddvals (pr, cmd, stat);  {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_vddlow (         {set target Vdd to the low level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_vddlow (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_vddlow (pr, cmd, stat);   {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_vddnorm (        {set target Vdd to the normal level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_vddnorm (pr, cmd, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_vddnorm (pr, cmd, stat);  {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_vddhigh (        {set target Vdd to the high level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_vddhigh (pr, cmd, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_vddhigh (pr, cmd, stat);  {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_vddoff (         {set target Vdd to off (0 volts)}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_vddoff (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_vddoff (pr, cmd, stat);   {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_vppon (          {turn on target programming voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_vppon (pr, cmd, stat);    {send the command}
  if sys_error(stat) then return;
  picprg_rsp_vppon (pr, cmd, stat);    {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_vppoff (         {turn off target programming voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_vppoff (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_vppoff (pr, cmd, stat);   {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_vpphiz (         {turn off target programming voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_vpphiz (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_vpphiz (pr, cmd, stat);   {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_idreset (        {select reset algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  in      id: picprg_reset_k_t;        {reset algorithm ID}
  in      offvddvpp: boolean;          {Vdd then Vpp when turn off target}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_idreset (pr, cmd, id, offvddvpp, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_idreset (pr, cmd, stat);  {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_idwrite (        {select write algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  in      id: picprg_write_k_t;        {write algorithm ID}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_idwrite (pr, cmd, id, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_idwrite (pr, cmd, stat);  {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_idread (         {select read algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  in      id: picprg_read_k_t;         {read algorithm ID}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_idread (pr, cmd, id, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_idread (pr, cmd, stat);   {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_reset (          {reset target chip, ready for programming}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_reset (pr, cmd, stat);    {send the command}
  if sys_error(stat) then return;
  picprg_rsp_reset (pr, cmd, stat);    {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_test1 (          {send debugging TEST1 command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_test1 (pr, cmd, stat);    {send the command}
  if sys_error(stat) then return;
  picprg_rsp_test1 (pr, cmd, stat);    {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_test2 (          {send debugging TEST2 command}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_machine_t;      {parameter byte value}
  out     b0, b1, b2, b3: sys_int_machine_t; {returned bytes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_test2 (pr, dat, cmd, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_test2 (pr, cmd, b0, b1, b2, b3, stat); {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_adr (            {set address of next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {target address for next operation}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_adr (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_adr (pr, cmd, stat);      {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_read (           {read from target, increment address}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: picprg_dat_t;           {data read from the target}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_read (pr, cmd, stat);     {send the command}
  if sys_error(stat) then return;
  picprg_rsp_read (pr, cmd, dat, stat); {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_write (          {write to target, increment address}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: picprg_dat_t;           {the data to write}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_write (pr, cmd, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_write (pr, cmd, stat);    {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_write8 (         {write 8 bytes in the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: univ picprg_datar_t;    {8 data words to write, only low bytes used}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_write8 (pr, cmd, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_write8 (pr, cmd, stat);   {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_tprog (          {set the programming write cycle time}
  in out  pr: picprg_t;                {state for this use of the library}
  in      t: real;                     {wait time in seconds}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_tprog (pr, cmd, t, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_tprog (pr, cmd, stat);    {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_spprog (         {select program memory space}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_spprog (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_spprog (pr, cmd, stat);   {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_spdata (         {select data memory space}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_spdata (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_spdata (pr, cmd, stat);   {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_incadr (         {increment adr for next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_incadr (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_incadr (pr, cmd, stat);   {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_adrinv (         {invalidate target address assumption}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_adrinv (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_adrinv (pr, cmd, stat);   {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_pan18 (          {specialized 8 byte panel write for 18xxx}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: picprg_pandat8_t;       {the 8 data bytes to write}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_pan18 (pr, cmd, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_pan18 (pr, cmd, stat);    {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_rbyte8 (         {read low bytes of next 8 target words}
  in out  pr: picprg_t;                {state for this use of the library}
  out     buf: univ picprg_8byte_t;    {returned array of 8 bytes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_rbyte8 (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_rbyte8 (pr, cmd, buf, stat); {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_writing (        {indicate the target is being written to}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_writing (pr, cmd, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_writing (pr, cmd, stat);  {get the response}
  if sys_error(stat) then return;
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_resadr (         {indicate target chip address after reset}
  in out  pr: picprg_t;                {state for this use of the library}
  in      resadr: picprg_adr_t;        {address to assume after target chip reset}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_resadr (pr, cmd, resadr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_resadr (pr, cmd, stat);   {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_chkcmd (         {check availability of a particular command}
  in out  pr: picprg_t;                {state for this use of the library}
  in      opcode: int8u_t;             {opcode to check availability of}
  out     cmdavail: boolean;           {TRUE if the command is available}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_chkcmd (pr, cmd, opcode, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_chkcmd (pr, cmd, cmdavail, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_getpwr (         {get internal power voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_getpwr (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_getpwr (pr, cmd, v, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_getvdd (         {get target chip Vdd voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_getvdd (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_getvdd (pr, cmd, v, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_getvpp (         {get target chip Vpp voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_getvpp (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_getvpp (pr, cmd, v, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_waitchk (        {wait and return completion status}
  in out  pr: picprg_t;                {state for this use of the library}
  out     flags: int8u_t;              {returned status flags}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_waitchk (pr, cmd, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_waitchk (pr, cmd, flags, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_getbutt (        {get number of button presses since start}
  in out  pr: picprg_t;                {state for this use of the library}
  out     npress: sys_int_machine_t;   {number of presses modulo 256}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_getbutt (pr, cmd, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_getbutt (pr, cmd, npress, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_appled (         {configure display of App LED}
  in out  pr: picprg_t;                {state for this use of the library}
  in      bri1: sys_int_machine_t;     {0-15 brightness for phase 1}
  in      t1: real;                    {phase 1 display time, seconds}
  in      bri2: sys_int_machine_t;     {0-15 brightness for phase 2}
  in      t2: real;                    {phase 2 display time, seconds}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_appled (pr, cmd, bri1, t1, bri2, t2, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_appled (pr, cmd, stat);   {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_run (            {allow target PIC to run}
  in out  pr: picprg_t;                {state for this use of the library}
  in      v: real;                     {volts Vdd, 0 = high impedence}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_run (pr, cmd, v, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_run (pr, cmd, stat);      {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_highz (          {set target lines to high impedence}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_highz (pr, cmd, stat);    {send the command}
  if sys_error(stat) then return;
  picprg_rsp_highz (pr, cmd, stat);    {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_ntout (          {disable host timeout until next command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_ntout (pr, cmd, stat);    {send the command}
  if sys_error(stat) then return;
  picprg_rsp_ntout (pr, cmd, stat);    {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_getcap (         {get info about a programmer capability}
  in out  pr: picprg_t;                {state for this use of the library}
  in      id: picprg_pcap_k_t;         {ID of capability inquiring about}
  in      dat: sys_int_machine_t;      {0-255 parameter for the specific capability}
  out     cap: sys_int_machine_t;      {0-255 response, 0 = default}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_getcap (pr, cmd, id, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_getcap (pr, cmd, cap, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_w30pgm (         {write 4 words to dsPIC program memory}
  in out  pr: picprg_t;                {state for this use of the library}
  in      w0, w1, w2, w3: sys_int_conv24_t; {the four 24-bit words}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_w30pgm (pr, cmd, w0, w1, w2, w3, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_w30pgm (pr, cmd, stat);   {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_r30pgm (         {read 2 words from dsPIC program memory}
  in out  pr: picprg_t;                {state for this use of the library}
  out     w0, w1: sys_int_conv24_t;    {2 program memory words read}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_r30pgm (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_r30pgm (pr, cmd, w0, w1, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_datadr (         {set data EEPROM mapping start}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {address where start of EEPROM is mapped}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_datadr (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_datadr (pr, cmd, stat);   {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_wbufsz (         {indicate size of target chip write buffer}
  in out  pr: picprg_t;                {state for this use of the library}
  in      sz: sys_int_machine_t;       {write buffer size in target address units}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_wbufsz (pr, cmd, sz, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_wbufsz (pr, cmd, stat);   {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_wbufen (         {write buffer coverage last address}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {last address that uses write buffer method}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_wbufen (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_wbufen (pr, cmd, stat);   {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_vpp (            {set Vpp level for when Vpp is enabled}
  in out  pr: picprg_t;                {state for this use of the library}
  in      vpp: real;                   {desired Vpp level}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_vpp (pr, cmd, vpp, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_vpp (pr, cmd, stat);      {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_gettick (        {get programmer clock tick period}
  in out  pr: picprg_t;                {state for this use of the library}
  out     ticksec: real;               {programmer tick period in seconds}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_gettick (pr, cmd, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_gettick (pr, cmd, ticksec, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_vdd (            {set single Vdd level next time enabled}
  in out  pr: picprg_t;                {state for this use of the library}
  in      vdd: real;                   {desired Vdd level, volts}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_vdd (pr, cmd, vdd, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_vdd (pr, cmd, stat);      {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_nameset (        {set user-definable name of this unit}
  in out  pr: picprg_t;                {state for this use of the library}
  in      name: univ string_var_arg_t; {new name}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_nameset (pr, cmd, name, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_nameset (pr, cmd, stat);  {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_nameget (        {get user-definable name of this unit}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  name: univ string_var_arg_t; {user-define name of the unit}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_nameget (pr, cmd, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_nameget (pr, cmd, name, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_reboot (         {restart control processor}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_reboot (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_reboot (pr, cmd, stat);   {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_read64 (         {read block of 64 data words}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: univ picprg_datar_t;    {returned array of 64 data words}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_read64 (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_read64 (pr, cmd, dat, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_testget (        {get the test mode setting}
  in out  pr: picprg_t;                {state for this use of the library}
  out     tmode: sys_int_machine_t;    {test mode ID}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_testget (pr, cmd, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_testget (pr, cmd, tmode, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_testset (        {set new test mode}
  in out  pr: picprg_t;                {state for this use of the library}
  in      tmode: sys_int_machine_t;    {ID of new test mode to set}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_testset (pr, cmd, tmode, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_testset (pr, cmd, stat);  {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_eecon1 (         {indicate address of EECON1 register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_eecon1 (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_eecon1 (pr, cmd, stat);   {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_eeadr (          {indicate address of EEADR register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_eeadr (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_eeadr (pr, cmd, stat);    {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_eeadrh (         {indicate address of EEADRH register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_eeadrh (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_eeadrh (pr, cmd, stat);   {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_eedata (         {indicate address of EEDATA register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_eedata (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_eedata (pr, cmd, stat);   {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_visi (           {indicate address of VISI register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_visi (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_visi (pr, cmd, stat);     {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_tblpag (         {indicate address of TBLPAG register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_tblpag (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_tblpag (pr, cmd, stat);   {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_nvmcon (         {indicate address of NVMCON register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_nvmcon (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_nvmcon (pr, cmd, stat);   {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_nvmkey (         {indicate address of NVMKEY register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_nvmkey (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_nvmkey (pr, cmd, stat);   {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_nvmadr (         {indicate address of NVMADR register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_nvmadr (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_nvmadr (pr, cmd, stat);   {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_nvmadru (        {indicate address of NVMADRU register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_nvmadru (pr, cmd, adr, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_nvmadru (pr, cmd, stat);  {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_tprogf (         {set programming time in fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  in      ticks: sys_int_machine_t;    {programming time in number of fast ticks}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_tprogf (pr, cmd, ticks, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_tprogf (pr, cmd, stat);   {wait for the command to complete}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_ftickf (         {get frequency of fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  out     freq: real;                  {fast tick frequency, Hz}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_ftickf (pr, cmd, stat);   {send the command}
  if sys_error(stat) then return;
  picprg_rsp_ftickf (pr, cmd, freq, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_sendser (        {send bytes out the serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  in      nbytes: sys_int_machine_t;   {number of bytes to send, 1-256}
  in      dat: univ picprg_bytes_t;    {the bytes to send}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_sendser (pr, cmd, nbytes, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_sendser (pr, cmd, stat);  {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_recvser (        {get unread bytes from serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  out     nbytes: sys_int_machine_t;   {number of bytes returned in DAT}
  out     dat: univ picprg_bytes_t;    {the returned data bytes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_recvser (pr, cmd, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_recvser (pr, cmd, nbytes, dat, stat); {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_send8m (         {send 8 bits to target, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_conv32_t;       {the data bits to send, MSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_send8m (pr, cmd, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_send8m (pr, cmd, stat);   {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_send24m (        {send 24 bits to target, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_conv32_t;       {the data bits to send, MSB first}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_send24m (pr, cmd, dat, stat); {send the command}
  if sys_error(stat) then return;
  picprg_rsp_send24m (pr, cmd, stat);  {get the response}
  end;
{
*******************************************************************************
}
procedure picprg_cmdw_recv24m (        {read 24 bits from the target, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: sys_int_conv32_t;       {returned bits, received MSB to LSB order}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  cmd: picprg_cmd_t;                   {info about the command being sent}

begin
  picprg_cmd_recv24m (pr, cmd, stat);  {send the command}
  if sys_error(stat) then return;
  picprg_rsp_recv24m (pr, cmd, dat, stat); {get the response}
  end;
