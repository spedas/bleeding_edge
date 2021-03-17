;+
;procedure:  spice_position_to_tplot
;Usage:
;  object= 'Earth'
;  Observer='Sun'
;  spice_postion_to_tplot,object,observer,frame=frame,
;
;Purpose: ;
; Author: Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-12-16 13:15:41 -0800 (Wed, 16 Dec 2020) $
; $LastChangedRevision: 29509 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_position_to_tplot.pro $
;-

pro spice_position_to_tplot,body,observer,utimes=ut,frame=frame,trange=tr,resolution=res,names=names,scale=scale,normalize=normalize,basename=basename,check_objects=check_objects,force_objects=force_objects
  if not keyword_set(ut) then begin
    tr = timerange(tr)
    if not keyword_set(res) then begin
      res=  1 > (tr[1]-tr[0])/10000d  < 86400
    endif
    ut =dgen(range= tr,resolution=res)
  endif
  pstring = '_POS_'
  vstring = '_VEL_'
  object=body
;  append_array,check_objects,[body,observer,frame]             ;   must fix this !!
  if ~keyword_set(check_objects) then check_objects= [ body,observer ]
;  append_array,check_objects,[body,observer]            
  vel=transpose(spice_body_vel(body,observer,utc=ut,frame=frame,pos=pos,check_objects=check_objects,force_objects=force_objects))
  pos=transpose(pos)
  if keyword_set(scale) then pos /= scale   else scale=1d
  if keyword_set(normalize) then begin
    pos /= (sqrt(total(pos^2,2)) # [1,1,1])
    vel /= (sqrt(total(vel^2,2)) # [1,1,1])
    pstring = '_POS_DIR_'
    vstring = '_VEL_DIR_'
  endif
  if ~keyword_set(basename) then basename=body+pstring+'('+observer+'-'+frame+')'
  pname = basename
  vname = body+vstring+'('+observer+'-'+frame+')'
  names=[pname,vname]
  vel_subtitle = '(km/s)'
  if ~keyword_set(pos_subtitle) then   pos_subtitle ='('+strtrim(scale,2)+' km)'
  
  store_data,pname,ut,pos,dlimit=struct(ysubtitle=pos_subtitle,colors='bgr',labels=['X','Y','Z'],labflag=-1,ystyle=3,object=object,observer=observer,frame=frame,scale=scale)
  store_data,vname,ut,vel,dlimit=struct(ysubtitle=vel_subtitle,colors='bgr',labels=['Vx','Vy','Vz'],labflag=-1,ystyle=3,object=object,observer=observer,frame=frame,units='km/s')
end

