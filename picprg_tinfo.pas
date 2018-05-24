{   Subroutine PICPRG_TINFO (PR, TINFO, STAT)
*
*   Get detailed information about the target chip the library is
*   configured to into TINFO.  STAT is returned with an error if the
*   library has not been previously configured.
}
module picprg_tinfo;
define picprg_tinfo;
%include '/cognivision_links/dsee_libs/pics/picprg2.ins.pas';

procedure picprg_tinfo (               {get detailed info about the target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  out     tinfo: picprg_tinfo_t;       {returned detailed target chip info}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ent_p: picprg_adrent_p_t;            {pointer to current address list entry}

begin
  if picprg_nconfig (pr, stat) then return; {library not configured ?}

  tinfo.name.max := size_char(tinfo.name.str);
  tinfo.name1.max := size_char(tinfo.name1.str);

  string_copy (pr.name_p^.name, tinfo.name); {name of the chosen variant}
  string_copy (pr.id_p^.name_p^.name, tinfo.name1); {first listed name this PIC}
  tinfo.idspace := pr.id_p^.idspace;   {name space for device ID word}
  tinfo.id := pr.id;                   {actual device ID word including rev}
  tinfo.rev_mask := pr.id_p^.rev_mask; {mask for revision value}
  tinfo.rev_shft := pr.id_p^.rev_shft; {bits to shift maked revision value right}
  tinfo.rev := rshft(tinfo.id & tinfo.rev_mask, tinfo.rev_shft); {revision number}
  tinfo.vdd := pr.name_p^.vdd;         {voltage levels}
  tinfo.vppmin := pr.id_p^.vppmin;     {allowable Vpp voltage range}
  tinfo.vppmax := pr.id_p^.vppmax;
  tinfo.wbufsz := pr.id_p^.wbufsz;     {write buffer size and applicable range}
  tinfo.wbstrt := pr.id_p^.wbstrt;
  tinfo.wblen := pr.id_p^.wblen;
  tinfo.pins := pr.id_p^.pins;         {number of pins in DIP package}
  tinfo.nprog := pr.id_p^.nprog;
  tinfo.ndat := pr.id_p^.ndat;
  tinfo.adrres := pr.id_p^.adrres;
  tinfo.maskprg := pr.id_p^.maskprg;
  tinfo.maskdat := pr.id_p^.maskdat;
  tinfo.datmap := pr.id_p^.datmap;
  tinfo.tprogp := pr.id_p^.tprogp;
  tinfo.tprogd := pr.id_p^.tprogd;

  tinfo.nconfig := 0;                  {init number of config addresses}
  ent_p := pr.id_p^.config_p;          {init to first entry in the list}
  while ent_p <> nil do begin          {once for each entry in the list}
    tinfo.nconfig := tinfo.nconfig + 1; {count one more CONFIG address}
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;
  tinfo.config_p := pr.id_p^.config_p; {return pointer to list of CONFIG addresses}

  tinfo.nother := 0;                   {init number of other addresses}
  ent_p := pr.id_p^.other_p;           {init to first entry in the list}
  while ent_p <> nil do begin          {once for each entry in the list}
    tinfo.nother := tinfo.nother + 1;  {count one more OTHER address}
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;
  tinfo.other_p := pr.id_p^.other_p;   {return pointer to list of OTHER addresses}

  tinfo.fam := pr.id_p^.fam;           {PIC family ID}
  tinfo.eecon1 := pr.id_p^.eecon1;
  tinfo.eeadr := pr.id_p^.eeadr;
  tinfo.eeadrh := pr.id_p^.eeadrh;
  tinfo.eedata := pr.id_p^.eedata;
  tinfo.visi := pr.id_p^.visi;
  tinfo.tblpag := pr.id_p^.tblpag;
  tinfo.nvmcon := pr.id_p^.nvmcon;
  tinfo.nvmkey := pr.id_p^.nvmkey;
  tinfo.nvmadr := pr.id_p^.nvmadr;
  tinfo.nvmadru := pr.id_p^.nvmadru;
  tinfo.hdouble := pr.id_p^.hdouble;   {HEX file addresses are doubled}
  tinfo.eedouble := pr.id_p^.eedouble; {EEPROM addresses double in HEX file beyond HDOUBLE}
  end;
