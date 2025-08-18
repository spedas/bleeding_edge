
function x_rot_mat, a

  n = n_elements(a)

  out = make_array(n, 3, 3, /double)

  out[*, 0, 0] = 1D

  out[*, 1, 1] =  cos(2*!DPI*a)

  out[*, 2, 1] = -sin(2*!DPI*a) 

  out[*, 1, 2] =  sin(2*!DPI*a) 

  out[*, 2, 2] =  cos(2*!DPI*a) 

  return, out

end

function y_rot_mat, a

  n = n_elements(a)

  out = make_array(n, 3, 3, /double)

  out[*, 0, 0] = cos(2*!DPI*a)

  out[*, 2, 0] = -sin(2*!DPI*a)  

  out[*, 1, 1] = 1D

  out[*, 0, 2] = sin(2*!DPI*a)

  out[*, 2, 2] = cos(2*!DPI*a)

  return, out

end

function z_rot_mat, a
  
  n = n_elements(a)

  out = make_array(n, 3, 3, /double)

  out[*, 0, 0] = cos(2*!DPI*a)
  
  out[*, 1, 0] = -sin(2*!DPI*a)

  out[*, 0, 1] = sin(2*!DPI*a)

  out[*, 1, 1] = cos(2*!DPI*a)

  out[*, 2, 2] = 1D

  return, out 

end

;generates a list of rotations by multiplying each element of l2 by l1
;n_elements(output) = n_elements(list1)*n_elements(list2)
function cross_multiply, l1, l2

compile_opt idl2

dims1 = size(l1, /dimensions)
dims2 = size(l2, /dimensions)

out = make_array(dims1[0]*dims2[0], 3, 3, /double)

for i = 0, dims1[0]-1 do begin
  for j = 0, dims2[0]-1 do begin

    m1 = reform(l1[i,*,*],3,3)
    m2 = reform(l2[j,*,*],3,3)

    out[i*dims2[0]+j, *, *] = m2 ## m1

  endfor
endfor

return, out

end

pro qslerp_tests, tnum

if(tnum eq 1) then begin

  m1 = [[1, 0, 0], [0, 1, 0], [0, 0, 1]] ;no rotation

;m2 = [[0,-1,0],[1,0,0],[0,0,1]] ;pi/2 rotation around z axis

  m2 = [[-1, 0, 0], [0, -1, 0], [0, 0, 1]] ;pi rotation around z axis
  
  qin = transpose([[mtoq(m1)], [mtoq(m2)]])

  x1 = [0.0D, 1.0D]

  x2 = [0.0D, 1.0/6.0, 1.0/3.0, 1.0/2.0, 2.0/3.0, 5.0/6.0, 1.0D]

  qout = qslerp(qin, x1, x2)

  mout = qtom(qout)

  v = [1, 0, 0]

  vout = dblarr(n_elements(x2), 3)

  for i = 0, n_elements(x2)-1L do begin

    vout[i, *] = (reform(mout[i, *, *], 3, 3))##v

  endfor

  xp = dblarr(n_elements(x2)*2)

  yp = dblarr(n_elements(x2)*2)

  xp[2*indgen(n_elements(x2))] = vout[*, 0]

  yp[2*indgen(n_elements(x2))] = vout[*, 1]

  plots, xp+.5, yp+.5 ;the vectors rotated with interpolated rotations

  stop

  plot, indgen(n_elements(x2)), acos(vout[*, 0]) ;this should be a straight line,~y=x, demonstrating constant rates of rotation

  stop

  plot, indgen(n_elements(x2)), asin(vout[*, 1]) ;this should form a triangle,something like y =-|x| with appropriate shifts

  stop

  plot, indgen(n_elements(x2)), sqrt(total(vout*vout, 2)),yrange=[0,2] ;this should be a straight line, y=1.0D demonstrating constant vector lengths

endif else if (tnum eq 2) then begin 

timespan,'2007-03-23'

thm_load_fgm,probe='b',coord='gse',level=2

get_data,'thb_fgl_gse',data=ld,dlimits=ldl
get_data,'thb_fgs_gse',data=sd,dlimits=sdl

idx = where(sd.x gt ld.x[0] and sd.x lt ld.x[n_elements(ld.x)-1])

