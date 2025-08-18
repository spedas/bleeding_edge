;+
; <B>File Name :</B>configdata__define.pro<P>
; <B>Class Name :</B>ConfigData<P>
;
;@file_comments
; <B>Purpose :</B><P>
; Configuration data object. 
; コンフィグデータオブジェクト。<P>
;
; <B>Members :</B><P>
; 
;   - TIME RANGE - 
;   trange        時間幅<P>
;   - CURRENT TIME - 
;   curtime       表示に使用する時間
;   - NUMBER OF OBESRVATION 
;   numtimekeys   観測時間の数
;   - SCATTER MODE - 
;   scatter       表示方法1（離散データ表示）<P>
;   - SLICE-VOLUME MODE 
;   slice_volume  表示方法2（スライスボリューム表示）<P>
;   - MAGNETIC FIELD VECTOR - 
;   ptmagnetic    磁場ベクトル<P>
;   - VELOCITY VECTOR -  
;   ptvelocity    速度ベクトル<P>
;   - VIEW VECTOR - 
;   ptview        視点ベクトル<P>
;   - COORDINATE 1 - 
;   gsm           座標系１<P>
;   - COORDINATE 2 - 
;   mag           座標系２<P>
;   - COORDINATE 3 - 
;   sc            座標系３<P>
;   - COORDINATE 4 - 
;   gse           座標系４<P>
;   - COORDINATE 5 - 
;   sm            座標系５<P>
;   - COORDINATE 6 - 
;   bce           座標系６<P>
;   - SETTING FOR X RANGE (ON/OFF) - 
;   set_xrange    X軸の幅の設定on/off<P>
;   - X RANGE - 
;   xrange        X軸の幅<P>
;   - SETTING FOR Y RANGE (ON/OFF) - 
;   set_yrange    Y軸の幅の設定on/off<P>
;   - Y RANGE - 
;   yrange        Y軸の幅<P>
;   - SETTING FOR Z RANGE (ON/OFF) - 
;   set_zrange    Z軸の幅の設定on/off<P>
;   - Z RANGE - 
;   zrange        Z軸の幅<P>
;   - UNIT OF AXIS (VELOCITY, ENERGY, OR MU); MU NOT YET COMPLETE 
;   axis_unit     軸の単位('velocity','energy','mu'のいずれかを指定)<P>
;   - SETTING FOR MAX & MIN OF PHYSICAL QUANTITY - 
;   set_range     物理量の上限下限値の設定on/off<P>
;   - MAX & MIN OF PHYSICAL QUANTITY - 
;   range         物理量の上限下限値<P>
;   - UNIT OF PHYSICAL QUANTITY (DIFFERENTIAL FLUX, ENERGY FLUX, OR PSD) - 
;       ENERGY FLUX NOT YET COMPLETE 
;   unit          物理量の単位（'diff_flux','energy_flux','psd'のいずれかを指定）<P>
;   - USER-DEFINED VECTOR - 
;   ptuser        ユーザー指定のベクトル<P>
;   - PATH FOR CONFIGURATION FILE - 
;   config        コンフィグファイルのパス<P>
;   - MAX & MIN OF VOLUME - 
;   vol_range     ボリュームの上限下限値<P>
;   - COLOR OF VOLUME - 
;   vol_color     ボリュームの色<P>
;   - MAX & MIN of ADDITIONAL VOLUME - 
;   vol_range_add 追加ボリュームの上限下限値<P>
;   - COLOR of ADDITIONAL VOLUME - 
;   vol_color_add 追加ボリュームの色<P>
;   - LOCATION OF 1D SLICE (X) - 
;   pslice_x      1Dスライス面と場所X<P>
;   - LOCATION OF 1D SLICE (Y) - 
;   pslice_y      1Dスライス面と場所Y<P>
;   - LOCATION OF 1D SLICE (Z) - 
;   pslice_z      1Dスライス面と場所Z<P>
;   - LOCATION OF 2D SLICE (xy) - 
;   ptslice_xy    2Dスライス面と場所XY面<P>
;   - LOCATION OF 2D SLICE (yz) - 
;   ptslice_yz    2Dスライス面と場所YZ面<P>
;   - LOCATION OF 2D SLICE (zx) - 
;   ptslice_xz    2Dスライス面と場所ZX面<P>
;   - SETTING OF INTERPOLATION METHOD - 
;   interpol      補間方法を指定<P>
;   - COLOR TABLE (33 BY DEFAULT) - 
;   color_table    カラーテーブルの番号（デフォルトは33）
;   - NUMBER OF CONTOUR LEVEL - 
;   cont_nlevels  コンタのレベル数
;
;@history
; Who      Date        version  Description<P>
; ----------------------------------------------------------------------------<P>
; Kunihiro Keika 2015/07/21 Added English comments. 
; Exelis VIS KK 2014/05/20  1.0.0.0  Original Version<P>
;-


