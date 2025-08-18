;+
; FUNCTION:        SPP_SPACECRAFT_VERTICES
;
; PURPOSE:         Collection of Parker Solar Probe spacecraft/instrument vertices and
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
;     PLOT_SC1:     Plot all Parker Solar Probe vertices and SWEAP instrument locations.
;
; CREATED BY:      Roberto Livi on 2020-04-23
;
; VERSION:
;   $LastChangedBy:
;   $LastChangedDate:
;   $LastChangedRevision:
;   $URL 
;-


PRO spp_spacecraft_vertices_mollweide, x, y, lambda, phi, r, label

   Lambda = LAMBDA * !pi / 180.
   Phi    = PHI * !pi / 180.   
   t = Phi
   dif = 1                      
   ;;WHILE dif GT 1e-5 DO BEGIN
   ;;   t = t - (2 * t + sin(2 * t) - !pi * sin(Phi)) / (2 + 2 * cos(2 * t)) 
   ;;   dif = max(abs(2 * t + sin(2 * t) - !pi * sin(Phi)))
   ;;ENDWHILE

   ;; Replace While loop with 5 iterations
   t = t - (2 * t + sin(2 * t) - !pi * sin(Phi)) / (2 + 2 * cos(2 * t))
   t = t - (2 * t + sin(2 * t) - !pi * sin(Phi)) / (2 + 2 * cos(2 * t))
   t = t - (2 * t + sin(2 * t) - !pi * sin(Phi)) / (2 + 2 * cos(2 * t))
   t = t - (2 * t + sin(2 * t) - !pi * sin(Phi)) / (2 + 2 * cos(2 * t))
   t = t - (2 * t + sin(2 * t) - !pi * sin(Phi)) / (2 + 2 * cos(2 * t))
   
   x = sqrt(2) * R / !pi * 2 * Lambda * cos(t) 
   y = sqrt(2) * R * sin(t)                    

END

