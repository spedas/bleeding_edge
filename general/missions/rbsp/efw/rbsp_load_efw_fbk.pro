;Procedure: RBSP_LOAD_EFW_FBK
;
;Purpose:  Loads RBSP EFW Filterbank data
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
;                      into tplot variables. (NOT IMPLEMENTED YET)
;  /DOWNLOADONLY: download file but don't read it. (NOT IMPLEMENTED YET)
;  /QA: If set, load data from l1_qa testing directory
;  /INTEGRATION: If set, load data from integration.
;  /MSIM: If set, load data from mission simulations.
;  /ETU: If set, load data from the ETU.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  type:  set to 'calibrated' to automatically convert data into physical units
;Example:
;   rbsp_load_efw_fbk,/get_suppport_data,probe=['a', 'b']
;Notes:
; 1. Written by Peter Schroeder, February 2012
;
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2015-07-10 07:53:49 -0700 (Fri, 10 Jul 2015) $
; $LastChangedRevision: 18070 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_load_efw_fbk.pro $
;-

pro rbsp_load_efw_fbk,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                 varformat=varformat, valid_names = valid_names, files=files,$
                 type=type, integration=integration, msim=msim, etu=etu, qa=qa,$
                 pT=pT

rbsp_efw_init
dprint,verbose=verbose,dlevel=4,'$Id: rbsp_load_efw_fbk.pro 18070 2015-07-10 14:53:49Z aaronbreneman $'

if keyword_set(etu) then probe = 'a'

;define frequency values for fbk7 and fbk13 products
v7 = [1., 2., 3., 4., 5., 6., 7.]
v13 = [1., 2., 3., 4., 5., 6., 7., 8., 9., 10., 11., 12., 13.]
if(keyword_set(probe)) then $
  p_var = strlowcase(probe)

vb = keyword_set(verbose) ? verbose : 0
vb = vb > !rbsp_efw.verbose
 
vprobes = ['a','b']
vlevels = ['l1','l2']
vdatatypes=['fbk']
default_data_att = {units: 'ADC', coord_sys: 'uvw', st_type: 'none', channel:''}
support_data_keep = ['BEB_config','DFB_config']

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

probe_colors = ['m','b']



for s=0,n_elements(p_var)-1 do begin
     rbspx = 'rbsp'+ p_var[s]
     if keyword_set(integration) then rbsppref = rbspx + '/l1_int' $
        else if keyword_set(msim) then rbsppref = rbspx+ '/l1_msim' $
        else if keyword_set(etu) then rbsppref = rbspx+ '/l1_etu' $
        else if keyword_set(qa) then rbsppref = rbspx+ '/l1_qa' $
        else rbsppref = rbspx + '/l1'
     
     format = rbsppref + '/fbk/YYYY/'+rbspx+'_l1_fbk_7_YYYYMMDD_v*.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
;     if vb ge 4 then printdat,/pgmtrace,relpathnames
     dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
     files = file_retrieve(relpathnames, /last_version, _extra=!rbsp_efw)

     if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue

;     suf='_raw'
     suf=''
;     midfix='_hsk_beb_analog_'
     prefix=rbspx+'_efw_fbk_7_'



;     if keyword_set(get_support_data) then $
          cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
              tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables

     if is_string(tns) then begin
     
       fbkname = rbspx+'_efw_fbk_7_fbk_7'
       fbknewname = rbspx+'_efw_fbk_7'
       
;       store_data,fbkname,newname=fbknewname
       
       get_data,fbkname,data=fbk7data
       
       store_data,fbknewname+'_fb1_av',data={x: fbk7data.x, $
          y:reform(fbk7data.y[*,*,0]), v: v7},dlimits={spec: 1, data_att: default_data_att}
       store_data,fbknewname+'_fb1_pk',data={x: fbk7data.x, $
          y:reform(fbk7data.y[*,*,1]), v: v7},dlimits={spec: 1, data_att: default_data_att}
       store_data,fbknewname+'_fb2_av',data={x: fbk7data.x, $
          y:reform(fbk7data.y[*,*,2]), v: v7},dlimits={spec: 1, data_att: default_data_att}
       store_data,fbknewname+'_fb2_pk',data={x: fbk7data.x, $
          y:reform(fbk7data.y[*,*,3]), v: v7},dlimits={spec: 1, data_att: default_data_att}
  
       pn = byte(p_var[s]) - byte('a')