;+
;
; CONSTRUCTER of CONFIGURATION DATA OBJECT 
; <B>Purpose :</B>コンフィグデータオブジェクトのコンストラクタ。<P>
;
;  SUCCESS (1), FAILURE (<0) 
; @returns 成功(1)、不成功(0以下)
;
;-
function ConfigData::init
;@stel3d_common

  self.interpol = 'qgrid3'
  self.gsm = 1b
  self.sc_coord=1B
  self.mag_coord=0B
  self.unit='count'
  self.axis_unit='velocity'
  self.spinsum= 1
  self.step = 1
  self.iso1_level = [30,50]
  self.iso2_level = [10,30]
  self.iso1_color = 'magenta'
  self.iso2_color = 'lime'
  self.color_table=33
  loadct, 33, /SILENT
  self.cont_custom = 0B
  self.cont_nlevels = 8
 
  void = self->IDL_Object::Init()
  ;----------------------
  ; DEFAULT VALUE FOR VECTORS 
  ; ベクトル初期値
;  tMagnetic = {VEC, show:0b, color:'cyan', x:10.0, y:10.0, z:2.0, thick:2, length:'full'}
;  tVelocity = {VEC, show:0b, color:'yellow', x:400.0, y:100.0, z:10.0, thick:2, length:'half'}
  tUser = {VEC, show:0b, color:'magenta', x:0.0, y:1.0, z:0.0, thick:2, length:'full'}
  tView = {VEC, show:0b, color:'black', x:0.0, y:0.0, z:-1.0, thick:2, length:'quarter'}

  self.ptmagnetic = ptr_new(tMagnetic)
  self.ptvelocity = ptr_new(tVelocity)
  self.ptuser = ptr_new(tUser)
  self.ptview = ptr_new(tView)
    
  ;----------------------
  ; DEFAULT VALUES FOR 2D SLICE 
  ; 2D Slice 初期値
  tSliceXY = {SLICE_2D, show:0b, position:0L, Contour:0b, Fill:0b}
  tSliceYZ = {SLICE_2D, show:0b, position:0L, Contour:0b, Fill:0b}
  tSliceZX = {SLICE_2D, show:0b, position:0L, Contour:0b, Fill:0b}
  self.ptslice_xy = ptr_new(tSliceXY)
  self.ptslice_yz = ptr_new(tSliceXY)
  self.ptslice_xz = ptr_new(tSliceXY)

  return, 1
End

;+
;
; GET RGB FROM COLOR NAMES.  
; <B>Purpose :</B>色名よりRGBを取得する。<P>
;
;-
function ConfigData::GetRGB, cColor

  ;@stel3d_common
  rgb=[0,0,0]
  case (cColor) of
    'red': rgb=!COLOR.red
    'blue': rgb=!COLOR.blue
    'green': rgb=!COLOR.green
    'lime': rgb=!COLOR.lime
    'yellow': rgb=!COLOR.yellow
    'magenta': rgb=!COLOR.magenta
    'cyan': rgb=!COLOR.cyan
    'white': rgb=!COLOR.white
    'black': rgb=!COLOR.black
    else: begin
      message, 'It is a color that is not defined.'
    end
  endcase

  return, rgb

end

