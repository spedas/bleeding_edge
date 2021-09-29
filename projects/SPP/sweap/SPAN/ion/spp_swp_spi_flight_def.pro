;+
;
; SPP_SWP_SPI_FLIGHT_DEF
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 28312 $
; $LastChangedDate: 2020-02-18 15:48:49 -0800 (Tue, 18 Feb 2020) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_def.pro $
;
;-

PRO spp_swp_spi_flight_def, def

   eres0 = -1396.73000000000d
   eres1 =   539.08300000000d
   eres2 =     0.80229300000d
   eres3 =    -0.04624000000d
   eres4 =    -0.00016336900d
   eres5 =     0.00000319759d

   ires0 =    -6.6967358589d
   ires1 =  1118.9683837891d
   ires2 =     0.5826185942d
   ires3 =    -0.0928234607d
   ires4 =     0.0000374681d
   ires5 =     0.0000016514d

   ires = [ires0,ires1,ires2,ires3,ires4,ires5]
   eres = [eres0,eres1,eres2,eres3,eres4,eres5]
   
   xx = dindgen(180.d)-90.d

   yy=ires0 + $
      xx*ires1 + $
      xx^2*ires2 + $
      xx^3*ires3 + $
      xx^4*ires4 + $
      xx^5*ires5

   eyy=eres0 + $
       xx*eres1 + $
       xx^2*eres2 + $
       xx^3*eres3 + $
       xx^4*eres4 + $
       xx^5*eres5

   new_yy = 65535.0D - dindgen(2.d*65535.D)
   dac_to_def_ions = interp(xx, yy, new_yy)
   dac_to_def_electrons = interp(xx, eyy, new_yy)

   
   def = {poly5_ions:ires,$
          dac_to_def_ions:dac_to_def_ions,$
          poly5_electrons:eres,$
          dac_to_def_electrons:dac_to_def_electrons}
   
   ;; Debugging and Plotting
   IF 0 THEN BEGIN 

      popen, '~/Desktop/pol5_comparison',/landscape

      yy1 = findgen('FFFF'x)
      ;;yy2 = -1.*reverse(findgen('FFFF'x))
      plot, def.dac_to_def_ions, yy1, xr=[-60,60], $
            xs=1, ys=1,yr=[-1,1]*'FFFF'x,/nodata,$
            ytitle='DAC',xtitle='Deflection Angle'

      oplot, xx,yy, linestyle=2,color=250
      ;;oplot, -1.*reverse(def.dac_to_def_ions), yy2, linestyle=2,color=250

      oplot, xx-2.7,eyy*2.d, linestyle=2,color=50
      ;;oplot, -1.*reverse(def.dac_to_def_electrons), yy2*2.d,$
      ;;linestyle=2,color=50

      oplot, [0,0], [-1e5,1e5], linestyle=3,thick=0.5
      oplot, [-1e5,1e5],[0,0], linestyle=3,thick=0.5
      iress = string(ires,format='(F17.11)')
      eress = string(eres,format='(F17.11)')

      alll = 1.0
      
      xyouts, 25, -2.0e4, 'SPAN-E (x2 GAIN)', color=50, align=alll
      xyouts, 25, -2.3e4, eress[0], color=50, align=alll
      xyouts, 25, -2.6e4, eress[1], color=50, align=alll
      xyouts, 25, -2.9e4, eress[2], color=50, align=alll
      xyouts, 25, -3.2e4, eress[3], color=50, align=alll
      xyouts, 25, -3.5e4, eress[4], color=50, align=alll
      xyouts, 25, -3.8e4, eress[5], color=50, align=alll
      
      xyouts, 50, -2.0e4, 'SPAN-I', color=250, align=alll
      xyouts, 50, -2.3e4, iress[0], color=250, align=alll
      xyouts, 50, -2.6e4, iress[1], color=250, align=alll
      xyouts, 50, -2.9e4, iress[2], color=250, align=alll
      xyouts, 50, -3.2e4, iress[3], color=250, align=alll
      xyouts, 50, -3.5e4, iress[4], color=250, align=alll
      xyouts, 50, -3.8e4, iress[5], color=250, align=alll

      pclose

   ENDIF

END



   
