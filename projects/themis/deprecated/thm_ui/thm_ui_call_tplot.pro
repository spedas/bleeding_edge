;+ 
;NAME: Setting ptype
; thm_ui_call_tplot
;PURPOSE:
; A widget interface for calling tplot from the themis_w widget,
; currently of limited usefulness, but expandable
;CALLING SEQUENCE:
; thm_ui_call_tplot, master_widget_id
;INPUT:
; master_widget_id = the id number of the widget that calls this
;OUTPUT:
; none, there are button_master to push for plotting, setting limits, not
; sure what else yet...
;HISTORY:
; 14-dec-2006, jmm, jimm@ssl.berkeley.edu
; 13-feb-2007, jmm, fixed problem with !p.background resetting in
; set_plot commands
; 12-mar-2007, jmm, Added wavelet button
; 2-apr-2007, jmm, Added pwrspc options, NEEDS TESTING.
; jun-2007, jmm, split from dproc widget.
; 12-jul-2007, jmm, added a message widget, for invalid user input
;                   errors, grays out all button_master while processing
; 31-jul-2007, jmm, various checks for windows present to avoid tplot
;                   and ctime bombs
; 25-oct-2007, jmm, plot info, window number, size, ptyp, are no held
;                   in the main GUI state structure
; 19-mar-2008, jmm, changed state.ptyp to pstate.ptyp to fix bug
; 1-apr-2008, cg, added a pop-up window to allow user to set size/units
;                 for postscript files
; 5-may-2008, cg, fixed bug with scroll bar
; 15-may-2008, cg, added spacecraft/component plot capabilities
;                  reorganized code
;
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_call_tplot.pro $
;
;-
Pro thm_ui_call_tplot_event, event

  @tplot_com
  common thm_ui_call_tplot_sav, plot_types

  err_xxx = 0
  catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    catch, /cancel
    help, /last_message, output = err_msg
    For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
    If(is_struct(state) Eq 0) Then $
      widget_control, event.top, get_uval = state, /no_copy
    widget_control, state.messw, set_val = 'Error--See history'
    cw = state.cw
    For j = 0, n_elements(state.button_arr)-1 Do widget_control, $
      state.button_arr[j], sensitive = 1
    widget_control, event.top, set_uval = state, /no_copy
    If(widget_valid(cw)) Then Begin
      If(is_struct(wstate)) Then widget_control, cw, set_uval = wstate
      thm_ui_update_history, cw, [';*** FYI', ';'+err_msg]
      thm_ui_update_progress, cw, 'Error--See history'
    Endif
    thm_ui_error
    Return
  Endif

;start here
  widget_control, event.id, get_uval = uval
  If(uval Eq 'EXIT') Then widget_control, event.top, /destroy Else Begin
;find the tplot variables that are selected, and do the tplot
    widget_control, event.top, get_uval = state, /no_copy
    widget_control, state.cw, get_uval = wstate, /no_copy
    If(ptr_valid(wstate.active_vnames)) Then Begin
;Clear out messw
      widget_control, state.messw, set_val = ''
;Disable all button_master
      button_arr = state.button_arr
      For j = 0, n_elements(button_arr)-1 Do widget_control, $
        button_arr[j], sensitive = 0
      tv_plot = *wstate.active_vnames
      pstate = wstate.pstate    ;info for plot type and size, etc...
      widget_control, state.cw, set_uval = wstate, /no_copy
