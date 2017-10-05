;+
;Procedure:  spice_qrot_to_tplot,from_frame,to_frame
;Purpose:  Obtains a unit (rotation) quaternion that can be used to rotate from one frame to another 
;
;Purpose: ;
; Author: Davin Larson  
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
pro spice_qrot_to_tplot,frame1,frame2,utimes=ut,trange=tr,resolution=res,names=name,basetime=basetime,basename=basename,check_objects=check_objects $
      ,get_omega=get_omega,fix_qsign=fix_qsign,error=error,derror=derror
if spice_test() eq 0 then return
if not keyword_set(ut) then begin
   tr = timerange(tr)
   if not keyword_set(res) then begin
      res= 600d > (tr[1]-tr[0])/1000d  < 86400d       ;   defaults to a range of 10 minutes to 1 day
      if not keyword_set(error) then  error = .05
   endif
   ut =dgen(range= res*round(tr/res),resolution=res)  
endif
if not keyword_set(basename) then basename=frame1+'_QROT_'+frame2
n0 = basename  
if keyword_set(basetime) then begin
   baserot = spice_body_att(frame1,frame2,average(basetime),check_objects=check_objects)
   baserot = transpose(baserot)
   n0=n0+'@'
endif
; qatt =  spice_body_att(frame1,frame2,ut,/quaternion,fix_qsign=fix_qsign,baserot=baserot,check_objects=check_objects) 
nreps = 0
repeat   begin
   qatt =  spice_body_att(frame1,frame2,ut,/quaternion,fix_qsign=fix_qsign,baserot=baserot,check_objects=check_objects) 
   if keyword_set(error) || keyword_set(derror) then begin
      if nreps++ gt 5 then break
      del_qatt = sqrt(total( (shift(qatt,0,-1) - qatt )  ^2,1))
      del_qatt[n_elements(ut)-1] = 0
;      del_qatt[0] = 0
      bad = 0
      if keyword_set(error) then bad = del_qatt gt error
      if keyword_set(derror) then begin              ;  this section of code has not been debugged
          del2_qatt = abs( shift(del_qatt,-1) - shift(del_qatt,1) )
          del2_qatt[[0,n_elements(del2_qatt)-1]] = 0
          bad = bad or (del2_qatt gt derror)
      endif
      w = where(bad,nw)
      if nw eq 0 then break
      ndiv = 4
      uti = 0
      dprint,dlevel=2,'Subdividing '+strtrim(nw,2)+' intervals into '+strtrim(ndiv,2)+' sections ',nreps
      for i=1,ndiv-1 do  append_array,uti,  ut[w]+ (ut[w+1]-ut[w])*double(i)/ndiv
      ut = [ut,uti]
      ut = ut[sort(ut)]
   endif else break
endrep  until 0b               ;keyword_set(error) && ~(keyword_set(fix_qsign) ne 0))
printdat,nreps
qatt = transpose(qatt)
name =n0
store_data,n0,ut,qatt,dlimit=struct(colors='dbgr',ystyle=2)
if keyword_set(get_omega) && (get_omega and 2) then begin
  angvel = q_angular_velocity(ut,qatt)
  n1 = str_sub(n0,'_QROT_','_Q-OMEGA2_')
  angvel = shift(angvel,0,-1)      ;  shift scaler component into last position (allows use of xyz_to_polar) 
  store_data,n1,ut,angvel,dlimit=struct(colors='bgrd',ystyle=2,reverse_order=1)
  append_array,name,n1
endif
if keyword_set(get_omega) && (get_omega and 1) then begin
  angvel = q_angular_velocity(ut,qatt,/moving)
;  n2 = n0+'_OMEGA2'
  n2 = str_sub(n0,'_QROT_','_Q-OMEGA1_')
  angvel = shift(angvel,0,-1)      ;  shift scaler component into last position (allows use of xyz_to_polar) 
  store_data,n2,ut,angvel,dlimit=struct(colors='bgrd',ystyle=2,reverse_order=1)
  append_array,name,n2
endif
dprint,dlevel=2,name
end

