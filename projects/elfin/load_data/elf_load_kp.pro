;+
; PROCEDURE:
;         elf_load_kp
;
; PURPOSE:
;         Load data from a csv file downloaded from a csv file stored on the
;         elfin server and return all values in the time range
;         The original data was downloaded from the ftp site:
;            ftp://ftp.gfz-potsdam.de/pub/home/obs/kp-nowcast-archive/wdc/
;
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         no_download:  set this flag to search for the file on your local disk
;         extend_time:  set this flag to return the two adjacent values - this is useful for very
;                       small time frames
;
; NOTES:
;         The kp values downloaded from potsdam are at 3 hour intervals. 01:30, 04:30, 07:30, ... 22:30.
;         If you time range is less than 3 hours it's possible no values will be found. Use the extend_time
;         keyword to return the prevoius and next values.
;
;-
pro elf_load_kp, trange=trange, extend_time=extend_time, no_download=no_download

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
  endif

  if ~undefined(trange) && n_elements(trange) eq 2 then tr = timerange(trange) else tr = timerange()

  ; create file name
    ts=time_string(tr[0])
    kp_filename='elfin_kp.csv'
    remote_kp_dir=!elf.REMOTE_DATA_DIR+'/kp'
    local_kp_dir=!elf.LOCAL_DATA_DIR+'/kp'
    if strlowcase(!version.os_family) eq 'windows' then local_kp_dir = strjoin(strsplit(local_kp_dir, '/', /extract), path_sep())

    remote_filename=remote_kp_dir+'/'+kp_filename
    local_filename=local_kp_dir+'/'+kp_filename
    paths = ''

    if keyword_set(no_download) then no_download=1 else no_download=0

    paths = ''
    if no_download eq 0 then begin
  ; NOTE: directory is temporarily password protected. this will be
  ;       removed when data is made public.
  ;    if undefined(user) OR undefined(pw) then authorization = elf_get_authorization()
  ;    user=authorization.user_name
  ;    pw=authorization.password
  ;    ; only query user if authorization file not found
  ;    If user EQ '' OR pw EQ '' then begin
  ;      print, 'Please enter your ELFIN user name and password'
  ;      read,user,prompt='User Name: '
  ;      read,pw,prompt='Password: '
  ;    endif
    if file_test(local_kp_dir,/dir) eq 0 then file_mkdir2, local_kp_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_kp_dir
    paths = spd_download(remote_file=remote_filename, local_file=local_filename, $
      ssl_verify_peer=0, ssl_verify_host=0)
    if undefined(paths) or paths EQ '' then $
      dprint, devel=1, 'Unable to download ' + local_filename
    endif

;   if file not found on server then begin
    if paths[0] EQ '' || no_download EQ 1 then begin
      ; check that there is a local file
      if file_test(local_filename) NE 1 then begin
        dprint, dlevel=1, 'Unable to find local file ' + local_filename
        return
      endif
    endif
  
  ;noaa_load_kp, trange=tr, /gfz, local_kp_dir=!elf.local_data_dir+'\kp'
  ; read the kp csv file
    kp_struct = read_csv(local_filename)
  ;check that data exists
    if size(kp_struct, /type) EQ 8 then begin
      ; find all values that lie within the time frame
      idx=where(time_double(kp_struct.field1) GE tr[0] AND time_double(kp_struct.field1) LE tr[1], ncnt)
      if ncnt GT 0 then begin
        ; temporarily store data
        kp_time=time_double(kp_struct.field1[idx])
        kp_value=round(kp_struct.field3[idx])
      endif else begin
        ; no data was found in this time frame
        ; if extend time flag set then check for adjacent points
        if keyword_set(extend_time) then begin
          ; check for adjacent points
          sidx=where(time_double(kp_struct.field1) LE tr[0], scnt)
          eidx=where(time_double(kp_struct.field1) GE tr[1], ecnt)
          if scnt GT 0 then begin
            append_array, kp_time, time_double(kp_struct.field1[sidx[scnt-1]])
            append_array, kp_value, round(kp_struct.field3[sidx[scnt-1]])
          endif
          if ecnt GT 0 then begin
            append_array, kp_time, time_double(kp_struct.field1[eidx[0]])
            append_array, kp_value, round(kp_struct.field3[eidx[0]])
          endif
        endif
      endelse
    endif

  ;  if ~undefined(kp_time) && ~undefined(kp_value) then begin
;  get_data, 'Kp', data=d
  if ~undefined(kp_time) then begin
;    kp_time=d.x
;    kp_value=d.y
    dt=5400.    ; kp values are every 3 hours dt/2 is 1.5 hrs
    kp={x:kp_time-dt, y:kp_value}
    store_data, 'elf_kp', data=kp
    options, 'elf_kp', colors=65
    options, 'elf_kp', psym=10
    options, 'elf_kp', labels=['kp']
    max_kp=max(kp_value)
    if max_kp GT 4.3 then begin
      max_kp_range=max_kp + (max_kp*.1)
      options, 'elf_kp', yrange=[-0.5,max_kp_range]
    endif else begin
      options, 'elf_kp', yrange=[-0.5,4.5]
    endelse
    options, 'elf_kp', ystyle=1
  endif else begin
    dprint, dlevel=1, 'No KP data was loaded!'
    options, 'kp', labels=['']
  endelse

end