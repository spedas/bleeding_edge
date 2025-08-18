;20171031 Ali
;Modeling electron flux dispersions at periapse during the Sep 2017 SEP event
;loads the data and tplots stuff

pro mvn_sep_elec_peri,loaddata=loaddata,orbit=orbit,arc=arc,bmap=bmap,savetplot=savetplot,model=model,trange=trange,mhd=mhd

  common mvn_orbit_num_com,alldat,time_cached,filenames

  if keyword_set(arc) then septplot='mvn_arc_sep?_?-F_Eflux_Energy' else septplot='mvn_sep?_?-F_Eflux_Energy'

  if keyword_set(loaddata) then begin
    ;if keyword_set(trange) then timespan,trange else timespan,'17-9-12',2
    ;timespan,'17-7-20',10
    ;timespan,'14-12-15',10
    trange=timerange(trange)
    cdf2tplot,mvn_pfp_file_retrieve('maven/data/sci/sep/anc/cdf/YYYY/MM/mvn_sep_l2_anc_YYYYMMDD_v??_r??.cdf',/daily),prefix='SepAnc_' ;sep ancillary data
    mvn_sep_var_restore,trange=trange,/basic,arc=arc
    ylim,septplot,10,500
    zlim,septplot,20,2e4
    mvn_spice_load,trange=trange
    mvn_mag_load,trange=trange
    options,'mvn_B_1sec',colors='bgr',ytitle=[],/def
    spice_vector_rotate_tplot,'mvn_B_1sec','MSO'
    spice_vector_rotate_tplot,'mvn_B_1sec','IAU_MARS'
    mvn_swe_load_l2,/spec,/nospice ;load SWEA spec data
    mvn_swe_sumplot,eph=0,orb=0,/loadonly ;plot SWEA data, without calling maven_orbit_tplot, changing orbnum tplot variable, or plotting anything!
    zlim,'swe_a4',1e5,1e8
    maven_orbit_tplot,colors=[4,6,2],/loadonly ;loads the color-coded orbit info
    mvn_sep_elec_peri_stats,mhd=mhd
  endif
  if keyword_set(model) then mvn_sep_elec_peri_model,lowalt=trange,mhd=mhd

  orbit1=5731
  orbit2=5745

  if ~keyword_set(alldat) then begin
    dprint,'Use keyword /loaddata first!'
    return
  endif
  if keyword_set(savetplot) then begin
    for orbit=orbit1,orbit2 do begin
      peritime=alldat[orbit-1].peri_time
      trange=peritime+60.*30.*[-1.,1.] ;30 mins before and after
      tplot,trange=trange
      makepng,'mvn_sep_peri_orbit_'+strtrim(orbit,2)
    endfor
  endif else begin
    if ~keyword_set(orbit) then orbit=orbit1
    peritime=alldat[orbit-1].peri_time
    trange=peritime+60.*20.*[-1.,1.] ;30 mins before and after
    dmnames=[tnames(septplot),tnames('mvn_sep??_1/optical_depth')]
    tplot,trange=trange,'mvn_50keV_electron_gyrocntr_alt_(km) mvn_B_cos_dip mvn_B_data_model_*_(nT) mvn_electron_gyroperiod_(s) mvn_cos_B_FOV mvn_50keV_electron_gyroradius_(km) '$
      +strjoin(dmnames[[0,4,1,5,2,6,3,7]],' ')+' swe_a4 mvn_SEPS_svy_ATT mvn_SEPS_svy_DURATION'
    maven_orbit_snap2,mars=2,/alt,/cyl,/bcomp,/terminator,/prec,bmap=bmap
  endelse
end