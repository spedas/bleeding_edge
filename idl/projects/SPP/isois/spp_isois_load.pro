; $LastChangedBy: pulupalap $
; $LastChangedDate: 2022-06-26 16:28:28 -0700 (Sun, 26 Jun 2022) $
; $LastChangedRevision: 30885 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/isois/spp_isois_load.pro $
; Created by Davin Larson 2020-April 27
;
;-

pro spp_isois_load,types=types,level=level,trange=trange,no_load=no_load,tname_prefix=tname_prefix,save=save,$
  verbose=verbose,varformat=varformat,fileprefix=fileprefix,overlay=overlay,key=key

  if ~keyword_set(level) then level='L2'
  level=strupcase(level)
  ;if ~keyword_set(types) then types=['sf00']  ;,'sf01','sf0a']


  ;; Product File Names
  ;dir='spi/'+level+'/YYYY/MM/spi_TYP/' ;old directory structure
  if not keyword_set(fileprefix) then fileprefix='psp/data/sci/isois/'
  
  if 0 then begin
    dir='EPILo/level2/'
    fileformat=dir+'psp_isois-epilo_l2-ic_YYYYMMDD_v03.cdf
    remote_dir = 'http://spp-isois.sr.unh.edu/data_public/'   ; file_http_copy doesn't work with this server... Not sure why.
    remote_dir = 'http://research.ssl.berkeley.edu/data/psp/data/sci/isois/data_public/'
    local_data_dir = root_data_dir() + fileprefix
    fsource = file_retrieve(/default_struct,remote_data_dir=remote_dir,/valid_only,local_data_dir = local_data_dir)
    printdat,fsource
    types = 'test'

    tr=timerange(trange)
    foreach type,types do begin

      ;; Instrument string substitution
      filetype=str_sub(fileformat,'TYP',type)

      ;; Find file locations
      dprint,filetype,/phelp
      pathname =   filetype
      files = file_retrieve(pathname,_extra = fsource,trange=tr,/daily_res,verbose=verbose,/last_version)
      ;files=spp_file_retrieve(filetype,trange=tr,/daily_names,/valid_only,/last_version,prefix=fileprefix,verbose=verbose)

      if keyword_set(save) then begin
        vardata = !null
        novardata = !null
        loadcdfstr,filenames=files,vardata,novardata
        source=spp_data_product_hash('isois_'+type+'_'+level,vardata)
        printdat,source
      endif

      ;; Do not load the files
      if keyword_set(no_load) then continue

      ;; Load TPLOT Formats
      ;   if keyword_set(varformat) then varformat2=varformat else if vars.haskey(type) then varformat2=vars[type] else varformat2=[]

      prefix='psp_isois_'
      if keyword_set(tname_prefix) then prefix=tname_prefix+prefix
      ;; Convert to TPLOT
      cdf2tplot,files,prefix=prefix,varformat=varformat2,verbose=verbose
    endforeach
  endif else begin     ; http://sprg.ssl.berkeley.edu/data/psp/data/sci/isois/data_private/ISOIS/level2/psp_isois_l2-summary_20200318_v1.0.0.cdf
    remote_dir = 'http://spp-isois.sr.unh.edu/data_private/'   ; file_http_copy doesn't work with this server... Not sure why.
    remote_dir = 'http://research.ssl.berkeley.edu/data/'
    local_data_dir = root_data_dir() + fileprefix
    dir=fileprefix+'data_private/ISOIS/level2/'

    if n_elements(key) EQ 0 then key = 'SWEAP'
    if key EQ 'FIELDS' then dir=fileprefix+'shared/rsync/l2/'

    ; note: this doesn't work for files ending like v3.10.0.cdf

    fileformat=dir+'psp_isois_l2-sum\mary_YYYYMMDD_v*.*.*.cdf'
    files = spp_file_retrieve(key=key,fileformat,/valid_only,/last_version,/daily_names)
  endelse
  
  cdf2tplot,files

  ;; Product TPLOT Parameters

end


