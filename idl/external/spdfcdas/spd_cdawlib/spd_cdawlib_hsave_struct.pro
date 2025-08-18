;Author: johnson $
;Date: 2013/09/06 17:17:44 $
;Header: /home/cdaweb/dev/control/RCS/hsave_struct.pro,v 1.3 2013/09/06 17:17:44 johnson Exp kovalick $
;Locker: kovalick $
;Revision: 1.3 $
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
; Utilize IDL's SAVE procedure to save the structure a into the given filename.
;If data is stored in handles, make .dat structure tags and extract
;the data from the handles and put into the .dat tags, then wipe out
;the .handle tags.
FUNCTION spd_cdawlib_hsave_struct,a,fname, debug=debug, nosave=nosave
 
if SIZE(a, /type) ne 8 then return,a 

if (spd_cdawlib_tagindex('HANDLE',tag_names(a.(0))) eq -1) then begin
  if (not(keyword_set(nosave)))then begin ;save the buffer to the save file
    ; data is stored directly in the structure
    SAVE,a,FILENAME=fname
    endif else begin ;return the structure as is, since the data is already in the .dat tags
      return, a
    endelse

endif else begin
  ; data is stored in handles.  Retrieve the data from the handles,
  ; create .dat and re-create the structure, then SAVE to file.
  tn = tag_names(a)
  nt = n_elements(tn)

  for i=0,nt-1 do begin ; retrieve each handle value    
     handle_value,a.(i).HANDLE,data
     a.(0).handle = 0
     tmp = create_struct(a.(i),'dat',data)
     if (i eq 0) then data_buf = create_struct(a.(i).varname, tmp) else $
     data_buf = create_struct(data_buf, a.(i).varname, tmp)
   endfor

  if (not(keyword_set(nosave)))then begin ;save the buffer to the save file
    ; Add the filename keyword to save command
    if keyword_set(debug) then print, 'Saving data contents to ',fname    
    SAVE,data_buf,FILENAME=fname ; execute the save command
  endif else begin ;otherwise return the buffer to the calling program
    return, data_buf
  endelse
endelse
end

