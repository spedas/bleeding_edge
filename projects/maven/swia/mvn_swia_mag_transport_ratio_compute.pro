;+
;PROCEDURE: 
; MVN_SWIA_MAG_TRANSPORT_RATIO_COMPUTE
;PURPOSE: 
; COMPUTE TRANSPORT RATIOS FOR WAVE MODE IDENTIFICAITON  
;
;INPUT:   
;
;KEYWORDS:
; NDATA: tplot variable for the density
; VDATA: tplot variable for the velocity
; BDATA: tplot variable for the magnetic field 

;
;AUTHOR:  Suranga Ruhunusiri 
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-03-24 08:35:45 -0700 (Tue, 24 Mar 2015) $
; $LastChangedRevision: 17171 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_mag_transport_ratio_compute.pro $
;
;-
pro mvn_swia_mag_transport_ratio_compute, ndata = ndata, vdata = vdata, bdata=bdata
print,'Use button 1 to select time; button 3 to quit.'
ctime,tr,npoints = 2
if not keyword_set(ndata) then ndata = 'mvn_swim_density'
if not keyword_set(vdata) then vdata = 'mvn_swim_velocity'
if not keyword_set(bdata) then bdata = 'mvn_B_1sec'

av_factor = 2.00;
inc_time = 4.0*av_factor
inc_time_2 = 60.0*av_factor 
 
get_data,ndata, data=n_dat
get_data,vdata, data=V_dat
get_data,bdata, data=B_dat 
   
;t = yymmdd_to_time(141215,0000)
;t2 = yymmdd_to_time(141230,0000) 
trange = tr ;[t,t2]

 w3 = where(B_dat.x ge trange(0) and B_dat.x le trange(1)) 
 w4 = where(V_dat.x ge trange(0) and V_dat.x le trange(1))

;mag field
var_B_time = B_dat.x[w3,*]
var_B = B_dat.y[w3,*]
  
;veleocity 
var_V_time = V_dat.x[w4,*]
var_V = V_dat.y[w4,*]
  
time_fin = var_V_time

;density
 Var_n = n_dat.y[w4,*]

;mag components
B_x = var_B(*,0)
B_y = var_B(*,1)
B_z = var_B(*,2)

;velocity components
V_x = var_V(*,0)
V_y = var_V(*,1)
V_z = var_V(*,2)

ave_60_s_inte = (max(var_V_time) - min(var_V_time))/inc_time
ave_60_s_inte = long(ave_60_s_inte)
temp_sta_time = min(var_V_time)
var_B_time = var_B_time - min(var_B_time)
var_V_time = var_V_time - min(var_V_time)
time_temp = Var_V_time - Var_V_time

Energy_dat_t = Make_Array(ave_60_s_inte,1,/double)
Spectra_TR = Make_Array(ave_60_s_inte,17,/double)
Spectra_DR = Make_Array(ave_60_s_inte,17,/double)
Spectra_PR = Make_Array(ave_60_s_inte,17,/double)
Spectra_CR = Make_Array(ave_60_s_inte,17,/double)
Wave_Mode  = Make_Array(ave_60_s_inte,17,/double)
Power_spectra = Make_Array(ave_60_s_inte,17,/double)
Max_mode_TR = Make_Array(ave_60_s_inte,1,/double)
Max_mode_DR = Make_Array(ave_60_s_inte,1,/double)
Max_mode_PR = Make_Array(ave_60_s_inte,1,/double)
Max_mode_CR =Make_Array(ave_60_s_inte,1,/double)
Max_wave_mode = Make_Array(ave_60_s_inte,1,/double)
Max_freq = Make_Array(ave_60_s_inte,1,/double);time_temp;

Spectra_holder_2 = Make_Array(ave_60_s_inte,17,/double)
freqline = Make_Array(ave_60_s_inte,17,/double)
Ellip_spectra = Make_Array(ave_60_s_inte,17,/double)
Max_mode_ellip = Make_Array(ave_60_s_inte,1,/double)
Ion_cyc_wave = Make_Array(ave_60_s_inte,1,/double)
gyro_freq_holder =Make_Array(ave_60_s_inte,1,/double)
counter_start = 0
print, 'processing.....'
for inc=1L,ave_60_s_inte do begin
start_time = min(var_V_time) + inc_time*(inc-1)
end_time = start_time + inc_time_2
    
