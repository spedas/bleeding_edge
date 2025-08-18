;+
;
; ESC_IESA_FLIGHT_MAS
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 32782 $
; $LastChangedDate: 2024-08-06 17:41:17 -0700 (Tue, 06 Aug 2024) $
; $LastChangedBy: rlivi04 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_flight_mas.pro $
;
;-


;+
;;#####################################################
;;                   CHECKSUM CRC16
;;#####################################################
;-
;; CRC16 Checksum
;;   data -> byte array
FUNCTION esc_iesa_flight_mas_crc16, data
   
   init_crc = uint('FFFF'x)

   ;; Find Data Type
   dt = (size(data))[1+(size(data))[0]]

   ;; Turn data into byte array
   CASE dt OF
      1: databyte = data
      2: BEGIN
         a1 = byte(ishft(uint(data),-8))
         a2 = byte(uint(data) OR '0xFF')
         databyte = reform(transpose([[a1],[a2]]),n_elements(data)*2)
      END
      3: BEGIN
         a1 = byte(ishft(uint(data),-8))
         a2 = byte(uint(data) OR '0xFF')
         databyte = reform(transpose([[a1],[a2]]),n_elements(data)*2)
      END

      ELSE: stop, 'Must provide bytearr or uintarr.'
   ENDCASE
   
   
   ;; Byte Array
   ;;IF isa(data,'byte') THEN databyte = data
   
   ;; Convert uint to bytarr if necessary
   ;;IF isa(data, 'uint') THEN BEGIN 
   ;;   a1 = byte(ishft(uint(data),-8))
   ;;   a2 = byte(uint(data) OR '0xFF')
   ;;   databyte = reform(transpose([[a1],[a2]]),n_elements(data)*2)
   ;;ENDIF
   
   crc = init_crc
   FOR i=0, n_elements(databyte)-1 DO BEGIN

      ;;char = uint(data[i])
      char = databyte[i]
      crc = (ishft(crc,-8) AND 'FF'x) OR (ishft(crc,8) AND 'FFFF'x)
      crc = crc XOR char
      crc = crc XOR (ishft(crc AND 'FF'x,-4))
      crc = crc XOR (ishft(crc,12) AND 'F000'x)
      crc = crc XOR (ishft(crc AND 'FF'x,5))

   ENDFOR

   return, crc
   
END


