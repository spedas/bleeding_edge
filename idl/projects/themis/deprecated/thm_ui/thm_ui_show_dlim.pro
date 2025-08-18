;+
;
;Name:
;THM_UI_SHOW_DLIM.PRO
;
;Syntax:
;  THM_UI_SHOW_DLIM ,tplot_name, group=group
;    where,
;    tplot_name is the name string or index number of a single tplot
;      variable.
;
;Purpose:
;  Display the output of help,/structure for the default limits
;    structure of specified tplot variable.
;
;Keywords:
;  group
;
;Example:
;  This is a subroutine to THM_GUI.PRO -- not intended for outside
;    calls (but it wil work).
;
;Author: W.M.Feuerstein, 2008/2/4
;
;Modification History:
;  Padded names array with white space to make widget output left
;    justified, WMF.
;  Fixed group kw (must die with parent), fixed Windows bug,
;    added DLIMITS.DATA_ATT info (if present), WMF, 3/5/2008.
;
;History:
;  A J. McTiernan request.
;  Adapted from TPLOT_LABEL.PRO
;
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_show_dlim.pro $
;-

PRO thm_ui_show_dlim_event, event

END

PRO thm_ui_show_dlim, tplot_name, GROUP = GROUP

if not(keyword_set(tplot_name)) then return

;Get default limit structure info:
;=================================
get_data,tplot_name,dlim=dlim
help,dlim,/structure,output=info
names=['DLIMITS:','=========',info]

;Does dlim exist?
;================
dlim_exists = size(dlim,/type) eq 8 ? 1 : 0

;If yes, then test for the presence of DATA_ATT:
;===============================================
data_att_exists = $
  (where(tag_names(dlim) eq 'DATA_ATT'))[0] ne -1 ? 1 : 0

;If yes, then run help and concatinate info:
;===========================================
if data_att_exists then begin
  help,dlim.data_att,/structure,output=info
  names=[names,' ','DLIMITS.DATA_ATT:','================',info]
endif

;Note number of names (including null and undefined):
;====================================================
n_names=n_elements(names)

;If the list exists, print to widget:
;====================================
if n_names ge 1 and dlim_exists ne 0 then begin


  ;Note width of widest variable name:
  ;===================================
  strlen=strlen(names)
  maxwidth=max(strlen)
  maxwidth=maxwidth>25          ;but make it wide enough for title.
  xsize = 8.1*maxwidth          ;Make the box and frame wide enough.

  base = widget_base(title = 'Tplot variable "'+string(tplot_name)+ $
    '" default limits structure(s):', $
    /COLUMN, $                  ;Organize subsequent widgets in columns.
    xsize = xsize, $    ;Make it wide enough that the
			; base's title shows completely.
    ysize=n_names*15.,$ ;Make it tall enough to hold the list (limit?)
    group_leader=group) ;Make sure widget dies with THEMIS GUI.


  ;Join the name array into a scalar w/ linefeed delimiters and
  ;pad white space on right so output is left justified (label widget
  ;seems to center):
  ;=================
  pad = maxwidth-strlen
  for i = 0,n_elements(names)-1 do $
    if pad[i] gt 0 then names[i]=names[i]+strjoin( replicate(' ',pad[i]))

  label1 = widget_text(base, VALUE = names, /frame, $
    xsize = xsize, $    ;Make it wide enough that the
			; base's title shows completely.
    ysize=n_names*15.)  ;Make it tall enough to hold the list (limit?)

endif else begin           ;Otherwise the tplot name is not valid.
			   ;Notify the user.

  base = widget_base(title = tplot_name+': DEFAULT LIMIT STRUCTURE', $
     /COLUMN, $                  ;Organize subsequent widgets in columns.
     xsize = 250., $
     ysize=30., $
     group_leader=group)

     label1 = widget_label(base, $
     	      VALUE = 'THE SPECIFIED TPLOT NAME IS INVALID.');,$
     		       ;/FRAME)

endelse

; Realize the widgets:
WIDGET_CONTROL, base, /REALIZE

; Hand off to the XMANAGER:
XMANAGER, 'TPLOT_LABEL', base, group_leader=grou, /NO_BLOCK

END


