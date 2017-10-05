;+
;Procedure: thm_cotrans
;Purpose:   Transform between various THEMIS  and geophysical coordinate systems
;keywords:
;  probe = Probe name. The default is 'all', i.e., transform data for all
;          available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be transformed, can take any of the values
;          allowed for datatype for the various thm_load routines. You
;          can use wildcards like ? and [lh].
;          'all' is not accepted. You can use '*', but you may get unexpected
;          results if you are using suffixes.
;  in_coord = 'spg', 'ssl', 'dsl', 'gse', 'gsm','sm', 'gei','geo', 'sse', 'sel' or
;          'mag' coordinate system of input.
;          This keyword is optional if the dlimits.data_att.coord_sys attribute
;          is present for the tplot variable, and if present, it must match
;          the value of that attribute.  See cotrans_set_coord,
;          cotrans_get_coord
;  out_coord = 'spg', 'ssl', 'dsl', 'gse', 'gsm', 'sm', 'gei','geo', 'sse','sel', or 'mag'
;           coordinate system of output.  This keyword is optional if
;           out_suffix is specified and last 3 characters of suffix specify
;           the output coordinate system.
;  in_suffix = optional suffix needed to generate the input data quantity name:
;           'th'+probe+'_'datatype+in_suffix
;  out_suffix = optional suffix to add to output data quantity name.  If
;           in_suffix is present, then in_suffix will be replaced by out_suffix
;           in the output data quantity name.
; valid_names:return valid coordinate system names in named varibles supplied to
;           in_coord and/or out_coord keywords.
; support_suffix: if support_data is loaded with a suffix you can
; specify it here
;           
; out_vars: return a list of the names of any transformed variables
;
; ignore_dlimits: set this keyword to true so that an error will not
;     be produced if the internal label of the coordinate system clashed
;     with the user provided coordinate system.
; interpolate_state: use interpolation on 1-minute state CDF spinper/spinphase
;     samples for despinning instead of spin model
;     
; no_update_labels: Set this keyword if you want the routine to not update the labels automatically
;
;
;Optional Positional Parameters:
; in_name  Name(s) of input tplot variable(s) (or glob patern)
;          (space-separated list or array of strings.).  If the in_name
;          parameter is provided, the probe and datatype
;          keywords will be ignored.  However, if the input name
;          is not of format 'th[a-e]_*', use the probe keyword to indicate
;          which probe's state data should be used for each input variable.
; out_name Name(s) of output tplot variable(s).  glob patterns not accepted.
;          Number of output names must match number of input names (after glob
;          expansion of input names).  (single string, or array of strings.)
;
;Examples:
;  thm_load_state, /get_support
;
;  thm_cotrans, probe='a', datatype='fgl', out_suffix='_gsm'
;
;  ; or equivalently
;
;  thm_cotrans, 'tha_fgl', 'tha_fgl_gsm', out_coord='gsm'
;
;  ; to transform all th?_fg?_dsl to th?_fg?_gsm
;
;  thm_cotrans, 'th?_fg?', in_suffix='_dsl', out_suffix='_gsm'
;
;  ; for arbitrary input variables, specify in_coord and probe:
;
;  thm_cotrans,'mydslvar1 mydslvar2 mydslvar3', $
;              in_coord='dsl', probe='b c d', out_suff='_gse'
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2016-09-27 17:42:42 -0700 (Tue, 27 Sep 2016) $
; $LastChangedRevision: 21952 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/cotrans/thm_cotrans.pro $
;-

