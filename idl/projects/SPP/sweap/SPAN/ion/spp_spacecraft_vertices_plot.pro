;+
; FUNCTION:        SPP_SPACECRAFT_VERTICES_PLOT
;
; PURPOSE:         
;                  
;                  
;                  
;
; INPUT:           
;
; OUTPUT:          
;
; KEYWORDS:        
;   
;     PLOT_SC1:     
;
; CREATED BY:      Roberto Livi on 2021-11-06
;
; VERSION:
;   $LastChangedBy:
;   $LastChangedDate:
;   $LastChangedRevision:
;   $URL 
;-


PRO spp_spacecraft_vertices_plot_mollweide_outline

      plot, [0,0],[0,0], /nodata, xrange=[-180,180], yrange=[-90,90],xstyle=3,ystyle=3

      FOR i=0., 361., 45. DO BEGIN
         lambda = replicate(i,360)-180.
         phi = findgen(360)/2.-90.
         r = 1
         spp_spacecraft_vertices_plot_mollweide, x, y, lambda, phi, r
         oplot, x*!RADEG, y*!RADEG,linestyle=1;;, psym=1, 
      ENDFOR

      FOR i=0., 361., 45. DO BEGIN
         phi = replicate(i,360)/2.-90.
         lambda = findgen(360)-180.      
         r = 1
         ;;plot, [0,0],[0,0], /nodata, xrange=[-180,180], yrange=[-90,90],xstyle=3,ystyle=3         
         spp_spacecraft_vertices_plot_mollweide, x, y, lambda, phi, r
         oplot, x*!RADEG, y*!RADEG,linestyle=1;;, psym=1, 
      ENDFOR      
   
END

   
PRO spp_spacecraft_vertices_plot_mollweide, x, y, lambda, phi, r

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


PRO spp_spacecraft_vertices_plot, plot_sc1=plot_sc1, plot_sc2=plot_sc2, plot_sc3=plot_sc3, $
                                  moll=moll, $
                                  spa=spa, spb=spb, spi=spi

   ;; Initiate Common Block
   COMMON spp_vertex, inst

   ;; Get PSP Spacecraft Vertices
   IF ~keyword_set(inst) THEN spp_spacecraft_vertices, vertex=vertex
   
   ;; SWEAP Instrument Locations
   
   ;; SPAN-Ai
   spi_loc = inst.spi_loc ;;[ 661.0935, -224.7284,  76.9131]
   ;; SPAN-Ae
   spa_loc = inst.spa_loc ;;[ 562.7270, -494.9875,  76.9080]
   ;; SPAN-B
   spb_loc = inst.spb_loc ;;[-654.87378, 122.6182, 453.8726]
   ;; SPC
   spc_loc = inst.spc_loc ;;[-1296.2722,   0.0000,2970.9419]


   ;; Transformation matrix from SC to ion instrument coordinates
   rotmat_sc_spi  = inst.rotmat_sc_spi
   rotmat_sc_spi2 = inst.rotmat_sc_spi2
   
   ;; SPAN-Ae Rotation Matrix
   rotmat_sc_spa = inst.rotmat_sc_spa

   ;; SPAN-B Rotation Matrix
   rotmat_sc_spb = inst.rotmat_sc_spb

   ;; Plot Mollweide Axis
   spp_spacecraft_vertices_plot_mollweide_outline
   
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
      vtmp = inst.vertex
      vtmpi = inst.vertex
      vtmpa = inst.vertex
      vtmpb = inst.vertex
      

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
            spp_spacecraft_vertices_mollweide, x, y, phi, theta, rr
            oplot, x*!RADEG, y*!RADEG

            ;; SPI FOV Small Anodes Thetas
            FOR i=0, 10 DO BEGIN
               phi = replicate(i*11.25,10)
               theta = indgen(9)*15-60.
               spp_spacecraft_vertices_mollweide, x, y, phi, theta, rr            
               oplot, x*!RADEG, y*!RADEG;;, linestyle=1, thick=1, color=250
            ENDFOR

            ;; SPI FOV Small Anodes Phis
            FOR i=0, 8 DO BEGIN
               phi = indgen(11)*11.25
               theta = replicate(i*15.,11)-60.
               spp_spacecraft_vertices_mollweide, x, y, phi, theta, rr            
               oplot, x*!RADEG, y*!RADEG;;, linestyle=1, thick=1, color=250
            ENDFOR

            ;; SPI FOV Large Anodes Thetas
            FOR i=0, 6 DO BEGIN
               phi = replicate(i*22.5,9)+10.*11.25
               theta = indgen(9)*15-60.
               IF max(phi) GT 180 THEN phi = (phi MOD 180) -180.
               spp_spacecraft_vertices_mollweide, x, y, phi, theta, rr            
               oplot, x*!RADEG, y*!RADEG;;, linestyle=1, thick=1, color=250
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
               spp_spacecraft_vertices_mollweide, x, y, phi, theta, rr
               oplot, x*!RADEG, y*!RADEG;;, linestyle=1, thick=1, color=250
            ENDFOR
            
            stop
            
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

         stop
         
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
      
      
      ;; Right: Mollweide projection
      
      
      ;; Apply SPAN-I rotation
      nvtmp = vtmpi # rotmat_sc_spi2      

   ENDIF
   
END