store_data,'thb_fgs_gse2',data={x:sd.x[idx],y:sd.y[idx,*],v:sd.v},dlimits=sdl

tsmooth2,'thb_fgl_gse',601,newname='thb_fgl_gse_sm601'

fac_matrix_make,'thb_fgl_gse_sm601',other_dim='xgse',newname='thb_fgl_gse_fac_mat'

tvector_rotate,'thb_fgl_gse_fac_mat','thb_fgs_gse2',newname='thb_facx'

tplot,['thb_fgs_gse2','thb_fgl_gse_sm601','thb_facx']

endif else if (tnum eq 3) then begin

m1 = y_rot_mat([-1D/4D, 0D])

m2 = z_rot_mat([0D, 3D/4D])

;mlist = cross_multiply(m1, m2)

mlist = make_array(4, 3, 3, /double)

mlist[0:1, *, *] = m2
mlist[2:3, *, *] = m1

qlist = mtoq(mlist)

x1 = dindgen(4)

x2 = dindgen(40)/10

qlist = qslerp(qlist, x1, x2)

mlist = qtom(qlist)

v = [1, 0, 0]

dims = size(mlist, /dimensions)

vlist = make_array(dims[0], 3, /double)

for i = 0, dims[0]-1L do begin

  vlist[i, *] = reform(mlist[i,*, *], 3, 3) ## v

endfor

plotxy, vlist

stop

endif else if tnum eq 4 then begin

  v = [1, 0, 0]

  m1 = x_rot_mat(0)

  m2 = z_rot_mat(3D/8D)

  m3 = y_rot_mat(-1D/8D)

  m4 = z_rot_mat(5D/8D)

  m5 = x_rot_mat(1D/16D)

  m23 = reform(m3) ## reform(m2)

  m45 = reform(m5) ## reform(m4)

  q1 = mtoq(m1)

  q23 = mtoq(m23)

  q45 = mtoq(m45)

  ql1 = transpose([[q1], [q23]])

  ql2 = transpose([[q23], [q45]])

  ql3 = transpose([[q45], [q1]])

  qls1 = qslerp(ql1, dindgen(2), dindgen(20)/10)

  qls2 = qslerp(ql2, dindgen(2), dindgen(20)/10)

  qls3 = qslerp(ql3, dindgen(2), dindgen(20)/10)

  mls1 = qtom(qls1)

  mls2 = qtom(qls2)

  mls3 = qtom(qls3)

  dims1 = size(mls1, /dimensions)

  dims2 = size(mls2, /dimensions)

  dims3 = size(mls3, /dimensions)

  vlist = make_array(dims1[0], 3, /double)

  for i = 0, dims1[0]-1L do begin

    vlist[i, *] = reform(mls1[i, *, *], 3, 3) ## v

  endfor

  custom = make_array(2, 3, /double)

  va = reform(vlist[0, *])

  vb = reform(vlist[dims1[0]-1L, *])

  vc = crossp(vb, va)

  custom[0, *] = vb
  
  custom[1, *] = vc

  plotxy, vlist, plotaxes = ['xy', 'xz', 'yrz', 'cc'], custom4 = custom

  stop

  vlist = make_array(dims2[0], 3, /double)

  for i = 0, dims2[0]-1L do begin

    vlist[i, *] = reform(mls2[i, *, *], 3, 3) ## v

  endfor

  custom = make_array(2, 3, /double)

  va = reform(vlist[0, *])

  vb = reform(vlist[dims2[0]-1L, *])

  vc = crossp(vb, va)

  custom[0, *] = vb
  
  custom[1, *] = vc

  plotxy, vlist, plotaxes = ['xy', 'xz', 'yrz', 'cc'], custom4 = custom

  stop

  vlist = make_array(dims3[0], 3, /double)

  for i = 0, dims3[0]-1L do begin

    vlist[i, *] = reform(mls3[i, *, *], 3, 3) ## v

  endfor
  
  custom = make_array(2, 3, /double)
  
  va = reform(vlist[0, *])

  vb = reform(vlist[dims1[0]-1L, *])

  vc = crossp(va, vb)

  custom[0, *] = va
  
  custom[1, *] = vc

  plotxy, vlist, plotaxes = ['xy', 'xz', 'yrz', 'cc'], custom4 = custom

  stop

endif

end
