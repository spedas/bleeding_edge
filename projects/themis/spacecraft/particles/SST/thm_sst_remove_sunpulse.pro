;+
;PROCEDURE: THM_SST_REMOVE_SUNPULSE
;Purpose:
;  Routine to perform a variety of calibrations on full distribution sst data.  
;  These can remove sun contamination and on-board masking. They can also scale 
;  the data to account for the loss of solid angle from the inability of the sst
;  to measure directly along the probe geometric Z axis and the inability to measure
;  directly along the probe geometric xy plane.(ie X=0,Y=0,Z = n or X=n,Y=m,Z=0,  are SST 'blind spots')  
;  THM_REMOVE_SUNPULSE routine should not generally be called directly.
;  Keywords to it will be passed down from higher level routines such as, thm_part_moments,
;  thm_part_moments2, thm_part_dist,thm_part_getspec, thm_sst_psif, and thm_sst_psef
;
;  Arguments:
;           dat:  the dat structure used in thm_part_dist, etc...
;
;  Keywords:
;  
;  method_clean: Simplified sun cleaning methods:
;                   Allowed options are:
;                   'manual': To use this option you need to specify the contaminated bins using the sun_bins keyword.  Specified bins are removed and interpolated over phi.
;                  
;                   'automatic': This method attempts to find contaminated bins using a statistical outlier test(modified z-score)
;                    then fills the bins by interpolation over phi.
;
;  sun_bins: method_clean manual removal bin selection.  Must be either a 64 element or a 16x64 element 0-1 array.  Bins set to 1 will be used, bins set to 0
;                  will be removed and filled.  
;                  The 64 element input is the same format as the output from edit3dbins, it removes and fills all energies at a particular angle of measure.
;                  The 16x64 element input allows the user to remove some bins at some of the 16 energies but to keep others.                                 
; 
;  
;  all_angle_median:  set this option to replace the angular distribution with the median
;                     of the data calculated over the all angles(thetas & phis) for each energy.
;                     This will generally eliminate contamination in some of the moments, but will make 
;                     analysis of angular plots impossible. It will also eliminate the velocity
;                     moment.
;  scale_sphere:  set this option to increase the value of all counts by 16%.  This accounts
;                 for the loss of phase space mentioned above.
;
;  method_sunpulse_clean:  set this to a string:  Either 'median' or 'spin_fit' or 'z_score_mod'
;              'median':  This will remove all points that are greater 
;                than 2.0 standard deviations from the median.By default they will be filled by a 
;                linear interpolation across the phi angle by default. 
;              'spin_fit':  This will remove all points that are greater
;                than 2.0 standard deviations from a spin fit across phi angle.  The equation used to
;                fit is A+B*sin(phi)+C*cos(phi). By default these points will be filled by a linear
;                interpolation across the phi angle. The fitting is done using the svdfit routine
;                from the idl distribution.
;              'z_score_mod': This will remove all points that have a modified z-score(calculated across phi) greater than 3.5 
;                The modified z-score is a normalized outlier detection test defined as follows:  
;                #1 X_Bar = median(X+1)
;                #2 Sigma = MAD = Median Absolute Deviation = median(abs(X-X_Bar))
;                #3 Z_Score_Mod = .6745*(X - X_Bar)/Sigma
;                This test can often get excellent results because it is insensitive to variation in standard deviation
;                and skew in the distributions.  
;
;  limit_sunpulse_clean: set this equal to a floating point number that will override the default of 2.0 standard
;             deviation tolerance or 3.5 z_score_tolerance, used by the sunpulse cleaning methods by default.
;             This keyword will only have an effect if the method_sunpulse_clean keyword is set.
;
;  fillin_method: Set this keyword to a string that specifies the method used to fill the points that are
;             removed via the method_sunpulse_clean or the mask_remove keywords, and bins removed when enoise_remove_method='fill'.
;             'interpolation': this routine will interpolate across the phi angle.  This is the 
;               default behavior. Interpolation is done using the interp_gap routine.
;             'spin_fit': this routine will perform a spin fit to the data after the points
;               have been removed using the equation A+B*sin(phi)+C*cos(phi).  It will then generate
;               expected values for each removed phi using the equation of fit.   The fitting is done using
;               the svdfit routine from the idl distribution.  Note that if 'spin_fit' is selected for
;               the clean method and the fill method, this routine will perform two spin fits.
;             'blank' : Just removes the data but doesn't fill with anything
;
;
;  mask_remove: Set this keyword to the proportion of values that must be 0 at all energies to determine that a mask is present.
;             Generally .99 or 1.0 is a good value.  The mask is a set of points that are set to 0 on-board the spacecraft. 
;             By default they will be filled by linear interpolation across phi.  NOTE: This argument is not actually accepted by
;             this routine, it is only documented here.  If you provide this argument to thm_part_moments, 
;             thm_part_moments2, or thm_part_getspec, those routines will appropriately set the value for the
;             mask_tot keyword to this routine.
;
; enoise_bins:  A 0-1 array that indicates which bins should be used to calculate electronic noise.  A 0 indicates that the
;               bin should be used for electronic noise calculations.  This is basically the output from the bins argument of edit3dbins.
;               It should have dimensions 16x4. NOTE: This argument is not actually accepted by
;               this routine, it is only documented here.  If you provide this argument to thm_part_moments, 
;               thm_part_moments2, or thm_part_getspec, those routines will appropriately set the value for the
;               enoise_tot keyword to this routine.
;
; enoise_bgnd_time:  This should be either a 2 element array or a 2xN element array(where n is the number of elements in enoise_bins).  
;                The arguments represents the start and end times over which the electronic background will be calculated for each
;                bin.  If you pass a 2 element array the same start and end times can be used for each bin.  If you pass a 2xN element
;                array, then the Ith bin in enoise_bins will use the time enoise_bgnd_time[0,I] as the start time and enoise_bgnd_time[1,I] as
;                the end time for the calculation of the background for that bin.  If this keyword is not set then electronic noise will not 
;                be subtracted.NOTE: This argument is not actually accepted by
;                this routine, it is only documented here.  If you provide this argument to thm_part_moments, 
;                thm_part_moments2, or thm_part_getspec, those routines will appropriately set the value for the
;                enoise_tot keyword to this routine.
;
; 
;
; enoise_remove_method(default: 'fit_median') set the keyword to a string specifying the method you want to use to calculate the electronic noise that will be subtracted 
;                This function combines values across time.  The allowable options are:
;                'min':  Use the minimum value in the time interval for each bin/energy combination.
;                
;                'average': Use the average value in the time interval for each bin/energy combination.
;                
;                'median': Use the median value in the time interval for each bin/energy combination.
;                
;                'fit_average': Fill in selected bins with a value that is interpolated across phi,  then use
;                     the average of these values across the time interval for each bin/energy combination.
;                     
;                'fit_median' : Fill in selected bins with a value that is interpolated across phi,  then use
;                     the mean of these values across the time interval for each bin/energy combination.
;                     
;                'fill': Fill in selected bins across phi, do not perform any subtraction.  This will
;                provide the cleanest looking plot, but the signal in that bin will be entirely removed.
;                 
;             
;                  NOTE: This argument is not actually accepted by
;                     this routine, it is only documented here.  If you provide this argument to thm_part_moments, 
;                     thm_part_moments2, or thm_part_getspec, those routines will appropriately set the value for the
;                     enoise_tot keyword to this routine.
;                     
;  enoise_remove_fit_method(default:'interpolation'):  Set this keyword to control the method used in 'fit_average' & 'fit_median' to
;                    fit across phi. 
;                    Options are: 
;                    'interpolation'
;                    'spin_fit' 
;                    By default, missing bins are interpolated across phi.  Setting
;                    enoise_remove_fit_method='spin_fit' will instead try to fill by fitting to a curve of the form A+B*sin(phi)+C*cos(phi).
; 
;  mask_tot:  The user should never manually set this keyword.  thm_part_moments,thm_part_moments2, & thm_part_getspec
;             will properly set this keyword, if the mask_remove keyword is set when they are called.
;
;  enoise_tot: The user should never manually set this keyword. thm_part_moments,thm_part_moments2, & thm_part_getspec
;             will properly set this keyword, if enoise keywords are set when called.
;

