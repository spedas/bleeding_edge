;+
; NAME: XTPLOT
;
; PURPOSE: A GUI wrapper for tplot
;
; CALLING SEQUENCE: Use just like 'tplot'
;
; CREATED BY: Mitsuo Oka   Jan 2015
;
;
; $LastChangedBy: moka $
; $LastChangedDate: 2024-07-13 23:42:09 -0700 (Sat, 13 Jul 2024) $
; $LastChangedRevision: 32742 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/xtplot/xtplot.pro $
pro xtplot_change_tlimit, strcmd
  compile_opt idl2
  @tplot_com.pro

  case strcmd of
    'default': tshift = 100
    'full': tshift = 200
    'ignore': tshift = 300
    'expand': tshift = [-0.25d, 0.25d] ; total length = 0.5
    'shrink': tshift = [-1.00d, 1.00d] ; total length = 2.0
    'forward': tshift = [-0.25d, 0.75d] ; [ 0.50d, 1.50d]  ;[-0.25d,0.75d] ; total length = 1.0
    'backward': tshift = [-0.75d, 0.25d] ; [-1.50d,-0.50d];[-0.75d,0.25d] ; total length = 1.0
  endcase

  case tshift[0] of
    100: tlimit, /silent
    200: tlimit, /full, /silent
    300: ; do nothing!
    else: begin
      trange = tplot_vars.options.trange
      tlen = trange[1] - trange[0]
      trange_new = mean(trange) + tshift * tlen
      tlimit, trange_new, /silent
    end
  endcase

  str_element, /add, tplot_vars, 'settings.i_trange_stack', 0
  rst = where(strmatch(tag_names(tplot_vars.settings), 'trange_stack', /fold_case), count)
  if count eq 0 then $
    str_element, /add, tplot_vars, 'settings.trange_stack', [tplot_vars.options.trange, tplot_vars.settings.trange_old] $
  else $
    str_element, /add, tplot_vars, 'settings.trange_stack', [tplot_vars.options.trange, tplot_vars.settings.trange_stack]
end

pro xtplot_recovr_tlimit, strcmd, widf
  compile_opt idl2
  @tplot_com.pro

  i = tplot_vars.settings.i_trange_stack ; which step to plot? current--> i=0, one_step_past--> i=1
  case strcmd of
    'undo': i++ ; one step backward in time
    'redo': i-- ; one step forward in time
  endcase
  imax = n_elements(tplot_vars.settings.trange_stack) / 2
  case 1 of
    i lt 0: i = 0
    i ge imax: i = imax - 1
    else: tlimit, [tplot_vars.settings.trange_stack[2 * i], tplot_vars.settings.trange_stack[2 * i + 1]], /silent
  endcase
  str_element, /add, tplot_vars, 'settings.i_trange_stack', i
end

pro xtplot_change_ylimit, widf
  compile_opt idl2
  widget_control, widf.fldAmin, get_value = Amin
  widget_control, widf.fldAmax, get_value = Amax
  range = float([Amin, Amax])
  widget_control, widf.drpTarget, get_value = names
  index = widget_info(widf.drpTarget, /droplist_select)
  options, names[index], 'yrange', range
  options, names[index], 'autorange', 0
  options, names[index], 'ystyle', 1
  tplot, verbose = 0
end

pro xtplot_refresh, widf, gpp = gpp
  compile_opt idl2

  if ~widf.auto_refresh then begin
    x = widf.refresh_window_size[0]
    y = widf.refresh_window_size[1]
    xmin = widf.refresh_window_size[2]
    ofs = widf.refresh_window_size[3]
    widget_control, widf.baseTl, xsize = x > xmin, ysize = y - ofs
    widget_control, widf.drwPlot, draw_xsize = x > xmin, draw_ysize = (y - ofs - widf.resYsize) > 0
    gpp = 1
  endif

  if keyword_set(gpp) then begin
    tplot, verbose = 0, get_plot_pos = plot_pos
    str_element, /add, widf, 'plot_pos', plot_pos
  endif else tplot
end

function xtplot_timeformat, tr, nodate = nodate
  compile_opt idl2
  s1 = time_string(tr)
  s2 = strjoin(strsplit(s1, '/', /extract), '_')
  s3 = strjoin(strsplit(s2, ':', /extract), '')
  s4 = strjoin(strsplit(s3, '-', /extract), '')
  if keyword_set(nodate) then begin
    s4 = strmid(s4, 9, 1000)
  endif
  return, s4
