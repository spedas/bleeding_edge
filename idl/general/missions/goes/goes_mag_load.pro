;+
;Procedure: GOES_MAG_LOAD
;
;Purpose:  Loads GOES MAG data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;Example:
;   goes_mag_load,probe='11'
;Notes:
;  This routine is still in development.
; Author: Davin Larson
;
; $LastChangedBy: davin-win $
; $LastChangedDate: $
; $LastChangedRevision:  $
; $URL $
;-
pro goes_mag_load,trange=trange,verbose=verbose,downloadonly=downloadonly, $
      varformat=varformat,datatype=datatype, $
      probes=probes, no_download=no_download, no_update=no_update, $
      addmaster=addmaster,tplotnames=tn,source=source

;if not keyword_set(probes) then probes = ['0','6','7','8','9','11','12']
if not keyword_set(probes) then probes = ['10','11','12']
nprobes = n_elements(probes)
;if not keyword_set(datatype) then $
   datatype = 'k0'

istp_init
if not keyword_set(source) then source = !istp

for i=0,nprobes-1 do begin
probe=probes[i]

if datatype eq 'k0'  then begin

dprint,dlevel=2,verbose=source.verbose,'Loading GOES ',probe,' MAG data'


   case probe of
   ;Format is deprecated due to reorg at SPDF
;   '10':   pathformat = 'goes/0_mag/YYYY/g0_k0_mag_YYYYMMDD_v03.cdf'
;   '6':   pathformat = 'goes/6_mag/YYYY/g6_k0_mag_YYYYMMDD_v02.cdf'
;   '7':   pathformat = 'goes/7_mag/YYYY/g7_k0_mag_YYYYMMDD_v02.cdf'
;   '8':   pathformat = 'goes/8_mag/YYYY/g8_k0_mag_YYYYMMDD_v03.cdf'
;   '9':   pathformat = 'goes/9_mag/YYYY/g9_k0_mag_YYYYMMDD_v03.cdf'
;   '11':  pathformat = 'goes/11_mag/YYYY/goes11_k0_mag_YYYYMMDD_v03.cdf'
;   '12':  pathformat = 'goes/12_mag/YYYY/goes12_k0_mag_YYYYMMDD_v03.cdf'
   ;New URLs 2012/10 pcruce@igpp
   '10':  pathformat = 'goes/goes10/mag_k0/YYYY/g0_k0_mag_YYYYMMDD_v03.cdf'
   '6':   pathformat = 'goes/goes06/mag_k0/YYYY/g6_k0_mag_YYYYMMDD_v02.cdf'
   '7':   pathformat = 'goes/goes07/mag_k0/YYYY/g7_k0_mag_YYYYMMDD_v02.cdf'
   '8':   pathformat = 'goes/goes08/mag_k0/YYYY/g8_k0_mag_YYYYMMDD_v03.cdf'
   '9':   pathformat = 'goes/goes09/mag_k0/YYYY/g9_k0_mag_YYYYMMDD_v03.cdf'
   '11':  pathformat = 'goes/goes11/mag_k0/YYYY/goes11_k0_mag_YYYYMMDD_v03.cdf'
   '12':  pathformat = 'goes/goes12/mag_k0/YYYY/goes12_k0_mag_YYYYMMDD_v03.cdf'  
   else:  pathformat = ''
   endcase
endif

if not keyword_set(pathformat) then begin
    dprint,'Not a valid probe'
    return
endif

if not keyword_set(varformat) then begin
   varformat = 'SC_pos_* B_???_c'
;   if datatype eq  'k0' then    varformat = 'BGSEc'
;   if datatype eq  'h0' then    varformat = '*'
;   if datatype eq  'h1' then    varformat = '*'
endif

if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
if keyword_set(no_update) && no_update ne 0 then source.no_update = 1

relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)
files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path = source.local_data_dir, $
  no_download = source.no_download, no_update = source.no_update, /last_version, $
  file_mode = '666'o, dir_mode = '777'o)
  
if keyword_set(downloadonly) then continue

prefix = 'goes'+probe+'_'
cdf2tplot,file=files,varformat=varformat,verbose=source.verbose,prefix=prefix ,tplotnames=tn    ; load data into tplot variables

; Set options for specific variables

dprint,dlevel=3,'tplotnames: ',tn

;del_data,strfilter(tn,'*PB5')


;options,/def,strfilter(tn,'*fl*x'),/ylog
options,/def,strfilter(tn,'*GSE* *GSM* *pos* *lcl*',delim=' '),/lazy_ytitle , colors='bgr'     ; set colors for the vector quantities
;options,/def,strfilter(tn,'*B*GSE* *B*GSM*',delim=' '), labels=['Bx','By','Bz'] , ysubtitle = '[nT]'

endfor


end
