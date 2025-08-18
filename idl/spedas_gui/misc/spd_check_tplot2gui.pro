;+
; Procedure:
;  spd_check_tplot2gui
;
; Purpose:
;  Checks if a tplot variable can be loaded as a gui variable.
;
; Keywords:
;         varname: a single tplot variable name
;         tcheck: returns 1 if the tplot variable can be loaded to gui, 0 otherwise
;         error: if the variable cannot be loaded to gui, this contains the type of error
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2021-10-14 19:49:56 -0700 (Thu, 14 Oct 2021) $
; $LastChangedRevision: 30358 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/misc/spd_check_tplot2gui.pro $
;-

pro spd_check_tplot2gui, varname, tcheck=tcheck, error=error
  ; Checks if a tplot variable can be loaded as a gui variable.
  ; Similar checks to spd_ui_loaded_data::addData

  compile_opt idl2

  ; Initialize the returned keywords.
  tcheck = 0
  error = 'Unknown Error'

  ; Catch all unexpected errors.
  catch, err
  if err ne 0 then begin
    catch, /cancel
    tcheck = 0
    error = !error_state.msg
    return
  endif

  ; Check if variable exists.
  vars = tnames(varname)
  if n_elements(vars) ne 1 || vars[0] eq '' then begin
    error = 'Variable not found.'
    return
  endif

  ; Check the data it contains.
  get_data, varname, data=d,limits=l,dlimits=dl

  if ~is_struct(d) then begin
    error = 'Data does not have valid data structure.'
    return
  endif

  if ~in_set(tag_names(d),'X') then begin
    error = 'Data does not have valid X component.'
    return
  endif

  if ~is_num(d.x) then begin
    error = 'X component is not a numeric type.'
    return
  endif

  if ~in_set(tag_names(d),'Y') then begin
    error = 'Data does not have valid Y component.'
    return
  endif

  if ~is_num(d.y) then begin
    error = 'Y component is not a numeric type.'
    return
  endif

  ; Check data dimensions.
  dSize = dimen(d.y)
  dxSize = dimen(d.x)

  if n_elements(dxSize) gt 1 then begin
    error = 'GUI data model does not currently support data times with dimensions greater than 1.'
    return
  endif

  if n_elements(dSize) gt 2 then begin
    error = 'GUI data model does not currently support data with dimensions greater than 2.'
    return
  endif

  if dsize[0] ne n_elements(d.x) then begin
    error = 'X and Y components contain a different number of elements.'
    return
  endif

  ; No problems.
  tcheck = 1
  error = ''

end