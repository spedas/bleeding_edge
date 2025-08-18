;+
;
; ESC_IESA_SCI_LUTS
;
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2024-07-19 13:45:07 -0700 (Fri, 19 Jul 2024) $
; $LastChangedRevision: 32754 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_sci_luts.pro $
;
;-


;; Generate a CSV file with all of the values and constants
FUNCTION esc_iesa_sci_luts_write_csv, table

   openw, 1,'~/Desktop/esc_iesa_sci_luts.txt'
   printf, 1, '# ESCAPADE iESA Science Product Look-Up Tables'
   printf, 1, '# '
   printf, 1, '# Source:   spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_sci_luts.pro'
   printf, 1, '# Date:     $LastChangedDate: 2024-07-19 13:45:07 -0700 (Fri, 19 Jul 2024) $'
   printf, 1, '# Revision: $LastChangedRevision: 32754 $'
   printf, 1, '# '
   ;;printf, 1, '# ' + table.note
   printf, 1, '# '
   printf, 1, '# Sweep Table Dimensions'
   printf, 1, '# Mass:       '+ string(table.tbl_mas_rr,format='(I2)')
   printf, 1, '# Anode:      '+ string(table.tbl_ano_rr,format='(I2)')
   printf, 1, '# Deflection: '+ string(table.tbl_def_rr,format='(I2)')
   printf, 1, '# Energy:     '+ string(table.tbl_nrg_rr,format='(I2)')
   printf, 1, '# '
   printf, 1, '# '
   printf, 1, '# '
   printf, 1, '# '
   printf, 1, '# '
   printf, 1, '# '
   printf, 1, '# ##############################'
   printf, 1, '# ###    Science Products    ###'
   printf, 1, '# ##############################'
   printf, 1, '# '
   printf, 1, '# '
   printf, 1, '# '   
   printf, 1, '#      --- Fine Masses ---     #'
   printf, 1, '# '+strjoin(replicate('-',30))
   printf, 1, '# Mass:   '+ string(table.nn_mas_fm,format='(I2)')
   printf, 1, '# Energy: '+ string(table.nn_nrg_fm,format='(I2)')
   printf, 1, '# '
   printf, 1, '# MLUT - 64 Bin Array'
   FOR i=0, 7 DO printf, 1, format='(8I4)',table.mas_lut_fm[8*i:8*i+7]
   printf, 1, '# '
   printf, 1, '# ELUT - 64 Bin Array'
   FOR i=0, 7 DO printf, 1, format='(8I4)',table.nrg_lut_fm[8*i:8*i+7]
   printf, 1, '#  '
   printf, 1, '#  '
   printf, 1, '#  '   

   printf, 1, '#     --- Fine Energies ---    #'
   printf, 1, '# '+strjoin(replicate('-',30))
   printf, 1, '# '
   printf, 1, '# Mass:       '+ string(table.nn_mas_fe,format='(I2)')
   printf, 1, '# Anode:      '+ string(table.nn_ano_fe,format='(I2)')
   printf, 1, '# Deflection: '+ string(table.nn_def_fe,format='(I2)')
   printf, 1, '# Energy:     '+ string(table.nn_nrg_fe,format='(I2)')
   printf, 1, '# '
   printf, 1, '# MLUT -  4 Bin Array'
   printf, 1, format='(4I4)', table.mas_lut_fe
   printf, 1, '#  '   
   printf, 1, '# ALUT - 16 Bin Array'
   FOR i=0, 1 DO printf, 1, format='(8I4)', table.ano_lut_fe[8*i:8*i+7]
   printf, 1, '#  '   
   printf, 1, '# DLUT -  8 Bin Array'
   printf, 1, format='(8I4)', table.def_lut_fe
   printf, 1, '#  '   
   printf, 1, '# ELUT - 64 Bin Array'
   FOR i=0, 7 DO printf, 1, format='(8I4)',table.nrg_lut_fe[8*i:8*i+7]
   printf, 1, '#  '
   printf, 1, '#  '
   printf, 1, '#  '

   printf, 1, '#    --- Fine Deflectors ---   #'
   printf, 1, '# '+strjoin(replicate('-',30))
   printf, 1, '# '
   printf, 1, '# Mass:       '+ string(table.nn_mas_fd,format='(I2)')
   printf, 1, '# Anode:      '+ string(table.nn_ano_fd,format='(I2)')
   printf, 1, '# Deflection: '+ string(table.nn_def_fd,format='(I2)')
   printf, 1, '# Energy:     '+ string(table.nn_nrg_fd,format='(I2)')
   printf, 1, '# '
   printf, 1, '# MLUT -  4 Bin Array'
   printf, 1, format='(4I4)', table.mas_lut_fd
   printf, 1, '# '   
   printf, 1, '# ALUT - 16 Bin Array'
   FOR i=0, 1 DO printf, 1, format='(8I4)', table.ano_lut_fd[8*i:8*i+7]
   printf, 1, '# '   
   printf, 1, '# DLUT -  8 Bin Array'
   printf, 1, format='(8I4)', table.def_lut_fd
   printf, 1, '# '   
   printf, 1, '# ELUT - 64 Bin Array'
   FOR i=0, 7 DO printf, 1, format='(8I4)',table.nrg_lut_fd[8*i:8*i+7]
   printf, 1, '# '
   printf, 1, '#  '
   printf, 1, '#  '

   printf, 1, '#       --- Fine 4D ---        #'
   printf, 1, '# '+strjoin(replicate('-',30))
   printf, 1, '# '
   printf, 1, '# Mass:       '+ string(table.nn_mas_f4,format='(I2)')
   printf, 1, '# Anode:      '+ string(table.nn_ano_f4,format='(I2)')
   printf, 1, '# Deflection: '+ string(table.nn_def_f4,format='(I2)')
   printf, 1, '# Energy:     '+ string(table.nn_nrg_f4,format='(I2)')
   printf, 1, '# '
   printf, 1, '# MLUT -  4 Bin Array'
   printf, 1, format='(4I4)', table.mas_lut_f4
   printf, 1, '# '   
   printf, 1, '# ALUT - 16 Bin Array'
   FOR i=0, 1 DO printf, 1, format='(8I4)', table.ano_lut_f4[8*i:8*i+7]
   printf, 1, '# '   
   printf, 1, '# DLUT -  8 Bin Array'
   printf, 1, format='(8I4)', table.def_lut_f4
   printf, 1, '# '   
   printf, 1, '# ELUT - 64 Bin Array'
   FOR i=0, 7 DO printf, 1, format='(8I4)',table.nrg_lut_f4[8*i:8*i+7]
   printf, 1, '# '
   printf, 1, '#  '
   printf, 1, '#  '
   
   printf, 1, '#      --- Solar Wind ---      #'
   printf, 1, '# '+strjoin(replicate('-',30))
   printf, 1, '# '
   printf, 1, '# Mass:       '+ string(table.nn_mas_sw,format='(I2)')
   printf, 1, '# Anode:      '+ string(table.nn_ano_sw,format='(I2)')
   printf, 1, '# Deflection: '+ string(table.nn_def_sw,format='(I2)')
   printf, 1, '# Energy:     '+ string(table.nn_nrg_sw,format='(I2)')
   printf, 1, '# '
   printf, 1, '# MLUT -  4 Bin Array'
   printf, 1, format='(4I4)', table.mas_lut_sw
   printf, 1, '# '   
   printf, 1, '# ALUT - 16 Bin Array'
   FOR i=0, 1 DO printf, 1, format='(8I4)', table.ano_lut_sw[8*i:8*i+7]
   printf, 1, '# '   
   printf, 1, '# DLUT -  8 Bin Array'
   printf, 1, format='(8I4)', table.def_lut_f4
   printf, 1, '# '   
   printf, 1, '# ELUT - 64 Bin Array'
   FOR i=0, 7 DO printf, 1, format='(8I4)',table.nrg_lut_sw[8*i:8*i+7]


   close, 1            

