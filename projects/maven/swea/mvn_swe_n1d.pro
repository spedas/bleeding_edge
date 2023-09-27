;+
;PROCEDURE: 
;	mvn_swe_n1d
;PURPOSE:
;	Determines density and temperature moments from 1D energy spectra.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_n1d
;INPUTS: 
;KEYWORDS:
;   PANS:      Named variable to return tplot panels created.
;
;   DDD:       Calculate density from 3D distributions (allows bin
;              masking).  Typically lower cadence and coarser energy
;              resolution.
;
;   ABINS:     Anode bin mask -> 16 elements (0 = off, 1 = on)
;              Default = replicate(1,16)
;
;   DBINS:     Deflector bin mask -> 6 elements (0 = off, 1 = on)
;              Default = replicate(1,6)
;
;   OBINS:     3D solid angle bin mask -> 96 elements (0 = off, 1 = on)
;              Default = reform(ABINS # DBINS)
;
;   MASK_SC:   Mask the spacecraft blockage.  This is in addition to any
;              masking defined by the ABINS, DBINS, and OBINS.
;              Default = 1 (yes).  Set this to 0 to disable and use the
;              above 3 keywords only.
;
;   MINDEN:    Smallest reliable density (cm-3).  Default = 0.08
;
;   ERANGE:    Restrict calculation to this energy range.
;
;   SECONDARY: Estimate and remove secondary electrons before calculating
;              moments.  See mvn_swe_secondary for details.
;
;   QLEVEL:    Minimum quality level for calculating moments.  Filters out
;              the vast majority of spectra affected by the sporadic low energy
;              anomaly below 28 eV.  The validity levels are:
;
;                0B = Data are affected by the low-energy anomaly.  There
;                     are significant systematic errors below 28 eV.
;                1B = Unknown because: (1) the variability is too large to 
;                     confidently identify anomalous spectra, as in the 
;                     sheath, or (2) secondary electrons mask the anomaly,
;                     as in the sheath just downstream of the bow shock.
;                2B = Data are not affected by the low-energy anomaly.
;                     Caveat: There is increased noise around 23 eV, even 
;                     for "good" spectra.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-09-25 16:30:03 -0700 (Mon, 25 Sep 2023) $
; $LastChangedRevision: 32129 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_n1d.pro $
;
;-
pro mvn_swe_n1d, pans=pans, ddd=ddd, abins=abins, dbins=dbins, obins=obins, mask_sc=mask_sc, $
                 mom=mom, minden=minden, erange=erange, secondary=sec, qlevel=qlevel

  compile_opt idl2

  @mvn_swe_com

  mass = mass_e                    ; electron rest mass [eV/(km/s)^2]
  c1 = (mass/(2D*!dpi))^1.5D
  c2 = (2d5/(mass*mass))
  c3 = 4D*!dpi*1d-5*sqrt(mass/2D)  ; assume isotropic electron distribution
  tiny = 1.d-31
  
  if (size(mom,/type) eq 0) then mom = 1
  if (size(minden,/type) eq 0) then minden = 0.08  ; minimum density
  dosec = keyword_set(sec)
  qlevel = (n_elements(qlevel) gt 0) ? byte(qlevel[0]) < 2B : 0B

; Get energy spectra from SPEC or 3D distributions

  if keyword_set(ddd) then begin

    if ((size(swe_3d,/type) ne 8) and (size(mvn_swe_3d,/type) ne 8)) then begin
      print,"No 3D data."
      return
    endif

    if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
    if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
    if (n_elements(obins) ne 96) then begin
      obins = replicate(1B, 96, 2)
      obins[*,0] = reform(abins # dbins, 96)
      obins[*,1] = obins[*,0]
    endif else obins = byte(obins # [1B,1B])
    if (size(mask_sc,/type) eq 0) then mask_sc = 1
    if keyword_set(mask_sc) then obins = swe_sc_mask * obins
   
    if (size(mvn_swe_3d,/type) eq 8) then t = mvn_swe_3d.time $
                                     else t = swe_3d.time

    npts = n_elements(t)
    dens = fltarr(npts)
    temp = dens
    dsig = dens
    tsig = dens
    bkg = dens

    energy = fltarr(64, npts)
    eflux = energy
    sig2 = energy
    sc_pot = fltarr(npts)

    for i=0L,(npts-1L) do begin
      ddd = mvn_swe_get3d(t[i], units='eflux')
      f = ddd.data
      v = ddd.var
      if (dosec) then begin
        mvn_swe_secondary, ddd
        fs = ddd.bkg
        indx = where(~ddd.valid, count)
        if (count gt 0L) then begin
          f[indx] = tiny
          v[indx] = tiny
          fs[indx] = 0.
        endif
      endif else fs = 0.

      if (ddd.time gt t_mtx[2]) then boom = 1 else boom = 0
      ondx = where(obins[*,boom], ocnt)
      onorm = float(ocnt)
      obins_b = replicate(1B, 64) # obins[*,boom]

      energy[*,i] = ddd.energy[*,0]
      eflux[*,i] = total((f - fs)*obins_b,2)/onorm
      sig2[*,i] = total(v*obins_b,2)
      sc_pot[i] = ddd.sc_pot
    endfor

  endif else begin

    if (size(mvn_swe_engy,/type) ne 8) then mvn_swe_makespec

    t = mvn_swe_engy.time
    npts = n_elements(t)
    dens = fltarr(npts)
    temp = dens
    dsig = dens
    tsig = dens

    ounits = mvn_swe_engy[0].units_name
    mvn_swe_convert_units, mvn_swe_engy, 'eflux'
    energy = mvn_swe_engy.energy
    eflux = mvn_swe_engy.data
    var = mvn_swe_engy.var
    bkg = mvn_swe_engy.bkg
    sc_pot = mvn_swe_engy.sc_pot

    if (dosec) then begin
      mvn_swe_secondary, mvn_swe_engy
      bkg = mvn_swe_engy.bkg
      indx = where(~mvn_swe_engy.valid, count)
      if (count gt 0L) then begin
        eflux[indx] = tiny
        var[indx] = tiny
        bkg[indx] = 0.
      endif
    endif else bkg[*] = 0.
  endelse

  E = energy[*,0]
  dE = E
  dE[0] = abs(E[1] - E[0])
  for i=1,62 do dE[i] = abs(E[i+1] - E[i-1])/2.
  dE[63] = abs(E[63] - E[62])

  sdev = sqrt(var)

; Trim data to desired energy range

  if (n_elements(erange) gt 1) then begin
    Emin = min(erange, max=Emax)
    endx = where((E ge Emin) and (E le Emax), n_e)
    if (n_e eq 0L) then begin
      print,"No data within energy range: ",erange
      return
    endif
    E = E[endx]
    dE = dE[endx]
    eflux = eflux[endx,*]
    sdev = sdev[endx,*]
  endif

; Calculate the moments

  for i=0L,(npts-1L) do begin
    F = (eflux[*,i] - bkg[*,i]) > 0.
    S = sdev[*,i]
    pot = sc_pot[i]

    if (finite(pot)) then begin
      j = where(E gt pot, n_e)
      if (n_e lt n_elements(E)) then begin
        j = j[0:(n_e-2)]  ; one channel cushion from s/c potential
        n_e--
      endif
    endif else n_e = 0

    if (mom) then begin
      if (n_e gt 0) then begin
        prat = (pot/E[j]) < 1.
        Enorm = c3*dE[j]*sqrt(1. - prat)*(E[j]^(-1.5))
        N_j = Enorm*F[j]
        S_j = Enorm*S[j]

        dens[i] = total(N_j)
        dsig[i] = sqrt(total(S_j^2.))

        Enorm = (2./3.)*c3*dE[j]*((1. - prat)^1.5)*(E[j]^(-0.5))
        P_j = Enorm*F[j]
        S_j = Enorm*S[j]

        pres = total(P_j)
        psig = sqrt(total(S_j^2.))
        
        temp[i] = pres/dens[i]
        tsig[i] = temp[i]*sqrt((dsig[i]/dens[i])^2. + (psig/pres)^2.)
      endif else begin
        dens[i] = !values.f_nan
        temp[i] = !values.f_nan
        dsig[i] = !values.f_nan
        tsig[i] = !values.f_nan
      endelse
    endif else begin
      if (n_e gt 0) then begin
        p = swe_maxbol()
        p.pot = pot
        Fmax = max(F[j],k,/nan)
        Emax = E[j[k]]
        p.t = Emax/2.
        p.n = Fmax/(4.*c1*c2*sqrt(p.t)*exp((p.pot/p.t) - 2.))
        Elo = Emax*0.8 < ((Emax/2.) > pot)
        j = where((E gt Elo) and (E lt Emax*3.))

        fit,E[j],F[j],dy=S[j],func='swe_maxbol',par=p,names='N T',p_sigma=sig,/silent

        j = where(E gt Emax*2.)
        E_halo = E[j]
        F_halo = F[j] - swe_maxbol(E_halo, par=p)
        prat = (p.pot/E_halo) < 1.

        N_halo = c3*total(dE[j]*sqrt(1. - prat)*(E_halo^(-1.5))*F_halo)

        dens[i] = p.n + N_halo
        temp[i] = p.t
      
        dsig[i] = sig[0]
        tsig[i] = sig[1]
      endif else begin
        dens[i] = !values.f_nan
        temp[i] = !values.f_nan
        dsig[i] = !values.f_nan
        tsig[i] = !values.f_nan
      endelse
    endelse
    
  endfor

; Filter out bad data

  indx = where(dens lt minden, count)
  if (count gt 0L) then begin
    dens[indx] = !values.f_nan
    temp[indx] = !values.f_nan
    dsig[indx] = !values.f_nan
    tsig[indx] = !values.f_nan
  endif

; New version of low-energy masking

  str_element, mvn_swe_engy, 'quality', success=ok
  if (ok) then begin
    indx = where(mvn_swe_engy.quality lt qlevel, count)
    if (count gt 0L) then begin
      dens[indx] = !values.f_nan
      temp[indx] = !values.f_nan
      dsig[indx] = !values.f_nan
      tsig[indx] = !values.f_nan
    endif
  endif else print,"Quality level not defined."

; Old version of low-energy masking (to be replaced)

  if (0) then begin
    lowe_test = {x:t, y:replicate(1.,npts)}
    mvn_swe_lowe_mask, lowe_test
    dens *= lowe_test.y
    temp *= lowe_test.y
    dsig *= lowe_test.y
    tsig *= lowe_test.y
  endif

; Create TPLOT variables

  if keyword_set(ddd) then mode = '3d' else mode = 'spec'
  dname = 'mvn_swe_' + mode + '_dens'
  tname = 'mvn_swe_' + mode + '_temp'

  ddata = {x:t, y:dens, dy:dsig, ytitle:'Ne [cm!u-3!n]'}
  store_data,dname,data=ddata
  options,dname,'ynozero',1
  options,dname,'psym',3

  tdata = {x:t, y:temp, dy:tsig, ytitle:'Te [eV]'}
  store_data,tname,data=tdata
  options,tname,'ynozero',1
  options,tname,'psym',3

  pans = [dname, tname]
  
  return

end