;This routine will replace coordinate plot labels only in the dlimits,
;If the coordinate name is clearly delineated, so that it will not accidentally modify substrings that look like coordinate names  
pro thm_cotrans_update_dlimits,out_name,in_coord,out_coord

  get_data, out_name, dlimit = dl
  
  if ~is_struct(dl) then return
  
  if in_set(strlowcase(tag_names(dl)),'ytitle') then begin
    type1 = stregex(dl.ytitle,'[^a-zA-Z]'+in_coord+'[^a-zA-Z]',/fold_case)
    type2 = stregex(dl.ytitle,'^'+in_coord+'[^a-zA-Z]',/fold_case)
    type3 = stregex(dl.ytitle,'[^a-zA-Z]'+in_coord+'$',/fold_case)
    type4 = stregex(dl.ytitle,'^'+in_coord+'$',/fold_case)
    if type1 ne -1 then begin
      dl.ytitle = strmid(dl.ytitle,0,type1+1) + out_coord + strmid(dl.ytitle,type1+strlen(in_coord)+1,strlen(dl.ytitle)-(type1+strlen(in_coord)+1))
    endif else if type2 ne -1 then begin
      dl.ytitle = out_coord + strmid(dl.ytitle,strlen(in_coord),strlen(dl.ytitle)-strlen(in_coord))
    endif else if type3 ne -1 then begin
      dl.ytitle = strmid(dl.ytitle,0,type3+1) + out_coord
    endif else if type4 ne -1 then begin
      dl.ytitle = out_coord
    endif else begin
      return
    endelse
    store_data,out_name,dlimit=dl
  endif

  if in_set(strlowcase(tag_names(dl)),'ysubtitle') then begin
    type1 = stregex(dl.ysubtitle,'[^a-zA-Z]'+in_coord+'[^a-zA-Z]',/fold_case)
    type2 = stregex(dl.ysubtitle,'^'+in_coord+'[^a-zA-Z]',/fold_case)
    type3 = stregex(dl.ysubtitle,'[^a-zA-Z]'+in_coord+'$',/fold_case)
    type4 = stregex(dl.ysubtitle,'^'+in_coord+'$',/fold_case)
    if type1 ne -1 then begin
      dl.ysubtitle = strmid(dl.ysubtitle,0,type1+1) + out_coord + strmid(dl.ysubtitle,type1+strlen(in_coord)+1,strlen(dl.ysubtitle)-(type1+strlen(in_coord)+1))
    endif else if type2 ne -1 then begin
      dl.ysubtitle = out_coord + strmid(dl.ysubtitle,strlen(in_coord),strlen(dl.ysubtitle)-strlen(in_coord))
    endif else if type3 ne -1 then begin
      dl.ysubtitle = strmid(dl.ysubtitle,0,type3+1) + out_coord
    endif else if type4 ne -1 then begin
      dl.ysubtitle = out_coord
    endif else begin
      return
    endelse
    store_data,out_name,dlimit=dl
  endif

  if in_set(strlowcase(tag_names(dl)),'labels') then begin
    nl = n_elements(dl.labels)
    for k = 0, nl-1 do begin
      type1 = stregex(dl.labels[k], '[^a-zA-Z]'+in_coord+'[^a-zA-Z]', /fold_case)
      type2 = stregex(dl.labels[k], '^'+in_coord+'[^a-zA-Z]', /fold_case)
      type3 = stregex(dl.labels[k], '[^a-zA-Z]'+in_coord+'$', /fold_case)
      type4 = stregex(dl.labels[k], '^'+in_coord+'$', /fold_case)
      if type1 ne -1 then begin
        dl.labels[k] = strmid(dl.labels[k], 0, type1+1) + out_coord + strmid(dl.labels[k], type1+strlen(in_coord)+1, strlen(dl.labels[k])-(type1+strlen(in_coord)+1))
      endif else if type2 ne -1 then begin
        dl.labels[k] = out_coord + strmid(dl.labels[k], strlen(in_coord), strlen(dl.labels[k])-strlen(in_coord))
      endif else if type3 ne -1 then begin
        dl.labels[k] = strmid(dl.labels[k], 0, type3+1) + out_coord
      endif else if type4 ne -1 then begin
        dl.labels[k] = out_coord
      endif else begin
        return
      endelse
      store_data, out_name, dlimit = dl
    endfor
  endif

end

