;+
; NAME:
; spd_ui_spdfcdawebchooser
;
; PURPOSE:
; This procedure opens a GUI that can download CDF files from CDAWEB.
;
; CATEGORY:
; Widgets
;
; CALLING SEQUENCE:
; spd_ui_spdfcdawebchooser
;
; INPUTS:
;
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
; GROUP_LEADER: This is the id of the calling widget, required to show as a modal window.
; HISTORYWIN: The history window of SPEDAS. Required for the calendar widget.
; STATUSBAR: The main bar of the main window of SPEDAS. Required for the calendar widget.
;
; OUTPUTS:
; This function returns a CDF file. Also, it stores the values into variable spd_spdfdata.
; If there is no data read, it shows a message to the user.
;
; EXAMPLE:
;  spd_ui_spdfcdawebchooser, historyWin=info.historyWin, statusBar=info.statusBar, GROUP_LEADER = info.master
;
; NOTES:;
; This window was adapted from the file spdfCdawebChooser.pro of spdfcdas
; http://cdaweb.gsfc.nasa.gov/WebServices
;
; MODIFICATION HISTORY:
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-01-30 14:22:19 -0800 (Sat, 30 Jan 2016) $
;$LastChangedRevision: 19861 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_spdfcdawebchooser.pro $
;-


;+
; Find and replace for strings.
;
; @param inString {in} {type=string}
;            input string.
; @param findString {in} {type=string}
;            find string. It can be a regular expression.
; @param replaceString {in} {type=string}
;            replace string.
; @returns new string
;            inString where findString is replaced by replaceString.
;-
function spd_string_replacen, inString, findString, replaceString
  if STRLEN(inString) le 0 then return, inString
  if STRLEN(inString) lt STRLEN(findString) then return, inString
  return, StrJoin( StrSplit(inString, findString, /Regex, /Extract, /Preserve_Null), replaceString)
end

;+
; Deletes DEPEND_TIME attributes for SPEDAS and ARTEMIS CDF files.
; The problem is that CDA web creates CDF files with twice as many time points
; but the EPOCH time points are correct. So we delete the DEPEND_TIME which points
; to Unix times and then cdf2tplot will use EPOCH times.
; This problem exists only for spedas and artemis.
;
; @param cdffile {in} {type=string}
;            CDF filename (full path)
; @returns new string
;            The same file without DEPEND_TIME attributes
;-
pro fix_spedas_depend_time, cdffile
  cdfid = CDF_OPEN(cdffile)
  CDF_ATTGET, cdfid, 'Project', 0, project
  if (STRMATCH(project, 'themis', /FOLD_CASE) EQ 1) or (STRMATCH(project, 'artemis', /FOLD_CASE) EQ 1) then begin
    CDF_ATTDELETE, cdfid, 'DEPEND_TIME'
  endif
  CDF_CLOSE, cdfid
end

;+
; Gives a time string in the format used by spdf.
;
; @param time {in} {type=string}
;            time in the SPEDAS format 2007-03-23/00:00:00.
; @returns new string
;            time in the SPDF format 2007/03/23 00:00:00.
;-
function spd_tranform_time_to_spdf, time

  time = spd_string_replacen(time, "/", " ")
  time = spd_string_replacen(time, "-", "/")
  
  return, time
end

;+
; Responds to an event that initiates a termination of this program.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spd_spdfExit, event

  ;  widget_control, event.top, get_uvalue=state
  
  widget_control, event.top, /destroy
end

;+
; Selects a dataview.
;
; @param tlb {in} {type=int}
;            widget id of top level base.
; @param dvList {in} {type=int}
;            widget id of dataview list widget.
; @param dvIndex {in} {type=int}
;            index of dataview to select
;-
pro spd_spdfSelectDataview, $
  tlb, dvList, dvIndex
  widget_control, dvList, set_combobox_select=dvIndex
  widget_control, dvList, $
    send_event={id:dvList, top:tlb, handler:dvList, index:dvIndex}
end


