

;======================================
;
;DENS_POT.PRO
;
;Evaluates McFadden's empirical formula for calculating density as a function of spacecraft potiential.  Also appropriate to be called by CURVEFIT.PRO
;
;W.M.Feuerstein, 5/18/2009.
;
pro dens_pot, scpot, depv, result, pder

compile_opt idl2 , hidden

  offset = depv[0]
  delta = offset - scpot
  result = 460.* 10^(delta/1.5) + 34.* 10^(delta/0.7) + 1.6* 10^(delta/30.)
  if n_params() eq 4 then pder = [ alog(10) * ( (460./1.5)* 10^(delta/1.5) + (34./0.7)* 10^(delta/0.7) + (1.6/30.)* 10^(delta/30.) ) ]
end
;======================================

;+
;
;function THM_SCPOT2DENS.PRO
;
;Purpose:
;  This stand-alone function calculates the spacecraft potential derived density.  All argindex_esa_e[0] uments should be 1-d arrays.
;  Average temps will be interpolated onto the SCPOT, using the time values (SCPTIME).
;
;Result:
;  The plasma density as a function of SCPOT keeping the same time base (SCPTIME).
;
;Calling sequence:
;  RESULT = THM_SCPOT2DENS( scpot, scptime, Te, Tetime, dens_e, dens_e_time, dens_i, dens_i_time )
;
;  where
;
;  SCPOT: 		The spacecraft potential time (call THM_LOAD_ESA, DATATYPE = 'peer_sc_pot').
;  SCPTIME:		The time base of SCPOT.
;  TE: 			The electron temperature (a la THM_LOAD_ESA, DATATYPE = 'peer_avgtemp').
;  TETIME: 		The time base of TE.
;  DENS_E: 		The electron density (call THM_LOAD_ESA, DATATYPE = 'peer_density').
;  DENS_E_TIME: 	The time base for DENS_E.
;  DENS_I: 		The ion density (call THM_LOAD_ESA, DATATYPE = 'peir_density').
;  DENS_I_TIME: 	The time base for DENS_I.
;
;W.M.Feuerstein, 2009-05-18.
;
;Example:
; see THM_CRIB_SCPOT2DENS.PRO
;
;History:
; clrussell, 09-26-2012  Fixed bug when converting probe number to a character
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

function thm_scpot2dens, scpot, scptime, Te, Tetime, dens_e, dens_e_time, dens_i, dens_i_time, probe_in

compile_opt idl2

; Validate probe
;
if is_num(probe_in) then probe = thm_probe_num(probe_in) else $
                         probe = thm_probe_num(thm_probe_num(probe_in))

if is_num(probe) then begin
  print, 'Invalid probe entered '
  print, 'Valid probes are [a, b, c, d, e], or [1, 2, 3, 4, 5]
  return, -1
endif

