;+
; Procedure:
;     goesr_load_data
;
; Purpose:
;     Loads data from GOES-R satelites (GOES-16, GOES-17)
;     or from reprocessed data from earlier satelites (GOES 8-15).
;
; Keywords:
;     trange:       Time range of interest
;     datatype:     Type of GOES-R data to be loaded. Valid data types are:
;                     'mag': Magnetometer (default: 1 min, 'hires': 0.1 sec)
;                     'xrs': EXIS X-Ray Sensor (default: 1 min, 'hires': 1 sec);
;                     'mpsh': Magnetospheric Electrons and Protons, Medium and High Energy (MPSH)
;                             (default: 5 min, hires: 1 min)
;                     'sgps': Solar and Galactic Proton Sensors (SGPS)
;                             (default: 5 min, Hires: 1 min)
;     prefix:        String to append to the beginning of the loaded tplot variables
;     suffix:        String to append to the end of the loaded tplot variables
;     prefix:        String to append to the beginning of the loaded tplot variables
;     probes:        Array of GOES spacecrafts (8-17). Default is probes=['16'].
;     varnames:      Array of names of variables to load. Defaults is all (*)
;     downloadonly: Download files but don't load them into tplot.
;     hires:        If set, download full data files (larger files, can be over 180MB).
;                   If not set, use lowest available resolution (default).
;     no_time_clip: Don't clip the tplot variables.
;     get_support_data: Keep the support data.
;
; Notes:
;     NOAA Site:  https://www.ngdc.noaa.gov/stp/satellite/goes-r.html
;     data:   https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes16/l2/data/
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2024-06-08 13:44:22 -0700 (Sat, 08 Jun 2024) $
; $LastChangedRevision: 32691 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goesr/goesr_load_data.pro $
;-

function goesr_find_in_list, alist, astr, notstr=notstr
  ; Find a substring in a list, exclude all notstr
  names = ['']
  if undefined(notstr) then begin
    positions = strpos(alist, astr)
    idx = where(positions ne -1, count)
    if count ge 1 then begin
      names = tnames(alist[idx])
    endif
  endif else begin
    positions = strpos(alist, astr)
    nopositions = strpos(alist, notstr)
    idx = where(positions ne -1 and nopositions eq -1, count)
    if count ge 1 then begin
      names = tnames(alist[idx])
    endif
  endelse

  return, names[0]
end

pro goesr_sgps_postprocessing, varnames, prefix = prefix, suffix = suffix
  ; Create separate tplot variables for each of the two sensors
  ; Total of 13 energy channels

  if undefined(prefix) then prefix=''
  if undefined(suffix) then suffix=''

  v = prefix + 'AvgDiffProtonFlux' + suffix
  vn = prefix + 'AvgDiffProtonFluxUncert' + suffix
  protons = goesr_find_in_list(varnames, v, notstr=vn)

  v = prefix + 'DiffProtonEffectiveEnergy' + suffix
  protons_energies =  goesr_find_in_list(varnames, v)

  if protons ne '' and protons ne -1 then begin
    get_data, protons, data=dp, dl=dlp
    get_data, protons_energies, data=dpen, dl=dlpen
    dlp.ylog = 1
    str_element, dlp, 'labels', ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'P9', 'P10', 'P11', 'P12', 'P13'], /add
    str_element, dlp, 'labflag', -1, /add
    for i=0,1 do begin
      new_name = protons + '_' + strcompress(string(i), /remove_all)
      store_data, new_name, data={x:dp.x, y:transpose([reform([dp.y[*,i,*]])])}, dl=dlp
      options, /def, new_name, 'sensor', strcompress(string(i), /remove_all)
      if size(dpen,/n_dimensions) gt 0 then begin
        options, /def, new_name, 'EffectiveEnergies', reform(dpen.y[*,i]) ; Effective sensor energies
      endif
    endfor
  endif

end