;+
; Executes the the operation to retrieve the specified data into this
; IDL environment.
;
; @param state {in} {type=struct}
;            widget program's state.
; @param timeInterval {in} {type=SpdfTimeInterval}
;            time range of data to get.
; @param datasetId {in} {type=string}
;            dataset identifier.
; @param varNames {in} {type=strarr}
;            names of variables containing the desired data.
;-
pro spd_spdfGetCdawebDataExec, $
  event, state, timeInterval, datasetId, varNames
  
  tlb=state.tlb
  
  localDirText = widget_info(tlb, find_by_uname='LOCALDIR')
  widget_control, localDirText, get_value=cdfFolder
  localdir = STRTRIM(cdfFolder[0],2)
  if STRMID(localdir, 0, 1, /REVERSE_OFFSET) ne path_sep() then localdir = localdir + path_sep()
  ; check that the directory exists; if not, create it.
  if ~file_test(localdir, /directory, /write) then begin
    file_mkdir2, localdir, /writeable
  endif
  ; now check that the directory is writable
  if ~FILE_SEARCH(localdir, /TEST_WRITE) then begin
    reply = dialog_message( $
      'Local CDF directory must be writable. ' +  string(10B) + string(10B) + localdir , $
      title='Local CDF directory', /center, /error)
    return
  endif else begin
    spd_spdf_savecdfdir, event
  endelse
  
  widget_control, state.dataVarName, get_value=dataVarName  
  if dataVarName eq '' then begin
    reply = dialog_message( $
      'A name for the result variable must be set.', $
      title='Missing Variable Name', /center, /error)
    return
  endif
  
  widget_control, /hourglass
  
  dataResults = $
    state.cdas->getCdfData($
    timeInterval, datasetId, varNames, $
    dataview=*state.selectedDataview, $
    authenticator=state.authenticator, $
    httpErrorReporter=state.errorDialog)
    
  fileDescriptions = dataResults->getFileDescriptions()
  
  if obj_valid(fileDescriptions) and $
    n_elements(fileDescriptions) gt 0 then begin
    
    localCdfNames = strarr(n_elements(fileDescriptions))
    
    for i = 0, n_elements(fileDescriptions) - 1 do begin
      urlname = fileDescriptions[i]->getName()
      urlComponents = parse_url(urlname)
      urlfilename = file_basename(urlComponents.path)
      filename = localdir + urlfilename
      localCdfNames[i] = fileDescriptions[i]->getFile(filename=filename[0])
    endfor
    
    ; make a copy of localCdfNames that read_mycdf can alter
    localCdfNames2 = localCdfNames
    cdfData = spd_cdawlib_read_mycdf(varNames, localCdfNames2)
    
    (scope_varFetch(dataVarName, /enter, level=1)) = $
      spd_cdawlib_hsave_struct(cdfData, /nosave)
      
    resultMsgLines = n_elements(varNames) + 1
    
    if *state.saveData then begin
    
      resultMsgLines += n_elements(localCdfNames) + 1
    endif
    
    resultMsg = strarr(resultMsgLines)
    resultMsg[0] = $
      'The selected data is now available in'
      
    for i = 0, n_elements(varNames) - 1 do begin
    
      resultMsg[1 + i] = $
        '    ' + dataVarName + '.' + varNames[i] + '.dat'
    endfor
    
    if n_elements(localCdfNames) gt 0 then state.localCdfNames = localCdfNames
    if *state.saveData then begin
    
      resultMsgIndex = n_elements(varNames)
      
      resultMsg[resultMsgIndex++] = $
        'Also, the downloaded data has been saved in'
        
      for i = 0, n_elements(localCdfNames) - 1 do begin
      
        resultMsg[resultMsgIndex + i] = $
          '    ' + localCdfNames[i]
      endfor
    endif else begin
    
      ;file_delete, localCdfNames
    endelse
  endif else begin
  
    resultMsg = 'No data found with the specified parameters.'
  endelse
  
  obj_destroy, fileDescriptions
  obj_destroy, dataResults
  
  reply = dialog_message(resultMsg, $
    title='Get Data Operation', /center, /information)
end


