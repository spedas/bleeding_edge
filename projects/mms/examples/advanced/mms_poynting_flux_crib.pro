;+
;
; mms_poynting_flux_crib
; 
; This is a crib sheet that computes the Poynting flux for waves between Fmin and Fmax
; in time domain as well as in Fourier domain
; in GSE as well as in Field-aligned coordinates (FAC)
; 
; 
; HISTORY
; Created by Le Contel, July 2017, based on thm_crib_poynting_flux.pro
; 
; 
; Open this file in a text editor and then use copy and paste to copy
; selected lines into an idl window. 
; 
; $LastChangedBy: jwl $
; $LastChangedDate: 2023-06-01 18:15:21 -0700 (Thu, 01 Jun 2023) $
; $LastChangedRevision: 31875 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_poynting_flux_crib.pro $
;-


del_data,'*'

date = '2015-10-16/00:00:00'

timespan,date,1,/day

;starting_time ='13:00:00.000000' ; Multiple MPause crossings in survey mode (srvy)
;ending_time   ='13:10:00.000000'

starting_time ='13:05:40.000000' ; Magnetospheric Whistler waves at 600 Hz in burst mode (brst) propagating parallel to B0
ending_time   ='13:05:50.000000'

satname = 'mms1'
    
;; To impose by hand t1 and t2 :
starting_date =strmid(date,0,10)
     
coord_final ='gse'

;======= select same data level ('l2') for FGM, EDP and SCM
data_level_input = 'l2'
 
;;;;;;=======================================================================================================
;;;;;; FOR BASIC PLOTS JUST CHANGE THE DATA_RATE_INPUT VALUE ('brst' for burst mode or 'srvy' for survey mode)
;;;;;; AND  KEEP ALL OTHER PARAMETERS FIXED AT DEFAULT VALUES
;;;;;;=======================================================================================================
;======= select same data rate ('srvy', 'brst') for FGM, EDP and SCM
data_rate_input = 'brst';'srvy'

;======= select individual MAG data rate ('srvy', 'brst') if needed
mag_data_rate = data_rate_input

;======== Select individual MAG level ('l2','l2pre') if needed
mag_level = data_level_input
 
;=== Select MAG 
mag = 'fgm'  
mag_name = satname+'_'+mag+'_b_'+coord_final+'_'+ mag_data_rate+'_'+mag_level

if data_rate_input eq 'brst' then n_sample = 8192 else n_sample = 32

;================ EDP parameters
;; Select individual EDP level of data ('ql', 'l2') if needed
edp_level = data_level_input

if data_rate_input eq 'srvy' then edp_data_rate = 'fast' else edp_data_rate =  data_rate_input

;; select edp datatype 
edp_datatype = 'dce'

edp_coord = coord_final

edp_name = satname+ '_edp_'+edp_datatype+'_'+edp_coord+'_'+edp_data_rate+'_'+ edp_level 
  
;================ SCM parameters
scm_data_rate = data_rate_input

if scm_data_rate eq 'brst' then scm_datatype= 'scb' else scm_datatype= 'scsrvy'

scm_level = data_level_input

scm_coord = coord_final

scm_name = satname+'_scm_acb_'+scm_coord+'_'+scm_datatype+'_'+scm_data_rate+'_'+scm_level

;============================ Frequencies for Band-path filtering applied
;============================ on EDP and SCM waveforms used in time domain as well as in Fourier domain
if data_rate_input eq 'brst' then nfft = 256 else nfft=32 ;1024;128; 512;128 ;1024L

if data_rate_input eq 'brst' then Fsamp=8192. else Fsamp=32.

Fmin = (1./(float(nfft)/Fsamp))
Fmax = Fsamp/2.

;========== set to 1 for log or 0 for linear frequency scale 
if data_rate_input eq 'brst' then n_log_freq = 1 else n_log_freq = 0


