pro save_marker_list,windowstorage=windowstorage,filename=filename,statuscode=statuscode,statusmsg=statusmsg

tgt_dirname=file_dirname(filename)

fi=file_info(tgt_dirname)
if ~fi.exists then begin
   statusmsg=string(tgt_dirname,format='("save_marker_list: Save failed. Directory ",A," does not exist.")')
   statuscode=-1
   return
endif else if ~fi.write then begin
   statusmsg=string(tgt_dirname,format='("save_marker_list: Save failed. Directory ",A," is not writeable by you.")')
   statuscode=-1
   return
endif

fi=file_info(filename)
if (fi.exists AND ~fi.write) then begin
   statusmsg=string(filename,format='("save_marker_list: Save failed. File ",A," exists, and is not writeable by you.")')
   statuscode=-1
   return
end else if (fi.exists) then begin
   statusmsg=string(filename,format='("save_marker_list: File ",A," already exists. Do you wish to overwrite it?")')
   answer=dialog_message(statusmsg,/question,/default_no)
   if (answer NE 'Yes') then begin
      statusmsg='save_marker_list: Save cancelled by user.'
      statuscode=-1
      return
   endif
 
endif

; Get marker list

cwindow=windowstorage->getactive()

if ~obj_valid(cwindow[0]) then begin
   statuscode=-1
   statusmsg='save_marker_list: no active window!'
   return
endif

cwindow[0]->GetProperty,panels=panels

if obj_valid(panels) then begin
   ; We can't make a zero-element array, so start with one garbage object
   marker_array=objarr(1)
   panelObjs=panels->Get(/all)
   if ~is_num(panelObjs) then begin
      for i=0,n_elements(panelObjs)-1 do begin
         panelobjs[i]->GetProperty,Marker=markers
         ; markers is an IDL container of marker objects
         panel_markers=markers->get(/all,count=count)
         ; update marker_array with any markers from this panel
         if (count gt 0) then marker_array=[marker_array,panel_markers]
      endfor
   endif else begin
      statuscode=-1
      statusmsg='save_marker_list: no panels in panel object!'
      return
   endelse
endif else begin
   statuscode=-1
   statusmsg='save_marker_list: no panels object for active window!'
   return
endelse

; marker_array now has one garbage object plus whatever markers were
; found in the active window

if (n_elements(marker_array) EQ 1) then begin
   statuscode=-1
   statusmsg='save_marker_list: no markers found!'
   return
endif else begin
   ; get rid of initial garbage object
   marker_array=marker_array[1:*]
endelse

; Open file
openw,lun,filename,/get_lun

; Write markers

printf,lun,'("<MarkerList>")'
printf,lun,n_elements(marker_array),format='("count = ",I)'
for i=0, n_elements(marker_array)-1 do begin
    marker_array[i]->write,lun
endfor
printf,lun,'("</MarkerList>")'

; Cleanup and return success
free_lun,lun
statuscode=0
statusmsg=STRING(filename,format='("Marker list successfully saved to ",A)')
return
end
