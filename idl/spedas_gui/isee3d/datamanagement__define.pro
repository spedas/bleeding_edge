;+
; <B>File Name :</B>datamanagement__define.pro<P>
; <B>Class Name :</B>DataManagement<P>
;
;@file_comments
; <B>Purpose :</B><P>
; �タ管琂�ブジェクト�P>
;
; <B>Members :</B><P>
;   pcTime 時間の配�<P>
;   pfX    X値の配�<P>
;   pfY    Y値の配�<P>
;   pfZ    Z値の配�<P>
;   pfN    N値の配�<P>
;
;@history
; Who      Date        version  Description<P>
; ----------------------------------------------------------------------------<P>
; Exelis VIS KK 2014/05/20  1.0.0.0  Original Version<P>
;-


;+
;
; OBJECT CONSTRUCTOR 
; <B>Purpose :</B>�タ管琂�ブジェクト�コンストラクタ�P>
;
; @returns 成功(1)、不��マイナス値)
;
; @param olep {in} {required} {type=object}
;  SETTING OF INPUT DATA OBJECT 
;　入力データオブジェクトを設定する�
;
;-
function DataManagement::init, olep, oConf
  @stel3d_common

  self.olep = olep
  self.oConf = oConf
  

  self.oPalette = obj_new('IDLgrPalette')
  ;self.oPalette->LoadCT, 33
  self.oPalette->LoadCT, oConf.color_table

  ; GET DATA FROM DATA FILE 
  ; ファイル�全時間を取得する�
  alltime = olep->getTimeKeys()
  self.pTimekeys =ptr_new(alltime)
  ;dAllTime = olep->convertJulday(alltime)
  dAllTime = olep->convertUnixTime(alltime)
  self.pdT =ptr_new(dAllTime, /NO_COPY)

  ; LOAD DATA FOR STARTTIME 
  ; starttimeに合�する�タをロードす�
  trange = self->getTrange()
  if n_elements(trange) ne 2 then begin
    message, 'trange error';, /CONTINUE
    return, 0    
  endif
  ; GET DATA FOR STARTTIME 
  ; starttimeに該当するデータを取得する�
  if ~self->reload_data(trange[0]) then begin
      message, 'reload error';, /CONTINUE
      return, 0
  endif
  spinsum = fix(oConf.spinsum)
  ;print, 'spinsum: ', spinsum
  cSpinEndtime = alltime[spinsum[0]]
  self.cSpinTrange = [trange[0], cSpinEndtime]
  
  ; SET DATA PROPERTY 
  ; 設定されてぁ�ぃ�ータを設定する�
  self.oConf->GetProperty, xrange=xrange, $
    yrange=yrange, $
    zrange=zrange, $
    range=range
    
  if ~ptr_valid(self.xrange) && ~undefined(xrange) then self.xrange = ptr_new(xrange)
  if ~ptr_valid(self.yrange) && ~undefined(yrange) then self.yrange = ptr_new(yrange)
  if ~ptr_valid(self.zrange) && ~undefined(zrange) then self.zrange = ptr_new(zrange)
  
  if ~undefined(xrange) or ~undefined(yrange) or ~undefined(zrange) then self.range_set_by_kws = 1b

  if n_elements(xrange) ne 2 then xrange = self->getXSouceRange()
  if n_elements(yrange) ne 2 then yrange = self->getYSouceRange()
  if n_elements(zrange) ne 2 then zrange = self->getZSouceRange()
  if n_elements(range)  ne 2 then range  = self->getNSouceRange()
  ;
  ;
  self.oConf->SetProperty, xrange=xrange, $
    yrange=yrange, $
    zrange=zrange, $
    range=range    
  ;print, range

  ;
  ; INITIALIZE COLOR MAX AND MIN 
  ; カラーの閾値の初期化
  if (oConf.color_max_val eq 0) and (oConf.Color_min_val eq 0) then begin
    oConf.color_max_val = range[1]
    oConf.color_min_val = range[0]
  endif
    
  ; CREATE INDEX 
  ; 表示する�タのインッ�クスを生成す�  
  self->updateShowIdx
  
  ; 2D SLIDER SETTING 
  ; 2Dスライダーヂ�ストデータ設定�nergy
  self.oConf->SetProperty, axis_unit='energy'
  rt = self->reload_data(trange[0])
  voldata = self->GetVolumeData()
  sz = self->GetVolDimension()
  if undefined(xrange) then xrange = self->getXSouceRange()
  if undefined(yrange) then yrange = self->getYSouceRange()
  if undefined(zrange) then zrange = self->getZSouceRange()
  range=[[xrange], [yrange], [zrange]]
  
  
  self.oConf->GetProperty, SLICE_YZ=slice_yz, SLICE_XZ=slice_xz, SLICE_XY=slice_xy
  for i = 0, 2 do begin
    t = fix(type=5,range[0, i] + ((abs(range[0, i])+abs(range[0, i]))/sz[i]) * indgen(sz[i]))
    if t[sz[i]-1] gt range[1, i] then t[sz[i]-1] = fix(type=5,range[1, i])
    if t[0] lt range[0, i] then t[0] = fix(type=5,range[0, i])
    if i eq 0 then self.plSliderEX = ptr_new(t, /NO_COPY)
    if i eq 1 then self.plSliderEY = ptr_new(t, /NO_COPY)
    if i eq 2 then self.plSliderEZ = ptr_new(t, /NO_COPY)
  endfor
  
  ; 2D SLIDER SETTING 
  ; 2Dスライダーヂ�ストデータ設定�elocity)
  self.oConf->SetProperty, axis_unit='velocity'
  rt = self->reload_data(trange[0])
  voldata = self->GetVolumeData()
  sz = self->GetVolDimension()
  if undefined(xrange) then xrange = self->getXSouceRange()
  if undefined(yrange) then yrange = self->getYSouceRange()
  if undefined(zrange) then zrange = self->getZSouceRange()
  range=[[xrange], [yrange], [zrange]]
  for i = 0, 2 do begin
    t = fix(type=5,range[0, i] + ((abs(range[0, i])+abs(range[0, i]))/sz[i]) * INDGEN(sz[i]))
    if t[sz[i]-1] gt range[1, i] then t[sz[i]-1] = fix(type=5,range[1, i])
    if t[0] lt range[0, i] then t[0] = fix(type=5,range[0, i])
    if i eq 0 then self.plSliderVX = ptr_new(t, /NO_COPY)
    if i eq 1 then self.plSliderVY = ptr_new(t, /NO_COPY)
    if i eq 2 then self.plSliderVZ = ptr_new(t, /NO_COPY)
  endfor

  return, 1
