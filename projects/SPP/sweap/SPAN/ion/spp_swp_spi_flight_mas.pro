;+
;
; SPP_SWP_SPI_FLIGHT_MAS
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 28317 $
; $LastChangedDate: 2020-02-18 15:50:42 -0800 (Tue, 18 Feb 2020) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_mas.pro $
;
;-


;+
;;#####################################################
;;                  Mass Table 0
;;#####################################################
;-
PRO spp_swp_spi_flight_mas_0, tbl, dac, sci, tof

   ev       = dac.ev
   mass     = [1,2,21,32]
   mass_nn  = n_elements(mass)
   mass_amu = replicate(1.,n_elements(ev))#(mass)
   enrg_amu = dac.ev#replicate(1.,mass_nn)
   mass_tof = sqrt(0.5*mass_amu*sci.atokg*$
                   tof.tof_flight_path^2/$
                   sci.evtoj/$
                   (enrg_amu))/1e-9

   ;; Find and store mass tof bin locations
   mass_ppp   = intarr(n_elements(ev),mass_nn)
   mass_eloss = intarr(n_elements(ev),mass_nn)
   FOR i=0, mass_nn-1 DO BEGIN
      FOR j=0, n_elements(ev)-1 DO BEGIN 
         mass_ppp[j,i] = value_locate($
                         tof.tof512_bnds,$
                         reform(mass_tof[j,i]))
         mass_eloss[j,i] = (*spi_param.eloss)[mass_ppp[j,i],j]
      ENDFOR
   ENDFOR
   
   ;; Account for energy loss
   enrg_amu_corr = enrg_amu*(mass_eloss/100.)

   ;; Account for TOF correction
   mass_tof_corr = sqrt(0.5*mass_amu*spi_param.sci.atokg*$
                        tof.tof_flight_path^2/$
                        sci.evtoj/$
                        (enrg_amu_corr))/1e-9 - $
                   tof.tof_e_corr*1e9

   ;; Setup final mass table
   ;; Value 63 will be used for trash
   mass_table_0 = fix((*spi_param.eloss) * 0) + 63

   FOR i=0, 127 DO BEGIN

      ;; Find tof at current energy
      m0 = mean(mass_tof_corr[i,0])
      m1 = mean(mass_tof_corr[i,1])
      m2 = mean(mass_tof_corr[i,2])
      m3 = mean(mass_tof_corr[i,3])

      ;; Find corresponding TOF bin number
      ;; and force it to be even
      p0 = value_locate(tof.tof512_bnds, m0)
      IF (p0 MOD 2) THEN p0 = p0-1
      p1 = value_locate(tof.tof512_bnds, m1)
      IF (p1 MOD 2) THEN p1 = p1-1
      p2 = value_locate(tof.tof512_bnds, m2)
      IF (p2 MOD 2) THEN p2 = p2-1
      p3 = value_locate(tof.tof512_bnds, m3)
      IF (p3 MOD 2) THEN p3 = p3-1

      p0_range = [p0-8:p0+7]
      p1_range = [p1-8:p1+7]
      p2_range = [p2-8:p2+7]
      p3_range = [p3-8:p3+7]

      ;; Make sure no overlap between p0/p1
      diff = min(p1_range) - max(p0_range)
      IF diff LT 0 THEN BEGIN
         diff = temporary(ABS(diff))
         p0_range = [p0-8:p0+7] - ceil(diff/2.)
         p1_range = [p1-8:p1+7] + floor(diff/2.)+1
      ENDIF 

      ;; Make sure no overlap between p1/p2
      diff = min(p2_range) - max(p1_range)
      IF diff LT 0 THEN BEGIN
         diff = temporary(ABS(diff))
         p2_range = [p2-8:p2+7] + diff
      ENDIF 
      
      mass_table_0[p0_range,i] = indgen(16) +  0
      mass_table_0[p1_range,i] = indgen(16) + 16
      mass_table_0[p2_range,i] = indgen(16) + 32
      mass_table_0[p3_range,i] = indgen(16) + 48

      ;;print, format='(8I4)',$
      ;;       minmax(p0_range), $
      ;;       minmax(p1_range), $
      ;;       minmax(p2_range), $
      ;;       minmax(p3_range)

   ENDFOR

   ;;FOR i=0, 127 DO BEGIN
   ;;   plot, mass_table_0[*,i]
   ;;   wait, 0.5
   ;;ENDFOR


