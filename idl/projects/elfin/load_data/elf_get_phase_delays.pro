;+
; PROCEDURE:
;         elf_get_phase_delay
;
; PURPOSE:
;         This routine will download and retrieve the phase delay values for a given
;         time range. All values in the file are returned in a structure of arrays.
;         phase_delay = { $
;            starttimes:starttimes, $
;              endtimes:endtimes, $
;              sect2add:dsect2add, $
;              phang2add:dphang2add, $
;              lastestmediansectr:latestmediansectr, $
;              latestmedianphang:latestmedianphang, $
;              badflag:badflag }
;
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probe:        'a' or 'b'
;         no_download:  set this flag to search for the file on your local disk
;         hourly:       set this flag to find the nearest science zone within an hour of the
;                       trange
;
;-
function elf_get_phase_delays, no_download=no_download, trange=trange, probe=probe, instrument=instrument

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

;  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
;    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
;    return, -1
;  endif

;  if ~undefined(trange) && n_elements(trange) eq 2 $
;    then tr = timerange(trange) $
;  else tr = timerange()

  if not keyword_set(probe) then probe = 'a'

  if ~undefined(instrument) then instrument='epde'
  instrument='epde'
 
  ; check for existing phase_delays tplot var
;  get_data, 'el'+probe+'_epd_phase_delays', data=pd_struct
;  if is_struct(pd_struct) then begin
;    phase_delays=pd_struct.phase_delays[0]
;    return, phase_delays
;  endif
  
  ; create calibration file name
  sc='el'+probe
  remote_cal_dir=!elf.REMOTE_DATA_DIR+sc+'/calibration_files'
  local_cal_dir=!elf.LOCAL_DATA_DIR+sc+'/calibration_files'
  if strlowcase(!version.os_family) eq 'windows' then local_cal_dir = strjoin(strsplit(local_cal_dir, '/', /extract), path_sep())

  remote_filename=remote_cal_dir+'/'+sc+'_'+instrument+'_phase_delays.csv'
  local_filename=local_cal_dir+'/'+sc+'_'+instrument+'_phase_delays.csv'
  paths = ''

  if keyword_set(no_download) then no_download=1 else no_download=0

  if no_download eq 0 then begin
;    ; NOTE: directory is temporarily password protected. this will be
;    ;       removed when data is made public.
;    if undefined(user) OR undefined(pw) then authorization = elf_get_authorization()
;    user=authorization.user_name
;    pw=authorization.password
;    ; only query user if authorization file not found
;    If user EQ '' OR pw EQ '' then begin
;      print, 'Please enter your ELFIN user name and password'
;      read,user,prompt='User Name: '
;      read,pw,prompt='Password: '
;    endif
    if file_test(local_cal_dir,/dir) eq 0 then file_mkdir2, local_cal_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_cal_dir
    paths = spd_download(remote_file=remote_filename, $   ;remote_path=remote_cal_dir, $
      local_file=local_filename, $   ;local_path=local_cal_dir, $
      ssl_verify_peer=0, ssl_verify_host=0)
    if undefined(paths) or paths EQ '' then $
      dprint, devel=1, 'Unable to download ' + local_filename
  endif

  ; check that there is a local file
  if file_test(local_filename) NE 1 then begin
    dprint, dlevel=1, 'Unable to find local file ' + local_filename
    return, -1
  endif else begin  
    pd_data=read_csv(local_filename)
    if is_struct(pd_data) then begin
      phase_delay = { $
        starttimes:time_double(pd_data.field1), $
        endtimes:time_double(pd_data.field2), $
        sect2add:pd_data.field3, $
        phang2add:pd_data.field4, $
        lastestmediansectr:pd_data.field5, $
        latestmedianphang:pd_data.field6, $
        badflag:pd_data.field7 }      
      store_data, 'el'+probe+'_epd_phase_delays', data={phase_delays:phase_delay}
    endif else begin
      dprint, dlevel=1, 'Unable to open and read local file ' + local_filename
      return, -1      
    endelse
  endelse  
  
  return, phase_delay
  
end