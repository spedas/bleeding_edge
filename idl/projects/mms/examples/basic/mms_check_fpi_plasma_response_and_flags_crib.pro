;+
; MMS FPI crib sheet
; mms_check_fpi_plasma_response_and_flags_crib.pro
; 
; This crib sheet creates figures showing:
;     1) burst interval status bar
;     2) DIS energy spectra
;     3) DIS flags
;     4) DES energy spectra
;     5) DES flags
;     6) DIS and DES densities
;     7) S/C potential from EDP
;     8) DIS and DES temperatures
;  
;
; 
; NOTES:
;    see: crib_tplot_annotation if you would like to make 
;    modifications to the plot annotations - e.g., colors, 
;    plotting symbols instead of lines, etc; some examples 
;    are also provided at the bottom of this crib sheet
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_check_fpi_plasma_response_and_flags_crib.pro $
;-

;----------------------------------------
;INITIALIZE TIME, SPACECRAFT, DATA TYPE, ETC
del_data, '*'   ; clear tplot variables
;trange = ['2018-07-23/11:37:57', '2018-07-23/11:38:05']  ;burst
;trange = ['2018-07-23/11:39:01', '2018-07-23/11:39:09']  ;burst
;trange = ['2018-07-24/17:46:33', '2018-07-24/17:46:41']  ;burst
;trange = ['2018-07-24/17:47:06', '2018-07-24/17:47:14']  ;burst
;trange = ['2017-07-11/22:34:00', '2017-07-11/22:34:08']  ;burst
trange = ['2016-11-23/07:49:32', '2016-11-23/07:49:35']  ;burst
probes =  [1, 2, 3, 4]  ;or [2, 3, 4] etc
level = 'l2'  ;or 'ql'
;level = 'ql'  ;or 'l2'
;data_rate = 'fast'  ; or 'brst'
data_rate = 'brst'  ; or 'fast'
time_clip = 1   ;data gaps appears as gaps, rather than interpolating across

;----------------------------------------
;INITIALIZE OPTIONS FOR PNG AND PS PLOTS
plot_directory1 = 'tmp_ps/'       ;directory for postscript files
plot_directory2 = 'tmp_png/'   ;directory for png files
init_crib_colors    ;set new color scheme (for aesthetics)
width = 750
height = 2250
!x.ticklen = 0.2
!y.charsize = 0.75
thisletter = "136B
perpsymbol = '!9' + string(thisletter) + '!X'
tplot_options, window=0    ;make sure we're using window 0
window, 0, xsize=width, ysize=height
tplot_options, 'xmargin', [10, 10] ;some folks use 18 characters on left side, 12 on right
tplot_options, 'ymargin', [4, 2]   ;some folks use 8 characters on the bottom, 4 on the top (4 and 2 is my default)

;----------------------------------------
;LOAD AND PREPARE DATA
mms_load_fpi, trange=trange, time_clip=time_clip, probes=probes, datatype=['des-moms', 'dis-moms'], level=level, data_rate=data_rate, versions=versions, /center_measurement
mms_load_edp, time_clip=time_clip, trange=trange, probes=sc_num, level=level, data_rate=data_rate, datatype='scpot'
spd_mms_load_bss, trange=trange, datatype=['fast', 'burst'], /include_labels ; use bss routine to create tplot variables for fast, burst bars

