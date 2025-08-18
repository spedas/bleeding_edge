;+
;Procedure: THM_LOAD_ESA
;
;Purpose:  Loads THEMIS ESA data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, for this case, there is only
;          one option, the default value of 'mom', so this is a
;          placeholder should there be more that one data type. 'all'
;          can be passed in also, to get all variables.
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l2', or level-2
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
;  /NO_TIME_CLIP: Disables time clipping, which is the default
;Example:
;   thg_load_esa,/get_suppport_data,probe=['a', 'b']
;Notes:
; Written by Davin Larson, Dec 2006
; Updated to use thm_load_xxx by KRB, 2007-2-5
; Fixed bug in valid_names block, removed references to sst in coments
; jmm, 21-feb-2007
; Fixed bugs, added ylim, zlim calls for spec data, as in thm_load_sst
; Handles new version of Level2 data files, jmm, 12-oct-2007
; adds units and coordinates to all new variables, jmm, 24-feb-2008
; $LastChangedBy: kenb-mac $
; $LastChangedDate: 2007-02-08 09:48:04 -0800 (Thu, 08 Feb 2007) $
; $LastChangedRevision: 328 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/themis/spacecraft/particles/thm_load_esa.pro $
;-

;-----------------------------------------------------------------------------------------------------------------------

; esa-specific helper function
; to return relative path names to files in the data tree.
; this routine maps datatypes to file type.

function thm_load_esa_relpath, sname=probe, filetype=ft, $
                               level=lvl, trange=trange, $
                               addmaster=addmaster, _extra=_extra

  relpath = 'th'+probe+'/'+lvl+'/'+ ft+'/'
  prefix = 'th'+probe+'_'+lvl+'_'+ft+'_'
  dir = 'YYYY/'
  ending = '_v01.cdf'

  return, file_dailynames(relpath, prefix, ending, dir=dir, $
                          trange = trange,addmaster=addmaster)
end

;-----------------------------------------------------------------------------------------------------------------------

pro thm_load_esa_post, sname=probe, datatype=dt, level=lvl, $
                       tplotnames=tplotnames, $
                       suffix=suffix, proc_type=proc_type, coord=coord, $
                       delete_support_data=delete_support_data, _extra=_extra

  if tplotnames[0] eq '' then return 

  ;; add DLIMIT tags to data quantities
  spd_new_units, tplotnames     ;gets units from cdf vatts
  spd_new_coords, tplotnames    ;gets coords from cdf vatts
  thm_fix_spec_units, strfilter(tplotnames,'*eflux*')  ;move units to z axis title
  for l=0, n_elements(tplotnames)-1 do begin
     tplot_var = tplotnames[l]
     get_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str
     isit_density=total(strmatch(strsplit(tplot_var,'_',/extract), 'density'))+$
       total(strmatch(strsplit(tplot_var, '_', /extract), 'avgtemp'))+$
       total(strmatch(strsplit(tplot_var, '_', /extract), 'vthermal'))
     isit_velocity=total(strmatch(strsplit(tplot_var,'_',/extract), 'velocity'))
     isit_t3=total(strmatch(strsplit(tplot_var,'_',/extract), 't3')) 
     isit_eflux=total(strmatch(strsplit(tplot_var,'_',/extract), 'eflux'))
     isit_yaxis=total(strmatch(strsplit(tplot_var,'_',/extract), 'yaxis'))
     isit_ptens=total(strmatch(strsplit(tplot_var,'_',/extract), 'ptens'))
     isit_mftens=total(strmatch(strsplit(tplot_var,'_',/extract), 'mftens'))
     isit_any = isit_density+isit_velocity+isit_t3+isit_eflux+isit_yaxis+$
       isit_ptens+isit_mftens
     if(lvl eq 'l2' Or isit_any Gt 0) then begin ;add 'calibrated' to vars
       if(size(dl_str, /type) eq 8) then Begin
         str_element, dl_str, 'data_att', success = has_data_att
         if(has_data_att) then begin
           data_att = dl_str.data_att
           str_element, data_att, 'data_type', 'calibrated', /add_replace
         endif else data_att = {data_type:'calibrated'}
         str_element, dl_str, 'data_att', data_att, /add
       endif else begin
         data_att = {data_type:'calibrated'}
         dl_str = {data_att:data_att}
       endelse
     endif
;colors, labels, etc
     case 1 of 
       isit_density 	: begin
           		  str_element, dl_str, 'ylog', 1, /add
       			  end
       isit_velocity	: begin
           		  str_element, dl_str, 'colors', [2,4,6], /add
       			  end
       isit_t3  	: begin
           		  str_element, dl_str, 'colors', [2,4,6], /add
       			  end
       isit_eflux	: begin
           		  str_element, dl_str, 'ylog', 1, /add
           		  str_element, dl_str, 'zlog', 1, /add
                          end
       isit_ptens       : begin
           		  str_element, dl_str, 'colors', [1,2,3,4,5,6], /add
                          end
       isit_mftens      : begin
           		  str_element, dl_str, 'colors', [1,2,3,4,5,6], /add
                        end
       else:	
     endcase
     
     store_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str
     if(isit_eflux && in_set(tag_names(d_str),'V')) then begin
        vmin = min(d_str.v, /nan, max = vmax) > 0.10
        ylim, tplot_var, vmin, vmax, 1
     endif

