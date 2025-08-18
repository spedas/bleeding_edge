;+
;
;Procedure:
;   elf_mlt_l_lat
;
;Purpose:
;   subroutine to calculate mlt,l,mlat under dipole configuration
;
;Inputs:
;   variable_state: tplot variable containing position data in sm coordinates
;
;Keywords:
;   mlt0: 
;   l0:
;   lat0: Latitude
;
;Example:
;   elf_mlt_l_lat,probe='a',date='2007-03-23'
;
;Notes:
;   Based on a routine by Qianli Ma (qianlima@atmos.ucla.edu)
;
;$LastChangedBy:$
;$LastChangedDate:$
;$LastChangedRevision:$
;$URL:$
;-

pro elf_mlt_l_lat,variable_state,MLT0=MLT0,L0=L0,lat0=lat0

  ; retrieve position data
  get_data,variable_state,xs,ys,zs
  time_s=xs
  px=ys[*,0]
  py=ys[*,1]
  pz=ys[*,2]
  Re=6370.

  ; convert to RE units
  nn=size(px)
  nx=px/Re
  ny=py/Re
  nz=pz/Re

  ; initialize arrays
  theta=dblarr(nn[1])
  lat0=dblarr(nn[1])
  r=dblarr(nn[1])
  MLT0=dblarr(nn[1])
  L0=dblarr(nn[1])
  tims_s=dblarr(nn[1])
  time_st=dblarr(nn[1])
  i=long(0)

  ;for i=0,nn[1]-1 do begin
  repeat begin
  tx=nx[i]
  ty=ny[i]
  tz=nz[i]
  rect_coord=[tx,ty,tz]
  sphere_coord=cv_coord(from_rect=rect_coord,/to_sphere)
  theta[i]=sphere_coord[0]
  lat0[i]=sphere_coord[1]
  r[i]=sphere_coord[2]
  i=i+1
  endrep until (i eq nn[1])
  ;endfor

  ii=long(0)
  repeat begin
    MLT0[ii]=12+24*theta[ii]/2/!pi
    L0[ii]=r[ii]/(cos(lat0[ii])^2)
    ii=ii+1
  endrep until (ii eq nn[1])

end