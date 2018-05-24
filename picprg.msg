/*   Messages for the PICPRG library.
/*
/*   Messages represented by status codes.
/*
msg err1                               /* BADNBITS
  lan english -def
    An invalid number of bits value was passed to the routine.  Valid
    values are from %p1i to %p2i, but the passed value was %p3i.
msg err2                               /* WRONGRSP
  lan english -def
    Wrong response subroutine called for the command.  The response
    subroutine for the %p1s command was called with a command that has an
    opcode of %p2i.
msg err3                               /* CLOSE
  lan english -def
    The operation was aborted because the PICPRG library is being closed
    by another thread.
msg err4                               /* ARG_BAD
  lan english -def
    "%p1s" is not valid here.
msg err5                               /* IDID
  lan english -def
    An ID command is not allowed here because a previous ID block is still
    open.  The error occurred on line %p1i of file "%p2s".
msg err6                               /* NAMES2
  lan english -def
    A previous NAMES command was already given in this ID block.  The
    error occurred on line %p1i of file "%p2s".
msg err7                               /* BADVDDNAME
  lan english -def
    The name "%p1s" is not known.  All names used in VDD commands must be
    previously declared with a NAMES command in the same ID block.  The
    error occurred on line %p2i of file "%p3s".
msg err8                               /* BADFAM
  lan english -def
    The name "%p1s" is not a recognized PIC family type.
    The error occurred on line %p2i of file "%p3s".
msg err9                               /* NONAME
  lan english -def
    No %p1s command given in ID block.
    The error occurred on line %p2i of file "%p3s".
msg err11                              /* BADCMD
  lan english -def
    "%p1s" is not a valid command.
    The error occurred on line %p2i of file "%p3s".
msg err12                              /* TKEXTRA
  lan english -def
    One or more extra tokens were found at the end of this command.
    The error occurred on line %p1i of file "%p2s".
msg err13                              /* NIDBLOCK
  lan english -def
    The command %p1s is only allowed within an ID block, but no ID block
    is open at this location.
    The error occurred on line %p2i of file "%p3s".
msg err14                              /* IDEOF
  lan english -def
    An ID block was still open when the end of the environment file set
    was reached.  All ID blocks must be closed with the ENDID command.
msg err16                              /* IDNMATCH
  lan english -def
    No information was found for a PIC with device ID word %p1i.  This chip
    is not supported.
msg err17                              /* NAMENMATCH
  lan english -def
    The name "%p1s" does not match any of the variant names for the generic
    chip type of %p2s.
msg err18                              /* BARG_ATLINE
  lan english -def
    Invalid command argument encountered on line %p1i of file "%p2s".
msg err19                              /* NOID
  lan english -def
    Unable to read the device ID from the target chip.  This is probably
    because the target chip is not a supported type, does not contain a
    unique device ID (12 bit core devices),  nothing is plugged
    into the programming socket (if present), or the programmer is not
    connected to a target circuit.
msg err20                              /* UNKFAM
  lan english -def
    The PIC family ID is unknown or unsupported.
msg err21                              /* NERASE
  lan english -def
    No specific erase routine has been installed for this target chip.
msg err22                              /* DUPADR
  lan english -def
    Attempt detected to add an entry to an address list with a duplicate
    address.
    The error occurred on line %p1i of file "%p2s".
msg err23                              /* OVFLCFG
  lan english -def
    Too many CONFIG addresses specified for target chip %p1s.  Only %p2i
    are supported.
msg err24                              /* OVFLOTH
  lan english -def
    Too many OTHER addresses specified for target chip %p1s.  Only %p2i
    are supported.
msg err25                              /* NCONGIF
  lan english -def
    The PICPRG library has not been configured to the specific target
    device.  The library must be configured before this operation can
    be performed.
msg err26                              /* NWRITE
  lan english -def
    No specific write routine has been installed for this target chip.
msg err27                              /* NREAD
  lan english -def
    No specific read routine has been installed for this target chip.
msg err28                              /* CFGMIX
  lan english -def
    PICPRG_WRITE was called with an address range that included both configuration
    and non-configuration locations.  This is not allowed for this target
    chip.
msg err29                              /* FWVERS1
  lan english -def
    The PIC programmer firmware is incompatible with this program.
    The program requires compliance with the protocol specification version %p1i,
    but this firmware only supports version %p2i.
msg err30                              /* FWVERS2
  lan english -def
    The PIC programmer firmware is incompatible with this program.
    The program requires compliance with the protocol specification version %p1i,
    but this firmware only supports versions %p3i-%p2i.
msg err31                              /* BADSPACE
  lan english -def
    Target chip memory address space ID of %p1i is invalid or unimplemented.
msg err32                              /* NAMENF
  lan english -def
    The target chip name %p1s does not identify any of the supported devices.
msg err33                              /* BADIDSPACE
  lan english -def
    The PIC unique ID namespace of value %p1i is invalid or unimplemented.
    The error occurred in subroutine %p2s.
msg err34                              /* WRONGPIC
  lan english -def
    The target chip is not a %p1s or one of its variants as specified.  This
    may also indicate that there is no target chip or that the programmer is
    not connected to the target.
msg err35                              /* NRESP
  lan english -def
    No response was received from the programmer.  The programmer may be
    powered off or not connected to COM%p1i.
msg err36                              /* CMDNIMP
  lan english -def
    Command %p1s is not implemented in this programmer.
msg err37                              /* PICNIMP
  lan english -def
    The target PIC type of %p1s is not supported by this firmware.
msg err38
  lan english -def
    Reset algorithm with ID %p1i is not implemented by this programmer.
msg err39
  lan english -def
    Write algorithm with ID %p1i is not implemented by this programmer.
msg err40
  lan english -def
    Read algorithm with ID %p1i is not implemented by this programmer.
msg err41
  lan english -def
    Target chip write buffer size of %p1i is larger than supported by
    routine %p2s.
msg err42
  lan english -def
    Target chip write buffer size of %p1i is not a multiple of 8 bytes.
msg err43
  lan english -def
    Attempt to set Vpp to %p1f4.1 V, but the programmer's range is
    %p2f4.1 - %p3f45.1 V.
smsg err44                              /* FWVERS1B
  lan english -def
    The PIC programmer firmware is incompatible with this program.
    The program requires compliance with the a protocol specification version
    from %p1i to %p2i but this firmware only supports version %p3i.
msg err45                              /* FWVERS2B
  lan english -def
    The PIC programmer firmware is incompatible with this program.
    The program requires compliance with the a protocol specification version
    from %p1i to %p2i but this firmware only supports versions %p3i to %p4i.
msg err46
  lan english -def
    No specific target chip selected.  A known target chip is required for this
    operation.
msg err47
  lan english -def
    Invalid VDD selection ID of %p1i encountered.
msg err48
  lan english -def
    Invalid ID of %p1i encountered for type of I/O connection to the programmer.
msg err49
  lan english -def
    PIC programmer "%p1s" is already in use.
msg err50
  lan english -def
    PIC programmer "%p1s" not found.
msg err51
  lan english -def
    No PIC programmer found.
msg err52
  lan english -def
    All PIC programmer(s) are already in use.
msg err53
  lan english -def
    Attempt to wait for overallped command complete, but no outstanding command
    existed.
msg err54                              /* UNKFAMRT
  lan english -def
    The PIC family ID is unknown or unsupported in routine %p2s.
msg err55
  lan english -def
    Unsupported response of %p3i received to GETCAP command with parameters
    %p1i,%p2i.
msg err56
  lan english -def
    The address %p1s is not valid for this target chip.
msg err57
  lan english -def
    Verification error at data memory address %p1sh.  Expected %p2sh, found %p3sh.
msg err58
  lan english -def
    Verification error at program memory address %p1sh.  Expected %p2sh, found %p3sh.
msg err59
  lan english -def
    The target PIC is not supported by the combination of this programmer
    and the options selected.
msg err60
  lan english -def
    Invalid number of bytes specified.  Was %p1i, but must be from %p2i to %p3i.
/*
/*   Messages referenced by name and not used in status codes.
/*
msg address_out_range
  lan english -def
    Input data was encountered at address %p1sh, which is not a valid address
    for this target chip.  The HEX file may not be intended for this target
    type.  The target chip was not modified.
msg cc_nblank
  lan english -def
    The constant carrier flag in the target chip is off and can not be reset to
    on by this program.  The chip must be re-programmed to reset the flag.
msg cc_none
  lan english -def
    This firmware does not support the constant carrier flag.
msg ccoff
  lan english -def
    Constant carrier OFF
msg ccon
  lan english -def
    Constant carrier ON
msg close
  lan english -def
    Error occurred on attempt to close a use of the PICPRG library.
msg erasing
  lan english -def
    Erasing the target chip.
msg fw_vers
  lan english -def
    Firmware is %p1s %p2i.
msg fw_vers_id
  lan english -def
    Programmer firmware is type %p1s version %p2i by unknown organization with ID %p3i.
msg fw_vers_targ_unk
  lan english -def
    Unable to determine the version of firmware in the target chip.
msg fw_vers_name
  lan english -def
    Programmer firmware is type %p1s version %p2i by %p3s.
msg get_fwinfo
  lan english -def
    Error occurred on attempt to get revision and other information about
    the programmer firmware.
msg hex_nodat
  lan english -def
    No data bytes in HEX file "%p1s".
msg id
  lan english -def
    ID = %p1s
msg id_nblank
  lan english -def
    The ID in the target chip is not blank, and was previously set to %p1sh.
    The ID can only be set once.
msg n_progs
  lan english -def
    %p1i PIC programmers found.
msg n_progs1
  lan english -def
    %p1i PIC programmer found.
msg name
  lan english -def
    Programmer name is "%p1s".
msg no_errors
  lan english -def
    No errors.  Elapsed time was %p1f6.1 seconds.
msg num_targets
  lan english -def
    %p1i target systems operated on.
msg open
  lan english -def
    Error occurred on attempt to open a new use of the PICPRG library.
msg osccal_backup
  lan english -def
    Backup OSCCAL = %p1s
msg osccal_default
  lan english -def
    Setting backup OSCCAL to %p1s default.
msg osccal_last
  lan english -def
    Setting backup OSCCAL to %p1s from last instruction word.
msg prog_data
  lan english -def
    Writing to non-volatile data memory.
msg prog_other
  lan english -def
    Writing to ID and other locations.
msg prog_prog
  lan english -def
    Writing to program memory.
msg progged
  lan english -def
    PIC %p1s has been programmed successfully.
msg progging
  lan english -def
    Programming "%p1s" into PIC %p2s.
msg read_stats
  lan english -def
    %p1i words read in %p2f8.2 seconds, %p3f8.2 sec/8Kwords, %p4f8.2 mS/word.
msg reading_adr
  lan english -def
    .nfill
      Reading %p1s
msg read_val_bad
  lan english -def
    Found value %p2s at address %p1s, expected %p3s.
msg rfcal
  lan english -def
    RFCAL = %p1i
msg rfcal_nblank
  lan english -def
    The RFCAL value in the target chip is not blank and was previously set to %p1i.
    The RFCAL value can only bet set once.
msg rfcal_none
  lan english -def
    This firmware does not support an RFCAL value.
msg rfcal_orange
  lan english -def
    The RFCAL value of %p1i is out of range.
msg symbol_ninfile
  lan english -def
    Symbol "%p1s" was not found in the map file %p2s.
msg target_type
  lan english -def
    The target chip type is %p1s revision %p2i.
msg unsup_bend
  lan english -def
    -BEND command line option is not supported by this programmer or its
    firmware.
msg unsup_run
  lan english -def
    -RUN command line option is not supported by this programmer or its
    firmware.
msg unsup_varvdd
  lan english -def
    The programmer Vdd level can not be adjusted, and other than the fixed
    value of %p1f6.1 volts was specified.
msg unsup_vdd
  lan english -def
    The requested Vdd level is outside the programmer's range of %p1f6.1 to
    %p2f6.1 volts.
msg unsup_vpp
  lan english -def
    The requested Vpp level is outside the programmer's range of %p1f6.1 to
    %p2f6.1 volts.
msg unsup_wait
  lan english -def
    -WAIT command line option is not supported by this programmer or its
    firmware.
msg vdd_outofrange
  lan english -def
    The Vdd voltage level specified is outside the valid range.
msg vdd_high
  lan english -def
    Unable to lower Vdd to specified level within the allotted time.
msg vdd_low
  lan english -def
    Unable to raise Vdd to specified level within the allotted time.
msg vdd_set
  lan english -def
    Error occurred on attempt to set fixed Vdd level.
msg vdd_diff
  lan english -def
    The programmer is unable to set Vdd to %p1f6.1 Volts.
msg verifying
  lan english -def
    Performing verification at %p1f4.1 volts.
msg verify_error_data
  lan english -def
    Verification error at data memory address %p1sh.  Expected %p2sh, found %p3sh.
msg verify_error_prog
  lan english -def
    Verification error at program memory address %p1sh.  Expected %p2sh, found %p3sh.
msg vpp_high
  lan english -def
    Unable to lower Vpp to specified level within the allotted time.
msg vpp_low
  lan english -def
    Unable to raise Vpp to specified level within the allotted time.
msg vpp_prog_high
  lan english -def
    WARNING: Programmer Vpp minimum of %p1f5.1V is above maximum %p2f5.1V
    allowed by target.
msg vpp_prog_low
  lan english -def
    WARNING: Programmer Vpp maximum of %p1f5.1V is below minimum %p2f5.1V
    required by target.
msg writing_adr
  lan english -def
    .nfill
      Writing %p1s
msg write_stats
  lan english -def
    %p1i words written in %p2f8.2 seconds, %p3f8.2 sec/8Kwords, %p4f8.2 mS/word.
msg writing_config
  lan english -def
    Writing configuration bits.
/*
/*   Messages used by PIC_CTRL program.
/*
msg pic_ctrl_bad_opt
  lan english -def
    INTERNAL ERROR: Unexpected stored command line option ID of %p1i encountered.
/*
/*   Messages for the USBPROG_TEST program.
/*
msg utest_connect_usb
  lan english -def
    Connect the unit under test to the USB.
msg utest_continue
  lan english -def
    Press ENTER to continue:
msg utest_fail
  lan english -def
    .nfill
    >>>>>>>>>> UNIT FAILED <<<<<<<<<<
msg utest_fwbad
  lan english -def
    Tool programmer is running modified firmware.  Select a programmer using official
    firmware.
msg utest_pass
  lan english -def
    .nfill
    ********** UNIT PASSED **********
msg utest_prog8v
  lan english -def
    Hold the programming cable to "P3 Prg7.5".
msg utest_prog17v
  lan english -def
    Hold the programming cable to "P6 Prg17".
msg utest_progctrl
  lan english -def
    Hold the programming cable to "P4 PrgCtrl"
msg utest_progctrl_lprog
  lan english -def
    Hold the programming cable into the pads in the far left corner of the board.
msg utest_sernum
  lan english -def
    Assigning serial number %p1s.
msg utest_start
  lan english -def
    Starting new test:
msg utest_tester_done
  lan english -def
    When the tests have completed, remove the test header and press ENTER:
msg utest_tester_run
  lan english -def
    Connect the target programmer USB to the computer, its programming output
    to the tester, and hold the 4 pin serial cable from the tester to "P5 Serial".
msg utest_tester_run_lprog
  lan english -def
    Hold the 8 pin test header into the programming output pads of the unit
    under test.
msg utest_toolinfo
  lan english
    Tool programmer is %p2s "%p1s", firmware version %p3i.
msg utest_toolser_bad
  lan english -def
    %p1i is not a valid USBProg serial number.
msg utest_toolser_get
  lan english -def
    Serial number of programmer used as tool:
/*
/*   Messages for the READY02_TEST program.
/*
msg r2test_prog5v
  lan english -def
    Hold the programming cable to "Prg5V P4".
msg r2test_prog30v
  lan english -def
    Hold the programming cable to "Prg30V P10".
msg r2test_prog3v
  lan english -def
    Hold the programming cable to "Prg3.3V P12".
msg r2test_prog_ctrl
  lan english -def
    Plug the RJ-12 programming cable into the RJ-12 socket "Prog".
msg r2test_power
  lan english -def
    .nfill
    1: Apply 20-30V power
    2: Verify 1W or less
    3: Verify 6.3V, 5.6V, 5.0V, 3.3V, and -2.4V supply voltages
    4: Verify IC7 pin 6 is below -7.5 volts
    5: Verify low LEDs lit
    6: Apply 5V to each LED input and verify the high LED lights
    7: Disconnect power
    8: Install the PIC 18F2550 into the socket at IC6
msg r2test_usb
  lan english -def
    Disconnect the programmer and connect the target unit to the USB.
