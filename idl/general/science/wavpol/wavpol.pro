;+
;
; NAME:wavpol
;
; MODIFICATION HISTORY:Written By Chris Chaston, 30-10-96
;         :Modified by Vassilis, 2001-07-11
;         :Modified by Olivier Le Contel, 2008-07
;              to be able to change nopfft and steplength
;         :Modified by O. Le Contel, 2016-03
;              to be able to change frequency averaging parameter by adding bin_freq keyword
;         :Modified by O. Le Contel, LPP, 2016-07, in order to manage data gaps in the waveform
;              using test written by K. Bromund (in thm_cal_scm)
;         :Modified by egrimes, merging OLE's changes with SPEDAS's wavpol:
;             gamma -> gammay (avoids confusion with IDL's gamma function)
;             redefined W (fixed bug reported by Justin Lee) -> W=Total(smooth^2) / double(nopfft)
;             added pspec3 input, pspec[x,y,z], returns pspec3 (changes from Justin Lee) - added to original 10/10/2013
;             converted () to [], fixed tabbing
;             updated documentation with changes from Justin Lee - added to original 9/23/2014
;         :Modified by egrimes, now checking for 0s in the output time series, setting those
;             data values to NaNs
;         :Modified by jwl, generate smoothing array on the fly with the correct number of bins
;             
;              
;PURPOSE:To perform polarisation analysis of three orthogonal component time
;         series data.
;
;EXAMPLE: wavpol,ct,Bx,By,Bz,timeline,freqline,powspec,degpol,waveangle,elliptict,helict
;
;CALLING SEQUENCE: wavpol,ct,Bx,By,Bz,timeline,freqline,powspec,degpol,waveangle,elliptict,helict
;
;INPUTS:ct,Bx,By,Bz, are IDL arrays of the time series data; ct is cline time
;
;       Subroutine assumes data are in righthanded fieldaligned
;	coordinate system with Z pointing the direction
;       of the ambient magnetic field.
;
;       threshold:-if this keyword is set then results for ellipticity,
;       helicity and wavenormal are set to Nan if below 0.6 deg pol
;       
;Keywords:
;  nopfft (optional): Number of points in FFT
;
;  steplength (optional): The amount of overlap between successive FFT intervals
;
;  bin_freq (optional): No. of bins in frequency domain
;  
;OUTPUTS: The program outputs five spectral results derived from the
;         fourier transform of the covariance matrix (spectral matrix)
;         These are follows:
;
;         Wave power: On a linear scale (units of nT^2/Hz if input Bx, By, Bz are in nT)
;
;         Degree of Polarisation:
;		This is similar to a measure of coherency between the input
;		signals, however unlike coherency it is invariant under
;		coordinate transformation and can detect pure state waves
;		which may exist in one channel only.100% indicates a pure
;		state wave. Less than 70% indicates noise. For more
;		information see J. C. Samson and J. V. Olson 'Some comments
;		on the description of the polarization states
;		of waves' Geophys. J. R. Astr. Soc. (1980) v61 115-130
;
;         Wavenormal Angle:
;     The angle between the direction of minimum variance
;     calculated from the complex off diagonal elements of the
;     spectral matrix and the Z direction of the input ac field data.
;     for magnetic field data in field aligned coordinates this is the
;     wavenormal angle assuming a plane wave. See:
;     Means, J. D. (1972), Use of the three-dimensional covariance
;     matrix in analyzing the polarization properties of plane waves,
;     J. Geophys. Res., 77(28), 5551-5559,
;     doi:10.1029/JA077i028p05551.
;
;         Ellipticity:
;     The ratio (minor axis)/(major axis) of the ellipse transcribed
;     by the field variations of the components transverse to the
;     Z direction (Samson and Olson, 1980). The sign indicates
;     the direction of rotation of the field vector in the plane (cf.
;     Means, (1972)).
;     Negative signs refer to left-handed rotation about the Z
;     direction. In the field aligned coordinate system these signs
;     refer to plasma waves of left and right handed polarization.
;
;         Helicity:Similar to Ellipticity except defined in terms of the
;	direction of minimum variance instead of Z. Stricltly the Helicity
;	is defined in terms of the wavenormal direction or k.
;	However since from single point observations the
;	sense of k cannot be determined,  helicity here is
;	simply the ratio of the minor to major axis transverse to the
;       minimum variance direction without sign.
;
;
;RESTRICTIONS:-If one component is an order of magnitude or more  greater than
;	the other two then the polarisation results saturate and erroneously
;	indicate high degrees of polarisation at all times and
;	frequencies. Time series should be eyeballed before running the program.
;	 For time series containing very rapid changes or spikes
;	 the usual problems with Fourier analysis arise.
;	 Care should be taken in evaluating degree of polarisation results.
;	 For meaningful results there should be significant wave power at the
;	 frequency where the polarisation approaches
;	 100%. Remember, comparing two straight lines yields 100% polarisation.
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-03-29 21:55:43 -0700 (Sat, 29 Mar 2025) $
; $LastChangedRevision: 33213 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/wavpol/wavpol.pro $
;-
pro wavpol,ct,Bx,By,Bz,timeline,freqline,powspec,degpol,waveangle,elliptict,helict,pspec3,$
samp_per=samp_per_input, nopfft=nopfft_input,steplength = steplength_input, bin_freq = bin_freq_input, err_flag = err_flag
    
    If size(nopfft_input, /type) ne 0 then nopfft = nopfft_input else nopfft = 256
    If size(steplength_input, /type) ne 0 then steplength = steplength_input else steplength =  nopfft/2
    If size(bin_freq_input, /type) ne 0 then bin_freq = bin_freq_input else bin_freq =  3
    If size(err_flag, /type) ne 0 then err_flag = err_flag else err_flag = 0
    nopoints=n_elements(Bx)
    
    iano      = intarr(nopoints)
    
    dt = ct[1:*]-ct
    
    
    beginsampfreq=1d/(ct[1]-ct[0])
    endsampfreq=1d/(ct[nopoints-1]-ct[nopoints-2])
    if beginsampfreq NE endsampfreq then dprint,'Warning: file sampling ' + $
      'frequency changes',beginsampfreq,'Hz to',endsampfreq,'Hz' else dprint,'ac ' + $
      'file sampling frequency',beginsampfreq,'Hz'
    
    samp_freq = beginsampfreq 
    samp_per = 1d/samp_freq
      
    ; ========= Time anomaly detection from test written by K. Bromund (in thm_cal_scm)
    ; ========= time reversal detection
    reverse = where(dt lt 0, n_reverse)
    if n_reverse gt 0 then  iano[reverse] = 16 ; time reverse
    ; =========  discontinuity in time detection
    accuracy = 0.01 ; the accuracy of the sampling frequency should be about 1 percent.
    discont_trigger = accuracy*samp_per
    ;discontinuity = where(abs(dt-1.0/samp_freq) gt 2.0d-5, n_discont)
    discontinuity = where(abs(dt-1d/samp_freq) gt discont_trigger, n_discont)
    
    if n_discont gt 0 then iano[discontinuity] = 17 ; discontinuity in time
    ; ========= end of file
    iano[nopoints-1] = 22
    
    ;; discontinuity in sample rate (Minor bug: some changes in sample rate
    ;; can be mislabled as discontinuities in time)
    ;iano[ind_r[n_elements(ind_r)-1]] = 22
    
    errs = where(iano ge 15, n_batches)
    dprint,''
    dprint, 'Number of continuous batches: ', n_batches
    if n_batches gt 8d4 then begin
      dprint,''
      dprint, 'Large number of batches. Returning to avoid memory runaway.'
      err_flag = 1;
      return
    endif
    nbp_fft_batches = lonarr(n_batches)*0.
    
    ; Total numbers of FFT calculations including 1 leap frog for each batch
    ind_batch0 = 0
    nosteps    = 0
    
    for batch = 0,n_batches-1 do begin
      nosteps     = nosteps+floor((errs[batch] - ind_batch0)/steplength,/L64)
      ind_batch0  = errs[batch]
    endfor
    nosteps= nosteps+n_batches
    
    ;nosteps=(nopoints-nopfft)/steplength             ;total number of FFTs
    
    leveltplot=0.000001                                ;power rejection level 0 to 1
    lam=dblarr(2)
    nosmbins=bin_freq                                      ;No. of bins in frequency domain
    ;!p.charsize=2                                    ;to include in smoothing (must be odd)
    ;aa=[0.024,0.093,0.232,0.301,0.232,0.093,0.024]   ;smoothing profile based on Hanning
    ; The above 7-element smoothing array was used no matter how many frequency bins were requested.
    ; So for smaller values of bin_freq (e.g. the default 3), only the first few entries were used,
    ; so the smoothing was asymmetric and the weights didn't sum to 1.  For bin_freq > 7, the code would
    ; crash with an array index out of bounds.
    ;
    ; We now generate a Hamming (not Hann/hanning!) smoothing window on the fly, with the correct number of bins.  For bin_freq=7,
    ; the generated values match the old hardwired values.
    ; JWL 2023-02-01
    
    aa=hamming_window(nosmbins,/normalize)
    timeline = dblarr(nosteps)*0.
    ;
    ;ARRAY DEFINITIONS
    
    fields=make_array(3, nopoints,/double)
    power=Make_Array(nosteps,nopfft/2)
    specx=Make_Array(nosteps,nopfft,/dcomplex)
    specy=Make_Array(nosteps,nopfft,/dcomplex)
    specz=Make_Array(nosteps,nopfft,/dcomplex)
    wnx=Make_Array(nosteps,nopfft/2);DBLARR(nosteps,nopfft/2)
    wny=Make_Array(nosteps,nopfft/2);DBLARR(nosteps,nopfft/2)
    wnz=Make_Array(nosteps,nopfft/2);DBLARR(nosteps,nopfft/2)
    vecspec=Make_Array(nosteps,nopfft/2,3,/dcomplex)
    matspec=Make_Array(nosteps,nopfft/2,3,3,/dcomplex)
    ematspec=Make_Array(nosteps,nopfft/2,3,3,/dcomplex)
    matsqrd=Make_Array(nosteps,nopfft/2,3,3,/dcomplex)
    matsqrd1=Make_Array(nosteps,nopfft/2,3,3,/dcomplex)
    trmatspec=Make_Array(nosteps,nopfft/2,/double)
    xrmatspec=Make_Array(nosteps,nopfft/2,/double) ; added 10Sep2013 jhl
    yrmatspec=Make_Array(nosteps,nopfft/2,/double) ; added 10Sep2013 jhl
    zrmatspec=Make_Array(nosteps,nopfft/2,/double) ; added 10Sep2013 jhl
    powspec=Make_Array(nosteps,nopfft/2,/double)
    trmatsqrd=Make_Array(nosteps,nopfft/2,/double)
    degpol=Make_Array(nosteps,nopfft/2,/double)
    alpha=Make_Array(nosteps,nopfft/2,/double)
    alphasin2=Make_Array(nosteps,nopfft/2,/double)
    alphacos2=Make_Array(nosteps,nopfft/2,/double)
    alphasin3=Make_Array(nosteps,nopfft/2,/double)
    alphacos3=Make_Array(nosteps,nopfft/2,/double)
    alphax=Make_Array(nosteps,nopfft/2,/double)
    alphasin2x=Make_Array(nosteps,nopfft/2,/double)
    alphacos2x=Make_Array(nosteps,nopfft/2,/double)
    alphasin3x=Make_Array(nosteps,nopfft/2,/double)
    alphacos3x=Make_Array(nosteps,nopfft/2,/double)
    alphay=Make_Array(nosteps,nopfft/2,/double)
    alphasin2y=Make_Array(nosteps,nopfft/2,/double)
    alphacos2y=Make_Array(nosteps,nopfft/2,/double)
    alphasin3y=Make_Array(nosteps,nopfft/2,/double)
    alphacos3y=Make_Array(nosteps,nopfft/2,/double)
    alphaz=Make_Array(nosteps,nopfft/2,/double)
    alphasin2z=Make_Array(nosteps,nopfft/2,/double)
    alphacos2z=Make_Array(nosteps,nopfft/2,/double)
    alphasin3z=Make_Array(nosteps,nopfft/2,/double)
    alphacos3z=Make_Array(nosteps,nopfft/2,/double)
    gammay=Make_Array(nosteps,nopfft/2,/double)
    gammarot=Make_Array(nosteps,nopfft/2,/double)
    upper=Make_Array(nosteps,nopfft/2,/double)
    lower=Make_Array(nosteps,nopfft/2,/double)
    lambdau=Make_Array(nosteps,nopfft/2,3,3,/dcomplex)
    lambdaurot=Make_Array(nosteps,nopfft/2,2,/dcomplex)
    thetarot=Make_Array(nopfft/2,/double)
    thetax=DBLARR(nosteps,nopfft)
    thetay=DBLARR(nosteps,nopfft)
    thetaz=DBLARR(nosteps,nopfft)
    aaa2=DBLARR(nosteps,nopfft/2)
    helicity=Make_Array(nosteps,nopfft/2,3)
    ellip=Make_Array(nosteps,nopfft/2,3)
    waveangle=Make_Array(nosteps,nopfft/2)
    halfspecx=Make_Array(nosteps,nopfft/2,/dcomplex)
    halfspecy=Make_Array(nosteps,nopfft/2,/dcomplex)
    halfspecz=Make_Array(nosteps,nopfft/2,/dcomplex)
    pspecx=Make_Array(nosteps,nopfft/2,/double)
    pspecy=Make_Array(nosteps,nopfft/2,/double)
    pspecz=Make_Array(nosteps,nopfft/2,/double)
    pspec3=Make_Array(nosteps,nopfft/2,3,/double)
    
    ;
    ; DEFINE ARRAYS
    ;
    ;xs=Bx & ys=By & zs=Bz
    ;
    dprint,' '
    dprint, 'Total number of steps',nosteps
    dprint,' '
    
    ind0 = 0L
    KK   = 0L
    
    for batch = 0l, n_batches-1 do begin
      ind1 = errs[batch]
      nbp_batch  = ind1-ind0+1L
      ind1_ref = ind1
      KK_batch_start = KK
    
      xs = Bx[ind0:ind1]
      ys = By[ind0:ind1]
      zs = Bz[ind0:ind1]
      
      good_data = where(finite(xs), ngood,/L64)
      if(ngood Gt nopfft) then begin
          ;=== Number of fft spectra
          nbp_fft_batches[batch]   = floor(ngood/steplength,/L64)
          dprint,'Total number of possible FFT in the batch n°', batch,' is:',nbp_fft_batches[batch]
          
          ind0_fft=0L
       
          for j=0L,nbp_fft_batches[batch]-1L do begin        
          
              ind1_fft =  nopfft*(j+1L)-1L
              ind1_ref_fft = ind1_fft
              
              ;FFT CALCULATION
              smooth=0.08+0.46*(1-cos(2*!DPI*findgen(nopfft)/nopfft))
              
              tempx=smooth*xs[0:nopfft-1]
              tempy=smooth*ys[0:nopfft-1]
              tempz=smooth*zs[0:nopfft-1]
              specx[KK,*]=(fft(tempx,/double));+Complex(0,j*steplength*3.1415/32))
              specy[KK,*]=(fft(tempy,/double));+Complex(0,j*steplength*3.1415/32))
              specz[KK,*]=(fft(tempz,/double));+Complex(0,j*steplength*3.1415/32))
              halfspecx[KK,*]=specx[KK,0:(nopfft/2-1)]
              halfspecy[KK,*]=specy[KK,0:(nopfft/2-1)]
              halfspecz[KK,*]=specz[KK,0:(nopfft/2-1)]
              xs=shift(xs,-steplength)
              ys=shift(ys,-steplength)
              zs=shift(zs,-steplength)
              
              ;CALCULATION OF THE SPECTRAL MATRIX
              matspec[KK,*,0,0]=halfspecx[KK,*]*conj(halfspecx[KK,*])
              matspec[KK,*,1,0]=halfspecx[KK,*]*conj(halfspecy[KK,*])
              matspec[KK,*,2,0]=halfspecx[KK,*]*conj(halfspecz[KK,*])
              matspec[KK,*,0,1]=halfspecy[KK,*]*conj(halfspecx[KK,*])
              matspec[KK,*,1,1]=halfspecy[KK,*]*conj(halfspecy[KK,*])
              matspec[KK,*,2,1]=halfspecy[KK,*]*conj(halfspecz[KK,*])
              matspec[KK,*,0,2]=halfspecz[KK,*]*conj(halfspecx[KK,*])
              matspec[KK,*,1,2]=halfspecz[KK,*]*conj(halfspecy[KK,*])
              matspec[KK,*,2,2]=halfspecz[KK,*]*conj(halfspecz[KK,*])
              
              ;CALCULATION OF SMOOTHED SPECTRAL MATRIX
              ;
              ; NOTE: k does not iterate over the full set of spectral bins!  Depending on the nosmbins setting, the first
              ; few and last few frequencies will not have values assigned here.   They are implicitly set to 0, by the
              ; make_array calls that initialized the arrays.   This resulted in a discrepancy between IDL results, and
              ; Python results, where the data wasn't zero-initialized (and it wasn't obvious that it was necessary).
              ;
              ; JWL 2025-03-29
              ;
              
              for k=(nosmbins-1)/2, (nopfft/2-1)-(nosmbins-1)/2 do begin
                    ematspec[KK,k,0,0]=TOTAL(aa[0:(nosmbins-1)]*matspec[KK,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),0,0])
                    ematspec[KK,k,1,0]=TOTAL(aa[0:(nosmbins-1)]*matspec[KK,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),1,0])
                    ematspec[KK,k,2,0]=TOTAL(aa[0:(nosmbins-1)]*matspec[KK,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),2,0])
                    ematspec[KK,k,0,1]=TOTAL(aa[0:(nosmbins-1)]*matspec[KK,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),0,1])
                    ematspec[KK,k,1,1]=TOTAL(aa[0:(nosmbins-1)]*matspec[KK,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),1,1])
                    ematspec[KK,k,2,1]=TOTAL(aa[0:(nosmbins-1)]*matspec[KK,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),2,1])
                    ematspec[KK,k,0,2]=TOTAL(aa[0:(nosmbins-1)]*matspec[KK,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),0,2])
                    ematspec[KK,k,1,2]=TOTAL(aa[0:(nosmbins-1)]*matspec[KK,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),1,2])
                    ematspec[KK,k,2,2]=TOTAL(aa[0:(nosmbins-1)]*matspec[KK,(k-(nosmbins-1)/2):(k+(nosmbins-1)/2),2,2])
              endfor
              
              ;CALCULATION OF THE MINIMUM VARIANCE DIRECTION AND WAVENORMAL ANGLE
               aaa2[KK,*]=SQRT(IMAGINARY(ematspec[KK,*,0,1])^2+IMAGINARY(ematspec[KK,*,0,2])^2+IMAGINARY(ematspec[KK,*,1,2])^2)
               wnx[KK,*]=ABS(IMAGINARY(ematspec[KK,*,1,2])/aaa2[KK,*])
               wny[KK,*]=-ABS(IMAGINARY(ematspec[KK,*,0,2])/aaa2[KK,*])
               wnz[KK,*]=IMAGINARY(ematspec[KK,*,0,1])/aaa2[KK,*]
               waveangle[KK,*]=ATAN(Sqrt(wnx[KK,*]^2+wny[KK,*]^2),abs(wnz[KK,*]))
          
              ;CALCULATION OF THE DEGREE OF POLARISATION
              
              ;calc of square of smoothed spec matrix
               matsqrd[KK,*,0,0]=ematspec[KK,*,0,0]*ematspec[KK,*,0,0]+ematspec[KK,*,0,1]*ematspec[KK,*,1,0]+ematspec[KK,*,0,2]*ematspec[KK,*,2,0]
               matsqrd[KK,*,0,1]=ematspec[KK,*,0,0]*ematspec[KK,*,0,1]+ematspec[KK,*,0,1]*ematspec[KK,*,1,1]+ematspec[KK,*,0,2]*ematspec[KK,*,2,1]
               matsqrd[KK,*,0,2]=ematspec[KK,*,0,0]*ematspec[KK,*,0,2]+ematspec[KK,*,0,1]*ematspec[KK,*,1,2]+ematspec[KK,*,0,2]*ematspec[KK,*,2,2]
               matsqrd[KK,*,1,0]=ematspec[KK,*,1,0]*ematspec[KK,*,0,0]+ematspec[KK,*,1,1]*ematspec[KK,*,1,0]+ematspec[KK,*,1,2]*ematspec[KK,*,2,0]
               matsqrd[KK,*,1,1]=ematspec[KK,*,1,0]*ematspec[KK,*,0,1]+ematspec[KK,*,1,1]*ematspec[KK,*,1,1]+ematspec[KK,*,1,2]*ematspec[KK,*,2,1]
               matsqrd[KK,*,1,2]=ematspec[KK,*,1,0]*ematspec[KK,*,0,2]+ematspec[KK,*,1,1]*ematspec[KK,*,1,2]+ematspec[KK,*,1,2]*ematspec[KK,*,2,2]
               matsqrd[KK,*,2,0]=ematspec[KK,*,2,0]*ematspec[KK,*,0,0]+ematspec[KK,*,2,1]*ematspec[KK,*,1,0]+ematspec[KK,*,2,2]*ematspec[KK,*,2,0]
               matsqrd[KK,*,2,1]=ematspec[KK,*,2,0]*ematspec[KK,*,0,1]+ematspec[KK,*,2,1]*ematspec[KK,*,1,1]+ematspec[KK,*,2,2]*ematspec[KK,*,2,1]
               matsqrd[KK,*,2,2]=ematspec[KK,*,2,0]*ematspec[KK,*,0,2]+ematspec[KK,*,2,1]*ematspec[KK,*,1,2]+ematspec[KK,*,2,2]*ematspec[KK,*,2,2]
          
               Trmatsqrd[KK,*]=matsqrd[KK,*,0,0]+matsqrd[KK,*,1,1]+matsqrd[KK,*,2,2]
               Trmatspec[KK,*]=ematspec[KK,*,0,0]+ematspec[KK,*,1,1]+ematspec[KK,*,2,2]
               degpol[KK,(nosmbins-1)/2:(nopfft/2-1)-(nosmbins-1)/2]=(3*Trmatsqrd[KK,(nosmbins-1)/2:(nopfft/2-1)-(nosmbins-1)/2]-Trmatspec[KK,(nosmbins-1)/2: (nopfft/2-1)-(nosmbins-1)/2]^2)/(2*Trmatspec[KK,(nosmbins-1)/2: (nopfft/2-1)-(nosmbins-1)/2]^2)

               Xrmatspec[KK,*]=ematspec[KK,*,0,0] ; added 10Sep2013 jhl
               Yrmatspec[KK,*]=ematspec[KK,*,1,1] ; added 10Sep2013 jhl
               Zrmatspec[KK,*]=ematspec[KK,*,2,2] ; added 10Sep2013 jhl
               
              ;CALCULATION OF HELICITY, ELLIPTICITY AND THE WAVE STATE VECTOR
              
              alphax[KK,*]=Sqrt(ematspec[KK,*,0,0])
              alphacos2x[KK,*]=Double(ematspec[KK,*,0,1])/Sqrt(ematspec[KK,*,0,0])
              alphasin2x[KK,*]=-Imaginary(ematspec[KK,*,0,1])/Sqrt(ematspec[KK,*,0,0])
              alphacos3x[KK,*]=Double(ematspec[KK,*,0,2])/Sqrt(ematspec[KK,*,0,0])
              alphasin3x[KK,*]=-Imaginary(ematspec[KK,*,0,2])/Sqrt(ematspec[KK,*,0,0])
              lambdau[KK,*,0,0]=alphax[KK,*]
              lambdau[KK,*,0,1]=Complex(alphacos2x[KK,*],alphasin2x[KK,*])
              lambdau[KK,*,0,2]=Complex(alphacos3x[KK,*],alphasin3x[KK,*])
              
              alphay[KK,*]=Sqrt(ematspec[KK,*,1,1])
              alphacos2y[KK,*]=Double(ematspec[KK,*,1,0])/Sqrt(ematspec[KK,*,1,1])
              alphasin2y[KK,*]=-Imaginary(ematspec[KK,*,1,0])/Sqrt(ematspec[KK,*,1,1])
              alphacos3y[KK,*]=Double(ematspec[KK,*,1,2])/Sqrt(ematspec[KK,*,1,1])
              alphasin3y[KK,*]=-Imaginary(ematspec[KK,*,1,2])/Sqrt(ematspec[KK,*,1,1])
              lambdau[KK,*,1,0]=alphay[KK,*]
              lambdau[KK,*,1,1]=Complex(alphacos2y[KK,*],alphasin2y[KK,*])
              lambdau[KK,*,1,2]=Complex(alphacos3y[KK,*],alphasin3y[KK,*])
              
              alphaz[KK,*]=Sqrt(ematspec[KK,*,2,2])
              alphacos2z[KK,*]=Double(ematspec[KK,*,2,0])/Sqrt(ematspec[KK,*,2,2])
              alphasin2z[KK,*]=-Imaginary(ematspec[KK,*,2,0])/Sqrt(ematspec[KK,*,2,2])
              alphacos3z[KK,*]=Double(ematspec[KK,*,2,1])/Sqrt(ematspec[KK,*,2,2])
              alphasin3z[KK,*]=-Imaginary(ematspec[KK,*,2,1])/Sqrt(ematspec[KK,*,2,2])
              lambdau[KK,*,2,0]=alphaz[KK,*]
              lambdau[KK,*,2,1]=Complex(alphacos2z[KK,*],alphasin2z[KK,*])
              lambdau[KK,*,2,2]=Complex(alphacos3z[KK,*],alphasin3z[KK,*])
              
              ;HELICITY CALCULATION
              
              for k=0, nopfft/2-1 do begin
                  for xyz=0,2 do begin
                      upper[KK,k]=Total(2*double(lambdau[KK,k,xyz,0:2])*(Imaginary(lambdau[KK,k,xyz,0:2])),/NAN) ; Add /NAN OLe 2016
                      lower[KK,k]=Total((Double(lambdau[KK,k,xyz,0:2]))^2-(Imaginary(lambdau[KK,k,xyz,0:2]))^2,/NAN) ; Add /NAN OLE 2016
                      if (upper[KK,k] GT 0.00) then gammay[KK,k]=ATAN(upper[KK,k],lower[KK,k]) else gammay[KK,k]=!DPI+(!DPI+ATAN(upper[KK,k],lower[KK,k]))
              
                      lambdau[KK,k,xyz,*]=exp(Complex(0,-0.5*gammay[KK,k]))*lambdau[KK,k,xyz,*]
              
                      helicity[KK,k,xyz]=1/(SQRT(Double(lambdau[KK,k,xyz,0])^2+Double(lambdau[KK,k,xyz,1])^2+Double(lambdau[KK,k,xyz,2])^2)/SQRT(Imaginary(lambdau[KK,k,xyz,0])^2+Imaginary(lambdau[KK,k,xyz,1])^2+Imaginary(lambdau[KK,k,xyz,2])^2))
              
                      ;ELLIPTICITY CALCULATION
              
                      uppere=Imaginary(lambdau[KK,k,xyz,0])*Double(lambdau[KK,k,xyz,0])+Imaginary(lambdau[KK,k,xyz,1])*Double(lambdau[KK,k,xyz,1])
                      lowere=-Imaginary(lambdau[KK,k,xyz,0])^2+Double(lambdau[KK,k,xyz,0])^2-Imaginary(lambdau[KK,k,xyz,1])^2+Double(lambdau[KK,k,xyz,1])^2
                      if uppere GT 0 then gammarot[KK,k]=ATAN(uppere,lowere) else gammarot[KK,k]=!DPI+!DPI+ATAN(uppere,lowere)
              
                      lam=lambdau[KK,k,xyz,0:1]
                      lambdaurot[KK,k,*]=exp(complex(0,-0.5*gammarot[KK,k]))*lam[*]
              
                      ellip[KK,k,xyz]=Sqrt(Imaginary(lambdaurot[KK,k,0])^2+Imaginary(lambdaurot[KK,k,1])^2)/Sqrt(Double(lambdaurot[KK,k,0])^2+Double(lambdaurot[KK,k,1])^2)
                      ellip[KK,k,xyz]=-ellip[KK,k,xyz]*(Imaginary(ematspec[KK,k,0,1])*sin(waveangle[KK,k]))/abs(Imaginary(ematspec[KK,k,0,1])*sin(waveangle[KK,k]))
             
                  endfor
              endfor
              
              binwidth=samp_freq/nopfft
              ;scaling power results to units with meaning
              ;W=nopfft*Total(smooth^2); original Chaston
              
              ; redefining W ; 8Sep2012 jhl
              W=Total(smooth^2) / double(nopfft) ; switch to divide by nopfft
              powspec[KK,1:nopfft/2-2]=1/W*2*trmatspec[KK,1:nopfft/2-2]/binwidth
              powspec[KK,0]=1/W*trmatspec[KK,0]/binwidth
              powspec[KK,nopfft/2-1]=1/W*trmatspec[KK,nopfft/2-1]/binwidth
              
              ; added 10Sep2013 jhl
              pspecx[KK,1:nopfft/2-2]=1/W*2*xrmatspec[KK,1:nopfft/2-2]/binwidth
              pspecx[KK,0]=1/W*xrmatspec[KK,0]/binwidth
              pspecx[KK,nopfft/2-1]=1/W*xrmatspec[KK,nopfft/2-1]/binwidth
              
              pspecy[KK,1:nopfft/2-2]=1/W*2*yrmatspec[KK,1:nopfft/2-2]/binwidth
              pspecy[KK,0]=1/W*yrmatspec[KK,0]/binwidth
              pspecy[KK,nopfft/2-1]=1/W*yrmatspec[KK,nopfft/2-1]/binwidth
              
              pspecz[KK,1:nopfft/2-2]=1/W*2*zrmatspec[KK,1:nopfft/2-2]/binwidth
              pspecz[KK,0]=1/W*zrmatspec[KK,0]/binwidth
              pspecz[KK,nopfft/2-1]=1/W*zrmatspec[KK,nopfft/2-1]/binwidth
              
              pspec3[KK,*,0]=pspecx[KK, *]
              pspec3[KK,*,1]=pspecy[KK, *]
              pspec3[KK,*,2]=pspecz[KK, *]
              
              ind0_fft = ind0_fft+ steplength
              KK_batch_stop = KK
              KK = KK+1L
          endfor ; end of main body
        
          ;AVERAGING HELICITY AND ELLIPTICITY RESULTS
          
          elliptict=(ellip[*,*,0]+ellip[*,*,1]+ellip[*,*,2])/3
          helict=(helicity[*,*,0]+helicity[*,*,1]+helicity[*,*,2])/3
          
          ; CREATING OUTPUT STRUCTURES
          timeline[KK_batch_start:KK_batch_stop]=ct[ind0]+ABS(nopfft/2)/samp_freq+findgen(nbp_fft_batches[batch])*steplength/samp_freq
          ; avoid a crash when we hit the end of timeline
          if KK eq n_elements(timeline) then continue 
          ; time tag of the leap frog between batch
          timeline[KK_batch_stop+1]=ct[ind0]+ABS(nopfft/2)/samp_freq+(nbp_fft_batches[batch]+1)*steplength/samp_freq
          KK = KK+1L
      Endif Else Begin
          binwidth=samp_freq/nopfft
          dprint, 'Fourier Transform is not possible'
          ;print, 'Nbp = ', nbp_fft
          dprint, 'Ngood = ', ngood
          dprint, 'Required number of points for FFT = ', nopfft
          
          if KK ge n_elements(timeline) then continue
          
          timeline[KK]=ct[ind0]+ABS(nopfft/2)/samp_freq+steplength/samp_freq
          powspec[KK,1:nopfft/2-2]=!values.d_nan
          powspec[KK,0]=!values.d_nan
          powspec[KK,nopfft/2-1]=!values.d_nan
          KK = KK+1L
      Endelse
    
      ind0 = ind1_ref+1L
    
    endfor ; loop end on batches
    freqline=binwidth*findgen(nopfft/2)
    
    ; make sure there aren't any missing data points at the end of the output
    wherezero = where(timeline eq 0, zerocount)
    if zerocount ne 0 then begin
      timeline[wherezero] = !values.d_nan
      powspec[wherezero, *] = !values.d_nan
      if size(elliptict,/type) eq 5 then elliptict[wherezero, *] = !values.d_nan else elliptict = make_array(n_elements(powspec[*,0]),n_elements(powspec[0,*]),value=!values.d_nan)
      if size(helict,/type) eq 5 then helict[wherezero, *] = !values.d_nan else helict = make_array(n_elements(powspec[*,0]),n_elements(powspec[0,*]),value=!values.d_nan)
      pspecx[wherezero, *] = !values.d_nan
      pspecy[wherezero, *] = !values.d_nan
      pspecz[wherezero, *] = !values.d_nan
      pspec3[wherezero, *, *] = !values.d_nan
    endif
    return
end