End
;
;
;
function DataManagement::reload_data, starttime, NO_DATA_UPDATE=no_data_update
;  @stel3d_common
  
;  print, 'unit: ', (self.oConf).unit
;  print, 'axis_unit: ', (self.oConf).axis_unit
  if n_elements(starttime) ne 1 then begin
    (self.oConf).GetProperty, CURTIME=starttime
  endif else begin
    strtime = self.InputDate2FileDate(starttime)
    (self.oConf).SetProperty, CURTIME=strtime
  endelse
  
  ; IF NO_DATA_UPDATE SET, UPDATE ONLY TIME INFORMATION. 
  ;NO_DATA_UPDATEがセットされていたら、時間情報のみ更新
  if keyword_set(no_data_update) then return, 0
  ;
  ; extract data
  strtime = self.InputDate2FileDate(starttime)
  ;  strtime = '19971212 13:48:48'
  res = self.olep->getOneData(strtime, DATA=onedata)
  if ~res then begin
    message, 'import error';, /CONTINUE
    return, 0
  endif
  
  ; convert coordinate
  case (self.oConf).axis_unit of
    'energy': res = self.olep->getXYZCoord(onedata, /ENERGY)
    'velocity': res = self.olep->getXYZCoord(onedata, /VELOCITY)
    else: res = self.olep->getXYZCoord(onedata)
  endcase
  ;res = self.olep->getXYZCoord(onedata)
  ;
  ; update vector information
  mag_vect = (self.olep).getVector(strtime)
