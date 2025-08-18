;+
;PROCEDURE:   revvid
;PURPOSE:
;  Swaps !p.color and !p.background to switch between a light and
;  dark background.
;
;USAGE:
;  revvid [, KEYWORD=value]
;
;INPUTS:
;   none:    A simple toggle.
;
;KEYWORDS:
;   WHITE:   Make !p.background the lighter color (often white) and 
;            !p.color the darker color (often black).
;
;   BLACK:   Make !p.background the darker color (often black) and 
;            !p.color the lighter color (often white).
;
;SEE ALSO:
;   line_colors to set custom line, background and foreground colors.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-03-05 09:49:26 -0800 (Sun, 05 Mar 2023) $
; $LastChangedRevision: 31585 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/revvid.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro revvid, white=white, black=black

  foreground = !p.color
  background = !p.background

  white = keyword_set(white)
  black = keyword_set(black)

  if (white || black) then begin
    tvlct, r, g, b, /get
    cols = [0,255]  ; foreground and background colors assumed to be at the ends
    i = sqrt(float(r[cols])^2. + float(g[cols])^2. + float(b[cols])^2.)
    i_min = min(i, dark)
    i_max = max(i, lite)

    if (white) then begin
      foreground = cols[lite]
      background = cols[dark]
    endif else begin
      foreground = cols[dark]
      background = cols[lite]
    endelse
  endif

  !p.color = background
  !p.background = foreground

  i = find_handle('alt_lab',verbose=-2)  ; special case -- not useful for most people
  if (i gt 0) then begin
    get_data,'alt_lab',alim=lim
    options,'alt_lab','colors',[lim.colors[0:2],!p.color]
  endif

  return

end
