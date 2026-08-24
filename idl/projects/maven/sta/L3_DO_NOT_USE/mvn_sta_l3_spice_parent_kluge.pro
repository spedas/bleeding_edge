pro mvn_sta_l3_spice_parent_kluge 
;;;; add the spice_loaded and parent_files attributes to the v2 and v3 L3 files without reprocessing the whole dataset. 

start_date='2016-02-01'
end_date='2024-01-01'

ndays=ceil((end_date-start_date)/86400.)

load_spice_dates = ['2016-02-01','2016-07-01','2017-01-01',$
  '2017-07-01','2018-01-01','2018-07-01','2019-01-01','2019-07-01',$
  '2020-01-01','2020-07-01','2021-01-01','2021-07-01','2022-01-01',$
  '2022-07-01','2023-01-01','2023-07-01','2024-01-01']
  
;;;;; loop through dates


;;;; load the L3 full files


;;; load the L2 data with parent_files keyword set


;;; if needed, load new spice kernels



;;; add the parent_files and spiceloaded attributes to the L3 variables



;;; save the L3 file again. 




end