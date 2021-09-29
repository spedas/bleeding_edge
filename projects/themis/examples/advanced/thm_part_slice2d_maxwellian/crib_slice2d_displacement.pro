;+
;Crib:
;  crib_slice2d_displacment
;
;Purpose:
; This example demonstrates the displacement keyword of thm_part_slice2d function
; This is a very advanced crib that generates Maxwellian distribution and replaces the peib data with it.
; At the end, it generates the slice2d figures with the specified displacement of the origin.
;
;Notes:
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2018-05-30 19:24:40 -0700 (Wed, 30 May 2018) $
;$LastChangedRevision: 25301 $
;$URL:
;-

;generate Maxwellian distribution
  BulkV = [100.,200.,300.] ; bulk velocity
  DispV = [100.,200.,300.] ; displacement velocity
  
  N = 1000000 ; number of test particles
  Vt = 100.   ; Termal velocity km/s
  sigma2 = (Vt^2)/2
  generate_maxwellian,vx=vx,vy=vy,vz=vz,sigma2=sigma2,num=N  
  vx = vx + BulkV[0]
  vy = vy + BulkV[1]
  vz = vz + BulkV[2]
  vr = sqrt(vx^2 + vy^2 + vz^2) ; total velocity
  
; Create binning grid
  gmaxmin = [-1000, 1000] ; grid boundaries
  gbin_size = 20 ; grig resolution
  g_size = (gmaxmin[-1]-gmaxmin[0])/gbin_size + 1
  xarr = FINDGEN(g_size,INCREMENT=gbin_size)+gmaxmin[0]
  yarr = xarr
  zarr = xarr  
  ; Initialize the arrays
  data   = FLTARR(g_size,g_size,g_size) ; counts
  data_v = FLTARR(g_size,g_size,g_size) ; total velocity
  data_e = FLTARR(g_size,g_size,g_size) ; energy
    
  ; Binning
  for i=0, N-1 do begin
    tmp = min(abs(xarr - vx[i]),ix)
    tmp = min(abs(yarr - vy[i]),iy)
    tmp = min(abs(zarr - vz[i]),iz)
    data[ix,iy,iz]++
  endfor
  
; Fillind velosity and energy arrays
  for i=0, g_size-1 do begin
    for j=0, g_size-1 do begin
      for k=0, g_size-1 do begin
        data_v[i,j,k] = sqrt(xarr[i]^2 + yarr[j]^2 + zarr[k]^2)
        data_e[i,j,k] = 0.5*1.67e-27*(data_v[i,j,k])^2/1.6e-19*1e6 ; energy in eV 
      endfor
    endfor
  endfor
  
; Calculate PSD 
  n3d = 10 ; Arbitrary number density
  orig_psd = data / N / double(gbin_size)^3 * (n3d);  

;generate peir distribution   
  ;load a data sample
  trange = '2013-07-09/' + ['20:39:00','20:40:00']
  esa_mode='peib'
  probe='c'
  thm_load_fit, probe=probe, level=2, trange=trange
  peib_ptrarr = thm_part_dist_array(probe=probe, type=esa_mode, trange=trange) ; array of pointers  
  peib_data=(*peib_ptrarr[0])[0] ; only the first record
  
  peib_v =  sqrt(peib_data.ENERGY * 2 / peib_data.mass)
  sphere_to_cart, peib_v, peib_data.THETA, peib_data.PHI, peib_x, peib_y, peib_z
    
; Filling velocity and energy arrays
  for i=0, peib_data.NENERGY-1 do begin
    for j=0, peib_data.NBINS-1 do begin
      tmp=min(abs(xarr - peib_x[i,j]), idx_x) 
      tmp=min(abs(yarr - peib_y[i,j]), idx_y) 
      tmp=min(abs(zarr - peib_z[i,j]), idx_z) 
      peib_data.data[i,j] = orig_psd[idx_x, idx_y, idx_z]      
    endfor
  endfor
  
  mxwl_arr = peib_data
  mxwl_arr.UNITS_NAME = 'DF' ; we already have DF units
  mxwl_arr.VELOCITY = v_3d(mxwl_arr) ; bluk velocity
  mxwl_arr[*] = mxwl_arr
  mxwl_arr.time = peib_data.time
  mxwl_prtarr=[ptr_new(mxwl_arr)] ; create pointer array (dist_arr)
  
  
  i_struct = {rgb_table:22, ASPECT_RATIO:1, FILL:1, AXIS_STYLE:2, $
    C_VALUE:indgen(51)/50.*5-10, xrange:[-1000,1000], yrange:[-1000,1000], CURRENT:1}

  ; Figure from original distribution
     
  tmp = min(abs(xarr - DispV[0]),midx) ; mid[xyz] - index of the grid around new origin
  tmp = min(abs(yarr - DispV[1]),midy) 
  tmp = min(abs(zarr - DispV[2]),midz) 
  
  fid=window(DIMENSIONS=[1200,800])
  pid = contour(alog10(REFORM(orig_psd[*,*,midz])), xarr, yarr,layout=[3,2,1],$
    xtitle='$V_x$, [km/s]',ytitle='$V_y$, [km/s]', title='Maxwellian distribution xy, z = ' + string(FORMAT='(%"%d")',DispV[2]) ,_extra=i_struct)
  pid.translate, 0
  pid = contour(alog10(REFORM(orig_psd[*,midy,*])), xarr, zarr, layout=[3,2,2],$
   xtitle='$V_x$, [km/s]',ytitle='$V_z$, [km/s]', title='Maxwellian distribution xz, y = ' + string(FORMAT='(%"%d")',DispV[1]),_extra=i_struct)
  pid.translate, -40
  pid = contour(alog10(REFORM(orig_psd[midx,*,*])), yarr, zarr, layout=[3,2,3],$
   xtitle='$V_y$, [km/s]',ytitle='$V_z$, [km/s]', title='Maxwellian distribution yz, x = ' + string(FORMAT='(%"%d")',DispV[0]),_extra=i_struct)
  pid.translate, -80    
  c = COLORBAR(TARGET=pid,  ORIENTATION=1, TAPER=1, title='$Log_{10}(PSD)$ [$(s/(km cm))^3$]')  
  c.translate, 30  
  
  ; slice2d setup  
  slice_time=trange[0]
  timewin = 30.
  
 ; Processed figure using slice2d
  rotarr = ['xy','xz','yz']
  rotaxes = ['z','y','x']
  lpos=3
  foreach rt, rotarr do begin
    thm_part_slice2d, mxwl_prtarr, slice_time=slice_time, timewin=timewin, rotation=rt, $
    smooth=0, part_slice=mxwl_part_slice,  displacement =  DispV, /three_d ;
    lpos++                
    STRANGE = STRING(FORMAT='(%"peib. distribution %s, %s = %d")',rt,rotaxes[lpos-4], DispV[abs(lpos-6)])
    ;STRANGE = rt
    pid = contour((alog10(mxwl_part_slice.data)), mxwl_part_slice.xgrid, mxwl_part_slice.ygrid, $
      xtitle='$V_'+strmid(rt,0,1)+'$, [km/s]',ytitle='$V_'+strmid(rt,1,2)+'$, [km/s]', $
      LAYOUT=[3,2,lpos], title = STRANGE, _extra=i_struct)
    pid.translate, -40*((lpos-1) mod 3)
  endforeach
  c = COLORBAR(TARGET=pid,  TAPER=1, ORIENTATION=1, title='$Log_{10}(PSD)$ [$(s/(km cm))^3$]')
  c.translate, 30

end