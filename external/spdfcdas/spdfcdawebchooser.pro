;
; NOSA HEADER START
;
; The contents of this file are subject to the terms of the NASA Open 
; Source Agreement (NOSA), Version 1.3 only (the "Agreement").  You may 
; not use this file except in compliance with the Agreement.
;
; You can obtain a copy of the agreement at
;   docs/NASA_Open_Source_Agreement_1.3.txt
; or 
;   https://cdaweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
;
; See the Agreement for the specific language governing permissions
; and limitations under the Agreement.
;
; When distributing Covered Code, include this NOSA HEADER in each
; file and include the Agreement file at 
; docs/NASA_Open_Source_Agreement_1.3.txt.  If applicable, add the 
; following below this NOSA HEADER, with the fields enclosed by 
; brackets "[]" replaced with your own identifying information: 
; Portions Copyright [yyyy] [name of copyright owner]
;
; NOSA HEADER END
;
; Copyright (c) 2010-2017 United States Government as represented by the
; National Aeronautics and Space Administration. No copyright is claimed
; in the United States under Title 17, U.S.Code. All Other Rights 
; Reserved.
;
;


;+
; This program provides a GUI for choosing datasets from 
; <a href="https://cdaweb.gsfc.nasa.gov/">CDAWeb</a>.
; 
; @copyright Copyright (c) 2010-2017 United States Government as 
;     represented by the National Aeronautics and Space Administration.
;     No copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-

pro twinscolorbar
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
pro spdfSelectDataview, $
    tlb, dvList, dvIndex
    compile_opt idl2

    widget_control, dvList, set_combobox_select=dvIndex
    widget_control, dvList, $
        send_event={id:dvList, top:tlb, handler:dvList, index:dvIndex}
end


;+
; Responds to a "dataview selected" event.
;
; @param event {in} {type=widget event}
;            widget_list event.
;-
pro spdfDataviewSelected, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    *state.selectedDataview = state.dataviews[event.index]->getId()

    if *state.selectedDataview eq 'cnofs' then begin

        reply = dialog_message( $
                    ['The required authentication for this dataview is not yet implemented.', 'Please choose a different dataview.'], $
                    title='Dataview Selection', /center, /information)

        spdfSelectDataview, event.top, state.dataviewList, 0

        return
    endif

    widget_control, /hourglass

    observatoryGroups = state.cdas->getObservatoryGroups($
        dataview = *state.selectedDataview, $
        authenticator=state.authenticator, $
        httpErrorReporter=state.errorDialog)

    *state.observatoryGroups = strarr(n_elements(observatoryGroups))

    for i = 0, n_elements(observatoryGroups) - 1 do begin

        (*state.observatoryGroups)[i] = observatoryGroups[i]->getName()
    endfor

    obj_destroy, observatoryGroups

    widget_control, state.observatoryGroupList, $
        set_value=*state.observatoryGroups


    instrumentTypes = state.cdas->getInstrumentTypes($
        dataview = *state.selectedDataview, $
        authenticator=state.authenticator, $
        httpErrorReporter=state.errorDialog)

    *state.instrumentTypes = strarr(n_elements(instrumentTypes))

    for i = 0, n_elements(instrumentTypes) - 1 do begin

        (*state.instrumentTypes)[i] = instrumentTypes[i]->getName()
    endfor

    obj_destroy, instrumentTypes

    widget_control, state.instrumentTypeList, $
        set_value=*state.instrumentTypes

end


;+
; Finds the specified dataset description within the given array of
; descriptions.
;
; @private
;
; @param descriptions {in} {type=SpdfDatasetDescription}
;            Array of descriptions to search (for example, 
;            state.datasets).
; @param id {in} {type=string}
;            Dataset identifier.
; @returns Dataset description from descriptions with the specified id
;              or a NULL object reference if the description was not
;              found.
;-
function spdfGetDatasetDescription, $
    descriptions, id
    compile_opt idl2

    for i = 0, n_elements(descriptions) - 1 do begin

        if descriptions[i]->getId() eq id then return, descriptions[i]
    endfor

    return, obj_new()
end


