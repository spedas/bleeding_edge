;------------------------------------------------------------------------------
;
;  NSSDC/CDF				    IDL/CDF Interface, EPOCHbreakdown.
;
;  Version 1.2, 16-Aug-96, Hughes STX.
;
;  Modification history:
;
;   V1.0  24-Jan-94, J Love	Original version.
;   V1.1   1-Nov-94, J Love	CDF V2.5.
;   V1.2  16-Aug-96, J Love	CDF V2.6.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; EPOCHbreakdown.
;------------------------------------------------------------------------------

;+
; NAME:
;       EPOCHbreakdown
;
; PURPOSE:
;       `EPOCHbreakdown' is used to break down a CDF_EPOCH value into its
;       component parts.
;
;       This procedure is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       EPOCHbreakdown, epoch, year, month, day, hour, minute, second, msec
;
; INPUTS:
;       epoch:          DOUBLE (double precision floating-point).  The
;                       CDF_EPOCH value to be broken down.
;
;       All input variables must have been created/initialized before calling
;       `EPOCHbreakdown'.
;
; OUTPUTS:
;       year:           LONG.  The year component (AD).
;       month:          LONG.  The month component (1-12).
;       day:            LONG.  The day component (1-31).
;       hour:           LONG.  The hour component (0-23).
;       minute:         LONG.  The minute component (0-59).
;       second:         LONG.  The second component (0-59).
;       millisecond:    LONG.  The millisecond component (0-999).
;
;       All output variables are (re)created/assigned by `EPOCHbreakdown'.
;
; EXAMPLE:
;       IDL> epoch = 6d13
;       IDL> EPOCHbreakdown, epoch, year, month, day, hour, minute, second, $
;       IDL>                 msec
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       24-Jan-94        Original version.
;        1-Nov-94        CDF V2.5.
;       16-Aug-96        CDF V2.6.
;-

pro EPOCHbreakdown, epoch, year, month, day, hour, minute, second, msec
on_error, 1
idl_epochbreak, epoch, year, month, day, hour, minute, second, msec
return
end
