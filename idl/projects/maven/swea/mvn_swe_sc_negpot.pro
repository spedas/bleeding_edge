;+
;PROCEDURE:
;   mvn_swe_sc_negpot
;
;PURPOSE:
;   Estimates the negative spacecraft potential within the ionosphere
;   from SWEA energy spectra.  The basic idea is to use the second 
;   derivative of the spectrum to find the shift of the He II features
;   at 23 and 27 eV (mainly the 23 eV feature), from which then the 
;   negative potential can be calculated.  No attempt is made to 
;   estimate the potential when the spacecraft is in darkness or above
;   1000 km altitude.
;
;AUTHOR:
;   Shaosui Xu
;
;CALLING SEQUENCE:
;   This procedure requires tplot variables "mvn_swe_shape_par, swe_a4, alt,
;   sza, d2f".  If any of these variables does not exist, then this procedure
;   attempts to create them using the appropriate procedures.
;   
;INPUTS:
;   none
;
;KEYWORDS:
;	POTENTIAL: Returns spacecraft potentials in a structure.
;
;   FILL:      Do not fill in the common block.  Default = 0 (no).
;
;   RESET:     Initialize the spacecraft potential, discarding all previous 
;              estimates, and start fresh.
;
;   QLEVEL:    Minimum quality level for processing.  Filters out the vast
;              majority of spectra affected by the sporadic low energy
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
;   None - Result is stored in the common block variables swe_sc_pot and 
;          mvn_swe_engy, and as the TPLOT variable 'neg_pot'.
;
; $LastChangedBy: xussui_lap $
; $LastChangedDate: 2025-03-13 16:36:15 -0700 (Thu, 13 Mar 2025) $
; $LastChangedRevision: 33173 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_negpot.pro $
;
;-

pro mvn_swe_sc_negpot, potential=pot, fill=fill, reset=reset, qlevel=qlevel, maxalt=maxalt

    compile_opt idl2
    
    @mvn_swe_com
    @mvn_scpot_com
  
    if (size(Espan,/type) eq 0) then mvn_scpot_defaults

    reset = keyword_set(reset)
    dofill = keyword_set(fill)
    
    if ~keyword_set(maxalt) then maxalt = 1000.
; Make sure SWEA data are loaded, initialize potential structure

    if (size(mvn_swe_engy, /type) ne 8) then begin
      print,"You must load SWEA data first."
      return
    endif

    npts = n_elements(mvn_swe_engy)
    pot = replicate(mvn_pot_struct, npts)
    pot.time = mvn_swe_engy.time
    pot.potential = badval
    pot.method = -1

    badphi = !values.f_nan  ; bad value guaranteed to be a NaN
    qlevel = (n_elements(qlevel) gt 0) ? byte(qlevel[0]) < 2B : 1B

; Get the shape parameter from tplot.  Calculate it if necessary.

    get_data, 'mvn_swe_shape_par', data=shp, index=i
    if (i eq 0) then begin
      get_data, 'swe_a4', index=i
      if (i eq 0) then mvn_swe_sumplot, /loadonly
      mvn_swe_shape_par, var='swe_a4', erange=[15,100], /keep_nan
      get_data, 'mvn_swe_shape_par', data=shp, index=i
      if (i eq 0) then begin
        print,"Error getting shape parameter.  Abort!"
        return
      endif
    endif
    shape=shp.y

; Get ephemeris information from tplot.  Calculate it if necessary.

    get_data, 'alt', data=alt0, index=i
    if (i eq 0) then begin
      maven_orbit_tplot, /loadonly
      get_data, 'alt', data=alt0
    endif
    alt=alt0.y
    talt=alt0.x

    get_data,'sza',data=sza0
    sza=sza0.y

; Make sure data are in energy flux units

    old_units = mvn_swe_engy[0].units_name
    mvn_swe_convert_units, mvn_swe_engy, 'eflux'
    f40 = mvn_swe_engy.data[40]  ; electron energy flux at 43 eV

; Get d2(logF)/d(logE)2.  Calculate it if necessary.
    foo = mvn_swe_sc_pospot(mvn_swe_engy.energy, mvn_swe_engy.data)
    foo = 0
