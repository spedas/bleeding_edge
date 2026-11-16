;+
; FUNCTION:
;         mms_find_perigee_times
;
; PURPOSE:
;         Function that returns the times of perigee just before and after the input time (using the MEC data)
;
; INPUT:
;         time: time to find perigee
;
; KEYWORDS:
;         probe: spacecraft probe #
;
; EXAMPLE:
;         trange=mms_find_perigee_times('2015-09-02/00:00:00', probe='1')
;
; NOTES:
;         Created by Naritoshi Kitamura
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2026-11-12 14:38:11 -0800 (Thu, 12 Nov 2026) $
; $LastChangedRevision: 35051 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_find_perigee_times.pro $
;-

FUNCTION mms_find_perigee_times, time, probe=probe

  if undefined(probe) then probe='1' else $
    probe = strcompress(string(probe), /rem)

  time = time_double(time)
  if time lt time_double('2017-02-01') then days=1.d else days=4.d

  result = replicate(!values.d_nan, 2)

  name_before = 'mms'+probe+'_mec_r_eci_before'
  name_after  = 'mms'+probe+'_mec_r_eci_after'

  ; Remove stale temporary data before attempting new loads.
  store_data, [name_before, name_after], /delete

  ; Find the last valid perigee at or before the input time.
  mms_load_mec, trange=[time-86400.d*days, time+60.d], $
    probes=probe, varformat='*_r_eci', datatype='epht89d', $
    suffix='_before', /time_clip

  get_data, name_before, data=d1

  n1 = 0L
  if size(d1, /type) eq 8 then n1 = n_elements(d1.x)

  if n1 ge 3L then begin
    p1 = double(d1.y)
    r1 = sqrt(p1[*,0]*p1[*,0] + $
      p1[*,1]*p1[*,1] + $
      p1[*,2]*p1[*,2])

    for i=n1-2L, 1L, -1L do begin
      ; Require three adjacent valid samples; do not bridge gaps.
      if total(finite(r1[i-1L:i+1L])) ne 3 then continue
      if total(finite(d1.x[i-1L:i+1L])) ne 3 then continue
      if d1.x[i] gt time then continue

      dr_before = r1[i] - r1[i-1L]
      dr_after  = r1[i+1L] - r1[i]

      if (dr_before lt 0.d) and (dr_after ge 0.d) then begin
        result[0] = d1.x[i]
        break
      endif
    endfor
  endif

  ; Find the first valid perigee strictly after the input time.
  mms_load_mec, trange=[time, time+86400.d*days], $
    probes=probe, varformat='*_r_eci', datatype='epht89d', $
    suffix='_after', /time_clip

  get_data, name_after, data=d2

  n2 = 0L
  if size(d2, /type) eq 8 then n2 = n_elements(d2.x)

  if n2 ge 3L then begin
    p2 = double(d2.y)
    r2 = sqrt(p2[*,0]*p2[*,0] + $
      p2[*,1]*p2[*,1] + $
      p2[*,2]*p2[*,2])

    for i=1L, n2-2L do begin
      if total(finite(r2[i-1L:i+1L])) ne 3 then continue
      if total(finite(d2.x[i-1L:i+1L])) ne 3 then continue
      if d2.x[i] le time then continue

      dr_before = r2[i] - r2[i-1L]
      dr_after  = r2[i+1L] - r2[i]

      if (dr_before lt 0.d) and (dr_after ge 0.d) then begin
        result[1] = d2.x[i]
        break
      endif
    endfor
  endif

  store_data, [name_before, name_after], /delete

  if finite(result[0]) eq 0 then $
    message, 'No valid perigee found at or before the input time.', /continue

  if finite(result[1]) eq 0 then $
    message, 'No valid perigee found after the input time.', /continue

  return, result

END