;+
; Responds to a dataset tree event.
;
; @param event {in} {type=widget event}
;            event triggering the execution of this procedure
;-
pro spdfDatasetTreeEvent, $
    event
    compile_opt idl2

    ;
    ; Note: In general, the selected item's tree index cannot be used
    ; to locate the corresponding SpdfDatasetDescription in 
    ; state.datasets because "pointer datasets" are not in the tree but
    ; are in state.datasets and the tree may be sorted differently.
    ;
    widget_control, event.top, get_uvalue=state

    selectedItem = widget_info(state.datasetTree, /tree_select)

    if selectedItem[0] eq -1 then return

    widget_control, selectedItem[0], get_uvalue=selectedValue

    ; Only dataset tree values are of type 7 (string) so ignore 
    ; all others

    if size(selectedValue, /type) ne 7 then return

    *state.selectedDataset = $
        spdfGetDatasetDescription(*state.datasets, selectedValue)

    if tag_names(event, /structure_name) eq 'WIDGET_CONTEXT' then begin

        widget_displaycontextmenu, event.ID, event.X, event.Y, $
            state.datasetContextMenu
    end
end


;+
; Responds to a request to view a dataset's notes.
;
; @param event {in} {type=widget event}
;            event triggering the execution of this procedure
;-
pro spdfViewNotes, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    selectedDataset = *state.selectedDataset

    fullNotesUrl = selectedDataset->getNotes()

    urlComponents = $
        strsplit(fullNotesUrl, '#', count=componentCount, /extract)

    notesUrl = urlComponents[0]

    if componentCount eq 2 then begin

        notesAnchor = urlComponents[1]
    endif

    pathComponents = $
        strsplit(notesUrl, '/', count=componentCount, /extract)

    filename = pathComponents[componentCount - 1]

    proxy_authentication = 0
    proxy_hostname = ''
    proxy_password = ''
    proxy_port = ''
    proxy_username = ''

    http_proxy = getenv('HTTP_PROXY')

    if strlen(http_proxy) gt 0 then begin

        proxyComponents = parse_url(http_proxy)

        proxy_hostname = proxyComponents.hostname
        proxy_password = proxyComponents.password
        proxy_port = proxyComponents.port
        proxy_username = proxyComponents.username

        if strlen(proxy_username) gt 0 then begin

            proxy_authentication = 3
        endif
    endif

    notes = obj_new('IDLnetURL', $
                    proxy_authentication = proxy_authentication, $
                    proxy_hostname = proxy_hostname, $
                    proxy_port = proxy_port, $
                    proxy_username = proxy_username, $
                    proxy_password = proxy_password)

    localNotes = notes->get(filename=filename, url=notesUrl)

; save filename so it can be deleted when this program Exits

    if n_elements(notesAnchor) ne 0 then begin

        online_help, notesAnchor, book=localNotes, /full_path
    endif else begin

        online_help, book=localNotes, /full_path
    endelse

end



;+
; Responds to an inventory window close event.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spdfCloseInventory, $
    event
    compile_opt idl2

    widget_control, event.top, /destroy
end


;+
; Responds to a request to view a dataset's inventory.
;
; @param event {in} {type=widget event}
;            event triggering the execution of this procedure
;-
pro spdfViewInventory, $
    event

    widget_control, event.top, get_uvalue=state

    selectedDataset = *state.selectedDataset

    inventory = state.cdas->getInventory( $
                    dataview = *state.selectedDataview, $
                    selectedDataset->getId(), $
                    authenticator=state.authenticator, $
                    httpErrorReporter=state.errorDialog)

    intervals = inventory->getTimeIntervals()

    intervalStrings = strarr(2, n_elements(intervals))

    for i = 0, n_elements(intervals) - 1 do begin

        intervalStrings[0, i] = intervals[i]->getCdawebStart()
        intervalStrings[1, i] = intervals[i]->getCdawebStop()
    endfor

    title = inventory->getId() + ' Data Inventory'

    inventoryWin = $
        widget_base(title=title, /column, group_leader=event.top)

    label = widget_label(inventoryWin, value=title);

    table = widget_table(inventoryWin, $
                column_labels = ['Start Time', 'Stop Time'], $
                /no_row_headers, value=intervalStrings)

    closeButton = widget_button(inventoryWin, /align_left, $
                      event_pro='spdfCloseInventory', $
                      value='Close', tooltip='Close inventory window')

    widget_control, inventoryWin, /realize

    xmanager, 'SpdfViewInventory', inventoryWin, /no_block

    obj_destroy, intervals
    obj_destroy, inventory
