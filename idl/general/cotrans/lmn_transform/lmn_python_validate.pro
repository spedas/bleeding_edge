
;+
; Procedure:
;  lmn_python_validate
;
; Purpose:
;  Creates a savefile with tplot variables that contain lmn_matrix_make data.
;
;  The savefile can used to compare the results of IDL lmn_matrix_make.pro
;  to the results of the similar python function in pyspedas.
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2025-04-13 15:29:48 -0700 (Sun, 13 Apr 2025) $
;$LastChangedRevision: 33259 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/lmn_transform/lmn_python_validate.pro $
;-

pro lmn_python_validate

  ; Load data
  del_data, '*'
  trange = ['2022-01-01', '2022-01-01 06:00:00']
  thm_load_fgm, trange=trange, probe='a', level='l2', data='fgl', coord='gsm', /get_support
  thm_load_state, trange=trange, probe='a', /get_support
  print, tnames()

  ; apply lmn_matrix_make
  pos = 'tha_state_pos_gsm'
  b = 'tha_fgl_gsm'
  out = 'tha_fgl_gsm_lmn_mat_hro'
  omni_bz = 'OMNI_solarwind_BZ'
  omni_p = 'OMNI_solarwind_P'
  lmn_matrix_make, pos, b, newname=out
  print, tnames()

  vars = [pos, pos+'_interpol', b, out, omni_p, omni_p+'_interpol', omni_bz, omni_bz+'_interpol']
  time_clip, vars, trange[0], trange[1], /replace

  ; Save the data
  ; The following will save a file 'lmn_python_validate.tplot' in the IDL working dir
  for i=0, n_elements(vars)-1 do begin
    tplot_rename, vars[i], vars[i] + '_idl'
    vars[i] = vars[i] + '_idl'
  endfor
  tplot_save, vars, filename='lmn_python_validate'
  ; Names saved: tha_state_pos_gsm_idl tha_state_pos_gsm_interpol_idl tha_fgl_gsm_idl tha_fgl_gsm_lmn_mat_hro_idl 
  ; OMNI_solarwind_P_idl OMNI_solarwind_P_interpol_idl OMNI_solarwind_BZ_idl OMNI_solarwind_BZ_interpol_idl
  print, "Names saved:", vars

  ; Plot the variables (optional)
  ; tplot, vars
end