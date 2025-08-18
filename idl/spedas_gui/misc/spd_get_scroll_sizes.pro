
;NAME:
; spd_get_scroll_sizes
;
;PURPOSE:
; Check the screen dimensions and return reasonable x and y thresholds for when scrollbars
; should be added.
;
;CALLING SEQUENCE:
; spd_get_scroll_sizes, xfrac=xfrac, yfrac=yfrac, scroll_needed=scroll_needed, $
;      x_scroll_size=x_scroll_size, y_scroll_size=y_scroll_size
;
;KEYWORDS:
;
;xfrac:         (Optional) Approximate fraction of the screen X dimension the panel should take up, defaults to 0.8
;
;yfrac:         (Optional) Approximate fraction of the screen Y dimension the panel should take up, defaults to 0.8
; 
;scroll_needed: Specifies a variable to receive a boolean flag, 1 if the display is small enough
;        worry about scroll bars, 0 otherwise
;        
;x_scroll_size: Specifies a variable to receive the suggested x_scroll_size value for the panel width
;
;y_scroll_size: Specifies a variable to receive the suggested y_scroll_size value for the panel height
;
;HISTORY:
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-04 13:39:57 -0800 (Fri, 04 Mar 2022) $
;$LastChangedRevision: 30649 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/misc/spd_get_scroll_sizes.pro $
;
;---------------------------------------------------------------------------------

pro spd_get_scroll_sizes,xfrac=xfrac,yfrac=yfrac,scroll_needed=scroll_needed,x_scroll_size=x_scroll_size,y_scroll_size=y_scroll_size
   if n_elements(xfrac) eq 0 then xfrac=0.8
   if n_elements(yfrac) eq 0 then yfrac=0.8
   dims = get_screen_size()
   if ( (dims[0] le 800) || (dims[1] le 1000)) then scroll_needed=1 else scroll_needed=0
   x_scroll_size = fix(dims[0]*xfrac)
   y_scroll_size = fix(dims[1]*yfrac)
   return
end