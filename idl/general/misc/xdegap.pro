;+
;NAME:
; xdegap
;PURPOSE:
; Locates gaps in data, and fills in with NaN
; This subroutine accepts the time array (can be cline time) t and the
; multi-dimensional array yarr that matches with the time array.
; It outputs the same arrays but with a different number of rows
; depending on how many rows were added. It then figures out where to
; add rows by checking which time differences are greater than or equal to
; deltat plus a margin and adds an array of rows of equispaced times of
; size tstep=gap/(number_of_points_that_fit_with_minimum_cumulative_error).
; The same number of rows is added to yarr with values equal to
; FLAGs.
; NOTE: ARRAYS AND STRUCTURES THAT NEED DEGAPPING ARE REDEFINED TO BE
; LARGER THAN BEFORE. THUS THE TIME COLUMN THAT HAS BEEN DEGAPPED
; WILL NOT CORRESPOND TO THE ELEMENTS OF AN ARRAY THAT HAS NOT BEEN
; DEGAPPED. CAUTION: DEGAP ALL ARRAYS OR STRUCTURES YOU ARE GOING TO USE
; TOGETHER, I.E., WITH ONE DEGAP CALL.
; ADDITIONAL NOTE: To conserve memory, see the ONENANPERGAP keyword.
;CALLING SEQUENCE:
; xdegap, dt, margin, ct, y, ct_out, y_out [,/nowarning] [,maxgap =
; <value>] [,iindices=<variable>] [,/onenanpergap] [,/twonanpergap]
;INPUT:
; dt = the time interval for tests
; margin = the margin 
; ct = the input time array
; y = the input array, can be 1 or 2d (n_elements(ct), m)
;OUTPUT:
; ct_out = the output time array, 
; y_out = the input time array
;KEYWORDS:
; nowarning = if set, suppresses warnings
; maxgap = the maximum gap size filled, in seconds
; iindicies = the indices in the output arrays that contain the original data
; flag = A numeric user-specified value to use for flagging gaps.
;   Defaults to a floating NaN.  If an array is entered, only the
;   first element is considered.If a non-numeric datatype is entered,
;   its value is ignored.
; onenanpergap = Fill gaps with only one NaN -> useful for conserving memory.
;   Also, for reference concerning post-processing, the INTERPOL function
;   propagates a single NaN just as it would many NaNs.
; twonanpergap = Fill gaps with only two NaNs, it turns out that
;                onenanpergap does not work well with
;                spectrograms. The exeption is if only one NAN fits in
;                the gap given the input parameters, then only one is
;                used.
; n_gaps = the number of gaps found
; gap_begin = the double-precision start times of the detected gaps.
; gap_end = the double-precision end times of the detected gaps.
; display_object = Object reference to be passed to dprint for output.
; output_message = Passes any messages generated up to the calling procedure as an array of strings
;
;
;HISTORY:
; From Vassilis' degap.pro, 2-apr-2007, jmm, jimm@ssl.berkeley.edu
; bug fix for undefined variable, jmm, 24-jun-2007
; Switched maxgap to seconds, jmm, 26-oct-2007
; Added comment to test svn version 4_00, jmm, 28-apr-2008
; Added ONENANPERGAP kw, W.M.F., 5 May, 2009.
; Added GAP_BEGIN, GAP_END kwd's, 12 June, 2009.
; Added _extra keyword, 20-oct-2009, jmm
; Added output_message keyword Feb-02-2011 prc
; Added twonanpergap, jmm, 14-aug-2012
; Return inputs instead of -1 if no gaps found, added n_gaps keyword, af 2016-05-03
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
;$LastChangedRevision: 33563 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/xdegap.pro $
;-
pro xdegap, dt, margin, ct0, y, ct_out, y_out, nowarning = nowarning, $
            iindices = iindices, maxgap = maxgap, flag = flag_in, $
            onenanpergap = onenanpergap, output_message=output_message, $
            display_object=display_object, twonanpergap=twonanpergap, $
            n_gaps=n_gaps, gap_begin = gstart, gap_end = gend, _extra = _extra
