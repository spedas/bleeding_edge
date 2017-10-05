;+ 
;NAME:
; spd_ui_calculate
;
;PURPOSE:
; A widget interface for selecting data
;
;CALLING SEQUENCE:
; spd_ui_calculate, master_widget_id
;
;INPUT:
; master_widget_id = the id number of the widget that calls this program
;
;OUTPUT:
; none
;
;HISTORY:
;$LastChangedBy: pcruce $
;$LastChangedDate: 2015-01-05 17:01:57 -0800 (Mon, 05 Jan 2015) $
;$LastChangedRevision: 16596 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_calculate.pro $
;
;---------------------------------------------------------------------------------

function spd_ui_calculate_insert_text,programTextID,insertText,offset
 
  Compile_Opt hidden,idl2

  Widget_control,programTextID,get_value=programtext

  ;insert requested constant at cursor location
  xy = widget_info(programTextID,text_offset_to_xy=offset)
      
  ;cursor is allowed to go one element beyond current text
  if xy[1] ge n_elements(programtext) then begin
    temptext = strarr(n_elements(programtext)+1)
    temptext[0:n_elements(programtext)-1] = programtext
    programtext = temptext
  endif
  
  ;check that xy is not [-1,-1]
  if xy[0] ge 0 and xy[1] ge 0 then begin
  
    textline = programtext[xy[1]] 
    textline = strmid(textline,0,xy[0]) + insertText + strmid(textline,xy[0],strlen(textline)-xy[0])
    outText = programText
    outText[xy[1]] = textline
   
  endif else begin

    ;otherwise is this a new line?
    if spd_ui_calculate_checknl(programTextID, offset) then begin
      outText = [programText, insertText]
    endif

  endelse

  return,outText
  
end


; Helper fuction to determine if cursor is on a new line
; at the end of the current text widget.
function spd_ui_calculate_checknl, id, offset

    compile_opt idl2, hidden

  ;get number of known chars in text widget
  widget_control, id, get_value=text
  chars = total( strlen(text) ) + n_elements(text)-1

  ;no text
  if chars eq 0 and offset eq 0 then return, 1b
  
  ;if offset is one greater than known chars (and xy is [-1,-1])
  ;assume a new line (this may be a windows only problem)
  if (chars + 1) eq offset then return, 1b

  return, 0b
  
end

;Abstraction of the insert operation for the calculate panel.
;Allows operation to be called from an insert button event or from a double click on another interface element
pro spd_ui_calculate_insert,listInFocus,insertTree,programTextId,strToAdd,textOffset,statusBar,historyWin

  compile_opt idl2,hidden

     case listinFocus of 
        0: BEGIN ; insert from data tree
              selection = insertTree->getValue()
            
              if is_string(selection[0]) then begin          
                Widget_control,programTextId,set_value=spd_ui_calculate_insert_text(programTextID,'"'+strToAdd+'"',textOffset)
              endif else begin
                statusBar->update,'Please select a variable to insert.'
                historyWin->update,'Calculate: Please select a variable to insert.'
              endelse
        END
        1: BEGIN ; insert from functions list
             Widget_control,programtextId,set_value=spd_ui_calculate_insert_text(programTextId,strToAdd,textOffset)
        END
        2: BEGIN ; insert from operators list
            Widget_control,programtextId,set_value=spd_ui_calculate_insert_text(programTextId,strToAdd,textOffset)
        END
        3: BEGIN ; insert from constants list
            Widget_control,programtextId,set_value=spd_ui_calculate_insert_text(programTextId,strToAdd,textOffset)
        END
      endcase
      
end


