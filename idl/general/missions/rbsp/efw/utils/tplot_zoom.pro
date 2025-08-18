;+
; NAME:
;   tplot_zoom (procedure)
;
; PURPOSE:
;   This is basically a wrapper of some of the functions of tlimit and timebar.
;
; CATEGORY:
;   Widget
;
; CALLING SEQUENCE:
;   tplot_zoom, reset = reset, horizontal = horizontal
;
;   Use following calls to change the styles of time bars and y-bars (horizontal
;   bars).
;   
;     tplot_zoom_set_ybar, linestyle = linestyle, color = color, $
;       thick = thick, reset = reset
;     tplot_zoom_set_tbar, linestyle = linestyle, color = color, $
;       thick = thick, reset = reset
;
; KEYWORDS:
;   /reset: In, optional
;         If set, the common block tplot_zoom_com will be reset.
;   /horizontal: In, optional
;         If set, the shape of the widget will be a horizontal bar.
;
; INPUTS:   
;   None.
;
; SEE ALSO:
;   tplot, tlimit, ctime, timebar
;
; MODIFICATION HISTORY:
;   2011-09-06: Created by Jianbao Tao (JBT) at CU/LASP for REE, JBT's PhD
;               advisor, to demo tplot capabilities in a MMS meeting.
;   2012-06-15: JBT, CU/LASP. 
;         1. Updated the documentation header.
;         2. Cleaned the code.
;   2012-06-26: JBT, CU/LASP. (Obsolete comment. JBT, 2012-10-31)
;         1. Added more comments.
;         2. Replaced 'Zoom In', 'Zoom Out', 'Pan Forward', and 'Pan Backward'
;            buttons with ' + + ', '  +  ', '  -  ', ' - - ', ' < < ', '  <  ',
;            '  >  ', and ' > > ' buttons.
;         3. Added the 'Full Time Span' and 'Add Time Bar(s)' buttons.
;   2012-10-31: JBT, SSL/UCB. Initial release in TDAS.
;   2013-06-20: JBT. Fixed a bug when tplot options do not include the window
;               option.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2013-06-20 08:46:53 -0700 (Thu, 20 Jun 2013) $
; $LastChangedRevision: 12558 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/tplot_zoom.pro $
;-

pro tplot_zoom_event, ev
; For the 'Quit' button.

  compile_opt idl2, hidden

  if ev.select then widget_control, ev.top, destroy = 1
end

;-------------------------------------------------------------------------------
pro tplot_zoom_set_tbar, linestyle = linestyle, color = color, thick = thick, $
  reset = reset

  compile_opt idl2, hidden
;   common tplot_zoom_com, tbar, ybar, trange_stack, yzoom_vars, base
  @tplot_zoom_com.pro

  if keyword_set(reset) then begin
    tbar = {linestyle:2, color: 6, thick:1.0}
    return
  endif 

  if size(tbar, /type) ne 8 then begin
    tbar = {linestyle:2, color: 6, thick:1.0}
  endif

  if n_elements(linestyle) ne 0 then tbar.linestyle = linestyle
  if n_elements(color) ne 0 then tbar.color = color
  if n_elements(thick) ne 0 then tbar.thick = thick

end

;-------------------------------------------------------------------------------
pro tplot_zoom_set_ybar, linestyle = linestyle, color = color, thick = thick, $
  reset = reset

  compile_opt idl2, hidden
;   common tplot_zoom_com, tbar, ybar, trange_stack, yzoom_vars, base
  @tplot_zoom_com.pro

  if keyword_set(reset) then begin
    ybar = {linestyle:2, color: 6, thick:1.0}
    return
  endif 

  if size(ybar, /type) ne 8 then begin
    ybar = {linestyle:2, color: 6, thick:1.0}
  endif

  if n_elements(linestyle) ne 0 then ybar.linestyle = linestyle
  if n_elements(color) ne 0 then ybar.color = color
  if n_elements(thick) ne 0 then ybar.thick = thick

