; the purpose of this routine is to plot MAVEN quicklook data
; alongside EMUS geometry and brightness data using the tplot routine
; for a certain time span

; the keyword DISK is a structure produced by the routine
; emm_emus_examine_disk. If this has already been run, you can provide
; this directly to save time.

pro emm_emus_maven_ql, time_range, disk = disk,load_only =load_only

  emissions = ['O I 130.4 triplet', 'O I 135.6 doublet']

  !p.background = 255
  !p.color = 0
  tplot_options,var_label= ['sza', 'orbnum']
  if not keyword_set (load_only) then window, 1, xsize = 1300, ysize = 770 
  brightness_range = [[2, 20], [1, 8]]
  zlog = [1, 0]
  ;.r mvn_ql_pfp_tplot
  
  mvn_ql_pfp_tplot, time_range, window = 1,/bcrust,sep = 0, sta = 0, euv = 0, $
                    lpw = 0,/mag,/spacewe
  
  ;mvn_swe_load_l2, trange, /pad
  ;stop
; just make sure we have the solar wind moments
  mvn_swia_load_l2_data, trange=time_range, /tplot,/Loadmom

; calculate solar wind pressure
  Get_data, 'mvn_swim_velocity_mso', data = vsw
  get_data, 'mvn_swim_density', data = nsw
  if size (nsw,/type) eq 8 then begin
     Density = nsw.y
     speed = sqrt ( total (vsw.y^2, 2))
     pressure = 1e9*(1.67e-27*(density*1e6)*(speed*1e3)^ 2.0)
     Store_data, 'mvn_swim_pressure_npa', data = {x:nsw.x, y: pressure}
     options, 'mvn_swim_pressure_npa', 'ytitle', 'SW Pressure!c nPa'
     ylim, 'mvn_swim_pressure_npa', 0.08, 3.0, 1
     options, 'mvn_swim_pressure_npa', 'ystyle', 1
  endif
  
  
; calculate cone and clock angles
  get_data, 'mvn_mag_bmso_1sec', data =  bmso
  if Size (bmso,/type) ne 8 then message, 'B-field data does not exist for this time range.'
  bx= bmso.y [*, 0] & by = bmso.y [*, 1] & bz = bmso.y [*, 2]
  Clock = clock_angle (by, bz) 
  cone =  cone_angle (bx, by, bz) 
  bphi = ATAN(by, bx)
  btotal = sqrt (BX*BX + By*by + bz*bz)
  btheta = ASIN(bz / btotal)
  store_data, 'cone', data = {x: bmso.x, y:cone}
  store_data, 'clock', data = {x:bmso.x, y: clock}
  
  aopt = {yaxis: 1, ystyle: 1, yrange: [0, 180], ytitle: 'Bcone [deg]', $
          color: 6, yticks: 4, yminor: 3}
  IF tag_exist(topt, 'charsize') THEN str_element, aopt, 'charsize', topt.charsize, /add
  store_data, 'mvn_mag_cone_clock', data=$
              {x: bmso.x, y: [ [2.*cone], [clock]]}, $
              dlimits={psym: 3, colors: [6, 0], ytitle: 'MAG MSO', $
                       ysubtitle: 'Bclock [deg]', $
                       yticks: 4, yminor: 3, axis: aopt}
  ylim, 'mvn_mag_cone_clock', 0., 360., 0., /def
  options, 'mvn_mag_cone_clock', ystyle=9

  if not keyword_set (disk) then  emm_emus_examine_disk, time_range, $
     emission = emissions, color_table = [8, 3], $
     brightness_range = brightness_range, zlog =zlog, $
     disk = disk
  Timespan, time_range 
  emm_emus_image_bar,trange = time_range, disk = disk, $
                     brightness_range = brightness_range 

  !p.charsize = 1.2 
  if not keyword_set (load_only) then Tplot, $
     ['mvn_swis_en_eflux', 'mvn_swe_etspec','mvn_mag_bamp', $
      'mvn_mag_cone_clock', 'alt2',$
      'emus_lt','emus_br','emus_O_1304'] 
end

