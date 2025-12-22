;------------------------------------------------------------------------------
;
;  NSSDC/CDF				      IDL/CDF Interface, computeEPOCH.
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
; computeEPOCH.
;------------------------------------------------------------------------------

;+
; NAME:
;       computeEPOCH
;
; PURPOSE:
;       `computeEPOCH' is used to compute a CDF_EPOCH value from its
;       component parts.
;
;       This function is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       epoch = computeEPOCH (year, month, day, hour, minute, second, msec)
;
; INPUTS:
;       year:           LONG.  The year component (AD).
;       month:          LONG.  The month component (1-12).
;       day:            LONG.  The day component (1-31).
;       hour:           LONG.  The hour component (0-23).
;       minute:         LONG.  The minute component (0-59).
;       second:         LONG.  The second component (0-59).
;       millisecond:    LONG.  The millisecond component (0-999).
;
;       All input variables must have been created/initialized before calling
;       `computeEPOCH'.
;
; OUTPUTS:
;       epoch:          DOUBLE (double precision floating-point).  The
;                       computed CDF_EPOCH value.
;
;       All output variables are (re)created/assigned by `computeEPOCH'.
;
; EXAMPLE:
;       IDL> year = 1993L
;       IDL> month = 5L
;       IDL> day = 20L
;       IDL> epoch = computeEPOCH (year, month, day, 0L, 0L, 0L, 0L)
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

function computeEPOCH, year, month, day, hour, minute, second, msec
on_error, 1
idl_computepoch, year, month, day, hour, minute, second, msec, epoch
return, epoch
end
