;+
;PROCEDURE: 
;	mvn_swe_sciplot
;PURPOSE:
;	Creates a science-oriented summary plot for SWEA and MAG and optionally other 
;   instruments.
;
;   Warning: This routine can consume a large amount of memory:
;
;     SWEA + MAG : 0.6 GB/day
;     SEP        : 0.2 GB/day
;     SWIA       : 0.2 GB/day
;     STATIC     : 3.5 GB/day
;     LPW        : 0.001 GB/day
;     EUV        : 0.004 GB/day
;     -------------------------
;      total     : 4.5 GB/day
;
;   You'll also need memory for performing calculations on large arrays, so you
;   can create a plot with all data types spanning ~1 day per 8 GB of memory.
;
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_sciplot
;INPUTS:
;   None:      Uses data currently loaded into the SWEA common block.
;
;KEYWORDS:
;   SUN:       Create a panel for the Sun direction in spacecraft coordinates.
;
;   RAM:       Create a panel for the RAM direction in spacecraft coordinates.
;
;   NADIR:     Create a panel for the Nadir direction in spacecraft coordinates.
;
;   DATUM:     Reference surface for calculating altitude.  Can be one of
;              "sphere", "ellipsoid", "areoid", or "surface".  Passed to 
;              maven_orbit_tplot.  Default = 'ellipsoid'.
;              See mvn_altitude.pro for details.
;
;   SEP:       Include two panels for SEP data: one for ions, one for electrons.
;
;   SWIA:      Include panels for SWIA ion density and bulk velocity (coarse
;              survey ground moments).
;
;   STATIC:    Include two panels for STATIC data: one mass spectrum, one energy
;              spectrum.
;
;   APID:      Additional STATIC APID's to load.  (Hint: D0, D1 might be useful.)
;
;   LPW:       Include panel for electron density from LPW data.
;
;              Note: if two or more of O2+, O+, and electron densities are present
;              they are combined into a single panel.
;
;   EUV:       Include a panel for EUV data.
;
;   SC_POT:    Include a panel for spacecraft potential.
;
;   EPH:       Named variable to hold ephemeris data.
;
;   LOADONLY:  Create tplot variables, but don't plot.
;
;   PANS:      Array of tplot variables created.
;
;   PADSMO:    Smooth the resampled PAD data in time with this smoothing interval,
;              in seconds.
;
;   SHAPE:     Include a panel for the electron shape parameter.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-11-09 11:39:31 -0800 (Fri, 09 Nov 2018) $
; $LastChangedRevision: 26094 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sciplot.pro $
;
;-

pro mvn_swe_sciplot, sun=sun, ram=ram, sep=sep, swia=swia, static=static, lpw=lpw, euv=euv, $
                     sc_pot=sc_pot, eph=eph, min_pad_eflux=min_pad_eflux, loadonly=loadonly, $
                     pans=pans, padsmo=padsmo, apid=apid, shape=shape, nadir=nadir, datum=datum

  compile_opt idl2

  @mvn_swe_com
  @maven_orbit_common

  if not keyword_set(APID) then apid = 0
  
  if (size(min_pad_eflux,/type) eq 0) then min_pad_eflux = 6.e4

; Make sure the datum is valid

  dlist = ['sphere','ellipsoid','areoid','surface']
  if (size(datum,/type) ne 7) then datum = dlist[1]
  i = strmatch(dlist, datum+'*', /fold)
  case (total(i)) of
     0   : begin
             print, "Datum not recognized: ", datum
             result = 0
             return
           end
     1   : datum = (dlist[where(i eq 1)])[0]
    else : begin
             print, "Datum is ambiguous: ", dlist[where(i eq 1)]
             result = 0
             return
           end
  endcase

  mvn_swe_stat, /silent, npkt=npkt
  if (npkt[4] eq 0) then begin
    print,"No SWEA data loaded."
    return
  endif

; Make sure ephemeris covers loaded data

  tplot_options, get=topt
  if (max(topt.trange) lt 1D) then timespan, (minmax(a4.time) + [0D,34D])

  if (find_handle('alt2',v=-1) gt 0) then begin
    get_data,'alt',data=alt
    tsp = minmax(alt.x)
    indx = where((a4.time lt tsp[0]) or (a4.time gt tsp[1]), count)
    if (count gt 0) then maven_orbit_tplot, /loadonly, /shadow, datum=datum
  endif else maven_orbit_tplot, /loadonly, /shadow, datum=datum

  mvn_swe_sumplot,/loadonly

