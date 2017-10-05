;+
;Procedure: SPICE_VECTOR_ROTATE_TPLOT
;Purpose:  TPLOT wrapper routine for the function SPICE_VECTOR_ROTATE
;Usage:   SPICE_VECTOR_ROTATE_TPLOT,TPLOTNAME,TO_FRAME
;Inputs:    TPLOTNAME:   string(s) - valid tplot name(s)
;           TO_FRAME:    string or id - valid SPICE FRAME
;Output:    VECTOR_PRIME:  3xN array - vector as measured in the TO_FRAME
;  Note: time is in the last dimension  (not like tplot storage)
; 
; Author: Davin Larson  
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro SPICE_VECTOR_ROTATE_TPLOT,tvarnames,to_frame,check_objects=check_objects,verbose=verbose,suffix=suffix,names=names,trange=trange

if ~keyword_set(suffix) then suffix='_'+to_frame
tvn= tnames(tvarnames,n)
names=''
for i=0,n-1 do begin
   alim=0
   get_data,tvn[i],time,vals,alimit=alim
   from_frame = ''
   co=''
   if keyword_set(check_objects) then co=check_objects
   str_element,alim,'SPICE_FRAME',from_frame
   if ~keyword_set(from_frame) then begin
      dprint,'Frame not defined for variable: ',tvn[i]
      continue
   endif
   newname = tvn[i]+suffix
   dprint,dlevel=2,verbose=verbose,'Creating: ',newname
   str_element,alim,'SPICE_MASTER_FRAME',co
 ;  vector = transpose(*ptrs.y)
;   time   = *ptrs.x
   if n_elements(trange) eq 2 then begin
       tr = time_double(trange)
       ind  = where(time ge tr[0] and time le tr[1],nind)
       if nind eq 0 then continue
       time=time[ind]
       vals = vals[ind,*]
   endif
   vector_prime = spice_vector_rotate(transpose(vals),time,from_frame,to_frame,check_objects=co,verbose=verbose)
;   vector_pr///ime = spice_vector_rotate(transpose(vals),time,to_frame,from_frame,check_objects=co,verbose=verbose)
   alim.spice_frame = to_frame
   store_data,newname,time,transpose(vector_prime),dlimit=alim
   append_array,names,newname
endfor
end


