;+
;NAME:
;   icon_load_data
;
;PURPOSE:
;   Loads ICON data
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2020-02-21 13:53:53 -0800 (Fri, 21 Feb 2020) $
;$LastChangedRevision: 28326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/load/icon_load_data.pro $
;
;-------------------------------------------------------------------

function icon_mighti_filenames, relpathnames,remote_path, trange, fversion=fversion, frevision=frevision
  ; Find the MIGHTI file names scanning the directory
  ;http://themis.ssl.berkeley.edu/data/icon/Repository/Archive/Simulated-Data/LEVEL.1/MIGHTI-A/2010/143/ICON_L1_MIGHTI-A_Science_2010-05-23_000027_v01r000.NC
  
  ; TODO:Data can be downloaded only locally for now
  localdirsim = '/disks/data/icon/Repository/Archive/Simulated-Data/'
  result = FILE_TEST(localdirsim, /directory, /read) 
  if not result then begin
    print, "For now, ICON data can only be downloaded inside SSL."
    return, 0 
  endif
  
  
  files = []

  t = time_string(trange)
  td = time_double(t)
  remote_path=!icon.remote_data_dir

  all_url = []
  for i=0, n_elements(relpathnames)-1 do begin
    url = remote_path + relpathnames[i]
    spd_download_expand, url
    all_url = [all_url, url]
  endfor
  url = all_url[sort(all_url)]

  ; Find max for version and revision
  v_all = 0
  for j=0, n_elements(url)-1 do begin
    ss = strsplit(strsplit(strsplit(url[j],'.+[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}_v',/extract,/regex), '.NC', /extract), 'r', /extract)
    v_all = [v_all, ss[0]]
  endfor
  v_max = max(v_all)
  if keyword_set(fversion) then v_max = fversion
  v_str = strmid('00' + strtrim(string(v_max), 2), 1, 2,/reverse_offset)

  r_all = 0
  for j=0, n_elements(url)-1 do begin
    ss = strsplit(strsplit(url[j],'.+[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}_v' + v_str + 'r',/extract,/regex), '.NC', /extract)
    r_all = [r_all, ss[0]]
  endfor
  r_max = max(r_all)
  if keyword_set(frevision) then r_max = frevision
  r_str = strmid('000' + strtrim(string(r_max), 2), 2, 3,/reverse_offset)

  for j=0, n_elements(url)-1 do begin
    file0 = STRSPLIT(url[j], !icon.remote_data_dir,/EXTRACT,/regex)
    pre0 = STRSPLIT(file0[0],'ICON_L1_MIGHTI-A_Science_',/EXTRACT,/regex)
    s0= STRSPLIT(file0[0],'.*ICON_L1_MIGHTI-A_Science_',/EXTRACT,/REGEX)
    t0 =  STRSPLIT(s0[0],'_v.*NC',/EXTRACT,/REGEX)
    ts0 = strmid(t0[0], 0, 10) + '/' + strmid(t0[0], 11, 2) + ':' + strmid(t0[0], 13, 2) + ':' + strmid(t0[0], 15, 2)
    td0 = time_double(ts0)
    if (td0 ge td[0]) and (td0 le td[1]) then begin
      files=[files, pre0[0] + 'ICON_L1_MIGHTI-A_Science_' + t0 + '_v' + v_str + 'r' + r_str +'.NC']
    endif
  endfor

  n_download = n_elements(files)
  dprint, 'Number of files to download: ', n_download
  if n_download gt 100 then dprint, "Warning! More than 100 files will be downloaded. Consider decreasing the time range."
  dprint, files

  return, files
end

function icon_download_expand, url
  ; This function is similar to spd_download_expand, but also works for local files on windows
  ; relpathnames = 'LEVEL.1/EUV/2020/011/Data/ICON_L1_EUV_Flux_2020-01-11_*_v??r???.NC'
  ; remote_path='Z:\\icon\\Repository\\Archive\\Simulated-Data\\'
  result = FILE_SEARCH(url)
  return, result

