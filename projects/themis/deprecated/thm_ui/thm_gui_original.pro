;takes stime format to time_string format, only start of day... thm_ui_choose_dtype
Function temp_stime2daystr, time_in
  mon = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', $
         'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']
  mm = ['01', '02', '03', '04', '05', '06', $
        '07', '08', '09', '10', '11', '12']
  mx = strupcase(strmid(time_in, 3, 3))
  this_month = where(mon Eq mx)
  yy = strmid(time_in, 7, 4)
  dd = strmid(time_in, 0, 2)
  time_out = yy+'-'+mm[this_month]+'-'+dd+'/00:00:00'
  Return, time_out
End
;+ 
;NAME:
; thm_gui_original
;PURPOSE:
; GUI for THEMIS data analysis
;CALLING SEQUENCE:
; thm_gui_original
;INPUT:
; none
;OUTPUT:
; none
;HISTORY:
; Version 2.0 jmm, jimm@ssl.berkeley.edu 25-apr-2007
;             jmm, 21-may-2007, Currently Only Loads data
;             jmm, 7-jun-2007, all buttons are now defined
;             jmm, 31-jul-2007, added warning for too long time ranges
;             jmm, 2-aug-2007, added widget_kill_request block so that
;                  the pointers and progobj are cleaned up when you click
;                  the 'x'
;             jmm, 11-sep-2007, added this comment
;             jmm, 25-oct-2007, Now holds plot parameters (wondow
;                               number,etc) in state structure
;             jmm, 4-mar-2008, put in this comment to test email
;                  notifications
;             cg,  1-apr-2008, added ps_size and ps_units to pstate structure
;                  (needed to store user inputs for postscript file size)
;             cg,  29-may-2008, added a new structure that defines the SCM 
;                  calibration parameters. altered how the load SCM data is
;                  handled, it now calls a different GUI for SCM data
;             jmm, Tweaking to test SVN, 21-May-2009
;             jmm, Tweaking to test SVN, 9-nov-2016
;$LastChangedBy: $
;$LastChangedDate: $
;$LastChangedRevision: $
;$URL: $
;-
;@tplot_com                      ;this is available from the main level
Pro thm_gui_original_event, event
@tplot_com

  Common thm_gui_original_private, instr0, master

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    catch, /cancel
    help, /last_message, output = err_msg
    For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
    If(is_struct(state)) Then Begin
      For j = 0, n_elements(state.button_arr)-1 Do widget_control, $
        state.button_arr[j], sensitive = 1
      widget_control, event.top, set_uval = state, /no_copy
    Endif
    thm_ui_update_history, event.top, [';*** FYI', ';'+err_msg]
    thm_ui_update_progress, event.top, 'Error--See history'
    thm_ui_error
    Return
  Endif
  
  ;kill request block
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
  
  ;redefine !themis, because you cannot easily destroy the progress object
  exit_sequence:
    If(obj_valid(!themis.progobj)) Then Begin
      themis_old = !themis
      themis_new = file_retrieve(/structure_format)
      themis_tags = tag_names(themis_new)
      For j = 0, n_elements(themis_tags)-1 Do Begin
        If(themis_tags[j] Ne 'PROGOBJ') Then $
          themis_new.(j) = themis_old.(j)
      Endfor
      defsysv, '!themis', themis_new
      obj_destroy, themis_old.progobj
    Endif
    
    ;kill the pointers too:
    widget_control, event.top, get_uval = state, /no_copy
    ptr_free, state.active_vnames
    ptr_free, state.history
    ptr_free, state.dtyp
    ptr_free, state.dtyp_1
    ptr_free, state.dtyp_pre
    ptr_free, state.station
    ptr_free, state.astation
    ptr_free, state.probe
    widget_control, event.top, /destroy
    Return
  Endif
  
  ;what happened?
  widget_control, event.id, get_uval = uval
  loading = where(uval Eq instr0, nloading)

  ;if data is being loaded disable the buttons
  If(nloading Gt 0) Then Begin
    widget_control, event.top, get_uval = state, /no_copy
    For j = 0, n_elements(state.button_arr)-1 Do widget_control, $
      state.button_arr[j], sensitive = 0
    widget_control, event.top, set_uval = state, /no_copy
    thm_ui_update_progress, event.top, 'Choosing Data Quantities to Load'
    if uval eq 'SCM' then Begin
       cal_params=thm_ui_scmcal(event.top, uval) 
       widget_control, event.top, get_uval = state, /no_copy
       state.scm_cal=cal_params
       widget_control, event.top, set_uval = state, /no_copy
    endif else Begin
       thm_ui_choose_dtype, event.top, uval 
    endelse
    widget_control, event.top, get_uval = state, /no_copy
    ;Check to see if there are duplicates
    If(ptr_valid(state.dtyp_1)) Then Begin
      If(ptr_valid(state.dtyp)) Then Begin
        ndtyp = [*state.dtyp, *state.dtyp_1]
        ndtyp = ndtyp[sort(ndtyp)]
        ndtyp = ndtyp[uniq(ndtyp)]
        ptr_free, state.dtyp
      Endif Else ndtyp = *state.dtyp_1
      ptr_free, state.dtyp_1
      state.dtyp = ptr_new(ndtyp)
      ;update the history
      h1 = thm_ui_multichoice_history('dtyp = ', ndtyp)
      widget_control, event.top, set_uval = state, /no_copy
      thm_ui_update_history, event.top, h1
      thm_ui_update_progress, event.top, 'Finished Choosing Data Quantities to Load'
    Endif Else Begin
      widget_control, event.top, set_uval = state, /no_copy
      thm_ui_update_progress, event.top, 'No Data Quantities Chosen'
    Endelse
    
    ;enable the buttons
    widget_control, event.top, get_uval = state, /no_copy
    For j = 0, n_elements(state.button_arr)-1 Do widget_control, $
      state.button_arr[j], sensitive = 1
    widget_control, event.top, set_uval = state, /no_copy
  Endif Else Begin
    
    ;check to see which event occurred
    Case uval Of   
      'EXIT': goto,  exit_sequence
      'LOAD':Begin
        widget_control, event.top, get_uval = state, /no_copy
        If(ptr_valid(state.dtyp)) Then dtype = *state.dtyp $
        Else If(ptr_valid(state.dtyp_pre)) Then dtype = *state.dtyp_pre $
        Else Begin
          widget_control, event.top, set_uval = state, /no_copy
          thm_ui_update_progress, event.top, 'Please Choose a data type'
          Return
        Endelse
        If(ptr_valid(state.station)) Then station = *state.station $
        Else station = '*'
        If(ptr_valid(state.astation)) Then astation = *state.astation $
        Else astation = '*'
        If(ptr_valid(state.probe)) Then probe = *state.probe $
        Else probe = ['a', 'b', 'c', 'd', 'e']
        t0 = state.st_time & t1 = state.en_time
        progobj = state.progobj
        widget_control, event.top, set_uval = state, /no_copy
        ;test for time range...
        If(t0 Eq 0.0 Or t1 Eq 0.0) Then Begin
          thm_ui_update_progress, event.top, 'Please Choose a Time Range'
          Return
        Endif
        ;test for too looong of a time range:
        dt_all = t1 - t0
        asf_l1 = strpos(dtype, 'asf/l1')
        asf_test = where(asf_l1 Ne -1, nasf_test)
        If(nasf_test Gt 0) Then Begin
          ttest = 7.0*3600.0d0
          txt_m = 'THIS IS A LONG TIME RANGE FOR ASF DATA. DO YOU REALLY WANT TO LOAD THE DATA?'
        Endif Else Begin
          ttest = 7.0*24.0*3600.0d0
          txt_m = 'THIS IS A LONG TIME RANGE. DO YOU REALLY WANT TO LOAD THE DATA?'
        Endelse
        ;A widget for a question
        If(dt_all Gt ttest) Then Begin
          ppp = yesno_widget_fn(title = 'test', label = txt_m)
        Endif Else ppp = 1b
        If(ppp Eq 0) Then Begin
          thm_ui_update_progress, event.top, 'Load Operation Cancelled'
          Return
        Endif
        h1 = 'varnames = thm_ui_load_data_fn('+ $
          ''''+time_string(t0)+''''+', '+ $
          ''''+time_string(t1)+''''+', '+ $
          'dtype=dtyp, station=station, astation=asi_station, probe=probe)'
        thm_ui_update_history, event.top, h1
        thm_ui_update_progress, event.top, 'Loading data...'
        ;special case for scm, need to pass in calibration parameters
        if (strlowcase(strmid(dtype(0),0,3)) eq 'scm') then Begin
           widget_control, event.top, get_uval = state, /no_copy
           tv_names = thm_ui_load_data_fn(t0, t1, dtype = dtype, $
                                       station = station, $
                                       astation = astation, $
                                       progobj = progobj, $
                                       probe = probe, $
                                       scm_cal = state.scm_cal)
           widget_control, event.top, set_uval = state, /no_copy
        endif else Begin
          tv_names = thm_ui_load_data_fn(t0, t1, dtype = dtype, $
                                       station = station, $
                                       astation = astation, $
                                       progobj = progobj, $
                                       probe = probe)
        endelse
        If(is_string(tv_names)) Then Begin
          thm_ui_update_data_all, event.top, tv_names
          ;Clear out the dtype pointer, set dtyp_pre
          widget_control, event.top, get_uval = state, /no_copy
          If(ptr_valid(state.dtyp)) Then ptr_free, state.dtyp
          If(ptr_valid(state.dtyp_pre)) Then ptr_free, state.dtyp_pre
          state.dtyp_pre = ptr_new(dtype)
          widget_control, event.top, set_uval = state, /no_copy
          thm_ui_update_history, event.top, ';Finished Loading data...'
          thm_ui_update_progress, event.top, 'Finished Loading data...'
        Endif Else Begin
          thm_ui_update_progress, event.top, 'NO NEW DATA LOADED: No New Data was loaded for requested data type and time interval'
        Endelse
      End
      'CLEARLOAD': Begin
        thm_ui_update_progress, event.top, 'Choosing Active Data Sets'
        widget_control, event.top, get_uval = state, /no_copy
        If(ptr_valid(state.dtyp)) Then ptr_free, state.dtyp
        If(ptr_valid(state.dtyp_1)) Then ptr_free, state.dtyp_1
        If(ptr_valid(state.dtyp_pre)) Then ptr_free, state.dtyp_pre
        If(ptr_valid(state.probe)) Then ptr_free, state.probe
        If(ptr_valid(state.station)) Then ptr_free, state.station
        If(ptr_valid(state.astation)) Then ptr_free, state.astation
        widget_control, event.top, set_uval = state, /no_copy
        history_ext = ['dtyp = ''''', $
                       'probe = ''''', $
                       'gmag_station = ''''', $
                       'asi_station = ''''']
        thm_ui_update_history, event.top, history_ext
        thm_ui_update_progress, event.top, 'Choosing Active Data Sets'
      End
      'DATALIST':Begin
	      if event.clicks eq 1 then begin
          thm_ui_update_progress, event.top, 'Choosing Active Data Sets'
          widget_control, event.top, get_uval = state, /no_copy
          pindex = widget_info(state.datalist, /list_select)
          pindex = pindex+1
          tv_names = tnames()
          newnames = tv_names[pindex-1]
          If(ptr_valid(state.active_vnames)) Then ptr_free, state.active_vnames
      	  state.active_vnames = ptr_new(newnames)
      	  history_ext = thm_ui_multichoice_history('varnames = ', newnames)
      	  widget_control, event.top, set_uval = state, /no_copy
      	  thm_ui_update_history, event.top, history_ext
      	  thm_ui_update_data_display, event.top, /only_active
      	  thm_ui_update_progress, event.top, 'Finished Choosing Active Data Sets'
          ;If double click, then show default limits:
          ;==========================================
        endif else begin
          thm_ui_update_progress, event.top, 'Choosing Active Data Sets'
      	  widget_control, event.top, get_uval = state, /no_copy
      	  pindex = widget_info(state.datalist, /list_select)
      	  pindex = pindex+1
      	  tv_names = tnames()
      	  newnames = tv_names[pindex-1]
      	  group_leader = state.wmaster
      	  widget_control, event.top, set_uval = state, /no_copy
      	  thm_ui_show_dlim, newnames[0],group=group_leader
        endelse
      End
      'DATASTRINP':Begin
        thm_ui_update_progress, event.top, 'Choosing Active Data Sets'
      End
      'SETDATATOSTRING':Begin
        thm_ui_update_progress, event.top, 'Choosing Active Data Sets'
        widget_control, event.top, get_uval = state, /no_copy
        dstxt = state.datastrinp
        widget_control, event.top, set_uval = state, /no_copy
        widget_control, dstxt, get_val = temp_string
        newnames = tnames(temp_string[0]) ;tnames can't handle arrays, unless it does....
        If(is_string(newnames)) Then Begin
          history_ext = thm_ui_multichoice_history('varnames = ', newnames)
          thm_ui_update_history, event.top, history_ext
          widget_control, event.top, get_uval = state, /no_copy
          If(ptr_valid(state.active_vnames)) Then ptr_free, state.active_vnames
          state.active_vnames = ptr_new(newnames)
          widget_control, event.top, set_uval = state, /no_copy
          thm_ui_update_data_all, event.top, newnames
          thm_ui_update_progress, event.top, 'Finished Choosing Active Data Sets'
        Endif Else Begin
          thm_ui_update_progress, event.top, 'Choosing Active Data Set using string failed'
        Endelse
      End
      'CLEARACTIVEDATA':Begin
        widget_control, event.top, get_uval = state, /no_copy
        If(ptr_valid(state.active_vnames)) Then ptr_free, state.active_vnames
        widget_control, event.top, set_uval = state, /no_copy
        thm_ui_update_data_display, event.top, /only_active
        thm_ui_update_progress, event.top, 'Cleared Active Data Sets'
      End
      'TR': Begin
        thm_ui_update_progress, event.top, 'Choosing Time Range'
        widget_control, event.top, get_uval = state, /no_copy
        trange_id = state.trange_id
        widget_control, event.top, set_uval = state, /no_copy
        If(widget_valid(trange_id)) Then widget_control, trange_id, /show $
        Else thm_ui_set_trange, event.top
      End
      'HELP': thm_ui_help
      'ERROR': thm_ui_error
      'HSAVE': Begin
        thm_ui_update_progress, event.top, 'Saving History'
        widget_control, event.top, get_uval = state, /no_copy
        hist = *state.history
        If(strcompress(strupcase(hist[0]), /remove_all) Ne 'NONE') Then Begin
          nhist = n_elements(hist)
          xt = time_string(systime(/sec))
          ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
            '_'+strmid(xt,11,2)+strmid(xt,14,2)+strmid(xt,17,2)
          ofile = 'thm_gui_original_history_'+ttt+'.pro'
          osf = strupcase(!version.os_family)
          If(osf Eq 'WINDOWS') Then ofile0 = file_expand_path('')+'\'+ofile $
          Else ofile0 = file_expand_path('')+'/'+ofile
          ofile = dialog_pickfile(title = 'THEMIS GUI History Filename', $
                                  filter = '*.pro', file = ofile0)
          If(is_string(ofile)) Then Begin
            openw, unit, ofile, /get_lun
            For j = 0, nhist-1 Do printf, unit, hist[j]
            printf, unit, 'End'
            free_lun, unit
            hist = [temporary(hist), ';History saved in file: '+ofile]
            ptr_free, state.history
            state.history = ptr_new(hist)
            widget_control, state.historylist, set_val = hist
            widget_control, event.top, set_uval = state, /no_copy
            thm_ui_update_progress, event.top, 'History saved in file: '+ofile
          Endif Else Begin
            widget_control, event.top, set_uval = state, /no_copy
            thm_ui_update_progress, event.top, 'No History saved'
          Endelse
        Endif Else Begin
          widget_control, event.top, set_uval = state, /no_copy
          thm_ui_update_progress, event.top, 'No History to save'
        Endelse
      End
      'HCLR':Begin
        thm_ui_update_progress, event.top, 'Clearing History'
        widget_control, event.top, get_uval = state, /no_copy
        ptr_free, state.history
        state.history = ptr_new('NONE')
        widget_control, state.historylist, set_val = 'None'
        widget_control, event.top, set_uval = state, /no_copy
        thm_ui_update_progress, event.top, 'Finished Clearing History'
      End
      'CFG':Begin
        thm_ui_config
      End
      ;For the next four, only call a new one if there is no valid one up
      'CAL':Begin
        widget_control, event.top, get_uval = state, /no_copy
        cal_id = state.cal_id
        widget_control, event.top, set_uval = state, /no_copy
        If(widget_valid(cal_id)) Then widget_control, cal_id, /show $
        Else thm_ui_call_cal_data, event.top
      End
      'CTO':Begin
        widget_control, event.top, get_uval = state, /no_copy
        cto_id = state.cto_id
        widget_control, event.top, set_uval = state, /no_copy
        If(widget_valid(cto_id)) Then widget_control, cto_id, /show $
        Else thm_ui_cotrans_old, event.top
      End
      'PROC':Begin
        widget_control, event.top, get_uval = state, /no_copy
        proc_id = state.proc_id
        widget_control, event.top, set_uval = state, /no_copy
        If(widget_valid(proc_id)) Then widget_control, proc_id, /show $
        Else thm_ui_dproc, event.top
      End
      'PLT':Begin
        widget_control, event.top, get_uval = state, /no_copy
        plt_id = state.plt_id
        widget_control, event.top, set_uval = state, /no_copy
        If(widget_valid(plt_id)) Then widget_control, plt_id, /show $
        Else thm_ui_call_tplot, event.top
      End
      'DOPLT':Begin
        widget_control, event.top, get_uval = state, /no_copy
        If(ptr_valid(state.active_vnames)) Then Begin
          tv_plot = *state.active_vnames
          pstate = state.pstate
        Endif Else tv_plot = ''
        widget_control, event.top, set_uval = state, /no_copy
        If(is_string(tv_plot)) Then Begin
          ptyp = pstate.ptyp
          wno = pstate.current_wno
          wsz = pstate.windowsize
          thm_ui_update_progress, event.top, 'Plotting '+tv_plot
          tv_plot_s = ''''+tv_plot+''''
          If(ptyp Eq 'PS') Then Begin
            xt = time_string(systime(/sec))
            ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
              '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
            filename = 'thm_gui_original_plot_'+ttt
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
              popen, filename
              tplot, tv_plot
              pclose
              history_ext = ['popen, '+''''+filename+'''', 'tplot, '+tv_plot_s, $
                             'pclose', ';CREATED: '+filename+'.ps']
              thm_ui_update_progress, event.top, 'CREATED: '+filename+'.ps'
              set_plot, dname
              !p.background = !d.table_size-1 ;White background   (color table 34)
              !p.color = 0      ; Black Pen
              !p.font = -1      ; Use default fonts
            Endif Else Begin
              thm_ui_update_progress, event.top, 'Operation Cancelled'
            Endelse
          Endif Else If(ptyp Eq 'PNG') Then Begin
            xt = time_string(systime(/sec))
            ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
              '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
            filename = 'thm_gui_original_plot_'+ttt
            osf = strupcase(!version.os_family)
            If(osf Eq 'WINDOWS') Then Begin
              filename0 = file_expand_path('')+'\'+filename
            Endif Else filename0 = file_expand_path('')+'/'+filename
            filename = dialog_pickfile(title = 'THEMIS GUI Plot Filename', $
                                       filter = '*.png', file = filename0)
            If(is_string(filename)) Then Begin
              dname = !d.name   ;'X' or 'WIN'
              set_plot, 'z'     ;do this in the z-buffer
              !p.background = !d.table_size-1 ;White background(color table 34)
              !p.color = 0      ; Black Pen
              !p.font = -1      ; Use default fonts
              tplot, tv_plot
              makepng, filename
              thm_ui_update_progress, event.top, 'CREATED: '+filename+'.png'
              set_plot, dname
              !p.background = !d.table_size-1
              !p.color = 0
              !p.font = -1
              history_ext = ['dname = !d.name', 'set_plot, ''z''', $
                             'tplot, '+tv_plot_s, 'makepng, '+''''+$
                             filename+'''', $
                             'set_plot, dname', $
                             ';CREATED: '+filename]
              thm_ui_update_progress, event.top, 'CREATED: '+filename+'.png'
            Endif Else Begin
              thm_ui_update_progress, event.top, 'Operation Cancelled'
            Endelse
          Endif Else Begin
            If(!version.os_family Eq 'Windows') Then Begin
              set_plot, 'win'
              history_ext = ['set_plot, ''win''', 'tplot, '+tv_plot_s]
            Endif Else Begin
              set_plot, 'x'
              history_ext = ['set_plot, ''x''', 'tplot, '+tv_plot_s]
            Endelse
            !p.background = !d.table_size-1
            !p.color = 0
            !p.font = -1
            window, wno, xs = wsz[0], ys = wsz[1]
            tplot, tv_plot, window = wno
            thm_ui_update_progress, event.top, 'Finished Plotting '
          Endelse
          thm_ui_update_history, event.top, history_ext
        Endif Else Begin
          thm_ui_update_progress, event.top, 'No Active Data, Nothing Happened'
        Endelse
      End
      'SUMMP':Begin
        widget_control, event.top, get_uval = state, /no_copy
        summp_id = state.summp_id
        widget_control, event.top, set_uval = state, /no_copy
        If(widget_valid(summp_id)) Then widget_control, summp_id, /show $
        Else thm_ui_summplot, event.top
      End
      Else:thm_ui_update_progress, event.top, uval+' Not Implemented'
    Endcase
  Endelse
  Return
