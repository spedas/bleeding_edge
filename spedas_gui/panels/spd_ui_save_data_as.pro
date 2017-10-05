;
;NAME:
; spd_ui_save_data_as
;
;PURPOSE:
; simple user interface which allows the user to choose file format parameters
; 
;CALLING SEQUENCE:
; spd_ui_save_data_as, gui_id
;
;INPUT:
; gui_id    id of base widget that is calling this program
; 
;OUTPUT:
; 
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_save_data_as.pro $
;
;---------------------------------------------------------------------------------



FUNCTION GetDateFormat, index
formatNames=self->GetDateFormats()
IF index LT 0 OR index GE n_elements(formatNames) THEN RETURN, -1 ELSE RETURN, formatNames[index]
END ;--------------------------------------------------------------------------------



FUNCTION GetDateFormats
formats = [' AMERDATE  1/19/83 11:45:30.234 ',            $
           ' EURODATE   19.1.83 11:45:30.234 ',           $
           ' ABBRAMER  jan 19, 1983 11:45:30.234 ',       $
           ' ABBREURO  19 jan, 1983 11:45:30.234 ',       $
           ' LONGAMER  January 19, 1983 11:45:30.234 ',   $
           ' LONGEURO  19 january, 1983 11:45:30.234 ',   $
           ' NUMERICAL  83.019 11:45:30.234 ',            $
           ' DAYNUMBER  1983 303 11:45:30.234 ',          $
           ' JAPANDATE   83.1.19 11:45:30.234 ',          $
           ' NIPPONDATE  83.19.1 11:45:30.234 ',          $
           ' HIGHLOW  83 01 19 00 11 45:30.234 ',         $
           ' ISEEDATE  83 019 JAN 19 11 45:30.234 ',      $
           ' DFS_STYLE  1989-JAN-19 11:45:30.234 ',       $
           ' ABBRDFS_STYLE  1989/01/19 11:45:30.234 ',    $
           ' PDS_STYLE  1989-01-19T11:45:30.234 ',        $
           ' TPLOTDATE  1989-01-19/11:45:30.234 ',        $
           ' ISO  U19890119T114530.234 ',                 $
           ' PVODATE1  79319 86399.999 ',                 $
           ' PVODATE1  79319 86399999 ',                  $
           ' GLLDATE  1979 319 86399.999 ',               $
           ' CLUSTER  19-01-1989 11:45:30.234 '] 
RETURN, formats
END ;---------------------------------------------------------------------------------           

function GetTimeAnnotationFormats
fmtcount=21
fmts=strarr(fmtcount)
tstamp=1171670475.12345D
anno_type={timeAxis:1,scaling:0,formatid:0}
for i=0,fmtcount-1 do begin
   anno_type.formatid=i
   fmts[i]=formatannotation(0,0,tstamp,data=anno_type)
endfor

;print, ''
return,fmts
end

function GetFpFormats
fmts=['($,D21.3)', '($,D21.6)', '($,E14.6)', '($,E21.13)']
return,fmts
end

function ExampleFpFormats
data_value = !dpi
fmts=GetFpFormats()
example_strings=strarr(n_elements(fmts))
for i=0,n_elements(fmts)-1 do example_strings[i] = strtrim(string(data_value,format=fmts[i]),2)
return,example_strings
end


