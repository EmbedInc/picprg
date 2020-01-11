{   Routines for handling overlapped commands.
}
module picprg_cmdovl;
define picprg_cmdovl_init;
define picprg_cmdovl_out;
define picprg_cmdovl_outw;
define picprg_cmdovl_in;
define picprg_cmdovl_flush;
%include 'picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_CMDOVL_INIT (OVL)
*
*   Initialize the overlapped commands structure OVL.  The remaining CMDOVL
*   routines can not be used on an OVL structure until it has been
*   initialized.  This routine only sets up state in OVL and does not
*   allocate any resources.
*
*   This routine must not be called with an OVL structure that is in use
*   and may have pending commands.
}
procedure picprg_cmdovl_init (         {initialize overalpped commands state}
  out     ovl: picprg_cmdovl_t);       {structure to initialize}
  val_param;

var
  i: sys_int_machine_t;                {scratch integer and loop counter}

begin
  ovl.nexto := 0;                      {init index for next descriptor for output}
  ovl.nexti := 0;                      {init index for next descriptor for input}
  for i := 0 to picprg_cmdq_last_k do begin {once for each command descriptor}
    ovl.use[i] := false;               {indicate all descriptors unused}
    end;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_CMDOVL_OUT (PR, OVL, OUT_P, STAT)
*
*   Get the next sequential overlapped command descriptor for creating a new
*   command.  OUT_P will be returned pointing to the new descriptor, which
*   will not be initialized.  OUT_P is returned NIL indicating that no new
*   descriptor was available.  When OUT_P is returned NIL, the application must
*   wait for at least one existing outstanding command to complete before a new
*   descriptor for output will be available.
}
procedure picprg_cmdovl_out (          {make a new command descriptor avail if possible}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  ovl: picprg_cmdovl_t;        {overlapped commands control structure}
  out     out_p: picprg_cmd_p_t;       {pointer to new descriptor, NIL for none}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no errors}
  out_p := nil;                        {init to no new descriptor available}

  if ovl.use[ovl.nexto] then begin     {next descriptor still in use ?}
    return;
    end;

  out_p := addr(ovl.cmd[ovl.nexto]);   {return pointer to new descriptor}
  ovl.use[ovl.nexto] := true;          {this CMD descriptor will be in use}

  ovl.nexto := ovl.nexto + 1;          {update index for next descriptor in circular queue}
  if ovl.nexto > picprg_cmdq_last_k    {wrap back to entry 0 ?}
    then ovl.nexto := 0;
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_CMDOVL_OUTW (PR, OVL, OUT_P, STAT)
*
*   Same as PICPRG_CMDOVL_OUT except that it waits as necessary for the next
*   descriptor to become free.  If a wait for a command completion is necessary,
*   any input data received by that command will be discarded.  This routine is
*   therefore only intended for sending a sequence of output-only commands.
}
procedure picprg_cmdovl_outw (         {get new command descriptor, wait as necessary}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  ovl: picprg_cmdovl_t;        {overlapped commands control structure}
  out     out_p: picprg_cmd_p_t;       {pointer to new descriptor}
  out     stat: sys_err_t);            {completion status}
  val_param;

label
  retry;

begin
retry:                                 {back here to try again to get new descriptor}
  picprg_cmdovl_out (pr, ovl, out_p, stat); {try to get next available descriptor}
  if sys_error(stat) then return;
  if out_p <> nil then return;         {successfully got descriptor ?}

  picprg_cmdovl_in (pr, ovl, out_p, stat); {wait for first command to complete}
  if sys_error(stat) then return;
  goto retry;                          {try again to get new descriptor}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_CMDOVL_IN (PR, OVL, IN_P, STAT)
*
*   Get the next sequential command queued for input.  IN_P will be returned
*   pointing to the command descriptor.  The command descriptor at IN_P will
*   be marked as available, so the application must retrieve any data it
*   cares about from that command before requesting a new output command
*   descriptor.
*
*   The command itself is not accessed in any way.  After this call, it
*   needs to be completed before the next attempt to get a new output
*   command descriptor.
}
procedure picprg_cmdovl_in (           {get next command waiting on input}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  ovl: picprg_cmdovl_t;        {overlapped commands control structure}
  out     in_p: picprg_cmd_p_t;        {pointer to next command awaiting input}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ind: sys_int_machine_t;              {index to this command descriptor}

begin
  ind := ovl.nexti;                    {get index to the next input command}
  if not ovl.use[ind] then begin       {no pending command input command ?}
    sys_stat_set (picprg_subsys_k, picprg_stat_ovlnout_k, stat);
    end;

  in_p := addr(ovl.cmd[ind]);          {get pointer to the next command}
  ovl.nexti := ovl.nexti + 1;          {advance index to next command awaiting input}
  if ovl.nexti > picprg_cmdq_last_k    {wrap back to entry 0 ?}
    then ovl.nexti := 0;
  ovl.use[ind] := false;               {indicate this descriptor no longer in use}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_CMDOVL_FLUSH (PR, OVL, STAT)
*
*   Wait for all pending commands to complete.  All input from any pending
*   commands will be discarded, so this routine is intended to be used with
*   output-only (except for ACK) commands.
*
*   All system resources allocated to the commands will be released.  OVL will
*   be returned in a valid state but with no pending commands.  PICPRG_CMDOVL_OUT
*   must be called to send any new commands.
}
procedure picprg_cmdovl_flush (        {wait for all pending commands to complete}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  ovl: picprg_cmdovl_t;        {overlapped commands structure}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  in_p: picprg_cmd_p_t;                {pointer to completed descriptor}

begin
  sys_error_none (stat);               {init to no errors}

  while ovl.use[ovl.nexti] do begin    {loop until done with all descriptors}
    picprg_cmdovl_in (pr, ovl, in_p, stat); {get pointer to next queued command}
    if sys_error(stat) then return;
    picprg_wait_cmd (pr, in_p^, stat); {wait for this command to complete}
    if sys_error(stat) then return;
    end;
  end;