end

function icon_euv_filenames, relpathnames,remote_path, trange, fversion=fversion, frevision=frevision
  ; Find the EUV file names scanning the directory
  ;http://themis.ssl.berkeley.edu/data/icon/Repository/Archive/LEVEL.1/EUV/2010/143/Data/ICON_L1_EUV_Flux_2010-05-23_235959_v01r000.NC
  files = []

  t = time_string(trange)
  td = time_double(t)

  all_url = []
  for i=0, n_elements(relpathnames)-1 do begin
    url = remote_path + relpathnames[i]
    spd_download_expand, url
    ;url = icon_download_expand(url)
    all_url = [all_url, url]
  endfor
  url = all_url[sort(all_url)]

  ; Find max for version and revision
  v_all = 0
  for j=0, n_elements(url)-1 do begin
    ss = strsplit(strsplit(strsplit(url[j],'.+[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}_v',/extract,/regex), '.NC', /extract), 'r', /extract)
    v_all = [v_all, ss[0]]
  endfor
  v_max = max(v_all)
  if keyword_set(fversion) then v_max = fversion
  v_str = strmid('00' + strtrim(string(v_max), 2), 1, 2,/reverse_offset)

  r_all = 0
  for j=0, n_elements(url)-1 do begin
    ss = strsplit(strsplit(url[j],'.+[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}_v' + v_str + 'r',/extract,/regex), '.NC', /extract)
    r_all = [r_all, ss[0]]
  endfor
  r_max = max(r_all)
  if keyword_set(frevision) then r_max = frevision
  r_str = strmid('000' + strtrim(string(r_max), 2), 2, 3,/reverse_offset)

  for j=0, n_elements(url)-1 do begin
    file0 = STRSPLIT(url[j], remote_path,/EXTRACT,/regex)
    pre0 = STRSPLIT(file0[0],'ICON_L1_EUV_Flux_',/EXTRACT,/regex)
    s0= STRSPLIT(file0[0],'.*ICON_L1_EUV_Flux_',/EXTRACT,/REGEX)
    t0 =  STRSPLIT(s0[0],'_v.*NC',/EXTRACT,/REGEX)
    ts0 = strmid(t0[0], 0, 10) + '/' + strmid(t0[0], 11, 2) + ':' + strmid(t0[0], 13, 2) + ':' + strmid(t0[0], 15, 2)
    td0 = time_double(ts0)
    if (td0 ge td[0]) and (td0 le td[1]) then begin
      files=[files, pre0[0] + 'ICON_L1_EUV_Flux_' + t0 + '_v' + v_str + 'r' + r_str +'.NC']
    endif
  endfor

  n_download = n_elements(files)
  dprint, 'Number of files to download: ', n_download
  if n_download gt 100 then dprint, "Warning! More than 100 files will be downloaded. Consider decreasing the time range."
  dprint, files

  return, files
end