;ylims for data quality flag
     isit_dq = total(strmatch(strsplit(tplot_var,'_',/extract), 'quality'))
     If(isit_dq) Then Begin
       ylim, tplot_var, -1, 8.0, 0
       options, tplot_var, 'tplot_routine', 'bitplot'
       options, tplot_var, 'labels', ['scpot_flag', 'sat_flag', $
                                      'sw_flag', 'flow_flag', 'earth_shadow', $
                                      'moon_shadow', 'maneuver', 'dens_mismatch']
     Endif
   
  endfor

 
end

;-----------------------------------------------------------------------------------------------------------------------


pro thm_load_esa,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 relpathnames_all=relpathnames_all, no_download=no_download, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 varnames=varnames, valid_names = valid_names, files=files, $
                 suffix=suffix, type=type, coord=coord, $
                 progobj=progobj, _extra = _extra

  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end
  if not keyword_set(suffix) then suffix = ''

  vlevels = 'l1 l2'
  deflevel = 'l2'
  lvl = thm_valid_input(level,'Level',vinputs=vlevels,definput=deflevel,$
                        format="('l', I1)", verbose=0)
  if lvl eq '' then return                            

  if lvl eq 'l1' then begin
     dprint,  'This routine does not currently load l1 data.'
     dprint,  'l1 ESA data is loaded and calibrated from l0.'
     dprint,  'See ESA crib sheet for appropriate l0/packet routines.'
     return
  endif
  
  ;vcoord=['dsl','gse','gsm','all']
  coordSysObj = obj_new('thm_ui_coordinate_systems')
  vcoord = coordSysObj->MakeCoordSysList(instrument = 'esa', /include_all)
  obj_destroy, coordSysObj
  
  instr_0 = ['peif', 'peef', 'peir', 'peer', 'peib', 'peeb']
  moments_0 = ['mode', 'en_eflux', 'sc_pot', 'sc_current', 'magf', 'density', 'avgtemp', $
               'vthermal', 'flux', 'ptens', 'mftens', 't3', 'symm', $
               'symm_ang', 'magt3', 'data_quality']
;  if keyword_set(coord) then begin
;    coordkey=0
;    if size(coord,/dimen) eq 0 then coord=strsplit(coord,' ',/extract)
;    for i=0,2 do if total(strmatch(strtrim(strlowcase(coord),2),vcoord(i))) gt 0 then coordkey=coordkey+(i+2)
;    if total(strmatch(strtrim(strlowcase(coord),2),vcoord(3))) gt 0 then coordkey=9
;    case coordkey of
;      0 : begin
;          dprint,  "Invalid coordinate keyword.  Valid coordinates: 'dsl gse gsm all'"
;          return
;          end
;      2 : vl2coords='dsl'
;      3 : vl2coords='gse'
;      4 : vl2coords='gsm'
;      5 : vl2coords=['dsl', 'gse']
;      6 : vl2coords=['dsl', 'gsm']
;      7 : vl2coords=['gse', 'gsm']
;      else : vl2coords=['dsl', 'gse', 'gsm']
;    endcase
;  endif else vl2coords=['dsl', 'gse', 'gsm']

  vl2coords=['dsl', 'gse', 'gsm']
  vl2dt = ''
  for k = 0, n_elements(instr_0)-1 Do Begin
    vl2dt = [vl2dt, instr_0[k]+'_'+moments_0]
;add the appropriate velocities
    vl2dt = [vl2dt, instr_0[k]+'_velocity_'+vl2coords]
  endfor
;Add solarwind mode vars.
  vl2dt = [vl2dt, 'iesa_solarwind_flag', 'eesa_solarwind_flag']
;put array into single string with spaces
  vl2datatypes = vl2dt[1]       ;the first element is a null string...
  For j = 2, n_elements(vl2dt)-1 Do vl2datatypes = temporary(vl2datatypes)+' '+vl2dt[j]
  thm_load_xxx,sname=probe, datatype=datatype, trange=trange, $
               level=level, verbose=verbose, downloadonly=downloadonly, $
               relpathnames_all=relpathnames_all, no_download=no_download, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               get_support_data=get_support_data, $
               varnames=varnames, valid_names = valid_names, files=files, $
               vsnames = 'a b c d e', $
               type_sname = 'probe', $
               vdatatypes = 'esa', $
               file_vdatatypes = 'esa', $
               vlevels = vlevels, $
               vL2datatypes = vL2datatypes, $
               vL2coord = '', $
               deflevel = deflevel, $
               version = 'v01', $
               relpath_funct = 'thm_load_esa_relpath', $
               post_process_proc='thm_load_esa_post', $
               delete_support_data=delete_support_data, $
               proc_type=type, coord=coord, suffix=suffix, $
               progobj=progobj,$
               msg_out=msg_out, $
               _extra = _extra

  ;print accumulated error messages now that loading is complete
  if keyword_set(msg_out) then begin
    for i=0, n_elements(msg_out)-1 do begin
      if msg_out[i] ne '' then dprint, dlevel=1, msg_out[i]
    endfor
  endif

end

