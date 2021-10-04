; this routine is obsolete and has been replaced by elf_load_proxy_ae
pro elf_load_pseudo_ae, no_download=no_download, trange=trange, smooth=smooth, nsmooth=nsmooth

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
  remote_ae_dir=!elf.REMOTE_DATA_DIR+'/pseudo_ae'
  local_ae_dir=!elf.LOCAL_DATA_DIR+'/pseudo_ae'
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
    paths = spd_download(remote_file=remote_filename, $   ;remote_path=remote_cal_dir, $
      local_file=local_filename, ssl_verify_peer=1, ssl_verify_host=1)
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
       pseudo_ae = read_csv(local_filename[i])
       t0=time_double(strmid(time_string(tr[0]+i*86400.),0,10))
       append_array, pseudo_ae_x, (pseudo_ae.field1 * 60.) + t0
       append_array, pseudo_ae_y, double([pseudo_ae.field4])
     endfor
     dl = {ytitle:'proxy_ae', labels:['proxy_AE'], colors:[2]}
     idx=where(pseudo_ae_y LT 2000., ncnt)
     if ncnt GT 2 then store_data, 'pseudo_ae', data={x:pseudo_ae_x[idx], y:pseudo_ae_y[idx]}, dlimits=dl $
        else store_data, 'pseudo_ae', data={x:pseudo_ae_x, y:pseudo_ae_y}, dlimits=dl
     time_clip, 'pseudo_ae', tr[0], tr[1], replace=1, error=error
     if keyword_set(smooth) then begin
        tsmooth2, 'pseudo_ae', nsmooth, newname='pseudo_ae_sm'
        ; check that there are no spikes resulting from smooth
        get_data, 'pseudo_ae_sm', data=d, dlimits=dl, limits=l
        idx = where(d.y LT 50000., ncnt)
        if ncnt GT 5 then store_data, 'pseudo_ae', data={x:d.x[idx], y:d.y[idx]}, dlimits=dl, limits=l
     endif
  endelse

end