end

;-------------------------------------------------------------------------------
pro tplot_zoom_trange_stack, reset = reset, addtr = addtr, inc_itr = inc_itr, $
  dec_itr = dec_itr

  compile_opt idl2, hidden
  @tplot_com.pro
;   common tplot_zoom_com, tbar, ybar, trange_stack, yzoom_vars, base
  @tplot_zoom_com.pro
  tspan = tplot_vars.options.trange_full

  force_reset = 0
  if size(trange_stack, /type) eq 8 then begin
    if total(abs(trange_stack.tspan - tspan)) gt 0 then force_reset = 1
  endif

  if keyword_set(reset) or force_reset gt 0 then begin
    tr = tplot_vars.settings.x.crange + tplot_vars.settings.time_offset
;     tspan = [0d, 0d]
    vars = tnames(/tplot)
    nvars = n_elements(vars)
    vars_arr = strarr(1, 100)
    vars_arr[0,0:nvars-1] = vars
    trange_stack = {tr: transpose(tr), itr:0, vars_arr:vars_arr, $
                    nvar_arr:[nvars], tspan:tspan}
    return
  endif

  if keyword_set(addtr) then begin
    tmptr = tplot_vars.settings.x.crange + tplot_vars.settings.time_offset
    tmptr = transpose(tmptr)
    tr = [trange_stack.tr[0:trange_stack.itr,*], tmptr]
    itr = n_elements(tr) / 2 - 1
;     trange_stack = {tr: tr, itr:itr}
    vars = tnames(/tplot)
    nvars = n_elements(vars)
    vars_arr = strarr(1, 100)
    vars_arr[0,0:nvars-1] = vars
    vars_arr = [trange_stack.vars_arr[0:trange_stack.itr,*], vars_arr]
    nvar_arr = [trange_stack.nvar_arr[0:trange_stack.itr], nvars]
    trange_stack = {tr: tr, itr:itr, vars_arr:vars_arr, $
                    nvar_arr:nvar_arr, tspan:tspan}
;     stop
    return
  endif

  if keyword_set(inc_itr) then begin
    ntr = n_elements(trange_stack.tr) / 2
    if trange_stack.itr eq ntr - 1 then begin
      dprint, 'Already in the end of the time range stack. ', $
        'No where to go forward.'
      return
    endif else begin
      trange_stack.itr++
      nvars = trange_stack.nvar_arr[trange_stack.itr]
      tlist = trange_stack.vars_arr[trange_stack.itr, 0:nvars-1] 
      tr = trange_stack.tr[trange_stack.itr, *]
      tplot, tlist, trange = tr
      return
    endelse
  endif

  if keyword_set(dec_itr) then begin
    ntr = n_elements(trange_stack.tr) / 2
    if trange_stack.itr eq 0 then begin
      dprint, 'Already in the beginning of the time range stack. ', $
        'No where to go backward.'
      return
    endif else begin
      trange_stack.itr--
      nvars = trange_stack.nvar_arr[trange_stack.itr]
      tlist = trange_stack.vars_arr[trange_stack.itr, 0:nvars-1] 
      tr = trange_stack.tr[trange_stack.itr, *]
      tplot, tlist, trange = tr
      return
    endelse
  endif

end


;-------------------------------------------------------------------------------
pro tplot_zoom_yzoom_vars, reset = reset

  compile_opt idl2, hidden
  @tplot_com.pro
;   common tplot_zoom_com, tbar, ybar, trange_stack, yzoom_vars, base
  @tplot_zoom_com.pro

  if keyword_set(reset) then begin
    if size(yzoom_vars, /type) ne 8 then begin
      yzoom_vars = {cvar:''}
    endif else yzoom_vars.cvar = ''

    return
  endif

end





;-------------------------------------------------------------------------------
function quick_zoom_event, ev
; Handles all the zooming buttons.

  compile_opt idl2, hidden

  @tplot_com.pro
