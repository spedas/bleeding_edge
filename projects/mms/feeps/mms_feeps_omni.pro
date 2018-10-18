;+
; PROCEDURE:
;         mms_feeps_omni
;
; PURPOSE:
;       Calculates the omni-directional flux for all 24 sensors 
;       
;       (this version re-bins the data due to the different energy channels for each s/c, sensor head and sensor ID)
;       
; INPUT:
;       probe:      spacecraft # (1, 2, 3, or 4)
;
; KEYWORDS:
;
;       datatype:   feeps data types include ['electron', 'electron-bottom', 'electron-top',
;                   'ion', 'ion-bottom', 'ion-top'].
;                   If no value is given the default is 'electron'.
;       data_rate:  instrument data rates for feeps include 'brst' 'srvy'. The
;                   default is 'srvy'
;       tplotnames: names of loaded tplot variables
;       suffix:     suffix used in call to mms_load_data; required to find the correct
;                   variables
;       data_units: specify units for omni-directional calculation
;
; NOTES:
;       New version, 1/26/17 - egrimes
;       Newer version, 1/31/17 - dturner
;       Fixed 2 bugs (3/29/17): 1) off by one bug when setting bottom sensor without data to NaNs, and
;                               2) now initializing output as NaNs, to avoid setting channels with 
;                                 counts=0 to NaN - egrimes
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-10-08 21:09:02 -0700 (Mon, 08 Oct 2018) $
; $LastChangedRevision: 25939 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_omni.pro $
;-


