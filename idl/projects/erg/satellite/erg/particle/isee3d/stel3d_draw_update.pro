PRO stel3d_draw_update, evTop, val
  
  oConf = val['oConf']
  oData = val['oData']
  oTitle = val['oTitle']
  oColorbar = val['oColorbar']
  oScatter = val['oScatter']
  oMagVec = val['oMagVec']
  oVelVec = val['oVelVec']
  oISO1 = val['oISO1']
  oISO2 = val['oISO2']
  oVolume = val['oVolume']
  oWindow = val['oWindow']
  oXYImage = val['oXYImage']
  oYZImage = val['oYZImage']
  oXZImage = val['oXZImage']
  oXYContour = val['oXYContour']
  oYZContour = val['oYZContour']
  oXZContour = val['oXZContour']
  tSliderval = val['tSliderval']

  oConf->GetProperty, $
    ISO1_LEVEL=iso1_level,     $  ; isosurfaceの表示レベル[追加]
    ISO2_LEVEL=iso2_level,  $
    RANGE=nrange, $
    AXIS_UNIT=axis_unit, $
    UNIT=unit, $
    SLICE_XY=slice_xy, $  ; 2Dスライス面と場所XY面
    SLICE_YZ=slice_yz, $  ; 2Dスライス面と場所YZ面
    SLICE_XZ=slice_xz, $  ; 2Dスライス面と場所ZX面
    MAX_MAG_VEC=max_mag_vec, $
    MAX_VEL_VEC=max_vel_vec, $
    MAG_COORD=mag_coord

  ; reload data
  res = oData.reload_data()

  ; Get original data and set color min/max value
  origvol = oData.GetVolumedata(/original)
  nrange = oData.getNSouceRange()
  oConf.SetProperty, COLOR_MAX_VAL=float(nrange[1]), COLOR_MIN_VAL=float(nrange[0])
  widget_control, widget_info(evTop, FIND_BY_UNAME='colortab:ColorMinText'), SET_VALUE=strcompress(nrange[0], /REMOVE_ALL)
  widget_control, widget_info(evTop, FIND_BY_UNAME='colortab:ColorMaxText'), SET_VALUE=strcompress(nrange[1], /REMOVE_ALL)

  ; Update Volume
  voldata = oData.getVolumeData()
  res = oData.GetCoordConv(XS=xs, YS=ys, ZS=zs)
  oVolume.SetProperty, DATA0=voldata, XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs

  ; get nrange for updated Volume
  nrange = oData.getNSouceRange()
  oConf.SetProperty, COLOR_MAX_VAL=float(nrange[1]), COLOR_MIN_VAL=float(nrange[0])
  widget_control, widget_info(evTop, FIND_BY_UNAME='colortab:ColorMinText'), SET_VALUE=strcompress(nrange[0], /REMOVE_ALL)
  widget_control, widget_info(evTop, FIND_BY_UNAME='colortab:ColorMaxText'), SET_VALUE=strcompress(nrange[1], /REMOVE_ALL)

  ;
  ; Update Colorbar
  oColorbar.GetProperty, MAJOR=major
  fStep = (max(nrange)-min(nrange))/(major-1)
  if unit eq 'psd' then begin
    oFont = obj_new('IDLgrFont', SIZE=6)
    bartext = strtrim(string(findgen(major)*fStep + min(nrange), FORMAT='(1E8.0)'),1)
    oTickText = obj_new( 'IDLgrText', $
      bartext, $
      FONT=oFont )
  endif else begin
    oFont = obj_new('IDLgrFont', SIZE=8)
    bartext = strtrim(string(findgen(major)*fStep + min(nrange), FORMAT='(F10.1)'),1)
    oTickText = obj_new( 'IDLgrText', $
      bartext, $
      FONT=oFont )
  endelse

  oColorbar.SetProperty, $
    TITLE=IDLgrText(unit, FONT=oFont), $
    TICKTEXT=oTickText, $
    TICKVALUES=congrid(indgen(256), major, /MINUS_ONE), $
    /NO_COPY


  ; Update Slice & Contour
  sz = oData.GetVolDimension()
  xy_pos = slice_xy.position
  xy_img = voldata[*, *, xy_pos]
  xy_img = reform(xy_img, sz[0], sz[1], /OVERWRITE)
  oXYImage.SetProperty, DATA = xy_img
  oXYContour.SetProperty, DATA = xy_img

  yz_pos = slice_yz.position
  yz_img = voldata[yz_pos,*,*]
  yz_img = reform(yz_img, sz[1], sz[2], /OVERWRITE)
  oYZImage.SetProperty, DATA = yz_img
  res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=oYZContour)
  oYZContour.GetProperty, DATA=yz_cont
  yz_cont[0,*]=yz_pos
  oYZContour.SetProperty, DATA=yz_cont


  xz_pos = slice_xz.position
  xz_img = voldata[*,xz_pos,*]
  xz_img = reform(xz_img, sz[0], sz[2], /OVERWRITE)
  oXZImage.SetProperty, DATA = xz_img
  res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=oXZContour)
  oXZContour.GetProperty, DATA=xz_cont
  xz_cont[1,*]=xz_pos
  oXZContour.SetProperty, DATA=xz_cont

  ;
  ; Update Scatter Plot
  !null = stel3d_create_scatter(oData, UPDATE=oScatter)
  widget_control, widget_info(evTop, FIND_BY_UNAME='scattertab:MINTEXT'), SET_VALUE=strcompress(string(ceil(nrange[0])))
  widget_control, widget_info(evTop, FIND_BY_UNAME='scattertab:MAXTEXT'), SET_VALUE=strcompress(string(ceil(nrange[1])))
  widget_control, widget_info(evTop, FIND_BY_UNAME='scattertab:MINSLIDER'), SET_VALUE=nrange[0], SET_SLIDER_MIN=nrange[0] , SET_SLIDER_MAX=nrange[1]
  widget_control, widget_info(evTop, FIND_BY_UNAME='scattertab:MAXSLIDER'), SET_VALUE=nrange[1], SET_SLIDER_MIN=nrange[0] , SET_SLIDER_MAX=nrange[1]
  ;
  ; Update ISOsurface
  !null = stel3d_create_isosurface(oVolume, iso1_level, UPDATE=oISO1)
  !null = stel3d_create_isosurface(oVolume, iso2_level, UPDATE=oISO2)
  oISO1.SetProperty, XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs
  oISO2.SetProperty, XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs
  ;
  ; Update Axis

  ;
  ; Update Vectors
  oConf->GetProperty, $
    BFIELD=bfield, $      ; 磁場ベクトル
    VELOCITY=velinfo      ; 速度ベクトル
  ROTMAT=rotmat
  if mag_coord eq 1 then begin
    bvec = [bfield.x, bfield.y, bfield.z]
    vvec = [velinfo.x, velinfo.y, velinfo.z]
    bvec_unit = [bfield.x, bfield.y, bfield.z]/sqrt(bfield.x^2.+bfield.y^2.+bfield.z^2.)
    vvec_unit = [velinfo.x, velinfo.y, velinfo.z]/sqrt(velinfo.x^2.+velinfo.y^2.+velinfo.z^2.)
    mv_p = crossp(bvec_unit, vvec_unit) ;Cross product of magnetc and velocity vectors, B x V (=new Y) ^M
    mv_p /= norm(mv_p) ;normalize
    mvm_p = crossp(mv_p, bvec_unit) ; Cross product of (BxV) x B (=new X) ^M
    mvm_p /= norm(mvm_p) ;normalize
    ;
    ;ROTATION USING MATRIX
    rotmat = [[mvm_p],[mv_p],[bvec_unit]]
    res = stel3d_create_vector(invert(rotmat) # bvec, UPDATE=val['oMagVec'])
    res = stel3d_create_vector(invert(rotmat) # vvec, UPDATE=val['oVelVec'])
  endif else begin
    res = stel3d_create_vector([bfield.x, bfield.y, bfield.z], UPDATE=val['oMagVec'])
    res = stel3d_create_vector([velinfo.x, velinfo.y, velinfo.z], UPDATE=val['oVelVec'])
  endelse

  ; Redraw the display
  oWindow.Draw

END