str_Fmin = string(Fmin,format='(f6.2)')
str_Fmin = strtrim(str_Fmin ,1)
str_Fmax = string(Fmax,format='(f7.2)')
str_Fmax = strtrim(str_Fmax ,1)
      
trange = [starting_date+'/'+starting_time, $
            starting_date+'/'+ending_time]
  
;string definitions for file names

str_date_yy = strmid(date,0,4)
str_date_diryy = strmid(date,2,2)
str_date_mm = strmid(date,5,2)
str_date_dd = strmid(date,8,2)
str_date = str_date_yy+str_date_mm+str_date_dd
; str_dir  = str_date_yy+'_'+str_date_mm 
str_dir  = str_date_yy+str_date_mm 
str_t0_hh = strmid(starting_time,0,2)
str_t0_mm = strmid(starting_time,3,2)
str_t0_ss = strmid(starting_time,6,6)
 
str_t0 = str_t0_hh+str_t0_mm+str_t0_ss
 
str_t1_hh = strmid(ending_time,0,2)
str_t1_mm = strmid(ending_time,3,2)
str_t1_ss = strmid(ending_time,6,6)
 
str_t1 = str_t1_hh+str_t1_mm+str_t1_ss

;;=================
;;LOAD L2 FGM DATA
;;=================
mms_load_fgm,probe=strmid(satname,3),data_rate=mag_data_rate,level=mag_level,trange=trange,/time_clip


;;==================
;;LOAD L2 EDP DATA 
;;==================
mms_load_edp,probe=strmid(satname,3),data_rate=edp_data_rate,level=edp_level,trange=trange,/time_clip

;;===================== 
;;LOAD L2 SCM DATA 
;;=====================
mms_load_scm,probe=strmid(satname,3),datatype=scm_data_type,data_rate=scm_data_rate,level=scm_level,trange=trange,/time_clip


;;=====================
;; BAND-PASS FILTERING
;;=====================
tinterpol_mxn,scm_name,edp_name
get_data,edp_name,time_edp,val_edp,values
get_data,scm_name+'_interp',time_scm,val_scm,values

edp={x:time_edp,y:val_edp}
scm={x:time_scm,y:val_scm}
edp_filtered = time_domain_filter(edp,Fmin,Fmax)
scm_filtered = time_domain_filter(scm,Fmin,Fmax)

store_data,edp_name+'_filt',data=edp_filtered
store_data,scm_name+'_filt',data=scm_filtered

;;======================================================================
;; Compute Poynting vector in GSE of band-pass filtered EDP and SCM DATA
;;======================================================================
; Calculate Poynting flux (bandpass filtered, time domain)
ndata = n_elements(edp_filtered.x)  
S     = dblarr(ndata,3)
    
E = edp_filtered.y
B = scm_filtered.y

S[*,0]= E[*,1]*B[*,2]-E[*,2]*B[*,1]
S[*,1]=-E[*,0]*B[*,2]+E[*,2]*B[*,0]
S[*,2]= E[*,0]*B[*,1]-E[*,1]*B[*,0]

S_conversion=1d-3*1d-9*1d6/(4d-7*!dpi)  ; mV->V, nT->T, W->uW, divide by mu_0
S*=S_conversion
;for i=0,2 do S[*,i]=smooth(S[*,i],nfft)
store_data,'S_timeseries',data={x:edp_filtered.x,y:S},lim={ytitle:'S !C!C[!4l!3W/m!E2!N]',colors:[2,4,6]}
store_data,'S_tot1',    data={x:edp_filtered.x,y:sqrt(total(S*S,2))}

