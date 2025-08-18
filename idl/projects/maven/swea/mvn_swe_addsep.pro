;+
;PROCEDURE:   mvn_swe_addsep
;PURPOSE:
;  Loads SEP data, sums over the look directions, and stores electron and ion
;  energy spectra in tplot variables.
;
;USAGE:
;  mvn_swe_addsep
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;
;    PANS:          Named variable to hold an array of
;                   the tplot variable(s) created.
;
;    NOATT:         When averaging look directions, exclude data with the
;                   attenuator is enabled.  Default = 1.
;
;    FTO:           Make a panel for the omnidirectional FTO signal.
;
;    TSMO:          Smoothing interval for FTO signal.  Default = 65 sec.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-11-13 11:21:33 -0800 (Wed, 13 Nov 2024) $
; $LastChangedRevision: 32960 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addsep.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addsep, pans=pans, noatt=noatt, fto=fto, tsmo=tsmo

  noatt = (n_elements(noatt) gt 0) ? keyword_set(noatt) : 1
  dofto = keyword_set(fto)
  tsmo = (n_elements(tsmo) gt 0) ? double(tsmo[0]) : 65D

  mvn_sep_load

; Electrons

  if (find_handle('mvn_SEP1F_elec_eflux') gt 0) then begin
    sepe_pan = 'mvn_SEP_elec_eflux'
    get_data,'mvn_SEP1F_elec_eflux',data=sep1f,dl=dlim
    j = where(finite(sep1f.v[*,0]),count)
    if (count gt 0L) then v = reform(sep1f.v[j[0],*]) else v = findgen(15)
    get_data,'mvn_SEP1R_elec_eflux',data=sep1r
    get_data,'mvn_sep1_svy_ATT',data=att1
    indx = where(att1.y eq 2B, count)
    if (count gt 0L) then begin
      sep1f.y[indx,*] = !values.f_nan
      sep1r.y[indx,*] = !values.f_nan
    endif

    get_data,'mvn_SEP2F_elec_eflux',data=sep2f
    get_data,'mvn_SEP2R_elec_eflux',data=sep2r
    get_data,'mvn_sep2_svy_ATT',data=att2
    indx = where(att2.y eq 2B, count)
    if (count gt 0L) then begin
      sep2f.y[indx,*] = !values.f_nan
      sep2r.y[indx,*] = !values.f_nan
    endif

    sepe_y = replicate(!values.f_nan, n_elements(sep2f.x), n_elements(v), 4)
    indx = nn2(sep1f.x, sep2f.x, maxdt=1D, /valid, vindex=vndx)
    sepe_y[vndx,*,0] = sep1f.y[indx,*]
    sepe_y[vndx,*,1] = sep1r.y[indx,*]
    sepe_y[*,*,2] = sep2f.y
    sepe_y[*,*,3] = sep2r.y

    store_data,sepe_pan,data={x:sep2f.x, y:average(sepe_y,3,/nan), v:v}, dl=dlim
    undefine, sep1f, sep1r, sep2f, sep2r, att1, att2
    ylim,sepe_pan,20,200,1
    options,sepe_pan,'ytitle','SEP elec!ckeV'
    options,sepe_pan,'panel_size',0.5
  endif else begin
    print,"Missing SEP electron data."
    sepe_pan = ''
  endelse