pro goesr_mpsh_postprocessing, varnames, prefix = prefix, suffix = suffix
  ; Create separate tplot variables for each telescope

  if undefined(prefix) then prefix=''
  if undefined(suffix) then suffix=''

  ; Proton telescopes: T1, T4, T2, T5, T3
  ; Total of 11 energy channels.
  v = prefix + 'AvgDiffProtonFlux' + suffix
  vn = prefix + 'AvgDiffProtonFluxUncert' + suffix
  protons = goesr_find_in_list(varnames, v, notstr=vn)

  v = prefix + 'DiffProtonEffectiveEnergy' + suffix
  protons_energies =  goesr_find_in_list(varnames, v)
  protons_energies = protons_energies[0]

  tprotons = ['T1', 'T4', 'T2', 'T5', 'T3']
  if protons ne '' and protons ne -1 then begin
    get_data, protons, data=dp, dl=dlp
    get_data, protons_energies, data=dpen, dl=dlpen
    dlp.ylog = 1
    str_element, dlp, 'labels', ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'P9', 'P10', 'P11'], /add
    str_element, dlp, 'labflag', -1, /add
    for i=0,4 do begin
      new_name = protons + '_' + strcompress(string(i), /remove_all)
      store_data, new_name, data={x:dp.x, y:transpose([reform([dp.y[*,i,*]])])}, dl=dlp
      options, /def, new_name, 'telescope', tprotons[i]
      if size(dpen,/n_dimensions) gt 0 then begin
        options, /def, new_name, 'EffectiveEnergies', reform(dpen.y[*,i]) ; Effective telescope energies
      endif
    endfor
  endif

  ; Electron telescopes: T3, T1, T4, T2, T5
  ; Total of 10 energy channels.
  v = prefix + 'AvgDiffElectronFlux' + suffix
  vn = prefix + 'AvgDiffElectronFluxUncert' + suffix
  electrons = goesr_find_in_list(varnames, v, notstr=vn)

  v = prefix + 'DiffElectronEffectiveEnergy' + suffix
  electrons_energies =  goesr_find_in_list(varnames, v)

  telectrons = ['T3', 'T1', 'T4', 'T2', 'T5']
  if electrons ne '' and electrons ne -1 then begin
    get_data, electrons, data=de, dl=dle
    get_data, electrons_energies, data=deen, dl=dleen
    dle.ylog = 1
    str_element, dle, 'labels', ['E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7', 'E8', 'E9', 'E10'], /add
    str_element, dle, 'labflag', -1, /add
    for i=0,4 do begin
      new_name = electrons + '_' + strcompress(string(i), /remove_all)
      store_data, new_name, data={x:de.x, y:transpose([reform([de.y[*,i,*]])])}, dl=dle
      options, /def, new_name, 'telescope', telectrons[i]
      if size(deen,/n_dimensions) gt 0 then begin
        options, /def, new_name, 'EffectiveEnergies', reform(deen.y[*,i]) ; Effective telescope energies
      endif
    endfor
  endif

end

pro goesr_mag_postprocessing, varnames
  ; Replace FillValues -9999.0f with NaNs.

  vvars = tnames('*_b_*')
  bvars = []
  for i=0,n_elements(vvars)-1 do begin
    positions = strpos(varnames, vvars[i])
    idx = where(positions ne -1, count)
    if count ge 1 then begin
      names = varnames[idx]
      bvars = [bvars, names]
    endif
  endfor

  for i=0, n_elements(bvars)-1 do begin
    vname = bvars[i]
    idx = where(vname eq varnames, count)
    if count gt 0 then begin
      get_data, vname, data=d, dl=dl
      if is_struct(d) && n_elements(d.x) gt 1 then begin
        idx = where(d.y le -9000.0, count1)
        if count1 gt 0 then begin
          d.y[idx] = float('NaN')
          store_data, vname, data=d, dl=dl
        endif
      endif
    endif
  endfor
end

pro goesr_xrs_postprocessing, varnames
  ; Replace FillValues -9999.0f with NaNs.

  vvars = tnames('*_flux_*')
  xrsvars = []
  for i=0,n_elements(vvars)-1 do begin
    positions = strpos(varnames, vvars[i])
    idx = where(positions ne -1, count)
    if count ge 1 then begin
      names = varnames[idx]
      xrsvars = [xrsvars, names]
    endif
  endfor
  
  for i=0, n_elements(xrsvars)-1 do begin
    vname = xrsvars[i]
    idx = where(vname eq varnames, count)
    if count gt 0 then begin
      get_data, vname, data=d, dl=dl
      if is_struct(d) && n_elements(d.x) gt 1 then begin
        idx = where(d.y le -9000.0, count1)
        if count1 gt 0 then begin
          d.y[idx] = float('NaN')
          store_data, vname, data=d, dl=dl
        endif
      endif
    endif
  endfor
end

