;+
;
; ESC_IESA_SWEEP_TABLE
;
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2024-06-04 23:23:44 -0700 (Tue, 04 Jun 2024) $
; $LastChangedRevision: 32687 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_sweep_table.pro $
;
;-


;; CRC16 Checksum
;;   data -> byte array
FUNCTION esc_iesa_sweep_table_crc16, data
   
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



;; Plot Results
FUNCTION esc_iesa_sweep_table_plot, table

   ;; Window Options
   window,1,xsize=1200,ysize=900
   ;;popen, '~/Desktop/tmp',/landscape
   !P.CHARSIZE = 1.2
   !P.CHARTHICK = 1.2

   pss = -2
   xrr = [0,1024]
   yy = findgen(4)/3.*0.9+1*0.05
   xx = findgen(4)/3.*0.70+1*0.15
   p1 = [xx[0],yy[0],xx[1],yy[1]]
   p2 = [xx[0],yy[1],xx[1],yy[2]]
   p3 = [xx[0],yy[2],xx[1],yy[3]]
   p4 = [xx[2],yy[0],xx[3],yy[1]]
   p5 = [xx[2],yy[1],xx[3],yy[2]]
   p6 = [xx[2],yy[2],xx[3],yy[3]]
      
   ;; --- Hemisphere ---

   ;; Hemisphere Energies
   plot, table.hem_energy,xst=1,yst=3,yr=minmax(table.hem_energy),/nodata,pos=p3,$
         ytitle='Energies [eV]',/noerase,/ylog,xr=xrr,$
         xtickn=replicate(' ',7)
   oplot, table.hem_energy, psym=pss, color=50
   
   ;; Hemisphere Voltage
   plot, table.hem_volts,xst=1,yst=3,/ylog,yr=minmax(table.hem_volts),/nodata,pos=p2,$
         ytitle='Hemisphere [V]',/noerase,xr=xrr,$
         xtickn=replicate(' ',7)
   oplot, table.hem_volts, psym=pss, color=50

   ;; Hemipshere DACs
   plot, table.hem_dacs,xst=1,yst=3,/ylog,yr=minmax(table.hem_dacs),/nodata,pos=p1,$
         xtitle='ID Bin', ytitle='Hemisphere [DAC]',/noerase,xr=xrr
   oplot, table.hem_dacs, psym=pss, color=50

   ;; --- Deflectors ---

   ;; Deflector Angles
   plot, table.def1_angs,xst=1,yst=3,yr=[table.const.dmin,table.const.dmax],/nodata,pos=p6,$
         ytitle='Deflector [Degrees]',/noerase,$
         xtickn=replicate(' ',7),xr=xrr
   oplot, table.def1_angs,psym=pss, color=50
   oplot, table.def2_angs,psym=pss, color=250
   
   ;; Deflector Voltage
   plot, table.def1_volts>1e-5,xst=1,yst=3,$
         yr=minmax([table.def1_volts,table.def2_volts]),/nodata,pos=p5,$
         ytitle='Deflector [V]',/noerase,xr=xrr,$
         xtickn=replicate(' ',7)
   oplot, table.def1_volts>1e-5,psym=pss, color=50
   oplot, table.def2_volts>1e-5,psym=pss, color=250

   ;; Deflector DACs
   plot, table.def1_dacs,xst=1,yst=3,$
         yr=minmax([table.def1_dacs,table.def2_dacs]),/nodata,pos=p4,$
         xtitle='ID Bin', ytitle='Deflector DAC',/noerase,xr=xrr
   oplot, table.def1_dacs>0.1,psym=pss, color=50
   oplot, table.def2_dacs>0.1,psym=pss, color=250

   ;;pclose

END



;; Conversion of Deflector angles in degrees to Deflector DACs
FUNCTION esc_iesa_sweep_table_deflector_angle_to_dac, ang, poly_val

   ;; Polynomial Values
   p = double(poly_val)
   
   ;; Generate DACS
   ang_dac = p[0]+p[1]*ang+p[2]*ang^2+p[3]*ang^3+p[4]*ang^4+p[5]*ang^5
   
   RETURN, ang_dac

END