;+
; Gets the dataset and variable selection values.
;
; @param datasetTree {in} {type=int}
;            id of dataset tree widget.
; @param selectedDatasetId {out} {type=string}
;            id of selected dataset.
; @param selectedVarNames {out} {type=strarr}
;            names of selected variables.
; @returns 1 if a valid selections was made.  0 if the selection
;              was invalid.
;-
function spd_spdfGetDatasetSelection, $
  datasetTree, selectedDatasetId, selectedVarNames
  
  selectedDatasets = widget_info(datasetTree, /tree_select)
  
  if selectedDatasets[0] eq -1 then begin
  
    reply = dialog_message( $
      'Please choose one or more Variables within a single Dataset', $
      title='Dataset Variable Selection', /center, /error)
    return, 0
  endif
  
  datasetsSelected = 0
  varsSelected = 0
  selectedDatasetId = ''
  
  for i = 0, n_elements(selectedDatasets) - 1 do begin
  
    if ~widget_info(selectedDatasets[i], /tree_folder) then begin
    
      widget_control, selectedDatasets[i], $
        get_uvalue=selectedDataset
        
      if selectedDataset.datasetId ne selectedDatasetId then begin
      
        datasetsSelected++
        selectedDatasetId = selectedDataset.datasetId
        varsSelected = 0
      endif
      
      varsSelected++
    endif
  endfor
  
  if datasetsSelected eq 1 then begin
  
    selectedVarNames = strarr(varsSelected)
    
    for i = 0, n_elements(selectedDatasets) - 1 do begin
    
      if ~widget_info(selectedDatasets[i], /tree_folder) then begin
      
        widget_control, selectedDatasets[i], $
          get_uvalue=selectedDataset
          
        selectedVarNames[i] = selectedDataset.varName
      endif
    endfor
  endif else begin
  
    reply = dialog_message( $
      'Please choose one or more Variables within a single Dataset', $
      title='Dataset Variable Selection', /center, /error)
    return, 0
  endelse
  
  return, 1
end

;+
; Determines if the given string is a valid date/time value.
;
; @param value {in} {type=string}
;            value to be tested.
; @returns true if the given string is a valid date/time value.
;             Otherwise false.
;-
function spd_spdfIsValidDate, $
  value
  
  return, stregex(value, $
    '[12][0-9]{3}[-/][01][0-9][-/][0-3][0-9]([ T][0-2][0-9]:[0-5][0-9]:[0-5][0-9])?', $
    /boolean)
end

;+
; Gets the specified time interval.
;
; @param startTimeWidget {in} {type=int}
;            id of start time widget.
; @param stopTimeWidget {in} {type=int}
;            id of stop time widget.
; @returns specifed time interval or null object reference if an
;              invalid value was specified.
;-
function spd_spdfGetSpecifiedTime, $
  startTimeWidget, stopTimeWidget
  
  widget_control, startTimeWidget, get_value=startTime
  
  if ~spd_spdfIsValidDate(startTime) then begin
  
    reply = dialog_message( $
      ['The Start Time must be set to a valid value', $
      'YYYY/MM/DD[ HH:MM:SS]'], $
      title='Invalid Date', /center, /error)
    return, obj_new()
  endif
  
  widget_control, stopTimeWidget, get_value=stopTime
  
  if ~spd_spdfIsValidDate(stopTime) then begin
  
    reply = dialog_message( $
      ['The Stop Time must be set to a valid value', $
      'YYYY/MM/DD[ HH:MM:SS]'], $
      title='Invalid Date', /center, /error)
    return, obj_new()
  endif
  
  timeInterval = obj_new('SpdfTimeInterval', startTime, stopTime)
  
  if ~timeInterval->isStartLessThanStop() then begin
  
    reply = dialog_message( $
      'Start Time must be less than Stop Time value', $
      title='Invalid Time Interval', /center, /error)
      
    obj_destroy, timeInterval
    
    return, obj_new()
  endif
  
  return, timeInterval
end

