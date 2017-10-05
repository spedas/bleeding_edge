;+
; PRO get_sd_vlshell
;
; :Description:
;    Generate tplot variables cotaining true velocities by assuming that the true velocity is aligned to 
;    the L-shell direction.  
;
; :Params:
; vlos_vn:  Name of tplot variable for LOSV data (sd_???_vlos_?).
;
; :Keywords:
; angle_var: Set this keyword to generate a tplot variable containing the angles 
;                 between the beam direction and the local MLT direction for each pixel. 
;                 See the comment at Line 247 for details. 
; exclude_angle: Set an angle range, say [85.,95.], to substitute the L-shell assumed true velocities 
;                       for pixels with beam-MLT angles falling in this range, with NaN.  
; vmag:     additionally generate the V_MLAT (the MLAT component of LOSV) and 
;               V_MLT (the MLT component of LOSV) tplot variables
;
; Currently glatp,glatm,glonp, and glonm are used only for debugging. 
; 
; :Examples:
;   get_sd_vlshell, 'sd_hok_vlos_1', exclude_angle=[85,95], /angle_var, /vmag 
;
; :History:
; 2013/02/06: Initial release
; 2013/11/01: implemented vmag keyword
;
; :Author:
;   Tomo Hori (E-mail: horit at stelab.nagoya-u.ac.jp)
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2014-02-10 16:54:11 -0800 (Mon, 10 Feb 2014) $
; $LastChangedRevision: 14265 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/ground/radar/superdarn/get_sd_vlshell.pro $
;-
PRO get_sd_vlshell, vlos_vn, angle_var=angle_var, exclude_angle=exclude_angle, glatp=glatp,glonp=glonp,glatm=glatm,glonm=glonm, $
  vmag=vmag
  
  ;Check the argument
  npar = n_params()
  if npar ne 1 then return
  
  vlos_vn = tnames(vlos_vn)
  if strlen( vlos_vn[0] ) lt 6 then return
  
  ;For multiple vlos_vn variables
  if n_elements(vlos_vn) gt 1 then begin
    for i=0L, n_elements(vlos_vn)-1 do begin
      vn = vlos_vn[i]
      get_sd_vlshell, vn, angle_var=angle_var, exclude_angle=exclude_angle, glatp=glatp,glonp=glonp,glatm=glatm,glonm=glonm
    endfor
    return
  endif
  
  stn = strmid( strmid(vlos_vn, 0,6), 3, 3 )
  if strlen(tnames(vlos_vn)) lt 6 then begin
    print, 'Cannnot find the vlos variable: '+vlos_vn
    return
  endif
  
  ;Inisitalize the AACGM lib
  sd_init
  get_data, vlos_vn, data=d
  ts = time_struct( d.x[0] )
  aacgmloadcoef, ts.year
  
  ;Variable names
  prefix = 'sd_'+strlowcase(stn)+'_'
  suf = strmid(vlos_vn, 0,1,/reverse)
  vlos_vn = prefix+'vlos_'+suf
  azmno_vn = prefix+'azim_no_'+suf
  ptbl_vn = prefix+ 'position_tbl_'+suf
  ctbl_vn = prefix+ 'positioncnt_tbl_'+suf
  
  ;Get variable values
  get_timespan, tr ;Time range
  get_data, vlos_vn, data=d, lim=vlos_lim
  vlos = d.y & vlos_v = d.v &  vlos_time = d.x
  get_data, azmno_vn, data=d
  azmno = d.y
  get_data, ptbl_vn, data= d
  ptbl = reform(d.y[0,*,*,*])
  get_data, ctbl_vn, data= d
  ctbl = reform(d.y[0,*,*,*])
  
  ;Number of range gate and beam
  nrang = n_elements(ctbl[*,0,0])
  azmmax = n_elements(ctbl[0,*,0] )
  
  posm = fltarr( nrang, azmmax, 2)
  posp = fltarr( nrang, azmmax, 2)
  
  for i=0L, nrang-1 do begin
    for j=0L, azmmax-1 do begin
    
      pos = get_sphcntr( [ ptbl[i,j,1],ptbl[i,j+1,1] ], [ ptbl[i,j,0],ptbl[i,j+1,0] ] )
      posm[i,j,0] = pos[1] & posm[i,j,1] = pos[0]
      pos = get_sphcntr( [ ptbl[i+1,j,1],ptbl[i+1,j+1,1] ], [ ptbl[i+1,j,0],ptbl[i+1,j+1,0] ] )
      posp[i,j,0] = pos[1] & posp[i,j,1] = pos[0]
      
    endfor
  endfor
  
  ;height
  if ~keyword_set(alt) then alt = 400. ;[km]
  earth_radii = 6371.2 ;km
  r = (alt + earth_radii)/earth_radii ;[Re]
  
  ;;;Beam vector for each pixel in GEO
  xm = r*cos(posm[*,*,1]*!dtor)*cos(posm[*,*,0]*!dtor)
  ym = r*cos(posm[*,*,1]*!dtor)*sin(posm[*,*,0]*!dtor)
  zm = r*sin(posm[*,*,1]*!dtor)
  xp = r*cos(posp[*,*,1]*!dtor)*cos(posp[*,*,0]*!dtor)
  yp = r*cos(posp[*,*,1]*!dtor)*sin(posp[*,*,0]*!dtor)
  zp = r*sin(posp[*,*,1]*!dtor)
  beam_dx_geo = xp-xm   ;Beam dir at the center of each pixel in GEO
  beam_dy_geo = yp-ym
  beam_dz_geo = zp-zm
  t = sqrt(beam_dx_geo^2+beam_dy_geo^2+beam_dz_geo^2)
  beam_dx_geo /= t & beam_dy_geo /= t & beam_dz_geo /= t ;normalized
  
  ;;;Get unit vectors of the "AACGM MLT direction" in GEO
  
  glat = ctbl[*,*,1] & glon = ctbl[*,*,0]
  altarr = glat & altarr[*,*] = alt
  aacgmconvcoord, glat,glon,altarr, mlat,mlon,err,/TO_AACGM
  mlon = ( mlon + 360. ) mod 360.
  mlonp = mlon + 0.15 & mlonp = ( mlonp + 360. ) mod 360.
  mlonm = mlon - 0.15 & mlonm = ( mlonm + 360. ) mod 360.
  aacgmconvcoord, mlat,mlonp,altarr,glatp,glonp,err, /TO_GEO
  aacgmconvcoord, mlat,mlonm,altarr,glatm,glonm,err, /TO_GEO
  ;return
  xp = r*cos(glatp*!dtor)*cos(glonp*!dtor)
  yp = r*cos(glatp*!dtor)*sin(glonp*!dtor)
  zp = r*sin(glatp*!dtor)
  xm = r*cos(glatm*!dtor)*cos(glonm*!dtor)
  ym = r*cos(glatm*!dtor)*sin(glonm*!dtor)
  zm = r*sin(glatm*!dtor)
  mltdir_dx_geo = xp-xm   ;AACGM MLT dir at the center of each pixel in GEO
  mltdir_dy_geo = yp-ym   ;Positive is eastward
  mltdir_dz_geo = zp-zm
  t = sqrt(mltdir_dx_geo^2+mltdir_dy_geo^2+mltdir_dz_geo^2)
  mltdir_dx_geo /= t & mltdir_dy_geo /= t & mltdir_dz_geo /= t ;normalized
  
  
  
  ;;;Get an angle between VLOS and MLT dir
  cos_vlos_mltdir = beam_dx_geo*mltdir_dx_geo + beam_dy_geo*mltdir_dy_geo $
    + beam_dz_geo*mltdir_dz_geo   ;as a 2-D array in [nrang,azmax]
    
  ;;; Generate the Vmlat and Vmlt tplot vars
  
  ;;;Get unit vectors of the "AACGM LAT direction" in GEO
  glat = ctbl[*,*,1] & glon = ctbl[*,*,0]
  altarr = glat & altarr[*,*] = alt
  aacgmconvcoord, glat,glon,altarr, mlat,mlon,err,/TO_AACGM
  mlon = ( mlon + 360. ) mod 360.
  mlatp = (mlat + 0.1) < 90.0
  mlatm = (mlat - 0.1) > (-90.0)
  aacgmconvcoord, mlatp,mlon,altarr,glatp,glonp,err, /TO_GEO
  aacgmconvcoord, mlatm,mlon,altarr,glatm,glonm,err, /TO_GEO
  ;return
  xp = r*cos(glatp*!dtor)*cos(glonp*!dtor)
  yp = r*cos(glatp*!dtor)*sin(glonp*!dtor)
  zp = r*sin(glatp*!dtor)
  xm = r*cos(glatm*!dtor)*cos(glonm*!dtor)
  ym = r*cos(glatm*!dtor)*sin(glonm*!dtor)
  zm = r*sin(glatm*!dtor)
  mlatdir_dx_geo = xp-xm   ;AACGM MLat dir at the center of each pixel in GEO
  mlatdir_dy_geo = yp-ym   ;Positive is eastward
  mlatdir_dz_geo = zp-zm
  t = sqrt(mlatdir_dx_geo^2+mlatdir_dy_geo^2+mlatdir_dz_geo^2)
  mlatdir_dx_geo /= t & mlatdir_dy_geo /= t & mlatdir_dz_geo /= t ;normalized
  
  ;;;Get an angle between VLOS and MLAT dir
  cos_vlos_mlatdir = beam_dx_geo*mlatdir_dx_geo + beam_dy_geo*mlatdir_dy_geo $
    + beam_dz_geo*mlatdir_dz_geo   ;as a 2-D array in [nrang,azmax]

    
  ;;;Get Vmlat and Vmlt
  cos_vlos_mlatdir_arr = (transpose(cos_vlos_mlatdir))[azmno, * ]
  cos_vlos_mltdir_arr = (transpose(cos_vlos_mltdir))[ azmno, * ]
  vmlat = -vlos * cos_vlos_mlatdir_arr
  vmlt = -vlos * cos_vlos_mltdir_arr
  
  if keyword_set(vmag) then begin
  
    ;;;Store into a tplot variable
    vmlat_vn = prefix+'vmlat_'+suf
    if strlen(tnames(vmlat_vn)) gt 6 then $
      store_data, delete=vmlat_vn
      
    store_data, vmlat_vn, $
      data={x: vlos_time, y: vmlat, v: vlos_v}, $
      dl={spec:1}, $
      lim={ytitle:vlos_lim.ytitle, ysubtitle:vlos_lim.ysubtitle, $
      ztitle:'V_Mlat [m/s]', zrange:[-1000.,1000.] }
      
    vmlt_vn = prefix+'vmlt_'+suf
    if strlen(tnames(vmlt_vn)) gt 6 then $
      store_data, delete=vmlt_vn
      
    store_data, vmlt_vn, $
      data={x: vlos_time, y: vmlt, v: vlos_v}, $
      dl={spec:1}, $
      lim={ytitle:vlos_lim.ytitle, ysubtitle:vlos_lim.ysubtitle, $
      ztitle:'V_MLT [m/s]', zrange:[-1000.,1000.] }
      
  endif
  
  ;;;Get V_Lshell values
  cos_vlos_mltdir_arr = (transpose(cos_vlos_mltdir))[ azmno, * ]
  vlshell = -vlos / cos_vlos_mltdir_arr
  ;help, azmno, cos_vlos_mltdir, cos_vlos_mltdir_arr, vlos
  
  ;Exclude Vlshell values with mltdir-bmdir angle satisfying the
  ;exclude angle range given by the keyword "exclude_angle"
  if keyword_set(exclude_angle) then begin
    if n_elements(size(exclude_angle)) ne 4 then begin
      print, 'exclude_angle is invalid!'
      exclude_angle=0
    endif
  endif
  if keyword_set(exclude_angle) then begin
    angrng = exclude_angle
    sz = size(angrng)
    if sz[1] eq 2 and sz[3] eq 2 then begin
      angrng = minmax(angrng)
      angarr = acos(cos_vlos_mltdir_arr)*!radeg
      idx = where( angarr ge angrng[0] and angarr le angrng[1] )
      if idx[0] ne -1 then vlshell[idx] = !values.f_nan
    endif else begin
      print, 'exclude_angle is invalid!'
      help, angrng
      print, '...ignored'
    endelse
  endif
  
  ;;;Store into a tplot variable
  vlshell_vn = prefix+'vlshell_'+suf
  if strlen(tnames(vlshell_vn)) gt 6 then $
    store_data, delete=vlshell_vn
  store_data, vlshell_vn, $
    data={x: vlos_time, y: vlshell, v: vlos_v}, $
    dl={spec:1}, $
    lim={ytitle:vlos_lim.ytitle, ysubtitle:vlos_lim.ysubtitle, $
    ztitle:'V_Lshell [m/s]', zrange:[-1000.,1000.] }
    
  if keyword_set(angle_var) then begin
    ; This tplot variable contains angles between the beam direction (bmdir) and 
    ; the local MLT direction for each pixel. The resultant angle is a positive 
    ; value if the beam direction has a positive northward component in AACGM
    ; and a negative value if it has a southward component in AACGM. 
    ; For example, bmdir_mlat = 10 and bmdir_mlt = 10 then the angle should be +45 deg., and 
    ; bmdir_mlat = -10 and bmdir_mlt = 10 then the angle should be -45 deg. 
    angle_var_vn = prefix+'mltdir-bmdir_angle_'+suf
    if strlen(tnames(angle_var_vn)) gt 6 then store_data,del=angle_var_vn
    store_data, angle_var_vn, $
      data={x: vlos_time, $
      y: acos(cos_vlos_mltdir_arr)*!radeg *sign(cos_vlos_mlatdir_arr), $
      v: vlos_v}, $
      dl={spec:1}, $
      lim={ytitle:vlos_lim.ytitle, ysubtitle:vlos_lim.ysubtitle, $
      ztitle:'MLTdir-bmdir!Cangle [deg]', zrange:[-180.,180.] }
  endif
  
  return
end