end


;+
; Responds to a request to set a default time value.
;
; @param event {in} {type=widget event}
;            event triggering the execution of this procedure
;-
pro spdfDefaultTime, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    selectedItem = widget_info(state.datasetTree, /tree_select)

    if selectedItem[0] eq -1 then begin

        reply = dialog_message( $
                    'Please choose a Dataset/Variable', $
                    title='Missing Dataset Selection', /center, /error)
        return
    endif

    if ~widget_info(selectedItem[0], /tree_folder) then begin

        datasetWidget = widget_info(selectedItem[0], /parent)
    endif else begin

        datasetWidget = selectedItem[0]
    endelse

    widget_control, datasetWidget, get_uvalue=datasetId

    selectedDataset = $
        spdfGetDatasetDescription(*state.datasets, datasetId)

    timeInterval = selectedDataset->getTimeInterval()

    timeInterval->setStart, timeInterval->getStop() - 1

    widget_control, state.startTime, $
        set_value = timeInterval->getCdawebStart()
    widget_control, state.stopTime, $
        set_value = timeInterval->getCdawebStop()
end


;+
; Responds to an event by doing nothing (ignoring it).
;
; @param event {in} {type=widget event}
;            event triggering the execution of this procedure.
;-
pro spdfIgnoreSelected, $
    event
    compile_opt idl2

end


;+
; Responds to a "save data" button event.
;
; @param event {in} {type=widget event}
;            event triggering the execution of this function.
; @returns 0
;-
function spdfSaveDataButton, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    *state.saveData = event.select

    return, 0
end


;+
; Responds to an event that initiates a search for datasets that
; satisfies the users previous selections.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spdfFindDatasets, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    selectedObservatoryGroups = $
        widget_info(state.observatoryGroupList, /list_select)

    if selectedObservatoryGroups[0] eq -1 then begin

        reply = dialog_message( $
                    'Please choose one or more Mission Groups', $
                    title='Mission Selection', /center, /error)
        return
    endif

    observatoryGroups = ptr_new()

    if selectedObservatoryGroups[0] ne -1 then begin

        observatoryGroups = strarr(n_elements(selectedObservatoryGroups))

        for i = 0, n_elements(observatoryGroups) - 1 do begin

            observatoryGroups[i] = $
                (*state.observatoryGroups)[selectedObservatoryGroups[i]]
        endfor
    endif

    selectedInstrumentTypes = $
        widget_info(state.instrumentTypeList, /list_select)

    if selectedInstrumentTypes[0] eq -1 then begin

        reply = dialog_message( $
                    'Please choose one or more Instrument Types', $
                    title='Mission Selection', /center, /error)
        return
    endif

    instrumentTypes = ptr_new()

    if selectedInstrumentTypes[0] ne -1 then begin

        instrumentTypes = strarr(n_elements(selectedInstrumentTypes))

        for i = 0, n_elements(instrumentTypes) - 1 do begin

            instrumentTypes[i] = $
                (*state.instrumentTypes)[selectedInstrumentTypes[i]]
        endfor
    endif

    oldRootNode = widget_info(state.datasetTree, /child)

    if oldRootNode ne 0 then widget_control, oldRootNode, /destroy

    if n_elements(*state.datasets) then begin

        *state.selectedDataset = obj_new()
        obj_destroy, *state.datasets
    endif

    rootNode = widget_tree(state.datasetTree, value='Datasets', $
                   event_pro='spdfIgnoreSelected', $
                   /folder, /expanded)

    widget_control, /hourglass

    datasets = state.cdas->getDatasets( $
                   dataview = *state.selectedDataview, $
                   observatoryGroups = observatoryGroups, $
                   instrumentTypes = instrumentTypes, $
                   authenticator=state.authenticator, $
                   httpErrorReporter=state.errorDialog)

    if ~obj_valid(datasets[0]) then begin

        reply = dialog_message( $
                    ['No datasets were found matching the selection criteria.',$
                     'Please change the selection criteria.'], $
                    title='Datasets Not Found', /center, /information)

        obj_destroy, datasets
        return
    endif

    *state.datasets = datasets

    datasetIds = strarr(n_elements(datasets))
    for i = 0, n_elements(datasets) - 1 do begin

        datasetIds[i] = datasets[i]->getId()
    endfor
    sortedDatasetIndexes = sort(datasetIds)

    for i = 0, n_elements(datasets) - 1 do begin

        datasetId = datasets[sortedDatasetIndexes[i]]->getId()

        datasetLabel = datasets[sortedDatasetIndexes[i]]->getLabel()
        datasetTimeRange = datasets[sortedDatasetIndexes[i]]->getTimeInterval()

        datasetTitle = datasetId + ': ' + $
            datasetTimeRange->getCdawebStart() + ' - ' + $
            datasetTimeRange->getCdawebStop() + ': ' + datasetLabel

        variables = state.cdas->getVariables( $
                        datasetId, $
                        dataview = *state.selectedDataview, $
                        authenticator=state.authenticator, $
                        httpErrorReporter=state.errorDialog)

        if obj_valid(variables[0]) then begin

            ; Not merely a pointer dataset (we do not show pointer
            ; datasets in the tree).

            ;
            ; Putting a uvalue of datasets[i] in the tree widget
            ; makes destroying the widget more difficult
            ;
            datasetNode = widget_tree(rootNode, value=datasetTitle, $
;                              /folder, /expanded, uvalue=datasetId, $
                              /folder, uvalue=datasetId, $
                              event_pro='spdfDatasetTreeEvent')

            for j = 0, n_elements(variables) - 1 do begin

                varName = variables[j]->getName()
                varDescription = variables[j]->getLongDescription()
                if varDescription eq '' then begin

                    varDescription = variables[j]->getShortDescription()
                endif

                varTitle = varName + ': ' + varDescription

                varNode = widget_tree(datasetNode, value=varTitle, $
                              event_pro='spdfIgnoreSelected', $
                            uvalue={datasetId:datasetId, varName:varName})
            endfor
        endif
        obj_destroy, variables
    endfor