END


PRO esc_iesa_sci_luts

   ;; --- Full 4D Range ---
   nrg_rr = 64
   ano_rr = 16
   def_rr = 8
   mas_rr = 4
   
   ;; ######################
   ;; ###  Fine Masses   ###
   ;; ######################
   nn_mas_fm = 64
   nn_nrg_fm = 1
   fm = intarr(nn_mas_fm, nn_nrg_fm) 
   
   mas_lut_fm = indgen(nn_mas_fm)
   nrg_lut_fm = replicate(0,64)
   
   ;; ######################
   ;; ###  Fine Energies ###
   ;; ######################

   ;; Product Array
   nn_mas_fe = 3
   nn_ano_fe = 1
   nn_def_fe = 1
   nn_nrg_fe = 64
   fe = intarr(nn_mas_fe, nn_ano_fe, nn_def_fe, nn_nrg_fe)

   ;; Sum Mass 0 (Protons) and Mass 1 (Alphas)
   ;; Leave Mass 2 and Mass 3
   mas_lut_fe = [0,0,1,2]
   ano_lut_fe = replicate(0,ano_rr)
   def_lut_fe = replicate(0,def_rr)
   nrg_lut_fe = indgen(nrg_rr)
   
   ;; ########################
   ;; ###  Fine Deflectors ###
   ;; ########################

   ;; Product Array
   nn_mas_fd = 3
   nn_ano_fd = 1
   nn_def_fd = 8
   nn_nrg_fd = 16
   fd = intarr(nn_mas_fd, nn_ano_fd, nn_def_fd, nn_nrg_fd)

   mas_lut_fd = [0,0,1,2]
   ano_lut_fd = replicate(0,ano_rr)
   def_lut_fd = indgen(8)
   nrg_lut_fd = reform(transpose(indgen(nrg_rr/4) # replicate(1,4)),nrg_rr)
   
   ;; ########################
   ;; ###     Fine 4D      ###
   ;; ########################
   nn_mas_f4 = 3
   nn_ano_f4 = 11
   nn_def_f4 = 8
   nn_nrg_f4 = 32
   f4 = intarr(nn_mas_f4, nn_ano_f4, nn_def_f4, nn_nrg_f4)

   mas_lut_f4 = [0,0,1,2]
   ;;ano_lut_f4 = [indgen(10),replicate(10,6)]
   ano_lut_f4 = [0,0,1,1,2,2,3,3,4,4,5,6,7,8,9,10,11]
   def_lut_f4 = indgen(def_rr)
   nrg_lut_f4 = reform(transpose(indgen(nrg_rr/2) # replicate(1,2)),64)

   ;; ########################
   ;; ###    Solar Wind    ###
   ;; ########################
   nn_mas_sw = 2
   nn_ano_sw = 4
   nn_def_sw = 8
   nn_nrg_sw = 32
   ano_offset = 4
   sw = intarr(nn_mas_sw, nn_ano_sw, nn_def_sw, nn_nrg_sw)

   mas_lut_sw = [0, 1, 4, 4]
   ano_lut_sw = [replicate(16,ano_offset),$
                 indgen(nn_ano_sw),$
                replicate(16,16-ano_offset-nn_ano_sw)]
   def_lut_sw = indgen(ano_rr)
   nrg_lut_sw = reform(transpose(indgen(nrg_rr/2) # replicate(1,2)),64)

   ;; ########################
   ;; ###       Rates      ###
   ;; ########################


   table = { $

           tbl_mas_rr:mas_rr, tbl_ano_rr:ano_rr, tbl_def_rr:def_rr, tbl_nrg_rr:nrg_rr,$

           nn_mas_fm:nn_mas_fm, nn_nrg_fm:nn_nrg_fm, $
           mas_lut_fm:mas_lut_fm, nrg_lut_fm:nrg_lut_fm, $

           nn_mas_fe:nn_mas_fe, nn_ano_fe:nn_ano_fe, nn_def_fe:nn_def_fe, nn_nrg_fe:nn_nrg_fe, $
           nn_mas_fd:nn_mas_fd, nn_ano_fd:nn_ano_fd, nn_def_fd:nn_def_fd, nn_nrg_fd:nn_nrg_fd, $
           nn_mas_f4:nn_mas_f4, nn_ano_f4:nn_ano_f4, nn_def_f4:nn_def_f4, nn_nrg_f4:nn_nrg_f4, $
           nn_mas_sw:nn_mas_sw, nn_ano_sw:nn_ano_sw, nn_def_sw:nn_def_sw, nn_nrg_sw:nn_nrg_sw, $
           mas_lut_fe:mas_lut_fe, ano_lut_fe:ano_lut_fe, def_lut_fe:def_lut_fe, nrg_lut_fe:nrg_lut_fe, $
           mas_lut_fd:mas_lut_fd, ano_lut_fd:ano_lut_fd, def_lut_fd:def_lut_fd, nrg_lut_fd:nrg_lut_fd, $
           mas_lut_f4:mas_lut_f4, ano_lut_f4:ano_lut_f4, def_lut_f4:def_lut_f4, nrg_lut_f4:nrg_lut_f4, $
           mas_lut_sw:mas_lut_sw, ano_lut_sw:ano_lut_sw, def_lut_sw:def_lut_sw, nrg_lut_sw:nrg_lut_sw  $
           
   }

   tmp = esc_iesa_sci_luts_write_csv(table)

END
