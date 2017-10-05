;+
;procedure:  spice_position_to_tplot
;Usage:
;  object= 'Earth'
;  Observer='Sun'
;  spice_postion_to_tplot,object,observer,frame=frame,
;
;Purpose: ;
; Author: Davin Larson  
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro spice_position_to_tplot,body,observer,utimes=ut,frame=frame,trange=tr,resolution=res,names=name,scale=scale,normalize=normalize,basename=basename,check_objects=check_objects
if not keyword_set(ut) then begin
   tr = timerange(tr)
   if not keyword_set(res) then begin
      res=  1 > (tr[1]-tr[0])/10000d  < 86400
   endif
   ut =dgen(range= tr,resolution=res)  
endif
pstring = '_POS_'
append_array,check_objects,[body,observer,frame]             ;   must fix this !!
pos = transpose( spice_body_pos(body,observer,utc=ut,frame=frame, check_objects=check_objects) )
if keyword_set(scale) then pos /= scale
if keyword_set(normalize) then begin 
   pos /= (sqrt(total(pos^2,2)) # [1,1,1])
   pstring = '_DIR_'
endif
if ~keyword_set(basename) then basename=body+pstring+'('+observer+'-'+frame+')'
name = basename
store_data,name,ut,pos,dlimit=struct(colors='bgr',ystyle=2,object=object,observer=observer,frame=frame)
end