PRO spd_ui_calculate_event, event

  Compile_Opt hidden,idl2

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

      ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Calculate'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
      ;kill request block
  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
    Exit_Sequence:
    widget_control,state.programText,get_value=text
    state.settings->setProperty,text=text,name=state.programName,path=state.programPath
    ;Update the draw object to refresh any plots
    state.drawobject->update, state.windowStorage, state.loadeddata
    state.drawobject->draw
    state.historyWin->update,'Calculate Widget Killed'
    state.tlb_statusbar->update, 'Calculate Widget Killed'
    if obj_valid(state.insertTree) then begin
      *state.treeCopyPtr = state.insertTree->getCopy() 
    endif 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy    
    Widget_Control, event.top, /Destroy
    RETURN      
  ENDIF

  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_TAB') THEN BEGIN  
    widget_control,state.programText,get_value=text
    state.settings->setProperty,text=text,name=state.programName,path=state.programPath
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    RETURN 
  ENDIF

  Widget_Control, event.id, Get_UValue=uval

  IF Size(uval, /Type) NE 0 THEN BEGIN

  state.historywin->update,'SPD_UI_CALCULATE: User value: '+uval  ,/dontshow

  overwrite_selections = ''
  overwrite_count = 0
  
  CASE uval OF
    'OK': begin
      ;Update the draw object to refresh any plots
      state.drawobject->update, state.windowStorage, state.loadeddata
      state.drawobject->draw
      state.historyWin->update,'Calculate Widget Closed'
      state.tlb_statusbar->update, 'Calculate Widget Closed'
      widget_control,state.programText,get_value=text
      state.settings->setProperty,text=text,name=state.programName,path=state.programPath
      if obj_valid(state.insertTree) then begin
        *state.treeCopyPtr = state.insertTree->getCopy() 
      endif 
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy    
      Widget_Control, event.top, /Destroy
      RETURN
    end
    'INSERT': begin
      spd_ui_calculate_insert,state.listInFocus,state.insertTree,state.programText,state.strToAdd,state.offset,state.statusBar,state.historyWin
