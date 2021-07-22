{   Private include file used by all the routines that implement the
*   PICPRG library.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'stuff.ins.pas';
%include 'picprg.ins.pas';

type
  picprg_cop_k_t = (                   {command opcodes}
    picprg_cop_nop_k = 1,              {no operation, just responds with ACK}
    picprg_cop_off_k = 2,              {power down the target chip}
    picprg_cop_pins_k = 3,             {get number of pins information}
    picprg_cop_send1_k = 4,            {send up to 8 bits to the target}
    picprg_cop_send2_k = 5,            {send up to 16 bits to the target}
    picprg_cop_recv1_k = 6,            {read up to 8 bits from the target}
    picprg_cop_recv2_k = 7,            {read up to 16 bits from the target}
    picprg_cop_clkh_k = 8,             {raise the clock line to the target}
    picprg_cop_clkl_k = 9,             {lower the clock line to the target}
    picprg_cop_dath_k = 10,            {raise the data line to the target}
    picprg_cop_datl_k = 11,            {lower the data line to the target}
    picprg_cop_datr_k = 12,            {read the data line from the target}
    picprg_cop_tdrive_k = 13,          {test whether target is driving data line}
    picprg_cop_wait_k = 14,            {wait before next op in I16 200uS units}
    picprg_cop_fwinfo_k = 15,          {get firmware version and other info}
    picprg_cop_vddvals_k = 16,         {set low, normal, and high Vdd levels}
    picprg_cop_vddlow_k = 17,          {set Vdd to the low level}
    picprg_cop_vddnorm_k = 18,         {set Vdd to the normal level}
    picprg_cop_vddhigh_k = 19,         {set Vdd to the high level}
    picprg_cop_vddoff_k = 20,          {switch off target chip Vdd (set to 0)}
    picprg_cop_vppon_k = 21,           {turn on the target chip programming voltage}
    picprg_cop_vppoff_k = 22,          {turn off the target chip programming voltage}
    picprg_cop_idreset_k = 23,         {select algorithm for reset}
    picprg_cop_reset_k = 24,           {reset target, leave ready for programming}
    picprg_cop_idwrite_k = 25,         {select algorithm for write}
    picprg_cop_idread_k = 26,          {select algorithm for read}
    picprg_cop_test1_k = 27,           {run debugging test}
    picprg_cop_adr_k = 28,             {set address for next target operation}
    picprg_cop_read_k = 29,            {read from target, increment address}
    picprg_cop_write_k = 30,           {write to target, increment address}
    picprg_cop_tprog_k = 31,           {set programming write cycle time}
    picprg_cop_spprog_k = 32,          {select program memory space}
    picprg_cop_spdata_k = 33,          {select data memory space}
    picprg_cop_incadr_k = 34,          {increment adr for next target operation}
    picprg_cop_adrinv_k = 35,          {invalidate target address assumption}
    picprg_cop_pan18_k = 36,           {specialized 18xxx 8 byte panel write}
    picprg_cop_rbyte8_k = 37,          {read 8 bytes}
    picprg_cop_writing_k = 38,         {indicate target is being written to}
    picprg_cop_fwinfo2_k = 39,         {get additional firmware info}
    picprg_cop_resadr_k = 40,          {indicate target address after reset}
    picprg_cop_chkcmd_k = 41,          {check availability of a command}
    picprg_cop_getpwr_k = 42,          {get on-board processor power voltage}
    picprg_cop_getvdd_k = 43,          {get target Vdd voltage}
    picprg_cop_getvpp_k = 44,          {get target Vpp voltage}
    picprg_cop_waitchk_k = 45,         {wait and get completion status}
    picprg_cop_getbutt_k = 46,         {get number of user button presses}
    picprg_cop_appled_k = 47,          {configure the "App" LED display}
    picprg_cop_run_k = 48,             {let target PIC run}
    picprg_cop_highz_k = 49,           {set target lines to high impedence}
    picprg_cop_ntout_k = 50,           {disable host timeout until next command}
    picprg_cop_getcap_k = 51,          {get programmer capabilities}
    picprg_cop_send3_k = 52,           {send up to 24 bits to the target}
    picprg_cop_send4_k = 53,           {send up to 32 bits to the target}
    picprg_cop_recv3_k = 54,           {read up to 24 bits from the target}
    picprg_cop_recv4_k = 55,           {read up to 32 bits from the target}
    picprg_cop_w30pgm_k = 56,          {write 4 words to dsPIC program memory}
    picprg_cop_test2_k = 57,           {debug test, 1 parm byte, 4 return bytes}
    picprg_cop_r30pgm_k = 58,          {read 2 words from dsPIC program memory}
    picprg_cop_datadr_k = 59,          {set data EEPROM mapping start}
    picprg_cop_write8_k = 60,          {write 8 bytes at a time to target}
    picprg_cop_vpp_k = 61,             {set Vpp level for when Vpp is enabled}
    picprg_cop_wbufen_k = 62,          {indicate last address covered by write buffer}
    picprg_cop_wbufsz_k = 63,          {indicate size of targer write buffer}
    picprg_cop_gettick_k = 64,         {get programmer clock tick period}
    picprg_cop_vdd_k = 65,             {set Vdd level for when Vdd is enabled}
    picprg_cop_nameset_k = 66,         {set user-definable name string}
    picprg_cop_nameget_k = 67,         {get user-definable name string}
    picprg_cop_reboot_k = 68,          {completely restart control processor}
    picprg_cop_read64_k = 69,          {read 64 words}
    picprg_cop_vpphiz_k = 70,          {set Vpp to high impedence}
    picprg_cop_testget_k = 71,         {get test mode}
    picprg_cop_testset_k = 72,         {set test mode}
    picprg_cop_eecon1_k = 73,          {indicate address of target EECON1 register}
    picprg_cop_eeadr_k = 74,           {indicate address of target EEADR register}
    picprg_cop_eeadrh_k = 75,          {indicate address of target EEADRH register}
    picprg_cop_eedata_k = 76,          {indicate address of target EEDATA register}
    picprg_cop_visi_k = 77,            {indicate address of the VISI register}
    picprg_cop_tblpag_k = 78,          {indicate address of the TBLPAG register}
    picprg_cop_nvmcon_k = 79,          {indicate address of the NVMCON register}
    picprg_cop_nvmkey_k = 80,          {indicate address of the NVMKEY register}
    picprg_cop_nvmadr_k = 81,          {indicate address of the NVMADR register}
    picprg_cop_nvmadru_k = 82,         {indicate address of the NVMADRU register}
    picprg_cop_tprogf_k = 83,          {set programming time in fast ticks}
    picprg_cop_ftickf_k = 84,          {get fast tick frequency}
    picprg_cop_sendser_k = 85,         {send bytes out the serial data port}
    picprg_cop_recvser_k = 86,         {get unread bytes from serial data port}
    picprg_cop_send8m_k = 87,          {send 8 bits, MSB first}
    picprg_cop_send24m_k = 88,         {send 24 bits, MSB first}
    picprg_cop_recv24m_k = 89);        {receive bits, MSB first}

  picprg_rsp_k_t = (                   {special response codes}
    picprg_rsp_ack_k = 1);             {command opcode received, OK to send next}

 picprg_buf_t =                        {buffer of raw bytes}
   array [0 .. 255] of int8u_t;


procedure picprg_18_read (             {send command to read from PIC18}
  in out  pr: picprg_t;                {state for this use of the library}
  in      cmd: sys_int_machine_t;      {4 bit command opcode}
  in      datw: sys_int_machine_t;     {8 bit data written to chip after opcode}
  out     datr: sys_int_machine_t;     {8 bit data read from the chip}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_18_setadr (           {set TBLPTR address register in PIC18}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_conv32_t;       {the address}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_18_write (            {send command with write data to PIC18}
  in out  pr: picprg_t;                {state for this use of the library}
  in      cmd: sys_int_machine_t;      {4 bit command opcode}
  in      datw: sys_int_machine_t;     {16 bit data to write to the chip}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_30_getvisi (          {read contents of PIC30 VISI register}
  in out  pr: picprg_t;                {state for this use of the library}
  out     visi: sys_int_conv16_t;      {returned VISI register contents}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_30_goto100 (          {force PIC30 program counter to 100h}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_30_setreg (           {set a PIC30 W register to a constant}
  in out  pr: picprg_t;                {state for this use of the library}
  in      k: sys_int_conv16_t;         {value to load into the W register}
  in      w: sys_int_machine_t;        {0-15 W register number}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_30_wram (             {write W register to RAM}
  in out  pr: picprg_t;                {state for this use of the library}
  in      w: sys_int_machine_t;        {0-15 W register number}
  in      adr: sys_int_machine_t;      {RAM address to write the register to}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_30_xinst (            {execute instruction on 30F target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      inst: sys_int_conv24_t;      {opcode of instruction to execute}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

function picprg_closing (              {check for library is being closed}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t)             {set to CLOSE if library being closed}
  :boolean;                            {TRUE iff library being closed}
  val_param; extern;

procedure picprg_config_idb (          {configure to target described in ID block}
  in out  pr: picprg_t;                {state for this use of the library}
  in      idb: picprg_idblock_t;       {ID block of target to configure to}
  in      idname: picprg_idname_t;     {descriptor for the selected variant name}
  out     stat: sys_err_t);            {completion status}
  extern;

procedure picprg_devs_add (            {add blank entry to end of devices list}
  in out  devs: picprg_devs_t);        {list to add entry to, new entry will be last}
  val_param; extern;

procedure picprg_env_read (            {read env file, save info in PR}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_10 (            {erase routine for generic 10Fxxx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_12 (            {erase routine for generic 12 bit core device}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_12f6xx (        {erase routine for 12F6xx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f (           {erase routine for generic 16Fxxx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f688 (        {erase routine for 16F688 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f62xa (       {erase routine for 16F62xA}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f7x7 (        {erase routine for 16F7x7}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f87xa (       {erase routine for 16F87xA}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f7x (         {erase routine for 16F7x}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f88x (        {erase routine for 16F88x}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f61x (        {erase routine for 12F60x, 12F61x, 16F61x}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f84 (         {erase routine for 16F84}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f182x (       {erase routine for 16F182x}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16f183xx (      {erase routine for 16F18313 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_16fb(           {erase routine for 16F15313 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_12f1501(        {erase routine enhanced 14 bit core, no EEPROM}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_18f (           {erase routine for generic 18Fxxx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_18f2520 (       {erase routine for 18F2520 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_18f14k22 (      {erase routine for 18F14k22 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_18f2523 (       {erase routine for 18F2523 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_18f6310 (       {erase routine for 18F6310 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_18f25j10 (      {erase routine for 18F25J10 and related}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_18k80 (         {erase routine for 18FxxK80}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_30 (            {erase routine for generic dsPIC}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_24 (            {erase routine for dsPIC 24H and 33F}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_24f (           {erase routine for 24F parts}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_24fj (          {erase routine for 24FJ parts}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase_33ep (          {erase routine for 24EP and 33EP parts}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_init_cmd (            {initialize a command descriptor}
  out     cmd: picprg_cmd_t);          {returned initialized}
  val_param; extern;

function picprg_nconfig (              {check for library has been configured}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t)             {set to error if library not configured}
  :boolean;                            {TRUE if library not configured}
  val_param; extern;

procedure picprg_read_gen (            {generic read, uses READ and RBYTE8 commands}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to read from}
  in      n: picprg_adr_t;             {number of locations to read from}
  in      mask: picprg_maskdat_t;      {mask for valid data bits}
  out     dat: univ picprg_datar_t;    {the returned data array, unused bits 0}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_read_18d (            {read routine for 18xxx data space}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to read from}
  in      n: picprg_adr_t;             {number of locations to read from}
  in      mask: picprg_maskdat_t;      {mask for valid data bits}
  out     dat: univ picprg_datar_t;    {the returned data array, unused bits 0}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_recv8mss24 (          {receive 24 bit MSB-first word, get 8 bit payload}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: sys_int_machine_t;      {returned 8 bit payload}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_recv14mss24 (         {receive 24 bit MSB-first word, get 14 bit payload}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: sys_int_machine_t;      {returned 14 bit payload}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

function picprg_sec_ticks (            {convert seconds to min clock ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  in      sec: real)                   {seconds}
  :int32u_t;                           {min programmer ticks for SEC elapsed}
  val_param; extern;

procedure picprg_send6 (               {send 6 bits of data to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_conv16_t;       {the data word to send}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_send14mss24 (         {send 14 bits of data in 24 bit word, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_machine_t;      {data to send in the low 14 bits}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_send14ss (            {send 14 data bits with start/stop bits}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_conv16_t;       {the data word to send}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_send16mss24 (         {send 16 bits of data in 24 bit word, MSB first}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_machine_t;      {data to send in the low 16 bits}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_sendbuf (             {send buffer of bytes to the programmer}
  in out  pr: picprg_t;                {state for this use of the library}
  in      buf: univ picprg_buf_t;      {buffer of bytes to send}
  in      n: sys_int_adr_t;            {number of bytes to send}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_space (               {reconfig library to new mem space selection}
  in out  pr: picprg_t;                {state for this use of the library}
  in      space: picprg_space_k_t);    {ID for the new selected target memory space}
  val_param; extern;

procedure picprg_sys_usbprog_close (   {private close routine for USBProg connection}
  in      conn_p: file_conn_p_t);      {pointer to connection to close}
  val_param; extern;

procedure picprg_sys_usbprog_enum (    {add all USBProgs to devices list}
  in out  devs: picprg_devs_t);        {list to add devices to}
  val_param; extern;

procedure picprg_sys_name_open (       {open connection to named PIC programmer}
  in      name: univ string_var_arg_t; {name of USBProg to open, opens first on empty}
  out     conn: file_conn_t;           {returned connection to the USBProg}
  out     devconn: picprg_devconn_k_t; {type of connection to the programmer}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_sys_usb_read (        {read next chunk of bytes from USBProg}
  out     conn: file_conn_t;           {returned connection to the USBProg}
  in      ilen: sys_int_adr_t;         {max number of machine adr increments to read}
  out     buf: univ char;              {returned data}
  out     olen: sys_int_adr_t;         {number of machine adresses actually read}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure picprg_sys_usb_write (       {send data to a USBProg}
  in      conn: file_conn_t;           {handle to this file connection}
  in      buf: univ char;              {data to write}
  in      len: sys_int_adr_t;          {number of machine adr increments to write}
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure picprg_thread_in (           {root thread routine, receives from remote}
  in out  pr: picprg_t);               {state for this use of the library}
  val_param; extern;

function picprg_volt_vdd (             {make internal Vdd value from volts}
  in      volts: real)                 {desired value in volts}
  :int8u_t;                            {internal vdd value}
  val_param; extern;

procedure picprg_write_18 (            {array write for program space of PIC18 parts}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_write_18d (           {array write for data space of PIC18 parts}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_write_18f2520 (       {array write for 18F2520 family}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_write_targw (         {array write using programmer WRITE command}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_write_16f72x (        {array write, special for 16F72x config words}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_write_30pgm (         {array write for dsPIC program memory}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
