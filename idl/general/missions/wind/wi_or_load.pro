;+
;Procedure: WI_OR_LOAD
;
;Purpose:  Loads WIND fluxgate magnetometer data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;Example:
;   wi_mfi_load
;Notes:
;  This routine is still in development.
; Author: Davin Larson
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2020-02-04 11:26:38 -0800 (Tue, 04 Feb 2020) $
; $LastChangedRevision: 28274 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/wi_or_load.pro $
;-
pro wi_or_load,type,trange=trange,verbose=verbose,downloadonly=downloadonly, $
      varformat=varformat,datatype=datatype, no_download=no_download, no_update=no_update, $
      addmaster=addmaster,data_source=data_source,tplotnames=tn,source_options=source,suffix=suffix

if keyword_set(addmaster) then begin
   dprint, 'WIND orbit, MFI and SWE files are istp-compliant.'
   dprint, 'The addmaster keyword has been deprecated, as of Feb. 2020.'
endif

if not keyword_set(datatype) then datatype = 'pre'

istp_init
if not keyword_set(source) then source = !istp

;path deprecated by changes at SPDF
;pathformat = 'wind/'+datatype+'_or/YYYY/wi_or_'+datatype+'_YYYYMMDD_v??.cdf'
;New URL 2012/10 pcruce@igpp
pathformat = 'wind/orbit/'+datatype+'_or/YYYY/wi_or_'+datatype+'_YYYYMMDD_v??.cdf'

if not keyword_set(varformat) then begin
   varformat = 'GSE_POS'
endif

if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
if keyword_set(no_update) && no_update ne 0 then source.no_update = 1

relpathnames = file_dailynames(file_format=pathformat,trange=trange)

files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path = source.local_data_dir, $
                     no_download = source.no_download, no_update = source.no_update, /last_version, $
                     file_mode = '666'o, dir_mode = '777'o)

if keyword_set(downloadonly) then return

prefix = 'wi_'+datatype+'_or_'
cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn,suffix=suffix    ; load data into tplot variables

; Set options for specific variables

dprint,dlevel=3,'tplotnames: ',tn

options,/def,tn+'',/lazy_ytitle          ; options for all quantities
options,/def,strfilter(tn,'*GSE* *GSM*',delim=' ') , colors='bgr' , labels=['X','Y','Z']    ; set colors for the vector quantities

end