;   common tplot_zoom_com, tbar, ybar, trange_stack, yzoom_vars, base
  @tplot_zoom_com.pro

  ; Check if there is a tplot window existing.
  if !d.window eq -1 then begin
    msg = 'There is currently no plot window. Click OK to continue.'
    buttontext = dialog_message(msg, /center, /error)
    return, -1
  endif

  ; Check if there is a valid tplot.
  names = tnames('*', /tplot)
  if strcmp(names[0], '') then begin
    msg = 'There is currently no tplot window yet. Click OK to continue.'
    buttontext = dialog_message(msg, /center, /error)
    return, -1
  endif

  ; Get uvalue
  widget_control, ev.id, get_uvalue = uvalue

  case uvalue of
    'ZoomIn2x': begin
        trange = tplot_vars.settings.x.crange
        tlen = trange[1] - trange[0]
        tcenter = mean(trange) + tplot_vars.settings.time_offset
        new_trange = tcenter + [-0.25d, 0.25d] * tlen
        tlimit, new_trange
        tplot_zoom_trange_stack, /add
      end
    'ZoomIn8x': begin
        trange = tplot_vars.settings.x.crange
        tlen = trange[1] - trange[0]
        tcenter = mean(trange) + tplot_vars.settings.time_offset
        new_trange = tcenter + [-0.25d, 0.25d] * tlen * 0.5d * 0.5d
        tlimit, new_trange
        tplot_zoom_trange_stack, /add
      end
    'ZoomOut2x': begin
        trange = tplot_vars.settings.x.crange
        tlen = trange[1] - trange[0]
        tcenter = mean(trange) + tplot_vars.settings.time_offset
        new_trange = tcenter + [-1d, 1d] * tlen
        tlimit, new_trange
        tplot_zoom_trange_stack, /add
      end
    'ZoomOut8x': begin
        trange = tplot_vars.settings.x.crange
        tlen = trange[1] - trange[0]
        tcenter = mean(trange) + tplot_vars.settings.time_offset
        new_trange = tcenter + [-1d, 1d] * tlen * 4d
        tlimit, new_trange
        tplot_zoom_trange_stack, /add
      end
    'ClickZoom': begin
        tlimit
        tplot_zoom_trange_stack, /add
      end
    'Backward': tplot_zoom_trange_stack, /dec
    'Forward': tplot_zoom_trange_stack, /inc
    'YZoom': begin
        ctime,t,y,vname=var,npoints=2, panel = panel, ynorm = ynorm
        pos = jbt_tplot_pos()
        ivar = panel[0]
        s = tplot_vars.settings.y[ivar].s
        type = tplot_vars.settings.y[ivar].type
        yvalue = (ynorm - s[0]) / s[1]
        if type eq 1 then yvalue = 10^yvalue

        options,var[0], yrange = minmax(yvalue), ystyle = 1
        yzoom_vars.cvar = var[0]
        tplot
      end
    'YZreset': begin
        options,yzoom_vars.cvar, 'yrange'
        options,yzoom_vars.cvar, 'ystyle'
        tplot
      end
    'FullSpan': begin
        tlimit, /full
        tplot_zoom_trange_stack, /add
      end
    'HomeSpan': begin
        nvars = trange_stack.nvar_arr[0]
        tlist = trange_stack.vars_arr[0, 0:nvars-1]
        tr = trange_stack.tr[0,*]
        tplot, tlist, trange = tr
        tplot_zoom_trange_stack, /add
      end
    'Tcross': begin
        ; Pick panels.
        ctime, t, y, vname = vars
        tlist = tnames(/tplot)
        ind = uniq(vars)
        vars = vars[ind]
        ntotal = n_elements(tlist)
        nsub = n_elements(vars)
        if nsub ge ntotal then begin