; Perform FFTs for frequency-domain calculation
;nfft=128
stride=nfft;32
ndata    = n_elements(edp_filtered.x)
nstrides = (ndata - nfft)/stride + 1L
edp_fft  = dcomplexarr(nstrides,nfft,3)
scm_fft  = dcomplexarr(nstrides,nfft,3)
win      = hanning(nfft,/double)
win     /= mean(win^2)  ; preserve energy
i=0L  ; which stride is being computed
for j=0L,ndata-nfft,stride do begin
  for k=0,2 do edp_fft[i,*,k]=fft(edp_filtered.y[j:j+nfft-1,k]*win)
  for k=0,2 do scm_fft[i,*,k]=fft(scm_filtered.y[j:j+nfft-1,k]*win)
  i++
endfor
t    = scm_filtered.x[0]+(dindgen(nstrides)*stride+nfft/2)/double(n_sample)
freq = (findgen(nfft/2)+0.5)*n_sample/nfft
bw   = n_sample/nfft

; Freq calculation from IDL docs, even number of points
fx=findgen((nfft-1)/2)+1
freq_all = [0.0, fx, nfft/2, -nfft/2 + fx]*8192.0/nfft
freq_nonneg = freq_all[0:nfft/2-1]

if data_rate_input eq 'brst' then psd_edp_min = 1e-8  else psd_edp_min = 1e-6
if data_rate_input eq 'brst' then psd_edp_max = 1e-4  else psd_edp_max = 1e2
if data_rate_input eq 'brst' then psd_scm_min = 1e-10 else psd_scm_min = 1e-6
if data_rate_input eq 'brst' then psd_scm_max = 1e-6  else psd_scm_max = 1e1
 
;edplim={spec:1,zlog:1,ylog:n_log_freq,yrange:[Fmin,Fmax],ystyle:1,zrange:[psd_edp_min,psd_edp_max],ytitle:'[Hz]'}
;scmlim={spec:1,zlog:1,ylog:n_log_freq,yrange:[Fmin,Fmax],ystyle:1,zrange:[psd_scm_min,psd_scm_max],ytitle:'[Hz]'}
edplim={spec:1,zlog:1,ylog:n_log_freq,yrange:[Fmin,Fmax],ystyle:1,ytitle:'[Hz]'}
scmlim={spec:1,zlog:1,ylog:n_log_freq,yrange:[Fmin,Fmax],ystyle:1,ytitle:'[Hz]'}
store_data,'edp_fft_x',data={x:t,y:abs(edp_fft[*,0:nfft/2,0])^2/bw,v:freq},lim=edplim
store_data,'edp_fft_y',data={x:t,y:abs(edp_fft[*,0:nfft/2,1])^2/bw,v:freq},lim=edplim
store_data,'edp_fft_z',data={x:t,y:abs(edp_fft[*,0:nfft/2,2])^2/bw,v:freq},lim=edplim
store_data,'scm_fft_x',data={x:t,y:abs(scm_fft[*,0:nfft/2,0])^2/bw,v:freq},lim=scmlim
store_data,'scm_fft_y',data={x:t,y:abs(scm_fft[*,0:nfft/2,1])^2/bw,v:freq},lim=scmlim
store_data,'scm_fft_z',data={x:t,y:abs(scm_fft[*,0:nfft/2,2])^2/bw,v:freq},lim=scmlim

options,'edp_fft_x','ztitle','Ex !C!C [(mV/m)!E2!N/Hz]'
options,'edp_fft_y','ztitle','Ey '
options,'edp_fft_z','ztitle','Ez '
options,'scm_fft_x','ztitle','Bx!C!C [(nT)!E2!N/Hz]'
options,'scm_fft_y','ztitle','By'
options,'scm_fft_z','ztitle','Bz'

