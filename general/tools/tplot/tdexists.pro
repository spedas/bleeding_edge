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
;    This routine always returns 0 if the size(d.y,/n_dim) gt 3
;    Where d is the data struct of a tplot variable
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2008-05-21 16:19:20 -0700 (Wed, 21 May 2008) $
; $LastChangedRevision: 3144 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/tdexists.pro $
;-

function tdexists,tvarname,start_time,end_time,dims=dims

  compile_opt idl2

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
        
        if (size(d.y,/n_dim) eq 0) then begin
          y = d.y
        endif else if(size(d.y,/n_dim) eq 1) then begin
          y = d.y[idx]
        endif else if (size(d.y,/n_dim) eq 2) then begin
          y = d.y[idx,*]
        endif else if (size(d.y,/n_dim) eq 3) then begin
          y = d.y[idx,*,*]
        endif else begin
          return,0
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

