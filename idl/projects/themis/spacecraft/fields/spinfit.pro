;+
;Name:
; spinfit
;Purpose:
; performs a spinfit on B or E field data, results should be
; equivalent to FGS or EFS datatypes
;Calling Sqeuence:
; spinfit,arr_in_t,arr_in_data,arr_in_sunpulse_t,arr_in_sunpulse_data, $
;           A,B,C, avg_axis, median_axis,Sigma,Npoints,sun_data, $
;           min_points=min_points,alpha=alpha,beta=beta, $
;           plane_dim=plane_dim,axis_dim=axis_dim,phase_mask_starts=phase_mask_starts, $
;           phase_mask_ends=phase_mask_ends,sun2sensor=sun2sensor
;Input:
;  arr_in_t = time array for the data
;  arr_in_data = the data to be spin fit
;  arr_in_sunpulse_t = time array for sunpulse data
;  arr_in_sunpulse_data = sunpulse data
;Output:
;  A,B,C = fit parameters for spinfit
;  avg_axis = the average over the spin_axis direction
;  median_axis = the median over the spin_axis direction
;  sigma = sigma for each spin period
;  npoints = number of points in fit for each spin period
;  sun_data = midpoint times of spitfit data
;keywords:
;  plane_dim = Tells program which dimension to treat as the plane. 0=x, 1=y, 2=z. Default 0.
;  axis_dim = Tells program which dimension contains axis to average over. Default 0.  Will not
;             create a tplot variable unless used with /spinaxis.
;  min_points = Minimum number of points to fit.  Default = 5.
;  alpha = A parameter for finding fits.  Points outside of sigma*(alpha + beta*i)
;          will be thrown out.  Default 1.4.
;  beta = A parameter for finding fits.  See above.  Default = 0.4
;  phase_mask_starts = Time to start masking data.  Default = 0
;  phase_mask_ends = Time to stop masking data.  Default = -1
;  sun2sensor = Tells how much to rotate data to align with sun sensor.
;
;Example:
;      thm_spinfit,'th?_fg?',/sigma
; 20-sep-2010, changed sign of sun2sensor to insure agressment between
;              spinfit EFF and on-board EFS spinfit data, and between
;              spinfit FGL and on-board FGS spinfit data.
;Written by Katherine Ramer
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
pro spinfit,arr_in_t,arr_in_data,arr_in_sunpulse_t,arr_in_sunpulse_data, $
           A,B,C, avg_axis, median_axis,Sigma,Npoints,sun_data, $
           min_points=min_points,alpha=alpha,beta=beta, $
           plane_dim=plane_dim,axis_dim=axis_dim,phase_mask_starts=phase_mask_starts, $
           phase_mask_ends=phase_mask_ends,sun2sensor=sun2sensor

if not keyword_set(alpha) then alpha=1.4 else dprint, alpha
if not keyword_set(beta) then beta = 0.4
if not keyword_set(min_points) then min_points=5
if not keyword_set(phase_mask_starts) then phase_mask_starts=0
if not keyword_set(phase_mask_ends) then phase_mask_ends=-1
if not keyword_set(sun2sensor) then sun2sensor=0
if not keyword_set(plane_dim) then plane_dim=0
if not keyword_set(axis_dim) then axis_dim=0

; Make sure ARR_IN_T is monotonic (if necessary, remove 1 s chunks until it is).  Update ARR_IN_DATA correspondingly:
;
size_xxx=size(arr_in_t)
monoton=1b
non_monoton_detected = 0b
k0=0L
k1=k0+1L
while monoton && ( k1 le size_xxx[1]-1 ) do begin
  if ( arr_in_t[ k1++ ] - arr_in_t[ k0++ ] lt 0 ) then begin
    non_monoton_detected = 1b
    monoton = 0b
    w = where( (arr_in_t ge (-0.5+arr_in_t[ k0-1 ]) ) and (arr_in_t le (0.5+arr_in_t[ k0-1 ]) ), complement = complement )
    if complement[0] ne -1 then begin
      arr_in_t =  temporary( arr_in_t[ complement ] )
      arr_in_data =  temporary( arr_in_data[ complement, *] )
    endif
    size_xxx=size(arr_in_t)
    if w[0] ne -1 then begin
      if w[0] ne 0 then k0=w[0]-1 else k0 = 0
    endif
    k1=k0+1L
    monoton=1b
  endif
