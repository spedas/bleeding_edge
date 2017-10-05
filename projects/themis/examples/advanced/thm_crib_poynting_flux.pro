;+
;Procedure:
;  thm_crib_poynting_flux
;
;Purpose:
;  This crib sheet shows how to correct the THEMIS-EFI high-frequency
;  data to compensate for the transfer function, and then shows how to 
;  calculate Poynting flux from the EFI and SCM data.
;
;Notes:
;  
;
;History:
;  2012-05-23, jmm, changed input to have user prompted for test case.
;  2015-05-14,  af, integrating thm_validate_high_freq_using_phase into this crib 
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-14 17:01:41 -0700 (Thu, 14 May 2015) $
;$LastChangedRevision: 17619 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_poynting_flux.pro $
;-


;===============================
; Set the time and satellite for the event
;===============================

start_input:


print, 'Input 1 for Whistler sampled at 8 kHz, THEMIS D, 2008-06-05 12:48:47 to 2008-06-05 12:48:54'
print, 'Input 2 for Oblique whistler sampled at 16 kHz, THEMIS D, 2010-01-01 00:10:02 to 2010-01-01 00:10:07.9'
print, 'Input 3 for Whistler sampled at 16 kHz, THEMIS E, 2009-07-26 12:26:40 to 2009-07-26 12:27:00'

read, tc, prompt='Choose test case (1, 2, or 3):  '

case tc of
  1: begin ; Whistler sampled at 8 kHz
       timespan,'2008-06-05'
       probe='d'
       interval=[str2time('2008-06-05 12:48:47'),str2time('2008-06-05 12:48:54')]
       trange=interval+[2.5,-2.5]
       power_cutoff=0.1 ; lowest power shown on 1D timeseries plots of phase, etc.
       ave_phase_yrange=[0,180]
     end
  2: begin ; Oblique whistler sampled at 16 kHz.
       timespan,'2010-01-01'
       probe='d'
       interval=[str2time('2010-01-01 00:10:02'),str2time('2010-01-01 00:10:07.9')]
       trange=interval+[3.0,-0.5]
       power_cutoff=0.1 ; lowest power shown on 1D timeseries plots of phase, etc.
       ave_phase_yrange=[180,360]
     end
  3: begin ; Whistler sampled at 16 kHz.
       timespan,'2009-07-26'
       probe='e'
       interval=[str2time('2009-07-26 12:26:40'),str2time('2009-07-26 12:27:00')]
       trange=interval+[4.5,-13.5]
       power_cutoff=0.03 ; lowest power shown on 1D timeseries plots of phase, etc.
       ave_phase_yrange=[0,180]
   end
   else: begin
       print, 'Please input 1, 2, or 3'
       goto, start_input
   end
endcase

;===============================
; Load the data
;===============================

thm_load_state,probe=probe[0], /get_support_data
thm_load_efi,probe=probe[0],datatype='efw',coord='dsl',trange=interval+[-10,10]
thm_load_scm,probe=probe[0],datatype='scw',coord='dsl',trange=interval+[-10,10],nk=256,/edge_truncate,fmin=10.0,fcut=10.0,despin=0
thm_load_fgm,probe=probe[0],datatype='fgs',coord='dsl',level='l2'

; rotate to FAC
tsmooth2, 'th'+probe[0]+'_fgs_dsl', 5, newname = 'smooth_B'
thm_fac_matrix_make, 'smooth_B', other_dim='Zdsl', newname = 'fac_mat'
tvector_rotate, 'fac_mat', 'th'+probe[0]+'_efw', newname = 'th'+probe[0]+'_efw'
tvector_rotate, 'fac_mat', 'th'+probe[0]+'_scw', newname = 'th'+probe[0]+'_scw'


