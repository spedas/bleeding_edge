;+
;Procedure: ACE_MFI_LOAD
;
;Purpose:  Loads ACE fluxgate magnetometer data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;   datatype = One of: ['k0, 'h0', 'h1', 'h2', 'h3']
;Example:
;   ace_mfi_load
;Notes:
;  This routine is still in development.
; Author: Davin Larson
;
; $LastChangedBy: davin-win $
; $LastChangedDate: $
; $LastChangedRevision:  $
; $URL $
;-
pro ace_mfi_load,type,files=files,trange=trange,verbose=verbose,downloadonly=downloadonly, $
      varformat=varformat,datatype=datatype, $
      addmaster=addmaster,tplotnames=tn,source=source,no_download=no_download, no_update=no_update

if not keyword_set(datatype) then datatype = 'k0'
dtyp = strcompress(/remove_all, strlowcase(datatype[0]))

istp_init
if not keyword_set(source) then source = !istp

;URLs changed due to SPDF reorg
;if datatype eq 'k0'  then    pathformat = 'ace/mfi/YYYY/ac_k0_mfi_YYYYMMDD_v01.cdf'
;if datatype eq 'h0'  then    pathformat = 'ace/mfi_h0/YYYY/ac_h0_mfi_YYYYMMDD_v05.cdf'
;if datatype eq 'h1'  then    pathformat = 'ace/mfi_h1/YYYY/ac_h1_mfi_YYYYMMDD_v05.cdf'
;if datatype eq 'h2'  then    pathformat = 'ace/mfi_h2/YYYY/ac_h2_mfi_YYYYMMDD_v05.cdf'
;New URLs 2012/10 pcruce@igpp
;if datatype eq 'k0'  then    pathformat = 'ace/mag/level_2_cdaweb/mfi_k0/YYYY/ac_k0_mfi_YYYYMMDD_v01.cdf'
;if datatype eq 'h0'  then    pathformat = 'ace/mag/level_2_cdaweb/mfi_h0/YYYY/ac_h0_mfi_YYYYMMDD_v05.cdf'
;if datatype eq 'h1'  then    pathformat = 'ace/mag/level_2_cdaweb/mfi_h1/YYYY/ac_h1_mfi_YYYYMMDD_v05.cdf'
;if datatype eq 'h2'  then    pathformat = 'ace/mag/level_2_cdaweb/mfi_h2/YYYY/ac_h2_mfi_YYYYMMDD_v05.cdf'
;if datatype eq 'h3'  then    pathformat = 'ace/mag/level_2_cdaweb/mfi_h3/YYYY/ac_h3_mfi_YYYYMMDD_v01.cdf'

;Hard-coded version numbers don't always work, 2016-06-13, jmm
pathformat = 'ace/mag/level_2_cdaweb/mfi_'+dtyp+'/YYYY/ac_'+dtyp+'_mfi_YYYYMMDD_v??.cdf'

if not keyword_set(varformat) then begin
   varformat = '*'
   if datatype eq  'k0' then    varformat = 'BGSEc'
   if datatype eq  'h0' then    varformat = '*'
   if datatype eq  'h1' then    varformat = '*'
endif

if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
if keyword_set(no_update) && no_update ne 0 then source.no_update = 1

relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)
files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path = source.local_data_dir, $
  no_download = source.no_download, no_update = source.no_update, /last_version, $
  file_mode = '666'o, dir_mode = '777'o)

if keyword_set(downloadonly) then return

prefix = 'ace_'+datatype+'_mfi_'
cdf2tplot,file=files,varformat=varformat,verbose=source.verbose,prefix=prefix ,tplotnames=tn    ; load data into tplot variables

; Set options for specific variables

options,/def,strfilter(tn,'*GSE* *GSM*',delim=' '),/lazy_ytitle , colors='bgr'     ; set colors for the vector quantities
options,/def,strfilter(tn,'*B*GSE* *B*GSM*',delim=' '), labels=['Bx','By','Bz'] , ysubtitle = '[nT]'

dprint,dlevel=3,'tplotnames: ',tn


end
