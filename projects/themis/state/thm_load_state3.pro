;+
;Procedure: THM_LOAD_STATE2
;
;Purpose:  Loads THEMIS STATE (orbit and attitude) data
;
;;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, can be an array of strings
;          or single string separate by spaces.  The default is 'all'
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  version = the version of the state file, one of 'v01', 'v02', 'v03', 'v04'.
;            defaults to 'v01'
;  level = the level of the data, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;Example:
;   thm_load_state
;Notes:
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-01-05 17:01:57 -0800 (Mon, 05 Jan 2015) $
; $LastChangedRevision: 16596 $
; $URL $
;-
pro thm_load_state3,probes=probes, datatype=datatype, trange=trange, $
                   varformat=varformat, var_type=var_type, $
                   level=level, verbose=verbose, downloadonly=downloadonly, $
                   cdf_data=cdf_data,get_support_data=get_support_data, $
                   varnames=varnames, make_multi_tplotvar=make_multi_tplotvar, $
                   valid_names = valid_names, files=files, $
                   polar=polar,  $
                   suffix=suffix, $
                   version=version, $
                   progobj=progobj

thm_init
dprint,verbose=verbose,dlevel=4,'$Id: thm_load_state3.pro 16596 2015-01-06 01:01:57Z pcruce $'

if not keyword_set(version) then version= ['v02', 'v01', 'v00']

vb = keyword_set(verbose) ? verbose : 0
vb = vb > !themis.verbose

vprobes = ['a','b','c','d','e']  ;,'f']
vlevels = ['l1'] ;,'l2']
vdatatypes=['state']

if keyword_set(valid_names) then begin
    probe = vprobes
    level = vlevels
    datatype = datatypes
    return
endif


;probe = strfilter(vprobes, probe ,delimiter=' ',/string)
probes_a       = strfilter(vprobes,size(/type,probes) eq 7 ? probes : '*',/fold_case,delimiter=' ',count=nprobes)

if not keyword_set(datatype) then datatype='*'
datatype = strfilter(vdatatypes, datatype ,delimiter=' ',/string)

if not keyword_set(level) then level='l1'
lvl = strfilter(vlevels, level ,delimiter=' ',/string)

addmaster=0

probe_colors = ['m','b','c','g','r','y']

for s=0,nprobes-1 do begin
     probe = probes_a[s]
     thx = 'th'+ probe

;     relpathnames = file_dailynames(thx+'/l1/hsk/',dir='YYYY/',thx+'_l1_hsk_','_v01.cdf',trange=trange,addmaster=addmaster)
     format = thx+'/'+lvl+'/state/YYYY/'+thx+'_'+lvl+'_state_YYYYMMDD_'+version[0]+'.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
;     if vb ge 4 then printdat,/pgmtrace,relpathnames
     dprint,dlevel=4,verbose=verbose,relpathnames,/phelp

     files = file_retrieve_v(relpathnames, _extra=!themis, version=version, $
                           progobj = progobj)

     if keyword_set(downloadonly) then continue

     midfix='_state'
     cdf2tplot,file=files,varformat=varformat,all=0,midfix=midfix,midpos=3,verbose=vb,suffix=suffix, $
              get_support_data=get_support_data,tplotnames=tns,/convert_int1_to_int2 ; load data into tplot variables

     pn = byte(probe) - byte('a')
     dprint,dlevel=4,'Setting options...'
     if keyword_set(polar) then begin
        xyz_to_polar,thx+midfix+'_pos'
        get_data,thx+midfix+'_pos_mag',data=d
        if keyword_set(d) then begin
           d.y = d.y/ 6371.2 ;mean earth radius
           store_data,thx+midfix+'_pos_Re',data=d
        endif
        thm_setprobe_colors, thx+midfix+'_pos_*'
     endif
     thm_setprobe_colors, tns

     options,/default,tns,code_id='$Id: thm_load_state3.pro 16596 2015-01-06 01:01:57Z pcruce $'
;     options,/default,tns,colors = probe_colors[pn]

     dprint,dwait=5.,'Flushing output'
     dprint,dlevel=4,'Housekeeping data Loaded for probe: '+probe

endfor

options,'th?_state_roi',tplot_routine='bitplot'

if keyword_set(make_multi_tplotvar) then begin
    tns = tnames('th?_state_*')
    tns_suf = strmid(tns,10)
    tns_suf = tns_suf[uniq(tns_suf,sort(tns_suf))]
    for i=0,n_elements(tns_suf)-1 do store_data,'Thx_state_'+tns_suf[i],data=tnames('th?_state_'+tns_suf[i])
;    store_data,'Thx_state_pos_Re',data=tnames('th?_state_pos_Re')
;    store_data,'Thx_state_pos_th',data=tnames('th?_state_pos_th')
;    store_data,'Thx_state_pos_phi',data=tnames('th?_state_pos_phi')
endif

end