;Now you have valid names, do the plotting, etc...
      Case uval Of
        'SCRN':Begin
          if pstate.ptyp ne 'SCREEN' then Begin
            pstate.ptyp = 'SCREEN'
            history_ext = 'plot_type = SCREEN'
            thm_ui_update_history, state.cw, history_ext
            thm_ui_update_progress, state.cw, $
              'Setting ptype to SCREEN', message_wid = state.messw
            widget_control, state.scrnbut, /set_button 
          endif
        End   
        'PNG':Begin
          if pstate.ptyp ne 'PNG' then Begin
            pstate.ptyp = 'PNG'
            history_ext = 'plot_type = PNG'
            thm_ui_update_history, state.cw, history_ext
            thm_ui_update_progress, state.cw, $
              'Setting ptype to PNG', message_wid = state.messw
             widget_control, state.pngbut, /set_button 
          endif
        End   
        'PS':Begin
          if pstate.ptyp ne 'PS' then Begin
            pstate.ptyp = 'PS'
            history_ext = 'plot_type = PS'
            thm_ui_update_history, state.cw, history_ext
            thm_ui_update_progress, state.cw, $
              'Setting ptype to PS', message_wid = state.messw
             widget_control, state.psbut, /set_button 
          endif
        End   
        'SCON' :Begin
           history_ext = 'plot variable = SPACECRAFT'
           thm_ui_update_history, state.cw, history_ext
           thm_ui_update_progress, state.cw, $
            'Plotting variables by SPACECRAFT', message_wid = state.messw
           new_names=thm_component_to_tplot(tv_plot, state.cw, state.messw)
           tv_plot=new_names
        End
        'COMPON' :Begin
           history_ext = 'plot by value set to COMPONENT'
           thm_ui_update_history, state.cw, history_ext
           thm_ui_update_progress, state.cw, $
            'Plotting variables by COMPONENT', message_wid = state.messw
           new_names=thm_tplot_to_component(tv_plot, state.cw, state.messw)
           tv_plot=new_names
        End
        'PLOT':Begin
          thm_ui_update_progress, message_wid = state.messw, $
            state.cw, 'Plotting '+tv_plot
          tv_plot_s = ''''+tv_plot+''''
;get the plot type
          ptyp = pstate.ptyp
          If(ptyp Eq 'PS') Then Begin
            xt = time_string(systime(/sec))
            ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
              '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
            filename = 'thm_gui_plot_'+ttt
            osf = strupcase(!version.os_family)
            If(osf Eq 'WINDOWS') Then filename0 = file_expand_path('')+'\'+filename $
            Else filename0 = file_expand_path('')+'/'+filename
            filename = dialog_pickfile(title = 'THEMIS GUI Plot Filename', $
                                       filter = '*.ps', file = filename0)
            If(is_string(filename)) Then Begin
              dname = !d.name   ;'X' or 'WIN'
              !p.background = !d.table_size-1 ;White background   (color table 34)
              !p.color = 0      ; Black Pen
              !p.font = -1      ; Use default fonts
              popen, filename, xsize=pstate.ps_size[0], ysize=pstate.ps_size[1], $
                     units=pstate.ps_units
              tplot, tv_plot
              pclose
              history_ext = ['popen, '+''''+filename+'''', 'tplot, '+tv_plot_s, $
                             'pclose', ';CREATED: '+filename+'.ps']
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'CREATED: '+filename+'.ps'
              set_plot, dname
              !p.background = !d.table_size-1 ;White background   (color table 34)
              !p.color = 0      ; Black Pen
              !p.font = -1      ; Use default fonts
            Endif Else Begin
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'Operation Cancelled'
            Endelse
          Endif Else If(ptyp Eq 'PNG') Then Begin
            xt = time_string(systime(/sec))
            ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
              '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
            filename = 'thm_gui_plot_'+ttt
            osf = strupcase(!version.os_family)
            If(osf Eq 'WINDOWS') Then filename0 = file_expand_path('')+'\'+filename $
            Else filename0 = file_expand_path('')+'/'+filename
            filename = dialog_pickfile(title = 'THEMIS GUI Plot Filename', $
                                       filter = '*.png', file = filename0)
            If(is_string(filename)) Then Begin
              dname = !d.name   ;'X' or 'WIN'
              set_plot, 'z'     ;do this in the z-buffer
              !p.background = !d.table_size-1 ;White background   (color table 34)
              !p.color = 0      ; Black Pen
              !p.font = -1      ; Use default fonts
              tplot, tv_plot
              makepng, filename
              history_ext = ['dname = !d.name', 'set_plot, ''z''', $
                             'tplot, '+tv_plot_s, 'makepng, '+''''+filename+'''', $
                             'set_plot, dname', $
                             ';CREATED: '+filename]
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'CREATED: '+filename+'.png'
              set_plot, dname
              !p.background = !d.table_size-1 ;White background   (color table 34)
              !p.color = 0      ; Black Pen
              !p.font = -1      ; Use default fonts
            Endif Else Begin
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'Operation Cancelled'
            Endelse
          Endif Else Begin
            If(!version.os_family Eq 'Windows') Then begin
              set_plot, 'win'
              history_ext = ['set_plot, ''win''', 'tplot, '+tv_plot_s]
            Endif Else Begin
              set_plot, 'x'
              history_ext = ['set_plot, ''x''', 'tplot, '+tv_plot_s]
            Endelse
            !p.background = !d.table_size-1 ;White background   (color table 34)
            !p.color = 0        ; Black Pen
            !p.font = -1        ; Use default fonts
            window, pstate.current_wno, xs = pstate.windowsize[0], ys = pstate.windowsize[1]
            tplot, tv_plot, window = pstate.current_wno
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Finished Plotting '
          Endelse
          thm_ui_update_history, state.cw, history_ext
        End
