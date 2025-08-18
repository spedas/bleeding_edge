;+
;Procedure:
;  mms_qcotrans
;
;Purpose:
;  Perform coordinate transformations using MMS MEC quaternions.
;  This routine mirrors mms_cotrans but applies a different transformation.
;
;
;Calling Sequence:
;  mms_qcotrans, input_name [,output_name] 
;                ,out_coord=out_coord [,out_suffix=out_suffix] 
;                [,in_coord=in_coord] [,in_suffix=in_suffix] ...
;
;Example Usage:
;  mms_qcotrans, 'mms1_fgm_b_gse_srvy_l2_bvec', in_coord='gse', out_coord='gsm', $
;                out_suffix='_gsm'
;
;
;Arguments:
;  input_name: String or string array of input tplot variable(s).  Standard tplot
;              wildcards may be used to specify multiple variables.
;  output_name (optional) String or string array of output tplot variable names.
;              Number of output names must match number of input names once 
;              wildcards are considered.
;
;Keywords:
;  in_coord:  String specifying the coordinate system of the input(s).
;             This keyword is optional if the dlimits.data_att.coord_sys attribute
;             is present for the tplot variable, and if present, it must match
;             the value of that attribute (see cotrans_set_coord, cotrans_get_coord).
;               e.g. 'bcs','gse','gse2000','gsm','sm','geo','eci'
;  out_coord:  String specifying the output coordinate system.
;                e.g. 'bcs','gse','gse2000','gsm','sm','geo','eci'
;  in_suffix:  Suffix of input variable name.  This specifies the portion of
;              the input variable's name that will be replace with the output
;              suffix.  If specified, the name effective input name will be
;              input_name + in_suffix
;  out_suffix:  Suffix appended to the output name.  If in_suffix is present or
;               the input coordinates are part of the input variable's name then
;               they will be replaced with out_suffix.
;           
;  out_vars: return a list of the names of any transformed variables
;
;  valid_names:  return valid coordinate system names
;  no_update_labels: Set this keyword if you want the routine to not update the labels automatically
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-02-01 15:58:09 -0800 (Thu, 01 Feb 2018) $
;$LastChangedRevision: 24622 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/mms_qcotrans.pro $
;-

pro mms_qcotrans, $

           ; variable names
           in_name_0, $
           out_name_0, $

           ; coordinates
           in_coord=in_coord_0, $
           out_coord=out_coord_0, $

           ; suffixes
           in_suffix=in_suffix, $
           out_suffix=out_suffix, $
           support_suffix=support_suffix, $
           
           ; supplementary info
           probe=probe_0, $
           valid_names=valid_names, $
           out_vars=out_vars, $
           
           ; metadata options
           no_update_labels=no_update_labels, $
           ignore_dlimits=ignore_dlimits, $

           ; other
           verbose=verbose


    compile_opt idl2, hidden



mms_init

vb = undefined(verbose) ? !mms.verbose :  verbose

;valid values
valid_probes = ['1','2','3','4']
;valid_coords = ['bcs','gse','gse2000','gsm','sm','geo','eci']
valid_coords = ['bcs','dbcs','dmpa','smpa','dsl','ssl','gse','gse2000','gsm','sm','geo','eci','j2000']

;print and return valid inputs if requested
if keyword_set(valid_names) then begin
  in_coord_0 = valid_coords
  out_coord_0 = valid_coords
  probe_0 = valid_probes
  if keyword_set(vb) then begin
    dprint, string(strjoin(valid_coords, ','), format = '( "Valid coords:",X,A,".")')
    dprint, string(strjoin(valid_probes, ','), format = '( "Valid probes:",X,A,".")')
  endif
  return
endif

;copy input strings from temp vars to keep them from being altered
if ~undefined(in_name_0) then in_name = in_name_0
if ~undefined(out_name_0) then out_name = out_name_0
if ~undefined(in_coord_0) then in_coord = in_coord_0
if ~undefined(out_coord_0) then out_coord = out_coord_0 
if ~undefined(probe_0) then probe = probe_0


; Validate input/output coordinates
;----------------------------------------------------------

if n_elements(out_coord) gt 1 or n_elements(out_suffix) gt 1 then begin
  dprint, dlevel=0, 'Can only specify one out_coord/out_suffix'
  return
endif

;get output coord from suffix if none is specified
;  -distinguish "sm" from "gsm"
if undefined(out_coord) and is_string(out_suffix) then begin
  out_coord = mms_cotrans_parse(out_suffix,valid_coords)
endif

if undefined(out_coord) then begin
  dprint, dlevel=0, 'Must specify out_coord or out_suffix'
  return
endif else begin
  out_coord = ssl_check_valid_name(strlowcase(out_coord), valid_coords)
endelse

if ~is_string(out_coord) then return


if n_elements(in_coord) gt 1 or n_elements(in_suffix) gt 1 then begin
  dprint, dlevel=0, 'Can only specify one in_coord/in_suffix'
  return
endif

;get input coord from suffix if none is specified
;  -distinguish "sm" from "gsm"
if undefined(in_coord) && is_string(in_suffix) then begin 
  in_coord = mms_cotrans_parse(in_suffix,valid_coords)
