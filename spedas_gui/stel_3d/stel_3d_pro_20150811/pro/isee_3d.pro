;+
; <B>Purpose :</B>三次元データアプリケーション。<P>
;-
pro isee_3d, $
    ; INPUT FILE  
    infile, $                     ; 入力ファイル。
    ; HASH CONTAINING DATA
    data=data, $
    ; TIME RANGE. If not set, use mouse click to determine time range. 
    TRANGE=trange, $              ; 時間幅。現在必須データ(指定が無ければtlimitのようにマウスクリックで指定。)
    CURTIME=curtime, $
    ; SCATTER MODE 
    SCATTER=scatter, $            ; 表示方法1（離散データ表示）
    ; SLICE VOLUME MODE 
    SLICE_VOLUME=slice_volume, $  ; 表示方法2（スライスボリューム表示）
    ; ISOSURFACE MODE 1 
    ISOSURFACE1=isosurface1,  $   ; 表示方法3（isosurface表示）[追加]
    ; ISOSURFACE MODE 2 
    ISOSURFACE2=isosurface2,  $   ; 表示方法4（isosurface表示）[追加]
    ; SET MAGNETIC FIELD VECTORS 
    BFIELD=bfield, $              ; 磁場ベクトル
    ; SET VELOCITY VECTORS 
    VELOCITY=velocity, $          ; 速度ベクトル
    ; SET VIEW VECTOR 
    VIEW=view, $                  ; 視点ベクトル
    ; GSM COORDINATE (NOT YET COMPLETE) 
    GSM=gsm, $                    ; 座標系１
    ; MAGNETIC FIELD COORDINATE 
    MAG_COORD=mag_coord, $        ; 座標系２
    ; S/C COORDINATE 
    SC_COORD=sc_coord, $          ; 座標系３
    ; GSE COORDINATE (NOT YET COMPLETE) 
    GSE=gse, $                   ; [未実装]座標系４
    ; SM COORDINATE (NOT YET COMPLETE) 
;    sm=sm, $                     ; [未実装]座標系５
;    bce=bce, $                   ; [未実装]座標系６
    XRANGE=xrange, $              ; X軸の幅
    YRANGE=yrange, $              ; Y軸の幅
    ZRANGE=zrange, $              ; Z軸の幅
    ; UNIT OF AXIS (Velocity or Energy) 
    AXIS_UNIT=axis_unit, $        ; 軸の単位('velocity','energy' のいずれかを指定)
    ; UNIT OF PHYSICAL QUANTITY (Counts or PSD) 
    UNIT=unit, $                  ; 物理量の単位（'counts','psd'のいずれかを指定）
    ; NUMBER OF TIME STEP 
    STEP=step,  $                 ; Step の値
    ; NUMBER OF SPIN SUM (FOR HOW MANY SPINS ARE DATA ACCUMULATED?)  
    SPINSUM=spinsum, $            ; Spin Sum の値
    ; MAX AND MIN OF PHYSICAL QUANTITY 
    RANGE=range, $                ; 物理量の上限下限値
    ; USER-DEFINED VECTORS 
    VECTOR=vector, $              ;　ユーザー指定のベクトル
    ; CONFIGURATION FILE (NOT YET COMPLETE) 
    CONFIG=config, $              ; [未実装]コンフィグファイルのパス
    ; BELOW ARE USED FOR SLICE VOLUME MODE 
    ; 以下はスライス・ボリューム表示時に使用
    SLICE_XY=slice_xy, $            ; 2Dスライス面と場所XY面
    SLICE_YZ=slice_yz, $            ; 2Dスライス面と場所YZ面
    SLICE_XZ=slice_xz, $            ; 2Dスライス面と場所ZX面
    ; DEFINE INTERPOLATION METHOD.  
    INTERPOL=interpol, $            ; 補間方法を指定
    ; MESH OF ISOSURFACE 1 
    ISO1_MESH=iso1_mesh, $          ; isosurface1のメッシュ
    ; MESH OF ISOSURFACE 2  
    ISO2_MESH=iso2_mesh, $          ; isosurface2のメッシュ
    ; COLOR OF ISOSURFACE 1 
    ISO1_COLOR=iso1_color, $        ; isosurfaceのカラー
    ; COLOR OF ISOSURFACE 2 
    ISO2_COLOR=iso2_color, $        ; isosurfaceのカラー
    ; LEVEL OF ISOSURFACE 1
    ISO1_LEVEL=iso1_level, $        ; isosurfaceの表示レベル[追加]
    ; LEVEL OF ISOSURFACE 2 
    ISO2_LEVEL=iso2_level, $        ; isosurfaceの表示レベル[追加]
    ; COLOR TABLE NUMBER.  
    COLOR_TABLE=color_table, $      ; color table の番号
    ; NUMBER OF LEVELS FOR CONOURS OF SLICE MODE 
    CONT_NLEVELS=cont_nlevels, $    ; contourの NLEVELS
    COLOR_MIN_VAL=color_min_val, $
    COLOR_MAX_VAL=color_max_val, $
    ; OPTIONS FOR TEST ENVIRONMENT 
    ; 以下はテスト用のオプション
    xsize=xsize, $                ; IN: (opt) pixel size of draw window.
    ysize=ysize                   ; IN: (opt) pixel size of draw window.