;----------------------------------------
;LOOP THROUGH SPACECRAFT TO MAKE PLOTS
FOR isc = 0, n_elements(probes)-1 DO BEGIN
  prefix = 'mms'+string(probes[isc],format='(I1)')
  
  ;PREPARE DATA
  copy_data, prefix+'_dis_numberdensity_'+data_rate, prefix+'Ni'
  copy_data, prefix+'_des_numberdensity_'+data_rate, prefix+'Ne'
  copy_data, prefix+'_dis_temppara_'+data_rate, prefix+'Ti_para_l2'
  copy_data, prefix+'_dis_tempperp_'+data_rate, prefix+'Ti_perp_l2'
  copy_data, prefix+'_des_temppara_'+data_rate, prefix+'Te_para_l2'
  copy_data, prefix+'_des_tempperp_'+data_rate, prefix+'Te_perp_l2'

  store_data, 'N', data=[prefix+'Ni',prefix+'Ne']
  options, 'N', 'colors', [6, 2]    ;notes on color values are at bottom of crib
  options, 'N', 'thick', 2         ;line thickness
  options, 'N', 'ytitle', 'n!C!C(cm!u-3!n)'
  options, 'N', labels=['n!di!n', 'n!de!n']
  options, 'N', 'labflag', -1
  options, 'N', 'ysubtitle', ''
  options, 'N', 'thick', 2

  tclip, prefix+'Te_perp_l2', 0, 10000, /overwrite
  tclip, prefix+'Te_para_l2', 0, 10000, /overwrite
  store_data, 'Telectrons', data=[prefix+'Te_perp_l2', prefix+'Te_para_l2']
  options, 'Telectrons', 'colors', [1, 6]    ;notes on color values are at bottom of crib
  options, 'Telectrons', 'thick', 2
  options, 'Telectrons', 'ytitle', ' '
  options, 'Telectrons', 'ysubtitle', ' '
  options, 'Telectrons', labels=[' ', ' '] ;note: now drawing labels with xyouts
  options, 'Telectrons', 'labflag', -1

  tclip, 'prefix+Ti_perp_l2', 0, 10000, /overwrite
  tclip, 'prefix+Ti_para_l2', 0, 10000, /overwrite
  store_data, 'Tions', data=[prefix+'Ti_perp_l2',prefix+'Ti_para_l2']
  options, 'Tions', 'colors', [2, 3]    ;notes on color values are at bottom of crib
  options, 'Tions', 'thick', 2   ;line thickness
  options, 'Tions', 'ytitle', ' '
  options, 'Tions', 'ysubtitle', ' '
  options, 'Tions', labels=[' ', ' '] ;note: now drawing labels with xyouts
  options, 'Tions', 'labflag', -1
   
  options, prefix+'_edp_scpot_'+data_rate+'_l2', labels=['SCPOT'], charsize=0.75

  ;PLOT
  time_stamp, /off                 ;time stamp for creation of plot can be turned on or off 
  tplot_multiaxis, ['mms_bss_burst', prefix+'_dis_energyspectr_omni_'+data_rate, $
                    prefix+'_dis_errorflags_'+data_rate+'_moms_flagbars_full',  $
                    prefix+'_des_energyspectr_omni_'+data_rate, $
                    prefix+'_des_errorflags_'+data_rate+'_moms_flagbars_full',  $
                    'N', prefix+'_edp_scpot_'+data_rate+'_l2', 'Telectrons'], 'Tions', 8, trange=trange
  
  ;add labels to the figure
  outputfilelabel = prefix+'_'+data_rate+'_'+time_string(trange[0], tformat='YYYYMMDD_hhmmss.fff')+'-'+time_string(trange[1], tformat='hhmmss.fff')
  xyouts, 0.12, 0.99, outputfilelabel, charsize=1.2, /normal

  xyouts, 0.05, 0.12, 'Temperature (eV)', color=0, orientation=90, alignment=0.5, charsize=0.7, /normal

  xyouts, 0.02, 0.085, 'T!De'+perpsymbol+'!3!N', color=1, /normal
  xyouts, 0.02, 0.15, 'T!De||!N', color=6, /normal
  
  xyouts, 0.95, 0.085, 'T!Di'+perpsymbol+'!3!N', color=2, /normal
  xyouts, 0.95, 0.15, 'T!Di||!N', color=3, /normal
  
  ;EXPORT TO FILES
  makepng, plot_directory2+outputfilelabel  ;extension appended automatically

  ;redraw the plot to the postscript file
  popen, plot_directory1+outputfilelabel, /port    ;note /land option will output in landscape mode, extension appended automatically
  tplot_multiaxis, ['mms_bss_burst', prefix+'_dis_energyspectr_omni_'+data_rate, $
                    prefix+'_dis_errorflags_'+data_rate+'_moms_flagbars_full',  $
                    prefix+'_des_energyspectr_omni_'+data_rate, $
                    prefix+'_des_errorflags_'+data_rate+'_moms_flagbars_full',  $
                    'N', prefix+'_edp_scpot_'+data_rate+'_l2', 'Telectrons'], 'Tions', 8, trange=trange 
                    
  ;add labels to the figure
  xyouts, 0.12, 0.98, outputfilelabel, charsize=1.0, /normal
 
  xyouts, 0.073, 0.14, 'Temperature (eV)', color=0, orientation=90, alignment=0.5, charsize=0.7, /normal

  xyouts, 0.03, 0.085, 'T!De'+perpsymbol+'!3!N', color=1, /normal
  xyouts, 0.03, 0.15, 'T!De||!N', color=6, /normal
  
  xyouts, 0.93, 0.085, 'T!Di'+perpsymbol+'!3!N', color=2, /normal
  xyouts, 0.93, 0.15, 'T!Di||!N', color=3, /normal
  pclose  ;close the postscript file

ENDFOR ;end loop through the spacecraft array
del_data, '*'   ;this line deletes the data so next iteration, if any, starts fresh

end


;----------------------------------------------------------------------------------------
;HELPFUL CRIBS:
;NAME: crib_tplot_annotation

;"colors" option controls line/label color
; if the number of elements is less than the number of components the color sequence
; will be repeated
;options,'sta_SWEA_mom_flux',colors=['b','m','c']
;valid values for colors include
;'x','m','b','c','g','y','r','w', 'd','z', and 0-255
;'x' or 0 is black
;'m' or 1 is magenta
;'b' or 2 is blue
;'c' or 3 is cyan
;'g' or 4 is green
;'y' or 5 is yellow
;'r' or 6 is red
;'w' or 255 is white
;'d' is foreground color(!p.color)
;'z' is background color(!p.background)
;10-255 are elements in a continuous color table. (The default is a basic rainbow table)

;symbols,rather than lines, (use -# to also draw a line between points)
;options,'sta_SWEA_mom_flux_low', psym = 4
; 1 Plus sign (+)
; 2 Asterisk (*)
; 3 Period (.)
; 4 Diamond
; 5 Triangle
; 6 Square
; 7 X
; 8 User-defined (See examples below)
; 10 Histogram mode