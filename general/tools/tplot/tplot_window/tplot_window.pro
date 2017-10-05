;+
;NAME:
; tplot_window
;PURPOSE:
; Allowd various widget-like features in a tplot window, this is
; accomplished by setting up the window as a draw widget.
;CALLING SEQUENCE:
; tplot_window, tplot_vars
;DESCRIPTION:
; Called just like tplot, e.g.,
;
;   tplot_window, tplot_variable_names
;
; (The variable names are optional, if left out, then the previous set
; of tplotted variables are used)
;
; Once tplot_window is called, the all succeeding "tplot" commands are
; sent to that first window, unless tplot is called using the WINDOW
; keyword. (To get a new widget, call tplot_window again.)
;
; Tplot_window makes the tplot window a draw widget, and enables
; keyboard commands, e.g., 
;      'z' for zoom in by 50%; 
;      'o' for zoom out by200%; 
;      'r' for reset to initial time range; 
;      't' for interactive tlimit, which allows you to set 
;          the plotted time range by clicking same as in a regular
;          window; 
;      'b' for shift back by 25%;
;      'f' for shift forward by 25%;
;      'c' centers the plot on the cursor, without zooming
; Arrow keys work too, up zooms in, down zooms out, left shifts back,
; right shifts forwards.
;
; All tplot keywords are allowed except window and wshow. The draw widget
; does not respond to click events, so that calling tlimit, ctime, etc..
; from the command line still works. 
;
; Note that the widget has no 'memory' so if you zoom out right after
; zooming in, you don't necessarily return to the same time range, unless
; you are careful about where on the window you start.
; The zoom in commands key on the cursor position on the plot, while the zoom
; out commands zoom out from the center of the current plot.
;
; Note that all issues with multiple windows have not been sorted
; out. To return control of tplot to a given window, call 
; tplot with no arguments except for the appropriate value using the
; window keyword, e.g., 
;    tplot, window = 32 will return control to the original
;    tplot_window.
;INPUT:
; tplot_vars = tplot variable names or numbers
;OUTPUT:
; no explicit output, just plots and keywords
;KEYWORDS:
; Same as tplot.pro, excluding WINDOW:
;   TITLE:    A string to be used for the title. Remembered for future plots.
;   ADD_VAR:  Set this variable to add datanames to the previous plot.  If set
;         to 1, the new panels will appear at the top (position 1) of the
;         plot.  If set to 2, they will be inserted directly after the
;         first panel and so on.  Set this to a value greater than the
;         existing number of panels in your tplot window to add panels to
;             the bottom of the plot.
;   LASTVAR:  Set this variable to plot the previous variables plotted in a
;         TPLOT window.
;   PICK:     Set this keyword to choose new order of plot panels
;             using the mouse.
;   VAR_LABEL:  String [array]; Variable(s) used for putting labels along
;     the bottom. This allows quantities such as altitude to be labeled.
;   VERSION:  Must be 1,2,3, or 4 (3 is default)  Uses a different labeling
;   scheme.  Version 4 is for rocket-type time scales.
;   OVERPLOT: Will not erase the previous screen if set.
;   NAMES:    The names of the tplot variables that are plotted.
;   NOCOLOR:  Set this to produce plot without color.
;   TRANGE:   Time range for tplot.
;   NEW_TVARS:  Returns the tplot_vars structure for the plot created. Set
;         aside the structure so that it may be restored using the
;             OLD_TVARS keyword later. This structure includes information
;             about various TPLOT options and settings and can be used to
;             recreates a plot.
;   OLD_TVARS:  Use this to pass an existing tplot_vars structure to
;     override the one in the tplot_com common block.
;   GET_PLOT_POSITION: Returns an array containing the corners of each
;     panel in the plot, to make it easier to overplot and annotate plots
;   HELP:     Set this to print the contents of the tplot_vars.options
;         (user-defined options) structure.
;HISTORY:
; 2016-09-23, jmm, jimm@ssilberkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-10-21 11:05:30 -0700 (Fri, 21 Oct 2016) $
; $LastChangedRevision: 22185 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/tplot_window/tplot_window.pro $
;-
Pro tplot_window_event, event

@tplot_com
;Insert catch here so that state remains defined
  err0 = 0
  catch, err0
  If(err0 Ne 0) Then Begin
     catch, /cancel
     help, /last_message, output = err_msg
     For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
     If(is_struct(state)) Then Begin
        widget_control, event.top, set_uval = state, /no_copy
     Endif
     Return
  Endif
  
;kill request block, note this is the only way to exit
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
  exit_sequence:
    widget_control, event.top, /destroy
    Return
  Endif

