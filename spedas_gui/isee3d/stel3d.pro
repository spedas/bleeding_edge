;+
;Procedure:
;  stel3d.pro 
;
;Purpose:
;  Backward compatibility wrapper for ISEE_3D.pro
;
;Notes:
;  Please refer to ISEE_3D and associated cribs
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2019-10-23 15:29:51 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27925 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/isee3d/stel3d.pro $
;-

pro stel3d, $
      infile, $                     ; 入力ファイル。
      data=data, $
      TRANGE=trange, $              ; 時間幅。現在必須データ(指定が無ければtlimitのようにマウスクリックで指定。)
      CURTIME=curtime, $
      SCATTER=scatter, $            ; 表示方法1（離散データ表示）
      SLICE_VOLUME=slice_volume, $  ; 表示方法2（スライスボリューム表示）
      ISOSURFACE1=isosurface1,  $   ; 表示方法3（isosurface表示）[追加]
      ISOSURFACE2=isosurface2,  $   ; 表示方法4（isosurface表示）[追加]
      BFIELD=bfield, $              ; 磁場ベクトル
      VELOCITY=velocity, $          ; 速度ベクトル
      VIEW=view, $                  ; 視点ベクトル
      GSM=gsm, $                    ; 座標系１
      MAG_COORD=mag_coord, $        ; 座標系２
      SC_COORD=sc_coord, $          ; 座標系３
      GSE=gse, $                   ; [未実装]座標系４
      XRANGE=xrange, $              ; X軸の幅
      YRANGE=yrange, $              ; Y軸の幅
      ZRANGE=zrange, $              ; Z軸の幅
      AXIS_UNIT=axis_unit, $        ; 軸の単位('velocity','energy' のいずれかを指定)
      UNIT=unit, $                  ; 物理量の単位（'counts','psd'のいずれかを指定）
      STEP=step,  $                 ; Step の値
      SPINSUM=spinsum, $            ; Spin Sum の値
      RANGE=range, $                ; 物理量の上限下限値
      VECTOR=vector, $              ;　ユーザー指定のベクトル
      CONFIG=config, $              ; [未実装]コンフィグファイルのパス
      SLICE_XY=slice_xy, $            ; 2Dスライス面と場所XY面
      SLICE_YZ=slice_yz, $            ; 2Dスライス面と場所YZ面
      SLICE_XZ=slice_xz, $            ; 2Dスライス面と場所ZX面
      INTERPOL=interpol, $            ; 補間方法を指定
      ISO1_MESH=iso1_mesh, $          ; isosurface1のメッシュ
      ISO2_MESH=iso2_mesh, $          ; isosurface2のメッシュ
      ISO1_COLOR=iso1_color, $        ; isosurfaceのカラー
      ISO2_COLOR=iso2_color, $        ; isosurfaceのカラー
      ISO1_LEVEL=iso1_level, $        ; isosurfaceの表示レベル[追加]
      ISO2_LEVEL=iso2_level, $        ; isosurfaceの表示レベル[追加]
      COLOR_TABLE=color_table, $      ; color table の番号
      CONT_NLEVELS=cont_nlevels, $    ; contourの NLEVELS
      COLOR_MIN_VAL=color_min_val, $
      COLOR_MAX_VAL=color_max_val, $
      xsize=xsize, $                ; IN: (opt) pixel size of draw window.
      ysize=ysize                   ; IN: (opt) pixel size of draw window.


compile_opt idl2, hidden


print,ssl_newline()+'###############################################'+ssl_newline()
print,'STEL3D has been renamed to ISEE_3D.  Please call the new routine directly.  '+ $
      'For example usage see MMS and THEMIS crib sheets located in:'
print,'  .../projects/mms/examples/ '
print,'  .../projects/themis/examples/'
print,+ssl_newline()+'###############################################'+ssl_newline()

wait, 2.

isee_3d, $
  infile, $                     ; 入力ファイル。
  data=data, $
  TRANGE=trange, $              ; 時間幅。現在必須データ(指定が無ければtlimitのようにマウスクリックで指定。)
  CURTIME=curtime, $
  SCATTER=scatter, $            ; 表示方法1（離散データ表示）
  SLICE_VOLUME=slice_volume, $  ; 表示方法2（スライスボリューム表示）
  ISOSURFACE1=isosurface1,  $   ; 表示方法3（isosurface表示）[追加]
  ISOSURFACE2=isosurface2,  $   ; 表示方法4（isosurface表示）[追加]
  BFIELD=bfield, $              ; 磁場ベクトル
  VELOCITY=velocity, $          ; 速度ベクトル
  VIEW=view, $                  ; 視点ベクトル
  GSM=gsm, $                    ; 座標系１
  MAG_COORD=mag_coord, $        ; 座標系２
  SC_COORD=sc_coord, $          ; 座標系３
  GSE=gse, $                   ; [未実装]座標系４
  XRANGE=xrange, $              ; X軸の幅
  YRANGE=yrange, $              ; Y軸の幅
  ZRANGE=zrange, $              ; Z軸の幅
  AXIS_UNIT=axis_unit, $        ; 軸の単位('velocity','energy' のいずれかを指定)
  UNIT=unit, $                  ; 物理量の単位（'counts','psd'のいずれかを指定）
  STEP=step,  $                 ; Step の値
  SPINSUM=spinsum, $            ; Spin Sum の値
  RANGE=range, $                ; 物理量の上限下限値
  VECTOR=vector, $              ;　ユーザー指定のベクトル
  CONFIG=config, $              ; [未実装]コンフィグファイルのパス
  SLICE_XY=slice_xy, $            ; 2Dスライス面と場所XY面
  SLICE_YZ=slice_yz, $            ; 2Dスライス面と場所YZ面
  SLICE_XZ=slice_xz, $            ; 2Dスライス面と場所ZX面
  INTERPOL=interpol, $            ; 補間方法を指定
  ISO1_MESH=iso1_mesh, $          ; isosurface1のメッシュ
  ISO2_MESH=iso2_mesh, $          ; isosurface2のメッシュ
  ISO1_COLOR=iso1_color, $        ; isosurfaceのカラー
  ISO2_COLOR=iso2_color, $        ; isosurfaceのカラー
  ISO1_LEVEL=iso1_level, $        ; isosurfaceの表示レベル[追加]
  ISO2_LEVEL=iso2_level, $        ; isosurfaceの表示レベル[追加]
  COLOR_TABLE=color_table, $      ; color table の番号
  CONT_NLEVELS=cont_nlevels, $    ; contourの NLEVELS
  COLOR_MIN_VAL=color_min_val, $
  COLOR_MAX_VAL=color_max_val, $
  xsize=xsize, $                ; IN: (opt) pixel size of draw window.
  ysize=ysize                   ; IN: (opt) pixel size of draw window.

end