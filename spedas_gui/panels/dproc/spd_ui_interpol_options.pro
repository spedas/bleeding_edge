;+
;NAME:
;  spd_ui_interpol_options
;
;PURPOSE:
;  Front end window allowing user to select options for interpolation.
;
;CALLING SEQUENCE:
;  result = spd_ui_interpol_options(gui_ID, historywin, statusbar, datap)
;
;INPUT:
;  gui_id: group leader widget
;  historywin: history window object
;  statusbar: status bar object
;  datap: pointer to loaded data object
;  ptree: pointer to tree copy
;
;OUTPUT:
;  values = {num, type, matchto, extrap, suffix, ok}
;    num: number of points passed to interpol function
;    type: type on interpolation (0=linear, 1=quad, 2=lst sqr qd, 3=spline, 4= nearest neighbor)
;    matchto: pointer to copy of returned struct from loaded data obj,
;             specifies the selected quantity to match, null string if
;             none selected
;    extrap: type of extrapolation for matching (0=none, 1=nan) 
;    suffix: optional suffix for new data quantity
;    ok: flag indicating whether to procede with interpolation
;
;NOTES:
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/dproc/spd_ui_interpol_options.pro $
;-

pro spd_ui_interp_match_event, event

    compile_opt idl2, hidden

  widget_control, event.top, get_uval=state, /no_copy

  catch, on_err
  if on_err ne 0 then begin
    catch, /cancel
    help, /last_message, output=msg
    if is_struct(state) then begin
      for i=0, n_elements(msg)-1 do state.historywin->update,msg[i]
      gui_id = state.gui_id
      hwin = state.historywin
    endif
    print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted, see console for details.', $
                     /noname,/center, title='Error in Interpolate Match')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif
  
  if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
        state.historywin->update,'SPD_UI_INTERPOL_OPTIONS: Match window killed',/dontshow
        widget_control, event.top, /destroy
        return
  endif

  widget_control, event.id, get_uval=uval
  
  if size(uval, /type) ne 0 then begin
    case uval of
      'OK':begin
        ;Get tree value and copy into pointer value to be returned
        val = state.tree->getvalue() 
        if size(val,/type) eq 10 then *state.pname = *(val[0])

        *state.ptree = state.tree->getcopy()

        widget_control, event.top, /destroy
        return
      end

      'CANCEL':begin
        if obj_valid(state.tree) then *state.ptree = state.tree->getcopy()
        state.historywin->update,'SPD_UI_INTERPOL_OPTIONS: Match window canceled'
        widget_control, event.top, /destroy
        return
      end

      else:
    endcase
  endif
  
  widget_control, event.top, set_uval=state, /no_copy
  
end 



function spd_ui_interp_match, state

    compile_opt idl2, hidden

;Check for data
  if ~obj_valid(*state.datap) then begin
    ok = error_message('No viable data, please restart Data Processing', $
                       /noname,/center,traceback=0,title='Interpolate Error')
    return, -1
  endif

;Main Base
  mtlb = widget_base(/col, /modal, group_leader=state.gui_id, /base_align_center, $
                     title='Select data to match')

;Widget Tree
  tree = obj_new('spd_ui_widget_tree', mtlb, 'TREE', *state.datap, xsize=300, $
                 ysize=400, mode=0)
  ;tree->setproperty, leafonly=1
  tree->update,from_copy=*state.ptree

;Buttons
  mButtonBase = widget_base(mtlb, /row, /align_center)
  mOk = widget_button(mbuttonbase, value='OK', uval='OK', xsize=45)
  mCancel = widget_button(mbuttonbase, value='Cancel', uval='CANCEL', xsize=45)

;Initialize
  pname=ptr_new('')
  mstate = {mtlb:mtlb, gui_id:state.gui_id, historywin:state.historywin, $
            datap:state.datap, tree:tree, ptree:state.ptree, pname:pname}

  centertlb, mtlb
  
  widget_control, mtlb, set_uval=mstate
  widget_control, mtlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, mtlb, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_interp_match', mtlb, /no_block

  name=*pname
  ptr_free, pname

  return, name

end 



pro spd_ui_interp_updatestatus, state

    compile_opt idl2, hidden

numtype = widget_info(state.ntype,/button_set)
i='Interpolate:  '

if numtype then begin
  widget_control, state.numtext, get_value=value
  if ~finite(value) or value le 1 then $
      state.statusbar->update,i+'Invalid # of points, please re-enter.' $
    else state.statusbar->update,i+'Using '+strtrim(value,1)+' points.
endif else begin
  widget_control, state.cadtext, get_value=value
  if ~finite(value) or value le 0 then $
      state.statusbar->update,i+'Invalid cadence, please re-enter.' $
    else state.statusbar->update,i+'Using '+strtrim(value,1)+' second cadence.'
endelse

end 

pro spd_ui_interpol_options_event, event

    compile_opt idl2, hidden
  
  widget_control, event.top, get_uval=state, /no_copy
  
