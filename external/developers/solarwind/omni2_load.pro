;+
;Procedure: OMNI2_LOAD
;
;Purpose:  Loads OMNI data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;Example:
;   omni2_load
;Notes:
;  This routine is still in development.
; Author: Davin Larson
;
; $LastChangedBy: bckerr $
; $LastChangedDate: 2008-09-08 13:16:17 -0700 (Mon, 08 Sep 2008) $
; $LastChangedRevision: 3459 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/developers/solarwind/omni2_load.pro $
;-
pro omni2_load,type,files=files,trange=trange,verbose=verbose,downloadonly=downloadonly, $
      varformat=varformat,datatype=datatype, $
      res5min=res5min, $
      addmaster=addmaster,data_source=data_source, $
      tplotnames=tn,source_options=source

istp_init
if not keyword_set(source) then source = !istp

pathformat1 = 'omni2/YYYY/omni2_h0_mrg1hr_YYYY0101_v0?.cdf'
pathformat2 = 'omni2/YYYY/omni2_h0_mrg1hr_YYYY0701_v0?.cdf'

relpathnames1 = file_dailynames(file_format=pathformat1,trange=trange,/unique)
relpathnames2 = file_dailynames(file_format=pathformat2,trange=trange,/unique)

files1 = file_retrieve(relpathnames1, _extra=source)
files2 = file_retrieve(relpathnames2, _extra=source)

files=[files1,files2]

if keyword_set(downloadonly) then return

prefix = 'OMNI2_mrg1hr_'
;prefix2 = 'OMNI2_mrg1hr_2_'
varformat='DST BZ_GSM Pressure'
cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn    ; load data into tplot variables
;cdf2tplot,file=files2,varformat=varformat,verbose=verbose,prefix=prefix2 ,tplotnames=tn2    ; load data into tplot variables

; Set options for specific variables

dprint,dlevel=3,'tplotnames: ',tn
;dprint,dlevel=3,'tplotnames: ',tn2

options,/def,tn+'',/lazy_ytitle          ; options for all quantities
;options,/def,tn2+'',/lazy_ytitle          ; options for all quantities

end
