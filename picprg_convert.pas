{   Routines that convert between different representation of values.
}
module picprg_convert;
define picprg_sec_ticks;
define picprg_volt_vdd;
%include '/cognivision_links/dsee_libs/pics/picprg2.ins.pas';
{
*******************************************************************************
*
*   Function PICPRG_SEC_TICKS (PR, SEC)
*
*   Return the number of programmer clock ticks to wait to guarantee the minimum
*   wait time at least SEC seconds long.
}
function picprg_sec_ticks (            {convert seconds to min clock ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  in      sec: real)                   {seconds}
  :int32u_t;                           {min programmer ticks for SEC elapsed}
  val_param;

var
  r: real;
  i: int32u_t;

begin
  r := sec / pr.fwinfo.ticksec;        {make FP number of tick intervals}
  i := trunc(r);
  if r > i then i := i + 1;
  i := i + 1;                          {number of ticks to guarantee minimum interval}
  picprg_sec_ticks := i;               {pass back the result}
  end;
{
*******************************************************************************
*
*   Function PICPRG_VOLT_VDD (VOLTS)
*
*   Return the vdd value for the voltage VOLTS.  The value is silently
*   clipped to the available range.
}
function picprg_volt_vdd (             {make internal Vdd value from volts}
  in      volts: real)                 {desired value in volts}
  :int8u_t;                            {internal vdd value}
  val_param;

const
  vddstep_k = 6.0 / 250.0;             {voltage step for each integer increment}

var
  r: real;

begin
  r := max(0.0, min(255, volts / vddstep_k)); {FP number of integer steps}
  picprg_volt_vdd := trunc(r + 0.5);   {pass back nearest integer step value}
  end;