;+
; Responds to an event requesting the retrieval of the data
; specified by the users previous selections.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spd_spdfGetCdawebData, $
  event
  
  widget_control, event.top, get_uvalue=state
  
  ; check the CDF library version, gracefully error 
  ; when the user is using an outdated version
  cdf_lib_info, release=release, version=version, increment=increment
  cdf_version = float(strcompress(string(version)+'.'+string(release), /rem))
  if cdf_version lt 3.3 then begin
      current_cdf_version = strcompress(string(version)+'.'+string(release)+'.'+string(increment), /rem)
      err_message = [ $
          'The installed version of the CDF library is out of date', $
          'Current CDF version: ' + current_cdf_version, $
          'You must install the IDL CDF patch to continue.', $
          'See: http://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html']
      reply = dialog_message(err_message, $
          title='Can''t continue without patching the CDF library', /center, /information)
      
      ; send the error to the status bar, history window and console
      for linenum = 0, n_elements(err_message)-1 do begin
          state.historyWin->update, err_message[linenum]
          state.statusBar->update, err_message[linenum]
          dprint, dlevel = 0, err_message[linenum]
      endfor
      return
  endif
  
  if spd_spdfGetDatasetSelection(state.datasetTree, $
    selectedDatasetId, selectedVarNames) ne 1 then return
    
  timeInterval = spd_spdfGetSpecifiedTime(state.startTime, state.stopTime)
  
  if ~obj_valid(timeInterval) then return
  
  ;spd_spdfGetCdawebExec mutates selectedVarNames, this stores pristine copy for callsequence add, if getdataexec call succeeds.
  saved_varnames = selectedVarNames
  
  spd_spdfGetCdawebDataExec, $
    event, state, timeInterval, selectedDatasetId, selectedVarNames
    
  state.callsequence->addspdfcall,[timeInterval->getCdawebStart(),timeInterval->getCdawebStop()],selectedDatasetId,saved_varnames,*state.selectedDataview
    
  widget_control, event.top, set_uvalue=state
  obj_destroy, timeInterval
end



;+
; Gets all dataview descriptions.
;
; @private
;
; @param cdas {in} {required} {type=SpdfCdas}
;            the Coordinated Data Analysis System.
; @returns objarr containing SpdfDataviewDescription objects for all
;              cdaweb dataviews.
;-
function spd_spdfGetDataviews, $
  cdas
  
  if ~(cdas->isUpToDate()) then begin
  
    reply = dialog_message([ $
      'Current version: ' + cdas->getVersion(), $
      'Available version: ' + cdas->getCurrentVersion(), $
      'There is a newer version of this software available.'], $
      title='Version Warning', /center, /information)
  endif
  
  dataviews = cdas->getDataviews()
  
  extraDataviewIds = getenv('SPDF_EXTRA_DATAVIEWS')
  
  if strlen(extraDataviewIds) eq 0 then begin
  
    return, dataviews
  endif
  
  extraDataviewIds = strsplit(extraDataviewIds, ':', /extract)
  numExtraDataviews = 0
  
  for i = 0, n_elements(extraDataviewIds) - 1 do begin
  
    datasets = cdas->getDatasets(dataview = extraDataviewIds[i])
    
    if n_elements(datasets) eq 1 && $
      ~obj_valid(datasets[0]) then begin
      
      print, extraDataviewIds[i], $
        ' does not appear to be a valid dataview.', $
        ' It will be ignored.'
      extraDataviewIds[i] = ''
    endif else begin
    
      numExtraDataviews = numExtraDataviews + 1
    endelse
  endfor
  
  if numExtraDataviews gt 0 then begin
  
    expandedDataviews = $
      objarr(n_elements(dataviews) + numExtraDataviews, /nozero)
      
    for i = 0, n_elements(dataviews) - 1 do begin
    
      expandedDataviews[i] = dataviews[i]
    endfor
    
    endpointAddress = dataviews[0]->getEndpointAddress()
    endpointAddress = $
      strsplit(endpointAddress, dataviews[0]->getId(), $
      /regex, /extract)
      
    j = 0
    for i = n_elements(dataviews), $
      n_elements(expandedDataviews) - 1 do begin
      
      while extraDataviewIds[j] eq '' do j = j + 1
      
      expandedDataviews[i] = $
        obj_new('SpdfDataviewDescription', $
        extraDataviewIds[j], endpointAddress, $
        extraDataviewIds[j], '', '', 1b, '', 0b)
        
      j = j + 1
    endfor
    
    return, expandedDataviews
  endif
  
  return, dataviews
