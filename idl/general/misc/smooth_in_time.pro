Function temp_dtx_test, dtx0, min_dtx_fraction = min_dtx_fraction, _extra = _extra
; Function to get an effective minimum value for dtx, this will reject
; any negative or unduly small values, that show up fewer times than
; min_dtx_fraction (default is 0.10) times the peak value
;No zero values are allowed
  If(keyword_set(min_dtx_fraction)) Then mf = min_dtx_fraction Else mf = 0.10
  xxx = where(dtx0 Gt 0)
  If(xxx[0] Eq -1) Then Return, 1.0 ;you've got troubles
;Get a histogram of log(dtx)
  dtx = alog10(dtx0[xxx])       ;bin in orders of magnitude
  minv = double(long(min(dtx)))-1.0d0
  maxv = double(long(max(dtx)))+1.0d0 ;note that there should always be 3 bins
  h = histogram(dtx, min = minv, max = maxv, binsize = 1.0)
  edges = minv+findgen(n_elements(h)+1)
  lowest_reasonable_bin = min(where(h Ge mf*max(h)))
  otp = min(dtx[where(dtx Ge edges[lowest_reasonable_bin])])
  otp = 10.0^otp
  Return, otp
End

Function temp_t_integration, array, n
;simulate a time integration using the smooth function
;at each point, 
;result = n*smooth(array, n)/(n-1)-shift(array,
;-n/2)/(2.0*(n-1))-shift(array, n/2)/(2.0*(n-1))
;put n values on either side of the array to avoid edge issues
  narr = n_elements(array)
  first = array[0]
  last = array[narr-1]
  array_x = [replicate(first, n), temporary(array), replicate(last, n)]
  array_x = n*smooth(array_x, n)/(n-1)-$
    shift(array_x,-n/2)/(2.0*(n-1))-$
    shift(array_x, n/2)/(2.0*(n-1))
  return, array_x[n:n+narr-1]

End
;+
;NAME:
; smooth_in_time
;PURPOSE:
; Runs smooth for irregular grids, after regularising grid
;CALLING SEQUENCE:
; ts = smooth_in_time(array, time_array, dt, /backward, /forward,
;                  /double, /no_time_interp)
;INPUT:
; array = a data array, can be 2-d (ntimes, n_something_else), the
;         first index is smoothed or averaged.
; time_array = a time array (in units of seconds)
; dt = the averaging time (in seconds)
;KEYWORDS:
; backward = if set, perform an average over the previous dt, the
;            default is to average from t-dt/2 to t+dt/2
; forward = if set, perform an average over the next dt
; double = if set, do calculation in double precision
;                  regardless of input type. (If input data is double
;                  calculation is always done in double precision)
; no_time_interp = if set, do *not* interpolate the data to the
;                  minimum time resolution. The default procedure is
;                  to interpolate the data to a regularly spaced grid,
;                  and then use ts_smooth to get the running
;                  average. This alternative can be slow.
; smooth_nans = if set, replace Nan values in the input array with the
;               average values calculated using the ts_smooth
;               process. This has not been implemented for the
;               no_time_interp option.
; true_t_integration = if set, subtract 1/2 of the end points of the
;                      integration from each value, to obtain the
;                      value for an integration over time of the
;                      appropriate interval. This has not been
;                      implemented for the no_time_interp option.
;                      Ths is created for the high_pass_filter.
; interp_resolution = If time interpolation is being used, set this
;                     option to control the number of seconds between
;                     interpolated samples.  The default is to use
;                     the value of the smallest separation between 
;                     samples.  Any number higher than this will sacrifice
;                     output resolution to save memory. (NOTE: This option
;                     will not be applied if no interpolation is being
;                     performed because either (1) no_time_interp is set or
;                     (2) the sample rate of the data is constant)
; dtx_min_fraction = When interp_resolution is not set, the default is to use
;                    the value of the smallest separation between 
;                    samples, with the caveat that this value of smallest
;                    separation has to occur relatively
;                    frequently. Dtx_min_fraction is used to get an
;                    effective value for the minimum of the input time
;                    resolution. If a suspected minimum value occurs
;                    less than dtx_min_fraction times the peak of a
;                    histogram of time resolutions, it is
;                    discarded. The default value is 0.10
; interactive_warning = if keyword is set pops up a message box if there are memory problems and asks
;                     the user if they would like to continue
; interactive_varname = set this to a string indicating the name of the quantity to be used in the warning message.
; warning_result = assign a named variable to this keyword to determine the result of the computation              
; display_object = Object reference to be passed to dprint for output.
; 
;OUTPUT:
; ts = the data array smoothed or averaged
;
;
;HISTORY:
; 13-mar-2008, jmm, jimm@ssl.berkeley.edu, hacked from
; high_pass_filter.pro and added ts_smooth as the default
; 13-mar-2008, ts_smooth is way too slow, just uses smooth.pro now
; 6-may-2008, jmm, added sort for input data for cases with
;                  non-monotonic time_arrays
; 23-apr-2008, pcruce, Added padding for no_time_interp option, added _extra keyword
; 28-apr-2008, pcruce, Added interp_resolution option, added memory warning, 
;                        mod to guarantee that precision of output is at least as 
;                        large as precision of input
;$LastChangedBy: ghanley $
;$LastChangedDate: 2024-07-03 11:10:37 -0700 (Wed, 03 Jul 2024) $
;$LastChangedRevision: 32716 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/smooth_in_time.pro $
;-

