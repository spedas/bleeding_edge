;+
;
;Procedure:
;  moka_mms_part_products_crib
;
;History:
;  Created on 2017-01-01 by moka
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-10-06 09:35:27 -0700 (Thu, 06 Oct 2016) $
;$LastChangedRevision: 22050 $
;$URL: svn+ssh://ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_products.pro $
;-

PRO moka_mms_part_products_crib
  compile_opt idl2
  clock=tic('moka_mms_part_products_crib')
  mms_init
  
  ;/////// USER SETTING ////////////
  probe      = '3'
  species    = 'i'
  start_time = '2015-10-22/06:03:25'
  stop_time  = '2015-10-22/06:06:00'
;  start_time = '2016-12-07/14:42:30'
;  stop_time  = '2016-12-07/14:43:30'

  filename   = 'pt_custom'
  SUBTRACT_BULK = 1
  RESTORE    = 0  ; (0) Load/Save, (1) Restore, (2) do nothing (data must be already loaded into the IDL session)
  ;////////////////////////////////

  ;--------------
  ; INITIALIZE
  ;--------------
  trange = time_double([start_time, stop_time]) ;use short time range for data due to high resolution
  support_trange = trange + [-60,60] ;use longer time range for support data to ensure we have enough to work with
  data_rate  = 'brst'    ;brst, fast
  level      = 'l2'
  timespan, trange[0], trange[1]-trange[0], /seconds
  name = 'mms'+probe+'_d'+species+'s_dist_'+data_rate
  ;mag_name = 'mms'+probe+'_fgm_b_dmpa_'+data_rate+'_l2_bvec'
  mag_name = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
  vel_name = 'mms'+probe+'_d'+species+'s_bulkv_dbcs_'+data_rate
  
  ;--------------
  ; LOAD
  ;--------------
  case RESTORE of
    0:begin
      mms_load_fpi,  probe=probe, trange=trange, data_rate=data_rate, level=level, $
        datatype='d'+species+'s-'+['dist','moms'], min_version='2.2.0'
      mms_load_state,probe=probe, trange=support_trange
      mms_load_fgm,  probe=probe, trange=support_trange, data_rate='srvy', level='l2'

      ; Generates pitch-angle-distribution data 
      moka_mms_part_products,name,mag_name=mag_name,out=['pad'],vel_name=vel_name,subtract_bulk=SUBTRACT_BULK
      
      tplot_save,'*',filename=filename
    end
    1:tplot_restore, filename=filename+'.tplot'
    else:; Do nothing (Data must be already loaded in this IDL session)
  endcase

  ;-----------------------------------------------------
  ; PITCH-ANGLE SPECTROGRAMS for SELECTED ENERGY RANGES
  ;-----------------------------------------------------
  
  ; Define energy ranges
  kmax=5
  ranges = fltarr(kmax,2)
  ranges[0,*] = [   30,   50] ; core electrons
  ranges[1,*] = [   90,  140] ; strahl electrons
  ranges[2,*] = [  180,  250] ; non-thermal electrons
  ranges[3,*] = [  700, 1100] ; mid-energy non-thermal electrons
  ranges[4,*] = [ 4000, 9000] ; highest energy electrons
  
  ; pitch-angle spectrograms
  moka_mms_part_products_pt,name+'_pad',ranges=ranges
  tplot,'*pad*-*eV'
  stop
  
  ; pitch-angle spectrograms (normalized at each time step)
  moka_mms_part_products_pt,name+'_pad',ranges=ranges,/norm,suffix='_normalized'
  tplot,'*pad*-*_normalized'
  stop
  
  ;-----------------------------------------------------
  ; PITCH-ANGLE SPECTROGRAMS for ALL ENERGY BINS
  ;-----------------------------------------------------

  ; pitch-angle spectrograms
  moka_mms_part_products_pt,name+'_pad',suffix='_all'
  tplot,'*_all'
  stop
  
  ; pitch-angle spectrograms (normalized at each time step)
  moka_mms_part_products_pt,name+'_pad',/norm,suffix='_all_normalized'
  tplot,'*_all_normalized'

  

  toc, clock
END
