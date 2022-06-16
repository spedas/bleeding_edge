;+
;PROCEDURE:   putwin
;PURPOSE:
;  When there are multiple monitors, IDL defines a rectangular "super
;  monitor" that encompasses all physical monitors.  One of the physical
;  monitors is designated the "primary monitor" and the lower left corner
;  of that monitor is the origin of the coordinate system for the super
;  monitor.  XPOS and YPOS are used to position windows within the super
;  monitor; however, the coordinate system may not be known in advance, 
;  strange things happen when you exceed the bounds of the super monitor, 
;  and parts of the super monitor are not covered by a physical monitor, 
;  so it's not obvious how to set XPOS and YPOS to place a window where
;  you want.
;
;  This procedure divides the super monitor back into physical monitors
;  and allows you to choose a monitor and place a window relative to the
;  edges of that monitor (or in the center, or full screen).  You can 
;  also place a new window next to and aligned with an existing window.
;  It is also possible to clone an existing window and place it as above.
;  In short, this is a user-friendly version of WINDOW designed for a 
;  multiple monitor setup.  It allows you to create new windows within a
;  routine and arrange them accurately in specified monitors or next to
;  other windows without the need for resizing and moving them with the 
;  mouse.
;
;  On first call, this routine queries the OS to get the number, sizes, 
;  and arrangement of the physical monitors.  This works well on Mac 
;  systems but has not been thoroughly tested on other platforms.  See
;  keywords CONFIG and TBAR for more information.
;
;  If CONFIG=0 (default), putwin behaves exactly like window.  This allows
;  the routine to be used in public code, where the user may not know about
;  or does not want to use its functionality.
;
;USAGE:
;  putwin [, wnum [, monitor]] [, KEYWORD=value, ...]  ; normal usage
;
;  putwin, CONFIG={0|1} [, TBAR=value]  ; 0=disable, 1=enable
;
;  putwin, SHOW=N  ; identify the monitor(s) and corners for N seconds.
;
;EXAMPLES:
;  putwin, 0, /full
;    --> put a full-screen window in the primary monitor
;
;  putwin, 1, xsize=800, aspect=4./3., /secondary, dx=10, dy=10
;    --> put a 4:3 aspect window in the secondary monitor, offset by 10 pixels
;        from the top left corner
;
;  putwin, 2, clone=1, relative=1, dx=10, /top
;    --> put a clone of window 1 to the right of window 1 offset by 10 pixels
;        with the top edges aligned
;
;  putwin, 3, 0, clone=1, scale=0.6, /center
;    --> put a clone of window 1 scaled by 60% in the center of monitor 0
;
;INPUTS:
;       wnum:      Window number.  Can be an integer from 0 to 31.
;                  Default: next free widow number > 31.
;
;                  This can also be set to a variable name, which will
;                  return the window number chosen.
;
;       monitor:   Monitor number.  Can also be set by keyword (see
;                  below), but this method takes precedence.  Only the
;                  second input will be interpreted as a monitor number.
;                  If there's only one input, it's interpreted as the 
;                  window number.
;
;                  If there is more than one monitor, this routine 
;                  defines a "primary monitor", where graphics windows
;                  appear if no monitor is specified.  See keyword
;                  SETPRIME for details.
;
;KEYWORDS:
;       Accepts all keywords for WINDOW.  In addition, the following
;       are defined:
;
;       CONFIG:    An integer that controls the behavior of putwin.
;                  The first time putwin is called, it queries the OS
;                  to get the number, dimensions, and arrangement of
;                  the monitors.  This information is stored in a
;                  common block.
;
;                     0 = disabled: putwin acts like window (default)
;                     1 = enabled: putwin has full functionality
;
;       SETPRIME:  Set the primary (and secondary) monitors manually.
;                  The first element is the primary monitor number, and
;                  the second element, if present, is the secondary
;                  monitor number.  These values are persistent.
;
;                  Default:
;                    primary monitor = left-most external monitor
;                    secondary monitor = highest numbered non-primary
;
;       TBAR:      Title bar width in pixels.  Default = 22.
;
;                  The standard WINDOW procedure does not account for
;                  the window title bar width, so that widows placed
;                  along the bottom of a monitor are clipped.  This
;                  procedure fixes that issue.
;
;                  Window positioning will not be precise until this
;                  is set properly.  IDL does not have access to this
;                  piece of information, so you'll have to figure it
;                  out.  This value is persistent.
;
;       STAT:      Output the current monitor configuration.  When 
;                  this keyword is set, CONFIG will return the current 
;                  monitor array and the primary and secondary monitor
;                  indices.
;
;       SHOW:      Place a small window in each monitor for 5 sec to 
;                  identify the monitor numbers and which are primary and
;                  secondary.  In addition, place four small windows in the
;                  corners of the primary monitor to identify the corner 
;                  numbers (keyword CORNER).
;
;                  Set this keyword to a number N > 5 to display the small
;                  windows for N seconds.
;
;       MONITOR:   Put window in this monitor.  If no monitor is set by
;                  input or keyword, then the new window is placed in
;                  the primary monitor.
;
;       SECONDARY: Put window in the secondary monitor.
;
;       DX:        Horizontal offset from left or right edge (pixels).
;                    If DX is positive, offset is from left.
;                    If DX is negative, offset is from right.
;                  Replaces XPOS.  Default = 0.
;
;       DY:        Vertical offset from top or bottom edge (pixels).
;                    If DY is positive, offset is from top.
;                    If DY is negative, offset is from bottom.
;                  Replaces YPOS.  Default = 0.
;
;                  Note: XPOS and YPOS only work if CONFIG = 0.  They
;                  refer to position on a rectangular "super monitor"
;                  that encompasses all physical monitors.
;
;       RELATIVE:  Set this keyword to an existing window number.  Then
;                  DX and DY specify offsets of the new window location
;                  from the perimeter of the existing window.
;                    If DX (DY) is positive, place window right (above).
;                    If DX (DY) is negative, place window left (below).
;                  Usually, DX and/or DY are non-zero, in which case the
;                  new window is placed around the perimeter of the 
;                  existing window.  However, when DX and DY are both 
;                  zero, the new window is placed on top of the existing 
;                  window, with the top left corners aligned.
;
;                  If RELATIVE is set, NORM=0 and NOFIT=1 are enforced.
;
;       TOP:       If RELATIVE is set and DY=0, align the top edges of
;                  the windows.  Default.
;
;       LEFT:      If RELATIVE is set and DX=0, align the left edges of
;                  the windows.  Default.
;
;       BOTTOM:    If RELATIVE is set and DY=0, align the bottom edges of
;                  the windows.
;
;       RIGHT:     If RELATIVE is set and DX=0, align the right edges of
;                  the windows.
;
;       MIDDLE:    If RELATIVE is set and DX=0 (DY=0), center the two
;                  windows vertically (horizontally).
;
;       CLONE:     Create a new window with the same dimensions as the
;                  (existing) window specified by this keyword.  SCALE
;                  can then be used to shrink/expand the window while
;                  maintaining the aspect ratio.  Unless NOFIT is set,
;                  the clone is allowed to move around and shrink/expand
;                  so that it fits entirely on the monitor.
;
;       CORNER:    Alternate method for determining which corner to 
;                  place window.  If this keyword is set, then only the
;                  absolute values of DX and DY are used and specify
;                  offsets from the selected corner.  Corners are
;                  numbered like reading a book:
;
;                    0 = top left (default)
;                    1 = top right
;                    2 = bottom left
;                    3 = bottom right
;
;       NORM:      Measure DX and DY in normalized coordinates (0-1)
;                  instead of pixels.
;
;       XCENTER:   Center the window horizontally in the monitor.
;
;       YCENTER:   Center the window vertically in the monitor.
;
;       CENTER:    Center the window in both X and Y.
;
;       SCALE:     Scale factor for setting the window size.  If no
;                  window size is specified, then SCALE is relative
;                  to the default size: 1/4 of the monitor size.
;                  Default = 1.
;
;       NOFIT:     If the combination of XSIZE, YSIZE, SCALE, DX and
;                  DY cause the window to extend beyond the monitor,
;                  first DX and DY, then XSIZE and YSIZE are reduced
;                  until the window does fit.  If ASPECT is set, then
;                  the window is further reduced, if necessary, to 
;                  maintain the aspect ratio.  Set NOFIT to disable
;                  this behavior and create the window as requested.
;
;       XFULL:     Make the window full-screen in X.
;                  (Ignore XSIZE, DX.)
;
;       YFULL:     Make the window full-screen in Y.
;                  (Ignore YSIZE, DY.)
;
;       FULL:      If set, make a full-screen window in MONITOR.
;                  (Ignore XSIZE, YSIZE, DX, DY, SCALE, ASPECT.)
;
;       ASPECT:    Aspect ratio: XSIZE/YSIZE.  If one dimension is
;                  set with XSIZE, YSIZE, XFULL, or YFULL, this
;                  keyword sets the other dimension.
;
;       KEY:       A structure containing any of the above keywords
;                  plus XSIZE and YSIZE:
;
;                    {KEYWORD:value, KEYWORD:value, ...}
;
;                  Case folded minimum matching is used to match tag
;                  names in this structure to valid keywords.  For
;                  example:
;
;                    {f:1, mon:2} is interpreted as FULL=1, MONITOR=2.
;
;                  Unrecognized or ambiguous tag names generate an
;                  error message, and no window is created.
;
;                  Keywords set using this mechanism take precedence.
;                  All other keywords for WINDOW must be passed
;                  separately in the usual way.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-06-15 11:56:55 -0700 (Wed, 15 Jun 2022) $
; $LastChangedRevision: 30859 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/putwin.pro $
;
;CREATED BY:	David L. Mitchell  2020-06-03
;-
pro putwin, wnum, mnum, monitor=monitor, dx=dx, dy=dy, corner=corner, full=full, $
                  config=config, xsize=xsize, ysize=ysize, scale=scale, $
                  key=key, stat=stat, nofit=nofit, norm=norm, center=center, $
                  xcenter=xcenter, ycenter=ycenter, tbar=tbar2, xfull=xfull, $
                  yfull=yfull, aspect=aspect, show=show, secondary=secondary, $
                  relative=relative, top=top, bottom=bottom, right=right, left=left, $
                  middle=middle, clone=clone, setprime=setprime, _extra=extra

  @putwin_common