;+
;
; DESTRUCTOR OF CONFIGURATION DATA OBJECT 
; <B>Purpose :</B>コンフィグデータオブジェクトのデストラクタ。<P>
;
;-
pro ConfigData::cleanup

  ;@stel3d_common

  if ptr_valid(self.ptmagnetic) ne 0 then ptr_free, self.ptmagnetic
  if ptr_valid(self.ptvelocity) ne 0 then ptr_free, self.ptvelocity
  if ptr_valid(self.ptview) ne 0 then ptr_free, self.ptview
  if ptr_valid(self.ptuser) ne 0 then ptr_free, self.ptuser
  if ptr_valid(self.ptslice_xy) ne 0 then ptr_free, self.ptslice_xy
  if ptr_valid(self.ptslice_yz) ne 0 then ptr_free, self.ptslice_yz
  if ptr_valid(self.ptslice_xz) ne 0 then ptr_free, self.ptslice_xz
 
end

;+
;
; SETTING OF PROPERTIES 
; <B>Purpose :</B>プロパティを設定する。<P>
;
;-
pro Configdata::SetProperty, $
  TRANGE=trange, $  ; 時間幅
  CURTIME=curtime, $
  SC_COORD=sc_coord, $
  MAG_COORD=mag_coord, $
  NUMTIMEKEYS=numtimekeys, $
  SCATTER=scatter, $
  SLICE_VOLUME=slice_volume, $
  ISOSURFACE1=isosurface1, $      ; 表示方法3（isosurface表示）[追加]
  ISOSURFACE2=isosurface2, $      ; 表示方法3（isosurface表示）[追加]
  UNIT=unit,    $
  AXIS_UNIT=axis_unit, $
  SPINSUM=spinsum, $
  STEP=step,  $
;  spinTrange=spintTrange, $ ; Set は設定させない
  XRANGE=xrange, $
  YRANGE=yrange, $
  ZRANGE=zrange, $
  RANGE=range, $
  INTERPOL=interpol, $
  ; MAGNETIC FIELD VECTOR 
  BFIELD=bfield, $      ; 磁場ベクトル
  ; VELOCITY VECTOR 
  VELOCITY=velocity, $  ; 速度ベクトル
  ; VIEW VECTOR 
  VIEW=view, $          ; 視点ベクトル
  ; USER-DEFINED VECTOR 
  USER=user, $          ; ユーザー指定ベクトル
  ; POSITION OF 2D SLICE (XY) 
  SLICE_XY=slice_xy, $  ; 2Dスライス面と場所XY面
  ; POSITION OF 2D SLICE (YZ) 
  SLICE_YZ=slice_yz, $  ; 2Dスライス面と場所YZ面
  ; POSITION OF 2D SLICE (ZX) 
  SLICE_XZ=slice_xz, $  ; 2Dスライス面と場所ZX面
  ISO1_MESH=iso1_mesh,  $   ; isosurface1のメッシュ
  ISO2_MESH=iso2_mesh,  $   ; isosurface2のメッシュ
  ISO1_COLOR=iso1_color,  $   ; isosurfaceのカラー
  ISO2_COLOR=iso2_color,  $   ; isosurfaceのカラー
  ISO1_LEVEL=iso1_level,  $   ; isosurfaceの表示レベル[追加]
  ISO2_LEVEL=iso2_level,  $   ; isosurfaceの表示レベル[追加]
  COLOR_TABLE=color_table, $  ; ColorTableの番号
  CONT_CUSTOM=cont_custom,  $   ; Auto:0, Custom:1
  CONT_LEVELS=cont_levels,     $ ; Contour Levels for custom mode
  CONT_NLEVELS=cont_nlevels,   $ ; Contour Nlevels
  COLOR_MIN_VAL=color_min_val, $  ; Temporary Color Min value
  COLOR_MAX_VAL=color_max_val, $     ; Temporary Color max value
  XANG=xang, $
  YANG=yang, $
  ZANG=zang, $
  ROTMAT=rotmat, $  ; Rotation matrix 
  MAX_MAG_VEC=max_mag_vec, $
  MAX_VEL_VEC=max_vel_vec, $
  TIMEKEYS=timekeys