END


;+
;;#####################################################
;;                  Mass Table 1
;;#####################################################
;-
PRO spp_swp_spi_flight_mas_1, tbl, dac, sci, tof, elo

   ev       = sci.ev
   mass     = [1,2,21,32]
   mass_nn  = n_elements(mass)
   mass_amu = replicate(1.,n_elements(ev))#(mass)
   enrg_amu = ev#replicate(1.,mass_nn)
   mass_tof = sqrt(0.5*mass_amu*sci.atokg*$
                   tof.tof_flight_path^2/$
                   sci.evtoj/$
                   (enrg_amu))/1e-9

   kk = 0
   mass_ppp   = intarr(n_elements(ev),mass_nn)
   mass_eloss = intarr(n_elements(ev),mass_nn)
   FOR i=0, mass_nn-1 DO BEGIN
      FOR j=0, n_elements(ev)-1 DO BEGIN 
         mass_ppp[j,i] = value_locate($
                         tof.tof512_bnds,$
                         reform(mass_tof[j,i]))
         mass_eloss[j,i] = (elo)[mass_ppp[j,i],j]
      ENDFOR
   ENDFOR
   
   ;; Account for energy loss
   enrg_amu_corr = enrg_amu*(mass_eloss/100.)

   ;; Account for electron travel time correction (~1ns)
   mass_tof_corr = sqrt(0.5*mass_amu*sci.atokg*$
                        tof.tof_flight_path^2/$
                        sci.evtoj/$
                        (enrg_amu_corr))/1e-9 - $
                   tof.tof_e_corr*1e9

   ;; Empty variable with same dimensions as elo
   mass_table_1 = fix((elo) * 0)

   ;; Temporary variables
   p0 = intarr(128)
   p1 = intarr(128)
   p2 = intarr(128)

   ;; For each energy bin:
   ;;    1. Find the mean tof time between the different masses.
   ;;    2. Fill
   ;;       
   FOR i=0, 127 DO BEGIN

      ;; 1. Find Interval 
      m0 = mean(mass_tof_corr[i,0:1])
      m1 = mean(mass_tof_corr[i,1:2])
      m2 = mean(mass_tof_corr[i,2:3])

      p0[i] = value_locate(tof.tof512_bnds, m0)
      IF (p0[i] MOD 2) THEN p0[i] = p0[i]-1
      p1[i] = value_locate(tof.tof512_bnds, m1)
      IF (p1[i] MOD 2) THEN p1[i] = p1[i]-1
      p2[i] = value_locate(tof.tof512_bnds, m2)
      IF (p2[i] MOD 2) THEN p2[i] = p2[i]-1

      p0_range = fix((findgen(p0[i])/p0[i])*16.) 
      p1_range = fix((findgen(p1[i]-p0[i])/(p1[i]-p0[i])*16.)+16.)
      p2_range = fix((findgen(p2[i]-p1[i])/(p2[i]-p1[i])*16.)+32.)
      p3_range = fix((findgen(512-p2[i])/(512-p2[i])*16.)+48.)

      mass_table_1[0:p0[i]-1, i] = p0_range
      mass_table_1[p0[i]:p1[i]-1,i] = p1_range
      mass_table_1[p1[i]:p2[i]-1,i] = p2_range
      mass_table_1[p2[i]:511, i] = p3_range

   ENDFOR

   ;; Mass Table
   mt1 = mass_table_1
   
   ;; 64 Mass Summation histogram
   mt1_sum = fltarr(128,64)
   FOR ii=0, 127 DO mt1_sum[ii,*] = $
    histogram(reform(mt1[*,ii]),$
              binsize=1,loc=loc)

   ;; TOF boundaries
   mt1_tof = fltarr(128,64)
   FOR ii=0, 127 DO BEGIN
      ind1 = 0
      FOR jj=0, 63 DO BEGIN
         ind2 = ind1+mt1_sum[ii,jj]
         mt1_tof[ii,jj] = $
          mean(tof.tof512_avgs[ind1:ind2-1])
         ind1 = ind2
      ENDFOR 
   ENDFOR

   ;; Structure
   tbl = {mt1:mass_table_1,$
          mt1_sum:mt1_sum,$
          mt1_tof:mt1_tof,$
          mt1_mpq:mt1_tof}