;; Generate a CSV file with all of the values and constants
FUNCTION esc_iesa_sweep_table_write, table, mram=mram

   ;; Set all keywords
   b1024_dac = 1
   b1024 = 1
   b512 = 1

   ;; Main directory for all files
   main_dir = '~/Desktop/esc_fm_sweep_tables/'
   file_mkdir, main_dir
   
   IF keyword_set(b1024) THEN BEGIN

      ;; Create Folder
      folder_dir = 'full/'
      file_mkdir, main_dir + folder_dir      
      openw, 1, main_dir + folder_dir + table.title + '_full.txt'
      printf, 1, '# ESCAPADE EESA Ion Sweep Table'
      printf, 1, '# '
      printf, 1, '# '+table.note
      printf, 1, '# '
      printf, 1, '# Source:   spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_sweep_table.pro'
      printf, 1, '# Date:     $LastChangedDate: 2024-06-04 23:23:44 -0700 (Tue, 04 Jun 2024) $'
      printf, 1, '# Revision: $LastChangedRevision: 32687 $'
      printf, 1, '# '
      printf, 1, '# --- Sweep Parameters ---'
      printf, 1, format='(A21, F7.1, A5)', '# Energy Min:         ', table.const.emin, ' [eV]'
      printf, 1, format='(A21, F7.1, A5)', '# Energy Max:         ', table.const.emax, ' [eV]'
      printf, 1, format='(A21, I7)',       '# Total Bins:         ', table.const.tot_bins
      printf, 1, format='(A21, I7)',       '# Microsteps:         ', table.const.mbins
      printf, 1, format='(A21, I7)',       '# Energy Steps:       ', table.const.nenr
      printf, 1, format='(A21, I7)',       '# Deflector Steps:    ', table.const.nang
      printf, 1, format='(A21, F7.2)',     '# Spoiler Ratio:      ', table.const.spl_ratio
      printf, 1, format='(A21, I7, A5)',   '# Spoiler Max Energy: ', table.const.spl_max_en, ' [eV]'
      printf, 1, '# '
      printf, 1, '# --- CRC16 Checksums ---'
      printf, 1, format='(A21, A3, Z04)',  '# Hemisphere:         '+' 0x', table.chk.hem
      printf, 1, format='(A21, A3, Z04)',  '# Deflector 1:        '+' 0x', table.chk.def1
      printf, 1, format='(A21, A3, Z04)',  '# Deflector 2:        '+' 0x', table.chk.def2
      printf, 1, format='(A21, A3, Z04)',  '# Spoiler:            '+' 0x', table.chk.spl
      printf, 1, '# '
      printf, 1, '# --- 5th Degree Polynomials for Deflectors ---'
      printf, 1, format='(A14)',        '# ' + table.const.poly
      printf, 1, format='(A5, F20.10)', '# P0:', table.const.poly_val[0]
      printf, 1, format='(A5, F20.10)', '# P1:', table.const.poly_val[1]
      printf, 1, format='(A5, F20.10)', '# P2:', table.const.poly_val[2]
      printf, 1, format='(A5, F20.10)', '# P3:', table.const.poly_val[3]
      printf, 1, format='(A5, F20.10)', '# P4:', table.const.poly_val[4]
      printf, 1, format='(A5, F20.10)', '# P5:', table.const.poly_val[5]
      printf, 1, '# '
      printf, 1, '# --- Instrument Characteristics ---'
      printf, 1, format='(A21, F7.2)',     '# K-Factor:           ', table.const.k
      printf, 1, format='(A21, F7.2)',     '# High Voltage Gain:  ', table.const.hv_gain
      printf, 1, format='(A21, F7.2)',     '# Deflector DAC Gain: ', table.const.def_gain
      printf, 1, format='(A21, F7.2)',     '# Spoiler Gain:       ', table.const.spl_gain
      printf, 1, '# '
      printf, 1, '# ID_Msg_Bin  ', $
              'ENERGY [eV]', 'DEF1 [DEG]','DEF2 [DEG]','SPOILER', $
              'HEM_BIN', 'DEF_BIN', $
              'HEM_DAC',   'DEF1_DAC',  'DEF2_DAC',  'SPL_DAC', $
              'HEM_VOLTS', 'DEF1_VOLTS','DEF2_VOLTS','SPL_VOLTS', $
              format='(16A14)'
      printf, 1, '# '+strjoin(replicate('-',14*16-12))
      FOR i=0l, 1023 DO BEGIN
         printf, 1, table.id_msg_bin[i], $
                 table.hem_energy[i], table.def1_angs[i], table.def2_angs[i], table.spl_rat[i], $
                 table.hem_bin[i], table.def_bin[i], $
                 table.hem_dacs[i],  table.def1_dacs[i],  table.def2_dacs[i],  table.spl_dacs[i],  $
                 table.hem_volts[i], table.def1_volts[i], table.def2_volts[i], table.spl_volts[i], $
                 format='(i14, 4F14.2, 2i14, 4I14, 4F14.2)'
      ENDFOR

      close, 1            
   ENDIF



   
   IF keyword_set(b1024_dac) THEN BEGIN

      folder_dir = 'full_dac/'
      file_mkdir, main_dir + folder_dir      
      openw, 1, main_dir + folder_dir + table.title + '_full_dac.txt'
      printf, 1, '# ESCAPADE EESA Ion Sweep Table'
      printf, 1, '# '
      printf, 1, '# '+table.note
      printf, 1, '# '
      printf, 1, '# Source:   spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_sweep_table.pro'
      printf, 1, '# Date:     $LastChangedDate: 2024-06-04 23:23:44 -0700 (Tue, 04 Jun 2024) $'
      printf, 1, '# Revision: $LastChangedRevision: 32687 $'
      printf, 1, '# '
      printf, 1, '# --- Sweep Parameters ---'
      printf, 1, format='(A21, F7.1, A5)', '# Energy Min:         ', table.const.emin, ' [eV]'
      printf, 1, format='(A21, F7.1, A5)', '# Energy Max:         ', table.const.emax, ' [eV]'
      printf, 1, format='(A21, I7)',       '# Total Bins:         ', table.const.tot_bins
      printf, 1, format='(A21, I7)',       '# Microsteps:         ', table.const.mbins
      printf, 1, format='(A21, I7)',       '# Energy Steps:       ', table.const.nenr
      printf, 1, format='(A21, I7)',       '# Deflector Steps:    ', table.const.nang
      printf, 1, format='(A21, F7.2)',     '# Spoiler Ratio:      ', table.const.spl_ratio
      printf, 1, format='(A21, I7, A5)',   '# Spoiler Max Energy: ', table.const.spl_max_en, ' [eV]'
      printf, 1, '# '
      printf, 1, '# --- CRC16 Checksums ---'
      printf, 1, format='(A21, A3, Z04)',  '# Hemisphere:         ',' 0x', table.chk.hem
      printf, 1, format='(A21, A3, Z04)',  '# Deflector 1:        ',' 0x', table.chk.def1
      printf, 1, format='(A21, A3, Z04)',  '# Deflector 2:        ',' 0x', table.chk.def2
      printf, 1, format='(A21, A3, Z04)',  '# Spoiler:            ',' 0x', table.chk.spl
      printf, 1, '# '
      printf, 1, '# --- 5th Degree Polynomials for Deflectors ---'
      printf, 1, format='(A14)',        '# ' + table.const.poly      
      printf, 1, format='(A5, F20.10)', '# P0:', table.const.poly_val[0]
      printf, 1, format='(A5, F20.10)', '# P1:', table.const.poly_val[1]
      printf, 1, format='(A5, F20.10)', '# P2:', table.const.poly_val[2]
      printf, 1, format='(A5, F20.10)', '# P3:', table.const.poly_val[3]
      printf, 1, format='(A5, F20.10)', '# P4:', table.const.poly_val[4]
      printf, 1, format='(A5, F20.10)', '# P5:', table.const.poly_val[5]
      printf, 1, '# '
      printf, 1, '# --- Instrument Characteristics ---'
      printf, 1, format='(A21, F7.2)',     '# K-Factor:           ', table.const.k
      printf, 1, format='(A21, F7.2)',     '# High Voltage Gain:  ', table.const.hv_gain
      printf, 1, format='(A21, F7.2)',     '# Deflector DAC Gain: ', table.const.def_gain
      printf, 1, format='(A21, F7.2)',     '# Spoiler Gain:       ', table.const.spl_gain
      printf, 1, '# '
      printf, 1, '# ','HEM_DAC', 'DEF1_DAC','DEF2_DAC','SPOILER_DAC', format='(A2,A12,3A14)'
      printf, 1, '# '+strjoin(replicate('-',14*4-2))
      FOR i=0l, 1023 DO BEGIN
         printf, 1, table.hem_dacs[i], table.def1_dacs[i], table.def2_dacs[i], table.spl_dacs[i],$
                 format='(4i14)'
      ENDFOR

      close, 1

   ENDIF


   
   IF keyword_set(b512) THEN BEGIN

      folder_dir = 'sci/'
      file_mkdir, main_dir + folder_dir      
      openw, 1, main_dir + folder_dir + table.title + '.txt'
      ;;openw, 1,'~/Desktop/'+table.title+'.txt'
      printf, 1, '# ESCAPADE EESA Ion Sweep Table'
      printf, 1, '# '
      printf, 1, '# '+table.note
      printf, 1, '# '
      printf, 1, '# Source:   spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_sweep_table.pro'
      printf, 1, '# Date:     $LastChangedDate: 2024-06-04 23:23:44 -0700 (Tue, 04 Jun 2024) $'
      printf, 1, '# Revision: $LastChangedRevision: 32687 $'
      printf, 1, '# '
      printf, 1, '# --- Sweep Parameters ---'
      printf, 1, format='(A21, F7.1, A5)', '# Energy Min:         ', table.const.emin, ' [eV]'
      printf, 1, format='(A21, F7.1, A5)', '# Energy Max:         ', table.const.emax, ' [eV]'
      printf, 1, format='(A21, I7)',       '# Total Bins:         ', table.const.tot_bins
      printf, 1, format='(A21, I7)',       '# Microsteps:         ', table.const.mbins
      printf, 1, format='(A21, I7)',       '# Energy Steps:       ', table.const.nenr
      printf, 1, format='(A21, I7)',       '# Deflector Steps:    ', table.const.nang
      printf, 1, format='(A21, F7.2)',     '# Spoiler Ratio:      ', table.const.spl_ratio
      printf, 1, format='(A21, I7, A5)',   '# Spoiler Max Energy: ', table.const.spl_max_en, ' [eV]'
      printf, 1, '# '
      printf, 1, '# --- CRC16 Checksums ---'
      printf, 1, format='(A21, A3, Z04)',  '# Hemisphere:         ',' 0x', table.chk.hem
      printf, 1, format='(A21, A3, Z04)',  '# Deflector 1:        ',' 0x', table.chk.def1
      printf, 1, format='(A21, A3, Z04)',  '# Deflector 2:        ',' 0x', table.chk.def2
      printf, 1, format='(A21, A3, Z04)',  '# Spoiler:            ',' 0x', table.chk.spl
      printf, 1, '# '
      printf, 1, '# --- 5th Degree Polynomials for Deflectors ---'
      printf, 1, format='(A14)',        '# ' + table.const.poly      
      printf, 1, format='(A5, F20.10)', '# P0:', table.const.poly_val[0]
      printf, 1, format='(A5, F20.10)', '# P1:', table.const.poly_val[1]
      printf, 1, format='(A5, F20.10)', '# P2:', table.const.poly_val[2]
      printf, 1, format='(A5, F20.10)', '# P3:', table.const.poly_val[3]
      printf, 1, format='(A5, F20.10)', '# P4:', table.const.poly_val[4]
      printf, 1, format='(A5, F20.10)', '# P5:', table.const.poly_val[5]
      printf, 1, '# '
      printf, 1, '# --- Instrument Characteristics ---'
      printf, 1, format='(A21, F7.2)',      '# K-Factor:           ', table.const.k
      printf, 1, format='(A21, F7.2)',      '# High Voltage Gain:  ', table.const.hv_gain
      printf, 1, format='(A21, F7.2)',      '# Deflector DAC Gain: ', table.const.def_gain
      printf, 1, format='(A21, F7.2)',      '# Spoiler Gain:       ', table.const.spl_gain
      printf, 1, '# '
      printf, 1, '# ','Science Bin', $
              'Energy Bin', 'ENERGY [eV]', 'dEnergy',$
              'Def. Bin', 'DEF [DEG]', 'dTheta', 'SPOILER', $
              format='(A2,A12,9A14)'
      printf, 1, strjoin(replicate('-',14*8))
      FOR i=0l, 511 DO BEGIN
         printf, 1, table.sci_bin[i], $
                 table.sci_hem_bin[i], table.sci_hem_energy[i], table.sci_hem_denergy[i],$
                 table.sci_def_bin[i], table.sci_def_angs[i], table.sci_def_dtheta[i],$
                 table.sci_spl_rat[i], $
                 format='(i14, i14, 2F14.1, i14, 2F14.1, F14.2)'
      ENDFOR

      close, 1      
   ENDIF
   
   
