;+
;Procedure: RBSP_LOAD_EFW_XSPEC
;
;Purpose:  Loads RBSP EFW XSPEC data
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
;  /QA: If set, load data from l1_qa testing directory.
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
;   rbsp_load_efw_xspec,/get_suppport_data,probe=['a', 'b']
;Notes:
; 1. Written by Peter Schroeder, February 2012
;
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2018-12-17 14:50:55 -0800 (Mon, 17 Dec 2018) $
; $LastChangedRevision: 26347 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_load_efw_xspec.pro $
;-

pro rbsp_load_efw_xspec,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                 varformat=varformat, valid_names = valid_names, files=files,$
                 type=type, integration=integration, msim=msim, etu=etu, qa=qa

rbsp_efw_init
dprint,verbose=verbose,dlevel=4,'$Id: rbsp_load_efw_xspec.pro 26347 2018-12-17 22:50:55Z aaronbreneman $'

if keyword_set(etu) then probe = 'a'

if keyword_set(probe) then p_var = probe

vb = keyword_set(verbose) ? verbose : 0
vb = vb > !rbsp_efw.verbose

vprobes = ['a','b']
vlevels = ['l1','l2']
vdatatypes=['xspec']
default_data_att = {units: 'ADC', coord_sys: 'uvw', st_type: 'none'}
support_data_keep = ['BEB_config','DFB_config']

