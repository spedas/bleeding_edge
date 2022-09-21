;+
; PROCEDURE:
;         elf_load_dst
;
; PURPOSE:
;         Load data from a csv file downloaded from a csv file stored on the
;         elfin server.
;         The original data was downloaded from the ftp site:
;
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         no_download:  set this flag to search for the file on your local disk
;
;-
pro elf_load_dst, no_download=no_download, trange=trange

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
  endif

  if ~undefined(trange) && n_elements(trange) eq 2 then tr = timerange(trange) else tr = timerange()

  ; create file name
  ts=time_string(tr[0])
  dst_filename='elfin_dst.csv'
  remote_dst_dir=!elf.REMOTE_DATA_DIR+'/dst'
  local_dst_dir=!elf.LOCAL_DATA_DIR+'/dst'
  if strlowcase(!version.os_family) eq 'windows' then local_dst_dir = strjoin(strsplit(local_dst_dir, '/', /extract), path_sep())

  remote_filename=remote_dst_dir+'/'+dst_filename
  local_filename=local_dst_dir+'/'+dst_filename
  paths = ''

  if keyword_set(no_download) then no_download=1 else no_download=0

  paths = ''
  if no_download eq 0 then begin
    ; NOTE: directory is temporarily password protected. this will be
    ;       removed when data is made public.
;    if undefined(user) OR undefined(pw) then authorization = elf_get_authorization()
;    user=authorization.user_name
;    pw=authorization.password
    ; only query user if authorization file not found
;    If user EQ '' OR pw EQ '' then begin
;      print, 'Please enter your ELFIN user name and password'
;      read,user,prompt='User Name: '
;      read,pw,prompt='Password: '
;    endif
    if file_test(local_dst_dir,/dir) eq 0 then file_mkdir2, local_dst_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_dst_dir
    paths = spd_download(remote_file=remote_filename, local_file=local_filename, $
      ssl_verify_peer=0, ssl_verify_host=0)
      ;url_username=user, url_password=pw, 
    if undefined(paths) or paths EQ '' then $
      dprint, devel=1, 'Unable to download ' + local_filename
  endif

  ; if file not found on server then
  if paths[0] EQ '' || no_download EQ 1 then begin
    ; check that there is a local file
    if file_test(local_filename) NE 1 then begin
      dprint, dlevel=1, 'Unable to find local file ' + local_filename
      return
    endif
  endif

  dst_fields = read_csv(local_filename)
  td=time_double(dst_fields.field1)
  idx=where(td GE tr[0]-3601. AND td LE tr[1]+3601., ncnt)
  if ncnt LT 1 then begin
     dprint, dlevel=1, 'No dst data was found for the time range: '+time_string(tr[0])+ ' to '+time_string(tr[1])
     options, 'dst', labels=['']
     return
  endif

  dst_times=time_double(dst_fields.field1[idx])
  dst_values=dst_fields.field3[idx]
  dt = 1800.
  dst={x:dst_times+1800., y:dst_values}
  store_data, 'dst', data=dst
  options, 'dst', colors=65
  options, 'dst', psym=10
  mindst=min(dst_values)
  maxdst=max(dst_values)
  difdst=abs(maxdst-mindst)*.1
  yrange=[mindst-difdst, maxdst+difdst]
  if (maxdst LT 0.) AND (mindst GT -50.) then dstrange=[-50,0] else dstrange=yrange
  options, 'dst', yrange=dstrange 
  options, 'dst', labels=['dst']

end