;
;
;
;
; Examples:  
; 
;            thm_part_moments,probe='a',inst='ps?f',method_clean='automatic'
;            
;            sun_bins=dblarr(64)+1
;            sun_bins[[30,39,40,46,55,56,61,62]] = 0 ;these are the bin numbers that will be removed 
;            thm_part_moments,probe='a',inst='ps?f',sun_method='manual',sun_bins=sun_bins
; 
;            thm_part_moments,probe='a',instrum=['ps?f'],mag_suffix='_peif_magf',scpot_suffix='_peif_sc_pot',moments='*', $
;              ,fillin_method='spin_fit',method_sunpulse_clean='spin_fit',limit_sunpulse_clean=1.8, $
;              trange=['2008-05-19','2008-05-20'],tplotsuffix='_fit_mask_fit'
;   
;            thm_part_getspec, probe='a', trange=['2007-03-23','2007-03-23'],theta=[0,45], data_type='ps?f', angle='phi', $
;              erange=[50000,100000], /mask_remove,method_sunpulse_clean='median',limit_sunpulse_clean=1.5, $
;              suffix='_fit_mask_med_t2'  
;          
;            edit3dbins,thm_sst_psef(probe='a', time_double('2008-03-01'),method_sunpulse_clean='spin_fit', $
;              limit_sunpulse_clean=1.2),ebins=4,sum_ebins=1
;
;
;SEE ALSO:
;  thm_part_moments.pro, thm_part_moments2.pro, thm_part_getspec.pro
;  thm_part_dist.pro, thm_sst_psif.pro, thm_sst_psef.pro,thm_crib_sst_contamination.pro
;  thm_sst_find_masking.pro, thm_sst_erange_bin_val.pro
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2012-08-10 09:42:49 -0700 (Fri, 10 Aug 2012) $
; $LastChangedRevision: 10800 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_remove_sunpulse.pro $
;-

