;+
;Procedure: time_clip
;
;Purpose: clips a tplot variable between a start time and an end time
;
;Inputs:   tplot_var_name: the name of the variable to be clipped
;       
;          start_time: the start time for the clipping(double or string)
;
;          end_time: the end time for the clipping(double or string)
;
;Keywords:
;          newname(optional): the name of the output tplot variable
;                   otherwise it will be tplot_var_name+'_tclip'
;
;          tvar(optional): set this keyword and start_time and
;          end_time will be interpreted as the names of tplot variables
;          The start and end times will then be taken from the first
;          and last component of the tplot variables listed
;          
;          replace(optional): set this to replace the tplot variable,  rather than create
;          a new one
;
;          error(optional): set this to a named variable to return the
;          error status of the function, it will return 0 for no error
;          and 1 to signal an error.  This may be set to true even if
;          the error was non fatal.  Also if you are using globbing
;          to modify many tplot variables it will signal an error if 
;          any of the variables failed
;
;          interior_clip(optional): removes data inside the selected region instead of outside the selected region
;          
;          nan_replace(optional): instead of clipping replaces data with NaNs
;
;          examples:
;                 time_clip,'thb_fgs_gsm','2007-03-23/10:00:00','2007-03-23/12:00:00',newname='thb_fgs_gsm_10t12clip'
;                 time_clip,'thb_peem_velocity','thb_fgs_gsm',thb_fgs_gsm',/tvar
;
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-01-10 17:03:26 -0800 (Wed, 10 Jan 2018) $
; $LastChangedRevision: 24506 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time_clip.pro $
;-

pro time_clip,tplot_var_name,start_time,end_time,newname=newname,tvar=tvar,replace=replace,error=error,interior_clip=interior_clip,nan_replace=nan_replace

COMPILE_OPT idl2

error = 0 

nm = tnames(tplot_var_name)

if nm[0] eq '' then message,'illegal tvar name: "'+tplot_var_name+'"' 

;I don't think this statement is needed...
;else if size(nm,/type) ne 7 then nm = tplot_var_name

if keyword_set(tvar) then begin

   tn1 = tnames(start_time)

   tn2 = tnames(end_time)

   if tn1[0] eq '' then begin
      error = 1
      message,'keyword TVAR is set and start_time not a valid tplot variable name'
   endif

   if n_elements(tn1) ne 1 then begin
      error = 1
      message,'keyword TVAR is set and start_time must contain exactly one tplot variable name'
   endif
   
   if tn2[0] eq '' then begin
      error = 1
      message,'keyword TVAR is set and end_time not a valid tplot variable name'
   endif

   if n_elements(tn2) ne 1 then begin
      error = 1
      message,'keyword TVAR is set and end_time must contain exactly one tplot variable name'
   endif

   get_data,tn1,data=d

   stime = d.x[0]

   get_data,tn2,data=d

   etime = d.x[n_elements(d.x)-1]

endif else begin

   if size(start_time,/type) eq 7 then stime = time_double(start_time) else stime=start_time

   if size(end_time,/type) eq 7 then etime = time_double(end_time) else etime = end_time

endelse

for i=0,n_elements(nm)-1 do begin

   get_data,nm[i],data=d, dlimits = dl
   
   if ~is_struct(d) then begin
     dprint, 'No data in ', nm[i], dlevel = 3
     continue
   endif
   
   idx = where(d.x ge stime and d.x le etime,complement=cidx)
   
   if keyword_set(nan_replace) then begin
      tmp = idx
      idx = cidx
      cidx=tmp
   endif
   
   if keyword_set(interior_clip) then begin
     idx = cidx
   endif
   
   if idx[0] eq -1 then begin
      error = 1
      dprint,'tvar_name: ' + nm[i] + ' out of range'
      continue
   endif

;No clipping if the number of x's and the number of columns in y are
;mismatched. jmm, 27-aug-2009, fixes a problem with THEMIS ASI mosaic
;creation.
   if(n_elements(d.x) ne n_elements(d.y[*, 0])) then begin
     dprint, 'No time clip done for: '+ nm[i], dlevel = 3
     d2 = temporary(d) 
   endif else begin
    
     if keyword_set(nan_replace) then begin
   
       str_element, d, 'V', success = s

       d2=temporary(d)
       if ndimen(d2.y) eq 1 then begin
         d2.y[idx] = !VALUES.D_NAN
       endif else if ndimen(d2.y) eq 2 then begin
         d2.y[idx,*] = !VALUES.D_NAN
       endif else if ndimen(d2.y) eq 3 then begin
         d2.y[idx,*,*] = !VALUES.D_NAN
       endif else if ndimen(d2.y) eq 4 then begin
         d2.y[idx,*,*,*] = !VALUES.D_NAN
       endif else begin
         dprint, 'tvar_name: ' + nm[i] + ' too many dimensions'
         continue
       endelse

     endif else begin
   
       if(ndimen(d.y) eq 1) then begin 
         d2 = {x:d.x[idx], y:d.y[idx]} 
       endif else if(ndimen(d.y) eq 2) then begin
         d2 = {x:d.x[idx], y:d.y[idx, *]}
         str_element, d, 'V', success = s
         if s then begin
           if (ndimen(d.v) eq 1) then str_element, d2, 'V', d.v, /add
           if (ndimen(d.v) eq 2) then str_element, d2, 'V', d.v[idx, *], /add
         endif
       endif else if(ndimen(d.y) eq 3) then begin
         d2 = {x:d.x[idx], y:d.y[idx, *, *]}
         str_element, d, 'V1', success = s
         if s then begin
            if (ndimen(d.v1) eq 1) then str_element, d2, 'V1', d.v1, /add
            if (ndimen(d.v1) eq 2) then str_element, d2, 'V1', d.v1[idx, *], /add
         endif
         str_element, d, 'V2', success = s
         if s then begin
           if (ndimen(d.v2) eq 1) then str_element, d2, 'V2', d.v2, /add
           if (ndimen(d.v2) eq 2) then str_element, d2, 'V2', d.v2[idx, *], /add
         endif
       endif else if(ndimen(d.y) eq 4) then begin
         d2 = {x:d.x[idx], y:d.y[idx, *, *, *]}
         str_element, d, 'V1', success = s
         if s then begin
            if (ndimen(d.v1) eq 1) then str_element, d2, 'V1', d.v1, /add
            if (ndimen(d.v1) eq 2) then str_element, d2, 'V1', d.v1[idx, *], /add
         endif
         str_element, d, 'V2', success = s
         if s then begin
            if (ndimen(d.v2) eq 1) then str_element, d2, 'V2', d.v2, /add
            if (ndimen(d.v2) eq 2) then str_element, d2, 'V2', d.v2[idx, *], /add
         endif
         str_element, d, 'V3', success = s
         if s then begin
            if (ndimen(d.v3) eq 1) then str_element, d2, 'V3', d.v3, /add
            if (ndimen(d.v3) eq 2) then str_element, d2, 'V3', d.v3[idx, *], /add
         endif
       endif else begin
         error = 1
         dprint, 'tvar_name: ' + nm[i] + ' too many dimensions'
         continue
       endelse
       
     endelse
   endelse
   
   if keyword_set(replace) then begin
     store_data,nm[i],data=d2, dlimits = dl
   endif else if (n_elements(nm) eq 1) && keyword_set(newname) then begin
      store_data,newname,data=d2, dlimits = dl
   endif else begin   
      store_data,nm[i]+'_tclip',data=d2, dlimits = dl
   endelse
   
endfor

end
