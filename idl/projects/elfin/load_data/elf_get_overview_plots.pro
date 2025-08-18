;+
;NAME:
;  elf_get_overview_plots
;          This routine will download the overview plots for ELFIN. The downloaded files will
;          be copied to your local_data_dir.
;           
;KEYWORDS (commonly used by other load routines):
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probe:        'a' or 'b' (if no probe is specified the default is probe 'a')
;         local_data_dir: Use this keyword to specify the local data directory where you want 
;                         the plots downloaded.
;         
;NOTE: This routine handles only 1 date and 1 probe at a time. It's on the TO DO list.
;      If you want to reset the local_data_dir system variable for !elf simply call elf_init
;
;EXAMPLE:
;   idl> elf_get_overview_plots, trange=['2019-09-28','2019-09-29'], probe='a'
;   idl> elf_get_overview_plots, trange=['2019-09-28','2019-09-29'], probe='a', local_data_dir='C:\Users\clrussell\data\elfin\ela\overplots'
;   
;
;-
pro elf_get_overview_plots, trange=trange, probe=probe, local_data_dir=local_data_dir

  ; Initialize variables 
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
      dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
      return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
     then tr = timerange(trange) else tr = timerange()
  if not keyword_set(probe) then probe = 'a'

  hrs=['_00','_01','_02','_03','_04','_05','_06','_07','_08','_09','_10','_11','_12',$
       '_13','_14','_15','_16','_17','_18','_19','_20','_21','_22','_23','_24hr']
  zones = ['_nasc', '_ndes', '_sasc', '_sdes']
  
  ; create overview plot file name
  sc='el'+probe
  daily_names = file_dailynames(trange=tr, /unique, times=times)
  yyyy=strmid(daily_names,0,4)
  mm=strmid(daily_names,4,2)
  dd=strmid(daily_names,6,2)
  remote_png_dir=!elf.REMOTE_DATA_DIR+sc+'/overplots/'+yyyy+'/'+mm+'/'+dd+'/'
  if keyword_set(local_data_dir) then local_png_dir=local_data_dir+'/'+sc+'/overplots/'+yyyy+'/'+mm+'/'+dd+'/' $
    else local_png_dir=!elf.LOCAL_DATA_DIR+sc+'/overplots/'+yyyy+'/'+mm+'/'+dd+'/'

  if strlowcase(!version.os_family) eq 'windows' then local_png_dir = strjoin(strsplit(local_png_dir, '/', /extract), path_sep())

  ; Download files by the hour
  for j=0,n_elements(hrs)-1 do begin
    
    remote_filename=remote_png_dir+'/'+sc+'_l2_overview_'+daily_names+hrs[j]+'.png'
    local_filename=local_png_dir+'/'+sc+'_l2_overview_'+daily_names+hrs[j]+'.png'
    paths = ''
    
    ; NOTE: directory is temporarily password protected. 
;    if undefined(user) OR undefined(pw) then authorization = elf_get_authorization()
;    user=authorization.user_name
;    pw=authorization.password
    ; only query user if authorization file not found
;    If user EQ '' OR pw EQ '' then begin
;        print, 'Please enter your ELFIN user name and password'
;        read,user,prompt='User Name: '
;        read,pw,prompt='Password: '
;    endif  
  
    ; Test that directory exists and then download file
    if file_test(local_png_dir,/dir) eq 0 then file_mkdir2, local_png_dir
    paths = spd_download(remote_file=remote_filename, $   
       local_file=local_filename, ssl_verify_peer=0, ssl_verify_host=0)
;       url_username=user, url_password=pw, ssl_verify_peer=1, $
;       ssl_verify_host=1)
    if undefined(paths) or paths EQ '' then begin
       dprint, devel=1, 'Unable to download ' + local_filename
    endif    
    
    ; Each hour has the potential to 4 science zones
    if hrs[j] NE '_24hr' then begin
      for i=0,3 do begin
        ; create file names for science zones and download
        remote_filename=remote_png_dir+'/'+sc+'_l2_overview_'+daily_names+hrs[j]+zones[i]+'.png'
        local_filename=local_png_dir+'/'+sc+'_l2_overview_'+daily_names+hrs[j]+zones[i]+'.png'
        paths = ''
        paths = spd_download(remote_file=remote_filename, $   ;remote_path=remote_png_dir, $
          local_file=local_filename, ssl_verify_peer=0, ssl_verify_host=0)
      endfor    ; end of science zone loop
    endif 

  endfor    ; end of hourly loop
  
end