;Moving to separate file
;;HELPER function
;;take the dat component of a structure and splits it into an array
;;ordered in terms of theta =  energy*angle->energy*theta*phi
;;dimensions 16*64->16*4*16,  phi is guaranteed to be contiguous but
;;not necessarily ascending(some phi may be out of phase by 180 degrees)
;;returns indices to perform this transformation
;function dat2angsplit,dat
;
;  compile_opt idl2,hidden
;  
;  index = indgen(16,64)
;  t_sort = bsort(dat.theta[0,*])
;  index = index[*,t_sort]
;  return,transpose(reform(index,16,16,4),[0,2,1]) ; this magic properly reforms and orders the dimensions  
;
;end

;HELPER function
;function to use in svd fitting for sunpulse correction
function svd_func,x,m

  compile_opt idl2,hidden

  return,[[1.0],[sin(x*!DTOR)],[cos(x*!DTOR)]]

end

;HELPER function
;performs filling using an svd fit
function do_spin_fill,dat,ref,phi

  compile_opt idl2,hidden

  dat2 = dat

  good = where(finite(dat2))
  bad = ssl_set_complement(good,indgen(n_elements(dat)))
  
  if good[0] ne -1 && bad[0] ne -1 then begin

    idx = where(dat2[good] ne 0)
    
    if idx[0] eq -1 then begin  ;if the system of equations is not-invertible because it is all zeros then add a constant offset
      dat2[good] += 1
    endif
      
    except_val = !EXCEPT  ;svdfit annoyingly reports a floating point error EVERY TIME IT OCCURS if you don't disable them entirely
    !EXCEPT = 0  
    result = svdfit(phi[good],dat2[good],a=[1,1,1],function_name='svd_func',status=stat) ;fit the data
    !EXCEPT = except_val
                     
    if stat eq 0 then begin
    ; replace values with fit points
      dat2[bad] = result[0] + result[1]*sin(phi[bad]*!DTOR)+result[2]*cos(phi[bad]*!DTOR)         
    endif else begin
      dat2[bad] = ref[bad] ;replace values with ref values to ensure there are no NaNs in the output
    endelse
      
    
    if idx[0] eq -1 then begin ;remove a constant offset if one was added
      dat2 -= 1
    endif
  endif
  
  idx = where(~finite(dat2))
  
  return,dat2

end

;fills nan's using the nearest neighbor method
;function fill_nn,x,y

;  idx = where(finite(y))

;  y_nan = y[idx]
;  x_nan = x[idx]
  
;  int = interpol(findgen(n_elements(idx)),x_nan,x)
;  return,y_nan[round(int)]

;end

