{   List all the PICs that are supported by the LProg.
}
program lprg_list;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'stuff.ins.pas';
%include 'picprg.ins.pas';

var
  pr: picprg_t;                        {PICPRG library state}
  pic_p: picprg_idblock_p_t;           {info about one PIC}
  npics: sys_int_machine_t;            {total number of PICs found}
  llist: string_list_t;                {list of PICs supported by LProg}
  stat: sys_err_t;                     {completion status}

begin
  string_cmline_init;                  {init for reading the command line}
  string_cmline_end_abort;             {no command line parameters allowed}

  picprg_init (pr);                    {init library state}
  picprg_open (pr, stat);              {open the PICPRG library}
  sys_error_abort (stat, '', '', nil, 0);
{
*   Make a list of all the PICs that the LProg can handle.
}
  npics := 0;                          {init total number of PICs found}

  string_list_init (llist, util_top_mem_context); {init list of supported PIC names}
  llist.deallocable := false;          {won't individually delete list entries}

  pic_p := pr.env.idblock_p;           {init to first PIC in list}
  while pic_p <> nil do begin          {scan the PICs in the list}
    npics := npics + 1;                {count one more PIC found in the list}
    case pic_p^.fam of                 {which family is this PIC in ?}

picprg_picfam_18f14k22_k,
picprg_picfam_18k80_k,
picprg_picfam_16f182x_k,
picprg_picfam_16f15313_k,
picprg_picfam_16f183xx_k,
picprg_picfam_12f1501_k,
picprg_picfam_24h_k,
picprg_picfam_24fj_k,
picprg_picfam_33ep_k: begin
        string_list_str_add (          {add name of this PIC to the list}
          llist, pic_p^.name_p^.name);
        end;
      end;
    pic_p := pic_p^.next_p;            {to next PIC in list}
    end;                               {back to handle this new PIC}
{
*   LLIST is the list of names of all PICs that are supported by the LProg.
}
  picprg_close (pr, stat);
  sys_error_abort (stat, '', '', nil, 0);

  string_list_sort (                   {sort the list of supported PICs}
    llist,                             {the list to sort}
    [ string_comp_ncase_k,             {ignore character case}
      string_comp_num_k]);             {compare numeric fields numerically}

  string_list_pos_abs (llist, 1);      {go to first list entry}
  while llist.str_p <> nil do begin    {loop over all the entries}
    writeln (llist.str_p^.str:llist.str_p^.len);
    string_list_pos_rel (llist, 1);
    end;

  writeln;
  writeln (llist.n, ' of ', npics, ' PICs supported by the LProg');
  end.