;set ylimits for the active dataset
        'YLIMIT':Begin
          thm_ui_update_progress, message_wid = state.messw, state.cw, $
            'Setting ylimits for all active data: '
          yr = [0.0d0, 0.0d0] ;initialize
          yl = 0b
;If there is only 1 active data set here, then remember the ylimits:
          If(n_elements(tv_plot) Eq 1) Then Begin
            get_data, tv_plot[0], lim = lim
            If(is_struct(lim)) Then Begin
              If(tag_exist(lim, 'yrange')) Then yr = lim.yrange
              If(tag_exist(lim, 'ylog')) Then yl = byte(lim.ylog)
            Endif
          Endif
          yr = strcompress(/remove_all, string(yr))
          If(yl Eq 0) Then yrv = 'LINEAR' Else yrv = 'LOG'
          ylims = thm_ui_npar(['YMAX', 'YMIN'], radio_array = ['LINEAR', 'LOG'], $
                                [yr[1], yr[0]], radio_value = yrv, $
                                title='Y Limits')
          If(ylims[0] Eq 'Cancelled') Then Begin
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Operation Cancelled'
          Endif Else Begin
            yr = [double(ylims[1]), double(ylims[0])]
            If(ylims[2] Eq 'LOG') Then yl = 1 Else yl = 0
            ylim, tv_plot, yr[0], yr[1], yl
            ystring = ylims[1]+', '+ylims[0]+', '+strcompress(string(yl), /remove_all)
            history_ext = 'ylim, varnames, '+ystring
            thm_ui_update_history, state.cw, history_ext
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Finished setting ylimits: '
          Endelse
        End
;set zlimits for the active dataset
        'ZLIMIT':Begin
          thm_ui_update_progress, message_wid = state.messw, state.cw, $
            'Setting zlimits for all active data: '
          zr = [0.0d0, 0.0d0] ;initialize
          zl = 0b
