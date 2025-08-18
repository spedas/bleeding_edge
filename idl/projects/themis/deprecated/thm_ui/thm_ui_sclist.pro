;+
;NAME:
; thm_ui_sclist
;PURPOSE:
; creates an array for the different themis spacecraft, to be used in
; a list widget
;CALLING SEQUENCE:
; sclist = thm_ui_sclist()
;INPUT:
; none
;OUTPUT:
; sclist = ['THA', 'THB', 'THC', 'THD', 'THE']
;
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_sclist.pro $
;
;-
Function thm_ui_sclist

  Return, ['THA', 'THB', 'THC', 'THD', 'THE']
End