end


;+
; Determines if the given string is a valid date/time value.
;
; @param value {in} {type=string}
;            value to be tested.
; @returns true if the given string is a valid date/time value.
;             Otherwise false.
;-
function spdfIsValidDate, $
    value
    compile_opt idl2

    return, stregex(value, $
                '[12][0-9]{3}[-/][01][0-9][-/][0-3][0-9]([ T][0-2][0-9]:[0-5][0-9]:[0-5][0-9])?', $
                /boolean)
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
function spdfGetDatasetSelection, $
    datasetTree, selectedDatasetId, selectedVarNames
    compile_opt idl2

    selectedItems = widget_info(datasetTree, /tree_select)

    if selectedItems[0] eq -1 then begin

        reply = dialog_message( $
            'Please choose one or more Variables within a single Dataset', $
            title='Dataset Variable Selection', /center, /error)
        return, 0
    endif

    datasetsSelected = 0
    varsSelected = 0
    selectedDatasetId = ''

    ; first count the number of selected datasets and variables

    for i = 0, n_elements(selectedItems) - 1 do begin

        if ~widget_info(selectedItems[i], /tree_folder) then begin

            widget_control, selectedItems[i], $
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
        selectedVarIndex = 0

        ; now go back and get the selected variable names
        
        for i = 0, n_elements(selectedItems) - 1 do begin

            if ~widget_info(selectedItems[i], /tree_folder) then begin


                widget_control, selectedItems[i], $
                    get_uvalue=selectedDataset

                selectedVarNames[selectedVarIndex] = $
                    selectedDataset.varName
                selectedVarIndex++
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
; Gets the specified time interval.
;
; @param startTimeWidget {in} {type=int}
;            id of start time widget.
; @param stopTimeWidget {in} {type=int}
;            id of stop time widget.
; @returns specifed time interval or null object reference if an
;              invalid value was specified.
;-
function spdfGetSpecifiedTime, $
    startTimeWidget, stopTimeWidget
    compile_opt idl2

    widget_control, startTimeWidget, get_value=startTime

    if ~spdfIsValidDate(startTime) then begin

        reply = dialog_message( $
            ['The Start Time must be set to a valid value', $
             'YYYY/MM/DD[ HH:MM:SS]'], $
            title='Invalid Date', /center, /error)
        return, obj_new()
    endif

    widget_control, stopTimeWidget, get_value=stopTime

    if ~spdfIsValidDate(stopTime) then begin

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
; Creates IDL statements to read the specified data into an IDL 
; environment.  
;
; @param state {in} {type=struct}
;            widget program's state.
; @param timeInterval {in} {type=SpdfTimeInterval}
;            time range of data to get.  If this is not a valid
;            object reference, then the generated IDL statement
;            contains the variable names t_init and t_final instead
;            of actual time values.
; @param datasetId {in} {type=string}
;            dataset identifier.
; @param varNames {in} {type=strarr}
;            names of variables containing the desired data.
;-
pro spdfGetCdawebDataCmd, $
    state, timeInterval, datasetId, varNames
    compile_opt idl2

    widget_control, state.dataVarName, get_value=dataVarName

    datasetCmdTxt = "'" + datasetId + "'"

    varCmdTxt = "['" + varNames[0] + "'"
    for i = 1, n_elements(varNames) - 1 do begin
        varCmdTxt = varCmdTxt + ", '" + varNames[i] + "'"
    endfor
    varCmdTxt = varCmdTxt + "]"

    if obj_valid(timeInterval) then begin

        timeCmdTxt = "['" + timeInterval->getIso8601Start() + $
                     "', '" + timeInterval->getIso8601Stop() + "']"
    endif else begin

        timeCmdTxt = "[t_init, t_final]"

    endelse

    print, dataVarName, ' = spdfgetdata(', datasetCmdTxt, ', ', $
           varCmdTxt, ', ', timeCmdTxt, ')'

    reply = dialog_message( $
        ['The specified data can be read into the IDL environment by', $
        'executing the IDL statements that were printed on the ', $
        'IDL console.'], $
                title='Get Data Operation', /center, /information)