;Display a new window describing the accepted tokens for custom time formats.
;
pro spd_ui_save_data_as_timehelp, gui_ID

    compile_opt idl2, hidden

  tlb2 = widget_base(title = 'Specify Output Formatting', $
                     /base_align_center, /col, group_leader=gui_id, /modal, tab_mode=1)
  
  mainBase = widget_base(tlb2, /col, xpad=12, ypad=12, space=2)
  
  cr = ssl_newline()
  text = ['The following tokens are recognized; all other characters are printed.', $
          '    ', $
          '    YYYY  - 4 digit year', $
          '    yy    - 2 digit year', $
          '    MM    - 2 digit month', $
          '    DD    - 2 digit date', $
          '    hh    - 2 digit hour', $
          '    mm    - 2 digit minute', $
          '    ss    - 2 digit seconds', $
          '    .fff   - fractional seconds', $
          '    MTH   - 3 character month', $
          '    DOW   - 3 character Day of week', $
          '    DOY   - 3 character Day of Year', $
          '    TDIFF - 5 character, hours different from UTC', $
          '    ', $
          'Example: YYYY-MM-DD/hh:mm:ss.ff DOW TDIFF']
  
  ;cross platform size control
  mx = max(strlen(text), mi)
  dummy = widget_label(mainbase, value=text[mi])
  geo = widget_info(dummy,/geo)
  widget_control, dummy, /destroy
  
  rotlegend = widget_label(mainbase, value=strjoin(text,cr), $
                           xsize = geo.scr_xsize, $
                           ysize = geo.scr_ysize * n_elements(text))
  
  centertlb, tlb2
  
  widget_control, tlb2, /realize 
  
  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb2, xoffset=0, yoffset=0
  endif
  
end


;Update the example text for custom time formats
;
pro spd_ui_save_data_as_tupdate, state

    compile_opt idl2, hidden

  ;clear?
  if ~widget_info(state.timefmt,/sens) then begin
    widget_control, state.timespecsample, set_value = '  '
    return
  endif

  ;get format string
  widget_control, state.timefmt, get_value=tformat
  
  ;local time?
  local = widget_info(state.localbutton, /button_set)
  
  ;update
  val = time_string(1171670475.12345D,tformat=tformat, local=local)
  widget_control, state.timespecsample, set_value = val[0]

end


