;+
;NAME:
;  elf_load_proxy_ae
;          This routine loads proxy_ae data.
;          Proxy AE data is derived from plots at Kyoto
;
;KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         smooth:       set this flag is you want the data smoothed
;         nsmooth:      number points to smooth over. Default is 5
;         
;EXAMPLE:
;   elf_load_proxy_ae, trange=['2020-03-18','2020-03-19'], /smooth
;
;NOTES:
;
;--------------------------------------------------------------------------------------
pro elf_load_proxy_ae, trange=trange, smooth=smooth, nsmooth=nsmooth, no_download=no_download 

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif

  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()

  if not keyword_set(probe) then probe = 'a'
  if not keyword_set(smooth) then dosmooth=1 else dosmooth=0
  if not keyword_set(nsmooth) then nsmooth=5

  ; create calibration file name
  sc='el'+probe
  remote_ae_dir=!elf.REMOTE_DATA_DIR+'proxy_ae'
  local_ae_dir=!elf.LOCAL_DATA_DIR+'/proxy_ae'
  daily_name = file_dailynames(trange=tr, /unique, times=times)
  fname = daily_name + '_ProxyAE.csv'
  if strlowcase(!version.os_family) eq 'windows' then local_ae_dir = strjoin(strsplit(local_ae_dir, '/', /extract), path_sep())

  remote_filename=remote_ae_dir+'/' + daily_name + '_ProxyAE.csv'
  local_filename=local_ae_dir+'/'+ daily_name + '_ProxyAE.csv'
  paths = ''

  if keyword_set(no_download) then nodownload=1 else nodownload=0

  if nodownload eq 0 then begin
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
    if file_test(local_ae_dir,/dir) eq 0 then file_mkdir2, local_ae_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_ae_dir
    paths = spd_download(remote_file=remote_filename, local_file=local_filename, $
      ssl_verify_peer=0, ssl_verify_host=0)
    if undefined(paths) or paths[0] EQ '' then $
      dprint, devel=1, 'Unable to download ' + local_filename
  endif
  
  ; check that there is a local file
  if file_test(local_filename[0]) NE 1 then begin
    dprint, dlevel=1, 'Unable to find local file ' + local_filename
    return
  endif else begin
    for i=0,n_elements(local_filename)-1 do begin
      if file_test(local_filename[i]) EQ 0 then continue
      proxy_ae = read_csv(local_filename[i])
      t0=time_double(strmid(time_string(tr[0]+i*86400.),0,10))
      append_array, proxy_ae_x, (proxy_ae.field1 * 60.) + t0
      append_array, proxy_ae_y, double([proxy_ae.field5])
    endfor
    dl = {ytitle:'proxy_ae', labels:['proxy_AE'], colors:[2]}
    idx=where(proxy_ae_y LT 2000., ncnt)
    if ncnt GT 2 then store_data, 'proxy_ae', data={x:proxy_ae_x[idx], y:proxy_ae_y[idx]}, dlimits=dl $
    else store_data, 'proxy_ae', data={x:proxy_ae_x, y:proxy_ae_y}, dlimits=dl
    time_clip, 'proxy_ae', tr[0], tr[1], replace=1, error=error
    if keyword_set(smooth) then begin
      tsmooth2, 'proxy_ae', nsmooth, newname='proxy_ae_sm'
      ; check that there are no spikes resulting from smooth
      get_data, 'proxy_ae_sm', data=d, dlimits=dl, limits=l
      idx = where(d.y LT 50000., ncnt)
      if ncnt GT 5 then store_data, 'proxy_ae', data={x:d.x[idx], y:d.y[idx]}, dlimits=dl, limits=l
    endif
  endelse

end