Energy_dat_t[inc-1,0] =  temp_sta_time +(start_time+end_time)/2.0
    
if 5*double(inc)/(ave_60_s_inte-1) gt (counter_start+1) then begin
dprint, strtrim(100*long(inc)/(ave_60_s_inte-1),2) + ' % Complete '
counter_start++
endif

w_my= where(var_V_time ge start_time and var_V_time lt end_time)
w_my_3= where(var_B_time ge start_time and var_B_time lt end_time)

B_x_temp = B_x[w_my_3,*]
B_y_temp = B_y[w_my_3,*]
B_z_temp = B_z[w_my_3,*]
V_x_temp = V_x[w_my,*]
V_y_temp = V_y[w_my,*]
V_z_temp = V_z[w_my,*]
 
Var_V_time_temp = Var_V_time[w_my,*]
Var_n_temp = Var_n[w_my,*]
  
if (n_elements(B_x_temp) EQ 60*av_factor ) and (n_elements(V_x_temp) EQ 15*av_factor) then begin
     
    inc_max = n_elements(V_x_temp)
   
    B_x_temp_2 = V_x_temp
    B_y_temp_2 = V_x_temp
    B_z_temp_2 = V_x_temp
   
    track = 0
      
    ;B_field averaging
      
    for inc_i=0,(inc_max-1) do begin
        
        temp_sum_B_x = 0.0
        temp_sum_B_y = 0.0
        temp_sum_B_z = 0.0
        track = 4*inc_i
        
        for i=0,3 do begin
          
          temp_sum_B_x  = temp_sum_B_x + B_x_temp(track,0)
          temp_sum_B_y  = temp_sum_B_y + B_y_temp(track,0)
          temp_sum_B_z  = temp_sum_B_z + B_z_temp(track,0)
          track= track+1
          
        endfor
        
        B_x_temp_2(inc_i,0) = temp_sum_B_x/4.0
        B_y_temp_2(inc_i,0) = temp_sum_B_y/4.0
        B_z_temp_2(inc_i,0) = temp_sum_B_z/4.0

      endfor

      B_x_temp = B_x_temp_2
      B_y_temp = B_y_temp_2
      B_z_temp = B_z_temp_2
      
 

      var_B_time_temp = var_V_time_temp
      
      B_0_x_unit_vec = mean(B_x_temp)/sqrt(mean(B_x_temp)^2 + mean(B_y_temp)^2 + mean(B_z_temp)^2)
      B_0_y_unit_vec = mean(B_y_temp)/sqrt(mean(B_x_temp)^2 + mean(B_y_temp)^2 + mean(B_z_temp)^2)
      B_0_z_unit_vec = mean(B_z_temp)/sqrt(mean(B_x_temp)^2 + mean(B_y_temp)^2 + mean(B_z_temp)^2)

      B_perp_1_x_unit =  B_0_y_unit_vec/sqrt( B_0_y_unit_vec^2+ B_0_x_unit_vec^2)
      B_perp_1_y_unit =  -B_0_x_unit_vec/sqrt( B_0_y_unit_vec^2+ B_0_x_unit_vec^2)

      B_perp_2_x_unit = -B_0_z_unit_vec*B_perp_1_y_unit
      B_perp_2_y_unit = B_0_z_unit_vec*B_perp_1_x_unit
      B_perp_2_z_unit = B_0_x_unit_vec*B_perp_1_y_unit-B_0_y_unit_vec*B_perp_1_x_unit
      B_perp_2_unit_mag = sqrt(B_perp_2_x_unit^2 + B_perp_2_y_unit^2 + B_perp_2_z_unit^2)
      B_perp_2_x_unit = B_perp_2_x_unit/B_perp_2_unit_mag
      B_perp_2_y_unit = B_perp_2_y_unit/B_perp_2_unit_mag
      B_perp_2_z_unit = B_perp_2_z_unit/B_perp_2_unit_mag

      B_perp_1 = B_x_temp
      B_perp_2 = B_x_temp
      B_parallel = B_x_temp
      B_total = B_x_temp
      V_total = B_x_temp

      V_perp_1 = B_x_temp
      V_perp_2 = B_x_temp

      for inc_i=0,(n_elements(B_x_temp)-1) do begin
        ;B_parallel
        B_parallel(inc_i,0) = B_0_x_unit_vec*B_x_temp(inc_i,0) + B_0_y_unit_vec*B_y_temp(inc_i,0) + B_0_z_unit_vec*B_z_temp(inc_i,0)
        ;B_total
        B_total(inc_i,0) = sqrt(B_x_temp(inc_i,0)^2 + B_y_temp(inc_i,0)^2 + B_z_temp(inc_i,0)^2)
        ;V_total
        V_total(inc_i,0) = sqrt(V_x_temp(inc_i,0)^2 + V_y_temp(inc_i,0)^2 + V_z_temp(inc_i,0)^2)
        ;B_perp
        B_perp_1(inc_i,0) = B_perp_1_x_unit*B_x_temp(inc_i,0) + B_perp_1_y_unit*B_y_temp(inc_i,0)
        B_perp_2(inc_i,0) = B_perp_2_x_unit*B_x_temp(inc_i,0) + B_perp_2_y_unit*B_y_temp(inc_i,0)+ B_perp_2_z_unit*B_z_temp(inc_i,0)
        ;V_perp
        V_perp_1(inc_i,0) = B_perp_1_x_unit*V_x_temp(inc_i,0) + B_perp_1_y_unit*V_y_temp(inc_i,0)
        V_perp_2(inc_i,0) = B_perp_2_x_unit*V_x_temp(inc_i,0) + B_perp_2_y_unit*V_y_temp(inc_i,0)+ B_perp_2_z_unit*V_z_temp(inc_i,0)
    
      endfor