PRO spd_ui_save_data_as_event, event

  Compile_Opt hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

    ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Save Data As'
    if obj_valid(state.treeObj) then begin
      *state.treeCopyPtr = state.treeObj->getCopy() 
    endif 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
    if obj_valid(state.treeObj) then begin
      *state.treeCopyPtr = state.treeObj->getCopy() 
    endif 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy    
    Widget_Control, event.top, /Destroy
    RETURN      
  ENDIF

  state.historywin->update,'SPD_UI_SAVE_DATA_AS: User value: '+uval ,/dontshow
  
  CASE uval OF
    'CANC': BEGIN
      dprint, dlevel=4, 'Save Data As widget canceled' 
      state.statusbar->update, 'Save Data As widget canceled'
      state.historywin->update, 'Save Data As widget canceled'
      if obj_valid(state.treeObj) then begin
        *state.treeCopyPtr = state.treeObj->getCopy() 
      endif  
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END    
    'SAVE': BEGIN
      xt = Time_String(SysTime(/sec))
      timeString = Strmid(xt, 0, 4)+Strmid(xt, 5, 2)+Strmid(xt, 8, 2)+$
        '_'+Strmid(xt,11,2)+Strmid(xt,14,2)+Strmid(xt,17,2)
      fileString = 'spedas_saved_'+timeString

      tree_id=widget_info(state.tlb,find_by_uname='SDA_DATA_TREE')
      widget_control,tree_id,get_value=treeobj
      selected_fields=treeobj->GetValue()

      ; Do we need to strip out the yaxis components?
      yaxisflag=widget_info(state.yaxisButton,/button_set)

      IF (size(selected_fields,/type) NE 7) THEN BEGIN
         dummy=dialog_message('No variables selected!',/ERROR,/CENTER, title='Error in Save Data As')
      ENDIF ELSE BEGIN
         ; Is a time range specified?
         timeflag=widget_info(state.trButton,/button_set)

         widget_control,state.trControls[0],get_value=st_text
         widget_control,state.trControls[1],get_value=et_text
         ;tr_obj=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
         
         if is_string( spd_ui_timefix(st_text) ) then dummy = state.tr_obj->setstarttime(st_text)
         if is_string( spd_ui_timefix(et_text) ) then dummy = state.tr_obj->setendtime(et_text)
         
         tr_array=dblarr(2)
         tr_array[0] = state.tr_obj->GetStartTime() 
         tr_array[1] = state.tr_obj->GetEndTime() 
         IF ((timeflag EQ 1) AND (tr_array[0] GT tr_array[1])) then begin
            dummy=dialog_message('Start and stop times are out of order',/ERROR,/CENTER,$
                                 title='Error in Save Data As')
         ENDIF ELSE IF widget_info(state.asciiButton,/button_set) THEN BEGIN
            sepstrings=[',',',',' ']
            sepstrings[1]=string([9B]) ; tab character
            
            sepstring_index=widget_info(state.sepcharDroplist,/combobox_gettext)
            widget_control,state.sepcharDroplist, get_value=sepstring_val
            sepstring_index=where(sepstring_val eq sepstring_index)
            sepstr=sepstrings[sepstring_index]
            
            ;get time format from list
            timefmt=widget_info(state.timefmtDroplist,/combobox_gettext)
            widget_control,state.timefmtDroplist, get_value=timefmt_val
            timefmt=where(timefmt_val eq timefmt)
            
            ;get specified time format
            ;*this will over-ride the format given by TIMEFMT above
            if widget_info(state.timefmt, /sens) then begin
              widget_control, state.timefmt, get_value=timeStringFmt
              local_time = widget_info(state.localbutton, /button_set) 
            endif
            
            datafmt=widget_info(state.datafmtDroplist,/combobox_gettext)
            widget_control,state.datafmtDroplist, get_value=datafmt_val
            datafmt=where(datafmt_val eq datafmt)
            
            hdrfmt=widget_info(state.hdrfmtDroplist,/combobox_gettext)
            widget_control,state.hdrfmtDroplist, get_value=hdrfmt_val
            hdrfmt=where(hdrfmt_val eq hdrfmt)
            
            fmt_strings=GetFpFormats()
            widget_control,state.flagText,get_value=flagstring
            if(~Is_String(*state.saveDataDirPtr)) then begin
              CD, current = *state.saveDataDirPtr
            endif
            ;Open the Save Data As file choice window, passing it the directory work was last saved to, and recording the new directory data is saved to.