;===============================
; Polarization analysis
;===============================
twavpol,'th'+probe[0]+'_scw',nopfft=256,steplength=64
get_data,'th'+probe[0]+'_scw_waveangle',lim=lim,dlim=dlim,data=angle
angle.y/=!dtor
store_data,'th'+probe[0]+'_scw_waveangle',lim=lim,dlim=dlim,data=angle
options,'th'+probe[0]+'_scw_waveangle',zrange=[0,40],yrange=[0,4096],ystyle=1
options,'th'+probe[0]+'_scw_powspec',zlog=1,yrange=[0,4096],ystyle=1
options,'th'+probe[0]+'_scw_degpol',yrange=[0,4096],ystyle=1


;===============================
; Correct for EFI transfer function in time domain
; Corrections include:
;   plasma-probe response
;   anti-aliasing filter response
;   ADC interleaving timing
;   DFB digital filter response
;===============================

; Set up kernels
get_data,'th'+probe[0]+'_efw',lim=lim,dlim=dlim,data=efw
fsample=double(round(1/(efw.x[1]-efw.x[0])))
print,'Sampling frequency for EFI:',fsample
kernel_length=1024
df=fsample/double(kernel_length)
f=dindgen(kernel_length)*df
f[kernel_length/2+1:*] -= double(kernel_length)*df
thm_comp_efi_response, 'SPB', f, SPB_resp,rsheath=5d6,/complex_response
thm_comp_efi_response, 'AXB', f, AXB_resp,rsheath=5d6,/complex_response
if fsample eq 16384 then begin
  print,'Assuming AC coupling.'
  E12_resp=1/(SPB_resp*thm_eac_filter_resp(f)*thm_adc_resp('E12AC',f)*thm_dfb_dig_filter_resp(f, fsample))
  E34_resp=1/(SPB_resp*thm_eac_filter_resp(f)*thm_adc_resp('E34AC',f)*thm_dfb_dig_filter_resp(f, fsample))
  E56_resp=1/(AXB_resp*thm_eac_filter_resp(f)*thm_adc_resp('E56AC',f)*thm_dfb_dig_filter_resp(f, fsample))
endif else begin
  print,'Assuming DC coupling.'
  E12_resp=1/(SPB_resp*bessel_filter_resp(f,4096,4)*thm_adc_resp('E12DC',f)*thm_dfb_dig_filter_resp(f, fsample))
  E34_resp=1/(SPB_resp*bessel_filter_resp(f,4096,4)*thm_adc_resp('E34DC',f)*thm_dfb_dig_filter_resp(f, fsample))
  E56_resp=1/(AXB_resp*bessel_filter_resp(f,4096,4)*thm_adc_resp('E56DC',f)*thm_dfb_dig_filter_resp(f, fsample))
endelse

; Filter out frequencies above SCM Nyquist (before downsampling)
if fsample eq 16384 then begin
  E12_resp[kernel_length/4:3*kernel_length/4-1]=0
  E34_resp[kernel_length/4:3*kernel_length/4-1]=0
  E56_resp[kernel_length/4:3*kernel_length/4-1]=0
  E12_resp[0]=0
  E34_resp[0]=0
  E56_resp[0]=0
endif

; Transfer kernel into time domain: take inverse FFT and center
E12_resp=shift((fft(E12_resp,1)),kernel_length/2)/kernel_length
E34_resp=shift((fft(E34_resp,1)),kernel_length/2)/kernel_length
E56_resp=shift((fft(E56_resp,1)),kernel_length/2)/kernel_length

; Extend data to account for edge wrap
ndata=n_elements(efw.x)
efw_y=[[replicate(efw.y[0,0],kernel_length/2),efw.y[*,0],replicate(efw.y[ndata-1,0],kernel_length/2)],$
       [replicate(efw.y[0,1],kernel_length/2),efw.y[*,1],replicate(efw.y[ndata-1,1],kernel_length/2)],$
       [replicate(efw.y[0,2],kernel_length/2),efw.y[*,2],replicate(efw.y[ndata-1,2],kernel_length/2)]]