;  print, 'mag vector: ', mag_vect
  vel_vect = (self.olep).getVector(strtime, /VEL)
  tBfield = {VEC, show:1b, color:'cyan', x:mag_vect[0], y:mag_vect[1], z:mag_vect[2], thick:2, length:'full'}
  tVelocity = {VEC, show:1b, color:'yellow', x:vel_vect[0], y:vel_vect[1], z:vel_vect[2], thick:2, length:'full'}

  rec_coord = onedata['xyz']
  (self.oConf).GetProperty, UNIT=unit
  count = onedata[unit]
  ;  psd =  data['psd']
  x = reform(rec_coord[0,*])
  y = reform(rec_coord[1,*])
  z = reform(rec_coord[2,*])
  
  self.pfN = ptr_new(count, /NO_COPY)
  self.pfX = ptr_new(x, /NO_COPY)
  self.pfY = ptr_new(y, /NO_COPY)
  self.pfZ = ptr_new(z, /NO_COPY)

  self.lDataNum = n_elements(*self.pfN)
  self.lShowNum = self.lDataNum
  
  self.oConf->SetProperty, $
 ;   XRANGE = self.getXSouceRange(), $
 ;   YRANGE = self.getYSouceRange(), $
 ;   ZRANGE = self.getZSouceRange(), $
    RANGE = self.getNSouceRange(), $
    ; MAGNETIC FIELD VECTOR 
    BFIELD= tBfield, $      ; 磁場ベクトル
    ; VELOCITY VECTOR 
    VELOCITY= tVelocity     ; 速度ベクトル

  return, 1
 
end
;
;
;
function DataManagement::InputDate2FileDate, inputdate
  @stel3d_common
  
  num = n_elements(inputdate)
  if num lt 1 then begin
    message, 'invalid input'
    return, 0
  endif

;;  filedate = strarr(num)
;;  
;;  for i = 0, num-1 do begin
;;    datetime = strsplit(inputdate[i], '/', /EXTRACT)
;;    date = STRJOIN(strsplit(datetime[0], '-', /EXTRACT))
;;    time = datetime[1]
;;    filedate[i] = date + ' ' + time
;;  endfor
;
;  return, filedate
  return, inputdate
end
;+
;
; <B>Purpose :</B>�タ管琂�ブジェクト�ヂ�トラクタ�P>
;
;-
pro DataManagement::cleanup
;  @stel3d_common

  if ptr_valid(self.pfN) ne 0 then ptr_free, self.pfN
  if ptr_valid(self.pfX) ne 0 then ptr_free, self.pfX
  if ptr_valid(self.pfY) ne 0 then ptr_free, self.pfY
  if ptr_valid(self.pfZ) ne 0 then ptr_free, self.pfZ
  if ptr_valid(self.pdT) ne 0 then ptr_free, self.pdT
  if ptr_valid(self.plShowIdx) ne 0 then ptr_free, self.plShowIdx
  if ptr_valid(self.plSliderEX) ne 0 then ptr_free, self.plSliderEX
  if ptr_valid(self.plSliderEY) ne 0 then ptr_free, self.plSliderEY
  if ptr_valid(self.plSliderEZ) ne 0 then ptr_free, self.plSliderEZ
  if ptr_valid(self.plSliderVX) ne 0 then ptr_free, self.plSliderVX
  if ptr_valid(self.plSliderVY) ne 0 then ptr_free, self.plSliderVY
  if ptr_valid(self.plSliderVZ) ne 0 then ptr_free, self.plSliderVZ

end

;+
;
;  SETTING OF PROPERTIES 
; <B>Purpose :</B>プロパティを設定する�P>
;
; @param trange {in} {optional} {type=string array}
;  SETTING OF TIME RANGE 
;　時間幂�設定する�
;
;-
pro DataManagement::SetProperty, $
  fXMin=fXMin, $
  fXMax=fXMax, $
  fYMin=fYMin, $
  fYMax=fYMax, $
  fZMin=fZMin, $
  fZMax=fZMax, $
  fNMin=fNMin, $
  fNMax=fNMax, $
  cSpinTrange=cSpinTrange, $
  COLOR_TABLE=color_table

