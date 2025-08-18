;+
; function: time_ephemeris(t)
; Purpose: conversion between unix time and ephemeris time
; Usage:   et = time_ephemeris(ut)          ; Converts from UT (unix/posix time) to ephemeris time
; Or:      ut = time_ephemeris(et,/et2ut)   ; Converts from ephemeris time to UT double precision (UNIX time)
; 
; Warning: this routine is only accurate to about 1 millisecond and does not attempt to reflect GR effects
;
; Does NOT require the ICY DLM to be loaded
;Author: Davin Larson
;
; $LastChangedBy: ali $
; $LastChangedDate: 2025-07-09 11:12:12 -0700 (Wed, 09 Jul 2025) $
; $LastChangedRevision: 33436 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/time_ephemeris.pro $

;-


function time_ephemeris,t,et2ut=et2ut,ut2et=ut2et
common time_ephemeris_com, ls_num,  ls_utimes, ls_etimes, utc_et_diff, disable_time   ;, ls_etimes
;ls_num=0
if not keyword_set(ls_num) then begin
    ls_utimes = time_double(['0200-1-1','1972-1-1','1972-7-1','1973-1-1','1974-1-1','1975-1-1','1976-1-1','1977-1-1','1978-1-1','1979-1-1','1980-1-1',  $
    '1981-7-1','1982-7-1','1983-7-1','1985-7-1','1988-1-1','1990-1-1','1991-1-1','1992-7-1','1993-7-1','1994-7-1', $
    '1996-1-1','1997-7-1','1999-1-1','2006-1-1','2009-1-1','2012-7-1','2015-7-1','2017-1-1','3000-1-1'])
    ls_num = dindgen(n_elements(ls_utimes)) + 9
    utc_et_diff = time_double('2000-1-1/12:00:00') -32.184   ;  -32.18392728
    ls_etimes = ls_utimes + ls_num - utc_et_diff 
;  printdat,ls_num,ls_utimes,ls_etimes,utc_et_diff
    disable_time = time_double('2026-7-1')   ; time of next possible leap second
    if systime(1) gt disable_time-30*86400L then message,'Warning: This procedure must be modified before '+time_string(disable_time)+' to account for potential leap second',/cont
endif

if systime(1) gt disable_time  then message,'Sorry!  This procedure has been disabled because it was not modified to account for a possible leap second on '+time_string(disable_time)
if systime(1) gt disable_time-7*86400L then message,'Warning: This procedure must be modified before '+time_string(disable_time)+' to account for potential leap second at that time.',/cont

if keyword_set(et2ut) then begin
    return, t -  floor( interp(ls_num,ls_etimes,t) ) + utc_et_diff   ; Not verified...
endif
;if keyword_set(ut2et) then begin
    ut = time_double(t)
    return, ut + floor( interp(ls_num,ls_utimes,ut) ) - utc_et_diff
;endif
message,'Must set at least one keyword!)
end





