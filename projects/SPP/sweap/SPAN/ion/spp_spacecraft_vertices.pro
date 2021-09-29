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
;     PLOT_SC:     Plot all Parker Solar Probe vertices and SWEAP instrument locations.
;
; CREATED BY:      Roberto Livi on 2020-04-23
;
; VERSION:
;   $LastChangedBy:
;   $LastChangedDate:
;   $LastChangedRevision:
;   $URL 
;-


PRO spp_spacecraft_vertices, plot_sc1=plot_sc1, plot_sc2=plot_sc2


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
   vertex = [arr1,nn,arr2,nn,arr3]

   IF keyword_set(plot_sc1) THEN BEGIN
      
      ;;window, 0, xsize=900,ysize=900
      !P.Multi = [0,3]

      ;; X - Y - Z
      
      ;; XX - YY
      plot, vertex[*,0], vertex[*,1],/iso,chars=2,chart=2
      oplot, replicate(spa_loc[0],2),replicate(spa_loc[1],2), psym=2,color=250
      oplot, replicate(spb_loc[0],2),replicate(spb_loc[1],2), psym=2,color=250
      oplot, replicate(spc_loc[0],2),replicate(spc_loc[1],2), psym=4,color=50
      oplot, replicate(spi_loc[0],2),replicate(spi_loc[1],2), psym=5,color=80

      ;; XX - ZZ
      plot, vertex[*,0], vertex[*,2],/iso,chars=2,chart=2
      oplot, replicate(spa_loc[0],2),replicate(spa_loc[2],2), psym=2,color=250
      oplot, replicate(spb_loc[0],2),replicate(spb_loc[2],2), psym=2,color=250
      oplot, replicate(spc_loc[0],2),replicate(spc_loc[2],2), psym=4,color=50
      oplot, replicate(spi_loc[0],2),replicate(spi_loc[2],2), psym=5,color=80

      ;; YY - ZZ
      plot, vertex[*,1], vertex[*,2],/iso,chars=2,chart=2
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
         FOR ith=0., 2.*!PI, 0.025 DO BEGIN

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
            new_r = zz/cos(theta) / 4
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
            
            wait, 0.01

         ENDFOR
      ENDFOR
   ENDIF

   ;; Final Structure
   inst = {tps:tps, tps_ind:tps_ind,$
           rda:rda, rda_ind:rda_ind,$
           spp_bus:spp_bus, spp_bus_ind:spp_bus_ind,$
           vertex:vertex,$
           spa_loc:spa_loc,$
           spb_loc:spb_loc,$
           spc_loc:spc_loc,$
           spi_loc:spi_loc,$
           inst_loc:reform(fltarr(3),1,3)}

END
