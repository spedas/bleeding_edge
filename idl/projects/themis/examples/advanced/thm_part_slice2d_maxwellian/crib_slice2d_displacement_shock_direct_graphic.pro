;+
;Crib:
;  crib_slice2d_displacement_shock_direct_graphic
;
;Purpose:
; This example follows crib_slice2d_displacment but operates with real data and 
; represents the case of the real distribution during the shock event.
; The crib can work in 2 modes with and without displacement
; 4 coordinate system can be used: DSL, GSE, GSM, Shock frame
; In the shock frame the rotation is defined by normal and parallel vectors 
; shock_n and shock_l in GSE, additionaly, the origin is shifted accorgind to the shock 
; and upstream velocity in km/s.
; 
; Displacement can be set to none, to maximum from 2d slices, to bulk velocity 
; and to custom vector   
; 
;Notes:
; This exmaple uses Direct Graphics to produce the image.
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2018-08-20 20:21:37 -0700 (Mon, 20 Aug 2018) $
;$LastChangedRevision: 25683 $
;$URL:
;-

; === Setup ===
; flags and parameters
; DISPMODE - Displacement mode
;   'none' - displacement is set to [0., 0., 0.], no displacement
;   'max' - calculate displacement, from 2d distributions Vx, Vy -> max(DF at x,y), Vz -> max(Df at x,z)
;   'bulk' - displacement is equal to the bulk velocity
;   'custom' - use cutrom_displacement vector
; CORDSYS - Coordinate system
;   'dsl' - DSL
;   'gse' - GSE
;   'gsm' - GSM
;   'shock' - shock frame defined by shock_l and shock_n vectors (x and normal)
; CROSSMODE - Show cross on the figure
;   'none' - no cross
;   'max'  - determined max
;   'bulk' - bulk velocity
;   'disp' - displacement
; NORMPSD - Normalize DF
;    1 - f = DF/max(DF)
;    0 - f = DF
; VNORM -  normalize the velocity by the shock speed 
;   1 - Vj = Vj/Vs
;   0 - Vj in km/s 
; 
; SAVEPS - Flag. Save graphics into ps file
;    psfilename - ps file name
;
; time_start - Time of the first frame 
; secwin - time window of frames.
; custom_displacement - vector of the custom center of the coordinate system (DISPMODE = 'custom')
; Vs - Shock speed. The axis in normalized to this value
; 

DISPMODE  = 'custom' ; [none], [max], [bulk], [custom]
CORDSYS   = 'shock'  ; [dsl], [gse], [gsm], [shock]
CROSSMODE = 'bulk' ; [none], [max], [bulk], [disp]
NORMPSD  = 0; Normalize DF to max
VNORM = 1; normalize the velocity by Vs; set to VNORM = 1 in shock frame 

SAVEPS  = 0 ; Output graphics into PostScript file
psfilename = 'crib_shock' ; ps filename if SAVEPS=1     

; basic settings
; data range (day and time interval)
thm = 'c' ; THEMIS probe
trange = '2013-07-09/' + ['20:39:00','20:40:20']
time_start = [time_double('2013-07-09/20:39:38')] ; Shock time is 2013-07-09/20:39:42
secwin = 4. ; time window
Vs = 124.5  ;shock speed. Vj = Vj/Vs
Vu = 348.2  ;upstream speed 
custom_displacement = [1., 0., 0.]

; Shock frame rotation
shock_l = [-0.166, 0.494, 0.853]
shock_n = [0.972, 0.227, 0.059]

; === Processing ===
; load data
dist_arr = thm_part_dist_array(probe=thm,type='peib', trange=trange) ;esa ion burst data
thm_load_fgm, probe=thm, datatype = 'fgl', level=2, coord='gse', trange=trange
mag_data = 'th' + thm + '_fgl_gse'

; displacment variable
origin_shift = [0., 0., 0.]
xyzarr = []
xyzarr2 = []

rotation = ['xy','xz','yz']
letters=[['a','b','c'],['d','e','f'],['g','h','j']]

; image settings
tabno = 22 ; colors
defaulttabno = 43 ; colors

if VNORM then begin 
  units_str = ''
  sformat='(%"%s = %5.2f%s")'

  ; axis ranges
  xrange=[-4, 4]
  yrange=[-4, 4]

  ;annotation position
  textx = -1
  texty = -3.5
  NVs = abs(Vs)
endif else begin
  units_str = ' km/s'
  sformat='(%"%s = %7.2f%s")'
  ; axis ranges
  xrange=[-1000, 1000]
  yrange=[-1000, 1000]

  ;annotation position
  textx = -550
  texty = -875
  
  NVs = 1
endelse

xyz = ['V!Dx!N','V!Dy!N','V!Dz!N']
nml = ['V!Dn!N','V!Dm!N','V!Dl!N']

xtitle= [xyz[0], xyz[0], xyz[1]]
ytitle = [xyz[1], xyz[2], xyz[2]]
ztitle = [xyz[2], xyz[1], xyz[0]]

if CORDSYS eq 'shock' then begin
  xtitle= [nml[0], nml[0], nml[1]]
  ytitle = [nml[1], nml[2], nml[2]]
  ztitle = [nml[2], nml[1], nml[0]]
  n_shift = Vs + Vu
  custom_displacement[0] = custom_displacement[0] -1*n_shift/NVs
endif else begin
  ctitle = STRUPCASE(CORDSYS) + ' '
  xtitle=[ctitle+xtitle[0],ctitle+xtitle[1],ctitle+xtitle[2]]
  ytitle=[ctitle+ytitle[0],ctitle+ytitle[1],ctitle+ytitle[2]]
  ztitle=[ctitle+ztitle[0],ctitle+ztitle[1],ctitle+ztitle[2]]
  n_shift = 0