;If there is only 1 active data set here, then remember the ylimits:
          If(n_elements(tv_plot) Eq 1) Then Begin
            get_data, tv_plot[0], lim = lim
            If(is_struct(lim)) Then Begin
              If(tag_exist(lim, 'zrange')) Then zr = lim.zrange
              If(tag_exist(lim, 'zlog')) Then zl = byte(lim.zlog)
            Endif
          Endif
          zr = strcompress(/remove_all, string(zr))
          zl = strcompress(/remove_all, string(zl))
          If(zl Eq 0) Then zrv = 'LINEAR' Else zrv = 'LOG'
          zlims = thm_ui_npar(['ZMAX', 'ZMIN'], radio_array = ['LINEAR', 'LOG'], $
                                [zr[1], zr[0]], radio_value = zrv, $
                                title='Z Limits')
          If(zlims[0] Eq 'Cancelled') Then Begin
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Operation Cancelled'
          Endif Else Begin
            zr = [double(zlims[1]), double(zlims[0])]
            If(zlims[2] Eq 'LOG') Then zl = 1 Else zl = 0
            zlim, tv_plot, zr[0], zr[1], zl
            zstring = zlims[1]+', '+zlims[0]+', '+strcompress(string(zl), /remove_all)
            history_ext = 'zlim, varnames, '+zstring
            thm_ui_update_history, state.cw, history_ext
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Finished setting zlimits: '
          Endelse
        End
;Set spectrogram,
        'SETSPEC':Begin
;Done for each active dataset separately
          For j = 0, n_elements(tv_plot)-1 Do Begin
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Setting Spectrogram '+tv_plot[j]
            get_data, tv_plot[j], data = d
            If(tag_exist(d, 'v')) Then nv = n_elements(d.v) $
            Else If tag_exist(d, 'v2') Then nv = n_elements(d.v2) $
            Else nv = 0
            If(nv Gt 6) Then Begin
              options, tv_plot[j], 'spec', 1
              history_ext = 'options,'+''''+tv_plot[j]+''''+$
                ', ''spec'', 1'
              thm_ui_update_history, state.cw, history_ext
              thm_ui_update_progress, message_wid = state.messw, $
                state.cw, 'Finished Setting Spectrogram '+tv_plot[j]
            Endif Else Begin
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'Spectrogram is not an option for '+tv_plot[j]
              thm_ui_update_history, state.cw, $
                ';Spectrogram is not an option for '+tv_plot[j]
            Endelse
          Endfor
        End
;Set spectrogram,
        'UNSETSPEC':Begin
