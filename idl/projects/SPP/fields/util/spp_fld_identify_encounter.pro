;+
;
; spp_fld_identify_encounter
;
; short function to identify the encounter number given a time value
; returns -1 if time is not in any encounter
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-11-04 11:26:44 -0800 (Tue, 04 Nov 2025) $
; $LastChangedRevision: 33821 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/spp_fld_identify_encounter.pro $
;-

function spp_fld_identify_encounter, t
  compile_opt idl2

  time = time_double(t)

  mde = spp_fld_read_mde_file(spp_fld_most_recent_mde())

  n_t = n_elements(t)

  encounter = -1 + intarr(n_t)

  for i = 1, 42 do begin
    start_orbit = (mde['Orbit' + string(i, format = '(I02)')])['start_t']
    stop_orbit = (mde['Orbit' + string(i, format = '(I02)')])['stop_t']

    ; if time GE start_orbit and time LT stop_orbit then encounter = i
    ind = where(time ge start_orbit and time lt stop_orbit, count)

    if count gt 0 then encounter[ind] = i
  endfor

  return, reform(encounter)
end
