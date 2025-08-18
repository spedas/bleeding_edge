pro t04s_crib

  ; Load and display the Dst index for a period of time preceding the time of interest, 2001-03-21/07:50
  
  timespan,'2001-03-18',3,/days
  kyoto_load_dst
  tplot,'kyoto_dst'
  print,'The time of interest for this example is 2001-03-21/07:50. Note the Dst goes negative for this storm near 2001-03-19/11:30.'
  print,'Since the T04S W-coefficients represent integrations from the start of the storm, we need to load at least this much solar wind data.'
  stop
  
  ; Reset the timespan and load solar wind data at 5-minute resolution
  
  timespan,'2001-03-19/11:20',2,/days
  kyoto_load_dst
  omni_hro_load,/res5min

  ;Storm time is chosen to be march 21 so that magnetic dipole axis tilt is as close to 0 as possible.
  start_times = '2001-03-21 07:50:00' ;'2015-12-18 00:40:00'
  end_times = '2001-03-21 08:20:00' ;'2015-12-18 01:20:00'

  ; Period of interest
  sdate = time_double(start_times)
  edate = time_double(end_times)
  
  
  ;;********************************************************
  ;;This section generates TS04 model B field for a 3-d grid of points
  ;;********************************************************

  ; x,y,z ranges and x,y,z resolutions
  nx = 45.
  ny = 60.
  nz = 360.
  xmin=-25.
  xmax=-5. ;+12.
  ymin=-8. ; -11.
  ymax=+8. ; +11.
  zmin=-20.
  zmax=+17.
  ;

  ; x,y,z position arrays of size (nx,ny,nz)
  x = findgen(nx,start = xmin,increment = (xmax-xmin)/(nx-1))
  y = findgen(ny,start = ymin,increment = (ymax-ymin)/(ny-1))
  z = findgen(nz,start = zmin,increment = (zmax-zmin)/(nz-1))
  xvals = reform(reform(x#Replicate(1,n_elements(y)),nx*ny)#Replicate(1,n_elements(z)),nx,ny,nz)
  yvals = reform(reform(Replicate(1,n_elements(x))#y,nx*ny)#Replicate(1,n_elements(z)),nx,ny,nz)
  zvals = reform(reform(Replicate(1,n_elements(x))#Replicate(1,n_elements(y)),nx*ny)#z,nx,ny,nz)

 
  model = 't04s'
 
  ; Combine IMF By and Bz into a single tplot variable
  store_data,'omni_imf',data=['OMNI_HRO_5min_BY_GSM','OMNI_HRO_5min_BZ_GSM']
  ; Use get_tsy_params to generate W-coefficients and other model parameters for T04S model
  get_tsy_params,'kyoto_dst','omni_imf',$
    'OMNI_HRO_5min_proton_density','OMNI_HRO_5min_flow_speed',model,/speed,/imf_yz

  par = model + '_par'

  thm_load_state,probe='b',trange = ['2015-12-18'],/get_supp ; get it for setting dlim only!
  get_data,'thb_state_pos_gsm',data=thb_state_gsm,dlim=mydlim ; get it for setting dlim only! this gets 2 days!!
    times = replicate(sdate,nx*ny*nz)
    store_data,'xyzpos',data={x:times,y:[[reform(xvals,nx*ny*nz)],[reform(yvals,nx*ny*nz)],[reform(zvals,nx*ny*nz)]]},dlim=mydlim
    Re=6371.2 ; km - Earth equatorial radius (note 6371.2km is used inside Tsyganenko models)
    calc," 'xyzposkm' = 'xyzpos' * Re " ; in km now
    ;Model the field at the input time and positions, passing the 't04s_par' variable with all the model parameters
    tt04s, 'xyzposkm',par=par, get_tilt='mytilts' ; this takes 10sec for 15 x 20 x 30 points in x,y,z respectively (for 30x30x30pnts --> 30sec)

    get_data,'xyzpos',data=pos_array ; in Re
    get_data,'xyzposkm_bt04s',data=mag_array

  x = reform(pos_array.y[*,0],nx,ny,nz)
  y = reform(pos_array.y[*,1],nx,ny,nz)
  z = reform(pos_array.y[*,2],nx,ny,nz)
  Bx = reform(mag_array.y[*,0],nx,ny,nz)
  By = reform(mag_array.y[*,1],nx,ny,nz)
  Bz = reform(mag_array.y[*,2],nx,ny,nz)
 
 ; Plot the modeled Bz values along a set of points near the X-GSM axis 
  Bz_plot = plot(x[*,30,194],Bz[*,30,194],xtitle = 'X [RE]', ytitle = 'BZ (nT)', title = 'Bz(x) on the noon-midnight meridian')
 
 stop
  ;;********************************************************
  ;;This section generates TS04 model field lines
  ;;********************************************************
  
  ; We will continue to use the same par variable created above.
  
  ;Set the starting positions for the traces
  
  n = 15;
  x_model = findgen(n, start = -5,increment = -1)
  y_model = replicate(0,n)
  z_model = replicate(0.0,n)

  times = replicate(sdate,n_elements(x_model))

  trace_pts_north =  [[x_model],[y_model],[z_model-1.2]]
  trace_pts_south =  [[x_model],[y_model],[-z_model-1.25]]

  store_data,'trace_pts_north',data={x:times,y:trace_pts_north}
  store_data,'trace_pts_south',data={x:times,y:trace_pts_south}

  ; trace the field lines (note that this is a projection of the field line onto the plane you input...)
  ; Note that the trace routines default to positions in units of Re (use the /kn keyword if you have positions in km)
  ttrace2iono,'trace_pts_north',trace_var_name = 'trace_n', $
    external_model=model,par=par,in_coord='gsm',out_coord=$
    'gsm'
  ttrace2iono,'trace_pts_south',trace_var_name = 'trace_s',$
    external_model=model,par=par,in_coord='gsm',out_coord=$
    'gsm', /south

  ;generate the plot of field lines
  window,xsize=800,ysize=600
  xrange = [-30,10] ;x range of the xz plot
  zrange = [-11,11] ;z range of the xz plot
  tplotxy,'trace_n',versus='xrz',xrange=xrange,yrange=zrange,charsize=charsize,title="XZ field lines",ymargin=[.15,0.]
  tplotxy,'trace_s',versus='xrz',/over
  
 end