; Query the operating system to get monitor information.
; Silently act like WINDOW until CONFIG is set.

  if (size(windex,/type) eq 0) then begin
    oInfo = obj_new('IDLsysMonitorInfo')
      numMons = oInfo->GetNumberOfMonitors()
      rects = oInfo->GetRectangles()
      primon = oInfo->GetPrimaryMonitorIndex()
    obj_destroy, oInfo

    if (numMons gt 2) then primon = min(rects[0,1:*]) + 1L  ; left-most external

    mons = indgen(numMons)
    i = where(mons ne primon, count)
    if (count gt 0) then secmon = max(mons[i]) else secmon = primon

    mgeom = rects
    mgeom[1,*] = rects[3,primon] - rects[3,*] - rects[1,*]
    maxmon = numMons - 1
    primarymon = primon
    secondarymon = secmon

    klist = ['CONFIG','STAT','SHOW','MONITOR','SECONDARY','DX','DY','NORM', $
             'CENTER','XCENTER','YCENTER','CORNER','SCALE','FULL','XFULL', $
             'YFULL','ASPECT','XSIZE','YSIZE','NOFIT','TBAR2','RELATIVE', $
             'TOP','BOTTOM','RIGHT','LEFT','MIDDLE','CLONE','SETPRIME']

    windex = 0
  endif