;           dprint, 'nsub == ntotal'
;           stop
          erase
          break
        endif

        ; Remove panels in the current tplot list
        ntmp = n_elements(vars)
        con = intarr(ntotal) + 1
        for i = 0, ntmp - 1 do begin
          ind = where(strcmp(tlist, vars[i]))
          con[ind] = 0
        endfor
        ind = where(con gt 0)
        newlist = tlist[ind]

;         stop

        ; Re-plot the new list.
        tplot, newlist

        ; Add to stack
        tplot_zoom_trange_stack, /add
      end
    'Tpick': begin
        tplot, /pick
        tplot_zoom_trange_stack, /add
      end
    'panForward': begin
        trange = tplot_vars.settings.x.crange
        tlen = trange[1] - trange[0]
        tcenter = mean(trange) + tplot_vars.settings.time_offset
        new_trange = trange + tlen * 0.5 + tplot_vars.settings.time_offset
        tlimit, new_trange
        tplot_zoom_trange_stack, /add
      end
    'panForward2': begin
        trange = tplot_vars.settings.x.crange
        tlen = trange[1] - trange[0]
        tcenter = mean(trange) + tplot_vars.settings.time_offset
        new_trange = trange + tlen * 1.0 + tplot_vars.settings.time_offset
        tlimit, new_trange
        tplot_zoom_trange_stack, /add
      end
    'panBackward': begin
        trange = tplot_vars.settings.x.crange
        tlen = trange[1] - trange[0]
        tcenter = mean(trange) + tplot_vars.settings.time_offset
        new_trange = trange - tlen * 0.5 + tplot_vars.settings.time_offset
        tlimit, new_trange
        tplot_zoom_trange_stack, /add
      end
    'panBackward2': begin
        trange = tplot_vars.settings.x.crange
        tlen = trange[1] - trange[0]
        tcenter = mean(trange) + tplot_vars.settings.time_offset
        new_trange = trange - tlen * 1.0 + tplot_vars.settings.time_offset
        tlimit, new_trange
        tplot_zoom_trange_stack, /add
      end
    'TimeBar': begin
        ctime, tmptime
        timebar, tmptime, linestyle = tbar.linestyle, color = tbar.color, $
          thick = tbar.thick
      end
    'YBar': begin
        ctime, t, y, panel = panel
        pos = jbt_tplot_pos()
        for ii = 0, n_elements(panel) - 1 do begin
          tmppos = pos[panel[ii], *]
          yrange = tplot_vars.settings.y[panel[ii]].crange
          if tplot_vars.settings.y[panel[ii]].type eq 1 then $
            yvalue = alog10(y[ii]) else yvalue = y[ii]
          x0 = tmppos[0]
          x1 = tmppos[2]
          ylen = tmppos[3] - tmppos[1]
          ytmp = (yvalue - yrange[0]) / (yrange[1] - yrange[0]) * ylen $
            + tmppos[1]
          plots, [x0, x1], [ytmp, ytmp], /normal, linestyle = ybar.linestyle, $
            color = ybar.color, thick = ybar.thick
        endfor
      end
    else: begin
        msg = 'No actions defined for this UVALUE. Click OK to continue.'
        buttontext = dialog_message(msg, /center, /error)
        return, -1
      end
  endcase

  return, 0
end

;-------------------------------------------------------------------------------
function tplot_zoom_visible
  compile_opt idl2, hidden

;   common tplot_zoom_com, tbar, ybar, trange_stack, yzoom_vars, base
  @tplot_zoom_com.pro

  if n_elements(base) gt 0 then begin
    errorNumber = 0L
    catch, errorNumber
    ; If an error occur, that means base not visible
    if (errorNumber ne 0L) then begin
      catch, /cancel
      return, 0
    endif

    info = widget_info(base, /visible)
    return, info  ; base visible
  endif else return, 0

end

;-------------------------------------------------------------------------------
pro tplot_zoom, reset = reset, horizontal = horizontal
; Defines the graphical layout of the widget, and links buttons to event
; handling functions or procedures.

  compile_opt idl2

