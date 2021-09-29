;
; Event handler for slice tab
;
pro stel3d_widget_slicetab_event, ev

  widget_control, ev.top, GET_UVALUE=val
  widget_control, ev.id, GET_UVALUE=uval
  ;help, ev, /STRUCT
  
  val['oVolume'].GetProperty, DATA0=voldata
  sz = size(voldata)
  txtval = 0L
  
  oConf = val['oConf']
  oConf.GetProperty, SLICE_XY=slice_xy, SLICE_XZ=slice_xz, SLICE_YZ=slice_yz, $
    XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange, CONT_CUSTOM=cont_custom
  
  case uval of 
    'slicetab:XY':begin
      xy_img = voldata[*, *, ev.value]
      ztex=(val['oData']).getZSliceText()
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:XYText'), $
        SET_VALUE=strcompress(string(ztex[ev.value]), /REMOVE_ALL)      
      xy_img = reform(xy_img, sz[1], sz[2], /OVERWRITE)
      if cont_custom eq 0 then begin
        val['oXYContour'].SetProperty, DATA=xy_img, GEOMZ=ev.value, N_LEVELS=oConf.cont_nlevels
      endif else begin
        if oConf.unit eq 'count' then begin
          val['oXYContour'].SetProperty, DATA=xy_img, GEOMZ=ev.value, $
            C_VALUE=bytscl(oConf.cont_levels, MAX=oConf.color_max_val , MIN=oConf.color_min_val)
        endif else begin
          val['oXYContour'].SetProperty, DATA=xy_img, GEOMZ=ev.value, $
            C_VALUE=alog10(oConf.cont_levels)
        endelse
      endelse
      val['oXYImage'].SetProperty, DATA=xy_img
      val['oXYPlane'].GetProperty, DATA=data
      data[2,*] = ev.value
      val['oXYPlane'].SetProperty, DATA=data
      val['oWindow'].Draw
      slice_xy.position=ev.value
      oConf.SetProperty, SLICE_XY=slice_xy
    end
    'slicetab:XYCONTOUR':begin
      val['oXYContour'].SetProperty, HIDE=(~ev.select)
      val['oWindow'].Draw
      slice_xy.contour = (~ev.select)
      oConf.SetProperty, SLICE_XY=slice_xy
    end
    'slicetab:XYFILL':begin
      val['oXYPlane'].SetProperty, HIDE=(~ev.select)
      val['oWindow'].Draw
      slice_xy.fill = (~ev.select)
      oConf.SetProperty, SLICE_XY=slice_xy
    end
    'slicetab:XYText':begin
      widget_control, ev.id, GET_VALUE=tval
      tval=fix(tval)
      ztex=(val['oData']).getZSliceText()
      index = WHERE(ztex ge tval[0])
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:XYText'), $
        SET_VALUE=strcompress(string(ztex[index[0]]), /REMOVE_ALL)
      slice_xy.position=index[0]
      oConf.SetProperty, SLICE_XY=slice_xy
    end
    'slicetab:YZ':begin
      yz_img = voldata[ev.value, *, *]
      xtex=(val['oData']).getXSliceText()
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:YZText'), $
        SET_VALUE=strcompress(string(xtex[ev.value]), /REMOVE_ALL)
      yz_img = reform(yz_img, sz[2], sz[3], /OVERWRITE)
      if cont_custom eq 0 then begin
        res = stel3d_create_contour(yz_img, /YZPLANE, UPDATE=val['oYZContour'])
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
      yz_cont[0,*]=ev.value
      val['oYZContour'].SetProperty, DATA=yz_cont
      
      val['oYZImage'].SetProperty, DATA=yz_img
      val['oYZPlane'].GetProperty, DATA=data
      data[0,*] = ev.value ; update polyogon coordinate
      val['oYZPlane'].SetProperty, DATA=data
      val['oWindow'].Draw
      slice_yz.position=ev.value
      oConf.SetProperty, SLICE_YZ=slice_yz
    end
    'slicetab:YZCONTOUR':begin
      val['oYZContour'].SetProperty, HIDE=abs(1-ev.select)
      val['oWindow'].Draw
      slice_yz.fill = abs(1-ev.select)
      oConf.SetProperty, SLICE_YZ=slice_yz
    end
    'slicetab:YZFILL':begin
      val['oYZPlane'].SetProperty, HIDE=abs(1-ev.select)
      val['oWindow'].Draw
      slice_yz.fill = abs(1-ev.select)
      oConf.SetProperty, SLICE_YZ=slice_yz
    end
    'slicetab:YZText':begin
      widget_control, ev.id, GET_VALUE=tval
      tval=fix(tval)
      xtex=(val['oData']).getXSliceText()
      index = WHERE(xtex ge tval[0])
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:YZText'), $
        SET_VALUE=strcompress(string(xtex[index[0]]), /REMOVE_ALL)
      slice_yz.position=index[0]
      oConf.SetProperty, SLICE_YZ=slice_yz
    end
    'slicetab:XZ':begin
      xz_img = voldata[*, ev.value, *]
      ytex=(val['oData']).getYSliceText()
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:XZText'), $
        SET_VALUE=strcompress(string(ytex[ev.value]), /REMOVE_ALL)
      xz_img = reform(xz_img, sz[1], sz[3], /OVERWRITE)
      if cont_custom eq 0 then begin
        res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'])
      endif else begin
        if oConf.unit eq 'count' then begin
          res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'], $
            LEVELS=bytscl(oConf.cont_levels, MAX=oConf.color_max_val , MIN=oConf.color_min_val))
        endif else begin
          res = stel3d_create_contour(xz_img, /XZPLANE, UPDATE=val['oXZContour'], $
            LEVELS=alog10(oConf.cont_levels))
        endelse
      endelse
      val['oXZContour'].GetProperty, DATA=xz_cont
      xz_cont[1,*]=ev.value
      val['oXZContour'].SetProperty, DATA=xz_cont
      ;val['oXZContour'].SetProperty, DATA=xz_img, GEOMZ=sz[2]-ev.value
      val['oXZImage'].SetProperty, DATA=xz_img
      val['oXZPlane'].GetProperty, DATA=data
      data[1,*] = ev.value ; update polyogon coordinate
      val['oXZPlane'].SetProperty, DATA=data
      val['oWindow'].Draw
      slice_xz.position=ev.value
      oConf.SetProperty, SLICE_XZ=slice_xz
    end
    'slicetab:XZCONTOUR':begin
      val['oXZContour'].SetProperty, HIDE=abs(1-ev.select)
      val['oWindow'].Draw
      slice_xz.fill = abs(1-ev.select)
      oConf.SetProperty, SLICE_XZ=slice_xz
    end
    'slicetab:XZFILL':begin
      val['oXZPlane'].SetProperty, HIDE=abs(1-ev.select)
      val['oWindow'].Draw
      slice_xz.fill = abs(1-ev.select)
      oConf.SetProperty, SLICE_XZ=slice_xz
    end
    'slicetab:XZText':begin
      widget_control, ev.id, GET_VALUE=tval
      tval=fix(tval)
      ytex=(val['oData']).getYSliceText()
      index = WHERE(ytex ge tval[0])
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:XZText'), $
        SET_VALUE=strcompress(string(ytex[index[0]]), /REMOVE_ALL)
      slice_xz.position=index[0]
      oConf.SetProperty, SLICE_XZ=slice_xz
    end
    else: print, 'else'
  endcase
  
  
  
end