;This routine will replace coordinate plot labels only in the limits,
;If the coordinate name is clearly delineated, so that it will not accidentally modify substrings that look like coordinate names  
pro thm_cotrans_update_limits,out_name,in_coord,out_coord

  get_data, out_name, limit = al
  
  if ~is_struct(al) then return
  
  if in_set(strlowcase(tag_names(al)),'labels') then begin
    nl = n_elements(al.labels)
    for k = 0, nl-1 do begin
      type1 = stregex(al.labels[k], '[^a-zA-Z]'+in_coord+'[^a-zA-Z]', /fold_case)
      type2 = stregex(al.labels[k], '^'+in_coord+'[^a-zA-Z]', /fold_case)
      type3 = stregex(al.labels[k], '[^a-zA-Z]'+in_coord+'$', /fold_case)
      type4 = stregex(al.labels[k], '^'+in_coord+'$', /fold_case)
      if type1 ne -1 then begin
        al.labels[k] = strmid(al.labels[k], 0, type1+1) + out_coord + strmid(al.labels[k], type1+strlen(in_coord)+1, strlen(al.labels[k])-(type1+strlen(in_coord)+1))
      endif else if type2 ne -1 then begin
        al.labels[k] = out_coord + strmid(al.labels[k], strlen(in_coord), strlen(al.labels[k])-strlen(in_coord))
      endif else if type3 ne -1 then begin
        al.labels[k] = strmid(al.labels[k], 0, type3+1) + out_coord
      endif else if type4 ne -1 then begin
        al.labels[k] = out_coord
      endif else begin
        return
      endelse
      store_data, out_name, limit = al
    endfor
  endif

end

; if the data is of type 'vel' this is an invalid coordinate transform, warn user
pro thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
    get_data, in_name, dlimit = dl
    if is_struct(dl) && in_set(strlowcase(tag_names(dl)),'data_att') && $
        in_set(strlowcase(tag_names(dl.data_att)),'st_type') && $ 
        strlowcase(dl.data_att.st_type) eq 'vel' then begin
        dprint, 'Warning: Transforming '+in_name+' from '+strupcase(in_coord)+' to '+strupcase(out_coord)+' coordinates can produce invalid results'
    endif
end