end

;+
; Responds to an event requesting the retrieval of the data
; specified by the users previous selections.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spd_GetCdawebDataRun, event

  widget_control, event.top, get_uvalue=state
  groupLeaderWidgetId = state.groupLeaderWidgetId
  Widget_Control, groupLeaderWidgetId, Get_UValue=info
  
  timeRangeObj = state.timeRangeObj
  timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj
  
  startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
  endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
  
  newStartTime=spd_tranform_time_to_spdf(startTimeString)
  newStopTime=spd_tranform_time_to_spdf(endTimeString)
  
  widget_control, state.startTime, set_value=newStartTime
  widget_control, state.stopTime, set_value=newStopTime
  
  spd_spdfGetCdawebData, event
  
  prefixText = widget_info(event.top, find_by_uname='PREFIXTEXT')
  widget_control, prefixText, get_value=prefix
  widget_control, event.top, get_uvalue=state
  theprefix = prefix[0]
  if theprefix ne '' then theprefix = spd_string_replacen(theprefix,' ', '_')
  
  saveCheckbox = widget_info(event.top, find_by_uname='SAVECDFFILE')
  checkboxstatus = Widget_Info(saveCheckbox, /BUTTON_SET)
  
  localCDFfile = state.localcdfnames
  CDFfileExists = FILE_TEST(localCDFfile[0])
  if CDFfileExists then begin
  
    selectedObservatoryGroups = $
      widget_info(state.observatoryGroupList, /list_select)
      
    fix_spedas_depend_time, localCDFfile[0]
    
    cdf2tplot,files=localCDFfile,all=1,prefix=theprefix,tplotnames=tplotnames,/load_labels
    
    ;replacing with automatic import
    ;spd_ui_manage_data, info.master, info.loadedData, info.windowStorage, info.historywin,info.guiTree
 
    ;better import, although gui_load_tvars breaks abstraction a little bit
    ;TODO: fix abstraction violation by allowing keyword override of !spedas variables that spd_ui_tplot_gui_load_tvars uses (I only fixed the funcitonally important one, gui_id)
    spd_ui_tplot_gui_load_tvars,tplotnames,all_names=all_varnames,gui_id=event.top   
    spd_ui_verify_data,event.top, all_varnames,info.loadedData, info.windowStorage, info.historyWin, success=success,newnames=new_names
    
    if ~keyword_set(success) then success=0
    if success then begin
      statusMessage = 'CDAWeb: All variables imported successfully. Check history window for details.'
      state.statusBar->Update, statusMessage
      info.historyWin->Update, statusMessage
      tmp = dialog_message(statusMessage,/info,/center,title='CDAWeb Import Succesful')
    endif else begin
      statusMessage = 'CDAWeb: Problem importing some variables.  Check history window for details.'
      state.statusBar->Update, statusMessage
      info.historyWin->Update, statusMessage
      tmp = dialog_message(statusMessage,/error,/center,title='CDAWeb Import Error')
    endelse      
    
    info.drawObject->Update,info.windowStorage,info.loadedData
    info.drawObject->Draw
    
  endif
  
  if checkboxstatus eq 1 then begin
    statusMessage = 'Saved CDAWeb CDF file: ' + state.localcdfnames
    state.statusBar->Update, statusMessage
    info.historyWin->Update, statusMessage
  endif else begin
    if CDFfileExists then begin
      file_delete, state.localcdfnames, /QUIET
      statusMessage = 'Removed CDAWeb CDF file: ' + state.localcdfnames
      state.statusBar->Update, statusMessage
      info.historyWin->Update, statusMessage
    endif
  endelse
  
  return
end