function thm_sst_remove_sunpulse,dat, $
  all_angle_median=all_angle_median, $
  scale_sphere=scale_sphere, $
  method_sunpulse_clean=method_sunpulse_clean, $
  limit_sunpulse_clean=limit_sunpulse_clean, $
  fillin_method=fillin_method, $
  mask_tot=mask_tot, $
  enoise_tot=enoise_tot, $
  badbins2mask=badbins2mask,$
  method_clean=method_clean,$ ;simplified logic for sun contamination removal
  sun_bins=sun_bins,$
  no_sun=no_sun, $
  err_msg=err_msg, msg_suppress=msg_suppress

  compile_opt idl2

  ;prevents double calculation during recursive calls
  if keyword_set(no_sun) then return,dat

  if keyword_set(method_clean) then begin
    
    ;if not set, automatic and manual contamination methods will use interpolation by default
    if ~keyword_set(fillin_method) && ~is_string(fillin_method) then begin
      fillin_method = 'interpolation'
    endif
    
    if strlowcase(method_clean) eq 'automatic' then begin
      method_sunpulse_clean = 0 ;prevent interaction between multiple methods of contamination removal
    endif else if (method_clean) eq 'manual' then begin
      if undefined(sun_bins) then begin
        err_msg = 'Warning: Sun contamination removal set to manual but sun bins is not set'
        if ~keyword_set(msg_suppress) then dprint, dlevel=1, err_msg
        return,dat
      endif else begin
        dim = dimen(sun_bins)
        enoise_tot = dblarr(16,64)
        if n_elements(dim) eq 1 then begin
          idx = where(sun_bins eq 0,c)
          if c gt 0 then begin
            enoise_tot[*,idx] = replicate(!VALUES.D_NAN,16,c)
          endif else begin
            err_msg = 'Warning: No sun contamination bins selected, but sun contamination removal is turned on'
            if ~keyword_set(msg_suppress) then dprint, dlevel=1, err_msg
          endelse
        endif else if n_elements(dim) eq 2 then begin ;select sun contaminated bins by angle and energy
          idx = where(sun_bins eq 0,c) 
          if c gt 0 then begin
            enoise_tot[idx] = !VALUES.D_NAN
          endif else begin
            err_msg = 'Warning: No sun contamination bins selected, but sun contamination removal is turned on 
            if ~keyword_set(msg_suppress) then dprint, dlevel=1, err_msg
          endelse
        endif
      endelse
    endif
  endif

  ;************************************
  ;This code sets some defaults & validates inputs
  ;***********************************
  if keyword_set(limit_sunpulse_clean) && is_num(limit_sunpulse_clean,/real) then begin
    deviation = limit_sunpulse_clean
    z_score_val = limit_sunpulse_clean
  endif else begin
    deviation = 2.0
    z_score_val = 3.5
  endelse

  if keyword_set(method_sunpulse_clean) && is_string(method_sunpulse_clean) then begin
    if strmatch(strlowcase(method_sunpulse_clean),'median') then begin
      median = deviation
    endif else if strmatch(strlowcase(method_sunpulse_clean),'spin_fit') then begin
      spin_fit = deviation
    endif else if strmatch(strlowcase(method_sunpulse_clean),'z_score_mod') then begin   
      zvar_mod = z_score_val
    endif else begin
      err_msg = 'method_sunpulse_clean unrecognized, probable typo in input: ' + method_sunpulse_clean
      if ~keyword_set(msg_suppress) then dprint, dlevel=1, err_msg
      return, dat
    endelse
  endif
  
  if keyword_set(fillin_method) && is_string(fillin_method) then begin
    if strmatch(strlowcase(fillin_method),'spin_fit') then begin
      spin_fill = 1
    endif else if strmatch(strlowcase(fillin_method),'blank') then begin
      blank_fill = 1
    endif else if ~strmatch(strlowcase(fillin_method),'interpolation') then begin
      msg = 'fillin_method unrecognized, probable typo in input: ' + fillin_method
      err_msg = keyword_set(err_msg) ? [err_msg,msg]:msg
      if ~keyword_set(msg_suppress) then dprint, dlevel=1, msg
    endif
  endif 

  dat_out = dat ;don't mutate the original

  ;**********************************************
  ;This code substracts the electronic noise
  ;*********************************************
  if keyword_set(enoise_tot) && enoise_tot[0] ne -1 then begin
  
    dat_out.data -= enoise_tot
    
