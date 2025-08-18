;+
;NAME:
;  omni_ui_import_data
;
;PURPOSE:
;  This routine provides an example for loading data into the GUI from the load
;  data panel. The purpose of this routine is to provide a wrapper around the actual 
;  load data procedure (which is mission specific). This routine handles all the 
;  'administrative' work of validating times, checking if data exists, and adding the 
;  data to the GUI's loadedData object. The loadedData object loads and tracks
;  all data that is available to the GUI. 
;
;HISTORY:
;
;;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-22 15:41:37 -0700 (Wed, 22 Apr 2015) $
;$LastChangedRevision: 17398 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/omni/omni_ui_import_data.pro $
;
;--------------------------------------------------------------------------------

pro omni_ui_import_data,$
                         loadStruc, $
                         loadedData,$
                         statusBar,$
                         historyWin,$
                         parent_widget_id,$  ;needed for appropriate layering and modality of popups
                         replay=replay,$
                         overwrite_selections=overwrite_selections ;allows replay of user overwrite selections from spedas 

  compile_opt hidden,idl2

  ; initialize variables
  res=loadStruc.res   
  datatypes=loadStruc.datatypes
  timerange=loadStruc.timerange
  loaded = 0
  new_vars = ''
  overwrite_selection=''
  overwrite_count =0
  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif
  
  ; **** Specify the starting and ending time ranges for this mission *****
  ; **** this should be modified for each new mission *****
  omnimintime = '1970-01-01'
  omnimaxtime = '2050-12-31'
  
  ; in this example data is loaded into temporary tplot variables. the existing
  ; tplot names are determined before the load so that later in the procedure 
  ; when the code is deleting the temporary tplot variables the previous ones will
  ; not get clobbered as well
  tn_before = [tnames('*',create_time=cn_before)]

  ; ***** This is the routine that loads the actual data *****
  ; ***** This routine is provided by each mission ***** 
  min1res=0
  min5res=0
  FOR i=0, n_elements(res)-1 DO BEGIN
      IF strpos('5min',res[i]) GT -1 THEN min5res=1
      IF strpos('1min',res[i]) GT -1 THEN min1res=1
  ENDFOR
 
  IF min5res EQ 1 THEN omni_load_data, res5min=1, trange=timeRange
  IF min1res EQ 1 THEN omni_load_data, trange=timeRange
   
  ; determine which tplot vars to delete and which ones are the new temporary vars
  spd_ui_cleanup_tplot, tn_before, create_time_before=cn_before, del_vars=to_delete,$
                        new_vars=new_vars

  if time_double(omnimaxtime) lt time_double(timerange[1]) || $
      time_double(omnimintime) gt time_double(timerange[0]) then begin
      statusBar->update,'No OMNI Data Loaded, OMNI data is only available between ' + omnimintime + ' and ' + omnimaxtime
      historyWin->update,'No OMNI Data Loaded, OMNI data is only available between ' + omnimintime + ' and ' + omnimaxtime
  endif else begin
      if new_vars[0] ne '' then begin
        loaded = 1
        
        ; loop over loaded data
        for i = 0,n_elements(new_vars)-1 do begin
          ; check if data is already loaded, if so query the user on whether they want to overwrite data
          spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
                                     replay=replay,overwrite_selections=overwrite_selections
          if strmid(overwrite_selection, 0, 2) eq 'no' then continue

          ; this statement adds the variable to the loadedData object which is
          ; used by many other panels to display the variables that are available to the GUI
          result = loadedData->add(new_vars[i],mission='omni',observatory='omni',instrument='omni')
            
          ; report errors to the status bar and add them to the history window
          if ~result then begin
            statusBar->update,'Error loading: ' + new_vars[i]
            historyWin->update,'OMNI: Error loading: ' + new_vars[i]
            return
          endif
        endfor
      endif
  endelse

  ; here's where the temporary tplot variables are removed
  if to_delete[0] ne '' then begin
     store_data,to_delete,/delete
  endif
  
  ; inform the user that the load was successful and add it to the history   
  if loaded eq 1 then begin
     statusBar->update,'OMNI Data Loaded Successfully'
     historyWin->update,'OMNI Data Loaded Successfully'
  endif

end
