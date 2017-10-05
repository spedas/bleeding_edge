;+ 
;Name:
;  spd_ui_cotrans
;
;Purpose:
;  Performs coordinate transformations on GUI data
;
;Input:
;  tlb:  top level widget ID
;  out_coord:  string storing the destination coordinate system
;  active:  string array of variables to be transformed
;  loadedData:  the loadedData object
;  callSequence:  the call sequence object for replaying SPEDAS documents.
;  sobj:  status bar object
;  historywin:  history window object  
;  replay:  This keyword determines whether operations are pushed 
;           onto the call sequence and whether popups are displayed
;  tvar_overwrite_selections:  Set this keyword when the replay keyword is set.
;                              It should contain an array of what overwrite selection 
;                              was made for each processed variable.
;
;Output:
;  none
;
;Notes:
;  -If successful all previous active data variables will be replaced with
;   their transformed copies.
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2017-08-25 16:18:12 -0700 (Fri, 25 Aug 2017) $
;$LastChangedRevision: 23832 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/cotrans/spd_ui_cotrans.pro $
;
;---------------------------------------------------------------------------------

pro spd_ui_cotrans, tlb, $
                    out_coord, $
                    active, $
                    loadedData, $
                    sobj, $
                    historywin, $
                    callSequence, $
                    replay=replay, $
                    tvar_overwrite_selections=tvar_overwrite_selections

compile_opt idl2, hidden


; no children traces will hold support data so we don't bother either
all = loadedData->getAll(/parent)

;get valid coordinates
coordSysObj = obj_new('spd_ui_coordinate_systems')
validcoords = coordSysObj->makeCoordSysList()
obj_destroy, coordSysObj
 
;remember "Yes to all" and "No to all" decisions for state load queries
yesall = 0
noall = 0

;existing variable overwrite for replay 
tvar_overwrite_selection =''
tvar_overwrite_count = 0

if ~keyword_set(replay) then begin
  tvar_overwrite_selections=''
endif
 
if ~keyword_set(active) then begin
  sobj->update, 'No Active Data selected.'
  return
endif
 
;keep track of all preexisting tplot vars
tn_before = tnames('*')

for i = 0,n_elements(active)-1 do begin
  
  sobj->update, 'Coordinate Transforming: ' + active[i]

  ;reset names
  out_name = ''
  name = active[i]

  ;export data to tplot variable
  tname = loadedData->getTvarData(name)

  ;get input coords
  loadedData->getdatainfo, name, coordinate_system=in_coord

  ;skip if variable is not a 3-vector
  ;this is checked in spd_cotrans but checking here allows for a pop-up message
  get_data,name,data=dTest
  dDim = dimen(dTest.y)
  if n_elements(dDim) ne 2 || dDim[1] ne 3 then begin
    errors = array_concat(name + ':  Data is not a 3-vector.', errors)
    continue
  endif

  ;check input coord validity
  if ~in_set(strlowcase(in_coord),validcoords) then begin
    errors = array_concat(name + ':  Input coordinates not recognized.  ' + $
                                'See "More..." menu for mission-specific cotrans tools.  ' + $
                                'Verify coordinates with File > Manage Data.', errors)
    continue
  endif

  out_suffix = '_'+strlowcase(out_coord)
  in_suffix = ''
  in_name = name
     
  ;break name into base and suffix
  for j = 0,n_elements(validCoords)-1 do begin
    if (pos = stregex(name,'_'+validCoords[j]+'$',/fold_case)) ne -1 then begin
      in_suffix = '_'+ validCoords[j]
      in_name = strmid(name,0,pos)
      break
    endif
  endfor

  ;perform transformation    
  catch,err
  if err ne 0 then begin
    catch,/cancel
    if ~keyword_set(replay) then begin
      ok = error_message('Unexpected cotrans error, see console output.',/traceback,/center,title='Coordinate Transform Error')
    endif
    spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
    store_data,to_delete,/delete
    return
  endif else begin
  
    spd_cotrans, in_name, $
                 in_coord=in_coord, $
                 out_coord=out_coord, $
                 in_suffix=in_suffix, $
                 out_suffix=out_suffix, $
                 out_vars=out_var
  
  endelse
  catch,/cancel
  
  ;check for output vars
  if keyword_set(out_var) then begin
    sobj->update,String('Successfully transformed variable to: ' + out_var[0])
  endif else begin
    sobj->update,String('Data not transformed: '+name)
    continue
  endelse
  
  ;add output to the GUI
  spd_ui_check_overwrite_data,out_var[0],loadedData,tlb,sobj,historyWin,tvar_overwrite_selection,tvar_overwrite_count,$
                         replay=replay,overwrite_selections=tvar_overwrite_selections
                         
  if ~loadedData->add(out_var[0]) && ~keyword_set(replay) then begin
    ok = error_message('Unknown error adding data',traceback=0,/center,title='Coordinate Transform Error')
  endif
        
  loadedData->clearActive,name
  loadedData->setActive,out_var
  
endfor


;clean up new tplot vars
spd_ui_cleanup_tplot, tn_before, del_vars=to_delete
store_data, to_delete, /delete

;add this operation to the call sequence
if ~keyword_set(replay) then begin
  callSequence->addCotransOp, out_coord, active, tvar_overwrite_selections
endif

;inform user of any errors
if ~undefined(errors) then begin
  text = ['Some errors were encountered; the following data was not transformed:  ',errors]
  spd_ui_message, strjoin(text,ssl_newline()), title='Skipped variables', dialog=~keyword_set(replay), hw=historywin
endif
       
 
end