pro mms_feeps_omni, probe, datatype = datatype, tplotnames = tplotnames, suffix = suffix, $
  data_units = data_units, data_rate = data_rate, level = level, sensor_eyes=sensor_eyes
  if undefined(level) then level = 'l2'
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe))
  ; default to electrons
  if undefined(datatype) then datatype = 'electron'
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(data_units) then data_units = 'cps'
  if (data_units eq 'flux') then data_units = 'intensity'
  if (data_units eq 'cps') then data_units = 'count_rate'
  units_label = data_units eq 'intensity' ? '1/(cm!U2!N-sr-s-keV)' : 'Counts/s'
  
  probe = strcompress(string(probe), /rem)

  prefix = 'mms'+probe+'_epd_feeps_'

  if datatype eq 'electron' then begin
    energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
      200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]
  endif else energies = [57.900000d, 76.800000d, 95.400000d, 114.10000d, 133.00000d, 153.70000d, 177.60000d, $
       205.10000d, 236.70000d, 273.20000d, 315.40000d, 363.80000d, 419.70000d, 484.20000d,  558.60000d]
  
  ; Added by DLT on 31 Jan 2017: set unique energy and gain correction factors per spacecraft
  eEcorr = [14.0, -1.0, -3.0, -3.0]
  iEcorr = [0.0, 0.0, 0.0, 0.0]
  eGfact = [1.0, 1.0, 1.0, 1.0]
  iGfact = [0.84, 1.0, 1.0, 1.0]
  
  ; Added by DLT on 31 Jan 2017: set unique energy bins per spacecraft     
  ; Electrons:
  if probe eq '1' && datatype eq 'electron' then energies = energies + eEcorr[0]
  if probe eq '2' && datatype eq 'electron' then energies = energies + eEcorr[1]
  if probe eq '3' && datatype eq 'electron' then energies = energies + eEcorr[2]
  if probe eq '4' && datatype eq 'electron' then energies = energies + eEcorr[3]
  ; Ions:
  if probe eq '1' && datatype eq 'ion' then energies = energies + iEcorr[0]
  if probe eq '2' && datatype eq 'ion' then energies = energies + iEcorr[1]
  if probe eq '3' && datatype eq 'ion' then energies = energies + iEcorr[2]
  if probe eq '4' && datatype eq 'ion' then energies = energies + iEcorr[3]


  ;en_bins = bin_edges(energies) ; commented by DLT on 31 Jan 2017
  n_enbins = n_elements(energies) ; n_elements(en_bins)-1 ; changed by DLT on 31 Jan 2017
  en_label = energies
  en_chk = 0.10  ; percent error around energy bin center to accept data for averaging; anything outside of energies[i] +/- en_chk*energies[i] will be changed to NAN and not averaged 
  
  top_sensors = sensor_eyes['top']
  bot_sensors = sensor_eyes['bottom']
  
  var_name = strcompress(prefix+data_rate+'_'+level+'_'+datatype+'_top_'+data_units+'_sensorid_'+string(top_sensors[0])+'_clean_sun_removed'+suffix, /rem)
  get_data, var_name, data = d, dlimits=dl
  
  if is_struct(d) then begin
    flux_omni = dblarr(n_elements(d.x), n_elements(d.v))
    if level ne 'sitl' then begin
      dalleyes = dblarr(n_elements(d.x), n_elements(d.v), n_elements(top_sensors)+n_elements(bot_sensors))+!values.d_nan
      for isen = 0, n_elements(top_sensors)-1 do begin
        ; Top units:
        var_name = strcompress(prefix+data_rate+'_'+level+'_'+datatype+'_top_'+data_units+'_sensorid_'+string(top_sensors[fix(isen)])+'_clean_sun_removed'+suffix, /rem)
        get_data, var_name, data = d, dlimits=dl
        dalleyes[*,*,isen] = reform(d.y)
        iE = where(abs(energies - d.v) gt en_chk*energies) ; Check for energies beyond en_chk [%] of the corrected energy bin center and replace with NAN
        if iE[0] ne -1 then dalleyes[*,iE,isen] = !values.d_nan
      endfor
      for isen = 0, n_elements(bot_sensors)-1 do begin
        ; Bottom units:
        var_name = strcompress(prefix+data_rate+'_'+level+'_'+datatype+'_bottom_'+data_units+'_sensorid_'+string(bot_sensors[fix(isen)])+'_clean_sun_removed'+suffix, /rem)
        get_data, var_name, data = d, dlimits=dl
        dalleyes[*,*,isen+n_elements(top_sensors)] = reform(d.y)
        iE = where(abs(energies - d.v) gt en_chk*energies) ; Check for energies beyond en_chk [%] of the corrected energy bin center and replace with NAN
        if iE[0] ne -1 then dalleyes[*,iE,isen+n_elements(top_sensors)] = !values.d_nan
      endfor
    endif else begin
      dalleyes = dblarr(n_elements(d.x), n_elements(d.v), n_elements(top_sensors))+!values.d_nan
      for isen = 0, n_elements(top_sensors)-1 do begin
        ; Only Top units in SITL product:
        var_name = strcompress(prefix+data_rate+'_'+level+'_'+datatype+'_top_'+data_units+'_sensorid_'+string(top_sensors[fix(isen)])+'_clean_sun_removed'+suffix, /rem)
        get_data, var_name, data = d, dlimits=dl
        dalleyes[*,*,isen] = reform(d.y)
        iE = where(abs(energies - d.v) gt en_chk*energies) ; Check for energies beyond en_chk [%] of the corrected energy bin center and replace with NAN
        if iE[0] ne -1 then dalleyes[*,iE,isen] = !values.d_nan
      endfor
    endelse
  endif

  ; if no data found, just return
  if undefined(dalleyes) then return
  
  flux_omni = reform(average(dalleyes,3,/NAN))

  ; Added by DLT on 31 Jan 2017: set unique gain factors per spacecraft
  ; Electrons:
  if probe eq '1' && datatype eq 'electron' then flux_omni = flux_omni*eGfact[0]
  if probe eq '2' && datatype eq 'electron' then flux_omni = flux_omni*eGfact[1]
  if probe eq '3' && datatype eq 'electron' then flux_omni = flux_omni*eGfact[2]
  if probe eq '4' && datatype eq 'electron' then flux_omni = flux_omni*eGfact[3]
  ; Ions:
  if probe eq '1' && datatype eq 'ion' then flux_omni = flux_omni*iGfact[0]
  if probe eq '2' && datatype eq 'ion' then flux_omni = flux_omni*iGfact[1]
  if probe eq '3' && datatype eq 'ion' then flux_omni = flux_omni*iGfact[2]
  if probe eq '4' && datatype eq 'ion' then flux_omni = flux_omni*iGfact[3]

  
  newname = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_'+data_units+'_omni'+suffix, /rem)

  dl.cdf.vatt.catdesc = 'MMS' + probe + ' FEEPS omni-directional ' + datatype + ' ' + data_units
  
  store_data, newname, data={x: d.x, y: flux_omni, v: en_label}, dlimits=dl
  options, newname, spec=1, /ylog, /zlog ;, yticks=3, ystyle=1, zrange=[1., 1.e6];, no_interp=0, y_no_interp=0, x_no_interp=0

  options, newname, ysubtitle='[keV]', ztitle=units_label, ystyle=1, /default,  yrange = minmax(energies)
  append_array, tplotnames, newname
end ; pro