;  @stel3d_common
  
  bChange = 0b
 
  ; GET PREVIOUS DATA 
  ; 設定前の�タを取得す�
  self.oConf->GetProperty,  $; , trange=trange, $
    xrange=xrange, $
    yrange=yrange, $
    zrange=zrange, $
    range=range
    
  if (n_elements(cSpinTrange) eq 1) then begin
    self.cSpinTrange = cSpinTrange
  endif

  if ~self->reload_data(cSpinTrange[0]) then begin
    message, 'reload error', /CONTINUE
    return
  endif 
  bChange = 1b

  if n_elements(fXMin) eq 1 then begin
    xrange[0] = fXMin
    bChange = 1b
  endif
  if n_elements(fXMax) eq 1 then begin
    xrange[1] = fXMax
    bChange = 1b
  endif

  if n_elements(fYMin) eq 1 then begin
    yrange[0] = fYMin
    bChange = 1b
  endif
  if n_elements(fYMax) eq 1 then begin
    yrange[1] = fYMax
    bChange = 1b
  endif

  if n_elements(fZMin) eq 1 then begin
    zrange[0] = fZMin
    bChange = 1b
  endif
  if n_elements(fZMax) eq 1 then begin
    zrange[1] = fZMax
    bChange = 1b
  endif

  if n_elements(fNMin) eq 1 then begin
    range[0] = fNMin
    bChange = 1b
  endif
  if n_elements(fNMax) eq 1 then begin
    range[1] = fNMax
    bChange = 1b
  endif
  if n_elements(color_table) eq 1 then begin
    (self.oPalette).LoadCT, color_table
  endif

  self.oConf->SetProperty,  CURTIME=cStartSpinTime, $
    xrange=xrange, $
    yrange=yrange, $
    zrange=zrange, $
    range=range,  $
    COLOR_TABLE=color_talbe

  ; RE-MAKE DISPLAY INDEX IF SETTING UPDATED. 
  ; 設定が変更されたら、表示用インッ�クス配�を作り直す�
  if bChange eq 1b then begin
    self->updateShowIdx
  endif

end

;+
;
; RE-MAKE DISPLAY INDEX 
; <B>Purpose :</B>表示�タのインッ�クス値を作�し直す�P>
;
;-
pro DataManagement::updateShowIdx
  @stel3d_common

  self.oConf->GetProperty, trange=trange, $
    xrange=xrange, $
    yrange=yrange, $
    zrange=zrange, $
    range=range

  if ptr_valid(self.plShowIdx) eq 1 then ptr_free, self.plShowIdx

  lShowIndexs = make_array(self.lDataNum, /LONG, index=1)
  
  if n_elements(xrange) eq 2 then begin
    for i=0L, self.lDataNum-1 do begin
      if ((*self.pfX)[i] lt xrange[0]) or ((*self.pfX)[i] gt xrange[1]) then begin
        lShowIndexs[i] = -1
      endif
    endfor
  endif
  if n_elements(yrange) eq 2 then begin
    for i=0L, self.lDataNum-1 do begin
      if ((*self.pfY)[i] lt yrange[0]) or ((*self.pfY)[i] gt yrange[1]) then begin
        lShowIndexs[i] = -1
      endif
    endfor
  endif
  if n_elements(zrange) eq 2 then begin
    for i=0L, self.lDataNum-1 do begin
      if ((*self.pfZ)[i] lt zrange[0]) or ((*self.pfZ)[i] gt zrange[1]) then begin
        lShowIndexs[i] = -1
      endif
    endfor
  endif
  if n_elements(range) eq 2 then begin
    for i=0L, self.lDataNum-1 do begin
      if ((*self.pfN)[i] lt range[0]) or ((*self.pfN)[i] gt range[1]) then begin
        lShowIndexs[i] = -1
      endif
    endfor
  endif

  indexslist = LIST(lShowIndexs, /EXTRACT)
  removeidx = indexslist.Where(-1)

  indexslist.Remove, removeidx

  self.plShowIdx =ptr_new(indexslist.toarray(), /NO_COPY)
  self.lShowNum = indexslist.Count()

 ; if self.lShowNum ne 0 and self.range_set_by_kws eq 0b then begin
  if self.lShowNum ne 0 then begin
    fMinN = min((*self.pfN)[(*self.plShowIdx)], MAX=fMaxN)
    self.fXdim = abs(min((*self.pfX)[(*self.plShowIdx)]) - max((*self.pfX)[(*self.plShowIdx)]))
    self.fYdim = abs(min((*self.pfY)[(*self.plShowIdx)]) - max((*self.pfY)[(*self.plShowIdx)]))
    self.fZdim = abs(min((*self.pfZ)[(*self.plShowIdx)]) - max((*self.pfZ)[(*self.plShowIdx)]))

    print, 'dim: ', self.fXdim, self.fYdim, self.fZdim
    print, 'n: ', fMinN, fMaxN
  endif
  
