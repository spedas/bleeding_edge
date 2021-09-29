;+
;Crib:
;  crib_slice2d_replace_maxwellian
;
;Purpose:
; This is a very advanced crib that generates Maxwellian distribution and replaces the satellite data with it.
; At the end, it generates the figures. Uncomment corresponding lines to save the figures.
;
;Notes:
;  
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2018-05-21 18:38:17 -0700 (Mon, 21 May 2018) $
;$LastChangedRevision: 25241 $
;$URL: 
;-

;generate Maxwellian distribution
  N = 1000000
  Vt = 200. ; km/s
  sigma2 = (Vt^2)/2
  BulkV = [500.,500.,0] ; km/s
  
  generate_maxwellian,vx=vx,vy=vy,vz=vz,sigma2=sigma2,num=N  
  vx = vx + BulkV[0]
  vy = vy + BulkV[1]
  vz = vz + BulkV[2]
  vr = sqrt(vx^2 + vy^2 + vz^2) ; total velocity
  
; Create binning grid
  gmaxmin = [-1000, 1000]
  gbin_size = 50
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
  esa_mode='peir'
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
  mxwl_arr[*] = mxwl_arr
  mxwl_arr.time = peib_data.time
  mxwl_prtarr=[ptr_new(mxwl_arr)] ; create pointer array (dist_arr)
  
  tmp = min(abs(xarr),midx) ; midx - index of the grid around 0
  i_struct = {rgb_table:22, ASPECT_RATIO:1, FILL:1, AXIS_STYLE:2, $
    C_VALUE:indgen(51)/50.*5-12, xrange:[-1000,1000], yrange:[-1000,1000], CURRENT:1}

  ; REPLACE WITH YOUR PATH
  png_folder = 'e:\Codes\SPEDAS\spedas_development\mycodes\slice2d_summary\500_offest_'

if 0 then begin  ; Figure from original distribution
  fid=window(DIMENSIONS=[1200,400])
  pid = contour(alog10(REFORM(orig_psd[*,*,midx])), xarr, yarr,layout=[3,1,1],$
    xtitle='$V_x$, [km/s]',ytitle='$V_y$, [km/s]', title='Maxwellian distribution xy',_extra=i_struct)
  pid.translate, -10
  pid = contour(alog10(REFORM(orig_psd[*,midx,*])), xarr, zarr, layout=[3,1,2],$
   xtitle='$V_x$, [km/s]',ytitle='$V_z$, [km/s]', title='Maxwellian distribution xz',_extra=i_struct)
  pid.translate, -60
  pid = contour(alog10(REFORM(orig_psd[midx,*,*])), yarr, zarr, layout=[3,1,3],$
   xtitle='$V_y$, [km/s]',ytitle='$V_z$, [km/s]', title='Maxwellian distribution yz',_extra=i_struct)
  pid.translate, -100    
  c = COLORBAR(TARGET=pid,  ORIENTATION=1, TAPER=1, title='$Log_{10}(PSD)$ [$(s/(km cm))^3$]')  
  c.translate, 30  
;   fid.save, png_folder+'PSD_maxwellian.png'
endif  
  
  ; slice2d setup  
  slice_time=trange[0]
  timewin = 30.
  
if 0 then begin ; simples plot for testing 
  thm_part_slice2d, mxwl_prtarr, slice_time=slice_time, timewin=timewin, $
    smooth=0, part_slice=mxwl_part_slice,/two_d
  thm_part_slice2d_plot, mxwl_part_slice
endif
    
if 0 then begin ; Processed figure using slice2d
  interarr = ['2d','3d','geometric']
  rotarr = ['xy','xz','yz'] 
  fid2=window(DIMENSIONS=[1200,1200])
  lpos=0
  foreach ir, interarr do begin     
    foreach rt, rotarr do begin
      lpos++
      case ir of
        '2d': thm_part_slice2d, mxwl_prtarr, slice_time=slice_time, timewin=timewin, rotation=rt, $            
            smooth=0, part_slice=mxwl_part_slice,/two_d
        '3d': thm_part_slice2d, mxwl_prtarr, slice_time=slice_time, timewin=timewin, rotation=rt, $            
            smooth=0, part_slice=mxwl_part_slice,/three_d
        'geometric': thm_part_slice2d, mxwl_prtarr, slice_time=slice_time, timewin=timewin, rotation=rt, $            
            smooth=0, part_slice=mxwl_part_slice,/geometric
      endcase
      STRANGE = STRING(FORMAT='(%"%s, %s interp")', rt, ir)
      pid = contour((alog10(mxwl_part_slice.data)), mxwl_part_slice.xgrid, mxwl_part_slice.ygrid, $
        xtitle='$V_'+strmid(rt,0,1)+'$, [km/s]',ytitle='$V_'+strmid(rt,1,2)+'$, [km/s]', $
        LAYOUT=[3,3,lpos], title = STRANGE, _extra=i_struct)
      pid.translate, -40*((lpos-1) mod 3)      
    endforeach
    c = COLORBAR(TARGET=pid,  TAPER=1, ORIENTATION=1, title='$Log_{10}(PSD)$ [$(s/(km cm))^3$]')
    c.translate, 30
  endforeach
 ;   fid2.save, png_folder+'PSD_spacecraft.png'
endif

if 1 then begin ; Cut of the both figures 
  fid3=window(DIMENSIONS=[600,500])
  tmp = min(abs(xarr - 500),orig_midx) ; midx - index of the grid around 0    
  tmp = min(abs(xarr),orig_midxz) ; midx - index of the grid around 0
  p1 = plot(xarr,orig_psd[*,orig_midx,orig_midxz],/current,COLOR='black', THICK = 2,$
      title='DF cut, y = 500 km/s', xtitle='$V_x$, [km/s]', ytitle='PSD [$(s/(km cm))^3$]',$
      xrange=[-1000, 1000], position=[0.2, 0.1, 0.9, 0.9],name='Original')
  
  thm_part_slice2d, mxwl_prtarr, slice_time=slice_time, timewin=timewin, smooth=0, part_slice=mxwl_part_slice2d,/two_d
  tmp = min(abs(mxwl_part_slice2d.YGRID - 500),mxwl_midx) ; midx - index of the grid around 0
  p2 = plot(mxwl_part_slice2d.XGRID,mxwl_part_slice2d.data[*,mxwl_midx],/overplot,COLOR='blue',name='2D slice')
  
  thm_part_slice2d, mxwl_prtarr, slice_time=slice_time, timewin=timewin, smooth=0, part_slice=mxwl_part_slice3d,/three_d
  tmp = min(abs(mxwl_part_slice3d.YGRID - 500),mxwl_midx) ; midx - index of the grid around 0
  p3 = plot(mxwl_part_slice3d.XGRID,mxwl_part_slice3d.data[*,mxwl_midx],/overplot,COLOR='red',name='3D slice')

  thm_part_slice2d, mxwl_prtarr, slice_time=slice_time, timewin=timewin, smooth=0, part_slice=mxwl_part_sliceG,/geometric
  tmp = min(abs(mxwl_part_sliceG.YGRID - 500),mxwl_midx) ; midx - index of the grid around 0
  p4 = plot(mxwl_part_sliceG.XGRID,mxwl_part_sliceG.data[*,mxwl_midx],/overplot,COLOR='green',name='Geometric slice')  
  
   l = legend(target=[p1,p2,p3,p4])
 ;  fid3.save, png_folder+'y500_PSD_cut.png'
endif
end