; Alternate method of setting PUTWIN keywords.  Except for XSIZE and YSIZE,
; all keywords for WINDOW must be passed separately in the usual way.

  if (size(key,/type) eq 8) then begin
    ktag = tag_names(key)
    for j=0,(n_elements(ktag)-1) do begin
      ok = 0
      i = strmatch(klist, ktag[j]+'*', /fold)
      case (total(i)) of
          0  : print, "Keyword not recognized: ", ktag[j]
          1  : ok = execute((klist[where(i eq 1)])[0] + ' = key.(j)',0,1)
        else : print, "Keyword ambiguous: ", ktag[j]
      endcase
      if (not ok) then return
    endfor
  endif

; Output the current monitor configuration.

  if (keyword_set(stat) or keyword_set(show)) then begin
    if (~windex) then begin
      print,"Putwin is disabled (acts like window).  Use 'putwin, /config' to enable."
      return
    endif

    if keyword_set(show) then begin
      j = -1
      for i=0,maxmon do begin
        case i of
          primarymon   : msg = "(primary)"
          secondarymon : msg = "(secondary)"
          else         : msg = ""
        endcase
        xs = mgeom[2,i]/10.
        ys = mgeom[3,i]/10.
        putwin, /free, monitor=i, xsize=xs, ysize=ys, /center, title=''
        xyouts,0.5,0.35,strtrim(string(i),2),/norm,align=0.5,charsize=4,charthick=3,color=6
        xyouts,0.5,0.1,msg,/norm,align=0.5,charsize=1.5,charthick=1,color=6
        j = [j, !d.window]
      endfor

      for k=0,3 do begin
        putwin, /free, corner=k, xsize=150, ysize=100, dx=5, dy=5, title=''
        msg = 'Corner ' + strtrim(string(k),2)
        xyouts,0.5,0.5,msg,/norm,align=0.5,charsize=2,charthick=1,color=4
        j = [j, !d.window]
      endfor

      j = j[1:*]
      wait, fix(show[0]) > 5
      for i=0,(n_elements(j)-1) do wdelete, j[i]
    endif else begin
      print,"Monitor configuration:"
      j = sort(mgeom[1,0:maxmon])
      for i=maxmon,0,-1 do begin
        print, j[i], mgeom[2:3,j[i]], format='(2x,i2," : ",i4," x ",i4," ",$)'
        case i of
          primarymon   : msg = "(primary)"
          secondarymon : msg = "(secondary)"
          else         : msg = ""
        endcase
        print, msg
      endfor
      print,""
    endelse

    config = {geom:mgeom, primon:primarymon, secmon:secondarymon, tbar:tbar}

    return
  endif