compile_opt idl2
  @stel3d_common
;  cd, file_dirname(routine_filepath())
  ptr = ptr_valid(COUNT=ptr_count)
  obj = obj_valid(COUNT=obj_count)
  ;
  ; version check
  if float(!version.release) lt 8.2 then message, 'please use IDL 8.2 or later'

  ; CHECK TRANGE KEYWORD TO SHOW AN E-T DIAGRAM. . 
  ; THE XTPLOT PACKAGE WILL BE USED IN SHOW_ET_DIAGRAM(). 
  ; 入力キーワードチェック
  if not keyword_set(trange) then begin
    trange = show_et_diagram()
    if trange[0] eq -1 then message, 'invalid TRANGE'
  endif

  ; CHECK INPUT FILE FOR 3D DISTRIBUTIONS. 
  if not keyword_set(infile) and undefined(data) then begin
;    cd, file_dirname(routine_filepath())
    if ~n_elements(infile) then infile = dialog_pickfile(FILTER='19971212_lep_psd_8532.txt')
    if infile eq '' then begin
      print, 'please specify input file'
      return
    endif
  endif
  ;
  ; READ FILE 
  ; ファイルの読み込み
  ;
  olep = obj_new('stel_import_lep')
  if undefined(data) then begin
    res = olep.read_lep(infile, TRANGE=trange)
  endif else begin
    res = olep.read_hash(data, trange=trange)
  endelse
  ; 
  ; UPDATE TIME RANGE, USING THE INPUT FILE (INFILE). 
  ; trangeをファイルからのデータに更新する
  print, 'trange from ui' + trange
  trange = olep.getTrange()
  print, 'trange from file' + trange
  
  if ~res then begin
    message, 'import error', /CONTINUE
    return
  endif
  
  ;import support variables
  support = olep.read_support(bfield=bfield, velocity=velocity)
  if ~support then begin
    message, /info, 'failed to import one or more specified support variable'
  endif

  timeKeys = olep.getTimeKeys()
  numTimeKeys = n_elements(timeKeys)
  if ~keyword_set(curtime) then begin
    curtime = (olep.getTimeKeys())[0]
  endif
  ;
  ; GET VECTOR INFORMATION 
  ; ベクタ情報の取得
  mag_vect = olep.getVector(curtime)
  ;print, 'mag vector: ', mag_vect
  vel_vect = olep.getVector(curtime, /VEL)
  tBfield = {VEC, show:1b, color:'cyan', x:mag_vect[0], y:mag_vect[1], z:mag_vect[2], thick:2, length:'full'}
  tVelocity = {VEC, show:1b, color:'yellow', x:vel_vect[0], y:vel_vect[1], z:vel_vect[2], thick:2, length:'full'}
  ;
  ; get maximum vectors
  max_mag_vec = stel3d_get_max_vector(olep, timeKeys)
  max_vel_vec = stel3d_get_max_vector(olep, timeKeys, /VEL)
  
  ; OBJECT FOR CONFIGRATION DATA. 
  ; 設定データオブジェクト
  oConf = obj_new('ConfigData')
  oConf->SetProperty, TRANGE=trange, $
    CURTIME=curtime, $
    NUMTIMEKEYS=numtimekeys,    $
    SCATTER=scatter,            $
    SLICE_VOLUME=slice_volume,  $
    ISOSURFACE1=isosurface1,    $
    ISOSURFACE2=isosurface2,    $
    MAG_COORD=mag_coord,        $ 
    SC_COORD=sc_coord,    $
    UNIT=unit,            $
    AXIS_UNIT=axis_unit,  $
    STEP=step,        $
    SPINSUM=spinsum,  $
    XRANGE=xrange,    $
    YRANGE=yrange,    $
    ZRANGE=zrange,    $
    RANGE=range,      $
    INTERPOL=interpol, $
    ; MAGNEITC FIELD VECTOR 
    BFIELD=tBfield, $      ; 磁場ベクトル
    ; VELOCITY VECTOR 
    VELOCITY=tVelocity, $  ; 速度ベクトル
    ; VIEW VECTOR 
    VIEW=view, $          ; 視点ベクトル
    ; USER-DEFINED VECTOR 
    USER=vector, $        ; ユーザー指定ベクトル
    ; LOCATION OF X-Y SLICED PLANE 
    SLICE_XY=slice_xy, $  ; 2Dスライス面と場所XY面
    ; LOCATION OF Y-Z SLICED PLANE 
    SLICE_YZ=slice_yz, $  ; 2Dスライス面と場所YZ面
    ; LOCATION OF X-Z SLICED PLANE 
    SLICE_XZ=slice_xz, $  ; 2Dスライス面と場所ZX面
    ; MESH OF ISOSURFACE 1 
    ISO1_MESH=iso1_mesh,  $     ; isosurface1のメッシュ
    ; MESH OF ISOSURFACE 2
    ISO2_MESH=iso2_mesh,  $     ; isosurface2のメッシュ
    ; COLOR OF ISOSURFACE 1 
    ISO1_COLOR=iso1_color,  $     ; isosurface1のカラー
    ; COLOR OF ISOSURFACE 2
    ISO2_COLOR=iso2_color,  $     ; isosurface2のカラー
    ; LEVEL OF ISOSURFACE 1 
    ISO1_LEVEL=iso1_level,  $     ; isosurface1の表示レベル
    ; LEVEL OF ISOSURFACE 2
    ISO2_LEVEL=iso2_level,  $     ; isosurface2の表示レベル
    ; COLOR TABLE NUMBER 
    ; color table の番号
    COLOR_TABLE=color_table, $    
    ; NUMBER OF CONTOUR LEVELS 
    CONT_NLEVELS=cont_nlevels,    $  ; Contour Nlevels
    COLOR_MIN_VAL=color_min_val,  $
    COLOR_MAX_VAL=color_max_val,  $
    MAX_MAG_VEC=max_mag_vec,      $
    MAX_VEL_VEC=max_vel_vec
    
  ; READ SCATTER DATA (i.e., ORIGINAL PARTICLE DATA) FROM THE INPUT FILE 
  ; AND THEN SAVE THEM IN AN OBJECT. 
  ; ファイルから離散データを読みオブジェクトに保持する
  oData = obj_new('DataManagement', olep, oConf)
  if not obj_valid(oData) then message, 'Unable to create DataManagement object.'

  ;----------------------------------------
  ;   Create widgets.
  ;----------------------------------------
  stel3d_widget, oData, oConf
  