;Fouriter transform of moments & fields
      var_B_time_temp = var_B_time_temp-min(var_B_time_temp)
      var_B_mag = B_parallel
      fft_B_mag = fft(var_B_mag)
      nopfft_B_mag = n_elements(var_B_mag)
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      F_s_B_mag = (n_elements(var_B_time_temp)-1)/(max(var_B_time_temp)-min(var_B_time_temp))
      f_B_mag =var_B_time_temp[0:(nopfft_B_mag/2+1)]
      f_B_mag= f_B_mag/max(f_B_mag)
      f_B_mag = (F_s_B_mag/2)*f_B_mag
      Y_B_parallel = 2*halfresult_B_mag 
      Y_B_parallel(0,0)=0

      var_B_mag = B_perp_1
      fft_B_mag = fft(var_B_mag)
      Y_B_perp_1_full = fft_B_mag 
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_B_perp_1 = 2*halfresult_B_mag
      Y_B_perp_1(0,0)=0
  
      var_B_mag = B_perp_2
      fft_B_mag = fft(var_B_mag)
      Y_B_perp_2_full = fft_B_mag 
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_B_perp_2 = 2*halfresult_B_mag
      Y_B_perp_2(0,0)=0
        
      var_B_mag = B_x_temp
      fft_B_mag = fft(var_B_mag)
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_B_X = 2*halfresult_B_mag
      Y_B_X(0,0)=0

      var_B_mag = B_y_temp
      fft_B_mag = fft(var_B_mag)
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_B_Y = 2*halfresult_B_mag
      Y_B_Y(0,0)=0

      var_B_mag = B_z_temp
      fft_B_mag = fft(var_B_mag)
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_B_Z = 2*halfresult_B_mag
      Y_B_Z(0,0)=0

      var_B_mag = Var_n_temp
      fft_B_mag = fft(var_B_mag)
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_n = 2*halfresult_B_mag
      Y_n(0,0)=0

      var_B_mag = V_x_temp
      fft_B_mag = fft(var_B_mag)
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_V_X = 2*halfresult_B_mag
      Y_V_X(0,0)=0

      var_B_mag = V_y_temp
      fft_B_mag = fft(var_B_mag)
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_V_Y = 2*halfresult_B_mag
      Y_V_Y(0,0)=0

      var_B_mag = V_z_temp
      fft_B_mag = fft(var_B_mag)
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_V_Z = 2*halfresult_B_mag
      Y_V_Z(0,0)=0

      var_B_mag = B_total
      fft_B_mag = fft(var_B_mag)
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_mag_B = 2*halfresult_B_mag
      Y_mag_B(0,0)=0

      var_B_mag = V_total
      fft_B_mag = fft(var_B_mag)
      halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
      Y_mag_V = 2*halfresult_B_mag
      Y_mag_V(0,0)=0
        

        var_B_mag = V_perp_1
        fft_B_mag = fft(var_B_mag)
        halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
        Y_V_perp_1 = 2*halfresult_B_mag
        Y_V_perp_1(0,0)=0
        
        ;fft of V_perp_2
        var_B_mag = V_perp_2
        fft_B_mag = fft(var_B_mag)
        halfresult_B_mag = fft_B_mag[0:(nopfft_B_mag /2+1)]
        Y_V_perp_2 = 2*halfresult_B_mag
        Y_V_perp_2(0,0)=0
        

        
        
        mean_B = mean(B_total)
        mean_N = mean(Var_n_temp)
        mean_V = mean(V_total)
        
        m_i = 1.00794*1.6605e-27
        prot_cyc_freq  = 1.602e-19*mean_B*1e-9/(2*(!pi)*m_i)
        for inc_i=0,(n_elements(f_B_mag)-1) do begin
          del_B_del_B = Y_B_X(inc_i,0)*conj(Y_B_X(inc_i,0)) + Y_B_Y(inc_i,0)*conj(Y_B_Y(inc_i,0))+Y_B_Z(inc_i,0)*conj(Y_B_Z(inc_i,0))
          del_V_del_V = Y_V_X(inc_i,0)*conj(Y_V_X(inc_i,0)) + Y_V_Y(inc_i,0)*conj(Y_V_Y(inc_i,0))+Y_V_Z(inc_i,0)*conj(Y_V_Z(inc_i,0))
          Transverse_ratio = (del_B_del_B-Y_B_parallel(inc_i,0)*conj(Y_B_parallel(inc_i,0)))/(Y_B_parallel(inc_i,0)*conj(Y_B_parallel(inc_i,0)))
          Comp_ratio = ((Y_n(inc_i,0)*conj(Y_n(inc_i,0)))/mean_N^2)*(mean_B^2/(del_B_del_B))
         tem_fr = f_B_mag(1,0) - f_B_mag(0,0)
          real_phase=real_part(((Y_n(inc_i,0))/mean_N)*(mean_B/(Y_B_parallel(inc_i,0))))
          imag_phase=imaginary(((Y_n(inc_i,0))/mean_N)*(mean_B/(Y_B_parallel(inc_i,0))))
          Phase_ratio =real_phase/sqrt(real_phase^2+imag_phase^2)
          
          Dop_ratio = (del_V_del_V*mean_B^2)/(mean_V^2*del_B_del_B)
        
          
         
        
          Spectra_TR[inc-1,inc_i] = Transverse_ratio;alog(Transverse_ratio(inc_i,0))
          
          Spectra_DR[inc-1,inc_i] = Dop_ratio
          Spectra_PR[inc-1,inc_i] = Phase_ratio
           Spectra_CR[inc-1,inc_i] =Comp_ratio

          freqline[inc-1,inc_i] = tem_fr*inc_i  ;0.12-
          Power_spectra[inc-1,inc_i] = sqrt(del_B_del_B)/mean_B
          
          Y_B_min_X  = Y_B_perp_1(inc_i,0)
          Y_B_min_Y  = Y_B_perp_2(inc_i,0)