;helps simplify transformation logic code using a recursive formulation.
;Rather than specifying the set of transformations for each combination of
;in_coord & out_coord, this routine will perform only the nearest transformation
;then make a recursive call to itself, with each call performing one additional
;step in the chain.  This makes it so only neighboring coordinate transforms need be
;specified.
;The set of transformations forms the following graph:
;SPG<->SSL<->DSL<->GSE<->GEI<->GEO<->MAG
;      SEL<->SSE<->GSE<->GSM<->SM
pro thm_cotrans_transform_helper,in_name,out_name,in_coord,out_coord, $
                      spinras,spindec,spinper,spinphase,ignore_dlimits=ignore_dlimits,$
                      interpolate_state=interpolate_state,$
                      use_spinphase_correction=use_spinphase_correction,$
                      name_sun_pos=name_sun_pos,name_lun_pos=name_lun_pos,$
                      name_lun_att_x=name_lun_att_x, name_lun_att_z=name_lun_att_z,$
                      prb=prb,use_eclipse_corrections=use_eclipse_corrections
                      
  compile_opt hidden

  ;case select below modified to increase simplicity and maintainability.
  ;#1 Identity transform separated.
  ;#2 Recursive calls to thm_cotrans prevents duplicated code. 
  if in_coord eq out_coord then begin
    if in_name ne out_name then copy_data,in_name,out_name 
  endif else begin
    case in_coord of
      'sel': begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
          sse2sel,in_name,name_sun_pos,name_lun_pos,name_lun_att_x,name_lun_att_z,out_name,/sel2sse
          recursive_in_coord='sse'
        end
      'spg': begin
          spg2ssl,in_name,out_name,probe=prb,ignore_dlimits=ignore_dlimits
          recursive_in_coord='ssl'
        end
      'ssl': switch out_coord of
        'spg': begin
          spg2ssl,in_name,out_name,/ssl2spg,probe=prb,ignore_dlimits=ignore_dlimits
          recursive_in_coord='spg'
          break
        end
        else: begin
          if keyword_set(interpolate_state) then begin
            ssl2dsl, name_input=in_name, name_thx_spinper=spinper, name_thx_spinphase=spinphase, name_output=out_name,ignore_dlimits=ignore_dlimits,/interpolate_state
          endif else begin
            ssl2dsl, name_input=in_name, name_output=out_name,ignore_dlimits=ignore_dlimits,spinmodel_ptr=spinmodel_get_ptr(prb,use_eclipse_corrections=use_eclipse_corrections),use_spinphase_correction=use_spinphase_correction
          endelse
          recursive_in_coord='dsl'
        end
      endswitch
      'dsl': switch out_coord of 
        'spg': 
        'ssl': begin
          if keyword_set(interpolate_state) then begin
            ssl2dsl, name_input=in_name, name_thx_spinper=spinper, name_thx_spinphase=spinphase, name_output=out_name, /dsl2ssl,ignore_dlimits=ignore_dlimits,/interpolate_state
          endif else begin
            ssl2dsl, name_input=in_name, name_output=out_name, /dsl2ssl,ignore_dlimits=ignore_dlimits,spinmodel_ptr=spinmodel_get_ptr(prb),use_spinphase_correction=use_spinphase_correction
          endelse
          recursive_in_coord='ssl'
          break
        end
        else: begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
          dsl2gse, in_name, spinras, spindec, out_name,ignore_dlimits=ignore_dlimits      
          recursive_in_coord='gse'           
        end   
      endswitch
      'gse': switch out_coord of
        'spg':
        'ssl':
        'dsl': begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
          dsl2gse, in_name, spinras, spindec, out_name,ignore_dlimits=ignore_dlimits,/gse2dsl
          recursive_in_coord='dsl'
          break
        end
        'sel':
        'sse': begin
          gse2sse,in_name,name_sun_pos,name_lun_pos,out_name,ignore_dlimits=ignore_dlimits
          recursive_in_coord='sse'
          break
        end
        'sm':
        'gsm': begin
          cotrans, in_name, out_name, /gse2gsm,ignore_dlimits=ignore_dlimits
          recursive_in_coord='gsm'
          break
        end
        'agsm': begin
          ; using a rotation angle of 4 degrees when transforming to aGSM coordinates in the GUI
          gse2agsm, in_name, out_name, rotation_angle = 4.0
          recursive_in_coord='agsm'
          break
        end
        else: begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans, in_name,out_name,/gse2gei, ignore_dlimits=ignore_dlimits
          recursive_in_coord='gei'
        end
      endswitch
      'agsm': begin
        agsm2gse, in_name, out_name, rotation_angle = 4.0
        recursive_in_coord='gse'
        break
      end
      'sse': switch out_coord of
        'sel': begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
          sse2sel,in_name,name_sun_pos,name_lun_pos,name_lun_att_x,name_lun_att_z,out_name   
          recursive_in_coord='sel'
          break;
        end
        else: begin
          gse2sse,in_name,name_sun_pos,name_lun_pos,out_name,ignore_dlimits=ignore_dlimits,/sse2gse
          recursive_in_coord='gse'
          break
       end
      endswitch 
      'sm': begin
         cotrans, in_name,out_name,/sm2gsm, ignore_dlimits=ignore_dlimits
         recursive_in_coord='gsm'
      end
      'gsm': switch out_coord of
        'sm': begin
          cotrans, in_name,out_name,/gsm2sm, ignore_dlimits=ignore_dlimits
          recursive_in_coord='sm'
          break
        end
        else: begin
          cotrans, in_name,out_name,/gsm2gse, ignore_dlimits=ignore_dlimits
          recursive_in_coord='gse'
        end
      endswitch
      'gei': switch out_coord of
        'geo': begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans,in_name,out_name,/gei2geo,ignore_dlimits=ignore_dlimits
          recursive_in_coord='geo'
          break
        end
        'mag': begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans,in_name,out_name,/gei2geo,ignore_dlimits=ignore_dlimits
          recursive_in_coord='geo'
          break
        end
        'j2000': begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans,in_name,out_name,/gei2j2000,ignore_dlimits=ignore_dlimits
          recursive_in_coord='j2000'
          break
        end
        else: begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans,in_name,out_name,/gei2gse,ignore_dlimits=ignore_dlimits
          recursive_in_coord='gse'
        end
      endswitch
      'geo': switch out_coord of
        'mag': begin
          ;geo2mag,in_name,out_name
          cotrans,in_name,out_name,/geo2mag,ignore_dlimits=ignore_dlimits
          recursive_in_coord='mag'            
          break
        end
        else: begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          thm_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans,in_name,out_name,/geo2gei,ignore_dlimits=ignore_dlimits
          recursive_in_coord='gei'
          break
        end
      endswitch 
      'mag': begin
          cotrans,in_name,out_name,/mag2geo,ignore_dlimits=ignore_dlimits
          ;mag2geo,in_name,out_name
          recursive_in_coord='geo'
      end
      'j2000': begin
          cotrans,in_name,out_name,/j20002gei,ignore_dlimits=ignore_dlimits
          recursive_in_coord='gei'
      end
      else: begin
        dprint,"thm_cotrans: does not know how to transform "+in_coord+" to " $
                + out_coord
        recursive_in_coord=out_coord
      end
    endcase
    thm_cotrans_transform_helper,out_name,out_name,recursive_in_coord,out_coord, $
                      spinras,spindec,spinper,spinphase,ignore_dlimits=ignore_dlimits,$ 
                      interpolate_state=interpolate_state,$
                      use_spinphase_correction=use_spinphase_correction,$
                      name_sun_pos=name_sun_pos,name_lun_pos=name_lun_pos,$
                      name_lun_att_x=name_lun_att_x, name_lun_att_z=name_lun_att_z,$
                      prb=prb
  endelse          
                      