Function smooth_in_time, array, time_array, dt, $
                         backward = backward,$
                         forward = forward, $
                         double = double, $
                         no_time_interp = no_time_interp, $
                         smooth_nans = smooth_nans, $
                         true_t_integration = true_t_integration, $
                         interp_resolution = interp_resolution, $
                         interactive_warning = interactive_warning, $
                         interactive_varname = interactive_varname, $
                         warning_result = warning_result, $
                         display_object=display_object, $
                         _extra = _extra
                         
  out_array = -1                ;initialize
  warning_result = 1
;; determine number of rows in input array
;; Note: this is a tplot array, reversed from
;; idl array
  n =  n_elements(array[*, 0])
;; Make sure time values exist for each entry
  If(n_elements(time_array) Ne n) Then Begin
    dprint, 'Array mismatch', display_object=display_object
    return,  out_array
  Endif
;; Produces array of values, the first being the dimension of the array
;; which will later be used as a check
  sz = size(array)
  If(sz[0] Eq 2) Then nv = sz[2] Else nv = 1 ;the 2nd index will be looped over
;; Now declare output array, fill with NaN's
  If(keyword_set(double)) || is_num(array,/double) Then Begin
    out_array = double(array) & out_array[*] = !values.d_nan
  Endif Else Begin
    out_array = float(array) & out_array[*] = !values.f_nan
  Endelse
;; Do the calculation
  If(keyword_set(no_time_interp)) Then Begin
;; This for loop will take us through the full array of values; this
;; can be very slow


    ;Note:  The loop below could probably be speed-optimized by use of the value_locate routine
    ;which would prevent the where function from being called on every iteration
    ;This might entail the need to allocate copies of the inputs for the duration
    For j = 0l, n-1 Do Begin 
;; Get subscripts of group to take running average over
;; nss is the number values returned
      If(keyword_set(backward)) Then Begin
        t0 = time_array[j]-dt
        t1 = time_array[j]
      Endif Else If(keyword_set(forward)) Then Begin
        t0 = time_array[j]
        t1 = time_array[j]+dt
      Endif Else Begin
        t0 = time_array[j]-dt/2.0
        t1 = time_array[j]+dt/2.0
      Endelse
      
      ;padding is done in-place.  This probably entails a speed hit because the operation is repeated,
      ;But it is assumed that the /no_time_interp is being used because the user values space over time
      ss = where([time_array[0]-dt/2.0, time_array, time_array[n-1]+dt/2.0] Lt t1 And $
                 [time_array[0]-dt/2.0, time_array, time_array[n-1]+dt/2.0] Ge t0, nss)
      
      ;; Check if subscripts available
      
      If(nss Gt 0) Then Begin
       
        For k = 0l, nv-1 Do Begin
        
          ok = where(finite(([array[0, k], array[*, k], array[n-1, k]])[ss]), nok) ;Do not include NaN's
          
          If(nok Gt 0) Then out_array[j, k] = total(([array[0, k], array[*, k], array[n-1, k]])[ss[ok]])/nok
        Endfor
      Endif
    Endfor
  Endif Else Begin              ;default behavior is to interpolate
  
    For k = 0, nv-1 Do Begin
      ok = where(finite(array[*, k]), nok) ;Do not include NaN's
      If(nok Gt 0) Then Begin
        tx = time_array[ok]     ;ok times
        ax = array[ok, k]       ;ok data points
        dtx = tx[1:*]-tx
        bad_dtx = where(dtx Le 0.0, nbad_dtx)
        If(nbad_dtx Gt 0) Then Begin ;sort the data
          dprint, 'Data is non-monotonic, Sorting...', display_object=display_object
          ss_tx = sort(tx)
          tx = tx[ss_tx]
          ax = ax[ss_tx]
          dtx = tx[1:*]-tx
        Endif
        if keyword_set(interp_resolution) then begin
           dtx0 = interp_resolution[0] ;needs to be scalar
        endif else begin
          dtx0 = temp_dtx_test(dtx, _extra = _extra)
          dtx0 = dtx0[0] ;needs to be scalar
        endelse
