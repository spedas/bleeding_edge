;+
;PROCEDURE:
;   mvn_swe_sc_negpot_twodir_burst
;
;PURPOSE:
;   Estimates potentials from the shift of He II features 
;   for both anti-parallel and parallel directions with 
;   SWEA PAD data. Right now it only works for burst data. 
;
;INPUTS:
;   none
;
;KEYWORDS:
;	POTENTIAL: Returns spacecraft potentials in a structure.
;
;   SHADOW:    If keyword set, all the estimations outside of shadow
;              at altitudes > 800 km are set to NANs
;
;   SWIDTH:    Field-aligned angle to calculate spectra for both
;              directions. The default value is 45 degrees. 
;
;   FILL:      Fill in the common block.  Default = 0 (no).
;
;   RESET:     Initialize the spacecraft potential, discarding all previous 
;              estimates, and start fresh.
;
;   SCPOT:     If keyword set, it provides s/c potential estimates. 
;              The default is set to be 1.
;
;OUTPUTS:
;   None - Potential results are stored as a TPLOT variable 'negpot_pad'. 
;          Four additional TPLOT variables are created for diagnostics. 
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-23 16:18:35 -0700 (Mon, 23 Jun 2025) $
; $LastChangedRevision: 33411 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_negpot_twodir_burst.pro $
;
;CREATED BY:    Shaosui Xu  01-03-2017
;-
pro mvn_swe_sc_negpot_twodir_burst, potential=phi, shadow=shadow, swidth=swidth, $
                                    fill=fill, reset=reset, scpot=scpot

    @mvn_swe_com
    @mvn_scpot_com
  
    if (size(Espan,/type) eq 0) then mvn_scpot_defaults
    if (size(scpot,/type) eq 0) then scpot=1
; This routine requires SPEC and PAD burst data.  Make sure they exist.

    if (size(mvn_swe_engy,/type) ne 8) then begin
      print,"Please load SWEA data first."
      phi = 0
      return
    endif

    if (size(mvn_swe_pad_arc,/type) ne 8) then begin
      mvn_swe_load_l2,prod=['arcpad'],/noerase
      pad3 = temporary(mvn_swe_pad_arc)  ; undefine the L2 if it wasn't there to start with
    endif else pad3 = mvn_swe_pad_arc    ; otherwise, leave the L2 alone
    npkt = n_elements(pad3)

    if ((npkt eq 0L) or (size(pad3,/type) ne 8)) then begin
      print,"No PAD burst data within the current time range."
      phi = 0
      return
    endif

    npts = n_elements(mvn_swe_engy)
    badphi = !values.f_nan  ; bad value guaranteed to be a NaN
    phi = replicate(mvn_pot_struct, npts)
    phi.time = mvn_swe_engy.time
    phi.potential = badphi
    phi.method = -1

; Process keywords

    reset = keyword_set(reset)
    dofill = keyword_set(fill)
    if not keyword_set(swidth) then swidth = 45.*!dtor else swidth *= !dtor

; Calculate potentials

;    print,'MVN_SWE_SC_NEGPOT_TWODIR_BURST:  This program is experimental - use with caution.'

    tmin = min(pad3.time, max=tmax)
    tsp = [tmin, tmax]                     ; time coverage for PAD burst data

    data = pad3.data
    pad3.data = smooth(data,[1,1,5],/nan)  ; smooth in time to increase SNR
    t = pad3.time                          ; PAD burst times
       
    pot = fltarr(npkt,2)                   ; separate potentials for para & anti-para
    pot[*,*] = badphi
    heii_pot = pot

    d2fps = fltarr(npkt,100)
    d2fms = d2fps
    std = fltarr(npkt,2)

    tic

    for i=0L,(npkt-1L) do begin

        pad = pad3[i]
        energy=pad.energy[*,0]

;       Extract parallel and anti-parallel pitch angle ranges from PAD data

        Fp = replicate(!values.f_nan,64)
        Fm = replicate(!values.f_nan,64)
          
        pndx = where(reform(pad.pa[63,*]) lt swidth, count)
        if (count gt 0L) then Fp = average(reform(pad.data[*,pndx]*pad.dpa[*,pndx]), 2, /nan)$
                                   /average(pad.dpa[*,pndx], 2, /nan)

        mndx = where(reform(pad.pa[63,*]) gt (!pi - swidth), count)
        if (count gt 0L) then Fm =average(reform(pad.data[*,mndx]*pad.dpa[*,mndx]), 2, /nan)$
                                  /average(pad.dpa[*,mndx], 2, /nan)

        ie = 64-18            ;20 eV

        mvn_swe_d2f_heii,Fp,Fm,energy,d2fp,d2fm,ee
        nee = n_elements(ee)
        d2fps[i,0:nee-1] = d2fp
        d2fms[i,0:nee-1] = d2fm