END



;+
;;#####################################################
;;                  Mass Table 2
;;#####################################################
;-
PRO spp_swp_spi_flight_mas_2, tbl, dac, sci, tof, elo

   mass     = [1,2,21,32]
   mass_nn  = n_elements(mass)
   mass_amu = replicate(1.,n_elements(sci.ev))#(mass)
   enrg_amu = sci.ev#replicate(1.,mass_nn)
   mass_tof = sqrt(0.5*mass_amu*sci.atokg*$
                   tof.tof_flight_path^2/$
                   sci.evtoj/$
                   (enrg_amu))/1e-9

   kk = 0
   mass_ppp   = intarr(n_elements(sci.ev),mass_nn)
   mass_eloss = intarr(n_elements(sci.ev),mass_nn)
   FOR i=0, mass_nn-1 DO BEGIN
      FOR j=0, n_elements(sci.ev)-1 DO BEGIN 
         mass_ppp[j,i] = value_locate($
                         tof.tof512_bnds,$
                         reform(mass_tof[j,i]))
         mass_eloss[j,i] = (elo)[mass_ppp[j,i],j]
      ENDFOR
   ENDFOR
   
   ;; Account for energy loss
   enrg_amu_corr = enrg_amu*(mass_eloss/100.)

   ;; Account for TOF correction
   mass_tof_corr = sqrt(0.5*mass_amu*sci.atokg*$
                        tof.tof_flight_path^2/$
                        sci.evtoj/$
                        (enrg_amu_corr))/1e-9 - $
                   tof.tof_e_corr*1e9
   mass_table_2 = fix(elo * 0)

   FOR i=0, 127 DO BEGIN

      m0 = mean(mass_tof_corr[i,0:1])
      m1 = mean(mass_tof_corr[i,1:2])
      m2 = mean(mass_tof_corr[i,2:3])

      p0 = value_locate(tof.tof512_bnds, m0)
      IF (p0 MOD 2) THEN p0 = p0-1
      p1 = value_locate(tof.tof512_bnds, m1)
      IF (p1 MOD 2) THEN p1 = p1-1
      p2 = value_locate(tof.tof512_bnds, m2)
      IF (p2 MOD 2) THEN p2 = p2-1

      p0_range = [replicate(2,(p0-2)/2), replicate(3,(p0-2)/2) ]
      p1_range = [replicate(4,(p1-p0)/2),replicate(5,(p1-p0)/2)]
      p2_range = fix(interpol([ 6:32],$
                              findgen(27),$
                              findgen(p2-p1)/(p2-p1)*27))
      p3_range = [fix(interpol([33:63],$
                               findgen(31),$
                               findgen(511-p2)/(511-p2)*31)),63]

      mass_table_2[0:1,i]     = [0,1]
      mass_table_2[2:p0-1,i]  = p0_range
      mass_table_2[p0:p1-1,i] = p1_range
      mass_table_2[p1:p2-1,i] = p2_range
      mass_table_2[p2:511,i]  = p3_range

   ENDFOR

   mt2 = mass_table_2

   ;; 64 Mass Summation histogram
   mt2_sum = fltarr(128,64)
   FOR ii=0, 127 DO mt2_sum[ii,*] = $
    histogram(reform(mt2[*,ii]),$
              binsize=1,loc=loc)

   ;; TOF boundaries
   mt2_tof = fltarr(128,64)
   FOR ii=0, 127 DO BEGIN
      ind1 = 0
      FOR jj=0, 63 DO BEGIN
         ind2 = ind1+mt2_sum[ii,jj]
         ;;print, ind1, ind2-1, mt2_sum[ii,jj]
         mt2_tof[ii,jj] = $
          mean(tof.tof512_avgs[ind1:ind2-1])
         ind1 = ind2
      ENDFOR 
   ENDFOR

   ;; Structure
   tbl = {mt2:mt2,$
          mt2_sum:mt2_sum,$
          mt2_tof:mt2_tof,$
          mt2_mpq:mt2_tof}
   
