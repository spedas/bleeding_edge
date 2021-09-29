
;+
;Procedure: thm_santize_l2_sst
;
;Purpose:
;  Basic santization for L2 CDFs.
;  Right now, only removes attenuator spikes
;  Only tested for psif/psef.  Not sure how it would work on other data
;
;Arguments:
;  probe: the probe ('a','b,', etc...)
;  datatype: the sst data type( e.g. psif etc..)
;  tvarnames: the tvarnames to be sanitized
;  suffix=suffix:Set to add a suffix for comparison testing
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2021-06-21 13:40:03 -0700 (Mon, 21 Jun 2021) $
; $LastChangedRevision: 30075 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sanitize_l2_sst.pro $
;
;
;-
pro thm_sanitize_l2_sst,probe,datatype,tvarnames,suffix=suffix

 if undefined(suffix) then begin
   suffix = ''
 endif

 atten_name = 'th'+probe + '_' + datatype + '_atten'

 ;load attenuator data
 thm_load_sst,probe=probe 
 
 ;if there is no attenuator data, this cannot happen
 get_data, atten_name, data = d
 If(~is_struct(d)) Then Begin
    dprint, 'No attenuator data for this time period, data remains unsanitized'
    Return
 Endif

 for i = 0,n_elements(tvarnames)-1 do begin
   

   get_data,tvarnames[i],data=data
   
   undefine,datten
   ;match attenuator data to target
   tinterpol_mxn,atten_name,data.x,out=datten,/repeat_extrapolate
 
   if ~is_struct(datten) then begin
     message,'ERROR: no atten data defined';never get here, why do we have hard-coded stops in production
   endif
   
   n=n_elements(datten.x)
   idx = where(round(datten.y[1:n-1]) ne round(datten.y[0:n-2]))
   idx = [idx-1,idx,idx+1]
   c_idx = ssl_set_complement(idx,lindgen(n)) ;since this is a relative complement, there is no need to worry about out of range indices on idx
   
   ;removes the points, doesn't NAN label them
   if ndimen(data.y) eq 1 then begin
     data = {x:data.x[c_idx],y:data.y[c_idx]}
   endif else begin
     str_element,data,'v',success=s
     if s then begin
       if ndimen(data.v) eq 1 then begin
         data = {x:data.x[c_idx],y:data.y[c_idx,*],v:data.v}
       endif else begin
         data = {x:data.x[c_idx],y:data.y[c_idx,*],v:data.v[c_idx,*]}
       endelse
     endif else begin
       data = {x:data.x[c_idx],y:data.y[c_idx,*]}
     endelse
   endelse
  
   store_data,tvarnames[i]+suffix,data=data
 endfor

end
