


;
; Event handler for Color settings
;
pro stel3d_widget_colortab_event, ev
compile_opt idl2

  widget_control, ev.top, GET_UVALUE=val
  widget_control, ev.id, GET_UVALUE=uval
  oData = val['oData']
  oConf = val['oConf']
  oColorbar = val['oColorbar']
  oWindow = val['oWindow']
  oVolume = val['oVolume']
 
  case uval of
    'colortab:ColorMinText':begin
      widget_control, ev.id, GET_VALUE=minval
      oConf.color_min_val=float(minval)
      ;
      ;update colorbar
      oColorbar.GetProperty, TITLE=oBartitle, MAJOR=major, TICKTEXT=oTicktextBar
      nrange = [oConf.color_min_val, oConf.color_max_val]
      fStep = (max(nrange)-min(nrange))/(major-1)
      oTicktextBar.Setproperty, FONT=oFont, $
        STRINGS=strtrim(string(findgen(major)*fStep + min(nrange), FORMAT='(1E10.1)'),1)
      ;
      ;update volume data
      voldata = oData.GetVolumedata()
      oVolume.SetProperty, DATA0=voldata
      sz = size(voldata)
      ;
      ;update xy slice
      oConf.GetProperty, SLICE_XY=slice_xy, SLICE_XZ=slice_xz, SLICE_YZ=slice_yz
      slice_xy = slice_xy.position
      slice_yz = slice_yz.position
      slice_xz = slice_xz.position
      xy_img = voldata[*, *, slice_xy]
      xy_img = reform(xy_img, sz[1], sz[2], /OVERWRITE)
      if oConf.cont_custom eq 0 then begin
        (val['oXYContour']).SetProperty, DATA=xy_img, GEOMZ=slice_xy, N_LEVELS=oConf.cont_nlevels
      endif else begin
        if oConf.unit eq 'count' then begin
          (val['oXYContour']).SetProperty, DATA=xy_img, GEOMZ=slice_xy, $
            C_VALUE=bytscl(oConf.cont_levels, MAX=oConf.color_max_val, MIN=oConf.color_min_val)
        endif else begin
          (val['oXYContour']).SetProperty, DATA=xy_img, GEOMZ=slice_xy, $
            C_VALUE=alog10(oConf.cont_levels)
        endelse
      endelse
      (val['oXYImage']).SetProperty, DATA=xy_img
      (val['oXYPlane']).GetProperty, DATA=data
      data[2,*] = slice_xy
      (val['oXYPlane']).SetProperty, DATA=data
      ;
      ;update yz slice
      yz_img = voldata[slice_yz, *, *]
      yz_img = reform(yz_img, sz[2], sz[3], /OVERWRITE)
      if oConf.cont_custom eq 0 then begin
        res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=val['oYZContour'], NLEVELS=oConf.cont_nlevels)
      endif else begin
        if oConf.unit eq 'count' then begin
          res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=val['oYZContour'], $
            LEVELS=bytscl(oConf.cont_levels, MAX=oConf.color_max_val , MIN=oConf.color_min_val))
        endif else begin
          res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=val['oYZContour'], $
            LEVELS=alog10(oConf.cont_levels))
        endelse
      endelse
      val['oYZContour'].GetProperty, DATA=yz_cont
      yz_cont[0,*]=slice_yz
      val['oYZContour'].SetProperty, DATA=yz_cont
      val['oYZImage'].SetProperty, DATA=yz_img
      val['oYZPlane'].GetProperty, DATA=data
      data[0,*] = slice_yz ; update polyogon coordinate
      val['oYZPlane'].SetProperty, DATA=data
      ;
      ;update xz slice
      xz_img = voldata[*, slice_xz, *]
      xz_img = reform(xz_img, sz[1], sz[3], /OVERWRITE)
      if oConf.cont_custom eq 0 then begin
        res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'], NLEVELS=oConf.cont_nlevels)
      endif else begin
        res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'], $
         LEVELS=bytscl(oConf.cont_levels, MAX=oConf.color_max_val , MIN=oConf.color_min_val))
      endelse
      val['oXZContour'].GetProperty, DATA=xz_cont
      xz_cont[1,*]=slice_xz
      val['oXZContour'].SetProperty, DATA=xz_cont
      val['oXZImage'].SetProperty, DATA=xz_img
      val['oXZPlane'].GetProperty, DATA=data
      data[1,*] = slice_xz ; update polyogon coordinate
      val['oXZPlane'].SetProperty, DATA=data
      oWindow.Draw
    end
    'colortab:ColorMaxText':begin
      widget_control, ev.id, GET_VALUE=maxval
      ;
      ;update colorbar
      oConf.color_max_val=float(maxval)
      oColorbar.GetProperty, TITLE=oBartitle, MAJOR=major, TICKTEXT=oTicktextBar
      nrange = [oConf.color_min_val, oConf.color_max_val]
      fStep = (max(nrange)-min(nrange))/(major-1)
      oTicktextBar.Setproperty, FONT=oFont, $
        STRINGS=strtrim(string(findgen(major)*fStep + min(nrange), FORMAT='(1E10.1)'),1)
      ;
      ;update volume data
      voldata = oData.GetVolumedata()
      oVolume.SetProperty, DATA0=voldata
      sz = size(voldata)
      ;
      ;update xy slice
      oConf.GetProperty, SLICE_XY=slice_xy, SLICE_XZ=slice_xz, SLICE_YZ=slice_yz, CONT_CUSTOM=cont_custom
      slice_xy = slice_xy.position
      slice_yz = slice_yz.position
      slice_xz = slice_xz.position
      xy_img = voldata[*, *, slice_xy]
      xy_img = reform(xy_img, sz[1], sz[2], /OVERWRITE)
      if cont_custom eq 0 then begin
        (val['oXYContour']).SetProperty, DATA=xy_img, GEOMZ=slice_xy, N_LEVELS=oConf.cont_nlevels
      endif else begin
        if oConf.unit eq 'count' then begin
          (val['oXYContour']).SetProperty, DATA=xy_img, GEOMZ=slice_xy, $
            C_VALUE=bytscl(oConf.cont_levels, MAX=oConf.color_max_val, MIN=oConf.color_min_val)
        endif else begin
          (val['oXYContour']).SetProperty, DATA=xy_img, GEOMZ=slice_xy, $
            C_VALUE=alog10(oConf.cont_levels)
        endelse
      endelse
      (val['oXYImage']).SetProperty, DATA=xy_img
      (val['oXYPlane']).GetProperty, DATA=data
      data[2,*] = slice_xy
      (val['oXYPlane']).SetProperty, DATA=data
      ;
      ;update yz slice
      yz_img = voldata[slice_yz, *, *]
      yz_img = reform(yz_img, sz[2], sz[3], /OVERWRITE)
      if cont_custom eq 0 then begin
        res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=val['oYZContour'], NLEVELS=oConf.cont_nlevels)
      endif else begin
        if oConf.unit eq 'count' then begin
          res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=val['oYZContour'], $
            LEVELS=bytscl(oConf.cont_levels, MAX=oConf.color_max_val, MIN=oConf.color_min_val))
        endif else begin
          res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=val['oYZContour'], $
            LEVELS=alog10(oConf.cont_levels))
        endelse
      endelse
      val['oYZContour'].GetProperty, DATA=yz_cont
      yz_cont[0,*]=slice_yz
      val['oYZContour'].SetProperty, DATA=yz_cont
      val['oYZImage'].SetProperty, DATA=yz_img
      val['oYZPlane'].GetProperty, DATA=data
      data[0,*] = slice_yz ; update polyogon coordinate
      val['oYZPlane'].SetProperty, DATA=data
      ;
      ;update xz slice
      xz_img = voldata[*, slice_xz, *]
      xz_img = reform(xz_img, sz[1], sz[3], /OVERWRITE)
      if cont_custom eq 0 then begin
        res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'], NLEVELS=oConf.cont_nlevels)
      endif else begin
        if oconf.unit eq 'count' then begin
          res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'], $
            LEVELS=bytscl(oConf.cont_levels, MAX=oConf.color_max_val, MIN=oConf.color_min_val))
        endif else begin
          res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'], $
            LEVELS=alog10(oConf.cont_levels))
        endelse
      endelse
      val['oXZContour'].GetProperty, DATA=xz_cont
      xz_cont[1,*]=slice_xz
      val['oXZContour'].SetProperty, DATA=xz_cont
      val['oXZImage'].SetProperty, DATA=xz_img
      val['oXZPlane'].GetProperty, DATA=data
      data[1,*] = slice_xz ; update polyogon coordinate
      val['oXZPlane'].SetProperty, DATA=data
      ;
      ; redraw
      oWindow.Draw
    end
    'colortab:AutoButton':begin
      wContTextLevels=widget_info(ev.top, FIND_BY_UNAME='colortab:ContTextLevels')
      wContNlevelsText=widget_info(ev.top, FIND_BY_UNAME='colortab:ContNlevelsText')
      widget_control, wContTextLevels, SENSITIVE=0
      widget_control, wContNlevelsText, SENSITIVE=1   
      oConf.cont_custom=0
    end
    'colortab:CustomButton':begin
      wContTextLevels=widget_info(ev.top, FIND_BY_UNAME='colortab:ContTextLevels')
      wContNlevelsText=widget_info(ev.top, FIND_BY_UNAME='colortab:ContNlevelsText')
      widget_control, wContTextLevels, SENSITIVE=1
      widget_control, wContNlevelsText, SENSITIVE=0
      oConf.cont_custom=1
    end
    'colortab:ContNlevelsText':begin
      widget_control, ev.id, GET_VALUE=nlevels
      val['oVolume'].GetProperty, DATA0=voldata
      sz = size(voldata)
      oConf.cont_nlevels =fix(nlevels)
      ;
      ;Update XYcontour
      val['oXYContour'].SetProperty, N_LEVELS=oConf.cont_nlevels
      ;
      ;Update YZcontour
      yz_pos=(oConf.SLICE_YZ).position
      yz_img = voldata[yz_pos, *, *]
      yz_img = reform(yz_img, sz[2], sz[3], /OVERWRITE)
      res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=val['oYZContour'], NLEVELS=oConf.cont_nlevels)
      (val['oYZContour']).GetProperty, DATA=yz_cont
      yz_cont[0,*]=yz_pos
      val['oYZContour'].SetProperty, DATA=yz_cont
      ;
      ;Update XZContour
      xz_pos=(oConf.SLICE_XZ).position
      xz_img = voldata[*, xz_pos, *]
      xz_img = reform(xz_img, sz[1], sz[3], /OVERWRITE)
      res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'], NLEVELS=oConf.cont_nlevels)
      (val['oXZContour']).GetProperty, DATA=xz_cont
      xz_cont[1,*]=xz_pos
      (val['oXZContour']).SetProperty, DATA=xz_cont
      oWindow.Draw
    end
    'colortab:ContTextLevels':begin
      widget_control, ev.id, GET_VALUE=strLevels
      strLevels = strsplit(strLevels, ',', /EXTRACT,COUNT=count)
      if count le 0 then begin
        widget_control, ev.id, SET_VALUE=''
        return
      endif
      oConf.cont_levels = float(strLevels)
      val['oVolume'].GetProperty, DATA0=voldata
      sz = size(voldata)
      ;
      ; update XYcontour
      if oConf.unit eq 'count' then begin
        (val['oXYContour']).SetProperty, C_VALUE=bytscl(oConf.cont_levels, MAX=oConf.color_max_val , MIN=oConf.color_min_val)
      endif else begin
        (val['oXYContour']).SetProperty, C_VALUE=alog10(oConf.cont_levels)
      endelse
      ;
      ; update YZcontour
      yz_pos=(oConf.SLICE_YZ).position
      yz_img = voldata[yz_pos, *, *]
      yz_img = reform(yz_img, sz[2], sz[3], /OVERWRITE)
      if oConf.unit eq 'count' then begin
        res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=val['oYZContour'], $
           LEVELS=bytscl(oConf.cont_levels, MAX=oConf.color_max_val, MIN=oConf.color_min_val))
      endif else begin
        res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=val['oYZContour'], $
          LEVELS=alog10(oConf.cont_levels))
      endelse
      (val['oYZContour']).GetProperty, DATA=yz_cont
      yz_cont[0,*]=yz_pos
      val['oYZContour'].SetProperty, DATA=yz_cont
      ;
      ; update XZcontour
      xz_pos=(oConf.SLICE_XZ).position
      xz_img = voldata[*, xz_pos, *]
      xz_img = reform(xz_img, sz[1], sz[3], /OVERWRITE)
      if oConf.unit eq 'count' then begin
        res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'], $
          LEVELS=bytscl(oConf.cont_levels, MAX=oConf.color_max_val, MIN=oConf.color_min_val))
      endif else begin
        res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'], $
          LEVELS=alog10(oConf.cont_levels))
      endelse
      (val['oXZContour']).GetProperty, DATA=xz_cont
      xz_cont[1,*]=xz_pos
      (val['oXZContour']).SetProperty, DATA=xz_cont
      ;
      ; redraw
      oWindow.Draw
    end
    else:print, 'else'
  endcase

end