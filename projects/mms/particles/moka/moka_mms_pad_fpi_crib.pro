;+
; A crib for moka_mms_pad_fpi
; 
;$LastChangedBy: moka $
;$LastChangedDate: 2017-09-30 11:03:14 -0700 (Sat, 30 Sep 2017) $
;$LastChangedRevision: 24073 $
;$URL: svn+ssh://ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/moka/moka_mms_pad.pro $
;-
PRO moka_mms_pad_fpi_crib
  compile_opt idl2
  clock=tic('moka_mms_pad_fpi_crib')
  
  ;//////////////////////////////////////////
  ; USER SETTING
  ;//////////////////////////////////////////
  prb     = '1'   ; spacecraft '1','2','3' or '4'
  rate    = 'brst'; FPI data_rate 'brst' or 'fast'
  brate   = 'brst'; FGM data_rate 'brst' or 'srvy
  species = 'i'   ; 'i' or 'e'
  sample  =  1    ; number of samples to be averaged over
  subtract_bulk = 1 ; subtract bulk velocity for shifting to plasma-frame
  subtract_err  = 1 ; subtract FPI error 
  
  ; Magnetopause reconnection
  trange  = '2015-10-16/'+['13:06', '13:07'] ;time range to load
  time    = '2015-10-16/13:06:00' ;slice time
  
;  ; Magnetotail reconnection
;  trange  = '2017-07-06/'+['15:31', '15:32'] ;time range to load
;  time    = '2017-07-06/15:31:50.4452' ;slice time
;  
  ; Bow Shock 
;  trange  = '2015-11-04/'+['04:57:30','04:58:30']; time range to load
;  time    = '2015-11-04/04:57:45'; slice time
;  
  ;//////////////////////////////////////////
  psd_range = (species eq 'e') ? [1e-4, 1e+5] : [1e+2, 1e+9]; s3/km6
  
  ;--------------
  ; Initialize
  ;--------------
  sc      = 'mms'+prb
  name    = sc+'_d'+species+'s_dist_'+rate
  ename   = sc+'_d'+species+'s_disterr_'+rate
  trange = time_double(trange)
  time    = time_double(time)
  mag_data = 'mms'+prb+'_fgm_b_dmpa_'+brate+'_l2_bvec' ;name of bfield vector
  vel_data = 'mms'+prb+'_d'+species+'s_bulkv_dbcs_'+rate     ;name of bulk velocity vector
  !P.MULTI=[0,2,2,0,1]; For plotxyz. Somehow, !P.POSITION doesn't work.
  
  ;-------------
  ; LOAD
  ;-------------
  if ~spd_data_exists(vel_data, trange[0], trange[1]) then begin
    mms_load_fpi,trange=trange, probe=prb,data_rate=rate,level='l2',$
      datatype=['d'+species+'s-dist', 'd'+species+'s-moms']
  endif
  if ~spd_data_exists(mag_data, trange[0], trange[1]) then begin
    mms_load_fgm,trange=trange, probe=prb, level='l2', data_rate=brate
  endif
  
  ;------------------
  ; FPI DISTRIBUTION
  ;------------------
  dist = mms_get_dist(name, trange=trange,subtract_err=subtract_err, error=ename)
  
  ;--------------------------
  ; PLOT 1: Energy Spectrum
  ;--------------------------
  pad_df = moka_mms_pad_fpi(dist, time=time, sample=sample, units='df_km',$
    subtract_bulk=subtract_bulk, mag_data=mag_data, vel_data=vel_data)
  moka_mms_pad_plot, pad_df, output=['perp','para','anti-para'],$
    colors=[0,4,6],xunit='keV',xrange=[0.010,27.],yrange=psd_range
  
  ;----------------------------------
  ; PLOT 2: Pitch Angle Distribution
  ;----------------------------------
  pad_eflux = moka_mms_pad_fpi(dist, time=time, sample=sample, units='eflux', $
    subtract_bulk=subtract_bulk, mag_data=mag_data,vel_data=vel_data)
  zmax = max(pad_eflux.DATA,/nan)
  plotxyz,multi='2,2',mpanel='0,1',xmargin=[0.19,0.1],ymargin=[0.2,0],$
    pad_eflux.EGY*0.001, pad_eflux.PA, pad_eflux.DATA,/noisotropic,$
    /xlog, xrange=[0.010,27.],xtitle='energy [keV]',$
    ylog=0,yrange=[0,180],ytitle='pitch angle',ytickinterval=30,$
    zlog=1,zrange=[1e-5*zmax,zmax],ztitle=pad_eflux.UNITS

  ;------------------------------------------
  ; PLOT 3: velocity distribution 1D slices
  ;------------------------------------------
  xrange = (species eq 'e') ? [-1e+5,1e+5] : [-1500,1500] 
  moka_mms_pad_plot, pad_df, output=['perp','para','anti-para'],$
    color=[0,4,6],xunit='km/s',/noerase,$
    xrange=xrange, yrange=psd_range

  ;----------------------------------
  ; PLOT 4: Slice2D (bv)
  ;----------------------------------
  !P.POSITION = [0.65, 0.1, 0.9, 0.5]  
  slice = spd_slice2d(dist, time=time, sample=sample, $
    subtract_bulk=subtract_bulk, rotation='bv', mag_data=mag_data, vel_data=vel_data)
  spd_slice2d_plot, slice, /custom, /noerase, title='', $
    zrange=psd_range*(1e-30),zstyle=2, /PLOTBFIELD

  !P.POSITION = 0
  !P.MULTI = 0
  toc,clock
END