;    if (size(ee,/type) eq 0) then begin
;      foo = mvn_swe_sc_pospot(mvn_swe_engy.energy, mvn_swe_engy.data)
;      foo = 0
;    endif

    n_t = n_elements((transpose(ee))[*,0])
    if (n_t ne n_elements(mvn_swe_engy.time)) then begin
      foo = mvn_swe_sc_pospot(mvn_swe_engy.energy, mvn_swe_engy.data)
      foo = 0
    endif

    print,"Estimating negative potentials from SWEA."

    t1=mvn_swe_engy.time
    d2f=transpose(d2fs)
    en1=transpose(ee)
    alt1=spline(talt,alt,t1)
    sza1=spline(talt,sza,t1)
    pot1=dblarr(n_elements(t1))
    pot1[*]=badphi
    heii_pot1=pot1
    altcut=400;8000
    ;calculate terminator
    base=150 ;to set a slightly higher altitude to avoid falsely identifying potentials
    R_m=3396.
    ;maxalt = 1000.
    term=90+acos((R_m+base)/(R_m+alt1))*!radeg
    indx=where((f40 gt 1.e6 and sza1 le term) and $
        (alt1 le altcut or (alt1 gt altcut and alt1 le maxalt and shape le 0.9)),cts)
    ;indx=where((f40 gt 1.e6) and sza1 le term and (shape le .9),cts)
    lim=-0.05
    ebase=23-0.705

    ;******************************************************************************************
    ;Mth 2
    ;ine=where(en ge 4)
    orb=floor(mvn_orbit_num(time=t1))+0.5
    for io=min(orb),max(orb) do begin
        ino=where(orb[indx] eq io, ox)
        if ox gt 1 then begin
            for i=0, ox - 1 do begin
                spec=reform(d2f[indx[ino[i]],*])
                en = reform(en1[indx[ino[i]],*])

                inn = where(spec le lim, npt)
                inp = where(spec gt 0.04, np)

                emax = max(en[inn], min=emin)
                emap = max(en[inp], min=emip)
                if (npt gt 0 and np gt 0) then begin
                    if (emax-emin le 10) and (emax-emin gt 2) and $
                        (emin le ebase and emin gt 3.5) then begin
                        ; (abs(median(en[inn])-0.5*(emin+emax)) le 1) and
                        pot1[indx[ino[i]]]=emin-ebase
                        heii_pot1[indx[ino[i]]] = emin
                        if (pot1[indx[ino[i]]] le -5 and alt1[indx[ino[i]]] gt altcut) then $
                            pot1[indx[ino[i]]]=badphi
                    endif else begin
                        if alt1[indx[ino[i]]] le 200 and emin gt 6 and emin le 9 $
                            and emap le 10 and emap gt 5 then begin
                            pot1[indx[ino[i]]]=emin-ebase-3
                            heii_pot1[indx[ino[i]]] = emin
                        endif
                    endelse
                endif
                ;stop
            endfor

            inc=where(pot1[indx[ino]] eq pot1[indx[ino]], mpts)
            dx=indx[ino[inc]]
            if dx[0] ne -1 then pot1[indx[ino[inc[0]:inc[mpts-1]]]]=$
                interp(pot1[dx],t1[dx],t1[indx[ino[inc[0]:inc[mpts-1]]]],interp_thres=120.d)
;            if dx[0] ne -1 then pot1[indx[ino[inc[0]:inc[mpts-1]]]]=$
;                interpol(pot1[indx[ino[inc[0]:inc[mpts-1]]]],$
;                t1[indx[ino[inc[0]:inc[mpts-1]]]],t1[indx[ino[inc[0]:inc[mpts-1]]]],/nan)
            ;stop
        endif
    endfor

; Filter based on QUALITY flag

    str_element, mvn_swe_engy, 'quality', success=ok
    if (ok) then begin
      indx = where(mvn_swe_engy.quality lt qlevel, count)
      if (count gt 0L) then begin
        pot1[indx] = !values.f_nan
        heii_pot1[indx] = !values.f_nan
      endif
    endif

; Make tplot variables

    phi={x:t1,y:pot1}
    str_element,phi,'thick',4,/add
    str_element,phi,'psym',3,/add
    store_data, 'neg_pot', data=phi
;   options,'neg_pot','constant',15

    phi={x:t1,y:heii_pot1}
    str_element,phi,'thick',4,/add
    str_element,phi,'psym',3,/add
    store_data, 'heii_pot', data=phi

    store_data,'d2f_pot',data=['d2f','heii_pot']
    ylim,'d2f_pot',0,30
    zlim,'d2f_pot',-0.05,0.05

; Fill in the potential structure with valid SWE- estimates

  igud = where(finite(pot1), ngud, complement=ibad, ncomplement=nbad)
  if (ngud gt 0) then begin
    pot[igud].potential = pot1[igud]
    pot[igud].method = 3   ; swe- method
  endif

  msg = string("SWE- : ",ngud," valid potentials from ",npts," spectra",format='(a,i8,a,i8,a)')
  print, strcompress(strtrim(msg,2))

; Update the common block

  if (reset) then begin
    swe_sc_pot = replicate(mvn_pot_struct, npts)
    swe_sc_pot.potential = badphi
    swe_sc_pot.method = -1  ; invalid
    mvn_swe_engy.sc_pot = badphi
  endif

  if (dofill) then begin
    indx = where(swe_sc_pot.method lt 1, count)
    if (count gt 0) then swe_sc_pot[indx] = pot[indx]
    indx = where((alt1 le maxalt) and finite(pot1) and (swe_sc_pot.potential gt 0.), count)
    if (count gt 0) then swe_sc_pot[indx] = pot[indx]

    if (finite(badval)) then begin
      indx = where(swe_sc_pot.method lt 1, count)
      if (count gt 0L) then begin
        swe_sc_pot[indx].potential = badval
        swe_sc_pot[indx].method = 0  ; manually set to a finite value
      endif
    endif

    mvn_swe_engy.sc_pot = pot.potential
  endif

end