if ~keyword_set(type) then type = 'calibrated'

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

     ;----------------------------------------------------------------
     ;Find out what xspec 32 files are online
     format = rbsppref + '/xspec/YYYY/'+rbspx+'_l1_xspec_32_YYYYMMDD_v*.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)

     ;...and load them
     file_loaded = []
      for ff=0, n_elements(relpathnames)-1 do begin
          undefine,lf
          localpath = file_dirname(relpathnames[ff])+'/'
          locpath = !rbsp_efw.local_data_dir+localpath
          remfile = !rbsp_efw.remote_data_dir+relpathnames[ff]
          tmp = spd_download(remote_file=remfile, local_path=locpath, local_file=lf,/last_version)
          locfile = locpath+lf
          if file_test(locfile) eq 0 then locfile = file_search(locfile)
          if locfile[0] ne '' then file_loaded = [file_loaded,locfile]
      endfor

    if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue
    suf=''
    prefix=rbspx+'_efw_xspec_32_'
    cdf2tplot,file=file_loaded,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
         tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables


     if is_string(tns) then begin

       xspecname = rbspx+'_efw_xspec_32_xspec_32'

       get_data,xspecname+'_src1',data=src1data
       get_data,xspecname+'_src2',data=src2data
       get_data,xspecname+'_rc',data=rcdata
       get_data,xspecname+'_ic',data=icdata

       for i = 0,3 do begin
         specnewname = rbspx+'_efw_xspec_32_xspec'+strcompress(i,/rem)
         store_data,specnewname+'_src1',data={x: src1data.x, $
           y: reform(src1data.y[*,*,i]), v: src1data.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
         store_data,specnewname+'_src2',data={x: src2data.x, $
           y: reform(src2data.y[*,*,i]), v: src2data.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
         store_data,specnewname+'_rc',data={x: rcdata.x, $
           y: reform(rcdata.y[*,*,i]), v: rcdata.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
         store_data,specnewname+'_ic',data={x: icdata.x, $
           y: reform(icdata.y[*,*,i]), v: icdata.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
       endfor

       store_data,xspecname+'_src1',/delete
       store_data,xspecname+'_src2',/delete
       store_data,xspecname+'_rc',/delete
       store_data,xspecname+'_ic',/delete

       dprint, dlevel = 5, verbose = verbose, 'Setting options...'
       options, /def, tns, code_id = '$Id: rbsp_load_efw_xspec.pro 26347 2018-12-17 22:50:55Z aaronbreneman $'
       dprint, dwait = 5., verbose = verbose, 'Flushing output'
       dprint, dlevel = 4, verbose = verbose, 'XSPEC 32 data Loaded for probe: '+p_var[s]

       ;calibrate data
       if ~strcmp(type, 'raw', /fold) then begin
         rbsp_efw_cal_xspec, probe = p_var[s], $
           datatype = datatype, trange = trange
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

     endif else dprint, dlevel = 0, verbose = verbose, 'No EFW XSPEC 32 data loaded...'+' Probe: '+p_var[s]

     ;----------------------------------------------------------------
     ;Find out what xspec 64 files are online
     format = rbsppref + '/xspec/YYYY/'+rbspx+'_l1_xspec_64_YYYYMMDD_v*.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)

     ;...and load them
     file_loaded = []
      for ff=0, n_elements(relpathnames)-1 do begin
          undefine,lf
          localpath = file_dirname(relpathnames[ff])+'/'
          locpath = !rbsp_efw.local_data_dir+localpath
          remfile = !rbsp_efw.remote_data_dir+relpathnames[ff]
          tmp = spd_download(remote_file=remfile, local_path=locpath, local_file=lf,/last_version)
          locfile = locpath+lf
          if file_test(locfile) eq 0 then locfile = file_search(locfile)
          if locfile[0] ne '' then file_loaded = [file_loaded,locfile]
      endfor

    if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue
    suf=''
    prefix=rbspx+'_efw_xspec_64_'
    cdf2tplot,file=file_loaded,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
         tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables

     if is_string(tns) then begin

       xspecname = rbspx+'_efw_xspec_64_xspec_64'

       get_data,xspecname+'_src1',data=src1data
       get_data,xspecname+'_src2',data=src2data
       get_data,xspecname+'_rc',data=rcdata
       get_data,xspecname+'_ic',data=icdata

       for i = 0,3 do begin
         specnewname = rbspx+'_efw_xspec_64_xspec'+strcompress(i,/rem)
         store_data,specnewname+'_src1',data={x: src1data.x, $
           y: reform(src1data.y[*,*,i]), v: src1data.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
         store_data,specnewname+'_src2',data={x: src2data.x, $
           y: reform(src2data.y[*,*,i]), v: src2data.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
         store_data,specnewname+'_rc',data={x: rcdata.x, $
           y: reform(rcdata.y[*,*,i]), v: rcdata.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
         store_data,specnewname+'_ic',data={x: icdata.x, $
           y: reform(icdata.y[*,*,i]), v: icdata.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
       endfor

       store_data,xspecname+'_src1',/delete
       store_data,xspecname+'_src2',/delete
       store_data,xspecname+'_rc',/delete
       store_data,xspecname+'_ic',/delete


       dprint, dlevel = 5, verbose = verbose, 'Setting options...'
       options, /def, tns, code_id = '$Id: rbsp_load_efw_xspec.pro 26347 2018-12-17 22:50:55Z aaronbreneman $'
       dprint, dwait = 5., verbose = verbose, 'Flushing output'
       dprint, dlevel = 4, verbose = verbose, 'XSPEC 64 data Loaded for probe: '+p_var[s]

       ;calibrate data
       if ~strcmp(type, 'raw', /fold) then begin
         rbsp_efw_cal_xspec, probe = p_var[s], $
           datatype = datatype, trange = trange
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

     endif else dprint, dlevel = 0, verbose = verbose, 'No EFW XSPEC 64 data loaded...'+' Probe: '+p_var[s]


     ;----------------------------------------------------------------
     ;find out what xspec 112 files are online
     format = rbsppref + '/xspec/YYYY/'+rbspx+'_l1_xspec_112_YYYYMMDD_v*.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)

     ;...and load them
     file_loaded = []
      for ff=0, n_elements(relpathnames)-1 do begin
          undefine,lf
          localpath = file_dirname(relpathnames[ff])+'/'
          locpath = !rbsp_efw.local_data_dir+localpath
          remfile = !rbsp_efw.remote_data_dir+relpathnames[ff]
          tmp = spd_download(remote_file=remfile, local_path=locpath, local_file=lf,/last_version)
          locfile = locpath+lf
          if file_test(locfile) eq 0 then locfile = file_search(locfile)
          if locfile[0] ne '' then file_loaded = [file_loaded,locfile]
      endfor

    if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue
    suf=''
    prefix=rbspx+'_efw_xspec_112_'
    cdf2tplot,file=file_loaded,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
         tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables


     if is_string(tns) then begin

        xspecname = rbspx+'_efw_xspec_112_xspec_112'

       get_data,xspecname+'_src1',data=src1data
       get_data,xspecname+'_src2',data=src2data
       get_data,xspecname+'_rc',data=rcdata
       get_data,xspecname+'_ic',data=icdata

       for i = 0,3 do begin

         xspecnewname = rbspx+'_efw_xspec_112_xspec'+strcompress(i,/rem)
         store_data,xspecnewname+'_src1',data={x: src1data.x, $
           y: reform(src1data.y[*,*,i]), v: src1data.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
         store_data,xspecnewname+'_src2',data={x: src2data.x, $
           y: reform(src2data.y[*,*,i]), v: src2data.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
         store_data,xspecnewname+'_rc',data={x: rcdata.x, $
           y: reform(rcdata.y[*,*,i]), v: rcdata.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
         store_data,xspecnewname+'_ic',data={x: icdata.x, $
           y: reform(icdata.y[*,*,i]), v: icdata.v2}, $
           dlimits = {spec: 1, data_att: default_data_att}
       endfor

       store_data,xspecname+'_src1',/delete
       store_data,xspecname+'_src2',/delete
       store_data,xspecname+'_rc',/delete
       store_data,xspecname+'_ic',/delete

       pn = byte(p_var[s]) - byte('a')
       options, /def, tns, colors = probe_colors[pn]

       dprint, dlevel = 5, verbose = verbose, 'Setting options...'

       options, /def, tns, code_id = '$Id: rbsp_load_efw_xspec.pro 26347 2018-12-17 22:50:55Z aaronbreneman $'

       dprint, dwait = 5., verbose = verbose, 'Flushing output'
       dprint, dlevel = 4, verbose = verbose, 'XSPEC 112 data Loaded for probe: '+p_var[s]

       ;calibrate data
       if ~strcmp(type, 'raw', /fold) then begin
         rbsp_efw_cal_xspec, probe = p_var[s], $
           datatype = datatype, trange = trange
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

     endif else dprint, dlevel = 0, verbose = verbose, 'No EFW XSPEC 112 data loaded...'+' Probe: '+p_var[s]

endfor
end