;       Parallel potential

        spec = d2fp
        en = ee
        lim = -0.05
        ebase = 23. - 0.705

        inn = where(spec le lim, npt)
        inp = where(spec gt 0.04, np)
        emax = max(en[inn], min=emin)
        emax = min([emax,27.])
        emap = max(en[inp], min=emip)

        if (npt gt 0 and np gt 0 and Fp[ie] ge 5.e6) then begin
          inmm = where((en ge emin) and (en le 2*median(en[inn])-emin))
          inpp = where(spec[inmm] gt 0.04,ct)
          std[i,0] = stddev(spec[inmm])
          if (emax-emin le 10) and (emax-emin gt 2.5) and $
             (emin le ebase and emin gt 3.5) and $
             (abs(median(en[inn[*]])-0.5*(emax+emin)) le 2) then begin
               pot[i,0] = emin - ebase
               ;pot[i,0] = emax - 27.0;ebase
               heii_pot[i,0] = emin
               if (emin-ebase ge -14 and ct gt 5) then pot[i,0] = badphi
          endif
        endif

;       Anti-parallel potential

        spec=d2fm
        inn = where(spec le lim, npt)
        inp = where(spec gt 0.04, np)
        emax = max(en[inn], min=emin)
        emax = min([emax,27.])
        emap = max(en[inp], min=emip)

        if (npt gt 0 and np gt 0 and Fm[ie] ge 5.e6) then begin
          inmm = where(en ge emin and en le 2*median(en[inn])-emin)
          inpp = where(spec[inmm] gt 0.04,ct)
          std[i,1] = stddev(spec[inmm])
          if (emax-emin le 10) and (emax-emin gt 2.5) and $
             (emin le ebase and emin gt 3.5) and $
             (abs(median(en[inn[*]])-0.5*(emax+emin)) le 2) then begin
                pot[i,1] = emin - ebase
                ;pot[i,1] = emax - 27.0;ebase
                heii_pot[i,1] = emin
                
                if (emin-ebase ge -14 and ct gt 5) then pot[i,1] = badphi
             endif
          endif
    endfor

    toc

    print,'finished calculating potentials'
    d2fps = d2fps[*,0:nee-1]
    d2fms = d2fms[*,0:nee-1]

;   Wake filter

    if keyword_set(shadow) then begin
      get_data, 'wake', data=wk0, index=i
      get_data, 'alt', data=alt0, index=j
      if (i eq 0) then begin
        maven_orbit_tplot, /loadonly
        get_data, 'wake', data=wk0
      endif
      wake = interpol(wk0.y,wk0.x,t)
      alt = interpol(alt0.y,alt0.x,t)
      ;inw = where((wake ne wake) and (alt ge 800), cts)
      inw = where(wake ne wake, cts)
      if cts gt 0 then pot[inw,*] = badphi
    endif

;   Package the result
    if keyword_set(scpot) then begin
       scpot0=max(pot,dim=2,/nan)
       pot1 = interp(scpot0,t,mvn_sc_pot.time,no_extra=1,interp_thresh=maxdt)
;       pot1 = interpol(scpot0, t, mvn_sc_pot.time)
;       indx = nn(t, mvn_sc_pot.time)
;       gap = where(abs(t[indx] - mvn_sc_pot.time) gt maxdt, count)
;       if (count gt 0L) then pot1[gap] = badphi ; estimates too far away

       igud = where(finite(pot1), ngud, complement=ibad, ncomplement=nbad)
       if (ngud gt 0) then begin
          store_data,'pot_inshdw',data={x:mvn_sc_pot[igud].time, y:pot1[igud]}
          options,'pot_inshdw','psym',3

          phi[igud].potential = pot1[igud]
          phi[igud].method = 5
       endif
    endif
;   Fill in the common block (optional)

    if (dofill) then begin
      indx = where((phi.method eq 5) and (mvn_sc_pot.method lt 1), count)
      if (count gt 0L) then begin
        mvn_sc_pot[indx] = phi[indx]
        mvn_swe_engy[indx].sc_pot = phi[indx].potential
      endif             
    endif

;   Create tplot variables

    store_data,'negpot_pad',data={x:t, y:pot[*,0:1]}
    name='negpot_pad'
    options,name,'ytitle','negpot'
    options,name,'labels',['para','anti-para']
    options,name,'colors',[254,64]
    options,name,'psym',3

    store_data,'d2fp',data={x:t,y:d2fps,v:ee}
    ename='d2fp'
    options,ename,'spec',1
    ylim,ename,10,30,0
    options,ename,'ytitle','Energy (eV)'
    options,ename,'ztitle',ename
    store_data,'heiip',data={x:t, y:heii_pot[*,0]}
    name='heiip'
    options,name,'psym',1
       
    store_data,'d2fp_pot',data=['d2fp','heiip']
    ylim,'d2fp_pot',10,30,0
    zlim,'d2fp_pot',-0.05,0.05,0
       
    store_data,'d2fm',data={x:t,y:d2fms,v:ee}
    ename='d2fm'
    options,ename,'spec',1
    ylim,ename,10,30,0
    options,ename,'ytitle','Energy (eV)'
    options,ename,'ztitle',ename
    store_data,'heiim',data={x:t, y:heii_pot[*,1]}
    name='heiim'
    options,name,'psym',1

    store_data,'d2fm_pot',data=['d2fm','heiim']
    ylim,'d2fm_pot',10,30,0
    zlim,'d2fm_pot',-0.05,0.05,0

end
