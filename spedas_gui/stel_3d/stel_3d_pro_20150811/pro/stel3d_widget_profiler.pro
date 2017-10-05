;
; main event handler
;
pro stel3d_widget_profiler_event, ev

;  widget_control, ev.top, GET_UVALUE=val
;  help, ev, /STRUCT
;  print, val

end
;
; Mouse motion event hander for Image window
;
function stel3d_widget_profiler_image_motion_event, oWinImage, x, y, keymods
  compile_opt idl2

  val = oWinImage.uvalue
  ;
  ; convert device coord to data coord
  xrange=(val['oImage']).xrange
  yrange=(val['oImage']).yrange
  res = (val['oImage']).ConvertCoord(x, y, /DEVICE, /TO_DATA)
  
  if (res[0] lt xrange[0]) or (res[0] gt xrange[1]) then return, 0
  if (res[1] lt yrange[0]) or (res[1] gt yrange[1]) then return, 0
  
  (val['oCross']).location = [fix(res[0]), fix(res[1])]
  print, 'image coord; ', fix(res[0]), fix(res[1])
  if (fix(res[0]) eq 22) && (fix(res[1]) eq 24) then begin
    print, 'test'
  endif
  
  hori = reform((val['imgdata'])[*,fix(res[1])])
  vert = reform((val['imgdata'])[fix(res[0]),*])  
  
  (val['oPlot1']).SetData, val['haxis'], hori
  (val['oPlot2']).SetData, val['vaxis'], vert
  
  return, 1
  
END
;
; Main
;
pro stel3d_widget_profiler, ev, XY=xy, YZ=yz, XZ=xz

  widget_control, ev.top, GET_UVALUE=val
 
  wbase = widget_base(GROUP=ev.top, /FLOATING, ROW=3, /MODAL)
  subBase1 = widget_base(wbase, /COL)
  label = widget_label(subBase1, VAlUE='Menu')
  subBase2 = widget_base(wbase, COL=2)
  wImage = widget_window(subBase2, XSIZE=500, YSIZE=500, UNITS=0, $
    MOUSE_MOTION_HANDLER='stel3d_widget_profiler_image_motion_event')
  wPlot = widget_window(subBase2, XSIZE=600, YSIZE=500)
  subbase3 = widget_base(wbase)
  closeButton = widget_button(subBase3, VALUE='Close', UVALUE='close')
  widget_control, wbase, /REALIZE
  ;
  ; Get window object references
  widget_control, wImage, GET_VALUE=oWinImage
  widget_control, wPlot, GET_VALUE=oWinPlot
  ;
  ; Get Initial information
  oConf = val['oConf']
  oData = val['oData']
  voldata = oData.GetVolumeData(/ORIGINAL) ;raw data
  coldata = oData.GetVolumeData() ;color strech data
  oPalette = oData.getPalette()
  oPalette.GetProperty, Red=r, Green=g, Blue=b
  xaxis = oData.getXSliceText()
  yaxis = oData.getYSliceText()
  zaxis = oData.getZSliceText()
  
  oConf.GetProperty, SLICE_XY=slice_xy, SLICE_XZ=slice_xz, SLICE_YZ=slice_yz, $
    COLOR_MIN_VAL=color_min_val, COLOR_MAX_VAL=color_max_val, $
    XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange
  
  if keyword_set(xy) then begin
    imgdata = reform(voldata[*,*,slice_xy.position])
    colimg = reform(coldata[*,*,slice_xy.position])
    sTitle = 'X-Y plane'
    sHtitle = '<x>'
    haxis = xaxis
    hrange = xrange
    sVtitle = '<y>'
    vaxis = yaxis
    vrange = yrange
  endif
  if keyword_set(yz) then begin
    imgdata = reform(voldata[slice_yz.position,*,*])
    colimg = reform(coldata[slice_yz.position,*,*])
    sTitle = 'Y-Z plane'
    sHtitle = '<y>'
    haxis = yaxis
    hrange = yrange
    sVtitle = '<z>'
    vaxis = zaxis
    vrange = zrange
  endif
  if keyword_set(xz) then begin
    imgdata = reform(voldata[*,slice_xz.position, *])
    colimg = reform(coldata[*,slice_xz.position, *])
    sTitle = 'X-Z plane'
    sHtitle = '<x>'
    haxis = xaxis
    hrange = yrange
    sVtitle = '<z>'
    vaxis = zaxis
    vrange = zrange
  endif
  
  ; Title
  oConf.GetProperty, CURTIME=curtime, AXIS_UNIT=unit
  sTitle = sTitle + ' ' + curtime + ' (' + unit + ')'
  
  oImage = image( colimg, RGB_TABLE=[[r],[g],[b]], $
                  CURRENT=oWinImage, $
                  POSITION=[0.18,0.15,0.9,0.9], $
;                  XTITLE=sHtitle, $
;                  YTITLE=sVtitle, $
                  AXIS_STYLE=1, $
                  TITLE=sTitle)
  oAxis=oImage.AXES
  oAxis[0].tickname=[string(fix(hrange[0])), '0', string(fix(hrange[1]))]
  oAxis[0].tickdir=1
  oAxis[0].tickfont_size=10
  oAxis[1].tickname=[string(fix(hrange[0])), '0', string(fix(hrange[1]))]
  oAxis[1].tickdir=1
  oAxis[1].tickfont_size=10

  oHText = text( 0.5, 0.05, sHtitle, Target=oWinImage)
  oVText = text( 0.02, 0.51, sVtitle, Target=oWinImage)

  ;
  ; Set corsshair in image window
  oCross = oImage.CROSSHAIR
  oCross.Transparency = 0
  oCross.Linestyle=0
  oCross.COLOR = 'red'
  oCross.THICK = 1
  ;
  ; Create Plot
  oPlot1 = plot(haxis, imgdata[*, 0], TITLE='Horizontal Profile', LAYOUT=[1,2,1], YRANGE=[color_min_val, color_max_val], CURRENT=oWinPlot)
  oPlot2 = plot(vaxis, imgdata[0, *], TITLE='Vertical Profile', LAYOUT=[1,2,2], YRANGE=[color_min_val, color_max_val], CURRENT=oWinPlot)
  oP1Axis=oPlot1.AXES
  oP1Axis[0].tickfont_size=10
  oP1Axis[1].tickfont_size=10
  oP2Axis=oPlot2.AXES
  oP2Axis[0].tickfont_size=10
  oP2Axis[1].tickfont_size=10
  ;
  ; Set values
  uval = hash()
  uval['oWinImage'] = oWinImage
  uval['oWinPlot'] = oWinPlot
  uval['oImage'] = oImage
  uval['oPlot1'] = oPlot1
  uval['oPlot2'] = oPlot2
  uval['oCross'] = oCross
  uval['oData'] = oData
  uval['oConf'] = oConf
;  uval['oVolume'] = oVolume
  uval['oConf'] = oConf
  uval['imgdata'] = imgdata
  uval['haxis'] = haxis
  uval['vaxis'] = vaxis
  
  oWinImage.uvalue= uval
  widget_control, wbase, SET_UVALUE=uval
  xmanager, 'stel3d_widget_profiler', wbase

end
;
;
;pro test_stel3d_widget_profiler
;
;  top = widget_base(xs=300, ys=300)
;  stel3d_widget_profiler, top
;  
;end