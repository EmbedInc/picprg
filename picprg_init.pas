{   Subroutine PICPRG_INIT (PR)
*
*   Initialize the library use state PR.  This call allocates no resources,
*   but after this call PR can be passed to PICPRG_OPEN to open a new use
*   of the library.  The application may change some of the fields in PR
*   before the OPEN call to chose non-default settings.  See the PICPRG_OPEN
*   documentations for details.
}
module picprg_init;
define picprg_init;
%include 'picprg2.ins.pas';

procedure picprg_init (                {initialize library state to defaults}
  out     pr: picprg_t);               {returned ready to pass to OPEN}
  val_param;

begin
  pr.devconn := picprg_devconn_unk_k;  {init to device connection type unknown}
  pr.sio := 1;                         {system serial line 1}
  pr.prgname.max := size_char(pr.prgname.str); {user name of programmer not specified}
  pr.prgname.len := 0;
  pr.debug := 1;                       {set to default debug output information}
  pr.flags := [];                      {init all general control flags to off}
  pr.lvpenab := true;                  {init to allow low voltage prog entry mode}
  pr.hvpenab := true;                  {init to allow high voltage prog entry mode}
  end;