endelse

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
i_struct = { zrange:[minlog, maxlog], xrange:xrange, yrange:yrange}
; Settings for the countour
c_struct = { overplot:1, levels:[minlog:maxlog], c_labels:intarr(abs(maxlog-minlog+1))+1}
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
if SAVEPS then begin 
  popen, psfilename, /encap, /land, options={charsize:0.5}
endif else begin
  window, 0, xsize=1200, ysize=1000
endelse

loadct2, tabno

for r_idx=0,2 do begin
   
  ; if we have cross indicator or displacement set to max or buil  
  if DISPMODE eq 'max' or CROSSMODE eq 'max' or DISPMODE eq 'bulk' or CROSSMODE eq 'bulk' then begin
    xyzarr = FLTARR(2,2) ; search coordinates (xy,xz) 
    time = time_start + (r_idx)*secwin
    for c_idx=0,1 do begin
      thm_part_slice2d, dist_arr, rotation=rotation[c_idx], part_slice=slice, slice_time=time, _extra = t_struct ; get xy anc xz rotations
      xyidx = ARRAY_INDICES(slice.data, where(slice.data eq max(slice.data))) ; find  maximums
      account = max(slice.data) gt 1e-8 ; check if the data is ok
      xyzarr[c_idx,*] = [slice.xgrid[xyidx[0]]*account, slice.ygrid[xyidx[1]]*account]
      if DISPMODE eq 'bulk' and (CROSSMODE eq 'bulk' or CROSSMODE eq 'disp') then c_idx = 1 ; we need to run it only once to get bulk vel
    endfor

    if CROSSMODE eq 'bulk' then xyzarr2 = slice.bulk / NVs
    if CROSSMODE eq 'max'  then xyzarr2 = [xyzarr[0,0], xyzarr[0,1], xyzarr[1,1]] / NVs
    
    if DISPMODE  eq 'bulk' then origin_shift = slice.bulk / NVs   
    if DISPMODE  eq 'max'  then origin_shift = [xyzarr[0,0], xyzarr[0,1], xyzarr[1,1]] / NVs
  endif  
    
  if CROSSMODE eq 'disp'  then xyzarr2 = custom_displacement
  if DISPMODE eq 'custom' then origin_shift = custom_displacement
  
  xyzarr2[0] = xyzarr2[0] + (n_shift / NVs) ; in shock frame - shift along n
    
      
  disp = origin_shift * NVs
  origin_shift[0] = origin_shift[0] + (n_shift/NVs)
  
  for c_idx=0,2 do begin
    ; Time
    time = time_start + (r_idx)*secwin
    stitle = string(format='(%"%s-%s")', time_string(time, TFORMAT='hh:mm:ss'), time_string(time+secwin, TFORMAT='hh:mm:ss'))
        
    thm_part_slice2d, dist_arr, rotation=rotation[c_idx], part_slice=slice, slice_time=time, $
      displacement=disp, _extra = t_struct    
         
    ; post_process
    if NORMPSD then begin
      log_psd=(alog10(slice.data/max(slice.data)))
    endif else begin
      log_psd=(alog10(slice.data))
    endelse

    ; shift along n in shock frame    
    if (c_idx eq 0) or (c_idx eq 1 ) then slice.XGRID = slice.XGRID + n_shift    
          
    slice.XGRID = (slice.XGRID)/NVs
    slice.YGRID = (slice.YGRID)/NVs

    ; === Direct Graphics Plot ===    
    mpanelstr = string(format='(%"%d,%d")',c_idx,r_idx)
    no_color_scale_opt = 1
    add_opt = 1
    if c_idx eq 2 then  no_color_scale_opt = 0
    if c_idx+r_idx eq 0 then begin
    plotxyz, slice.xgrid, slice.ygrid, log_psd, multi='3,3', mpanel = mpanelstr, no_color_scale=no_color_scale_opt, $ 
      xtitle = xtitle[c_idx]+units_str, ytitle = ytitle[c_idx]+units_str,$
      ztitle = 'Log!D10!N('+ psd_str +')', title= letters[c_idx,r_idx] + ') ' + ' th' + thm + ' ' + stitle, $
      mmargin=[0.01,0.005,0.01,0.02], xsize=1200, ysize=1000, _extra = i_struct
    endif else begin
      plotxyz, slice.xgrid, slice.ygrid, log_psd, mpanel = mpanelstr, no_color_scale=no_color_scale_opt, /addpanel, $
        xtitle = xtitle[c_idx]+units_str, ytitle = ytitle[c_idx]+units_str,$
        ztitle = 'Log!D10!N('+ psd_str +')', title= letters[c_idx,r_idx] + ') '+ ' th' + thm + ' ' + stitle, _extra = i_struct
    endelse
    contour, log_psd, slice.xgrid, slice.ygrid, _extra = c_struct
    if CROSSMODE ne 'none' then OPLOT, [xyzarr2[c_idx/2]], [xyzarr2[(c_idx+1)/2+1]], psym=1, SYMSIZE=2.5  ;symbol='+',SYM_SIZE=2.5 ; the math behind the indexes is based on int devision => 3/2 = 1
    xyouts, textx, texty, string(format=sformat,ztitle[c_idx],origin_shift[2-c_idx],units_str)
  endfor
endfor


print, "THEMIS: " + thm
print, "DISPLACEMENT: " + DISPMODE
print, "COORDINATES: " + CORDSYS
print, "ORIENTATION MATRIX:"
print, slice.ORIENT_MATRIX
if SAVEPS then pclose
loadct2, defaulttabno

end