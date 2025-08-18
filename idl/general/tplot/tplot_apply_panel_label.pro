;+
;NAME:
;tplot_apply_panel_label
;PURPOSE:
;Applies a label to a panel, given an input structure from
;tplot_panel_label.pro,
;  opt_struct = {label:label, xpos:x, ypos:y, $
;                dq_set:dq_set, charsize:char}
;'dq_set' is set to 1 if xpos and ypos are in data coordinates,
; otherwise xpos and ypos are relative values
; Call this from MPLOT, SPECPLOT, BITPLOT, etc...
;HISTORY:
;2025-02-18, jmm. jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
Pro tplot_apply_panel_label, panel_label
  If(~is_struct(panel_label)) Then Return ;quietly
  If(panel_label.dq_set) Then Begin
;xpos has to be seconds from the start of the plot
     xyouts, panel_label.xpos, panel_label.ypos, panel_label.label, charsize=panel_label.charsize, color=panel_label.color
  Endif Else Begin
     xpos = !x.window[0] + panel_label.xpos*(!x.window[1]-!x.window[0])
     ypos = !y.window[0] + panel_label.ypos*(!y.window[1]-!y.window[0])
     xyouts,xpos,ypos, panel_label.label, /normal, charsize=panel_label.charsize, color=panel_label.color
  Endelse
End