;Resize? See xtplot and http://www.idlcoyote.com/widget_tips/resize_draw.html
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_BASE') Then Begin
     widget_control, event.top, get_uvalue = state, /no_copy
     widget_control, state.draw_widget, draw_xsize = event.x, draw_ysize = event.y
     widget_control, event.top, set_uvalue = state, /no_copy
     tplot, verbose = 0
     tplot_apply_timebar & tplot_apply_databar
     Return
  Endif

  widget_control, event.top, get_uval = state, /no_copy
  If(state.init Eq 0) Then Begin ;there always seems to be an event at the start, do nothing
     state.init = 1
     widget_control, event.top, set_uval = state, /no_copy
     Return
  Endif Else widget_control, event.top, set_uval = state, /no_copy

;what sort of events, only keystrokes to start
  used_tlimit = 0b
  If(tag_exist(event, 'type') && (event.type Eq 5 || event.type Eq 6)) Then Begin
     If(event.release Eq 1) Then Begin
        If(~is_struct(tplot_vars) || ~is_struct(tplot_vars.options)) Then Return
        widget_control, event.top, get_uval = state, /no_copy
;Check to be sure that the graphics device is set to the tplot window,
;sometimes this is not the case when windows get deleted or moved
;around
        wset, tplot_vars.options.window
        tplot, verbose = 0, get_plot_pos = ppp
;Figure out where we are in non-device coordinates
;Now some xtplot hacks
        geo = widget_info(state.draw_widget, /geo) ;widget geometry
        widget_control, event.top, set_uval = state, /no_copy
;We never want to get into a situation where we are getting prompted
;for times, unless no data has been loaded
        trange = tplot_vars.options.trange
        If(trange[0] Eq 0 And trange[1] Eq 0) Then $
           trange = tplot_vars.options.trange_full
        If(trange[0] Eq 0 And trange[1] Eq 0) Then Begin
           If(tag_exist(tplot_vars.options, 'varnames') && $
              is_string(tplot_vars.options.varnames)) Then Begin
              vn = tplot_vars.options.varnames
              tr = trange
              For k = 0, n_elements(vn)-1 Do Begin
                 get_data, vn[k], data = d
                 If(is_struct(d)) Then tr = minmax(d.x)
                 If(total(abs(tr)) Gt 0) Then trange = tr
              Endfor
           Endif
        Endif
        If(trange[0] Eq 0 And trange[1] Eq 0) Then Return
;Her we have a time range so continue
        x = event.x
        time = ((event.x/geo.xsize)-ppp[0, 0])*$
               ((trange[1]-trange[0])/(ppp[2, 0]-ppp[0, 0]))+$
               trange[0]
        time = (time < trange[1]) > trange[0]
;        dprint, dlevel=4, print, time_string(time)
;        dprint, dlevel=4, event.x, event.y
;Be sure that you are in the window before doing anything
        xlimit = geo.xoffset+[0.0, geo.xsize]
        ylimit = geo.yoffset+[0.0, geo.ysize]
        If(event.x Gt xlimit[0] And event.x Lt xlimit[1] And $
           event.y Gt ylimit[0] And event.y Lt ylimit[1]) Then Begin