; Deconvolve transfer function
b_length = 8 * kernel_length
efw_y[*,0] = shift(blk_con(E12_resp, efw_y[*,0], b_length=b_length),-kernel_length/2)
efw_y[*,1] = shift(blk_con(E34_resp, efw_y[*,1], b_length=b_length),-kernel_length/2)
efw_y[*,2] = shift(blk_con(E56_resp, efw_y[*,2], b_length=b_length),-kernel_length/2)

; Align data to SCM (downsampling to 8 kHz if needed) and store it
get_data,'th'+probe[0]+'_scw',data=scw
efw={x:scw.x,y:[[interpol(efw_y[kernel_length/2:ndata+kernel_length/2-1,0],efw.x,scw.x)],$
                [interpol(efw_y[kernel_length/2:ndata+kernel_length/2-1,1],efw.x,scw.x)],$
                [interpol(efw_y[kernel_length/2:ndata+kernel_length/2-1,2],efw.x,scw.x)]]}
store_data,'th'+probe[0]+'_efw_corrected',lim=lim,dlim=dlim,data=efw


;===============================
; Poynting flux analysis
;===============================
nfft=128

; Get data
get_data,'th'+probe[0]+'_efw_corrected',lim=lim,dlim=dlim,data=efw
get_data,'th'+probe[0]+'_scw',lim=lim1,dlim=dlim1,data=scw

; Calculate Poynting flux (bandpass filtered, time domain)
ndata = n_elements(efw.x)       ;jmm, 22-may-2012 efw was interpolated earlier
S=dblarr(ndata,3)
E=efw.y
B=scw.y
filter=digital_filter(200./4096,1,50,nfft,/double)
for i=0,2 do E[*,i]=convol(E[*,i],filter,/center)
for i=0,2 do B[*,i]=convol(B[*,i],filter,/center)
S[*,0]= E[*,1]*B[*,2]-E[*,2]*B[*,1]
S[*,1]=-E[*,0]*B[*,2]+E[*,2]*B[*,0]
S[*,2]= E[*,0]*B[*,1]-E[*,1]*B[*,0]
S_conversion=1d-3*1d-9*1d6/(4d-7*!dpi)  ; mV->V, nT->T, W->uW, divide by mu_0
S*=S_conversion
for i=0,2 do S[*,i]=smooth(S[*,i],nfft)
store_data,'S_timeseries',data={x:efw.x,y:S},lim={ytitle:'Poynting flux 200-4096 Hz!C!C[!4l!3W/m2]'}
store_data,'S_tot1',    data={x:efw.x,y:sqrt(total(S*S,2))}

; Perform FFTs for frequency-domain calculation
nfft=128
stride=32
ndata=n_elements(efw.x)
efw_fft=dcomplexarr(long(ndata-nfft)/stride+1,nfft,3)
scw_fft=dcomplexarr(long(ndata-nfft)/stride+1,nfft,3)
win=hanning(nfft,/double)
win/=mean(win^2)  ; preserve energy
i=0L
for j=0L,ndata-nfft-1,stride do begin
  for k=0,2 do efw_fft[i,*,k]=fft(efw.y[j:j+nfft-1,k]*win)
  for k=0,2 do scw_fft[i,*,k]=fft(scw.y[j:j+nfft-1,k]*win)
  i++
endfor
t=scw.x[0]+(dindgen(i-1)*stride+nfft/2)/8192.
freq=(findgen(nfft/2)+0.5)*8192/nfft
bw=8192/nfft
efwlim={spec:1,zlog:1,ylog:0,yrange:[100,4096],ystyle:1,zrange:[1e-8,1e-4]}
scwlim={spec:1,zlog:1,ylog:0,yrange:[100,4096],ystyle:1,zrange:[1e-10,1e-6]}
store_data,'efw_fft_x',data={x:t,y:abs(efw_fft[*,0:nfft/2,0])^2/bw,v:freq},lim=efwlim
store_data,'efw_fft_y',data={x:t,y:abs(efw_fft[*,0:nfft/2,1])^2/bw,v:freq},lim=efwlim
store_data,'efw_fft_z',data={x:t,y:abs(efw_fft[*,0:nfft/2,2])^2/bw,v:freq},lim=efwlim
store_data,'scw_fft_x',data={x:t,y:abs(scw_fft[*,0:nfft/2,0])^2/bw,v:freq},lim=scwlim
store_data,'scw_fft_y',data={x:t,y:abs(scw_fft[*,0:nfft/2,1])^2/bw,v:freq},lim=scwlim
store_data,'scw_fft_z',data={x:t,y:abs(scw_fft[*,0:nfft/2,2])^2/bw,v:freq},lim=scwlim

