;+
;Procedure: omni_load_data
;
;Purpose:  Loads OMNI data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;   download_only: set this keyword to download the file only. this doesn't create tplot vars
;   no_download: set this keyword to not download data and look for the file locally
;   local_file_first: set this keyword to look for the local file first before
;       downloading the file
;   res5min: set this keyword to request only 5 minute resolution data
;   hro2: download hro2 data instead of hro
;
;   Obsolete keywords no longer used:
;   datatype
;   res1min
;   addmaster
;   data_source
;   source options
;
;Example:
;   OMNI_HRO_load
;
;Notes:
;     Original author: Davin Larson
;     Forked for SPEDAS by egrimes 4/21/2015 - moving to omni_init from istp_init
;
;     http://omniweb.gsfc.nasa.gov/html/HROdocum.html
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2025-04-13 15:06:29 -0700 (Sun, 13 Apr 2025) $
; $LastChangedRevision: 33256 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/omni/omni_load_data.pro $
;-
pro omni_load_data,type,files=files,trange=trange,verbose=verbose,$
  downloadonly=downloadonly, no_download=no_download, $
  local_file_first=local_file_first, varformat=varformat,datatype=datatype, hro2=hro2, $
  res5min=res5min,res1min=res1min, $
  addmaster=addmaster,data_source=data_source, $
  tplotnames=tn,source_options=source

  ;if not keyword_set(datatype) then datatype = 'h0'

  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()
  if ~keyword_set(no_download) then no_download=0 else no_download=1

  omni_init
  if not keyword_set(source) then source = !omni
  if not keyword_set(local_file_first) then local_file_first=0 else local_file_first=1

  rstrings = ['1min','5min']
  rstr = rstrings[ keyword_set(res5min)  ]


  ;if datatype eq 'k0'  then    pathformat = 'wind/mfi/YYYY/wi_k0_mfi_YYYYMMDD_v0?.cdf'
  ;if datatype eq 'h0'  then    pathformat = 'wind/mfi_h0/YYYY/wi_h0_mfi_YYYYMMDD_v0?.cdf'

  ;URL deprecated by reorg at SPDF
  ;pathformat = 'omni/hro_'+rstr+'/YYYY/omni_hro_'+rstr+'_YYYYMM01_v01.cdf
  ;New URL 2012/10 pcruce@igpp
  
  if keyword_set(hro2) then begin
    pathformat = 'omni/omni_cdaweb/hro2_'+rstr+'/YYYY/omni_hro2_'+rstr+'_YYYYMM01_v01.cdf'
  endif else begin
  pathformat = 'omni/omni_cdaweb/hro_'+rstr+'/YYYY/omni_hro_'+rstr+'_YYYYMM01_v01.cdf'
  endelse
  
  ;if not keyword_set(varformat) then begin
  ;   if datatype eq  'k0' then    varformat = 'BGSEc PGSE'
  ;   if datatype eq  'h0' then    varformat = 'B3GSE'
  ;endif

  relpathnames = file_dailynames(file_format=pathformat,trange=tr,/unique)

  ;files = file_retrieve(relpathnames, _extra=source)
  ; If no_download flag and local_file_first is not set then
  ; download the data. Look for local file only if unable to
  ; download the data from the remote server
  if no_download eq 0 and local_file_first eq 0 then begin
    files = spd_download(remote_file=relpathnames, $
      remote_path=source.remote_data_dir, $
      local_path = source.local_data_dir, $
      ssl_verify_peer=0, ssl_verify_host=0, $
      no_download = source.no_download, $
      no_update = source.no_update,  $
      file_mode = '666'o, dir_mode = '777'o)
    ; file was not downloaded. look locally
    if file_test(files) eq 0 then begin
      print, 'Unable to download ' + source.remote_data_dir + relpathnames
      print, 'Will look for file locally'
    endif
    ; if remote file not found or no_download set then look for local copy
    if files[0] EQ '' then begin
      files = source.local_data_dir + relpathnames
      if file_test(files) eq 0 then begin
        print, 'Unable to find local file '+ files
        return
      endif
    endif

    ; either the no_download key was set or the user requested
    ; to use a local file first
  endif else begin
    files = source.local_data_dir + relpathnames
    if file_test(files) eq 0 then begin
      print, 'Unable to find local file '+ files
      print, 'Will try and download file from server'
      ; local file was not found, if the no_download key isn't
      ; set then try downloading the file.
      if no_download eq 0 then begin
        files = spd_download(remote_file=relpathnames, $
          remote_path=source.remote_data_dir, $
          local_path = source.local_data_dir, $
          ssl_verify_peer=0, ssl_verify_host=0, $
          no_download = source.no_download, $
          no_update = source.no_update,  $
          file_mode = '666'o, dir_mode = '777'o)
        if file_test(files) eq 0 then begin
          print, 'Unable to download ' + source.remote_data_dir + relpathnames
          return
        endif
      endif
    endif
  endelse

  if keyword_set(downloadonly) then return

  ; double check that the file is available
  if file_test(files) eq 0 then return

  if keyword_set(hro2) then begin
    prefix = 'OMNI_HRO2_'+rstr+'_'
  endif else begin
    prefix = 'OMNI_HRO_'+rstr+'_'
  endelse

  cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn    ; load data into tplot variables

  ;time clip
  if keyword_set(tr)then begin
    if (N_ELEMENTS(tr) eq 2) and (tn[0] gt '') then begin
      time_clip, tn, tr[0], tr[1], replace=1, error=error
    endif
  endif

  ; Set options for specific variables

  dprint,dlevel=3,'tplotnames: ',tn

  options,/def,tn+'',/lazy_ytitle          ; options for all quantities
  options,/def,strfilter(tn,'*_T',delim=' ') , max_value=5e6    ; set colors for the vector quantities
  ;options,/def,strfilter(tn,'*B*GSE* *B*GSM*',delim=' '),constant=0., labels=['Bx','By','Bz'] , ysubtitle = '[nT]'

  ; the following assumes the OMNI variables are loaded with the default names
  swvel_datt = {units: 'km/s', coord_sys: 'gse', st_type: 'none', observatory: 'OMNI', instrument: 'OMNI'}
  swpos_datt = {units: 'Re', coord_sys: 'gse', st_type: 'pos', observatory: 'OMNI', instrument: 'OMNI'}
  swBgse_datt = {units: 'nT', coord_sys: 'gse', st_type: 'none', observatory: 'OMNI', instrument: 'OMNI'}
  swBgsm_datt = {units: 'nT', coord_sys: 'gsm', st_type: 'none', observatory: 'OMNI', instrument: 'OMNI'}

  ; set the data attributes for the solar wind velocity
  options, /def, strfilter(tn, '*_flow_speed'), 'data_att', swvel_datt
  options, /def, strfilter(tn, '*_V?'), 'data_att', swvel_datt

  ; set the data attributes for the s/c position variables
  options, /def, strfilter(tn, '*_?min_x'), 'data_att', swpos_datt
  options, /def, strfilter(tn, '*_?min_y'), 'data_att', swpos_datt
  options, /def, strfilter(tn, '*_?min_z'), 'data_att', swpos_datt

  ; set the data attributes for the B field variables
  options, /def, strfilter(tn, '*_B?_GSE'), 'data_att', swBgse_datt
  options, /def, strfilter(tn, '*_B?_GSM'), 'data_att', swBgsm_datt

end
