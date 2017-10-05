; Get FPI data and delete variables not used by EVA.
;
;

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2016-09-30 18:05:55 -0700 (Fri, 30 Sep 2016) $
;  $LastChangedRevision: 21993 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_fpi_moments.pro $


pro mms_sitl_fpi_moments, sc_id = sc_id, clean=clean

  ; See if spacecraft id is set
  if ~keyword_set(sc_id) then begin
    print, 'Spacecraft ID not set, defaulting to mms1'
    sc_id = ['mms1']
  endif else begin
    ivalid = intarr(n_elements(sc_id))
    for j = 0, n_elements(sc_id)-1 do begin
      sc_id(j)=strlowcase(sc_id(j)) ; this turns any data type to a string
      if sc_id(j) ne 'mms1' and sc_id(j) ne 'mms2' and sc_id(j) ne 'mms3' and sc_id(j) ne 'mms4' then begin
        ivalid(j) = 1
      endif
    endfor
    if min(ivalid) eq 1 then begin
      message,"Invalid spacecraft ids. Using default spacecraft mms1",/continue
      sc_id='mms1'
    endif else if max(ivalid) eq 1 then begin
      message,"Both valid and invalid entries in spacecraft id array. Neglecting invalid entries...",/continue
      print,"... using entries: ", sc_id(where(ivalid eq 0))
      sc_id=sc_id(where(ivalid eq 0))
    endif
  endelse

  for j = 0, n_elements(sc_id)-1 do begin
    
    prb = fix(strmid(sc_id(j), 3, 1))
    
    ; Load ion and electron data
    
    mms_load_fpi, probes = prb, data_rate = 'fast', level = 'ql', datatype = 'dis', min_version='3.0.0'
    mms_load_fpi, probes = prb, data_rate = 'fast', level = 'ql', datatype = 'des', min_version='3.0.0'
    
    
    ; Densities
    name = 'mms' + prb + '_des_numberdensity_fast'
    get_data, name, data=Nelc, dlimits=dlimits
    name = 'mms' + prb + '_dis_numberdensity_fast'
    get_data, name, data=Nion, dlimits=dlimits

    if ~is_struct(Nelc) or ~is_struct(Nion) then begin
      print, 'NO V3 FPI FILES. SKIPPING.'
      continue
    endif

    npts = n_elements(Nelc.X)
    Y = fltarr(npts,2)
    Y(*,0) = Nelc.Y ; convol(Nelc.Y,[0.25, 0.5, 0.25])
    Y(*,1) = interpol(Nion.Y, Nion.X, Nelc.X)  ;interpol(convol(Nion.Y, [0.25, 0.5, 0.25]), Nion.X, Nelc.X)

    dlim = {CDF: dlimits.cdf, SPEC: 0b, YLOG: 1b, YSUBTITLE: '(cm!U-3!N)', $
      COLORS: [2,6], $
      LABELS: ['Electron', 'Ion'], LABFLAG: 1}
    DensityN = 'mms' + prb + '_fpi_density'
    store_data, DensityN, data={X:Nelc.X, Y:Y, V: [1,2]}, dlim=dlim

    ; Electron and ion bulk velocities
    
    ivel_n = 'mms' + prb + '_fpi_ion_vel_dbcs'
    evel_n = 'mms' + prb + '_fpi_elec_vel_dbcs'
    
    tplot_rename, 'mms' + prb + '_dis_bulkv_dbcs_fast', ivel_n
    tplot_rename, 'mms' + prb + '_des_bulkv_dbcs_fast', evel_n
    
    ; Temperatures
    epara_name = 'mms' + prb + '_des_temppara_fast'
    eperp_name = 'mms' + prb + '_des_tempperp_fast'

    ipara_name = 'mms' + prb + '_dis_temppara_fast'
    iperp_name = 'mms' + prb + '_dis_tempperp_fast'

    get_data, epara_name, data = tepar
    get_data, eperp_name, data = teprp
    get_data, ipara_name, data = tipar
    get_data, iperp_name, data = tiprp

    npts = n_elements(tepar.x)
    TallY = fltarr(npts, 4)
    TallY(*,0) = teprp.Y
    TallY(*,1) = tepar.Y
    TallY(*,2) = interpol(tiprp.y, tiprp.x, teprp.x, /NAN)
    TallY(*,3) = interpol(tipar.y, tipar.x, tepar.x, /NAN)

    dlim = {CDF: dlimits.cdf, SPEC: 0b, YLOG: 1b, YSUBTITLE: '(eV)', $
      COLORS: [2,4,6,7], $
      LABELS: ['Te!DPerp!N', 'Te!DPar!N', 'Ti!DPerp!N', 'Ti!DPar!N'], LABFLAG: 1}

    TempN = 'mms' + prb + '_fpi_temp'
    store_data, TempN, data={x:tepar.x, y:TallY}, dlim=dlim

    ; Spectra
    tplot_rename, 'mms' + prb + '_dis_energyspectr_omni_fast', 'mms' + prb + '_fpi_ions'
    tplot_rename, 'mms' + prb + '_des_energyspectr_omni_fast', 'mms' + prb + '_fpi_electrons'
    
    ; Electron pitch angle distributions
    
    lowpname = 'mms' + prb + '_des_pitchangdist_lowen_fast'
    midpname = 'mms' + prb + '_des_pitchangdist_miden_fast'
    highpname = 'mms' + prb + '_des_pitchangdist_highen_fast'
    
    newlowpname = 'mms' + prb + '_fpi_epad_lowen_fast'
    newmidpname = 'mms' + prb + '_fpi_epad_miden_fast'
    newhighpname = 'mms' + prb + '_fpi_epad_highen_fast'

    tplot_rename, lowpname, newlowpname
    tplot_rename, midpname, newmidpname
    tplot_rename, highpname, newhighpname
    
    if keyword_set(clean) then begin
      tplot_names, '*des*', names=names
      store_data, delete=names
      tplot_names, '*dis*', names=names
      store_data, delete=names
    endif
        
  endfor


end