;+
; Responds to an event
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
PRO spd_ui_spdfcdawebchooser_event, event

  IF TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST' THEN begin
  
    spd_spdfExit, event
    return
  ENDIF
  
  ;get state structure and widget identity
  widget_control, event.top, get_uvalue=state
  widget_name = widget_info(event.id, /uname)

  ; *** NOTE ***
  ; Some events caught here appear to have identical event.top & event.id
  ; These appear to be the benign results of "Undocumented features" in xmanager
  
  ;process recognized widgets' events
  CASE widget_name[0] OF
  
    'PICKDIR':BEGIN
    localDirText = widget_info(event.top, find_by_uname='LOCALDIR')
    widget_control, localDirText, get_value=cdfFolder
    sFolder = DIALOG_PICKFILE(PATH=cdfFolder, /DIRECTORY, $
      TITLE="Choose directory for saving CDAWeb CDF files.")
    
    ; only update the directory if the user didn't cancel the window
    if sFolder ne '' then begin
        localDirText = widget_info(event.top, find_by_uname='LOCALDIR')
        widget_control, localDirText, set_value=sFolder
    endif 
    
    END
    'SAVECDFFILE': BEGIN
      *state.saveData = event.select

    END
    'EXIT': BEGIN
      spd_spdf_savecdfdir, event
      spd_spdfExit, event
      return
    end
    else:
  
  endcase

end

pro spd_spdf_savecdfdir, event
  localDirText = widget_info(event.top, find_by_uname='LOCALDIR')
  widget_control, localDirText, get_value=cdfFolder
  localdir = STRTRIM(cdfFolder[0],2)
  if localdir ne '' then begin
    if STRMID(localdir, 0, 1, /REVERSE_OFFSET) ne path_sep() then localdir = localdir + path_sep()
    if FILE_SEARCH(localdir, /TEST_WRITE) then begin
      if localdir ne !spedas.TEMP_CDF_DIR then begin
        !spedas.TEMP_CDF_DIR = localdir
        spedas_write_config
      endif
    endif
   endif
end 