;Done for each active dataset separately
          For j = 0, n_elements(tv_plot)-1 Do Begin
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Unsetting Spectrogram '+tv_plot[j]
            get_data, tv_plot[j], data = d
            If(tag_exist(d, 'v') Or tag_exist(d, 'v2')) Then Begin
              options, tv_plot[j], 'spec', 0
              history_ext = 'options,'+''''+tv_plot[j]+''''+$
                ', ''spec'', 0'
              thm_ui_update_history, state.cw, history_ext
              thm_ui_update_progress, message_wid = state.messw, $
                state.cw, 'Finished Unsetting Spectrogram '+tv_plot[j]
            Endif
          Endfor
        End
        'SETPSSZ':Begin
          thm_ui_update_progress, message_wid = state.messw, state.cw, $
            'Setting postscript size'
          pssz = strcompress(string(pstate.ps_size), /remove_all)
          ps_values = thm_ui_npar(['XSIZE', 'YSIZE'], pssz, $
                                radio_array=['inches', 'cm'], $
                                radio_value=pstate.ps_units, $
                                title='Postscript Size')
          If(ps_values[0] Eq 'Cancelled') Then Begin
             thm_ui_update_progress, message_wid = state.messw, state.cw, $
               'Operation Cancelled'
          Endif Else Begin
          ps_size = float(ps_values[0:1])
          If(ps_size[0] Gt 0 And ps_size[1] Gt[0]) Then Begin
            pstate.ps_size = ps_size
            pstate.ps_units = ps_values[2]
            ptyp = pstate.ptyp
            wno = pstate.current_wno
            If(!version.os_family Eq 'Windows') Then set_plot, 'win' $
            Else set_plot, 'x'
              history_ext = [';ps xsize='+ strcompress(string(pstate.ps_size[0])), $
                             ';ps ysize='+ strcompress(string(pstate.ps_size[1])), $
                             ';ps units='+strcompress(string(pstate.ps_units))]
              thm_ui_update_history, state.cw, history_ext
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'Finished setting postscript size'
            Endif Else Begin
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'Invalid postscript size'
            Endelse
          Endelse
        End
        'SETWNSZ':Begin
          thm_ui_update_progress, message_wid = state.messw, state.cw, $
            'Setting window size'
          wsz = strcompress(string(pstate.windowsize), /remove_all)
          wsz = thm_ui_npar(['XSIZE (pixels)', 'YSIZE (pixels)'], wsz, $
                            title = 'Window Size')
          If(wsz[0] Eq 'Cancelled') Then Begin
            thm_ui_update_progress, state.cw, 'Operation Cancelled'
          Endif Else Begin
            wsz = fix(wsz)
            If(wsz[0] Gt 0 And wsz[1] Gt[0]) Then Begin
              pstate.windowsize = wsz
              ptyp = pstate.ptyp
              If(ptyp Eq 'PNG') Then Begin
                set_plot, 'z'
                device, set_resolution = pstate.windowsize
                history_ext = $
                  thm_ui_multichoice_history('device, set_resolution = ', wsz)
                If(!version.os_family Eq 'Windows') Then set_plot, 'win' $
                Else set_plot, 'x'
              Endif Else Begin
                wno = pstate.current_wno
                If(!version.os_family Eq 'Windows') Then set_plot, 'win' $
                Else set_plot, 'x'
                history_ext = ['xsize_w ='+$
                               strcompress(string(pstate.windowsize[0])), $
                               'ysize_w ='+$
                               strcompress(string(pstate.windowsize[1]))]
              Endelse
              thm_ui_update_history, state.cw, history_ext
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'Finished setting window size'
            Endif Else Begin
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'Invalid window size'
            Endelse
          Endelse
        End
        'SETWNNO':Begin
          thm_ui_update_progress, message_wid = state.messw, state.cw, $
            'Setting window number'
          wno0 = strcompress(string(pstate.current_wno), /remove_all)
          wno = thm_ui_npar('Current Number', wno0, $
                            title='Window Number')
          If(wno[0] Eq 'Cancelled') Then Begin
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Operation Cancelled'
          Endif Else Begin
            wno = fix(wno[0])
            If(wno Lt 32 And wno ge 0) Then Begin
              pstate.current_wno = wno
              If(!version.os_family Eq 'Windows') Then set_plot, 'win' $
              Else set_plot, 'x'
              history_ext = 'winno ='+strcompress(string(wno))
              thm_ui_update_history, state.cw, history_ext
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'Finished setting window number'
            Endif Else Begin
              thm_ui_update_progress, message_wid = state.messw, state.cw, $
                'Invalid window number, must be LT 32'
            Endelse
          Endelse
        End
        'CREATEWIN':Begin
          ptyp = pstate.ptyp
          If(ptyp Eq 'PNG') Then Begin
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Window Not Used for PNG plots'
          Endif Else Begin
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Creating New window'
            window, pstate.current_wno, xs = pstate.windowsize[0], $
              ys = pstate.windowsize[1]
            history_ext = 'window,'+strcompress(string(pstate.current_wno))+$
              ', xs ='+strcompress(string(pstate.windowsize[0]))+$
              ', ys ='+strcompress(string(pstate.windowsize[1]))
            thm_ui_update_history, state.cw, history_ext
            thm_ui_update_progress, message_wid = state.messw, state.cw, $
              'Finished creating new window'
          Endelse
        End