; Calculate Poynting flux (frequency domain)
Sx= double(efw_fft[*,*,1]*conj(scw_fft[*,*,2])-efw_fft[*,*,2]*conj(scw_fft[*,*,1]))*S_conversion
Sy=-double(efw_fft[*,*,0]*conj(scw_fft[*,*,2])-efw_fft[*,*,2]*conj(scw_fft[*,*,0]))*S_conversion
Sz= double(efw_fft[*,*,0]*conj(scw_fft[*,*,1])-efw_fft[*,*,1]*conj(scw_fft[*,*,0]))*S_conversion
bw=8192/nfft
indx=where(freq ge 200)
Stot=sqrt(total(Sx[*,indx]^2+Sy[*,indx]^2+Sz[*,indx]^2,2))
zrange=max(Stot)*0.1*[-1,1]/bw
store_data,'S_x',     data={x:t,y:Sx/bw,v:freq},lim={spec:1,zlog:0,ylog:0,yrange:[100,4096],ystyle:1,zrange:zrange,ytitle:'Poynting flux S!Bx!N!C!C[!4l!3W/m!A2!N/Hz]'}
store_data,'S_y',     data={x:t,y:Sy/bw,v:freq},lim={spec:1,zlog:0,ylog:0,yrange:[100,4096],ystyle:1,zrange:zrange,ytitle:'Poynting flux S!By!N!C!C[!4l!3W/m!A2!N/Hz]'}
store_data,'S_z',     data={x:t,y:Sz/bw,v:freq},lim={spec:1,zlog:0,ylog:0,yrange:[100,4096],ystyle:1,zrange:zrange,ytitle:'Poynting flux S!Bz!N!C!C[!4l!3W/m!A2!N/Hz]'}
store_data,'S_tot2',data={x:t,y:Stot},lim={color:1}
store_data,'S_tot' ,data=['S_tot1','S_tot2'],lim={ytitle:'|S| 200-4096 Hz!C!C[!4l!3W/m2]'}


;===============================
; Plot
;===============================
window,0,ysize=900
window,1,ysize=900
tplot,['??w_*fft_?'],trange=trange,title='Calibrated data with transfer function corrected',window=0
tplot,['th'+probe[0]+'_scw_'+['powspec','degpol','waveangle'],'S_?','S_timeseries'],trange=trange,title='Poynting flux',window=1



stop



;===============================
; Phase analysis
;===============================
;   -this section was previously part of thm_crib_validate_high_freq_using_phase

; Calculate E-B phase lag
phase=dblarr(n_elements(efw_fft[*,0,0]),nfft,3)
for k=0,2 do phase[*,*,k]=atan(efw_fft[*,*,k],/phase)-atan(scw_fft[*,*,k],/phase)
phase/=!dtor
phase=phase mod 360
phase[where(abs(scw_fft) lt median(abs(scw_fft[*,nfft*0.25:*,*])))]=!values.f_nan
phaselim={spec:1,zlog:0,ylog:0,yrange:[100,4096],ystyle:1,zrange:ave_phase_yrange}
store_data,'phase_x',data={x:t,y:phase[*,*,0],v:freq},lim=phaselim
store_data,'phase_y',data={x:t,y:phase[*,*,1],v:freq},lim=phaselim
store_data,'phase_z',data={x:t,y:phase[*,*,2],v:freq},lim=phaselim


