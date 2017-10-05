;+
;NAME:
;    spd_ui_superpo_options
;
;PURPOSE:
;    This is an example SPEDAS data processing plugin that adds a 
;    window to the data processing panel for the time series analysis routine
;    superpo_histo. This interface allows the GUI user to
;    calculate the minimum, maximum, average, median, and difference between min and max
;    for several time series datasets (as specified by the tplot variables in the active data 
;    in the data processing panel).
;
;CALLING SEQUENCE:
;    plugin_options = spd_ui_superpo_options(gui_id, statusbar, historywindow)
;
;INPUT:
;    gui_id: widget id of group leader
;    status_bar: status bar object ref.
;    history_window: history window object ref.
;    loaded_data: loaded data object ref.
;
;OUTPUT:
;    plugin_options: anonymous structure containing input and keyword parameters for the data processing 
;                   plugin code (in the case of this example, superpo_histo)
;    plugin_options = {
;           dproc_routine: 'superpo_histo' ; name of the data processing routine that we're providing 
;                                        an interface to.
;           ok: flag indicating success (user clicked OK in the window)
;           process_all_vars_at_once: 1b ; flag for whether this data processing operation should
;                                      apply to all variables at once (1), or one at a time (0)?
;           keywords: keyword_values ; structure that contains keywords to pass to the data processing 
;                                  plugin; see below for an example specific to this plugin
;        }
;    
;    where 'keyword_values' is the following structure:
;    
;        keyword_values = {
;           min: 'minarr' ; specific to this example, passes this value to the 'min' keyword 
;                       in superpo_histo 
;           max: 'maxarr' ; similar to above
;           med: 'medarr' ; similar to above
;           avg: 'avgarr' ; similar to above
;           dif: 'difarr' ; similar to above
;        }
;    
;    To pass additional information to the data processing routine via 
;    the routine's keywords, add new tags to the keyword_values structure. 
;    
;    
;    For example, when the user clicks OK in this dialog, the following call is made:
;        superpo_histo, '[list of variables in the active data list]', min='minarr', max='maxarr', $
;            med='medarr', avg='avgarr', dif='difarr'
;    
;
;NOTES:
;    The _extra keyword should be included if any of the 4 input keywords are not used.
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/api_examples/data_processing/spd_ui_superpo_options.pro $
;-

pro spd_ui_superpo_options_event, event
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
                     /noname,/center, title='Error')
        widget_control, event.top, /destroy
        if widget_valid(gui_id) && obj_valid(hwin) then begin
            spd_gui_error, gui_id, hwin
        endif
        return
    endif

    ;kill requests
    if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
        state.historywin->update,'SPD_UI_SUPERPO_OPTIONS: Widget killed', /dontshow
        state.statusbar->update,'Superposed window canceled'
        widget_control, event.top, /destroy
        return
    endif

    ;get user value
    widget_control, event.id, get_uval=uval

    if size(uval,/type) ne 0 then begin
        case uval Of
            'OK':begin
                ; get the options
                widget_control, state.min_text, get_value = min_text
                widget_control, state.max_text, get_value = max_text
                widget_control, state.med_text, get_value = med_text
                widget_control, state.avg_text, get_value = avg_text
                widget_control, state.dif_text, get_value = dif_text
                widget_control, state.resolution, get_value = res_text
                
               ; (*state.pvals).dproc_routine = 'superpo_interpol'
                (*state.pvals).dproc_routine = 'superpo_histo'
                
                ;Set success flag
                (*state.pvals).ok = 1b
                
                ; set the keywords to pass to the data processing routine 
                str_element,(*state.pvals),'keywords.min',min_text[0],/add
                str_element,(*state.pvals),'keywords.max',max_text[0],/add
                str_element,(*state.pvals),'keywords.med',med_text[0],/add
                str_element,(*state.pvals),'keywords.avg',avg_text[0],/add
                str_element,(*state.pvals),'keywords.dif',dif_text[0],/add
                str_element,(*state.pvals),'keywords.res',res_text[0],/add
                
                widget_control, event.top, /destroy
                return
            end
            'CANCEL': begin
                state.historywin->update,'SPD_UI_SUPERPO_OPTIONS: Canceled', /dontshow
                state.statusbar->update,'Superposed window canceled'
                widget_control, event.top, /destroy
                return
            end
          else: 
        endcase
    endif

    widget_control, event.top, set_uval = state, /no_copy

