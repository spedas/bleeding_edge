;+
;
; SPP_SWP_SPI_FLIGHT_ELO
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 28316 $
; $LastChangedDate: 2020-02-18 15:50:29 -0800 (Tue, 18 Feb 2020) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_elo.pro $
;
;-

PRO spp_swp_spi_flight_elo, sci, tof, elo, mpq, $
                            verbose=verbose, $
                            plott=plott

   ;; Remove last nine bits from Hemisphere DACS
   hv_dac = sci.hv_dac
   ;; Change HEM index to voltage and then to particle energy
   hv = sci.hv
   ;; Add acceleration pot. of 15000V
   ev = sci.ev

   ;; From TRIM 1.0 microgram/cm^2

   ;; Masse/Charge used in simulation
   mass = [1, 16, 40]
   ;; Hydrogen Start Energy
   hse = [100., 500., 1000., 2000., 10000., 20000., 65000.] + 15000.
   ;; Oxygen Start Energy
   ose = [100., 500., 1000., 2000., 10000., 20000., 65000.] + 15000.
   ;; Argon Start Energy
   ase = [100., 500., 1000., 2000., 10000., 20000., 65000.] + 15000.
   ;; Hydrogen Exit Energy 
   hee = [14574., 14969., 15463., 16452., 24380., 34321., 79235.]
   ;; Oxygen Exit Energy 
   oee = [12791., 13188., 13669., 14652., 22552., 32483., 77283.]
   ;; Argon Exit Energy 
   aee = [10310., 10680., 11171., 12112., 19836., 29640., 74270.]
   ;; Change to percentage
   hh = 100.*hee/hse
   oo = 100.*oee/ose
   aa = 100.*aee/ase
   ;; Assume error of 1
   sigmah = replicate(1., n_elements(hh))
   sigmao = replicate(1., n_elements(oo))
   sigmab = replicate(1., n_elements(aa))

   ;; Perform fit
   ;; func = 'spp_swp_param_func'
   ;; hfit = curvefit(hv, hh, weights, ah, sigmah, function_name=func)
   ;; ofit = curvefit(ov, oo, weights, ao, sigmao, function_name=func)
   ;; afit = curvefit(av, aa, weights, ab, sigmab, function_name=func)

   ;; Curvefit Results of an exponential
   ;; a1*exp(energy*a2)+a3
   ah = [  -5.2, -4.5e-05, 99.2]
   ao = [ -28.5, -5.7e-05, 96.8]
   ab = [ -57.1, -5.5e-05, 93.4]
   hfit = (ah[0]*exp(ev*ah[1])+ah[2]) < 100.0
   ofit = (ao[0]*exp(ev*ao[1])+ao[2]) < 100.0
   afit = (ab[0]*exp(ev*ab[1])+ab[2]) < 100.0

   ;; Empty Array to store values
   eloss_matrix = fltarr(512, 128)
   tof_to_mpq   = fltarr(512, 128)
   
   ;; Cycle through 128 energy bins
   FOR i=0, 127 DO BEGIN

      ;; Define Energy Loss
      tt = sqrt(0.5*mass*sci.atokg*$
                tof.tof_flight_path^2 / $
                sci.evtoj/ev[i])/1e-9
      yy = [hfit[i], ofit[i], afit[i]]
      tmp1 =  interpol(yy, tt, tof.tof512_avgs) > 0
      tmp2 = tmp1 < 100.0
      eloss_matrix[*, i] = tmp2

      ;; Define TOF to M/Q conversion using ELOSS_MATRIX
      new_ev = (tmp2/100.)*ev[i]
      mass_ev = ((tof.tof512_avgs*1e-9)/tof.tof_flight_path)^2 / $
                sci.atokg / 0.5 * new_ev * sci.evtoj
      tof_to_mpq[*,i] = mass_ev

      ;; Diagnostic Plotting
      IF keyword_set(plott) THEN BEGIN 
         !p.multi = [0,0,2]
         plot,  tt, yy,  xr=[1, 100], xs=1, yr=[50, 100], $
                ys=1, /xlog,title=string(ev[i])
         oplot, tof.tof512_avgs, eloss_matrix[*, i], $
                color=250,psym=-1
         plot, tof.tof512_avgs, mass_ev, psym=-1
         wait, 0.05
         !p.multi = 0
      ENDIF

   ENDFOR

   ;; FINAL VALUES
   elo = eloss_matrix
   mpq = tof_to_mpq
   
   ;;################
   ;;### Plotting ###
   ;;################

   verbose = 0
   IF keyword_set(verbose) THEN BEGIN

      ;;##############################
      ;;### Setup Plotting Windows ###
      ;;##############################
      window, xsize=1200,ysize=900
      !p.multi = [0,2,2]


      ;;#######################################
      ;;#             PLOT 1                  #
      ;;#                                     #
      ;;# TOF vs. Energy (black)              #
      ;;# TOF vs. Energy including loss (red) #
      ;;#######################################
      
      ;; Choose masses to plot
      specific_mass = [1,2,4,20]

      mass_nn  = n_elements(specific_mass)
      mass_amu = replicate(1.,n_elements(ev))#(specific_mass)
      enrg_amu = ev#replicate(1.,mass_nn)
      mass_tof = sqrt(0.5*mass_amu*sci.atokg*$
                      tof.tof_flight_path^2/$
                      sci.evtoj/$
                      (enrg_amu))/1e-9
      mass_ppp   = intarr(n_elements(ev),mass_nn)
      mass_eloss = intarr(n_elements(ev),mass_nn)
      FOR i=0, mass_nn-1 DO BEGIN
         FOR j=0, n_elements(ev)-1 DO BEGIN 
            mass_ppp[j,i] = value_locate($
                            tof.tof512_bnds,$
                            reform(mass_tof[j,i]))            
            mass_eloss[j,i] = eloss_matrix[mass_ppp[j,i],j]
         ENDFOR
      ENDFOR
      
      ;; Account for energy loss
      enrg_amu_corr = enrg_amu*(mass_eloss/100.)
      mass_tof_corr = sqrt(0.5*mass_amu*sci.atokg*$
                           tof.tof_flight_path^2/$
                           sci.evtoj/$
                           (enrg_amu_corr))/1e-9

      yyr = minmax([mass_tof,$
                    mass_tof_corr,$
                    mass_tof_corr-$
                    tof.tof_e_corr*1e9])
      xxr = minmax(enrg_amu)
      plot, [1.,1000.],[0,1],/nodata,$
            ytitle='ns',xtitle='Particle Energy [eV]',$
            title='TOF vs Energy',$
            yr=yyr,xr=xxr,$
            ys=1,xs=1,xlog=1    ;,ylog=1
      FOR i=0, mass_nn-1 DO BEGIN 
         oplot, enrg_amu[*,i],mass_tof[*,i]
         oplot, enrg_amu[*,i],mass_tof_corr[*,i],color=250
         oplot, enrg_amu[*,i],mass_tof_corr[*,i]-$
                tof.tof_e_corr*1e9,color=50
      ENDFOR 

      ;; Add results from Davin's Energy-Mass Scans
      IF file_test('~/Desktop/tmp.sav') THEN BEGIN 
         restore, '~/Desktop/tmp.sav'
         oplot, vh, h, color=80, psym=1
         oplot, vo, o, color=80, psym=1
         oplot, vc, c, color=80, psym=1
      ENDIF
      
      ;; Add results from Colutron scan
      h   = tof.tof_moy.tof_mq1*[1,2.365,1]
      h2  = tof.tof_moy.tof_mq2*[1,2.365,1]
      he  = tof.tof_moy.tof_mq4*[1,2.365,1]
      o   = tof.tof_moy.tof_mq16*[1,2.365,1]
      nne = tof.tof_moy.tof_mq20*[1,2.365,1]
      ni = tof.tof_moy.tof_mq28*[1,2.365,1]
      xx = 16000.
      oplot, replicate(xx,2), [h[2] - h[1], h[2]  + h[1]],  thick=5
      oplot, replicate(xx,2), [h2[2]- h2[1],h2[2] + h2[1]], thick=5
      oplot, replicate(xx,2), [he[2]- he[1],he[2] + he[1]], thick=5
      ;oplot, replicate(xx,2), [ni[2]- ni[1],ni[2] + ni[1]], thick=5
      oplot, replicate(xx,2), [o[2] - o[1], o[2]  + o[1]],  thick=5
      ;oplot, replicate(xx,2), [nne[2]-nne[1],nne[2]+nne[1]], thick=5

      ;;coef = mass_enrg
      ;;xx   = indgen(8000.)+15000.
      ;;yyh  = coef[0,0] * exp(coef[1,0]*xx) + coef[2,0]
      ;;yyo  = coef[0,1] * exp(coef[1,1]*xx) + coef[2,1]
      ;;yyu  = coef[0,2] * exp(coef[1,2]*xx) + coef[2,2] 

      ;;oplot, xx, yyh, color=80
      ;;oplot, xx, yyo, color=80
      ;;oplot, xx, yyu, color=80

      ;;#######################################
      ;;#              PLOT 2                 #
      ;;#                                     #
      ;;#     Seconds due to energy loss      #
      ;;#######################################
      mass_tof_diff = ABS(mass_tof - mass_tof_corr)
      xxr = minmax(enrg_amu)
      yyr = minmax(mass_tof_diff-tof.tof_e_corr*1e9)
      plot, [0,1],[0,1],/nodata,xr=xxr,$
            ytitle='ns',xtitle='Particle Energy [eV]',$
            title='TOF Difference vs Energy',$
            ys=1,xs=1,yr=yyr,xlog=1;,ylog=1
      FOR i=0, n_elements(specific_mass)-1 DO BEGIN
         oplot, enrg_amu[*,i], mass_tof_diff[*,i],color=250
         oplot, enrg_amu[*,i], mass_tof_diff[*,i]-$
                tof.tof_e_corr*1e9,color=50
      ENDFOR

      ;;#######################################
      ;;#              PLOT 3                 #
      ;;#                                     #
      ;;#         Energy Loss Matrix          #
      ;;#           Units of Bins             #
      ;;#######################################
      xxx = (sci.ev-15000.)##replicate(1.,512) > 1
      yyy = (tof.tof512_avgs#replicate(1.,128))>0.1 
      zzz = elo/max(elo)<0.95>0.15
      contour, zzz, yyy, xxx,$
               /fill,nleve=100, xs=1,ys=1,/xlog,/ylog,$
               title='Energy Loss Matrix',$
               xr=[10,200], yr=[100,60000],$
               ytitle='Energy (7 most significant bits) [eV]',$
               xtitle='TOF [ns]'

      ;;#######################################
      ;;#              PLOT 4                 #
      ;;#                                     #
      ;;#         Energy Loss Matrix          #
      ;;#           Physical Units            #
      ;;#######################################
      xxx = (sci.ev-15000.)##replicate(1.,512) > 1
      yyy = (tof.tof512_avgs#replicate(1.,128)-1d)>0.1 
      zzz = alog(tof_to_mpq < 60 > 0.5)
      contour, zzz, yyy, xxx,$
               nlevel=512, xs=1,ys=1,/fill,$
               title='Mass/Charge Matrix',xr=[7,120],$
               ytitle='Energy (7 most significant bits) [eV]',$
               /xlog,/ylog,yr=[100,60000],$
               xtitle='TOF [ns]',zr=alog([0.5,60])

      IF mass_nn EQ 4 THEN BEGIN 
         oplot, mass_tof_corr[*,0]-tof.tof_e_corr*$
                1e9,(enrg_amu[*,0]-15000.)>1, $
                color=255, thick=3, linestyle=2
         oplot, mass_tof_corr[*,1]-tof.tof_e_corr*$
                1e9,(enrg_amu[*,1]-15000.)>1, $
                color=255, thick=3, linestyle=2
         oplot, mass_tof_corr[*,2]-tof.tof_e_corr*$
                1e9,(enrg_amu[*,2]-15000.)>1, $
                color=255, thick=3, linestyle=2
         oplot, mass_tof_corr[*,3]-tof.tof_e_corr*$
                1e9,(enrg_amu[*,3]-15000.)>1, $
                color=0,   thick=3, linestyle=2
         xyouts,  9.5, 110,  '1', charthick=3, size=2, color=255
         xyouts, 14.0, 110,  '2', charthick=3, size=2, color=255
         xyouts, 21.0, 110,  '4', charthick=3, size=2, color=255
         xyouts, 47.0, 110, '20', charthick=3, size=2, color=0
      ENDIF 

      !p.multi = 0


      stop
   ENDIF 

END