; Ions

  if (find_handle('mvn_SEP1F_ion_eflux') gt 0) then begin
    sepi_pan = 'mvn_SEP_ion_eflux'
    get_data,'mvn_SEP1F_ion_eflux',data=sep1f,dl=dlim
    j = where(finite(sep1f.v[*,0]),count)
    if (count gt 0L) then v = reform(sep1f.v[j[0],*]) else v = findgen(15)
    get_data,'mvn_SEP1R_ion_eflux',data=sep1r
    get_data,'mvn_sep1_svy_ATT',data=att1
    indx = where(att1.y eq 2B, count)
    if (count gt 0L) then begin
      sep1f.y[indx,*] = !values.f_nan
      sep1r.y[indx,*] = !values.f_nan
    endif

    get_data,'mvn_SEP2F_ion_eflux',data=sep2f
    get_data,'mvn_SEP2R_ion_eflux',data=sep2r
    get_data,'mvn_sep2_svy_ATT',data=att2
    indx = where(att2.y eq 2B, count)
    if (count gt 0L) then begin
      sep2f.y[indx,*] = !values.f_nan
      sep2r.y[indx,*] = !values.f_nan
    endif

    sep_y = replicate(!values.f_nan, n_elements(sep2f.x), n_elements(v), 4)
    indx = nn2(sep1f.x, sep2f.x, maxdt=1D, /valid, vindex=vndx)
    sep_y[vndx,*,0] = sep1f.y[indx,*]
    sep_y[vndx,*,1] = sep1r.y[indx,*]
    sep_y[*,*,2] = sep2f.y
    sep_y[*,*,3] = sep2r.y

    store_data,sepi_pan,data={x:sep2f.x, y:average(sep_y,3,/nan), v:v}, dl=dlim
    undefine, sep1f, sep1r, sep2f, sep2r, att1, att2
    ylim,sepi_pan,20,6000,1
    options,sepi_pan,'ytitle','SEP ion!ckeV'
    options,sepi_pan,'ztitle','EFLUX'
    options,sepi_pan,'panel_size',0.5
  endif else begin
    print,"Missing SEP ion data."
    sepi_pan = ''
  endelse

; FTO

  if (dofto) then begin
    if (find_handle('mvn_sep1_A-FTO_Eflux_Energy') gt 0) then begin
      get_data,'mvn_sep1_A-FTO_Eflux_Energy',data=fto1a
      get_data,'mvn_sep1_B-FTO_Eflux_Energy',data=fto1b
      get_data,'mvn_sep1_svy_ATT',data=att1
      indx = where(att1.y eq 2B, count)
      fto1a.y[indx,*] = !values.f_nan
      fto1b.y[indx,*] = !values.f_nan

      get_data,'mvn_sep2_A-FTO_Eflux_Energy',data=fto2a
      get_data,'mvn_sep2_B-FTO_Eflux_Energy',data=fto2b
      get_data,'mvn_sep2_svy_ATT',data=att2
      indx = where(att2.y eq 2B, count)
      fto2a.y[indx,*] = !values.f_nan
      fto2b.y[indx,*] = !values.f_nan

      fto_y = replicate(0.,n_elements(fto2a.x),18,4)
      indx = nn2(fto1a.x, fto2a.x, maxdt=1d)
      fto_y[*,*,0] = fto1a.y[indx,*]
      fto_y[*,*,1] = fto1b.y[indx,*]
      fto_y[*,*,2] = fto2a.y
      fto_y[*,*,3] = fto2b.y
      fto_a = average(fto_y,3,/nan)

      store_data,'fto',data={x:fto2a.x, y:fto_a, v:fto2a.v}
      options,'fto','spec',1
      options,'fto','ytitle','SEP FTO!ckeV'
      ylim,'fto',3e2,2e4,1
      zlim,'fto',3e0,1e3,1
      options,'fto','panel_size',0.5

      E = fto2a.v
      n = n_elements(E)
      dE = E
      dE[0] = abs(E[1] - E[0])
      for i=1,(n-2) do dE[i] = abs(E[i+1] - E[i-1])/2.
      dE[n-1] = abs(E[n-2] - E[n-1])
      dE = replicate(1.,n_elements(fto2a.x)) # dE

      fto_sum = total(fto_a*dE,2,/nan)/1e3
      indx = where(finite(fto2a.x), count)
      store_data,'fto_sum',data={x:fto2a.x[indx], y:fto_sum[indx]}
      if (tsmo gt 2D) then begin
        tsmooth_in_time,'fto_sum',tsmo
        fto_pan = 'fto_sum_smoothed'
      endif else fto_pan = 'fto_sum'
      options,fto_pan,'ytitle','SEP FTO!cMeV/cm!u2!n-s-ster'

      undefine, fto1a, fto1b, fto2a, fto2b, att1, att2
    endif else begin
      print,"Missing SEP FTO data."
      fto_pan = ''
    endelse
  endif else fto_pan = ''

  pans = [fto_pan, sepi_pan, sepe_pan]
  indx = where(pans ne '', count)
  if (count gt 0L) then pans = pans[indx] else pans = ''

  return
  
end