end


; Eliminated the following when everyone is using CDF 3.5's better version.
;
function spdfCdfEpoch2Julday, $
    epoch
    compile_opt idl2

    julday = dblarr(n_elements(epoch), /nozero)

    for i = 0, n_elements(epoch) - 1 do begin

        cdf_epoch, epoch[i], /breakdown_epoch, $
            year, month, day, hour, minute, second, millisecond

        secondMillisecond = float(second) + float(millisecond) / 1000.0

        julday[i] = julday (month, day, year, hour, minute, secondMillisecond)
    endfor

    return, julday
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
pro spdfGetCdawebDataExec, $
    state, timeInterval, datasetId, varNames
    compile_opt idl2

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

            localCdfNames[i] = fileDescriptions[i]->getFile()
        endfor

        ; make a copy of localCdfNames that read_mycdf can alter
        localCdfNames2 = localCdfNames
        cdfData = read_mycdf(varNames, localCdfNames2) 

        (scope_varFetch(dataVarName, /enter, level=1)) = $
            hsave_struct(cdfData, /nosave)

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

        if *state.saveData then begin

            resultMsgIndex = n_elements(varNames)

            resultMsg[resultMsgIndex++] = $
                'Also, the downloaded data has been saved in'

            for i = 0, n_elements(localCdfNames) - 1 do begin

                resultMsg[resultMsgIndex + i] = $
                    '    ' + localCdfNames[i]
            endfor
        endif else begin

            file_delete, localCdfNames
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
; Responds to an event requesting the retrieval of the data
; specified by the users previous selections.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spdfGetCdawebData, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    if spdfGetDatasetSelection(state.datasetTree, $
           selectedDatasetId, selectedVarNames) ne 1 then return

    timeInterval = spdfGetSpecifiedTime(state.startTime, state.stopTime)

    if ~obj_valid(timeInterval) then return

    spdfGetCdawebDataExec, $
        state, timeInterval, selectedDatasetId, selectedVarNames

    obj_destroy, timeInterval
end