; Title bar width

  if (size(tbar2,/type) gt 0) then tbar = fix(tbar2[0])
  if (size(tbar,/type) eq 0) then tbar = 22

; Monitor priority

  nset = n_elements(setprime)
  if (nset gt 0) then begin
    if (nset eq 1) then begin
      primon = fix(setprime[0]) < maxmon
      mons = indgen(numMons)
      i = where(mons ne primon, count)
      if (count gt 0) then secmon = max(mons[i]) else secmon = primon
      primarymon = primon
      secondarymon = secmon
    endif else begin
      primon = fix(setprime[0]) < maxmon
      secmon = fix(setprime[1]) < maxmon
      primarymon = primon
      secondarymon = secmon
    endelse
    putwin,/stat
    return
  endif

; Monitor configuration

  if (size(config,/type) gt 0) then begin

    if (fix(config[0]) eq 0) then begin
      if (windex eq 1) then print,"Putwin is disabled (acts like window)."
      windex = 0
    endif else begin
      windex = 1
      putwin, /stat
    endelse

    return
  endif

; If no configuration is set, then just pass everything to WINDOW

  if (~windex) then begin
    if (size(scale,/type) gt 0) then begin
      if (size(xsize,/type) gt 0) then xsize *= scale
      if (size(ysize,/type) gt 0) then ysize *= scale
    endif
    if (size(wnum,/type) gt 0) then window, wnum, xsize=xsize, ysize=ysize, _extra=extra $
                               else window, xsize=xsize, ysize=ysize, _extra=extra
    return
  endif

; Choose monitor

  if (n_elements(wnum) eq 0) then wnum = -1 else wnum = fix(wnum[0])
  if (size(mnum,/type) gt 0) then monitor = fix(mnum[0])
  if (n_elements(monitor) eq 0) then begin
    monitor = primarymon
    if keyword_set(secondary) then monitor = secondarymon
  endif else monitor = fix(monitor[0])
  monitor = (monitor > 0) < maxmon
  mnum = monitor

  xoff = mgeom[0, monitor]          ; horizontal offset
  yoff = mgeom[1, monitor]          ; vertical offset
  xdim = mgeom[2, monitor]          ; horizontal dimension
  ydim = mgeom[3, monitor]          ; vertical dimension

; Window dimensions

  if (size(clone,/type) gt 0) then begin
    cmd = 'wset, ' + strtrim(string(fix(clone[0])),2)
    ok = execute(cmd,0,1)
    if (ok) then begin
      xsize = !d.x_size
      ysize = !d.y_size
      aspect = float(xsize)/float(ysize)
    endif else begin
      print,"Window ",strmid(cmd,6)," does not exist."
      return
    endelse
  endif

  if (size(aspect,/type) gt 0) then begin
    if (n_elements(xsize) gt 0) then begin
      ysize = float(xsize[0])/aspect
    endif else begin
      if (n_elements(ysize) gt 0) then xsize = float(ysize[0])*aspect
    endelse
    if ((n_elements(xsize) eq 0) and (n_elements(ysize) eq 0)) then begin
      ysize = ydim/2
      xsize = float(ysize[0])*aspect
    endif
  endif

  if (n_elements(xsize) eq 0) then xsize = (xdim < 2560)/2
  if (n_elements(ysize) eq 0) then ysize = ydim/2
  if (n_elements(scale) eq 0) then scale = 1.
  xsize = fix(float(xsize[0])*scale)
  ysize = fix(float(ysize[0])*scale)

