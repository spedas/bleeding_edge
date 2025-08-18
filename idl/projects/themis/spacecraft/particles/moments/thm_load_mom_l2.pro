;+
;Procedure: THM_LOAD_MOM_l2
;
;Purpose:  Loads THEMIS Level 2 moments data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, for this case, there is only
;          one option, the default value of 'fgm', so this is a
;          placeholder should there be more that one data type. 'all'
;          can be passed in also, to get all variables.
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  /DOWNLOADONLY: download file but don't read it.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named variable for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  /NO_TIME_CLIP: Disables time clipping, which is the default
;Example:
;   thm_load_mom,/get_suppport_data,probe=['a', 'b']
;Notes:
;  Temporary version, to avoid conflicts, but can read Level 2 data, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-04-22 14:24:42 -0700 (Mon, 22 Apr 2019) $
; $LastChangedRevision: 27056 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/moments/thm_load_mom_l2.pro $
;-
pro thm_load_mom_l2, probe = probe, datatype = datatype, trange = trange, $
                     level = level, verbose = verbose, downloadonly = downloadonly, $
                     valid_names = valid_names, source_options = source, progobj = progobj,$
                     raw = raw, files = files, suffix = suffix, no_time_clip = no_time_clip

thm_init

vprobes = ['a','b','c','d','e']
vlevels = ['l1','l2']
deflevel = 'l2'
lvl = thm_valid_input(level,'Level',vinputs=strjoin(vlevels, ' '), $
                      definput=deflevel, format="('l', I1)", verbose=0)
if lvl eq 'l1' then begin
  if keyword_set(raw) then vdatatypes = thm_data2load('mom', 'l10') $
  else vdatatypes = thm_data2load('mom', 'l1')
endif 
if lvl eq 'l2' then begin
  vdatatypes = thm_data2load('mom', 'l2')
endif
if keyword_set(valid_names) then begin
  probe = vprobes
  dprint, string(strjoin(probe, ','), $
                         format = '( "Valid probes:",X,A,".")')
  datatype = vdatatypes
  dprint, string(strjoin(datatype, ','), $
                         format = '( "Valid '+lvl+' datatypes:",X,A,".")')
  level = vlevels
  dprint, string(strjoin(level, ','), format = '( "Valid levels:",X,A,".")')
  return
endif

if n_elements(probe) eq 1 then if probe eq 'f' then vprobes=[vprobes,'f']

if not keyword_set(probe) then probe=vprobes
probes = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all, $
                              invalid=msg_probe, type='probe')

if not keyword_set(datatype) then datatype = vdatatypes else begin
  if n_elements(datatype) Eq 1 and datatype[0] eq 'mom' then datatype = vdatatypes
endelse

datatype = ssl_check_valid_name(strlowcase(datatype), vdatatypes, /include_all, /loose, $
                                invalid=msg_dt, type='data type')

if not keyword_set(source) then source = !themis

lvl = 'l2'                      ;now Level is set to 2

addmaster=0

if arg_present(files) then begin ; needed because a variable of the name files is used internally
  file_list_flag = 1
endif else begin
  file_list_flag = 0
endelse

for s = 0, n_elements(probes)-1 do begin
  thx = 'th'+ probes[s]
  
  pathformat = thx+'/'+lvl+'/mom/YYYY/'+thx+'_'+lvl+'_mom_YYYYMMDD_v01.cdf'
  dprint, dlevel = 3, 'pathformat: ', pathformat

  relpathnames = file_dailynames(file_format = pathformat, trange = trange, addmaster = addmaster)
  files = spd_download(remote_file=relpathnames, _extra = source)

  if file_list_flag then begin ;concatenate the list
    if n_elements(file_list) eq 0 then begin
      file_list = [files]
    endif else begin
      file_list = [file_list,files]
    endelse
  endif

  if keyword_set(downloadonly) then continue

  if(keyword_set(varformat)) then vf = varformat else vf = '*'+datatype+'*'
  spd_cdf2tplot, file = files, varformat = vf, verbose = verbose, varname = loaded_vars, suffix=suffix
;loaded_vars refers to CDF vars, not necessarily tplot vars
  new_v = tnames(loaded_vars)
  If(new_v[0] Ne '') Then Begin
    spd_new_units, new_v  ;set units in dlimits using dlimits.cdf.vatt
    spd_new_coords, new_v       ;set coordinates in dlimits
;set data_type of 'calibrated'
    For j = 0, n_elements(new_v)-1 Do Begin
      get_data, new_v[j], dlimit = dl
      If(size(dl, /type) Eq 8) Then Begin
        str_element, dl, 'data_att', success = has_data_att
        If(has_data_att) Then Begin
          data_att = dl.data_att
          str_element, data_att, 'data_type', 'calibrated', /add_replace
        Endif Else data_att = {data_type:'calibrated'}
        str_element, dl, 'data_att', data_att, /add
      Endif Else Begin
        data_att = {data_type:'calibrated'}
        dl = {data_att:data_att}
      Endelse
      store_data, new_v[j], dlimit = dl
      If(~keyword_set(no_time_clip)) Then Begin
        If (keyword_set(trange) && n_elements(trange) Eq 2) $
          Then tr = timerange(trange) Else tr = timerange()
        time_clip, new_v[j], min(tr), max(tr), /replace, error = tr_err
        If(tr_err) Then Begin
          dprint, new_v[j]+' Out of range and not clipped'
        Endif
      Endif
    Endfor
  Endif
;Set colors, labels, etc.
  dq = where(strpos(new_v, 'quality') ne -1)
  If(dq[0] Ne -1) Then Begin
     ylim, new_v[dq], -1, 8.0, 0
     options, new_v[dq], 'tplot_routine','bitplot', /default
     options, new_v[dq], 'labels', ['no-scpot', ' ', 'eesa-low-E', $
                                    'iesa-low-E', 'n_e >> n_i', $
                                    'n_i >> n_e', 'man_flag'], /default
  Endif
  dv = where(strpos(new_v, 'velocity') ne -1)
  If(dv[0] Ne -1) Then Begin
     options, new_v[dv], 'colors', 'bgr', /default
     options, new_v[dv], 'labels', ['Vx','Vy','Vz'], /default
  Endif
  dv = where(strpos(new_v, 'flux') ne -1)
  If(dv[0] Ne -1) Then Begin
     options, new_v[dv], 'colors', 'bgr', /default
     options, new_v[dv], 'labels', ['fx','fy','fz'], /default
  Endif
  dv = where(strpos(new_v, 'ptens') ne -1)
  If(dv[0] Ne -1) Then Begin
     options, new_v[dv], 'colors', 'bgrmcy', /default
     options, new_v[dv], 'labels', ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], /default
  Endif
  dv = where(strpos(new_v, 'mftens') ne -1)
  If(dv[0] Ne -1) Then Begin
     options, new_v[dv], 'colors', 'bgrmcy', /default
     options, new_v[dv], 'labels', ['Mxx','Myy','Mzz','Mxy','Mxz','Myz'], /default
  Endif
  dv = where(strpos(new_v, 't3') ne -1)
  If(dv[0] Ne -1) Then Begin
     options, new_v[dv], 'colors', 'bgrmcy', /default
     options, new_v[dv], 'labels', ['Tx','Ty','Tz'], /default
  Endif

endfor


if file_list_flag && n_elements(file_list) ne 0 then begin
  files=file_list
endif

;print accumulated error messages now that loading is complete
if keyword_set(msg_probe) then dprint, dlevel=1, msg_probe
if keyword_set(msg_dt) then dprint, dlevel=1, msg_dt


End

