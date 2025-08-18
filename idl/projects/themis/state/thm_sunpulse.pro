; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

PRO thm_sunpulse, time_state,spinpha,spinper,sunpulse,sunp_spinper, $
                  probe=probe, suffix=suffix, sunpulse_name = sunpulse_name
; ----------------------------------------------------------------------
;+
;NAME:
;  thm_sunpulse
;Purpose: 
;  Interpolate spin phase to have same time resolution as time_dat
;Keyword:
;         probe: string indicating probe.  Array of strings, or a string
;                like 'a b'.  Not used if positional parameters are present.
;        suffix: suffix to add to default tplot name in which to store sunpulse
;                data: thx_state_sunpulse (x = probe letter designation)
;                This suffix is expected on the names of the state data inputs.
;Optional Inputs/Output parameters:
;(if not present, then standard state tplot variable names will be used for i/o)
;  Input Parameters:
;    time_state: double precision array: times of data from state file
;       spinpha: spin phase from state file
;       spinper: spin period from state file
;  Output Parameters:
;      sunpulse: sunpulse times (times of zero spin phase)
;  sunp_spinper: spin period at time of each sunpulse.
;
;Keywords:
; sunpulse_name: string.  If present, store sunpulse/spinperiod in tplot 
;                variable with this name.  Has no effect if probe keyword 
;                is provided.
;
;Notes:
;
; Written by K. Bromund, SPSystems/NASA/GSFC, May 2007
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-30 15:28:49 -0700 (Thu, 30 Apr 2015) $
;$LastChangedRevision: 17458 $ 
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/thm_sunpulse.pro $
;-
; ----------------------------------------------------------------------

  if n_params() eq 0 then begin
     if not keyword_set(suffix) then suff = '' else suff = suffix
     vprobes = ['a','b','c','d','e']
     if not keyword_set(probe) then prb = vprobes $
     else prb = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all)
     if not keyword_set(prb) then begin
        dprint, 'probe keyword required if no positional args present'
        return
     endif
     for i = 0, n_elements(prb)-1 do begin
        get_data, 'th'+prb[i]+'_state_spinphase'+suff, $
                  time_state,spinpha,dtype=tph
        get_data, 'th'+prb[i]+'_state_spinper'+suff, $
                  time_state, spinper, dtype=tpe
        if (tph ne 1 || tpe ne 1) then begin
           dprint, '*** thm_sunpulse: state data not loaded for probe ', prb[i]
           continue
        endif
        thm_sunpulse, time_state, spinpha, spinper, $
                      sunpulse='th'+prb[i]+'_state_sunpulse'+suff
     endfor
     return
  endif

  nsta=N_ELEMENTS(time_state)

  dprint, '   Dimension of state file array = ', nsta
  FLUSH, 0, -1, -2

; get time of sunpulse which occurred before each state data point

  sunpulse_state1 = time_state - spinpha/360.0*spinper

; get time of sunpulse which occurred after each state data point

  sunpulse_state2 = time_state + (360.0-spinpha)/360.0*spinper

; get number of spins between each known sunpulse time

  dtime = sunpulse_state1[1:*]-sunpulse_state2
  nspins1 = dtime/spinper
  nspins2 = dtime/spinper[1:*]

  int_nspins1 = long(nspins1+0.5)
  int_nspins2 = long(nspins2+0.5)

  spin_error = where(int_nspins1 ne int_nspins2, n_spin_error)
  if n_spin_error gt 0 then begin
     dprint, '*** thm_sunpulse: spin rate changing too quickly to uniquely'
     dprint, '    determine sunpulses between state data points at ', $
            time_string(time_state[spin_error[0:10 < n_spin_error-1]])
     if n_spin_error gt 10 then $
        dprint, '    ', n_spin_error, ' times. Output truncated'
  endif

  err1 = nspins1 - int_nspins1

  spin_warn = where(abs(err1) gt 0.25, n_spin_warn)
  if n_spin_warn gt 0 then begin
     dprint, '*** thm_sunpulse: spin rate data questionable at ', $
            time_string(time_state[spin_warn[0:10 < n_spin_warn-1]])
     if n_spin_warn gt 10 then $
        dprint, '    ', n_spin_warn, ' times. Output truncated'
  endif

  nspins = int_nspins1

; calculate spin period based on sun pulse times, to interpolate 
; sun pulse times in between state data values.
  spinper_state = dtime/nspins

  sunpulse = dblarr(total(nspins)+nsta)
  sunp_spinper = fltarr(total(nspins)+nsta)

  spin_ind = 0

  for i=0L, nsta-2 do begin
     sunpulse_ind = lindgen(nspins[i])
     sunpulse[spin_ind] = sunpulse_state1[i] 
     sunp_spinper[spin_ind] = spinper[i]
     ;; after state data point, fill at interpolated rate, based on spinphase
     sunpulse[spin_ind + 1 + sunpulse_ind] = sunpulse_state2[i] + $
                                             sunpulse_ind*spinper_state[i]
     sunp_spinper[spin_ind + 1 + sunpulse_ind] = spinper_state[i]
     spin_ind += nspins[i] + 1
  endfor
  
  sunpulse[spin_ind] = sunpulse_state1[nsta-1]
  sunp_spinper[spin_ind] = spinper[nsta-1]

  if keyword_set(sunpulse_name) then $
     store_data, sunpulse_name, data={x:sunpulse, y:sunp_spinper}
  
end