;  @stel3d_common

  ;--------------------
  ; scatter/slice_volume
  if n_elements(scatter) eq 1 then self.scatter = scatter
  if n_elements(slice_volume) eq 1 then self.slice_volume = slice_volume
  if n_elements(isosurface1) eq 1 then self.isosurface1 = isosurface1
  if n_elements(isosurface2) eq 1 then self.isosurface2 = isosurface2

  ;--------------------
  ; range
  if n_elements(trange) eq 2 then self.trange = trange
  if n_elements(curtime) eq 1 then self.curtime=curtime
  if n_elements(numtimekeys) eq 1 then self.numtimekeys=numtimekeys
  if n_elements(sc_coord) eq 1 then begin
    self.sc_coord = sc_coord
    self.mag_coord = 0b
  endif
  if n_elements(mag_coord) eq 1 then begin
    self.mag_coord=mag_coord
    self.sc_coord=0B
  endif
  if n_elements(xrange) eq 2 then begin
    self.set_xrange = 1b
    self.xrange = xrange
  endif
  if n_elements(yrange) eq 2 then begin
    self.set_yrange = 1b
    self.yrange = yrange
  endif
  if n_elements(zrange) eq 2 then begin
    self.set_zrange = 1b
    self.zrange = zrange
  endif
  if n_elements(range) eq 2 then begin
    self.set_range = 1b
    self.range = range
  endif
  
  if n_elements(unit) eq 1 then self.unit = strlowcase(unit)
  if n_elements(axis_unit) eq 1 then self.axis_unit=strlowcase(axis_unit)
  
  ;--------------------
  ; Time
  if n_elements(spinsum) eq 1 then self.spinsum = spinsum
  if n_elements(step) eq 1 then self.step = step
  if n_elements(spinTrange) eq 2 then self.spinTrange = spinTrange
    
  ;--------------------
  ; INTERPOLATION METHOD 
  ; 補間方法
  if n_elements(interpol) eq 1 then self.interpol = interpol

  ;--------------------
  ; vector
  if n_elements(bfield) eq 1 then begin
    if tag_names(bfield, /STRUCTURE_NAME) ne 'VEC' then message, 'Set the structure named VEC to bfield.'
    if ptr_valid(self.ptmagnetic) ne 0 then ptr_free, self.ptmagnetic
    self.ptmagnetic =ptr_new(bfield)
  endif
  if n_elements(velocity) eq 1 then begin
    if tag_names(velocity, /STRUCTURE_NAME) ne 'VEC' then message, 'Set the structure named VEC to velocity.'
    if ptr_valid(self.ptvelocity) ne 0 then ptr_free, self.ptvelocity
    self.ptvelocity =ptr_new(velocity)
  endif
  if n_elements(view) eq 1 then begin
    if tag_names(view, /STRUCTURE_NAME) ne 'VEC' then message, 'Set the structure named VEC to view.'
    if ptr_valid(self.ptview) ne 0 then ptr_free, self.ptview
    self.ptview =ptr_new(view)
  endif
  if n_elements(user) eq 1 then begin
    if tag_names(user, /STRUCTURE_NAME) ne 'VEC' then message, 'Set the structure named VEC to user.'
    if ptr_valid(self.ptuser) ne 0 then ptr_free, self.ptuser
    self.ptuser =ptr_new(user)
  endif

  ;--------------------
  ; 2D slice
  if n_elements(slice_xy) eq 1 then begin
    if TAG_NAMES(slice_xy, /STRUCTURE_NAME) ne 'SLICE_2D' then message, 'Set the structure named SLICE_2D to slice_xy.'
    if ptr_valid(self.ptslice_xy) ne 0 then ptr_free, self.ptslice_xy
    self.ptslice_xy =ptr_new(slice_xy)
  endif
  if n_elements(slice_yz) eq 1 then begin
    if TAG_NAMES(slice_yz, /STRUCTURE_NAME) ne 'SLICE_2D' then message, 'Set the structure named SLICE_2D to slice_yz.'
    if ptr_valid(self.ptslice_yz) ne 0 then ptr_free, self.ptslice_yz
    self.ptslice_yz =ptr_new(slice_yz)
  endif
  if n_elements(slice_xz) eq 1 then begin
    if TAG_NAMES(slice_xz, /STRUCTURE_NAME) ne 'SLICE_2D' then message, 'Set the structure named SLICE_2D to slice_xz.'
    if ptr_valid(self.ptslice_xz) ne 0 then ptr_free, self.ptslice_xz
    self.ptslice_xz =ptr_new(slice_xz)
  endif

  ;--------------------
  ; Isosurface level
  if n_elements(iso1_level) eq 2 then self.iso1_level = iso1_level
  if n_elements(iso2_level) eq 2 then self.iso2_level = iso2_level
  
  ;--------------------
  ; Isosurface color
  if n_elements(iso1_color) eq 1 then self.iso1_color = iso1_color
  if n_elements(iso2_color) eq 1 then self.iso2_color = iso2_color

  ;--------------------
  ; Isosurface mesh
  if n_elements(iso1_mesh) eq 1 then self.iso1_mesh = iso1_mesh
  if n_elements(iso2_mesh) eq 1 then self.iso2_mesh = iso2_mesh
  
  ; Color Table
  if n_elements(color_table) eq 1 then begin
    loadct, color_table, /SILENT
    self.color_table = color_table
  endif
  ;
  ;Contour
  if n_elements(cont_custom) eq 1 then begin
    self.cont_custom=cont_custom
  endif
  ;
  if n_elements(cont_levels) gt 0 then begin
    if ptr_valid(self.cont_levels) then ptr_free, self.cont_levels
    self.cont_levels=ptr_new(cont_levels, /NO_COPY)
  endif
  ;
  if n_elements(cont_nlevels) eq 1 then begin
    self.cont_nlevels = cont_nlevels
  endif
  ;
  ;Color Threshold
  if n_elements(color_min_val) eq 1 then begin
    self.color_min_val = color_min_val
  endif
  
  if n_elements(color_max_val) eq 1 then begin
    self.color_max_val = color_max_val
  endif
  ;
  ; rotate angle for MAG coordinate
  if n_elements(xang) eq 1 then begin
    self.xang = xang
  endif
  if n_elements(yang) eq 1 then begin
    self.yang = yang
  endif
  if n_elements(zang) eq 1 then begin
    self.zang = zang
  endif
  if n_elements(rotmat) eq 9 then begin 
    self.rotmat = rotmat 
  endif 
  ;
  ; maximum vector in selected time
  if n_elements(max_mag_vec) eq 3 then begin
    self.max_mag_vec = max_mag_vec
  endif
  if n_elements(max_vel_vec) eq 3 then begin
    self.max_vel_vec = max_vel_vec
  endif

