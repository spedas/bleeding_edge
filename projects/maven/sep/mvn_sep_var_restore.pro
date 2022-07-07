; $LastChangedBy: ali $
; $LastChangedDate: 2022-07-06 12:21:07 -0700 (Wed, 06 Jul 2022) $
; $LastChangedRevision: 30902 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_var_restore.pro $

pro mvn_sep_var_restore,pathname,trange=trange,verbose=verbose,download_only=download_only,prereq_info=prereq_temp,filename=files,no_finish=no_finish, $
  lowres=lowres,units_name=units_name,svy_tags=svy_tags,hkp_tags=hkp_tags,noise_tags=noise_tags,pfdpu_hkp_tags=pfdpu_hkp_tags,   $
  shkp_tags=shkp_tags,oper_tags=oper_tags,basic_tags=basic_tags,full_tags=full_tags,arc=arc

  @mvn_sep_handler_commonblock.pro
  @mvn_pfdpu_handler_commonblock.pro

  trange = timerange(trange)
  if ~keyword_set(pathname) then pn='maven/data/sci/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_1day.sav'
  if keyword_set(lowres) then begin
    pathname='maven/data/sci/sep/l1/sav_$RES/YYYY/MM/mvn_sep_l1_YYYYMMDD_$RES.sav'
    res=lowres
    if lowres eq 1 then res='5min'
    if lowres eq 2 then res='01hr'
    if lowres eq 3 then res='32sec'
    pn = str_sub(pathname,'$RES', res)
  endif

  if ~keyword_set(files) then files = mvn_pfp_file_retrieve(pn,/daily,trange=trange,source=source,verbose=verbose,/valid_only,no_update=0,last_version=0)

  if ~keyword_set(files) then begin
    dprint,verbose=verbose,dlevel=2,pn,'No SEP L1 files were found for the selected time range of '+time_string(trange[0])+' to '+time_string(trange[1])
    return
  endif

  if keyword_set(download_only) then return

  undefine,prereq_temp
  undefine,source_filenames

  mvn_sep_handler,/clear
  mvn_pfdpu_handler,/clear
  for i=0,n_elements(files)-1 do begin
    undefine, s1_hkp,s1_svy,s1_arc,s1_nse
    undefine, s2_hkp,s2_svy,s2_arc,s2_nse
    undefine, prereq_info,source_filename
    dprint,verbose=verbose,dlevel=2,'Restoring '+file_info_string(files[i])
    restore,verbose=verbose,filename=files[i]
    mav_gse_structure_append  ,sep1_hkp  , s1_hkp
    mav_gse_structure_append  ,sep1_svy  , s1_svy
    mav_gse_structure_append  ,sep1_arc  , s1_arc
    mav_gse_structure_append  ,sep1_noise, s1_nse
    mav_gse_structure_append  ,sep2_hkp  , s2_hkp
    mav_gse_structure_append  ,sep2_svy  , s2_svy
    mav_gse_structure_append  ,sep2_arc  , s2_arc
    mav_gse_structure_append  ,sep2_noise, s2_nse
    mav_gse_structure_append  ,mag1_hkp_f0  , m1_hkp
    mav_gse_structure_append  ,mag2_hkp_f0  , m2_hkp

    mav_gse_structure_append  ,apid20x  , ap20
    mav_gse_structure_append  ,apid21x  , ap21
    mav_gse_structure_append  ,apid22x  , ap22
    mav_gse_structure_append  ,apid23x  , ap23
    mav_gse_structure_append  ,apid24x  , ap24
    mav_gse_structure_append  ,apid25x  , ap25
    append_array, prereq_temp,prereq_info
    append_array, source_filenames, source_filename
  endfor

  if keyword_set(basic_tags) then begin
    svy_tags='ATT DURATION'
    hkp_tags=' '
    noise_tags=' '
    pfdpu_hkp_tags=' '
    shkp_tags=' '
    oper_tags=' '
  endif

  if keyword_set(full_tags) then begin
    svy_tags='*'
    hkp_tags='*'
    noise_tags='*'
    pfdpu_hkp_tags='*'
    shkp_tags='*'
    oper_tags='*'
  endif

  mvn_pfdpu_handler,finish= ~keyword_set(no_finish),hkp_tags=pfdpu_hkp_tags,shkp_tags=shkp_tags,oper_tags=oper_tags,lowres=res
  mvn_sep_handler,finish= ~keyword_set(no_finish),units_name=units_name,svy_tags=svy_tags,hkp_tags=hkp_tags,noise_tags=noise_tags,lowres=res,arc=arc
end