; Calculate averaged power phase difference, E/B, etc. for in-band power
phase_max=dblarr(n_elements(efw_fft[*,0,0]),4)
power_max=dblarr(n_elements(efw_fft[*,0,0]),3)
freq_max=dblarr(n_elements(efw_fft[*,0,0]))
eb_ratio=dblarr(n_elements(efw_fft[*,0,0]),3)
waveangle=dblarr(n_elements(efw_fft[*,0,0]),2)
for i=0,n_elements(power_max[*,0])-1 do begin
  pow=total(reform(scw_fft[i,*,*]*conj(scw_fft[i,*,*])),2)
  indx=where(pow eq max(pow[nfft*0.1:nfft*0.5]))
  indx=indx[0] < (nfft/2-2)
  freq_max[i]=indx[0]
  indx=indx[0]+indgen(3)-1
  indx=indx[0]+indgen(3)-1
  for k=0,2 do begin
    power_max[i,k]=mean(abs(efw_fft[i,indx,k])^2)
  endfor
endfor
power_cutoff=max(power_max)*power_cutoff
for i=0,n_elements(power_max[*,0])-1 do begin
  indx=freq_max[i]
  freq_max[i]=freq[indx]
  if total(power_max[i,0:1]) gt power_cutoff then begin
    indx=indx[0]+indgen(3)-1
    for k=0,2 do begin
      power_max[i,k]=mean(abs(efw_fft[i,indx,k])^2)
      phase_max[i,k]=atan(total(efw_fft[i,indx,k]),/phase)-atan(total(scw_fft[i,indx,k]),/phase)
      phase_max[i,k]=(phase_max[i,k]/!dtor + 360) mod 360
      eb_ratio[i,k]=mean(abs(efw_fft[i,indx,k]))/mean(abs(scw_fft[i,indx,k]))*1d3
    endfor
  endif else begin
    for k=0,2 do $
      power_max[i,k]=mean(abs(efw_fft[i,indx,k])^2)
    phase_max[i,*]=!values.f_nan
    eb_ratio[i,*]=!values.f_nan
    waveangle[i,*]=!values.f_nan
  endelse
endfor
store_data,'freq',data={x:t,y:freq_max}
store_data,'ave_phase_x',data={x:t,y:[[phase_max[*,0]],[90+ave_phase_yrange[0]+fltarr(n_elements(phase_max[*,0]))]]},lim={yrange:ave_phase_yrange,ystyle:1,psym:0}
store_data,'ave_phase_y',data={x:t,y:[[phase_max[*,1]],[90+ave_phase_yrange[0]+fltarr(n_elements(phase_max[*,0]))]]},lim={yrange:ave_phase_yrange,ystyle:1,psym:0}
store_data,'ave_phase_z',data={x:t,y:[[phase_max[*,2]],[90+ave_phase_yrange[0]+fltarr(n_elements(phase_max[*,0]))]]},lim={yrange:ave_phase_yrange,ystyle:1,psym:0}
store_data,'power',data={x:t,y:power_max},lim={ytitle:'In-band B power'}
store_data,'eb_ratio',data={x:t,y:eb_ratio},lim={yrange:[0,4e4],ytitle:'E/B [km/s]'}



;===============================
; Plot
;===============================
window,0,ysize=900
window,1,ysize=900
;window,4,ysize=900
;window,5,ysize=900
tplot,['??w_*fft_?','th'+probe[0]+'_scw_'+['powspec','degpol','waveangle']],trange=trange,title='Calibrated data with transfer function corrected',window=0
tplot,['S_?','S_timeseries','S_tot'],trange=trange,title='Poynting flux',window=1
;tplot,'phase_?',trange=trange,title='Phase lags',window=4
;tplot,['freq','power','ave_phase_x','ave_phase_y','ave_phase_perp','eb_ratio','wave_angle'],trange=trange,window=5


end