end

;+
;
; GET PROPERTIES 
; <B>Purpose :</B>プロパティを取得する。<P>
;
;-
pro ConfigData::GetProperty, $
  TRANGE=trange, $  ; 時間幅
  CURTIME=curtime, $ ;表示している時間
  NUMTIMEKEYS=numtimekeys, $
  SCATTER=scatter, $
  slice_volume=slice_volume, $
  ISOSURFACE1=isosurface1, $      ; 表示方法3（isosurface表示）[追加]
  ISOSURFACE2=isosurface2, $      ; 表示方法3（isosurface表示）[追加]
  SC_COORD=sc_coord, $
  MAG_COORD=mag_coord, $
  XRANGE=xrange, $
  YRANGE=yrange, $
  ZRANGE=zrange, $
  UNIT=unit, $
  SPINSUM=spinsum, $
  STEP=step, $
;  spinTrange=spintTrange, $
  AXIS_UNIT=axis_unit, $
  RANGE=range, $
  INTERPOL=interpol, $
  BFIELD=bfield, $      ; 磁場ベクトル
  VELOCITY=velocity, $  ; 速度ベクトル
  VIEW=view, $          ; 視点ベクトル
  USER=user, $          ; ユーザー指定ベクトル
  SLICE_XY=slice_xy, $  ; 2Dスライス面と場所XY面
  SLICE_YZ=slice_yz, $  ; 2Dスライス面と場所YZ面
  SLICE_XZ=slice_xz, $  ; 2Dスライス面と場所ZX面
  ISO1_MESH=iso1_mesh,     $  ; isosurface1のメッシュ
  ISO2_MESH=iso2_mesh,     $  ; isosurface2のメッシュ
  ISO1_COLOR=iso1_color,    $  ; isosurfaceのカラー
  ISO2_COLOR=iso2_color,    $   ; isosurfaceのカラー
  ISO1_LEVEL=iso1_level,    $   ; isosurfaceの表示レベル[追加]
  ISO2_LEVEL=iso2_level,    $   ; isosurfaceの表示レベル[追加]
  COLOR_TABLE=color_table,  $   ; colortable の番号
  CONT_CUSTOM=cont_custom,  $   ; Auto:0, Custom:1
  CONT_LEVELS=cont_levels,  $   ; Contour Levels for custom mode
  CONT_NLEVELS=cont_nlevels,  $     ; Contour Nlevels
  COLOR_MIN_VAL=color_min_val,  $  ; Temporary Color Min value
  COLOR_MAX_VAL=color_max_val,  $     ; Temporary Color max value
  XANG=xang, $
  YANG=yang, $
  ZANG=zang, $
  ROTMAT=rotmat, $ 
  MAX_MAG_VEC=max_mag_vec, $
  MAX_VEL_VEC=max_vel_vec
  
  ;--------------------
  ; scatter/slice_volume
  if arg_present(scatter) then scatter = self.scatter
  if arg_present(slice_volume) then slice_volume = self.slice_volume
  if arg_present(isosurface1) then isosurface1 = self.isosurface1
  if arg_present(isosurface2) then isosurface2 = self.isosurface2
  if arg_present(trange) then trange = self.trange
  if arg_present(curtime) then curtime = self.curtime
  if arg_present(numtimekeys) then numtimekeys = self.numtimekeys
  if arg_present(sc_coord) then sc_coord = self.sc_coord
  if arg_present(mag_coord) then mag_coord = self.mag_coord
  
  ;--------------------
  ; unit 
  if arg_present(unit) then unit=self.unit
  if arg_present(axis_unit) then axis_unit=self.axis_unit
  
  ;--------------------
  ; range
  if arg_present(xrange) then begin
    if self.set_xrange eq 1b then xrange = self.xrange
  endif
  if arg_present(yrange) then begin
    if self.set_yrange eq 1b then yrange = self.yrange
  endif
  if arg_present(zrange) then begin
    if self.set_zrange eq 1b then zrange = self.zrange
  endif
  if arg_present(range) then begin
    if self.set_range eq 1b then range = self.range
  endif
  
  ;--------------------
  ; time
  if arg_present(spinsum) then spinsum=self.spinsum
  if arg_present(step) then step=self.step
