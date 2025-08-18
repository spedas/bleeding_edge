;+  
;NAME:
;
; thm_gui
;
;PURPOSE:
; GUI for THEMIS data analysis
;
;CALLING SEQUENCE:
; thm_gui
;
;INPUT:
; none
; 
; Keywords:
;   Reset - If set will reset all internal settings.  
;           Otherwise, it will try to load the state of the previous call.
;   template_filename - The file name of a previously saved themis template document,
;                   can be used to store user preferences and defaults.
;
;OUTPUT:
; none
;
;HISTORY:
; Made into a wrapper for spd_gui.pro, jmm, 2014-02-11
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-12 15:49:01 -0800 (Wed, 12 Feb 2014) $
;$LastChangedRevision: 14368 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_gui.pro $
;-----------------------------------------------------------------------------------
PRO thm_gui,reset=reset,template_filename=template_filename


  message, /info, 'THM_GUI is now a wrapper for SPD_GUI'

  spd_gui, reset=reset,template_filename=template_filename

 RETURN

END ;--------------------------------------------------------------------------------

