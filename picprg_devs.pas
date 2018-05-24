{   Routines that deal with devices lists.
}
module picprg_devs;
define picprg_list_get;
define picprg_devs_add;
define picprg_list_del;
%include '/cognivision_links/dsee_libs/pics/picprg2.ins.pas';
{
*******************************************************************************
*
*   Subroutine PICPRG_LIST_GET (MEM, DEVS)
*
*   Return the list of all known compatible programmers currently visible to this
*   process.  A list entry can be passed to PICPRG_OPEN_DEV to open that selected
*   device, although there is no guarantee that the device is not in use by another
*   process.  Only programmers connect via means that allow for enumeration are
*   listed, such as USB and PCI bus devices, for example.  Programmers connected
*   by other means, such as serial port, can not be enumerated.
*
*   MEM is the parent memory context to create the memory context for the new
*   list from.  All system resources allocated by this call will be released
*   when the list is deleted by PICPRG_LIST_DEL.
}
procedure picprg_list_get (            {get list of known programmers}
  in out  mem: util_mem_context_t;     {parent memory context to create list context from}
  out     devs: picprg_devs_t);        {returned list, all fields overwritten}
  val_param;

begin
  util_mem_context_get (mem, devs.mem_p); {create memory context for the new list}
  devs.n := 0;                         {init number of list entries}
  devs.list_p := nil;                  {init to empty list}
  devs.last_p := nil;

  picprg_sys_usbprog_enum (devs);      {add all USBProgs found to the list}
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_LIST_DEL (DEVS)
*
*   Deallocate all system resources allocated to the devices list DEVS.  DEVS is
*   returned invalid.
}
procedure picprg_list_del (            {delete list of programmers, deallocate resources}
  in out  devs: picprg_devs_t);        {returned invalid}
  val_param;

begin
  util_mem_context_del (devs.mem_p);   {deallocate all dynamic memory used by the list}
  devs.n := 0;
  devs.list_p := nil;
  devs.last_p := nil;
  end;
{
*******************************************************************************
*
*   Subroutine PICRPG_DEVS_ADD (DEVS)
*
*   Create a new devices list entry and add it to the end of the list.  The
*   entry is initialized with default or benign values to the extent possible.
}
procedure picprg_devs_add (            {add blank entry to end of devices list}
  in out  devs: picprg_devs_t);        {list to add entry to, new entry will be last}
  val_param;

var
  dev_p: picprg_dev_p_t;               {pointer to new devices list entry}

begin
  util_mem_grab (sizeof(dev_p^), devs.mem_p^, false, dev_p); {alloc mem for new entry}

  dev_p^.next_p := nil;                {no entry follows this one}
  dev_p^.name.max := size_char(dev_p^.name.str); {init device name}
  dev_p^.name.len := 0;
  dev_p^.devconn := picprg_devconn_unk_k; {device connection type is unknown}
  dev_p^.unit := 0;
  dev_p^.path.max := size_char(dev_p^.path.str); {init system device pathname}
  dev_p^.path.len := 0;

  if devs.last_p = nil
    then begin                         {this is first list entry}
      devs.list_p := dev_p;
      devs.n := 1;
      end
    else begin                         {adding to end of existing list}
      devs.last_p^.next_p := dev_p;
      devs.n := devs.n + 1;            {count one more entry in the list}
      end
    ;
  devs.last_p := dev_p;                {update pointer to last list entry}
  end;