End
Pro thm_gui_original
@tplot_com

  Common thm_gui_original_private, instr0, master

  If(widget_valid(master)) Then Begin
    message, /info, 'thm_gui_original is already active'
    thm_ui_update_progress, master, 'thm_gui_original is already active'
    Return
  Endif
  thm_init

  ;build master widget
  master = widget_base(/row, title = 'THEMIS: Main Menu', $
                       /align_top, /tlb_kill_request_events)

  ;Initial start and end times
  tt0x = temp_stime2daystr(!stime)
  tt0 = time_double(tt0x)-86400.0d0
  tt1 = tt0+86400.0d0
  tt0x = time_string(tt0)
  tt1x = time_string(tt1)

  ;Initial history
  init_history = ['; **** Starting thm_gui_original', $
                  ';Master widget id'+string(master), $
                  'plot_type = ''SCREEN''']
                  
  ;3 widgets in a row
  load_master = widget_base(master, /col, /align_center)
  flabel = widget_label(load_master, value = 'Data Choices')
  middle_master = widget_base(master, /col)
  flabel = widget_label(middle_master, value = 'Process/Plot Data', /align_center)

  ;the middle master has 3 rows
  ;buttons widget on top this time
  buttons_master = widget_base(middle_master, /row, /align_center) 
  ;lists of stuff in the middle
  lists_master = widget_base(middle_master, /row, /align_center)
  ;information-help-exit on the bottom
  info_master =  widget_base(middle_master, /row, /align_center)

  ;Ok, what goes in the widgets:
  ;load widget
  loadw = widget_base(load_master, /col, /align_center)
  ;what buttons in the load widget? All of the different types of data,
  ;of course:
  instr0 = ['ASI', 'ASK', 'ESA', $
           'EFI', 'FBK', 'FFT', 'FGM', $
           'FIT', 'GMAG', 'MOM', 'SCM', 'SST', 'STATE']
  ninstr0 = n_elements(instr0)
  loadbut = lonarr(ninstr0)
  For j = 0, ninstr0-1 Do $
    loadbut[j] = widget_button(loadw, val = instr0[j], uval = instr0[j])
  ;Separate out the load button, and time buttons
  loadx = widget_base(load_master, /col)
  timebut = widget_button(loadx, val = 'Time Range', uval = 'TR')
  loadbut_do = widget_button(loadx, val = 'Load Data', uval = 'LOAD')
  clearload = widget_button(loadx, val = 'Clear Load Queue', $
                            uval = 'CLEARLOAD')

  ;cotrans widget
  ctow = widget_base(buttons_master, /col)
  ctobut = widget_button(ctow, val = 'Coordinate Transform', uval = 'CTO')
  
  ;data procesisng widget
  procw = widget_base(buttons_master, /col)
  procbut = widget_button(procw, val = 'Data Processing', uval = 'PROC')
  
  ;plot widget
  pltx = widget_base(buttons_master, /row)
  pltw = widget_base(pltx, /col)
  pltbut = widget_button(pltw, val = 'Plot Menu', uval = 'PLT')
  
  ;plot_data button
  doplotbut = widget_button(pltx, val = 'Draw Plot', uval = 'DOPLT', $
                           /frame, scr_xsize = 100, scr_ysize = 50)
                           
  ;summary plot widget
  summpbut = widget_button(pltw, val = 'Overview Plots', uval = 'SUMMP')

  ;the middle of the middle, the lists_master holds the data_list and
  ;history list widgets
  ;start a state array
  state_x = {datalist:0, data_id:ptr_new()}
  
  ;If there is data loaded already, you want to have it here, also you
  ;need to set a start and end time - jmm, 18-jan-2008
  thm_ui_set_data_id, state_x
  val_data = *state_x.data_id     ;you know this will work
  If(n_elements(val_data) Gt 1) Then Begin
    val_data = val_data[1:*]
    ;for start and end times, use timerange function
    oti = timerange(/current)
    st_time = oti[0]
    en_time = oti[1]
  Endif Else Begin
    val_data = 'None'
    st_time = 0.0d0
    en_time = 0.0d0
  Endelse
  datadisp = widget_base(lists_master, /col)
  flabel = widget_label(datadisp, value = 'Loaded Data', /align_center)
  state_x.datalist = widget_list(datadisp, value = val_data, $
                                 uval = 'DATALIST', xsiz = 25, ysiz = 15, $
                                 frame = 5, /multiple)
  dstringbase = widget_base(datadisp, /row)
  datastrinp = widget_text(dstringbase, value = '*', uval = 'DATASTRINP', $
                           xsiz = 15, ysiz = 1, /editable, /all_events)
  datastrbut = widget_button(dstringbase, val = 'Set Active Data to String', $
                             uval = 'SETDATATOSTRING')

  ;A widget the shows the Active datasets
  adatadisp = widget_base(lists_master, /col)
  flabel = widget_label(adatadisp, value = 'Active Data (Coordinates)', /align_center)
  adatalist = widget_text(adatadisp, value = 'None', xsiz = 25, ysiz = 15, $
                          /scroll, frame = 5)
  clearactivebut = widget_button(Adatadisp, val = 'Clear Active Data', $
                                 uval = 'CLEARACTIVEDATA')
  
  ;The history widget is now on the front
  historyw = widget_base(lists_master, /col)
  flabel = widget_label(historyw, value = 'History', /align_center)
  historylist = widget_text(historyw, value = init_history, xsiz = 50, $
                            ysiz = 15, $
                            /scroll, frame = 5)
  hbuttons = widget_base(historyw, /row, /align_center)
  hsavebut = widget_button(hbuttons,  val = ' Save History', uval = 'HSAVE', $
                          /align_center)
  hclearbut = widget_button(hbuttons,  val = ' Clear History', uval = 'HCLR', $
                          /align_center)

  ;Ok, now the bottom row of the widget
  progress_text = widget_text(info_master, value = init_history, $
                              xsize = 100, ysize = 1, /scroll)
  helpbut = widget_button(info_master, val = ' HELP ', uval = 'HELP', $
                        /align_center)
  errbut = widget_button(info_master, val = ' ERROR ', uval = 'ERROR', $
                         /align_center)
  cfgbut = widget_button(info_master, val = '  Config ', uval = 'CFG', $
                         /align_center)
  exitbut = widget_button(info_master, val = ' Exit ', uval = 'EXIT', $
                        /align_center)

  ;create a progress object
  progobj = obj_new('thm_ui_progobj')
  progobj -> set, gui_id = master
  If(obj_valid(!themis.progobj)) Then obj_destroy, !themis.progobj
  !themis.progobj = progobj

  ;define state, plot, calibration structures
  button_arr = [exitbut, cfgbut, errbut, helpbut, hsavebut, hclearbut, $
                datastrbut, datastrinp, pltbut, procbut, ctobut, summpbut, $
                clearload, loadbut_do, timebut, loadbut, clearactivebut, $
                doplotbut]
                
  ;define state, plot, calibration structures  
  scm_cal_params = {nk:'', mk:'', despin:1, nspins:'1',$
                 cleanup_type:'None', cleanup_author:'ole', win_dur_1s:'1.0', $
                 win_dur_st:'1.0', dfbb:1, dfbdf:1, ag:1, det_freq:'0', $
                 low_freq:'0.1', freq_min:'0.1', freq_max:'1.0', psteps:5, $
                 edge:'Zero', download:1, cal_dir:'', in_suffix:'', $ 
                 out_suffix:'', coord_sys:'DSL', verbose:0}
  
  pstate = {st_time:st_time, en_time:en_time, windowsize:[640, 480], $
            ps_size:[7.0,9.5], ps_units:'inches', current_wno:0, $
            ptyp:'SCREEN'}

  state = {wmaster:master, $    ;master widget id
           progobj:progobj, $
           datalist:state_x.datalist, $ ;datalist id
           datastrinp:datastrinp, $
           adatalist:adatalist, $
           st_time:st_time, $     ;start_time, double
           en_time:en_time, $     ;end_time
           data_id:state_x.data_id, $ ;a pointer to an array of strings, 1 for each loaded dataset
           active_vnames:ptr_new(), $ ;the tplot variable names that are active
           history:ptr_new(init_history), $ ;a string array with the analysis history
           historylist:historylist, $ ;the history list widget
           progress_text:progress_text, $ ;tells you what's happenin'
           messages:ptr_new(init_history[0]), $ ;
           dtyp_1:ptr_new(), $ ;the datatype from the last choose_data
           dtyp:ptr_new(), $    ;the datatype to load, must be cleared
           dtyp_pre:ptr_new(), $ ;the dtyp for the last load call,
                                ;so that you can load those types for
                                ;a different time range or probe,
                                ;without choosing dtyp's again
           probe:ptr_new(), $ ;probe_id
           station:ptr_new(), $
           astation:ptr_new(), $
           cal_id:-1l, $      ;id of the cal_data widget
           cto_id:-1l, $      ;id of the cotrans_data widget
           proc_id:-1l, $     ;id of the data process widget
           plt_id:-1l, $      ;id of the tplot widget
           summp_id:-1l, $    ;id of the summplot widget
           trange_id:-1l, $   ;id of the time_range widget
           button_arr:button_arr, $ ;all of the buttons
           scm_cal:scm_cal_params, $ ;the parameter structure for scm
           pstate:pstate}     ;the state of plots

  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  xmanager, 'thm_gui_original', master, /no_block

Return
End