;      case state.listinFocus of 
;        0: BEGIN ; insert from data tree
;              selection = state.insertTree->getValue()
;            
;              if is_string(selection[0]) then begin          
;                Widget_control,state.programtext,set_value=spd_ui_calculate_insert_text(state.programText,'"'+state.strtoadd+'"',state.offset)
;              endif else begin
;                state.statusBar->update,'Please select a variable to insert.'
;                state.historyWin->update,'Calculate: Please select a variable to insert.'
;              endelse
;        END
;        1: BEGIN ; insert from functions list
;             Widget_control,state.programtext,set_value=spd_ui_calculate_insert_text(state.programText,state.strtoadd,state.offset)
;        END
;        2: BEGIN ; insert from operators list
;            Widget_control,state.programtext,set_value=spd_ui_calculate_insert_text(state.programText,state.strtoadd,state.offset)
;        END
;        3: BEGIN ; insert from constants list
;            Widget_control,state.programtext,set_value=spd_ui_calculate_insert_text(state.programText,state.strtoadd,state.offset)
;        END
;      endcase     
    end
    'CLEAR': begin
      widget_control,state.programtext,set_value=' ' 
      state.statusBar->update,'Calculate: Clearing program text.'
      state.historyWin->update,'Calculate: Clearing program text.'
    end 
    'INSERTTREE': begin
        selection = state.insertTree->getValue()
        
        if is_string(selection[0]) then begin
            ; 0 for default/data tree, 1 for functions list, 2 for operators list and 3 for constants
            state.listinFocus = 0
        
            buttonid = widget_info(state.tlb,find_by_uname='INSERT')
            insertvarlbl =  'Insert variable: '+selection[0]
  
            state.selectBar->update,insertvarlbl
            widget_control,buttonid, tooltip=insertvarlbl+' into the program'
            state.strtoadd = selection[0]
            state.statusBar->update,'Variable selected: '+selection+'.'
            state.historyWin->update,'Calculate: Variable selected: '+selection

            ; we should clear the selection on the function and operator lists
            idoperator = widget_info(state.tlb, find_by_uname='operator')
            idfunction = widget_info(state.tlb, find_by_uname='function')
            widget_control, idoperator, set_list_select=-1 ; no selection 
            widget_control, idfunction, set_list_select=-1 ; ^^
        endif else begin
          ; the user clicked in the data tree, but not a valid variable
          if (state.listinFocus eq 0) then begin ; the data tree was in focus last
       
              buttonid = widget_info(state.tlb,find_by_uname='INSERT')
              insertvarlbl =  'Select a variable, function, operator or constant to add to the program'
              state.selectBar->update,insertvarlbl
              widget_control,buttonid, tooltip=insertvarlbl
          endif
        endelse
    end
    'FUNCTION': begin
        ; 0 for default/data tree, 1 for functions list, 2 for operators list and 3 for constants
        state.listinFocus = 1

        buttonid = widget_info(state.tlb,find_by_uname='INSERT')
        insertvarlbl = 'Insert function: '+state.functions[event.index]
        widget_control,buttonid, tooltip=insertvarlbl+' into the program', /sensitive
        state.strtoadd = state.functions[event.index]
        state.selectBar->update,insertvarlbl
        state.statusBar->update,'Function selected: '+state.functions[event.index]+'.'
        state.historyWin->update,'Calculate: Function selected: '+state.functions[event.index]
        ; we should clear the selection on the operator list
        idoperator = widget_info(state.tlb, find_by_uname='operator')
        widget_control, idoperator, set_list_select=-1 ; no selection
        ; clear selection in data tree
        state.insertTree->clearSelected
        
        if event.clicks ge 2 then begin
          spd_ui_calculate_insert,state.listInFocus,state.insertTree,state.programText,state.strToAdd,state.offset,state.statusBar,state.historyWin
        endif
    end
    'OPERATOR': begin
        ; 0 for default/data tree, 1 for functions list, 2 for operators list and 3 for constants
        state.listinFocus = 2

        buttonid = widget_info(state.tlb,find_by_uname='INSERT')
        insertvarlbl = 'Insert operator: '+state.operators[event.index]
        state.selectBar->update,insertvarlbl
        widget_control,buttonid, tooltip=insertvarlbl+' into the program', /sensitive
        state.strtoadd = state.operators[event.index]
        state.statusBar->update,'Operator selected: '+state.operators[event.index]+'.'
        state.historyWin->update,'Calculate: Operator selected: '+state.operators[event.index]
        ; we should clear the selection on the function list
        idfunction = widget_info(state.tlb, find_by_uname='function')
        widget_control, idfunction, set_list_select=-1 ; no selection
        ; clear selection in data tree
        state.insertTree->clearSelected
        if event.clicks ge 2 then begin
          spd_ui_calculate_insert,state.listInFocus,state.insertTree,state.programText,state.strToAdd,state.offset,state.statusBar,state.historyWin
        endif
    end
    'PI':begin
      ;use abstracted function
      spd_ui_calculate_insert,3,state.insertTree,state.programText,'pi',state.offset,state.statusBar,state.historyWin
    end
    'E':begin
      ;use abstracted function
      spd_ui_calculate_insert,3,state.insertTree,state.programText,'e',state.offset,state.statusBar,state.historyWin
    end
    'RE':begin
      ;use abstracted function
      ;use actual value instead of symbolic constant so that users know what value they're getting
      spd_ui_calculate_insert,3,state.insertTree,state.programText,'6371.2',state.offset,state.statusBar,state.historyWin
    end
    'RUN': begin 
      ; initialize a prompt object to pass to calc
      calc_prompt_user = obj_new('spd_ui_prompt_obj', gui_id=state.gui_id, historyWin=state.historyWin, statusBar=state.statusBar)

      Widget_control,state.programtext,get_value=programtext
     
      spd_ui_run_calc,programtext,state.loadedData,state.historyWin,state.statusBar,state.gui_id,error=err,overwrite_selections=overwrite_selections,overwrite_count=overwrite_count,calc_prompt_obj=calc_prompt_user,last_line=last_line
 
      widget_control,state.programLabel,set_value=state.programName
      state.insertTree->update
           
      if keyword_set(err) then begin
      
        state.historyWin->update,'Calculation Failed.  Error Follows:'
        printdat,err,output=o
        for i = 0,n_elements(o)-1 do begin
          state.historyWin->update,o[i]
        endfor
        
        if in_set('VALUE',tag_names(err)) then begin
          state.statusBar->update,'Calculation failed with error: ' + err.name + '  :  ' + err.value[0] + ' on line: ' + strtrim(last_line+1,2) + '. Check history for more detail.'
          for i = 0,n_elements(err.value)-1 do begin
            state.historyWin->update,'VALUE:' + err.value[i]
          endfor
        endif else begin
          state.statusBar->update,'Calculation failed with error: ' + err.name + ' on line: ' + strtrim(last_line+1,2) + '. Check history for more detail.'
        endelse
        
      endif
       
      defsysv, '!mini_globals', exists=mini_globals_exists
      if mini_globals_exists eq 1 then begin
        
        
        if last_line gt -1 then begin        
          ; add the calc operation to the call sequence object
          state.call_sequence->addCalcOp,programText[0:last_line],(*!mini_globals.replay_struct).overwrite_selections
          
        endif
        
        ; need to clear the user's overwrite selections, in case the user decides to do more calc operations in this session
        str_element, *!mini_globals.replay_struct, 'overwrite_selections', '', /add_rep
        ; gotta reset the overwrite count to 0, too.
        (*!mini_globals.replay_struct).overwrite_count = 0
        ;   ok = dialog_message('Calculation complete',/information,/center)
        if ~keyword_set(err) then begin
          state.statusBar->update,'Calculation complete'
          state.historyWin->update,'Calculation complete'
        endif  
      endif else begin
        errmsg = 'Error in spd_ui_calculate, !mini_globals system variable seems to be missing.'
        dprint, dlevel = 0, errmsg
        state.statusBar->update,errmsg
        state.historyWin->update,errmsg
        return
      endelse
      

       
     ; Widget_Control, event.TOP, Set_UValue=state, /No_Copy    
    end
    'TEXT': begin
     
      ;keep track of cursor location
      
      ;widget event (incorrectly ) uses an offset of 2 for cairrage returns in windows 
      if !version.OS_FAMILY eq 'Windows' and event.type eq 0 then begin
        if event.ch eq 10b then event.offset--
      endif
      
      ;get cursor location
      xy = widget_info(state.programtext,text_offset_to_xy=event.offset)
      
  
      ;only store legitimate cursor locations
      if n_elements(xy) eq 2 && $
         xy[0] ge 0 && $
         xy[1] ge 0 then begin
        state.offset = event.offset
      endif else begin
        if spd_ui_calculate_checknl(event.id, event.offset) then begin
          state.offset = event.offset
        endif
      endelse
 
    end
    'OPEN': begin
      
      if state.programPath ne '' && state.programName ne '-scratch-' then begin
        file = dialog_pickfile(path=state.programPath,get_path=path, filter = '*.txt',/must_exist)
      endif else begin
        file = dialog_pickfile(get_path=path, filter = '*.txt',/must_exist)
      endelse
       
      ;if the file is not a regular file and it is not a new file
      if ~file_test(file,/regular) && file_test(file) then begin
         
        result = dialog_message('Illegal file type selected, please try again',/center)
      
      endif else if file ne  '' then begin
       
        sep = path_sep()
        files = strsplit(file,sep,/extract)
         
        state.programPath = path
        state.programName = files[n_elements(files)-1]
        
        catch,err
          
        if err then begin
          catch, /cancel
          ok = error_message('Error reading file: ' + state.programName, /center, $
              title='Error in Calculate')
          state.statusBar->update,'Error reading file: ' + state.programName
          state.historyWin->update,'Error reading file: ' + state.programName
          close,lun
          free_lun,lun
        endif else begin
        
          ln_num = file_lines(state.programPath+state.programName)
        
          if ln_num gt 0 then begin
        
            inlines = strarr(ln_num)
        
            get_lun,lun     
            openr,lun,state.programPath+state.programName
            readf,lun,inlines
            close,lun
            free_lun,lun
            
          endif else begin
            inlines=''
          endelse
          
          state.statusBar->update,'Displaying file: ' + state.programName
          state.historyWin->update,'Displaying file: ' + state.programName
          state.offset = 0
          widget_control,state.programLabel,set_value=state.programName
          widget_control,state.programText,set_value=inlines
      
        endelse
        
        catch,/cancel
      
      endif
    
    end
    'HELP':BEGIN

      gethelppath,path
      xdisplayfile,path+'spd_ui_calculate.txt' , group=state.tlb, /modal, done_button='Done', $
                    title='HELP: Calculate Window'
    END
    
    'SAVE': begin
   
      programpath = state.programPath
      filename = state.programName
      if (state.programPath + state.programName) eq '-scratch-' then begin
      
     ;   ok=dialog_message('Scratch file not a valid save destination, please select a file name.',/center)
      
        state.statusBar->update,'Scratch file not a valid save destination, please select a file name.'
      
        ;file = dialog_pickfile(get_path = path, filter = '*.txt', /write, default_extension='*.txt')