;What key did i press? 
           If(event.type Eq 5) Then Begin
              keyval = strlowcase(string(event.ch))
              Case keyval of
                 'c': Begin     ;If 'c' then center the plot on the cursor
                    tmid = 0.5*(trange[1]+trange[0])
                    dt1 = time-tmid
                    tlimit, trange[0]+dt1, trange[1]+dt1
                    used_tlimit = 1b
                 End
                 'z': Begin     ;If 'z', then zoom in by 50%
                    dt0 = trange[1]-trange[0]
                    dt1 = dt0/4.0 ;25% on either side of the point
                    tlimit, time-dt1, time+dt1
                    used_tlimit = 1b
                 End
                 'o':Begin      ;zoom out by 200%
                    dt1 = trange[1]-trange[0]
                    tmid = 0.5*(trange[1]+trange[0])
                    tlimit, tmid-dt1, tmid+dt1
                    used_tlimit = 1b
                 End
                 'r': Begin     ;If 'r' go back to initial time range
                    tlimit, tplot_vars.options.trange_full[0], $
                            tplot_vars.options.trange_full[1]
                    used_tlimit = 1b
                 End
                 't':Begin      ;If t, just call tlimit
                    tlimit
                    used_tlimit = 1b
                 End
                 'b':Begin      ;If 'b' shift back by 25%
                    dt0 = trange[1]-trange[0]
                    dt1 = dt0/4.0 ;25% on either side of the point
                    tlimit, trange[0]-dt1, trange[1]-dt1
                    used_tlimit = 1b
                 End
                 'f':Begin      ;If 'f' shift forward by 25%
                    dt0 = trange[1]-trange[0]
                    dt1 = dt0/4.0 ;25% on either side of the point
                    tlimit, trange[0]+dt1, trange[1]+dt1
                    used_tlimit = 1b
                 End
                 Else:Begin
                 End
              Endcase
           Endif Else If(event.type Eq 6) Then Begin ;arrow keys
              keyval = event.key
              Case keyval of
                 5:Begin        ;left arrow If 'b' shift back by 25%
                    dt0 = trange[1]-trange[0]
                    dt1 = dt0/4.0 ;25% on either side of the point
                    tlimit, trange[0]-dt1, trange[1]-dt1
                    used_tlimit = 1b
                 End
                 6:Begin        ;right arrow shift forward by 25%
                    dt0 = trange[1]-trange[0]
                    dt1 = dt0/4.0 ;25% on either side of the point
                    tlimit, trange[0]+dt1, trange[1]+dt1
                    used_tlimit = 1b
                 End
                 7: Begin       ;up arrow then zoom in by 50%
                    dt0 = trange[1]-trange[0]
                    dt1 = dt0/4.0 ;25% on either side of the point
                    tlimit, time-dt1, time+dt1
                    used_tlimit = 1b
                 End
                 8:Begin        ;down arrow zoom out by 200%
                    dt1 = trange[1]-trange[0]
                    tmid = 0.5*(trange[1]+trange[0])
                    tlimit, tmid-dt1, tmid+dt1
                    used_tlimit = 1b
                 End
                 Else:Begin
                 End
              Endcase
           Endif
        Endif
     Endif
  Endif

  If(used_tlimit) Then Begin
     tplot_apply_timebar & tplot_apply_databar
  Endif
  
  If(is_struct(state)) Then widget_control, event.top, $
                                            set_uval = state, /no_copy
Return
End

Pro tplot_window, datanames, $
   NOCOLOR = nocolor,     $
   VERBOSE = verbose,     $
   wshow = wshow,         $
   OPLOT = oplot,         $
   OVERPLOT = overplot,   $
   VERSION = version , $
   TITLE = title,         $
   LASTVAR = lastvar,     $
   ADD_VAR = add_var,     $
   LOCAL_TIME= local_time,$
   REFDATE = refdate,     $
   VAR_LABEL = var_label, $
   OPTIONS = opts,        $
   T_OFFSET = t_offset,   $
   TRANGE = trng,         $
   NAMES = names,         $
   PICK = pick,           $
   new_tvars = new_tvars, $
   old_tvars = old_tvars, $
   datagap = datagap,     $
   get_plot_position=pos, $
   xsize = xsize, $
   ysize = ysize, $
   help = help

  @tplot_com
  common tplot_window_private, state

;create a widget
  master = widget_base(/row, title = 'tplot window ', $
                       /align_top, /tlb_kill_request_events, $
                      /tlb_size_events)
;Define a state structure
  state = {master:master, $
           window_id:-1L, $
           ww0:'', $
           draw_widget:-1L, $
           init:0}

;add a draw widget
  If(keyword_set(xsize)) Then xsz0 = xsize Else xsz0 = 960
  If(keyword_set(ysize)) Then ysz0 = ysize Else ysz0 = 600
  id0 = widget_draw(master, xsize = xsz0, ysize = ysz0, $
;                    /button_events, /motion_events, /tracking_events, $
                   /keyboard_events)
  state.draw_widget = id0

  widget_control, master, /realize
  xmanager, 'tplot_window', master, /no_block
  state.window_id = !d.window
  state.ww0 = strcompress(string(!d.window))
  widget_control, master, tlb_set_title = 'tplot window '+state.ww0
  widget_control, master, set_uval = state, /no_copy

  tplot, datanames, $
         WINDOW = !d.window, $
         NOCOLOR = nocolor,     $
         VERBOSE = verbose,     $
         OPLOT = oplot,         $
         OVERPLOT = overplot,   $
         VERSION = version , $
         TITLE = title,         $
         LASTVAR = lastvar,     $
         ADD_VAR = add_var,     $
         LOCAL_TIME= local_time,$
         REFDATE = refdate,     $
         VAR_LABEL = var_label, $
         OPTIONS = opts,        $
         T_OFFSET = t_offset,   $
         TRANGE = trng,         $
         NAMES = names,         $
         PICK = pick,           $
         new_tvars = new_tvars, $
         old_tvars = old_tvars, $
         get_plot_position=pos,$
         help = help
;GO ahead an apply any time and databars
  tplot_apply_timebar
  tplot_apply_databar

Return
End

