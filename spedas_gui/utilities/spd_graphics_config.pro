;+
;  PRO spd_graphics_config
;
;  This routine does just the graphics configuration for SPEDAS plug-ins.  It can be called from routines that
;  need to have a guaranteed graphics configuration without forcing the rest of the plug-in initialization
;  to be run.  This is done to avoid overwriting settings that may have been set by users later in their
;  session.
;  
;  Keywords:
;   colortable: overwrite the default colortable initialization
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-01-16 13:34:22 -0800 (Wed, 16 Jan 2019) $
; $LastChangedRevision: 26470 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_graphics_config.pro $
;
;-

pro spd_graphics_config,colortable=colortable


  ;ctable_file = file_retrieve(ctable_relpath, _extra=!themis)
  ;setenv,  'IDL_CT_FILE='+ctable_file

  ;This routine sets the IDL_CT_FILE env variable to a local file
  ;So that it doesn't need to be downloaded
 ; thmctpath

  if n_elements(colortable) eq 0 then colortable = 43     ; default color table

;                        Define POSTSCRIPT color table
  old_dev = !d.name             ;  save current device name
  set_plot,'PS'                 ;  change to PS so we can edit the font mapping
  loadct2,colortable
  device,/symbol,font_index=19  ;set font !19 to Symbol
  set_plot,old_dev              ;  revert to old device

;                        Color table for ordinary windows
  loadct2,colortable

;              Make black on white background
  !p.background = !d.table_size-1                   ; White background   (color table 34)
  !p.color=0                                        ; Black Pen
  !p.font = -1                                      ; Use default fonts


  if !d.name eq 'WIN' then begin
    device,decompose = 0
  endif

  if !d.name eq 'X' then begin
    ; device,pseudo_color=8  ;fixes color table problem for machines with 24-bit color
    device,decompose = 0
    if !version.os_family eq 'unix' then device,retain=2  ; Unix family does not provide backing store by default
  endif

end