END



;+
;; Write to File
;-
PRO spp_swp_spi_flight_mass_table_write, table, tbl_name

   openw, 1, '~/Desktop/'+tbl_name+'.txt'
   FOR i=0, 127 DO BEGIN
      FOR j=0, 511 DO BEGIN
         printf,1,format='(I2)',table[j,i]
      ENDFOR
   ENDFOR 
   close, 1

END



;+
;; Mass Range LUT
;-
PRO spp_swp_spi_flight_mass_range_table, table

   ;; MRLUT
   ;; 64 Element Array
   mrlut_2 = intarr(64)
   mrlut_2[0:1] = 4
   mrlut_2[2:3] = 0
   mrlut_2[4:5] = 1
   mrlut_2[p2_range[uniq(p2_range)]] = 2
   mrlut_2[p3_range[uniq(p3_range)]] = 3
   (*spi_param.mrlut_2) = mrlut_2
   table = mrlut_2

END



;+
;; Flight Mass Tables
;-
PRO spp_swp_spi_flight_mas, tbl, dac, sci, tof, elo

   ;; Get Mass Tables
   mass_table_default_arr = ishft(indgen(512),-3)
   ;;spp_swp_spi_flight_mas_0, mt0, dac, sci, tof, elo
   spp_swp_spi_flight_mas_1, mt1, dac, sci, tof, elo
   spp_swp_spi_flight_mas_2, mt2, dac, sci, tof, elo

   tbl = mt1

   ;;spp_swp_spi_checksum, mas=reform(transpose(mt1.mt1),512*128.)
   
   ;; WRITING TO FILE
   IF keyword_set(write_file) THEN BEGIN
      spp_swp_spi_flight_mass_table_write, mass_table, 'default'
      spp_swp_spi_flight_mass_table_write, mass_table_0, 'mlut0'
      spp_swp_spi_flight_mass_table_write, mass_table_1, 'mlut1'      
      spp_swp_spi_flight_mass_table_write, mass_table_2, 'mlut2'
   ENDIF 

   ;; PLOTTING
   IF keyword_set(plott) THEN BEGIN
      loadct2, 5
      mt1 = mass_table_1
      pp0 = where(mt1 GE   0 AND mt1 LE  15,cc0)
      pp1 = where(mt1 GE  16 AND mt1 LE  31,cc1)
      pp2 = where(mt1 GE  32 AND mt1 LE  47,cc2)
      pp3 = where(mt1 GE  48 AND mt1 LE  63,cc3)
      ;;pp4 = where(mt1 GE 33 AND mt1 LE 63,cc4)      
      ;;mt1[pp0] = 1.
      ;;mt1[pp1] = 2.
      ;;mt1[pp2] = 3.
      ;;mt1[pp3] = 4.
      ;;mt1[pp4] = 4.
      ;;mt1 = mt1/4. * 256.
      ;;contour, mt1, nlevel=4, /fill, xs=1,ys=1
      ;; Plotting 
      
      tt1=mean(mass_tof_corr[*,0:1],dimension=2)
      tt2=mean(mass_tof_corr[*,1:2],dimension=2)
      tt3=mean(mass_tof_corr[*,2:3],dimension=2)   
      
      loadct2, 34
      ;;oplot, transpose(mass_tof_corr[*,0]),indgen(128),color=250
      ;;oplot, transpose(mass_tof_corr[*,1]),indgen(128),color=250
      ;;oplot, transpose(mass_tof_corr[*,2]),indgen(128),color=250
      ;;oplot, transpose(mass_tof_corr[*,3]),indgen(128),color=250
   ENDIF

END