pro icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type, suffix = suffix, $
  downloadonly = downloadonly, no_time_clip = no_time_clip, level = level, fversion=fversion, frevision=frevision, $
  tplotnames = tplotnames, varformat = varformat, get_support_data = get_support_data, noephem = noephem

  compile_opt idl2

  icon_init

  ; handle possible loading errors
  catch, errstats
  if errstats ne 0 then begin
    dprint, dlevel=1, 'Error in icon_load_data: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

  if undefined(suffix) then suffix = ''
  if keyword_set(fversion) then begin
    v_str = strmid('00' + strtrim(string(fversion), 2), 1, 2,/reverse_offset)
  endif else v_str ='??'
  if keyword_set(frevision) then begin
    r_str = strmid('000' + strtrim(string(frevision), 2), 2, 3,/reverse_offset)
  endif else r_str ='???'

  ; set the default datatype to FUV data
  if not keyword_set(instrument) then instrument = ['fuv']
  if not keyword_set(datal1type) then datal1type = ''
  if not keyword_set(datal2type) then datal2type = ''
  if not keyword_set(source) then source = !icon
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()

  tn_list_before = tnames('*')
  pathformat = []


  if strlowcase(instrument) eq 'fuv' then begin
    if datal1type[0] eq '*' then datal1type=['lwp', 'sli', 'ssi', 'swp']
    if datal2type[0] eq '*' then datal2type=['Oxygen-Profile-Night', 'Daytime-ON2']
    if datal2type[0] eq 'O-daytime' then datal2type=['Daytime-ON2']
    if datal2type[0] eq 'O-nighttime' then datal2type=['Oxygen-Profile-Night']

    if datal1type[0] ne '' then begin
      level = '1'
      remote_path1 = 'LEVEL.' + level + '/' + strupcase(instrument) + '/YYYY/DOY/ICON_L' + level + '_' + strupcase(instrument) + '_' + strupcase(datal1type) + '_YYYY-MM-DD_v' + v_str + 'r' + r_str + '.NC'
      pathformat = [pathformat, remote_path1]
    endif
    if datal2type[0] ne '' then begin
      ;LEVEL.2/FUV/2010/146/ICON_L2_FUV_Oxygen-Profile-Night_2010-05-26_v01r000.NC
      level = '2'
      remote_path2 = 'LEVEL.' + level + '/' + strupcase(instrument) + '/YYYY/DOY/ICON_L' + level + '_' + strupcase(instrument) + '_' + datal2type + '_YYYY-MM-DD_v' + v_str + 'r' + r_str + '.NC'
      pathformat = [pathformat, remote_path2]
    endif

  endif else if strlowcase(instrument) eq 'ivm' then begin
    ; /LEVEL.1/IVM-A/2010/141/Data/ICON_L1_IVM-A_2010-05-21_v01r000.NC
    level = '1'
    instrument = 'IVM-A'
    if datal1type[0] ne '' then begin
      level = '1'
    endif
    if datal2type[0] ne '' then begin
      level = '2'
    endif
    remote_path = 'LEVEL.' + level + '/' + strupcase(instrument)  + '/YYYY/DOY/Data/ICON_L' + level + '_' + strupcase(instrument) + '_YYYY-MM-DD_v' + v_str + 'r' + r_str + '.NC'
    pathformat = [pathformat, remote_path]

  endif else if strlowcase(instrument) eq 'euv' then begin
    ;data/icon/Repository/Archive/Simulated-Data/LEVEL.1/EUV/2010/141/Data/ICON_L1_EUV_Flux_2010-05-21_000011_v01r000.NC
    level = '1'
    instrument = 'euv'
    minutes = '*'
    if datal1type[0] ne '' then begin
      level = '1'
      remote_path = 'LEVEL.' + level + '/' + strupcase(instrument)  + '/YYYY/DOY/Data/ICON_L' + level + '_' + strupcase(instrument) + '_Flux_YYYY-MM-DD_' + minutes +'_v' + v_str + 'r' + r_str + '.NC'
    endif
    if datal2type[0] ne '' then begin
      level = '2'
      remote_path = 'LEVEL.' + level + '/' + strupcase(instrument)  + '/YYYY/DOY/Data/ICON_L' + level + '_' + strupcase(instrument) + '_Daytime_YYYY-MM-DD_v' + v_str + 'r' + r_str + '.NC'
    endif
    pathformat = [pathformat, remote_path]
  endif else if strlowcase(instrument) eq 'mighti-a' or strlowcase(instrument) eq 'mighti-b' or strlowcase(instrument) eq 'mighti' then begin
    ;http://themis.ssl.berkeley.edu/data/icon/Repository/Archive/Simulated-Data/LEVEL.1/MIGHTI-A/2010/140/ICON_L1_MIGHTI-A_Science_2010-05-20_000027_v01r000.NC
    level = '1'
    instrument = strlowcase(instrument)
    minutes = '*'
    if datal1type[0] ne '' then begin
      level = '1'
      remote_path = 'LEVEL.' + level + '/' + strupcase(instrument)  + '-A/YYYY/DOY/Data/ICON_L' + level + '_' + strupcase(instrument) + '-A_Science_YYYY-MM-DD_' + minutes +'_v' + v_str + 'r' + r_str + '.NC'
     endif
    if datal2type[0] ne '' then begin
      ;LEVEL.2/MIGHTI/2010/141/Vector-Winds/ICON_L2_MIGHTI_Vector-Wind-Green_2010-05-21_v01r000.NC
      ;LEVEL.2/MIGHTI/2010/141/Temperature/ICON_L2_MIGHTI-A_Temperature-A-Band_2010-05-21_v01r000.NC
      level = '2'
      remote_path0 = 'LEVEL.' + level + '/' + strupcase(instrument)  + '/YYYY/DOY/Vector-Winds/ICON_L' + level + '_' + strupcase(instrument) + '_Vector-Wind-' + ['Green','Red'] + '_YYYY-MM-DD_v' + v_str + 'r' + r_str + '.NC'
      remote_path1 = 'LEVEL.' + level + '/' + strupcase(instrument)  + '/YYYY/DOY/Temperature/ICON_L' + level + '_' + strupcase(instrument) + '-A_Temperature-A-Band_YYYY-MM-DD_v' + v_str + 'r' + r_str + '.NC'
      remote_path = [remote_path0, remote_path1]
      ; Oct 2019, change in name: ICON_L2_MIGHTI-A_Temperature_2010-05-27_v01r000.NC
      remote_path1 = 'LEVEL.' + level + '/' + strupcase('mighti')  + '/YYYY/DOY/ICON_L' + level + '_' + strupcase(instrument) + '_Temperature_YYYY-MM-DD_v' + v_str + 'r' + r_str + '.NC'    
      remote_path = [remote_path1]
    endif
   pathformat = [pathformat, remote_path]  
    
  endif

  dprint,dlevel=2,verbose=source.verbose,'Loading ICON-', strupcase('level ' + string(level)), ' ', strupcase(instrument), ' ', strupcase(datal1type), ' data'

  if not keyword_set(pathformat) then begin
    dprint,'No data found. Try a different probe.'
    return
  endif

  for j = 0, n_elements(pathformat)-1 do begin
    relpathnames = file_dailynames(file_format=pathformat[j],trange=tr,addmaster=addmaster, /unique)

    if instrument eq 'euv' and level eq '1' then begin
      ; For EUV level 1, we have to search and find the actual filenames
      relpathnames = icon_euv_filenames(relpathnames, !icon.remote_data_dir, trange, fversion=fversion, frevision=frevision)
    endif else if instrument eq 'mighti' and level eq '1' then begin 
      ; For MIGHTI level 1, we have to search and find the actual filenames
      relpathnames = icon_mighti_filenames(relpathnames, !icon.remote_data_dir, trange, fversion=fversion, frevision=frevision)
    endif 

    remote_dir = !icon.remote_data_dir
    if !version.release ge 8.4 then BEGIN
      remote_dir = remote_dir.replace('\\', '\')
    endif
    
    files = spd_download(remote_file=relpathnames, remote_path=remote_dir, local_path = !icon.local_data_dir, last_version=1)
      

    if keyword_set(downloadonly) then continue

    icon_netcdf2tplot, files

  endfor

  ; make sure some tplot variables were loaded
  tn_list_after = tnames('*')
  new_tnames = ssl_set_complement([tn_list_before], [tn_list_after])

  tplotnames = tnames('*')
  if ~undefined(tr) && ~undefined(tplotnames) then begin
    if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
      time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
    endif
  endif

  ;For testing: 
  ;print, 'TPLOT variables: ', tnames()
end