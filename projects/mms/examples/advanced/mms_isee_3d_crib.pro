; 
; PURPOSE: 
;     A crib sheet for visualizing MMS 3D distribution function data (L2) 
;     by using an interactive visualization tool, ISEE3D, developed by 
;     Institute for Space-Earth Environmental Research (ISEE), Nagoya University, Japan. . 
; 
; NOTES: 
;     Please use the latest version of SPEDAS bleeding edges. 
;     Please use both 'bfield' and 'velocity' keywords to run isee3d. 
; 
; HISTORY: 
;     Updated by egrimes, March 13, 2020; replaced hard-coded data rates with data_rate variable, and added fgm_data_rate option
;     Updated by Kunihiro Keika, ISEE, Nagoya Univ., May 20, 2016. 
;     Preparedy by Kunihiro Keika, ISEE, Nagoya Univ., Mar. 2016. 
; 
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 

; - - - TIME SETTING - - - 
trange='2015-11-18/02:'+['10:00','14:00']
timespan, trange 
probe='1'
species='i' 
data_rate='brst'
fgm_data_rate='brst'
level='l2'


; - - - FOR MAGNETIC FIELD DATA - - - - 
;Load magnetic field data (Despun MPA-Alligned Coordinate, DMPA) 
mms_load_fgm, probes=probe, data_rate=fgm_data_rate, level=level, cdf_filenames=files;, /latest_version, 

; - - - FOR FPI E-T & MOMENT DATA - - - 
datatype='d'+species+'s-moms' 
mms_load_fpi, probes=probe, datatype=datatype, level=level, data_rate=data_rate 
;join_vec, 'mms1_dis_bulk'+['x','y','z']+'_gse_'+data_rate, 'mms1_dis_bulk_gse_'+data_rate

; - - - PLOT VEL, MAG and E-T diagram 
tvar_plot = [$ 
           'mms1_dis_energyspectr_px_'+data_rate, $ 
;           'mms1_fgm_b_dmpa_'+data_rate+'_l2', $ 
           'mms1_fgm_b_gse_'+fgm_data_rate+'_l2', $ 
           'mms1_dis_bulkv_gse_'+data_rate, $   
;           'mms1_dis_bulk_gse_'+data_rate, $   
           ''] 
!p.charsize=1.2
tplot_options, 'tickinterval', 30.
options, tvar_plot[0],'yrange',[10.,3.*10^4.] 
options, tvar_plot[0],'ystyle', 1 
tplot, tvar_plot 
;popen, 'sample', /encap, xsize=20., ysize=15., unit='cm' 
;tplot
;pclose 

; - - - Load 3D-dist data - - - 
;trange='2015-11-18/02:10:'+['00','10']
;trange='2015-11-18/02:11:'+['40','59']
;trange='2015-11-18/02:11:'+['35','45']
;trange='2015-11-18/02:12:'+['30','50']
trange='2015-11-18/02:13:'+['15','20']
datatype='d'+species+'s-dist'
mms_load_fpi,trange=trange,probe=probe,data_rate=data_rate,level=level,datatype=datatype 

; load data into standard structures 
name = 'mms'+probe+'_d'+species+'s_dist_'+data_rate 
;dist = mms_get_fpi_dist(name, trange=trange, level=level, data_rate=data_rate, species=species, probe=probe)
;version20160401 or later, DATA_RATE and LEVEL keywords are not needed. 
dist = mms_get_fpi_dist(name, trange=trange, species=species, probe=probe)

;convert structures to isee3d data model
data = spd_dist_to_hash(dist)


; - - - RUN STEL3D - - - 
   print, '###############################################' 
   print, 'Once GUI is open, select PSD from Units menu.' 
   print, '###############################################' 
tvar_b = 'mms'+probe+'_fgm_b_gse_'+fgm_data_rate+'_l2_bvec' 
tvar_v = 'mms1_dis_bulkv_gse_'+data_rate
;stel3d, data=data, trange=trange, bfield=tvar_b, velocity=tvar_v
isee_3d, data=data, trange=trange, bfield=tvar_b, velocity=tvar_v



end 
