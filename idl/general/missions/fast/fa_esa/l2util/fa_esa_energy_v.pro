;+
;NAME:
; fa_esa_energy_array
;PURPOSE:
; creates an energy angle array for FAST ESA data;
;CALLING SEQUENCE:
; pa = fa_esa_energy_array(energy, mode_ind)
;INPUT:
; energy = an array of (96, 64, 2 or 3) of energies
; mode = 0, 1 (or 2) the mode index used to get the correct value of
;               energy to apply for each time interval
;KEYWORDS:
; fillval = the fill value, the default is !values.f_nan
;HISTORY:
; 2015-08-28, jmm, jimm@ssl.berkeley.edu
;-
Function fa_esa_energy_array, energy, mode_ind, fillval = fillval

  ntimes = n_elements(mode_ind)
  If(keyword_set(fillval)) Then fv = fillval Else fv = !values.f_nan
  energy_out = fltarr(96, 64, ntimes) & energy_out[*] = fv
  mode0 = where(mode_ind Eq 0, nmode0)
  If(nmode0 Gt 0) Then Begin
     For j = 0, nmode0-1 Do energy_out[0, 0, mode0[j]] = energy[*, *, 0]
  Endif
  mode1 = where(mode_ind Eq 1, nmode1)
  If(nmode1 Gt 0) Then Begin
     For j = 0, nmode1-1 Do energy_out[0, 0, mode1[j]] = energy[*, *, 1]
  Endif
  mode2 = where(mode_ind Eq 2, nmode2)
  If(nmode2 Gt 0) Then Begin
     For j = 0, nmode2-1 Do energy_out[0, 0, mode2[j]] = energy[*, *, 2]
  Endif
  Return, energy_out
End

;+
;NAME:
; fa_esa_energy
;CALLING SEQUENCE:
; energy_full = fa_esa_energy(astruct, orig_names, index=index)
;INPUT:
; astruct - the structure, created by read_myCDF that should contain
;           at least one Virtual variable.
; orig_names - the list of varibles that exist in the structure.
; index - the virtual variable (index number) for which this
;         function is being called to compute.  If this isn't
;         defined, then the function will find the 1st virtual variable.
;HISTORY:
; hacked from CDAWlib apply_esa_qflag.pro, jmm, 2015-08-28
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-02-02 13:55:56 -0800 (Tue, 02 Feb 2016) $
; $LastChangedRevision: 19874 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_energy_v.pro $
;-
Function fa_esa_energy_v, astruct, orig_names, index=index

;This code assumes that the Component_0 is energy, the mode-dependent
;angle, Component_1 is the energy_shift variable and Component_2 the
;mode_ind variable
  
  atags = tag_names(astruct)    ;get the variable names.
  vv_tagnames=strarr(1)
  vv_tagindx = vv_names(astruct,names=vv_tagnames) ;find the virtual vars

  if keyword_set(index) then begin
     index = index
  endif else begin              ;get the 1st vv
     index = vv_tagindx[0]
     if (vv_tagindx[0] lt 0) then return, -1
  endelse
  
  c_0 = astruct.(index).COMPONENT_0
  c_1 = astruct.(index).COMPONENT_1
  if (c_0 ne '' && c_1 ne '') then begin
;energy variable
     var_idx = tagindex(c_0, atags)
     itags = tag_names(astruct.(var_idx)) ;tags for comp 0
     d0 = tagindex('DAT', itags)
     if(d0[0] ne -1) then energy = astruct.(var_idx).DAT else begin
        d0 = tagindex('HANDLE', itags)
        if(d0[0] ne -1) then handle_value, astruct.(var_idx).HANDLE, energy else begin
           message, /info, 'No component_0: '+c_0+' found.'
           return, astruct
        endelse
     endelse
     fillval = astruct.(var_idx).fillval
;mode_ind
     var_idx = tagindex(c_1, atags)
     itags = tag_names(astruct.(var_idx)) ;tags for comp 1
     d1 = tagindex('DAT', itags)
     if(d1[0] ne -1) then mode_ind = astruct.(var_idx).DAT else begin
        d1 = tagindex('HANDLE', itags)
        if(d1[0] ne -1) then handle_value, astruct.(var_idx).HANDLE, mode_ind else begin
           message, /info, 'No component_1: '+c_1+' found.'
           return, astruct
        endelse
      endelse
;That's all, fill the output variable
     energy_out = fa_esa_energy_array(energy, mode_ind, fillval=fillval)
;Looks like you need to add a "handle"
     temp = handle_create(value=energy_out)
     astruct.(index).HANDLE = temp
  endif

  return, astruct

end