end

pro xtplot_makeimage, drwin, jpg = jpg
  compile_opt idl2
  fmt = 'png'
  if keyword_set(jpg) then fmt = 'jpg'
  tr = timerange(/current)
  ts = xtplot_timeformat(tr[0])
  te = xtplot_timeformat(tr[1], /nodate)
  fname_default = 'xtplot_' + ts + '-' + te + '.' + fmt
  fname = dialog_pickfile(default_extension = fmt, /write, file = fname_default)
  if strlen(fname) eq 0 then begin
    answer = dialog_message('Cancelled', /center, /info)
  endif else begin
    nlen = strlen(fname)
    if strpos(fname, '.' + fmt) eq nlen - 4 then fname = strmid(fname, 0, nlen - 4)
    case fmt of
      'png': makepng, fname, window = drwin
      'jpg': makejpg, fname, window = drwin
      else: message, 'A wrong image format'
    endcase
  endelse
end

pro xtplot_event, event
  compile_opt idl2
  @tplot_com.pro
  @xtplot_com.pro

  ; initialize
  widget_control, event.top, get_uvalue = widf

  widget_control, widf.drwPlot, get_value = drwin
  wset, drwin

  ; -------- 2016-03-31 Temporary Fix ---------------
  widf_tplot_vars = widf.tplot_vars
  c_tvars = tplot_vars
  vname = c_tvars.settings.varnames
  jmax = n_elements(vname)
  for j = 0, jmax - 1 do begin ; for each current varname
    idx = where(widf.tplot_vars.settings.varnames eq vname[j], ct)
    if ct eq 1 then begin
      widf_tplot_vars.settings.y[idx[0]].crange = c_tvars.settings.y[j].crange
    endif
  endfor
  tplot_vars = widf_tplot_vars
  ; -------------------------------------------------
  ; tplot_vars = widf.tplot_vars

  code_exit = 0

  ; main
  case event.id of
    ; -----------------------------------
    ; TOOL BAR
    ; -----------------------------------
    widf.btnTlm: begin
      xtplot_right_click = 0
      xtplot_change_tlimit, 'default'
      xtplot_right_click = 1
    end
    widf.btnBackward: xtplot_change_tlimit, 'backward'
    widf.btnForward: xtplot_change_tlimit, 'forward'
    widf.btnExpand: xtplot_change_tlimit, 'expand'
    widf.btnShrink: xtplot_change_tlimit, 'shrink'
    widf.btnTlmFull: xtplot_change_tlimit, 'full'
    widf.btnTlmUndo: xtplot_recovr_tlimit, 'undo'
    widf.btnTlmRedo: xtplot_recovr_tlimit, 'redo'
    widf.btnTlmRefresh: xtplot_refresh, widf
    widf.bgRefresh: str_element, /add, widf, 'auto_refresh', event.select

    ; -----------------------------------
    ; WINDOW (Resize or Kill)
    ; -----------------------------------
    widf.baseTl: begin
      thisEvent = tag_names(event, /structure_name)
      case thisEvent of
        'WIDGET_KILL_REQUEST': code_exit = 1
        'WIDGET_BASE': begin ; Resize Event
          wsize = widf.refresh_window_size
          if widf.auto_refresh then begin
            xmin = wsize[2]
            ofs = wsize[3]
            widget_control, widf.baseTl, xsize = event.x > xmin, ysize = (event.y - ofs)
            widget_control, widf.drwPlot, draw_xsize = event.x > xmin, draw_ysize = (event.y - ofs - widf.resYsize) > 0
            tplot, verbose = 0, get_plot_pos = plot_pos
            str_element, /add, widf, 'plot_pos', plot_pos
          endif else begin
            ; Sometimes, the auto-refresh feature causes flickering/flashing.
            ; Removing 'tplot' greatly reduced the time of flickering.
            ; Removing widget_control completely stopped flickering.
            ; Here, we just save the desired window size. Later on, when the user
            ; decides to refresh the display, we can execute both tplot and widget_control
            ; with the saved window size. By the way, there is also an UPDATE keyword
            ; for widget_control, but I couldn't come up with a good way of using it.
            wsize[0] = event.x
            wsize[1] = event.y
            str_element, /add, widf, 'refresh_window_size', wsize
          endelse
        end
        else:
      endcase
    end

    ; -----------------------------------
    ; PLOT (Cursor, Status-Bar, Right-Click)
    ; -----------------------------------
    widf.drwPlot: begin
      thisEvent = tag_names(event, /structure_name)
      if strmatch(thisEvent, 'WIDGET_DRAW') then begin
        ; converting plot_pos --> time
        time = timerange(/current)
        tL = time[0] ; left edge
        tR = time[1] ; right edge
        geo = widget_info(widf.drwPlot, /geo)
        xL = widf.plot_pos[0, 0] ; left edge
        xR = widf.plot_pos[2, 0] ; right edge
        xC = event.x / geo.xsize ; clicked position
        tC = (xC - xL) * ((tR - tL) / (xR - xL)) + tL ; clicked time

        ; --- This block will be used when the XTPLOT_MOUSE_EVENT is enabled.
        ; See explanation a few blocks below.
        ; Here, updating selected time interval
        ; if widf.selected.state ge 1 then begin; if left-button has been pressed
        ; tL = widf.selected.tL
        ; if abs(tL-tC) gt 0 then begin ; if cursor has moved since the first left-press
        ; if widf.selected.state eq 2 then begin
        ; xtplot_timebar,widf.selected.oldtC,/transient; Delete Line 2
        ; endif else str_element,/add,widf,'selected.state',2
        ; xtplot_timebar,tC,/transient; Plot Line 2
        ; str_element,/add,widf,'selected.oldtC',tC
        ; endif
        ; endif

        ; cursor and status bar
        sz = size(widf.plot_pos, /dim) ; to obtain number of panels
        if n_elements(sz) gt 1 then begin
          mmax = sz[1]
          yBarr = fltarr(mmax)
          yTarr = fltarr(mmax)
          yBarr[0 : mmax - 1] = widf.plot_pos[1, 0 : mmax - 1]
          yTarr[0 : mmax - 1] = widf.plot_pos[3, 0 : mmax - 1]
        endif else begin
          mmax = 1
          yBarr = fltarr(mmax)
          yTarr = fltarr(mmax)
          yBarr[0] = widf.plot_pos[1]
          yTarr[0] = widf.plot_pos[3]
        endelse
        value = 0.0
        ylog = 0
        tn = ''
        for m = 0, mmax - 1 do begin ; for each panel
          yB = yBarr[m] ; widf.plot_pos[1,m]; bottom
          yT = yTarr[m] ; widf.plot_pos[3,m]; top
          yC = event.y / geo.ysize ; clicked position
          if (yB le yC) and (yC le yT) then begin
            ; check ylog setting
            if n_elements(tplot_vars.options.def_datanames) ge mmax then begin
              tn = tplot_vars.options.def_datanames[m]
              get_data, tn, data = D, dl = dl, lim = lim
              if n_tags(dl) ne 0 then begin
                index = where(strmatch(strlowcase(tag_names(dl)), 'ylog'), c) ; look for tag 'ylog'
                if c then ylog = dl.ylog
              endif
            endif

            ; get yrange from the plot
            ysetting = tplot_vars.settings.y
            fmin = ysetting[m].crange[0]
            fmax = ysetting[m].crange[1]
            value = ((yC - yB) / (yT - yB)) * (fmax - fmin) + fmin
            if ylog then value = 10 ^ value
          endif
        endfor
        widget_control, widf.lblBar, set_value = time_string(tC) + $
          ', value = ' + strtrim(string(value), 2) + ' ( ' + tn + ' )'

        ; RIGHT CLICK EVENT
        ; if (event.release eq 4) and (xtplot_right_click) then begin
        ; print,'right clicked on '+tn
        ; xtplot_options_panel, group_leader=widf.baseTL, target=tn
        ; endif

        ; /////////////////////////////////////////////
        ; XTPLOT_MOUSE_EVENT
        ; This part lets you click and slide left/right to select a time interval.
        ; This is more intuitive than the 'tlimit' interface.
        ; However, when combined with an external interactive program (e.g. EVA),
        ; there would be a conflict and makes the programming complex.
        ; For now, this feature has been turned off.
        ; When turning it on, make sure you have the 'xtplot_mouse_event' in xtplot_com
        xtplot_mouse_event = 0
        if xtplot_mouse_event then begin
          if event.press eq 4 then begin ; right-press
            ; WIDGET_DISPLAYCONTEXTMENU, Parent, X, Y, ContextBase_ID
            print, 'tC=', tC
          endif
          if event.press eq 1 then begin ; left-press
            xtplot_timebar, tC ; .............. Plot Line 1
            str_element, /add, widf, 'selected.tL', tC
            str_element, /add, widf, 'selected.state', 1
            str_element, /add, widf, 'selected.oldtC', tC
            str_element, /add, widf, 'selected.xL', xC
          endif
          if event.release eq 1 then begin ; left-release
            str_element, /add, widf, 'selected.xR', xC
            str_element, /add, widf, 'selected.tR', tC
            tL = widf.selected.tL
            xL = widf.selected.xL
            tR = widf.selected.tR
            xR = widf.selected.xR
            if tL gt tR then begin
              temp = tL
              tL = tR
              tR = temp
              temp = xL
              xL = xR
              xR = temp
              str_element, /add, widf, 'selected.tL', tL
              str_element, /add, widf, 'selected.tR', tR
              str_element, /add, widf, 'selected.xL', xL
              str_element, /add, widf, 'selected.xR', xR
            endif
            xtplot_timebar, widf.selected.tL, /transient ; ....... Delete Line 1
            if widf.selected.state eq 2 then begin ; cursor moved
              xtplot_timebar, widf.selected.oldtC, /transient ; ... Delete Line 2
              if abs(tL - tR) gt 0 then begin
                ; //////////////////////////////////////////////////////////
                call_procedure, xtplot_routine_name, widf.selected
                ; //////////////////////////////////////////////////////////
                xtplot_change_tlimit, 'ignore' ; add to stack list
              endif
            endif
            str_element, /add, widf, 'selected.state', 0
          endif ; left-release
        endif ; xtplot_mouse_event
        ; ///////////////////////////////////////////////////
      endif
    end ; widf.drwPlot: begin

    ; -----------------------------------
    ; MENU BAR
    ; -----------------------------------
    ; widf.mnClip:      begin
    ; widget_control, widf.drwPlot, GET_VALUE=win1
    ; clipboard,win1
    ; end
    widf.mnExJpg: begin
      widget_control, widf.drwPlot, get_value = drwin
      xtplot_makeimage, drwin, /jpg
    end
    widf.mnExPng: begin
      widget_control, widf.drwPlot, get_value = drwin
      xtplot_makeimage, drwin
    end
    ; widf.mnExGIF:     makegif,'xtplot'
    widf.mnConfig: begin
      formInfo = cmps_form(cancel = canceled, create = create, defaults = widf.ps_config, $
        /color, parent = widf.baseTl)
      if not canceled then begin
        if create then begin
          thisDevice = !d.name
          set_plot, 'PS'
          device, _extra = formInfo
          tplot, verbose = 0
          device, /close
          set_plot, thisDevice
        endif
        str_element, /add, widf, 'ps_config', formInfo
        init_devices
      endif
    end
    widf.mnPrin: begin
      result = dialog_printersetup()
      if result ne 0 then begin
        def_device = !d.name
        set_plot, 'PRINTER', /copy, /interpolate
        tplot, verbose = 0
        device, /close_document
        set_plot, def_device
      endif
    end
    widf.mnExit: code_exit = 1
    widf.mnC_useMouse: xtplot_change_tlimit, 'default'
    widf.mnC_redo: xtplot_recovr_tlimit, 'redo'
    widf.mnC_undo: xtplot_recovr_tlimit, 'undo'
    widf.mnC_100: xtplot_change_tlimit, 'full'
    widf.mnC_zoomIn: xtplot_change_tlimit, 'expand'
    widf.mnC_zoomOut: xtplot_change_tlimit, 'shrink'
    widf.mnC_forward: xtplot_change_tlimit, 'forward'
    widf.mnC_backward: xtplot_change_tlimit, 'backward'
    widf.mnC_refresh: xtplot_refresh, widf
    widf.mnP_pick: begin
      tplot, /pick, get_plot_pos = plot_pos, verbose = 0
      str_element, /add, widf, 'plot_pos', plot_pos
    end
    widf.mnP_rmv: begin
      ctime, panel = pan
      tnms = tnames(/tplot) ; variables used in tplot
      rnms = tnms[pan] ; variables to be removed
      nnms = strarr(1) ; variable to be remained
      imax = n_elements(tnms)
      for i = 0, imax - 1 do begin
        index = where(strmatch(rnms, tnms[i]), count) ; check if tnms[i] is to be removed
        if count eq 0 then begin ; tnms[i] is NOT to be removed
          nnms = [nnms, tnms[i]]
        endif
      endfor
      tplot, nnms, verbose = 0, get_plot_pos = plot_pos
      str_element, /add, widf, 'plot_pos', plot_pos
    end
    widf.mnP_addRmv: xtplot_panel
    widf.mnP_restore: begin
      tplot, tplot_vars.options.def_datanames, get_plot_pos = plot_pos, verbose = 0
      str_element, /add, widf, 'plot_pos', plot_pos
    end
    widf.mnO_autoExec: xtplot_options
    widf.mnO_panelOptions: begin
      ctime, prompt = 'Click on desired panels. (button 3 to quit)', panel = mix, /silent, npoints = 1
      ; tn = tplot_vars.options.def_datanames[mix]
      tn_tmp = strsplit(tplot_vars.options.datanames, ' ', /extract)
      tn = tn_tmp[mix]
      xtplot_options_panel, group_leader = widf.baseTl, target = tn
    end
    widf.mnO_tplotOptions: xtplot_options_tplot, group_leader = widf.baseTl
    ; widf.mnH_Guide:   begin
    ; fullpath = filepath(root_dir=ProgramRootDir(), 'xtplot.pdf')
    ; online_help,'Getting Started', BOOK=fullpath,/full_path;fullpath,/full_path
    ; end
    widf.mnH_about: answer = dialog_message('XTPLOT Ver. Beta', /info, /center)
  endcase

  ; finalize
  str_element, /add, widf, 'tplot_vars', tplot_vars

  widget_control, event.top, set_uvalue = widf
  if code_exit then begin
    chsize = !p.charsize
    if chsize eq 0. then chsize = 1.
    def_opts = {ymargin: [4., 2.], xmargin: [12., 12.], position: fltarr(4), $
      title: '', ytitle: '', xtitle: '', xrange: dblarr(2), xstyle: 1, $
      version: 3, window: -1, wshow: 0, charsize: chsize, noerase: 0, overplot: 0, spec: 0, base: -1}
    extract_tags, tplot_vars.options, def_opts
    str_element, /add, tplot_vars, 'options.trange', tplot_vars.options.trange_full
    str_element, /add, tplot_vars, 'options.base', -1
    widget_control, widf.baseTl, /destroy
    init_devices

    if (!d.flags and 256) ne 0 then begin ; windowing devices
      str_element, tplot_vars, 'options.window', !d.window, /add_replace
      str_element, tplot_vars, 'settings.window', !d.window, /add_replace
      ; if def_opts.window ge 0 then wset,current_window
    endif
  endif