;  if arg_present(spinTrange) then spinTrange=self.spinTrange

  ;--------------------
  ; INTERPOLATION METHOD 
  ; 補間方法
  if arg_present(interpol) then interpol = self.interpol

  ;--------------------
  ; vector
  if arg_present(bfield) then bfield = *self.ptmagnetic
  if arg_present(velocity) then velocity = *self.ptvelocity
  if arg_present(view) then view = *self.ptview
  if arg_present(user) then user = *self.ptuser

  ;--------------------
  ; 2D slice
  if arg_present(slice_xy) then slice_xy = *self.ptslice_xy
  if arg_present(slice_yz) then slice_yz = *self.ptslice_yz
  if arg_present(slice_xz) then slice_xz = *self.ptslice_xz

  ;--------------------
  ; Isosurface level
  if arg_present(iso1_level) then iso1_level = self.iso1_level
  if arg_present(iso2_level) then iso2_level = self.iso2_level
  
  ;--------------------
  ; Isosurface Color
  if arg_present(iso1_color) then iso1_color = self.iso1_color
  if arg_present(iso2_color) then iso2_color = self.iso2_color
  
  ;--------------------
  ; Isosurface Mesh
  if arg_present(iso1_mesh) then iso1_mesh = self.iso1_mesh
  if arg_present(iso2_mesh) then iso2_mesh = self.iso2_mesh
  
  ; color table
  if arg_present(color_table) then color_table = self.color_table
  ;
  ; contour nlevels
  if arg_present(cont_custom) then cont_custom=self.cont_custom
  if arg_present(cont_levels) then cont_levels=*self.cont_levels
  if arg_present(cont_nlevels) then cont_nlevels = self.cont_nlevels
  if arg_present(color_min_val) then color_min_val = self.color_min_val
  if arg_present(color_max_val) then color_max_val = self.color_max_val
  ;
  ;
  if arg_present(xang) then xang = self.xang
  if arg_present(yang) then yang = self.yang
  if arg_present(zang) then zang = self.zang
  if arg_present(rotmat) then rotmat = self.rotmat
  ;
  ; max vector in selected time 
  if arg_present(max_mag_vec) then max_mag_vec = self.max_mag_vec
  if arg_present(max_vel_vec) then max_vel_vec = self.max_vel_vec
  ;
  ; time keys
  ;if arg_present(timekeys) then timekeys = (*self.timekeys)