Pow_spec_xx = (Y_B_min_X*conj(Y_B_min_X))
Pow_spec_xy = (Y_B_min_X*conj(Y_B_min_Y))
Pow_spec_yx = (Y_B_min_Y*conj(Y_B_min_X))
Pow_spec_yy = (Y_B_min_Y*conj(Y_B_min_Y))

det_J = real_part(Pow_spec_xx*Pow_spec_yy-Pow_spec_xy*Pow_spec_yx)
Tr_J = real_part(Pow_spec_xx+Pow_spec_yy)

min_method_pol = 100.0*sqrt(1.0-4.0*det_J/(Tr_J^2))

sin_2pi = 2.0*imaginary(Pow_spec_xy)/sqrt(Tr_J^2-4.0*det_J)

pi_2 = asin(sin_2pi)

Ellip_spectra[inc-1,inc_i] = tan(pi_2/2.0)
         
        endfor
        
        gyro_freq_holder[inc-1,0]  =  prot_cyc_freq 
        
         track_power = where(Power_spectra[inc-1,*] eq  max(Power_spectra[inc-1,*]))
         if n_elements(track_power) eq 1 then begin
         Max_mode_TR[inc-1,0] = Spectra_TR[inc-1,track_power]
         Max_mode_PR[inc-1,0] = Spectra_PR[inc-1,track_power]
         Max_mode_CR[inc-1,0] = Spectra_CR[inc-1,track_power]
         Max_mode_DR[inc-1,0] = Spectra_DR[inc-1,track_power]
         Max_freq[inc-1,0] = freqline[inc-1,track_power]
         Max_mode_ellip[inc-1,0] = Ellip_spectra[inc-1,track_power]
         endif
         
         for inc_i=0,(n_elements(f_B_mag)-1) do begin
         
         
         
         if (Spectra_TR[inc-1,inc_i] GT 1) and  (Spectra_CR[inc-1,inc_i] LT 0.1) then begin
         Wave_Mode(inc-1, inc_i-1) = 4 ; Alfven
         endif
         if (Spectra_TR[inc-1,inc_i] GT 1) and  (Spectra_CR[inc-1,inc_i] GT 1) then begin
         Wave_Mode(inc-1, inc_i-1) = 10 ;Fast
         endif
         if (Spectra_TR[inc-1,inc_i] LT 1) and  (Spectra_PR[inc-1,inc_i] GT 0) then begin
         Wave_Mode(inc-1, inc_i-1) = 10 ;Fast
         endif
         if (Spectra_TR[inc-1,inc_i] LT 1) and  (Spectra_PR[inc-1,inc_i] LT 0) and (Spectra_DR[inc-1,inc_i] GE 1) then begin
         Wave_Mode(inc-1, inc_i-1) = 16 ;Slow
         endif
         if (Spectra_TR[inc-1,inc_i] LT 1) and  (Spectra_PR[inc-1,inc_i] LT 0) and (Spectra_DR[inc-1,inc_i] LT 0.1) then begin
         Wave_Mode(inc-1, inc_i-1) = 22 ;Mirror
         endif
         
         
         endfor 
         
    if (Max_mode_TR[inc-1,0] GT 1.0) and  (Max_mode_CR[inc-1,0] LT 0.2) and (Max_mode_ellip [inc-1,0] LT -0.5) and (Max_freq[inc-1,0]/prot_cyc_freq LT 1.5) and (Max_freq[inc-1,0]/prot_cyc_freq Gt 0.5) then begin
    Ion_cyc_wave[inc-1,0] = 4.0 ;ICW
    endif
         
         if (Max_mode_TR[inc-1,0] GT 1.0) and  (Max_mode_CR[inc-1,0] LT 0.1) then begin
         Max_wave_mode[inc-1,0] = 4.0 ; Alfven
        
         endif
         if (Max_mode_TR[inc-1,0] GT 1.0) and  (Max_mode_CR[inc-1,0] GE 0.1) and (Max_mode_CR[inc-1,0] LT 1.0)  then begin
         Max_wave_Mode[inc-1, 0] = 7.0 ;Fast & Alfven intermediate
         
         endif
         if (Max_mode_TR[inc-1,0] GT 1.0) and  (Max_mode_CR[inc-1,0] GE 1.0) then begin
         Max_wave_mode[inc-1, 0] = 10 ;Fast
         endif
         if (Max_mode_TR[inc-1,0] LT 1.0) and  (Max_mode_PR[inc-1,0] GT 0) then begin
         Max_wave_mode[inc-1, 0] = 10 ;Fast
         endif
          if (Max_mode_TR[inc-1,0] LT 1) and  (Max_mode_PR[inc-1,0] LT 0) and (Max_mode_DR[inc-1,0] GE 1) then begin
         Max_wave_mode[inc-1,0] = 16 ;Slow
         endif
         if (Max_mode_TR[inc-1,0] LT 1) and  (Max_mode_PR[inc-1,0] LT 0) and (Max_mode_DR[inc-1,0] LE 0.1) then begin
         Max_wave_mode[inc-1, 0] = 22 ;Mirror
         endif
         if (Max_mode_TR[inc-1,0] LT 1) and  (Max_mode_PR[inc-1,0] LT 0) and (Max_mode_DR[inc-1,0] GT 0.1) and (Max_mode_DR[inc-1,0] LT 1) then begin
         Max_wave_mode(inc-1, 0) = 19 ;Mirror & Slow like
         endif
         
         
     
     
   
    endif
  
  endfor

  
          Spectra_TR = alog10(Spectra_TR)
          Spectra_DR = alog10(Spectra_DR)
          Spectra_CR = alog10(Spectra_CR)
            
          Max_mode_TR = alog10(Max_mode_TR)
          Max_mode_CR = alog10(Max_mode_CR)
          Max_mode_DR = alog10(Max_mode_DR)
          