; If Ne and Ni exist and have >= 2 elements, then proceed:
;
if (dens_e[0] ne -1 && dens_i[0] ne -1) && (n_elements(dens_e) ge 2 && n_elements(dens_i) ge 2) then begin

  idxTfin = where(finite(Te))
  if n_elements(idxTfin) lt 2 then return,-1L
  Teint = interpol(Te[idxTfin], Tetime[idxTfin], scptime)

  w= where(finite(dens_e))                                   ;Sync Ne to scpot time base.
  if n_elements(w) lt 2 then return,-1L
  dens_e= interpol(dens_e[w], dens_e_time[w], scptime)

  w= where(finite(dens_i))                                   ;Sync Ni to scpot time base.
  if n_elements(w) lt 2 then return,-1L
  dens_i= interpol(dens_i[w], dens_i_time[w], scptime)


  ; Set bias current change times and offsets as a function of probe:
  ;
  case probe of
    'a': begin
      biaschange = [ time_double('2001-1-1') ]
      offsetmatrix = [ 2.2, 2.0, !values.f_nan, !values.f_nan ]
    end
    'b': begin
      biaschange = [ time_double('2001-1-1') ]
      offsetmatrix = [ 2.2, 2.0, !values.f_nan, !values.f_nan ]
    end
    'c': begin
      biaschange = time_double([ '2001-1-1', '2007-7-20/17:24' ])   ; bias current change times.
      offsetmatrix = [ [ 2.2, 2.0, !values.f_nan, !values.f_nan ], $
                       [ 2.9, 2.0, !values.f_nan, !values.f_nan ] ]              ; 4xn (wll, wlh, whl, whh, 1st dim.; bias current boundaries, 2nd dim.)
    end
    'd': begin
      biaschange = [ time_double('2001-1-1') ]
      offsetmatrix = [ 2.2, 2.0, !values.f_nan, !values.f_nan ]
    end
    'e': begin
      biaschange = [ time_double('2001-1-1') ]
      offsetmatrix = [ 2.2, 2.0, !values.f_nan, !values.f_nan ]
    end
  endcase


  ; Loop on bias current periods filling in DENS:
  ;
  dens = fltarr(n_elements(scpot))
  for i = 0, n_elements(biaschange)-1 do begin

    ; Isolate indicies by plasma region and bias period:
    ;

    ;;wscpoth = where( scpot gt 6.0 , n_scpoth, complement = wscpotl )    ;Faster than four WHERE statements (work out later).
    ;;wTeinth = where( Teint gt 500., n_Teinth, complement = wTeintl )
    ;;case wscpoth[0] of
    ;;  -1: if

    if i ne n_elements(biaschange)-1 then begin                 ;last bias period?
      wll = where(scpot le 6.0 and Teint le 500. and scptime ge biaschange[i] and scptime lt biaschange[i+1] )
      wlh = where(scpot le 6.0 and Teint gt 500. and scptime ge biaschange[i] and scptime lt biaschange[i+1] )
      whl = where(scpot gt 6.0 and Teint le 500. and scptime ge biaschange[i] and scptime lt biaschange[i+1] )
      whh = where(scpot gt 6.0 and Teint gt 500. and scptime ge biaschange[i] and scptime lt biaschange[i+1] )
      wnf = where( ~finite(scpot) or ~finite(Teint) and scptime ge biaschange[i] and scptime lt biaschange[i+1] )
    endif else begin
      wll = where(scpot le 6.0 and Teint le 500. and scptime ge biaschange[i] )
      wlh = where(scpot le 6.0 and Teint gt 500. and scptime ge biaschange[i] )
      whl = where(scpot gt 6.0 and Teint le 500. and scptime ge biaschange[i] )
      whh = where(scpot gt 6.0 and Teint gt 500. and scptime ge biaschange[i] )
      wnf = where( ~finite(scpot) or ~finite(Teint) and scptime ge biaschange[i] )
    endelse
  
    ;
    ;Make DENS based on plasma region (low/low, low/high, high/low, high/high, where the cutoffs are scpot=6V, and Te = 500eV, respectively):
    ;
    if wll[0] ne -1 then begin
      dens_pot, scpot[wll], offsetmatrix[0,i], foo
      dens[wll] = temporary(foo)
    endif
    if wlh[0] ne -1 then begin
      dens_pot, scpot[wlh], offsetmatrix[1,i], foo
      dens[wlh] = temporary(foo)
    endif
  ;  if whl[0] ne -1 then dens[whl] = !values.f_nan
    if whl[0] ne -1 then begin
      ;
      ; Do it the old way for now:
      ;
      dens[whl] = exp((-scpot[whl]+12D)/((scpot[whl]*.14D)+3.36D))/sqrt(Teint[whl])
      ; the code below will recompute in cases where cold electrons need to be accounted for
      ;
      idx1 = where(dens[whl] gt 10)
      idx2 = where(Teint[whl] gt 50)
      idxT = ssl_set_intersection(idx1, idx2)
      if(idxT[0] ne -1) then (dens[whl])[idxT] = exp(( -( (scpot[whl])[idxT] ) +12D)/( ( (scpot[whl])[idxT]*.14D) + 3.36D ))/sqrt(3D)
    endif
    if whh[0] ne -1 then begin
  ;    dens_pot, scpot[whh], [-0.5], foo
  ;    dens[whh] = temporary(foo)
      ;
      ; Do it the old way for now:
      ;
      dens[whh] = exp((-scpot[whh]+12D)/((scpot[whh]*.14D)+3.36D))/sqrt(Teint[whh])
      ; the code below will recompute in cases where cold electrons need to be accounted for
      ;
      idx1 = where(dens[whh] gt 10)
      idx2 = where(Teint[whh] gt 50)
      idxT = ssl_set_intersection(idx1, idx2)
      if(idxT[0] ne -1) then (dens[whh])[idxT] = exp(( -( (scpot[whh])[idxT] ) +12D)/( ( (scpot[whh])[idxT]*.14D) + 3.36D ))/sqrt(3D)
    endif
    if wnf[0] ne -1 then dens[wnf] = !values.f_nan
  endfor; i

; else do it the old way:
;
endif else begin

  idxTfin = where(finite(Te))

  if n_elements(idxTfin) lt 2 then return,-1L

  Teint = interpol(Te[idxTfin],Tetime[idxTfin],scptime)

  dens = exp((-scpot+12D)/((scpot*.14D)+3.36D))/sqrt(Teint)

  ; the code below will recompute in cases where cold electrons need to be accounted for
  ;
  idx1 = where(dens gt 10)
  idx2 = where(Teint gt 50)
  idxT = ssl_set_intersection(idx1, idx2)
  if(idxT[0] ne -1) then dens[idxT] = exp((-scpot[idxT]+12D)/((scpot[idxT]*.14D)+3.36D))/sqrt(3D)
endelse

; If DENS is unmodified, then return -1:
;
if (where(dens ne 0.))[0] eq -1 then return, -1

return, dens

end