;+
; Provides a GUI for choosing and retrieving data from
; <a href="http://cdaweb.gsfc.nasa.gov/">CDAWeb</a>.
;
; @keyword GROUP_LEADER {in} {type=int}
;              The widget ID of the group leader for this window.  If
;              no value is provided, the resulting window will not
;              belong to a group and will be non-blocking.
; @keyword historyWin {in} {type=int}
;              The widget ID of history of the main window
; @keyword statusBar {in} {type=int}
;              The widget ID of statusBar of the main window
; @keyword timeRangeObj {in} {type=obj}
;              Object reference for the GUI time range.  (Allows webChooser to maintain time range state when panel is opened and closed)
;-
pro spd_ui_spdfcdawebchooser, historyWin=historyWin, GROUP_LEADER = groupLeaderWidgetId,timeRangeObj=timeRangeObj,callSequence=callSequence

  COMPILE_OPT IDL2
  
  spd_cdawlib
  
  if ~keyword_set(!spedas) then spedas_init
  localdir = !spedas.TEMP_CDF_DIR
    
  if keyword_set(groupLeaderWidgetId) then begin
  
    tlb = widget_base(title='CDAWeb Data Chooser', /column, $
      GROUP_LEADER=groupLeaderWidgetId, /Modal,  /TLB_KILL_REQUEST_EVENTS, tab_mode=1, TLB_Size_Events=1)
    ;defaultSaveCdfOption = 1
  endif else begin
  
    tlb = widget_base(title='CDAWeb Data Chooser', /column, TLB_Size_Events=1)
    ;defaultSaveCdfOption = 0
  endelse
  
  defaultSaveCdfOption = 0
  cdas = $
    obj_new('SpdfCdas', $
    endpoint='http://cdaweb.gsfc.nasa.gov/WS/cdasr/1', $
    userAgent='CdawebChooser/1.0')
    
  dataviews = spd_spdfGetDataviews(cdas)
  
  initialDvSelection = 0
  
  if ~OBJ_VALID(dataviews[0]) then begin
    errorstr = 'Could not connect to CDAWEB. Please check if there is an internet connection to http://cdaweb.gsfc.nasa.gov'
    res = dialog_message(errorstr, /center )
    return
  endif
  
  dvTitles = strarr(n_elements(dataviews))
  for i = 0, n_elements(dataviews) - 1 do begin
    dvTitles[i] = dataviews[i]->getTitle()
    if dataviews[i]->getId() eq 'sp_phys' then begin
      initialDvSelection = i
    endif
  endfor
  
  ;
  ;create tlb base widgets
  ;
  dvBase = widget_base(tlb, frame=3, /column)
  datasetSelectionPanel = widget_base(tlb, frame=3, /column)
  dataSelectionPanel = widget_base(tlb, frame=3, row=3)
  dsContextMenu = widget_base(tlb, /context_menu)
  ;dataOperationPanel = widget_base(tlb, frame=3, /column, MAP=0, SCR_YSIZE=1)
  programControlPanel = widget_base(tlb, /row, /align_center,/GRID_LAYOUT)
  
  ;
  ;local status bar
  ;
  statusBar = Obj_New('SPD_UI_MESSAGE_BAR',tlb, XSize=100, YSize=1)
  
  ;
  ; Dataview selection panel
  ;

  dvLabel = widget_label(dvBase, /align_left, $
    value='Dataview Selection: ')
  dvList = widget_combobox(dvBase, event_pro='spdfDataviewSelected', $
    value=dvTitles)
    
  ;
  ; Dataset selection panel
  ;

  
  datasetSelectionLabel = $
    widget_label(datasetSelectionPanel, /align_left, $
    value='Dataset Selection:')
    
  miPanel = widget_base(datasetSelectionPanel, /row)
  
  missionGroups = ['']
  missionGroupsPanel = widget_base(miPanel, /column)
  mLabel = widget_label(missionGroupsPanel, value='Mission Groups')
  mList = widget_list(missionGroupsPanel, $
    event_pro='spdfIgnoreSelected', $
    value=missionGroups, xsize=50, ysize=8, /multiple)
    
  instrumentTypes = ['']
  instrumentTypesPanel = widget_base(miPanel, /column)
  iLabel = widget_label(instrumentTypesPanel, $
    value='Instrument Types')
  iList = widget_list(instrumentTypesPanel, $
    event_pro='spdfIgnoreSelected', $
    value=instrumentTypes, xsize=60, ysize=8, /multiple)
    
  dsButton = widget_button(datasetSelectionPanel, $
    /align_center,  $
    event_pro='spdfFindDatasets', $
    value='Find Datasets', $
    tooltip='Find datasets for the specified mission groups and instrument types')
    


    
  ;
  ; Data selection panel
  ;

  
  dataSelectionLabel = $
    widget_label(dataSelectionPanel, /align_left, $
    value='Data Selection:')
    
  dsLabel = widget_label(dataSelectionPanel, $
    value='Datasets/Variables')
  dsTreeBase = widget_base(dataSelectionPanel, row=1)
  dsTree = widget_tree(dsTreeBase, /multiple, $
    /context_events, event_pro='spdfDatasetTreeEvent', $
   xsize=650, ysize=200)
   