end


function spd_ui_superpo_options, gui_id=gui_id, $
                                 status_bar=statusbar, $
                                 history_window=historywin, $
                                 _extra=_extra
    compile_opt idl2

    catch, _err
    if _err ne 0 then begin
        catch, /cancel
        ok = error_message('Error starting Superposed Options, see console for details.')
        widget_control, tlb, /destroy
        return,{ok:0}
    endif

    tlb = widget_base(title = 'Superposed Analysis', /col, /base_align_center, $ 
                    group_leader=gui_id, /modal, /tlb_kill_request_events)


    ; Main bases
    mainbase = widget_base(tlb, /col, xpad=4, ypad=4, tab_mode=1)
    contentBase = widget_base(mainbase, /col, ypad=4)
    nameBase = widget_base(mainbase, /row, ypad=4)
    buttonBase = widget_base(mainbase, /row, /align_center, ypad=10)

    label_width = 60 ; pixels
    
    ; Options widgets
    options_base = widget_base(contentBase, /col, xpad=0, ypad=0, space=0)
    resolution = spd_ui_spinner(options_base, label = 'Resolution (sec):  ', $
                              text_box_size=10, uval='RES', value=60d, incr=1, $
                              tooltip='Sampling interval', min_value=0)
                              
    min_row_base = widget_base(options_base, /row)
    superpo_min_label = widget_label(min_row_base, value='Min: ', xsize=label_width)
    superpo_min_text = widget_text(min_row_base, value='minarr', /editable)
    
    max_row_base = widget_base(options_base, /row)
    superpo_max_label = widget_label(max_row_base, value='Max: ', xsize=label_width)
    superpo_max_text = widget_text(max_row_base, value='maxarr', /editable)
    
    avg_row_base = widget_base(options_base, /row)
    superpo_avg_label = widget_label(avg_row_base, value='Average: ', xsize=label_width)
    superpo_avg_text = widget_text(avg_row_base, value='avgarr', /editable)
    
    med_row_base = widget_base(options_base, /row)
    superpo_median_label = widget_label(med_row_base, value='Median: ', xsize=label_width)
    superpo_median_text = widget_text(med_row_base, value='medarr', /editable)
    
    diff_row_base = widget_base(options_base, /row)
    superpo_diff_label = widget_label(diff_row_base, value='Difference: ', xsize=label_width) 
    superpo_diff_text = widget_text(diff_row_base, value='difarr', /editable)
    
    ; Buttons
    ok = widget_button(buttonbase, value = 'OK', xsize=60, uval='OK')
    cancel = widget_button(buttonbase, valu = 'Cancel', xsize=60, uval='CANCEL')

    ; default keywords that are passed to the data processing routine when the user clicks 
    ; OK in this panel
    values = {min: 'minarr', max: 'maxarr', med: 'medarr', avg: 'avgarr', dif: 'difarr'}
    
    ; plugin options for this data processing plugin
    ;    dproc_routine: the data processing routine to call when the user clicks 
    ;     OK in this panel
    ; 
    ;    ok: 1b when the user clicks OK, 0b when the user doesn't
    ; 
    ;    process_all_vars_at_once: certain operations in the data processing panel require all
    ;     active variables to be passed to the dproc_routine at once while others operate on
    ;     each active variable one at a time; to process all at once, set this tag to 1b, 
    ;     otherwise set it to 0b
    plugin_options = {dproc_routine: 'superpo_histo', ok:0b, process_all_vars_at_once: 1b, keywords: values}

    pvals = ptr_new(plugin_options)

    state = {tlb:tlb, gui_id:gui_id, statusbar:statusbar, historywin:historywin, $
            min_text: superpo_min_text, max_text: superpo_max_text, $
            avg_text: superpo_avg_text, med_text: superpo_median_text, $
            dif_text: superpo_diff_text, resolution: resolution, $
            pvals:pvals}

    centertlb, tlb

    widget_control, tlb, set_uvalue = state, /no_copy
    widget_control, tlb, /realize

    ;keep windows in X11 from snaping back to 
    ;center during tree widget events 
    if !d.NAME eq 'X' then begin
        widget_control, tlb, xoffset=0, yoffset=0
    endif

    xmanager, 'spd_ui_superpo_options', tlb, /no_block

    ;Return adjusted plugin options
    plugin_options = *pvals
    ptr_free, pvals

    widget_control, /hourglass
    return, plugin_options
end
