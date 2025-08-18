;+
;
;     mms_wavpol_crib
;
;
;     This crib sheet demonstrates usage of the wave polarization routines
;     using MMS SCM data
;     
;This version stores these outputs as tplot variables with the
;specified prefix
;         These are follows:
;
;         Wave power: On a linear scale (units of nT^2/Hz if input Bx, By, Bz are in nT)
;
;         Degree of Polarisation:
;   This is similar to a measure of coherency between the input
;   signals, however unlike coherency it is invariant under
;   coordinate transformation and can detect pure state waves
;   which may exist in one channel only.100% indicates a pure
;   state wave. Less than 70% indicates noise. For more
;   information see J. C. Samson and J. V. Olson 'Some comments
;   on the description of the polarization states
;   of waves' Geophys. J. R. Astr. Soc. (1980) v61 115-130
;
;         Wavenormal Angle:
;   the angle between the direction of minimum
;   variance calculated from the complex off diagonal
;   elements of the spectral matrix and the Z direction
;   of the input
;   ac field data. For magnetic field data in
;   field aligned coordinates this is the
;   wavenormal angle assuming a plane wave.
;
;         Ellipticity:The ratio (minor axis)/(major axis) of the
;   ellipse transcribed by the field variations of the
;   components transverse to the Z direction. The sign
;   indicates the direction of rotation of the field vector in
;     the plane. Negative signs refer to left-handed
;   rotation about the Z direction. In the field
;   aligned coordinate system these signs refer to
;   plasma waves of left and right handed
;   polarisation.
;
;         Helicity:Similar to Ellipticity except defined in terms of the
; direction of minimum variance instead of Z. Strictly the Helicity
; is defined in terms of the wavenormal direction or k.
; However since from single point observations the
; sense of k cannot be determined,  helicity here is
; simply the ratio of the minor to major axis transverse to the
;       minimum variance direction without sign.
;
;
; Last updated by:
; O. Le Contel, LPP, in order to manage data gaps in the waveform
; using test written by K. Bromund (in thm_cal_scm.pro)
;   
; For more informations about SCM data, please contact olivier.lecontel@lpp.polytechnique.fr
;
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-02-11 10:51:34 -0800 (Tue, 11 Feb 2025) $
; $LastChangedRevision: 33122 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_wavpol_crib.pro $
;-

 del_data,'*'
 
;; =============================
;; Select date and time interval
;; =============================

trange = ['2016-01-16/00:13:00', '2016-01-16/00:19:14']; example with datagap
;trange = ['2015-10-16/13:05:40', '2015-10-16/13:07:25']; Burch et al., Science event

;
;; =============================
;; Select probe and data type
;; =============================

sc = '4'
scm_data_rate = 'brst'

;; Select mode ('scsrvy' for survey data rate (both slow and fast have 32 S/s), 
;                'scb' (8192 S/s) or 'schb' (16384 S/s) for burst data rate)
scm_datatype = 'scb'

;; ==============================================================
;; Get SCM data 
;; ==============================================================

mms_load_scm, probe=sc, datatype=scm_datatype, level='l2', trange=trange, data_rate=scm_data_rate

mms_scm_name = 'mms'+sc+'_scm_acb_gse_'+scm_datatype+'_'+scm_data_rate+'_l2

;; =====================================================================
;; Get FGM data in order to define Field-Aligned Coordinate (FAC) system 
;; =====================================================================
fgm_data_rate = 'srvy'

mms_load_fgm, probes=sc, trange=trange, data_rate = fgm_data_rate
mms_fgm_name = 'mms'+sc+'_fgm_b_gse_'+fgm_data_rate+'_l2_bvec'

store_data,'all_b',data=[mms_fgm_name, 'mms'+sc+'_fgm_b_gse_'+fgm_data_rate+'_l2_btot']

;make transformation matrix
fac_matrix_make, mms_fgm_name,other_dim='xgse',newname = mms_fgm_name+'_fac_mat'
;other_dim='xgse', newname = 'thc_fgs_gse_sm601_fac_mat'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, mms_fgm_name+'_fac_mat', mms_scm_name, newname = mms_scm_name+'_fac'


;; =======================
;; Calculate polarization
;; =======================

;;; number of points for FFT
nopfft_input     = 8192;1024

;;; number of points for shifting between 2 FFT
steplength_input = nopfft_input/2
;;; number of bins for frequency averaging
bin_freq_input = 3
twavpol,mms_scm_name+'_fac' $
,nopfft=nopfft_input,steplength=steplength_input,bin_freq=bin_freq_input
;, error=error, freqline = freqline, $
;  timeline = timeline,