;; commented out the follow lines because they don't appear to do anything, egrimes 7/7/2014  
;  viewNotesButton = widget_button(dsContextMenu, $
;    event_pro='spdfViewNotes', $
;    value="View Notes")
;  viewInventoryButton = widget_button(dsContextMenu, $
;    event_pro='spdfViewInventory', $
;    value="View Inventory")

   ;; the purpose of this new base is to split the time selection and CDF directory
   ;; selection widgets into 2 columns, rather than 2 rows; this is needed so that the
   ;; buttons on the bottom of the screen are displayed on displays with resolutions ****x800px.
   
   new_col_base = widget_base(dataSelectionPanel, col=2)
  timeWidget = spd_ui_time_widget(new_col_base,$
    statusBar,$
    historyWin,$
    timeRangeObj=timeRangeObj,$
    uname='TIME_WIDGET',$
    startyear = 1965)
  ; the following is needed to grab SPDF data, for some reason, egrimes 7/10/2014  
  timePanel = widget_base(new_col_base, /row, MAP=0, SCR_YSIZE=1, scr_xsize=120)
 ; defaultTimeButton = widget_button(timePanel, $
 ;   event_pro='spdfDefaultTime', $
 ;   value="Set Default Time")
  startTime = cw_field(timePanel, title='Start Time')
  
  stopTime = cw_field(timePanel, title='Stop Time')
 ; timeFormatLabel = widget_label(timePanel, $
 ;   value='Format YYYY/MM/DD[ HH:MM:SS]')
    
  dataVarName = cw_field(timePanel, title='Variable Name', value='spdf_data')
    
  right_col_base = widget_base(new_col_base, row=2, /base_align_right)
  localDirPanel = widget_base(right_col_base, row=2)
  localDirLabel = widget_label(localDirPanel, value = 'Local CDF directory:  ')
  localDirText = widget_text(localDirPanel, /edit, /all_events, xsize = 20,  $
     uname = 'LOCALDIR', val = localdir )

  getresourcepath,rpath
  folderbmp = read_bmp(rpath + 'folder_horizontal_open.bmp', /rgb)
  spd_ui_match_background, tlb, folderbmp

  localDirButton=WIDGET_BUTTON(localDirPanel, VALUE=folderbmp, uname='PICKDIR', $
    tooltip='Choose directory for saving CDAWeb CDF files', /BITMAP)

  localDirLabelEmpty = widget_label(localDirPanel, value = ' ')
  saveCDFPanel = widget_base(localDirPanel, /row, /NonExclusive)
  prefixLabel = Widget_Button(saveCDFPanel, uname='SAVECDFFILE', value = 'Save local CDF file')


  prefixPanel = widget_base(right_col_base, /row)
  prefixLabel = widget_label(prefixPanel, value = 'Prefix for tplot variables:')
  prefixText = widget_text(prefixPanel, /edit, /all_events, xsiz = 20, $
    uval = 'PREFIXTEXT', uname = 'PREFIXTEXT', val = '' )

  ;
  ; Program control panel
  ;
  
  dataButton1 = widget_button(programControlPanel, $
    event_pro='spd_GetCdawebDataRun', $
    value='Get CDAWeb Data', $
    tooltip='Read CDAWeb data into SPEDAS environment', /align_center)
    
  programControlLabel = $
    widget_label(programControlPanel, /align_center, $
    value='       ')
  exitButton = widget_button(programControlPanel, /align_center, $
    event_pro='spd_spdfExit', $
    value='Close', tooltip='Close this window')
    

   
  localCdfNames=strarr(1)
  state = { $
    errorDialog:obj_new('SpdfHttpErrorDialog'), $
    authenticator:obj_new('SpdfCdawebChooserAuthenticator', tlb), $
    cdas:cdas, $
    selectedDataview:ptr_new(/allocate_heap), $
    dataviews:dataviews, $
    dataviewList:dvList, $
    observatoryGroups:ptr_new(/allocate_heap), $
    observatoryGroupList:mList, $
    instrumentTypes:ptr_new(/allocate_heap), $
    instrumentTypeList:iList, $
    datasets:ptr_new(/allocate_heap), $
    datasetTree:dsTree, $
    selectedDataset:ptr_new(/allocate_heap), $
    datasetContextMenu:dsContextMenu, $
    startTime:startTime, $
    stopTime:stopTime, $
    dataVarName:dataVarName, $
    saveData:ptr_new(defaultSaveCdfOption), $
    timeRangeObj:timeRangeObj, $
    localCdfNames:localCdfNames, $
    tlb:tlb, $
    callSequence:callSequence,$
    statusBar:statusBar,$
    historyWin:historyWin,$
    groupLeaderWidgetId:groupLeaderWidgetId $
  }
  
  widget_control, tlb, set_uvalue=state, /realize
  WIDGET_CONTROL, tlb, tab_mode=1
  spd_spdfSelectDataview, tlb, dvList, initialDvSelection
  
  if keyword_set(groupLeaderWidgetId) then begin
  
    xmanager, 'spd_ui_spdfcdawebchooser', tlb, $
      group_leader=groupLeaderWidgetId
      
  endif else begin
  
    xmanager, 'spd_ui_spdfcdawebchooser', tlb, /no_block
    
  endelse
  
end