; Window placement within monitor

  if (n_elements(dx) eq 0) then dx = 0
  if (n_elements(dy) eq 0) then dy = 0

  if (size(relative,/type) gt 0) then begin
    cmd = 'wset, ' + strtrim(string(fix(relative[0])),2)
    ok = execute(cmd,0,1)
    if (ok) then begin
      relative = !d.window
      device, get_window_position=wpos

      dx1 = wpos[0]
      if (dx lt 0) then dx1 -= (xsize - dx)
      if (dx gt 0) then dx1 += (!d.x_size + dx)
      if ((dx eq 0) and keyword_set(right)) then dx1 += (!d.x_size - xsize)
      if ((dx eq 0) and keyword_set(middle)) then dx1 += (!d.x_size - xsize)/2
      dx = dx1

      if not keyword_set(bottom) then top = 1  ; default is to align top edges
      if keyword_set(middle) then top = 0

      dy1 = wpos[1] - 1  ; not sure why there's a 1-pixel offset
      if (dy lt 0) then dy1 -= (ysize + tbar - dy)
      if (dy gt 0) then dy1 += (!d.y_size + tbar + dy)
      if ((dy eq 0) and keyword_set(top)) then dy1 += (!d.y_size - ysize)
      if ((dy eq 0) and keyword_set(middle)) then dy1 += (!d.y_size - ysize)/2
      dy = dy1

      monitor = primarymon
      corner = 2
      nofit = 1
    endif else begin
      print,"Window ",strmid(cmd,6)," does not exist."
      return
    endelse
  endif else relative = -1

  if keyword_set(norm) then begin
    dx *= xdim
    dy *= ydim
  endif

  if keyword_set(center) then begin
    xcenter = 1
    ycenter = 1
  endif
  if keyword_set(xcenter) then dx = (xdim - xsize)/2
  if keyword_set(ycenter) then dy = (ydim - ysize)/2
  dx = fix(dx[0])
  dy = fix(dy[0])

  if (n_elements(corner) eq 0) then begin
    corner = 0
    if (dx lt 0) then begin
      if (dy lt 0) then corner = 3 else corner = 1
    endif else begin
      if (dy lt 0) then corner = 2 else corner = 0
    endelse
  endif else corner = abs(fix(corner[0])) mod 4
  if (relative lt 0) then begin
    dx = abs(dx)
    dy = abs(dy)
  endif

; Override dimensions and placement if full-screen window requested

  if keyword_set(full) then begin
    xfull = 1
    yfull = 1
    undefine, aspect
  endif

  if keyword_set(xfull) then begin
    xsize = xdim
    dx = 0
    if (size(aspect,/type) gt 0) then ysize = fix(float(xsize)/aspect)
  endif

  if keyword_set(yfull) then begin
    ysize = ydim - tbar
    dy = 0
    if (size(aspect,/type) gt 0) then xsize = fix(float(ysize)*aspect)
  endif

; Make sure window will fit by moving, then shrinking if necessary

  if ~keyword_set(nofit) then begin
    dx = dx < ((xdim - xsize) > 0)
    dy = dy < ((ydim - tbar - ysize) > 0)
    xsize = xsize < (xdim - dx)
    ysize = ysize < (ydim - tbar - dy)
    if (size(aspect,/type) gt 0) then begin
      asp = float(xsize)/float(ysize)
      if (asp gt aspect) then xsize = fix(float(ysize)*aspect) $
                         else ysize = fix(float(xsize)/aspect)
    endif
  endif

; Place window relative to corner

  case corner of
    0 : begin  ; top left
          x0 = xoff + dx
          y0 = yoff + (ydim - ysize) - dy
        end
    1 : begin  ; top right
          x0 = xoff + (xdim - xsize) - dx
          y0 = yoff + (ydim - ysize) - dy
        end
    2 : begin  ; bottom left
          x0 = xoff + dx
          y0 = yoff + tbar + dy
        end
    3 : begin  ; bottom right
          x0 = xoff + (xdim - xsize) - dx
          y0 = yoff + tbar + dy
        end
    else :     ; do nothing
  endcase

; Finally, create the window

  if ((wnum lt 0) or (wnum gt 31)) then begin
    window, /free, xpos=x0, ypos=y0, xsize=xsize, ysize=ysize, _extra=extra
  endif else begin
    window, wnum, xpos=x0, ypos=y0, xsize=xsize, ysize=ysize, _extra=extra
  endelse
  wnum = fix(!d.window)

  return

end
