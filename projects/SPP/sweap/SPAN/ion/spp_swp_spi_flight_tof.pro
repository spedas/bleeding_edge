;+
;
; SPP_SWP_SPI_FLIGHT_TOF
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 26843 $
; $LastChangedDate: 2019-03-17 23:52:06 -0700 (Sun, 17 Mar 2019) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_tof.pro $
;
;-

PRO spp_swp_spi_flight_tof, ano, sci, tbl

   ;;------------------------------------------------------
   ;; Colutron Characteristics
   
   ;; Model 600 Wien Filter - Gauss to Current Conv.
   col_gauss = [190.00,200.00,350.00,400.00,500.00,600.00,670.00]
   col_curr  = [  0.50,  0.60,  1.00,  1.23,  1.50,  1.85,  2.00]
   wien_param = linfit(col_curr,col_gauss)

   ;;------------------------------------------------------
   ;; Time-of-Flight Bin to Nanoseconds

   ;; Time-of-Flight Flight Path
   tof_flight_path = 0.02    ;[m]

   ;; Original 2048 array bin size in nanoseconds
   tof_bin = 0.101725 
   tof2048_bnds = findgen(2049)*tof_bin
   tof2048_avgs = tof2048_bnds[1:2048] - tof_bin/2

   ;; TOF Histogram
   ;; Compression 1: Cut off LSB and scheme below
   tof1024_bnds = tof2048_bnds[findgen(1025)*2]
   tof1024_avgs = tof2048_avgs[findgen(1024)*2]

   ;; Bin Compression 2:
   ;; a) N       for      counts <  256
   ;; b) N/2+128 for  256 >= counts < 512)
   ;; c) N/4+256 for      counts >= 512

   ;p1_avgs      = tof1024_avgs[0:255]
   ;p2_avgs      = (tof1024_avgs[256:511])[findgen(128)*2]
   ;p3_avgs      = (tof1024_avgs[512:1023])[findgen(128)*4]
   ;tof512_avgs  = [p1_avgs,p2_avgs,p3_avgs]

   p1_bnds      = tof1024_bnds[0:256]
   p2_bnds      = (tof1024_bnds[256:512])[findgen(129)*2]
   p3_bnds      = (tof1024_bnds[512:1024])[findgen(129)*4]
   tof512_bnds  = [p1_bnds,p2_bnds[1:128],p3_bnds[1:128]]
   tof512_avgs  = (tof512_bnds[1:512]+tof512_bnds[0:511])/2.

   tof512_factor = [replicate(2,256),$
                    replicate(4,128),$
                    replicate(8,128)]
   
   ;; TOF Corrections from Flight Calibration
   tof_corr = [6, 5, 5, 6, 9, 8, 6, 6, $
               8, 5, 4, 0, 3, 3, 6, 1]

   ;;------------------------------------------------------
   ;; Start Electron Flight Path (Approximated)
   ;; Note: The path is a straight line and
   ;; acceleration is 1keV.
   stop_rad  = (ano.rad1+ano.rad2)/2.
   start_rad = (ano.rad3+ano.rad4)/2.
   epath = sqrt(tof_flight_path^2+((stop_rad-start_rad)*2.54/100.)^2)
   tof_e_corr = epath / $
                sqrt( (1000.*sci.evtoj) * $
                      2. / sci.mass_e_kg)

   ;; K Values from Calibration
   ;;kval = [16.9059, 17.4086, 17.3547, 17.4056, 16.9689, $
   ;;        17.0019, 17.4656, 16.7100, 16.5611, 16.4142, $
   ;;        16.6191, 16.6381, 16.5431, 16.1663, 16.1003, 16.1353]

   ;;-----------------------------------------------------------
   ;; TOF [ms] Moyal Distributions with 1keV beam 
   ;;---------------------
   ;; Var      - Definition
   ;;---------------------
   ;; var.moy.p[0] - Coefficient
   ;; var.moy.p[1] - X Sigma
   ;; var.moy.p[2] - X Offset
   ;;
   ;; Functional Form:
   ;;
   ;; coef  = (*var.moy.p)[0,*]/sqrt(2.*!PI)/(*var.moy.p)[1,*]
   ;; z     = (*var.moy.xx-(*var.moy.p)[2,*])/(*var.moy.p)[1,*]
   ;; expo  = exp(-0.5*(z+exp(-1.*z)))   
   ;; moyss = coef * expo

   ;; NOTE: Commented values do not have
   ;;       start e- travelt time  correction

   ;; M/Q =  1 (H+) -------------------
   tof_mq1   =  [ 5295.93, 0.1841, 10.21];[ 5470.04, 0.1786, 11.44]
   tof_mq1_2 =  [   11.67, 0.3434, 26.21];[   11.08, 0.2773, 27.41]
   ;; M/Q =  2 (H2+) ------------------
   tof_mq2   =  [ 2013.17, 0.2661, 15.72];[ 2009.37, 0.2687, 16.93]
   tof_mq2_2 =  [    7.37, 0.6196, 26.41];[    6.99, 0.5057, 27.57]
   ;tof_mq2_3 =  [   50.00, 0.4000, 41.30]
   ;; M/Q =  4 (He+) ------------------
   tof_mq4  =   [15072.70, 0.1841, 22.59];[15098.76, 0.3219, 23.79]
   ;; M/Q = 14 (N+) -------------------
   tof_mq14 =   [ 6256.83, 1.2630, 46.56];[ 6318.45, 1.2800, 47.76]
   ;; M/Q = 16 (O+) -------------------
   tof_mq16   = [12901.90, 1.8893, 53.61];[12954.58, 1.8982, 54.83]
   tof_mq16_2 = [  312.06, 9.3227, 35.35];[  316.86, 9.4813, 36.68]
   tof_mq16_3 = [   10.15, 0.2841, 17.08];[    9.71, 0.2755, 18.35]
   ;; M/Q = 18 (H2O+) -----------------
   tof_mq18   = [54835.30, 2.5826, 56.41];[50510.93, 2.3723, 57.50]
   tof_mq18_2 = [  918,82, 2.1051, 44.95];[ 1207.98, 3.4384, 47.83]
   tof_mq18_3 = [ 1197.27, 3.1664, 39.95];[ 1127.26, 2.3023, 37.84]
   tof_mq18_4 = [  586.24, 1.9254, 30.65];[  617.57, 1.8847, 31.83]
   ;; M/Q = 20 (Ne+) ------------------
   tof_mq20   = [ 4193.21, 2.1612, 58.97];[ 4149.07, 2.1446, 60.21]
   tof_mq20_2 = [   51.13, 2.3090, 34.89];[   49.92, 2.2469, 36.10]
   tof_mq20_3 = [  141.17, 5.0153, 49.63];[  146.49, 5.0791, 50.93]
   ;; M/Q = 28 (???) ------------------
   tof_mq28   = [56034.10, 4.2916, 71.10];[56136.68, 4.3313, 72.30]
   tof_mq28_2 = [  180.59, 1.1200, 55.00];[  168.39, 1.2000, 56.30]
   tof_mq28_3 = [  222.65, 1.6188, 49.00];[  213.88, 1.6024, 50.30]
   tof_mq28_4 = [ 1109.50, 3.3198, 41.00];[ 1146.82, 3.3621, 42.30]
   ;; M/Q = 29 (???) ------------------
   tof_mq29   = [ 2785.29, 3.7721, 72.83];[ 2787.20, 3.7702, 74.00]
   tof_mq29_2 = [   64.41, 5.6845, 43.85];[   63.99, 5.6191, 45.04]
   ;; M/Q = 30 (???) ------------------
   tof_mq30   = [ 1152.24, 3.9932, 73.95];[ 1150.00, 3.9979, 75.17]
   tof_mq30_2 = [   46.11, 8.5072, 47.06];[   46.39, 8.5572, 48.35]
   ;; M/Q = 38 (???) ------------------
   tof_mq38   = [28727.20, 5.9106, 86.95];[28747.82, 5.9203, 88.16]
   tof_mq38_2 = [ 5553.48, 6.1426, 60.93];[ 5576.29, 6.1649, 62.12]
   tof_mq38_3 = [  898.48, 2.8359, 45.04];[  887.23, 2.8105, 46.19]
   tof_mq38_4 = [   16.84, 0.2005, 25.93];[   27.20, 0.3982, 26.97]
   tof_mq38_5 = [   40.53, 0.4622, 17.18];[   25.64, 0.2607, 18.43]
   ;; M/Q = 39 (???) ------------------
   tof_mq39   = [57521.60, 5.7394, 88.65];[57528.07, 5.7444, 89.83]
   tof_mq39_2 = [12394.80, 6.9519, 62.05];[12373.91, 6.9405, 63.25]
   ;; M/Q = 40 (???) ------------------
   tof_mq40   = [11549.80, 6.4919, 91.37];[11445.40, 6.2185, 91.73]
   tof_mq40_2 = [ 2336.54, 6.7952, 62.64];[ 2427.04, 6.9886, 64.02]
   tof_mq40_3 = [  325.19, 3.2499, 46.30];[  298.92, 3.1008, 47.20]
   tof_mq40_4 = [   10.61, 0.3338, 26.03];[    9.92, 0.3092, 27.30]
   tof_mq40_5 = [   13.67, 0.2909, 17.15];[   13.90, 0.2881, 18.38]
      

   tof_moy = {tof_mq1:tof_mq1,       $
              tof_mq1_2:tof_mq1_2,   $

              tof_mq2:tof_mq2,       $
              tof_mq2_2:tof_mq2_2,   $

              tof_mq4:tof_mq4,       $

              tof_mq14:tof_mq14,     $

              tof_mq16:tof_mq16,     $
              tof_mq16_2:tof_mq16_2, $
              tof_mq16_3:tof_mq16_3, $

              tof_mq18:tof_mq18,     $
              tof_mq18_2:tof_mq18_2, $
              tof_mq18_3:tof_mq18_3, $
              tof_mq18_4:tof_mq18_4, $
              
              tof_mq20:tof_mq20,     $
              tof_mq20_2:tof_mq20_2, $
              tof_mq20_3:tof_mq20_3, $
              
              tof_mq28:tof_mq28,     $
              tof_mq28_2:tof_mq28_2, $
              tof_mq28_3:tof_mq28_3, $
              tof_mq28_4:tof_mq28_4, $
              
              tof_mq29:tof_mq29,     $
              tof_mq29_2:tof_mq29_2, $
              
              tof_mq30:tof_mq30,     $
              tof_mq30_2:tof_mq30_2, $
              
              tof_mq38:tof_mq38,     $
              tof_mq38_2:tof_mq38_2, $
              tof_mq38_3:tof_mq38_3, $
              tof_mq38_4:tof_mq38_4, $
              tof_mq38_5:tof_mq38_5, $
              
              tof_mq39:tof_mq39,     $
              tof_mq39_2:tof_mq39_2, $
              
              tof_mq40:tof_mq40,     $
              tof_mq40_2:tof_mq40_2, $
              tof_mq40_3:tof_mq40_3, $
              tof_mq40_4:tof_mq40_4, $
              tof_mq40_5:tof_mq40_5}



   ;;??????????????????????????????????????????????????????
   ;;------------------------------------------------------
   ;; Davin's Energy Mass Scan results for H+, O+, and
   ;; a heavier unidentified mass.
   ;;
   ;; Exponential function used:
   ;; a[0] * exp(a[1]*x) + a[2]
   ;;
   ;; Fits derived using:
   ;; spp_swp_spi_flight_cal_energy_mass_scan.pro
   mass_enrg = [[ 27.32, -1.26e-4,  6.64],$  ; H+
                [ 58.78, -4.98e-5, 28.09],$  ; O+
                [101.35, -8.06e-5, 17.70]]   ; Unidentified
   ;;??????????????????????????????????????????????????????


   tbl = {tof_moy:tof_moy,$
          tof_corr:tof_corr,$
          tof_e_corr:tof_e_corr,$
          ;;kval:kval,$
          tof2048_bnds:tof2048_bnds,$
          tof2048_avgs:tof2048_avgs,$
          tof1024_bnds:tof1024_bnds,$
          tof1024_avgs:tof1024_avgs,$
          tof512_bnds:tof512_bnds,$
          tof512_avgs:tof512_avgs,$
          tof512_factor:tof512_factor,$
          tof_bin:tof_bin,$
          tof_flight_path:tof_flight_path,$
          col_gauss:col_gauss,$
          col_curr:col_curr,$
          wien_param:wien_param,$
          davin_mas_nrg:mass_enrg $
         }

   
END
