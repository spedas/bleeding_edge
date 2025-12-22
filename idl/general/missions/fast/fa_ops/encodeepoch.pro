;------------------------------------------------------------------------------
;
;  NSSDC/CDF				    IDL/CDF Interface, encodeEPOCH.
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
; encodeEPOCH.
;------------------------------------------------------------------------------

;+
; NAME:
;       encodeEPOCH
;
; PURPOSE:
;       `encodeEPOCH' is used to encode a CDF_EPOCH value into a standard
;       EPOCH character string.
;
;       This procedure is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       encodeEPOCH, epoch, epString
;
; INPUTS:
;       epoch:          DOUBLE (double precision floating-point).  The
;                       CDF_EPOCH value to be encoded.
;
;       All input variables must have been created/initialized before calling
;       `encodeEPOCH'.
;
; OUTPUTS:
;       epString:       STRING.  The standard EPOCH character string.  The
;                       syntax of this string is `dd-mmm-yyyy hh:mm:ss.ccc'
;                       where `dd' is the day of the month (1-31), `mmm' is
;                       the month (`Jan', `Feb', `Mar', `Apr', `May', `Jun',
;                       `Jul', `Aug', `Sep', `Oct', `Nov', or `Dec'), `yyyy'
;                       is the year, `hh' is the hour (0-23), `mm' is the
;                       minute (0-59), `ss' is the second (0-59), and `ccc'
;                       is the millisecond (0-999).
;
;       All output variables are (re)created/assigned by `encodeEPOCH'.
;
; EXAMPLE:
;       IDL> epoch = 6d13
;       IDL> encodeEPOCH, epoch, epString
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       24-Jan-94        Original version.
;        7-Nov-94        CDF V2.5.
;       16-Aug-96        CDF V2.6.
;-

pro encodeEPOCH, epoch, epString
on_error, 1
idl_encodepoch, epoch, epString
return
end