end

;+
;
;  READ CONFIGURATION FILE 
; <B>Purpose :</B>コンフィグファイルを読み込む。<P>
;  SUCCESS (1), FAILURE (<0) 
; @returns 成功(1)、不成功(0以下)
;
;-
function ConfigData::readfile, filepath
  @stel3d_common
  
  ; NOT YET COMPLETE 
  ; 未実装
  
  return, 1
end

;+
;
; EXTRACT CONFIGURATION FILE 
; <B>Purpose :</B>コンフィグファイルを書き出す。<P>
;
; SUCCESS (1), FAILURE (<0) 
; @returns 成功(1)、不成功(0以下)
;
; @param filepath {in} {required} {type=string}
;  SETTING OF PATH FOR CONFIGURATION FILE 
;　コンフィグファイルパスを設定する。
;
;-
function ConfigData::writefile, filepath
  @stel3d_common

  ; NOT YET COMPLETE 
  ; 未実装

  return, 1
end

;+
; DEFINITION OF CONFIGURATION DATA OBJECT 
;<B>Purpose :</B> Definitions of ConfigData Class. <P>
; コンフィグデータオブジェクトの定義。
;
;  TIME RANGE 
; @field trange   時間幅
;
;-
pro ConfigData__define
;@stel3d_common
compile_opt idl2

  struct_hide, {ConfigData, $
    inherits IDL_Object,    $
    ; TIME RANGE 
    trange:['',''], $             ; 時間幅。
    ; CURRENT TIME 
    curtime:'',     $             ; 現時刻
    ; NUMBER OF OBSERVATIONS 
    numtimekeys:0L, $             ; 観測時間の数
    ; SCATTER MODE 
    scatter:0b, $                 ; 表示方法1（離散データ表示）
    ; SLICE-VOLUME MODE 
    slice_volume:0b, $            ; 表示方法2（スライスボリューム表示）
    ; ISOSURFACE MODE 1 
    isosurface1:0b, $             ; 表示方法3（isosurface表示）[追加]
    ; ISOSURFACE MODE 2
    isosurface2:0b, $             ; 表示方法3（isosurface表示）[追加]
    ; MAGNETIC FIELD VECTOR 
    ptmagnetic:ptr_new(), $       ; 磁場ベクトル
    ; VELOCITY VECTOR 
    ptvelocity:ptr_new(), $       ; 速度ベクトル
    ; VIEW VECTOR 
    ptview:ptr_new(), $           ; 視点ベクトル
    ; COORDINATE 1 
    gsm:0b, $                     ; 座標系１
    ; COORDINATE 2 
    mag_coord:0b, $               ; 座標系２
    ; COORDINATE 3 
    sc_coord:0b, $                ; 座標系３
    ; COORDINATE 4 
    gse:0b, $                     ; 座標系４
    ; COORDINATE 5 
    sm:0b, $                      ; 座標系５
    ; COORDINATE 6 
    bce:0b, $                     ; 座標系６
    ; SETTING OF X RANGE (ON/OFF) 
    set_xrange:0b, $              ; X軸の幅の設定on/off
    ; X RANGE 
    xrange:[0.0,0.0], $           ; X軸の幅
    ; SETTING OF X RANGE (ON/OFF) 
    set_yrange:0b, $              ; Y軸の幅の設定on/off
    ; Y RANGE 
    yrange:[0.0,0.0], $           ; Y軸の幅
    ; SETTING OF X RANGE (ON/OFF) 
    set_zrange:0b, $              ; Z軸の幅の設定on/off
    ; Z RANGE 
    zrange:[0.0,0.0], $           ; Z軸の幅
    ; UNIT OF AXIS (VELOCITY, ENERGY, or MU); MU NOT YET COMPLETE 
    axis_unit:'', $               ; 軸の単位('velocity','energy','mu'のいずれかを指定)
    ; SETTING OF MAX & MIN OF PHYSICAL QUANTITY 
    set_range:0b, $               ; 物理量の上限下限値の設定on/off
    ; MAX & MIN OF PHYSICAL QUANTITY 
    range:[0.0,0.0], $            ; 物理量の上限下限値
    ; UNIT OF PHYSICAL QUANTITY (DIFFERENTIAL FLUX, ENERGY FLUX, OR PSD) 
    unit:'', $                    ; 物理量の単位（'diff_flux','energy_flux','psd'のいずれかを指定）
    ; NUMBER OF SPINS TO BE SUMMED. 
    spinsum:0, $                  ; Spin Sum の値
    ; TIME STEP FOR NEXT DISTRIBUTION 
    step:0,  $                    ; Step （秒）の値
;    spinTrange:strarr(2), $      ; spin　sum に必要な時間情報
    ; USER-DEFINED VECTOR 
    ptuser:ptr_new(), $           ;　ユーザー指定のベクトル
    ; PATH FOR CONFIGURATION FILE 
    config:'', $                  ; コンフィグファイルのパス
    ; MAX & MIN OF VOLUME 
    vol_range:[0.0,0.0], $        ; ボリュームの上限下限値
    ; COLOR OF VOLUME 
    vol_color:'', $               ; ボリュームの色
    ; MAX & MIN OF VOLUME 
    vol_range_add:[0.0,0.0], $    ; 追加ボリュームの上限下限値
    ; COLOR OF VOLUME 
    vol_color_add:'', $           ; 追加ボリュームの色
    ; POSITION OF 1D SLICE (X) 
    pslice_x:ptr_new(), $         ; 1Dスライス面と場所X
    ; POSITION OF 1D SLICE (Y) 
    pslice_y:ptr_new(), $         ; 1Dスライス面と場所Y
    ; POSITION OF 1D SLICE (Z) 
    pslice_z:ptr_new(), $         ; 1Dスライス面と場所Z
    ; POSITION OF 2D SLICE (XY) 
    ptslice_xy:ptr_new(), $       ; 2Dスライス面と場所XY面
    ; POSITION OF 2D SLICE (YZ) 
    ptslice_yz:ptr_new(), $       ; 2Dスライス面と場所YZ面
    ; POSITION OF 2D SLICE (ZX) 
    ptslice_xz:ptr_new(), $       ; 2Dスライス面と場所ZX面
    ; INTERPOLATION METHOD 
    interpol:'', $                ; 補間方法を指定
    iso1_mesh:0,  $               ; isosurface1のメッシュ
    iso2_mesh:0,  $               ; isosurface2のメッシュ
    iso1_color:'',  $             ; isosurface1のカラー
    iso2_color:'',  $             ; isosurface2のカラー
    iso1_level:[0.0, 0.0],  $     ; isosurface1の表示レベル
    iso2_level:[0.0, 0.0],  $     ; isosurface2の表示レベル
    color_table:0,      $         ; Color Table の番号
    cont_custom:0B,     $         ; Auto:0, Custom:1
    cont_levels:ptr_new(),  $     ; Contour Levels for custom mode
    cont_nlevels:0,   $           ; Contour Nlevles
    color_max_val:0d,  $          ; Max Threshold for Color stretch 
    color_min_val:0d,   $         ; Min Threshold for Color stretch
    xang:0.0, $
    yang:0.0, $
    zang:0.0, $
    rotmat:[[0d,0d,0d],[0d,0d,0d],[0d,0d,0d]], $ 
    max_mag_vec:[0d, 0d, 0d], $
    max_vel_vec:[0d, 0d, 0d], $
    dummy:0B $
  }

end
