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
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-27 11:26:29 -0700 (Mon, 27 Apr 2015) $
; $LastChangedRevision: 17433 $
; $URL $
;-
pro thm_load_state2,probes=probes, datatype=datatype, trange=trange, $
                   varformat=varformat, var_type=var_type, $
                   level=level, verbose=verbose, downloadonly=downloadonly, $
                   cdf_data=cdf_data,get_support_data=get_support_data, $
                   varnames=varnames, make_multi_tplotvar=make_multi_tplotvar, $
                   valid_names = valid_names, files=files, $
                   polar=polar,  $
                   suffix=suffix, $
                   coords = coords,  $
                   source_options = source_options, $
                   version=version, $
                   progobj=progobj

dprint,verbose=verbose,dlevel=4,'$Id: thm_load_state2.pro 17433 2015-04-27 18:26:29Z aaflores $'
if not keyword_set(coords) then coords = 'gse'
r_e = 6371.2  ;mean radius of earth in km

if not keyword_set(source_options) then begin
   thm_init
   source_options = !themis
endif

_version = ''
;if n_elements(version) eq 0 then version='v0?'   ; Delete this line after unversioned files appear in production area.
if  keyword_set(version) then _version='_'+version     ;   acceptable values: 'v00', 'v01', 'v02', 'v03', or  'v0?'  ('v0?' will retrieve highest version #)

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

;probe_colors = ['m','b','c','g','r','y']

for s=0,nprobes-1 do begin
     probe = probes_a[s]
     thx = 'th'+ probe

;     relpathnames = file_dailynames(thx+'/l1/hsk/',dir='YYYY/',thx+'_l1_hsk_','_v01.cdf',trange=trange,addmaster=addmaster)
     format = thx+'/'+lvl+'/state/YYYY/'+thx+'_'+lvl+'_state_YYYYMMDD'+_version+'.cdf'
     relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)
;     if vb ge 4 then printdat,/pgmtrace,relpathnames
     dprint,dlevel=4,verbose=verbose,relpathnames,/phelp
     files = spd_download(remote_file=relpathnames, _extra=source_options, /last_version, $
                           progobj = progobj)

     if keyword_set(downloadonly) then continue

     midfix='_state'
;     if 1 then begin
     cdf2tplot,file=files,varformat=varformat,all=0,midfix=midfix,midpos=3,verbose=vb, suffix=suffix,$
              get_support_data=get_support_data,tplotnames=tns,/convert_int1_to_int2 ; load data into tplot variables
;     endif else begin
;if not keyword_set(varformat) then var_type = 'data'
;if keyword_set(get_support_data) then var_type = ['data','support_data']
;cdfi = cdf_load_vars(files,varformat=varformat,var_type=var_type,/spdf_depend, $
;     varnames=varnames2,verbose=verbose,record=record, convert_int1_to_int2=convert_int1_to_int2)
;cdf_info_to_tplot,cdfi,varnames2,all=all,prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix, $  ;bpif keyword_set(all) eq 0
;       verbose=verbose,  tplotnames=tplotnames
;
;dprint,dlevel=5,verbose=verbose,'Starting Clean up' ;bpif keyword_set(all) eq 0
;tplot_ptrs = ptr_extract(tnames(/dataquant))
;unused_ptrs = ptr_extract(cdfi,except=tplot_ptrs)
;ptr_free,unused_ptrs
;     endelse

;     options,/def,strfilter(
wait,0  ;bp

     pn = byte(probe) - byte('a')
     dprint,dlevel=4,'Setting options...'
;     r_e=1
;     if keyword_set(r_e) then begin
;        get_data,thx+midfix+'_pos',data=d
;        if keyword_set(d) then begin
;           d.y = d.y/ r_e
;           store_data,thx+midfix+'_pos_Re',data=d
;        endif
;     endif
;     endif

     if keyword_set(polar) then begin
        xyz_to_polar,thx+midfix+'_pos'
        get_data,thx+midfix+'_pos_mag',data=d
        if keyword_set(d) then begin
           d.y = d.y/ r_e
           store_data,thx+midfix+'_pos_Re',data=d
        endif
        thm_setprobe_colors, thx+midfix+'_pos_*'
     endif
     thm_setprobe_colors, tns,/def

     options,/def,tns,code_id='$Id: thm_load_state2.pro 17433 2015-04-27 18:26:29Z aaflores $'
;     options,/default,tns,colors = probe_colors[pn]

     dprint,dlevel=4,'Housekeeping data Loaded for probe: '+probe

     roi_labels = strsplit(/extract,'ES LS AAZ SAA NAZ SAZ PP RB DPS FSW SWB HMF APS BS MP GBO 2DC 4DC')
     options,strfilter(tns,'th?_state_roi'),/def,tplot_routine='bitplot',colors='rbgmc',labels=roi_labels,yrange=[-1,19],/ystyle

     posvelnames = strfilter(tns,['th?_state_vel', 'th?_state_pos'],count=n)
     for i=0,n-1 do begin
        nam = posvelnames[i]
        options,nam,/def,colors='bgr'
        options,nam,/def,'data_att.coord_sys','gei'
        get_data,nam ,data=d,alim=lim
        d.y /= r_e
        str_element,lim,'data_att.units','Re',/add
        store_data,nam+'_Re',data=d,dlim=lim
        thm_cotrans,nam+'_Re',out_suffix='_'+coords
     endfor


endfor

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


; get separation distances:
; prb = strsplit(/extract,'a b c d e')
; for i=0,4 do for j=i+1,4 do dif_data,'th'+prb[i]+'_state_pos_Re_gse', 'th'+prb[j]+'_state_pos_Re_gse',newname='th'+prb[i]+'-th'+prb[j]