;error catch block
  catch, on_err
  if on_err ne 0 then begin
    catch, /cancel
    help, /last_message, output=msg
    if is_struct(state) then begin
      for i=0, n_elements(msg)-1 do state.historywin->update,msg[i]
      gui_id = state.gui_id
      hwin = state.historywin
    endif
    print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted, see console for details.', $
                     /noname,/center, title='Error in Interpolate Options')
    widget_control, event.top, /destroy
    if widget_valid(gui_id) && obj_valid(hwin) then begin
      spd_gui_error, gui_id, hwin
    endif
    return
  endif

;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    state.historywin->update,'SPD_UI_INTERPOL_OPTIONS: Widget killed', /dontshow
    widget_control, event.top, set_uval=state, /no_copy
    widget_control, event.top, /destroy
    return
  endif

;use value for case statement
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 then begin
    Case uval Of
      'OK':begin

        ;Get type
        (*state.pvals).ntype = widget_info(state.ntype,/button_set) ? 0:1

        widget_control, state.trange, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
        if (~valid) then begin
          result = dialog_message('Invalid time range inputed. Use format: YYYY-MM-DD/hh:mm:ss',/center)
          break
        endif

        ;Get number of points
        widget_control, state.numtext, get_value = num
        if finite(num) && (num ge 1) then (*state.pvals).num = num $
          else if (*state.pvals).ntype eq 0 then begin
            ok = dialog_message('Invalid number of points, please enter a numeric value greater than or equal to 1.',/information, $
                                /center,title='Interpolate Error')
            break
          endif

        ;Get cadence
        widget_control, state.cadtext, get_value = cad
        if finite(cad) && (cad gt 0) then (*state.pvals).cad = cad $
          else if (*state.pvals).ntype eq 1 then begin
            ok = dialog_message('Invalid cadence, please enter a numeric value greater than 0.',/information, $
                                /center,title='Interpolate Error')
            break
          endif

        ;Check if matching
        (*state.pvals).match = widget_info(state.matchbase,/sensitive) 
        if (*state.pvals).match then begin
          if (*state.pvals).matchto eq '' then begin
            ok = dialog_message('Please select a data quantity for matching', $
                                /information,/center, title='Interpolate Error')
            break
          endif
        endif

        ;Get type requested (0=linear, 1=quad, 2=lst sqr qd, 3=spline 4 = nearest neighbor) 
        for i=0, n_elements(state.type)-1 do begin
          if widget_info(state.type[i],/button_set) then (*state.pvals).type[i] = 1
        endfor

        ;Get suffix if any
        widget_control, state.nametext, get_value = name
        (*state.pvals).suffix = name

        ;Check for time range limits
        (*state.pvals).limit = widget_info(state.timebase,/sensitive)
        if (*state.pvals).limit then begin
           tr = spd_ui_time_widget_get_value(state.trange)
           if(obj_valid(tr)) then (*state.pvals).trange = tr
        endif

        ;Get extrapolate option ([none,last value, NaN]) 
        for i=0, n_elements(state.extra)-1 do begin
          if widget_info(state.extra[i],/button_set) then (*state.pvals).extrap[i] = 1
        endfor

        ;Set success flag
        (*state.pvals).ok = 1

        widget_control, event.top, /destroy
        return
      end

      'CANCEL':Begin
        state.historywin->update,'Interpolate Options Canceled', /dontshow
        state.statusbar->update,'Interpolate Canceled'
        widget_control, event.top, set_uval=state, /no_copy
        widget_control, event.top, /destroy
        return
      end

      'NUM': spd_ui_interp_updatestatus, state

      'CAD': spd_ui_interp_updatestatus, state

      'NUMB': begin
        widget_control, state.cadtext, sens=0
        widget_control, state.numtext, sens=1
        spd_ui_interp_updatestatus, state
      end

      'CADB': begin
        widget_control, state.cadtext, sens=1
        widget_control, state.numtext, sens=0
      end

      'LIMIT': widget_control, state.timebase, sens = widget_info(event.id, /button_set)

      'MATCH':begin
        widget_control, state.matchbase, sens = widget_info(event.id, /button_set)
        widget_control, state.numbase, sens = ~widget_info(event.id, /button_set)
      end

      'MATCHTO':begin
        ;Get tree selection struct(will be null string if fail)
        name = spd_ui_interp_match(state)

        ;Update label and enter into return value
        if is_struct(name) then begin
          widget_control, state.matched, set_value=name.groupname
          (*state.pvals).matchto = name.groupname
          state.statusbar->update, 'Interpolate:  Matching to '+name.groupname+'.'
        endif
      end

      Else: dprint,  'Unknown Uval'
    EndCase
  endif

widget_control, event.top, set_uval=state, /no_copy

end 


function spd_ui_interpol_options, gui_ID, historywin, statusbar, datap, ptree = ptree

    compile_opt idl2

