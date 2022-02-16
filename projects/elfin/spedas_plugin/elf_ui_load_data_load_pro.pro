;+
;NAME:
;  elf_ui_load_data_load_pro
;
;PURPOSE:
;  This routine provides an example for loading data into the GUI from the load
;  data panel. The purpose of this routine is to provide a wrapper around the 
;  actual load data procedure (which is mission specific). This routine handles
;  all the 'administrative' work of validating times, checking if data exists,
;  and adding the data to the GUI's loadedData object. The loadedData object 
;  loads and tracks all data that is available to the GUI. 
;
; INPUT:
;  loadStruc - this structure contains all the mission specific information that
;              is required by the procedure that loads the data. 
;              For purposes of demonstration, this rouine uses the following 
;              parameters:
;              instrument - character string (or array) containing the name of
;                           the instrument such as 'fgm', 'epd', 'mrma', 'mrmi,
;                           or 'state'
;              datatype - dependent on instrument and level
;              time range - an array of 2 character strings containing the 
;                           start and stop times of the data to be loaded.
;                           ['2007-03-23/00:00:00', '2007-03-24/00:00:00']       
;  loadedData - the loaded data object contains information on all variables 
;               currently loaded in the gui. This object is used by many other
;               panels to display the variables that are available to the GUI.
;               Whenever new data is imported to the GUI this object must be 
;               updated.
;  statusBar - the status bar object used to display textual information 
;              for the user and is located at the bottom of the load windows.
;              This object can be used to inform the user of successful 
;              executions, warnings, and/or errors. 
;  historyWin - the history window object displays all messages generated 
;               during this session.
;  parent_widget_id - the widget ID of the parent. This ID is needed for 
;                     appropriate layering and modality of popups
;  
;  KEYWORDS (OPTIONAL):
;  replay - set this flag to replay previous dproc operations 
;  overwrite - this flag allows the replay of user overwrites
;  
;HISTORY:
;
;;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/tags/spedas_1_00/spedas/gui/api_examples/load_data_tab/elf_ui_load_data_load_pro.pro $
;
;--------------------------------------------------------------------------------

pro elf_ui_load_data_load_pro,$
                         loadStruc,$
                         loadedData,$
                         statusBar,$
                         historyWin,$
                         parent_widget_id,$  
                         replay=replay,$
                         overwrite_selections=overwrite_selections
                         
  compile_opt hidden,idl2
  
  ; initialize variables
  loaded = 0
  new_vars = ''
  overwrite_selection=''
  overwrite_count =0
  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif

  ; extract the variables from the load structure
  probes=loadStruc.probes
;  coordinate=loadStruc.coordinate
  instrument=loadStruc.instrument
;  level=loadStruc.level
  types=loadStruc.types
  timeRange=loadStruc.timerange

  ; **** Specify the starting and ending time ranges for this mission *****
  ; **** this should be modified for each new mission *****
  elfmintime = '1970-01-01'
  elfmaxtime = '2050-12-31'
  
  ; in this example data is loaded into temporary tplot variables. But first
  ; tplot names that already exist are noted so that later in the procedure 
  ; when the code is deleting the temporary tplot variables the previous 
  ; ones will not get clobbered.
  tn_before = [tnames('*',create_time=cn_before)]

  ; ***** This is the routine that loads the actual data *****
  ; ***** This routine is provided by each mission ***** 
  ; ***** Parameters for the load routines will vary per mission *****
  varformat = '*'+types
  
  Case instrument of
     'epd':  begin
       ptype=strmid(types,0,3)
       dtype=strmid(types,4)
       elf_load_epd, probes=probes, datatype=ptype, type=dtype, trange=timeRange
     end
     'state': elf_load_state, probes=probes, datatype=types, trange=timeRange
     'fgm':   elf_load_fgm, probes=probes, datatype=types, trange=timeRange
     'mrma':   elf_load_mrma, probes=probes, trange=timeRange
     'mrmi':   elf_load_mrmi, probes=probes, trange=timeRange

;     'eng':   elf_load_eng, probes=probes, datatype=types, level=level, trange=timeRange
;     else:    elf_load_data, probes=probes, instrument=instrument, datatype=types, level=level, $
;                  trange=timeRange, varformat=varformat
  endcase
  
  ; determine which tplot variables to delete and which ones are the new temporary 
  ; variables
  spd_ui_cleanup_tplot, tn_before, create_time_before=cn_before, del_vars=to_delete,$
                        new_vars=new_vars

  if new_vars[0] ne '' then begin
    loaded = 1
  
    ; loop over loaded data
    for i = 0,n_elements(new_vars)-1 do begin
    
      ; check if data is already loaded, if so query the user on whether they want to overwrite data
      spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin, $
        overwrite_selection,overwrite_count,replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue
      
      ; this statement adds the variable to the loadedData object
      result = loadedData->add(new_vars[i],mission='elf', $            ;,observatory=probe, $
                               instrument=instrument)
      
      ; report errors to the status bar and add them to the history window
      if ~result then begin
        statusBar->update,'Error loading: ' + new_vars[i]
        historyWin->update,'ELFIN: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif
   
  ; here's where the temporary tplot variables are removed
  if to_delete[0] ne '' then begin
     store_data,to_delete,/delete
  endif
  
  ; inform the user that the load was successful and add it to the history   
  if loaded eq 1 then begin  
     statusBar->update,'ELFIN Data Loaded Successfully'
     historyWin->update,'ELFIN Data Loaded Successfully'
  endif else begin
 
     ; if the time range specified by the user is not within the time range 
     ; of available data for this mission and instrument then inform the user 
     if time_double(elfmaxtime) lt time_double(timerange[0]) || $
        time_double(elfmintime) gt time_double(timerange[1]) then begin
        statusBar->update,'No ELFIN Data Loaded, ELFIN data is only available between ' + elfmintime + ' and ' + elfmaxtime
        historyWin->update,'No ELFIN Data Loaded, ELFIN data is only available between ' + elfmintime + ' and ' + elfmaxtime
     endif else begin   
        statusBar->update,'No ELFIN Data Loaded'
        historyWin->update,'No ELFIN Data Loaded'
     endelse
    
  endelse
end
