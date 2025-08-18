;+
; PRO get_sd_glondir
;
; :Description:
;    Generate a tplot variable containing angles between the beam direction and local geographical
;    longitude direction for each pixel. 
;
; :Params:
; vlos_vn:  Name of tplot variable for LOSV data. 
;
; :Keywords:
; 
;
; :Examples:
;   get_sd_glondir, 'sd_hok_vlos_1'
;
; :History:
; 2014/01/06: Initial release
;
; :Author:
;   Tomo Hori (E-mail: horit at isee.nagoya-u.ac.jp)
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
PRO get_sd_glondir, vlos_vn

  ;Check the argument
  npar = N_PARAMS()
  IF npar NE 1 THEN RETURN
  
  vlos_vn = tnames(vlos_vn)
  IF STRLEN( vlos_vn[0] ) LT 6 THEN RETURN
  
  ;For multiple vlos_vn variables
  IF N_ELEMENTS(vlos_vn) GT 1 THEN BEGIN
    FOR i=0L, N_ELEMENTS(vlos_vn)-1 DO BEGIN
      vn = vlos_vn[i]
      get_sd_glondir, vn, glatp=glatp,glonp=glonp,glatm=glatm,glonm=glonm
    ENDFOR
    RETURN
  ENDIF
  
  stn = STRMID( STRMID(vlos_vn, 0,6), 3, 3 )
  IF STRLEN(tnames(vlos_vn)) LT 6 THEN BEGIN
    PRINT, 'Cannnot find the vlos variable: '+vlos_vn
    RETURN
  ENDIF
  
  ;Inisitalize the AACGM lib
  sd_init
  get_data, vlos_vn, data=d
  ;ts = time_struct( d.x[0] )
  ;aacgmloadcoef, ts.year
  
  ;Variable names
  prefix = 'sd_'+STRLOWCASE(stn)+'_'
  suf = STRMID(vlos_vn, 0,1,/reverse)
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
  ptbl = REFORM(d.y[0,*,*,*])
  get_data, ctbl_vn, data= d
  ctbl = REFORM(d.y[0,*,*,*])
  
  ;Number of range gate and beam
  nrang = N_ELEMENTS(ctbl[*,0,0])
  azmmax = N_ELEMENTS(ctbl[0,*,0] )
  
  posm = FLTARR( nrang, azmmax, 2)
  posp = FLTARR( nrang, azmmax, 2)
  
  FOR i=0L, nrang-1 DO BEGIN
    FOR j=0L, azmmax-1 DO BEGIN
    
      pos = get_sphcntr( [ ptbl[i,j,1],ptbl[i,j+1,1] ], [ ptbl[i,j,0],ptbl[i,j+1,0] ] )
      posm[i,j,0] = pos[1] & posm[i,j,1] = pos[0]
      pos = get_sphcntr( [ ptbl[i+1,j,1],ptbl[i+1,j+1,1] ], [ ptbl[i+1,j,0],ptbl[i+1,j+1,0] ] )
      posp[i,j,0] = pos[1] & posp[i,j,1] = pos[0]
      
    ENDFOR
  ENDFOR
  
  ;height
  IF ~KEYWORD_SET(alt) THEN alt = 400. ;[km]
  earth_radii = 6371.2 ;km
  r = (alt + earth_radii)/earth_radii ;[Re]
  
  ;;;Beam vector for each pixel in GEO
  xm = r*COS(posm[*,*,1]*!dtor)*COS(posm[*,*,0]*!dtor)
  ym = r*COS(posm[*,*,1]*!dtor)*SIN(posm[*,*,0]*!dtor)
  zm = r*SIN(posm[*,*,1]*!dtor)
  xp = r*COS(posp[*,*,1]*!dtor)*COS(posp[*,*,0]*!dtor)
  yp = r*COS(posp[*,*,1]*!dtor)*SIN(posp[*,*,0]*!dtor)
  zp = r*SIN(posp[*,*,1]*!dtor)
  beam_dx_geo = xp-xm   ;Beam dir at the center of each pixel in GEO
  beam_dy_geo = yp-ym
  beam_dz_geo = zp-zm
  t = SQRT(beam_dx_geo^2+beam_dy_geo^2+beam_dz_geo^2)
  beam_dx_geo /= t & beam_dy_geo /= t & beam_dz_geo /= t ;normalized
  
  ;;;Get unit vectors of the "Glat direction"

  glat = ctbl[*,*,1] & glon = ctbl[*,*,0]
  altarr = glat & altarr[*,*] = alt

  glatp = glat + 0.1 & glatm = glat - 0.1
  glon = ( glon + 360. ) MOD 360.
  glonp = glon 
  glonm = glon 

  xp = r*COS(glatp*!dtor)*COS(glonp*!dtor)
  yp = r*COS(glatp*!dtor)*SIN(glonp*!dtor)
  zp = r*SIN(glatp*!dtor)
  xm = r*COS(glatm*!dtor)*COS(glonm*!dtor)
  ym = r*COS(glatm*!dtor)*SIN(glonm*!dtor)
  zm = r*SIN(glatm*!dtor)
  glatdir_dx_geo = xp-xm   ;Glon dir at the center of each pixel
  glatdir_dy_geo = yp-ym   ;Positive is eastward
  glatdir_dz_geo = zp-zm
  t = SQRT(glatdir_dx_geo^2+glatdir_dy_geo^2+glatdir_dz_geo^2)
  glatdir_dx_geo /= t & glatdir_dy_geo /= t & glatdir_dz_geo /= t ;normalized

  ;;;Get unit vectors of the "Glon direction"
  
  glat = ctbl[*,*,1] & glon = ctbl[*,*,0]
  altarr = glat & altarr[*,*] = alt
  
  glatp = glat & glatm = glat
  glon = ( glon + 360. ) MOD 360.
  glonp = glon + 0.1 & glonp = ( glonp + 360. ) MOD 360.
  glonm = glon - 0.1 & glonm = ( glonm + 360. ) MOD 360.
  
  xp = r*COS(glatp*!dtor)*COS(glonp*!dtor)
  yp = r*COS(glatp*!dtor)*SIN(glonp*!dtor)
  zp = r*SIN(glatp*!dtor)
  xm = r*COS(glatm*!dtor)*COS(glonm*!dtor)
  ym = r*COS(glatm*!dtor)*SIN(glonm*!dtor)
  zm = r*SIN(glatm*!dtor)
  glondir_dx_geo = xp-xm   ;Glon dir at the center of each pixel
  glondir_dy_geo = yp-ym   ;Positive is eastward
  glondir_dz_geo = zp-zm
  t = SQRT(glondir_dx_geo^2+glondir_dy_geo^2+glondir_dz_geo^2)
  glondir_dx_geo /= t & glondir_dy_geo /= t & glondir_dz_geo /= t ;normalized
  
  ;;;Get an angle between VLOS and Glon dir/Glat dir
  cos_vlos_glondir = beam_dx_geo*glondir_dx_geo + beam_dy_geo*glondir_dy_geo $
    + beam_dz_geo*glondir_dz_geo   ;as a 2-D array in [nrang,azmax]
  cos_vlos_glatdir = beam_dx_geo*glatdir_dx_geo + beam_dy_geo*glatdir_dy_geo $
    + beam_dz_geo*glatdir_dz_geo   ;as a 2-D array in [nrang,azmax]
  
  acos_vlos_glondir = acos( cos_vlos_glondir ) * !radeg 
  sine_sign = sign( cos_vlos_glatdir ) 
  idx = where( sine_sign lt 0., cnt ) 
  if cnt gt 0 then acos_vlos_glondir[idx] *= (-1.) 
  
  ;;;Generate the glondir/glatdir array
  acos_vlos_glondir_arr = (TRANSPOSE(acos_vlos_glondir))[ azmno, * ]
  
  angle_var_vn = prefix+'glondir-bmdir_angle_'+suf
  IF STRLEN(tnames(angle_var_vn)) GT 6 THEN store_data,del=angle_var_vn
  store_data, angle_var_vn, $
    data={x: vlos_time, y:(acos_vlos_glondir_arr), $
    v: vlos_v}, $
    dl={spec:1}, $
    lim={ytitle:vlos_lim.ytitle, ysubtitle:vlos_lim.ysubtitle, $
    ztitle:'Glondir-bmdir!Cangle [deg]', zrange:[0.,180.] }
    
    
    
    
  RETURN
END