;       options, /def, tns, colors = probe_colors[pn]       

       dprint, dlevel = 5, verbose = verbose, 'Setting options...'

       options, /def, tns, code_id = '$Id: rbsp_load_efw_fbk.pro 18070 2015-07-10 14:53:49Z aaronbreneman $'
  
       dprint, dwait = 5., verbose = verbose, 'Flushing output'
       dprint, dlevel = 4, verbose = verbose, 'Filterbank 7 data Loaded for probe: '+p_var[s]

;calibrate data
       if ~strcmp(type, 'raw', /fold) then begin
         rbsp_efw_cal_fbk, probe = p_var[s], $
           datatype = datatype, trange = trange, pT=pT
       endif



       if not keyword_set(get_support_data) then begin
          for i = 0, n_elements(tns) - 1 do begin
             if strfilter(tns[i],'*'+support_data_keep) eq '' then begin
                get_data,tns[i],dlimits=thisdlimits
                cdf_str = 0
                str_element,thisdlimits,'cdf',cdf_str
                if keyword_set(cdf_str) then if cdf_str.vatt.var_type eq 'support_data' then $
                   store_data,tns[i],/delete
             endif
          endfor
       endif
       
     endif else begin
       dprint, dlevel = 0, verbose = verbose, 'No EFW FBK 7 data loaded...'+' Probe: '+p_var[s]
;       dprint, dlevel = 0, verbose = verbose, 'Try using get_support_data keyword'
     endelse

     format = rbsppref + '/fbk/YYYY/'+rbspx+'_l1_fbk_13_YYYYMMDD_v*.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
;     if vb ge 4 then printdat,/pgmtrace,relpathnames
     dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
     files = file_retrieve(relpathnames, /last_version, _extra=!rbsp_efw)

     if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue

;     suf='_raw'
     suf=''
;     midfix='_hsk_beb_analog_'
     prefix=rbspx+'_efw_fbk_13_'

;     if keyword_set(get_support_data) then $
          cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
              tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables

     if is_string(tns) then begin

       fbkname = rbspx+'_efw_fbk_13_fbk_13'
       fbknewname = rbspx+'_efw_fbk_13'

;       store_data,fbkname,newname=fbknewname

       get_data,fbkname,data=fbk13data
       
       store_data,fbknewname+'_fb1_av',data={x: fbk13data.x, $
          y:reform(fbk13data.y[*,*,0]), v: v13},dlimits={spec: 1, data_att: default_data_att}
       store_data,fbknewname+'_fb1_pk',data={x: fbk13data.x, $
          y:reform(fbk13data.y[*,*,1]), v: v13},dlimits={spec: 1, data_att: default_data_att}
       store_data,fbknewname+'_fb2_av',data={x: fbk13data.x, $
          y:reform(fbk13data.y[*,*,2]), v: v13},dlimits={spec: 1, data_att: default_data_att}
       store_data,fbknewname+'_fb2_pk',data={x: fbk13data.x, $
          y:reform(fbk13data.y[*,*,3]), v: v13},dlimits={spec: 1, data_att: default_data_att}
                 
       pn = byte(p_var[s]) - byte('a')
 ;      options, /def, tns, colors = probe_colors[pn]       

       dprint, dlevel = 5, verbose = verbose, 'Setting options...'

       options, /def, tns, code_id = '$Id: rbsp_load_efw_fbk.pro 18070 2015-07-10 14:53:49Z aaronbreneman $'
  
       dprint, dwait = 5., verbose = verbose, 'Flushing output'
       dprint, dlevel = 4, verbose = verbose, 'Filterbank 13 data Loaded for probe: '+p_var[s]

;calibrate data
       if ~strcmp(type, 'raw', /fold) then begin
         rbsp_efw_cal_fbk, probe = p_var[s], $
           datatype = datatype, trange = trange, pT=pT
       endif


       if not keyword_set(get_support_data) then begin
          for i = 0, n_elements(tns) - 1 do begin
             if strfilter(tns[i],'*'+support_data_keep) eq '' then begin
                get_data,tns[i],dlimits=thisdlimits
                cdf_str = 0
                str_element,thisdlimits,'cdf',cdf_str
                if keyword_set(cdf_str) then if cdf_str.vatt.var_type eq 'support_data' then $
                   store_data,tns[i],/delete
             endif
          endfor
       endif
       
     endif else begin
       dprint, dlevel = 0, verbose = verbose, 'No EFW FBK 13 data loaded...'+' Probe: '+p_var[s]
;       dprint, dlevel = 0, verbose = verbose, 'Try using get_support_data keyword'
     endelse


endfor

end