; Calculate Poynting flux (frequency domain)
Sx = double(edp_fft[*,*,1]*conj(scm_fft[*,*,2])-edp_fft[*,*,2]*conj(scm_fft[*,*,1]))*S_conversion
Sy = -double(edp_fft[*,*,0]*conj(scm_fft[*,*,2])-edp_fft[*,*,2]*conj(scm_fft[*,*,0]))*S_conversion
Sz = double(edp_fft[*,*,0]*conj(scm_fft[*,*,1])-edp_fft[*,*,1]*conj(scm_fft[*,*,0]))*S_conversion
bw     = n_sample/nfft
indx   = where(freq ge Fmin)
Stot   = sqrt(total(Sx[*,indx]^2+Sy[*,indx]^2+Sz[*,indx]^2,2))
zrange = max(Stot)*1.e-3*[-1,1]/bw
store_data,'S_x',     data={x:t,y:Sx/bw,v:freq},lim={spec:1,zlog:0,ylog:n_log_freq,yrange:[Fmin,Fmax],ystyle:1,zrange:zrange,ztitle:'S!Bx!N!C!C[!4l!3W/m!A2!N/Hz]',ytitle:'[Hz]'}
store_data,'S_y',     data={x:t,y:Sy/bw,v:freq},lim={spec:1,zlog:0,ylog:n_log_freq,yrange:[Fmin,Fmax],ystyle:1,zrange:zrange,ztitle:'S!By',ytitle:'[Hz]'}
store_data,'S_z',     data={x:t,y:Sz/bw,v:freq},lim={spec:1,zlog:0,ylog:n_log_freq,yrange:[Fmin,Fmax],ystyle:1,zrange:zrange,ztitle:'S!Bz',ytitle:'[Hz]'}
store_data,'S_tot2',data={x:t,y:Stot},lim={color:1}
store_data,'S_tot' ,data=['S_tot1','S_tot2'],lim={ytitle:'|S| !C!C[!4l!3W/m!E2!N]'}



;; =====================================================================
;; Get FGM data in order to define Field-Aligned Coordinate (FAC) system
;; Background magnetic field is defined as time-averaged values of brst data
;; using res0 as time resolution
;; =====================================================================

if data_rate_input eq 'brst' then res0=0.1 else res0 = 1.
str_res = strmid(strtrim(res0,1),0,4)

avg_data,mag_name+'_bvec',res0,newname=mag_name+'_bvec_av'

;store_data,'all_b',data=[mms_fgm_name,  satname+'_fgm_b_gse_'+fgm_data_rate+'_l2_btot']

;make transformation matrix
fac_matrix_make, mag_name+'_bvec_av',other_dim='xgse',newname = mag_name+'_av_fac_mat'
;other_dim='xgse', newname = 'thc_fgs_gse_sm601_fac_mat'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, mag_name+'_av_fac_mat', edp_name+'_filt', newname = edp_name+'_filt_fac'
tvector_rotate, mag_name+'_av_fac_mat', scm_name+'_filt', newname = scm_name+'_filt_fac'

;;======================================================================
;; Compute Poynting vector in FAC  of band-path filtered EDP and SCM DATA
;;======================================================================
; Calculate Poynting flux (bandpass filtered, time domain)
ndata = n_elements(edp_filtered.x)
S_fac     = dblarr(ndata,3)

get_data,edp_name+'_filt_fac',data=edp_filt_fac
get_data,scm_name+'_filt_fac',data=scm_filt_fac

E = edp_filt_fac.y
B = scm_filt_fac.y

S[*,0]= E[*,1]*B[*,2]-E[*,2]*B[*,1]
S[*,1]=-E[*,0]*B[*,2]+E[*,2]*B[*,0]
S[*,2]= E[*,0]*B[*,1]-E[*,1]*B[*,0]

S_conversion=1d-3*1d-9*1d6/(4d-7*!dpi)  ; mV->V, nT->T, W->uW, divide by mu_0
S*=S_conversion
;for i=0,2 do S[*,i]=smooth(S[*,i],nfft)
store_data,'S_timeseries_fac',data={x:edp_filt_fac.x,y:S},lim={ytitle:'S !C!C[!4l!3W/m2]',colors:[2,4,6]}
store_data,'S_fac_tot1',    data={x:edp_filt_fac.x,y:sqrt(total(S*S,2))}

