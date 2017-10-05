;+
; FUNCTION:        MAVEN_SPACECRAFT_VERTICES
;
; PURPOSE:         Collection of MAVEN spacecraft/instrument vertices and
;                  rotation matrices for the purpose of plotting a model in
;                  IDL. Vertices are in units of [mm] and in MAVEN_SPACECRAFT
;                  coordinates.   
;
; INPUT:           None.
;
; OUTPUT:          Structure containing vertices and rotation matrices. 
;
; KEYWORDS:        
;   
;     PREC:        Number of points per side.
;
; CREATED BY:      Roberto Livi on 2015-02-23.       
;
; VERSION:
;   $LastChangedBy: rlivi2 $
;   $LastChangedDate: 2015-02-23 13:05:25$
;   $LastChangedRevision: 18258 $
;   $URL svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_gen_snapshot/mvn_sta_3d_snap.pro $
;-


function maven_spacecraft_vertices, prec=prec, $
                                    plot_sc=plot_sc


  if ~keyword_set(prec) then prec=100

  ;;-------------------------------------------------
  ;;Vertices of MAVEN in MAVEN Spacecraft coordinates


  ;;---------------------------
  ;;Instrument and Gimbal location

  ;;Inner Gimbal
  g1_gim_loc=[2589.00,203.50, 2044.00]
  ;;Outer Gimbal
  g2_gim_loc=[2775.00,203.50, 2044.00]
  ;;STATIC
  sta_loc=[2589.0+538.00, 203.50+450.00, 1847.50]
  ;;SWEA
  swe_loc=[-2359.00,   0.00,-1115.00]
  ;;SWIA
  swi_loc=[-1223.00,-1313.00, 1969.00]
  ;;SEP +X/+
  sep_py_loc=[ 1245.00, 1143.00,2080.00]
  ;;SEP +X/-Y
  sep_my_loc=[ 1245.00,-1143.00,2080.00]

  ;;---------------------------
  ;;Main Body
  main_body=[$
  [-1143.00, 1143.00, 1984.00],$
  [ 1143.00, 1143.00, 1984.00],$
  [-1143.00,-1143.00, 1984.00],$
  [ 1143.00,-1143.00, 1984.00],$
  [-1143.00, 1143.00,  340.00],$
  [ 1143.00, 1143.00,  340.00],$
  [-1143.00,-1143.00,  340.00],$
  [ 1143.00,-1143.00,  340.00]]

  main_body_ind=[$
                [0,1,3,2],$       ;+z side 1
                [4,5,7,6],$       ;-z side 2

                [0,2,6,4],$       ;+x side 3
                [1,5,7,3],$       ;-x side 4

                [0,1,5,4],$       ;+y side 3
                [2,6,7,3]]        ;-y side 4

  ;;---------------------------
  ;;Antenna Body
  val1=1000.*cos(45.*!DTOR);sqrt(1000.^2+1000.^2)
  val2= 208.*cos(45.*!DTOR);sqrt(208.^2+208.^2)
  ant_body=[$
  [-1.*val1,    val1, 1984.00],$
  [    val1,    val1, 1984.00],$
  [-1.*val1,-1.*val1, 1984.00],$
  [    val1,-1.*val1, 1984.00],$

  [-1.*val2,    val2, 2957.00],$
  [    val2,    val2, 2957.00],$
  [-1.*val2,-1.*val2, 2957.00],$
  [    val2,-1.*val2, 2957.00]]

  ant_body_ind=main_body_ind


  ;;---------------------------
  ;;+Y Solar Panel
  ;;
  ;;Part 1
  py_solar1=[$
  [-1066.00, 1143.00, 1983.00],$
  [ 1066.00, 1143.00, 1983.00],$
  [-1066.00, 3060.00, 1983.00],$
  [ 1066.00, 3060.00, 1983.00],$
  [-1066.00, 1143.00, 1954.00],$
  [ 1066.00, 1143.00, 1954.00],$
  [-1066.00, 3060.00, 1954.00],$
  [ 1066.00, 3060.00, 1954.00]]

  py_solar1_ind=main_body_ind

  ;;
  ;;Part 2
  py_solar2=[$
  [ -996.00, 3060.00, 1983.00],$
  [  996.00, 3060.00, 1983.00],$
  [ -996.00, 3060.00, 1983.00],$
  [  996.00, 3060.00, 1983.00],$
  [ -996.00, 5657.00, 2663.00],$
  [  996.00, 5657.00, 2663.00],$
  [ -996.00, 5657.00, 2633.00],$
  [  996.00, 5657.00, 2633.00]]

  py_solar2_ind=main_body_ind

  ;;---------------------------
  ;;-Y Solar Panel
  ;;
  ;;Part 1
  my_solar1=[$
  [-1066.00,-1143.00, 1983.00],$
  [ 1066.00,-1143.00, 1983.00],$
  [-1066.00,-3060.00, 1983.00],$
  [ 1066.00,-3060.00, 1983.00],$
  [-1066.00,-1143.00, 1954.00],$
  [ 1066.00,-1143.00, 1954.00],$
  [-1066.00,-3060.00, 1954.00],$
  [ 1066.00,-3060.00, 1954.00]]

  my_solar1_ind=main_body_ind

  ;;
  ;;Part 2
  my_solar2=[$
  [ -996.00,-3060.00, 1983.00],$
  [  996.00,-3060.00, 1983.00],$
  [ -996.00,-3060.00, 1983.00],$
  [  996.00,-3060.00, 1983.00],$
  [ -996.00,-5657.00, 2663.00],$
  [  996.00,-5657.00, 2663.00],$
  [ -996.00,-5657.00, 2633.00],$
  [  996.00,-5657.00, 2633.00]]
  
  my_solar2_ind=py_solar2_ind



  ;;---------------------------
  ;;+Y LPW

  py_lpw=[$
  [-4756.00, 6627.00,-1819.00],$
  [-4756.00, 6623.00,-1819.00],$
  [-1143.00,  204.00,  614.00],$
  [-1143.00,  208.00,  614.00],$
  [-4756.00, 6627.00,-1815.00],$
  [-4756.00, 6623.00,-1815.00],$
  [-1143.00,  204.00,  610.00],$
  [-1143.00,  208.00,  610.00]] 

  py_lpw_ind=main_body_ind





  ;;---------------------------
  ;;-Y LPW
  ;;
  ;;Part 2
  my_lpw=[$
  [-4756.00,-6627.00,-1819.00],$
  [-4756.00,-6623.00,-1819.00],$
  [-1143.00, -204.00,  614.00],$
  [-1143.00, -208.00,  614.00],$
  [-4756.00,-6627.00,-1815.00],$
  [-4756.00,-6623.00,-1815.00],$
  [-1143.00, -204.00,  610.00],$
  [-1143.00, -208.00,  610.00]] 
  
  my_lpw_ind=main_body_ind



  ;;---------------------------
  ;;APP
  app_body=[$
  [ 2503.00,  141.00, 1984.00],$
  [ 1078.00,  141.00, 1984.00],$
  [ 2503.00,  266.00, 1984.00],$
  [ 1078.00,  266.00, 1984.00],$
  [ 2503.00,  141.00, 2103.00],$
  [ 1078.00,  141.00, 2103.00],$
  [ 2503.00,  266.00, 2103.00],$
  [ 1078.00,  266.00, 2103.00]]

  app_body_ind=main_body_ind

  ;;---------------------------
  ;;Gimbal #1
  gi1_body=[$
  [ 2503.00,  123.00, 1938.00],$
  [ 2667.00,  123.00, 1938.00],$
  [ 2503.00,  284.00, 1938.00],$
  [ 2667.00,  284.00, 1938.00],$
  [ 2503.00,  123.00, 2150.00],$
  [ 2667.00,  123.00, 2150.00],$
  [ 2503.00,  284.00, 2150.00],$
  [ 2667.00,  284.00, 2150.00]]

  gi1_body_ind=main_body_ind


  ;;---------------------------
  ;;Gimbal #2
  gi2_body=[$
  [ 2883.00,   60.00, 1882.00],$
  [ 2667.00,   60.00, 1882.00],$
  [ 2883.00,  347.00, 1882.00],$
  [ 2667.00,  347.00, 1882.00],$
  [ 2883.00,   60.00, 2205.00],$
  [ 2667.00,   60.00, 2205.00],$
  [ 2883.00,  347.00, 2205.00],$
  [ 2667.00,  347.00, 2205.00]]

  gi2_body_ind=main_body_ind

  ;;---------------------------
  ;;SWEA Boom
  swe_boom=[$
  [-1000.00,  -66.00,  384.00],$
  [-1100.00,  -66.00,  384.00],$
  [-1000.00,   66.00,  384.00],$
  [-1100.00,   66.00,  384.00],$

  [-2331.00,  -66.00, -973.00],$
  [-2431.00,  -66.00, -973.00],$
  [-2331.00,   66.00, -973.00],$
  [-2431.00,   66.00, -973.00]]

  swe_boom_ind=main_body_ind








  ;;---------------------------------------------------------------
  ;;Rotation Matrix from MAVEN_SPACECRAFT to INSTRUMENT
  ;;
  ;;NOTE:
  ;;Used as follows:
  ;;IDL>to_pos = rotation_matrix # from_pos
  ;;When using the rotation matrix from cspice_pxform we must first
  ;;perform a transpose:
  ;;IDL> cspice_pxform, 'MAVEN_SPACECRAFT','MAVEN_INSTUMENT',et,inst_rot
  ;;IDL> rotation_matrix=transpose(inst_rot)
  ;;IDL> to_pos = rotation_matrix # from_pos



  ;;-----------------------------------------
  ;;SWEA
  ;;1. +140 degrees around Zs/c
  ;;Same as :
  ;;IDL> cspice_pxform, 'MAVEN_SPACECRAFT','MAVEN_SWEA',et,swea_rot
  ;;IDL> swea_rot=transpose(swea_rot)
  th=140.D*!DTOR
  swea_rot=[$
           [cos(th), -1.*sin(th),  0.],$
           [sin(th),     cos(th),  0.],$
           [     0.,          0.,  1.]]
  
  ;;-----------------------------------------
  ;;SWIA
  ;;1. +90 degrees around Xs/c
  ;;2. +90 degrees around Zs/c
  ;;Same as :
  ;;IDL> cspice_pxform, 'MAVEN_SPACECRAFT','MAVEN_SWIA',et,swia_rot
  ;;IDL> swia_rot=transpose(swia_rot)
  ;;From cspice_pxform
  ;swia_rot=transpose([$
  ;         [  0.D,   0.D,   1.D],$
  ;         [ -1.D,   0.D,   0.D],$
  ;         [  0.D,  -1.D,   0.D]])
  th=90.D*!DTOR
  swia_rot1=[$
            [        1.D,         0.D,         0.D],$
            [        0.D,     cos(th), -1.*sin(th)],$
            [        0.D,     sin(th),     cos(th)]]
  swia_rot2=[$
            [    cos(th), -1.*sin(th),         0.D],$
            [    sin(th),     cos(th),         0.D],$
            [        0.D,         0.D,         1.D]]
  swia_rot=swia_rot2 # swia_rot1




  ;;-----------------------------------------
  ;;SEP1
  ;;From cspice_pxform
  sep1_rot=transpose([$   
           [0.D,     -0.70710678,      0.70710678],$
           [1.D,             0.D,             0.D],$
           [0.D,      0.70710678,      0.70710678]])


  ;;-----------------------------------------
  ;;SEP2
  ;;From cspice_pxform
  sep2_rot=transpose([$
           [0.D,      0.70710678,      0.70710678],$
           [1.D,             0.D,             0.D],$
           [0.D,     -0.70710678,      0.70710678]])


  rot_matrix_name=['SWEA','SWIA','SEP1','SEP2']
  rot_matrix=[[[swea_rot]],$
              [[swia_rot]],$
              [[sep1_rot]],$
              [[sep2_rot]]]






         
  ;;---------------------------
  ;;Names
  names=['main_body_ind',$
         'ant_body_ind',$
         'py_solar1_ind',$
         'py_solar2_ind',$
         'my_solar1_ind',$
         'my_solar2_ind',$
         'py_lpw_ind',$
         'my_lpw_ind',$
         'app_body_ind',$
         'gi1_body_ind',$
         'gi2_body_ind',$
         'swe_boom_ind']


  ;;---------------------------
  ;;Index
  index=[[main_body_ind],$
         [ant_body_ind],$
         [py_solar1_ind],$
         [py_solar2_ind],$
         [my_solar1_ind],$
         [my_solar2_ind],$
         [py_lpw_ind],$
         [my_lpw_ind],$
         [app_body_ind],$
         [gi1_body_ind],$
         [gi2_body_ind],$
         [swe_boom_ind]]

  ;;array=[4, 6, #-of-object]
  n1=4
  n2=6
  n3=n_elements(index)/n1/n2
  index=reform(index, n1, n2, n3)


  ;;---------------------------
  ;;Vertex  
  vertex=[[[main_body],$
           [ant_body],$
           [py_solar1],$
           [py_solar2],$
           [my_solar1],$
           [my_solar2],$
           [py_lpw],$
           [my_lpw],$
           [app_body],$
           [gi1_body],$
           [gi2_body],$
           [swe_boom]]]

  ;;array=[3, 8, #-of-objects]
  nn1=3
  nn2=8
  nn3=n_elements(vertex)/nn1/nn2
  vertex=reform(vertex, nn1, nn2, nn3)



  ;;------------------------------------
  ;;PLOT TESTING
  if keyword_set(plot_sc) then begin
     ;;Cycle through all n3 objects
     x1=[-8000,8000]
     y1=[-8000,8000]
     pos1=[0.1,0.6,0.9,0.9]
     pos2=[0.1,0.3,0.9,0.6]
     pos3=[0.1,0.0,0.9,0.3]
     window, 1, xsize=600, ysize=900
     for iobj=0, nn3-1 do begin
        ;;-----------------------------
        ;; Cycle through all 8 vertices.
        for i=0, n2-1 do begin           
           box=vertex[*,*,iobj]
           ind=index[*,*,iobj]           
           indd=[ind[*,i],ind[0,i]]
           plot, box[0,indd],box[1,indd],$
                 /noerase,$
                 xrange=x1,$
                 yrange=y1,$
                 xstyle=1,$
                 ystyle=1,$
                 position=pos1
           plot, box[1,indd],box[2,indd],$
                 /noerase,$
                 xrange=x1,$
                 yrange=y1,$
                 xstyle=1,$
                 ystyle=1,$
                 position=pos2
           plot, box[0,indd],box[2,indd],$
                 /noerase,$
                 xrange=x1,$
                 yrange=y1,$
                 xstyle=1,$
                 ystyle=1,$
                 position=pos3
        endfor
        ;; ---- Step 1: Create 1x1 surface filled randomly
        xx1 = randomu(seed,100,100)
        ;; ---- Step 2:

     endfor
  endif


  ;;-----------------------------------
  ;;Create XYZ coordinates for plotting
  xx=fltarr(nn3,5.*n2)
  yy=fltarr(nn3,5.*n2)
  zz=fltarr(nn3,5.*n2)
  ;;Cycle through all n3 objects
  for iobj=0, nn3-1 do begin
     ;;Cycle through all 8 vertices.
     ll=indgen(5)
     for i=0, n2-1 do begin           
        box=vertex[*,*,iobj]
        ind=index[*,*,iobj]           
        indd=[ind[*,i],ind[0,i]]
        ;;Generate PREC number of points between two vertices.
        ;;Repeat for all indices.
        xx[iobj,ll]=reform(box[0,indd])
        yy[iobj,ll]=reform(box[1,indd])
        zz[iobj,ll]=reform(box[2,indd])
        ll=ll+5
     endfor
  endfor
  


  ;;---------------------------------------------------
  ;;Expand using 'prec'
  ;nn=5.*n2
  ;xx_new=fltarr(nn3,nn*prec-prec)
  ;yy_new=fltarr(nn3,nn*prec-prec)
  ;zz_new=fltarr(nn3,nn*prec-prec)
  ;for iobj=0, nn3-1 do begin    
  ;   xx_new[iobj,*]=interpol(xx[iobj,*],findgen(nn),findgen(nn*prec-prec)/prec)
  ;   yy_new[iobj,*]=interpol(yy[iobj,*],findgen(nn),findgen(nn*prec-prec)/prec)
  ;   zz_new[iobj,*]=interpol(zz[iobj,*],findgen(nn),findgen(nn*prec-prec)/prec)
  ;endfor

  ;;---------------------------------------------------
  ;;Expand using 'prec'
  nn=5.*n2
  xx_new=fltarr(nn3,nn*prec)
  yy_new=fltarr(nn3,nn*prec)
  zz_new=fltarr(nn3,nn*prec)
  for iobj=0, nn3-1 do begin    
     xx_new[iobj,*]=interpol(xx[iobj,*],findgen(nn),findgen(nn*prec)/prec)
     yy_new[iobj,*]=interpol(yy[iobj,*],findgen(nn),findgen(nn*prec)/prec)
     zz_new[iobj,*]=interpol(zz[iobj,*],findgen(nn),findgen(nn*prec)/prec)
  endfor





  return, {vertex:vertex, $
           x_sc:xx_new,$
           y_sc:yy_new,$
           z_sc:zz_new,$
           index:index, $
           names:names, $
           rot_matrix:rot_matrix,$
           rot_matrix_name:rot_matrix_name}
     
end




