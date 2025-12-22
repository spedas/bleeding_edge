;------------------------------------------------------------------------------
;
;  NSSDC/CDF				    IDL/CDF Interface, encodeEPOCH.
;
;  Version 1.1, 16-Aug-96, Hughes STX.
;
;  Modification history:
;
;   V1.0   7-Nov-94, J Love	Original version.
;   V1.1  16-Aug-96, J Love	CDF V2.6.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; encodeEPOCH3.
;------------------------------------------------------------------------------

;+
; NAME:
;       encodeEPOCH3
;
; PURPOSE:
;       `encodeEPOCH3' is used to encode a CDF_EPOCH value into an alternate
;       EPOCH character string.
;
;       This procedure is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       encodeEPOCH3, epoch, epString
;
; INPUTS:
;       epoch:          DOUBLE (double precision floating-point).  The
;                       CDF_EPOCH value to be encoded.
;
;       All input variables must have been created/initialized before calling
;       `encodeEPOCH3'.
;
; OUTPUTS:
;       epString:       STRING.  The alternate EPOCH character string.  The
;                       syntax of this string is `yyyy-mn-ddThh:mm:ss.cccZ'
;                       where `yyyy' is the year, `mn' is the month (1-12),
;                       `dd' is the day of the month (1-31), `hh' is the hour
;                       (0-23), `mm' is the minute (0-59), `ss' is the second
;                       (0-59), and `ccc' is the millisecond (0-999).
;
;       All output variables are (re)created/assigned by `encodeEPOCH3'.
;
; EXAMPLE:
;       IDL> epoch = 6d13
;       IDL> encodeEPOCH3, epoch, epString
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;        7-Nov-94       Original version.
;       16-Aug-96       CDF V2.6.
;-

pro encodeEPOCH3, epoch, epString
on_error, 1
idl_encodepoch3, epoch, epString
return
end
