;+
; Name
;     spd_ui_sbar_hwin_update
;     
; Purpose:
;     Wrapper routine for updating the status bar and history window objects
;     also handles dialog messages from error handlers
;
; Arguments:
;     state: state structure from the top level widget, contains the history window and status bar objects
;     message: string or array of strings to write to the history window and status bar objects
;     /nohistoryWin: flag to turn off updating the history window object
;     /nostatusBar: flag to turn off updating the status bar object
;     /error: flag indicating an error sent us here
;     err_msgbox_title: title to be displayed in the error msgbox
; 
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_sbar_hwin_update.pro $
;-

pro spd_ui_sbar_hwin_update, state, message, nohistoryWin=nohistoryWin, $
    nostatusBar=nostatusBar, error=error, err_msgbox_title=err_msgbox_title
    compile_opt idl2, hidden
    ; check that we have a valid state structure and message
    if (is_struct(state) && ~undefined(message)) then begin
        
        for i=0, n_elements(message)-1 do begin
            if (undefined(nohistoryWin) && obj_valid(state.historyWin)) $
                then state.historyWin->Update, message[i]
            if (undefined(nostatusBar) && obj_valid(state.statusBar)) $
                then state.statusBar->Update, message[i]
        endfor

        ; if an error sent us here, display the error msg
        if ~undefined(error) then begin
            widget_id = state.gui_id
            print, 'Error--See history'
            if undefined(err_msgbox_title) then err_msgbox_title='Error'
            ok=error_message('An unknown error occured and the window must be restarted. See console for details.', $
                /noname, /center, title=err_msgbox_title)
            if widget_valid(widget_id) && obj_valid(state.historyWin) $
                then spd_gui_error,widget_id,state.historyWin
        endif
    endif else if ~is_struct(state) then begin
        dprint, 'No valid state structure.'
    endif else if undefined(message) then begin
        dprint, 'No message to update.'
    endif
end