;            fileName = dialog_pickfile(Title='Save Data As:', $
;               Filter = '*.csv', File = fileName, /Write, Path = *state.saveDataDirPtr, Get_Path = newPath)
            fileName = spd_ui_dialog_pickfile_save_wrapper(Title='Save Data As:', $
               Filter = '*.csv', File = fileName, /Write, Path = *state.saveDataDirPtr, Get_Path = newPath)
           
            IF(Is_String(fileName)) THEN BEGIN 
              ; On Windows, ensure that the filename contains a dot, followed by 
              ; a 3-letter extension at the end of the string.
              ; If some 3-letter extension is not found, append '.csv'.
              ; This needs to happen after you check the fileName otherwise you'll end up saving with a fileName = '.csv' even when the user clicks Cancel
               if strlowcase(!version.os_family) eq 'windows' && $
                ~stregex(fileName,'\....$',/boolean,/fold_case) then begin
                state.historywin->update,'Windows file: ' + fileName + ' has no extension, automatically adding .csv extension'
                state.statusbar->update,'Windows file: ' + fileName + ' has no extension, automatically adding .csv extension'
                filename = fileName+'.csv'
               endif
               widget_control,/hourglass
               *state.saveDataDirPtr = newPath ;set the path to where it saved last
               saveas_ascii,loadedData=state.loadedData,field_names=selected_fields, $
                      timefmt=timefmt, timeStringFmt=timeStringFmt, local_time=local_time, $
                      fmt_strings=fmt_strings,fmt_code=datafmt,sepstring=sepstr,$
                      filename=fileName,flagstring=flagstring[0],$
                      statusmsg=statusmsg,statuscode=statuscode,hdrfmt=hdrfmt,$
                      timeflag=timeflag,timerange=tr_array,yaxisflag=yaxisflag
               IF (statuscode LT 0) THEN BEGIN
                    dummy=dialog_message(statusmsg,/ERROR,/CENTER, title='Error in Save Data As') 
                    state.historywin->update,statusmsg
                    state.statusbar->update,statusmsg
               ENDIF ELSE BEGIN
                    dummy=dialog_message(statusmsg,/INFO,/CENTER, title='Save Data As')
                    state.historywin->update,statusmsg
                    state.statusbar->update,statusmsg
                    if obj_valid(state.treeObj) then begin
                      *state.treeCopyPtr = state.treeObj->getCopy() 
                    endif  
                    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
                    Widget_Control, event.top, /Destroy
                    RETURN
               ENDELSE
            ENDIF
         ENDIF ELSE IF widget_info(state.flatButton,/button_set) THEN BEGIN
            ; Flat file
            ;if widget_info(state.topButton,/button_set) then begin
                 ; Upper
                 fileName = dialog_pickfile(Title='Save Data As:', $
                    Filter = '*.dat', File = fileName, /Write, Path = *state.saveDataDirPtr, Get_Path = newPath)
                 IF(Is_String(fileName)) THEN BEGIN 
                    widget_control,/hourglass
                    *state.saveDataDirPtr = newPath ;set the path to look at the last path used
                   loadedData=state.loadedData
                    saveas_upper_flatfile,loadedData=loadedData,$
                        field_names=selected_fields,$
                        filename=fileName, $
                        statusmsg=statusmsg,$
                        statuscode=statuscode, $
                        timeflag=timeflag, timerange=tr_array
                    IF (statuscode LT 0) THEN BEGIN
                       dummy=dialog_message(statusmsg,/ERROR,/CENTER, title='Error in Save Data As') 
                       state.historywin->update,statusmsg
                       state.statusbar->update,statusmsg
                    ENDIF ELSE BEGIN
                       dummy=dialog_message(statusmsg,/INFO,/CENTER, title='Save Data As')
                       state.historywin->update,statusmsg
                       state.statusbar->update,statusmsg
                       if obj_valid(state.treeObj) then begin
                        *state.treeCopyPtr = state.treeObj->getCopy() 
                       endif  
                       Widget_Control, event.TOP, Set_UValue=state, /No_Copy
                       Widget_Control, event.top, /Destroy
                       RETURN
                    ENDELSE
                 ENDIF
            ;endif else if widget_info(state.bottomButton,/button_set) then begin
            ;     ; Lower
            ;    dummy=dialog_message('Save as lower flatfile not yet implemented.',/ERROR,/CENTER,$
            ;                         title='Error in Save Data As') 
            ;ENDIF ELSE BEGIN
            ;  dummy=dialog_message('Please select a flatfile format (Upper or Lower)',/ERROR,/CENTER,$
            ;                       title='Error in Save Data As') 
            ;ENDELSE
         ENDIF ELSE BEGIN
             dummy=dialog_message('Please select an output file format (flatfile or ASCII)',/ERROR,/CENTER,$
                                   title='Error in Save Data As') 
         ENDELSE
      ENDELSE
     END
     'DATA_TREE': BEGIN
        widget_control,event.id,get_value=val
        varnames=val->GetValue()
        if (size(varnames,/type) EQ 7) then begin
           ; tree widget returned an array of strings -- if it returns
           ; 0L, it means nothing is selected yet.
           ; Update the start/stop time widgets based on the first variable
           ; returned
           objs = (state.loadedData)->GetObjects(name=varnames[0])
           objs[0]->GetProperty,timerange=timerange
           st_time = timerange->GetStartTime() 
           et_time = timerange->GetEndTime() 
           dummy = state.tr_obj->setstarttime(st_time)
           dummy = state.tr_obj->setendtime(et_time)
           st_time = time_string(st_time)
           et_time = time_string(et_time)
           widget_control,state.trControls[0],set_value=st_time
           widget_control,state.trControls[1],set_value=et_time
        endif
      END
     ;'TOP': state.lastFlatButton=0
     ;'BOTTOM':  state.lastFlatButton=1
     'FLAT': BEGIN
       ;FOR i = 0, N_Elements(state.flatFileButtons)-1 DO Widget_Control, state.flatFileButtons[i], Sensitive=1