;+
; Responds to an event requesting the IDL code to retrieve the data
; specified by the users previous selections.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spdfGetCdawebDataIdl, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    if spdfGetDatasetSelection(state.datasetTree, $
           selectedDatasetId, selectedVarNames) ne 1 then return

    widget_control, state.startTime, get_value=startTime
    widget_control, state.stopTime, get_value=stopTime

    if startTime eq '' and stopTime eq '' then begin

        timeInterval = obj_new()

    endif else begin

        timeInterval = $
            spdfGetSpecifiedTime(state.startTime, state.stopTime)

        if ~obj_valid(timeInterval) then return

    endelse

    spdfGetCdawebDataCmd, $
        state, timeInterval, selectedDatasetId, selectedVarNames

    obj_destroy, timeInterval
end


;+
; Responds to an event requesting that data be read from a local
; file.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spdfReadLocalData, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state
    widget_control, state.dataVarName, get_value=dataVarName

    files = dialog_pickfile(default_extension='cdf', $
                filter=['*.cdf'], /fix_filter, $
                /multiple_files, /must_exist, /read)

    widget_control, /hourglass

    if files ne '' then begin

        cdfData = read_mycdf(varNames, files, all=1)

        (scope_varFetch(dataVarName, /enter, level=1)) = $
            hsave_struct(cdfData, /nosave)

        reply = dialog_message($
                'Data from the selected file(s) is now available in ' $
                + dataVarName + '.dat', $
                    title='Read Data Operation', /center, /information)
    endif
end


;+
; Responds to an event requesting the CDAWlib's plot of the retrieved
; data specified by the users previous selections.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spdfGetCdawebPlot, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    widget_control, state.dataVarName, get_value=dataVarName

    if n_elements((scope_varFetch(dataVarName, /enter, level=1))) then begin

        ; make a copy of the data for plotmaster to destroy
        copyOfData = scope_varFetch(dataVarName, level=1)

        s = plotmaster(copyOfData, xsize=600, /AUTO, /CDAWEB, /SMOOTH, /SLOW)

    endif else begin

        reply = dialog_message( $
                    'Data must be retrieved before plotting it', $
                    title='Get Plot Operation', /center, /error)
    endelse
end


;+
; Responds to an event requesting the CDAWlib's listing of the retrieved
; data specified by the users previous selections.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spdfCreateCdawebListing, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    widget_control, state.dataVarName, get_value=dataVarName

    if n_elements((scope_varFetch(dataVarName, /enter, level=1))) then begin

        filename = dialog_pickfile(default_extension='txt', $
                       filter=['*.txt', '*.asci'], $
                       /overwrite_prompt, /write)

        if filename ne '' then begin

            ; make a copy of the data for list_mystruct to destroy
            copyOfData = scope_varFetch(dataVarName, level=1)

            listing = list_mystruct(copyOfData, filename=filename[0])

            xdisplayfile, filename[0], group=event.top

        endif

    endif else begin

        reply = dialog_message( $
                    'Data must be read before listing it', $
                    title='Get Plot Operation', /center, /error)
    endelse
end


;+
; Responds to an event that initiates a termination of this program.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spdfExit, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    obj_destroy, state.errorDialog
    obj_destroy, state.authenticator
    obj_destroy, state.cdas
    obj_destroy, state.dataviews
    ptr_free, state.selectedDataview
    ptr_free, state.observatoryGroups
    ptr_free, state.instrumentTypes
    if n_elements(*state.datasets) then obj_destroy, *state.datasets
    ptr_free, state.datasets
    ptr_free, state.selectedDataset
    ptr_free, state.saveData

; file_delete Notes?.html files

heap_gc

    widget_control, event.top, /destroy
end