; Perform FFTs for frequency-domain calculation
;nfft=128
;stride=nfft;32
ndata=n_elements(edp_filt_fac.x)
edp_fft=dcomplexarr(long(ndata-nfft)/stride+1,nfft,3)
scm_fft=dcomplexarr(long(ndata-nfft)/stride+1,nfft,3)
win=hanning(nfft,/double)
win/=mean(win^2)  ; preserve energy
i=0L
for j=0L,ndata-nfft-1,stride do begin
  for k=0,2 do edp_fft[i,*,k]=fft(edp_filt_fac.y[j:j+nfft-1,k]*win)
  for k=0,2 do scm_fft[i,*,k]=fft(scm_filt_fac.y[j:j+nfft-1,k]*win)
  i++
endfor
t=scm_filt_fac.x[0]+(dindgen(i-1)*stride+nfft/2)/double(n_sample)
freq=(findgen(nfft/2)+0.5)*n_sample/nfft
bw=n_sample/nfft
store_data,'edp_fft_fac_x',data={x:t,y:abs(edp_fft[*,0:nfft/2,0])^2/bw,v:freq},lim=edplim
store_data,'edp_fft_fac_y',data={x:t,y:abs(edp_fft[*,0:nfft/2,1])^2/bw,v:freq},lim=edplim
store_data,'edp_fft_fac_z',data={x:t,y:abs(edp_fft[*,0:nfft/2,2])^2/bw,v:freq},lim=edplim
store_data,'scm_fft_fac_x',data={x:t,y:abs(scm_fft[*,0:nfft/2,0])^2/bw,v:freq},lim=scmlim
store_data,'scm_fft_fac_y',data={x:t,y:abs(scm_fft[*,0:nfft/2,1])^2/bw,v:freq},lim=scmlim
store_data,'scm_fft_fac_z',data={x:t,y:abs(scm_fft[*,0:nfft/2,2])^2/bw,v:freq},lim=scmlim

options,'edp_fft_fac_x','ztitle','Ex !C!C [(mV/m)!E2!N/Hz]'
options,'edp_fft_fac_y','ztitle','Ey '
options,'edp_fft_fac_z','ztitle','Ez '
options,'scm_fft_fac_x','ztitle','Bx!C!C [(nT)!E2!N/Hz]'
options,'scm_fft_fac_y','ztitle','By'
options,'scm_fft_fac_z','ztitle','Bz'


; Calculate Poynting flux (frequency domain)
S_fac_x= double(edp_fft[*,*,1]*conj(scm_fft[*,*,2])-edp_fft[*,*,2]*conj(scm_fft[*,*,1]))*S_conversion
S_fac_y=-double(edp_fft[*,*,0]*conj(scm_fft[*,*,2])-edp_fft[*,*,2]*conj(scm_fft[*,*,0]))*S_conversion
S_fac_z= double(edp_fft[*,*,0]*conj(scm_fft[*,*,1])-edp_fft[*,*,1]*conj(scm_fft[*,*,0]))*S_conversion
bw=n_sample/nfft
indx=where(freq ge Fmin)
S_fac_tot=sqrt(total(S_fac_x[*,indx]^2+S_fac_y[*,indx]^2+S_fac_z[*,indx]^2,2))
zrange=max(Stot)*1.e-3*[-1,1]/bw
store_data,'S_fac_x',     data={x:t,y:S_fac_x/bw,v:freq},lim={spec:1,zlog:0,ylog:n_log_freq,yrange:[Fmin,Fmax],ystyle:1,zrange:zrange,ztitle:'S!Bx!N!C!C[!4l!3W/m!A2!N/Hz]',ytitle:'[Hz]'}
store_data,'S_fac_y',     data={x:t,y:S_fac_y/bw,v:freq},lim={spec:1,zlog:0,ylog:n_log_freq,yrange:[Fmin,Fmax],ystyle:1,zrange:zrange,ztitle:'S!By',ytitle:'[Hz]'}
store_data,'S_fac_z',     data={x:t,y:S_fac_z/bw,v:freq},lim={spec:1,zlog:0,ylog:n_log_freq,yrange:[Fmin,Fmax],ystyle:1,zrange:zrange,ztitle:'S!Bz',ytitle:'[Hz]'}
store_data,'S_fac_tot2',data={x:t,y:S_fac_tot},lim={color:1}
store_data,'S_fac_tot' ,data=['S_fac_tot1','S_fac_tot2'],lim={ytitle:'|S| !C!C[!4l!3W/m!E2!N]'}