endwhile
if non_monoton_detected  then begin
  dprint, '*** WARNING: Non-monotonic time tags detected.  1 s chunks of data discarded until time tags are monotonic, but consult '+ $
                  'THEMIS software team as to quality of time tags for these data!'
endif

; find portion of data where the input overlaps the sunpulse times
;
arr_in_sunpulse_t=arr_in_sunpulse_t+sun2sensor*arr_in_sunpulse_data/360
size_xxx=size(arr_in_t)
overlap1=where(arr_in_sunpulse_t ge arr_in_t[0] and arr_in_sunpulse_t le arr_in_t[size_xxx[1]-1])
sizeoverlap=size(overlap1)

dprint, "using axis dimension = ", axis_dim

; define dummy arrays to be filled later
;
sigma=dblarr(sizeoverlap[1]-1)
meany=dblarr(sizeoverlap[1]-1)
result=dblarr(3)
A=dblarr(sizeoverlap[1]-1)
B=dblarr(sizeoverlap[1]-1)
C=dblarr(sizeoverlap[1]-1)
sun_data=dblarr(sizeoverlap[1]-1)
avg_axis=dblarr(sizeoverlap[1]-1)
median_axis=dblarr(sizeoverlap[1]-1)

Npoints = ulonarr( sizeoverlap[1]-1 )


i=0L
If(overlap1[0] Eq -1) Then Begin
  dprint, 'No good spin model' ;Bombs later
  Return
Endif

for i=0L, sizeoverlap[1]-2 do begin

  ; select a one period chunk of data:
  ;
  overlap = where(arr_in_t gt arr_in_sunpulse_t[overlap1[i]] and $
                  arr_in_t le arr_in_sunpulse_t[overlap1[i+1]], noverlap)

  if noverlap ge min_points then begin
    thx_xxx_keepy = arr_in_data[overlap, plane_dim]
    thx_xxx_keepz = arr_in_data[overlap, axis_dim]
    thx_xxx_keepx = arr_in_t[overlap]
    sun_data[i] = (arr_in_sunpulse_t[overlap1[i]]+arr_in_sunpulse_t[overlap1[i+1]])/2

    ; make sure masked data is not selected
    ;
    sizemask = size(phase_mask_start)
    if max(phase_mask_ends)-min(phase_mask_starts) gt 360 then begin
      phase_mask_ends[0] = -1
      dprint,  "Warning: Phase Mask maxend-minstart > 360.  No culling will occur."
    endif
    if not max(phase_mask_ends)-min(phase_mask_starts) lt 0 then begin
      phase = (2*!dPI/arr_in_sunpulse_data[overlap1[i]])*(thx_xxx_keepx[overlap] - arr_in_sunpulse_t[overlap1[i]])
      for k = 0, sizemask[1]-1 do begin
        mask = where(phase gt phase_mask_starts[k] and phase lt phase_mask_ends[k])
        thx_xxx_keepy[mask] = NaN
        thx_xxx_keepx[mask] = NaN
        thx_xxx_keepz[mask] = NaN
      endfor                    ;k
    endif

    ; throw out points 1.4 stddev (alpha) away from mean
    ;
    y = 0
    meany[i] = mean(thx_xxx_keepy)
    sigma[i] = stddev(thx_xxx_keepy)
    nottoss = where(thx_xxx_keepy le meany[i]+sigma[i]*(alpha+beta*y) and thx_xxx_keepy ge meany[i]-sigma[i]*(alpha+beta*y))
    If(nottoss[0] Ne -1) Then Begin
      sizenottoss = size(nottoss)
      sizelap = size(overlap)
      thx_xxx_keepy = thx_xxx_keepy[nottoss]
      thx_xxx_keepx = thx_xxx_keepx[nottoss]
      thx_xxx_keepz = thx_xxx_keepz[nottoss]
    ;print,sizelap[1]-sizenottoss[1], " initial points tossed"
      repeat begin
      ; recreate ranges after tossing out bad points above
      ;
        overlap = where(thx_xxx_keepx ge arr_in_sunpulse_t[overlap1[i]] and thx_xxx_keepx le arr_in_sunpulse_t[overlap1[i+1]])
      ;Old location of performing least squares fit
      ; toss out bad points again and repeat if any points were tossed
      ;
        y = y+1
        meany[i] = mean(thx_xxx_keepy)
        sigma[i] = stddev(thx_xxx_keepy)
        nottoss = where(thx_xxx_keepy le meany[i]+sigma[i]*(alpha+beta*y) and thx_xxx_keepy ge meany[i]-sigma[i]*(alpha+beta*y))
        If(nottoss[0] Ne -1) Then Begin
