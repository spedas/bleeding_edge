;+
;  PRO erg_graphics_config
;
;  This routine is basically equivalent to spd_graphics_config.pro included in the SPEDAS distribution. 
;  The differences are: 
;    - The graphic settings are done separately for the supported output devices: X, Z, WIN 
;    - An error/exception handler is implemented for the X-window device since it often 
;       encounters an error when invoked by a background process without connection to an X server. 
;  This routine has been made by forking from: 
;   spd_graphics_config.pro 
;       LastChangedBy: nikos 
;       LastChangedDate: 2016-10-06 12:31:28 -0700 (Thu, 06 Oct 2016) 
;       LastChangedRevision: 22054 
;       URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_graphics_config.pro 
;  
;  ### Description for the original spd_graphics_config ###
;  This routine does just the graphics configuration for themis.  It can be called from routines that
;  need to have a guaranteed graphics configuration without forcing the rest of the themis initialization
;  to be run.  This is done to avoid overwriting settings that may have been set by users later in their
;  session.
;  
;  Keywords:
;   colortable: overwrite the default colortable initialization
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;
;-
; A helper routine called by erg_graphics_config
pro black_on_white_bg
  !p.background = !d.table_size-1                   ; White background   (color table 34)
  !p.color=0                                        ; Black Pen
  !p.font = -1                                      ; Use default fonts
  
  return
end

pro erg_graphics_config,colortable=colortable, silent=silent


  ;ctable_file = file_retrieve(ctable_relpath, _extra=!themis)
  ;setenv,  'IDL_CT_FILE='+ctable_file

  ;This routine sets the IDL_CT_FILE env variable to a local file
  ;So that it doesn't need to be downloaded
 ; thmctpath

  if undefined(silent) then silent = 0 
  

  if n_elements(colortable) eq 0 then colortable = 43     ; default color table

;                        Define POSTSCRIPT color table
  old_dev = !d.name             ;  save current device name
  set_plot,'PS'                 ;  change to PS so we can edit the font mapping
  loadct2,colortable
  device,/symbol,font_index=19  ;set font !19 to Symbol
  set_plot,old_dev              ;  revert to old device


  
  case (!d.name) of
    'WIN': begin  ;For IDL on MS-Windows 
        loadct2, colortable
        black_on_white_bg
        device, decompose=0
        
    end
    'Z': begin  ;For Z-buffer 
        loadct2, colortable
        black_on_white_bg
        device, decompose=0
        
    end
    'X': begin
      catch, err
      if err ne 0 then begin
        dprint, !ERROR_STATE.MSG
        dprint, 'Unable to set the default color table by loadct2!' 
        dprint, 'Make sure the X-window environment is properly established.'
        catch, /cancel
        return
      endif
      
      loadct2, colortable
      black_on_white_bg
      device,decompose = 0
      if !version.os_family eq 'unix' then device,retain=2  ; Unix family does not provide backing store by default
      
    end
    else: begin
      dprint, 'Currently the following devices are supported: WIN, Z, X'
      loadct2, colortable
      black_on_white_bg
      device, decompose=0
      
    end
  endcase
  
  

end