;set tlimit, using the cursor, or typing...
        'TLIMIT':Begin
          thm_ui_update_progress, message_wid = state.messw, state.cw, $
            'Choosing time limits for plotting'
          widget_control, event.top, set_uval = state, /no_copy
          thm_ui_set_tlimits, event.top
          widget_control, event.top, get_uval = state, /no_copy
          thm_ui_update_progress, message_wid = state.messw, state.cw, $
            'Finished choosing time limits for plotting'
        End
      Endcase
      ;Reset the button_master and other buttons
      For j = 0, n_elements(button_arr)-1 Do $
        widget_control, button_arr[j], sensitive = 1
  
      ;reset any changed pstate parameters and buttons
      widget_control, state.cw, get_uval = wstate, /no_copy
      wstate.pstate = pstate
      if wstate.pstate.ptyp eq 'SCREEN' then $
          widget_control, state.scrnbut, /set_button
      if wstate.pstate.ptyp eq 'PNG' then $
           widget_control, state.pngbut, /set_button
      if wstate.pstate.ptyp eq 'PS' then $
          widget_control, state.psbut, /set_button
      widget_control, state.cw, set_uval = wstate, /no_copy
    Endif Else Begin
      widget_control, state.cw, set_uval = wstate, /no_copy
      thm_ui_update_progress, message_wid = state.messw, state.cw, $
        'No Active Dataset, Please Load or Click on Data'
    Endelse
    widget_control, event.top, set_uval = state, /no_copy
 
  Endelse
  Return
End

