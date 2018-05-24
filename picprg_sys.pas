{   System-dependent routines.  This module is intended to be rewritten for
*   different target operating systems.  This version is for Windows 2000
*   and later.
}
module picprg_sys;
define picprg_sys_usbprog_enum;
define picprg_sys_name_open;
define picprg_sys_usb_write;
define picprg_sys_usb_read;
define picprg_sys_usbprog_close;
%include 'picprg2.ins.pas';
{
********************************************************************************
*
*   Subroutine PICPRG_SYS_USBPROG_ENUM (DEVS)
}
procedure picprg_sys_usbprog_enum (    {add all USBProgs to devices list}
  in out  devs: picprg_devs_t);        {list to add devices to}
  val_param;

var
  udevs: file_usbdev_list_t;           {list of USB devices with our VID/PID}
  udev_p: file_usbdev_p_t;             {pointer to current entry in UDEVS}
  stat: sys_err_t;

begin
  file_embusb_list_get (               {make list of PICPRG USB devices}
    file_usbid(picprg_vid_k, picprg_pid_k), {USB unique ID of device}
    util_top_mem_context,              {parent mem context for list context}
    udevs,                             {the returned list}
    stat);
  if sys_error(stat) then return;      {couldn't get list, nothing to do ?}

  udev_p := udevs.list_p;              {init pointer to first list entry}
  while udev_p <> nil do begin         {loop thru all the USB devices list entries}
    picprg_devs_add (devs);            {add new entry to end of DEVS list}
    string_copy (udev_p^.name, devs.last_p^.name); {copy data from UDEVS entry}
    devs.last_p^.devconn := picprg_devconn_usb_k;
    string_copy (udev_p^.path, devs.last_p^.path);
    udev_p := udev_p^.next_p;          {advance to next entry in UDEVS list}
    end;

  file_usbdev_list_del (udevs);        {deallocate temporary list resources}
  end;
{
********************************************************************************
*
*   Subroutine PICPRG_SYS_NAME_OPEN (NAME, CONN, DEVCONN, STAT)
*
*   Open a connection to a named PIC programmer.  NAME is the user name of the
*   specific USBProg to open.
*
*   If NAME is empty, then the first available programmer is opened.  No
*   particular order is guaranteed, so if multiple programmers are available the
*   selection will be arbitrary.
*
*   If NAME is not empty, then the first available programmer with that user
*   name is opened.  It is intended that the user ensure that user names are
*   unique among all programmers connected to a machine.
*
*   CONN is the returned I/O connection to the newly opened programmer.
*   Subsequent attempts to open that programmer will fail until CONN is closed.
*   DEVCONN is returned the type of I/O connection to the programmer.
}
procedure picprg_sys_name_open (       {open connection to named PIC programmer}
  in      name: univ string_var_arg_t; {name of USBProg to open, opens first on empty}
  out     conn: file_conn_t;           {returned connection to the USBProg}
  out     devconn: picprg_devconn_k_t; {type of connection to the programmer}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  devconn := picprg_devconn_usb_k;     {this connection will always be via USB}

  file_open_embusb (                   {open connection to the programmer}
    file_usbid(picprg_vid_k, picprg_pid_k), {USB unique ID of device}
    name,                              {user-defined name of the programmer}
    conn,                              {returned I/O connection}
    stat);
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_SYS_USB_WRITE (CONN, BUF, LEN, STAT)
}
procedure picprg_sys_usb_write (       {send data to a USBProg}
  in      conn: file_conn_t;           {existing connection to the USBProg}
  in      buf: univ char;              {data to write}
  in      len: sys_int_adr_t;          {number of machine adr increments to write}
  out     stat: sys_err_t);            {completion status code}
  val_param;

begin
  file_write_embusb (buf, conn, len, stat);
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_SYS_USB_READ (CONN, ILEN, BUF, OLEN, STAT)
*
*   Read the next chunk of data from the USB device.  ILEN is the maximum number
*   of bytes to read into BUF.  OLEN is returned the number of bytes actually
*   read, which will always be from 1 to 64 on no error.  This routine blocks
*   indefinitely until at least one byte is available.
}
procedure picprg_sys_usb_read (        {read next chunk of bytes from USBProg}
  out     conn: file_conn_t;           {existing connection to the USBProg}
  in      ilen: sys_int_adr_t;         {max number of machine adr increments to read}
  out     buf: univ char;              {returned data}
  out     olen: sys_int_adr_t;         {number of machine adresses actually read}
  out     stat: sys_err_t);            {completion status code}
  val_param;

begin
  file_read_embusb (conn, ilen, buf, olen, stat);
  end;
{
*******************************************************************************
*
*   Subroutine PICPRG_SYS_USBPROG_CLOSE (CONN_P)
}
procedure picprg_sys_usbprog_close (   {private close routine for USBProg connection}
  in      conn_p: file_conn_p_t);      {pointer to connection to close}
  val_param;

begin
  file_close (conn_p^);
  end;
