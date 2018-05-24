module picprg_prog;
define picprg_prog_hexfile;
define picprg_prog_fw;
%include 'picprg2.ins.pas';
{
********************************************************************************
*
*   Subroutine PICPRG_PROG_HEXFILE (PR, FNAM, PIC, STAT)
*
*   Programs the contents of a HEX file into the target PIC.  The connection to
*   the programmer must already be open.
*
*   FNAM is the pathname of the HEX file.  The ".hex" suffix may be omitted from
*   FNAM.
*
*   PIC is the PIC model name, like "16F876".  It is case-insensitive.  When PIC
*   is not blank, it is a error if it can be determined that the target PIC is
*   not the indicated model.  When PIC is blank, then the target type is
*   determined by reading it's ID.  This is only allowed when the target type
*   has a chip ID.  Note that the 12 bit core parts generally do not have a
*   chip ID, and the target type therefore can't be automatically determined.
*
*   FLAGS is a set of optional flags that can modify the default behavior of the
*   programming operation.
}
procedure picprg_prog_hexfile (        {program HEX file into traget PIC}
  in out  pr: picprg_t;                {state for this use of the library}
  in      fnam: univ string_var_arg_t; {pathname of the HEX file}
  in      pic: univ string_var_arg_t;  {PIC model like "16F876", case insensitive}
  in      flags: picprg_progflags_t;   {set of option flags}
  out     stat: sys_err_t);            {completion status}
  val_param;

const
  max_msg_args = 2;                    {max arguments we can pass to a message}

var
  picu: string_var32_t;                {upper case PIC name}
  ihn: ihex_in_t;                      {HEX file reading state}
  tdat_p: picprg_tdat_p_t;             {points to data for programming target PIC}
  hex_open: boolean;                   {the HEX file is open}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;
  stat2: sys_err_t;                    {to avoid corrupting STAT}

label
  leave;

begin
  picu.max := size_char(picu.str);     {init local var string}

  hex_open := false;                   {init to HEX file not open}
  tdat_p := nil;                       {init to TDAT structure not allocated}

  string_copy (pic, picu);             {make local upper case copy of PIC name}
  string_upcase (picu);                {upper case}
  picprg_config (pr, picu, stat);      {configure to the selected PIC}
  if sys_error(stat) then goto leave;

  ihex_in_open_fnam (fnam, '.hex', ihn, stat); {try to open HEX file}
  if sys_error(stat) then goto leave;
  hex_open := true;                    {indicate HEX file is now open}

  sys_msg_parm_vstr (msg_parm[1], ihn.conn_p^.tnam);
  sys_msg_parm_vstr (msg_parm[2], picu);
  sys_message_parms ('picprg', 'progging', msg_parm, 2);
  writeln;

  picprg_tdat_alloc (pr, tdat_p, stat); {allocate target data block}
  if sys_error(stat) then goto leave;
  picprg_tdat_hex_read (tdat_p^, ihn, stat); {read the data from the HEX file}
  if sys_error(stat) then goto leave;
  ihex_in_close (ihn, stat);           {close the HEX file}
  hex_open := false;                   {HEX file no longer open}
  if sys_error(stat) then goto leave;

  picprg_tdat_prog (                   {program the data into the target}
    tdat_p^,                           {info about what to program}
    flags,                             {set of option flags}
    stat);
  if sys_error(stat) then goto leave;
  picprg_tdat_dealloc (tdat_p);        {deallocate TDAT structure}

  writeln;
  sys_msg_parm_vstr (msg_parm[1], picu); {show success}
  sys_message_parms ('picprg', 'progged', msg_parm, 1);

