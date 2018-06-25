;
;; create contour object
;
function stel3d_create_vector, vec, UPDATE=oModel, COLOR=color, LENGTH=length, THICK=thick, SHOW=show, $
  MAX_MAG_VEC=max_mag_vec, MAX_VEL_VEC=max_vel_vec
  
  if ~keyword_set(length) then length = 'full'
  if ~keyword_set(show) then show = 0
  if ~keyword_set(color) then color = 'black'
  if n_elements(vec) ne 3 then return, -1
  ;if ~keyword_set(max_mag_vec) and ~keyword_set()
  
  vec_length = vec[0]^2 + vec[1]^2 + vec[2]^2
  if n_elements(max_mag_vec) eq 3 then begin
    max_length = max_mag_vec[0]^2 + max_mag_vec[1]^2 + max_mag_vec[2]^2
    ratio = vec_length/max_length
  endif
  if n_elements(max_vel_vec) eq 3 then begin
    max_length = max_vel_vec[0]^2 + max_vel_vec[1]^2 + max_vel_vec[2]^2
    ratio = vec_length/max_length
  endif
  
  if ratio eq !null then ratio = 1
  ;print, 'Vector RATIO', ratio
  scale=1
  case length of
    'full': scale=1*ratio
    'half': scale=0.5*ratio
    'quarter': scale=0.25*ratio
  endcase
  
  if ~keyword_set(oModel) then begin
    update = 0
    oPolygon=obj_new('IDLgrPolyline', [-0.4,0.4,0.35,0.4,0.35],[0,0,0.03,0,-0.03],[0,0,0,0,0], COLOR=color, THICK=thick, HIDE=~(show))
    oModel=obj_new('IDLgrModel')
    oModel.Add, oPolygon 
  endif else begin
    ;oPolygon=oModel.Get(ISA='IDLgrPolyline')
    oModel.reset
    update = 1
  endelse
  
  x = vec[0]
  y = vec[1]
  z = vec[2]
  
  idx = where(vec eq 0, count, COMPLEMENT=B_C, NCOMPLEMENT=count_c)
  case (count) of
    ;-------------------------
    ; WHEN ALL 3 VECTOR COMPONENTS ARE NON-ZERO. 
    ; 全ての辺に長さがある場合
    0: begin
      ; ↑y→x　軸z
      angle1 = getAngle([x,0,z], [x,y,z])
      if y lt 0 then angle1 = -angle1
      oModel->Rotate, [0,0,1], angle1
      ; ↑z→y　軸z
      angle2 = getAngle([0.5,0,0], [x,z,0])
      if z lt 0 then angle2 = -angle2
      oModel->Rotate, [0,-1,0], angle2
    end
    ;-------------------------
    ; WHEN 2 OF THE 3 VECTOR COMPONENTS ARE NON-ZERO. 
    ; ２辺に長さがある場合
    1: begin
      case (idx) of
        ; ↑z→y　軸x
        0: begin
          oModel->Rotate, [0,0,1], 90 ;x->y
          angle = getAngle([0.5,0,0], [y,z,0])
          if z lt 0 then angle = -angle
          oModel->Rotate, [1,0,0], angle
        end
        ; ↑x→z　軸y
        1: begin
          oModel->Rotate, [0,-1,0], 90 ;x->z
          angle = getAngle([0.5,0,0], [z,x,0])
          if x lt 0 then angle = -angle
          oModel->Rotate, [0,1,0], angle
        end
        ; ↑y→x　軸z
        else: begin
          angle = getAngle([0.5,0,0], [x,y,0])
          if y lt 0 then angle = -angle
          oModel->Rotate, [0,0,1], angle
        end
      endcase
    end
    ;-------------------------
    ; WHEN ONLY 1 COMPONENT IS NON-ZERO. 
    ; １辺に長さがある場合
    2: begin
      case (B_C) of
        ; ONLY X 
        ; xのみ
        0: begin
          Axis = [0,0,1]
        end
        ; ONLY Y 
        ; ｙのみ
        1: begin
          oModel->Rotate, [0,0,1], 90
          Axis = [0,0,1]
        end
        ; ONLY Z 
        ; zのみ
        else: begin
          oModel->Rotate, [0,1,0], -90
          Axis = [0,1,0]
        end
      endcase
      if vec[B_C] lt 0 then begin
        oModel->Rotate, Axis, 180
      endif
    end
    else: begin
    end
  endcase
  
  oModel.Scale, scale, scale, scale
  if ~update then return, oModel else return, !null
  
end
;
; create contour object
;
function stel3d_create_contour, input, XYPLANE=xyplane, YZPLANE=yzplane, XZPLANE=xzplane, UPDATE=oUpdate, NLEVELS=nlevels, LEVELS=levels

  if size(input, /N_DIMENSIONS) ne 2 then message, 'invalid input'
  if ~keyword_set(xyplane) and  ~keyword_set(yzplane) and  ~keyword_set(xzplane) then xyplane=1
  if ~keyword_set(nlevels) then nlevels=8

  if keyword_set(levels) then begin
    contour, input, LEVELS=levels, /PATH_DATA_COORDS, PATH_XY=path_xy, PATH_INFO=path_info, CLOSED=0
  endif else begin
    contour, input, NLEVELS=nlevels, /PATH_DATA_COORDS, PATH_XY=path_xy, PATH_INFO=path_info, CLOSED=0
  endelse
  ;
  ;
  if path_xy eq !null then begin
    if keyword_set(oUpdate) then begin
      oUpdate.SetProperty, DATA=[transpose([0,0,0]),transpose([0,0,0]),transpose([0,0,0])], POLYLINES=0
      return, !null
    endif else begin
      return, oPolyline = obj_new('IDLgrPolyline')
    endelse
  endif
  
  n_path_info = path_info.n
  cnt=0
  ;
  ; create polyline connect information
  for i=0L, n_elements(n_path_info)-1 do begin
    elem = n_path_info[i]
    if i eq 0 then begin
      ind = [lindgen(elem),0]
      polylines = [elem+1, ind+cnt]
    endif else begin
      ind = [lindgen(elem),0]
      polylines = [polylines, elem+1, ind+cnt]
    endelse
    cnt = polylines[-2]+1
  endfor
  
  ;help, polylines
  path1 = transpose(path_xy[0,*])
  path2 = transpose(path_xy[1,*])
  path3 = path2
  path3[*] = 0
  
;  save, FILENAME=dialog_pickfile(), polylines, path1, path2, path3, path_info    
  if keyword_set(xyplane) then begin
    ;print, 'create xyplane contour'
    oPolyline = obj_new('IDLgrPolyline', path1, path2, path3, POLYLINES=polylines)
  endif
  if keyword_set(yzplane) then begin
    ;print, 'create yzplane contour'
    if keyword_set(oUpdate) then begin
      oUpdate.SetProperty, DATA=[transpose(path3),transpose(path1),transpose(path2)], POLYLINES=polylines
      return, !null
    endif
    oPolyline = obj_new('IDLgrPolyline',  path3, path1, path2, POLYLINES=polylines)
  endif
  if keyword_set(xzplane) then begin
    ;print, 'create xzplane contour'
    if keyword_set(oUpdate) then begin
      oUpdate.SetProperty, DATA=[transpose(path1),transpose(path3),transpose(path2)], POLYLINES=polylines
      return, !null
    endif
    oPolyline = obj_new('IDLgrPolyline', path1, path3, path2, POLYLINES=polylines)
  endif
  
  if obj_valid(oPolyline) then return, oPolyline else return, obj_valid(oPolyline)

end
;
; create Scatter Plot
;
function stel3d_create_scatter, oData, MINVAL=minval, MAXVAL=maxval, UPDATE=oScatter

  if ~obj_valid(oData) then message, 'invalid object'

  fX = oData->GetX()
  fY = oData->GetY()
  fZ = oData->GetZ()
  fN = oData->GetN()
  if fN eq !NULL then message, 'no Data'
  ;  fMinN = Min(fN, MAX=fMaxN)
  ;
  ; store original values
;  allmin = min(fn, MAX=allmax)
  orange = oData->getNSouceRange()
  allmin = orange[0]
  allmax = orange[1]
  
;2016/02/17 by Kuni 
if allmax ge 1. then begin 

  xrange = oData.getXSouceRange()
  yrange = oData.getYSouceRange()
  zrange = oData.getZSouceRange()

  if ~keyword_set(minval) then minval=min(fN)
  if ~keyword_set(maxval) then maxval=max(fN)
  ;^M
  ; subset by data range specified by keywords
  pos = where((fN ge minval) and (fn le maxval))
  fX = fX[pos]
  fY = fY[pos]
  fZ = fZ[pos]
  fN = fN[pos]
  ;
  ; RE-SCALING OF N (0-255)
  ; N値を0～255の値にスケーリングする
  ; ToDo: change if psd
  ;
  bN = bytscl(fN, MAX=allmax, MIN=allmin)

endif else begin 

     xrange = oData.getXSouceRange()
     yrange = oData.getYSouceRange()
     zrange = oData.getZSouceRange()
  
     ;if ~keyword_set(minval) then minval=alog10(min(fN))
     ;if ~keyword_set(maxval) then maxval=alog10(max(fN))
     if ~keyword_set(minval) then minval=allmin
     if ~keyword_set(maxval) then maxval=allmax 
     ;
     ; subset by data range specified by keywords
     pos = where((fN ge minval) and (fn le maxval))
     fX = fX[pos]
     fY = fY[pos]
     fZ = fZ[pos]
     fN = fN[pos]
     ;
     ; RE-SCALING OF N (0-255) 
     ; N値を0～255の値にスケーリングする
     ;
     bN = bytscl(alog10(fN), MAX=alog10(allmax),MIN=alog10(allmin), /nan) 
endelse 
;2016/02/17 by Kuni -END-


  oPalette = oData->getPalette()
  oPalette->GetProperty, Red=bRed, Green=bGreen, Blue=bBlue

  ; MAKE SYMBOL and RELATED LINES. 
  ; Symbolとその付随線の生成を行う。
  lDataNum = n_elements(fX)
  olSymbols=objarr(lDataNum)
  for j=0, lDataNum-1 do begin
    cube = obj_new('cube', COLOR=[bRed[bN[j]], bGreen[bN[j]], bBlue[bN[j]]])
    olSymbols[j] = obj_new('IDLgrSymbol', cube, size=50)
  endfor

  if keyword_set(oScatter) then begin 
    if ~obj_valid(oScatter) then message, 'invalid object'
    
    oScatter.GetProperty, SYMBOL=oldSymbols
    foreach elem, oldSymbols do obj_destroy, elem
    
    oScatter.SetProperty, DATA=[transpose(fX),transpose(fY),transpose(fZ)], SYMBOL=olSymbols
    return, !null
  endif else begin
    ; CREATE POLYLINE OBJECT. 
    ; Polylineオブジェクトを生成する。
    oScatter = obj_new('IDLgrPolyline', fx, fy, fz, LineStyle=6, SYMBOL=olSymbols)
    ;oScatter.GetProperty, XRange=xrange, YRange=yrange, ZRange=zrange
    ;
    ; SCALING 
    ; スケーリング
    xMax = abs(xrange[0]-xrange[1])
    yMax = abs(yrange[0]-yrange[1])
    zMax = abs(zrange[0]-zrange[1])
    maxDim = max([xMax, yMax, zMax])
    xs = [0, 1.0/maxDim]
    ys = [0, 1.0/maxDim]
    zs = [0, 1.0/maxDim]
    oScatter.SetProperty, XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs
  endelse
  
  return, oScatter
