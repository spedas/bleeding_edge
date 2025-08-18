;+
;PROCEDURE:   win
;PURPOSE:
;  When there are multiple monitors, IDL defines a rectangular "super
;  monitor" that encompasses all physical monitors.  One of the physical
;  monitors is designated the "primary monitor" and the lower left corner
;  of that monitor is the origin of the coordinate system for the super
;  monitor.  XPOS and YPOS are used to position windows within the super
;  monitor; however, the coordinate system is not known in advance, and
;  when you attempt to place a window entirely or partially out of bounds,
;  it can appear in an unexpected location, depending on your window
;  server.  (IDL can only make a request.  The window server will try to
;  to honor that request, but if there's a problem the server may do 
;  something different and unexpected.)
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
;  keywords SETPRIME, TBAR, and TCALIB for more information.
;
;  If CONFIG=0 (default), win behaves exactly like window.  This allows
;  the routine to be used in public code, where the user may not know about
;  or does not want to use its functionality.
;
;USAGE:
;  win [, wnum [, monitor]] [, KEYWORD=value, ...]  ; normal usage
;
;  win, CONFIG={0|1} [, TBAR=value]  ; 0=disable, 1=enable
;
;  win, SHOW=N  ; identify the monitor(s) and corners for N seconds.
;
;EXAMPLES:
;  win, 0, /full
;    --> put a full-screen window in the primary monitor
;
;  win, 1, xsize=800, aspect=4./3., /secondary, dx=10, dy=10
;    --> put a 4:3 aspect window in the secondary monitor, offset by 10 pixels
;        from the top left corner
;
;  win, 2, clone=1, relative=1, dx=10, /top
;    --> put a clone of window 1 to the right of window 1 offset by 10 pixels
;        with the top edges aligned
;
;  win, 3, 0, clone=1, scale=0.6, /center
;    --> put a clone of window 1 scaled by 60% in the center of monitor 0
;
;  win, wnum, /free, key={sec:1, yf:1, xs:500, dx:10}
;    --> put a window with an index > 31 in the secondary monitor, full-screen in Y,
;        500 pixels in X; the assigned window number is returned in wnum
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
;       CONFIG:    An integer that controls the behavior of win.
;                  The first time win is called, it queries the OS
;                  to get the number, dimensions, and arrangement of
;                  the monitors.  This information is stored in a
;                  common block.
;
;                     0 = disabled: win acts like window (default)
;                     1 = enabled: win has full functionality
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
;       TBAR:      Title bar width in pixels.
;
;                  The standard WINDOW procedure does not account for the
;                  window title bar, but this procedure does, so windows 
;                  can be positioned precisely.  IDL does not have access
;                  to the title bar width, so this routine provides two
;                  defaults, depending on the operating system:
;
;                    MacOS    : TBAR = 22
;                    RedHat 8 : TBAR = 37
;
;                  For other X servers and Windows, use TCALIB (below) to
;                  calibrate the title bar width.  You can then set the 
;                  configuration in your IDL startup file, so you won't
;                  need to rerun the calibration:
;
;                    win, /config, tbar=N, /silent
;
;                  This value is persistent.
;
;       TCALIB:    Calibrate the title bar width by briefly creating two
;                  windows with the same dimensions and location but
;                  different (bogus) title bar widths.  The vertical offset
;                  between these two windows is used to calculate the actual
;                  title bar width.  This value is persistent.
;
;       STAT:      Output the current monitor configuration.  When this
;                  keyword is set, CONFIG will return the current monitor
;                  array, the primary and secondary monitor indices, and
;                  the title bar width.
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
;       LIST:      List the existing windows and their dimensions.
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
;                  XPOS and YPOS are ignored while win is enabled.
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
;       SILENT:    Shhh.
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
; $LastChangedDate: 2025-02-03 13:32:18 -0800 (Mon, 03 Feb 2025) $
; $LastChangedRevision: 33109 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/win.pro $
;
;CREATED BY:	David L. Mitchell  2020-06-03
;-
pro win, wnum, mnum, monitor=monitor, dx=dx, dy=dy, corner=corner, full=full, $
                  config=config, xsize=xsize, ysize=ysize, scale=scale, $
                  key=key, stat=stat, nofit=nofit, norm=norm, center=center, $
                  xcenter=xcenter, ycenter=ycenter, tbar=tbar2, xfull=xfull, $
                  yfull=yfull, aspect=aspect, show=show, secondary=secondary, $
                  relative=relative, top=top, bottom=bottom, right=right, left=left, $
                  middle=middle, clone=clone, setprime=setprime, silent=silent, $
                  tcalib=tcalib, xpos=xpos, ypos=ypos, list=list, _extra=extra

  @putwin_common
  @colors_com

  device, window_state=ws

