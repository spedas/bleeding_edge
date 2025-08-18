;+
;Procedure: symh2symc
;
;Purpose: Create a tplot variable with sliding average of SYM-H over 30-min interval,
;             centered on the current time moment
;
;Input:
;         symh:  (input) Name of a tplot variable that contains Sym-H index (nT) in 5-minute intervals, e.g, OMNI_HRO_5min_SYM_H
;
;         pdyn:  (input) Name of a tplot variable that contains Solar wind dynamic pressure [nPa] in 5-minute intervals), e.g. OMNI_HRO_5min_Pressure
;
;Output:
;
;         newname: (optional) Name of the tplot variable to use for the output. If not provided, symh + '_c' will be used.
;
;Notes:
;       Requires GEOPACK 10.9 or higher
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2022-09-15 18:51:58 -0700 (Thu, 15 Sep 2022) $
; $LastChangedRevision: 31088 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta16/symh2symc.pro $
;-

pro symh2symc, symh=symh, pdyn=pdyn, trange=trange, newname=newname

  COMPILE_OPT idl2
  if ta16_supported() eq 0 then return

  if ~keyword_set(symh) || (size(symh,/type) ne 7) then begin
    dprint,'Required symh parameter missing or invalid'
    return
  endif

  if ~keyword_set(pdyn) || (size(pdyn,/type) ne 7) then begin
    dprint,'Required pdyn parameter missing or invalid'
    return
  endif

  if ~keyword_set(newname) || (size(newname,/type) ne 7) then begin
    dprint,'Required newname parameter missing or invalid'
    return
  endif

  if tnames(symh) eq '' then begin
    dprint,symh+' not a valid tplot variable'
    return
  endif
  if tnames(pdyn) eq '' then begin
    dprint,pdyn+' not a valid tplot variable'
    return
  endif

  if n_elements(newname) eq 0 then newname=symh + '_c'

  if not keyword_set(trange) then tlims = timerange(/current) else tlims=trange

  ;identify the number of 5 minute time intervals in the specified range
  n = fix(tlims[1]-tlims[0],type=3)/300 +1
  ;the geopack parameter generating functions only work on 5 minute intervals

  ;construct a time array
  ntimes=dindgen(n)*300+tlims[0]

  error = 1
  ; Interpolate input variables to 5-minute grid, ensuring no NaNs in output
  tinterpol_mxn,symh,ntimes,/ignore_nans,out=symh_interp
  tinterpol_mxn,pdyn,ntimes,/ignore_nans,out=pdyn_interp

  if n_tags(symh_interp) ge 2 && n_tags(pdyn_interp) ge 2 then begin
    if n_elements(symh_interp.y) gt 0 && n_elements(symh_interp.y) eq n_elements(pdyn_interp.y) then begin
      symh_interpy = symh_interp.y
      pdyn_interpy = pdyn_interp.y
      GEOPACK_GETSYMHC, symh_interpy, pdyn_interpy, symc_dat
      if n_elements(symc_dat) gt 0 && n_elements(symc_dat) eq n_elements(ntimes) then begin
        dlimits = {ysubtitle: '[nT]'}
        store_data, newname, data={x:ntimes, y:symc_dat}, dlimits=dlimits
        error = 0
      endif

    endif
  endif

  if error eq 1 then begin
    dprint, 'Error, could not compute SYMH_C'
  endif

end