;; Generate a CSV file with all of the values and constants
PRO esc_iesa_flight_mas_table_write, table



   ;; ####################################################
   ;; ###              iESA Main MLUT                  ###
   ;; ####################################################
   
   ;; Main directory for all files
   main_dir = '~/Desktop/esc_fm_mass_tables/'
   file_mkdir, main_dir

   ;; Write File
   openw, 1, main_dir + 'iesa_fm1_mlut_1.txt'
   printf, 1, '# ESCAPADE EESA Ion Calibrated Mass Look-Up Table'
   printf, 1, '# '
   printf, 1, '# Source:   spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_flight_mas.pro'
   printf, 1, '# Date:     $LastChangedDate: 2024-08-06 17:41:17 -0700 (Tue, 06 Aug 2024) $'
   printf, 1, '# Revision: $LastChangedRevision: 32782 $'
   printf, 1, '# '
   printf, 1, '# --- TRIM Simulation Results for a 1.0 ug/cm^2 Carbon Foil ---'
   printf, 1, format='(A26, 3I7, A6)', '# Mass/Charge    [amu/q]: ', table.sim_mass
   printf, 1, format='(A26, 7I7, A6)', '# Start Energies    [eV]: ', table.hse
   printf, 1, format='(A26, 7I7, A6)', '# Exit Energies H+  [eV]: ', table.hee
   printf, 1, format='(A26, 7I7, A6)', '# Exit Energies O+  [eV]: ', table.oee
   printf, 1, format='(A26, 7I7, A6)', '# Exit Energies Ar+ [eV]: ', table.aee
   printf, 1, '# '
   printf, 1, '# --- Curvefit Results of an exponential fit to TRIM simulations - a0*exp(energy*a1)+a2  ---'
   printf, 1, format='(A9, 3F11.6)', '# H+:    ', table.h_exp_val
   printf, 1, format='(A9, 3F11.6)', '# O+:    ', table.o_exp_val
   printf, 1, format='(A9, 3F11.6)', '# Ar+:   ', table.ar_exp_val   
   printf, 1, '# '
   printf, 1, '# --- CRC16 Checksums ---'
   printf, 1, format='(A14, Z04)',  '# MLUT 1:   0x', table.mlut_1_checksum
   printf, 1, '# '
   printf, 1, '# 6 Bit Values (256 x 64 Byte Array)'
   printf, 1, '# '+strjoin(replicate('-',32))
   FOR i=0, 63 DO FOR j=0, 255, 8 DO printf, 1, format='(8I4)', $
    table.mlut_1[i*256+j+0],table.mlut_1[i*256+j+1],table.mlut_1[i*256+j+2],table.mlut_1[i*256+j+3],$
    table.mlut_1[i*256+j+4],table.mlut_1[i*256+j+5],table.mlut_1[i*256+j+6],table.mlut_1[i*256+j+7]
   close, 1

   ;; Use the same file for FM2
   file_copy, main_dir + 'iesa_fm1_mlut_1.txt', main_dir + 'iesa_fm2_mlut_1.txt'

   ;; ####################################################
   ;; ###           iESA Evenly Spaced MLUT            ###
   ;; ####################################################

   ;; Write File
   openw, 1, main_dir + 'iesa_mlut_even.txt'   
   printf, 1, '# ESCAPADE EESA Ion Evenly Spaced Mass Look-Up Table'
   printf, 1, '# '
   printf, 1, '# Source:   spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_flight_mas.pro'
   printf, 1, '# Date:     $LastChangedDate: 2024-08-06 17:41:17 -0700 (Tue, 06 Aug 2024) $'
   printf, 1, '# Revision: $LastChangedRevision: 32782 $'
   printf, 1, '# '
   printf, 1, '# --- CRC16 Checksums ---'
   printf, 1, format='(A17, Z04)',  '# MLUT EVEN:   0x', table.mlut_even_checksum
   printf, 1, '# '
   printf, 1, '# 6 Bit Values (256 x 64 Byte Array)'
   printf, 1, '# '+strjoin(replicate('-',32))
   FOR i=0, 63 DO FOR j=0, 255, 8 DO printf, 1, format='(8I4)', $
    table.mlut_even[i*256+j+0],table.mlut_even[i*256+j+1],table.mlut_even[i*256+j+2],table.mlut_even[i*256+j+3],$
    table.mlut_even[i*256+j+4],table.mlut_even[i*256+j+5],table.mlut_even[i*256+j+6],table.mlut_even[i*256+j+7]
   close, 1



   ;; ####################################################
   ;; ###           iESA Evenly Spaced MLUT            ###
   ;; ####################################################

   ;; Write File
   openw, 1, main_dir + 'iesa_mlimlut_even.txt'   
   printf, 1, '# ESCAPADE EESA Ion Evenly Spaced Mass Limit Look-Up Table'
   printf, 1, '# '
   printf, 1, '# Source:   spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_flight_mas.pro'
   printf, 1, '# Date:     $LastChangedDate: 2024-08-06 17:41:17 -0700 (Tue, 06 Aug 2024) $'
   printf, 1, '# Revision: $LastChangedRevision: 32782 $'
   printf, 1, '# '
   printf, 1, '# --- CRC16 Checksums ---'
   printf, 1, format='(A20, Z04)',  '# MLIMLUT EVEN:   0x', table.mlimlut_even_checksum
   printf, 1, '# '
   printf, 1, '# 6 Bit Values (64 x 4 Byte Array)'
   printf, 1, '# '+strjoin(replicate('-',32))
   FOR i=0, 63 DO printf, 1, format='(4I4)', $
                          table.mlimlut_even[i*4+0], table.mlimlut_even[i*4+1],$
                          table.mlimlut_even[i*4+2], table.mlimlut_even[i*4+3]

   close, 1
   
   

END


;+
;;
;; Mass Limit Look-Up-Table
;; Evenly Spaced Limits
;;
;-
PRO spp_swp_spi_flight_mlim_lut_even, mlimlut, checksum

   ;; Create 4 boundaries across the 64 masses
   mlimlut = bytarr(64*4)

   ;; Evenly Spaced Limit Values
   limval = [ 16, 32, 48,  0]
   
   FOR k=0, 64-1 DO BEGIN

      mlimlut[k*4 + 0] = limval[0]
      mlimlut[k*4 + 1] = limval[1]
      mlimlut[k*4 + 2] = limval[2]
      mlimlut[k*4 + 3] = limval[3]
      
   ENDFOR

   ;; CRC16 Checksum
   checksum  = esc_iesa_flight_mas_crc16(mlimlut)
   
END



;+
;; Mass Look-Up-Table
;; Evenly spaced energy-mass conversion
;; 256 Sweep Steps - Compressed from 2048
;; 64 Energy Steps
;-
PRO spp_swp_spi_flight_mas_lut_even, mlut, checksum

   mlut = bytarr(256 * 64)
   FOR k=0, 64-1 DO BEGIN
      FOR n=0, 256-1, 2 DO BEGIN
         
         mlut[k*256 + n + 0] =  ishft(n,-2)
         mlut[k*256 + n + 1] =  ishft((n+1),-2)
         
      ENDFOR
   ENDFOR

   ;; CRC16 Checksum
   checksum  = esc_iesa_flight_mas_crc16(mlut)
   
