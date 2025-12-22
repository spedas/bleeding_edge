;------------------------------------------------------------------------------
;
;  NSSDC/CDF				    IDL/CDF Interface, encodeEPOCH2.
;
;  Version 1.2, 16-Aug-96, Hughes STX.
;
;  Modification history:
;
;   V1.0  24-Jan-94, J Love	Original version.
;   V1.1   7-Nov-94, J Love	CDF V2.5.
;   V1.2  16-Aug-96, J Love	CDF V2.6.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; encodeEPOCH2.
;------------------------------------------------------------------------------

;+
; NAME:
;       encodeEPOCH2
;
; PURPOSE:
;       `encodeEPOCH2' is used to encode a CDF_EPOCH value into an alternate
;       EPOCH character string.
;
;       This procedure is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       encodeEPOCH2, epoch, epString
;
; INPUTS:
;       epoch:          DOUBLE (double precision floating-point).  The
;                       CDF_EPOCH value to be encoded.
;
;       All input variables must have been created/initialized before calling
;       `encodeEPOCH2'.
;
; OUTPUTS:
;       epString:       STRING.  The alternate EPOCH character string.  The
;                       syntax of this string is `yyyymmddhhmmss' where `yyyy'
;                       is the year, `mm' is the month (1-12), `dd' is the day
;                       of the month (1-31), `hh' is the hour (0-23), `mm' is
;                       minute (0-59), and `ss' is the second (0-59).
;
;       All output variables are (re)created/assigned by `encodeEPOCH2'.
;
; EXAMPLE:
;       IDL> epoch = 6d13
;       IDL> encodeEPOCH2, epoch, epString
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       24-Jan-94        Original version.
;        7-Nov-94        CDF V2.5.
;       16-Aug-96        CDF V2.6.
;-

pro encodeEPOCH2, epoch, epString
on_error, 1
idl_encodepoch2, epoch, epString
return
end
