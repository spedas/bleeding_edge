;+
;NAME:
;
; spedas_gui
;
;PURPOSE:
; Starts spd_gui, the GUI for SPEDAS data analysis
;
;CALLING SEQUENCE:
; spedas
;
;INPUT:
; none
;
; Keywords:
;   Reset - If set will reset all internal settings.
;           Otherwise, it will try to load the state of the previous call.
;   template_filename - The file name of a previously saved spedas template document,
;                   can be used to store user preferences and defaults.
;
;OUTPUT:
; none
;
;HISTORY:
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2018-10-16 10:54:43 -0700 (Tue, 16 Oct 2018) $
;$LastChangedRevision: 25985 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/spedas_gui.pro $
;-----------------------------------------------------------------------------------

pro spedas_gui, reset=reset,template_filename=template_filename

  spd_gui,reset=reset,template_filename=template_filename

end
