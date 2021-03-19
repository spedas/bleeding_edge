;+
;function: tdexists
;
; purpose: Checks to see if a tplot variable exists and if its data
; exists. Exists means that there is data on the specified interval
; and that the data is not all NaNs
; 
; Inputs:
; 
; tvarname: A name or names to be checked(accepts type globs)
; start_time: a start datetime for the interval
; end_time: an end datetime for the interval
;
; Keywords: 
;
;  dims: set this keyword to a number if you want the function also to verify that
;    the data has that number of elements in its second dimension.  For
;    example, if you set dims = 3, it will verify that the y component
;    of the tplot variable is Nx3.
; 
; 
; NOTES:
;    If you pass in a list of variables, this routine will return 0 if
;    any of them do not exist or they do not have data on the
;    interval.
;    If you use globbing, it will return 0 if no variables match the
;    glob and 0 if any of the variables that match the glob do not
;    have data on the interval. 
;    On the other hand, if, for example,
;    you expect that 2 variables should match the glob, but only one is
;    present or only one matches and that has data, it will return
;    true, because it cannot predict how many variables you expect to
;    exist if you do not explictly specify them.
;
;    For data types with the number of y dimensions > 6, false positives may result
;    if the Y array has some finite values, but all of them are outside the time range of interest.
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-03-18 16:49:04 -0700 (Thu, 18 Mar 2021) $
; $LastChangedRevision: 29776 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/tdexists.pro $
;-

function tdexists,inp_tvarname,start_time,end_time,dims=dims

  compile_opt idl2

  ; Avoid clobbering input variable
  tvarname=inp_tvarname
  
  if n_elements(tvarname) eq 1 then begin
     tvarname = strsplit(tvarname[0],/extract)
  endif else if n_elements(tvarname) eq 0 then begin
     message,'incorrect arguments to data exists'
  endif
  
  if ~keyword_set(start_time) || ~keyword_set(end_time) then begin
    message,'start time & end time must be set in calls to data_exists'
  endif
  
  for j=0,n_elements(tvarname)-1 do begin

     name_list = tnames(tvarname[j])

     if n_elements(name_list) eq 1 && name_list[0] eq '' then return, 0
    
     for i = 0,n_elements(name_list)-1 do begin
    
        get_data,name_list[i],data=d
  
        if ~is_struct(d) then return, 0
  
        str_element,d,'x',success=s
  
        if ~s then return, 0
  
        str_element,d,'y',success=s
  
        if ~s then return, 0
  
        idx = where(d.x ge time_double(start_time) and d.x le time_double(end_time))
  
        if idx[0] eq -1L then return, 0
        
        x = d.x[idx]
        
        ; The intention here is to filter out any values outside the time range of interest, before checking
        ; for NaNs.   Unfortunately, this can't be done concisely for an arbitrary number of array dimensions.
        ; I've added cases for 4-d arrays to accomodate certain MMS data types, and 5- and 6-d arrays in the 
        ; interest of future-proofing.  For even higher dimensions, any finite values (even outside the time 
        ; range of interest) will be accepted, so the possibility of a false positive exists when there are finite
        ; values, but all of them are outside the time range of interest.  JWL 2021-03-18
        
        if (size(d.y,/n_dim) eq 0) then begin
          y = d.y
        endif else if(size(d.y,/n_dim) eq 1) then begin
          y = d.y[idx]
        endif else if (size(d.y,/n_dim) eq 2) then begin
          y = d.y[idx,*]
        endif else if (size(d.y,/n_dim) eq 3) then begin
          y = d.y[idx,*,*]
        endif else if (size(d.y,/n_dim) eq 4) then begin
          y = d.y[idx,*,*,*]
        endif else if (size(d.y,/n_dim) eq 5) then begin
          y = d.y[idx,*,*,*,*]
        endif else if (size(d.y,/n_dim) eq 6) then begin
          y = d.y[idx,*,*,*,*,*]
        endif else begin
          ; Just test the whole array, even values outside the time range of interest.  False positives are possible.
          y = d.y
        endelse
   
        id = where(finite(y))
  
        if id[0] eq -1L then return, 0
  
        dsz = size(d.y,/dimensions)
  
        if dsz[0] ne n_elements(d.x) then return, 0
  
        if keyword_set(dims) then begin
  
           if dims eq 1 && n_elements(dsz) ne 1 then begin 
              return, 0
           endif else if n_elements(dsz) ne 2 then begin 
              return, 0
           endif else if dims ne dsz[1] then begin
              return, 0
           endif   
    
        endif
    
     endfor

  endfor
  
  return, 1
  
end

