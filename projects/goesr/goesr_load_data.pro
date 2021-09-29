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
;                     'mag': Magnetometer (default: 'avg1m', available: 'hires')
;                     'xrs': EXIS X-Ray Sensor (default: 'avg1m', available: 'hires' one-second);
;     prefix:        String to append to the beginning of the loaded tplot variables
;     suffix:        String to append to the end of the loaded tplot variables
;     prefix:        String to append to the beginning of the loaded tplot variables
;     probes:        Array of GOES spacecrafts (8-17). Default is probes=['16'].
;     varnames:      Array of names of variables to load. Defaults is all (*)
;     downloadonly: Download files but don't load them into tplot.
;     hires:        If set, download full data files (larger files, can be over 180MB).
;                   If not set, use averaged data files.
;     no_time_clip: Don't clip the tplot variables.
;     get_support_data: Keep the support data.
;
; Notes:
;     NOAA Site:  https://www.ngdc.noaa.gov/stp/satellite/goes-r.html
;
;   As of Dec 2020, the following data files can be downloaded:
;   - GOES 8-15 mag files, high resolution
;   - GOES 13, 14, 15 xrs files, high resolution (2 sec), 1 min averages
;   - GOES 16, 17 mag files, xrs files
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2021-09-10 11:53:02 -0700 (Fri, 10 Sep 2021) $
; $LastChangedRevision: 30287 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goesr/goesr_load_data.pro $
;-

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
  if not keyword_set(hires) then resolution='avg1m' else resolution='hires'
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
      ; Magnetometer
      'mag': begin
        if goesp gt 15 then begin
          ; GOES 16, 17
          ; Default is 1 min. Hires is large files (>180MB).
          lr = level + '-' + resolution
          pathformat = sc + '/' + level + '/data/magn-' + lr + '/YYYY/MM/dn_magn-' + lr + '_' + sc0 +'_dYYYYMMDD_v?-?-?.nc'
        endif else begin
          ; GOES 8-15: only high resolution is available (Dec 2020)
          if resolution eq 'hires' then begin
            remote_path = 'https://satdat.ngdc.noaa.gov/sem/goes/data/science/'
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
      ; High cadence measurements from the EXIS X-Ray Sensor (XRS)
      'xrs': begin
        if goesp gt 15 then begin
          ; GOES 16, 17
          ; Hires is 1 second. Default is 1 min.
          if resolution eq 'hires' then begin
            res0='flx1s'
          endif else res0='avg1m'
          lr = level + '-' + res0
          pathformat = sc + '/' + level + '/data/xrsf-' + lr + '_science/YYYY/MM/sci_xrsf-' + lr + '_' + sc0 +'_dYYYYMMDD_v?-?-?.nc
        endif else begin
          ; GOES 13, 14, 15
          ; hires is 2-sec fluxes, the only other option is 1-min averages
          if resolution eq 'hires' then begin
            res0='irrad'
            time_offset = time_double('1970-01-01/00:00:00.000')
          endif else res0='avg1m'
          lr = level + '-' + res0 + '_'
          remote_path = 'https://satdat.ngdc.noaa.gov/sem/goes/data/science/'
          if resolution eq 'hires' then begin
            pathformat = 'xrs/' + sc + '/gxrs-'+ lr +'science/YYYY/MM/sci_gxrs-' + lr + sc0 +'_dYYYYMMDD_v?-?-?.nc
          endif else begin
            pathformat = 'xrs/' + sc + '/xrsf-'+ lr +'science/YYYY/MM/sci_xrsf-' + lr + sc0 +'_dYYYYMMDD_v?-?-?.nc
          endelse
        endelse
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
      files = spd_download(remote_file=relpathnames, remote_path=remote_path, local_path = !goesr.local_data_dir)
      if keyword_set(downloadonly) then continue
      ; Load file into tplot.
      hdf2tplot, files, tplotnames=tplotnames, prefix = prefix, suffix = suffix, gatt2istp=gatt2istp, vatt2istp=vatt2istp, coord_list=coord_list, time_offset=time_offset
      if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
          if ~keyword_set(no_time_clip) then time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
      endif
    endfor

  endfor

end