;   common tplot_zoom_com, tbar, ybar, trange_stack, yzoom_vars, base
  @tplot_zoom_com.pro

  ; Check if there is a tplot window existing.
  if !d.window eq -1 then begin
    msg = 'There is currently no plot window. Click OK to continue.'
    buttontext = dialog_message(msg, /center, /error)
    return
  endif

  ; Check if there is a valid tplot.
  names = tnames(/tplot)
  if strcmp(names[0], '') then begin
    msg = 'There is currently no tplot window yet. Click OK to continue.'
    buttontext = dialog_message(msg, /center, /error)
    return
  endif

  ; Reset the tplot_zoom_com common block
  if keyword_set(reset) or size(trange_stack, /type) ne 8 then begin
    tplot_zoom_set_tbar, /reset
    tplot_zoom_set_ybar, /reset
    tplot_zoom_trange_stack, /reset
    tplot_zoom_yzoom_vars, /reset
  endif else tplot_zoom_trange_stack, /add

;   stop

  ; Get tplot options.
  tplot_options, get_options = opt

  str_element, opt, 'window', success = s

  if s gt 0 then iwin = opt.window else iwin = 0  ; tplot window index
  cur_iwin = !d.window ; the index of current window
  if iwin ne cur_iwin then begin
    wset, iwin
  endif

  ; Avoid multiple tplot_zoom widget
  if tplot_zoom_visible() then return

  quickbase_width = 140
  xpad = 10

  tplotwin_xsize = !d.x_size
  tplotwin_ysize = !d.y_size
  device, get_screen_size = scr_size, get_window_position = winpos
  left_margin = winpos[0]
  right_margin = scr_size[0] - winpos[0] - tplotwin_xsize
  if left_margin lt 400 and right_margin lt 400 then begin
    xoffset = 200
  endif else begin
    if left_margin ge right_margin then begin
      xoffset = left_margin - quickbase_width - xpad*2 - 20
    endif else begin
      xoffset = scr_size[0] - right_margin + 10
    endelse
  endelse

  ; Get the directory of button images
  callback_stack = scope_traceback(/structure)
  level = scope_level()
  levelstr = callback_stack[level-1]
  bmp_dir = file_dirname(levelstr.filename) + path_sep() + $
    'tplot_zoom_images' + path_sep()

  ; Set up a container, base, to contain all the buttons.
;   if keyword_set(vertical) then shape = 'vertical'
  if keyword_set(horizontal) then shape = 'horizontal'
  if n_elements(shape) eq 0 then shape = 'box'
  n_buttons = 19
  case shape of 
    'horizontal': begin
        basexpad = 10
        baseypad = 0
        widget_xsize = n_buttons * 36.5 + basexpad * 2
        basexoffset = winpos[0] + (tplotwin_xsize - widget_xsize) * 0.5 
        baseyoffset = scr_size[1] - winpos[1] + 7
        base = widget_base(/column, /align_center, xpad = basexpad, $
          ypad = baseypad, $
          xoffset = basexoffset, yoffset = baseyoffset, $
          space = 0)
        quickbase = widget_base(base, column=n_buttons, frame = 0, space = 0, $
          /align_center)
      end
;     'vertical': begin
;         base = widget_base(/column, /align_center, xpad = xpad, ypad = 10, $
;           xoffset = xoffset, $
;           yoffset = scr_size[1] - (winpos[1]+tplotwin_ysize), $
;           space = 10)
;         quickbase = widget_base(base, column=1, frame = 2, space = 0, $
;           /align_center, xsize = quickbase_width)
;       end
    'box': begin
        base = widget_base(/column, /align_center, xpad = xpad, ypad = 10, $
          xoffset = xoffset, $
          yoffset = scr_size[1] - (winpos[1]+tplotwin_ysize), $
          space = 10)
        quickbase = widget_base(base, column=1, frame = 2, space = 0, $
          /align_center, xsize = quickbase_width)
      end
    else: begin
        dprint, 'Invalid shape. Abort.'
        return
      end
  endcase

