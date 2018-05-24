{   Public include file for the PICPRG library.
*
*   This library provides a procedural interface to the PICster programmer.
*   This programmer is intended for programming Micropchip PIC microcontrollers.
}
const
  picprg_subsys_k = -48;               {subsystem ID for this library}

  picprg_fwmin_k = 2;                  {min spec version supported by this lib}
  picprg_fwmax_k = 29;                 {max spec version supported by this lib}
  picprg_maxlen_cmd_k = 258;           {max byte length of any command}
  picprg_maxlen_rsp_k = 256;           {max bytes received in any response}
  picprg_maxconfig_k = 16;             {max addresses that store config bits}
  picprg_maxother_k = 16;              {max number of other programmable addresses}
  picprg_cmdq_max_k = 32;              {max number of overlapped commands}
  picprg_vid_k = 5824;                 {USB vendor ID (VID)}
  picprg_pid_k = 1480;                 {USB product ID (PID)}

  picprg_progfw_nover_k = 16#80000000; {allow use of HEX file with no version}
  picprg_cmdq_last_k = picprg_cmdq_max_k - 1; {last valid CMDQ array index}
{
*   Status values unique to the PICPRG subsystem.
}
  picprg_stat_badnbits_k = 1;          {illegal number of bits passed to routine}
  picprg_stat_wrongrsp_k = 2;          {wrong response routine for this command}
  picprg_stat_close_k = 3;             {this use of library is being closed}
  picprg_stat_arg_bad_k = 4;           {unexpected argument}
  picprg_stat_idid_k = 5;              {ID command within ID block in env file}
  picprg_stat_names2_k = 6;            {NAMES previously given this ID block}
  picprg_stat_badvddname_k = 7;        {unrecognized name in VDD command}
  picprg_stat_badfam_k = 8;            {bad PIC family type name}
  picprg_stat_idmissing_k = 9;         {required info missing from ID block}
  picprg_stat_badcmd_k = 11;           {bad env file command name}
  picprg_stat_tkextra_k = 12;          {extra token on env file line}
  picprg_stat_nidblock_k = 13;         {not within an ID block}
  picprg_stat_ideof_k = 14;            {ID block open at end of env file set}
  picprg_stat_idnmatch_k = 16;         {no match found for target chip ID}
  picprg_stat_namenmatch_k = 17;       {no actual name matches expected name}
  picprg_stat_barg_atline_k = 18;      {bad argument on specific line of file}
  picprg_stat_noid_k = 19;             {unable to get valid device ID}
  picprg_stat_unkfam_k = 20;           {unknown PIC family ID encountered}
  picprg_stat_nerase_k = 21;           {no specific erase routine installed}
  picprg_stat_dupadr_k = 22;           {duplicate address in list}
  picprg_stat_ovflcfg_k = 23;          {TINFO config list overflow}
  picprg_stat_ovfloth_k = 24;          {TINFO other list overflow}
  picprg_stat_nconfig_k = 25;          {library not configured}
  picprg_stat_nwrite_k = 26;           {no specific WRITE routine installed}
  picprg_stat_nread_k = 27;            {no specific READ routine installed}
  picprg_stat_cfgmix_k = 28;           {attempt to write config and non-config bits}
  picprg_stat_fwvers1_k = 29;          {firmware version is incompatible, single}
  picprg_stat_fwvers2_k = 30;          {firmware version is incompatible, range}
  picprg_stat_badspace_k = 31;         {invalid or unimplemented adr space ID}
  picprg_stat_namenf_k = 32;           {target chip name not found}
  picprg_stat_badidspace_k = 33;       {invalid or unimplemented ID space}
  picprg_stat_wrongpic_k = 34;         {the target PIC is not the selected PIC}
  picprg_stat_nresp_k = 35;            {no response to command within timeout}
  picprg_stat_cmdnimp_k = 36;          {command not implemented in this firmware}
  picprg_stat_picnimp_k = 37;          {target PIC not implemented in this firmware}
  picprg_stat_restnimp_k = 38;         {reset ID algorithm not implemented}
  picprg_stat_writnimp_k = 39;         {write ID algorithm not implemented}
  picprg_stat_readnimp_k = 40;         {read ID algorithm not implemented}
  picprg_stat_wbufbig_k = 41;          {write buffer size larger than supported}
  picprg_stat_wbufn8_k = 42;           {write buffer size not multiple of 8}
  picprg_stat_vppor_k = 43;            {desired Vpp value is out of range}
  picprg_stat_fwvers1b_k = 44;         {firmware version is incompatible, single}
  picprg_stat_fwvers2b_k = 45;         {firmware version is incompatible, range}
  picprg_stat_notarg_k = 46;           {no specific target chip selected}
  picprg_stat_badvddid_k = 47;         {invalid or unimplemented Vdd ID}
  picprg_stat_baddevconn_k = 48;       {illegal value encountered in DEVCONN field}
  picprg_stat_namprogb_k = 49;         {named programmer busy, already in use}
  picprg_stat_namprognf_k = 50;        {named programmer not found}
  picprg_stat_noprog_k = 51;           {no programmer found}
  picprg_stat_progbusy_k = 52;         {all programmers busy}
  picprg_stat_ovlnout_k = 53;          {no overlapped command awaiting input}
  picprg_stat_unkfamrt_k = 54;         {unknown PIC family ID in named routine}
  picprg_stat_getcap_bad_k = 55;       {unexpected response from GETCAP command}
  picprg_stat_adr_bad_k = 56;          {address invalid for this target}
  picprg_stat_verr_data_k = 57;        {verify error in data address space}
  picprg_stat_verr_prog_k = 58;        {verify error in program address space}
  picprg_stat_nsupp_opt_k = 59;        {target not supported with current options}
  picprg_stat_badnbytes_k = 60;        {bad number of bytes, <actual> <min> <max>}

