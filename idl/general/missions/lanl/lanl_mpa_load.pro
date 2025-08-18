;+
;Procedure: LANL_MPA_LOAD
;
;Purpose:  Loads LANL MPA data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;Example:
;   lanl_mpa_load,probe='02'
;Notes:
;  This routine is still in development.
; Author: Davin Larson
;
; $LastChangedBy: davin-win $
; $LastChangedDate: $
; $LastChangedRevision:  $
; $URL $
;-
pro lanl_mpa_load,type,files=files,trange=trange,verbose=verbose,downloadonly=downloadonly, $
      varformat=varformat,datatype=datatype, $
      probe=probe, no_download=no_download, no_update=no_update, $
      addmaster=addmaster,tplotnames=tn,source=source

if not keyword_set(probe) then probe = '97'


;if not keyword_set(datatype) then $
    datatype = 'k0'

istp_init
if not keyword_set(source) then source = !istp

dprint,dlevel=2,verbose=source.verbose,'Loading LANL ',probe,' MPA data'

if datatype eq 'k0'  then begin
   case probe of
   '02':   pathformat = 'lanl/02a_mpa/YYYY/a2_k0_mpa_YYYYMMDD_v02.cdf'
   '01':   pathformat = 'lanl/01a_mpa/YYYY/a1_k0_mpa_YYYYMMDD_v02.cdf'
   '97':   pathformat = 'lanl/97_mpa/YYYY/l7_k0_mpa_YYYYMMDD_v02.cdf'
   '94':   pathformat = 'lanl/94_mpa/YYYY/l4_k0_mpa_YYYYMMDD_v02.cdf'
   '91':   pathformat = 'lanl/91_mpa/YYYY/l1_k0_mpa_YYYYMMDD_v02.cdf'
   '90':   pathformat = 'lanl/90_mpa/YYYY/l0_k0_mpa_YYYYMMDD_v02.cdf'
   '89':   pathformat = 'lanl/89_mpa/YYYY/l9_k0_mpa_YYYYMMDD_v02.cdf'
   endcase
endif
;if datatype eq 'k0'  then    pathformat = 'lanl/97_mpa/YYYY/l7_k0_mpa_YYYYMMDD_v02.cdf'
;if datatype eq 'h0'  then    pathformat = 'lanl/97_h0_mpa/YYYY/17_h0_mpa_YYYYMMDD_v03.cdf'  ; only limited data from 1998
;if datatype eq 'h1'  then    pathformat = 'ace/mfi_h1/YYYY/ac_h1_mfi_YYYYMMDD_v05.cdf'
;if datatype eq 'h2'  then    pathformat = 'ace/mfi_h2/YYYY/ac_h2_mfi_YYYYMMDD_v05.cdf'

if not keyword_set(varformat) then begin
   varformat = '*'
;   if datatype eq  'k0' then    varformat = 'BGSEc'
;   if datatype eq  'h0' then    varformat = '*'
;   if datatype eq  'h1' then    varformat = '*'
endif

if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
if keyword_set(no_update) && no_update ne 0 then source.no_update = 1

relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)
files =  spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path = source.local_data_dir, $
                     no_download = source.no_download, no_update = source.no_update, /last_version, $
                     file_mode = '666'o, dir_mode = '777'o)
                     
if keyword_set(downloadonly) then return

prefix = 'lanl_'+probe+'_mpa_'
cdf2tplot,file=files,varformat=varformat,verbose=source.verbose,prefix=prefix ,tplotnames=tn    ; load data into tplot variables

; Set options for specific variables

dprint,dlevel=3,verbose=source.verbose,'tplotnames: ',tn

del_data,strfilter(tn,'*PB5')

;options,/def,strfilter(tn,'*GSE* *GSM*',delim=' '),/lazy_ytitle , colors='bgr'     ; set colors for the vector quantities
;options,/def,strfilter(tn,'*B*GSE* *B*GSM*',delim=' '), labels=['Bx','By','Bz'] , ysubtitle = '[nT]'



end