pro goesr_load_data, trange = trange, datatype = datatype, probes = probes, prefix = prefix, suffix = suffix, hires=hires, level=level, $
  downloadonly = downloadonly, no_time_clip = no_time_clip, get_support_data = get_support_data, source=source

  compile_opt idl2

  goesr_init
  if undefined(suffix) then suffix = ''
  remote_path = !goesr.remote_data_dir ; this is only for goes 16-17

  ; handle possible server errors
  catch, errstats
  if errstats ne 0 then begin
    dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

  ; Map attributes to ISTP/CDF variables.
  gatt2istp = dictionary('PROJECT', ':project', $
    'SOURCE_NAME', ':source', $
    'DISCIPLINE', 'Space Physics>Magnetospheric Science',$
    'DATA_TYPE', ':title',$
    'DESCRIPTOR', ':processing_level',$
    'DATA_VERSION', '1',$
    'PI_NAME', ':creator_name',$
    'PI_AFFILIATION', ':creator_institution',$
    'TEXT', ':metadata_link',$
    'INSTRUMENT_TYPE', ':instrument',$
    'MISSION_GROUP', ':program',$
    'Logical_file_id', ':id', $
    'Logical_source', '', $
    'LOGICAL_SOURCE_DESCRIPTION', '',$
    'TIME_RESOLUTION', ':time_coverage_resolution',$
    'RULES_OF_USE', ':license',$
    'GENERATED_BY', ':creator_institution',$
    'Generation_date', ':date_created',$
    'ACKNOWLEDGEMENT', ':acknowledgment',$
    'HTTP_LINK', ':publisher_url', $
    'LINK_TITLE', ':institution')

  ; Coordinate list in variable names
  coord_list =  ['SENSOR', 'EPN', 'ECI', 'GSE', 'GSM', 'VDH', 'ACRF', 'BRF']

  ; set the default datatype to MAG data
  if not keyword_set(datatype) then datatype = 'mag'
  if not keyword_set(probes) then probes = ['16']
  if not keyword_set(source) then source = !goesr
  if not keyword_set(level) then level = 'l2'
  if not keyword_set(hires) then resolution='lowres' else resolution='hires'
  if (keyword_set(trange) && n_elements(trange) eq 2) then begin
    if time_double(trange[0]) gt time_double(trange[1]) then begin
      msg = 'Starting time cannot be larger than ending time.'
      dprint, dlevel=1, 'Error: ', msg
      return
    endif
    tr = timerange(trange)
  endif else begin
    tr = timerange()
  endelse

  for pidx=0, n_elements(probes)-1 do begin ; loop through the probes
    goesp = string(probes[pidx], format='(I02)')
    sc = 'goes' + goesp
    sc0 = 'g' + goesp
    prefix = sc + '_'

    case datatype of
      'mag': begin
        ; Magnetometer
        if goesp ge 16 then begin
          ; GOES 16, 17
          ; Lowres is 1 min. Hires is 0.1 second, large files (>180MB).
          res0='avg1m'
          if resolution eq 'hires' then begin
            res0='hires'
          endif
          lr = level + '-' + res0
          pathformat = sc + '/' + level + '/data/magn-' + lr + '/YYYY/MM/dn_magn-' + lr + '_' + sc0 +'_dYYYYMMDD_v?-?-?.nc'
        endif else begin
          ; GOES 8-15: only high resolution is available (Dec 2020)
          if resolution eq 'hires' then begin
            remote_path = 'https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/science/'
            res0 = 'hires'
            lr = level + '-' + res0
            pathformat = 'mag/' + sc + '/magn-'+ lr +'/YYYY/MM/dn_magn-' + lr + '_' + sc0 +'_dYYYYMMDD_v?_?_?.nc'
          endif else begin
            msg = 'For GOES 8-15 only high resolution MAG data exists. Use \hires keyword.'
            dprint, dlevel=1, 'Error: ', msg
            return
          endelse
        endelse
      end
      'xrs': begin
        ; High cadence measurements from the EXIS X-Ray Sensor (XRS)
        if goesp ge 16 then begin
          ; GOES 16, 17
          ; Hires is 1 second. Lowres is 1 min (default).
          res0='avg1m'
          if resolution eq 'hires' then begin
            res0='flx1s'
          endif
          lr = level + '-' + res0
          pathformat = sc + '/' + level + '/data/xrsf-' + lr + '_science/YYYY/MM/sci_xrsf-' + lr + '_' + sc0 +'_dYYYYMMDD_v?-?-?.nc
        endif else begin
          ; GOES 13, 14, 15
          ; Hires is 2-sec fluxes. Lowres is 1-min averages (default).
          if resolution eq 'hires' then begin
            res0='irrad'
            time_offset = time_double('1970-01-01/00:00:00.000')
          endif else res0='avg1m'
          lr = level + '-' + res0 + '_'
          remote_path = 'https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/science/'
          if resolution eq 'hires' then begin
            pathformat = 'xrs/' + sc + '/gxrs-'+ lr +'science/YYYY/MM/sci_gxrs-' + lr + sc0 +'_dYYYYMMDD_v?-?-?.nc
          endif else begin
            pathformat = 'xrs/' + sc + '/xrsf-'+ lr +'science/YYYY/MM/sci_xrsf-' + lr + sc0 +'_dYYYYMMDD_v?-?-?.nc
          endelse
        endelse
      end
      'mpsh': begin
        ; Magnetospheric Electrons and Protons, Medium and High Energy (MPSH)
        ; Hires is 1 min. Lowres is 5 min (default).
        ; Electrons: 5 telescopes, 10 channels
        ; Protons: 5 telescopes, 11 channels
        time_var = 'L2_SciData_TimeStamp'
        multidim = 'mpsh' ; contains many multi-dimensional variables that require special treatment
        res0='avg5m'
        if resolution eq 'hires' then begin
          res0='avg1m'
        endif
        lr = level + '-' + res0
        pathformat = sc + '/' + level + '/data/mpsh-' + lr + '/YYYY/MM/sci_mpsh-' + lr + '_' + sc0 +'_dYYYYMMDD_v?-?-?.nc'
      end
      'sgps': begin
        ; Solar and Galactic Proton Sensors (SGPS)
        ; Two sensors, one looking eastward and one looking westward
        ; Hires is 1 min. Low res is 5 min (default).
        if goesp ge 16 then begin
          ; GOES 16, 17
          time_var = 'L2_SciData_TimeStamp'
          res0='avg5m'
          scidn = 'sci'
          if (resolution eq 'hires') then begin
            res0='avg1m'
            scidn='dn'
          endif
          lr = level + '-' + res0
          pathformat = sc + '/' + level + '/data/sgps-' + lr + '/YYYY/MM/' + scidn +'_sgps-' + lr + '_' + sc0 +'_dYYYYMMDD_v?-?-?.nc'
        endif
      end

      else: begin
        msg = 'Datatype cannot be downloaded at this time: ' + datatype
        dprint, dlevel=1, 'Error: ', msg
        return
      end
    endcase

    for j = 0, n_elements(pathformat)-1 do begin
      ; Download file.
      relpathnames = file_dailynames(file_format=pathformat[j],trange=tr,addmaster=addmaster, /unique)
      files = spd_download(remote_file=relpathnames, remote_path=remote_path, local_path = !goesr.local_data_dir, /last_version)

      ; TODO: mpsh files with versions 1-0-0 contain H5T_CSET_UTF8 strings for the attributes and IDL cannot read these strings.

      if keyword_set(downloadonly) then continue
      ; Load file into tplot.
      hdf2tplot, files, tplotnames=tplotnames, prefix = prefix, suffix = suffix, gatt2istp=gatt2istp, vatt2istp=vatt2istp, coord_list=coord_list, time_offset=time_offset, time_var=time_var, multidim=multidim

      ; Post processing of tplot variables.
      case datatype of
        'mag':begin
          ; Magnetometer data contains a lot of -9999.0f FillValues instead of NaNs.
          goesr_mag_postprocessing, tplotnames
        end
        'xrs':begin
          ; Replace -9999.0f FillValues with NaNs.
          goesr_xrs_postprocessing, tplotnames 
        end
        'mpsh': begin
          ; Separate data from 5 telescopes.
          goesr_mpsh_postprocessing, tplotnames, prefix = prefix, suffix = suffix
        end
        'sgps':begin
          ; Separate data from 2 sensors.
          goesr_sgps_postprocessing, tplotnames, prefix = prefix, suffix = suffix
        end
      endcase
      ;
      ; Time clip
      if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
          if ~keyword_set(no_time_clip) then time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
      endif
    endfor

  endfor

end