end
;------------------------------------------------------
;
; test rogram
;
;------------------------------------------------------
pro test_stel3d
  
  thm_init
  ;cd, file_dirname(routine_filepath())
  ;infile = dialog_pickfile(FILTER='19971212_lep_psd_8532.txt')
  infile = '19971212_lep_psd_8532.txt'
  if infile eq '' then return

  ; テスト用の設定
  ;trange=['1997-12-12/13:47:11', '1997-12-12/14:00:00']
  ;trange =['1997-12-12/13:47:11', '1997-12-12/13:49:35']
  xrange=[-100,100]
  yrange=[-200,200]
  zrange=[-200,300]
  range=[0,80]
  
  tUser = {vec, show:1b, color:'yellow', x:1.0, y:3.0^0.5, z:3.0, thick:2, length:'half'}
  tMagnetic = {vec, show:0b, color:'cyan', x:10.0, y:10.0, z:2.0, thick:2, length:'full'}
  tVelocity = {vec, show:0b, color:'yellow', x:400.0, y:100.0, z:10.0, thick:2, length:'half'}
  tSliceXY = {SLICE_2D, show:1b, position:7L, Contour:1b, Fill:1b}
  tSliceYZ = {SLICE_2D, show:1b, position:10L, Contour:1b, Fill:1b}
  tSliceZX = {SLICE_2D, show:1b, position:6L, Contour:1b, Fill:1b}

  ;  ;case1
  ;  stel3d, infile, trange=trange  
  ;  ;case2
  ;  stel3d, infile, trange=trange, /SCATTER
  ;  ;case3
  ;  stel3d, infile, trange=trange, /SLICE_VOLUME
  ;  ;case4
  ;  stel3d, infile, trange=trange, /scatter, /slice_volume
  ;  stel3d, infile, trange=trange, /scatter, /SLICE_VOLUME, xrange=[-2747, -1500]
  ;  ;case5
  ;  stel3d, infile, trange=trange, /scatter, /slice_volume, xrange=xrange
  ;  ;case6
  ;  stel3d, infile, trange=trange, /scatter, /slice_volume, yrange=yrange
  ;  ;case7
  ;  stel3d, infile, trange=trange, /scatter, /slice_volume, zrange=zrange
  ;  ;case8
  ;  stel3d, infile, trange=trange, /scatter, /slice_volume, range=range
  ;  ;case9
  ;  stel3d, infile, trange=trange, /scatter, /slice_volume, xrange=xrange, yrange=yrange, zrange=zrange
  ;  ;case10
  ;  stel3d, infile, trange=trange, /scatter, range=range, vector=tUser
  ;  ;case11
  ;  tSliceXY = {SLICE_2D, show:1b, position:7L, Contour:1b, Fill:1b}
  ;  tSliceXY = {SLICE_2D, show:0b, position:7L, Contour:1b, Fill:1b}
  ;  tSliceXY = {SLICE_2D, show:1b, position:7L, Contour:0b, Fill:1b}
  ;  tSliceXY = {SLICE_2D, show:1b, position:7L, Contour:1b, Fill:0b}
  ;  tSliceXY = {SLICE_2D, show:1b, position:7L, Contour:0b, Fill:0b}
  ;  stel3d, infile, trange=trange, /scatter, range=range, slice_xy=tSliceXY
  
  ;  ;case12
  ;  tSliceYZ = {SLICE_2D, show:1b, position:7L, Contour:1b, Fill:1b}
  ;  tSliceYZ = {SLICE_2D, show:0b, position:7L, Contour:1b, Fill:1b}
  ;  tSliceYZ = {SLICE_2D, show:1b, position:7L, Contour:0b, Fill:1b}
  ;  tSliceYZ = {SLICE_2D, show:1b, position:7L, Contour:1b, Fill:0b}
  ;  tSliceYZ = {SLICE_2D, show:1b, position:7L, Contour:0b, Fill:0b}
  ;  stel3d, infile, trange=trange, /scatter, range=range, slice_yz=tSliceYZ
  
  ;  ;case13
  ;  tSliceZX = {SLICE_2D, show:1b, position:7L, Contour:1b, Fill:1b}
  ;  tSliceZX = {SLICE_2D, show:0b, position:7L, Contour:1b, Fill:1b}
  ;  tSliceZX = {SLICE_2D, show:1b, position:7L, Contour:0b, Fill:1b}
  ;  tSliceZX = {SLICE_2D, show:1b, position:7L, Contour:1b, Fill:0b}
  ;  tSliceZX = {SLICE_2D, show:1b, position:7L, Contour:0b, Fill:0b}
  ;  stel3d, infile, trange=trange, /scatter, range=range, slice_xz=tSliceZX
  
  ;  ;case14
  ;  stel3d, infile, trange=trange, /scatter, range=range, slice_xy=tSliceXY, slice_yz=tSliceYZ, slice_xz=tSliceZX

  ;  ;case15
  ;  stel3d, infile, trange=trange, /isosurface, range=range

  ;case15
  ;  stel3d, infile, TRANGE=trange, /ISOSURFACE1, ISO1_LEVEL=[40, 60], /ISOSURFACE2, $
  ;    /ISO2_MESH, ISO2_LEVEL=[10,30]
  ;stel3d, infile, TRANGE=trange,  RANGE=range, LEVEL=125
  ;stel3d, infile, TRANGE=trange, /SLICE_VOLUME
  
  stel3d, infile,  SPINSUM=1, /SLICE_VOLUME

end
