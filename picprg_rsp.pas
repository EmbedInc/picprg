{   Routines that wait for the response from a command and return the
*   values from any response data.  The command descriptor is also
*   closed out and resources released.  It can be re-used after one of
*   these calls.
}
module picprg_rsp;
define picprg_rsp_nop;
define picprg_rsp_off;
define picprg_rsp_pins;
define picprg_rsp_send1;
define picprg_rsp_send2;
define picprg_rsp_send3;
define picprg_rsp_send4;
define picprg_rsp_recv1;
define picprg_rsp_recv2;
define picprg_rsp_recv3;
define picprg_rsp_recv4;
define picprg_rsp_clkh;
define picprg_rsp_clkl;
define picprg_rsp_dath;
define picprg_rsp_datl;
define picprg_rsp_datr;
define picprg_rsp_tdrive;
define picprg_rsp_wait;
define picprg_rsp_fwinfo;
define picprg_rsp_vddvals;
define picprg_rsp_vddlow;
define picprg_rsp_vddnorm;
define picprg_rsp_vddhigh;
define picprg_rsp_vddoff;
define picprg_rsp_vppon;
define picprg_rsp_vppoff;
define picprg_rsp_vpphiz;
define picprg_rsp_idreset;
define picprg_rsp_idwrite;
define picprg_rsp_idread;
define picprg_rsp_reset;
define picprg_rsp_test1;
define picprg_rsp_test2;
define picprg_rsp_adr;
define picprg_rsp_read;
define picprg_rsp_write;
define picprg_rsp_tprog;
define picprg_rsp_spprog;
define picprg_rsp_spdata;
define picprg_rsp_incadr;
define picprg_rsp_adrinv;
define picprg_rsp_pan18;
define picprg_rsp_rbyte8;
define picprg_rsp_writing;
define picprg_rsp_fwinfo2;
define picprg_rsp_resadr;
define picprg_rsp_chkcmd;
define picprg_rsp_getpwr;
define picprg_rsp_getvdd;
define picprg_rsp_getvpp;
define picprg_rsp_waitchk;
define picprg_rsp_getbutt;
define picprg_rsp_appled;
define picprg_rsp_run;
define picprg_rsp_highz;
define picprg_rsp_ntout;
define picprg_rsp_getcap;
define picprg_rsp_w30pgm;
define picprg_rsp_r30pgm;
define picprg_rsp_datadr;
define picprg_rsp_wbufsz;
define picprg_rsp_wbufen;
define picprg_rsp_write8;
define picprg_rsp_vpp;
define picprg_rsp_gettick;
define picprg_rsp_vdd;
define picprg_rsp_nameset;
define picprg_rsp_nameget;
define picprg_rsp_reboot;
define picprg_rsp_read64;
define picprg_rsp_testget;
define picprg_rsp_testset;
define picprg_rsp_eecon1;
define picprg_rsp_eeadr;
define picprg_rsp_eeadrh;
define picprg_rsp_eedata;
define picprg_rsp_visi;
define picprg_rsp_tblpag;
define picprg_rsp_nvmcon;
define picprg_rsp_nvmkey;
define picprg_rsp_nvmadr;
define picprg_rsp_nvmadru;
define picprg_rsp_tprogf;
define picprg_rsp_ftickf;
define picprg_rsp_sendser;
define picprg_rsp_recvser;
define picprg_rsp_send8m;
define picprg_rsp_send24m;
define picprg_rsp_recv24m;

