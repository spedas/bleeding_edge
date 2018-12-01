;Procedure: RBSP_LOAD_EFW_HSK_IDPU_EVENTS
;
;Purpose:  Loads RBSP EFW Housekeeping data - IDPU EVENTS ONLY.
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
;  /QA: If set, load data from l1_qa testing directory.
;  /INTEGRATION: If set, load data from integration.
;  /MSIM: If set, load data from mission simulations.
;  /ETU: If set, load data from the ETU.
;  /DOWNLOADONLY: download file but don't read it. (NOT IMPLEMENTED YET)
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  type:  set to 'calibrated' to automatically convert data into physical units
;Example:
;   rbsp_load_efw_hsk_idpu_events,/get_support_data,probe=['a', 'b']
;Notes:
; 0. Kludged by John Bonnell from RBSP_LOAD_EFW_HSK, v. 2012-11-07 (rev 11201).
; 1. Written by Peter Schroeder, July 2011
; 2. Fixed the verbose keyword so that it now actually has the intended effects.
;    JBT, SSL/UCB, 2012-11-03.
;
; $LastChangedBy: peters $
; $LastChangedDate: 2012-11-07 14:58:26 -0800 (Wed, 07 Nov 2012) $
; $LastChangedRevision: 11201 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/missions/rbsp/efw/rbsp_load_efw_hsk.pro $
;-

pro rbsp_load_efw_hsk_idpu_events,$
				probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                 varformat=varformat, valid_names = valid_names, files=files,$
                 type=type, integration=integration, msim=msim, etu=etu, qa=qa

rbsp_efw_init
dprint,verbose=verbose,dlevel=4,'$Id: rbsp_load_efw_hsk.pro 11201 2012-11-07 22:58:26Z peters $'

if keyword_set(etu) then probe = 'a'

if(keyword_set(probe)) then $
  p_var = probe

if n_elements(verbose) gt 0 then vb = verbose else begin
  vb = 0
  vb >= !rbsp_efw.verbose
endelse

vprobes = ['a','b']
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

probe_colors = ['m','b']

for s=0,n_elements(p_var)-1 do begin
     rbspx = 'rbsp'+ p_var[s]
     if keyword_set(integration) then rbsppref = rbspx + '/l1_int' $
        else if keyword_set(msim) then rbsppref = rbspx+ '/l1_msim' $
        else if keyword_set(etu) then rbsppref = rbspx+ '/l1_etu' $
        else if keyword_set(qa) then rbsppref = rbspx+ '/l1_qa' $
        else rbsppref = rbspx + '/l1'



	; IDPU EVENTS.
     format = rbsppref + '/hsk_idpu_events/YYYY/'+rbspx+'_l1_hsk_idpu_events_YYYYMMDD_v*.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)


     ;extract the local data path without the filename
     localgoo = strsplit(relpathnames,'/',/extract)
     for i=0,n_elements(localgoo)-2 do $
        if i eq 0. then localpath = localgoo[i] else localpath = localpath + '/' + localgoo[i]
     localpath = strtrim(localpath,2) + '/'

     undefine,lf,tns
     dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
     file_loaded = spd_download(remote_file=!rbsp_efw.remote_data_dir+relpathnames,$
        local_path=!rbsp_efw.local_data_dir+localpath,$
        local_file=lf,/last_version)
     files = !rbsp_efw.local_data_dir + localpath + lf



     if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue

     suf=''
     prefix=rbspx+'_efw_hsk_idpu_events_'
		 tst = file_info(file_loaded)

     if tst.exists then cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
              tplotnames=tns,/convert_int1_to_int2,get_support_data=get_support_data ; load data into tplot variables

     if is_string(tns) then begin

       pn = byte(p_var[s]) - byte('a')
       options, /def, tns, colors = probe_colors[pn]

       dprint, dlevel = 5, verbose = verbose, 'Setting options...'

       options, /def, tns, code_id = '$Id: rbsp_load_efw_hsk.pro 11201 2012-11-07 22:58:26Z peters $'

       c_var = [1, 2, 3, 4, 5, 6]

       dprint, dwait = 5., verbose = verbose, 'Flushing output'
       dprint, dlevel = 4, verbose = verbose, 'Housekeeping data Loaded for probe: '+p_var[s]

     endif else begin
       dprint, dlevel = 0, verbose = verbose, 'No EFW HSK IDPU Events data loaded...'+' Probe: '+p_var[s]
     endelse


    if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue


endfor

end