END



;+
;;#####################################################
;;            Mass Table - ESCAPADE - iESA
;;#####################################################
;-
PRO esc_iesa_flight_mas, sci, tof, mas, $
                         verbose=verbose, $
                         plott=plott

   ;; The 6 MSB of the Hemisphere DAC converted into energy [eV]
   ev = sci.ev

   ;; Special M/Q Cases - Boundaries
   bnd = [ 1.55, 3.60, 26.00]
   mas_tbl_bnd = dblarr(256,64)
   
   ;; Special M/Q Cases - Higher Mass Ion
   minor_ions_mpq_names = [     'H+',  'He+',  'He2+',   'C4+',   'C5+', 'N 4+', $
                                'O5+',  'O6+',   'O7+',  'Ne7+',  'Mg8+', 'Mg9+', $ 
                                'Al10+', 'Si8+',  'Si9+', 'Si10+', 'Si11+',  'S9+', $
                                'Ca9+', 'Fe9+', 'Fe10+', 'Fe11+', 'Fe12+']

   minor_ions_mass = [    1.000,  4.003,  4.003, 12.011, 12.011, 14.007, $
                          15.999, 15.999, 15.999, 20.180, 24.305, 24.305, $
                          26.982, 28.086, 28.086, 28.086, 28.086, 32.067, $
                          40.078, 55.845, 55.845, 55.845, 55.845]

   minor_ions_charge = [ 1, 1, 2, 4, 5, 4,$
                         5, 6, 7, 7, 8, 9,$
                         10, 8, 9,10,11, 9,$
                         9, 9,10,11,12]
   
   ;; From TRIM 1.0 microgram/cm^2

   ;; Mass/Charge used in simulation
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

   ;; Percentage of  for of 1,16, and 40 
   hfit = (ah[0]*exp(ev*ah[1])+ah[2]) < 100.0
   ofit = (ao[0]*exp(ev*ao[1])+ao[2]) < 100.0
   afit = (ab[0]*exp(ev*ab[1])+ab[2]) < 100.0

   ;; Empty Array to store values
   eloss_matrix = fltarr(256, 64)
   tof_to_mpq   = fltarr(256, 64)

   mass256_ev = dblarr(256, 64)
   perc_loss_m64_ev = dblarr(64, 64)
   tof_bnd = dblarr(3,64)
   tof_spec = dblarr(64,64)
   tof_mim = dblarr(n_elements(minor_ions_mass),64)
   mlut_1 = dblarr(256,64)
   
   ;; Cycle through 64 energy bins
   FOR i=0, 64-1 DO BEGIN

      ;; Time it takes for 1,16, and 40 to
      ;; cross 2cm at ev[i] energy in a perfect
      ;; setting (no energy loss, no electron travel)
      tt = sqrt(0.5*mass*sci.atokg*tof.tof_flight_path^2 / sci.evtoj/ev[i])/1e-9

      ;; The percentage of energy loss for 1, 16, and 40
      ;; at energy ev[i]
      yy = [hfit[i], ofit[i], afit[i]]
      xx = mass


      
      ;; ------------- 64 Masses -------------------
      ;; Interpolate the energy loss to 64 M/Q units
      xx_new = indgen(64)+1
      perc_loss_m64 = interpol(yy, xx, xx_new) > 0 < 100
      perc_loss_m64_ev[*,i] = perc_loss_m64
      
      ;; Apply energy loss to current energy step ev[i] and
      ;; calculate new energies
      new_ev = ev[i] * (perc_loss_m64/100.D)
      
      ;; Calculate new TOF after applying energy loss and electron travel time
      new_tof = sqrt(0.5 * xx_new * sci.atokg * tof.tof_flight_path^2 / sci.evtoj/new_ev) / 1e-9 - $
                tof.tof_e_corr / 1e-9
      tof_spec[*,i] = new_tof
      
      ;; Generate TOF256 to M/Q Conversion
      mass256 = interpol(xx_new, new_tof, tof.tof256_mean) > 0
      mass256_ev[*,i] = mass256


      
      ;; ------------- Boundary Masses -------------------
      ;; Interpolate the energy loss to 64 M/Q units
      xx_new = bnd
      perc_loss_bnd = interpol(yy, xx, xx_new) > 0 < 100
      
      ;; Apply energy loss to current energy step ev[i] and
      ;; calculate new energies
      bnd_ev = ev[i] * (perc_loss_bnd/100.D)
      
      ;; Calculate new TOF after applying energy loss and electron travel time
      bnd_tof = sqrt(0.5 * xx_new * sci.atokg * tof.tof_flight_path^2 / sci.evtoj/new_ev) / 1e-9 - $
                tof.tof_e_corr / 1e-9
      tof_bnd[*,i] = bnd_tof

      ;; Create Mass Tables from Boundaries
      p0 = where(tof.tof256_mean LT bnd_tof[0],c1)
      p1 = where(tof.tof256_mean GE bnd_tof[0] AND tof.tof256_mean LT bnd_tof[1],c2)
      p2 = where(tof.tof256_mean GE bnd_tof[1] AND tof.tof256_mean LT bnd_tof[2],c3)
      p3 = where(tof.tof256_mean GE bnd_tof[2],c4)

      ;; Error check
      IF c1 LE 16 OR c2 LE 16 OR c3 LE 16 OR c4 LE 16 THEN stop
      mlut_1[p0,i] = round(findgen(c1)/c1 * 15)
      mlut_1[p1,i] = round(findgen(c2)/c2 * 15) + 16
      mlut_1[p2,i] = round(findgen(c3)/c3 * 15) + 32
      mlut_1[p3,i] = round(findgen(c4)/c4 * 15) + 48
      
      
      ;; ---------- Minor Ions Masses --------------
      ;; Interpolate the energy loss to 64 M/Q units
      xx_new = minor_ions_mass
      perc_loss_mim = interpol(yy, xx, xx_new) > 0 < 100
      
      ;; Apply energy loss to current energy step ev[i] and
      ;; calculate new energies
      mim_ev = ev[i] * (perc_loss_mim/100.D)
      
      ;; Calculate new TOF after applying energy loss and electron travel time
      mim_tof = sqrt(0.5 * (xx_new/minor_ions_charge) * sci.atokg * $
                     tof.tof_flight_path^2 / sci.evtoj/mim_ev) / 1e-9 - $
                tof.tof_e_corr / 1e-9
      tof_mim[*,i] = mim_tof

      

      ;; PLOT
      plott = 0
      IF keyword_set(plott) THEN BEGIN
         win, xsize=600,ysize=900
         !p.multi = [0,0,3]
         !P.CHARSIZE = 3
         xr1 = [0,65]
         plot,  xx_new, perc_loss_m64,  xs=1, yr=[0, 100], $
                ys=1, title=string(ev[i]),xr=xr1
         oplot, xx, yy,psym=1,symsize=2, color=250
         plot, xx_new, new_ev ,ys=1,xs=1,xr=xr1
         plot, xx_new, new_tof,ys=1,xs=1,xr=xr1,yr=[0,150]
         oplot, mass256, tof.tof256_mean, color=250, psym=1
         wait, 0.1
         !p.multi = 0
      ENDIF
      
   ENDFOR

   ;; Transform to bytearr and derive CRC16
   mlut_1 = byte(reform(mlut_1,256*64))
   mlut_1_checksum  = esc_iesa_flight_mas_crc16(mlut_1)
   
   ;; Mass LUT - Evenly Spaced Values
   spp_swp_spi_flight_mas_lut_even, mlut_even, mlut_even_checksum

   ;; Mass Limit LUT - Evenly Spaced Limit Values
   spp_swp_spi_flight_mlim_lut_even, mlimlut_even, mlimlut_even_checksum   
   
   ;; Final Structure
   mas = {mass256:mass256_ev,$
          sim_mass:mass,$
          mlut_1:mlut_1,$
          mlut_even:mlut_even,$
          mlimlut_even:mlimlut_even,$
          mlut_1_checksum:mlut_1_checksum,$
          mlut_even_checksum:mlut_even_checksum,$
          mlimlut_even_checksum:mlimlut_even_checksum,$
          title:'Mass Table',$
          note:'N/A',$
          hse:hse,$
          hee:hee,$
          oee:oee,$
          aee:aee,$
          h_exp_val:ah, $
          o_exp_val:ao, $
          ar_exp_val:ab }

   esc_iesa_flight_mas_table_write, mas
   
   
   
   ;;################
   ;;### Plotting ###
   ;;################

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

      ;;#######################################
      ;;#              PLOT 2                 #
      ;;#                                     #
      ;;#     Seconds due to energy loss      #
      ;;#######################################

      ;;#######################################
      ;;#              PLOT 3                 #
      ;;#                                     #
      ;;#         Energy Loss Matrix          #
      ;;#           Units of Bins             #
      ;;#######################################

      ;;#######################################
      ;;#              PLOT 4                 #
      ;;#                                     #
      ;;#         Energy Loss Matrix          #
      ;;#           Physical Units            #
      ;;#######################################

      !p.multi = 0

   ENDIF 

END
