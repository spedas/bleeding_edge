;+
;NAME:
; fgm_sensor_off
;PURPOSE:
; Returns True if the FGM sensor was turned off, but telemetry still enabled for the given probe and date
; 
;CALLING SEQUENCE:
; flag = fgm_sensor_off(probe=probe, data=date)
;
;KEYWORDS:
; probe = probe letter a, b, c, d or e
; date = a string date like '2026-01-01'
;RETURNS:
; 1 if the FGM sensor was turned off but telemetry still enabled, 0 otherwise
;$LastChangedBy: jwl $
;$LastChangedDate: 2026-09-02 13:32:02 -0700 (Wed, 02 Sep 2026) $
;$LastChangedRevision: 34866 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/fgm_sensor_off.pro $


function fgm_sensor_off,probe=probe,date=date
  pl = strlowcase(probe)
  if (pl eq 'a') then begin
    sensor_off = 0
    tdbl=time_double(date)
    sens_off_int1 = time_double(['2025-12-13','2026-01-15'])
    sens_off_int2 = time_double(['2026-01-31','2026-02-25'])
    sens_off_int3 = time_double(['2026-03-03','2026-03-23'])
    sens_off_int4 = time_double(['2026-03-24','2026-04-16'])
    if (tdbl ge sens_off_int1[0]) && (tdbl lt sens_off_int1[1]) then sensor_off = 1
    if (tdbl ge sens_off_int2[0]) && (tdbl lt sens_off_int2[1]) then sensor_off = 1
    if (tdbl ge sens_off_int3[0]) && (tdbl lt sens_off_int3[1]) then sensor_off = 1
    if (tdbl ge sens_off_int4[0]) && (tdbl lt sens_off_int4[1]) then sensor_off = 1
    
    return, sensor_off

  endif else return,0

end