type
  picprg_p_t = ^picprg_t;              {pointer to library use state}

  picprg_org_k_t = (                   {IDs for organizations creating firmware}
    picprg_org_min_k = 1,              {min allowed organization ID ordinal}
    picprg_org_official_k = 1,         {organization in charge of official releases}
    picprg_org_philpemberton_k = 2,    {Philip Pemberton}
    picprg_org_radianse_k = 3,         {Radianse}
    picprg_org_max_k = 254);           {max allowed organization ID ordinal}

  picprg_org_t = record                {definition of one software creating org}
    name: string_var80_t;              {arbitrary name string}
    webpage: string_var1024_t;         {web page URL without http://, lower case}
    end;

  picprg_orgs_t =                      {info about all possible organization IDs}
    array[picprg_org_min_k .. picprg_org_max_k] of picprg_org_t;

  picprg_fwid_k_t = (                  {firmware type IDs in the official line}
    picprg_fwid_easyprog_k = 0,        {standard EasyProg firmware}
    picprg_fwid_proprog_k = 1,         {standard ProProg firmware}
    picprg_fwid_usbprog_k = 2,         {standard USBProg or USBProg2 firmware}
    picprg_fwid_lprog_k = 3,           {standard LProg firmware}
    picprg_fwid_occtest_k = 4);        {OC1 product tester}

  picprg_picfam_k_t = (                {IDs for the different PIC families}
    picprg_picfam_unknown_k,           {PIC family type is unknown}
    picprg_picfam_10f_k,               {PIC 10Fxxx}
    picprg_picfam_12f_k,               {generic 12 bit core}
    picprg_picfam_16f_k,               {generic 16F, like 16F877}
    picprg_picfam_12f6xx_k,            {PIC 12F629, 12F675}
    picprg_picfam_12f1501_k,           {enhanced 14 bit core without EEPROM}
    picprg_picfam_16f77_k,             {PIC 16F77 and related}
    picprg_picfam_16f88_k,             {PIC 16F87/88}
    picprg_picfam_16f61x_k,            {PIC 12F60x, 12F61x, 16F61x}
    picprg_picfam_16f62x_k,            {PIC 16F62x}
    picprg_picfam_16f62xa_k,           {PIC 16F62xA}
    picprg_picfam_16f688_k,            {PIC 16F688 and related}
    picprg_picfam_16f716_k,            {PIC 16F716}
    picprg_picfam_16f7x7_k,            {PIC 16F7x7}
    picprg_picfam_16f720_k,            {PIC 18F720/721}
    picprg_picfam_16f72x_k,            {PIC 16F72x}
    picprg_picfam_16f84_k,             {PIC 16F84, 16F83}
    picprg_picfam_16f87xa_k,           {PIC 16F87xA}
    picprg_picfam_16f88x_k,            {PIC 16F88x}
    picprg_picfam_16f182x_k,           {PIC 16F182x}
    picprg_picfam_18f_k,               {generic 18F, like 18F452}
    picprg_picfam_18f2520_k,           {18F2520 and related}
    picprg_picfam_18f2523_k,           {18F2523 and related}
    picprg_picfam_18f6680_k,           {18F6680 and related}
    picprg_picfam_18f6310_k,           {18f6310 and related}
    picprg_picfam_18j_k,               {18F25J10 and related}
    picprg_picfam_18k80_k,             {18FxxK80}
    picprg_picfam_18f14k22_k,          {18FxxK22}
    picprg_picfam_18f14k50_k,          {18FxxK50}
    picprg_picfam_30f_k,               {PIC 30 (dsPIC)}
    picprg_picfam_24h_k,               {24H and 33F dsPIC types}
    picprg_picfam_24f_k,               {24F parts}
    picprg_picfam_24fj_k,              {24FJ parts}
    picprg_picfam_33ep_k);             {24EP and 33EP}

  picprg_reset_k_t = (                 {IDs for the possible reset algorithms}
    picprg_reset_none_k = 0,           {no algorithm, dummy routine used}
    picprg_reset_62x_k = 1,            {Vpp on before Vdd, like 16F62x}
    picprg_reset_18f_k = 2,            {Vdd on before Vpp, like 18Fxxx}
    picprg_reset_dpna_k = 3,           {Vdd before Vpp, target address unknown}
    picprg_reset_30f_k = 4,            {for 30F (dsPIC)}
    picprg_reset_vddvppf_k = 5,        {Vdd then Vpp as quickly as possible}
    picprg_reset_18j_k = 6,            {special unlock used by 18F25J10 and others}
    picprg_reset_24h_k = 7,            {24H and 33F dsPIC types}
    picprg_reset_24f_k = 8,            {24F parts}
    picprg_reset_16f182x_k = 9,        {no Vpp, special signature for 16F182x}
    picprg_reset_24fj_k = 10,          {24FJ parts}
    picprg_reset_18k80_k = 11,         {18FxxK80 high voltage program mode entry}
    picprg_reset_33ep_k = 12);         {24EP and 33EP parts}

  picprg_reset_t = set of bitsize 32 eletype picprg_reset_k_t;

  picprg_write_k_t = (                 {IDs for the possible write algorithms}
    picprg_write_none_k = 0,           {no algorithm, dummy routine used}
    picprg_write_16f_k = 1,            {BEGIN PROG 24}
    picprg_write_12f6_k = 2,           {BEGIN PROG 8}
    picprg_write_core12_k = 3,         {12 bit core devices}
    picprg_write_30f_k = 4,            {for 30F (dsPIC)}
    picprg_write_16fa_k = 5,           {BEGIN PROG 24, END PROG 23, config BEGIN PROG 8 no END}
    picprg_write_16f716_k = 6,         {BEGIN PROG 24, END PROG 14}
    picprg_write_16f688_k = 7,         {BEGIN PROG 8}
    picprg_write_18f2520_k = 8,        {18F2520 and related}
    picprg_write_16f88_k = 9,          {BEGIN PROG 24, END PROG 23}
    picprg_write_16f77_k = 10,         {BEGIN PROG 8, END PROG 14}
    picprg_write_16f88x_k = 11,        {BEGIN PROG 24, END PROG 10}
    picprg_write_16f182x_k = 12);      {BEGIN PROG 24 END PROG 10, config: BEGIN PROG 8}
  picprg_write_t = set of bitsize 32 eletype picprg_write_k_t;

  picprg_read_k_t = (                  {IDs for the possible read algorithms}
    picprg_read_none_k = 0,            {no algorithm, dummy routine used}
    picprg_read_16f_k = 1,             {generic 16F PIC}
    picprg_read_18f_k = 2,             {generic 18F PIC, program space only}
    picprg_read_core12_k = 3,          {12 bit core devices}
    picprg_read_30f_k = 4,             {for 30F (dsPIC)}
    picprg_read_18fe_k = 5,            {generic 18F, both program and EEPROM space}
    picprg_read_16fe_k = 6);           {enhanced (4 digit) 16F}
  picprg_read_t = set of bitsize 32 eletype picprg_read_k_t;

  picprg_space_k_t = (                 {IDs for the different target address spaces}
    picprg_space_prog_k,               {program memory address space}
    picprg_space_data_k);              {data (EEPROM) memory address space}

  picprg_idspace_k_t = (               {name space for target chip ID in PICPRG.ENV}
    picprg_idspace_unk_k,              {ID space unknown}
    picprg_idspace_16_k,               {generic PIC16, 14 bit ID word}
    picprg_idspace_18_k,               {generic PIC18, 16 bit ID word}
    picprg_idspace_12_k,               {generic 12 bit core, no chip ID}
    picprg_idspace_30_k);              {PIC 30 (dsPIC)}

  picprg_pininfo_k_t = (               {individual flags from PINS command}
    picprg_pininfo_le18_k);            {target chip has 18 or fewer pins}
  picprg_pininfo_t = set of picprg_pininfo_k_t;

  picprg_chipid_t = sys_int_conv32_t;  {hard coded target chip device ID word}
  picprg_adr_t = 0 .. 16#FFFFFF;       {target device address}
  picprg_dat_t = 0 .. 16#FFFF;         {one target data word}

  picprg_datar_t =                     {array of data values for consecutive adr}
    array[0 .. 16#FFFFFF] of picprg_dat_t; {max size declared, not used directly}
  picprg_datar_p_t = ^picprg_datar_t;

  picprg_pandat8_t =                   {data for 18xxx 8 byte panel writes}
    array[0 .. 7] of int8u_t;

  picprg_8byte_t =                     {buffer of 8 data bytes}
    array[0 .. 7] of int8u_t;

  picprg_bytes_t =                     {buffer of up to 256 bytes}
    array[0 .. 255] of int8u_t;

  picprg_pcap_k_t = (                  {IDs for the GETCAP capabilities}
    picprg_pcap_varvdd_k = 0,          {variable Vdd}
    picprg_pcap_reset_k = 1,           {supported reset algorithms}
    picprg_pcap_write_k = 2,           {supported write algorithms}
    picprg_pcap_read_k = 3,            {supported read algorithms}
    picprg_pcap_vpp_k = 4);            {supported Vpp range}

  picprg_fw_t = record                 {firmware version info}
    org: picprg_org_k_t;               {ID of the creating organization}
    cvlo: int8u_t;                     {lowest spec vers backward compatible to}
    cvhi: int8u_t;                     {highest spec vers compatible with}
    vers: int8u_t;                     {1-254 version within this ORG and ID}
    id: int8u_t;                       {firmware type ID}
    idname: string_var80_t;            {firmware type name, decimal ID value on no name}
    info: sys_int_conv32_t;            {32 bit data private to the organization}
    idreset: picprg_reset_t;           {set of supported reset algorithms}
    idwrite: picprg_write_t;           {set of supported write algorithms}
    idread: picprg_read_t;             {set of supported read algorithms}
    varvdd: boolean;                   {variable Vdd is supported}
    vddmin, vddmax: real;              {min/max Vdd voltage range programmer can do}
    vppmin, vppmax: real;              {min/max Vpp voltage range programmer can do}
    ticksec: real;                     {clock tick period in seconds}
    ftickf: real;                      {fast tick frequency in Hz, 0 = not used}
    cmd: array[0 .. 255] of boolean;   {TRUE if command supported in this firmware}
    end;

  picprg_vdd_k_t = (                   {IDs for the various Vdd settings}
    picprg_vdd_low_k,                  {low level for verify}
    picprg_vdd_norm_k,                 {normal level, for programming and erase}
    picprg_vdd_high_k);                {high level for verify}

  picprg_vddvals_t = record            {target chip Vdd voltage levels}
    low: real;                         {low voltage for verify}
    norm: real;                        {normal voltage, used for programming}
    high: real;                        {high voltage for verify}
    twover: boolean;                   {LOW and HIGH different, two verify required}
    end;

  picprg_idname_p_t = ^picprg_idname_t;
  picprg_idname_t = record             {info for one name within ID block}
    next_p: picprg_idname_p_t;         {points to next name in chain for this block}
    name: string_var32_t;              {specific chip name, upper case}
    vdd: picprg_vddvals_t;             {the Vdd levels for this specific chip}
    end;

  picprg_adrent_p_t = ^picprg_adrent_t;
  picprg_adrent_t = record             {one entry in list of address specs}
    next_p: picprg_adrent_p_t;         {pointer to next list entry}
    adr: picprg_adr_t;                 {the address}
    mask: picprg_dat_t;                {mask of valid bits at this address}
    val: picprg_dat_t;                 {current value of this word, if known}
    kval: boolean;                     {current value in VAL is known}
    end;

  picprg_maskdat_t = record            {mask for valid bits of a data word}
    maske: picprg_dat_t;               {mask for data at even addresses}
    masko: picprg_dat_t;               {mask for data at odd addresses}
    end;
  picprg_maskdat_p_t = ^picprg_maskdat_t;

  picprg_idblock_p_t = ^picprg_idblock_t;
  picprg_idblock_t = record            {info from one ID block in environment file}
    next_p: picprg_idblock_p_t;        {pointer to next ID block in chain}
    idspace: picprg_idspace_k_t;       {name space for chip ID}
    mask: picprg_chipid_t;             {mask for relevant bits in device ID word}
    id: picprg_chipid_t;               {ID word with masked-off bits set to 0}
    vdd: picprg_vddvals_t;             {default Vdd when no name specified}
    vppmin, vppmax: real;              {min/max allowable Vpp voltage range}
    name_p: picprg_idname_p_t;         {pnt to start of specific names chain}
    rev_mask: picprg_chipid_t;         {mask for revision field within device ID}
    rev_shft: sys_int_machine_t;       {bits to shift revision field right}
    wbufsz: sys_int_machine_t;         {write buffer size}
    wbstrt, wblen: sys_int_machine_t;  {address range over which WBUFSZ applies}
    pins: sys_int_machine_t;           {number of pins}
    nprog: picprg_adr_t;               {number of program memory locations}
    ndat: picprg_adr_t;                {number of data memory (EEPROM) locations}
    adrres: picprg_adr_t;              {target chip address when reset}
    maskprg: picprg_maskdat_t;         {valid bits mask within program memory word}
    maskdat: picprg_maskdat_t;         {valid bits mask within data memory word}
    datmap: picprg_adr_t;              {address where data memory mapped in HEX file}
    tprogp: real;                      {seconds to wait after program mem write}
    tprogd: real;                      {seconds to wait after data EEPROM write}
    config_p: picprg_adrent_p_t;       {pointer to list of config word addresses}
    other_p: picprg_adrent_p_t;        {pointer to list of other valid addresses}
    fam: picprg_picfam_k_t;            {PIC family ID}
    eecon1: sys_int_machine_t;         {adr of EECON1 reg, used on PIC 18}
    eeadr: sys_int_machine_t;          {adr of EEADR reg, used on PIC 18}
    eeadrh: sys_int_machine_t;         {adr of EEADRH reg, 0 = none, used on PIC 18}
    eedata: sys_int_machine_t;         {adr of EEDATA reg, used on PIC 18}
    visi: sys_int_machine_t;           {adr of VISI reg}
    tblpag: sys_int_machine_t;         {adr of TBLPAG reg}
    nvmcon: sys_int_machine_t;         {adr of NVMCON reg}
    nvmkey: sys_int_machine_t;         {adr of NVMKEY reg}
    nvmadr: sys_int_machine_t;         {adr of NVMADR reg}
    nvmadru: sys_int_machine_t;        {adr of NVMADRU reg}
    hdouble: boolean;                  {HEX file addresses doubled}
    eedouble: boolean;                 {EEPROM adressess in HEX file doubled beyond HDOUBLE}
    end;

  picprg_env_t = record                {all the info read from PICPRG.ENV file set}
    org: picprg_orgs_t;                {info about all possible organization IDs}
    idblock_p: picprg_idblock_p_t;     {pointer to first ID block}
    end;
  picprg_env_p_t = ^picprg_env_t;

  picprg_tinfo_t = record              {info about the target chip}
    name: string_var32_t;              {specific name of the chip, like 16LF876, ucase}
    name1: string_var32_t;             {first listed name for this ID block, ucase}
    idspace: picprg_idspace_k_t;       {name space for chip ID}
    id: picprg_chipid_t;               {complete device ID word}
    rev_mask: picprg_chipid_t;         {mask for revision field within device ID}
    rev_shft: sys_int_machine_t;       {bits to shift revision field right}
    rev: sys_int_machine_t;            {revision number from device ID word}
    vdd: picprg_vddvals_t;             {Vdd levels for this chip}
    vppmin, vppmax: real;              {min/max allowable Vpp voltage range}
    wbufsz: sys_int_machine_t;         {write buffer size}
    wbstrt, wblen: sys_int_machine_t;  {address range over which WBUFSZ applies}
    pins: sys_int_machine_t;           {number of pins}
    nprog: picprg_adr_t;               {number of program memory locations}
    ndat: picprg_adr_t;                {number of data memory (EEPROM) locations}
    adrres: picprg_adr_t;              {target chip address when reset}
    maskprg: picprg_maskdat_t;         {valid bits mask within program memory word}
    maskdat: picprg_maskdat_t;         {valid bits mask within data memory word}
    datmap: picprg_adr_t;              {address where data memory mapped in HEX file}
    tprogp: real;                      {seconds to wait after program mem write}
    tprogd: real;                      {seconds to wait after data EEPROM write}
    nconfig: sys_int_machine_t;        {number of CONFIG addresses in list}
    config_p: picprg_adrent_p_t;       {pointer to list of config word addresses}
    nother: sys_int_machine_t;         {number of OTHER addresses in list}
    other_p: picprg_adrent_p_t;        {pointer to list of other valid addresses}
    fam: picprg_picfam_k_t;            {PIC family ID}
    eecon1: sys_int_machine_t;         {12 bit address of EECON1 reg on PIC 18}
    eeadr: sys_int_machine_t;          {adr of EEADR reg, used on PIC 18}
    eeadrh: sys_int_machine_t;         {adr of EEADRH reg, 0 = none, used on PIC 18}
    eedata: sys_int_machine_t;         {adr of EEDATA reg, used on PIC 18}
    visi: sys_int_machine_t;           {adr of VISI reg}
    tblpag: sys_int_machine_t;         {adr of TBLPAG reg}
    nvmcon: sys_int_machine_t;         {adr of NVMCON reg}
    nvmkey: sys_int_machine_t;         {adr of NVMKEY reg}
    nvmadr: sys_int_machine_t;         {adr of NVMADR reg}
    nvmadru: sys_int_machine_t;        {adr of NVMADRU reg}
    hdouble: boolean;                  {HEX file addresses doubled}
    eedouble: boolean;                 {EEPROM adressess in HEX file doubled beyond HDOUBLE}
    end;

  picprg_buf_cmd_t = record            {info about command bytes to send}
    nbuf: sys_int_machine_t;           {number of bytes}
    buf:                               {the bytes}
      array[1 .. picprg_maxlen_cmd_k] of int8u_t;
    end;

  picprg_buf_rsp_t = record            {info about response to one command}
    lenby: sys_int_machine_t;          {index of length byte, 0 = none}
    nresp: sys_int_machine_t;          {number of bytes expected not counting ACK}
    nbuf: sys_int_machine_t;           {number of bytes received so far}
    ack: boolean;                      {ACK received for this command}
    buf:                               {the received bytes}
      array[1 .. picprg_maxlen_rsp_k] of int8u_t;
    end;

  picprg_cmd_p_t = ^picprg_cmd_t;
  picprg_cmd_t = record                {info for one remote system command/response}
    prev_p: picprg_cmd_p_t;            {pointer to previous queued command}
    next_p: picprg_cmd_p_t;            {pointer to next queued command}
    send: picprg_buf_cmd_t;            {output bytes buffer and info}
    recv: picprg_buf_rsp_t;            {input bytes buffer and info}
    done: sys_sys_event_id_t;          {event that is signalled when command done}
    end;

  picprg_cmdovl_t = record             {state for sending overlapped commands}
    cmd: array[0 .. picprg_cmdq_last_k] of picprg_cmd_t; {circular queue of descriptors}
    nexto: sys_int_machine_t;          {0-N index of next output descriptor to use}
    nexti: sys_int_machine_t;          {0-N index of next descriptor to get input from}
    use: array[0 .. picprg_cmdq_last_k] of boolean; {TRUE if command descriptor in use}
    end;

  picprg_erase_p_t = ^procedure (      {subroutine to erase the target chip}
    in      pr_p: picprg_p_t;          {pointer to library use state}
    out     stat: sys_err_t);          {completion status}
    val_param;

  picprg_write_p_t = ^procedure (      {subroutine to write array to target chip}
    in      pr_p: picprg_p_t;          {pointer to library use state}
    in      adr: picprg_adr_t;         {starting address to write to}
    in      n: picprg_adr_t;           {number of locations to write to}
    in      dat: univ picprg_datar_t;  {array of data to write}
    in      mask: picprg_maskdat_t;    {mask for valid bits in each data word}
    out     stat: sys_err_t);          {completion status}
    val_param;

  picprg_read_p_t = ^procedure (       {subroutine to read array from target chip}
    in      pr_p: picprg_p_t;          {pointer to library use state}
    in      adr: picprg_adr_t;         {starting address to read from}
    in      n: picprg_adr_t;           {number of locations to read from}
    in      mask: picprg_maskdat_t;    {mask for valid data bits}
    out     dat: univ picprg_datar_t;  {the returned data array, unused bits 0}
    out     stat: sys_err_t);          {completion status}
    val_param;

  picprg_flag_k_t = (                  {general control flags, all default to off}
    picprg_flag_showin_k,              {show input stream from programmer}
    picprg_flag_showout_k,             {show output stream to programmer}
    picprg_flag_nintout_k,             {no input stream timeout}
    picprg_flag_w1_k,                  {write one word at a time, reset by write}
    picprg_flag_ack_k);                {programmer sends ACK for all valid commands}
  picprg_flags_t = set of picprg_flag_k_t;

  picprg_devconn_k_t = (               {ID for type of connection to programmer}
    picprg_devconn_unk_k,              {unknown}
    picprg_devconn_sio_k,              {system serial line, number in UNIT}
    picprg_devconn_enum_k,             {open enumeratable named device, pathname in PATH}
    picprg_devconn_usb_k);             {connected via USB}

  picprg_dev_p_t = ^picprg_dev_t;
  picprg_dev_t = record                {info about one known programmer device}
    next_p: picprg_dev_p_t;            {pointer to next programmer}
    name: string_var80_t;              {programmer name string}
    devconn: picprg_devconn_k_t;       {type of connection to the programmer}
    unit: sys_int_conv32_t;            {optional unit number, specific to DEVCONN}
    path: string_treename_t;           {optional pathname, specific to DEVCONN}
    end;

  picprg_devs_t = record               {list of known programmers connected to this system}
    mem_p: util_mem_context_p_t;       {pointer to memory context for all list memory}
    n: sys_int_machine_t;              {number of programmers in the list}
    list_p: picprg_dev_p_t;            {pointer to first list entry}
    last_p: picprg_dev_p_t;            {pointer to last list entry}
    end;

  picprg_t = record                    {state for one use of the PICPRG library}
    devconn: picprg_devconn_k_t;       {type of device connection to open or is in use}
    sio: sys_int_machine_t;            {system serial line number}
    prgname: string_var80_t;           {prog name to open, actual name after open}
    mem_p: util_mem_context_p_t;       {pointer to mem context for this library use}
    conn: file_conn_t;                 {I/O connection to the programmer}
    fwinfo: picprg_fw_t;               {info about the programmer firmware}
    ready: sys_sys_event_id_t;         {signalled when ready to send next command}
    cmd_inq_p: picprg_cmd_p_t;         {pointer to curr CMD descriptor awaiting input}
    cmd_inq_last_p: picprg_cmd_p_t;    {pointer to last CMD awaiting input}
    lock_cmd: sys_sys_threadlock_t;    {interlock for pending commands pointers}
    erase_p: picprg_erase_p_t;         {pointer to ERASE subroutine}
    write_p: picprg_write_p_t;         {pointer to ARRAY WRITE subroutine}
    read_p: picprg_read_p_t;           {pointer to ARRAY READ subroutine}
    env: picprg_env_t;                 {info from environment file set}
    thid_in: sys_sys_thread_id_t;      {ID of input receiving thread}
    id: picprg_chipid_t;               {ID from target chip, including rev, init 0}
    id_p: picprg_idblock_p_t;          {pnt to target ID info, initially NIL}
    name_p: picprg_idname_p_t;         {pnt specific named target, initially NIL}
    space: picprg_space_k_t;           {ID for current target address space}
    flags: picprg_flags_t;             {various control flags}
    debug: sys_int_machine_t;          {0-10 debug level, 0 = production mode}
    vdd: picprg_vddvals_t;             {Vdd levels to use for the current chip}
    lvpenab, hvpenab: boolean;         {low/high voltage program entry modes allowed}
    quit: boolean;                     {trying to close}
    end;

  picprg_used_p_t = ^picprg_used_t;
  picprg_used_t =                      {flags indicating addresses used in HEX file}
    array[firstof(picprg_adr_t) .. lastof(picprg_adr_t)] {max size declare, not used directly}
    of boolean;

  picprg_tdat_p_t = ^picprg_tdat_t;
  picprg_tdat_t = record               {info about all data to be programmed into target}
    pr_p: picprg_p_t;                  {points to PICPRG library state associated with}
    mem_p: util_mem_context_p_t;       {points to mem context for all dynamic memory}
    val_prog_p: picprg_datar_p_t;      {points to program memory values}
    used_prog_p: picprg_used_p_t;      {points to list of used program memory addresses}
    val_data_p: picprg_datar_p_t;      {points to data memory values}
    used_data_p: picprg_used_p_t;      {points to list of used data memory addresses}
    val_cfg_p: picprg_datar_p_t;       {points to list of config words}
    ncfg: sys_int_machine_t;           {number of config words in the list}
    val_oth_p: picprg_datar_p_t;       {points to list of other locations}
    noth: sys_int_machine_t;           {number of other locations in the list}
    vdd: real;                         {normal Vdd level or single when VDD1 TRUE}
    vdd1: boolean;                     {perform all operations at the single VDD level in VDD}
    hdouble: boolean;                  {addresses in HEX file are doubled}
    eedouble: boolean;                 {EEPROM addresses doubled after HDOUBLE applied}
    end;

  picprg_progflag_k_t = (              {options for program and verify operations}
    picprg_progflag_stdout_k,          {show progress on standard output}
    picprg_progflag_nover_k,           {do not perform any verification}
    picprg_progflag_verhex_k);         {verify only addresses in HEX file, not all}
  picprg_progflags_t = set of picprg_progflag_k_t;

  picprg_verflag_k_t = (               {options for verify operations}
    picprg_verflag_stdout_k,           {show progress on standard output}
    picprg_verflag_prog_k,             {verify program memory}
    picprg_verflag_data_k,             {verify data eeprom}
    picprg_verflag_other_k,            {verify other locations}
    picprg_verflag_config_k,           {verify config words}
    picprg_verflag_hex_k);             {verify only data explicitly in HEX file}
  picprg_verflags_t = set of picprg_verflag_k_t;
{
*   General library routines not specific to individual programmer commands.
}
procedure picprg_add_i8u (             {add 8 bit unsigned int to cmd out stream}
  in out  cmd: picprg_cmd_t;           {the command to add data to}
  in      val: sys_int_machine_t);     {the value to add}
  val_param; extern;

procedure picprg_add_i16u (            {add 16 bit unsigned int to cmd out stream}
  in out  cmd: picprg_cmd_t;           {the command to add data to}
  in      val: int16u_t);              {the value to add}
  val_param; extern;

procedure picprg_add_i24u (            {add 24 bit unsigned int to cmd out stream}
  in out  cmd: picprg_cmd_t;           {the command to add data to}
  in      val: sys_int_conv24_t);      {the value to add}
  val_param; extern;

procedure picprg_add_i32u (            {add 32 bit unsigned int to cmd out stream}
  in out  cmd: picprg_cmd_t;           {the command to add data to}
  in      val: sys_int_conv32_t);      {the value to add}
  val_param; extern;

procedure picprg_close (               {end a use of this library}
  in out  pr: picprg_t;                {library use state, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_expect (          {indicate size of response expected from command}
  in out  cmd: picprg_cmd_t;           {command descriptor}
  in      n: sys_int_machine_t;        {number of fixed bytes always sent}
  in      lenb: sys_int_machine_t);    {1-N index of length byte, 0 = fixed size response}
  val_param; extern;

procedure picprg_cmd_start (           {start for sending a command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {returned command descriptor, will be initialized}
  in      opc: sys_int_machine_t;      {0-255 command opcode}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdovl_flush (        {wait for all pending commands to complete}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  ovl: picprg_cmdovl_t;        {overlapped commands structure}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdovl_in (           {get next command waiting on input}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  ovl: picprg_cmdovl_t;        {overlapped commands control structure}
  out     in_p: picprg_cmd_p_t;        {pointer to next command awaiting input}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdovl_init (         {initialize overalpped commands state}
  out     ovl: picprg_cmdovl_t);       {structure to initialize}
  val_param; extern;

procedure picprg_cmdovl_out (          {make a new command descriptor avail if possible}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  ovl: picprg_cmdovl_t;        {overlapped commands control structure}
  out     out_p: picprg_cmd_p_t;       {pointer to new descriptor, NIL for none}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdovl_outw (         {get new command descriptor, wait as necessary}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  ovl: picprg_cmdovl_t;        {overlapped commands control structure}
  out     out_p: picprg_cmd_p_t;       {pointer to new descriptor}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_config (              {configure library for specific target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  in      name: univ string_var_arg_t; {expected name, blank gets default for ID}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_erase (               {erase all erasable non-volatile target mem}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_fw_check (            {check firmware compatibility}
  in out  pr: picprg_t;                {state for this use of the library}
  in      fw: picprg_fw_t;             {firmware information}
  out     stat: sys_err_t);            {completion status, error if FW incompatible}
  val_param; extern;

procedure picprg_fw_show1 (            {show firmware: version, org name}
  in out  pr: picprg_t;                {state for this use of the library}
  in      fw: picprg_fw_t;             {firmware information}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_fwinfo (              {get all info about programmer firmware}
  in out  pr: picprg_t;                {state for this use of the library}
  out     fwinfo: picprg_fw_t;         {returned information about programmer FW}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_id (                  {get the hard coded ID of the target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  in      id_p: picprg_idblock_p_t;    {pointer to descriptor for this target chip}
  out     idspace: picprg_idspace_k_t; {namespace the chip ID is within}
  out     id: picprg_chipid_t;         {returned chip ID in low bits, 0 = none}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_init (                {initialize library state to defaults}
  out     pr: picprg_t);               {returned ready to pass to OPEN}
  val_param; extern;

procedure picprg_list_del (            {delete list of programmers, deallocate resources}
  in out  devs: picprg_devs_t);        {returned invalid}
  val_param; extern;

procedure picprg_list_get (            {get list of known programmers}
  in out  mem: util_mem_context_t;     {parent memory context to create list context from}
  out     devs: picprg_devs_t);        {returned list, all fields overwritten}
  val_param; extern;

function picprg_mask (                 {get mask of valid data bits at address}
  in      mask: picprg_maskdat_t;      {information about valid bits}
  in      adr: picprg_adr_t)           {target chip address of this data word}
  :picprg_dat_t;                       {returned mask of valid data bits}
  val_param; extern;

procedure picprg_mask_same (           {make mask info with one mask for all cases}
  in      mask: picprg_dat_t;          {the mask to apply in all cases}
  out     maskdat: picprg_maskdat_t);  {returned mask info}
  val_param; extern;

function picprg_maskit (               {apply valid bits mask to data word}
  in      dat: picprg_dat_t;           {data word to mask}
  in      mask: picprg_maskdat_t;      {information about valid bits}
  in      adr: picprg_adr_t)           {target chip address of this data word}
  :picprg_dat_t;                       {returned DAT with all unused bits zero}
  val_param; extern;

procedure picprg_off (                 {disengage from target to the extent possible}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_open (                {open a new use of this library}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_prog_fw (             {program particular firmware into target PIC}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dir: univ string_var_arg_t;  {directory containing HEX file}
  in      fwname: univ string_var_arg_t; {firmware name}
  in      ver: sys_int_machine_t;      {firmware version, 0 for unnumbered}
  in      pic: univ string_var_arg_t;  {PIC model like "16F876", case insensitive}
  in      flags: picprg_progflags_t;   {set of option flags}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_prog_hexfile (        {program HEX file into traget PIC}
  in out  pr: picprg_t;                {state for this use of the library}
  in      fnam: univ string_var_arg_t; {pathname of the HEX file}
  in      pic: univ string_var_arg_t;  {PIC model like "16F876", case insensitive}
  in      flags: picprg_progflags_t;   {set of option flags}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_progtime (            {set programming time}
  in out  pr: picprg_t;                {state for this use of the library}
  in      progt: real;                 {programming time, seconds}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_read (                {read data from target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to read from}
  in      n: picprg_adr_t;             {number of locations to read from}
  in      mask: picprg_maskdat_t;      {mask for valid data bits}
  out     dat: univ picprg_datar_t;    {the returned data array, unused bits 0}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_recv (                {read serial bits from targ, use optimum cmd}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {0-32 number of bits to read}
  out     dat: sys_int_conv32_t;       {returned bits shifted into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_reset (               {reset the target chip and associated state}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_send (                {send serial bits to target, use optimum cmd}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {0-32 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_send_cmd (            {send a command to the remote unit}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {the command to send}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_space_set (           {select address space for future operations}
  in out  pr: picprg_t;                {state for this use of the library}
  in      space: picprg_space_k_t;     {ID for the new selected target memory space}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_tdat_alloc (          {allocate target address data descriptor}
  in out  pr: picprg_t;                {state for this use of the library}
  out     tdat_p: picprg_tdat_p_t;     {pnt to newly created and initialized descriptor}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_tdat_dealloc (        {deallocate target address data descriptor}
  in out  tdat_p: picprg_tdat_p_t);    {pointer to descriptor to deallocate, returned NIL}
  val_param; extern;

procedure picprg_tdat_hex_byte (       {add one byte from HEX file to target data to program}
  in out  tdat: picprg_tdat_t;         {target data to add the byte to}
  in      dat: int8u_t;                {the data byte from the HEX file}
  in      adr: int32u_t;               {the address from the HEX file}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_tdat_hex_read (       {read HEX file data, build info about what to program}
  in out  tdat: picprg_tdat_t;         {program target info to update}
  in out  ihn: ihex_in_t;              {connection to input HEX file}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_tdat_prog (           {perform complete program and verify operations}
  in      tdat: picprg_tdat_t;         {info about what to program}
  in      flags: picprg_progflags_t;   {set of option flags}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_tdat_vdd1 (           {indicate to perform program and verify at single Vdd level}
  in out  tdat: picprg_tdat_t;         {target programming information}
  in      vdd: real);                  {the single Vdd level for all operations}
  val_param; extern;

procedure picprg_tdat_vddlev (         {set one of selected Vdd levels}
  in      tdat: picprg_tdat_t;         {target programming information}
  in      vddid: picprg_vdd_k_t;       {ID for the selected Vdd level}
  out     vdd: real;                   {actual resulting Vdd level in volts}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

function picprg_tdat_verify (          {verify actual target data against desired}
  in      tdat: picprg_tdat_t;         {info about what to program}
  in      flags: picprg_verflags_t;    {set of option flags}
  out     stat: sys_err_t)             {completion status}
  :boolean;                            {all verified memory matched expected value}
  val_param; extern;

procedure picprg_tinfo (               {get detailed info about the target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  out     tinfo: picprg_tinfo_t;       {returned detailed target chip info}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_vddlev (              {set Vdd level for next time enabled}
  in out  pr: picprg_t;                {state for this use of the library}
  in      vddid: picprg_vdd_k_t;       {ID for the new level to set to}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_vddset (              {set Vdd for specified level next reset}
  in out  pr: picprg_t;                {state for this use of the library}
  in      vin: real;                   {desired Vdd level in volts}
  out     vout: real;                  {actual Vdd level selected}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_wait_cmd (            {wait for a command to complete}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {the command, system resources released}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_wait_cmd_tout (       {wait for command to complete or timeout}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {the command, system resources released}
  in      tout: real;                  {maximum time to wait, seconds}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_write (               {write array of data to the target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {starting address to write to}
  in      n: picprg_adr_t;             {number of locations to write}
  in      dat: univ picprg_datar_t;    {array of data to write}
  in      mask: picprg_maskdat_t;      {mask for valid bits in each data word}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_write8b (             {write 8 bytes, uses WRITE or WRITE8 cmd}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  ovl: picprg_cmdovl_t;        {overlapped commands state}
  in      dat: univ picprg_datar_t;    {8 data words to write, only low bytes used}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
{
*   Command routines.  These routines each start a new command to be sent to
*   the remote system and return.  The caller must supply a CMD structure,
*   which will be initialized as needed.  The CMD structure is returned
*   and is used to track the progress of the command.  It must eventually
*   be passed to the PICPRG_RSP_xxx routine of the same name as the command.
*   These are described below.
}
procedure picprg_cmd_nop (             {send NOP command, just sends ACK back}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_off (             {turn off power to target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_pins (            {get info about target chip pins}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_send1 (           {send up to 8 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-8 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_send2 (           {send up to 16 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-16 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_send3 (           {send up to 24 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-24 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_send4 (           {send up to 32 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-32 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_recv1 (           {read up to 8 serial bits from the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-8 number of bits to read}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_recv2 (           {read up to 16 serial bits from the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-8 number of bits to read}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_recv3 (           {read up to 24 serial bits from the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-8 number of bits to read}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_recv4 (           {read up to 32 serial bits from the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      n: sys_int_machine_t;        {1-8 number of bits to read}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_clkh (            {set the serial clock line high}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_clkl (            {set the serial clock line low}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_dath (            {set the serial data line high}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_datl (            {set the serial data line low}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_datr (            {read the data line as driven by the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_tdrive (          {test whether target is driving data line}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_fwinfo (          {get firmware version and other info}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_fwinfo2 (         {get additional firmware info}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_vddvals (         {set target chip Vdd levels}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      vlo: real;                   {low Vdd level, volts}
  in      vnr: real;                   {normal Vdd level, volts}
  in      vhi: real;                   {high Vdd level, volts}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_vddlow (          {set target Vdd to the low level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_vddnorm (         {set target Vdd to the normal level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_vddhigh (         {set target Vdd to the high level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_vddoff (          {set target Vdd to off (0 volts)}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_vppon (           {turn on target programming voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_vppoff (          {turn off target programming voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_vpphiz (          {set Vpp line to high impedence}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_idreset (         {select reset algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      id: picprg_reset_k_t;        {reset algorithm ID}
  in      offvddvpp: boolean;          {Vdd then Vpp when turn off target}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_idwrite (         {select write algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      id: picprg_write_k_t;        {write algorithm ID}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_idread (          {select read algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      id: picprg_read_k_t;         {read algorithm ID}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_resadr (          {indicate target chip address after reset}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      resadr: picprg_adr_t;        {address to assume after target chip reset}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_reset (           {reset target chip, ready for programming}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_test1 (           {send debugging TEST1 command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_test2 (           {send debugging TEST2 command}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_machine_t;      {parameter byte value}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_adr (             {set address of next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: picprg_adr_t;           {target address for next operation}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_read (            {read from target, increment address}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_write (           {write to target, increment address}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      dat: picprg_dat_t;           {the data to write}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_tprog (           {set the programming write cycle time}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      t: real;                     {wait time in seconds}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_spprog (          {select program memory space}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_spdata (          {select data memory space}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_incadr (          {increment adr for next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_adrinv (          {invalidate target address assumption}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_pan18 (           {specialized 8 byte panel write for 18xxx}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      dat: picprg_pandat8_t;       {the 8 data bytes to write}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_rbyte8 (          {read low bytes of next 8 target words}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_writing (         {indicate the target is being written to}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_chkcmd (          {check availability of a particular command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      opcode: int8u_t;             {opcode to check availability of}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_getpwr (          {get internal power voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_getvdd (          {get target chip Vdd voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_getvpp (          {get target chip Vpp voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_wait (            {guaranteed wait before next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      t: real;                     {time to wait in seconds, clipped and rounded}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_waitchk (         {wait and return completion status}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_getbutt (         {get number of button presses since start}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_appled (          {configure display of App LED}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      bri1: sys_int_machine_t;     {0-15 brightness for phase 1}
  in      t1: real;                    {phase 1 display time, seconds}
  in      bri2: sys_int_machine_t;     {0-15 brightness for phase 2}
  in      t2: real;                    {phase 2 display time, seconds}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_run (             {allow target PIC to run}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      v: real;                     {volts Vdd, 0 = high impedence}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_highz (           {set target lines to high impedence}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_ntout (           {disable host timeout until next command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_getcap (          {get info about a programmer capability}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      id: picprg_pcap_k_t;         {ID of capability inquiring about}
  in      dat: sys_int_machine_t;      {0-255 parameter for the specific capability}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_w30pgm (          {write 4 words to dsPIC program memory}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      w0, w1, w2, w3: sys_int_conv24_t; {the four 24-bit words}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_r30pgm (          {read 2 words from dsPIC program memory}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_datadr (          {set data EEPROM mapping start}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: picprg_adr_t;           {address where start of EEPROM is mapped}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_wbufsz (          {indicate size of target chip write buffer}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      sz: sys_int_machine_t;       {write buffer size in target address units}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_write8 (          {write 8 bytes in the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      dat: univ picprg_datar_t;    {8 data words to write, only low bytes used}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_vpp (             {set Vpp level for when Vpp is enabled}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      vpp: real;                   {desired Vpp level, volts}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_wbufen (          {write buffer coverage last address}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: picprg_adr_t;           {last address that uses write buffer method}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_gettick (         {get programmer clock tick period}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_vdd (             {set single Vdd level next time enabled}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      vdd: real;                   {desired Vdd level, volts}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_nameset (         {set user-definable name of this unit}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      name: univ string_var_arg_t; {new name}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_nameget (         {get user-definable name of this unit}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_reboot (          {restart control processor}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_read64 (          {read block of 64 data words}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_testget (         {get the test mode setting}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_testset (         {set new test mode}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      tmode: sys_int_machine_t;    {ID of new test mode to set}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_eecon1 (          {indicate address of EECON1 register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_eeadr (           {indicate address of EEADR register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_eeadrh (          {indicate address of EEADRH register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_eedata (          {indicate address of EEDATA register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_visi (            {indicate address of VISI register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_tblpag (          {indicate address of TBLPAG register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_nvmcon (          {indicate address of NVMCON register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_nvmkey (          {indicate address of NVMKEY register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_nvmadr (          {indicate address of NVMADR register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_nvmadru (         {indicate address of NVMADRU register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_tprogf (          {set programming time in fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      ticks: sys_int_machine_t;    {prog time in fast ticks, clipped to 65535}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_ftickf (          {get frequency of fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_sendser (         {send bytes out the serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  in      nbytes: sys_int_machine_t;   {number of bytes to send, 1-256}
  in      dat: univ picprg_bytes_t;    {the bytes to send}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmd_recvser (         {get unread bytes from serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
{
*   Response routines.  These routines wait for the response to a command
*   to be received and return the response data, if any.  The CMD structure
*   must have been created by a PICPRG_CMD_xxx routine of the same name.
*   All resources allocated to the CMD structure are released, and the
*   CMD structure can be used again by passing it to another PICPRG_CMD_xxx
*   routine.
*
*   All these routines block execution until the expected response is received
*   from the remote unit.  However, multiple CMD structures may be outstanding,
*   meaning other PICPRG_CMD_xxx calls can be made before the response
*   routines for previous commands are called.  The PICPRG_CMD_xxx and
*   PICPRG_RSP_xxx routines may also be called from multiple threads.
}
procedure picprg_rsp_nop (             {wait for NOP command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_off (             {wait for OFF command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_pins (            {wait for PINS command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     pinfo: picprg_pininfo_t;     {returned info about target chip pins}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_send1 (           {wait for SEND1 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_send2 (           {wait for SEND2 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_send3 (           {wait for SEND3 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_send4 (           {wait for SEND4 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_recv1 (           {wait for RECV1 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_recv2 (           {wait for RECV2 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_recv3 (           {wait for RECV3 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_recv4 (           {wait for RECV4 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_clkh (            {wait for CLKH command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_clkl (            {wait for CLKL command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_dath (            {wait for DATH command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_datl (            {wait for DATL command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_datr (            {wait for DATR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     high: boolean;               {TRUE if data line was high, FALSE for low}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_tdrive (          {wait for TDRIVE command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     drive: boolean;              {TRUE iff target chip is driving data line}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_wait (            {wait for WAIT command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_fwinfo (          {wait for FWINFO command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     org: picprg_org_k_t;         {ID of organization that created firmware}
  out     cvlo, cvhi: int8u_t;         {range of protocol versions compatible with}
  out     vers: int8u_t;               {firmware version number}
  out     info: sys_int_conv32_t;      {extra 32 bit info value}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_fwinfo2 (         {wait for FWINFO2 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     fwid: int8u_t;               {firmware type ID, unique per organization}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_vddvals (         {wait for VDDVALS command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_vddlow (          {wait for VDDLOW command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_vddnorm (         {wait for VDDNORM command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_vddhigh (         {wait for VDDHIGH command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_vddoff (          {wait for VDDOFF command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_vppon (           {wait for VPPON command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_vppoff (          {wait for VPPOFF command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_vpphiz (          {wait for VPPHIZ command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_idreset (         {wait for IDRESET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_idwrite (         {wait for IDWRITE command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_idread (          {wait for IDREAD command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_resadr (          {wait for RESADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_reset (           {wait for RESET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_test1 (           {wait for TEST1 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_test2 (           {wait for TEST2 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     b0, b1, b2, b3: sys_int_machine_t; {returned bytes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_adr (             {wait for ADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_read (            {wait for READ command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     dat: picprg_dat_t;           {data read from the target}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_write (           {wait for WRITE command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_tprog (           {wait for TPROG command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_spprog (          {wait for SPPROG command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_spdata (          {wait for SPDATA command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_incadr (          {wait for INCADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_adrinv (          {wait for ADRINV command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_pan18 (           {wait for PAN18 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_rbyte8 (          {wait for RBYTE8 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     buf: univ picprg_8byte_t;    {returned array of 8 bytes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_writing (         {wait for WRITING command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_chkcmd (          {wait for CHKCMD command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     cmdavail: boolean;           {TRUE if the command is available}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_getpwr (          {wait for GETPWR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_getvdd (          {wait for GETVDD command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_getvpp (          {wait for GETVPP command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_waitchk (         {wait for WAITCHK command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     flags: int8u_t;              {returned status flags}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_getbutt (         {wait for GETBUTT command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     npress: sys_int_machine_t;   {number of presses modulo 256}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_appled (          {wait for APPLED command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_run (             {wait for RUN command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_highz (           {wait for HIGHZ command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_ntout (           {wait for NTOUT command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_getcap (          {wait for GETCAP command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     cap: sys_int_machine_t;      {0-255 response, 0 = default}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_w30pgm (          {wait for W30PGM command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_r30pgm (          {wait for R30PGM command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     w0, w1: sys_int_conv24_t;    {2 program memory words read}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_datadr (          {wait for DATADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_wbufsz (          {wait for WBUFSZ command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_write8 (          {wait for WRITE8 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_vpp (             {wait for VPP command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_wbufen (          {wait for WBUFEN command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_gettick (         {wait for GETTICK command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     ticksec: real;               {programmer tick period in seconds}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_vdd (             {wait for VDD command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_nameset (         {wait for NAMESET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_nameget (         {wait for NAMEGET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  in out  name: univ string_var_arg_t; {user-define name of the unit}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_reboot (          {wait for REBOOT command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_read64 (          {wait for READ64 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  out     cmd: picprg_cmd_t;           {info about the command in progress}
  out     dat: univ picprg_datar_t;    {returned array of 64 data words}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_testget (         {wait for TESTGET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command, returned invalid}
  out     tmode: sys_int_machine_t;    {test mode ID}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_testset (         {wait for TESTSET command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_eecon1 (          {wait for EECON1 command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_eeadr (           {wait for EEADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_eeadrh (          {wait for EEADRH command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_eedata (          {wait for EEDATA command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_visi (            {wait for VISI command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_tblpag (          {wait for TBLPAG command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_nvmcon (          {wait for NVMCON command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_nvmkey (          {wait for NVMKEY command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_nvmadr (          {wait for NVMADR command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_nvmadru (         {wait for NVMADRU command completion}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_tprogf (          {set programming time in fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_ftickf (          {get frequency of fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     freq: real;                  {fast tick frequency, Hz}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_sendser (         {send bytes out the serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_rsp_recvser (         {get unread bytes from serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  cmd: picprg_cmd_t;           {info about the command in progress}
  out     nbytes: sys_int_machine_t;   {number of bytes returned in DAT}
  out     dat: univ picprg_bytes_t;    {the returned data bytes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
{
*   Blocking command routines.  These are wrappers that first call the
*   PICPRG_CMD_xxx routine for the command, then the PICPRG_RSP_xxx routine.
*   These routines only return after the entire response to the command
*   has been received, thereby not allowing any overlap between commands.
*   These routines are therefore not recommended for a large number of
*   repetitive operations, such as writing to or reading from large sections
*   of the target chip program memory.
}
procedure picprg_cmdw_nop (            {send NOP command, just sends ACK back}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_off (            {turn off power to target chip}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_pins (           {get info about target chip pins}
  in out  pr: picprg_t;                {state for this use of the library}
  out     pinfo: picprg_pininfo_t;     {returned info about target chip pins}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_send1 (          {send up to 8 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-8 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_send2 (          {send up to 16 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-16 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_send3 (          {send up to 24 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-24 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_send4 (          {send up to 32 serial bits to the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-32 number of serial bits to send}
  in      dat: sys_int_conv32_t;       {the data bits to send, LSB first}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_recv1 (          {read up to 8 serial data bits from target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-8 number of bits to read}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_recv2 (          {read up to 16 serial data bits from target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-16 number of bits to read}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_recv3 (          {read up to 24 serial data bits from target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-24 number of bits to read}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_recv4 (          {read up to 32 serial data bits from target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      n: sys_int_machine_t;        {1-32 number of bits to read}
  out     dat: sys_int_conv32_t;       {returned bits shfited into LSB, high zero}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_clkh (           {set the serial clock line high}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_clkl (           {set the serial clock line low}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_dath (           {set the serial data line high}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_datl (           {set the serial data line low}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_datr (           {read the data line as driven by the target}
  in out  pr: picprg_t;                {state for this use of the library}
  out     high: boolean;               {TRUE if data line was high, FALSE for low}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_tdrive (         {test whether target is driving data line}
  in out  pr: picprg_t;                {state for this use of the library}
  out     drive: boolean;              {TRUE iff target chip is driving data line}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_wait (           {guaranteed wait before next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  in      t: real;                     {time to wait in seconds, clipped and rounded}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_fwinfo (         {get firmware version and other info}
  in out  pr: picprg_t;                {state for this use of the library}
  out     org: picprg_org_k_t;         {ID of organization that created firmware}
  out     cvlo, cvhi: int8u_t;         {range of protocol versions compatible with}
  out     vers: int8u_t;               {firmware version number}
  out     info: sys_int_conv32_t;      {extra 32 bit info value}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_fwinfo2 (        {get additional firmware info}
  in out  pr: picprg_t;                {state for this use of the library}
  out     fwid: int8u_t;               {firmware type ID, unique per organization}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_vddvals (        {set target chip Vdd levels}
  in out  pr: picprg_t;                {state for this use of the library}
  in      vlo: real;                   {low Vdd level, volts}
  in      vnr: real;                   {normal Vdd level, volts}
  in      vhi: real;                   {high Vdd level, volts}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_vddlow (         {set target Vdd to the low level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_vddnorm (        {set target Vdd to the normal level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_vddhigh (        {set target Vdd to the high level}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_vddoff (         {set target Vdd to off (0 volts)}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_vppon (          {turn on target programming voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_vppoff (         {turn off target programming voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_vpphiz (         {set Vpp line to high impedence}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_idreset (        {select reset algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  in      id: picprg_reset_k_t;        {reset algorithm ID}
  in      offvddvpp: boolean;          {Vdd then Vpp when turn off target}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_resadr (         {indicate target chip address after reset}
  in out  pr: picprg_t;                {state for this use of the library}
  in      resadr: picprg_adr_t;        {address to assume after target chip reset}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_idwrite (        {select write algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  in      id: picprg_write_k_t;        {write algorithm ID}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_idread (         {select read algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  in      id: picprg_read_k_t;         {read algorithm ID}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_reset (          {reset target chip, ready for programming}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_test1 (          {send debugging TEST1 command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_test2 (          {send debugging TEST2 command}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: sys_int_machine_t;      {parameter byte value}
  out     b0, b1, b2, b3: sys_int_machine_t; {returned bytes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_adr (            {set address of next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {target address for next operation}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_read (           {read from target, increment address}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: picprg_dat_t;           {data read from the target}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_write (          {write to target, increment address}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: picprg_dat_t;           {the data to write}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_tprog (          {set the programming write cycle time}
  in out  pr: picprg_t;                {state for this use of the library}
  in      t: real;                     {wait time in seconds}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_spprog (         {select program memory space}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_spdata (         {select data memory space}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_incadr (         {increment adr for next target operation}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_adrinv (         {invalidate target address assumption}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_pan18 (          {specialized 8 byte panel write for 18xxx}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: picprg_pandat8_t;       {the 8 data bytes to write}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_rbyte8 (         {read low bytes of next 8 target words}
  in out  pr: picprg_t;                {state for this use of the library}
  out     buf: univ picprg_8byte_t;    {returned array of 8 bytes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_writing (        {indicate the target is being written to}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_chkcmd (         {check availability of a particular command}
  in out  pr: picprg_t;                {state for this use of the library}
  in      opcode: int8u_t;             {opcode to check availability of}
  out     cmdavail: boolean;           {TRUE if the command is available}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_getpwr (         {get internal power voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_getvdd (         {get target chip Vdd voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_getvpp (         {get target chip Vpp voltage}
  in out  pr: picprg_t;                {state for this use of the library}
  out     v: real;                     {returned voltage}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_waitchk (        {wait and return completion status}
  in out  pr: picprg_t;                {state for this use of the library}
  out     flags: int8u_t;              {returned status flags}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_getbutt (        {get number of button presses since start}
  in out  pr: picprg_t;                {state for this use of the library}
  out     npress: sys_int_machine_t;   {number of presses modulo 256}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_appled (         {configure display of App LED}
  in out  pr: picprg_t;                {state for this use of the library}
  in      bri1: sys_int_machine_t;     {0-15 brightness for phase 1}
  in      t1: real;                    {phase 1 display time, seconds}
  in      bri2: sys_int_machine_t;     {0-15 brightness for phase 2}
  in      t2: real;                    {phase 2 display time, seconds}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_run (            {allow target PIC to run}
  in out  pr: picprg_t;                {state for this use of the library}
  in      v: real;                     {volts Vdd, 0 = high impedence}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_highz (          {set target lines to high impedence}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_ntout (          {disable host timeout until next command}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_getcap (         {get info about a programmer capability}
  in out  pr: picprg_t;                {state for this use of the library}
  in      id: picprg_pcap_k_t;         {ID of capability inquiring about}
  in      dat: sys_int_machine_t;      {0-255 parameter for the specific capability}
  out     cap: sys_int_machine_t;      {0-255 response, 0 = default}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_w30pgm (         {write 4 words to dsPIC program memory}
  in out  pr: picprg_t;                {state for this use of the library}
  in      w0, w1, w2, w3: sys_int_conv24_t; {the four 24-bit words}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_r30pgm (         {read 2 words from dsPIC program memory}
  in out  pr: picprg_t;                {state for this use of the library}
  out     w0, w1: sys_int_conv24_t;    {2 program memory words read}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_datadr (         {set data EEPROM mapping start}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {address where start of EEPROM is mapped}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_wbufsz (         {indicate size of target chip write buffer}
  in out  pr: picprg_t;                {state for this use of the library}
  in      sz: sys_int_machine_t;       {write buffer size in target address units}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_write8 (         {write 8 bytes in the target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      dat: univ picprg_datar_t;    {8 data words to write, only low bytes used}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_vpp (            {set Vpp level for when Vpp is enabled}
  in out  pr: picprg_t;                {state for this use of the library}
  in      vpp: real;                   {desired Vpp level, volts}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_wbufen (         {write buffer coverage last address}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: picprg_adr_t;           {last address that uses write buffer method}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_gettick (        {get programmer clock tick period}
  in out  pr: picprg_t;                {state for this use of the library}
  out     ticksec: real;               {programmer tick period in seconds}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_vdd (            {set single Vdd level next time enabled}
  in out  pr: picprg_t;                {state for this use of the library}
  in      vdd: real;                   {desired Vdd level, volts}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_nameset (        {set user-definable name of this unit}
  in out  pr: picprg_t;                {state for this use of the library}
  in      name: univ string_var_arg_t; {new name}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_nameget (        {get user-definable name of this unit}
  in out  pr: picprg_t;                {state for this use of the library}
  in out  name: univ string_var_arg_t; {user-define name of the unit}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_reboot (         {restart control processor}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_read64 (         {read block of 64 data words}
  in out  pr: picprg_t;                {state for this use of the library}
  out     dat: univ picprg_datar_t;    {returned array of 64 data words}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_testget (        {get the test mode setting}
  in out  pr: picprg_t;                {state for this use of the library}
  out     tmode: sys_int_machine_t;    {test mode ID}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_testset (        {set new test mode}
  in out  pr: picprg_t;                {state for this use of the library}
  in      tmode: sys_int_machine_t;    {ID of new test mode to set}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_eecon1 (         {indicate address of EECON1 register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_eeadr (          {indicate address of EEADR register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_eeadrh (         {indicate address of EEADRH register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_eedata (         {indicate address of EEDATA register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_visi (           {indicate address of VISI register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_tblpag (         {indicate address of TBLPAG register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_nvmcon (         {indicate address of NVMCON register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_nvmkey (         {indicate address of NVMKEY register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_nvmadr (         {indicate address of NVMADR register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_nvmadru (        {indicate address of NVMADRU register in target}
  in out  pr: picprg_t;                {state for this use of the library}
  in      adr: sys_int_machine_t;      {16 bit address of the register}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_tprogf (         {set programming time in fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  in      ticks: sys_int_machine_t;    {prog time in fast ticks, clipped to 65535}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_ftickf (         {get frequency of fast ticks}
  in out  pr: picprg_t;                {state for this use of the library}
  out     freq: real;                  {fast tick frequency, Hz}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_sendser (        {send bytes out the serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  in      nbytes: sys_int_machine_t;   {number of bytes to send, 1-256}
  in      dat: univ picprg_bytes_t;    {the bytes to send}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure picprg_cmdw_recvser (        {get unread bytes from serial data port}
  in out  pr: picprg_t;                {state for this use of the library}
  out     nbytes: sys_int_machine_t;   {number of bytes returned in DAT}
  out     dat: univ picprg_bytes_t;    {the returned data bytes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
{
*   For debugging and testing.
}
procedure picprg_18_test (             {test a PIC18 algorithm}
  in out  pr: picprg_t;                {state for this use of the library}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