END



;; Generate DACs, voltages, and scientific values based on instrument parameters and operations
PRO esc_iesa_sweep_table_generate, table, emin=emin, emax=emax, title=title, $
                                   note=note, dmin=dmin,dmax=dmax, spl_ratio=spl_ratio,$
                                   poly=poly

   ;; ### ESCAPADE EESA-I CONSTANTS ###

   ;; Analyzer Constant
   k = 7.8

   ;; Deflector DAC Gain Relative to Hemisphere DAC
   def_gain = 8.

   ;; High Voltage Multiplier (for both Hemisphere and Deflectors)
   hv_gain = 1000

   ;; Spoiler Gain
   spl_gain = 20.12

   ;; Energy DeltaE/E (%)
   denergy = 16.7

   ;; Deflection Delta FWHM (ANG)
   dtheta = 6.
   
   ;; Maximum Voltage on Deflectors
   def_max_volts = 4000.

   ;; Microsteps
   mbins = 2
      
   ;; Hemisphere Steps
   nenr = 64

   ;; Total Deflector Steps
   nang = 16
   
   ;; Total Voltage Steps
   tot_bins = nenr * nang

   ;; Minimum Ion energy in eV
   IF ~isa(emin) THEN emin = 0.1

   ;; Maximum Ion energy in eV
   IF ~isa(emax) THEN emax = 30000.

   ;; Maximum Deflection in Degrees
   IF ~isa(dmax) THEN dmax = 45.

   ;; Minimum Deflection in Degrees
   IF ~isa(dmin) THEN dmin = -45.   
   
   ;; Maximum Ion Energy in eV for spoiler (Cut-Off) 
   spl_max_en = 5000.

   ;; Spoiler Voltage Voltage Ratio between Spoiler/Hemisphere
   IF ~isa(spl_ratio) THEN spl_ratio = 0.25

   ;; Deflector Angle Resolution and Binning
   def_res = 1000.
   angles = (lindgen((dmax-dmin)*def_res+1) + (dmin * def_res))/def_res

   ;; Title
   IF ~keyword_set(title) THEN title = 'esc_template'

   ;; Additional Notes
   IF ~keyword_set(note) THEN note = 'esc_template'

   ;; 5th Degree Polynomial Values
   IF ~keyword_set(poly) THEN poly = 'HERMES'
   
   ;; PSP SPAN-Ion Calibration
   IF poly EQ 'PSP' THEN $
    poly_val = [ -6.6967358589, 1118.9683837891, 0.5826185942, -0.0928234607, 0.0000374681, 0.0000016514]

   ;; HERMES SPAN-I Calibration - 2023-01-06
   IF poly EQ 'HERMES' THEN $
    poly_val = [ -0.231661,     -807.011,       -1.48519,      -0.0246793,    0.000165991,  1.84911e-05 ]

   ;; ESCAPADE iESA FM1 Calibration - 2023-06-23
   IF poly EQ 'ESC_iESA_FM1' THEN $
    poly_val = [ -525.2822265625, -1231.6815185547, 0.1745962799, 0.1081047505,  0.0000314365, -0.0000239858]

   ;; ESCAPADE iESA FM2 Calibration - 2023-09-13/21:00:00
   IF poly EQ 'ESC_iESA_FM2' THEN $
    poly_val = [ -289.7713928223, -1304.4713134766, 1.4805048704, 0.1967162639, -0.0008549984, -0.0000669929]

   
   ;; ESCAPADE iESA FM2 Calibration
   ;;IF poly EQ 'ESC_FM2_B' THEN $
   ;; poly_val = [ ]

   ;; ESCAPADE iESA FM2 Calibration - 0.5eV to 400 eV - with spoiler - 2023-XX-XX
   ;;IF poly EQ 'ESC_FM2_C' THEN $
   ;; poly_val = [ ]

   ;;##################
   ;;### Hemisphere ###
   ;;##################
   
   ;; Hemisphere Individual Voltages
   exp = (emax/emin)^(1.0/(nenr-1))
   hem_volt = emin/k * (exp)^findgen(nenr) 
   
   ;; Hemisphere Bin Steps
   hem_bin = reverse(reform(transpose(rebin(indgen(nenr),nenr,nang)),tot_bins))

   ;; Hemisphere Sweep [V]
   hem_volts = hem_volt[hem_bin]

   ;; Hemisphere Energy (Scientific Units [eV])
   hem_energy = hem_volts * k

   ;; Double DAC Hemisphere Values (Same value for both DACs, hence sqrt())
   hem_dacs = round(sqrt(long64('ffff'x)^2 * hem_volts / (4 * hv_gain)))
   
   ;; ### Hemisphere Science Product Values ###
   sci_hem_bin = reverse(indgen(nenr))
   sci_hem_bin = reform(transpose(rebin(sci_hem_bin,nenr,tot_bins/nenr/mbins)),tot_bins/mbins)
   sci_hem_energy = mean(reform(hem_energy,mbins,tot_bins/mbins),dim=1)
   sci_hem_denergy = sci_hem_energy * denergy/100.



   ;;##################
   ;;### Deflectors ###
   ;;##################

   ;; Deflector Angle to DAC
   ang_dac = esc_iesa_sweep_table_deflector_angle_to_dac(angles, poly_val)

   ;; Defletor Binning
   dbins = lindgen(nang)
   
   ;; Deflector Bin Steps
   def_bin = reform(rebin([dbins, reverse(dbins)],nang*2,tot_bins/(nang*2)),tot_bins)

   ;; Deflector Conversion to angles
   def_angs = (def_bin) * (dmax-dmin)/ (nang-1) + dmin
   
   ;; Deflector DACs
   ang_loc = value_locate(angles, def_angs)
   def_dacs = long(ang_dac[ang_loc])

   ;; Assign Deflectors
   def1_dacs =     def_dacs > 0
   def2_dacs = ABS(def_dacs < 0)
   
   ;;### Adjust For Maximum Deflector Voltage ###
   def1_volts_tmp = hem_volts * def_gain * (1.*def1_dacs / 'ffff'x)
   def2_volts_tmp = hem_volts * def_gain * (1.*def2_dacs / 'ffff'x)

   def1_max = max(reform(def1_dacs,nang,tot_bins/nang),dim=1)
   def2_max = max(reform(def2_dacs,nang,tot_bins/nang),dim=1)
   
   def1_tmp = min((def_max_volts / reform(def1_volts_tmp,nang,tot_bins/nang)) < 1,dim=1)
   def2_tmp = min((def_max_volts / reform(def2_volts_tmp,nang,tot_bins/nang)) < 1,dim=1)

   def1_fac = reform(transpose(rebin(def1_tmp,tot_bins/nang,nang)),tot_bins)
   def2_fac = reform(transpose(rebin(def2_tmp,tot_bins/nang,nang)),tot_bins)

   ;; ### Final Deflector Values ###

   ;; Deflector DACs
   def1_dacs = long(def1_dacs * def1_fac)
   def2_dacs = long(def2_dacs * def2_fac)

   ;; Deflector Angles
   def1_angs = angles[value_locate(ang_dac,  def1_dacs)]
   def2_angs = angles[value_locate(ang_dac, -def2_dacs)]

   ;; Fix angle to 0 when DAC is 0
   def1_angs[where(def1_dacs EQ 0)] =  0
   def2_angs[where(def2_dacs EQ 0)] =  0
   
   ;; Deflector Voltages
   def1_volts = (1.*def1_dacs/'ffff'x) * def_gain * hem_volts
   def2_volts = (1.*def2_dacs/'ffff'x) * def_gain * hem_volts

   ;; ### Deflector Science Product Values ###
   sci_def_bin = [reverse(indgen(nang/2)),indgen(nang/2)]
   sci_def_bin = reform(rebin(sci_def_bin,nang,tot_bins/mbins/nang),tot_bins/mbins)
   sci_def1_angs = mean(reform(def1_angs,mbins,tot_bins/mbins),dim=1)
   sci_def2_angs = mean(reform(def2_angs,mbins,tot_bins/mbins),dim=1)
   sci_def_angs = sci_def1_angs + sci_def2_angs

   ;; ### Deflector Theta ###
   tmp1 = reform(def1_angs,mbins,tot_bins/mbins)
   tmp2 = reform(def2_angs,mbins,tot_bins/mbins)
   tmp1 = reform(dtheta + ABS(tmp1[0,*]-tmp1[1,*]))
   tmp2 = reform(dtheta + ABS(tmp2[0,*]-tmp2[1,*]))
   sci_def_dtheta = tmp1 > tmp2


   
   ;;###############
   ;;### Spoiler ###
   ;;###############
   
   spl_rat = spl_ratio < ((4.*spl_gain) / hem_volts)
   spl_ind = where(hem_volts GT (spl_max_en/k),cc)
   IF cc GT 0 THEN spl_rat[spl_ind] = 0.
   spl_dacs = long(1.*'ffff'x * spl_rat * hem_volts/(4*spl_gain))
   spl_volts = long((1.*spl_dacs/'ffff'x) * 4 * spl_gain)

   ;; ### Spoiler Science Products ###
   sci_spl_rat = mean(reform(spl_rat,mbins,tot_bins/mbins),dim=1)

   ;; ################
   ;; ### Checksum ###
   ;; ################

   hem_chk  = esc_iesa_sweep_table_crc16(hem_dacs)
   def1_chk = esc_iesa_sweep_table_crc16(def1_dacs)
   def2_chk = esc_iesa_sweep_table_crc16(def2_dacs)
   spl_chk  = esc_iesa_sweep_table_crc16(spl_dacs)

   ;; Assemble Structure
   table = {$

           ;; Table Information
           title:title,$
           note:note,$
           
           ;; Constants
           const:{k:k, $
                  def_max_volts:def_max_volts, $
                  dmax:dmax, $
                  dmin:dmin, $
                  tot_bins:tot_bins,$
                  mbins:mbins,$
                  nenr:nenr,$
                  nang:nang,$
                  emin:emin,$
                  emax:emax,$
                  hv_gain:hv_gain,$
                  def_gain:def_gain,$
                  spl_gain:spl_gain,$          
                  spl_max_en:spl_max_en,$
                  spl_ratio:spl_ratio,$
                  poly:poly,$
                  poly_val:poly_val},$
           
           ;; Bins
           id_msg_bin:indgen(1024),$
           hem_bin:hem_bin, $ 
           def_bin:def_bin,$

           ;; Science Bins
           sci_bin:indgen(tot_bins/mbins),$
           sci_hem_bin:sci_hem_bin,$
           sci_hem_energy:sci_hem_energy,$
           sci_def_bin:sci_def_bin,$
           sci_def_angs:sci_def_angs,$
           sci_spl_rat:sci_spl_rat,$
           sci_def_dtheta:sci_def_dtheta,$
           sci_hem_denergy:sci_hem_denergy,$
           
           
           ;; Scientific Unit Values
           hem_energy:hem_energy,$
           def1_angs:def1_angs,$
           def2_angs:def2_angs,$
           spl_rat:spl_rat,$
           
           ;; Voltage Values
           hem_volts:hem_volts,$
           def1_volts:def1_volts,$
           def2_volts:def2_volts,$
           spl_volts:spl_volts,$

           ;; DAC Values
           hem_dacs:hem_dacs,$
           def1_dacs:def1_dacs,$
           def2_dacs:def2_dacs,$
           spl_dacs:spl_dacs, $

           ;; CRC16 Checksum of DAC Tables
           chk:{hem:hem_chk,$
                def1:def1_chk,$           
                def2:def2_chk,$
                spl:spl_chk} $
           }

   ;; Write Table to CSV
   write_csv = 1
   IF keyword_set(write_csv) THEN tmp = esc_iesa_sweep_table_write(table)

   ;; Plot table contents
   pplot = 0
   IF keyword_set(pplot) THEN plot_res = esc_iesa_sweep_table_plot(table)