leave:                                 {common exit, STAT indicates error, if any}
  if hex_open then begin
    ihex_in_close (ihn, stat2);        {close the HEX file}
    end;
  if tdat_p <> nil then begin
    picprg_tdat_dealloc (tdat_p);      {deallocate TDAT structure}
    end;
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_PROG_FW (PR, DIR, FWNAME, VER, PIC, STAT)
*
*   Program a particular version of firmware into the target PIC.  The
*   connection to the programmer must already be open.
*
*   DIR is the directory containing the firmware HEX file.  FWNAME is the name
*   of the firmware.
*
*   VER is the 1-N specific version number to use.  When 0, the unnumbered
*   HEX file will be used.  For example, with FWNAME "abc" and VER 5, the HEX
*   file name will be "abc05.hex".  With VER 0, the HEX file name will be
*   "abc.hex".
*
*   VER can be modified by adding constants to it.  The following constants
*   are supported:
*
*     PICPRG_PROGFW_NOVER_K
*
*       Allows use of the HEX file with no version, if the file with the version
*       does not exist.
*
*   PIC is the PIC model name, like "16F876".  It is case-insensitive.  When PIC
*   is not blank, it is a error if it can be determined that the target PIC is
*   not the indicated model.  When PIC is blank, then the target type is
*   determined by reading it's ID.  This is only allowed when the target type
*   has a chip ID.  Note that the 12 bit core parts generally do not have a
*   chip ID, and the target type therefore can't be automatically determined.
*
*   FLAGS is a set of optional flags that can modify the default behavior of the
*   programming operation.
}
procedure picprg_prog_fw (             {program particular firmware into target PIC}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dir: univ string_var_arg_t;  {directory containing HEX file}
  in      fwname: univ string_var_arg_t; {firmware name}
  in      ver: sys_int_machine_t;      {firmware version, 0 for unnumbered}
  in      pic: univ string_var_arg_t;  {PIC model like "16F876", case insensitive}
  in      flags: picprg_progflags_t;   {set of option flags}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  fnam: string_treename_t;             {name of HEX file to open}
  tk: string_var32_t;                  {scratch token}
  v: sys_int_machine_t;                {version number with flags removed}
  nover: boolean;                      {allowed to use non-version file name}
  len_nover: sys_int_machine_t;        {file name length without version number}
  ii: sys_int_machine_t;               {scratch integer}

begin
  fnam.max := size_char(fnam.str);     {init local var strings}
  tk.max := size_char(tk.str);

  v := ver & 16#FFFFFF;                {extract just the version number}
  nover := (ver & picprg_progfw_nover_k) <> 0; {allowed to use no-version file name}

  string_f_int_max_base (              {make version number string}
    tk,                                {output string}
    v,                                 {input integer}
    10,                                {radix}
    0,                                 {free format output, no fixed width}
    [string_fi_unsig_k],               {the input integer is unsigned}
    stat);
  if sys_error(stat) then return;

  string_copy (dir, fnam);             {init HEX file name to directory name}
  string_append1 (fnam, '/');
  string_append (fnam, fwname);
  len_nover := fnam.len;               {save length to just before version number}
  if v > 0 then begin                  {a specific version was specified ?}
    for ii := tk.len to 1 do begin     {add min leading zeros to version number}
      string_append1 (fnam, '0');
      end;
    string_append (fnam, tk);          {add version number string}
    end;

  picprg_prog_hexfile (                {program the HEX file data into the target}
    pr,                                {PICPRG library use state}
    fnam,                              {HEX file name}
    pic,                               {PIC model name}
    flags,                             {set of programming option flags}
    stat);
  if                                   {try again with no-version file name ?}
      file_not_found(stat) and         {versioned file does not exist ?}
      (v > 0) and                      {a specific version was specified ?}
      nover                            {allowed to use no-version file ?}
      then begin
    fnam.len := len_nover;             {remove version number}
    picprg_prog_hexfile (              {try again with no-version file name}
      pr,                              {PICPRG library use state}
      fnam,                            {HEX file name}
      pic,                             {PIC model name}
      flags,                           {set of programming option flags}
      stat);
    end;
  end;
