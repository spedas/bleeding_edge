pro mvn_sta_sc_bins_load_crib, test_bins=test_bins

  ;time = ['2015-03-08/00:00:00','2015-03-10/00:00:00']  
  timespan;, time_double(time)
  mk = mvn_spice_kernels(/all,/load,trange=timerange())
  mvn_sta_l2_load
  mvn_sta_sc_bins_load;, perc_block=0.01

  if keyword_set(test_bins) then begin
     ;;-----------------------------------------------------------
     ;; Declare Common Blocks
     common mvn_c8,mvn_c8_ind,mvn_c8_dat ;16D       4s  Ram Conic
     common mvn_ca,mvn_ca_ind,mvn_ca_dat ;4Dx16A    4s  Ram Conic
     common mvn_cc,mvn_cc_ind,mvn_cc_dat ;8D       32s  Ram
     common mvn_cd,mvn_cd_ind,mvn_cd_dat ;8D        4s  Ram
     common mvn_ce,mvn_ce_ind,mvn_ce_dat ;4Dx16A   32s  Conic
     common mvn_cf,mvn_cf_ind,mvn_cf_dat ;4Dx16A    4s  Conic
     common mvn_d0,mvn_d0_ind,mvn_d0_dat ;4Dx16A  128s  Pickup
     common mvn_d1,mvn_d1_ind,mvn_d1_dat ;4Dx16A   16s  Pickup
     common mvn_d4,mvn_d4_ind,mvn_d4_dat ;4Dx16A    4s  Pickup

     ;;-------------------
     ;; APID C8
     ss = size(mvn_c8_dat)
     if ss[2] eq 8 then begin
        ss   = size(mvn_c8_dat.data)
        bins = mvn_c8_dat.bins_sc
        bins = transpose(rebin(bins, ss[1],ss[3],ss[2]),[0,2,1])
        mvn_c8_dat.data = mvn_c8_dat.data * bins
     endif

     ;;-------------------
     ;; APID CA
     ss = size(mvn_ca_dat)
     if ss[2] eq 8 then begin
        ss   = size(mvn_ca_dat.data)
        bins = mvn_ca_dat.bins_sc
        bins = transpose(rebin(bins, ss[1],ss[3],ss[2]),[0,2,1])
        mvn_ca_dat.data = mvn_ca_dat.data * bins
     endif

     ;;-------------------
     ;; APID CC
     ss = size(mvn_cc_dat)
     if ss[2] eq 8 then begin
        ss   = size(mvn_cc_dat.data)
        bins = mvn_cc_dat.bins_sc
        bins = transpose(rebin(bins, ss[1],ss[3],ss[2],ss[4]),[0,2,1,3])
        mvn_cc_dat.data = mvn_cc_dat.data * bins
     endif

     ;;-------------------
     ;; APID CD
     ss = size(mvn_cd_dat)
     if ss[2] eq 8 then begin
        ss   = size(mvn_cd_dat.data)
        bins = mvn_cd_dat.bins_sc
        bins = transpose(rebin(bins, ss[1],ss[3],ss[2],ss[4]),[0,2,1,3])
        mvn_cd_dat.data = mvn_cd_dat.data * bins
     endif

     ;;-------------------
     ;; APID CE
     ss = size(mvn_ce_dat)
     if ss[2] eq 8 then begin
        ss   = size(mvn_ce_dat.data)
        bins = mvn_ce_dat.bins_sc
        bins = transpose(rebin(bins, ss[1],ss[3],ss[2],ss[4]),[0,2,1,3])
        mvn_ce_dat.data = mvn_ce_dat.data * bins
     endif

     ;;-------------------
     ;; APID CF
     ss = size(mvn_cf_dat)
     if ss[2] eq 8 then begin
        ss   = size(mvn_cf_dat.data)
        bins = mvn_cf_dat.bins_sc
        bins = transpose(rebin(bins, ss[1],ss[3],ss[2],ss[4]),[0,2,1,3])
        mvn_cf_dat.data = mvn_cf_dat.data * bins
     endif

     ;;-------------------
     ;; APID D0
     ss = size(mvn_d0_dat)
     if ss[2] eq 8 then begin
        ss   = size(mvn_d0_dat.data)
        bins = mvn_d0_dat.bins_sc
        bins = transpose(rebin(bins, ss[1],ss[3],ss[2],ss[4]),[0,2,1,3])
        mvn_d0_dat.data = mvn_d0_dat.data * bins
     endif

     ;;-------------------
     ;; APID D1
     ss = size(mvn_d1_dat)
     if ss[2] eq 8 then begin
        ss   = size(mvn_d1_dat.data)
        bins = mvn_d1_dat.bins_sc
        bins = transpose(rebin(bins, ss[1],ss[3],ss[2],ss[4]),[0,2,1,3])
        mvn_d1_dat.data = mvn_d1_dat.data * bins
     endif

     ;;-------------------
     ;; APID D4
     ss = size(mvn_d4_dat)
     if ss[2] eq 8 then begin
        ss   = size(mvn_d4_dat.data)
        bins = mvn_d4_dat.bins_sc
        bins = transpose(rebin(bins, ss[1],ss[3],ss[2],ss[4]),[0,2,1,3])
        mvn_d4_dat.data = mvn_d4_dat.data * bins
     endif

     mvn_sta_l2_tplot
     tplot,1
     mvn_sta_3d_snap, erange=[0.1, 1.d4],$
                      wi=1, $
                      /keep, $
                      /mso, $
                      /app, $
                      /label, $
                      /plot_sc

  endif




end