END



;; #######################################
;; ################ MAIN #################
;; #######################################

;; Based on Instrument Data Allocations [22-10-03]

PRO esc_iesa_sweep_table, tables




   esc_iesa_crs = 1
   esc_iesa_fm1 = 1
   esc_iesa_fm2 = 1
   esc_iesa_cal = 0



   
   ;; ##################
   ;; ###   CRUISE   ###
   ;; ##################
   
   IF esc_iesa_crs THEN BEGIN   

      ;; iESA - FM1 - Blue - Cruise Table (2kV limit on RAW)
      emin = 100.
      emax = 2450.
      spl_ratio = 0.5      
      poly = 'ESC_iESA_FM1'
      title = 'esc_iesa_fm1_sweep_cruise'
      note = 'Cruise - Solar Wind Sweep - Log - FM1'      
      esc_iesa_sweep_table_generate, ts0_fm1_cruise, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Cruise Table (2kV limit on RAW) - No Spoiler
      emin = 100.
      emax = 2450.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM1'
      title = 'esc_iesa_fm1_sweep_cruise_ns'
      note = 'Cruise - Solar Wind Sweep - Log - FM1 - No Spoiler'      
      esc_iesa_sweep_table_generate, ts0_fm1_cruise, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly
      
      ;; iESA - FM2 - Blue - Cruise Table (2kV limit on RAW)
      emin = 100.
      emax = 2450.
      spl_ratio = 0.5      
      poly = 'ESC_iESA_FM2'
      title = 'esc_iesa_fm2_sweep_cruise'
      note = 'Cruise - Solar Wind Sweep - Log - FM2'
      esc_iesa_sweep_table_generate, ts0_fm2_cruise, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Blue - Cruise Table (2kV limit on RAW) - No Spoiler
      emin = 100.
      emax = 2450.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM2'
      title = 'esc_iesa_fm2_sweep_cruise_ns'
      note = 'Cruise - Solar Wind Sweep - Log - FM2 - No Spoiler'
      esc_iesa_sweep_table_generate, ts0_fm2_cruise, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly
      
   ENDIF

   

   ;; ##########################
   ;; ###   SCIENCE TABLES   ###
   ;; ##########################

   IF esc_iesa_fm1 THEN BEGIN      
      
      ;; iESA - FM1 - Blue - Science Sweep Table 1
      emin = 1.5
      emax = 25209.
      spl_ratio = 0.5      
      poly = 'ESC_iESA_FM1'
      title = 'esc_iesa_fm1_sweep_sci_1'
      note = 'Science Sweep 1 - Above 1000km - Regular Apoapsis - Log - dE/E 16.7'
      esc_iesa_sweep_table_generate, ts1, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Science Sweep Table 2      
      emin = 200.
      emax = 30000.
      spl_ratio = 0.5
      poly = 'ESC_iESA_FM1'      
      title = 'esc_iesa_fm1_sweep_sci_2'
      note = 'Science Sweep 2 - Above 1000km - Solar Wind - Log'
      esc_iesa_sweep_table_generate, ts2, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Science Sweep Table 3            
      emin = 0.5
      emax = 4000.
      spl_ratio = 0.5
      poly = 'ESC_iESA_FM1'
      title = 'esc_iesa_fm1_sweep_sci_3'      
      note = 'Science Sweep 3 - Below 1000km - Regular - Log'
      esc_iesa_sweep_table_generate, ts3, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Science Sweep Table 4            
      emin = 0.5
      emax = 450.
      spl_ratio = 0.5
      poly = 'ESC_iESA_FM1'
      title = 'esc_iesa_fm1_sweep_sci_4'      
      note = 'Science Sweep 4 - Below 1000km - Cold Ion Outflow - Log'
      esc_iesa_sweep_table_generate, ts4, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Science Sweep Table 5            
      emin = 1
      emax = 10.
      spl_ratio = 0.5
      poly = 'ESC_iESA_FM1'
      title = 'esc_iesa_fm1_sweep_sci_5'      
      note = 'Science Sweep 5 - Below 1000km - Wind Mode - Log'
      esc_iesa_sweep_table_generate, ts5, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Science Sweep Table 6      
      emin = 0.5
      emax = 100.
      spl_ratio = 0.5
      poly = 'ESC_iESA_FM1'      
      title = 'esc_iesa_fm1_sweep_sci_6'
      note = 'Science Sweep 6 - Below 1000km - Backup - Log'
      esc_iesa_sweep_table_generate, ts6, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly


      
      ;; --- Flight Tables without Spoiler ---



      ;; iESA - FM1 - Blue - Science Sweep Table 1 - Np Spoiler
      emin = 1.5
      emax = 25209.
      spl_ratio = 0.0      
      poly = 'ESC_iESA_FM1'
      title = 'esc_iesa_fm1_sweep_sci_1_ns'
      note = 'Science Sweep 1 - Above 1000km - Regular Apoapsis - Log - dE/E 16.7 - No Spoiler'
      esc_iesa_sweep_table_generate, ts1_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Science Sweep Table 2 - Np Spoiler
      emin = 200.
      emax = 30000.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM1'      
      title = 'esc_iesa_fm1_sweep_sci_2_ns'
      note = 'Science Sweep 2 - Above 1000km - Solar Wind - Log - No Spoiler'
      esc_iesa_sweep_table_generate, ts2_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Science Sweep Table 3 - Np Spoiler
      emin = 0.5
      emax = 4000.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM1'
      title = 'esc_iesa_fm1_sweep_sci_3_ns'      
      note = 'Science Sweep 3 - Below 1000km - Regular - Log - No Spoiler'
      esc_iesa_sweep_table_generate, ts3_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Science Sweep Table 4 - Np Spoiler
      emin = 0.5
      emax = 450.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM1'
      title = 'esc_iesa_fm1_sweep_sci_4_ns'      
      note = 'Science Sweep 4 - Below 1000km - Cold Ion Outflow - Log - No Spoiler'
      esc_iesa_sweep_table_generate, ts4_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Science Sweep Table 5 - Np Spoiler
      emin = 1
      emax = 10.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM1'
      title = 'esc_iesa_fm1_sweep_sci_5_ns'      
      note = 'Science Sweep 5 - Below 1000km - Wind Mode - Log - No Spoiler'
      esc_iesa_sweep_table_generate, ts5_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM1 - Blue - Science Sweep Table 6 - Np Spoiler
      emin = 0.5
      emax = 100.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM1'      
      title = 'esc_iesa_fm1_sweep_sci_6_ns'
      note = 'Science Sweep 6 - Below 1000km - Backup - Log - No Spoiler'
      esc_iesa_sweep_table_generate, ts6_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      iesa_fm1_tables = { ts1:ts1, ts1_ns:ts1_ns, ts2:ts2, ts2_ns:ts2_ns, $
                          ts3:ts3, ts3_ns:ts3_ns, ts4:ts4, ts4_ns:ts4_ns, $
                          ts5:ts5, ts5_ns:ts5_ns}
      
   ENDIF



   IF esc_iesa_fm2 THEN BEGIN      
      
      ;; iESA - FM2 - Gold - Science Sweep Table 1
      emin = 1.5
      emax = 25209.
      spl_ratio = 0.5      
      poly = 'ESC_iESA_FM2'
      title = 'esc_iesa_fm2_sweep_sci_1'
      note = 'Science Sweep 1 - Above 1000km - Regular Apoapsis - Log - dE/E 16.7'
      esc_iesa_sweep_table_generate, ts1, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Gold - Science Sweep Table 2      
      emin = 200.
      emax = 30000.
      spl_ratio = 0.5
      poly = 'ESC_iESA_FM2'      
      title = 'esc_iesa_fm2_sweep_sci_2'
      note = 'Science Sweep 2 - Above 1000km - Solar Wind - Log'
      esc_iesa_sweep_table_generate, ts2, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Gold - Science Sweep Table 3            
      emin = 0.5
      emax = 4000.
      spl_ratio = 0.5
      poly = 'ESC_iESA_FM2'
      title = 'esc_iesa_fm2_sweep_sci_3'      
      note = 'Science Sweep 3 - Below 1000km - Regular - Log'
      esc_iesa_sweep_table_generate, ts3, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Gold - Science Sweep Table 4            
      emin = 0.5
      emax = 450.
      spl_ratio = 0.5
      poly = 'ESC_iESA_FM2'
      title = 'esc_iesa_fm2_sweep_sci_4'      
      note = 'Science Sweep 4 - Below 1000km - Cold Ion Outflow - Log'
      esc_iesa_sweep_table_generate, ts4, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Gold - Science Sweep Table 5            
      emin = 1
      emax = 10.
      spl_ratio = 0.5
      poly = 'ESC_iESA_FM2'
      title = 'esc_iesa_fm2_sweep_sci_5'      
      note = 'Science Sweep 5 - Below 1000km - Wind Mode - Log'
      esc_iesa_sweep_table_generate, ts5, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Gold - Science Sweep Table 6      
      emin = 0.5
      emax = 100.
      spl_ratio = 0.5
      poly = 'ESC_iESA_FM2'      
      title = 'esc_iesa_fm2_sweep_sci_6'
      note = 'Science Sweep 6 - Below 1000km - Backup - Log'
      esc_iesa_sweep_table_generate, ts6, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly


      
      ;; --- Flight Tables without Spoiler ---



      ;; iESA - FM2 - Gold - Science Sweep Table 1 - Np Spoiler
      emin = 1.5
      emax = 25209.
      spl_ratio = 0.0      
      poly = 'ESC_iESA_FM2'
      title = 'esc_iesa_fm2_sweep_sci_1_ns'
      note = 'Science Sweep 1 - Above 1000km - Regular Apoapsis - Log - dE/E 16.7 - No Spoiler'
      esc_iesa_sweep_table_generate, ts1_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Gold - Science Sweep Table 2 - Np Spoiler
      emin = 200.
      emax = 30000.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM2'      
      title = 'esc_iesa_fm2_sweep_sci_2_ns'
      note = 'Science Sweep 2 - Above 1000km - Solar Wind - Log - No Spoiler'
      esc_iesa_sweep_table_generate, ts2_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Gold - Science Sweep Table 3 - Np Spoiler
      emin = 0.5
      emax = 4000.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM2'
      title = 'esc_iesa_fm2_sweep_sci_3_ns'      
      note = 'Science Sweep 3 - Below 1000km - Regular - Log - No Spoiler'
      esc_iesa_sweep_table_generate, ts3_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Gold - Science Sweep Table 4 - Np Spoiler
      emin = 0.5
      emax = 450.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM2'
      title = 'esc_iesa_fm2_sweep_sci_4_ns'      
      note = 'Science Sweep 4 - Below 1000km - Cold Ion Outflow - Log - No Spoiler'
      esc_iesa_sweep_table_generate, ts4_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Gold - Science Sweep Table 5 - Np Spoiler
      emin = 1
      emax = 10.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM2'
      title = 'esc_iesa_fm2_sweep_sci_5_ns'      
      note = 'Science Sweep 5 - Below 1000km - Wind Mode - Log - No Spoiler'
      esc_iesa_sweep_table_generate, ts5_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      ;; iESA - FM2 - Gold - Science Sweep Table 6 - Np Spoiler
      emin = 0.5
      emax = 100.
      spl_ratio = 0.0
      poly = 'ESC_iESA_FM2'      
      title = 'esc_iesa_fm2_sweep_sci_6_ns'
      note = 'Science Sweep 6 - Below 1000km - Backup - Log - No Spoiler'
      esc_iesa_sweep_table_generate, ts6_ns, emin=emin,emax=emax,title=title,note=note,spl_ratio=spl_ratio, poly=poly

      iesa_fm2_tables = { ts1:ts1, ts1_ns:ts1_ns, ts2:ts2, ts2_ns:ts2_ns, $
                          ts3:ts3, ts3_ns:ts3_ns, ts4:ts4, ts4_ns:ts4_ns, $
                          ts5:ts5, ts5_ns:ts5_ns}
      
   ENDIF



   












   



   

   IF esc_iesa_cal THEN BEGIN 

      ;; --- CALIBRATION TABLES ---
      
      ;; EESA-i Calibration Table 1 --- Energies 400eV - 600eV --- Deflections -15 to +15 --- Spoiler Ratio 0.25
      emin = 400.
      emax = 600.
      dmin = -15.
      dmax =  15.
      spl_ratio = 0.25
      title = 'esc_iesa_cal_table_1'
      note = 'Calibration Table 1: 400eV to 600eV - -15 to 15 - 0.25 SPL Ratio'
      esc_iesa_sweep_table_generate, tc1, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 2 --- Energies 0.5eV - 60eV --- Deflections -15 to +15 --- Spoiler Ratio 0.25
      emin = 0.5
      emax = 60.
      dmin = -15.
      dmax =  15.
      spl_ratio = 0.25
      title = 'esc_iesa_cal_table_2'
      note = 'Calibration Table 2: 0.5eV - 60eV - -15 to 15 - 0.25 SPL Ratio'
      esc_iesa_sweep_table_generate, tc2, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 3 - 800eV - 1200eV
      emin =  800.
      emax = 1200.
      dmin = -15.
      dmax =  15.
      spl_ratio = 0.25
      title = 'esc_iesa_cal_table_3'
      note = 'Calibration Table 3: 800eV - 1200eV - -15 to 15 - 0.25 SPL Ratio'
      esc_iesa_sweep_table_generate, tc3, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 4 --- Energies 400eV - 600eV --- Deflections -45 - 45 --- Spoiler Ratio 0.25
      emin = 400.
      emax = 600.
      dmin = -45.
      dmax =  45.
      spl_ratio = 0.25
      title = 'esc_iesa_cal_table_4'
      note = 'Calibration Table 4: 400eV - 600eV - -45 to 45 - 0.25 SPL Ratio'
      esc_iesa_sweep_table_generate, tc4, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 5 --- Energies 400eV - 600eV --- Deflections -45 - 45 --- Spoiler Ratio 0.5
      emin = 400.
      emax = 600.
      dmin = -45.
      dmax =  45.
      spl_ratio = 0.5
      title = 'esc_iesa_cal_table_5'
      note = 'Calibration Table 5: 400eV - 600eV - -45 to 45 - 0.5 SPL Ratio'
      esc_iesa_sweep_table_generate, tc5, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 6 --- Energies 400eV - 600eV --- Deflections -45 - 45 --- Spoiler Ratio 0.75
      emin = 400.
      emax = 600.
      dmin = -45.
      dmax =  45.
      spl_ratio = 0.75
      title = 'esc_iesa_cal_table_6'
      note = 'Calibration Table 6: 400eV - 600eV - -45 to 45 - 0.75 SPL Ratio'
      esc_iesa_sweep_table_generate, tc6, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 7 --- Energies 1eV - 15eV --- Deflections -15 - 15 --- Spoiler Ratio 0.25
      emin = 1.
      emax = 15.
      dmin = -15.
      dmax =  15.
      spl_ratio = 0.25
      title = 'esc_iesa_cal_table_7'
      note = 'Calibration Table 7: 1eV - 15eV - -15 to 15 - 0.25 SPL Ratio'
      esc_iesa_sweep_table_generate, tc7, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 8 --- Energies 1eV - 15eV --- Deflections -15 - 15 --- Spoiler Ratio 0.50
      emin = 1.
      emax = 15.
      dmin = -15.
      dmax =  15.
      spl_ratio = 0.50
      title = 'esc_iesa_cal_table_8'
      note = 'Calibration Table 8: 1eV - 15eV - -15 to 15 - 0.50 SPL Ratio'
      esc_iesa_sweep_table_generate, tc8, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 9 --- Energies 1eV - 15eV --- Deflections -15 - 15 --- Spoiler Ratio 0.75
      emin = 1.
      emax = 15.
      dmin = -15.
      dmax =  15.
      spl_ratio = 0.75
      title = 'esc_iesa_cal_table_9'
      note = 'Calibration Table 9: 1eV - 15eV - -15 to 15 - 0.75 SPL Ratio'
      esc_iesa_sweep_table_generate, tc9, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 10 - 800eV - 1200eV --- Deflections -15 - 15 --- Spoiler Ratio 0.50
      emin =  800.
      emax = 1200.
      dmin = -15.
      dmax =  15.
      spl_ratio = 0.50
      title = 'esc_iesa_cal_table_10'
      note = 'Calibration Table 10: 800eV - 1200eV - -15 to 15 - 0.50 SPL Ratio'
      esc_iesa_sweep_table_generate, tc10, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio
      
      ;; EESA-i Calibration Table 11 - 1200eV - 2800eV --- Deflections -15 - 15 --- Spoiler Ratio 0.50
      emin = 1200.
      emax = 2800.
      dmin = -15.
      dmax =  15.
      spl_ratio = 0.50
      title = 'esc_iesa_cal_table_11'
      note = 'Calibration Table 11: 1200eV - 2800eV - -15 to 15 - 0.50 SPL Ratio'
      esc_iesa_sweep_table_generate, tc11, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 12 - 2500eV - 7500eV --- Deflections -15 - 15 --- Spoiler Ratio 0.50
      emin = 2500.
      emax = 7500.
      dmin = -15.
      dmax =  15.
      spl_ratio = 0.50
      title = 'esc_iesa_cal_table_12'
      note = 'Calibration Table 12: 2500eV - 7500eV - -15 to 15 - 0.50 SPL Ratio'
      esc_iesa_sweep_table_generate, tc12, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio
      
      ;; EESA-i Calibration Table 13 --- Energies 0.5eV - 15eV --- Deflections -45 - 45 --- Spoiler Ratio 0.50
      emin = 0.5
      emax = 15.
      dmin = -45.
      dmax =  45.
      spl_ratio = 0.50
      title = 'esc_iesa_cal_table_13'
      note = 'Calibration Table 13: 0.5eV - 15eV - -45 to 45 - 0.50 SPL Ratio'
      esc_iesa_sweep_table_generate, tc13, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 14 --- Energies 250eV - 750eV --- Deflections -45 - 45 --- Spoiler Ratio 0.50
      emin = 250.
      emax = 750.
      dmin = -45.
      dmax =  45.
      spl_ratio = 0.50
      title = 'esc_iesa_cal_table_14'
      note = 'Calibration Table 14: 250eV - 750eV - -45 to 45 - 0.50 SPL Ratio'
      esc_iesa_sweep_table_generate, tc14, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 15 --- Energies 250eV - 750eV --- Deflections -45 - 45 --- Spoiler Ratio 0.75
      emin = 250.
      emax = 750.
      dmin = -45.
      dmax =  45.
      spl_ratio = 0.75
      title = 'esc_iesa_cal_table_15'
      note = 'Calibration Table 15: 250eV - 750eV - -45 to 45 - 0.50 SPL Ratio'
      esc_iesa_sweep_table_generate, tc15, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

      ;; EESA-i Calibration Table 16 - 600eV - 1400eV --- Deflections -15 - 15 --- Spoiler Ratio 0.50
      emin =  600.
      emax = 1400.
      dmin = -15.
      dmax =  15.
      spl_ratio = 0.50
      title = 'esc_iesa_cal_table_16'
      note = 'Calibration Table 16: 600eV - 1400eV - -15 to 15 - 0.50 SPL Ratio'
      esc_iesa_sweep_table_generate, tc16, emin=emin,emax=emax,dmin=dmin,dmax=dmax,title=title,note=note, spl_ratio=spl_ratio

   ENDIF
   

END
