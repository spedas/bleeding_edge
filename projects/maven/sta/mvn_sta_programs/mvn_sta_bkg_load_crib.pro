pro mvn_sta_bkg_load_crib

  ;; Select Test Time
  timespan, time_double(['2015-04-21','2015-04-26'])
  
  ;; Load Test Data
  mvn_sta_l2_load, sta_apid=['c0','c6','ce'],trange=trange

  ;; Uncomment if epehemris is not loaded automatically
  ;mvn_sta_ephemeris_load

  ;; Run STATIC Background Filler
  mvn_sta_bkg_load, /tplot_test

end
