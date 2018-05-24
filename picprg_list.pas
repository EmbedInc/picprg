{   Program PICPRG_LIST
*
*   List all the PIC programmers that can be enumerated from this system.
}
program picprg_list;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'stuff.ins.pas';
%include 'picprg.ins.pas';

const
  max_msg_args = 2;                    {max arguments we can pass to a message}

var
  devs: picprg_devs_t;                 {root data structure for list of programmers}
  dev_p: picprg_dev_p_t;               {pointer to programmers list entry}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;

label
  next_ent;

begin
  picprg_list_get (util_top_mem_context, devs); {get list of enumeratable programmers}
  sys_msg_parm_int (msg_parm[1], devs.n);
  if devs.n = 1
    then sys_message_parms ('picprg', 'n_progs1', msg_parm, 1)
    else sys_message_parms ('picprg', 'n_progs', msg_parm, 1);

  dev_p := devs.list_p;                {init to first list entry}
  while dev_p <> nil do begin          {once for each list entry}
    case dev_p^.devconn of             {how is this programmer connected to the system ?}
picprg_devconn_usb_k: begin            {USB}
        write ('USB');
        end;
otherwise
      sys_msg_parm_int (msg_parm[1], ord(dev_p^.devconn));
      sys_msg_parm_vstr (msg_parm[2], dev_p^.name);
      sys_message_parms ('picprg', 'namprog_badconn', msg_parm, 2);
      goto next_ent;
      end;
    writeln (': ', dev_p^.name.str:dev_p^.name.len);
next_ent:                              {advance to next list entry}
    dev_p := dev_p^.next_p;
    end;

  picprg_list_del (devs);              {deallocate list resources}
  end.