;       FOR i = 0, N_Elements(state.asciiButtons)-1 DO Widget_Control, state.asciiButtons[i], Sensitive=0      
       ;Widget_Control, state.flatFileButtons[state.lastFlatButton], Set_Button=1
       widget_control, state.asciiBase, sens=0
       Widget_Control, state.flatButton, Set_Button=1
       Widget_Control, state.asciiButton, Set_Button=0
     END
     'ASCII': BEGIN
;       FOR i = 0, N_Elements(state.asciiButtons)-1 DO Widget_Control, state.asciiButtons[i], Sensitive=1      
       ;FOR i = 0, N_Elements(state.flatFileButtons)-1 DO Widget_Control, state.flatFileButtons[i], Sensitive=0
;       FOR i = 0, N_Elements(state.tecplotButtons)-1 DO Widget_Control, state.tecplotButtons[i], Sensitive=0
       widget_control, state.asciiBase, sens=1
       Widget_Control, state.asciiButton, Set_Button=1
       Widget_Control, state.flatButton, Set_Button=0
     END           
    'TRANGE': begin
       if (widget_info(state.trButton,/button_set)) then begin
          for i=0,n_elements(state.trControls)-1 do begin
             widget_control,state.trControls[i],sensitive=1
          endfor
       endif else begin
          for i=0,n_elements(state.trControls)-1 do begin
             widget_control,state.trControls[i],sensitive=0
          endfor
       endelse
     end
    'STARTCAL': begin
      widget_control, state.trcontrols[0], get_value= val
      start=spd_ui_timefix(val)
      state.tr_obj->getproperty, starttime = start_time       
      if ~is_string(start) then start_time->set_property, tstring=start
      spd_ui_calendar, 'Choose date/time: ', start_time, state.gui_id
      start_time->getproperty, tstring=start
      widget_control, state.trcontrols[0], set_value=start
     end
    'STOPCAL': begin
      widget_control, state.trcontrols[1], get_value= val
      endt=spd_ui_timefix(val)
      state.tr_obj->getproperty, endtime = end_time       
      if ~is_string(endt) then end_time->set_property, tstring=endt
      spd_ui_calendar, 'Choose date/time: ', end_time, state.gui_id
      end_time->getproperty, tstring=endt
      widget_control, state.trcontrols[1], set_value=endt
     end
    'SPECTIMEHELP': begin
      spd_ui_save_data_as_timehelp, state.tlb
    end
    'TIMEFMTBUTTON': begin
      widget_control, state.timefmt, sens = event.select
      widget_control, state.localbutton, sens = event.select
      widget_control, state.timefmtDroplist, sens = ~event.select
      spd_ui_save_data_as_tupdate, state
    end
    'TIMEFMT': begin
      spd_ui_save_data_as_tupdate, state
    end
    'LOCAL': begin
      spd_ui_save_data_as_tupdate, state
    end
    'TSTART': begin
     end
    'TEND': begin
     end
    'TIMEFMTDROPLIST': BEGIN
     END
    'DATAFMT': BEGIN
     END
    'HDRFMT': BEGIN
     END
     'SEPCHAR': BEGIN
     END
     'IFLAG': BEGIN
     END
     'UPDATE': BEGIN
     END     
     'YAXIS': BEGIN
     END
    ELSE: dprint,  'Not yet implemented'
  ENDCase
  
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
END ;--------------------------------------------------------------------------------



