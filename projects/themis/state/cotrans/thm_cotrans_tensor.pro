;+
;NAME:
;thm_cotrans_tensor
;PURPOSE:
;wrapper for coordinate transforms to prssure and momentum
;flux tensors
;CALLING SEQUENCE:
; in_coord is optional if dlimits includes a data_att.coord_sys element.
;pro thm_cotrans_tensor, in_name, out_name, $
;                 in_coord=in_coord, out_coord=out_coord, verbose=verbose, $
;                 in_suffix=in_suf, out_suffix=out_suf, $
;                 support_suffix=support_suffix,ignore_dlimits=ignore_dlimits,$
;                 interpolate_state=interpolate_state,out_vars=out_vars,$
;                 use_spinaxis_correction=use_spinaxis_correction, $
;                 use_spinphase_correction=use_spinphase_correction, $
;                 use_eclipse_corrections=use_eclipse_corrections,$
;                 slp_suffix=slp_suffix,no_update_labels=no_update_labels
;INPUT:
; in_name  Name(s) of input tplot variable(s) (or glob patern)
;          (space-separated list or array of strings.). Non-tensor
;          variables can be mixed in, these will be passed to
;          thm_cotrans directly.
; out_name Name(s) of output tplot variable(s).  glob patterns not accepted.
;          Number of output names must match number of input names (after glob
;          expansion of input names).  (single string, or array of strings.)
;KEYWORDS:
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
; use_spinaxis_correction: use spinaxis correction
; use_spinphase_correction: use spinphase correction
; use_eclipse_corrections: use eclipse corrections
; no_update_labels: Set this keyword if you want the routine to not
;                   update the labels automatically
; reuse_rotation_matrix: If set, use the same rotation atrix for all
;                        inputs, if the time arrays are the same
; delete_rotation_matrix: If set, delete the rotation matirx variable
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-02-19 11:14:39 -0800 (Tue, 19 Feb 2019) $
; $LastChangedRevision: 26642 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/cotrans/thm_cotrans_tensor.pro $
;-
Pro thm_cotrans_tensor, in_name, out_name, $
                        in_coord=in_coord, out_coord=out_coord, verbose=verbose, $
                        in_suffix=in_suffix, out_suffix=out_suffix, $
                        support_suffix=support_suffix,ignore_dlimits=ignore_dlimits,$
                        interpolate_state=interpolate_state,out_vars=out_vars,$
                        use_spinaxis_correction=use_spinaxis_correction, $
                        use_spinphase_correction=use_spinphase_correction, $
                        use_eclipse_corrections=use_eclipse_corrections,$
                        slp_suffix=slp_suffix,no_update_labels=no_update_labels,$
                        reuse_rotation_matrix=reuse_rotation_matrix,$
                        delete_rotation_matrix=delete_rotation_matrix

  If(keyword_set(verbose)) Then dlvl = 9 Else dlvl = 2
;First check input names
  inames = tnames(in_name)
  nnames = n_elements(inames)
;Is out_name consistent?
  onames_ok = 0b
  If(is_string(out_name)) Then Begin
     If(n_elements(out_name) Eq nnames) Then Begin
        onames_ok = 1b
        onames = out_name
     Endif Else If(n_elements(out_name) Eq 1) Then Begin
        onames = strsplit(out_name, ' ', /extract)
        If(n_elements(onames) Eq nnames) Then onames_ok = 1b
     Endif
  Endif
  If(onames_ok Eq 0) Then Begin
     dprint, 'Out_names Not consistent with input, will use suffix'
  Endif

;Do cotrans
  vcount = 0
  For j = 0, nnames-1 Do Begin
     newnamej = ''
     If(onames_ok) Then newnamej = onames[j] Else Begin
        If(is_string(out_suffix)) Then newnamej = inames[j]+out_suffix[0] $
        Else newnamej = inames[j]+'_'+out_coord[0]
     Endelse
;Check array sizes, if not a tensor, just call thm_cotrans
     get_data, inames[j], data = t
     nyt = n_elements(t.y[0,*])
     If(nyt Ne 6) Then Begin
        dprint, dlevel = dlvl, 'Variable: '+inames[j]+' is not ntimes, 6, callling thm_cotrans'
        thm_cotrans, inames[j], newnamej, $
                     in_coord=in_coord, out_coord=out_coord, verbose=verbose, $
                     support_suffix=support_suffix,ignore_dlimits=ignore_dlimits,$
                     interpolate_state=interpolate_state,$
                     use_spinaxis_correction=use_spinaxis_correction, $
                     use_spinphase_correction=use_spinphase_correction, $
                     use_eclipse_corrections=use_eclipse_corrections,$
                     slp_suffix=slp_suffix,no_update_labels=no_update_labels
     Endif Else Begin
;grab rotation matrix, if needed, first check to see if the rotmat
;variable has the same time array as the tensor variable
        If(keyword_set(reuse_rotation_matrix) && is_string(tnames(rotmat))) Then Begin
           get_data, rotmat, data = r
        Endif Else r = 0
        If(~is_struct(r) || n_elements(r.x) Ne n_elements(t.x) || total(abs(r.x-t.x)) Gt 0) Then Begin
           rotmat = thm_cotrans_matrix(inames[j], in_coord=in_coord, $
                                       out_coord=out_coord, $
                                       interpolate_state=interpolate_state, $
                                       use_spinaxis_correction=use_spinaxis_correction, $
                                       use_spinphase_correction=use_spinphase_correction, $
                                       use_eclipse_corrections=use_eclipse_corrections)
        Endif
        If(~is_string(tnames(rotmat))) Then Begin
           dprint, 'Rotation matrix for: '+inames[j]+' failed'
           Continue
        Endif
;use ttensor_rotate to rotate
        ttensor_rotate, rotmat, inames[j], newname=newnamej, error=ct_error
        If(ct_error Eq 0) Then Begin
           dprint, 'Cotrans for: '+inames[j]+' failed'
           Continue
        Endif
        If(keyword_set(delete_rotation_matrix)) Then store_data, rotmat, /delete
;Set coordinates in variable newnamej, somewhere out_coord got set to
;an array?
        spd_set_coord, newnamej, out_coord[0]
;Confusion may exist if there is a coordinate_system tag from input
;variable
        get_data, newnamej, dlimits = dl
        If(tag_exist(dl, 'CDF') && tag_exist(dl.cdf, 'vatt') $
           && tag_exist(dl.cdf.vatt, 'COORDINATE_SYSTEM')) Then Begin
           dl.cdf.vatt.coordinate_system = strupcase(out_coord[0])
           store_data, newnamej, dlimits = dl
        Endif
        options, newnamej, 'ytitle', newnamej, /default
     Endelse
;populate out_vars variable array
     If(is_string(tnames(newnamej))) Then Begin
        If(vcount Eq 0) Then out_vars = newnamej Else out_vars = [out_vars, newnamej]
        vcount = vcount+1
     Endif
  Endfor

;Done
End