; Query the operating system to get monitor information.
; Silently act like WINDOW until CONFIG is set.

  if (size(windex,/type) eq 0) then begin
    oInfo = obj_new('IDLsysMonitorInfo')
      mnames = oInfo->GetMonitorNames()
      numMons = oInfo->GetNumberOfMonitors()
      rects = oInfo->GetRectangles()
      primon = fix(oInfo->GetPrimaryMonitorIndex())
    obj_destroy, oInfo

    if (numMons gt 2) then begin
      j = sort(rects[0,1:*]) + 1
      rects = rects[*,[0,j]]
      primon = 1  ; left-most external
    endif

    mons = indgen(numMons)
    i = where(mons ne primon, count)
    if (count gt 0) then secmon = max(mons[i]) else secmon = primon

    mgeom = rects
    mgeom[1,*] = rects[3,primon] - rects[3,*] - rects[1,*]
    maxmon = fix(numMons) - 1
    primarymon = fix(primon)
    secondarymon = fix(secmon)

    tbar = 22           ; MacOS
    if (strmatch(mnames[0], ':?')) then begin
      tbar = 37         ; RedHat 8
      mgeom[3,0] -= 29  ; make space for command bar
    endif

    klist = ['CONFIG','STAT','SHOW','MONITOR','SECONDARY','DX','DY','NORM', $
             'CENTER','XCENTER','YCENTER','CORNER','SCALE','FULL','XFULL', $
             'YFULL','ASPECT','XSIZE','YSIZE','NOFIT','TBAR2','TCALIB','RELATIVE', $
             'TOP','BOTTOM','RIGHT','LEFT','MIDDLE','CLONE','SETPRIME','SILENT', $
             'XPOS','YPOS']

    windex = 0
  endif

; Alternate method of setting win keywords.  Except for XSIZE and YSIZE,
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

  blab = ~keyword_set(silent)

  if (keyword_set(stat) or keyword_set(show)) then begin
    if (~windex) then begin
      if (blab) then print,"Win is disabled (acts like window).  Use 'win, /config' to enable."
      config = {enable:0}
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
        win, /free, monitor=i, xsize=xs, ysize=ys, /center, title=''
        xyouts,0.5,0.35,strtrim(string(i),2),/norm,align=0.5,charsize=4,charthick=3,color=6
        xyouts,0.5,0.1,msg,/norm,align=0.5,charsize=1.5,charthick=1,color=6
        j = [j, !d.window]
      endfor

      for k=0,3 do begin
        win, /free, corner=k, xsize=150, ysize=100, dx=5, dy=5, title=''
        msg = 'Corner ' + strtrim(string(k),2)
        xyouts,0.5,0.5,msg,/norm,align=0.5,charsize=2,charthick=1,color=4
        j = [j, !d.window]
      endfor

      j = j[1:*]
      wait, fix(show[0]) > 5
      for i=0,(n_elements(j)-1) do wdelete, j[i]
    endif else begin
      if (blab) then print,"Monitor configuration:"
      j = sort(mgeom[1,0:maxmon])
      for i=maxmon,0,-1 do begin
        if (blab) then print, j[i], mgeom[2:3,j[i]], format='(2x,i2," : ",i4," x ",i4," ",$)'
        case i of
          primarymon   : msg = "(primary)"
          secondarymon : msg = "(secondary)"
          else         : msg = ""
        endcase
        if (blab) then print, msg
      endfor
      if n_elements(color_table) then begin
        if (size(ct_file,/type) eq 7) then begin
          cfile = file_basename(ct_file,'.tbl')
          case cfile of
            ''               : cstr = ''
            'spp_fld_colors' : cstr = 'SPP Fields '
            else             : cstr = cfile + ' '
          endcase
        endif else cstr = ''
        if (color_table ge 1000) then cstr = 'CSV '
        cstr += strtrim(string(color_table),2)
        if keyword_set(color_reverse) then cstr += " (reverse)"
      endif else cstr = "not defined"
      if (blab) then print,"Color table: ", cstr
      if n_elements(line_colors_index) then lstr = strtrim(string(line_colors_index),2) $
                                       else lstr = "not defined"
      if (blab) then print,"Line colors: ", lstr
      if (stat gt 1) then begin
        owin = fix(where(ws, count))
        if (count gt 0L) then begin
          mnum = replicate(-1, count)
          wsave = !d.window
          if (blab) then begin
            print,""
            print,"Open windows: "
            print,'   #   Xsize   Ysize   Monitor'
          endif
          for i=0,(count-1) do begin
            wset,owin[i]
            device, get_window_position=wpos
            xok = (wpos[0] ge mgeom[0,*]) and (wpos[0] lt mgeom[0,*]+mgeom[2,*])
            yok = (wpos[1] ge mgeom[1,*]) and (wpos[1] lt mgeom[1,*]+mgeom[3,*])
            mnum[i] = where(xok and yok)
            if (blab) then print,owin[i],!d.x_size,!d.y_size,mnum[i],format='(2x,i2,3x,i5,3x,i5,5x,i2)'
          endfor
          wset,wsave
          tplot_options, get=topt
          str_element, topt, 'window', twin, success=ok
          if (~ok) then twin = -1
          if (ok and ws[twin]) then tmon = mnum[where(owin eq twin)] else tmon = -1
        endif else if (blab) then print,'  No open windows'
      endif
      if (blab) then print,""
    endelse

    config = {enable:windex, geom:mgeom, nmons:(maxmon+1), primon:primarymon, secmon:secondarymon, tbar:tbar}
    if keyword_set(stat) then if (stat gt 1) then begin
      str_element, config, 'owin', owin, /add
      str_element, config, 'mnum', mnum, /add
      str_element, config, 'twin', twin, /add
      str_element, config, 'tmon', fix(tmon[0]), /add
    endif

    return
  endif