%include 'picprg2.ins.pas';
{
*******************************************************************************
}
procedure picprg_rsp_nop (             {wait for NOP command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_nop_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('NOP', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_off (             {wait for OFF command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_off_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('OFF', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_pins (            {wait for PINS command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     pinfo: picprg_pininfo_t;     {returned info about target chip pins}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_pins_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('PINS', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}

  pinfo := [];                         {init all returned flags to off}
  if (cmd.recv.buf[1] & 1) <> 0
    then pinfo := pinfo + [picprg_pininfo_le18_k];
  end;
{
*******************************************************************************
}
procedure picprg_rsp_send1 (           {wait for SEND1 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_send1_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('SEND1', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_send2 (           {wait for SEND2 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_send2_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('SEND2', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_send3 (           {wait for SEND3 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_send3_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('SEND3', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_send4 (           {wait for SEND4 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_send4_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('SEND4', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_recv1 (           {wait for RECV1 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_recv1_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('RECV1', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}

  dat := cmd.recv.buf[1];
  end;
{
*******************************************************************************
}
procedure picprg_rsp_recv2 (           {wait for RECV2 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_recv2_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('RECV2', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}

  dat :=
    cmd.recv.buf[1] !
    lshft(cmd.recv.buf[2], 8);
  end;
{
*******************************************************************************
}
procedure picprg_rsp_recv3 (           {wait for RECV3 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_recv3_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('RECV3', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}

  dat :=
    cmd.recv.buf[1] !
    lshft(cmd.recv.buf[2], 8) !
    lshft(cmd.recv.buf[3], 16);
  end;
{
*******************************************************************************
}
procedure picprg_rsp_recv4 (           {wait for RECV4 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_recv4_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('RECV4', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}

  dat :=
    cmd.recv.buf[1] !
    lshft(cmd.recv.buf[2], 8) !
    lshft(cmd.recv.buf[3], 16) !
    lshft(cmd.recv.buf[4], 24);
  end;
{
*******************************************************************************
}
procedure picprg_rsp_clkh (            {wait for CLKH command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_clkh_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('CLKH', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_clkl (            {wait for CLKL command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_clkl_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('CLKL', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_dath (            {wait for DATH command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_dath_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('DATH', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_datl (            {wait for DATL command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_datl_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('DATL', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_datr (            {wait for DATR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     high: boolean;               {TRUE if data line was high, FALSE for low}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_datr_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('DATR', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  high := cmd.recv.buf[1] <> 0;
  end;
{
*******************************************************************************
}
procedure picprg_rsp_tdrive (          {wait for TDRIVE command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     drive: boolean;              {TRUE iff target chip is driving data line}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_tdrive_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('TDRIVE', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  drive := cmd.recv.buf[1] <> 0;
  end;
{
*******************************************************************************
}
procedure picprg_rsp_wait (            {wait for WAIT command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_wait_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('WAIT', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_fwinfo (          {wait for FWINFO command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     org: picprg_org_k_t;         {ID of organization that created firmware}
  out     cvlo, cvhi: int8u_t;         {range of protocol versions compatible with}
  out     vers: int8u_t;               {firmware version number}
  out     info: sys_int_conv32_t;      {extra 32 bit info value}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_fwinfo_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('FWINFO', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  org := picprg_org_k_t(cmd.recv.buf[1]);
  cvlo := cmd.recv.buf[2];
  cvhi := cmd.recv.buf[3];
  vers := cmd.recv.buf[4];
  info :=
    cmd.recv.buf[5] !
    lshft(cmd.recv.buf[6], 8) !
    lshft(cmd.recv.buf[7], 16) !
    lshft(cmd.recv.buf[8], 24);
  end;
{
*******************************************************************************
}
procedure picprg_rsp_vddvals (         {wait for VDDVALS command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_vddvals_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VDDVALS', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_vddlow (          {wait for VDDLOW command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_vddlow_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VDDLOW', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_vddnorm (         {wait for VDDNORM command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_vddnorm_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VDDNORM', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_vddhigh (         {wait for VDDHIGH command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_vddhigh_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VDDHIGH', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_vddoff (          {wait for VDDOFF command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_vddoff_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VDDOFF', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_vppon (           {wait for VPPON command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_vppon_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VPPON', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_vppoff (          {wait for VPPOFF command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_vppoff_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VPPOFF', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_vpphiz (          {wait for VPPHIZ command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_vpphiz_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VPPHIZ', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_idreset (         {wait for IDRESET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_idreset_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('IDRESET', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_idwrite (         {wait for IDWRITE command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_idwrite_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('WRITE', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_idread (          {wait for IDREAD command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_idread_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('IDREAD', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_reset (           {wait for RESET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_reset_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('RESET', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_test1 (           {wait for TEST1 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_test1_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('TEST1', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_test2 (           {wait for TEST2 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     b0, b1, b2, b3: sys_int_machine_t; {returned bytes}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_test2_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('TEST2', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  b0 := cmd.recv.buf[1];
  b1 := cmd.recv.buf[2];
  b2 := cmd.recv.buf[3];
  b3 := cmd.recv.buf[4];
  end;
{
*******************************************************************************
}
procedure picprg_rsp_adr (             {wait for ADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_adr_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('ADR', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_read (            {wait for READ command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: picprg_dat_t;           {data read from the target}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_read_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('READ', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  dat := lshft(cmd.recv.buf[2], 8) ! cmd.recv.buf[1]; {return the data value}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_write (           {wait for WRITE command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_write_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('WRITE', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_write8 (          {wait for WRITE8 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_write8_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('WRITE8', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_tprog (           {wait for TPROG command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_tprog_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('TPROG', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_spprog (          {wait for SPPROG command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_spprog_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('SPPROG', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_spdata (          {wait for SPDATA command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_spdata_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('SPDATA', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_incadr (          {wait for INCADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_incadr_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('INCADR', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_adrinv (          {wait for ADRINV command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_adrinv_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('ADRINV', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_pan18 (           {wait for PAN18 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_pan18_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('PAN18', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_rbyte8 (          {wait for RBYTE8 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     buf: univ picprg_8byte_t;    {returned array of 8 bytes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}

begin
  if cmd.send.buf[1] <> ord(picprg_cop_rbyte8_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('RBYTE8', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}

  for i := 0 to 7 do begin             {once for each byte to return}
    buf[i] := cmd.recv.buf[i+1];       {copy this byte into return argument}
    end;
  end;
{
*******************************************************************************
}
procedure picprg_rsp_writing (         {wait for WRITING command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_writing_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('WRITING', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_fwinfo2 (         {wait for FWINFO2 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     fwid: int8u_t;               {firmware type ID, unique per organization}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_fwinfo2_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('FWINFO2', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  fwid := cmd.recv.buf[1];             {firmware type ID}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_resadr (          {wait for RESADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_resadr_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('RESADR', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_chkcmd (          {wait for CHKCMD command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     cmdavail: boolean;           {TRUE if the command is available}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_chkcmd_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('CHKCMD', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}

  cmdavail := cmd.recv.buf[1] <> 0;
  end;
{
*******************************************************************************
}
procedure picprg_rsp_getpwr (          {wait for GETPWR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_getpwr_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('GETPWR', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  v := ((cmd.recv.buf[2] * 256) + cmd.recv.buf[1]) / 1000.0;
  end;
{
*******************************************************************************
}
procedure picprg_rsp_getvdd (          {wait for GETVDD command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_getvdd_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('GETVDD', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  v := ((cmd.recv.buf[2] * 256) + cmd.recv.buf[1]) / 1000.0;
  end;
{
*******************************************************************************
}
procedure picprg_rsp_getvpp (          {wait for GETVPP command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_getvpp_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('GETVPP', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  v := ((cmd.recv.buf[2] * 256) + cmd.recv.buf[1]) / 1000.0;
  end;
{
*******************************************************************************
}
procedure picprg_rsp_waitchk (         {wait for WAITCHK command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     flags: int8u_t;              {returned status flags}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_waitchk_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('WAITCHK', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  flags := cmd.recv.buf[1];
  end;
{
*******************************************************************************
}
procedure picprg_rsp_getbutt (         {wait for GETBUTT command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     npress: sys_int_machine_t;   {number of presses modulo 256}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_getbutt_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('GETBUTT', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  npress := cmd.recv.buf[1];
  end;
{
*******************************************************************************
}
procedure picprg_rsp_appled (          {wait for APPLED command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_appled_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('APPLED', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_run (             {wait for RUN command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_run_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('RUN', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_highz (           {wait for HIGHZ command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_highz_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('HIGHZ', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_ntout (           {wait for NTOUT command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_ntout_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('NTOUT', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_getcap (          {wait for GETCAP command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     cap: sys_int_machine_t;      {0-255 response, 0 = default}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_getcap_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('GETCAP', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  cap := cmd.recv.buf[1];
  end;
{
*******************************************************************************
}
procedure picprg_rsp_w30pgm (          {wait for W30PGM command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_w30pgm_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('W30PGM', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_r30pgm (          {wait for R30PGM command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     w0, w1: sys_int_conv24_t;    {2 program memory words read}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_r30pgm_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('R30PGM', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  w0 :=
    cmd.recv.buf[1] !
    (lshft(cmd.recv.buf[2], 8)) !
    (lshft(cmd.recv.buf[3], 16));
  w1 :=
    cmd.recv.buf[4] !
    (lshft(cmd.recv.buf[5], 8)) !
    (lshft(cmd.recv.buf[6], 16));
  end;
{
*******************************************************************************
}
procedure picprg_rsp_datadr (          {wait for DATADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_datadr_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('DATADR', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_wbufsz (          {wait for WBUFSZ command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_wbufsz_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('WBUFSZ', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_wbufen (          {wait for WBUFEN command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_wbufen_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('WBUFEN', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_vpp (             {wait for VPP command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_vpp_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VPP', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_gettick (         {wait for GETTICK command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     ticksec: real;               {programmer tick period in seconds}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_gettick_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('GETTICK', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  i := lshft(cmd.recv.buf[2], 8) ! cmd.recv.buf[1]; {assemble 16 bit return value}
  ticksec := i * 100.0e-9;             {convert from units of 100nS}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_vdd (             {wait for VDD command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_vdd_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VDD', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_nameset (         {wait for NAMESET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_nameset_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('NAMESET', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_nameget (         {wait for NAMEGET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  in out  name: univ string_var_arg_t; {user-define name of the unit}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}

begin
  if cmd.send.buf[1] <> ord(picprg_cop_nameget_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('NAMEGET', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  name.len := min(name.max, cmd.recv.buf[1]); {make returned string length}
  for i := 1 to name.len do begin      {once for each character}
    name.str[i] := chr(cmd.recv.buf[i+1]);
    end;
  end;
{
*******************************************************************************
}
procedure picprg_rsp_reboot (          {wait for REBOOT command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_reboot_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('reboot', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_read64 (          {wait for READ64 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     dat: univ picprg_datar_t;    {returned array of 64 data words}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}

begin
  if cmd.send.buf[1] <> ord(picprg_cop_read64_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('READ64', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  for i := 0 to 63 do begin            {once for each returned data word}
    dat[i] := cmd.recv.buf[i*2+1] ! lshft(cmd.recv.buf[i*2+2], 8); {get this data word}
    end;                               {back to get and return next data word}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_testget (         {wait for TESTGET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     tmode: sys_int_machine_t;    {test mode ID}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_testget_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('TESTGET', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  if sys_error(stat) then return;

  tmode := cmd.recv.buf[1];
  end;
{
*******************************************************************************
}
procedure picprg_rsp_testset (         {wait for TESTSET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_testset_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('TESTSET', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_eecon1 (          {wait for EECON1 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_eecon1_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('EECON1', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_eeadr (           {wait for EEADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_eeadr_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('EEADR', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_eeadrh (          {wait for EEADRH command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_eeadrh_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('EEADRH', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_eedata (          {wait for EEDATA command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_eedata_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('EEDATA', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_visi (            {wait for VISI command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_visi_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('VISI', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_tblpag (          {wait for TBLPAG command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_tblpag_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('TBLPAG', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_nvmcon (          {wait for NVMCON command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_nvmcon_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('NVMCON', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_nvmkey (          {wait for NVMKEY command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_nvmkey_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('NVMKEY', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_nvmadr (          {wait for NVMADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_nvmadr_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('NVMADR', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_nvmadru (         {wait for NVMADRU command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_nvmadru_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('NVMADRU', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_tprogf (          {set programming time in fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_tprogf_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('TPROGF', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_ftickf (          {get frequency of fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     freq: real;                  {fast tick frequency, Hz}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ii: sys_int_min32_t;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_ftickf_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('FTICKF', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}

  ii :=
    cmd.recv.buf[1] !
    lshft(cmd.recv.buf[2], 8) !
    lshft(cmd.recv.buf[3], 16) !
    lshft(cmd.recv.buf[4], 24);
  freq := ii * 256.0;                  {make frequency in Hz}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_sendser (         {send bytes out the serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_sendser_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('SENDSER', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_recvser (         {get unread bytes from serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     nbytes: sys_int_machine_t;   {number of bytes returned in DAT}
  out     dat: univ picprg_bytes_t;    {the returned data bytes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ii: sys_int_min32_t;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_recvser_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('RECVSER', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}

  nbytes := cmd.recv.buf[1];           {get number of bytes}
  for ii := 1 to nbytes do begin       {copy the bytes into DAT}
    dat[ii - 1] := cmd.recv.buf[ii + 1];
    end;
  end;
{
*******************************************************************************
}
procedure picprg_rsp_send8m (          {wait for SEND8M command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_send8m_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('SEND8M', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_send24m (         {wait for SEND24M command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_send24m_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('SEND24M', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}
  end;
{
*******************************************************************************
}
procedure picprg_rsp_recv24m (         {wait for RECV24M command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: sys_int_conv32_t;       {returned bits, received MSB to LSB order}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if cmd.send.buf[1] <> ord(picprg_cop_recv24m_k) then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_wrongrsp_k, stat);
    sys_stat_parm_str ('RECV24M', stat);
    sys_stat_parm_int (cmd.send.buf[1], stat);
    return;
    end;

  picprg_wait_cmd (pr, cmd, stat);     {wait for whole response, close CMD}

  dat :=
    cmd.recv.buf[1] !
    lshft(cmd.recv.buf[2], 8) !
    lshft(cmd.recv.buf[3], 16);
  end;