PRO spd_ui_save_data_as, gui_id, loadedData, historywin,treeCopyPtr, saveDataDirPtr, statusbar

  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO historywin->update,err_msg[j]
    ok = error_message('Error in save data as',title='Save data as error',/center)
    dprint, dlevel=2, 'Error in save_data_as -- See history'
    statusbar->update,'Error in save_data_as -- See history'
    widget_control, tlb,/destroy
    spd_gui_error,gui_id,historywin
    RETURN
  ENDIF

    ;top level and main base widgets 
    
  tlb = Widget_Base(/Col, Title='Save Data As', Group_Leader=gui_id, $
                    /Modal, /Floating,/tlb_kill_request_events, tab_mode=1)

  topBase = Widget_Base(tlb, /Row)
  treeBase = Widget_Base(topBase, /Col, YPad=7)
  spaceBase = Widget_Base(topBase, /Col)
  selectionBase = Widget_Base(topBase, /Col)
  fFrameBase = Widget_Base(selectionBase, /Col)

  trlabelBase = Widget_Base(fFrameBase, /Col)
  trvalsBase = Widget_Base(fFrameBase, /Col, Frame=3)
  tstartBase = Widget_Base(trvalsBase, /Row)
  tendBase = Widget_Base(trvalsBase, /Row)

  flabelBase = Widget_Base(fFrameBase, /Col)
  ;fbuttonBase = Widget_Base(fFrameBase, /Row, /Exclusive, Frame=3)

  tFrameBase = Widget_Base(selectionBase, /Col)
  aFrameBase = Widget_Base(selectionBase, /Col)
  alabelBase = Widget_Base(aFrameBase, /Col)
  abuttonBase = Widget_Base(aFrameBase, /Col, Frame=3)
  separatorBase = Widget_Base(abuttonBase, /Row)
    slBase = Widget_Base(separatorBase, /Row)
    sbBase = Widget_Base(separatorBase, /Row, /Exclusive)
  timeBase = Widget_Base(abuttonBase, /col)
  datafmtBase = Widget_Base(abuttonBase, /Row)
  hdrfmtBase = Widget_Base(abuttonBase, /Row)
  sepcharBase = Widget_Base(abuttonBase, /Row)
  flagBase = Widget_Base(abuttonBase, /Row)
  yaxisBase = Widget_Base(abuttonBase, /col,/NonExclusive)
  updateBase = Widget_Base(selectionBase, /Row, /NonExclusive)
  buttonBase = Widget_Base(tlb, /Row, /Align_Center, YPad=7)
  
      ;all the widgets 
  treeLabel = Widget_Label(treeBase,Value='Loaded Data:', /Align_Left)
  treeObj=obj_new('spd_ui_widget_tree',treeBase,'DATA_TREE',loadedData,uname='SDA_DATA_TREE',mode=1,multi=1,xsize=300,ysize=500,/showdatetime)
  treeObj->update,from_copy=*treeCopyPtr
  
  spaceLabel = Widget_Label(spaceBase, Value=' ')

  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, tlb, cal  

  st_text = '2007-03-23 00:00:00.0'
  et_text = '2007-03-24 00:00:00.0'
  tr_obj=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)

  st_text->getproperty, tstring=st_text
  et_text->getproperty, tstring=et_text

  trBase = Widget_Base(trlabelBase,/nonexclusive)
  trButton = Widget_Button(trBase,Value='Restrict Time Range:',/Align_Left,UValue='TRANGE')
  tstartLabel = Widget_Label(tstartBase,Value='Start Time: ',Sensitive=0)
  geo_struct = widget_info(tstartlabel,/geometry)
  labelXSize = geo_struct.scr_xsize
  tstartText = Widget_Text(tstartBase,Value=st_text,/Editable, /Align_Left,UValue='TSTART',Sensitive=0)
  startcal = widget_button(tstartbase, val = cal, /bitmap, uval='STARTCAL', uname='startcal', $
                           tooltip='Choose date/time from calendar.', sensitive=0)
  tendLabel = Widget_Label(tendBase,Value='  End Time: ',Sensitive=0, xsize=labelXSize)
  tendText = Widget_Text(tendBase,Value=et_text,/Editable, /Align_Left,UValue='TEND',Sensitive=0)
  stopcal = widget_button(tendbase, val = cal, /bitmap,  uval='STOPCAL', uname='stopcal', $
                          tooltip='Choose date/time from calendar.', sensitive=0)
  trControls=[tstartText,tendText,tstartLabel,tendLabel, startcal, stopcal]

  flatBase = Widget_Base(flabelBase, /nonexclusive)
  flatButton = Widget_Button(flatBase, Value='Save as UCLA (Upper) Flatfile (*.dat, *.hed, *.abs, and *.des files)', /Align_Left, UValue='FLAT')
  ;topButton = Widget_Button(fbuttonBase, Value='Top (*.des)', UValue='TOP')
  ;bottomButton = Widget_Button(fbuttonBase, Value='Bottom (*.ffh)', UValue='BOTTOM')
  Widget_Control,  flatButton, Set_Button=0 
  ;Widget_Control,  topButton, Set_Button=1
  ;Widget_Control,  bottomButton, Set_Button=0

  asciiBase = Widget_Base(alabelBase, /nonexclusive)
  asciiButton = Widget_Button(asciiBase, Value='Save as ASCII data file', /Align_Left, UValue='ASCII')
  datafmtLabel = Widget_Label(datafmtBase, Value='Floating Point Format: ')
  geo_struct = widget_info(datafmtLabel,/geometry)  
  labelXSize = geo_struct.scr_xsize
 
  ;time format widgets for ASCII
  timeChooseBase = widget_base(timebase, /row, xpad=0)
    timeLabel = Widget_Label(timeChooseBase, Value='Time Format: ', xsize=labelXSize)
    formatNames = GetTimeAnnotationFormats()
    timefmtDroplist = Widget_combobox(timeChooseBase, XSize=235, UValue='TIMEFMTDROPLIST', Value=formatNames) 
    widget_control, timefmtDroplist, set_combobox_select=3
  timeSpecBase = widget_base(timebase, /col, xpad=0)
    specLabelBase = widget_base(timeSpecBase, /row, xpad=0)
      specButtBase = widget_base(specLabelBase, xpad=0, ypad=0, /nonexclusive, xsize=labelXsize, /base_align_right)
        specFormatButton = widget_button(specButtBase, value='Specify: ', uval='TIMEFMTBUTTON', $
                                         tooltip='Specify custom format for time output')
      specFormatBox = widget_text(specLabelBase, /edit, value='YYYY-MM-DD/hh:mm:ss', $
                                  /all_events, xsize=30, uval='TIMEFMT', sens=0)
      specHelpButton = widget_button(specLabelBase, value='?', uval='SPECTIMEHELP')
    specExampleBase = widget_base(timeSpecBase, /row, xpad=0)
      specSampleLabel = widget_label(specExampleBase, value='  ', xsize=labelXSize)
      geo_struct = widget_info(specFormatBox,/geometry)  
      specSample = widget_label(specExampleBase, value='  ', xsize=geo_struct.scr_xsize)

  