options, edp_name+'_filt','ytitle','EDP filt. !C!C [mV/m]'
options, scm_name+'_filt','ytitle','SCM filt. !C!C [nT]'
options,edp_name+'_filt',colors=[2,4,6]
options,scm_name+'_filt',colors=[2,4,6]

options, edp_name+'_filt_fac','ytitle','EDP filt. !C!C [mV/m]'
options, scm_name+'_filt_fac','ytitle','SCM filt. !C!C [nT]'
options,edp_name+'_filt_fac',colors=[2,4,6]
options,scm_name+'_filt_fac',colors=[2,4,6]

window,1,xsize=1000,ysize=800 &
tplot_options,'region',[0.1,0.1,.9,.9]
tplot_options,'charsize',1.
tplot_options,'charthick',1.
tplot_options,'title',satname+ ' on '+ str_date +', Poynting vector calculations in GSE with !C!C SCM mode: '+scm_datatype+', EDP mode: '+edp_datatype $
   +', filtered between Fmin='+str_Fmin+' Hz and Fmax='+str_Fmax+' Hz, !C!C' 
;options,satname+'_des_pitchangdist_miden_'+fpi_data_rate,'spec',0
;ylim,satname+'_des_pitchangdist_miden_'+fpi_data_rate,5.e5,1.e7,1

options, ['*'], 'labflag', -1

tplot,[$
  mag_name $
  ,edp_name+'_filt' $
  ,scm_name+'_filt' $
  ,'S_timeseries' $
  ,'Stot1' $
  ,'edp_fft_x' $
  ,'edp_fft_y' $
  ,'edp_fft_z' $
  ,'scm_fft_x' $
  ,'scm_fft_y' $
  ,'scm_fft_z' $
  ,'S_x' $
  ,'S_y' $
  ,'S_z' $
 ; ,'S_tot' $ ;uncomment if you want to compare total Poynting flux from time domain and Fourier domain 
  ],window=1
tlimit,trange

  

;========================= Second WINDOW

window,2,xsize=1000,ysize=800 &
tplot_options,'region',[0.1,0.1,.9,.9]
tplot_options,'charsize',1.
tplot_options,'charthick',1.
tplot_options,'title',satname+ ' on '+ str_date +', Poynting vector calculations in FAC with !C!C SCM mode: '+scm_datatype+', EDP mode: '+edp_datatype $
   +', filtered between Fmin='+str_Fmin+' Hz and Fmax='+str_Fmax+' Hz, !C!C'

tplot,[$
   mag_name $
   ,edp_name+'_filt_fac' $
   ,scm_name+'_filt_fac' $
   ,'S_timeseries_fac' $
   ,'Stot1_fac' $
   ,'edp_fft_fac_x' $
   ,'edp_fft_fac_y' $
   ,'edp_fft_fac_z' $
   ,'scm_fft_fac_x' $
   ,'scm_fft_fac_y' $
   ,'scm_fft_fac_z' $
   ,'S_fac_x' $
   ,'S_fac_y' $
   ,'S_fac_z' $
  ; ,'S_fac_tot' $   ;uncomment if you want to compare total Poynting flux from time domain and Fourier domain   
  ],window=2
tlimit,trange

stop
end



