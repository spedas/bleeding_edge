;
; Events for Range Tab
;
pro stel3d_widget_rangetab_event, ev

  widget_control, ev.top, GET_UVALUE=val
  widget_control, ev.id, GET_UVALUE=uval
  ;print, 'Range Tab Event'
  
  oVolume=val['oVolume']
  oData=val['oData']
  oConf=val['oConf']
  oWindow=val['oWindow']
  sz = float(oData.GetVolDimension())
  
  case uval of
    'rangetab:XMAXSLIDER':begin
      index = ev.value
      if index gt val['xdispmin'] then begin
        val['xdispmax']=index
        xrange = oData.getXSouceRange()
        xdatadim = float(xrange[1]) - xrange[0]
        xdim = sz[0]
        dataval = xrange[0] + ((xdatadim/xdim)*index)
        widget_control, widget_info(ev.top, FIND_BY_UNAME='rangetab:XMAXTEXT'), SET_VALUE=strcompress(string(dataval, FORMAT='(1I)'), /REMOVE_ALL)
      endif else begin
        widget_control, ev.id, SET_VALUE=val['xdispmax']
      endelse
    end
    'rangetab:XMINSLIDER':begin
       index = ev.value
      if index lt val['xdispmax'] then begin
        val['xdispmin']=index
        xrange = oData.getXSouceRange()
        xdatadim = float(xrange[1]) - xrange[0]
        xdim = sz[0]
        dataval = xrange[0] + ((xdatadim/xdim)*index)
        widget_control, widget_info(ev.top, FIND_BY_UNAME='rangetab:XMINTEXT'), SET_VALUE=strcompress(string(dataval, FORMAT='(1I)'), /REMOVE_ALL)
      endif else begin
        widget_control, ev.id, SET_VALUE=val['xdispmin']
      endelse
    end
    'rangetab:YMAXSLIDER':begin
      index = ev.value
      if index gt val['ydispmin'] then begin
        val['ydispmax']=index
        yrange = oData.getYSouceRange()
        ydatadim = float(yrange[1]) - yrange[0]
        ydim = sz[1]
        dataval = yrange[0] + ((ydatadim/ydim)*index)
        widget_control, widget_info(ev.top, FIND_BY_UNAME='rangetab:YMAXTEXT'), SET_VALUE=strcompress(string(dataval, FORMAT='(1I)'), /REMOVE_ALL)
      endif else begin
        widget_control, ev.id, SET_VALUE=val['ydispmax']
      endelse
    end
    'rangetab:YMINSLIDER':begin
      index = ev.value
      if index lt val['ydispmax'] then begin
        val['ydispmin']=index
        yrange = oData.getYSouceRange()
        ydatadim = float(yrange[1]) - yrange[0]
        ydim = sz[1]
        dataval = yrange[0] + ((ydatadim/ydim)*index)
        widget_control, widget_info(ev.top, FIND_BY_UNAME='rangetab:YMINTEXT'), SET_VALUE=strcompress(string(dataval, FORMAT='(1I)'), /REMOVE_ALL)
      endif else begin
        widget_control, ev.id, SET_VALUE=val['ydispmin']
      endelse
    end
    'rangetab:ZMAXSLIDER':begin
      index = ev.value
      if index gt val['zdispmin'] then begin
        val['zdispmax']=index
        zrange = oData.getZSouceRange()
        zdatadim = float(zrange[1]) - zrange[0]
        zdim = sz[2]
        dataval = zrange[0] + ((zdatadim/zdim)*index)
        widget_control, widget_info(ev.top, FIND_BY_UNAME='rangetab:ZMAXTEXT'), SET_VALUE=strcompress(string(dataval, FORMAT='(1I)'), /REMOVE_ALL)
      endif else begin
        widget_control, ev.id, SET_VALUE=val['zdispmax']
      endelse
    end
    'rangetab:ZMINSLIDER':begin
      index = ev.value
      if index lt val['zdispmax'] then begin
        val['zdispmin']=index
      endif else begin
        widget_control, ev.id, SET_VALUE=val['zdispmin']
        zrange = oData.getZSouceRange()
        zdatadim = float(zrange[1]) - zrange[0]
        zdim = sz[2]
        dataval = zrange[0] + ((zdatadim/zdim)*index)
        widget_control, widget_info(ev.top, FIND_BY_UNAME='rangetab:ZMINTEXT'), SET_VALUE=strcompress(string(dataval, FORMAT='(1I)'), /REMOVE_ALL)
      endelse
    end
    'rangetab:XDEFAULT':begin
      xrange = oData.getXSouceRange()
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:XMAXSLIDER'), SET_VALUE=sz[0]
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:XMINSLIDER'), SET_VALUE=0
      val['xdispmin'] = 0
      val['xdispmax'] = sz[0] 
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:XMAXTEXT'), SET_VALUE=strcompress(string(xrange[1], FORMAT='(1I)'), /REMOVE_ALL)
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:XMINTEXT'), SET_VALUE=strcompress(string(xrange[0], FORMAT='(1I)'), /REMOVE_ALL)
    end
    'rangetab:YDEFAULT':begin
      yrange = oData.getYSouceRange()
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:YMAXSLIDER'), SET_VALUE=sz[1]
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:YMINSLIDER'), SET_VALUE=0
      val['ydispmin'] = 0
      val['ydispmax'] = sz[1]
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:YMAXTEXT'), SET_VALUE=strcompress(string(yrange[1], FORMAT='(1I)'), /REMOVE_ALL)
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:YMINTEXT'), SET_VALUE=strcompress(string(yrange[0], FORMAT='(1I)'), /REMOVE_ALL)
    end
    'rangetab:ZDEFAULT':begin
      zrange = oData.getZSouceRange()
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:ZMAXSLIDER'), SET_VALUE=sz[2]
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:ZMINSLIDER'), SET_VALUE=0
      val['zdispmin'] = 0
      val['zdispmax'] = sz[2]
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:ZMAXTEXT'), SET_VALUE=strcompress(string(zrange[1], FORMAT='(1I)'), /REMOVE_ALL)
      widget_control,  widget_info(ev.top, FIND_BY_UNAME='rangetab:ZMINTEXT'), SET_VALUE=strcompress(string(zrange[0], FORMAT='(1I)'), /REMOVE_ALL)
    end
    else: 
  endcase
  ;
  ; For Volume data
  bounds = [val['xdispmin'],val['ydispmin'], val['zdispmin'], $
    val['xdispmax'],val['ydispmax'], val['zdispmax']]
    
  ;  xDim = val['xdispmax'] - val['xdispmin'] 
  ;  yDim = val['ydispmax'] - val['ydispmin'] 
  ;  zDim = val['zdispmax'] - val['zdispmin'] 
  ;  
  ;  maxDim = MAX([xDim, yDim, zDim])
  ;  xs = [-0.5, (xdim/sz[0])/xdim]
  ;  ys = [-0.5, (ydim/sz[1])/ydim]
  ;  zs = [-0.5, (zdim/sz[2])/zdim]
  oVolume.SetProperty, BOUNDS=bounds
  ;
  ; For Axis 
  
  ;
  ; For Isodata
  
  ;
  ; For Scatter Data
  oWindow.Draw

end