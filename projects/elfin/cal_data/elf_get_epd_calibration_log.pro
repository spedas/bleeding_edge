;+
;PROCEDURE:
;   elf_get_epd_calibration_log
;
;PURPOSE:
;   This routine reads the epd calibration logs for ELFIN-A and ELFIN-B. The calibration logs
;   contain information from operations such as threshold and efficiency values. This routine 
;   returns a structure with the following values
;   epd_cal_logs = {cal_date:time_double(this_data[0]), $
;                   probe:probe, $
;                   epd_thresh_factors:float(this_data[24:25]), $
;                   epd_ch_efficiencies:float(this_data[108:123]), $
;                   epd_ebins:float(this_data[74:89])}
;
;KEYWORDS:
;   trange:    time range of interest [starttime, endtime] with the format
;              ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;              ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;   instrument: 'epde' or 'epdi'
;   probe:  name of probe 'a' or 'b'
;   nodownload: set this flag to force routine to use local files
;
;-
function elf_get_epd_calibration_log, trange=trange, probe=probe, instrument=instrument, no_download=no_download

  ; check that the elfin system variable exists. If not run the initialization routine
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return, -1
  endif

  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) else tr = timerange()

  if not keyword_set(probe) then probe = 'a'
  if not keyword_set(instrument) then instrument='epde'

  get_data, 'el'+probe+'_epd_cal_logs', data=epd_cal
  if is_struct(epd_cal) then begin
    epd_cal_logs=epd_cal.epd_cal_logs[0]
    stop
    return, epd_cal_logs 
  endif
   
  ; create calibration file name
  sc='el'+probe
  remote_cal_dir=!elf.REMOTE_DATA_DIR+sc+'/calibration_files'
  local_cal_dir=!elf.LOCAL_DATA_DIR+sc+'/calibration_files'
  if strlowcase(!version.os_family) eq 'windows' then local_cal_dir = strjoin(strsplit(local_cal_dir, '/', /extract), path_sep())

  remote_filename=remote_cal_dir+'/'+sc+'_epd_calibration.log'
  local_filename=local_cal_dir+'/'+sc+'_epd_calibration.log'
  paths = ''

  if keyword_set(no_download) then no_download=1 else no_download=0

  ; retrieve the calibration log file from the server
  if no_download eq 0 then begin
    if file_test(local_cal_dir,/dir) eq 0 then file_mkdir2, local_cal_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_cal_dir
    paths = spd_download(remote_file=remote_filename, ssl_verify_peer=0, $
      ssl_verify_host=0)
    if undefined(paths) or paths EQ '' then $
      dprint, devel=1, 'Unable to download ' + local_filename
  endif

  ; check that there is a local file
  if file_test(local_filename) NE 1 then begin
    dprint, dlevel=1, 'Unable to find local file ' + local_filename
    return, -1
  endif else begin

    ; open file and read first 7 lines (these are just headers)
    openr, lun, local_filename, /get_lun
    le_string=''
    count=0
    ; read header
    readf, lun, le_string
    dtypes=strsplit(le_string, ',', /extract)
    ; read the remainder of the file
    while (eof(lun) NE 1) do begin
      readf, lun, le_string
      if le_string eq '' then continue
      this_data=strsplit(le_string, ',', /extract)
      if time_double(tr[0]) LT time_double(this_data[0]) then begin
        this_data=prev_data
        break
      endif
      prev_data=this_data
    endwhile
    close, lun
    free_lun, lun
    
    ; create the calibration log structure
    if undefined(this_data) && undefined(prev_data) then begin
       dprint, 'No calibration data was found for: ' +trange[0] 
       return, -1
    endif else begin
      if instrument eq 'epde' then begin
        epd_cal_logs = {cal_date:time_double(this_data[0]), $
          probe:probe, $
          epd_thresh_factors:float(this_data[18:23]), $
          epd_ch_efficiencies:float(this_data[92:107]), $
          epd_ebins:float(this_data[58:73])}
      endif else begin   ; else instrument equals epdi
        epd_cal_logs = {cal_date:time_double(this_data[0]), $
          probe:probe, $
          epd_thresh_factors:float(this_data[24:25]), $
          epd_ch_efficiencies:float(this_data[108:123]), $
          epd_ebins:float(this_data[74:89])}
      endelse      
    endelse
 
  endelse

  if undefined(epd_cal_logs) then epd_cal_logs=-1

  store_data, 'el'+probe+'_epd_cal_logs', data=epd_cal_logs
  stop
  return, epd_cal_logs

end