Pro thm_ui_call_tplot, gui_id

  @tplot_com
  common thm_ui_call_tplot_sav, plot_types

  If(n_elements(plot_types) Eq 0) Then plot_types = ['SCREEN', 'PNG', 'PS']

  ;build master widget bases
  tplot_master = widget_base(/col, title = 'THEMIS: Plot Menu', $
                             group_leader = gui_id, scr_xsize = 495)
  selection_master = widget_base(tplot_master, /row, /align_left)
  message_master= widget_base(tplot_master, /row, /align_left)
  button_mastersp = widget_base(selection_master, /col, /align_center)
  butlabel = widget_label(button_mastersp, value=' ')
  button_master = widget_base(selection_master, /col, /align_center, frame=3, ypad=18, xpad=10)
  button_mastersp = widget_base(selection_master, /col, /align_center)
  butlabel = widget_label(button_mastersp, value=' ')
  plot_master = widget_base(selection_master, /col, /align_center, frame=3,ypad=13,xpad=5)

  ;Build up the button options
  tlimitbut = widget_button(button_master, val = ' Set Time limits ', $
                            uval = 'TLIMIT', /align_left, scr_xsize = 130)
  ylimbut = widget_button(button_master, val = ' Ylimit', $
                          uval = 'YLIMIT', /align_left, scr_xsize = 130)
  zlimbut = widget_button(button_master, val = ' Zlimit', $
                          uval = 'ZLIMIT', /align_left, scr_xsize = 130)
  psszbut = widget_button(button_master, val = ' Postscript Size', $
                           uval = 'SETPSSZ', /align_left, scr_xsize = 130)
  winszbut = widget_button(button_master, val = ' Plot Window Size', $
                           uval = 'SETWNSZ', /align_left, scr_xsize = 130)
  winnobut = widget_button(button_master, val = ' Plot Window Number', $
                           uval = 'SETWNNO', /align_left, scr_xsize = 130)
  cwinbut = widget_button(button_master, val = ' Create New Window', $
                          uval = 'CREATEWIN', /align_left, scr_xsize = 130)

  ;and now build the plot output options
  plottype_base = widget_base(plot_master, /row, /align_left)
  plottype_label = widget_label(plottype_base, value = 'Plot Output: ')
  plotbutton_master = widget_base(plottype_base, /exclusive, /row, uval='PBTN')
  scrnbut = widget_button(plotbutton_master, val = 'Screen       ', uval = 'SCRN')
  pngbut = widget_button(plotbutton_master, val = 'PNG  ', uval = 'PNG')
  psbut = widget_button(plotbutton_master, val = 'PS', uval = 'PS')
  
  ; plot type options
  spec_base = widget_base(plot_master, /row)
  spec_label = widget_label(spec_base, value = 'Plot Type:    ')
  specbutton_master = widget_base(spec_base, /row, uval='SPEC') 
  specbut1 = widget_button(specbutton_master, val = 'Line Plot    ', uval = 'UNSETSPEC')
  specbut = widget_button(specbutton_master, val = 'Spectrogram', uval = 'SETSPEC')

  ; and plot by options
  vartype_base = widget_base(plot_master, /row, /align_left)
  vartype_label = widget_label(vartype_base, value = 'Plot By:        ')
  varbutton_master=widget_base(vartype_base, /row, uval='VAR')
  spacecraft_on = widget_button(varbutton_master, value='Spacecraft', uval='SCON')
  component_on = widget_button(varbutton_master, value='Component  ', uval='COMPON')

  ;and finally the plot and exit buttons
  butbase = widget_base(plot_master, /col, /align_center)
  plabel=widget_label(butbase, value='                     ')
  plotbut = widget_button(butbase, val = 'Draw Plot', uval = 'PLOT', $
                          /align_center,  scr_xsize = 90)
  exitbut = widget_button(butbase, val = 'Close', uval = 'EXIT', $
                          /align_center, scr_xsize = 90)
 
  ; finally, build up the message window at the bottom
  messw = widget_text(message_master, value = '', xsize = 75, ysize = 5, /scroll)

  ;done with widget builds, now set initialized variables 
  ;for the main gui state structures
  widget_control, gui_id, get_uval = wstate, /no_copy
  wstate.plt_id = tplot_master
  t0 = wstate.st_time & t1 = wstate.en_time
  wstate.pstate.st_time = t0 & wstate.pstate.en_time = t1
  If(ptr_valid(wstate.active_vnames)) Then Begin
    tvn = *wstate.active_vnames
  Endif Else tvn = '*'
  ptype=wstate.pstate.ptyp
  
  ;retrieve current window number and size 
  ;they should be set already
  cwno = wstate.pstate.current_wno
  cwsz = wstate.pstate.windowsize 
  widget_control, gui_id, set_uval = wstate, /no_copy
  
  ;Some things won't work unless there has already been a tplot called,
  do_a_tplot = 1b
  If(is_struct(tplot_vars)) Then Begin
    If(is_struct(tplot_vars.options)) Then do_a_tplot = 0b
  Endif
  If(do_a_tplot) Then Begin
    window, cwno, xsize = cwsz[0], ysize = cwsz[1]
    tplot, tvn
  Endif
  
  ;clear out any title
  tplot_options, 'title', ''
  
  button_arr = [tlimitbut, ylimbut, zlimbut, psszbut, winszbut, $
               winnobut, cwinbut, plotbut, exitbut]
                
  ;create the state structure
  state = {tplot_master:tplot_master, $
           ptype:ptype, $
           scrnbut:scrnbut, $
           pngbut:pngbut, $
           psbut:psbut, $
           specbut:specbut,$
           specbut1:specbut1, $
           component_on:component_on, $
           spacecraft_on:spacecraft_on, $
           messw:messw, $       ;the message widget id
           button_arr:button_arr, $ ;an array with the button_master, to be greyed out
           cw:gui_id}           ;the id of the calling widget

  widget_control, tplot_master, set_uval = state, /no_copy
  widget_control, tplot_master, /realize

  ;initial button values
  widget_control, tplot_master, get_uval = state, /no_copy
  if ptype eq 'SCREEN' then $
     widget_control, state.scrnbut, /set_button
  if ptype eq 'PNG' then $
     widget_control, state.pngbut, /set_button
  if ptype eq 'PS' then $
     widget_control, state.psbut, /set_button

  widget_control, tplot_master, set_uval = state, /no_copy
  
  xmanager, 'thm_ui_call_tplot', tplot_master, /no_block

  Return
End
