; Created by Davin Larson
; $LastChangedBy: ali $
; $LastChangedDate: 2022-07-06 12:21:07 -0700 (Wed, 06 Jul 2022) $
; $LastChangedRevision: 30902 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_load.pro $

pro mvn_sep_load,pathnames=pathnames,trange=trange,files=files,RT=RT,download_only=download_only, $
  mag=mag,pfdpu=pfdpu,sep=sep,lpw=lpw,sta=sta,format=format,use_cache=use_cache,  $
  source=source,verbose=verbose,L1=L1,L0=L0,L2=L2,ancillary=ancillary,anc_structure=anc_structure,$
  pad=pads,eflux=eflux,lowres=lowres,arc=arc,units_name=units_name,basic_tags=basic_tags,full_tags=full_tags

  @mvn_sep_handler_commonblock.pro

  ; loading the ancillary data.
  if keyword_set(ancillary) then mvn_sep_anc_load,trange=trange,download_only=download_only,anc_structure=anc_structure

  if keyword_set(pads) then begin
    pad_format = 'maven/data/sci/sep/l3/pad/sav/YYYY/MM/mvn_sep_l3_pad_YYYYMMDD_v??_r??.sav'
    pad_files = mvn_pfp_file_retrieve(pad_format,/daily_names,trange=trange,/valid_only,/last_version)
    pads=[]
    if pad_files[0] eq '' then begin
      dprint,pad_format
      dprint, 'MAVEN/SEP PAD files do not exist for this time range. Returning...'
      return
    endif
    foreach pad_file,pad_files do begin
      dprint,'Restoring '+file_info_string(pad_file)
      restore,pad_file
      pads=[pads,pad]
    endforeach
    mvn_sep_pad_load_tplot,pads
    return
  endif

  if keyword_set(L0) then   format = 'L0_RAW'
  if keyword_set(L1) then   format = 'L1_SAV'
  if keyword_set(L2) then   format = 'L2_CDF'

  if ~keyword_set(format) then format='L1_SAV'

  if format eq 'L1_SAV' then begin

    if keyword_set(use_cache) and keyword_set(source_filenames) then begin
      files = mvn_pfp_file_retrieve(/L0,/daily,trange=trange,source=source,verbose=verbose,RT=RT,files=files,pathnames)
      if array_equal(files,source_filenames) then begin
        dprint,verbose=verbose,dlevel=2,'Using cached common block loaded from '+file_info_string(files)
        return
      endif
    endif

    mvn_sep_var_restore,trange=trange,download_only=download_only,verbose=verbose,lowres=lowres,arc=arc,$
      units_name=units_name,basic_tags=basic_tags,full_tags=full_tags,filename=files
    if ~keyword_set(download_only) && keyword_set(files) then begin
      mvn_sep_cal_to_tplot,sepn=1,lowres=lowres,arc=arc
      mvn_sep_cal_to_tplot,sepn=2,lowres=lowres,arc=arc
    endif
    return
  endif


  if format eq 'L2_CDF' then begin
    for sepnum = 1,2 do begin
      sepstr = 's'+strtrim(sepnum,2)
      data_type = sepstr+'-cal-svy-full'
      L2_fileformat =  'maven/data/sci/sep/l2/YYYY/MM/mvn_sep_l2_'+data_type+'_YYYYMMDD_v0?_r??.cdf'
      ;    if getenv('USER') eq 'davin' then L2_fileformat =  'maven/data/sci/sep/l2_v04/YYYY/MM/mvn_sep_l2_'+data_type+'_YYYYMMDD_v04_r??.cdf'
      filenames = mvn_pfp_file_retrieve(l2_fileformat,/daily_name,trange=trange,verbose=verbose,/valid_only)
      if ~keyword_set(download_only) then cdf2tplot,filenames,prefix = 'mvn_L2_sep'+strtrim(sepnum,2) else return
    endfor

    if keyword_set (eflux) then begin  ; also load Energy flux
      get_data,  'mvn_L2_sep1f_ion_flux', data = ion_1F
      get_data,  'mvn_L2_sep2f_ion_flux', data = ion_2F
      get_data,  'mvn_L2_sep1r_ion_flux', data = ion_1R
      get_data,  'mvn_L2_sep2r_ion_flux', data = ion_2R

      ; make tplot variables for ion energy flux
      store_data,'mvn_L2_sep1f_ion_eflux', data = {x: ion_1f.x, y: ion_1f.y*ion_1f.v, v:ion_1f.v}
      store_data,'mvn_L2_sep1r_ion_eflux', data = {x: ion_1r.x, y: ion_1r.y*ion_1r.v, v:ion_1r.v}
      store_data,'mvn_L2_sep2f_ion_eflux', data = {x: ion_2f.x, y: ion_2f.y*ion_2f.v, v:ion_2f.v}
      store_data,'mvn_L2_sep2r_ion_eflux', data = {x: ion_2r.x, y: ion_2r.y*ion_2r.v, v:ion_2r.v}

      get_data,  'mvn_L2_sep1f_elec_flux', data = electron_1F
      get_data,  'mvn_L2_sep2f_elec_flux', data = electron_2F
      get_data,  'mvn_L2_sep1r_elec_flux', data = electron_1R
      get_data,  'mvn_L2_sep2r_elec_flux', data = electron_2R

      ; make tplot variables for electron energy flux
      store_data,'mvn_L2_sep1f_electron_eflux',data = {x: electron_1f.x, y: electron_1f.y*electron_1f.v, v:electron_1f.v}
      store_data,'mvn_L2_sep1r_electron_eflux',data = {x: electron_1r.x, y: electron_1r.y*electron_1r.v, v:electron_1r.v}
      store_data,'mvn_L2_sep2f_electron_eflux',data = {x: electron_2f.x, y: electron_2f.y*electron_2f.v, v:electron_2f.v}
      store_data,'mvn_L2_sep2r_electron_eflux',data = {x: electron_2r.x, y: electron_2r.y*electron_2r.v, v:electron_2r.v}
    endif

    options,'mvn_L2_sep*flux',spec=1,ylog=1,zlog=1,ztickunits='scientific',ytickunits='scientific',ysubtitle='(keV)'
    options,'mvn_L2_sep*_flux', 'ztitle', 'Diff Flux, !c #/cm2/s/sr/keV'
    options,'mvn_L2_sep*eflux', 'ztitle', 'Diff EFlux, !c keV/cm2/s/sr/keV'

    ; make a tplot variable for both attenuators
    store_data, 'mvn_L2_sep_attenuator', data = 'mvn_L2_sep?attenuator_state',dlim={colors:'br',yrange:[0.5,2.5],labels:['SEP1','SEP2'],labflag:-1,panel_size:0.5}

    return
  endif

  ;  Use L0 format if it reaches this point.

  files = mvn_pfp_file_retrieve(/L0,/daily,trange=trange,source=source,verbose=verbose,RT=RT,files=files,pathnames)

  if keyword_set(use_cache) and keyword_set(source_filenames) then begin
    if array_equal(files,source_filenames) then begin
      dprint,verbose=verbose,dlevel=2,'Using cached common block loaded from '+file_info_string(files)
      return
    endif
  endif

  tstart=systime(1)
  if n_elements(pfdpu) eq 0 then pfdpu=1
  if n_elements(sep) eq 0 then sep=1
  if n_elements(mag) eq 0 then mag=1

  ;last_files=''
  if ~keyword_set(download_only) then begin
    mvn_pfp_l0_file_read,sep=sep,pfdpu=pfdpu,mag=mag,lpw=lpw,sta=sta ,pathname=pathname,file=files,trange=trange
    mvn_sep_handler,record_filenames = files
    ;  last_files = files
  endif

end

