;Procedure: RBSP_LOAD_EFW_B1
;
;Purpose:  Loads RBSP EFW Burst 1 Selection Data
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
;  /INTEGRATION: If set, load burst data from the integration burst data
;            map rather than the burst map derived from the standard
;            MOC interface.
;  /DOWNLOADONLY: download file but don't read it. (NOT IMPLEMENTED YET)
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  type:  set to 'calibrated' to automatically convert data into physical units
;Example:
;   rbsp_load_efw_b1,probe=['a', 'b']
;Notes:
; 1. Written by Peter Schroeder, February 2012
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2012-10-17 12:51:35 -0700 (Wed, 17 Oct 2012) $
; $LastChangedRevision: 11031 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_load_efw_b1.pro $
;-

pro rbsp_load_efw_b1,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,integration=integration, $
                 tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                 varformat=varformat, valid_names = valid_names, files=files,$
                 type=type

rbsp_efw_init
dprint,verbose=verbose,dlevel=4,'$Id: rbsp_load_efw_b1.pro 11031 2012-10-17 19:51:35Z jimm $'

if(keyword_set(probe)) then $
  p_var = probe

vb = keyword_set(verbose) ? verbose : 0
vb = vb > !rbsp_efw.verbose

vprobes = ['a','b']
vlevels = ['l1','l2']
vdatatypes=['b1s']

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

     if keyword_set(integration) then $
        format = 'burst_selection/int/'+rbspx+'_b1_fmt.cdf' else $
        format = 'burst_selection/'+rbspx+'_b1_fmt.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
;     if vb ge 4 then printdat,/pgmtrace,relpathnames
     dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
     files = file_retrieve(relpathnames, _extra=!rbsp_efw)

     if keyword_set(!rbsp_efw.downloadonly) or keyword_set(downloadonly) then continue

;     suf='_raw'
     suf=''
;     midfix='_hsk_beb_analog_'
     prefix=rbspx+'_efw_b1_fmt_'
     
     data = cdf_load_vars(files[0],varformat='*')
     for i = 0, data.nv - 1 do begin
        if data.vars[i].name eq 'MET' then timedata = time_double(/epoch, *(data.vars[i].dataptr))
        if data.vars[i].name eq 'BBI' then bbidata = *(data.vars[i].dataptr)
        if data.vars[i].name eq 'ECI' then ecidata = *(data.vars[i].dataptr)
     endfor
     
     sortindex = sort(timedata)
     
     store_data,prefix+'block_index', data = {x: timedata[sortindex], y: sortindex}
     if keyword_set(bbidata) then begin
        store_data, prefix+'BBI', data = {x: timedata[sortindex], y: bbidata[sortindex]}
        badbbi = where(bbidata[sortindex] eq 0 or bbidata[sortindex] eq 3, badbbinumber)
        b1indicator = bytarr(n_elements(sortindex)) + 1b
        if badbbinumber ne 0 then b1indicator[badbbi] = 0
        store_data, prefix+'B1_available', data = {x: timedata[sortindex], y: b1indicator}
        ylim, prefix+'B1_available',0,2
        options,prefix+'B1_available','psym',4
     endif
     if keyword_set(ecidata) then store_data, prefix+'ECI', data = {x: timedata[sortindex], y: ecidata[sortindex]}


endfor

end
