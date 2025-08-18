;20160404 Ali
;loads PFP data for use by MAVEN pickup ion model
;to be called by mvn_pui_model

pro mvn_pui_data_load,do3d=do3d,nomag=nomag,noswia=noswia,noswea=noswea,nostatic=nostatic,nosep=nosep,noeuv=noeuv,nospice=nospice,c6=c6,d0=d0,tohban=tohban

  if ~keyword_set(nomag) then begin
    mvn_mag_load,'L2_1sec' ;load MAG data

    options,'mvn_B_1sec',yrange=[-10,10],colors='bgr'
    options,'mvn_B_1sec','ytitle',[],/def

  endif

  if ~keyword_set(noswia) then begin
    mvn_swia_load_l2_data,/loadmom,/loadspec,loadcoarse=do3d,/eflux,/tplot,qlevel=0.1 ;load SWIA data

    ylim,'mvn_swim_density',.01,100,1
    options,'mvn_swim_velocity_mso',yrange=[100,-800],colors='bgr'
    options,'mvn_swis_en_eflux',yrange=[25,25e3],zrange=[1e3,1e8],ytickunits='scientific'
  endif

  if ~keyword_set(nostatic) then begin
    mvn_sta_l2_load,sta_apid='c0' ;load STATIC 1D spectra (64e2m)
    if keyword_set(c6) then mvn_sta_l2_load,sta_apid='c6' ;load STATIC mass-energy spectra (32e64m)
    if keyword_set(d0) then mvn_sta_l2_load,sta_apid='d0' ;load STATIC 3D spectra (32e4d16a8m)
    ;  mvn_sta_l2_tplot ;store STATIC data in tplot variables
    ;  ylim,'mvn_swim_swi_mode',0,1 ;because mvn_sta_l2_tplot messes with 'mvn_swim_swi_mode' !!!
    if keyword_set(do3d) then mvn_sta_l2_load,sta_apid=['d0','d1'] ;load STATIC 3D spectra
  endif

  if ~keyword_set(nosep) then begin
    mvn_sep_var_restore,units_name='Rate',/basic_tags,lowres=tohban ;load SEP data
    options,'mvn_5min_sep1_arc_ATT',spec=1,yrange=[.1,.2],zrange=[.1,.2],zlog=1,ytitle='Burst',ytickname=[' ',' '],yticklen=.0001,xticklen=.5,yticks=1,tpanel_size=.2,no_color_scale=1; tohban burst bar
    ;  options,'mvn_sep?_?-?_Rate_Energy','panel_size',1

    ;cdf2tplot,mvn_pfp_file_retrieve('maven/data/sci/sep/anc/cdf/YYYY/MM/mvn_sep_l2_anc_YYYYMMDD_v??_r??.cdf',/daily),prefix='SepAnc_' ;sep ancillary data
  endif

  if ~keyword_set(noeuv) then begin
    mvn_euv_l3_load ;load FISM data
    mvn_euv_load ;load EUVM data
    if keyword_set(tohban) then mvn_euv_l0_load

    ylim,'mvn_euv_data',1e-5,1e-2,1
    options,'mvn_euv_data',colors='gbr',labels=['17-22 nm','0.1-7 nm','121-122 nm'],labflag=1
  endif

  if ~keyword_set(nospice) then begin
    ;mvn_spice_load ;load spice kernels
    kernels=mvn_spice_kernels(/all,/clear)
    spice_kernel_load,kernels,verbose=3
    maven_orbit_tplot,colors=[4,6,2],/loadonly ;loads the color-coded orbit info
  endif

  if ~keyword_set(noswea) then begin
    mvn_swe_load_l2,/spec,/nospice ;load SWEA spec data
    mvn_swe_sumplot,eph=0,orb=0,/loadonly ;plot SWEA data, without calling maven_orbit_tplot, changing orbnum tplot variable, or plotting anything!
    ;  tlimit,/full ;revert back to full time period, since swea may change tlimit to its available trange
    ;  mvn_swe_sc_pot,/reset,/fill ;calculate the spacecraft potential from SWEA data
    options,'swe_a4*',zrange=[1e4,1e9],ytickunits='scientific'
    mvn_scpot,/composite,/nocalc
  endif

  if keyword_set(tohban) then tplot_options,'datagap',600. ;blank space for data gaps longer than 10 min
  ;this overrides mvn_swe_sumplot, which sets the datagap to 129D, causing tohban 5min resolution plots not to show up!

end