;          dtx0 = min(dtx[where(dtx Gt 0.0)]) ;min value of t resolution
        not_min = where(abs(dtx-dtx0) Gt dtx0/100.0, cnot_min) ;small allowance
        nrv = ceil(dt/dtx0)
;Note that for non-forward or backwards, this value must be an odd
;number gt 3
        If(nrv Lt 3) Then begin
          dprint, 'Number of smoothing points is LT 3, Smoothing over 3*minimum resolution', display_object=display_object
        endif
        nrv = nrv > 3
        If(nrv Mod 2 Eq 0) Then Begin 
          dprint, 'Even number of smoothing points:'+strcompress(string(nrv))+', Adding 1', display_object=display_object
          nrv = nrv+1
        Endif
;Now do the smoothing      
        If(cnot_min Ne 0) Then Begin
;Create the regular grid
          nr = ceil((tx[nok-1]-tx[0])/dtx0,/L64)
          t1 = tx[0]+dtx0*dindgen(nr)
        Endif Else Begin
          t1 = tx
          nr = nok
        Endelse
        
        ;first loop warning on memory allocation
        if k eq 0 then begin
          
          if is_num(out_array,/double) then begin
            vector_mem_factor = 2
          endif else begin
            vector_mem_factor = 1
          endelse
          
          ;elements in target * 4 bytes/word * ((2 words per time element)+(1 or 2 words per data element))
          ;divided by 1024 bytes per kB and 1024 kB per mB
          mem_usage_mb_interp = 4D*n_elements(t1)*(2D + vector_mem_factor)/(1024D^2)
          
          if keyword_set(true_t_integration) then begin
            ;(padding elements(front and back) + n of data elements)*4 bytes/word*(1 or 2 bytes per data element)
            ;divided by 1024 bytes per kB and 1024 kB per mB
            mem_usage_mb_smooth = (nrv * 2 + n_elements(t1))*4*vector_mem_factor*2/(1024D^2)
          endif else begin
            mem_usage_mb_smooth = 0
          endelse
          
          mem_usage_total = max([mem_usage_mb_smooth,mem_usage_mb_interp])
          
          ;only warn if memory usage is significant
          if mem_usage_total gt 100 then begin
            ;because of temporary allocation during operations, memory allocation may be as much as double the declared usage
            if keyword_set(interactive_warning) then begin
              if keyword_set(interactive_varname) then begin
                 s = 'WARNING: Operation on ' + interactive_varname + ' will take between ' + strtrim(mem_usage_total,2) + ' MB and ' + strtrim(2*mem_usage_total,2) + ' MB of memory. Do you want to continue?'
              endif else begin
                 s = 'WARNING: Operation will take between ' + strtrim(mem_usage_total,2) + ' MB and ' + strtrim(2*mem_usage_total,2) + ' MB of memory. Do you want to continue?'
              endelse
              ok = dialog_message(s,/question,/center)
              if strlowcase(ok) eq 'no' then begin
                warning_result = 0
                return,out_array     
              endif
            endif else begin
              msg = 'WARNING: Operation will take between ' + strtrim(mem_usage_total,2) + ' MB and ' + strtrim(2*mem_usage_total,2) + ' MB of memory'
              dprint, msg, display_object=display_object
            endelse
          endif
          
        endif
        out1 = interpol(temporary(ax), temporary(tx), t1) ;interp to hi-res
;get the average, pad backward and forwards if needed
        If(keyword_set(backward)) Then Begin
          out1 = [fltarr(nrv/2)+out1[0], out1]
          If(keyword_set(true_t_integration)) Then Begin
            rout1 = temp_t_integration(out1, nrv)
          Endif Else rout1 = smooth(out1, nrv, /edge_truncate)
          rout1 = rout1[0:nr-1]
        Endif Else If(keyword_set(forward)) Then Begin
          out1 = [out1, fltarr(nrv/2)+out1[nr-1]]
          If(keyword_set(true_t_integration)) Then Begin
            rout1 = temp_t_integration(out1, nrv)
          Endif Else rout1 = smooth(out1, nrv, /edge_truncate)
          rout1 = rout1[nrv/2:*]
        Endif Else Begin
          If(keyword_set(true_t_integration)) Then Begin
            rout1 = temp_t_integration(out1, nrv)
          Endif Else rout1 = smooth(out1, nrv, /edge_truncate)
        Endelse
;And interpolate back to the full time_array
        If(keyword_set(smooth_nans)) Then Begin
          out_array[*, k] = interpol(rout1, t1, time_array)
        Endif Else out_array[ok, k] = interpol(rout1, t1, time_array[ok])
      Endif
    Endfor
  Endelse
  Return, out_array
End
      
      