;  if self.range_set_by_kws eq 1b then begin
;    self.fXdim = abs(min((*self.xrange)[(*self.plShowIdx)]) - max((*self.xrange)[(*self.plShowIdx)]))
;    self.fYdim = abs(min((*self.yrange)[(*self.plShowIdx)]) - max((*self.yrange)[(*self.plShowIdx)]))
;    self.fZdim = abs(min((*self.zrange)[(*self.plShowIdx)]) - max((*self.zrange)[(*self.plShowIdx)]))
;    print, 'dim: ', self.fXdim, self.fYdim, self.fZdim
;  endif

  ;print, self.lShowNum ;ッ�ヂ�用
end
;+
;
; <B>Purpose :</B>Timeの惱を取得�P>
;
; @returns 時間惱の配�
;
;-
function DataManagement::getSpinTrange
  @stel3d_common
  return, self.cSpinTrange
end

;+
;
; <B>Purpose :</B>パレッ�を取得する�P>
;
; @returns パレッ�オブジェク�
;
;-
function DataManagement::getPalette
  ;@stel3d_common
  return, self.oPalette
end
;+
;
; <B>Purpose :</B>ボリュー��タを取得する�P>
;
; @returns 三次�列�ボリュー��タ
;
;-
function DataManagement::getVolumeData, ORIGINAL=original ;, XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange, DATA_RANGE=data_range
  ;@stel3d_common
  (self.oConf).GetProperty, UNIT=unit, SPINSUM=spinsum, INTERPOL=interpol, SC_COORD=sc_coord, MAG_coord=mag_coord, CURTIME=curtime
  ;print, spinsum
  
  fx = self->getX()
  fy = self->getY()
  fz = self->getZ()
  ;
  ; for SpinSum event
  if spinsum gt 1 then begin
    timeArr = self.getTimearray()
    curtimeIndex = where(timeArr eq curtime, cnt)
    if cnt[0] eq -1 then message, 'no match'
    
    for i=0, spinsum-1 do begin
      res = self.reload_data(timeArr[curtimeIndex])
      if i eq 0 then fn = self->getN() $
      else fn = fn + (self.GetN())
      ++ curtimeIndex
    endfor
    
    if unit eq 'psd' then fn = fn/spinsum ; PSD shoud be an average 
    
    ; 2016-02-25 -af
    ; storing data here appears to cause data array to be out of order
    ; with coordinates later, also break method's abstraction a bit 
;    if ptr_valid(self.pfn) then ptr_free, self.pfn
;    self.pfN = ptr_new(fn)
    
    ;set to original position
    res = self.reload_data(curtime, /NO_DATA_UPDATE)
  endif else begin ; no spin sum
    fn = self->getN()
  endelse  
  ;
  ; IF MAG IS CHOSEN, 
  ; MAGが選択された場合
  if (sc_coord eq 0) and (mag_coord eq 1) then begin
    mag_vec = (self.olep)->getVector(curtime)
    vel_vec = (self.olep)->getVector(curtime, /VEL)

;    res = (self.olep)->getOneData(curtime, DATA=onedata)
;    res = (self.olep)->getXYZCoord(onedata)
;    rec_coord = onedata['xyz']
;    fn = onedata['count']
    

    ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
    ; ROTATION TO MAG COORDINATE (by Kunihiro Keika) 
    ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
    dprint, '== VOLUME ==' 
    dprint, 'B Vector', mag_vec
    dprint, 'V Vector', vel_vec