end
                      
; in_coord is optional if dlimits includes a data_att.coord_sys element.
pro thm_cotrans, in_name, out_name, probe=probe, datatype=datatype,  $
                 in_coord=in_coord, out_coord=out_coord, verbose=verbose, $
                 in_suffix=in_suf, out_suffix=out_suf, valid_names=valid_names, $
                 support_suffix=support_suffix,ignore_dlimits=ignore_dlimits,$
                 interpolate_state=interpolate_state,out_vars=out_vars,$
                 use_spinaxis_correction=use_spinaxis_correction, $
                 use_spinphase_correction=use_spinphase_correction, $
                 use_eclipse_corrections=use_eclipse_corrections,$
                 slp_suffix=slp_suffix,no_update_labels=no_update_labels

  compile_opt idl2

  thm_init
; If verbose keyword is defined, override !themis.verbose
  vb = size(verbose, /type) ne 0 ? verbose : !themis.verbose

   vprobes = ['a','b','c','d','e']
   ;vcoord = ['spg', 'ssl', 'dsl', 'gse', 'gsm','sm', 'gei','geo','sse','sel', 'mag']
   coordSysObj = obj_new('thm_ui_coordinate_systems')
   vcoord = coordSysObj->makeCoordSysList()
   obj_destroy, coordSysObj
   
   if keyword_set(valid_names) then begin
      in_coord = vcoord
      out_coord = vcoord
      probe=vprobes
      if keyword_set(vb) then begin
         dprint, string(strjoin(vcoord, ','), $
                                format = '( "Valid coords:",X,A,".")')
         dprint, string(strjoin(vprobes, ','), $
                                format = '( "Valid probes:",X,A,".")')
         dprint, 'Valid datatypes: Anything goes!'

      endif
      return
   endif

; validate in_coord and out_coord
   if not keyword_set(out_coord) and keyword_set(out_suf) then begin
      out_coord=strmid(out_suf,2,3,/reverse)
      if stregex(out_coord,'sm',/boolean) && ~stregex(out_coord,'gsm',/boolean) then begin
        out_coord = 'sm'
      endif
   endif
   
   if not keyword_set(out_coord) then begin
      dprint, 'thm_cotrans: must specify out_coord or out_suffix'
      return
   endif else out_coord = ssl_check_valid_name(strlowcase(out_coord), vcoord)

   if not keyword_set(out_coord) then return

   if n_elements(out_coord) gt 1 then begin
      dprint, 'thm_cotrans: can only specify one out_coord'
      return
   endif

   if ~keyword_set(in_coord) && keyword_set(in_suf) then begin 
      in_coord=strmid(in_suf,2,3,/reverse)
      if stregex(in_coord,'sm',/boolean) && ~stregex(in_coord,'gsm',/boolean) then begin
        in_coord = 'sm'
      endif
   endif

   if keyword_set(in_coord) then begin
      in_coord = ssl_check_valid_name(strlowcase(in_coord), vcoord)
      if not keyword_set(in_coord) then return
      if n_elements(in_coord) gt 1 then begin
         dprint, 'thm_cotrans: can only specify one in_coord'
         return
      endif
   endif

   if not keyword_set(in_suf) then in_suf = ''
   if not keyword_set(out_suf) then out_suf = ''

   if (n_elements(use_spinaxis_correction) EQ 0) then begin
      use_spinaxis_correction=1
      dprint,'Defaulting to enable V03 spin axis correction'
   end

   if (n_elements(use_spinphase_correction) EQ 0) then begin
      use_spinphase_correction=1
      dprint,'Defaulting to enable V03 spin phase correction'
   end

