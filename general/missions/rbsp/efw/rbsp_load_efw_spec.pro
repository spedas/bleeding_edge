;+
;Procedure: RBSP_LOAD_EFW_SPEC
;
;Purpose:  Loads RBSP EFW SPEC data
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
;  /QA: If set, load data from 11_qa testing directory.
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
;   rbsp_load_efw_spec,/get_support_data,probe=['a', 'b']
;Notes:
; 1. Written by Peter Schroeder, February 2012
;
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2015-07-10 07:53:08 -0700 (Fri, 10 Jul 2015) $
; $LastChangedRevision: 18068 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_load_efw_spec.pro $
;-

pro rbsp_load_efw_spec,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                 varformat=varformat, valid_names = valid_names, files=files,$
                 type=type, integration=integration, msim=msim, etu=etu, qa=qa,$
                 pT=pT

rbsp_efw_init
dprint,verbose=verbose,dlevel=4,'$Id: rbsp_load_efw_spec.pro 18068 2015-07-10 14:53:08Z aaronbreneman $'

if keyword_set(etu) then probe = 'a'

if(keyword_set(probe)) then $
  p_var = strlowcase(probe)

vb = keyword_set(verbose) ? verbose : 0
vb = vb > !rbsp_efw.verbose
 
vprobes = ['a','b']
vlevels = ['l1','l2']
vdatatypes=['spec']
;default_data_att = {units: 'ADC', coord_sys: 'uvw', st_type: 'none'}
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

     format = rbsppref + '/spec/YYYY/'+rbspx+'_l1_spec_32_YYYYMMDD_v*.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
;     if vb ge 4 then printdat,/pgmtrace,relpathnames
     dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
     files = file_retrieve(relpathnames, /last_version, _extra=!rbsp_efw)

     if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue

;     suf='_raw'
     suf=''
;     midfix='_hsk_beb_analog_'
     prefix=rbspx+'_efw_spec_32_'

;     if keyword_set(get_support_data) then $
          cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
              tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables

     if is_string(tns) then begin
     
       specname = rbspx+'_efw_spec_32_spec_32'
       
       get_data,specname,data=specdata
       
       for i = 0,6 do begin
         specnewname = rbspx+'_efw_32_spec'+strcompress(i,/rem)
         store_data,specnewname,data={x: specdata.x, y: reform(specdata.y[*,*,i]), v: specdata.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
       endfor
       
         
;       pn = byte(p_var[s]) - byte('a')
;       options, /def, tns, colors = probe_colors[pn]       

       dprint, dlevel = 5, verbose = verbose, 'Setting options...'

       options, /def, tns, code_id = '$Id: rbsp_load_efw_spec.pro 18068 2015-07-10 14:53:08Z aaronbreneman $'
  
       dprint, dwait = 5., verbose = verbose, 'Flushing output'
       dprint, dlevel = 4, verbose = verbose, 'SPEC 32 data Loaded for probe: '+p_var[s]

;calibration data
       if ~strcmp(type, 'raw', /fold) then begin
         rbsp_efw_cal_spec, probe = p_var[s], $
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
       dprint, dlevel = 0, verbose = verbose, 'No EFW SPEC 32 data loaded...'+' Probe: '+p_var[s]
;       dprint, dlevel = 0, verbose = verbose, 'Try using get_support_data keyword'
     endelse

     format = rbsppref + '/spec/YYYY/'+rbspx+'_l1_spec_64_YYYYMMDD_v*.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
;     if vb ge 4 then printdat,/pgmtrace,relpathnames
     dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
     files = file_retrieve(relpathnames, /last_version, _extra=!rbsp_efw)

     if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue

;     suf='_raw'
     suf=''
;     midfix='_hsk_beb_analog_'
     prefix=rbspx+'_efw_spec_64_'

;     if keyword_set(get_support_data) then $
          cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
              tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables

     if is_string(tns) then begin

       specname = rbspx+'_efw_spec_64_spec_64'
       
       get_data,specname,data=specdata
       
       for i = 0,6 do begin
         specnewname = rbspx+'_efw_64_spec'+strcompress(i,/rem)
         store_data,specnewname,data={x: specdata.x, y: reform(specdata.y[*,*,i]), v: specdata.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
       endfor
     
;       pn = byte(p_var[s]) - byte('a')
;       options, /def, tns, colors = probe_colors[pn]       

       dprint, dlevel = 5, verbose = verbose, 'Setting options...'

       options, /def, tns, code_id = '$Id: rbsp_load_efw_spec.pro 18068 2015-07-10 14:53:08Z aaronbreneman $'
  
       dprint, dwait = 5., verbose = verbose, 'Flushing output'
       dprint, dlevel = 4, verbose = verbose, 'SPEC 64 data Loaded for probe: '+p_var[s]

;calibration data
       if ~strcmp(type, 'raw', /fold) then begin
         rbsp_efw_cal_spec, probe = p_var[s], $
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
       dprint, dlevel = 0, verbose = verbose, 'No EFW SPEC 64 data loaded...'+' Probe: '+p_var[s]
;       dprint, dlevel = 0, verbose = verbose, 'Try using get_support_data keyword'
     endelse

     format = rbsppref + '/spec/YYYY/'+rbspx+'_l1_spec_112_YYYYMMDD_v*.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
;     if vb ge 4 then printdat,/pgmtrace,relpathnames
     dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
     files = file_retrieve(relpathnames, /last_version, _extra=!rbsp_efw)

     if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue

;     suf='_raw'
     suf=''
;     midfix='_hsk_beb_analog_'
     prefix=rbspx+'_efw_spec_112_'

;     if keyword_set(get_support_data) then $
          cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
              tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables

     if is_string(tns) then begin
 
       specname = rbspx+'_efw_spec_112_spec_112'
       
       get_data,specname,data=specdata
       
       for i = 0,6 do begin
         specnewname = rbspx+'_efw_112_spec'+strcompress(i,/rem)
         store_data,specnewname,data={x: specdata.x, y: reform(specdata.y[*,*,i]), v: specdata.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
       endfor
     
       pn = byte(p_var[s]) - byte('a')
       options, /def, tns, colors = probe_colors[pn]       

       dprint, dlevel = 5, verbose = verbose, 'Setting options...'

       options, /def, tns, code_id = '$Id: rbsp_load_efw_spec.pro 18068 2015-07-10 14:53:08Z aaronbreneman $'
  
       dprint, dwait = 5., verbose = verbose, 'Flushing output'
       dprint, dlevel = 4, verbose = verbose, 'SPEC 112 data Loaded for probe: '+p_var[s]

;calibration data
       if ~strcmp(type, 'raw', /fold) then begin
         rbsp_efw_cal_spec, probe = p_var[s], $
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
       dprint, dlevel = 0, verbose = verbose, 'No EFW SPEC 112 data loaded...'+' Probe: '+p_var[s]
;       dprint, dlevel = 0, verbose = verbose, 'Try using get_support_data keyword'
     endelse

endfor

end