;  datafmtLabel = Widget_Label(datafmtBase, Value='Floating Point Format: ')
  datafmtNames = ExampleFpFormats()
  datafmtDroplist = Widget_combobox(datafmtBase, XSize=235, UValue='DATAFMT', Value=datafmtNames) 
  hdrfmtLabel = Widget_Label(hdrfmtBase, Value='Header Style: ',xsize=labelXSize)
  hdrfmtNames = ['None','Field Names Only','Tecplot']
  hdrfmtDroplist = Widget_combobox(hdrfmtBase, XSize=235, UValue='HDRFMT', Value=hdrfmtNames) 
  sepcharLabel = Widget_Label(sepcharBase, Value='Item Separator: ',xsize=labelXSize)
  sepcharNames = ['Comma','Tab','Space']
  sepcharDroplist = Widget_combobox(sepcharBase, XSize=235, UValue='SEPCHAR', Value=sepcharNames) 
  flagLabel = Widget_Label(flagBase, Value='Indicate flags with: ',xsize=labelXSize)
  flagText = Widget_Text(flagBase, Value='NaN', XSize=33, /Editable, UValue='IFLAG') 
  yaxisButton = Widget_Button(yaxisBase, Value='Ignore yaxis components',UValue='YAXIS')
  localButton = widget_button(yaxisBase, value='Use Local Time', sens=0, uval='LOCAL', $
                         tooltip='Time will be output in the local time zone')
  Widget_Control,  yaxisButton, Set_Button=1
  ;updateButton = Widget_Button(updateBase, Value='Update document with location of data', $
  ;  UValue='UPDATE') 
  saveButton = Widget_Button(buttonBase, Value='  Save    ', UValue='SAVE', XSize=80)
  cancelButton = Widget_Button(buttonBase, Value='  Cancel  ', UValue='CANC', XSize=80)

  ;this is unnecessary 
  ; create button arrays for various file type selections
  ; these will be grayed out once a selection has been made    
  ;flatFileButtons = [topButton, bottomButton, updateButton]