; do 'standard' THEMIS name conventions to get tplot names
if n_params() eq 0 then begin
   if not keyword_set(probe) then probe = vprobes $
   else probe = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all)
   if not keyword_set(probe) then begin
      dprint, 'probe keyword required if no positional args present'
      return
   endif

   if not keyword_set(datatype) then begin
      dprint, 'datatype keyword required if no positional args present'
      return
   endif

   if n_elements(datatype) eq 1 then datatype=strsplit(datatype, ' ', /extract)
   datatype=strlowcase(datatype)

   for i = 0, n_elements(probe)-1 do begin
      for j = 0, n_elements(datatype)-1 do begin
         in_name='th'+probe[i]+'_'+datatype[j]
         out_name='th'+probe[i]+'_'+datatype[j]

            thm_cotrans, in_name, in_coord=in_coord, out_coord=out_coord, $
                in_suf=in_suf, out_suf=out_suf, verbose=verbose,$
                ignore_dlimits=ignore_dlimits,$
                interpolate_state=interpolate_state,$
                use_spinphase_correction=use_spinphase_correction,$
                use_spinaxis_correction=use_spinaxis_correction

      endfor
   endfor
   return
endif else if n_params() gt 2 then begin
   dprint, 'usage: thm_cotrans, probe=probe, datatype=datatype, $'
   dprint, '                    in_coord=in_c, out_coord=out_c, $'
   dprint, '                    in_suffix=in_suf, out_suffix=out_suff'
   dprint, 'or: thm_cotrans, in_name[, out_name], in_coord=in_c, out_coord=out_c'
   return
endif

; allow for globbing on the input parameters , deal with in_suf and out_suf,
; figure out probe, if necessary.

in_names = tnames(in_name+in_suf, n)
if n eq 0 then begin
   dprint, 'thm_cotrans: no match: '+in_name+in_suf
   return
endif
if n_params() eq 1 || $
   n_params() eq 2 && n_elements(in_names) ne n_elements(out_name) then begin
   if n_params() eq 2 then dprint, 'thm_cotrans: warning: ignoring out_names'
   ;; generate output names based on out_suffix
   if in_suf ne '' then $
      base_len = strpos(in_names,in_suf,/reverse_search) $
   else $
      base_len = strlen(in_names)
   ;   out_names = strmid(in_names,0,transpose(base_len))+out_suf
;   out_names = strmid(in_names,0,base_len)+out_suf
;the statement with the transpose bombs on scalars, the statment
;without the transpose bombs later, due to undocumented weird behavior
;of the strmid function that causes out_names to be an nXn matrix
   out_names = in_names
   for j = 0, n-1 do out_names[j] = strmid(in_names[j],0,base_len[j])+out_suf
endif else out_names = out_name + out_suf

if n_elements(in_names) ne n_elements(out_names) then begin
   message, 'thm_cotrans: number of input variables does not match number of output variables'
endif

;preprocess coordinate systems, so we can determine if probe keyword is required.
;This code also helps resolve discrepancies between in_coord keyword, and data_att.coord_sys
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
    
    if ~keyword_set(in_coord) || strmatch(in_coord, 'unknown') then begin
      in_coords[i] = data_in_coord
    endif else if strmatch(data_in_coord,'unknown') then begin
      in_coords[i] = in_coord
    endif else if data_in_coord ne in_coord then begin
      in_coords[i] = 'conflict'
    endif else begin
      in_coords[i] = in_coord
    endelse
  
  endfor
endelse


if ~keyword_set(probe) then begin
   standard = strmatch(in_names,'th?_*')
   ;this only stops the routine if a probe is really necessary
   if total(standard) ne n_elements(in_names) then begin 
      idx = where(standard eq 0 and (in_coords eq 'spg' or in_coords eq 'ssl' or in_coords eq 'dsl'),c) 
      if c ne 0 || out_coord eq 'spg' || out_coord eq 'ssl' || out_coord eq 'dsl' then begin
        dprint, 'thm_cotrans: input name(s) do not specify probe according to THEMIS convention:'
        dprint, '            ', in_names[where(~standard)]
        dprint, '             Must specify probe with probe keyword'
        return
      endif else begin
        probe = strmid(in_names, 2,1)
        probe[where(~standard)] = 'a'
      endelse  
   endif else begin
     probe = strmid(in_names, 2,1)
   endelse
