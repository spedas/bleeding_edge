;+
;
; FUNCTION:
;         mms_estimate_mem_usage
;
; PURPOSE:
;         Estimate memory usage by HPCA ion data
;
; 
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-08-09 14:45:46 -0700 (Thu, 09 Aug 2018) $
; $LastChangedRevision: 25617 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_estimate_mem_usage.pro $
;-

function mms_estimate_mem_usage, trange, instrument
  if undefined(instrument) then begin
    dprint, dlevel = 0, 'Error: MMS instrument required to estimate memory usage!'
    return, -1
  endif
  if instrument eq 'hpca' then begin
    trange = time_double(trange)
    n_points = ((trange[1]-trange[0])/0.625d)*63d*16d
    memory_estimate = 0.0001*n_points-84.547
    return, memory_estimate
  endif
end