end

pro xtplot, datanames, $
  window = wind, $
  nocolor = nocolor, $
  verbose = verbose, $ ; Choose 0 to show only serious errors. Choose 4 to show all messages
  wshow = wshow, $
  oplot = oplot, $
  overplot = overplot, $
  title = title, $
  lastvar = lastvar, $
  add_var = add_var, $
  local_time = local_time, $
  refdate = refdate, $
  var_label = var_label, $
  options = opts, $
  t_offset = t_offset, $
  trange = trng, $
  names = names, $
  pick = pick, $
  new_tvars = new_tvars, $
  old_tvars = old_tvars, $
  get_plot_position = pos, $
  help = help, $
  ; XTPLOT only
  base = base, $
  xtnew = xtnew, $ ; Set this keyword to create a new window. Window ID will be automatically given by IDL.
  xsize = xsize, $
  ysize = ysize, $
  xoffset = xoffset, $
  yoffset = yoffset, $
  execcom = execcom, $
  routine_name = routine_name, $ ; this routine is called everytime a time interval is selected by mouse. Valid only when MOUSE_EVENT=1
  widf = widf, $
  group_leader = group_leader, $
  xtplot_right_click = xtplot_rclick
  compile_opt idl2
  @tplot_com.pro
  @xtplot_com.pro

  ; ===== initialize ===================================================================

  ; xtplot_com
  xtplot_right_click = 1
  if n_elements(xtplot_rclick) ne 0 then xtplot_right_click = xtplot_rclick

  if ~keyword_set(routine_name) then routine_name = 'xtplot_tlimit' ; obsolete?
  xtplot_routine_name = routine_name

  ; window size
  factor = 0.9
  this_screen_size = get_screen_size()
  if ~keyword_set(xsize) then xsize = this_screen_size[0] * 0.5 * factor
  if ~keyword_set(ysize) then ysize = this_screen_size[1] * 0.5 * factor
  if ~keyword_set(xoffset) then xoffset = this_screen_size[0] * 0.5
  if ~keyword_set(yoffset) then yoffset = 0
  str_element, /add, widf, 'xsize', xsize
  draw_ysize = ysize - 45 ; this number is obtained empirically. See geo.ysize at the end of this program.

  ; tplot_vars
  tplot_options, title = title, var_label = var_label, refdate = refdate, wind = wind, options = opts
  if keyword_set(old_tvars) then tplot_vars = old_tvars
  if keyword_set(xtnew) then str_element, tplot_vars, 'options.base', -1, /add_replace
  if keyword_set(help) then begin
    printdat, tplot_vars.options, varname = 'tplot_vars.options'
    new_tvars = tplot_vars
    return
  endif
  if keyword_set(base) then begin
    base_valid = widget_info(base, /valid_id)
    if base_valid then begin
      str_element, tplot_vars, 'options.base', base, /add_replace
    endif else begin
      answer = dialog_message('XTPLOT ' + strtrim(string(base), 2) + $
        ' is unavailable. Use XTNEW keyword to launch a new window.', title = 'XTPLOT WARNING')
      return
    endelse
  endif

  ; widget_setting (drpTarget)
  dt = size(/type, datanames)
  ndim = size(/n_dimen, datanames)
  if dt ne 0 then begin ; if dt is defined
    if dt ne 7 or ndim ge 1 then dnames = strjoin(tnames(datanames, /all), ' ') $ ; if not string
    else dnames = datanames
  endif else begin ; if dt is undefined, get a list from tplot_vars.options.datanames
    tpv_opt_tags = tag_names(tplot_vars.options)
    idx = where(tpv_opt_tags eq 'DATANAMES', icnt)
    if icnt gt 0 then begin
      dnames = tplot_vars.options.datanames
    endif else begin ; no data names in tplot_vars.options
      DPRINT, dlevel = 0, verbose = verbose, 'No valid variable names found to tplot (use TPLOT_NAMES to display)'
      return
    endelse
  endelse
  dnarr = strsplit(dnames, /extract)
  if n_elements(execcom) eq 0 then execcom = ''

  ; datanames check
  varnames = tnames(dnames, nd, ind = ind, /all)
  if nd eq 0 then begin
    DPRINT, dlevel = 0, verbose = verbose, 'No valid variable names found to tplot! (use TPLOT_NAMES to display)'
    return
  endif
  str_element, /add, tplot_vars, 'options.def_datanames', datanames

  ; time range
  if keyword_set(trange) then begin
    strTmin = time_string(trange[0])
    strTmax = time_string(trange[1])
  endif else begin
    strTmin = time_string(tplot_vars.options.trange[0])
    strTmax = time_string(tplot_vars.options.trange[1])
  endelse

  ; ; options
  ; imax = n_elements(dnarr)
  ; for i=0,imax-1 do begin
  ; options, dnarr[i], 'autorange', 1
  ; options, dnarr[i], 'ynozero', 1
  ; endfor

  ; xtp_opts
  xtp_opts = {base: -1} ; this '-1' remains if tplot_vars was undefined
  extract_tags, xtp_opts, tplot_vars.options ; overriden by tplot_vars.option
  ; tplot_options, 'xmargin', [15,9]

  ; postscript printer
  ps_config = cmps_form(/initialize)
  str_element, /add, widf, 'ps_config', ps_config

  ; click info
  str_element, /add, widf, 'selected.state', 0

  ; ===== widget layout ===================================================================

  if xtp_opts.base eq -1 then begin
    ; master base
    baseTL = widget_base( $
      mbar = mbar, $ ; menu bar$
      ; _extra=_extra, $  ; window icon
      title = 'XTPLOT', xoffset = xoffset, yoffset = yoffset, base_align_center = 0, xsize = xsize, $
      tab_mode = 1, /column, ypad = 0, xpad = 0, $
      tlb_size_events = 1, kbrd_focus_events = 1, tlb_kill_request_events = 1, context_events = 1)
    str_element, /add, widf, 'baseTL', baseTL
    str_element, /add, tplot_vars, 'options.base', baseTL ; to be stored in widf

    ; bitmap
    if double(!version.release) ge 6.4d then begin
      getresourcepath, rpath
      zoomInBMP = read_bmp(rpath + 'magnifier_zoom.bmp', /rgb)
      zoomOutBMP = read_bmp(rpath + 'magnifier_zoom_out.bmp', /rgb)
      plotBMP = read_bmp(rpath + 'np_icon.bmp', /rgb)
      shiftRBMP = read_bmp(rpath + 'control.bmp', /rgb)
      shiftLBMP = read_bmp(rpath + 'control_180.bmp', /rgb)
      spd_ui_match_background, baseTL, zoomInBMP
      spd_ui_match_background, baseTL, zoomOutBMP
      spd_ui_match_background, baseTL, plotBMP
      spd_ui_match_background, baseTL, shiftRBMP
      spd_ui_match_background, baseTL, shiftLBMP
    endif

    ; menu
    mnFile = widget_button(mbar, value = 'File', /menu)
    mnExpr = widget_button(mnFile, value = 'Export to Image Files', /menu)
    ; str_element,/add,widf,'mnClip',widget_button(mnExpr,VALUE='clipboard')
    str_element, /add, widf, 'mnExJPG', widget_button(mnExpr, value = 'JPG')
    str_element, /add, widf, 'mnExPNG', widget_button(mnExpr, value = 'PNG')
    ; str_element,/add,widf,'mnExGIF',widget_button(mnExpr,VALUE='GIF')
    str_element, /add, widf, 'mnConfig', widget_button(mnFile, value = 'Export to PS/EPS Files')
    str_element, /add, widf, 'mnPrin', widget_button(mnFile, value = 'Print')
    str_element, /add, widf, 'mnExit', widget_button(mnFile, value = 'Exit', /separator)
    mnCtrl = widget_button(mbar, value = 'View', /menu)
    str_element, /add, widf, 'mnC_UseMouse', widget_button(mnCtrl, value = 'Use Mouse', accelerator = 'Ctrl+m', /separator)
    str_element, /add, widf, 'mnC_Redo', widget_button(mnCtrl, value = 'Redo', accelerator = 'Ctrl+y')
    str_element, /add, widf, 'mnC_Undo', widget_button(mnCtrl, value = 'Undo', accelerator = 'Ctrl+z')
    str_element, /add, widf, 'mnC_100', widget_button(mnCtrl, value = '100%', accelerator = 'Ctrl+w')
    str_element, /add, widf, 'mnC_Forward', widget_button(mnCtrl, value = 'Forward', accelerator = 'Ctrl+f')
    str_element, /add, widf, 'mnC_Backward', widget_button(mnCtrl, value = 'Backward', accelerator = 'Ctrl+b')
    str_element, /add, widf, 'mnC_ZoomIn', widget_button(mnCtrl, value = 'Zoom In', accelerator = 'Ctrl+i')
    str_element, /add, widf, 'mnC_ZoomOut', widget_button(mnCtrl, value = 'Zoom Out', accelerator = 'Ctrl+o')
    str_element, /add, widf, 'mnC_Refresh', widget_button(mnCtrl, value = 'Refresh', accelerator = 'Ctrl+r')
    mnPanel = widget_button(mbar, value = 'Panels', /menu)
    str_element, /add, widf, 'mnP_Pick', widget_button(mnPanel, value = 'Pick by Click')
    str_element, /add, widf, 'mnP_Rmv', widget_button(mnPanel, value = 'Remove by Click')
    str_element, /add, widf, 'mnP_AddRmv', widget_button(mnPanel, value = 'Edit Panels', /separator)
    str_element, /add, widf, 'mnP_Restore', widget_button(mnPanel, value = 'Restore Panels')
    mnOptions = widget_button(mbar, value = 'Options', /menu)
    str_element, /add, widf, 'mnO_PanelOptions', widget_button(mnOptions, value = 'Panel Options')
    str_element, /add, widf, 'mnO_TplotOptions', widget_button(mnOptions, value = 'Tplot Options')
    mnMacros = widget_button(mbar, value = 'Macros', /menu)
    str_element, /add, widf, 'mnO_AutoExec', widget_button(mnMacros, value = 'Auto Exec')
    mnHelp = widget_button(mbar, value = 'Help', /menu)
    ; str_element,/add,widf,'mnH_Guide',widget_button(mnHelp,VALUE='Getting Started (PDF)')
    str_element, /add, widf, 'mnH_About', widget_button(mnHelp, value = 'About XTPLOT')

    ; toolbar
    sxsize = 10
    bsTool = widget_base(baseTL, /row)
    str_element, /add, widf, 'bsTool', bsTool
    str_element, /add, widf, 'btnTlm', widget_button(bsTool, value = 'tlimit', $
      tooltip = 'Left-click twice to define a time range (call to "tlimit")')

    bsSpace1 = widget_base(bsTool, xsize = sxsize)
    str_element, /add, widf, 'btnBackward', widget_button(bsTool, value = shiftLBMP, /bitmap, $
      tooltip = 'Shift Backward')
    str_element, /add, widf, 'btnForward', widget_button(bsTool, value = shiftRBMP, /bitmap, $
      tooltip = 'Shift Forward')

    bsSpace2 = widget_base(bsTool, xsize = sxsize)
    str_element, /add, widf, 'btnExpand', widget_button(bsTool, value = zoomInBMP, /bitmap, $
      tooltip = 'Zoom-In')
    str_element, /add, widf, 'btnShrink', widget_button(bsTool, value = zoomOutBMP, /bitmap, $
      tooltip = 'Zoom-Out')
    str_element, /add, widf, 'btnTlmFull', widget_button(bsTool, value = '100%', $
      tooltip = 'Reset to full time range')

    bsSpace3 = widget_base(bsTool, xsize = sxsize)
    str_element, /add, widf, 'btnTlmUndo', widget_button(bsTool, value = 'Undo', $
      tooltip = 'Undo time-range selection')
    str_element, /add, widf, 'btnTlmRedo', widget_button(bsTool, value = 'Redo', $
      tooltip = 'Redo time-range selection')
    str_element, /add, widf, 'btnTlmRefresh', widget_button(bsTool, value = 'Refresh', $
      tooltip = 'Refresh the plot')

    auto_refresh = strmatch(!version.os_family, 'Windows')
    str_element, /add, widf, 'bgRefresh', cw_bgroup(bsTool, 'Auto Refresh', /nonexclusive, $
      set_value = auto_refresh)
    str_element, /add, widf, 'auto_refresh', auto_refresh

    ; plot
    str_element, /add, widf, 'drwPlot', widget_draw(baseTL, xsize = xsize, ysize = draw_ysize, $
      /button_events, /motion_events, /tracking_events)

    ; status bar
    str_element, /add, widf, 'lblBar', widget_label(baseTL, xsize = xsize, value = 'XTPLOT', /align_left)

    ; realization and additional adjustments
    widget_control, baseTL, /realize
    widget_control, widf.drwPlot, get_value = drwin
    widget_control, baseTL, base_set_title = 'XTPLOT ' + strtrim(string(drwin), 2)
    widget_control, baseTL, set_uvalue = widf
    xmanager, 'xtplot', baseTL, /no_block, group_leader = group_leader

    w = drwin
    b = baseTL
  endif else begin
    b = xtp_opts.base
  endelse

  ; ===== tplot ===================================================================

  tplot, datanames, window = w, $
    nocolor = nocolor, verbose = verbose, oplot = oplot, overplot = overplot, $
    title = title, lastvar = lastvar, add_var = add_var, local_time = local_time, $
    refdate = refdate, var_label = var_label, options = opts, t_offset = t_offset, $
    trange = trng, names = names, pick = pick, new_tvars = new_tvars, $
    old_tvars = tplot_vars, $ ; old_tvars is replaced at the beginning of xtplot
    help = help, get_plot_position = plot_pos

  ; if ~undefined(w) then begin
  ; print, '**************',w
  ; endif

  widget_control, b, get_uvalue = widf

  geo1 = widget_info(b, /geometry)
  geo2 = widget_info(widf.drwPlot, /geometry)
  ofs = strmatch(!version.os_family, 'Windows') ? 0 : 34. ; a magic number
  str_element, /add, widf, 'resYsize', geo1.ysize - geo2.ysize
  str_element, /add, widf, 'tplot_vars', tplot_vars
  str_element, /add, widf, 'plot_pos', plot_pos
  str_element, /add, widf, 'refresh_window_size', [geo1.xsize, geo1.ysize, 500, ofs]
  widget_control, b, set_uvalue = widf
  xtplot_base = b

  return
end