endif

for i = 0, n_elements(in_names)-1 do begin
  in_nam = in_names[i]
  out_nam = out_names[i]
  prb = probe[i < (n_elements(probe)-1)]

  get_data,in_nam,data=in,dl=in_dl
  if size(in, /type) ne 8 then begin
    dprint, 'input tplot variable '+in_nam+' has no data'
    continue
  endif
  sizein=size(in.y)
  if sizein[0] ne 2 or sizein[2] ne 3 then begin
    dprint,'Input tplot variable '+in_nam+' is not a 3-vector. Skipping'
    continue
  endif

  in_c = in_coords[i]

  if in_c eq 'conflict' then begin
    dprint,'Argument input coordinate system and data coordinate system of "' + in_nam + '" do not match. Skipping.'
    continue
  endif else if in_c eq 'unknown' then begin
    dprint,'Tplot variable "' + in_nam + '" has unknown input coordinate system. Skipping'
    continue
  endif

  dprint, 'thm_cotrans: coord. system of input '+in_nam+': '+in_c

  ; Select which tplot variables (with or without spin axis correction)
  ; to use for transforms in and out of DSL, depending on
  ; use_spinaxis_corrections keyword argument

  if keyword_set(use_spinaxis_correction) then begin
    dprint,'Using spin axis correction'
    corrected='_corrected'
  endif else begin
    corrected=''
    dprint,'Not using spin axis correction'
  endelse

  ; force support_suffix to '' if not explicitly specified
  if ~keyword_set(support_suffix) then support_suffix=''

  spinras = 'th'+prb+'_state_spinras'+corrected+support_suffix
  spindec = 'th'+prb+'_state_spindec'+corrected+support_suffix
  spinper = 'th'+prb+'_state_spinper'+support_suffix
  spinphase = 'th'+prb+'_state_spinphase'+support_suffix

  ; for spinras/spindec, might need to fall back to uncorrected
  ; versions if _corrected tplot variables don't exist

  if (strlen(corrected) GT 0) then begin
     tn_spinras = tnames(spinras)
     tn_spindec = tnames(spindec)
     
     if ((strlen(tn_spinras) EQ 0) OR (strlen(tn_spindec) EQ 0)) then begin
        spinras_unc = 'th'+prb+'_state_spinras'+support_suffix
        spindec_unc = 'th'+prb+'_state_spindec'+support_suffix
        dprint,'spinras or spindec corrections not available, falling back to '+spinras_unc+' and '+spindec_unc
        spinras = spinras_unc
        spindec = spindec_unc
     endif
  endif
   
  if ~keyword_set(slp_suffix) then begin
    slp_suffix = ''
  endif
  
  name_sun_pos = 'slp_sun_pos'+slp_suffix
  name_lun_pos = 'slp_lun_pos'+slp_suffix
  name_lun_att_x = 'slp_lun_att_x'+slp_suffix
  name_lun_att_z = 'slp_lun_att_z'+slp_suffix
  
  thm_cotrans_transform_helper,in_nam,out_nam,in_c,out_coord, $
                      spinras,spindec,spinper,spinphase,ignore_dlimits=ignore_dlimits,$
                      interpolate_state=interpolate_state,$
                      use_spinphase_correction=use_spinphase_correction,$
                      name_sun_pos=name_sun_pos,name_lun_pos=name_lun_pos,$
                      name_lun_att_x=name_lun_att_x,name_lun_att_z=name_lun_att_z,$
                      prb=prb,use_eclipse_corrections=use_eclipse_corrections
   
   
  if n_elements(name_list) eq 0 then begin
    name_list = [out_nam] 
  endif else begin
    name_list = [name_list,out_nam]
  endelse
  
  if ~keyword_set(no_update_labels) then begin
    thm_cotrans_update_dlimits,out_nam,in_c,out_coord
    thm_cotrans_update_limits,out_nam,in_c,out_coord;labels may be stored in limits structure too
  endif

;this statement is superfluous in the presence of new logic 
;validating coordinate systems   
;   if in_c ne out_coord then $
;     dprint, 'thm_cotrans: '+out_coord+' output placed in '+out_nam

endfor

if arg_present(out_vars) && n_elements(name_list) gt 0 then begin
  out_vars = name_list
endif

end