;=== change of units from radians to degrees for wave angle variable
get_data,mms_scm_name+'_fac_waveangle',time_wa,val_wa,val_freq

val_wa = val_wa*180./!pi
store_data,mms_scm_name+'_fac_waveangle',data={x:time_wa,y:val_wa,v:val_freq}

;;; only plot polarization results if the degree of polarization is larger than 0.7
deg_pol_c = 0.7

get_data,mms_scm_name+'_fac_degpol',time,val,val_freq
index_deg_pol = where(val lt deg_pol_c)
val[index_deg_pol] = !VALUES.F_NAN
store_data,mms_scm_name+'_fac_degpol',data={x:time,y:val,v:val_freq}
get_data,mms_scm_name+'_fac_powspec',time,val,val_freq
val[index_deg_pol] = !VALUES.F_NAN
store_data,mms_scm_name+'_fac_powspec',data={x:time,y:val,v:val_freq}
get_data,mms_scm_name+'_fac_waveangle',time,val,val_freq
val[index_deg_pol] = !VALUES.F_NAN
store_data,mms_scm_name+'_fac_waveangle',data={x:time,y:val,v:val_freq}
get_data,mms_scm_name+'_fac_elliptict',time,val,val_freq
val[index_deg_pol] = !VALUES.F_NAN
store_data,mms_scm_name+'_fac_elliptict',data={x:time,y:val,v:val_freq}
get_data,mms_scm_name+'_fac_helict',time,val,val_freq
val[index_deg_pol] = !VALUES.F_NAN
store_data,mms_scm_name+'_fac_helict',data={x:time,y:val,v:val_freq}

;; =====================
;; Plot calculated data
;; =====================
if scm_datatype eq 'scb' then samp_freq = 8192.
if scm_datatype eq 'scsrvy' then samp_freq = 32.

freq_min = floor(samp_freq/nopfft_input)
if scm_datatype eq 'scb' then freq_max = 4096.
if scm_datatype eq 'scsrvy' then freq_max = 16.

nlog_f = 1

options, ['*'], 'labflag', -1
options, mms_scm_name, colors=[2, 4, 6]
options, mms_scm_name, labels=['X GSE', 'Y GSE', 'Z GSE']
options, mms_scm_name, labflag=-1
options, mms_scm_name,ytitle='MMS'+sc+'!C SCM !C'

options, mms_scm_name+'_fac',colors=[2,4,6]
options, mms_scm_name+'_fac', labels=['X FAC', 'Y FAC', 'Z FAC']
options, mms_scm_name+'_fac', labflag=-1
options, mms_scm_name+'_fac',ytitle='MMS'+sc+'!C SCM !C'

ylim, mms_scm_name+'_fac_powspec',freq_min,freq_max,nlog_f
ylim, mms_scm_name+'_fac_degpol',freq_min,freq_max,nlog_f
ylim, mms_scm_name+'_fac_waveangle',freq_min,freq_max,nlog_f
ylim, mms_scm_name+'_fac_elliptict',freq_min,freq_max,nlog_f
ylim, mms_scm_name+'_fac_helict',freq_min,freq_max,nlog_f

options, mms_scm_name+'_fac_powspec',ztitle='nT!U2!N/Hz'
options, mms_scm_name+'_fac_powspec',ytitle='f', ysubtitle='[Hz]'
options, mms_scm_name+'_fac_degpol',ztitle='Deg. Pol.'
options, mms_scm_name+'_fac_waveangle',ztitle='Wave !C!CAngle'
options, mms_scm_name+'_fac_elliptict',ztitle='Ellipticity'
options, mms_scm_name+'_fac_helict',ztitle='Helicity'

options, mms_scm_name+'_fac_degpol',ytitle='f', ysubtitle='[Hz]'
options, mms_scm_name+'_fac_waveangle',ytitle='f', ysubtitle='[Hz]'
options, mms_scm_name+'_fac_elliptict',ytitle='f', ysubtitle='[Hz]'
options, mms_scm_name+'_fac_helict',ytitle='f', ysubtitle='[Hz]'

zlim,'*_powspec',0.0,0.0,1
zlim,'*_degpol',0.7,1.,0
zlim,'*_waveangle',0.,90.,0
zlim,'*_elliptict',-1.0,1.0,0
zlim,'*_helict',0.,1.0,0

tplot_options, 'xmargin', [15, 15]
tplot_options,title= 'MMS'+sc+' '+ fgm_data_rate+' FGM data, '+scm_data_rate +' SCM data used for polarisation analysis'

tplot, ['all_b' ,mms_scm_name,mms_scm_name+'_fac'+['','_powspec', '_degpol', '_waveangle', '_elliptict', '_helict']]
tlimit,trange

end