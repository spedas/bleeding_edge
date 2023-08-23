;+
;PROCEDURE:       mvn_swe_addpot
;
;PURPOSE:         Overwrites SWEA spacecraft potentials with the
;                 composite potential from mvn_scpot.
;
;INPUTS:
;      none:      All information obtained from and written to common
;                 blocks and tplot variables.
;
;KEYWORDS:
;
;CREATED BY:      D. L. Mitchell
;
;LAST MODIFICATION:
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-22 13:47:16 -0700 (Tue, 22 Aug 2023) $
; $LastChangedRevision: 32056 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addpot.pro $
;
;-
pro mvn_swe_addpot

  @mvn_swe_com
  @mvn_scpot_com

; First get the composite potential

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print,'MVN_SWE_ADDPOT: No SWEA energy data.'
    return
  endif

  npts = n_elements(mvn_swe_engy.time)
  pot = mvn_get_scpot(mvn_swe_engy.time)
  valid = where(finite(pot), ngud, ncomplement=nbad)

  fbad = float(nbad)/float(npts)
  if (fbad gt 0.25) then begin
    pct = strtrim(string(round(100.*fbad)),2)
    print,'MVN_SWE_ADDPOT: ',pct,'% of potentials are invalid.'
  endif

; Next update the SWEA common block and a4 tplot variable

  mvn_swe_engy.sc_pot = pot
  swe_sc_pot = replicate(mvn_pot_struct, npts)
  swe_sc_pot.time = mvn_swe_engy.time
  swe_sc_pot.potential = pot

  phi = {x:swe_sc_pot.time, y:swe_sc_pot.potential}
  str_element,phi,'color',0,/add
  str_element,phi,'psym',3,/add
  store_data,'swe_pot_overlay',data=phi

  replot = 0

  get_data,'swe_a4',index=i
  if (i gt 0) then begin
    store_data,'swe_a4_pot',data=['swe_a4','swe_pot_overlay']
    ylim,'swe_a4_pot',3,5000,1

    tplot_options, get=topt
    str_element, topt, 'varnames', varnames, success=ok
    if (ok) then begin
      j = where(topt.varnames eq 'swe_a4', count)
      if (count gt 0) then begin
        topt.varnames[j] = 'swe_a4_pot'
        replot = 1
      endif
    endif
  endif

  get_data,'swe_a4_mask',index=i
  if (i gt 0) then begin
    store_data,'swe_a4_mask',data=['swe_a4','flag','swe_pot_overlay']
    ylim,'swe_a4_mask',3,5000,1

    tplot_options, get=topt
    str_element, topt, 'varnames', varnames, success=ok
    if (ok) then begin
      j = where(topt.varnames eq 'swe_a4_mask', count)
      if (count gt 0) then replot = 1
    endif
  endif

  if (replot) then tplot, topt.varnames

  return

end
