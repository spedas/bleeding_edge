;+
; PROCEDURE:
;         juno_init
;
; PURPOSE:
;         Initializes system variables for Juno
;
; KEYWORDS:
;         
;
;
; OUTPUT:
;
; EXAMPLE:
;
; NOTES:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-12-05 12:03:15 -0800 (Mon, 05 Dec 2016) $
;$LastChangedRevision: 22436 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/juno/juno_init.pro $
;-

pro juno_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, $
  no_color_setup=no_color_setup,no_download=no_download,colortable=colortable

  defsysv,'!juno',exists=exists
  if not keyword_set(exists) then begin
    defsysv,'!juno', file_retrieve(/structure_format)
  endif

  if keyword_set(reset) then !juno.init=0

  if !juno.init ne 0 then begin
    ;Assure that trailing slashes exist on data directories
    !juno.local_data_dir = spd_addslash(!juno.local_data_dir)
    !juno.remote_data_dir = spd_addslash(!juno.remote_data_dir)
    return
  endif


  !juno = file_retrieve(/structure_format)    ; force setting of all elements to default values.
  
  if keyword_set(local_data_dir) then begin 
    !juno.local_data_dir = spd_addslash(local_data_dir)
  endif else !juno.local_data_dir =  spd_default_local_data_dir() + 'juno/'

  if keyword_set(remote_data_dir) then begin 
    !juno.remote_data_dir = spd_addslash(remote_data_dir)
  endif else !juno.remote_data_dir = 'http://jupiter.physics.uiowa.edu/das/'

  if not keyword_set(no_color_setup) then begin
    spd_graphics_config,colortable=colortable
  endif ; no_color_setup
  
   if !prompt ne 'Juno> ' then !prompt = 'Juno> '
end