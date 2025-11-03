pro swfo_reaction_wheel_plot_output,tr,archive=archive
  if keyword_set(archive) then begin
    trs = 0
    append_array, trs, ['2025-10-01/20:37:40', '2025-10-01/21:30:00']   ; first occurance
    append_array, trs, ['2025-10-02/23:29:30', '2025-10-03/04:28:10'] ;  IRU invalid;  no signature in stis
    append_array, trs,   ['2025-10-03/23:55:00', '2025-10-04/01:17:40']   ; extremely weak ; not clearly a reaction wheel resonance - Not detectable in science
    append_array, trs,  ['2025-10-04/08:04:40', '2025-10-04/10:52:20'] ; Medium event  ; invalid IRU
    append_array, trs, ['2025-10-04/17:30:30', '2025-10-04/18:12:40']   ; Med event - does not affect science -  Occurs just prior to type 3 electron event
    append_array, trs, ['2025-10-04/19:14:00', '2025-10-04/19:45:30']  ; Barely detectable in STIS -  INVALID IRU
    append_array, trs, ['2025-10-05/05:09:00', '2025-10-05/05:37:20']  ; Barely detectable  - INVALID IRU
    append_array, trs, ['2025-10-05/06:25:20', '2025-10-05/06:41:30']  ; Detectable - meets science requirement
    append_array, trs, ['2025-10-06/21:49:40', '2025-10-06/22:41:40']   ; barely detectable in stis  INVALID IRU
    append_array, trs,['2025-10-06/23:43:40', '2025-10-06/23:55:00']    ; low noise - only briefly affects channel 1 


    append_array, trs,    ['2025-10-12/17:07:26', '2025-10-12/17:35:00']    ;    Not detected with STIS   IRU is invalid
    append_array, trs,    ['2025-10-13/04:39:14', '2025-10-13/05:08:08']   ;    ; Affects STIS channels 1 and 2 only   (IRU is valid)
    append_array, trs,    ['2025-10-14/01:03:30', '2025-10-14/01:39:30']   ;    IRU invalid   ; noise < 2 sigma   ; not seen in science
    append_array, trs,    ['2025-10-14/10:41:00', '2025-10-14/11:32:00'] ;    IRU invalid   ; noise < 2 sigma   ; not seen in science

    append_array, trs, ['2025-10-14/21:13:08',  '2025-10-14/22:03:10']   ;
    append_array, trs, ['2025-10-15/09:50:00','2025-10-15/12:16:00']  ;
    append_array, trs, ['2025-10-15/17:42:00','2025-10-15/19:29:20']
    
    append_array, trs, ['2025-10-20/21:57:00','2025-10-20/22:51:00']   ;
    append_array, trs, ['2025-10-21/09:16:00','2025-10-21/09:27:00']   ;  Invalid IRU,  no signature in STIS
    
    
    append_array, trs,       ['2025-10-20/21:56:30', '2025-10-20/22:50:10']  ; IRU valid    Channel 1 sigma= 8.55
    append_array, trs,       ['2025-10-21/19:16:30', '2025-10-21/19:31:50']  ; IRU invalid   No signature  in stis   sigma <2
    
    
    append_array, trs,       ['2025-10-22/15:02:30', '2025-10-22/16:49:00']  ; IRU Invalid    channel1 sigma=9.72
    append_array, trs,       ['2025-10-22/21:34:30', '2025-10-22/22:42:30']  ; IRU valid      cn1 sigma= 2.93
    append_array, trs,       ['2025-10-23/03:56:00', '2025-10-23/05:28:00']  ; IRU valid     ch1 sigma = 5.84
    append_array, trs,       ['2025-10-23/06:53:49', '2025-10-23/06:54:09']  ; IRU invalid    (NO signature in STIS)   sigma <2
    append_array, trs,       ['2025-10-23/11:53:30', '2025-10-23/14:39:30']  ; IRU invalid   ch1sigma = 12.46   ch2sigma= 5.24  ch5s=5.74  severe
    append_array, trs,       ['2025-10-26/16:11:00', '2025-10-26/17:01:00']  ; IRU valid  sigma1= >3.9  sig2=2.24   sigm5=1.97
    append_array, trs,       ['2025-10-27/00:14:46', '2025-10-27/00:15:54']  ; IRU valid  sigma1 =2.55
    
    trs = reform(trs,2,n_elements(trs)/2)
    timebar,trs
    for i=0,dimen2(trs)-1  do    swfo_reaction_wheel_plot_output,trs[*,i]
    return
  endif

  if n_elements(tr) ne 2 then   ctime,tr,/silent

  sigma_name = 'swfo_stis_L1a_NOISE_SIGMA'
  wheels_name = 'swfo_stis_L0b_REACTION_WHEEL_SPEED_RPM'



  sigma = tsample(sigma_name,tr)
  sigma_max = max(sigma,dimen=1)

  wheels = transpose(data_cut(wheels_name,time_double(tr)))


  ;print

  print,time_string(tr),wheels,sigma_max,format='%s, %s,  %6.0f, %6.0f,   %6.0f, %6.0f,   %6.0f, %6.0f,    %6.0f, %6.0f,      %5.2f, %5.2f, %5.2f, %5.2f, %5.2f, %5.2f  '


  if 0  then begin
  
  endif




end





pro swfo_reaction_wheel_plot_crib ,trange

  sigma_name = 'swfo_stis_L1a_NOISE_SIGMA'
  wheels_name = 'swfo_stis_L0b_REACTION_WHEEL_SPEED_RPM'

  sigma_name = 'swfo_stis_L1a_NOISE_SIGMA'
  wheels_name = 'swfo_stis_L0b_REACTION_WHEEL_SPEED_RPM'

  ;sigma_name  = 'swfo_stis_L0b_IRU_BITS'

  if 0 then begin
    sigma = tsample(sigma_name,trange,times=times)
    wheels = data_cut(wheels_name,times)
  endif
  ; plot,wheels[*,0], sigma[*,0]


  xlim,lim,-4000,6000
  options,lim,charsize=2,ytitle='SIGMA'
  if 0  then begin
    !p.multi = [0,0,4]
    options,lim,xtitle='#1  WHEEL SPEED (RPM)'
    scat_plot,WHEELs_name,SIGMA_name,xdimen=0,ydimen=0,lim=lim,trange=trange
    options,lim,xtitle='#2  WHEEL SPEED (RPM)'
    scat_plot,WHEELs_name,SIGMA_name,xdimen=1,ydimen=0,lim=lim,trange=trange
    options,lim,xtitle='#3  WHEEL SPEED (RPM)'
    scat_plot,WHEELs_name,SIGMA_name,xdimen=2,ydimen=0,lim=lim,trange=trange
    options,lim,xtitle='#4  WHEEL SPEED (RPM)'
    scat_plot,WHEELs_name,SIGMA_name,xdimen=3,ydimen=0,lim=lim,trange=trange
    !p.multi = 0

  endif else begin
    options,lim,xtitle='#1  WHEEL SPEED (RPM)'
    scat_plot,WHEELs_name,SIGMA_name,xdimen=0,ydimen=0,lim=lim,trange=trange,/over ;,color=6

  endelse


end