;   stop

;   ; The quick zoom group.
;   ; quickbase: The container of all the buttons except for the 'Quit' button.
;   quickbase = widget_base(base, column=1, frame = 2, space = 0, $
;     /align_center, xsize = quickbase_width)

  ; quickzoombase contains the quick zomming buttons ('+ +', ' + ', 
  ; ' - ', '- -').
;   quickzoombase = widget_base(quickbase, column=4, frame = 0, space = 3, $
;     /align_center, xsize = 130)
  if strcmp(shape, 'box') then $
    quickzoombase = widget_base(quickbase, column=4, frame = 0, space = 3, $
      /align_center, xsize = 130) $
      else quickzoombase = quickbase
  bmp = transpose(read_bmp(bmp_dir + 'zoom_in8.bmp', /rgb), [1,2,0])
  plus2 = widget_button(quickzoombase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'ZoomIn8x', uvalue = 'ZoomIn8x', $
    tooltip = 'Zoom in x 8')
  bmp = transpose(read_bmp(bmp_dir + 'zoom_in2.bmp', /rgb), [1,2,0])
  plus = widget_button(quickzoombase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'ZoomIn2x', uvalue = 'ZoomIn2x', $
    tooltip = 'Zoom in x 2')
  bmp = transpose(read_bmp(bmp_dir + 'zoom_out2.bmp', /rgb), [1,2,0])
  minus = widget_button(quickzoombase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'ZoomOut2x', $
    uvalue = 'ZoomOut2x', tooltip = 'Zoom out x 2')
  bmp = transpose(read_bmp(bmp_dir + 'zoom_out8.bmp', /rgb), [1,2,0])
  minus2 = widget_button(quickzoombase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'ZoomOut8x', $
    uvalue = 'ZoomOut8x', tooltip = 'Zoom out x 8')

  ; For the 'Click and Zoom' button.
  if strcmp(shape, 'box') then $
    selectzoombase = widget_base(quickbase, column=4, frame = 0, space = 3, $
      /align_center, xsize = 130) $
      else selectzoombase = quickbase
  bmp = transpose(read_bmp(bmp_dir + 'click_zoom.bmp', /rgb), [1,2,0])
  selectzoom = widget_button(selectzoombase, value = bmp, $
    event_func = 'quick_zoom_event', uname = 'ClickZoom', $
    uvalue = 'ClickZoom', tooltip = 'Left-click twice to zoom a new time range')
  ; For the 'Change yrange' button.
  bmp = transpose(read_bmp(bmp_dir + 'backward.bmp', /rgb), [1,2,0])
  backward = widget_button(selectzoombase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'Backward', $
    uvalue = 'Backward', $
    tooltip = 'Go backward in the time range stack')
  bmp = transpose(read_bmp(bmp_dir + 'forward.bmp', /rgb), [1,2,0])
  forward = widget_button(selectzoombase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'Forward', $
    uvalue = 'Forward', $
    tooltip = 'Go forward in the time range stack')
  bmp = transpose(read_bmp(bmp_dir + 'yzoom.bmp', /rgb), [1,2,0])
  yzoom = widget_button(selectzoombase, value = bmp, $
    event_func = 'quick_zoom_event', uname = 'YZoom', uvalue = 'YZoom', $
    tooltip = "Left-click twice to change a single panel's y-range")

  ; For the panning buttons.
  if strcmp(shape, 'box') then $
    panbase = widget_base(quickbase, column=4, frame = 0, space = 3, $
      /align_center, xsize = 130) $
      else panbase = quickbase
  bmp = transpose(read_bmp(bmp_dir + 'left2.bmp', /rgb), [1,2,0])
  left2 = widget_button(panbase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'panBackward2', $
    uvalue = 'panBackward2', $
    tooltip = 'Pan backward by a full length of the current time range')
  bmp = transpose(read_bmp(bmp_dir + 'left.bmp', /rgb), [1,2,0])
  left = widget_button(panbase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'panBackward', $
    uvalue = 'panBackward', $
    tooltip = 'Pan backward by a half length of the current time range')
  bmp = transpose(read_bmp(bmp_dir + 'right.bmp', /rgb), [1,2,0])
  right = widget_button(panbase, value = bmp, /bitmap,$
    event_func = 'quick_zoom_event', uname = 'panForward', $
    uvalue = 'panForward', $
    tooltip = 'Pan forward by a half length of the current time range')
  bmp = transpose(read_bmp(bmp_dir + 'right2.bmp', /rgb), [1,2,0])
  right2 = widget_button(panbase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'panForward2', $
    uvalue = 'panForward2', $
    tooltip = 'Pan forward by a full length of the current time range')

  ; Tbar, ybar, and YZreset
  if strcmp(shape, 'box') then $
    fullbase = widget_base(quickbase, column=3, frame = 0, space = 3, $
      /align_center, xsize = 100) $
      else fullbase = quickbase
  ; For the 'Add Time Bar' button.
  bmp = transpose(read_bmp(bmp_dir + 'tbar.bmp', /rgb), [1,2,0])
  tbar_btn = widget_button(fullbase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'TimeBar', uvalue = 'TimeBar', $
    tooltip = 'Left-click to add time bar(s); right-click to return')
  ; For the 'Add Horizotal bar(s)' button.
  bmp = transpose(read_bmp(bmp_dir + 'ybar.bmp', /rgb), [1,2,0])
  ybar_btn = widget_button(fullbase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'YBar', uvalue = 'YBar', $
    tooltip = 'Left-click to add horizontal bar(s); right-click to return')
  bmp = transpose(read_bmp(bmp_dir + 'yzoom_reset.bmp', /rgb), [1,2,0])
  yzreset_btn = widget_button(fullbase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'YZreset', uvalue = 'YZreset', $
    tooltip = 'Remove yrange of the last y-zoomed tplot variable.')

  ; home and pick
  if strcmp(shape, 'box') then $
    homebase = widget_base(quickbase, column=4, frame = 0, space = 3, $
      /align_center, xsize = 130) $
      else homebase = quickbase
  bmp = transpose(read_bmp(bmp_dir + 'cross.bmp', /rgb), [1,2,0])
  cross_btn = widget_button(homebase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'Tcross', uvalue = 'Tcross', $
    tooltip = 'Remove clicked tplot panels')
  bmp = transpose(read_bmp(bmp_dir + 'full.bmp', /rgb), [1,2,0])
  fullspan = widget_button(homebase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'FullSpan', uvalue = 'FullSpan', $
    tooltip = 'Go back to full time range.')
  bmp = transpose(read_bmp(bmp_dir + 'home.bmp', /rgb), [1,2,0])
  homespan = widget_button(homebase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'HomeSpan', uvalue = 'HomeSpan', $
    tooltip = 'Go back to the home view.')
  bmp = transpose(read_bmp(bmp_dir + 'pick.bmp', /rgb), [1,2,0])
  pick_btn = widget_button(homebase, value = bmp, /bitmap, $
    event_func = 'quick_zoom_event', uname = 'Tpick', uvalue = 'Tpick', $
    tooltip = 'Pick tplot panels')

;   ; The 'Quit' button 
;   quitbase = widget_base(base, /column, frame = 0, /align_center)
;   bmp = transpose(read_bmp(bmp_dir + 'exit.bmp', /rgb), [1,2,0])
;   button = widget_button(quitbase, value = bmp, xsize = 40, $
;     tooltip = 'Quit')
  widget_control, base, /realize

  xmanager, 'tplot_zoom', base, event_handler = 'tplot_zoom_event', $
    no_block = 1

end

