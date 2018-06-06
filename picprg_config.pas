module picprg_config;
define picprg_config;
define picprg_config_idb;
%include 'picprg2.ins.pas';
{
********************************************************************************
*
*   Subroutine PICPRG_CONFIG (PR, NAME, STAT)
*
*   Configure the library to the specific target chip.  NAME is the expected
*   name of the chip, which is case-insensitive.  Some very similar chips have
*   the same device ID word, like the 16F628 and 16LF628 for example.  If NAME
*   is non-blank, then it must match one of the names for the device ID.  In
*   that case, the library is configured to that particular variant.  If NAME is
*   empty, then the generic variant for that device ID is chosen.  STAT is
*   returned with an error if NAME is non-blank but does not match any of the
*   variant names for the ID word received from the target chip.
*
*   The target chip will be reset and left enabled and ready for performing
*   operations on it.
}
procedure picprg_config (              {configure library for specific target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  in      name: univ string_var_arg_t; {expected name, blank gets default for ID}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  id: picprg_chipid_t;                 {device ID word read from the target chip}
  idspace: picprg_idspace_k_t;         {device ID word name space}
  id_p: picprg_idblock_p_t;            {env info about one device ID}
  name_p: picprg_idname_p_t;           {pointer to info for a specific variant}
  uname: string_var32_t;               {upper case expected name}

label
  next_id, found, have_name, done_name;

begin
  uname.max := size_char(uname.str);   {init local var string}

  id_p := nil;                         {init to no specific chip identified}
  name_p := nil;
  if name.len > 0 then goto have_name; {already know the PIC supposed to be there ?}
{
******************************
*
*   No name was provided.  Try to read the chip ID to figure out what PIC it is.
}
  picprg_id (pr, id_p, idspace, id, stat); {try to get target PIC ID}
  if sys_error(stat) then return;
  if                                   {couldn't uniquely determine target chip ?}
      (id = 0) or                      {no chip ID read ?}
      (idspace = picprg_idspace_unk_k) {ID namespace not known ?}
      then begin
    sys_stat_set (picprg_subsys_k, picprg_stat_noid_k, stat);
    return;
    end;

  pr.id := id;                         {save actual target chip ID, including rev}
{
*   Search the environment information for the particular device ID word.
}
  id_p := pr.env.idblock_p;            {init to first ID block in the list}
  while id_p <> nil do begin           {loop thru the ID blocks}
    if id_p^.idspace <> idspace then goto next_id; {ID name space doesn't match ?}
    if (xor(id, id_p^.id) & id_p^.mask) = 0 then goto found; {found matching block ?}
next_id:                               {skip here to advance to next ID block}
    id_p := id_p^.next_p;              {advance to next ID block in the list}
    end;                               {back to check this new ID block}

  sys_stat_set (picprg_subsys_k, picprg_stat_idnmatch_k, stat); {no match found}
  sys_stat_parm_int (id, stat);        {pass the ID value}
  return;

found:                                 {ID_P is pointing to ID block for this PIC}
  name_p := id_p^.name_p;              {use first name in this ID block}

  picprg_config_idb (pr, id_p^, name_p^, stat); {configure to the selected target}
  return;
{
******************************
*
*   NAME contains the explicit name of the PIC that is supposed to be out there.
}
have_name:
{
*   Find the ID block for the chip with name NAME.
}
  string_copy (name, uname);           {make local upper case copy of chip name}
  string_upcase (uname);
  id_p := pr.env.idblock_p;            {init pointer to first ID block in list}

  while id_p <> nil do begin           {scan thru the list entries}
    name_p := id_p^.name_p;            {init pointer to first name for this block}
    while name_p <> nil do begin       {scan the names for this ID block}
      if string_equal(uname, name_p^.name) then goto done_name; {found it ?}
      name_p := name_p^.next_p;        {advance to next name for this ID block}
      end;                             {back to check this new name}
    id_p := id_p^.next_p;              {advance to next ID block in list}
    end;                               {back to check this new ID block}

  sys_stat_set (picprg_subsys_k, picprg_stat_namenf_k, stat);
  sys_stat_parm_vstr (uname, stat);
  return;                              {return with name not found error}
done_name:                             {ID_P is pointing to ID block of selected PIC}

  picprg_id (pr, id_p, idspace, id, stat); {verify ID if possible, get exact ID}
  if sys_error(stat) then return;
  pr.id := id;                         {save actual target chip ID, including rev}
  picprg_reset (pr, stat);             {reset the chip and all optional state}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_CONFIG_IDB (PR, IDB, IDNAME, STAT)
*
*   Configure the PICPRG library and the remote unit for the specific target PIC
*   described in the ID block IDB.  IDNAME must be the ID name descriptor
*   associated with this ID block of the particular variant to configure to.
*   The target chip will be reset and the target Vdd will be set to the normal
*   level for this chip.  The target will be left ready for performing
*   operations on it.
}
procedure picprg_config_idb (          {configure to target described in ID block}
  in out  pr: picprg_t;                {state for this use of the library}
  in      idb: picprg_idblock_t;       {ID block of target to configure to}
  in      idname: picprg_idname_t;     {descriptor for the selected variant name}
  out     stat: sys_err_t);            {completion status}

const
  max_msg_parms = 2;                   {max parameters we can pass to a message}

var
  r: real;                             {scratch floating point value}
  donevpp: boolean;                    {Vpp configuration all set}
  didit: boolean;                      {local, something was done with curr options}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

label
  not_implemented, not_supp_opt;

begin
  pr.id_p := addr(idb);                {save pointer to info for this device ID}
  pr.name_p := addr(idname);           {save pointer to info for specific dev name}
  donevpp := false;                    {init to Vpp configuration not set yet}
  didit := false;
  case idb.fam of                      {which PIC family is it in ?}

picprg_picfam_12f6xx_k: begin          {12F6xx}
      picprg_cmdw_idreset (pr, picprg_reset_62x_k, true, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_12f6_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_12f6xx));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f62x_k: begin          {16F62x}
      picprg_cmdw_idreset (pr, picprg_reset_62x_k, true, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f62xa_k: begin         {16F62xA}
      picprg_cmdw_idreset (pr, picprg_reset_62x_k, true, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_12f6_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f62xa));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f77_k: begin           {16F77 and related}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f77_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
          then goto not_implemented;
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f7x));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f88_k: begin           {16F87/88}
      picprg_cmdw_idreset (pr, picprg_reset_vddvppf_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat) then begin
        picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
          then goto not_implemented;
        end;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f88_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
          then goto not_implemented;
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f87xa));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f_k: begin             {generic 16F, like 16F877}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f84_k: begin           {16F83, 16F84}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f84));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f716_k: begin          {16F716}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f716_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f62xa));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f72x_k: begin          {16F72x}
      picprg_cmdw_idreset (pr, picprg_reset_62x_k, true, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f88x_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        discard( sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) );
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f88x));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_16f72x));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f720_k: begin          {16F720/721}
      picprg_cmdw_idreset (pr, picprg_reset_62x_k, true, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f688_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        discard( sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) );
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f7x7));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f7x7_k: begin          {16F7x7}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f716_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        discard( sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) );
        if sys_error(stat) then return;
        end;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f7x7));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f688_k: begin          {16F688}
      picprg_cmdw_idreset (pr, picprg_reset_62x_k, true, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f688_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
          then goto not_implemented;
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f688));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f87xa_k: begin         {16F87xA}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16fa_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f87xa));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f88x_k: begin          {16F88x}
      picprg_cmdw_idreset (pr, picprg_reset_62x_k, true, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f88x_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        discard( sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) );
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f88x));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f61x_k: begin          {12F60x, 12F61x, 16F61x}
      picprg_cmdw_idreset (pr, picprg_reset_62x_k, true, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_16f88x_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        discard( sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) );
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_16f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f61x));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_18f_k,                   {generic 18F, like 18F452}
picprg_picfam_18f6680_k: begin         {18F6680 and related}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_none_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_18f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_18f));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_18));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_18f2520_k: begin         {18F2520 and related}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_18f2520_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
          then goto not_implemented;
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_18f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_18f2520));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_18f2520));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_18f14k22_k: begin        {18F14K22 and related}
      r := (idb.vppmin + idb.vppmax) / 2.0; {make desired Vpp voltage}
      r := max(pr.fwinfo.vppmin, min(pr.fwinfo.vppmax, r)); {clip to programmer's range}
      didit := false;                  {init to no reset algorithm selected}
      if                               {use high voltage program mode entry method ?}
          pr.hvpenab and               {allowed by the user ?}
          (r >= idb.vppmin) and (r <= idb.vppmax) and {prog can hit required Vpp range ?}
          (picprg_reset_18f_k in pr.fwinfo.idreset) {can do required reset algorithm ?}
        then begin
          picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
          if sys_error(stat) then return;
          didit := true;
          end
        else begin                     {can't do HVP, try key sequence method}
          if                           {use low voltage key sequence method ?}
              pr.lvpenab and           {allowed by the user ?}
              (picprg_reset_18j_k in pr.fwinfo.idreset) {can do key sequence ?}
              then begin
            picprg_cmdw_idreset (pr, picprg_reset_18j_k, false, stat); {set key seq algorithm}
            if sys_error(stat) then return;
            if pr.fwinfo.cmd[61] then begin {prog has Vpp command ?}
              picprg_cmdw_vpp (pr, idb.vdd.norm, stat); {set Vpp to Vdd level}
              if sys_error(stat) then return;
              end;
            donevpp := true;           {Vpp config all set, don't try setting later}
            didit := true;
            end;
          end
        ;                              {done setting up reset algorithm}
      if not didit then begin          {unable to find reset algorithm}
        if (pr.hvpenab and pr.lvpenab) then goto not_implemented;
        goto not_supp_opt;
        end;

      picprg_cmdw_idwrite (pr, picprg_write_18f2520_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
          then goto not_implemented;
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_18f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_18f14k22));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_18f2520));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_18f14k50_k: begin        {18F14K50 and related}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_18f2520_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
          then goto not_implemented;
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_18f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_18f14k50));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_18f2520));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_18k80_k: begin           {18FxxK80}
      r := (idb.vppmin + idb.vppmax) / 2.0; {make desired Vpp voltage}
      r := max(pr.fwinfo.vppmin, min(pr.fwinfo.vppmax, r)); {clip to programmer's range}
      didit := false;                  {init to no reset algorithm selected}
      if                               {use high voltage program mode entry method ?}
          pr.hvpenab and               {allowed by the user ?}
          (r >= idb.vppmin) and (r <= idb.vppmax) and {prog can hit required Vpp range ?}
          (picprg_reset_18k80_k in pr.fwinfo.idreset) {can do required reset algorithm ?}
        then begin
          picprg_cmdw_idreset (pr, picprg_reset_18k80_k, false, stat);
          if sys_error(stat) then return;
          didit := true;
          end
        else begin                     {can't do HVP, try key sequence method}
          if                           {use low voltage key sequence method ?}
              pr.lvpenab and           {allowed by the user ?}
              (picprg_reset_18j_k in pr.fwinfo.idreset) {can do key sequence ?}
              then begin
            picprg_cmdw_idreset (pr, picprg_reset_18j_k, false, stat); {set key seq algorithm}
            if sys_error(stat) then return;
            if pr.fwinfo.cmd[61] then begin {prog has Vpp command ?}
              picprg_cmdw_vpp (pr, idb.vdd.norm, stat); {set Vpp to Vdd level}
              if sys_error(stat) then return;
              end;
            donevpp := true;           {Vpp config all set, don't try setting later}
            didit := true;
            end;
          end
        ;                              {done setting up reset algorithm}
      if not didit then begin          {unable to find reset algorithm}
        if (pr.hvpenab and pr.lvpenab) then goto not_implemented;
        goto not_supp_opt;
        end;

      picprg_cmdw_idwrite (pr, picprg_write_18f2520_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
          then goto not_implemented;
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_18f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_18k80));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_18f2520));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_18f2523_k: begin         {18F2523 and related}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_18f2520_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
          then goto not_implemented;
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_18f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_18f2523));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_18f2520));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_18f6310_k: begin         {18F6310 and related}
      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_18f2520_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
          then goto not_implemented;
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_18f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_18f6310));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_18f2520));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_18j_k: begin             {generic 18FJ like 18F25J10}
      picprg_cmdw_idreset (pr, picprg_reset_18j_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_18f2520_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
          then goto not_implemented;
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_18f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_18f25j10));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_18f2520));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_10f_k: begin             {10Fxxx}
      if not pr.fwinfo.cmd[40] then goto not_implemented; {no RESADR command ?}

      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_resadr (pr, idb.adrres, stat);
      if sys_error(stat) then return;

      if idb.ndat > 0 then begin       {this part has non-volatile data memory ?}
        picprg_cmdw_datadr (pr, idb.nprog, stat);
        if sys_error(stat) then goto not_implemented;
        end;

      picprg_cmdw_idwrite (pr, picprg_write_core12_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_core12_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_10));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_12f_k: begin             {generic 12 bit core}
      if not pr.fwinfo.cmd[40] then goto not_implemented; {no RESADR command ?}

      picprg_cmdw_idreset (pr, picprg_reset_18f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      picprg_cmdw_resadr (pr, idb.adrres, stat);
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_core12_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_core12_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_12));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_30f_k: begin             {5V dsPICs}
      picprg_cmdw_idreset (pr, picprg_reset_30f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_30f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_30f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_30));
      pr.write_p := nil;               {write routine installed by PICPRG_SPACE}
      pr.read_p := nil;                {read routine installed by PICPRG_SPACE}

      picprg_cmdw_datadr (pr, 16#800000 - (2 * idb.ndat), stat);
      if sys_error(stat) then return;
      end;

picprg_picfam_24h_k: begin             {24H and 33F dsPICs}
      picprg_cmdw_idreset (pr, picprg_reset_24h_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_30f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_30f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_24));
      pr.write_p := nil;               {write routine installed by PICPRG_SPACE}
      pr.read_p := nil;                {read routine installed by PICPRG_SPACE}

      picprg_cmdw_datadr (pr, 16#800000 - (2 * idb.ndat), stat);
      if sys_error(stat) then return;
      end;

picprg_picfam_24f_k: begin             {24F parts}
      picprg_cmdw_idreset (pr, picprg_reset_24f_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_30f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_30f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_24f));
      pr.write_p := nil;               {write routine installed by PICPRG_SPACE}
      pr.read_p := nil;                {read routine installed by PICPRG_SPACE}

      picprg_cmdw_datadr (pr, 16#800000 - (2 * idb.ndat), stat);
      if sys_error(stat) then return;
      end;

picprg_picfam_24fj_k: begin            {24FJ parts}
      picprg_cmdw_idreset (pr, picprg_reset_24fj_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_30f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_30f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_24fj));
      pr.write_p := nil;               {write routine installed by PICPRG_SPACE}
      pr.read_p := nil;                {read routine installed by PICPRG_SPACE}

      picprg_cmdw_datadr (pr, 16#800000 - (2 * idb.ndat), stat);
      if sys_error(stat) then return;
      end;

picprg_picfam_33ep_k: begin            {24EP and 33EP parts}
      picprg_cmdw_idreset (pr, picprg_reset_33ep_k, false, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_restnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idwrite (pr, picprg_write_30f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_30f_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_33ep));
      pr.write_p := nil;               {write routine installed by PICPRG_SPACE}
      pr.read_p := nil;                {read routine installed by PICPRG_SPACE}

      picprg_cmdw_datadr (pr, 16#800000 - (2 * idb.ndat), stat);
      if sys_error(stat) then return;
      end;

picprg_picfam_16f182x_k: begin         {16F182x}
      r := (idb.vppmin + idb.vppmax) / 2.0; {make desired Vpp voltage}
      r := max(pr.fwinfo.vppmin, min(pr.fwinfo.vppmax, r)); {clip to programmer's range}
      didit := false;                  {init to no reset algorithm selected}
      if                               {programmer can do normal high voltage Vpp method ?}
          pr.hvpenab and               {allowed by the user ?}
          (r >= idb.vppmin) and (r <= idb.vppmax) and {prog can hit required Vpp range ?}
          (picprg_reset_62x_k in pr.fwinfo.idreset) {can do required reset algorithm ?}
        then begin
          picprg_cmdw_idreset (pr, picprg_reset_62x_k, true, stat);
          if sys_error(stat) then return;
          didit := true;
          end
        else begin                     {can't do HVP, try key sequence method}
          if                           {programmer can do key sequence prog entry method ?}
              pr.lvpenab and           {allowed by the user ?}
              (picprg_reset_16f182x_k in pr.fwinfo.idreset) {can do key sequence ?}
              then begin
            picprg_cmdw_idreset (pr, picprg_reset_16f182x_k, true, stat); {set key seq algorithm}
            if sys_error(stat) then return;
            if pr.fwinfo.cmd[61] then begin {prog has Vpp command ?}
              picprg_cmdw_vpp (pr, idb.vdd.norm, stat); {set Vpp to Vdd level}
              if sys_error(stat) then return;
              end;
            donevpp := true;           {Vpp config all set, don't try setting later}
            didit := true;
            end;
          end
        ;                              {done setting up reset algorithm}
      if not didit then begin          {unable to find reset algorithm}
        if (pr.hvpenab and pr.lvpenab) then goto not_implemented;
        goto not_supp_opt;
        end;

      picprg_cmdw_idwrite (pr, picprg_write_16f182x_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        discard( sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) );
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_16fe_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16f182x));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_16f15313_k: begin        {8 bit opcodes, like 16F15313}
      r := (idb.vppmin + idb.vppmax) / 2.0; {make desired Vpp voltage}
      r := max(pr.fwinfo.vppmin, min(pr.fwinfo.vppmax, r)); {clip to programmer's range}
      didit := false;                  {init to no reset algorithm selected}
      if                               {programmer can do normal high voltage Vpp method ?}
          pr.hvpenab and               {allowed by the user ?}
          (r >= idb.vppmin) and (r <= idb.vppmax) and {prog can hit required Vpp range ?}
          (picprg_reset_18f_k in pr.fwinfo.idreset) {can do required reset algorithm ?}
        then begin
          picprg_cmdw_idreset (pr, picprg_reset_18f_k, true, stat);
          if sys_error(stat) then return;
          didit := true;
          end
        else begin                     {can't do HVP, try key sequence method}
          if                           {programmer can do key sequence prog entry method ?}
              pr.lvpenab and           {allowed by the user ?}
              (picprg_reset_16f182x_k in pr.fwinfo.idreset) {can do key sequence ?}
              then begin
            picprg_cmdw_idreset (pr, picprg_reset_16f182x_k, true, stat); {set key seq algorithm}
            if sys_error(stat) then return;
            if pr.fwinfo.cmd[61] then begin {prog has Vpp command ?}
              picprg_cmdw_vpp (pr, idb.vdd.norm, stat); {set Vpp to Vdd level}
              if sys_error(stat) then return;
              end;
            donevpp := true;           {Vpp config all set, don't try setting later}
            didit := true;
            end;
          end
        ;                              {done setting up reset algorithm}
      if not didit then begin          {unable to find reset algorithm}
        if (pr.hvpenab and pr.lvpenab) then goto not_implemented;
        goto not_supp_opt;
        end;

      picprg_cmdw_idwrite (pr, picprg_write_16fb_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      picprg_cmdw_idread (pr, picprg_read_16fb_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_16fb));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

picprg_picfam_12f1501_k: begin         {enhanced 14 bit core without EEPROM}
      r := (idb.vppmin + idb.vppmax) / 2.0; {make desired Vpp voltage}
      r := max(pr.fwinfo.vppmin, min(pr.fwinfo.vppmax, r)); {clip to programmer's range}
      didit := false;                  {init to no reset algorithm selected}
      if                               {programmer can do normal high voltage Vpp method ?}
          pr.hvpenab and               {allowed by the user ?}
          (r >= idb.vppmin) and (r <= idb.vppmax) and {prog can hit required Vpp range ?}
          (picprg_reset_62x_k in pr.fwinfo.idreset) {can do required reset algorithm ?}
        then begin
          picprg_cmdw_idreset (pr, picprg_reset_62x_k, true, stat);
          if sys_error(stat) then return;
          didit := true;
          end
        else begin                     {can't do HVP, try key sequence method}
          if                           {programmer can do key sequence prog entry method ?}
              pr.lvpenab and           {allowed by the user ?}
              (picprg_reset_16f182x_k in pr.fwinfo.idreset) {can do key sequence ?}
              then begin
            picprg_cmdw_idreset (pr, picprg_reset_16f182x_k, true, stat); {set key seq algorithm}
            if sys_error(stat) then return;
            if pr.fwinfo.cmd[61] then begin {prog has Vpp command ?}
              picprg_cmdw_vpp (pr, idb.vdd.norm, stat); {set Vpp to Vdd level}
              if sys_error(stat) then return;
              end;
            donevpp := true;           {Vpp config all set, don't try setting later}
            didit := true;
            end;
          end
        ;                              {done setting up reset algorithm}
      if not didit then begin          {unable to find reset algorithm}
        if (pr.hvpenab and pr.lvpenab) then goto not_implemented;
        goto not_supp_opt;
        end;

      picprg_cmdw_idwrite (pr, picprg_write_16f182x_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_writnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;
      if idb.wbufsz <> 1 then begin
        picprg_cmdw_wbufsz (pr, idb.wbufsz, stat);
        discard( sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) );
        if sys_error(stat) then return;
        end;

      picprg_cmdw_idread (pr, picprg_read_16fe_k, stat);
      if sys_stat_match (picprg_subsys_k, picprg_stat_readnimp_k, stat)
        then goto not_implemented;
      if sys_error(stat) then return;

      pr.erase_p :=                    {install erase routine}
        univ_ptr(addr(picprg_erase_12f1501));
      pr.write_p :=                    {install array write routine}
        univ_ptr(addr(picprg_write_targw));
      pr.read_p :=                     {install array read routine}
        univ_ptr(addr(picprg_read_gen));
      end;

otherwise                              {not a recognized PIC family type}
    sys_stat_set (picprg_subsys_k, picprg_stat_unkfam_k, stat);
    return;
    end;

  picprg_progtime (pr, idb.tprogp, stat); {set program cycle wait time}
  if sys_error(stat) then return;

  picprg_cmdw_wbufsz (pr, idb.wbufsz, stat); {set write buffer size}
  discard(                             {OK if WBUFSZ command not implemented}
    sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) );
  if sys_error(stat) then return;

  picprg_cmdw_wbufen (pr, idb.wbstrt + idb.wblen - 1, stat);
  discard(                             {OK if WBUFEN command not implemented}
    sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat) );
  if sys_error(stat) then return;

  if not donevpp then begin            {Vpp configuration not already set ?}
    r := (idb.vppmin + idb.vppmax) / 2.0; {make desired Vpp voltage}
    r := max(pr.fwinfo.vppmin, min(pr.fwinfo.vppmax, r)); {clip to programmer's range}
    if r < idb.vppmin then begin       {programmer's Vpp is too low ?}
      sys_msg_parm_real (msg_parm[1], pr.fwinfo.vppmax);
      sys_msg_parm_real (msg_parm[2], idb.vppmin);
      sys_message_parms ('picprg', 'vpp_prog_low', msg_parm, 2);
      end;
    if r > idb.vppmax then begin       {programmer's Vpp is too high ?}
      sys_msg_parm_real (msg_parm[1], pr.fwinfo.vppmin);
      sys_msg_parm_real (msg_parm[2], idb.vppmax);
      sys_message_parms ('picprg', 'vpp_prog_high', msg_parm, 2);
      end;
    if pr.fwinfo.cmd[61] then begin    {VPP command exists ?}
      picprg_cmdw_vpp (pr, r, stat);   {set Vpp level for this target chip}
      if sys_error(stat) then return;
      end;
    donevpp := true;                   {Vpp config is now set}
    end;

  pr.vdd.low := max(pr.fwinfo.vddmin, min(pr.fwinfo.vddmax, idname.vdd.low));
  pr.vdd.norm := max(pr.fwinfo.vddmin, min(pr.fwinfo.vddmax, idname.vdd.norm));
  pr.vdd.high := max(pr.fwinfo.vddmin, min(pr.fwinfo.vddmax, idname.vdd.high));
  pr.vdd.twover := abs(pr.vdd.high - pr.vdd.low) > 0.050;

  if pr.fwinfo.cmd[16] then begin      {VDDVALS command exists ?}
    picprg_cmdw_vddvals (              {set the Vdd voltage levels}
      pr, pr.vdd.low, pr.vdd.norm, pr.vdd.high, stat);
    if sys_error(stat) then return;
    picprg_cmdw_vddnorm (pr, stat);    {set Vdd to normal value for this chip}
    if sys_error(stat) then return;
    end;
  if pr.fwinfo.cmd[65] then begin      {VDD command exists ?}
    picprg_cmdw_vdd (pr, pr.vdd.norm, stat);
    if sys_error(stat) then return;
    end;

  picprg_cmdw_eecon1 (pr, idb.eecon1, stat); {try to set adr of EECON1 register}
  if                                   {programmer doesn't support variable EECON1 ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    if idb.eecon1 <> 16#FA6 then goto not_implemented; {need non-default value ?}
    end;
  if sys_error(stat) then return;

  picprg_cmdw_eeadr (pr, idb.eeadr, stat); {try to set adr of EEADR register}
  if                                   {programmer doesn't support variable EEADR ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    if idb.eeadr <> 16#FA9 then goto not_implemented; {need non-default value ?}
    end;
  if sys_error(stat) then return;

  picprg_cmdw_eeadrh (pr, idb.eeadrh, stat); {try to set adr of EEADRH register}
  if                                   {programmer doesn't support variable EEADRH ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    if idb.eeadrh <> 16#FAA then goto not_implemented; {need non-default value ?}
    end;
  if sys_error(stat) then return;

  picprg_cmdw_eedata (pr, idb.eedata, stat); {try to set adr of EEDATA register}
  if                                   {programmer doesn't support variable EEDATA ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    if idb.eedata <> 16#FA8 then goto not_implemented; {need non-default value ?}
    end;
  if sys_error(stat) then return;

  picprg_cmdw_visi (pr, idb.visi, stat); {try to set adr of VISI register}
  if                                   {programmer doesn't support variable VISI ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    if idb.visi <> 16#784 then goto not_implemented; {need non-default value ?}
    end;
  if sys_error(stat) then return;

  picprg_cmdw_tblpag (pr, idb.tblpag, stat); {try to set adr of TBLPAG register}
  if                                   {programmer doesn't support variable TBLPAG ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    if idb.tblpag <> 16#032 then goto not_implemented; {need non-default value ?}
    end;
  if sys_error(stat) then return;

  picprg_cmdw_nvmcon (pr, idb.nvmcon, stat); {try to set adr of NVMCON register}
  if                                   {programmer doesn't support variable NVMCON ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    if idb.nvmcon <> 16#760 then goto not_implemented; {need non-default value ?}
    end;
  if sys_error(stat) then return;

  picprg_cmdw_nvmkey (pr, idb.nvmkey, stat); {try to set adr of NVMKEY register}
  if                                   {programmer doesn't support variable NVMKEY ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    if idb.nvmkey <> 16#766 then goto not_implemented; {need non-default value ?}
    end;
  if sys_error(stat) then return;

  picprg_cmdw_nvmadr (pr, idb.nvmadr, stat); {try to set adr of NVMADR register}
  if                                   {programmer doesn't support variable NVMADR ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    if idb.nvmadr <> 16#762 then goto not_implemented; {need non-default value ?}
    end;
  if sys_error(stat) then return;

  picprg_cmdw_nvmadru (pr, idb.nvmadru, stat); {try to set adr of NVMADRU register}
  if                                   {programmer doesn't support variable NVMADRU ?}
      sys_stat_match (picprg_subsys_k, picprg_stat_cmdnimp_k, stat)
      then begin
    if idb.nvmadru <> 16#764 then goto not_implemented; {need non-default value ?}
    end;
  if sys_error(stat) then return;

  picprg_reset (pr, stat);             {reset the chip and all optional state}
  return;

not_implemented:                       {support missing for the selected PIC}
  sys_stat_set (picprg_subsys_k, picprg_stat_picnimp_k, stat);
  sys_stat_parm_vstr (idname.name, stat);
  return;

not_supp_opt:                          {not supported with the current options}
  sys_stat_set (picprg_subsys_k, picprg_stat_nsupp_opt_k, stat);
  sys_stat_parm_vstr (idname.name, stat);
  return;

  end;