;    print, 'V Vector' 
;    print, vel_vec 
    mag_vec_unit = mag_vec/sqrt(mag_vec[0]^2.+mag_vec[1]^2.+mag_vec[2]^2.)
    vel_vec_unit = vel_vec/sqrt(vel_vec[0]^2.+vel_vec[1]^2.+vel_vec[2]^2.)
    ; 
    mv_p = crossp(mag_vec_unit, vel_vec_unit) ;Cross product of magnetc and velocity vectors, B x V (=new Y) 
    mv_p /= norm(mv_p) ;normalize
    mvm_p = crossp(mv_p, mag_vec_unit) ; Cross product of (BxV) x B (=new X)
    mvm_p /= norm(mvm_p) ;normalize
    ; 
    ;ROTATION USING MATRIX 
    rotmat = [[mvm_p],[mv_p],[mag_vec_unit]]
;    res_mag = invert(rotmat) # rec_coord 
    res_mag = invert(rotmat) # transpose( [[fx],[fy],[fz]] )
    ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 


;    Z軸と磁場ベクトルの角度:Z軸方向の回転
;    z_p = crossp([0,0,1], mag_vec)
;    ;print, 'Z axis rotate'
;    zang = getangle([0,0,1], mag_vec, /DEG)
;
;    ;速度ベクトルと磁場ベクトルの外積ベクトル Y軸方向の回転
;    mv_p = crossp(vel_vec, mag_vec) ;Cross product magnet and velocity
;    ;print, 'Y axis rotate'
;    yang = getangle([0,1,0], mv_p, /DEG)
;
;    ;（速度ベクトルと磁場ベクトルの外積ベクトルと磁場ベクトルX軸方向の回転
;    mvm_p = crossp(mv_p, mag_vec)
;    ;print, 'X axis rotate'
;    xang = getangle([1,0,0], mvm_p, /DEG)
;    ;  print, 'X cross product'
;    ;  print, x_p

;     xang = getangle(mag_vec, [1,0,0], /DEG) 
;     yang = getangle(mag_vec, [0,1,0], /DEG) 
     
;     print, xang, yang
;     yang =  -1*(xang-90)
;     xang =  -1*(yang-90)
 
;     res_mag = rot3d(rec_coord, XANG=xang, YANG=yang, /DEGREES)

;     res_mag = rot3d(rec_coord, XANG=xang, YANG=yang, ZANG=zang, /DEGREES)


     fx = res_mag[0,*]
     fy = res_mag[1,*]
     fz = res_mag[2,*]
     ;
     ; set calculated angles 
     ;print, xang, yang, zang
     ;self.oConf->SetProperty, XANG=xang, YANG=yang, ZANG=zang
     self.oConf->SetProperty, XANG=xang, YANG=yang, ZANG=zang, ROTMAT=rotmat
;    self.fXdim = abs(min(fx) - max(fx))
;    self.fYdim = abs(min(fy) - max(fy))
;    self.fZdim = abs(min(fz) - max(fz))
  endif else begin
    ;print, 'SC coord'
    ;self.oConf->SetProperty, XANG=0, YANG=0, ZANG=0
    self.oConf->SetProperty, XANG=0, YANG=0, ZANG=0, ROTMAT=0
  endelse
  ;
  ; INTERPOLATION METHOD FOR VOLUME MODE 
  ;ボリュームデータ作成時�補間方法�刂�替�
  ;
  dimmax = max([self.fxdim, self.fydim, self.fzdim])
  fac = dimmax/50

  self.volxdim = fix(type=5,self.fXdim/fac)
  if (self.volxdim mod 2) then ++(self.volxdim)
  self.volydim = fix(type=5,self.fYdim/fac)
  if (self.volydim mod 2) then ++(self.volydim)
  self.volzdim = fix(type=5,self.fZdim/fac)
  if (self.volzdim mod 2) then ++(self.volzdim)

  ;
  ; 離散�タからボリュー��タに変換
  ;
  case (interpol) of
    'qgrid3': begin