;Constants
  num = 1000        ;initial # of points
  cad = 3d          ;initial cadence
  suffix = '-itrp'  ;initial suffix


  tlb = widget_base(title = 'Time Interpolate Options', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


;Main Bases
  mainBase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)
    numBase = widget_base(mainbase, /row, yoffset=8)
      numtypeBase = widget_base(numbase, /col, /exclusive)
      spinnerBase = widget_base(numbase, /col)

    typeBase = widget_base(mainbase, /row, /exclusive, ypad=4)

    matchlabelBase = widget_base(mainbase, /row, /nonexclusive)
    matchBase = widget_base(mainbase, /col, frame=1, sensitive=0)
      matchtoBase = widget_base(matchBase, /row)
      matchoptBase = widget_base(matchBase, /row, /exclusive)

    timelabelBase = widget_base(mainbase, /row, /nonexclusive)
    timeBase = widget_base(mainbase, /col, fram=1, sensitive=0)

    nameBase = widget_base(mainBase, /row, ypad=8)
    buttonBase = widget_base(mainbase, /row, /align_center, ypad=12)


;Widgets
;
;Suffix widgets
  namelabel = widget_label(namebase, value = 'Suffix: ')
  nametext = widget_text(namebase, /all_events, /editable, tab_mode=1, xsize=15, $
                         value=suffix)

;Number widgets
  cadence = widget_button(numtypebase, value='Cadence (sec): ', uval='CADB')
  cadtext = spd_ui_spinner(spinnerbase, text_box_size=10, $
                           uval='CAD', value = cad, incr=1, min_value='0')
  number = widget_button(numtypebase, value='Number of points: ', uval='NUMB')
  numtext = spd_ui_spinner(spinnerbase, text_box_size=10, sens=0, $
                           uval='NUM', value = num, incr=1,min_value='1')

;Type widgets
  linear = widget_button(typebase, value = 'Linear', uname='LINEAR')
  quad = widget_button(typebase, value = 'Quadratic')
  lsquad = widget_button(typebase, value = 'Lst Sqr Quad')
  spline = widget_button(typebase, value = 'Spline')
  nearest_neighbor = widget_button(typebase, value = 'Nearest Neighbor', uname='NNEIGHBOR')

;Time range widgets
  timebutton = widget_button(timelabelbase, value='Limit time range.', uval='LIMIT')
  time = spd_ui_time_widget(timebase, statusbar, historywin, oneday=0b)

;Match To widgets
  matchlabel = widget_button(matchlabelbase, value='Match to data quantity.', $
                             uval='MATCH')
  
  matchto = widget_button(matchtobase, value='Match', uval='MATCHTO', $
                          tooltip='Click to select quantity from data tree')
  separator = widget_label(matchtobase, value=' : ')
  matched = widget_label(matchtobase, value='none', xsize=100)
  
  noextra = widget_button(matchoptbase, value="Don't extrapolate")
  extra = widget_button(matchoptbase, value='Extrapolate')
  nanextra = widget_button(matchoptbase, value='Extrapolate w/ NaNs')
  

;Buttons
  ok = widget_button(buttonbase, value = 'OK', xsize=60, uval='OK')
  cancel = widget_button(buttonbase, valu = 'Cancel', xsize=60, uval='CANCEL')



;Initializations and such
;
  widget_control, cadence, set_button=1
  widget_control, linear, set_button=1
  widget_control, noextra, set_button=1

  ;initialize time range widget w/ data's time range
  active_data = (*datap)->getactive()

  for i=0, n_elements(active_data)-1 do begin
    (*datap)->getvardata, name=active_data[i], trange=trange
    if ~undefined(trange) then break
  endfor

  ;create new time range object
  if ~undefined(trange) then begin
    tr = obj_new('SPD_UI_TIME_RANGE')
    ok = tr->SetStartTime(trange[0])
    ok = tr->setendtime(trange[1])
    widget_control, time, set_value=tr 
  endif else tr = obj_new('SPD_UI_TIME_RANGE')

;struct to be returned later
values = {num:num, cad:cad, type:[0,0,0,0,0], matchto:'', match:0b, ntype:0b, $
            trange:tr, limit:0b, extrap:[0,0,0], suffix:suffix, ok:0b}

  pvals = ptr_new(values)

  state = {tlb:tlb, gui_id:gui_id, historywin:historywin, statusbar:statusbar, $
           type:[linear,quad,lsquad,spline,nearest_neighbor], extra:[noextra,extra,nanextra], ntype:number, $
           numtext:numtext, nametext:nametext, matchbase:matchbase, matched:matched, $
           numbase:numbase, timebase:timebase, trange:time, cadtext:cadtext, $
           pvals:pvals, datap:datap, ptree:ptree}

  centertlb, tlb
  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  xmanager, 'spd_ui_interpol_options', tlb, /no_block

  values = *pvals
  ptr_free, pvals

  widget_control, /hourglass

  Return, values

end
