;Procedure: THM_LOAD_HSK
;
;Purpose:  Loads THEMIS Housekeeping data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  varformat=string
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  type:  set to 'calibrated' to automatically convert data into physical units
;Example:
;   thg_load_sst,/get_suppport_data,probe=['a', 'b']
;Notes:
; 1. Written by Davin Larson, March 2007
; 2. If calibrating use dprint,setdebug=5 to see detailed calibration information
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-27 11:26:29 -0700 (Mon, 27 Apr 2015) $
; $LastChangedRevision: 17433 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/thm_load_hsk.pro $
;-

pro thm_load_hsk,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                 varformat=varformat, valid_names = valid_names, files=files,$
                 type=type

thm_init
dprint,verbose=verbose,dlevel=4,'$Id: thm_load_hsk.pro 17433 2015-04-27 18:26:29Z aaflores $'

if(keyword_set(probe)) then $
  p_var = probe

vb = keyword_set(verbose) ? verbose : 0
vb = vb > !themis.verbose

vprobes = ['a','b','c','d','e', 'f']
vlevels = ['l1','l2']
vdatatypes=['hsk']

if ~keyword_set(type) then begin
  type = 'raw'
endif

if keyword_set(valid_names) then begin
    probe = vprobes
    level = vlevels
    datatype = vdatatypes
    return
endif

if not keyword_set(p_var) then p_var='*'
p_var = strfilter(vprobes, p_var ,delimiter=' ',/string)

if not keyword_set(datatype) then datatype='*'
datatype = strfilter(vdatatypes, datatype ,delimiter=' ',/string)

if not keyword_set(level) then level='*'
level = strfilter(vdatatypes, level ,delimiter=' ',/string)

addmaster=0

probe_colors = ['m','b','c','g','r','y']

for s=0,n_elements(p_var)-1 do begin
     thx = 'th'+ p_var[s]

;     relpathnames = file_dailynames(thx+'/l1/hsk/',dir='YYYY/',thx+'_l1_hsk_','_v01.cdf',trange=trange,addmaster=addmaster)
     format = thx+'/l1/hsk/YYYY/'+thx+'_l1_hsk_YYYYMMDD_v01.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
;     if vb ge 4 then printdat,/pgmtrace,relpathnames
     dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
     files = spd_download(remote_file=relpathnames, _extra=!themis)

     if keyword_set(!themis.downloadonly) or keyword_set(downloadonly) then continue

     suf='_raw'
     midfix='_hsk'
     cdf2tplot,file=files,varformat=varformat,all=0,midfix=midfix,midpos=3,suffix=suf,verbose=vb, $
              get_support_data=get_support_data,tplotnames=tns,/convert_int1_to_int2 ; load data into tplot variables

     if is_string(tns) then begin
     
       pn = byte(p_var[s]) - byte('a')
       options, /def, tns, colors = probe_colors[pn]
     
       if keyword_set(type) && strlowcase(type) eq 'calibrated' then begin
         thm_cal_hsk,tns,out_names=out_names
         tns = [tns,out_names]
       endif
       

       dprint, dlevel = 5, verbose = verbose, 'Setting options...'

       options, /def, tns, code_id = '$Id: thm_load_hsk.pro 17433 2015-04-27 18:26:29Z aaflores $'
  
       c_var = [1, 2, 3, 4, 5, 6]

       hsk_options_grp = [thx+'_hsk_iefi_ibias',thx+'_hsk_iefi_usher',thx+'_hsk_iefi_guard']
       hsk_options_ele = [thx+'_hsk_iefi_ibias?',thx+'_hsk_iefi_usher?',thx+'_hsk_iefi_guard?']


       options, hsk_options_grp+'_raw', data_att = {units:'ADC'}, $
         ysubtitle = '[ADC]', colors = c_var, labels = string(c_var), $
         labflag = 1, /def
       options, hsk_options_ele+'_raw', ata_att = {units:'ADC'}, $
         ysubtitle = '[ADC]', labflag = 1, /def
       options, thx+'_hsk_iefi_braid_raw', data_att = {units:'ADC'}, $
         ysubtitle = '[ADC]', /def
       options, hsk_options_grp+'_cal', colors = c_var, labels = string(c_var), $
         labflag = 1, /def   
           
       options, /def, strfilter(tns, '*ietc_covers*'), tplot_routine = 'bitplot', colors = ''
       options, /def ,strfilter(tns, '*ipwrswitch*'), tplot_routine = 'bitplot', colors= ''
       dprint, dwait = 5., verbose = verbose, 'Flushing output'
       dprint, dlevel = 4, verbose = verbose, 'Housekeeping data Loaded for probe: '+p_var[s]
       
     endif else begin
       dprint, dlevel = 0, verbose = verbose, 'No HSK data loaded...'+' Probe: '+p_var[s]
     endelse
endfor

if keyword_set(make_multi_tplotvar) then begin
   tns = tnames('th?_hsk_*')
   tns_suf = strmid(tns,8)
   tns_suf = tns_suf[uniq(tns_suf,sort(tns_suf))]
   for i=0,n_elements(tns_suf)-1 do store_data,'Thx_hsk_'+tns_suf[i],data=tnames('th?_hsk_'+tns_suf[i])
endif


end
