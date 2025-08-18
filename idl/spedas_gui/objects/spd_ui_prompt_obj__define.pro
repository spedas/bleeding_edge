;+
; Name: spd_ui_prompt_obj
; 
; Purpose:
;     For encapsulating access to the prompt interface in the SPEDAS GUI
;     
; 
; Keywords:
;     msg: message to display in the prompt
;     gui_id: id of the parent (GUI) widget
;     historyWin: history window object, for sending text to the history window
;     statusBar: status bar object, for sending text to the status bar
;     
; Output:
;     reference to the new prompt object
;     
; Methods:
;     sendtoScreen: creates the prompt
;     
; Examples:
;     ; create the object
;     gui_prompt_obj = obj_new('SPD_UI_PROMPT_OBJ', historyWin=historyWin, statusBar=statusBar)
;     ; send the prompt to the user
;     user_selection = gui_prompt_obj->sendtoScreen('Are you sure you would like to overwrite this data?', 'Overwrite Data?', gui_id = gui_id)
;     ; check the option selected by the user
;     ...
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_prompt_obj__define.pro $
;-


function spd_ui_prompt_obj::sendtoScreen, msg, title, gui_id = gui_id
    if ~undefined(gui_id) then myguiid = gui_id else myguiid = self.gui_id

    user_selection = spd_ui_prompt_widget(myguiid,$
    self.statusbar,self.historywin,$
    prompttext=msg,/yes,/allyes,/no,/allno,title=title, frame_attr=8) 
    return, user_selection
end

function spd_ui_prompt_obj::init, msg=msg, gui_id=gui_id, historyWin=historyWin, statusBar=statusBar
    if undefined(msg) then msg = ''
    if undefined(gui_id) then gui_id = 1b
    if undefined(historyWin) then historyWin = obj_new()
    if undefined(statusBar) then statusBar = obj_new()

    self.msg = msg
    self.gui_id = gui_id
    self.historyWin = historyWin
    self.statusBar = statusBar
    return, 1
    
end

pro spd_ui_prompt_obj__define

    state = {SPD_UI_PROMPT_OBJ, $
            msg: '',$
            gui_id: 1b,$
            historyWin: obj_new(),$
            statusBar: obj_new()}
end