end
;
; create ISOSURFACE
;
function stel3d_create_isosurface, oVol, iso_level, UPDATE=oISO
  
  if ~obj_valid(oVol) then message, 'invalid input'
  if n_elements(iso_level ne 2) then message, 'invalid input'
  
  oVol.GetProperty, DATA0=data0, XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs, /NO_COPY
  if data0 eq !null then return,0
    empty_indx = where(finite(data0) eq 0)
  If empty_indx[0] ne -1 then begin
    data0[empty_indx] = min(data0) - 1.e9
  endif
  
  ;IsoSurface, data0, isosurface_threshold, verts, conn
  ;shade_volume, data0, isosurface1_threshold, verts, conn
  interval_volume, data0, iso_level[0], iso_level[1], verts, conn
  ;in case data is uniform or out of range
  if conn[0] eq -1 then begin
    message, /continue, 'cannot construct isosurface'
    return, obj_new('IDLgrPolygon', COLOR=[127,127,127], SHADING=1, $
                     XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs)
  endif
  conn = tetra_surface(verts, conn)
  oVol.SetProperty, DATA0=data0, /NO_COPY
  if (n_elements(verts) le 0) then begin
    verts=bytarr(3,3)
    conn=0
  endif
  
  if keyword_set(oISO) then begin
    if ~obj_isa(oISO, 'IDLgrPolygon') then rerutn, 0
    oISO.SetProperty, DATA=verts, POLYGONS=conn
    return, 1
  endif else begin
    oIso = obj_new('IDLgrPolygon', COLOR=[127,127,127], $
      DATA=verts, POLYGONS=conn, SHADING=1, $
      XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs)
      
    return, oIso
  endelse
  
end
;
; save image
;
pro stel3d_save_image, img, type

  filename = 'screen'
  oImage = image(img, /BUFFER, MARGIN=0)
  stime = SYSTIME(/JULIAN)
  CALDAT, stime, mo, d, y, h, mi, s
  uniq=string(y,FORMAT='(I0)')+string(mo,FORMAT='(I02)')+string(d,FORMAT='(I02)') $
       +string(h,FORMAT='(I02)')+string(mi,FORMAT='(I02)')+string(round(s),FORMAT='(I02)')
  filename = 'screen_' + uniq
  case type of
    'png': write_png, filename+'.png', img
    'eps': oImage.save, filename+'.eps'
  endcase
  
end
;
;
;
pro stel3d_widget_cleanup, ev

  ; set initial color table 
  loadct, 39, /SILENT

end
;
; Main Event Handler
;
pro stel3d_widget_event, ev

  widget_control, ev.top, GET_UVALUE=val
  widget_control, ev.id, GET_UVALUE=uval
  
  ;help, ev, /STRUCT
  if (tag_names(ev, /STRUCTURE_NAME) eq  $
    'WIDGET_KILL_REQUEST') then begin
    widget_control, ev.top, /DESTROY
    return
  endif
  
  if ev.top eq ev.id then begin
    widget_control, ev.top, TLB_GET_SIZE=size
    widget_control, widget_info(ev.top, FIND_BY_UNAME='main:DRAW'),  XSIZE=size[0]-350, YSIZE=size[1]
    val['oWindow'].draw
    return
  endif
  
  if uval eq !null then return
  case uval of
    'main:SCATTER':begin
      val['oScatter'].SetProperty, HIDE=abs(1-ev.select)
      val['oWindow'].draw
    end
    'main:VOLUME':begin
       val['oVolume'].SetProperty, HIDE=abs(1-ev.select)
      val['oWindow'].draw
    end
    'main:ISO1':begin
      val['oISO1'].SetProperty, HIDE=abs(1-ev.select)
      val['oWindow'].draw
    end
    'main:ISO2':begin
      val['oISO2'].SetProperty, HIDE=abs(1-ev.select)
      val['oWindow'].draw
    end
    'main:SAVETYPE':begin
      case ev.index of
        0: val['SaveType']='png'
        1: val['SaveType']='eps'
      end
    end
    'main:SAVE':begin
