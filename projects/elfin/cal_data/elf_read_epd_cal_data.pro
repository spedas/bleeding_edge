;+
;PROCEDURE:
;   elf_read_epd_cal_data
;
;PURPOSE:
;   This routine retrieves and reads the epd calibration data files for ELFIN-A and ELFIN-B. 
;   The calibration files contain information needed to calibrate epd data. This routine
;   returns a structure with the following values
;   epd_cal_logs = {date:date, $
;     probe:probe, $
;     gf:gf, $
;     overaccumulation_factors:overaccumulation_factors, $
;     thresh_factors:thresh_factors, $
;     ch_efficiencies:ch_efficiencies, $
;     ebins:ebins}
;   The structure returned is based on the time stamp passed as a parameter.
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
function elf_read_epd_cal_data, trange=trange, probe=probe, instrument=instrument, no_download=no_download

  ; check that elfin has been initialized and that the parameters have been set
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

  ; create calibration file name
  sc='el'+probe
  remote_cal_dir=!elf.REMOTE_DATA_DIR+sc+'/calibration_files'
  local_cal_dir=!elf.LOCAL_DATA_DIR+sc+'/calibration_files'
  if strlowcase(!version.os_family) eq 'windows' then local_cal_dir = strjoin(strsplit(local_cal_dir, '/', /extract), path_sep())

  remote_filename=remote_cal_dir+'/'+sc+'_'+instrument+'_cal_data.txt'
  local_filename=local_cal_dir+'/'+sc+'_'+instrument+'_cal_data.txt'
  paths = ''

  if keyword_set(no_download) then no_download=1 else no_download=0

  if no_download eq 0 then begin
    if file_test(local_cal_dir,/dir) eq 0 then file_mkdir2, local_cal_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_cal_dir
    paths = spd_download(remote_file=remote_filename, $   ;remote_path=remote_cal_dir, $
      local_file=local_filename, ssl_verify_peer=1, ssl_verify_host=1) 
    if undefined(paths) or paths EQ '' then $
      dprint, devel=1, 'Unable to download ' + local_filename
  endif
 
  ; check that there is a local file
  if file_test(local_filename) NE 1 then begin
    dprint, dlevel=1, 'Unable to find local file ' + local_filename
    return, -1
  endif else begin

    ; open file and read first line (header)
    openr, lun, local_filename, /get_lun
    le_string=''
    count=0
    ; read header
    readf, lun, le_string
    ;extract the Date
    ; ignore blanks (if there are any)
    readf, lun, le_string
    if le_string EQ '' then readf, lun, le_string
    sidx=strpos(le_string,':')
    dtype=strlowcase(strmid(le_string,0,sidx))
    if dtype EQ 'date' then begin
      date=time_double(strmid(le_string, sidx+1))
      readf, lun, le_string
      sidx=strpos(le_string,':')
      gf=float(strmid(le_string, sidx+1))
      readf, lun, le_string
      sidx=strpos(le_string,':')
      overaccumulation_factors=float(strsplit(strmid(le_string, sidx+1), ',', /extract))
      readf, lun, le_string
      sidx=strpos(le_string,':')
      thresh_factors=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
      readf, lun, le_string
      sidx=strpos(le_string,':')
      ch_efficiencies=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
      readf, lun, le_string
      sidx=strpos(le_string,':')
      ebins=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
    endif
    
    prev_date=date
    prev_gf=gf
    prev_overaccumulation_factors=overaccumulation_factors
    prev_thresh_factors=thresh_factors
    prev_ch_efficiencies=ch_efficiencies
    prev_ebins=ebins

    ; now loop for the remainder of the data
    while (eof(lun) NE 1) do begin
      ; read
      readf, lun, le_string
      ;extract the type of data
      sidx=strpos(le_string,':')
      dtype=strlowcase(strmid(le_string,0,sidx))
      if dtype EQ 'date' then begin
        date=time_double(strmid(le_string, sidx+1))
        readf, lun, le_string
        sidx=strpos(le_string,':')
        gf=float(strmid(le_string, sidx+1))
        readf, lun, le_string
        sidx=strpos(le_string,':')
        overaccumulation_factors=float(strsplit(strmid(le_string, sidx+1), ',', /extract))
        readf, lun, le_string
        sidx=strpos(le_string,':')
        thresh_factors=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
        readf, lun, le_string
        sidx=strpos(le_string,':')
        ch_efficiencies=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
        readf, lun, le_string
        sidx=strpos(le_string,':')
        ebins=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
      endif

      ; check to see if if input time is greater than file date
      if time_double(tr[0]) LT time_double(date) then begin
        date=prev_date
        gf=prev_gf
        overaccumulation_factors=prev_overaccumulation_factors
        thresh_factors=prev_thresh_factors
        ch_efficiencies=prev_ch_efficiencies
        ebins=prev_ebins
        break
      endif
      prev_date=date
      prev_gf=gf
      prev_overaccumulation_factors=overaccumulation_factors
      prev_thresh_factors=thresh_factors
      prev_ch_efficiencies=ch_efficiencies
      prev_ebins=ebins
    endwhile
    close, lun
    free_lun, lun
    
    if undefined(date) && undefined(prev_date) then begin
      dprint, 'No calibration data was found for: ' +trange[0]
      return, -1
    endif else begin
      if instrument eq 'epde' then begin
        epd_cal_logs = {date:date, $
          probe:probe, $
          gf:gf, $
          overaccumulation_factors:overaccumulation_factors, $
          thresh_factors:thresh_factors, $
          ch_efficiencies:ch_efficiencies, $
          ebins:ebins}
      endif else begin   ; else instrument equals epdi
        epd_cal_logs = {date:date, $
          probe:probe, $
          gf:gf, $
          overaccumulation_factors:overaccumulation_factors, $
          thresh_factors:thresh_factors, $
          ch_efficiencies:ch_efficiencies, $
          ebins:ebins}
      endelse
    endelse

  endelse

  if undefined(epd_cal_logs) then epd_cal_logs=-1

  return, epd_cal_logs

end