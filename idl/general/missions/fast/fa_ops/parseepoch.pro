;------------------------------------------------------------------------------
;
;  NSSDC/CDF				      IDL/CDF Interface, parseEPOCH.
;
;  Version 1.2, 16-Aug-96, Hughes STX.
;
;  Modification history:
;
;   V1.0  24-Jan-94, J Love	Original version.
;   V1.1   1-Nov-94, J Love	CDF V2.5.
;   V1.1a 26-Jun-95, J Love	IDL 4.0.
;   V1.2  16-Aug-96, J Love	CDF V2.6.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; parseEPOCH.
;------------------------------------------------------------------------------

;+
; NAME:
;       parseEPOCH
;
; PURPOSE:
;       `parseEPOCH' is used to parse a CDF_EPOCH value from the standard
;       EPOCH character string.
;
;       This function is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       epoch = parseEPOCH (epString)
;
; INPUTS:
;       epString:       STRING.  The standard EPOCH character string.  The
;                       syntax of this string is `dd-mmm-yyyy hh:mm:ss.ccc'
;                       where `dd' is the day of the month (1-31), `mmm' is
;                       the month (`Jan', `Feb', `Mar', `Apr', `May', `Jun',
;                       `Jul', `Aug', `Sep', `Oct', `Nov', or `Dec'), `yyyy'
;                       is the year, `hh' is the hour (0-23), `mm' is the
;                       minute (0-59), `ss' is the second (0-59), and `ccc'
;                       is the millisecond (0-999).
;
;       All input variables must have been created/initialized before calling
;       `parseEPOCH'.
;
; OUTPUTS:
;       epoch:          DOUBLE (double precision floating-point).  The
;                       parsed CDF_EPOCH value.
;
;       All output variables are (re)created/assigned by `parseEPOCH'.
;
; EXAMPLE:
;       IDL> epString = '04-Jan-1956 11:34:55.010'
;       IDL> epoch = parseEPOCH (epString)
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       24-Jan-94        Original version.
;        1-Nov-94        CDF V2.5.
;       26-Jun-95        IDL 4.0.
;       16-Aug-96        CDF V2.6.
;-

function parseEPOCH, epString
on_error, 1
idl_parsepoch, epString, epoch
return, epoch
end