;        file = dialog_pickfile(Title='Save Calculation File:', get_path=path, $
;             Filter='*.txt', /Write, Dialog_Parent=state.tlb, default_extension='txt')
        file = spd_ui_dialog_pickfile_save_wrapper(Title='Save Calculation File:', get_path=path, $
             Filter='*.txt', /Write, Dialog_Parent=state.tlb, default_extension='txt')
                 
        if file eq '' || $
           path eq '' then begin
           
           state.statusBar->update,'File Save Canceled' 
           
           Widget_Control, event.TOP, Set_UValue=state, /No_Copy
           
           return
             
        endif
             
        sep = path_sep()
        files = strsplit(file,sep,/extract) 
        ; lphilpott 8-mar-2012 removing update of file name as it shouldn't happen until after the tests below      
        ;state.programPath = path
        ;state.programName = files[n_elements(files)-1]
        programpath = path
        filename = files[n_elements(files)-1]
        
        ;widget_control,state.programLabel,set_value=state.programName
      
      endif
      
      result = "No"
      
      while result eq "No" && file_test(programpath+filename) do begin
      
        result = dialog_message('File: ' + filename + ' already exists. Are you sure you want to overwrite file?',/question,/center)
      
        if result eq "No" then begin
        
          if programpath ne '' && filename ne '-scratch-' then begin
            ;file = dialog_pickfile(path=state.programPath,get_path=path, filter = '*.txt', default_extension='*.txt', /write)
            file = spd_ui_dialog_pickfile_save_wrapper(path=programpath,get_path=path, filter = '*.txt', default_extension='*.txt', /write)
          endif else begin
            ;file = dialog_pickfile(get_path=path, filter = '*.txt', default_extension='*.txt', /write)
            file = spd_ui_dialog_pickfile_save_wrapper(get_path=path, filter = '*.txt', default_extension='*.txt', /write)
          endelse
          
          if file eq '' || $
            path eq '' then begin
            
            state.statusBar->update,'File Save Canceled' 
             
            Widget_Control, event.TOP, Set_UValue=state, /No_Copy
            return
             
         endif
        
          sep = path_sep()
          files = strsplit(file,sep,/extract)       
          programpath = path
          filename = files[n_elements(files)-1]
          ;state.programPath = path
          ;state.programName = files[n_elements(files)-1]
          ;widget_control,state.programLabel,set_value=state.programName
        endif
      
      endwhile
      state.programPath = programpath
      state.programName = filename
      widget_control,state.programLabel,set_value=state.programName
      widget_control,state.programText,get_value=text
            
      catch,err
      
      get_lun,lun
      openw,lun,state.programPath+state.programName
      
      if err then begin
        catch, /cancel
        ok = error_message('Error writing file: ' + state.programName,/center,title='Error in Calculate')
        state.statusBar->update,'Error writing file:'+state.programName
        state.historyWin->update,'Error writing file:'+state.programName
        close,lun
        free_lun,lun
      endif else begin
        
        for i = 0,n_elements(text)-1 do begin
          printf,lun,text[i]
        endfor
        
        close,lun
        free_lun,lun
        
      endelse
      state.statusBar->update,'File Save Successful'
      catch,/cancel
    
    end
     
    ELSE:
      
    ;add rest of cases here
  ENDCASE
  ENDIF
  
  Widget_Control, event.TOP, Set_UValue=state, /No_Copy
  
  RETURN
