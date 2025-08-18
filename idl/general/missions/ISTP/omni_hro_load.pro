;+
;Procedure: OMNI_HRO_LOAD
;
;Purpose:  Loads OMNI data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;Example:
;   OMNI_HRO_load
;Notes:
;  This routine is still in development.
; Author: Davin Larson
;
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL: $
;-
pro omni_hro_load,type,files=files,trange=trange,verbose=verbose,downloadonly=downloadonly, $
      varformat=varformat,datatype=datatype, no_download=no_download, no_update=no_update, $
      res5min=res5min,res1min=res1min, $
      addmaster=addmaster,data_source=data_source, $
      tplotnames=tn,source=source

;if not keyword_set(datatype) then datatype = 'h0'

istp_init
if not keyword_set(source) then source = !istp

rstrings = ['1min','5min']
rstr = rstrings[ keyword_set(res5min)  ]


;if datatype eq 'k0'  then    pathformat = 'wind/mfi/YYYY/wi_k0_mfi_YYYYMMDD_v0?.cdf'
;if datatype eq 'h0'  then    pathformat = 'wind/mfi_h0/YYYY/wi_h0_mfi_YYYYMMDD_v0?.cdf'

;URL deprecated by reorg at SPDF
;pathformat = 'omni/hro_'+rstr+'/YYYY/omni_hro_'+rstr+'_YYYYMM01_v01.cdf
;New URL 2012/10 pcruce@igpp
pathformat = 'omni/omni_cdaweb/hro_'+rstr+'/YYYY/omni_hro_'+rstr+'_YYYYMM01_v01.cdf

;if not keyword_set(varformat) then begin
;   if datatype eq  'k0' then    varformat = 'BGSEc PGSE'
;   if datatype eq  'h0' then    varformat = 'B3GSE'
;endif

relpathnames = file_dailynames(file_format=pathformat,trange=trange,/unique)

;files = file_retrieve(relpathnames, _extra=source)

if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
if keyword_set(no_update) && no_update ne 0 then source.no_update = 1
 
files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path = source.local_data_dir, ssl_verify_peer=0, ssl_verify_host=0, $
  no_download=source.no_download, no_update = source.no_update, /last_version )

if keyword_set(downloadonly) then return

prefix = 'OMNI_HRO_'+rstr+'_'
cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn    ; load data into tplot variables

;time clip 
if keyword_set(trange)then begin
  if (N_ELEMENTS(trange) eq 2) and (tn[0] gt '') then begin    
    time_clip, tn, trange[0], trange[1], replace=1, error=error 
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
