/*   Message file to provide text names for the various firmware types
/*   within this organization.
/*
/*   The name of this file is PICPRG_ORGn.MSG, where N is the organization
/*   ID returned by the FWINFO command.  Organization IDs are assigned
/*   by Embed Inc.
/*
/*   Each message of name IDNAMEn defines the text name of a firmware
/*   type within this organization.  The firwmare type is the value
/*   returned by the FWINFO2 command.  Each organization assigns
/*   firmware types itself.
/*
/*   If the PICPRG_ORGn.MSG file exists and the appropriate IDNAMEn
/*   message within it exists, then the PICPRG library will make the
/*   firmware type name from the message available to the application.
/*   If the appropriate message or message file is not found, then
/*   the decimal firmware type string is used instead.
/*
/*   This file must be placed in the ENV directory within the Embed
/*   Inc software installation directory.  The standard Embed Inc
/*   software distribution is guaranteed not to contain a file in the
/*   ENV directory with the name PICPRG_ORGn.MSG for values of N
/*   from 2 to 254.
/*
msg idname0
  lan english -def
    EasyProg
msg idname1
  lan english -def
    ProProg
msg idname2
  lan english -def
    USBProg
msg idname3
  lan english -def
    LProg