;
; EXAMPLES:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;dt=double(6.03187)&margin=double(0.5) : dt and margin do not need to be double
;xdegap,dt,margin,te3u,e3u              : te3u and e3u are arrays
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;dt=double(6.03187)&margin=double(0.5) 
;xdegap,dt,margin,te3u,e3u(*,0:2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;dt=double(3.01598)&margin=double(0.25)
;degap,dt,margin,ct,B_sc,maxgap=3
; (degaps anything that is greater than dt+margin and less than maxgap*dt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;

  compile_opt idl2, hidden

  ct_out = -1
  y_out = -1
  n_gaps = 0

  if (where( size(y, /type) eq [9, 6, 5, 4] ))[0] eq -1 then begin
    msg = '*** WARNING: Input data array not floating point: Gaps will be assigned the value "0".'
    dprint, msg, display_object=display_object
    if arg_present(output_message) then begin
      output_message = array_concat([msg],output_message)
    endif
  endif
  
  if ~undefined(flag_in) && ((where(size(flag_in[0], /type) eq [1,2,3,4,5,6,9,12,13,14,15]))[0] ne -1 ) then flag = flag_in[0] else begin
    if ~undefined(flag_in) then begin
      msg =  "*** WARNING: FLAG keyword value invalid.  Defaulting to floating NaN."
      dprint, msg, display_object=display_object
      if arg_present(output_message) then begin
        output_message = array_concat([msg],output_message)
      endif
    endif
    flag = !values.f_nan
  endelse
;
; Find size of arrays passed
  t = time_double(ct0)
  nct = n_elements(t)

  If(nct Le 1) Then Begin
    msg = 'Error: Not enough time elements'
    dprint, msg, display_object=display_object
    if arg_present(output_message) then begin
      output_message = array_concat([msg],output_message)
    endif
    Return
  Endif

  If(dt Le 0) Then Begin
    msg = 'Error: DT LE 0'
    dprint, msg, display_object=display_object
    if arg_present(output_message) then begin
      output_message = array_concat([msg],output_message)
    endif
    Return
  Endif

  ysz = size(y)
  If(ysz[0] Ne 1 And ysz[0] Ne 2) Then Begin
    msg = 'Error: Y input must be 1 or 2d'
    dprint, msg, display_object=display_object
    if arg_present(output_message) then begin
      output_message = array_concat([msg],output_message)
    endif
    Return
  Endif

  nyt = n_elements(y[*, 0])
  If(nyt Ne nct) Then Begin
    msg = 'Error: Y input does not match time input'
    dprint, msg, display_object=display_object
    if arg_present(output_message) then begin
      output_message = array_concat([msg],output_message)
    endif
    Return
  Endif
    
  av_dt = median(t[1:*]-t)
  If(av_dt Gt dt) Then Begin
    If(~keyword_set(onenanpergap) And ~keyword_set(twonanpergap)) Then Begin
        msg = 'Warning: median time resolution for data is greater than degap DT. Many NaNs in output'
        dprint, msg, display_object=display_object
        if arg_present(output_message) then begin
            output_message = array_concat([msg],output_message)
        endif
    Endif
  Endif

  nys = n_elements(y[0, *])
;
  nrows = n_elements(t)
  if (keyword_set(maxgap)) then mxgp = maxgap else mxgp = max(t)-min(t)

  irow = make_array(nrows, /long, /index)
  tdif = t[irow[1:nrows-1]]-t[irow[0:nrows-2]]
  t2check = dt
;i2add is the index of the time interval at the start of the gap
  i2add = where((((tdif-t2check) gt margin) and (tdif lt mxgp)), iany)
  toterror = double(0.)
  iaugment = long(0)
  if (iany gt 0) then begin
    n_gaps = iany  ;output # of gaps
    gstart = t[i2add]
    gend = t[i2add+1L]
    imore = lonarr(iany)
    tstep = dblarr(iany)
    xbegin = lonarr(iany+1l)
    xend = lonarr(iany+1l)
    for k = 0l, long(iany-1l) do begin
      imore_trial = long(tdif[i2add[k]]/dt+0.5)-1l
;onenanpergap is handled differently than 2, for onenanpergap, the
;point is put in the middle of the gap, for twonanpergap, one nan is
;put at each end of the gap, as determined by the dt value.
      if keyword_set(onenanpergap) then begin
          imore[k] = 1L
          tstep[k] = tdif[i2add[k]]/(imore[k]+1l)
      endif else if keyword_set(twonanpergap) then begin
        if imore_trial gt 2 then begin
            imore[k] = 2 
            tstep[k] = tdif[i2add[k]]/(imore_trial+1l)
        endif else begin
            imore[k] = imore_trial
            tstep[k] = tdif[i2add[k]]/(imore[k]+1l)
        endelse
      endif else begin
          imore[k] = imore_trial
          tstep[k] = tdif[i2add[k]]/(imore[k]+1l)
      endelse

      error = abs(dt*(imore[k]+1l)-tdif[i2add[k]])
      toterror = toterror+error
      iaugment = iaugment+imore[k]
      if ((error gt margin) and (keyword_set(nowarning) eq 0) $
        and ~keyword_set(onenanpergap) and ~keyword_set(twonanpergap)) then begin
        msg =  'warning: gap #'+ strtrim(k,2) + ' padded with increments significantly different from dt'
        dprint, msg, dlevel=4, display_object=display_object
        if arg_present(output_message) then begin
          output_message = array_concat([msg],output_message)
        endif
        msg = 'cumulative error = ' + strtrim(error,2)
        dprint, msg, dlevel=4, display_object=display_object
        if arg_present(output_message) then begin
          output_message = array_concat([msg],output_message)
        endif
      endif
    endfor
    newnrows = nrows+iaugment
;xbegin and xend are the start and end indices of the data without
;gaps in the final time array
    xbegin[0] = 0
    xend[0] = i2add[0]
    for k = 1l, long(iany-1) do begin
      xbegin[k] = xend[k-1]+imore[k-1]+1
      xend[k] = i2add[k]-i2add[k-1]+xbegin[k]-1
    endfor
    xbegin[iany] = xend[iany-1]+imore[iany-1]+1
    xend[iany] = nrows-1-i2add[iany-1]+xbegin[iany]-1
;
; Find which values to pass where.
; Iindices are the subscripts of the original t in the new t array
    inewrow = make_array(newnrows, /long, /index)
    iindices = where((inewrow ge xbegin[0]) and (inewrow le xend[0]), idummy)
    for k = 1l, long(iany) do begin
      iindices=[iindices, where((inewrow ge xbegin[k]) and (inewrow le xend[k]), idummy)]
    endfor
;
; Create new time array and fill it while finding where to pad
;
    ct_out = dblarr(newnrows)
    ct_out[iindices[*]] = t[0:*]
    if(keyword_set(twonanpergap)) then begin
        jindices=where((inewrow ge (xend[0]+1)) and (inewrow le (xbegin[0+1]-1)), jdummy)
        if (jdummy eq 2) then begin
            ct_out[jindices] = minmax([t[i2add[0]]+tstep[0], t[i2add[0]]+tdif[i2add[0]]-tstep[0]])
        endif else if(jdummy gt 0) then begin
            ct_out[jindices] = t[i2add[0]]+tstep[0]*(jindices-xend[0])
        endif
        if(iany gt 1) then begin
            for k = 1l, long(iany-1) do begin
                kindices=where((inewrow ge (xend[k]+1)) and (inewrow le (xbegin[k+1]-1)), kdummy)
                if (kdummy eq 2) then begin
                    ct_out[kindices] = minmax([t[i2add[k]]+tstep[k], t[i2add[k]]+tdif[i2add[k]]-tstep[k]])
                endif else if(kdummy gt 0) then begin
                    ct_out[kindices] = t[i2add[k]]+tstep[k]*(kindices-xend[k])
                endif
            endfor
        endif
    endif else begin
; jindices are the subscripts of the NaN times in the new time-array
        jindices=where((inewrow ge (xend[0]+1)) and (inewrow le (xbegin[0+1]-1)), jdummy)
        if (jdummy gt 0) then begin
            ct_out[jindices] = t[i2add[0]]+tstep[0]*(jindices-xend[0])
            for k = 1l, long(iany-1) do begin
                kindices=where((inewrow ge (xend[k]+1)) and (inewrow le (xbegin[k+1]-1)), kdummy)
                if (kdummy gt 0) then begin
                    jindices = [jindices, kindices]
                    ct_out[kindices] = t[i2add[k]]+tstep[k]*(kindices-xend[k])
                endif
            endfor 
        endif else begin        ; second gap is the real first gap
            for k = 1l, long(iany-1) do begin
                kindices=where((inewrow ge (xend[k]+1)) and (inewrow le (xbegin[k+1]-1)), kdummy)
                if (kdummy gt 0) then begin
                    jindices = [jindices, kindices]
                    ct_out[kindices] = t[i2add[k]]+tstep[k]*(kindices-xend[k])
                endif
            endfor
        endelse
    endelse
;
; Create new y array, fill them
;
    y_out = replicate(y[0], newnrows, nys)
    y_out[*] = flag
    y_out[iindices[*], *] = y
;
    if keyword_set(onenanpergap) then begin
      msg='ONENANPERGAP set -> one NaN inserted for each gap.'
      dprint, msg, dlevel=4, display_object=display_object
      if arg_present(output_message) then begin
        output_message = array_concat([msg],output_message)
      endif
    endif
    if keyword_set(twonanpergap) then begin
      msg='TWONANPERGAP set -> two NaNs inserted for each gap.'
      dprint, msg, dlevel=4, display_object=display_object
      if arg_present(output_message) then begin
        output_message = array_concat([msg],output_message)
      endif
    endif
  endif else begin

    ;output original data if no gaps were found - af 2016-05-03
    y_out = y
    ct_out = ct0
    iindices = lindgen(n_elements(ct_out))
  
    msg = 'No data gaps detected larger than '+strtrim(dt+margin,2)+$
      ' and less than '+strtrim(mxgp,2)+' seconds'
    dprint, msg, dlevel=4, display_object=display_object
    if arg_present(output_message) then begin
      output_message = array_concat([msg],output_message)
    endif
  endelse

;
  if (toterror gt 0) && ~keyword_set(twonanpergap) && ~keyword_set(onenanpergap) then begin
    msg= 'xdegap finished with total cumulative error not larger than '+ strtrim(toterror,2)
    dprint, msg, dlevel=4, display_object=display_object
    if arg_present(output_message) then begin
      output_message = array_concat([msg],output_message)
    endif
  endif
return
end
