;+
; Name: thm_crib_neutral_sheet
;
; Purpose:crib to demonstrate use of the neutral sheet routines
;      and means for generating plots.
;
; Notes: 1. run it by compiling in idl and then typing ".go"
;        or copy and paste.  
;
; SEE ALSO: idl/external/IDL_GEOPACK/trace/ttrace_crib.pro
;           idl/ssl_general/cotrans/aacgm/aacgm_example.pro
;           idl/themis/examples/thm_crib_tplotxy.pro
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-02-06 12:22:09 -0800 (Thu, 06 Feb 2014) $
; $LastChangedRevision: 14178 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_neutral_sheet.pro $
;-

PRO thm_crib_neutral_sheet
    compile_opt idl2
    ; set the timeframe
    date = '2008-12-27/00:00:00' 
    hrs = 3
    date = time_double(date)-3600*hrs/2
    timespan,date,hrs,/hour

    ; generate points for the neutral sheet models
    time = make_array(121, /double)
    ; space out time points, one every minute
    for i=0, 120l do $
        time[i] = time[i] + i*60 + time_double(date)
    
    gse_pos = make_array(121,3,/double)
    gse_pos[*,0] = (-1.*(dindgen(121)/4.))+8
    
    ;*******************************************************************
    ; This section shows the conversion from GSE to aGSM coordinates
    ; The aberrated GSM (aGSM) coordinate system is defined with the 
    ; 1) X-component along the aberrated solar wind flow direction
    ; 2) XZ plane containing the dipole axis
    ; 3) Y completing the right handed coordinate system
    ;*******************************************************************
    ; The trick is to start with GSE, do the 
    ; aberration and then rotate back into GSM

    ; load solar wind velocity data using OMNI (GSE coordinates, km/s)
    omni_hro_load, varformat=['Vx', 'Vy', 'Vz']
    
    ; remove NaNs from the solar wind velocity 
    tdeflag, ['OMNI_HRO_1min_Vx', 'OMNI_HRO_1min_Vy', 'OMNI_HRO_1min_Vz'], 'remove_nan'

    get_data, 'OMNI_HRO_1min_Vx_deflag', data=Vx_data
    get_data, 'OMNI_HRO_1min_Vy_deflag', data=Vy_data
    get_data, 'OMNI_HRO_1min_Vz_deflag', data=Vz_data
    
    ; do the transformation to aberrated GSM (aGSM) using solar wind velocity loaded from OMNI
    ; output variable: agsm_pos_from_vel
    gse2agsm, {x: time, y: gse_pos}, agsm_pos_from_vel, sw_velocity = [[Vx_data.Y], [Vy_data.Y], [Vz_data.Y]]
    
    ; use aberrated GSM coordinates calculated from velocity data 
    gsm_pos = agsm_pos_from_vel.Y
    stop
    
    ;**************************************************************
    ; This section calculates the distance to the neutral sheet
    ;**************************************************************

    ; get distance from XY plane to the NS using the SM model
    neutral_sheet, time, gsm_pos, model='sm', distance2NS=dz2NS_sm
    ; get distance from XY plane to the NS using the THEMIS model
    neutral_sheet, time, gsm_pos, model='themis', distance2NS=dz2NS_thm
    ; get distance from XY plane to the NS using the AEN model
    neutral_sheet, time, gsm_pos, model='aen', distance2NS=dz2NS_aen
    ; get distance from XY plane to the NS using the den model
    neutral_sheet, time, gsm_pos, model='den', distance2NS=dz2NS_den
    ; get distance from XY plane to the NS using the fairfield model
    neutral_sheet, time, gsm_pos, model='fairfield', distance2NS=dz2NS_fm
    ; get distance from XY plane to the NS using the den-fairfield model
    neutral_sheet, time, gsm_pos, model='den_fairfield', distance2NS=dz2NS_den_fm
    ; get distance from XY plane to the NS using the lopez model 
    neutral_sheet, time, gsm_pos, model='lopez', distance2NS=dz2NS_lm

    ;***********************************************************
    ;This section traces the field lines (Tsyganenko model)
    ;***********************************************************
    
    ; create points for the field line traces
    times = replicate(time_double(date),14)   
    x = [-22,-22,-22,-22,-17,-12,-8,-5,-3,2,4,7,8,8]
    y = replicate(0,14)
    z = [10,7,4,0,replicate(0,9),4]
    trace_pts_north =  [[x],[y],[z]]
    trace_pts_south =  [[x],[y],[-1*z]] 

    ; store the trace data in tplot variables
    store_data,'trace_pts_north',data={x:times,y:trace_pts_north}
    store_data,'trace_pts_south',data={x:times,y:trace_pts_south}

    ;use kp 2.0 for t89 model
    ;actual kp values can be found at: http://www.ngdc.noaa.gov/stp/GEOMAG/kp_ap.html
    ttrace2iono,'trace_pts_north',trace_var_name = 'trace_n', $
    external_model='t89',par=2.0D,in_coord='gsm',out_coord='gsm'
    ttrace2iono,'trace_pts_south',trace_var_name = 'trace_s',$
    external_model='t89',par=2.0D,in_coord='gsm',out_coord='gsm', /south

    ;********************************************************************
    ;This section generates a plot of XZ field lines with neutral 
    ;sheet models over plotted
    ;********************************************************************
    
    thm_init
    window,xsize=950,ysize=700
    
    ;you may want to control the thickness of the generated plots
    ;to make the lines in the output more visible when exported
    ;you can do so with these variables
    axisthick = 1.0
    charthick = 1.0
    linethick = 2.0
    charsize = 1.5
    symsize = 1.0
    landscape=1 ; set landscape = 1 if you want to make any postscripts generated in landscape
    encapsulated=1 ; set encapsulated = 1 if you want any postscripts generated to be eps
    xmargin = [.1,.1]
    ymargin = [.3,.1]
    xrange = [-21,10] ;x range of the xz plot
    zrange = [-11,11] ;z range of the xz plot
    
    ;generate the plot of field lines
    tplotxy,'trace_n',versus='xrz',xrange=xrange,yrange=zrange,charsize=charsize,title="XZ field line/neutral sheet plot (gsm)",subtitle='[Y at 0.0 re]',xthick=axisthick,ythick=axisthick,thick=linethick,background=255,charthick=charthick,ymargin=ymargin,xmargin=xmargin
    tplotxy,'trace_s',versus='xrz',xrange=xrange,yrange=zrange,/over,xthick=axisthick,ythick=axisthick,thick=linethick,charthick=charthick

    ;overplot the neutral sheet models
    oplot, gsm_pos[*,0], dz2NS_aen, color = 220, thick = 1.8
    oplot, gsm_pos[*,0], dz2NS_sm, color = 60, thick = 2.5
    oplot, gsm_pos[*,0], dz2NS_den, color = 90, thick = 1.8
    oplot, gsm_pos[*,0], dz2NS_fm, color = 30, thick = 2.5   
    oplot, gsm_pos[*,0], dz2NS_thm, color = 150, thick = 1.8, linestyle=2
    oplot, gsm_pos[*,0], dz2NS_lm, color = 200, thick = 1.8
    oplot, gsm_pos[*,0], dz2NS_den_fm, color = 250, thick = 1.8, linestyle=2
 
    ;display legend
    xyouts, .1, .22, 'AEN = Orange', color = 220, /normal, charsize=1.25
    xyouts, .1, .19, 'SM = Blue', color = 60, /normal, charsize=1.25
    xyouts, .1, .16, 'DEN = Light Blue', color = 90, /normal, charsize=1.25
    xyouts, .1, .13, 'FM = Purple', color = 30, /normal, charsize=1.25
    xyouts, .1, .10, 'THM = Dashed Green', color = 150, /normal, charsize=1.25
    xyouts, .1, .07, 'LM = Yellow', color = 200, /normal, charsize=1.25
    xyouts, .1, .04, 'DEN_FM = Dashed Red', color = 250, /normal, charsize=1.25

    print, '.c to continue'
    print, 'This is a plot of field lines with the neutral sheet models overplotted.'
    stop
    

    ;*****************************************************
    ; This section calculates the neutral sheet location
    ; at X = -21 Re in the tail and shows the neutral sheet 
    ; profile in the YZ plane
    ;*****************************************************
    
    time = replicate(time_double(date),24)
    x = make_array(24, /double)
    y = findgen(24)-12   
    z = make_array(24, /double)
    
    gsm_pos = make_array(24,3,/double)
    gsm_pos[*,0] = x-21
    gsm_pos[*,1] = y 
    gsm_pos[*,2] = z 

    ; note: we're not using the SM model here because it is not valid at X=-21 Re
    ; get distance from XY plane to the NS using the THEMIS model
    neutral_sheet, time, gsm_pos, model='themis', distance2NS=dz2NS_thm
    ; get distance from XY plane to the NS using the AEN model
    neutral_sheet, time, gsm_pos, model='aen', distance2NS=dz2NS_aen
    ; get distance from XY plane to the NS using the den model
    neutral_sheet, time, gsm_pos, model='den', distance2NS=dz2NS_den
    ; get distance from XY plane to the NS using the fairfield model
    neutral_sheet, time, gsm_pos, model='fairfield', distance2NS=dz2NS_fm
    ; get distance from XY plane to the NS using the den-fairfield model
    neutral_sheet, time, gsm_pos, model='den_fairfield', distance2NS=dz2NS_den_fm
    ; get distance from XY plane to the NS using the lopez model 
    neutral_sheet, time, gsm_pos, model='lopez', distance2NS=dz2NS_lm
    
    window, xsize=750, ysize=750
    xmargin = [17,17]
    ymargin = [25,5]

    ;overplot the neutral sheet models
    plot, gsm_pos[*,1], dz2NS_aen, color = 0, thick = 1.8, xtitle='Y', ytitle='Z', $
          xmargin=xmargin, ymargin=ymargin, yrange=[-11,11], $
          title='YZ Neutral sheet plot (gsm)', charsize=1.5, $
          subtitle = '[X at -21.0 re]'
    oplot, gsm_pos[*,1], dz2NS_aen, color = 220, thick = 1.8
    oplot, gsm_pos[*,1], dz2NS_sm, color = 60, thick = 2.
    oplot, gsm_pos[*,1], dz2NS_den, color = 90, thick = 1.8
    oplot, gsm_pos[*,1], dz2NS_fm, color = 30, thick = 2.5   
    oplot, gsm_pos[*,1], dz2NS_thm, color = 150, thick = 1.8, linestyle=2
    oplot, gsm_pos[*,1], dz2NS_lm, color = 200, thick = 1.8
    oplot, gsm_pos[*,1], dz2NS_den_fm, color = 250, thick = 1.8, linestyle=2
   
    ;display legend
    xyouts, .1, .22, 'AEN = Orange', color = 220, /normal, charsize=1.25
    xyouts, .1, .19, 'SM = Blue', color = 60, /normal, charsize=1.25
    xyouts, .1, .16, 'DEN = Light Blue', color = 90, /normal, charsize=1.25
    xyouts, .1, .13, 'FM = Purple', color = 30, /normal, charsize=1.25
    xyouts, .1, .10, 'THM = Dashed Green', color = 150, /normal, charsize=1.25
    xyouts, .1, .07, 'LM = Yellow', color = 200, /normal, charsize=1.25
    xyouts, .1, .04, 'DEN_FM = Dashed Red', color = 250, /normal, charsize=1.25

    ;times = replicate(time_double(date),31)
    bx = make_array(24, /double)
    by = make_array(24, /double)
    bz = make_array(24, /double)
    times=time
    gsm_pos[*,0] = x-21
    gsm_pos[*,1] = y 

    FOR i=0,n_elements(time)-1 DO BEGIN
  
        ;recalculate geomagnetic dipole tilt
        time=time_struct(times[i])
        geopack_recalc, time.year, time.doy, time.hour, time.min, time.sec, tilt=tilt
      
        ;calculate internal contribution
        geopack_igrf_gsm, gsm_pos[i,0], gsm_pos[i,1], gsm_pos[i,2], igrf_bx, igrf_by, igrf_bz 
        ;calculate external contribution, iopt = kp+1
        geopack_t89, 2, gsm_pos[i,0], gsm_pos[i,1], gsm_pos[i,2], t89_bx,t89_by, t89_bz, tilt = tilt
      
        ;sum total contribution
        bx[i] = igrf_bx + t89_bx
        by[i] = igrf_by + t89_by
        bz[i] = igrf_bz + t89_bz
   
    ENDFOR    

    print, 'Done'
    print, '.c to continue'
    stop

END