;+
; Display information about this software.
;
; @param event {in} {type=widget_button}
;            event triggering the execution of this procedure.
;-
pro spdfAbout, $
    event
    compile_opt idl2

    widget_control, event.top, get_uvalue=state

    reply = dialog_message([ $
        'NASA/Goddard Space Flight Center (GSFC)',$
        'Space Physics Data Facility (SPDF)', $
        'https://spdf.gsfc.nasa.gov/', $
        '', $
        'Current CDAWlib version: ' + version(), $
        'Current SpdfCdas version: ' + state.cdas->getVersion()], $
        title='About', /center, /information)
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
function spdfGetDataviews, $
    cdas
    compile_opt idl2

    if ~(cdas->isUpToDate()) then begin

        reply = dialog_message([ $
            'Current CDAWlib version: ' + version(), $
            'Current SpdfCdas version: ' + cdas->getVersion(), $
            'Available SpdfCdas version: ' + cdas->getCurrentVersion(), $
            'There is a newer version of the SpdfCdas library available.'], $
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
; Provides a GUI for choosing and retrieving data from 
; <a href="https://cdaweb.gsfc.nasa.gov/">CDAWeb</a>.
; 
; If access to the Internet is through an HTTP proxy, the caller 
; should ensure that the HTTP_PROXY environment is correctly set 
; before this procedure is called.  The HTTP_PROXY value should be of 
; the form 
; http://username:password@hostname:port/.
;
; @keyword endpoint {in} {optional} {type=string}
;              {default=SpdfCdas->getDefaultEndpoint()}
;              URL of CDAS web service.
; @keyword GROUP_LEADER {in} {optional} {type=int}
;              The widget ID of the group leader for this window.  If
;              no value is provided, the resulting window will not
;              belong to a group and will be non-blocking.
;-
pro spdfCdawebChooser, $
    endpoint = endpoint, $
    GROUP_LEADER = groupLeaderWidgetId
    compile_opt idl2

    cd, current=cwd
    if ~file_test(cwd, /write) then begin

        print, 'Error: The current working directory (', $
                       cwd, ') is not writable.'
        print, 'Downloaded files are saved in the current working directory.'
        print, 'Use the IDL CD procedure to change the current working'
        print, 'directory to one that is writable and then re-run'
        print, 'SpdfCdawebChooser.'
        return
    endif

; This is suppose to help with getting windows placed better in a
; multi-monitor environment but it doesn't seem to for an 
; "extended desktop".
;    monitorInfo = obj_new('IDLsysMonitorInfo')


    if keyword_set(groupLeaderWidgetId) then begin

        tlb = widget_base(title='CDAWeb Data Chooser', /column, $
                          GROUP_LEADER=groupLeaderWidgetId)
        defaultSaveCdfOption = 1
    endif else begin

        tlb = widget_base(title='CDAWeb Data Chooser', /column)
        defaultSaveCdfOption = 0
    endelse

    cdas = $
        obj_new('SpdfCdas', $
        endpoint=endpoint, $
        userAgent='CdawebChooser')

    dataviews = spdfGetDataviews(cdas)

    if ~obj_valid(dataviews[0]) then begin

        reply = dialog_message( $
                    ['Could not connect to CDAWeb.', $
                     'Please check Internet connectivity to ', $
                     'https://cdaweb.gsfc.nasa.gov/.'], $
                    title='Network Error', /center, /error)
        return
    endif

    initialDvSelection = 0

    dvTitles = strarr(n_elements(dataviews))
    for i = 0, n_elements(dataviews) - 1 do begin
        dvTitles[i] = dataviews[i]->getTitle()
        if dataviews[i]->getId() eq 'sp_phys' then begin
            initialDvSelection = i
        endif
    endfor
  
    ;
    ; Dataview selection panel
    ;
    dvBase = widget_base(tlb, frame=3, /column)
    dvLabel = widget_label(dvBase, /align_left, $
                  value='Dataview Selection: ')
    dvList = widget_combobox(dvBase, event_pro='spdfDataviewSelected', $
                 value=dvTitles)

    ;
    ; Dataset selection panel
    ;
    datasetSelectionPanel = widget_base(tlb, frame=3, /column)
    
    datasetSelectionLabel = $
        widget_label(datasetSelectionPanel, /align_left, $
            value='Dataset Selection:')

    miPanel = widget_base(datasetSelectionPanel, /row)

    missionGroups = ['']
    missionGroupsPanel = widget_base(miPanel, /column)
    mLabel = widget_label(missionGroupsPanel, value='Mission Groups')
    mList = widget_list(missionGroupsPanel, $
                event_pro='spdfIgnoreSelected', $
                value=missionGroups, xsize=50, ysize=7, /multiple)

    instrumentTypes = ['']
    instrumentTypesPanel = widget_base(miPanel, /column)
    iLabel = widget_label(instrumentTypesPanel, $
                 value='Instrument Types')
    iList = widget_list(instrumentTypesPanel, $
                event_pro='spdfIgnoreSelected', $
                value=instrumentTypes, xsize=50, ysize=7, /multiple)

    dsButton = widget_button(datasetSelectionPanel, $
                   /align_left, $
                   event_pro='spdfFindDatasets', $
                   value='Find Datasets', $
                   tooltip='Find datasets for the specified mission groups and instrument types')


    ;
    ; Data selection panel
    ;
    dataSelectionPanel = widget_base(tlb, frame=3, /column)

    dataSelectionLabel = $
        widget_label(dataSelectionPanel, /align_left, $
            value='Data Selection:')

    dsLabel = widget_label(dataSelectionPanel, $
                  value='Datasets/Variables')
    dsTree = widget_tree(dataSelectionPanel, /multiple, $
                 /context_events, event_pro='spdfDatasetTreeEvent', $
                 xsize=600, ysize=240)

    dsContextMenu = widget_base(tlb, /context_menu)

    viewNotesButton = widget_button(dsContextMenu, $
                          event_pro='spdfViewNotes', $
                          value="View Notes")
    viewInventoryButton = widget_button(dsContextMenu, $
                      event_pro='spdfViewInventory', $
                      value="View Inventory")


    timePanel = widget_base(dataSelectionPanel, /row)

    defaultTimeButton = widget_button(timePanel, $
                      event_pro='spdfDefaultTime', $
                      value="Set Default Time")
    startTime = cw_field(timePanel, title='Start Time')
    stopTime = cw_field(timePanel, title='Stop Time')
    timeFormatLabel = widget_label(timePanel, $
                          value='Format YYYY/MM/DD[ HH:MM:SS]')

    ;
    ; Data operation panel
    ;
    dataOperationPanel = widget_base(tlb, frame=3, /column)

    dataOperationLabel = $
        widget_label(dataOperationPanel, /align_left, $
            value='Data Operation:')

    optionPanel = widget_base(dataOperationPanel, /row)

    dataVarName = cw_field(optionPanel, title='Variable Name', $
                      value='data')
    saveCdfOption = cw_bgroup(optionPanel, $
                    ['Save local CDF files'], $
                    /nonexclusive, /frame, $
                    label_left='File Option', $
                    event_funct='spdfSaveDataButton', $
                    set_value=[defaultSaveCdfOption])

    actionPanel = widget_base(dataOperationPanel, /row)
    dataButton = widget_button(actionPanel, $
                     event_pro='spdfGetCdawebData', $
                     value='Get CDAWeb Data', $
                     tooltip='Read CDAWeb data into IDL environment')
    idlButton = widget_button(actionPanel, $
                     event_pro='spdfGetCdawebDataIdl', $
                     value='Show Get Data IDL', $
                     tooltip='Display IDL code to get data')
    fileButton = widget_button(actionPanel, $
                     event_pro='spdfReadLocalData', $
                     value='Read Local CDF', $
                     tooltip='Read data from local file into IDL environment')
    plotButton = widget_button(actionPanel, $
                     event_pro='spdfGetCdawebPlot', $
                     value='Show CDAWlib Plot', $
                     tooltip="Display CDAWlib's plot of the data")
    listButton = widget_button(actionPanel, $
                     event_pro='spdfCreateCdawebListing', $
                     value='Create CDAWlib Listing', $
                     tooltip="Create CDAWlib's listing of the data")

    bottomPanel = widget_base(tlb, frame=3, row=1)
    ;
    ; Program control panel
    ;
    programControlPanel = widget_base(bottomPanel, /column)

    programControlLabel = $
        widget_label(programControlPanel, /align_left, $
            value='Window Control:')

    exitButton = widget_button(programControlPanel, /align_left, $
                     event_pro='spdfExit', $
                     value='Close', tooltip='Close this window')

; this button needs to be positioned better
;    aboutButton = widget_button(bottomPanel, /align_right, $
;                     event_pro='spdfAbout', $
;                     value='About', tooltip='About this software')

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
        saveData:ptr_new(defaultSaveCdfOption) $
    }

    widget_control, tlb, set_uvalue=state, /realize

    if keyword_set(groupLeaderWidgetId) then begin

        xmanager, 'SpdfCdawebChooser', tlb, $
            group_leader=groupLeaderWidgetId

    endif else begin

        xmanager, 'SpdfCdawebChooser', tlb, /no_block

    endelse

    spdfSelectDataview, tlb, dvList, initialDvSelection

end
