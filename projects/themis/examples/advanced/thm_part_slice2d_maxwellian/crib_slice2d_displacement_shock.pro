;+
;Crib:
;  crib_slice2d_displacement_shock
;
;Purpose:
; This example follows crib_slice2d_displacment but operates with real data and 
; represents the case of the real distribution during the shock event.
; The crib can work in 2 modes with and without displacement
; 4 coordinate system can be used: DSL, GSE, GSM, Shock frame
; Displacement can be set to none, to maximum from 2d slices, to bulk velocity 
; and to custom vector   
;
;Notes:
; See crib_slice2d_displacement_shock_direct_graphic for the same exmaple, that 
; produces the plot using direct graphics. The same example can be used to save
; postscreept image file. 
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2018-07-23 16:27:29 -0700 (Mon, 23 Jul 2018) $
;$LastChangedRevision: 25510 $
;$URL:
;-

; === Setup ===

; flags and parameters
; DISPMODE - Displacement mode
;   'none' - don't use displacement, set to [0., 0., 0.]
;   'max' - calculate displacement, from 2d distributions Vx, Vy -> max(DF at x,y), Vz -> max(Df at x,z)
;   'bulk' - displacement is equal to the bulk velocity
;   'custom' - use cutrom_displacement vector
; CORDSYS - Coordinate system
;   'dsl' - DSL
;   'gse' - GSE
;   'gsm' - GSM
;   'shock' - shock frame defined by shock_l and shock_n vectors (x and normal)
; CROSSMODE - Shock cross on the figure
;   'none' - no cross
;   'max'  - determined max
;   'bulk' - bulk velocity
;   'disp' - displacement
; NORMPSD - Normalize DF
;    1 - f = DF/max(DF)
;    0 - f = DF
;
; time_start - Time of the first frame 
; secwin - time window of frames.
; cutrom_displacement - vector of the custom center of the coordinate system (DISPMODE = 'custom')
; Vs - Shock speed. The axis in normalized to this value
; 

DISPMODE  = 'bulk' ; [none], [max], [bulk], [custom]
CORDSYS   = 'gse'  ; [dsl], [gse], [gsm], [shock]
CROSSMODE = 'none' ; [none], [max], [bulk], [disp]
NORMPSD  = 0 ; Normalize DF to max

; basic settings
time_start = [time_double('2013-07-09/20:39:38')] ; Shock time is 2013-07-09/20:39:42
secwin = 4. ; time window
cutrom_displacement = [0., 0., 0.]
Vs = 146.0  ;shock speed. Vj = Vj/Vs

; load data
trange = '2013-07-09/' + ['20:39:00','20:40:20']
dist_arr = thm_part_dist_array(probe='c',type='peib', trange=trange) ;esa ion burst data
thm_load_fgm, probe='c', datatype = 'fgl', level=2, coord='gse', trange=trange
mag_data = 'thc_fgl_gse'

; Shock frame rotation
shock_l = [-0.166, 0.494, 0.853]
shock_n = [0.972, 0.227, 0.059]

; === Processing ===

; displacment variable
origin_shift = [0., 0., 0.]

xtitle=['$V_x$','$V_x$','$V_y$']
ytitle=['$V_y$','$V_z$','$V_z$']
ztitle=['$V_z$','$V_y$','$V_x$']

if CORDSYS eq 'shock' then begin
  xtitle=['$V_n$','$V_n$','$V_m$']
  ytitle=['$V_m$','$V_l$','$V_l$']
  ztitle=['$V_l$','$V_m$','$V_n$']
endif else begin
  ctitle = STRUPCASE(CORDSYS) + ' '
  xtitle=[ctitle+xtitle[0],ctitle+xtitle[1],ctitle+xtitle[2]]
  ytitle=[ctitle+ytitle[0],ctitle+ytitle[1],ctitle+ytitle[2]]
  ztitle=[ctitle+ztitle[0],ctitle+ztitle[1],ctitle+ztitle[2]]
endelse


rotation = ['xy','xz','yz']
letters=[['a','b','c'],['d','e','f'],['g','h','j']]

; image settings
tabno = 22 ; colors

; axis ranges
xrange=[-4, 4]
yrange=[-4, 4]

; size of the pannels
i_width = 0.26
i_hight = 0.24

; post-process
if NORMPSD then begin
  maxlog= 0
  minlog=-4
  psd_str = 'DF/max(DF)'
endif else begin
  maxlog=-6
  minlog=-10
  psd_str = 'DF'
