;------------------------------------------------------------------------------
;
;  NSSDC/CDF				    IDL/CDF Interface, encodeEPOCH1.
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
; encodeEPOCH1.
;------------------------------------------------------------------------------

;+
; NAME:
;       encodeEPOCH1
;
; PURPOSE:
;       `encodeEPOCH1' is used to encode a CDF_EPOCH value into an alternate
;       EPOCH character string.
;
;       This procedure is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       encodeEPOCH1, epoch, epString
;
; INPUTS:
;       epoch:          DOUBLE (double precision floating-point).  The
;                       CDF_EPOCH value to be encoded.
;
;       All input variables must have been created/initialized before calling
;       `encodeEPOCH1'.
;
; OUTPUTS:
;       epString:       STRING.  The alternate EPOCH character string.  The
;                       syntax of this string is `yyyymmdd.ttttttt' where
;                       `yyyy' is the year, `mm' is the month (1-12), `dd'
;                       is the day of the month (1-31), and `ttttttt' is the
;                       fraction of the day (eg. `5000000' is 12 o'clock noon).
;
;       All output variables are (re)created/assigned by `encodeEPOCH1'.
;
; EXAMPLE:
;       IDL> epoch = 6d13
;       IDL> encodeEPOCH1, epoch, epString
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       24-Jan-94        Original version.
;        7-Nov-94        CDF V2.5.
;       16-Aug-96        CDF V2.6.
;-

pro encodeEPOCH1, epoch, epString
on_error, 1
idl_encodepoch1, epoch, epString
return
end