creat_vec = {x:Energy_dat_t,y:Spectra_TR, v:freqline} 
store_data,'T_R',data=creat_vec,dlimits = {spec:1B} 
creat_vec = {x:Energy_dat_t,y:Spectra_CR, v:freqline} 
store_data,'C_R',data=creat_vec,dlimits = {spec:1B} 
creat_vec = {x:Energy_dat_t,y:Spectra_PR, v:freqline} 
store_data,'P_R',data=creat_vec,dlimits = {spec:1B} 
creat_vec = {x:Energy_dat_t,y:Spectra_DR, v:freqline} 
store_data,'D_R',data=creat_vec,dlimits = {spec:1B} 
creat_vec = {x:Energy_dat_t,y:Wave_Mode, v:freqline} 
store_data,'Wave_Mode',data=creat_vec,dlimits = {spec:1B} 
creat_vec = {x:Energy_dat_t,y:Ellip_spectra, v:freqline} 
store_data,'Ellipticity',data=creat_vec,dlimits = {spec:1B} 
creat_vec = {x:Energy_dat_t,y:Max_mode_TR} 
store_data,'max_mode_TR',data=creat_vec
creat_vec = {x:Energy_dat_t,y:Max_mode_CR} 
store_data,'max_mode_CR',data=creat_vec
creat_vec = {x:Energy_dat_t,y:Max_mode_PR} 
store_data,'max_mode_PR',data=creat_vec
creat_vec = {x:Energy_dat_t,y:Max_mode_DR} 
store_data,'max_mode_DR',data=creat_vec
creat_vec = {x:Energy_dat_t,y:Max_wave_mode} 
store_data,'max_wave_mode',data=creat_vec
creat_vec = {x:Energy_dat_t,y:Max_freq} 
store_data,'max_mode_freq',data=creat_vec
creat_vec = {x:Energy_dat_t,y:gyro_freq_holder} 
store_data,'Gyro_freq',data=creat_vec
creat_vec = {x:Energy_dat_t,y:Max_mode_ellip} 
store_data,'max_mode_ellip',data=creat_vec
creat_vec = {x:Energy_dat_t,y:Ion_cyc_wave} 
store_data,'ICW_status',data=creat_vec
options,'ICW_status',colors=['r']
options,'max_wave_mode',colors=['b']
options,'Gyro_freq',colors=['r']
store_data,'max_mode_and_gyro_freq',data=['Gyro_freq','max_mode_freq']

print, '**Max wave mode panel key**'
print, ''
print, ' 4 ==> Alfven & Q-// Slow'
print, '10 ==> Q-// Fast or Q-_|_ Fast'
print, ' 7 ==> Alfven and Q-// Fast like'
print, '16 ==> Q-_|_ Slow'
print, '22 ==> Mirror'
print, '19 ==> Q_|_ Slow & Mirror like'
print, ' 0 ==> Unclassified'

end