;                    and thx_xxx_keepx ge arr_in_sunpulse_t[overlap1[i]] and thx_xxx_keepx le arr_in_sunpulse_t[overlap1[i+1]] )
          thx_xxx_keepy = thx_xxx_keepy[nottoss]
          thx_xxx_keepx = thx_xxx_keepx[nottoss]
          thx_xxx_keepz = thx_xxx_keepz[nottoss]
          sizenottoss = size(nottoss)
          sizelap = size(overlap)
          NPoints[i] = sizenottoss[1]
        Endif Else Begin
;all points are bad for this spin?
          npoints[i] = 0
          sizenottoss = size(nottoss) & sizenottoss[1] = 0 ;end this loop
        Endelse
      ;print,sizelap[1]-sizenottoss[1], " points tossed"
      endrep until (sizenottoss[1] eq sizelap[1] or sizenottoss[1] le min_points)
      avg_axis[i] = mean(thx_xxx_keepz)
      median_axis[i] = median(thx_xxx_keepz)
    Endif Else npoints[i] = 0   ;no good values
    if (Npoints[i] le min_points) then begin
;      print, "No fit"
      A[i] = 'NaN'
      B[i] = 'NaN'
      C[i] = 'NaN'
    endif else begin

      ; calculate wt
      ;
      wt = (2*!dPI/arr_in_sunpulse_data[overlap1[i]])*(thx_xxx_keepx[overlap] - arr_in_sunpulse_t[overlap1[i]])

      ; construct matrices
      ;
      sinwt = sin(wt)           ;Repeated expressions.
      coswt = cos(wt)
      totsinwt = total(sinwt)
      totcoswt = total(coswt)
      sincoswt = sinwt*coswt
      totsincoswt = total(sincoswt)

      ; perform least squares fit
      ;
      result = la_least_squares([[sizelap[1], totcoswt, totsinwt], [totcoswt, total(coswt^2), totsincoswt], [totsinwt, totsincoswt, total(sinwt^2)]], $
                                transpose( [ total(thx_xxx_keepy), total(coswt*thx_xxx_keepy), total(sinwt*thx_xxx_keepy) ] ) )
      
      ; print,result
      ;
      A[i] = result[0]
      B[i] = result[1]
      C[i] = result[2]
    endelse
  endif else begin
    A[i] = 'NaN'
    B[i] = 'NaN'
    C[i] = 'NaN'
    sun_data[i] = (arr_in_sunpulse_t[overlap1[i]]+arr_in_sunpulse_t[overlap1[i+1]])/2
  endelse
endfor                          ; i

end