;Start removal here, to verify averages of enoise subtraction
;    idx = where(dat_out.data lt 0,c)
;    
;    if c gt 0 then begin
;      dat_out.data[idx] = 0
;    endif 
;Stop removal here
  
  endif

  ;****************************************************
  ;median keyword: kluge to remove sunpulse corruption
  ;This is an old option that sets all angles to the median over angle
  ;Better methods are now available
  ;****************************************************
  if keyword_set(all_angle_median) && ndimen(dat_out.data) eq 2 then begin
    dim_med = dimen(dat_out.data)
    val_med = rebin(median(dat_out.data,dimen=2),dim_med)
    dat_out.data = val_med
  endif 

  ;*****************************************************
  ;This code removes the masking, using the value passed
  ;via mask_tot
  ;*****************************************************
  if keyword_set(mask_tot) && mask_tot[0] ne -1 && ndimen(dat_out.data) eq 2 then begin
  
    mask_ang_idx = thm_sst_dat2angsplit(dat_out) ; get indices to convert 16*64->16*4*16
    mask_dat = dat_out.data[mask_ang_idx] ; get data from main stucture
    mask_phi = dat_out.phi[mask_ang_idx]
    mask_tots = mask_tot[mask_ang_idx]
      
    mask_phi[*,[0,2],0:7] -= 360  ; make phi's monotonic      
   
    idx = where(mask_tots eq 0)
   
    if idx[0] ne -1 then begin
    
      for i=0, n_elements(idx)-1 do begin
      
        en_idx = idx[i] mod 16     ; calculate dimensional indices from linear index
        th_idx = (idx[i] / 16) mod 4
        ph_idx = (idx[i] / 64)
        
        mask_dat[en_idx,th_idx,ph_idx] = !VALUES.F_NAN
      
      endfor
    
    endif
    
    mask_inv_ang_idx = bsort(mask_ang_idx)     ;calculate indices to reverse transformation
    dat_out.data = mask_dat[mask_inv_ang_idx]    ;store result
      
  endif 

  ;****************************************************************
  ;outliers keyword: remove sunpulse contamination by replacing the top n
  ;angles in the array with an svd fit
  ;This code removes the sun contamination using a certain distance from a central value
  ;Several different methods are available
  ;****************************************************************
  if (keyword_set(median) || keyword_set(spin_fit) || keyword_set(zvar_mod)) && ndimen(dat_out.data) eq 2 then begin

    rem_ang_idx = thm_sst_dat2angsplit(dat_out) ; get indices to convert 16*64->16*4*16
    rem_dat = dat_out.data[rem_ang_idx]
    rem_phi = dat_out.phi[rem_ang_idx]

    rem_phi[*,[0,2],0:7] -= 360  ; make phi's monotonic (sometimes they range from 180-360 degrees then 0-180, this makes them go from -180,180   

    for j=0L,16-1 do begin ; loop over energy
      for k=0L,4-1 do begin ; loop over theta
                            
        rem_var = reform(rem_dat[j,k,*]) ;store this loop's row of values
        rem_var_phi = reform(rem_phi[j,k,*]) ;store this loop's row of phis
          
        if keyword_set(median) then begin  
          rem_med = median(rem_var) ;calculate statistics
          rem_dev = sqrt(total((rem_var-rem_med)^2,/nan)/16)
          ;rem_min = rem_med-remove_std*rem_dev
          rem_min = 0
          rem_max = rem_med+median*rem_dev
          rem_good = where(rem_var ge rem_min and rem_var le rem_max) ;identify good values
          rem_bad = ssl_set_complement(rem_good,indgen(16))
          
          if rem_bad[0] ne -1 then begin
            rem_dat[j,k,rem_bad] = !VALUES.F_NAN ;store result    
          endif

        
        endif else if keyword_set(spin_fit) then begin
        
          idx = where(finite(rem_var))
        
          except_val = !EXCEPT  ;svdfit annoyingly reports a floating point error EVERY TIME IT OCCURS if you don't disable them entirely
         !EXCEPT = 0  
          result = svdfit(rem_var_phi[idx],rem_var[idx],a=[1,1,1],function_name='svd_func',status=rem_s) ;fit the data
         !EXCEPT = except_val
          
          if rem_s eq 0 then begin
            
            yfit = result[0] + result[1]*sin(rem_var_phi*!DTOR)+result[2]*cos(rem_var_phi*!DTOR)    
            ydev = stddev(yfit,/nan)
            ymin = 0
            ymax = yfit+spin_fit*ydev        
            ygood = where(rem_var ge ymin and rem_var le ymax) ;identify good values
            ybad = ssl_set_complement(ygood,indgen(16))
            
            if ybad[0] ne -1 && ygood[0] ne -1 then begin
              
              rem_dat[j,k,ybad] = !VALUES.F_NAN ;store result
              
            endif
          endif
        endif else if keyword_set(zvar_mod) then begin
        
          zvar_med = median(rem_var+1) ;calculate statistics
          zvar_mad = median(abs(rem_var - zvar_med))
          zvar_var = .6745*(rem_var - zvar_med)/zvar_mad
          
          zvar_good = where(zvar_var le zvar_mod)
          zvar_bad = ssl_set_complement(zvar_good,indgen(16))
        
          if zvar_bad[0] ne -1 then begin
            rem_dat[j,k,zvar_bad] = !VALUES.F_NAN ;store result    
          endif
        
        endif
         
      endfor
    endfor
    
     ;replace data
    rem_inv_ang_idx = bsort(rem_ang_idx)
    dat_out.data = rem_dat[rem_inv_ang_idx]           
      
  endif
  
  ;**************************************************
  ;perform fill, this is done in a separate step so that it can be done simulataneously for all modifications
  ;This code fills via interpolation of svd_fit
  ;**************************************************
  
  idx = where(~finite(dat_out.data))
  
  if idx[0] ne -1L then begin
  
    if ~keyword_set(blank_fill) || keyword_set(spin_fill) then begin
      fill_ang_idx = thm_sst_dat2angsplit(dat_out) ; get indices to convert 16*64->16*4*16
      fill_dat = dat_out.data[fill_ang_idx]
      fill_dat_ref = dat.data[fill_ang_idx] ; used as a reference to leave data unchanged if filling does not work
      fill_phi = dat_out.phi[fill_ang_idx]
      fill_bins = dat_out.bins[fill_ang_idx]
  
      fill_phi[*,[0,2],0:7] -= 360  ; make phi's monotonic (sometimes they range from 180-360 degrees then 0-180, this makes them go from -180,180   
  
      for j=0L,16-1 do begin ; loop over energy
        for k=0L,4-1 do begin ; loop over theta
                              
          fill_var = reform(fill_dat[j,k,*]) ;store this loop's row of values
          fill_var_ref = reform(fill_dat_ref[j,k,*])
          fill_var_phi = reform(fill_phi[j,k,*]) ;store this loop's row of phis          
                  
          triple_fill_var = [fill_var,fill_var,fill_var]  ;triple the data points to ensure that the fit wraps around the phi rotation
          triple_fill_ref = [fill_var_ref,fill_var_ref,fill_var_ref]
          triple_fill_phi = [fill_var_phi-360,fill_var_phi,fill_var_phi+360]
                  
          if keyword_set(spin_fill) then begin
            triple_fill_var = do_spin_fill(triple_fill_var,triple_fill_ref,triple_fill_phi)    
        ;    dprint,'Spin Fill'      
          endif else begin
            interp_gap,triple_fill_phi,triple_fill_var
        ;    dprint,'Interp Fill'
          endelse
              
          idx = where(~finite(triple_fill_var[16:31]),cnt)
          if cnt ne 0 then begin
            fill_dat[j,k,*] = 0
            fill_bins[j,k,*] = 0 ;if all bins got flagged as contaminated, disable those bins when constructing moments and spectra so that they don't contaminate the data
          endif else begin     
            fill_dat[j,k,*] = triple_fill_var[16:31] ;store result (only the center element of the triple)
          endelse
        endfor
      endfor    
      
      ;idx = where(~finite(fill_dat),cnt)
      
  ;    if cnt ne 0 then stop
      
        ;replace data
      fill_inv_ang_idx = bsort(fill_ang_idx)
      dat_out.data = fill_dat[fill_inv_ang_idx]
      dat_out.bins = fill_bins[fill_ang_idx]        
    endif else begin
     ; dprint,'Blank Fill'
      dat_out.bins[idx] = 0 ;if data blanking is set, disable NAN bins
      dat_out.data[idx]= 0 ;since data doesn't tolerate nans
    endelse
  endif
    
  if keyword_set(badbins2mask) then begin
     ;Zero out the bins
     bad_ang = where(badbins2mask eq 0)
     dat_out.bins[*,bad_ang] = 0
     dat_out.data[*,bad_ang] = !VALUES.D_NAN
  endif          
      
  ;*****************************************************************************        
  ;scale the input to account for the region of the sphere that is not covered
  ;This code scales the value for the loss of solid angle, if requested
  ;*****************************************************************************
  if keyword_set(scale_sphere) && ndimen(dat_out.data) eq 2 then begin
    dat_out.data *= 1.16         
  endif
              
  return,dat_out

end