END ;--------------------------------------------------------------------------------



Pro spd_ui_calculate, gui_id,loadedData,settings,historywin,treeCopyPtr,call_sequence, $
                      drawObject,windowStorage,scrollbar,tlb_statusBar

  xsize = 360
  ysize = 380

      ;master widget
      
  if ~obj_valid(settings) then begin
    ok = error_message('ERROR: Calculate panel passed illegal settings',/center, $
         title='Error in Calculate')
    return
  endif
  
  err_xxx = 0
  Catch, err_xxx
  IF(err_xxx Ne 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO historywin->update,err_msg[j]
    Print, 'Error in Calculate Panel--See history'
    ok = error_message('An unknown error occured starting Calculate. See console for details.',$
         /noname, /center, title='Error in Calculate')   
    widget_control, tlb,/destroy
    spd_gui_error, gui_id, historywin
    RETURN
  ENDIF
  tlb_statusBar->update,'Calculate Widget opened'   
  tlb = Widget_Base(/col, Title='Calculate', Group_Leader=gui_id, $
    /Modal, /Floating,/tlb_kill_request_events, xpad=3)

  mainBase =  widget_base(tlb,/row,/base_align_left, frame=3)
  buttonBase = widget_base(tlb,/row,/align_center)
  statusBase = widget_base(tlb,/row,/align_center)
  col1base = widget_base(mainBase,/col,/base_align_center)
 ; a sub-column to hold the insert button
  col1abase = widget_base(mainbase,/col)
  col2base = widget_base(mainBase,/col,/base_align_left)
  col3base = widget_base(mainBase,/col,/base_align_left)
  col4base = widget_base(mainBase,/col,/base_align_left)  
  col1row1 = widget_base(col1base,/row, /align_left)
  col1row2 = widget_base(col1base,/row)
  col1row3 = widget_base(col1base,/row,/align_center)
;  col1row4 = widget_base(col1base,/row)
  col1arow1 = widget_base(col1abase,/row,ypad=195)
  col2row1 = widget_base(col2base,/row, /align_left)
  col2row2 = widget_base(col2base,/row)
  col2row3 = widget_base(col2base,/row,/base_align_left)
  col3row1 = widget_base(col3base,/row)
  col3row2 = widget_base(col3base,/row)
  col3row3 = widget_base(col3base,/row)
  col3row4 = widget_base(col3base,/row)
  col3row5 = widget_base(col3base,/row)
  col3row6 = widget_base(col3base,/row,space=4) ;constant buttons
  col4row1 = widget_base(col4base,/row)
  col4row2 = widget_base(col4base,/row)
 
  settings->getProperty, $
       name=programName, $
       path=programPath, $
       text=programText
       

  programLabel = Widget_Label(col1row1, Value='Program: ')
  programLabel = Widget_Text(col1row1, Value = programName,xsize=40)
  ; this will be changed to a string array of tplot_names
;  ;tplot_names, name=insertValue
  ;insertValue=tnames()        ;Does not have limit on length of name like TPLOT_NAMES.

  fieldNames = loadedData->getAll()
  if ~is_string(fieldNames) then begin
    insertbuttonsens = 0
    fieldNames = ['none']
    fieldPtr = ptr_new()
  endif else begin
    insertbuttonsens = 1
    fieldPtr = ptr_new(fieldNames)
  endelse
    
  insertLabel = Widget_Label(col2row1, Value='Insert Variable: ',/Align_Left)
  insertTree = obj_new('spd_ui_widget_tree',col2row2,'INSERTTREE',loadedData,xsize=xsize,ysize=ysize,mode=3,multi=0,leafonly=1,showdatetime=1)
  insertTree->update,from_copy=*treeCopyPtr
 
 ; selectedlistLabel = Widget_Label(col2row3, Value='Select a variable, function, operator or constant to add to the program', uname='selectedlistLabel', /dynamic_resize)
  ; Right arrow button to insert field into program area
 getresourcepath,rpath
 leftArrow = read_bmp(rpath + 'arrow_180_medium.bmp', /rgb)
 spd_ui_match_background, tlb, leftArrow
 insertButton = Widget_Button(col1arow1, Value = leftArrow, /Bitmap,  UValue = 'INSERT', UName='INSERT', $
                          ToolTip = 'Select a variable, function, or operator to add to the program',/align_center, sensitive=insertbuttonsens); sensitivity cannot change without leaving calc panel to load data
 
 ;size calculations for text area 
 xtextsize=floor(xsize/(!D.X_CH_SIZE))
 ytextsize=floor(ysize/(!D.Y_CH_SIZE+4))

;alternate mechanism for avoiding x11 error described below

 if strlen(programText[0]) lt xtextsize+10 then begin
   programText[0] = programText[0]+strjoin(replicate(' ',xtextsize+10-strlen(programText[0])))
 endif

 selectBar = obj_new('spd_ui_message_bar',col2row3,value='Select item from list to add it to program.',xsize=xtextSize-6,ysize=1,/notimestamp)



;  if n_elements(programText) gt 1 && stregex(programText[0],"^[ ]*$",/bool) then begin ; check if first string is all spaces
;    programText = programText[1:n_elements(programText)-1] ;remove sentinel string
;  endif
;
;  sentinel_string=strjoin(replicate(' ',xtextsize+10)) ;used to stop an x-11 warning that occurs when:
;  ;when text widgets are realized
;  ;on linux
;  ;in modal sub-widgets
;  ;with initial text size is smaller than the horizontal width of the text area in characters
;  ;the sentinel string guarantees that the initial text is wider than the horizontal width of the text area in characters
;  ;it must be at the beginning of the text for the warning to be avoided 
;  programText = [sentinel_string,programText]
 
 
  progText = Widget_Text(col1row2, Value=programText, /Editable, XSize=xtextsize,ysize=ytextsize, /Scroll, Uvalue='TEXT',/all_events)

  calc, function_list=functionNames, operator_list=operatorNames 
  functionLabel= Widget_Label(col3row1, Value='Insert Function: ')
  functionList = Widget_List(col3row2, Value=functionNames, xsize=27, ysize=13, uval='FUNCTION', uname='function')

  operatorLabel= Widget_Label(col3row3, Value='Insert Operator: ')
  operatorList = Widget_List(col3row4, Value=operatorNames, xsize=27, ysize=12, uval='OPERATOR', uname='operator')

  constlabel = widget_label(col3row5, value = 'Insert Constant: ')
  pibutton = widget_button(col3row6, value = 'pi', uvalue='PI', tooltip='Insert pi')
    pigeo = widget_info(pibutton,/geo)
    bs = pigeo.scr_xsize * 1.35
    widget_control, pibutton, xsize=bs, ysize=bs
  ebutton = widget_button(col3row6, value = 'e', uvalue='E', tooltip='Insert e', xsize=bs, ysize=bs)
  rebutton = widget_button(col3row6, value = 'Re', uvalue='RE', tooltip='Insert Earth''s radius (km)', xsize=bs, ysize=bs)
    
  statusBar = obj_new('spd_ui_message_bar',statusBase,xsize=143,ysize=1)
  
  newButton = Widget_Button(col1row3, Value=' Open ', UValue = 'OPEN', xsize=70)
  saveButton = Widget_Button(col1row3, Value='  Save  ', UValue = 'SAVE', xsize=70)
  runButton = Widget_Button(col1row3, Value=' Run ', UValue = 'RUN', xsize=70)             
  clearButton = Widget_Button(col1row3, Value=' Clear ', UValue = 'CLEAR', xsize=70)                                                                   
  okButton = Widget_Button(buttonBase, Value=' Done ', UValue='OK', xsize=70)
  helpButton = Widget_Button(buttonBase, Value='Help', XSize=85, UValue='HELP', $
                            tooltip='Open Help Window.')
        

  
  state = {tlb:tlb, $
           gui_id:gui_id, $
           programtext:progtext, $
           programLabel:programLabel,$
           programPath:programPath,$
           programName:programName,$
           insertTree:insertTree,$
           functions:functionNames,$
           operators:operatorNames,$
           loadedData:loadedData, $
           offset:0,$
           historywin:historywin, $
           statusBar:statusBar,$
           selectBar:selectBar,$
           settings:settings, $
           treeCopyPtr:treeCopyPtr, $
           call_sequence:call_sequence, $
           tlb_statusBar:tlb_statusBar, $
           drawObject: drawObject, $
           windowStorage: windowStorage, $
           listinFocus:0, $ ; 0 for default/data tree, 1 for functions list, 2 for operators list and 3 for constants
           strtoadd:'' $ ; keep track of string to add to the program
           }

  Widget_Control, tlb, Set_UValue = state, /No_Copy
  
  centerTLB,tlb
  
  Widget_Control, tlb, /Realize
  
  ;print,tlb
  ;print,col1row2

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  statusBar->update,'Calculate opened.  Displaying File: ' + programName
  historyWin->update,'Calculate opened.  Displaying File: ' + programName
  
  XManager, 'spd_ui_calculate', tlb, /No_Block

; the following call to update/draw was commented out 9/30/2014
; by Eric Grimes; seems unnecessary, and calls to 
; the update method of the draw object are very expensive
  ;Update the draw object to refresh any plots
 ; drawobject->update, windowStorage, loadeddata
 ; drawobject->draw
  ;scrollbar->update
  

  historyWin->update,'Calculate panel closed'

  RETURN
END ;--------------------------------------------------------------------------------