; flap_sp - Flap Angle (degrees) for solar panels
; fthr_sp - Feather Angle (degrees) for solar panels
PRO spp_spacecraft_vertices, plot_sc1=plot_sc1, plot_sc2=plot_sc2, plot_sc3=plot_sc3, $
                             spi=spi, spa=spa, spb=spb, moll=moll, vertex=vertex,flap_sp=flap_sp,fthr_sp=fthr_sp


   ;; Initiate Common Block
   COMMON spp_vertex, inst

   ;; SPAN-Ai
   spi_loc = [ 661.0935, -224.7284,  76.9131]
   ;; SPAN-Ae
   spa_loc = [ 562.7270, -494.9875,  76.9080]
   ;; SPAN-B
   spb_loc = [-654.87378, 122.6182, 453.8726]
   ;; SPC
   spc_loc = [-1296.2722,   0.0000,2970.9419]

   ;; SPAN-Ai Rotation Matrix

   ;; Rotation angle
   rot_th = 20.                 
   rotr = [[1,            0,           0.],$
           [0, cosd(rot_th), sind(rot_th)],$
           [0,-sind(rot_th), cosd(rot_th)] ]

   ;; Effective relabelling of axes   
   rel = [[ 0,-1, 0],$
          [ 0, 0,-1],$
          [ 1, 0, 0]]                                        

   ;; And a 180 degree around X
   rel180 = [[1,0,0],$
             [0,-1,0],$
             [0,0,-1]]
   
   ;; Transformation matrix from ion instrument coordinates TO spacecraft   
   rotmat_spi_sc = rel ## rotr

   rotmat_spi_sc2 = rel ## rotr ## rel180

   ;; Transformation matrix from SC to ion instrument coordinates
   rotmat_sc_spi = transpose(rotmat_spi_sc)
   rotmat_sc_spi2 = transpose(rotmat_spi_sc2)
   
   ;; Check This!!!
   ;;spi_to_spi2 = [[-1d,0,0],[0,-1,0],[0,0,1]]              
   ;;rotmat_sc_spi = spi_to_spi2 ## rotmat_sc_spi

   ;;rotmat_inst2_sc = rotmat_sc_inst ## transpose(inst_to_inst2)
   ;;rotmat_sc_sc2 = [[0,1.,0],[0,0,-1],[-1,0,0]]
   ;;rotmat_inst_sc2= rotmat_sc_sc2 ## rotmat_inst_sc
   


   ;; SPAN-Ae Rotation Matrix
   xasc = [0,0,1]
   yasc = [1,-0.37,0]
   yasc = yasc/norm(yasc)
   zasc = crossp(xasc,yasc)
   rotmat_sc_spa = [[xasc],[yasc],[zasc]]
   ;;quaternion = [0.40403933, 0.58030356, 0.40403933, 0.58030356d]

   ;; SPAN-B Rotation Matrix
   xbsc = [-0.866,0,0.5]
   xbsc = xbsc/norm(xbsc)
   ybsc = [0,1,0]
   zbsc = crossp(xbsc,ybsc)
   rotmat_sc_spb = [[xbsc],[ybsc],[zbsc]]
   ;;quaternion = [0.25882519, 0, 0.96592418, 0d]

   nan = !VALUES.F_NAN

   ;; FIELDS Whips

   ;; FIELD Vertex Index
   fld_ind = [$
             0,4,5,1,0,$ ;; Side 1
             0,2,3,1,0,$ ;; TOP
             2,6,7,3,2,$ ;; Side 3
             4,6,7,5,4,$ ;; BOTTOM
             3,6,7,4,3,$ ;; Side 5
             4,7,6,3,4]      ;; Side 6
             
              
   ;; V1
   fld_v1 = [$

            [2009.28, 2870.67, 2821.54],$
            [2011.86, 2868.86, 2821.54],$
            [ 724.07, 1041.85, 2821.54],$
            [ 726.07, 1039.85, 2821.54],$            

            [2009.28, 2870.67, 2819.54],$
            [2011.86, 2868.86, 2819.54],$
            [ 724.07, 1041.85, 2819.54],$
            [ 726.07, 1039.85, 2819.54]]            

   fld_v1 = transpose(fld_v1)
   
   ;; V2
   fld_v2 = [$

            [-1994.48, -2844.60, 2825.24],$
            [-1992.08, -2846.78, 2825.24],$
            [ -706.90, -1013.65, 2825.25],$
            [ -704.90, -1015.65, 2825.25],$

            [-1994.48, -2844.60, 2825.24],$
            [-1992.08, -2846.78, 2825.24],$
            [ -706.90, -1013.65, 2825.25],$
            [ -704.90, -1015.65, 2825.25]]


   fld_v2 = transpose(fld_v2)
   
   ;; V3
   fld_v3 = [$
            [-2625.42, 2204.98, 2821.17],$
            [-2627.46, 2202.55, 2821.17],$
            [ -910.00,  770.97, 2821.12],$
            [ -908.00,  768.97, 2821.12],$

            [-2625.42, 2204.98, 2819.17],$
            [-2627.46, 2202.55, 2819.17],$
            [ -910.00,  770.97, 2819.12],$
            [ -908.00,  768.97, 2819.12]]
            
   
   fld_v3 = transpose(fld_v3)
            
   ;; V4
   ;; Three main points
   ;; [1121.83, -939.258, 2825.40]
   ;; [2653.95, -2224.81, 2825.40],$
   ;; [2651.90, -2227.24, 2825.39]$

   fld_v4 = [$

            [ 942.00,  -785.02, 2826.40],$
            [ 944.00,  -787.02, 2826.40],$
            [2653.95, -2224.81, 2826.40],$
            [2651.90, -2227.24, 2826.40],$
            [ 942.00,  -785.02, 2824.40],$
            [ 944.00,  -787.02, 2824.40],$
            [2653.95, -2224.81, 2824.40],$
            [2651.90, -2227.24, 2824.40]$
            
            ]
   
   fld_v4 = transpose(fld_v4)
   
   ;; Spacecraft Bus [mm]
   spp_bus = [$
             ;; Bottom 
             [ 533.4,   0.0000,0.0],$
             [ 266.7,-461.9379,0.0],$
             [-266.7,-461.9379,0.0],$
             [-533.4,   0.0000,0.0],$
             [-266.7, 461.9379,0.0],$
             [ 266.7, 461.9379,0.0],$
             [ 533.4,   0.0000,0.0],$
             ;; Top
             [ 533.4,   0.0000,1563.3701],$
             [ 266.7,-461.9379,1563.3701],$
             [-266.7,-461.9379,1563.3701],$
             [-533.4,   0.0000,1563.3701],$
             [-266.7, 461.9379,1563.3701],$
             [ 266.7, 461.9379,1563.3701],$
             [ 533.4,   0.0000,1563.3701]]

   spp_bus = transpose(spp_bus)
   
   spp_bus_ind = [0,7,8,1,0, $    ;; Side 1
                  1,8,9,2,1, $    ;; Side 2
                  2,9,10,3,2, $   ;; Side 3
                  3,10,11,4,3, $  ;; Side 4
                  4,11,12,5,4, $  ;; Side 5
                  5,12,13,6,5]    ;; Side 6                  
   
   ;; Solar Panel 1
   spp_solar_panel1 = [[-345.00, 2374.03, 1562.10],$
                       [ 345.00, 2374.03, 1562.10],$
                       [ 345.00, 1250.80, 1562.10],$
                       [-345.00, 1250.80, 1562.10],$

                       [-345.00, 2374.03, 1543.10],$
                       [ 345.00, 2374.03, 1543.10],$
                       [ 345.00, 1250.80, 1543.10],$
                       [-345.00, 1250.80, 1543.10]]

   ;; Solar Panel 1 Structure
   spp_solar_panel1_str = [[-31.00, 1264.60, 1543.10],$
                           [ 31.00, 1264.60, 1543.10],$
                           [ 31.00,  495.30, 1543.10],$
                           [-31.00,  495.30, 1543.10],$
                           
                           [-31.00, 1264.60, 1524.10],$
                           [ 31.00, 1264.60, 1524.10],$
                           [ 31.00,  495.30, 1524.10],$
                           [-31.00,  495.30, 1524.10]]                                                      

   ;; Solar Panel 2
   spp_solar_panel2 = [[ -345.00, -1250.80, 1562.10],$
                       [  345.00, -1250.80, 1562.10],$
                       [  345.00, -2374.03, 1562.10],$
                       [ -345.00, -2374.03, 1562.10],$

                       [ -345.00, -1250.80, 1543.10],$
                       [  345.00, -1250.80, 1543.10],$
                       [  345.00, -2374.03, 1543.10],$
                       [ -345.00, -2374.03, 1543.10]]

   ;; Solar Panel 2 Structure
   spp_solar_panel2_str = [[-31.00,-1264.60, 1543.10],$
                           [ 31.00,-1264.60, 1543.10],$
                           [ 31.00, -495.30, 1543.10],$
                           [-31.00, -495.30, 1543.10],$
                           
                           [-31.00,-1264.60, 1524.10],$
                           [ 31.00,-1264.60, 1524.10],$
                           [ 31.00, -495.30, 1524.10],$
                           [-31.00, -495.30, 1524.10]]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Rotate Solar Panels if feather angle for solar panels is set
  if isa(fthr_sp) then begin
    ; Check for separate flap angles
    fthr_sp1 = fthr_sp[0]
    if n_elements(fthr_sp) gt 1 then fthr_sp2 = fthr_sp[1] else fthr_sp2 = fthr_sp[0]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SOLAR PANEL 1
    ; Set origin points for rotation
    sp1_len       = (find_dim(spp_solar_panel1))[1]
    spstr1_len    = (find_dim(spp_solar_panel1_str))[1]
    sp1_origin    = ([0.00, 495.30, 1533.60] # (intarr(sp1_len)+1))
    spstr1_origin = ([0.00, 495.30, 1533.60] # (intarr(spstr1_len)+1))
    ; Change coordinate system
    new_sp1    =  spp_solar_panel1 - sp1_origin
    new_spstr1 =  spp_solar_panel1_str - spstr1_origin
    ; Rotate CCW around x axis
    ang1      = (fthr_sp1)*!DPI/180.0
    fthr_rot1 = [[ cos(ang1), 0.0, sin(ang1)],$
                 [       0.0, 1.0,       0.0],$
                 [-sin(ang1), 0.0, cos(ang1)] ]
    ; Perform operation and move to original coordinate system
    spp_solar_panel1     = (fthr_rot1 # new_sp1) + sp1_origin
    spp_solar_panel1_str = (fthr_rot1 # new_spstr1) + spstr1_origin
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SOLAR PANEL 2
    ; Set origin points for rotation
    sp2_len       = (find_dim(spp_solar_panel2))[1]
    spstr2_len    = (find_dim(spp_solar_panel2_str))[1]
    sp2_origin    = ([0.00, -495.30, 1533.60] # (intarr(sp2_len)+1))
    spstr2_origin = ([0.00, -495.30, 1533.60] # (intarr(spstr2_len)+1))
    ; Change coordinate system
    new_sp2    =  spp_solar_panel2 - sp2_origin
    new_spstr2 =  spp_solar_panel2_str - spstr2_origin
    ; Rotate CW around x axis (need to flip angle for correct direction)
    ang2      = (-fthr_sp2)*!DPI/180.0
    fthr_rot2 = [[ cos(ang2), 0.0, sin(ang2)],$
                 [       0.0, 1.0,       0.0],$
                 [-sin(ang2), 0.0, cos(ang2)] ]
    ; Perform operation and move to original coordinate system
    spp_solar_panel2     = (fthr_rot2 # new_sp2) + sp2_origin
    spp_solar_panel2_str = (fthr_rot2 # new_spstr2) + spstr2_origin
  endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Rotate Solar Panels if flap angle for solar panels is set
  if isa(flap_sp) then begin
   ; Check for separate flap angles
   flap_sp1 = flap_sp[0]
    if n_elements(flap_sp) gt 1 then flap_sp2 = flap_sp[1] else flap_sp2 = flap_sp[0]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SOLAR PANEL 1
    ; Set origin points for rotation
    sp1_len       = (find_dim(spp_solar_panel1))[1]
    spstr1_len    = (find_dim(spp_solar_panel1_str))[1]
    sp1_origin    = ([0.00, 495.30, 1533.60] # (intarr(sp1_len)+1))
    spstr1_origin = ([0.00, 495.30, 1533.60] # (intarr(spstr1_len)+1))
    ; Change coordinate system
    new_sp1    =  spp_solar_panel1 - sp1_origin 
    new_spstr1 =  spp_solar_panel1_str - spstr1_origin
    ; Rotate CCW around x axis 
    ang1      = (flap_sp1)*!DPI/180.0
    flap_rot1 = [[1.0,           0.0,           0.0],$
                [0.0, cos(ang1),-sin(ang1)],$
                [0.0, sin(ang1), cos(ang1)] ]
    ; Perform operation and move to original coordinate system
    spp_solar_panel1     = (flap_rot1 # new_sp1) + sp1_origin
    spp_solar_panel1_str = (flap_rot1 # new_spstr1) + spstr1_origin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SOLAR PANEL 2
    ; Set origin points for rotation
    sp2_len       = (find_dim(spp_solar_panel2))[1]
    spstr2_len    = (find_dim(spp_solar_panel2_str))[1]
    sp2_origin    = ([0.00, -495.30, 1533.60] # (intarr(sp2_len)+1))
    spstr2_origin = ([0.00, -495.30, 1533.60] # (intarr(spstr2_len)+1))
    ; Change coordinate system
    new_sp2    =  spp_solar_panel2 - sp2_origin 
    new_spstr2 =  spp_solar_panel2_str - spstr2_origin
    ; Rotate CW around x axis (need to flip angle for correct direction)
    ang2      = (-flap_sp2)*!DPI/180.0
    flap_rot2 = [[1.0,           0.0,           0.0],$
                [0.0, cos(ang2),-sin(ang2)],$
                [0.0, sin(ang2), cos(ang2)] ]
    ; Perform operation and move to original coordinate system
    spp_solar_panel2     = (flap_rot2 # new_sp2) + sp2_origin
    spp_solar_panel2_str = (flap_rot2 # new_spstr2) + spstr2_origin 
  endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   sol_ind = [$
             0,1,2,3,0,$  ;; TOP
             4,5,6,7,4,$  ;; BOTTOM
             0,4,5,1,0,$  ;; SIDE1
             3,2,6,7,3,2]     ;; SIDE2

   nan = reform(replicate(!VALUES.F_NAN,3),3,1)
   spp_solar = [[spp_solar_panel1[*,sol_ind]],[nan],$
                [spp_solar_panel1_str[*,sol_ind]],[nan],$
                [spp_solar_panel2[*,sol_ind]],[nan],$
                [spp_solar_panel2_str[*,sol_ind]],[nan]]

   spp_solar = transpose(spp_solar)

   
   ;; SPAN-A
   spana = [[533.00,-265.50, 146.75],$
            [478.42,-415.91, 146.75],$
            [533.00,-265.50,   7.06],$
            [478.42,-415.91,   7.06]]
   
   
   ;; Radiators
   
   ;;Anchor points on TPS
   rp1 = [ 920.7499,   0.0000,2932.0576]
   rp2 = [ 460.3750,-797.3928,2932.0576]
   rp3 = [-460.3750,-797.3928,2932.0576]
   rp4 = [-920.7499,   0.0000,2932.0576]
   rp5 = [-460.3749, 797.3929,2932.0576]
   rp6 = [ 460.3750, 797.3928,2932.0576]   
   rp7 = [ 920.7499,   0.0000,2932.0576]

   rda = [$
         [ 533.4,   0.0000,1563.3701],$
         [ 266.7,-461.9379,1563.3701],$
         [-266.7,-461.9379,1563.3701],$
         [-533.4,   0.0000,1563.3701],$
         [-266.7, 461.9379,1563.3701],$
         [ 266.7, 461.9379,1563.3701],$
         [ 533.4,   0.0000,1563.3701],$
         [rp1],[rp2],[rp3],[rp4],[rp5],[rp6],[rp1]]

   rda = transpose(rda)

   ;; Same number of sides as the bus
   rda_ind = spp_bus_ind

   ;; Thermal Protection Shield [mm]
   tps_xx = [ -669.57037, -923.45317, -1091.1123, -1097.7762, -1104.1107, -1110.1138,$
              -1115.7837, -1121.1187, -1126.1172, -1130.7776, -1135.0985, -1139.0785, -1142.7166, -1146.0115,$
              -1148.9623, -1151.5681, -1153.8280, -1155.7414, -1157.3077, -1158.5265, -1159.3973, -1159.9198,$
              -1160.0941, -1159.9198, -1159.3973, -1158.5265, -1157.3077, -1155.7414, -1153.8280, -1151.5681,$
              -1148.9623, -1146.0115, -1142.7166, -1139.0785, -1135.0985, -1130.7776, -1126.1172, -1121.1187,$
              -1115.7837, -1110.1138, -1104.1107, -1097.7762, -1091.1122,  -923.45297, -669.57037, $
              678.73065,  921.49164,  1089.1516,  $
              1096.0049,  1102.5194,  1108.6932,  1114.5243,  1120.0109,  1125.1515,  1129.9443,  1134.3880,$
              1138.4812,  1142.2227,  1145.6113,  1148.6460,  1151.3258,  1153.6499,  1155.6177,  1157.2286,$
              1158.4820,  1159.3775,  1159.9150,  1160.0941,  1159.9150,  1159.3775,  1158.4820,  1157.2286,$
              1155.6177,  1153.6499,  1151.3258,  1148.6460,  1145.6113,  1142.2227,  1138.4812,  1134.3880,$
              1129.9443,  1125.1515,  1120.0109,  1114.5243,  1108.6932,  1102.5194,  1096.0049,  1089.1515,$
              921.49164,  678.73065,  -669.57037]
   
   tps_yy = [   1105.7379, 851.85512, 391.21539, 372.39691, 353.46507, 334.42557,$
                315.28419, 296.04678, 276.71919, 257.30731, 237.81705, 218.25434, 198.62516, 178.93547,$
                159.19128, 139.39859, 119.56344, 99.691876, 79.789942, 59.863702, 39.919228, 19.962593,$
                  -0.0001,-19.962837,-39.919472,-59.863946,-79.790186,-99.692120,-119.56369,-139.39884,$
               -159.19152,-178.93571,-198.62540,-218.25459,-237.81729,-257.30755,-276.71943,-296.04703,$
               -315.28444,-334.42581,-353.46532,-372.39715,-391.21555, -851.85522,-1105.7379,$
                -1105.7379,-862.97693,-402.33521,$
                -382.98196,-363.51199,-343.93130,-324.24583,-304.46160,-284.58463,-264.62097,-244.57670,$
                -224.45793,-204.27079,-184.02143,-163.71601,-143.36072,-122.96177,-102.52535,-82.057711,$
                -61.565073,-41.053681,-20.529784,   0.00037, 20.530517, 41.054414, 61.565805, 82.058443,$
                102.52609, 122.96250, 143.36145, 163.71674, 184.02216, 204.27152, 224.45866, 244.57743,$
                264.62170, 284.58536, 304.46233, 324.24656, 343.93203, 363.51273, 382.98270, 402.33600,$
                862.97772, 1105.7379, 1105.7379]
   
   tps_zz_bot = replicate(2935.6306,n_elements(tps_xx))
   tps_zz_top = replicate(3049.9307,n_elements(tps_xx))

   ;; stitch stitch stitch
   tps_bot = [[tps_xx],[tps_yy],[tps_zz_bot]]
   tps_top = [[tps_xx],[tps_yy],[tps_zz_top]]
   ss = size(tps_bot)
   tps=reform(transpose([[[tps_top]],[[tps_bot]]],[2,0,1]),ss[1]*2,ss[2])
   tps_ind = ([0,1,3,2,0] ## replicate(1.,ss[1]-1)) + rebin(indgen(ss[1]-1)*2, ss[1]-1, 5)
   tps_ind = reform(transpose(tps_ind),(ss[1]-1)*5)

   
   
   ;;##############
   ;;# TEST PLOTS #
   ;;##############

   ;; Combine all veritces
   nn = reform(replicate(!VALUES.F_NAN,3),1,3)
   arr1 = tps[tps_ind,*]
   arr2 = rda[rda_ind,*]
   arr3 = spp_bus[spp_bus_ind,*]
   ;;arr4 = spp_flg[flg_ind,*]
   arr5 = fld_v1[fld_ind,*]
   arr6 = fld_v2[fld_ind,*]
   arr7 = fld_v3[fld_ind,*]
   arr8 = fld_v4[fld_ind,*]
   arr9 = spp_solar
   vertex = [nn,arr1,nn,arr2,nn,arr3,nn,arr5,nn,arr6,nn,arr7,nn,arr8,nn,arr9,nn]

   ;; Higher Res
   res = 40.
   nnn = n_elements(vertex[*,0]);;-1
   vertex_xx = interpol(vertex[0:nnn-1,0],indgen(nnn),indgen(nnn*res)/res)
   vertex_yy = interpol(vertex[0:nnn-1,1],indgen(nnn),indgen(nnn*res)/res)
   vertex_zz = interpol(vertex[0:nnn-1,2],indgen(nnn),indgen(nnn*res)/res)
   
   vertex = [[vertex_xx],[vertex_yy],[vertex_zz]]

   IF keyword_set(moll) THEN BEGIN

      plot, [0,0],[0,0], /nodata, xrange=[-180,180], yrange=[-90,90],xstyle=5,ystyle=5,$
            xtitle='Phi', ytitle='Theta', xtickn=['100','0','-100']

      FOR i=0., 361., 45. DO BEGIN
         lambda = replicate(i,360)-180.
         phi = findgen(360)/2.-90.
         r = 1
         spp_spacecraft_vertices_mollweide, x, y, lambda, phi, r
         oplot, x*!RADEG, y*!RADEG,linestyle=1;;, psym=1, 
      ENDFOR

      FOR i=0., 361., 45. DO BEGIN
         phi = replicate(i,360)/2.-90.
         lambda = findgen(360)-180.      
         r = 1
         ;;plot, [0,0],[0,0], /nodata, xrange=[-180,180], yrange=[-90,90],xstyle=3,ystyle=3         
         spp_spacecraft_vertices_mollweide, x, y, lambda, phi, r
         oplot, x*!RADEG, y*!RADEG,linestyle=1;;, psym=1, 
      ENDFOR      

      ;; Add labels
      xyouts,   -175,    0, 'Theta - Delfectors',orientation=90, size=2,charthick=2,align=0.5
      xyouts,      0,  -93, 'Phi - Anodes', size=2,charthick=2,align=0.5
      
   ENDIF
   
   IF keyword_set(plot_sc1) THEN BEGIN
      
      ;;window, 0, xsize=900,ysize=900
      !P.Multi = [0,3]

      ;; X - Y - Z
      
      ;; XX - YY
      plot, vertex[*,0], vertex[*,1],/iso,chars=2,chart=2, xtitle='SC-X', ytitle='SC-Y'
      oplot, replicate(spa_loc[0],2),replicate(spa_loc[1],2), psym=2,color=250
      oplot, replicate(spb_loc[0],2),replicate(spb_loc[1],2), psym=2,color=250
      oplot, replicate(spc_loc[0],2),replicate(spc_loc[1],2), psym=4,color=50
      oplot, replicate(spi_loc[0],2),replicate(spi_loc[1],2), psym=5,color=80

      ;; XX - ZZ
      plot, vertex[*,0], vertex[*,2],/iso,chars=2,chart=2, xtitle='SC-X', ytitle='SC-Z'
      oplot, replicate(spa_loc[0],2),replicate(spa_loc[2],2), psym=2,color=250
      oplot, replicate(spb_loc[0],2),replicate(spb_loc[2],2), psym=2,color=250
      oplot, replicate(spc_loc[0],2),replicate(spc_loc[2],2), psym=4,color=50
      oplot, replicate(spi_loc[0],2),replicate(spi_loc[2],2), psym=5,color=80

      ;; YY - ZZ
      plot, vertex[*,1], vertex[*,2],/iso,chars=2,chart=2, xtitle='SC-Y', ytitle='SC-Z'
      oplot, replicate(spa_loc[1],2),replicate(spa_loc[2],2), psym=2,color=250
      oplot, replicate(spb_loc[1],2),replicate(spb_loc[2],2), psym=2,color=250
      oplot, replicate(spc_loc[1],2),replicate(spc_loc[2],2), psym=4,color=50
      oplot, replicate(spi_loc[1],2),replicate(spi_loc[2],2), psym=5,color=80

      !P.MULTI = 0

   ENDIF

   IF keyword_set(plot_sc2) THEN BEGIN
      
      ;; Combine Vertex and inst locs
      nn_vert = n_elements(vertex[*,0])
      vert2 = [vertex,$
               reform(spa_loc,1,3),$
               reform(spb_loc,1,3),$
               reform(spc_loc,1,3),$
               reform(spi_loc,1,3)]                

      ;; Cycle through focus on a sphere radius 6000
      x1   = [-8000,8000]
      y1   = [-8000,8000]
      x1   = [-800,800]
      y1   = [-800,800]

      FOR jj=3500, 3800, 50 DO BEGIN 
         FOR ith=0., 2.*!PI, 0.05 DO BEGIN

            plot, [0,1],[0,1],/nodata, /iso,xrange = x1,$
                  yrange = y1,xstyle = 3,ystyle = 3
            
            focus_position = [0.00, 0.00, 1000.00] + [0,0,jj]

            box   = transpose(vert2)
            indd  = indgen(nn_vert)
      
            tmp1 = box[1,*]*cos(ith)-box[2,*]*sin(ith)
            tmp2 = box[1,*]*sin(ith)+box[2,*]*cos(ith)

            box[1,*] = tmp1
            box[2,*] = tmp2

            xx = box[0,*]-focus_position[0]
            yy = box[1,*]-focus_position[1]
            zz = box[2,*]-focus_position[2]
            rr = sqrt(reform(xx^2+yy^2+zz^2))
            theta = acos(reform(zz)/rr)
            phi   = atan(yy,xx)
            new_r = zz/cos(theta) / 5
            new_xx = new_r * sin(theta) * cos(phi)
            new_yy = new_r * sin(theta) * sin(phi)

            ;; Spacecraft
            oplot, new_xx[indd],new_yy[indd]

            ;; SPAN-Ai
            spi_xx = replicate(new_xx[nn_vert+3],2)
            spi_yy = replicate(new_yy[nn_vert+3],2)
            oplot, spi_xx, spi_yy, color=70, psym=1

            ;; SPAN-Ae
            spa_xx = replicate(new_xx[nn_vert+0],2)
            spa_yy = replicate(new_yy[nn_vert+0],2)
            oplot, spa_xx, spa_yy, color=250, psym=2

            ;; SPAN-B
            spb_xx = replicate(new_xx[nn_vert+1],2)
            spb_yy = replicate(new_yy[nn_vert+1],2)
            oplot, spb_xx, spb_yy, color=250, psym=2

            ;; SPC
            spc_xx = replicate(new_xx[nn_vert+2],2)
            spc_yy = replicate(new_yy[nn_vert+2],2)
            oplot, spc_xx, spc_yy, color=40, psym=5
            
            wait, 0.05

         ENDFOR
      ENDFOR
   ENDIF


   IF keyword_set(plot_sc3) THEN BEGIN

      ;;!P.MULTI = [0,0,3]

      ;; Temp
      vtmp = vertex
      vtmpi = vertex
      vtmpa = vertex
      vtmpb = vertex
      

      ;; SPAN-Ai
      IF keyword_set(spi) THEN BEGIN 
         
         ;; Shift center to SPAN-Ai
         vtmpi[*,0] = vtmp[*,0] - spi_loc[0]
         vtmpi[*,1] = vtmp[*,1] - spi_loc[1]
         vtmpi[*,2] = vtmp[*,2] - spi_loc[2]

         ;;SPAN-I rotation
         nvtmp = vtmpi # rotmat_sc_spi2
         ;;nvtmp = vtmpi # rotmat_sc_spi

         ;; Decompose
         xx = nvtmp[*,0]
         yy = nvtmp[*,1]
         zz = nvtmp[*,2]
         
         po = xx*xx + yy*yy
         rr = sqrt(reform(po+zz*zz))
         phi   = atan(yy,xx)        * !RADEG      
         theta = atan(zz/sqrt(po))  * !RADEG

         IF keyword_set(moll) THEN BEGIN

            ;; Spacecraft
            rr = 1
            phi = -1.*phi
            spp_spacecraft_vertices_mollweide, x, y, phi, theta, rr
            ;;polyfill, x*!RADEG, y*!RADEG, color=250
            oplot, x*!RADEG, y*!RADEG, thick=5, color=250

            ;; SPI FOV Small Anodes Thetas
            FOR i=0, 10 DO BEGIN
               phi = replicate(i*11.25,10)
               theta = indgen(9)*15-60.
               phi = -1.*phi
               spp_spacecraft_vertices_mollweide, x, y, phi, theta, rr            
               oplot, x*!RADEG, y*!RADEG,thick=3;;, linestyle=1, thick=1, color=250
            ENDFOR

            ;; SPI FOV Small Anodes Phis
            FOR i=0, 8 DO BEGIN
               phi = indgen(11)*11.25
               theta = replicate(i*15.,11)-60.
               phi = -1.*phi
               spp_spacecraft_vertices_mollweide, x, y, phi, theta, rr            
               oplot, x*!RADEG, y*!RADEG,thick=3;;, linestyle=1, thick=1, color=250
            ENDFOR

            ;; SPI FOV Large Anodes Thetas
            FOR i=0, 6 DO BEGIN
               phi = replicate(i*22.5,9)+10.*11.25
               theta = indgen(9)*15-60.
               IF max(phi) GT 180 THEN phi = (phi MOD 180) -180.
               phi = -1.*phi               
               spp_spacecraft_vertices_mollweide, x, y, phi, theta, rr            
               oplot, x*!RADEG, y*!RADEG,thick=3;;, linestyle=1, thick=1, color=250
            ENDFOR

            ;; SPI FOV Large Anodes Phis
            FOR i=0, 8 DO BEGIN
               phi = indgen(7)*22.5+10.*11.25
               theta = replicate(i*15.,7)-60.
               tmp1 = where(phi GT 180.,cc)
               IF cc THEN phi[tmp1] = (phi[tmp1] MOD 180) -180.
               tmp2 = max(phi[0:5]-phi[1:6],loc)
               phi = [phi[0:loc],180,!VALUES.F_NAN,-180,phi[loc+1:6]]
               theta = [theta[0:loc],theta[0],!VALUES.F_NAN,theta[0],theta[loc+1:6]]
               phi = -1.*phi
               spp_spacecraft_vertices_mollweide, x, y, phi, theta, rr
               oplot, x*!RADEG, y*!RADEG,thick=3;;, linestyle=1, thick=1, color=250
            ENDFOR
            
            
         ENDIF ELSE $
          plot, phi, theta,/iso, xr=[-180,180], yr=[-90,90], xst=1,yst=1
         
      ENDIF

      ;; SPAN-Ae
      IF keyword_set(spa) THEN BEGIN 
         
         ;; Shift center to SPAN-Ae
         vtmpa[*,0] = vtmp[*,0] - spa_loc[0]
         vtmpa[*,1] = vtmp[*,1] - spa_loc[1]
         vtmpa[*,2] = vtmp[*,2] - spa_loc[2]

         ;; Apply SPAN-Ae rotation
         nvtmp = vtmpa # rotmat_sc_spa      

         ;; Decompose
         xx = nvtmp[*,0]
         yy = nvtmp[*,1]
         zz = nvtmp[*,2]
         
         po = xx*xx + yy*yy
         rr = sqrt(reform(po+zz*zz))
         phi   = atan(yy,xx)        * !RADEG      
         theta = atan(zz/sqrt(po))  * !RADEG

         IF keyword_set(moll) THEN BEGIN
            r = 1.         
            spp_spacecraft_vertices_mollweide, x, y, phi, theta, r
            oplot, x*!RADEG, y*!RADEG
         ENDIF ELSE $
          plot, phi, theta,/iso, xr=[-180,180], yr=[-90,90], xst=1,yst=1
         
      ENDIF

      ;; SPAN-B
      IF keyword_set(spb) THEN BEGIN 
         
         ;; Shift center to SPAN-B
         vtmpb[*,0] = vtmp[*,0] - spb_loc[0]
         vtmpb[*,1] = vtmp[*,1] - spb_loc[1]
         vtmpb[*,2] = vtmp[*,2] - spb_loc[2]

         ;; Apply SPAN-B rotation
         nvtmp = vtmpb # rotmat_sc_spb      

         ;; Decompose
         xx = nvtmp[*,0]
         yy = nvtmp[*,1]
         zz = nvtmp[*,2]
         
         po = xx*xx + yy*yy
         rr = sqrt(reform(po+zz*zz))
         phi   = atan(yy,xx)        * !RADEG      
         theta = atan(zz/sqrt(po))  * !RADEG

         nn = n_elements(phi)
         tmp2 = ABS(phi[0:nn-2]-phi[1:nn-1])
         tmp3 = where(tmp2 GT 300,cc)

         IF cc GT 0 THEN BEGIN
            WHILE cc GT 0 DO BEGIN
               nn = n_elements(phi)
               tmp2 = ABS(phi[0:nn-2]-phi[1:nn-1])
               tmp3 = where(tmp2 GT 350,cc)
               loc = tmp3[0]
               ;;print, theta[loc-2], theta[loc-1], theta[loc], theta[loc+1], theta[loc+2]
               IF phi[tmp3[0]] LT -170 THEN phi = [phi[0:loc],-180,!VALUES.F_NAN,180,phi[loc+1:nn-1]] $
               ELSE phi = [phi[0:loc],180,!VALUES.F_NAN,-180,phi[loc+1:nn-1]]
               theta = [theta[0:loc],theta[loc],!VALUES.F_NAN,theta[loc+1],theta[loc+1:nn-1]]
            ENDWHILE
         ENDIF
         
            
         IF keyword_set(moll) THEN BEGIN
            r = 1.         
            spp_spacecraft_vertices_mollweide, x, y, phi, theta, r
            oplot, x*!RADEG, y*!RADEG
         ENDIF ELSE $
          plot, phi, theta,/iso, xr=[-180,180], yr=[-90,90], xst=1,yst=1,psym=1

         
      ENDIF

      !P.MULTI = 0      
      
   ENDIF
   
   IF keyword_set(plot_spi) THEN BEGIN   

      ;; Setup plotting environment
      window, 2, xsize=600, ysize=900

      ;; X-Y-Z Coordinates
      xcor = [[0,0,0],[1,0,0]]
      ycor = [[0,0,0],[0,1,0]]
      zcor = [[0,0,0],[0,0,1]]
      
      ;; Temporary Variables
      vtmp = vertex
      vtmp1 = vertex*0
      vtmp2 = vertex*0
      vtmp3 = vertex*0
      vtmp4 = vertex*0

      ;; Shift center to SPAN-Ai
      vtmp1[*,0] = vtmp[*,0] - spi_loc[0]
      vtmp1[*,1] = vtmp[*,1] - spi_loc[1]
      vtmp1[*,2] = vtmp[*,2] - spi_loc[2]

      ;; 1. Apply -20 degree rotation about spacecraft z
      rot_th = -20.                 
      rotr = [[cosd(rot_th), -sind(rot_th),            0],$
              [           0,  cosd(rot_th), sind(rot_th)],$
              [           0,             0,            1]]
      vtmp2 = vtmp1 # rotr

      ;; 2. 
      
      ;; Decompose and transform to spherical
      xx = nvtmp[*,0]
      yy = nvtmp[*,1]
      zz = nvtmp[*,2]
      po = xx*xx + yy*yy
      rr = sqrt(reform(po+zz*zz))
      phi   = atan(yy,xx)        * !RADEG      
      theta = atan(zz/sqrt(po))  * !RADEG

      
      nn = n_elements(phi)
      tmp2 = ABS(phi[0:nn-2]-phi[1:nn-1])
      tmp3 = where(tmp2 GT 300,cc)

         IF cc GT 0 THEN BEGIN
            WHILE cc GT 0 DO BEGIN
               nn = n_elements(phi)
               tmp2 = ABS(phi[0:nn-2]-phi[1:nn-1])
               tmp3 = where(tmp2 GT 350,cc)
               loc = tmp3[0]
               ;;print, theta[loc-2], theta[loc-1], theta[loc], theta[loc+1], theta[loc+2]
               IF phi[tmp3[0]] LT -170 THEN phi = [phi[0:loc],-180,!VALUES.F_NAN,180,phi[loc+1:nn-1]] $
               ELSE phi = [phi[0:loc],180,!VALUES.F_NAN,-180,phi[loc+1:nn-1]]
               theta = [theta[0:loc],theta[loc],!VALUES.F_NAN,theta[loc+1],theta[loc+1:nn-1]]
            ENDWHILE
         ENDIF
      
      ;; Left: PSP/coordinates
      
      
      ;; Right: Mollweide rojection
      
      
      ;; Apply SPAN-I rotation
      nvtmp = vtmpi # rotmat_sc_spi2      

      
      
      
   ENDIF
   
   ;; Assemble Rotation Matrix
   id = identity(3)
   rot_matrix = [[[id]],$
                 [[id]],$
                 [[id]],$
                 [[rotmat_sc_spi]],$
                 [[rotmat_sc_spi2]]]

   ;; Final Structure
   inst = {tps:tps, tps_ind:tps_ind,$
           rda:rda, rda_ind:rda_ind,$
           spp_bus:spp_bus, spp_bus_ind:spp_bus_ind,$
           vertex:vertex,$
           spa_loc:spa_loc,$
           spb_loc:spb_loc,$
           spc_loc:spc_loc,$
           spi_loc:spi_loc,$
           rotmat_spi_sc:rotmat_spi_sc,$
           rotmat_sc_spa:rotmat_sc_spa,$
           rotmat_sc_spb:rotmat_sc_spb,$
           rotmat_sc_spi:rotmat_sc_spi,$           
           rotmat_sc_spi2:rotmat_sc_spi2,$
           rot_matrix:rot_matrix,$
           inst_loc:reform(fltarr(3),1,3)}

END
