;+
; Name:
;    dsc_ui_check_overwrite_data
;
; Purpose:
;    Used to check if data is already loaded in the GUI and queries the 
;    user to see if they want to overwrite data if it is already loaded.
;
;    This code was originally repeated in basically every load routine, so the
;    purpose for this routine is to avoid repeated code
;    
; Input:
;    new_var: the new variable 
;    loadedData: the loadedData object
;    gui_id: widget ID of the parent widget
;    statusBar: status bar object
;    historyWin: history window object
;    overwrite_selection: user's selection for the current query 
;    overwrite_count: tracking the number of overwrites for saving/replaying SPEDAS documents
;    
; Output:
;    isnew: Return flag to note whether the variable is new - indicating that the prompt response is not relevant
; 	 
; Keywords:
;    replay: set by the calling routine if the user is replaying a SPEDAS document
;    overwrite_selections: an array containing the user's selections
;
; Notes:
; 	Modified from spd_ui_check_overwrite_data to include the 'isnew' return flag
; 	
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/spedas_plugin/dsc_ui_check_overwrite_data.pro $ 	
;--------------------------------------------------------------------------------
pro dsc_ui_check_overwrite_data,new_var,loadedData,gui_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
		replay=replay,overwrite_selections=overwrite_selections,isnew=isnew
		
	compile_opt idl2,hidden
		
	; check if the new variable exists in the loaded data object
	if loadedData->isParent(new_var) then begin
		isnew = 0
		if overwrite_selection ne 'yestoall' AND overwrite_selection ne 'notoall' then begin
			 if keyword_set(replay) then begin
					if overwrite_count ge n_elements(overwrite_selections) then begin
						;report errors to both the status bar and history window
						historywin->update,"ERROR: Discrepancy in spedas document, may have lead to a document load error"
						statusbar->update,"ERROR: Discrepancy in spedas document, may have lead to a document load error"
						overwrite_selection = "yestoall"
					endif else begin
						overwrite_selection = overwrite_selections[overwrite_count]
					endelse
			 endif else begin
					prompttext='The variable ' + strupcase(new_var) + ' already exists.  Do you want to ' + $
								'overwrite it with the new variable?  If you click "No" the new ' + strupcase(new_var) + ' will not be loaded.'
			
					overwrite_selection = spd_ui_prompt_widget(gui_id,statusBar,historyWin,promptText=prompttext,defaultValue='',/yes,/no,/allyes,/allno,maxwidth=80,$
								title="Overwrite Data?", frame_attr=8)
					overwrite_selections = array_concat_wrapper(overwrite_selection, overwrite_selections)
			 endelse
			 overwrite_count++
		endif
				
		if overwrite_selection eq 'yes' OR overwrite_selection eq 'yestoall' then begin
			h = strupcase(new_var) + ' will be overwritten.'
			historyWin->Update, h
			statusbar->Update, h
		endif
		if overwrite_selection eq 'no' OR overwrite_selection eq 'notoall' then begin
			h = strupcase(new_var) + ' not loaded into GUI to prevent overwrite of existing GUI data.'
			historyWin->Update, h
			statusbar->Update, h      
			return
		endif
	endif else isnew = 1
end
