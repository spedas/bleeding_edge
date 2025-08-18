;+
;
; ESC_SPI_FM1_TOF
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 31963 $
; $LastChangedDate: 2023-07-21 12:05:49 -0700 (Fri, 21 Jul 2023) $
; $LastChangedBy: rlivi04 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_fm1_tof.pro $
;
;-

PRO esc_iesa_fm1_tof, ano, sci, tbl

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
   tof_bin = (10d^9 * 4d) / 2d^24 / 2048d
   tof2048_bnds = findgen(2049)*tof_bin
   tof2048_mids = tof2048_bnds[1:2048] - tof_bin/2.
   tof2048_inds = indgen(2048)
   tof2048_inds_c = indgen(2048)
   
   ;; --- COMPRESSION --- ;;
   ;; Below ~22ns - Remove 1 LSB
   ;; Above ~22ns - Remove 3 LSB
   
   ;; Boundary - TOF BIN 0xC0 - 22.36224 ns
   bbin = 'c0'x

   ;; TOF2048 Compressed Bins
   tof2048_inds_c[0:bbin-1]  = ishft(tof2048_inds[0:bbin-1],-1)
   tof2048_inds_c[bbin:2047] = ishft(tof2048_inds[bbin:2047],-3)
   corr = max(tof2048_inds_c[0:bbin-1]) - min(tof2048_inds_c[bbin:2047]) + 1
   tof2048_inds_c[bbin:2047] = (tof2048_inds_c[bbin:2047] + corr) < 'ff'x

   ;; Loop
   tof256_bnds = fltarr(257)
   tof256_mean = fltarr(256)
   tof256_fact = fltarr(256)
   
   FOR i=0, 255 DO BEGIN
      pp = where(tof2048_inds_c EQ i,cc)
      tof256_bnds[i+1] = max(tof2048_bnds[pp+1])
      tof256_mean[i] = mean(tof256_bnds[i:i+1])
      tof256_fact[i] = cc
   ENDFOR
   
   ;; TOF Corrections from Flight Calibration
   ;; From iESA FM1 Calibrations - 05/17/23
   tof_corr = [3, 1, 3, 0, 1, 4, 6, 6, $
               4, 6, 5, 5, 6, 5, 5, 5]

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


   tbl = {tof_moy:tof_moy,$
          tof_corr:tof_corr,$
          tof_e_corr:tof_e_corr,$

          tof2048_bnds:tof2048_bnds,$
          tof2048_mids:tof2048_mids,$
          tof2048_inds:tof2048_inds,$
          tof2048_inds_c:tof2048_inds_c,$

          tof256_bnds:tof256_bnds,$
          tof256_mean:tof256_mean,$
          tof256_fact:tof256_fact,$
          tof_bin:tof_bin,$
          tof_flight_path:tof_flight_path,$
          col_gauss:col_gauss,$
          col_curr:col_curr,$
          wien_param:wien_param $
         }

   
END