endif

;check input coordinates, but allow for it to be unspecified
if ~undefined(in_coord) then begin
  in_coord = ssl_check_valid_name(strlowcase(in_coord), valid_coords)
  if ~is_string(in_coord) then begin
    return
  endif
endif

;
if undefined(in_suffix) then in_suffix = ''
if undefined(out_suffix) then out_suffix = ''
if undefined(support_suffix) then support_suffix = ''



; Build list of input/output variables
;   -allow wildcards in input names
;----------------------------------------------------------

in_names = tnames(in_name+in_suffix, n)
if n eq 0 then begin
  dprint, dlevel=0, 'No matches found for input: '+in_name+in_suffix
  return
endif

;generate output names if not provided
if n_params() eq 1 || n_elements(in_names) ne n_elements(out_name) then begin

  if n_params() eq 2 then dprint, 'WARNING: Ignoring out_names'
   if in_suffix ne '' then begin
      base_len = strpos(in_names,in_suffix,/reverse_search)
   endif else begin 
      base_len = strlen(in_names)
   endelse

  out_names = in_names
  for j = 0, n-1 do begin
    out_names[j] = strmid(in_names[j],0,base_len[j])+out_suffix
  endfor

endif else begin
  out_names = out_name + out_suffix
endelse

if n_elements(in_names) ne n_elements(out_names) then begin
   message, 'Number of input variables does not match number of output variables'
endif



; Get input coordinates
;   -preprocess coordinate systems, so we can determine if probe keyword is required
;   -this code also helps resolve discrepancies between in_coord keyword and data_att.coord_sys
;----------------------------------------------------------

if keyword_set(ignore_dlimits) then begin

  if is_string(in_coord) then begin
    in_coords = replicate(in_coord,n_elements(in_names))
  endif else begin
    dprint, 'Must specify input coordinates if /ignore_dlimits is set'
    return
  endelse

endif else begin

  in_coords = strarr(n_elements(in_names))
  for i = 0,n_elements(in_names)-1 do begin
  
    data_in_coord = cotrans_get_coord(in_names[i])
    
    if ~is_string(in_coord) then begin
      in_coords[i] = data_in_coord
    endif else if data_in_coord eq '' || strmatch(data_in_coord,'unknown') then begin
      in_coords[i] = in_coord
    endif else if data_in_coord ne in_coord then begin
      in_coords[i] = 'conflict'
    endif else begin
      in_coords[i] = in_coord
    endelse
  
  endfor

endelse



; Get probe designation
;----------------------------------------------------------

if undefined(probe) then begin

  ;get probe designation from variable name
  probes = ( stregex(in_names,'^mms([1-4])',/subexpr,/extract) )[1,*]

  if total(probes eq '') gt 0 then begin
    dprint, dlevel=0, 'Some input name(s) do not specify probe according to MMS convention:
    dprint, dlevel=0, '  '+in_names[where(probes eq'')]
    dprint, dlevel=0, 'Must specify probe with PROBE keyword'
    return
  endif

endif else begin

  ;ensure that probe is either singular or matches the number of input names
  if n_elements(probe) gt 1 then begin
    if n_elements(probe) ne n_elements(in_names) then begin
      dprint, dlevel=0, 'PROBE keyword must be singular or match the number on input names'
      return
    endif
    probes = probe
  endif else begin
    probes = replicate(probe,n_elements(in_names))
  endelse
  probes = strtrim(probes,2)

endelse



; Loop over input names to perform transformations
;----------------------------------------------------------

for i = 0, n_elements(in_names)-1 do begin

  in_name = in_names[i]
  out_name = out_names[i]
  probe = probes[i]

  ;verify data is valid
  get_data,in_name,data=in,dl=in_dl
  if ~is_struct(in) then begin
    dprint, 'input tplot variable '+in_name+' has no data'
    continue
  endif

  ;verify data is a 3-vector
  in_size=size(in.y)
  if in_size[0] ne 2 or in_size[2] ne 3 then begin
    dprint,'Input tplot variable '+in_name+' is not a 3-vector. Skipping'
    continue
  endif

  in_c = in_coords[i]

  ;notify if in_coord is inconsistent with metadata and skip variable
  if in_c eq 'conflict' then begin
    dprint,'Specified coordinate system does not match metadata for "' + in_name + '". Skipping.'
    continue
  endif else if in_c eq 'unknown' then begin
    dprint,'Tplot variable "' + in_name + '" has unknown input coordinate system. Skipping'
    continue
  endif

  dprint, 'Coordinate system of input '+in_name+': '+in_c

  mms_cotrans_qtransformer, in_name, out_name, in_c, out_coord, probe, ignore_dlimits=ignore_dlimits
 
  ;aggregate transformed variables
  name_list = array_concat(out_name,name_list)
  
  ;update labels in limits and dlimits structures
  if ~keyword_set(no_update_labels) then begin
    spd_cotrans_update_dlimits,out_name,in_c,out_coord
    spd_cotrans_update_limits,out_name,in_c,out_coord
  endif

endfor

if arg_present(out_vars) && n_elements(name_list) gt 0 then begin
  out_vars = name_list
endif


end