; List the currently existing windows.

  if keyword_set(list) then begin
    owin = fix(where(ws, count))
    mnum = -1
    if (count gt 0L) then begin
      mnum = replicate(-1L, count)
      wsave = !d.window
      if (blab) then begin
        print,"Open windows: "
        print,'   #   Xsize   Ysize   Monitor'
      endif
      for i=0,(count-1) do begin
        wset,owin[i]
        device, get_window_position=wpos
        xok = (wpos[0] ge mgeom[0,*]) and (wpos[0] lt mgeom[0,*]+mgeom[2,*])
        yok = (wpos[1] ge mgeom[1,*]) and (wpos[1] lt mgeom[1,*]+mgeom[3,*])
        mnum[i] = where(xok and yok)
        if (blab) then print,owin[i],!d.x_size,!d.y_size,mnum[i],format='(2x,i2,3x,i5,3x,i5,5x,i2)'
      endfor
      wset,wsave
    endif else if (blab) then print,'  No open windows'
    if (blab) then print,''
    config = {owin:owin, mnum:mnum}
    tplot_options, get=topt
    str_element, topt, 'window', twin, success=ok
    if (~ok) then twin = -1
    str_element, config, 'twin', twin, /add
    if (ok and ws[twin]) then tmon = mnum[where(owin eq twin)] else tmon = -1
    str_element, config, 'tmon', fix(tmon[0]), /add
    return
  endif

  exeunt = 0

; Title bar width

  if (size(tbar2,/type) gt 0) then begin
    tbar = fix(tbar2[0])
    tcalib = 0
    exeunt = 1
  endif

; Title bar calibration

  if keyword_set(tcalib) then begin
    t1 = 10
    t2 = 40
    xs = 200
    ys = 150
    undefine, w1, w2
    tbar = t1
    win, w1, /free, xsize=xs, ysize=ys, /center
    device, get_window_position=p1
    tbar = t2
    win, w2, /free, clone=w1, rel=w1
    device, get_window_position=p2
    wdelete, w1
    wdelete, w2
    tbar = t2 - (p2[1] - p1[1])
    print,"Title bar width: ", strtrim(string(tbar),2)
    blab = 0
    exeunt = 1
  endif

; Monitor priority

  case n_elements(setprime) of
     0   : ; do nothing
     1   : begin
             primarymon = fix(setprime[0]) < maxmon
             mons = indgen(numMons)
             i = where(mons ne primarymon, count)
             if (count gt 0) then secondarymon = max(mons[i]) else secondarymon = primarymon
             exeunt = 1
           end
    else : begin
             primarymon = fix(setprime[0]) < maxmon
             secondarymon = fix(setprime[1]) < maxmon
             exeunt = 1
           end
  endcase

; Monitor configuration

  if (size(config,/type) gt 0) then begin
    if (fix(config[0]) eq 0) then begin
      if (blab and windex) then print,"Win is disabled (acts like window)."
      blab = 0
      windex = 0
    endif else windex = 1
    exeunt = 1
  endif

; If there are any configuration changes, then exit before creating a window

  if (exeunt) then begin
    if (blab) then win, /stat
    return
  endif

; If win is disabled, then just pass everything to WINDOW

  if (~windex) then begin
    if (size(scale,/type) gt 0) then begin
      if (size(xsize,/type) gt 0) then xsize *= scale
      if (size(ysize,/type) gt 0) then ysize *= scale
    endif
    if (size(wnum,/type) gt 0) then window, wnum, xsize=xsize, ysize=ysize, xpos=xpos, ypos=ypos, _extra=extra $
                               else window, xsize=xsize, ysize=ysize, xpos=xpos, ypos=ypos, _extra=extra
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

  undefine, xpos, ypos  ; disable XPOS and YPOS --> use DX, DY instead

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

      monitor = primon  ; window placement is in OS coordinates
      xoff = mgeom[0, monitor]
      yoff = mgeom[1, monitor]
      xdim = mgeom[2, monitor]
      ydim = mgeom[3, monitor]
      corner = 2        ; origin at lower left
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