;      print, 'Saving files Format is ' + val['SaveType']
      val['oWindow'].GetProperty, IMAGE_DATA=image
      stel3d_save_image, image, val['SaveType']
    end
    'main:COORDBUTTON':begin
      case ev.index of
        0:begin
          (val['oConf']).SetProperty, SC_COORD=1B, MAG_COORD=0B
          widget_control, widget_info(ev.top, FIND_BY_UNAME='vectortab:MAGVECTORBTN'), SENSITIVE=1
          widget_control, widget_info(ev.top, FIND_BY_UNAME='vectortab:VELOVECTORBTN'), SENSITIVE=1
          widget_control, widget_info(ev.top, FIND_BY_UNAME='vectortab:USERVECTORBTN'), SENSITIVE=1
        end
        1:begin
          (val['oConf']).SetProperty, SC_COORD=0B, MAG_COORD=1B
          widget_control, widget_info(ev.top, FIND_BY_UNAME='vectortab:MAGVECTORBTN'), SET_BUTTON=0, SENSITIVE=0
          widget_control, widget_info(ev.top, FIND_BY_UNAME='vectortab:VELOVECTORBTN'), SET_BUTTON=0, SENSITIVE=0
          widget_control, widget_info(ev.top, FIND_BY_UNAME='vectortab:USERVECTORBTN'), SET_BUTTON=0, SENSITIVE=0
        end
      endcase

      stel3d_draw_update, ev.top, val
    end
    'main:AXISUNITBUTTON':begin
      ;print, "AxisUNIT"
      case ev.index of
        0: begin
          (val['oConf']).SetProperty, AXIS_UNIT='velocity'
          (val['oXTitle']).Setproperty, strings='<-  VX  ->'
          (val['oYTitle']).Setproperty, strings='<-  VY  ->'
          (val['oZTitle']).Setproperty, strings='<-  VZ  ->'
        end
        1:begin
          (val['oConf']).SetProperty, AXIS_UNIT='energy'
          (val['oXTitle']).Setproperty, strings='<-  EX  ->'
          (val['oYTitle']).Setproperty, strings='<-  EY  ->'
          (val['oZTitle']).Setproperty, strings='<-  EZ  ->'
        end
      endcase
      res = (val['oData']).reload_data()
      voldata = (val['oData']).GetVolumedata()
      val['oVolume'].SetProperty, DATA0=voldata
      ;
      ; Change Title and Axis Values
      ;ToDo: DEFINE THEM WHEN RELOADING. 
      ;ToDo: 本来はリロード時に設定する
      xrange = (val['oData']).getXSouceRange()
      yrange = (val['oData']).getYSouceRange()
      zrange = (val['oData']).getZSouceRange()
      (val['oConf']).SetProperty, XRANGE=xrage, YRANGE=yrange, ZRANGE=zrange
      ;
      ; Set values to Ticktext for each Axis
      ;
      (val['oAxisX']).GetProperty, TICKTEXT=oTickX
      oTickX.SetProperty, STRINGS= [string(fix(type=5,xrange[0])), '0', string(fix(type=5,xrange[1]))]
      (val['oAxisY']).GetProperty, TICKTEXT=oTickY
      oTickY.SetProperty, STRINGS= [string(fix(type=5,yrange[0])), '0', string(fix(type=5,yrange[1]))]
      (val['oAxisZ']).GetProperty, TICKTEXT=oTickZ
      oTickZ.SetProperty, STRINGS= [string(fix(type=5,zrange[0])), '0', string(fix(type=5,zrange[1]))]
      (val['oConf']).GetProperty, CURTIME=curtime, AXIS_UNIT=axis_unit
      (val['oTitle']).SetProperty, STRINGS= curtime+' : '+axis_unit
      ;
      ; Set values to slice range
      ;
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:XYMINLABEL'), SET_VALUE=string(fix(type=5,zrange[0]))
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:XYMAXLABEL'), SET_VALUE=string(fix(type=5,zrange[1]))
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:YZMINLABEL'), SET_VALUE=string(fix(type=5,xrange[0]))
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:YZMAXLABEL'), SET_VALUE=string(fix(type=5,xrange[1]))
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:XZMINLABEL'), SET_VALUE=string(fix(type=5,yrange[0]))
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:XZMAXLABEL'), SET_VALUE=string(fix(type=5,yrange[1]))
      xtex=(val['oData']).getXSliceText()
      ytex=(val['oData']).getYSliceText()
      ztex=(val['oData']).getZSliceText()
      (val['oConf']).GetProperty, SLICE_XY=slice_xy, SLICE_XZ=slice_xz, SLICE_YZ=slice_yz
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:XYText'), $
        SET_VALUE=strcompress(string(ztex[slice_xy.position]), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:XZText'), $
        SET_VALUE=strcompress(string(ytex[slice_xz.position]), /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='slicetab:YZText'), $
        SET_VALUE=strcompress(string(xtex[slice_yz.position]), /REMOVE_ALL)
      ;
      ; redraw
      stel3d_draw_update, ev.top, val
    end
    'main:UNITBUTTON':begin
      case ev.index of
        0:(val['oConf']).SetProperty, UNIT='count'
        1:(val['oConf']).SetProperty, UNIT='psd'
      endcase
      oVolume = val['oVolume']

      ; reload data
      res = (val['oData']).reload_data()
      
      ; Get original data and set color min/max value
      origvol = (val['oData']).GetVolumedata(/original)
      nrange = (val['oData']).getNSouceRange()
      (val['oConf']).SetProperty, COLOR_MAX_VAL=float(nrange[1]), COLOR_MIN_VAL=float(nrange[0])
      widget_control, widget_info(ev.top, FIND_BY_UNAME='colortab:ColorMinText'), SET_VALUE=strcompress(nrange[0], /REMOVE_ALL)
      widget_control, widget_info(ev.top, FIND_BY_UNAME='colortab:ColorMaxText'), SET_VALUE=strcompress(nrange[1], /REMOVE_ALL)

      voldata = (val['oData']).GetVolumedata()
      oVolume.SetProperty, DATA0=voldata
      ;
      ; Get New Values
      nrange = (val['oData']).getNSouceRange()
      (val['oConf']).SetProperty, RANGE=nrange
      (val['oConf']).GetProperty, UNIT=unit
      ;
      ; Change the values for the colorbar
      (val['oColorbar']).GetProperty, TITLE=oBartitle, MAJOR=major, TICKTEXT=oTicktextBar
      oBartitle.SetProperty, STRINGS=unit
      fStep = (max(nrange)-min(nrange))/(major-1)
      if unit eq 'psd' then begin 
         oFont = obj_new('IDLgrFont', SIZE=6)
        oTicktextBar.Setproperty, FONT=oFont, $
          STRINGS=strtrim(string(findgen(major)*fStep + min(nrange), FORMAT='(1E8.0)'),1)
      endif else begin
        oFont = obj_new('IDLgrFont', SIZE=8)
         oTicktextBar.Setproperty, FONT=oFont, $
          STRINGS=strtrim(string(findgen(major)*fStep + min(nrange), FORMAT='(1F10.1)'),1)
      endelse
      ;
      ; redraw
      stel3d_draw_update, ev.top, val
    end
    'main:Step':begin
      widget_control, ev.id, GET_VALUE=step
      (val['oConf']).SetProperty, STEP=string(fix(step))
    end
    else: print, 'no uval'
  endcase

end
;
;
;
pro stel3d_widget, oData, $
  oConf, $
  XDIM=xdim, $
  YDIM=ydim
  
  !EXCEPT=0
    
  if xdim eq !null then xdim = 560
  if ydim eq !null then ydim = 560
  
  ;
  ; GET DEFINED PARAMETERS. 
  ; 設定値を取得する
  ;
  oConf->GetProperty, $
    TRANGE=trange, $
    CURTIME=curtime, $
    NUMTIMEKEYS=numtimekeys, $
    SCATTER=scatter, $
    SLICE_VOLUME=slice_volume, $
    ISOSURFACE1=isosurface1, $
    ISOSURFACE2=isosurface2, $+
    XRANGE=xrange, $
    YRANGE=yrange, $
    ZRANGE=zrange, $
    RANGE=nrange, $
    UNIT=unit, $
    AXIS_UNIT=axis_unit,    $
    SPINSUM=spinsum,        $
    STEP=step,              $
    INTERPOL=interpol,      $
    SLICE_XY=slice_xy,      $  ; 2Dスライス面と場所XY面
    SLICE_YZ=slice_yz,      $  ; 2Dスライス面と場所YZ面
    SLICE_XZ=slice_xz,      $  ; 2Dスライス面と場所ZX面
    ISO1_MESH=iso1_mesh,    $
    ISO2_MESH=iso2_mesh,    $
    ISO1_COLOR=iso1_color,  $
    ISO2_COLOR=iso2_color,  $
    ISO1_LEVEL=iso1_level,  $
    ISO2_LEVEL=iso2_level,  $
    BFIELD=bfield,          $ ; 磁場ベクトル
    VELOCITY=velocity,      $ ; 速度ベクトル
    VIEW=view,              $ ; 視点ベクトル
    USER=user,  $             ; ユーザー指定ベクトル
    MAX_MAG_VEC=max_mag_vec, $
    MAX_VEL_VEC=max_vel_vec
  
  curtimeArr = oData.getTimearray()

  if n_elements(xrange) ne 2 then xrange =  oData.getXSouceRange()
  if n_elements(yrange) ne 2 then yrange = oData.getYSouceRange()
  if n_elements(zrange) ne 2 then zrange = oData.getZSouceRange()
  if n_elements(nrange)  ne 2 then nrange = oData.getNSouceRange()
  if n_elements(curtime) ne 1 then begin
    curtimeArr = (oData.olep).getTimeKeys()
    curtime = curtimeArr[0]
    oConf.SetProperty, CURTIME=curtime
  endif

  ;prevent error if data is uniform
  if nrange[0] eq nrange[1] then begin
    nrange = [0,1.]
  endif
  ;
  ; check values for isosurface
  if iso1_level[1] gt nrange[1] then iso1_level[1]=nrange[1]
  if iso1_level[0] gt nrange[1] then iso1_level[0]=nrange[0]
  if iso2_level[1] gt nrange[1] then iso2_level[1]=nrange[1]
  if iso2_level[0] gt nrange[1] then iso1_level[0]=nrange[0]
  ;
  ; Get Volume data
  voldata = oData.GetVolumeData()
  res = oData.GetCoordConv(XS=xs, YS=ys, ZS=zs)
  if res eq !null then message, 'invalid conversion factor'

  sz = oData.GetVolDimension()
  xMax = sz[0]
  yMax = sz[1]
  zMax = sz[2]

  ;
  ; SETTING OF VECTOR COLOE ETC. 
  ; ベクトルのカラー情報などの設定
  cColorList=['red', 'blue', 'green', 'lime', 'yellow', 'magenta', 'cyan', 'white', 'black']
  cLengthList=['full','half','quarter']
  cThicknessList=['1','2','3','4','5','6','7','8','9','10']
  
;***********************************************************************
; GUI SETTINGS 
; GUIの設定
;***********************************************************************
  wBase = widget_base(COL=2, XPAD=1, YPAD=1, UNAME='main:TOPBASE', UVALUE='main:TOPBASE', /TLB_SIZE_EVENTS)
  left = widget_base(wBase, ROW=3, XPAD=0, YPAD=0, Y_SCROLL_SIZE=600, X_SCROLL_SIZE=350, /SCROLL)
  up = widget_base(left, COL=2, XPAD=0, YPAD=0)
  upleft = widget_base(up, ROW=2, XSIZE=150, XPAD=0, YPAD=0)
  right = widget_base(wbase, UNAME='main:RIGHTBASE', UVALUE='main:RIGHTBASE')
  ;
  ; DISPLAY PANEL 
  ; 表示パネル
  ;
  wdraw = widget_draw(right, XSIZE=xdim, YSIZE=ydim, $
    /EXPOSE_EVENTS, /BUTTON_EVENTS, /WHEEL_EVENTS, $
    GRAPHICS_LEVEL=2, RETAIN=2, EVENT_PRO='stel3d_widget_draw_event', $
    UNAME='main:DRAW', UVALUE='main:DRAW')
  ;-------------------------------------------------------------------
  ; PANEL FOR OBJECT ON/OFF 
  ; オブジェクトのオンオフのパネル
  ;-------------------------------------------------------------------
  wUpLeftTop = widget_base(upleft, ROW=4, /FRAME, /NONEXCLUSIVE, XSIZE=145)
    wScatterBtn = widget_button(wUpLeftTop, VALUE='Scatter', UVALUE='main:SCATTER' )
    widget_control, wScatterBtn, SET_BUTTON=scatter
    wVolumeBtn = widget_button(wUpLeftTop, VALUE='Volume', UVALUE='main:VOLUME' )
    widget_control, wVolumeBtn, SET_BUTTON=slice_volume
    wIso1Btn = widget_button(wUpLeftTop, VALUE='Isosurface1', UVALUE='main:ISO1')
    widget_control, wIso1Btn, SET_BUTTON=isosurface1
    wIso2Btn = widget_button(wUpLeftTop, VALUE='Isosurface2', UVALUE='main:ISO2')
    widget_control, wIso2Btn, SET_BUTTON=isosurface2
  ;-------------------------------------------------------------------
  ; PANEL FOR "SAVE" 
  ; 保存パネル
  ;-------------------------------------------------------------------
  wUpLeftBottom = widget_base(upleft, COLUMN=2, /FRAME, XSIZE=145)
    cSaveTypeList = ['PNG', 'EPS']
    wTemp = widget_base(wUpLeftBottom, ROW=2)
    wLabel = widget_label(wTemp, VALUE='Types')
    wSaveType = widget_droplist(wTemp, VALUE=cSaveTypeList, UNAME='main:SAVETYPE', UVALUE='main:SAVETYPE')
    wTemp = widget_base(wUpLeftBottom, ROW=2)
    wLabel = widget_label(wTemp, VALUE=' ')
    wSaveBtn = widget_button(wTemp, VALUE='Save', UNAME='main:SAVE', UVALUE='main:SAVE')
    
  wsize = widget_info(upleft, /GEOMETRY)
  rsize = wsize.ysize - wsize.space
  ;-------------------------------------------------------------------
  ; PANEL FOR DATA CHANGE 
  ; データの変更パネル
  ;-------------------------------------------------------------------  
  wUpRight = widget_base(up, ROW=6, /FRAME, XSIZE=148, YSIZE=rsize, XPAD=5)
   cCoodList=['SC', 'MAG']
   wLabel = widget_label(wUpRight, VALUE='Coordinates')
   wCoordinates = widget_droplist(wUpRight, VALUE=cCoodList, SCR_XSIZE=90, UNAME='main:COORDBUTTON', UVALUE='main:COORDBUTTON')
   ; 各軸の単位
   cAxisUnits=['Velocity','Energy']
   wLabel = widget_label(wUpRight, VALUE='Axis Units', SCR_YSIZE=20)
   wAxisUnits = widget_droplist(wUpRight, VALUE=cAxisUnits, SCR_XSIZE=90, UNAME='main:AXISUNITBUTTON', UVALUE='main:AXISUNITBUTTON')
   ; 各軸の単位
   cUnits=['Count','PSD']
   wLabel = widget_label(wUpRight, VALUE='Units', SCR_YSIZE=20)
   wUnits = widget_droplist(wUpRight, VALUE=cUnits, SCR_XSIZE=90, SCR_YSIZE=20, UNAME='main:UNITBUTTON', UVALUE='main:UNITBUTTON')

   ; set the units per the units keyword
   idx_units = where(strlowcase(cUnits) eq strlowcase(unit), unit_count)
   if unit_count eq 0 then begin
    dprint, dlevel=0, 'Unknown units: ' + unit
    dprint, dlevel=0, 'Defaulting to count units'
    unit = 'count'
   endif else widget_control, wUnits, set_droplist_select=idx_units

  mid = widget_base(left, ROW=2, /FRAME, XSIZE=300, XPAD=0, YPAD=0)
    wTimeTextBase = widget_base(mid, ROW=2)
    wStartTimeBase = widget_base(wTimeTextBase, XPAD=0, YPAD=0, COLUMN=2)
    wLabel = widget_label(wStartTimeBase, SCR_XSIZE=80, VALUE='Start Time(UT)')
    wStartTimeText = widget_text(wStartTimeBase, SCR_XSIZE=150, UNAME='main:STARTTIME', VALUE=curtimeArr[0])
    wEndTimeBase = widget_base(wTimeTextBase, XPAD=0, YPAD=0, column=2)
    wLabel = widget_label(wEndTimeBase, SCR_XSIZE=80, VALUE='End Time(UT)') 
    wEndTimeText = widget_text(wEndTimeBase, SCR_XSIZE=150, UNAME='main:ENDTIME', VALUE=curtimeArr[0])
  
    cStartTime = strsplit(curtimeArr[0], '/', /EXTRACT)
    cEndTime = strsplit(curtimeArr[-1], '/', /EXTRACT)
    wTimeBase1 = widget_base(mid, ROW=2)
    wTimeBase2 = widget_base(wTimeBase1, ROW=2)
    wSliderBase = widget_base(wTimeBase2, COLUMN=2)
    wLabel = widget_label(wSliderBase, VALUE=cStartTime[1], SCR_XSIZE=110, FONT="TIMES*12", /ALIGN_LEFT)
    wLabel = widget_label(wSliderBase, VALUE=cEndTime[1], SCR_XSIZE=110, FONT="TIMES*12", /ALIGN_RIGHT)
    ;slider_steps = (2 * 12)/fix(2)
    wTimeSlider = widget_slider(wTimeBase2, MINIMUM=0, MAXIMUM=n_elements(curtimeArr)-1, XSIZE=220, $
      SCROLL=step, /SUPPRESS_VALUE, UNAME='main:TIMESLIDER', UVALUE='main:TIMESLIDER', $
      EVENT_PRO='stel3d_widget_timeslider_event')
    wTimeBase3 = widget_base(wTimeBase1, /ROW)
    wLabel = widget_label(wTimeBase3, VALUE='Spin sum', /ALIGN_RIGHT)
    wSpinsumText = widget_text(wTimeBase3,  VALUE=strcompress(string(spinsum), /REMOVE_ALL), $
                              UVALUE='main:Spinsum', UNAME='main:Spinsum', SCR_XSIZE=50, /EDITABLE, $
                              EVENT_PRO='stel3d_widget_timeslider_event')
    wLabel = widget_label(wTimeBase3, VALUE='   Step (1Step=12sec)',  /ALIGN_RIGHT)
    wStepText = widget_text(wTimeBase3, VALUE=strcompress(string(step), /REMOVE_ALL), $
                            UVALUE='main:Step', UNAME='main:Step', $
                            SCR_XSIZE=50, /EDITABLE)
    
  ;=======================================================================
  ; TAB SETTINGS 
  ; タブの設定
  ;=======================================================================
  bot = widget_base(left)
  wTab = widget_tab(bot)
  
  ;=======================================================================
  ; CREATE 2D SLICE 
  ; Slice 2Dの生成
  ;=======================================================================
  wSliceBase = widget_base(wTab, TITLE='Slice', XPAD=0, YPAD=0, EVENT_PRO='stel3d_widget_slicetab_event')
  ;wSliceBase = WIDGET_BASE(wVolumeBaseTop, /column, XPAD=0, YPAD=0)
  wSlice2DBase = widget_base(wSliceBase, ROW=9)
  wLabelBase = widget_base(wSlice2DBase, COLUMN=3, YPAD=5)
  wLabel = widget_label(wLabelBase, VALUE='Slice 2D', SCR_XSIZE=200, /ALIGN_CENTER)
  wLabel = widget_label(wLabelBase, VALUE='Contour ')
  wLabel = widget_label(wLabelBase, VALUE=' Image')

  ; XY-PLANE
  ; XY面
  wBase1 = widget_base(wSlice2DBase, /ROW, YPAD=0)
  wLabel = widget_label(wBase1, VALUE='XY-Plane', SCR_XSIZE=50)
  wXY2DText = widget_text(wBase1, /EDITABLE, SCR_XSIZE=60,  $
    UVALUE='slicetab:XYText', UNAME='slicetab:XYText', $
    VALUE=strcompress(string(fix(type=5,zrange[0])), /REMOVE_ALL) )
  wXY2DSlider = widget_slider(wBase1, SCR_XSIZE=100, MAX=(zMax-1), MIN=0 ,/SUPPRESS_VALUE, UVALUE='slicetab:XY', $
    UNAME='slicetab:XY')
  wTemp = widget_base(wBase1, XPAD=0, YPAD=0, SCR_XSIZE=15)
  wTempBase = widget_base(wBase1, /NONEXCLUSIVE, XPAD=0, YPAD=0, column=2)
  wXYContourBtn = widget_button(wTempBase, VALUE=' ', UVALUE='slicetab:XYCONTOUR', UNAME='slicetab:XYCONTOUR')
  widget_control, wXYContourBtn, SET_BUTTON=slice_xy.contour
  wXYFillBtn = widget_button(wTempBase, VALUE=' ', UVALUE='slicetab:XYFILL', UNAME='slicetab:XYFILL')
  widget_control, wXYContourBtn, SET_BUTTON=slice_xy.fill

  wBase2 = widget_base(wSlice2DBase, column=3, YPAD=0)
  wTmpBase = widget_base(wBase2, SCR_XSIZE=120, YPAD=0)
  wXYLowerLabel = widget_label(wBase2, $
    VALUE=strcompress(string(fix(type=5,zrange[0])),/REMOVE_ALL), SCR_XSIZE=50, /ALIGN_LEFT, FONT="TIMES*12", $
    UVALUE='slicetab:XYMINLABEL', UNAME='slicetab:XYMINLABEL')
  wXYUpperLabel = widget_label(wBase2, $
    VALUE=strcompress(string(fix(type=5,zrange[1])),/REMOVE_ALL), SCR_XSIZE=50, /ALIGN_RIGHT, FONT="TIMES*12", $
    UVALUE='slicetab:XYMAXLABEL', UNAME='slicetab:XYMAXLABEL')

  ; YZ PLANE 
  ; YZ面
  wBase3 = widget_base(wSlice2DBase, /row, YPAD=0)
  wLabel = widget_label(wBase3, VALUE='YZ-Plane', SCR_XSIZE=50)
  wYZ2DText = widget_text(wBase3, /EDITABLE, UVALUE='slicetab:YZText', UNAME='slicetab:YZText', $
    VALUE=strcompress(string(fix(type=5,xrange[0])), /REMOVE_ALL), SCR_XSIZE=60)
  wYZ2DSlider = widget_slider(wBase3, VALUE=slice_yz.position, MAX=(xMax-1), MIN=0, SCR_XSIZE=100, /SUPPRESS_VALUE, $
    UVALUE='slicetab:YZ', UNAME='slicetab:YZ')

  wTemp = widget_base(wBase3, XPAD=0, YPAD=0, SCR_XSIZE=15)
  wTempBase = widget_base(wBase3, /NONEXCLUSIVE, XPAD=0, YPAD=0, COLUMN=2)
  wYZContourBtn = widget_button(wTempBase, value=' ', UVALUE='slicetab:YZCONTOUR', UNAME='slicetab:YZCONTOUR')
  widget_control, wYZContourBtn, SET_BUTTON=slice_yz.contour
  wYZFillBtn = widget_button(wTempBase, value=' ', UVALUE='slicetab:YZFILL', UNAME='slicetab:YZFILL')
  widget_control, wYZFillBtn, SET_BUTTON=slice_yz.fill

  wBase4 = widget_base(wSlice2DBase, COLUMN=3, YPAD=0)
  wTmpBase = widget_base(wBase4, SCR_XSIZE=120, YPAD=0)
  wYZLowerLabel = widget_label(wBase4, SCR_XSIZE=50, /ALIGN_LEFT, FONT="TIMES*12", $
    VALUE=strcompress(string(fix(type=5,xrange[0])),/REMOVE_ALL), UVALUE='slicetab:YZMINLABEL', UNAME='slicetab:YZMINLABEL')
  wYZUpperLabel = widget_label(wBase4, SCR_XSIZE=50, /ALIGN_RIGHT, FONT="TIMES*12", $
    VALUE=strcompress(string(fix(type=5,xrange[1])),/REMOVE_ALL), UVALUE='slicetab:YZMAXLABEL', UNAME='slicetab:YZMAXLABEL')

  ; ZX PLANE 
  ; ZX面
  wBase5 = widget_base(wSlice2DBase, /row, YPAD=0)
  wLabel = widget_label(wBase5, VALUE='XZ-Plane', SCR_XSIZE=50)
  wXZ2DText = widget_text(wBase5, VALUE=strcompress(string(fix(type=5,yrange[0]))), $
    UVALUE='slicetab:XZText', UNAME='slicetab:XZText', /EDITABLE, SCR_XSIZE=60)
  wXZ2DSlider = widget_slider(wBase5,  VALUE=slice_xz.position, MIN=0, MAX=(yMax-1), SCR_XSIZE=100, /SUPPRESS_VALUE, $
    UVALUE='slicetab:XZ', UNAME='slicetab:XZ')
  wTemp = widget_base(wBase5, XPAD=0, YPAD=0, SCR_XSIZE=15)
  wTempBase = widget_base(wBase5, /NONEXCLUSIVE, XPAD=0, YPAD=0, column=2)
  wXZContourBtn = widget_button(wTempBase, value=' ', UVALUE='slicetab:XZCONTOUR', UNAME='slicetab:XZCONTOUR')
  widget_control, wXZContourBtn, SET_BUTTON=slice_xz.contour
  wXZFillBtn = widget_button(wTempBase, value=' ', UVALUE='slicetab:XZFILL', UNAME='slicetab:XZFILL')
  widget_control, wXZContourBtn, SET_BUTTON=slice_xz.contour

  wBase6 = widget_base(wSlice2DBase, column=3, YPAD=0)
  wTmpBase = widget_base(wBase6, SCR_XSIZE=120, YPAD=0)
  wZXLowerLabel = widget_label(wBase6, $
    VALUE=strcompress(string(fix(type=5,yrange[0])),/REMOVE_ALL), $
    SCR_XSIZE=50, /ALIGN_LEFT, FONT="TIMES*12", UVALUE='slicetab:XZMINLABEL', UNAME='slicetab:XZMINLABEL')
  wZXUpperLabel = widget_label(wBase6, $
    VALUE=strcompress(string(fix(type=5,yrange[1])),/REMOVE_ALL), $
    SCR_XSIZE=50, /ALIGN_RIGHT, FONT="TIMES*12", UVALUE='slicetab:XZMAXLABEL', UNAME='slicetab:XZMAXLABEL')

  ;==========================================================================
  ; TAB FOR COLOR SETTINGS 
  ; カラー 設定タブ
  ;==========================================================================
  wColorBase = widget_base(wTab, TITLE='Color', EVENT_PRO='stel3d_widget_colortab_event')
  wColorSubBase = widget_base(wColorBase, ROW=2)
  
  wBase7=widget_base(wColorSubBase, ROW=3)
  wLabelColor = widget_label(wBase7, VALUE='Display Color Setting')
  wBase7Sub1 = widget_base(wBase7, COL=2)
  wColorLabelMin = widget_label(wBase7Sub1, VALUE='Min Values:')
  wColorTextMin = widget_text(wBase7Sub1, /EDITABLE, VALUE=strcompress(oConf.color_min_val, /REMOVE_ALL), $
                              UVALUE='colortab:ColorMinText', UNAME='colortab:ColorMinText')
  wBase7Sub2 = widget_base(wBase7, COL=2)
  wColorLabelMax = widget_label(wBase7Sub2, VALUE='Max Values:')
  wColorTextMax = widget_text(wBase7Sub2, /EDITABLE, VALUE=strcompress(oConf.color_max_val, /REMOVE_ALL), $
                              UVALUE='colortab:ColorMaxText', UNAME='colortab:ColorMaxText')
  
  wBase8 = widget_base(wColorSubBase, ROW=5)
  wLabelCont = widget_label(wBase8, VALUE='Contour Setting')
  wBase8Sub1 = widget_base(wBase8, COL=2)
  wBase8Sub1Sub1 = widget_base(wBase8Sub1, COL=2, /EXCLUSIVE)
  wContSetAuto = widget_button(wBase8Sub1Sub1, VALUE='Auto', UVALUE='colortab:AutoButton')
  wContSetCustom = widget_button(wBase8Sub1Sub1, VALUE='Custom', UVALUE='colortab:CustomButton')
  wBase8Sub2 = widget_base(wBase8, COL=2)
  wContLabelNumLevel = widget_label(wBase8Sub2, VALUE='Num Levels:')
  wContTextNumLevel = widget_text(wBase8Sub2, VALUE=strcompress(oConf.cont_nlevels, /REMOVE_ALL), $
    /EDITABLE, UNAME='colortab:ContNlevelsText', UVALUE='colortab:ContNlevelsText')
  
  wBase8Sub3 = widget_base(wBase8, ROW=2)
  wBase8Sub3Sub1 = widget_base(wBase8Sub3, COL=4)
  wContLabelLevel = widget_label(wBase8Sub3Sub1, VALUE='Level Values:')
  wContTextLevels = widget_text(wBase8Sub3Sub1, VALUE='', /EDITABLE, UNAME='colortab:ContTextLevels', UVALUE='colortab:ContTextLevels')
  
  widget_control, wContSetAuto, /SET_BUTTON
  widget_control, wContTextLevels, SENSITIVE=0

  ;==========================================================================
  ; PROPERTIES FOR ISOSURFACE 
  ; ISOsurface 専用プロパティ
  ;==========================================================================
  wVolumeBase = widget_base(wTab, title='Isosurface', /COLUMN, EVENT_PRO='stel3d_widget_isotab_event')
  wVolumeBaseTop = widget_base(wVolumeBase, XPAD=0, YPAD=0, column=2)
  
  ;------------------------
  ; SET ISOSURFACE RANGE 
  ; Isosurface1 rangeの生成
  ;------------------------
  wVolumeLeft = widget_base(wVolumeBaseTop, /column, XPAD=0, YPAD=0)
  wVolumeRange = widget_base(wVolumeLeft, /column, XPAD=0, YPAD=0, /FRAME)
  ; Volume1 rangeの生成
  wVol1RangeBase = widget_base(wVolumeRange, /COLUMN, SCR_XSIZE=280)
  wLabelBase = widget_base(wVol1RangeBase, column=4, /ALIGN_CENTER)
  wLabel = widget_label(wLabelBase, VALUE='Isofurface1 Mesh')
  wTempBase = widget_base(wLabelBase, /NONEXCLUSIVE, YPAD=0)
  wIsoMesh1Btn = widget_button(wTempBase, value='', UVALUE='isotab:ISOMESH1ZBTN')
  wTemp = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=30)
  widget_control, wISOMesh1Btn, SET_BUTTON=iso1_mesh

  wVol1Base = widget_base(wVol1RangeBase, /ROW, /BASE_ALIGN_CENTER, XPAD=0, YPAD=0)
  wVol1Base2 = widget_base(wVol1Base, row=3, XPAD=0, YPAD=0)

  cValues = strtrim(string(nrange, format='(F5.1)'), 1)
  wMaxBase = widget_base(wVol1Base2, /ROW, /BASE_ALIGN_CENTER, XPAD=0, YPAD=0)
  wLabel = widget_label(wMaxBase, VALUE='Max', SCR_XSIZE=30)
  wVol1MaxText = widget_text(wMaxBase, SCR_XSIZE=45, UNAME='isotab:TEXTMAX1', UVALUE='isotab:TEXTMAX1', $
     /EDITABLE)
  wVol1MaxSlider = widget_slider(wMaxBase, SCR_XSIZE=100, MINIMUM=0, MAXIMUM=255, $
    UVALUE='isotab:SLIDERMAX1', UNAME='isotab:SLIDERMAX1',/SUPPRESS_VALUE)
  wMinBase = widget_base(wVol1Base2, /ROW, /BASE_ALIGN_CENTER, XPAD=0, YPAD=0)
  wLabel = widget_label(wMinBase, VALUE='Min', SCR_XSIZE=30)
  wVol1MinText = widget_text(wMinBase, SCR_XSIZE=45, UNAME='isotab:TEXTMIN1', UVALUE='isotab:TEXTMIN1', $
    /EDITABLE)
  wVol1MinSlider = widget_slider(wMinBase, SCR_XSIZE=100, MINIMUM=0, MAXIMUM=255, $
    UVALUE='isotab:SLIDERMIN1', UNAME='isotab:SLIDERMIN1', /SUPPRESS_VALUE)
  ;
  ; Set widget for Isosurface1
  widget_control, wVol1MinSlider, SET_VALUE=bytscl(iso1_level[0], MIN=nrange[0], MAX=nrange[1])
  widget_control, wVol1MaxSlider, SET_VALUE=bytscl(iso1_level[1], MIN=nrange[0], MAX=nrange[1])
  widget_control, wVol1MinText, SET_VALUE=strcompress(string(iso1_level[0], FORMAT='(1F5.1)'), /REMOVE_ALL)
  widget_control, wVol1MaxText, SET_VALUE=strcompress(string(iso1_level[1], FORMAT='(1F5.1)'), /REMOVE_ALL)

  wSliderBase = widget_base(wVol1Base2, column=3, XPAD=0, YPAD=0)
  wTmpBase = widget_base(wSliderBase, SCR_XSIZE=80, XPAD=0, YPAD=0)
  wLabel = widget_label(wSliderBase, VALUE=cValues[0], SCR_XSIZE=50, /ALIGN_LEFT, FONT="TIMES*12")
  wLabel = widget_label(wSliderBase, VALUE=cValues[1], SCR_XSIZE=50, /ALIGN_RIGHT, FONT="TIMES*12")
  wColorIso1 = widget_droplist(wVol1Base, VALUE=strupcase(cColorList), SCR_XSIZE=75, UVALUE='isotab:COLOR1', UNAME='isotab:COLOR1')
  iso1_color_pos = where(cColorList eq iso1_color)
  widget_control, wColorIso1, SET_DROPLIST_SELECT=iso1_color_pos
  ;------------------------
  ; SET ISOSURFACE RANGE 2 
  ; Isosurface2 rangeの生成
  ;------------------------
  wVol2RangeBase = widget_base(wVolumeRange, /COLUMN, SCR_XSIZE=260)
  wLabelBase = widget_base(wVol2RangeBase, COLUMN=4, /ALIGN_CENTER)
  wLabel = widget_label(wLabelBase, VALUE='Isosurface2 Mesh')
  wTempBase = widget_base(wLabelBase, /NONEXCLUSIVE, YPAD=0)
  wIsoMesh2Btn = widget_button(wTempBase, value='', UVALUE='isotab:ISOMESH2ZBTN', SCR_XSIZE=30)
  wTemp = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=30)
  widget_control, wISOMesh2Btn, SET_BUTTON=iso2_mesh
  ;wLabel = WIDGET_LABEL(wLabelBase, VALUE='Color2')

  wVol2Base = widget_base(wVol2RangeBase, /ROW, /BASE_ALIGN_CENTER, XPAD=0, YPAD=0)
  wVol2Base2 = widget_base(wVol2Base, row=4, XPAD=0, YPAD=0)

  wMaxBase = widget_base(wVol2Base2, /ROW, /BASE_ALIGN_CENTER, XPAD=0, YPAD=0)
  wLabel = widget_label(wMaxBase, VALUE='Max', SCR_XSIZE=30)
  wVol2MaxText = widget_text(wMaxBase, SCR_XSIZE=45, UNAME='isotab:TEXTMAX2', UVALUE='isotab:TEXTMAX2', $
    /EDITABLE)
  wVol2MaxSlider = widget_slider(wMaxBase, SCR_XSIZE=100, MINIMUM=0, MAXIMUM=255,   $
    UVALUE='isotab:SLIDERMAX2', UNAME='isotab:SLIDERMAX2', /SUPPRESS_VALUE)

  wMinBase = widget_base(wVol2Base2, /ROW, /BASE_ALIGN_CENTER, XPAD=0, YPAD=0)
  wLabel = widget_label(wMinBase, VALUE='Min', SCR_XSIZE=30)
  wVol2MinText = widget_text(wMinBase, SCR_XSIZE=45, UNAME='isotab:TEXTMIN2', UVALUE='isotab:TEXTMIN2', $
    /EDITABLE)
  wVol2MinSlider = widget_slider(wMinBase, SCR_XSIZE=100, MINIMUM=0, MAXIMUM=255,   $
    UVALUE='isotab:SLIDERMIN2', UNAME='isotab:SLIDERMIN2', /SUPPRESS_VALUE)
  ;
  ; Set widget for Isosurface2
  widget_control, wVol2MinSlider, SET_VALUE=bytscl(iso2_level[0], MIN=nrange[0], MAX=nrange[1])
  widget_control, wVol2MaxSlider, SET_VALUE=bytscl(iso2_level[1], MIN=nrange[0], MAX=nrange[1])
  widget_control, wVol2MinText, SET_VALUE=strcompress(string(iso2_level[0], FORMAT='(1F5.1)'), /REMOVE_ALL)
  widget_control, wVol2MaxText, SET_VALUE=strcompress(string(iso2_level[1], FORMAT='(1F5.1)'), /REMOVE_ALL)

  wSliderBase = widget_base(wVol2Base2, COLUMN=3, XPAD=0, YPAD=0)
  wTmpBase = widget_base(wSliderBase, SCR_XSIZE=80, XPAD=0, YPAD=0)
  wLabel = widget_label(wSliderBase, VALUE=cValues[0], SCR_XSIZE=50, /ALIGN_LEFT, FONT="TIMES*12")
  wLabel = widget_label(wSliderBase, VALUE=cValues[1], SCR_XSIZE=50, /ALIGN_RIGHT, FONT="TIMES*12")
  wColorIso2 = widget_droplist(wVol2Base, VALUE=strupcase(cColorList), SCR_XSIZE=75, UVALUE='isotab:COLOR2', UNAME='isotab:COLOR2')
  iso2_color_pos = where(cColorList eq iso2_color)
  widget_control, wColorIso2, SET_DROPLIST_SELECT=iso2_color_pos
  ;------------------------
  ; SET INTERPOLATION 
  ; Interpolationの生成
  ;------------------------
  wInterpol = widget_base(wVolumeLeft, YPAD=0, /ROW, /FRAME, /BASE_ALIGN_CENTER, SCR_YSIZE=30)
  wLabel = widget_label(wInterpol, VALUE='Interpolation')
  cInterpol = ['qgrid3']
  wInterpolation = widget_droplist(wInterpol, VALUE=cInterpol)
  
  ;------------------------
  ; SET VECTORS 
  ; ベクトル設定の生成
  ;------------------------
  wVectorBase = widget_base(wTab, TITLE='Vector', ROW=8, EVENT_PRO='stel3d_widget_vectortab_event')
  ;---- MAGNETIC FIELD VECTOR ----
  ;---- 磁場ベクトル ----
  wMagneticBase = widget_base(wVectorBase, /ROW, /BASE_ALIGN_BOTTOM)  ;ドロップリストを下付けする
  ; DISPLAY ON/OFF 
  ; 磁場ベクトルの表示/非表示
  wMagVectorBase = widget_base(wMagneticBase, ROW=2, YPAD=0, /BASE_ALIGN_CENTER)
  wTempBase = widget_base(wMagVectorBase, /ROW, YPAD=0)
  wLabel = widget_label(wTempBase, VALUE='Magnetic field vector(nT)')
  wTemp = widget_base(wTempBase, /NONEXCLUSIVE, YPAD=0)
  wMagVectorBtn = widget_button(wTemp, VALUE='', UVALUE='vectortab:MAGVECTORBTN', UNAME='vectortab:MAGVECTORBTN')

  wLabelBase = widget_base(wMagVectorBase, /ROW, XPAD=0, YPAD=0)
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=10)
  wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='X')
  wMagLabelX = widget_label(wLabelBase, SCR_XSIZE=45, /ALIGN_RIGHT, VALUE=strtrim(string(bfield.x, format='(F10.1)'),1))
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=20)
  wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='Y')
  wMagLabelY = widget_label(wLabelBase, SCR_XSIZE=45, /ALIGN_RIGHT, VALUE=strtrim(string(bfield.y, format='(F10.1)'),1))
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=20)
  wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='Z')
  wMagLabelZ = widget_label(wLabelBase, SCR_XSIZE=45, /ALIGN_RIGHT, VALUE=strtrim(string(bfield.z, format='(F10.1)'),1))
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=20)
  ; SETTING FOR COLOR, LENGTH, AND THICKNESS 
  ; 色、長さ、太さの設定
  wMagFormBase = widget_base(wVectorBase, COLUMN=3, XPAD=0, YPAD=0)
  wMagColor = widget_droplist(wMagFormBase, VALUE=cColorList, SCR_XSIZE=70, UVALUE='vectortab:MAGCOLOR')
  wMagLength = widget_droplist(wMagFormBase, VALUE=cLengthList, SCR_XSIZE=70, UVALUE='vectortab:MAGLENGTH')
  wMagThickness = widget_droplist(wMagFormBase, VALUE=cThicknessList, SCR_XSIZE=70, UVALUE='vectortab:MAGTHICKNESS')
  ;
  ; SETTING OF VALUES 
  ;値の設定
  widget_control, wMagVectorBtn, SET_BUTTON=bfield.show
  widget_control, wMagColor, SET_DROPLIST_SELECT=where(cColorList eq bfield.color)
  widget_control, wMagLength, SET_DROPLIST_SELECT=where(cLengthlist eq bfield.length)
  widget_control, wMagThickness, SET_DROPLIST_SELECT=where(cThicknessList eq bfield.thick)

  ;---- VELOCITY VECTOR ---- 
  ;---- 速度ベクトル ----
  wVelocityBase = widget_base(wVectorBase, /ROW, /BASE_ALIGN_BOTTOM)  ;ドロップリストを下付けする
  ; DISPLAY ON/OFF 
  ; 速度ベクトルの表示/非表示
  wVeloVectorBase = widget_base(wVelocityBase, ROW=2, YPAD=0)
  wTempBase = widget_base(wVeloVectorBase, /ROW, YPAD=0, /BASE_ALIGN_CENTER)
  wLabel = widget_label(wTempBase, VALUE='Velocity vector(km/s)')
  wTempBase = widget_base(wTempBase, /NONEXCLUSIVE, YPAD=0)
  wVeloVectorBtn = widget_button(wTempBase, VALUE='', UVALUE='vectortab:VELOVECTORBTN', UNAME='vectortab:VELOVECTORBTN' )
  wLabelBase = widget_base(wVeloVectorBase, /ROW, XPAD=0, YPAD=0)
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=10)
  wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='X')
  wVelLabelX = widget_label(wLabelBase, SCR_XSIZE=45, /ALIGN_RIGHT, VALUE=strtrim(string(velocity.x, format='(F10.1)'),1))
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=20)
  wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='Y')
  wVelLabelY = widget_label(wLabelBase, SCR_XSIZE=45, /ALIGN_RIGHT, VALUE=strtrim(string(velocity.y, format='(F10.1)'),1))
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=20)
  wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='Z')
  wVelLabelZ = widget_label(wLabelBase, SCR_XSIZE=45, /ALIGN_RIGHT, VALUE=strtrim(string(velocity.z, format='(F10.1)'),1))
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=20)
  ;
  ; SETTING OF COLOR, LENGTH, AND THICKNESS. 
  ; 色、長さ、太さの設定
  ;wVeloFormBase = WIDGET_BASE(wVelocityBase, column=3, XPAD=0, YPAD=0)
  wVeloFormBase = widget_base(wVectorBase, column=3, XPAD=0, YPAD=0)
  wVeloColor = widget_droplist(wVeloFormBase, VALUE=cColorList, SCR_XSIZE=70, UVALUE='vectortab:VELOCOLOR')
  wVeloLength = widget_droplist(wVeloFormBase, VALUE=cLengthList, SCR_XSIZE=70, UVALUE='vectortab:VELOLENGTH')
  wVeloThickness = widget_droplist(wVeloFormBase, VALUE=cThicknessList, SCR_XSIZE=70, UVALUE='vectortab:VELOTHICKNESS')
  ;
  ; SETTING OF VALUES 
  ;値の設定
  widget_control, wVeloVectorBtn, SET_BUTTON=velocity.show
  widget_control, wVeloColor, SET_DROPLIST_SELECT=where(cColorList eq velocity.color)
  widget_control, wVeloLength, SET_DROPLIST_SELECT=where(cLengthlist eq velocity.length)
  widget_control, wVeloThickness, SET_DROPLIST_SELECT=where(cThicknessList eq velocity.thick)

  ;---- USER-DEFINED VECTOR ---- 
  ;---- ユーザー指定ベクトル ----
  wUserBase = widget_base(wVectorBase, /ROW, /BASE_ALIGN_BOTTOM)  ;ドロップリストを下付けする
  ; DISPLAY ON/OFF 
  ; ユーザー指定ベクトルの表示/非表示
  wUserVectorBase = widget_base(wUserBase, row=2, YPAD=0)
  wTempBase = widget_base(wUserVectorBase, /ROW, YPAD=0, /BASE_ALIGN_CENTER)
  wLabel = widget_label(wTempBase, VALUE='User vector')
  wTempBase = widget_base(wTempBase, /NONEXCLUSIVE, YPAD=0)
  wUserVectorBtn = widget_button(wTempBase, value='', UVALUE='vectortab:USERVECTORBTN', UNAME='vectortab:USERVECTORBTN')
  wLabelBase = widget_base(wUserVectorBase, /ROW, XPAD=0, YPAD=0)
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=10)
  wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='X')
  wUserVectorX = widget_text(wLabelBase, SCR_XSIZE=65, /EDITABLE, $
    UVALUE='vectortab:USERVECTORX', VALUE=strtrim(string(user.x, format='(F10.1)'),1))
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=0)
  wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='Y')
  wUserVectorY = widget_text(wLabelBase, SCR_XSIZE=65, /EDITABLE, /KBRD_FOCUS_EVENTS,   $
    UVALUE='vectortab:USERVECTORY', VALUE=strtrim(string(user.y, format='(F10.1)'),1))
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=0)
  wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='Z')
  wUserVectorZ = widget_text(wLabelBase, SCR_XSIZE=65, /EDITABLE, /KBRD_FOCUS_EVENTS,   $
    UVALUE='vectortab:USERVECTORZ', VALUE=strtrim(string(user.z, format='(F10.1)'),1))
  wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=0)
  ; SETTING OF COLOR, LENGTH, AND THICKNESS 
  ; 色、長さ、太さの設定
  ;wUserFormBase = WIDGET_BASE(wUserBase, column=3, XPAD=0, YPAD=0)
  wUserFormBase = widget_base(wVectorBase, column=3, XPAD=0, YPAD=0)
  wUserColor = widget_droplist(wUserFormBase, VALUE=cColorList, SCR_XSIZE=70, UVALUE='vectortab:USERCOLOR')
  wUserLength = widget_droplist(wUserFormBase, VALUE=cLengthList, SCR_XSIZE=70, UVALUE='vectortab:USERLENGTH')
  wUserThickness = widget_droplist(wUserFormBase, VALUE=cThicknessList, SCR_XSIZE=70, UVALUE='vectortab:USERTHICKNESS')
  ;
  ; SETTING OF VALUES 
  ;値の設定
  widget_control, wUserVectorBtn, SET_BUTTON=user.show
  widget_control, wUserColor, SET_DROPLIST_SELECT=where(cColorList eq user.color)
  widget_control, wUserLength, SET_DROPLIST_SELECT=where(cLengthlist eq user.length)
  widget_control, wUserThickness, SET_DROPLIST_SELECT=where(cThicknessList eq user.thick)

  ;==========================================================================
  ; PROPERTIES FOR SCATTER MODE 
  ; 離散専用プロパティ
  ;==========================================================================
  wScatterBase = widget_base(wTab, TITLE='Scatter ', /COL, EVENT_PRO='stel3d_widget_scattertab_event')
  ; SET MAX AND MIN OF PHYSICAL QUANTITY 
  ; 物理量の上限下限値の生成
  wUnitsRangeBase = widget_base(wScatterBase, ROW=2)
  wLabel = widget_label(wUnitsRangeBase, VALUE='Units range', /ALIGN_CENTER, SCR_XSIZE=280)

  wUnitsBase = widget_base(wUnitsRangeBase, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wUnitsBase2 = widget_base(wUnitsBase, row=4, YPAD=0)

  wMaxBase = widget_base(wUnitsBase2, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wLabel = widget_label(wMaxBase, VALUE='Max', SCR_XSIZE=30)
  wUnitMaxText = widget_text(wMaxBase, $
    VALUE=strcompress(string(ceil(nrange[1]))), $
    SCR_XSIZE=50,  $  ;/EDITABLE, /KBRD_FOCUS_EVENTS,
    UVALUE='scattertab:MAXTEXT', UNAME='scattertab:MAXTEXT')
  wUnitMaxSlider = widget_slider(wMaxBase, VALUE=ceil(nrange[1]), $
    MAX=ceil(nrange[1]), MIN=floor(nrange[0]), $
    UNAME='scattertab:MAXSLIDER', UVALUE='scattertab:MAXSLIDER', $
    SCR_XSIZE=100, /SUPPRESS_VALUE)

  wMinBase = widget_base(wUnitsBase2, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wLabel = widget_label(wMinBase, VALUE='Min', SCR_XSIZE=30)
  wUnitMinText = widget_text(wMinBase, $
    VALUE=strcompress(string(floor(nrange[0]))), $
    SCR_XSIZE=50,  $  ;/EDITABLE, /KBRD_FOCUS_EVENTS,
    UVALUE='scattertab:MINTEXT', UNAME='scattertab:MINTEXT')
  wUnitMinSlider = widget_slider(wMinBase, VALUE=floor(nrange[0]), $
    MAX=ceil(nrange[1]), MIN=floor(nrange[0]), $
    UVALUE='scattertab:MINSLIDER', UNAME='scattertab:MINSLIDER', $
    SCR_XSIZE=100, /SUPPRESS_VALUE)

  wSliderBase = widget_base(wUnitsBase2, column=3, YPAD=0)
  wTmpBase = widget_base(wSliderBase, SCR_XSIZE=80, YPAD=0)
  wUnitMinLabel = widget_label(wSliderBase, $
    VALUE=strcompress(string(floor(nrange[0])), /REMOVE_ALL), $
    UVALUE='scattertab:MINLABEL', UNAME='scattertab:MINLABEL', $
    SCR_XSIZE=50, /ALIGN_LEFT, FONT="TIMES*12")
  wUnitMaxLabel = widget_label(wSliderBase, $
    VALUE=strcompress(string(ceil(nrange[1])), /REMOVE_ALL), $
    UVALUE='scattertab:MAXLABEL', UNAME='scattertab:MINLABEL', $
    SCR_XSIZE=50, /ALIGN_RIGHT, FONT="TIMES*12")

  wDefBase = widget_base(wUnitsBase)
  wUnitDefBtn = widget_button(wDefBase, value='Default')
 
  ;=======================================================================
  ; SETTING OF DISPLAY RANGE 
  ; 表示範囲の設定
  ;=======================================================================
  wAxisRangeBase = widget_base(wTab, TITLE='Range', ROW=4, EVENT_PRO='stel3d_widget_rangetab_event')
  wLabelbase = widget_base(wAxisRangeBase, SCR_YSIZE=25)
  wLabel = widget_label(wLabelbase,VALUE='Axis range', /ALIGN_CENTER, SCR_XSIZE=290)

  ; X AXIS RANGE 
  ; X軸の表示幅生成
  wXRangeBase = widget_base(wAxisRangeBase, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wXRangeBase2 = widget_base(wXRangeBase, ROW=4, YPAD=0)

  wXMaxBase = widget_base(wXRangeBase2, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wLabel = widget_label(wXMaxBase, VALUE='X max', SCR_XSIZE=40)
  wXMaxText = widget_text(wXMaxBase, SCR_XSIZE=50, VALUE=strcompress(string(max(fix(type=5,xrange))), /REMOVE_ALL), UNAME='rangetab:XMAXTEXT')
  ;wXMaxText = widget_text(wXMaxBase, /EDITABLE, SCR_XSIZE=50, VALUE=strcompress(string(max(fix(type=5,xrange))), /REMOVE_ALL), UVALUE='rangetab:XMAXTEXT')
  wXMaxSlider = widget_slider(wXMaxBase, SCR_XSIZE=100, /SUPPRESS_VALUE, MIN=0, MAX=sz[0], UNAME='rangetab:XMAXSLIDER', UVALUE='rangetab:XMAXSLIDER')
  
  wXMinBase = widget_base(wXRangeBase2, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wLabel = widget_label(wXMinBase, VALUE='X min', SCR_XSIZE=40)
  wXMinText = widget_text(wXMinBase, SCR_XSIZE=50, VALUE=strcompress(string(min(fix(type=5,xrange))), /REMOVE_ALL), UNAME='rangetab:XMINTEXT')
  ;wXMinText = widget_text(wXMinBase, /EDITABLE, SCR_XSIZE=50, VALUE=strcompress(string(min(fix(type=5,xrange))), /REMOVE_ALL), UVALUE='rangetab:XMINTEXT')
  wXMinSlider = widget_slider(wXMinBase, SCR_XSIZE=100, MIN=0, MAX=sz[0], /SUPPRESS_VALUE, UNAME='rangetab:XMINSLIDER', UVALUE='rangetab:XMINSLIDER')

  wSliderBase = widget_base(wXRangeBase2, column=3, YPAD=0)
  wTmpBase = widget_base(wSliderBase, SCR_XSIZE=90, YPAD=0)
  wXMinLabel = widget_label(wSliderBase, SCR_XSIZE=50, /ALIGN_LEFT, FONT="TIMES*12")
  wXMaxLabel = widget_label(wSliderBase, SCR_XSIZE=50, /ALIGN_RIGHT, FONT="TIMES*12")

  wDefBase = widget_base(wXRangeBase)
  wXDefBtn = widget_button(wDefBase, value='Default', UVALUE='rangetab:XDEFAULT')

  ; Y AXIS RANGE 
  ; Y軸の表示幅生成
  wYRangeBase = widget_base(wAxisRangeBase, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wYRangeBase2 = widget_base(wYRangeBase, row=4, YPAD=0)

  wYMaxBase = widget_base(wYRangeBase2, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wLabel = widget_label(wYMaxBase, VALUE='Y max', SCR_XSIZE=40)
  wYMaxText = widget_text(wYMaxBase, SCR_XSIZE=50, VALUE=strcompress(string(max(fix(type=5,yrange)))), UNAME='rangetab:YMAXTEXT')
  ;wYMaxText = widget_text(wYMaxBase, /EDITABLE, SCR_XSIZE=50, VALUE=strcompress(string(max(fix(type=5,yrange)))))
  wYMaxSlider = widget_slider(wYMaxBase, SCR_XSIZE=100,  MIN=0, MAX=sz[1], /SUPPRESS_VALUE, UNAME='rangetab:YMAXSLIDER', UVALUE='rangetab:YMAXSLIDER')

  wYMinBase = widget_base(wYRangeBase2, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wLabel = widget_label(wYMinBase, VALUE='Y min', SCR_XSIZE=40)
  wYMinText = widget_text(wYMinBase, SCR_XSIZE=50, VALUE=strcompress(string(min(fix(type=5,yrange)))), UNAME='rangetab:YMINTEXT')
  ;wYMinText = widget_text(wYMinBase, /EDITABLE, SCR_XSIZE=50, VALUE=strcompress(string(min(fix(type=5,yrange)))))
  wYMinSlider = widget_slider(wYMinBase, SCR_XSIZE=100,  MIN=0, MAX=sz[1], /SUPPRESS_VALUE, UNAME='rangetab:YMINSLIDER', UVALUE='rangetab:YMINSLIDER')

  wSliderBase = widget_base(wYRangeBase2, column=3, YPAD=0)
  wTmpBase = widget_base(wSliderBase, SCR_XSIZE=90, YPAD=0)
  wYMinLabel = widget_label(wSliderBase, SCR_XSIZE=50, /ALIGN_LEFT, FONT="TIMES*12")
  wYMaxLabel = widget_label(wSliderBase, SCR_XSIZE=50, /ALIGN_RIGHT, FONT="TIMES*12")

  wDefBase = widget_base(wYRangeBase)
  wYDefBtn = widget_button(wDefBase, VALUE='Default', UVALUE='rangetab:YDEFAULT')

  ; Z AXIS RANGE 
  ; Z軸の表示幅生成
  wZRangeBase = widget_base(wAxisRangeBase, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wZRangeBase2 = widget_base(wZRangeBase, ROW=4, YPAD=0)

  wZMaxBase = widget_base(wZRangeBase2, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wLabel = widget_label(wZMaxBase, VALUE='Z max', SCR_XSIZE=40)
  wZMaxText = widget_text(wZMaxBase, SCR_XSIZE=50, VALUE=strcompress(string(max(fix(type=5,zrange)))), UNAME='rangetab:ZMAXTEXT')
  ;wZMaxText = widget_text(wZMaxBase, /EDITABLE, SCR_XSIZE=50, VALUE=strcompress(string(max(fix(type=5,zrange)))))
  wZMaxSlider = widget_slider(wZMaxBase, SCR_XSIZE=100, MIN=0, MAX=sz[2], /SUPPRESS_VALUE, UNAME='rangetab:ZMAXSLIDER', UVALUE='rangetab:ZMAXSLIDER')

  wZMinBase = widget_base(wZRangeBase2, /ROW, /BASE_ALIGN_CENTER, YPAD=0)
  wLabel = widget_label(wZMinBase, VALUE='Z min', SCR_XSIZE=40)
 ;wZMinText = widget_text(wZMinBase, /EDITABLE, SCR_XSIZE=50, VALUE=strcompress(string(min(fix(type=5,zrange)))))
  wZMinText = widget_text(wZMinBase, SCR_XSIZE=50, VALUE=strcompress(string(min(fix(type=5,zrange)))), UNAME='rangetab:ZMINTEXT')
  wZMinSlider = widget_slider(wZMinBase, SCR_XSIZE=100,  MIN=0, MAX=sz[2], /SUPPRESS_VALUE, UNAME='rangetab:ZMINSLIDER', UVALUE='rangetab:ZMINSLIDER')

  wSliderBase = widget_base(wZRangeBase2, column=3, YPAD=0)
  wTmpBase = widget_base(wSliderBase, SCR_XSIZE=90, YPAD=0)
  wZMinLabel = widget_label(wSliderBase, SCR_XSIZE=50, /ALIGN_LEFT, FONT="TIMES*12")
  wZMaxLabel = widget_label(wSliderBase, SCR_XSIZE=50, /ALIGN_RIGHT, FONT="TIMES*12")

  wDefBase = widget_base(wZRangeBase)
  wZDefBtn = widget_button(wDefBase, VALUE='Default', UVALUE='rangetab:ZDEFAULT')
  
  widget_control, wXMaxSlider, SET_VALUE=sz[0] 
  widget_control, wYMaxSlider, SET_VALUE=sz[1] 
  widget_control, wZMaxSlider, SET_VALUE=sz[2] 

  ;==========================================================================
  ; DISPLAY SETTING PROPERTY 
  ; 表示設定プロパティ
  ;==========================================================================
   wViewBase = widget_base(wTab, TITLE='View', EVENT_PRO='stel3d_widget_viewtab_event')
   ; VIEW VECTOR ON/OFF 
   ; 視点ベクトルの表示/非表示
   ;---- 視点ベクトル ----
   wViewSubBase = widget_base(wViewBase, ROW=5)
   wViewVectorBase = widget_base(wViewSubBase, ROW=3, FRAME=1)
   wLabel = widget_label(wViewVectorBase, VALUE='Rotation Angles')
   wLabelBase = widget_base(wViewVectorBase, /ROW)
   wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=10)
   wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='X')
   wLabel = widget_label(wLabelBase, SCR_XSIZE=45, /ALIGN_RIGHT, UNAME='viewtab:XANG', VALUE=strtrim(string(view.x, format='(F10.1)'),1))
   wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=20)
   wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='Y')
   wLabel = widget_label(wLabelBase, SCR_XSIZE=45, /ALIGN_RIGHT, UNAME='viewtab:YANG', VALUE=strtrim(string(view.y, format='(F10.1)'),1))
   wTmpBase = widget_base(wLabelBase, XPAD=0, YPAD=0, SCR_XSIZE=20)
   wLabel = widget_label(wLabelBase, SCR_XSIZE=10, /ALIGN_RIGHT, VALUE='Z')
   wLabel = widget_label(wLabelBase, SCR_XSIZE=45, /ALIGN_RIGHT, UNAME='viewtab:ZANG', VALUE=strtrim(string(view.z, format='(F10.1)'),1))
   
   wSightBase = widget_base(wViewSubBase, ROW=2, FRAME=1)
   wSightSubBase1 = widget_base(wSightBase)
   wSightLabel = widget_label(wSightSubBase1, VALUE='Plane View')
   wSightSubBase2 = widget_base(wSightBase, COL=3)
   wXYButton = widget_button(wSightSubBase2, VALUE='XY-Plane', UVALUE='viewtab:XY')
   wXZButton = widget_button(wSightSubBase2, VALUE='XZ-Plane', UVALUE='viewtab:XZ')
   wYZButton = widget_button(wSightSubBase2, VALUE='YZ-Plane', UVALUE='viewtab:YZ')
   
   wAxisOnOfBAse = widget_base(wViewSubBase, ROW=2, FRAME=1)
    wAxisOnOfSubBase1 = widget_base(wAxisOnOfBAse)
    wAxisOnOfLabel = widget_label(wAxisOnOfSubBase1, VALUE='Turn On/Off Axis and Box')
    wAxisOnOfSubBase2 = widget_base(wAxisOnOfBAse, COL=4, /NONEXCLUSIVE)
    wBoxButton = widget_button(wAxisOnOfSubBase2, VALUE='Box', UVALUE='viewtab:BOX')
    widget_control, wBoxButton, /SET_BUTTON
    wCenterAxis = widget_button(wAxisOnOfSubBase2, VALUE='Center', UVALUE='viewtab:CENTER')
    widget_control, wCenterAxis, /SET_BUTTON
    wAxis = widget_button(wAxisOnOfSubBase2, VALUE='Axis', UVALUE='viewtab:AXIS')
    widget_control, wAxis, /SET_BUTTON
    
   wResetBase = widget_base(wViewSubBase)
   wReset = widget_button(wViewSubBase, VALUE='Reset View', UVALUE='viewtab:RESET')
   ;
   ; CONTEXT MENU 
   ; コンテキストメニュ
   ;
   contextBase = widget_base(wdraw, /CONTEXT_MENU, EVENT_PRO='stel3d_widget_context_menu_event', UNAME='context:Base')
   loadCTButton = widget_button(contextBase, VALUE='Change CT', UVALUE='context:CTButton')
   xyButton = widget_button(contextBase, VALUE = 'X-Y Slice Plot', UVALUE='context:XYplot')
   yzButton = widget_button(contextBase, VALUE = 'Y-Z Slice Plot', UVALUE='context:YZplot')
   xzButton = widget_button(contextBase, VALUE = 'X-Z Slice Plot', UVALUE='context:XZplot') 
   doneButton = widget_button(contextBase, VALUE = 'Done', $
     /SEPARATOR, UVALUE='context:Done')
     
  widget_control, wBase, /REALIZE
  widget_control, wdraw, GET_VALUE=oWindow

;***********************************************************************
; CREATE OBJECTS
; オブジェクトの作成
;***********************************************************************
  ;====================================================================
  ; Compute viewplane rect based on aspect ratio.
  ;====================================================================
  aspect = float(xdim)/float(ydim)
  myview = [-1, -1, 2, 2]*1.1
  if (aspect > 1) then begin
    myview[0] = myview[0] - ((aspect-1.0)*myview[2])/2.0
    myview[2] = myview[2] * aspect
  endif else begin
    myview[1] = myview[1] - (((1.0/aspect)-1.0)*myview[3])/2.0
    myview[3] = myview[3] * aspect
  endelse
  
  ; Drop the view down a bit to make room for the colorbar
  ;myview[1] = myview[1] + 0.1
  myview[0] = myview[0] + 0.1
  
  ; Create view.
  oView = obj_new('IDLgrView', PROJECTION=1, $
    VIEWPLANE_RECT=myview, COLOR=[255, 255, 255])

  ; Create model & View
  oTop = obj_new('IDLgrModel')
  ;oTop->Scale, 1.2, 1.2, 1.2
  oGroup = obj_new('IDLgrModel')
  oTop.Add, oGroup
  ;
  ; Set Font
  oFont = obj_new('IDLgrFont', SIZE=8)
  ;
  ; Get RGB information
  oPalette = oData->getPalette()
  oPalette->GetProperty, Red=bRed, Green=bGreen, Blue=bBlue
  rgb = [[bRed], [bGreen], [bBlue]]

  ;--------------------------
  ; Create Title
  ; -------------------------
  oTitleFont = obj_new('IDLgrFont', SIZE=14)
  endtime = strsplit(curtimeArr[-1], '/', /EXTRACT)
  oTitle = obj_new('IDLgrText', curtimeArr[0]+' - '+endtime[1]+'  ('+axis_unit+')', FONT=oTitleFont)
  oTitleModel=obj_new('IDLgrModel')
  oTitleModel.Add, oTitle
  oTitleModel.Translate, -0.45, 1, 0
  oView.Add, oTitleModel
  
  ;--------------------------
  ; Create Colorbar
  ; -------------------------
  mytitle = obj_new('IDLgrText', unit, FONT=oFont)
  oColorbar = obj_new('IDLgrColorbar', PALETTE=oPalette,  $
    DIMENSIONS = [0.05, 1.5], SHOW_AXIS=2, SHOW_OUTLINE=1, TITLE=mytitle)
  oColorbar->GetProperty, MAJOR=major
  fStep = (max(nrange)-min(nrange))/(major-1)
  if unit eq 'psd' then begin
    oTickText = obj_new( 'IDLgrText', $
      strtrim(string(findgen(major)*fStep + min(nrange), FORMAT='(1E8.0)'),1), $
      FONT=oFont )
  endif else begin
    oTickText = obj_new( 'IDLgrText', $
      strtrim(string(findgen(major)*fStep + min(nrange), FORMAT='(F10.1)'),1), $
      FONT=oFont )
  endelse

  oColorbar->SetProperty, $
    TICKTEXT=oTickText, $
    TICKVALUES=congrid(indgen(256), major, /MINUS_ONE)
  oColorbarModel = IDLgrModel()
  oColorbarModel.Add, oColorbar
  oColorbarModel.Translate, 0.9, -0.7, 0
  oView.Add, oColorbarModel
  
  ;---------------------------
  ; Center Axis
  ;---------------------------
  buffer = max([xMax,yMax,zMax])/3
  oCenterX = obj_new('IDLgrPolyline', $
    [0-buffer, xMax+buffer], [yMax/2.0, yMax/2.0], [zMax/2.0,zMax/2.0], $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs, $
    COLOR=!color.light_gray )
  oCenterY = obj_new('IDLgrPolyline', $
    [xMax/2.0, xMax/2.0], [0-buffer, yMax+buffer], [zMax/2.0,zMax/2.0], $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs, $
    COLOR=!color.light_gray )
  oCenterZ = obj_new('IDLgrPolyline', $
    [xMax/2.0, xMax/2.0], [yMax/2.0, yMax/2.0], [0-buffer, zMax+buffer], $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs, $
    COLOR=!color.light_gray)
  oGroup->Add, [oCenterX, oCenterY, oCenterZ]
  ;-------------------------------
  ; create vector
  ;-------------------------------
  
  oMagVec = stel3d_create_vector([bfield.x, bfield.y, bfield.z],  $
    MAX_MAG_VEC=max_mag_vec, COLOR=oConf.GetRGB(bfield.color), $
    THICK=bfield.thick, LENGTH=bfield.length, SHOW=bfield.show)
  oVelVec = stel3d_create_vector([velocity.x, velocity.y, velocity.z],  $
    MAX_VEL_VEC=max_vel_vec, COLOR=oConf.GetRGB(velocity.color), $
    THICK=velocity.thick, LENGTH=velocity.length, SHOW=velocity.show)
  oUserVec = stel3d_create_vector([user.x, user.y, user.z], COLOR=oConf.GetRGB(user.color), $
    THICK=user.thick, LENGTH=user.length, SHOW=user.show)
  
  oGroup.Add, [oMagVec, oVelVec, oUserVec]
  
  ;;----------------------------
  ; Create XYZ plane Object
  ;-----------------------------
  ; XY-plane
  xy_pos = slice_xy.position
  xy_img = voldata[*, *, xy_pos]
  xy_img = reform(xy_img, sz[0], sz[1], /OVERWRITE)
  oXYImage = obj_new('IDLgrImage', xy_img, PALETTE=oPalette)
  oXYPlane = obj_new('IDLgrPolygon', $
    [0, xMax, xMax, 0], [0,0,yMax,yMax], intarr(4)+xy_pos, $
    COLOR=[255,255,255], HIDE=~(slice_xy.fill),$
    TEXTURE_MAP=oXYImage, TEXTURE_INTERP=1, $
    TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]], $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs)
  ;YZ-plane
  yz_pos = slice_yz.position
  yz_img = voldata[yz_pos,*,*]
  yz_img = reform(yz_img, sz[1], sz[2], /OVERWRITE)
  oYZImage = obj_new('IDLgrImage', yz_img, PALETTE=oPalette)
  oYZPlane = obj_new('IDLgrPolygon', $
    intarr(4)+yz_pos, [0, yMax, yMax, 0], [0,0,zMax,zMax], $
    COLOR=[255,255,255], HIDE=~(slice_yz.fill),$
    TEXTURE_MAP=oYZImage, TEXTURE_INTERP=1, $
    TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]], $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs)
  ;XZ-plane  
  xz_pos = slice_xz.position
  xz_img = voldata[*,xz_pos,*]
  xz_img = reform(xz_img, sz[0], sz[2], /OVERWRITE)
  oXZImage = obj_new('IDLgrImage', xz_img, PALETTE=oPalette)
  oXZPlane = obj_new('IDLgrPolygon', $
     [0, xMax, xMax, 0], intarr(4)+xz_pos, [0,0,zMax,zMax], $
    COLOR=[255,255,255], HIDE=~(slice_xz.fill),$
    TEXTURE_MAP=oXZImage, TEXTURE_INTERP=1, $
    TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]], $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs)
    oGroup->Add, [oXYPlane, oYZPlane, oXZPlane]
  
  ;;----------------------------
  ; Create XYZ Contour Object
  ;----------------------------
  ;XY-Contour
  oXYContour = obj_new('IDLgrContour', xy_img, N_LEVELS=8, COLOR=!COLOR.black, $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs, /PLANAR, GEOMZ=xy_pos, HIDE=~(slice_xy.contour))
  ;YZ-Contour
  oYZContour=stel3d_create_contour(yz_img, /YZPLANE)
  if ~obj_valid(oYZcontour) then message, 'invalid object: Contour'
  oYZContour.Setproperty, HIDE=~(slice_yz.contour), $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs
  oYZContour.Getproperty, DATA=yz_path
  if yz_path ne !null then begin
    yz_path[0,*] = yz_pos
    oYZContour.Setproperty, DATA=yz_path, HIDE=~(slice_yz.contour), $
      XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs
  endif
  ;XZ-Contour
  oXZContour=stel3d_create_contour(xz_img, /XZPLANE)
  oXZContour.Setproperty, HIDE=~(slice_yz.contour), $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs
  oXZContour.Getproperty, DATA=xz_path
  if xz_path ne !null then begin
    xz_path[1,*] = xz_pos
    oYZContour.Setproperty, DATA=xz_path, HIDE=~(slice_xz.contour), $
      XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs
  endif
  
  oGroup->Add, [oXYContour, oYZContour, oXZContour]

  ;----------------------------
  ; Create Scatter Object
  ;----------------------------
  oScatter = stel3d_create_scatter(oData)
  if ~obj_valid(oScatter) then message, 'invalid object'
  oScatter.SetProperty, HIDE=~(scatter)
  oGroup.Add, oScatter
  
  ;----------------------------
  ; Create Volume Object
  ;----------------------------
  oVolume = obj_new('IDLgrVolume', DATA0=voldata, /ZBUFF, $
    RGB_TABLE0=rgb, HINTS=2, /NO_COPY, /ZERO_OPACITY_SKIP, $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs, $
    HIDE=(~slice_volume))
  
  ;----------------------------
  ; Create ISOsurface
  ;----------------------------
  oISO1 = stel3d_create_isosurface(oVolume, iso1_level)
  if ~obj_valid(oISO1) then message, 'invalid object: Isosurface1'
  oISO1.Setproperty, COLOR=oConf.GetRGB(iso1_color),  HIDE=~(isosurface1)
  if iso1_mesh eq 1 then ISO1.Setproperty, STYLE=iso1_mesh

  oISO2 = stel3d_create_isosurface(oVolume, iso2_level)
  if ~obj_valid(oISO2) then message, 'invalid object: Isosurface2'
  oISO2.Setproperty, COLOR=oConf.GetRGB(iso2_color), HIDE=~(isosurface2)
  if iso2_mesh eq 1 then oISO2.Setproperty, STYLE=iso2_mesh
  
  oGroup.Add, oISO1
  oGroup.Add, oISO2
  
  ;--------------------------
  ; Create X-axis objects.
  ;--------------------------
  oXTitle = obj_new('IDLgrText', '<-  VX  ->', FONT=oFont)
 ; oXTickText = obj_new('IDLgrText', [string(fix(type=5,xrange[0])), '0', string(fix(type=5,xrange[1]))], FONT=oFont) ; broken on xrange is too large to be an int
  oXTickText = obj_new('IDLgrText', [string(xrange[0]), '0', string(xrange[1])], FONT=oFont)
  oAxisX = obj_new('IDLgrAxis', 0, COLOR=!color.black, $
    RANGE=[0, xMax], /EXACT, TITLE=oXTitle, TICKLEN=1, MAJOR=3, TICKTEXT=oXTickText, $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs)
  oGroup->Add, oAxisX
  
  ;--------------------------
  ; Create Y-axis objects.
  ;--------------------------
  oYTitle = obj_new('IDLgrText','<-  VY  ->', FONT=oFont)
 ; oYTickText = obj_new('IDLgrText', [string(fix(type=5,yrange[0])), '0', string(fix(type=5,yrange[1]))], FONT=oFont) ; broken on yrange is too large to be an int
  oYTickText = obj_new('IDLgrText', [string(yrange[0]), '0', string(yrange[1])], FONT=oFont)
  oAxisY = obj_new('IDLgrAxis', 1, COLOR=!color.black, $
    RANGE=[0, yMax], /EXACT, TITLE=oYTitle, TICKLEN=1, MAJOR=3, TICKTEXT=oYTickText, $
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs)
  oGroup->Add, oAxisY
  
  ;--------------------------
  ; Create Z-axis objects.
  ;--------------------------
  oZTitle = obj_new('IDLgrText','<-  VZ  ->', FONT=oFont)
;  oZTickText = obj_new('IDLgrText', [string(fix(type=5,zrange[0])), '0', string(fix(type=5,zrange[1]))], FONT=oFont) ; broken on zrange is too large to be an int
  oZTickText = obj_new('IDLgrText', [string(zrange[0]), '0', string(zrange[1])], FONT=oFont)
  oAxisZ = obj_new('IDLgrAxis', 2, COLOR=!color.black, $
    RANGE=[0, zMax], $
    /EXACT, $
    TICKTEXT=oZTickText, $
    TITLE=oZTitle, $
    TICKLEN=1, $
    LOCATION=[0, yMax, 0],  $
    MAJOR=3, $
    XCOORD_CONV=xs, $
    YCOORD_CONV=ys, $
    ZCOORD_CONV=zs)
    
  oGroup->Add, oAxisZ
  
  ;--------------------------
  ; Create Box
  ;--------------------------
  oBox = obj_new('IDLgrPolyline', $
    [[0,0,0],[xMax,0,0],[0,yMax,0],[xMax,yMax,0], $
    [0,0,zMax],[xMax,0,zMax],[0,yMax,zMax],$
    [xMax,yMax,zMax]], $
    COLOR=[200,200,200], $
    POLYLINE=[5,0,1,3,2,0,5,4,5,7,6,4,2,0,4,2,1,5,2,2,6,2,3,7],$
    XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs)
  oGroup->Add, oBox
  ;
  ; Volume shoud be added last
  oGroup.Add, oVolume
  
  ;--------------------------
  ; Create some lights.
  ;--------------------------
  oLight = obj_new('IDLgrLight', LOCATION=[2,2,2], TYPE=1, INTENSITY=0.8)
  oTop.Add, oLight
  oLight = obj_new('IDLgrLight', TYPE=0, INTENSITY=0.5)
  oTop.Add, oLight
  
  ; Place the model in the view.
  oView.Add, oTop
  ;
  ; Rotate to standard view for first draw.
  oGroup.GetProperty, TRANSFORM=zerotrans
  oGroup->Rotate, [1,0,0], -90
  oGroup->Rotate, [0,1,0], 30
  oGroup->Rotate, [1,0,0], 30
  oGroup.GetProperty, TRANSFORM=inittrans
  
  rot_angles = stel3d_get_rotation_angles(inittrans, /DEGREE)
  widget_control, widget_info(wBase, FIND_BY_UNAME='viewtab:XANG'), $
    SET_VALUE=strcompress(string(rot_angles[0], FORMAT='(F10.1)'), /REMOVE_ALL)
  widget_control, widget_info(wBase, FIND_BY_UNAME='viewtab:YANG'),  $
    SET_VALUE=strcompress(string(rot_angles[1], FORMAT='(F10.1)'), /REMOVE_ALL)
  widget_control, widget_info(wBase, FIND_BY_UNAME='viewtab:ZANG'),  $
    SET_VALUE=strcompress(string(rot_angles[2], FORMAT='(F10.1)'), /REMOVE_ALL)
  
  ; Create a trackball.
  oTrack = obj_new('Trackball', [xdim/2, ydim/2.], xdim/2.)
  ;
  ; display objects
  ;
  oWindow.SetProperty, GRAPHICS_TREE=oView
  ;oWindow.SetProperty, GRAPHICS_TREE=oView2
  oWindow.draw
  ;
  ; create values for UVALUE in the Top Base
  ;
  val = hash() 
  val['oConf'] = oConf
  val['oData'] = oData
  val['oWindow'] = oWindow
  val['oGroup'] = oGroup
  val['oTrack'] = oTrack
  val['oBox'] = oBox
  val['oScatter'] = oScatter
  val['oISO1'] = oISO1
  val['oISO2'] = oISO2
  val['oVolume'] = oVolume
  val['oXTitle'] = oXTitle
  val['oYTitle'] = oYTitle
  val['oZTitle'] = oZTitle
  val['oAxisX'] = oAxisX
  val['oAxisY'] = oAxisY
  val['oAxisZ'] = oAxisZ
  val['oMagVec'] = oMagVec
  val['oVelVec'] = oVelVec
  val['oUserVec'] = oUserVec
  val['oXYImage'] = oXYImage
  val['oYZImage'] = oYZImage
  val['oXZImage'] = oXZImage
  val['oXYPlane'] = oXYPlane
  val['oYZPlane'] = oYZPlane
  val['oXZPlane'] = oXZPlane
  val['oXYContour'] = oXYContour
  val['oYZContour'] = oYZContour
  val['oXZContour'] = oXZContour
  val['oCenterX'] = oCenterX
  val['oCenterY'] = oCenterY
  val['oCenterZ'] = oCenterZ
  val['oTitle'] = oTitle
  val['oColorbar'] = oColorbar
  val['zerotrans'] = zerotrans ;initial transformation matrix with no rotation
  val['inittrans'] = inittrans ;transformation matrix with X=-90, Y=30, X=30
  val['xrange'] = xrange
  val['yrange'] = yrange
  val['zrange'] = zrange
  val['nrange'] = nrange
  val['xdispmin'] = 0
  val['xdispmax'] = sz[0]
  val['ydispmin'] = 0
  val['ydispmax'] = sz[1]
  val['zdispmin'] = 0
  val['zdispmax'] = sz[2]
  val['ColorList'] = cColorList
  val['LengthList'] = cLengthList
  val['ThickList'] = cThicknessList
  val['SaveType'] = 'png'
  val['tSliderval'] = 0L

  widget_control, wBase, SET_UVALUE=val, /NO_COPY
  xmanager, 'stel3d_widget', wBase, CLEANUP='stel3d_widget_cleanup', /NO_BLOCK

end