; Try to load resampled PAD data - mask noisy data

  mvn_swe_pad_restore
  pad_pan = 'mvn_swe_pad_resample'
  get_data, pad_pan, data=pad, index=i, alim=dl
  if (i gt 0) then begin
    nf = rebin(dl.nfactor, n_elements(pad.x), n_elements(pad.y[0,*]))
    indx = where(average(pad.y*nf,2,/nan) lt min_pad_eflux, count)
    if (count gt 0L) then begin
      pad.y[indx,*] = !values.f_nan
      store_data, pad_pan, data=pad, dl=dl
    endif
    if (size(padsmo,/type) ne 0) then begin
      dx = median(pad.x - shift(pad.x,1))
      dt = double(padsmo[0])
      if (dt gt 1.5D*dx) then begin
        tsmooth_in_time, pad_pan, padsmo
        pad_pan += '_smoothed'
      endif
    endif
    zlim,pad_pan,0,2,0
    options,pad_pan,'zticks',2
  endif else pad_pan = 'swe_a2_280'

; Spacecraft orientation

  alt_pan = 'alt2'

  if keyword_set(sun) then begin
    mvn_sundir, frame='swe', /polar
    sun_pan = 'Sun_SWEA_The'
    get_data,sun_pan,index=i
    if (i eq 0) then sun_pan = ''
  endif else sun_pan = ''

  if keyword_set(ram) then begin
    mvn_ramdir
    ram_pan = 'V_sc_MAVEN_SPACECRAFT'
    get_data,ram_pan,index=i
    if (i eq 0) then ram_pan = ''
  endif else ram_pan = ''

  if keyword_set(nadir) then begin
    mvn_nadir
    ndr_pan = 'Nadir_MAVEN_SPACECRAFT'
    get_data,ndr_pan,index=i
    if (i eq 0) then ndr_pan = ''
  endif else ndr_pan = ''

; MAG data

  mvn_swe_addmag
  mvn_mag_geom
  mvn_mag_tplot, /model
  
  mag_pan = ['mvn_mag_bamp','mvn_mag_bang']

; Shape Parameter

  shape_pan = ''
  if keyword_set(shape) then begin
     mvn_swe_shape_restore,/tplot
     get_data,'Shape_PAD',index=i
    if (i eq 0) then begin
      mvn_swe_shape_par_pad_l2, spec=45, /pot, tsmo=16
      get_data,'Shape_PAD',index=i
    endif
    if (i gt 0) then begin
      shape_pan = 'Shape_PAD'
      options, shape_pan, 'ytitle', 'Elec Shape'
    endif
  endif

; SEP electron and ion data - sum all look directions for both units

  sep_pan = ''
  if keyword_set(sep) then mvn_swe_addsep, pans=sep_pan

; SWIA survey data

  swi_pan = ''
  if keyword_set(swia) then mvn_swe_addswi, pans=swi_pan

; STATIC data

  sta_pan = ''
  if keyword_set(static) then mvn_swe_addsta, pans=sta_pan, apid=apid

; LPW data

  lpw_pan = ''
  if keyword_set(lpw) then mvn_swe_addlpw, pans=lpw_pan

; EUV data

  euv_pan = ''
  if keyword_set(euv) then mvn_swe_addeuv, pans=euv_pan

; Spacecraft Potential

  engy_pan = 'swe_a4'
  pot_pan = ''
  if keyword_set(sc_pot) then begin
    mvn_scpot
    engy_pan = 'swe_a4_pot'
    options,engy_pan,'ytitle','SWEA elec!ceV'
    pot_pan = 'scpot_comp'
  endif

; Ephemeris information from SPICE

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then mvn_swe_spice_init,/force
  eph = state

  mvn_mars_localtime, result=mlt  
  str_element, eph, 'lst', mlt.lst, /add
  str_element, eph, 'slon', mlt.slon, /add
  str_element, eph, 'slat', mlt.slat, /add

; Burst bar, if available

  get_data,'swe_a3_bar',index=i
  if (i gt 0) then bst_pan = 'swe_a3_bar' else bst_pan = ''

; Assemble the panels and plot

  pans = [ram_pan, ndr_pan, sun_pan, alt_pan, $
          euv_pan, swi_pan, sta_pan, mag_pan, $
          sep_pan, lpw_pan, pad_pan, pot_pan, $
          bst_pan, shape_pan, engy_pan]

  indx = where(pans ne '', npans)
  if (npans gt 0) then begin
    pans = pans[indx]
    if (not keyword_set(loadonly)) then tplot, pans
  endif else pans = ''

  return

end