;      qhull, fx[pos], fy[pos], fz[pos], tet, /DELAUNAY
;      vol = qgrid3(fx[pos], fy[pos], fz[pos], fn[pos], tet, $
;        DIMENSION=[self.volxdim, self.volydim, self.volzdim])
      qhull, fx, fy, fz, tet, /DELAUNAY
      vol = qgrid3(fx, fy, fz, fn, tet, $
        DIMENSION=[self.volxdim, self.volydim, self.volzdim])

      if keyword_set(original) then begin ; need to get original data without scaling
        return, vol
      endif else begin 
;        print, (self.oConf).color_min_val
;        print, (self.oConf).color_max_val

        if unit eq 'psd' then begin
          vol = temporary(bytscl(/nan,alog10(vol > (self.oConf).color_min_val < (self.oConf).color_max_val)))
        endif else begin
          vol = temporary(bytscl(vol > (self.oConf).color_min_val < (self.oConf).color_max_val))
        endelse
      endelse
      ;print, [self.volxdim, self.volydim, self.volzdim]
      ;help, vol
    end
    else: print, 'other'
  endcase

  return, vol
end
;+
;
; <B>Purpose :</B>Xの値を取得する�P>
;
;-
function DataManagement::getX
;  @stel3d_common

   fX = !NULL
   if self.lShowNum gt 0 then fX = (*self.pfX)[(*self.plShowIdx)]
   return, fX
end

;+
;
; <B>Purpose :</B>Yの値を取得する�P>
;
; @returns Yの配�値
;
;-
function DataManagement::getY
;  @stel3d_common

  fY = !NULL
  if self.lShowNum gt 0 then fY = (*self.pfY)[(*self.plShowIdx)]
  return, fY
end

;+
;
; <B>Purpose :</B>Zの値を取得する�P>
;
; @returns Zの配�値
;
;-
function DataManagement::getZ
  @stel3d_common

  fZ = !NULL
  if self.lShowNum gt 0 then fZ = (*self.pfZ)[(*self.plShowIdx)]
  return, fZ
end

;+
;
; GET N VALUE 
; <B>Purpose :</B>Nの値を取得する�P>
;
; @returns Nの配�値
;
;-
function DataManagement::getN
  @stel3d_common
  fN = !NULL
  if self.lShowNum gt 0 then fN = (*self.pfN)[(*self.plShowIdx)]
  return, fN
end

;+
;
;  GET START TIME AND END TIME. 
; <B>Purpose :</B>starttime, endtimeを取得する�P>
; @returns [starttime, endtime]
;
;-
function DataManagement::getTrange
  @stel3d_common

  self.oConf->GetProperty, trange=trange
  return, trange
end

function DataManagement::getTimearray
  @stel3d_common

  return, self.olep->getTimekeys()
  
end

;+
;
; GET MIN AND MAX OF TIME RANGE 
; <B>Purpose :</B>全�タ中の時間の篛�を取得する�P>
;
; @returns [時間最小値,時間最大値]
;
;-
function DataManagement::getTSouce
  @stel3d_common

  fmin = min((*self.pfT), MAX=fmax)
  return, [fmin, fmax]
end

;+
;
; GET MAX AND MIN OF X VALUE 
; <B>Purpose :</B>全�タ中のXの篛�を取得する�P>
;
; @returns [X最小値,X最大値]
;
;-
function DataManagement::getXSouceRange
;  @stel3d_common
  if ptr_valid(self.xrange) then return, *self.xrange
  fmin = min((*self.pfX), MAX=fmax)
  return, [fmin, fmax]
end

;+
;
; GET MAX AND MIN OF Y VALUE 
; <B>Purpose :</B>全�タ中のYの篛�を取得する�P>
;
; @returns [Y最小値,Y最大値]
;
;-
function DataManagement::getYSouceRange
;  @stel3d_common
  if ptr_valid(self.yrange) then return, *self.yrange

  fmin = min((*self.pfY), MAX=fmax)
  return, [fmin, fmax]
end

;+
;
; GET MAX AND MIN OF Z VALUE 
; <B>Purpose :</B>全�タ中のZの篛�を取得する�P>
;
; @returns [Z最小値,Z最大値]
;
;-
function DataManagement::getZSouceRange
  if ptr_valid(self.zrange) then return, *self.zrange
  fmin = min((*self.pfZ), MAX=fmax)
  return, [fmin, fmax]