;  asciiButtons = [timeLabel, datafmtLabel, timefmtDroplist, datafmtDroplist, $
;                  flagLabel, flagText,sepcharLabel,sepcharDroplist, $
;                  hdrfmtLabel, hdrfmtDroplist,yaxisButton, timeSpecBase]

  ; at initialization, gray out controls until a file format is selected
  ;FOR i = 0, N_Elements(flatfileButtons)-1 DO Widget_Control, flatFileButtons[i], Sensitive=0
;  FOR i = 0, N_Elements(asciiButtons)-1 DO Widget_Control, asciiButtons[i], Sensitive=0
  widget_control, abuttonbase, sens=0  



  ;state = {tlb:tlb, gui_id:gui_id, flatFileButtons:FlatFileButtons, $
  ;         asciiButtons:asciiButtons, $
  ;         trButton:trButton, trControls:trControls, tr_obj:tr_obj, $
  ;         flatButton:flatButton, topButton:topButton, bottomButton:bottomButton, $
  ;         asciiButton:asciiButton, $
  ;         timefmtDroplist:timefmtDroplist,datafmtDroplist:datafmtDroplist, $
  ;         sepcharDroplist:sepcharDroplist, yaxisButton:yaxisButton, $
  ;         hdrfmtDroplist:hdrfmtDroplist, flagText:flagText,$
  ;         lastFlatButton:0, $
  ;         loadedData:loadedData, historywin:historywin,$
  ;         treeCopyPtr:treeCopyPtr,treeObj:treeObj}
  state = {tlb:tlb, gui_id:gui_id, $
           asciiBase:abuttonbase, $
           trButton:trButton, trControls:trControls, tr_obj:tr_obj, $
           flatButton:flatButton, asciiButton:asciiButton, localbutton:localbutton, $
           timefmtDroplist:timefmtDroplist, timefmt:specFormatBox, $
           datafmtDroplist:datafmtDroplist, timeSpecSample:specSample, $
           sepcharDroplist:sepcharDroplist, yaxisButton:yaxisButton, $
           hdrfmtDroplist:hdrfmtDroplist, flagText:flagText,$
           loadedData:loadedData, historywin:historywin, statusbar:statusbar,$
           treeCopyPtr:treeCopyPtr,treeObj:treeObj,$
           saveDataDirPtr:saveDataDirPtr}
  Centertlb, tlb         
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize
  
  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
 
  XManager, 'spd_ui_save_data_as', tlb, /No_Block

  RETURN
END ;--------------------------------------------------------------------------------