endelse
; Settings for the images
i_struct = {rgb_table:tabno, ASPECT_RATIO:1, FILL:1, AXIS_STYLE:2, xstyle:1,ystyle:1, max_value:maxlog, min_value:minlog, xrange:xrange, yrange:yrange, CURRENT:1}
; Settings for the colorbar
c_struct = {C_VALUE:[-10:1], color:[1,1,1], C_LABEL_SHOW:[1,1,1,1], C_USE_LABEL_COLOR:1, C_USE_LABEL_ORIENTATION:1,OVERPLOT:1}
; Settings for the data
t_struct = {timewin:secwin, count_threshold:1,MAG_DATA:mag_data,UNITS:'DF',smooth:2, three_d_interp:1, coord:'dsl'}

if CORDSYS eq 'gse' then t_struct.coord = 'gse'
if CORDSYS eq 'gsm' then t_struct.coord = 'gsm'

if CORDSYS eq 'shock' then begin
  t_struct.coord = 'gse'
  str_element, t_struct,'slice_norm',shock_l,/add
  str_element, t_struct,'slice_x',shock_n,/add
endif


;display
fid=window(DIMENSIONS=[1200,1000])

for r_idx=0,2 do begin
   
  if DISPMODE eq 'max' or CROSSMODE eq 'max' or DISPMODE eq 'bulk' or CROSSMODE eq 'bulk' then begin
    xyzarr = FLTARR(3,3)
    time = time_start + (r_idx)*secwin
    for c_idx=0,1 do begin
      thm_part_slice2d, dist_arr, rotation=rotation[c_idx], part_slice=slice, slice_time=time, _extra = t_struct
      xyidx = ARRAY_INDICES(slice.data, where(slice.data eq max(slice.data)))
      account = max(slice.data) gt 1e-8
      xyzarr[c_idx,*] = [slice.xgrid[xyidx[0]]*account, slice.ygrid[xyidx[1]]*account, account]
      if DISPMODE eq 'bulk' and (CROSSMODE eq 'bulk' or CROSSMODE eq 'disp') then c_idx = 1
    endfor

    if CROSSMODE eq 'bulk' then xyzarr2 = slice.bulk / Vs
    if DISPMODE  eq 'bulk' then origin_shift = slice.bulk / Vs    
    if CROSSMODE eq 'max'  then xyzarr2 = [xyzarr[0,0], xyzarr[0,1], xyzarr[1,1]] / Vs
    if DISPMODE  eq 'max' then origin_shift = xyzarr
  endif  
   if DISPMODE eq 'custom' then origin_shift = cutrom_displacement
   if CROSSMODE eq 'disp' then xyzarr2 = origin_shift
   
      
  for c_idx=0,2 do begin
    ; Position
    x1 = 0.05 + i_width*c_idx + 0.05*c_idx
    y1 = 1 - 0.03 - (r_idx+1)*i_hight - 0.07*(r_idx)
    x2 = x1 + i_width
    y2 = y1 + i_hight
    position = [x1, y1, x2, y2]

    ; Time
    time = time_start + (r_idx)*secwin
    stitle = string(format='(%"%s-%s")', time_string(time, TFORMAT='hh:mm:ss'), time_string(time+secwin, TFORMAT='hh:mm:ss'))
        
    disp = origin_shift * Vs 
    
    thm_part_slice2d, dist_arr, rotation=rotation[c_idx], part_slice=slice, slice_time=time, $
      displacement=disp, _extra = t_struct    
         
    ; post_process
    if NORMPSD then begin
      log_psd=(alog10(slice.data/max(slice.data)))
    endif else begin
      log_psd=(alog10(slice.data))
    endelse
    
    slice.XGRID = (slice.XGRID)/Vs
    slice.YGRID = (slice.YGRID)/Vs

    ; === Plot ===    
    pid =   image(log_psd, slice.xgrid, slice.ygrid, position=position, title = letters[c_idx,r_idx] + ') ' + stitle,$
       xtitle = xtitle[c_idx], ytitle = ytitle[c_idx], _extra=i_struct)
    cid = CONTOUR(log_psd, slice.xgrid, slice.ygrid, _extra=c_struct) ;/OVERPLOT       
    if CROSSMODE ne 'none' then ppid = PLOT([xyzarr2[c_idx/2]], [xyzarr2[(c_idx+1)/2+1]], symbol='+',SYM_SIZE=2.5,/overplot) ; the math behind the indexes is based on int devision => 3/2 = 1
    tid = text(x2-0.15, y1+0.02, string(format='(%"%s = %5.2f")',ztitle[c_idx],origin_shift[2-c_idx]))
  endfor
  c=COLORBAR(target=pid,ORIENTATION=1,TAPER=0,BORDER=0,MAJOR=5,MINOR=5,TITLE='$Log_{10}('+ psd_str +')$') ;POSITION=[0.97,0.05,0.99,0.45],
endfor

print, "ORIENTATION MATRIX:"
print, slice.ORIENT_MATRIX

end