end

;+
;
; GET MAX AND MIN OF N VALUE 
; <B>Purpose :</B>全�タ中のNの篛�を取得する�P>
;
; @returns [N最小値,N最大値]
;
;-
function DataManagement::getNSouceRange
  (self.oConf).GetProperty, UNIT=unit
  ;return range of data > 0 if using psd units (log scaling)
  if unit eq 'psd' then begin
    gtz = where( *self.pfN gt 0, n_gtz)
    if n_gtz gt 0 then begin
      fmin = min((*self.pfN)[gtz], MAX=fmax)
    endif else begin
      fmin = 0. ;all data is zero, basically an error case
      fnax = 1.
    endelse
  endif else begin
    fmin = min((*self.pfN), MAX=fmax)
  endelse
  return, [fmin, fmax]
end
;
; COORDINATE CONVERSION 
; COORD_CONV の値を取�
;
function DataManagement::getCoordConv, XS=xs, YS=ys, ZS=zs
  
  if (self.volxdim le 0) or (self.volydim le 0) or (self.volzdim le 0) then return, !null
 
  xMax = self.volxdim - 1
  yMax = self.volydim - 1
  zMax = self.volzdim - 1

  ; Compute coordinate conversion to normalize.
  maxDim = MAX([xMax, yMax, zMax])
  xs = [-0.5 * xMax/maxDim, 1.0/maxDim]
  ys = [-0.5 * yMax/maxDim, 1.0/maxDim]
  ;zs = [(-zMin2/(zMax2-zMin2))-0.5, 1.0/(zMax2-zMin2)]
  zoom = 1.0
  zs = [-0.5*zMax/maxDim, 1.0/maxDim]*zoom
  return,1
  
end
;
;
;
function DataManagement::getVolDimension
  return, [self.volxdim, self.volydim, self.volzdim]
end
;
;
;
function DataManagement::getXSliceText
  self.oConf->GetProperty, axis_unit=axis_unit
  if axis_unit eq 'energy' then ret = *(self.plSliderEX) else ret = *(self.plSliderVX) 
  return, ret
end
;
;
;
function DataManagement::getYSliceText
  self.oConf->GetProperty, axis_unit=axis_unit
  if axis_unit eq 'energy' then ret = *(self.plSliderEY) else ret = *(self.plSliderVY)
  return, ret
end
;
;
;
function DataManagement::getZSliceText
  self.oConf->GetProperty, axis_unit=axis_unit
  if axis_unit eq 'energy' then ret = *(self.plSliderEZ) else ret = *(self.plSliderVZ)
  return, ret
end
;
;+
;<B>Purpose :</B> Definitions of DataManagement Class. <P>
; 離散�タオブジェクト�定義�
;-
pro DataManagement__define
;@stel3d_common

  struct_hide, {DataManagement, $
    olep:obj_new(), $
    oConf:obj_new(), $
    lDataNum:0L, $
    lShowNum:0L, $
    fXdim:0.0, $
    fYdim:0.0, $
    fZdim:0.0, $
    volxdim:0,  $
    volydim:0,  $
    volzdim:0,  $
    cSpinTrange:strarr(2), $
    pTimekeys:ptr_new(), $
    plShowIdx:ptr_new(), $
    pdT:ptr_new(), $
    pfX:ptr_new(), $
    pfY:ptr_new(), $
    pfZ:ptr_new(), $
    pfN:ptr_new(), $
    xrange: ptr_new(), $
    yrange: ptr_new(), $
    zrange: ptr_new(), $
    range_set_by_kws: 0b, $
    plSliderVX:ptr_new(), $ ;スライダーヂ�ス�
    plSliderVY:ptr_new(), $ ;スライダーヂ�ス�
    plSliderVZ:ptr_new(), $ ;スライダーヂ�ス�
    plSliderEX:ptr_new(), $ ;スライダーヂ�ス�
    plSliderEY:ptr_new(), $ ;スライダーヂ�ス�
    plSliderEZ:ptr_new(), $ ;スライダーヂ�ス�
    oPalette:obj_new() $
  }

end
