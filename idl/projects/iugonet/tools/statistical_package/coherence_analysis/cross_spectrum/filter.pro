;+
; NAME:
; filter
;
; PURPOSE:
; This function returns a smoothed version of the input vector.
;
; CATEGORY:
; Time Series Analysis
;
; CALLING SEQUENCE:
; Result = FILTER( Vector, [Width], [Window] )
;
; INPUTS:
; Vector:  An vector of type floating point and length N.
;
; OPTIONAL INPUTS:
; Width:  The width, of type integer, of the smoothing window.
; Window:  A string containing the name of the smoothing window to 
;   return.  Options are 'boxcar', 'gaussian', 'hanning', 
;   'triangle'.  The default is a boxcar window.
;
; KEYWORD PARAMETERS:
; BOXCAR:  Sets the smoothing window to a boxcar filter.  This is
;   the default.  If set to a value, it replaces Width.
; EDGE_TRUNCATE:  Set this keyword to apply the smoothing to all points.
;   If the neighbourhood around a point includes a point outside 
;   the array, the nearest edge point is used to compute the 
;   smoothed result.  If EDGE_TRUNCATE is not set, the points near 
;   the end are replaced with NaNs.
; FILTER:  A vector containing the filter window to use.  This overrides 
;   the window requested in the Window input.  This also returns 
;   the filter after use.
; NAN:  Set this keyword to ignore NaN values in the input array, 
;   provided there is at least one defined value nearby.  The 
;   default is to return NaNs wherever they occur.
; NO_NAN:  Obsolete version of NAN keyword retained for compatibility 
;   but no longer used.
; START_INDEX:  The location of the centre of the window for the first 
;   averaged output value, in units of Vector indices.  Values must 
;   be greater than 0.  The default is 0.
; STEP:  An integer defining the step size for window translation, in 
;   units of Vector indices.  The default is 1.
; TRIANGLE:  Sets the smoothing window to a triangle filter.  The default
;   is a boxcar filter.  If set to a value, it replaces Width.
; WRAP_EDGES:  If set, the vector is treated as being cyclic and the 
;   ends are joined together when smoothing.
;
; OUTPUTS:
; Result:  Returns the smoothed version of Vector.
;
; USES:
; dimension.pro
; filter_window.pro
; plus.pro
;
; PROCEDURE:
; This function manually convolves the input vector with the filter.
;
; EXAMPLE:
;       Create a vector of daily data and a sinusoid for a year.
;   x = randomn( seed, 365 ) + sin( 6.28 * findgen( 365 ) / 365. )
; Smooth x with a boxcar filter of 7 days, wrapping the edges together.
;   result = filter( x, 7, 'boxcar', /wrap_edges )
;
;CODE:
; A. Shinbori, 30/09/2011.
;
;MODIFICATIONS:
; A. Shinbori, 30/10/2011
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

;***********************************************************************

function filter, $
  Vector, $
  Width, $
  Window, $
  FILTER=filt, $
  BOXCAR=boxcar, TRIANGLE=triangle, $
  START_INDEX=start_index, STEP=step, $
  WRAP_EDGES=wrapedgesopt, EDGE_TRUNCATE=edgetruncateopt, $
  NAN=nanopt, NO_NAN=nonanopt

;***********************************************************************
; Constants, Variables, and Options

; Load absolute constants
nan = !values.f_nan

; Load smoothing window
if not( keyword_set( filt ) ) then begin
   filt = filter_window( width, window, boxcar=boxcar, triangle=triangle )
endif

; Edge-handling options
if keyword_set( wrapedgesopt ) then begin
   wrapedgesopt = 1
endif else begin
   wrapedgesopt = 0
endelse
if keyword_set( edgetruncateopt ) then begin
   edgetruncateopt = 1
endif else begin
  edgetruncateopt = 0
endelse

; NaN handling option
if keyword_set( nanopt ) then begin
   nanopt = 1
endif else begin
   nanopt = 0
endelse

; Half-length of filter
hwidth0 = ( width - 1 ) / 2
hwidth1 = width / 2

; Length of vector
vector = reform( vector )
n = n_elements( vector )

; The default position of the first application of the smoothing window
if n_elements( start_index ) eq 0 then start_index = 0
if start_index lt 0 then begin
   print, 'In filter.pro, start_index is less then zero!'
   return, 0
endif

; The default window stepping
if not( keyword_set( step ) ) then step = 1

; Output vector
n_out = n - start_index
if step ne 1 then begin
   n_out = ( n_out + start_index - start_index / width * width ) / step
endif
outvec = nan * 1. * vector[0:n_out-1]

;***********************************************************************
; Smooth Vector

; Expanded version of Vector.
; This needs to be done to handle the edges.
newvec = vector

; If EDGE_TRUNCATE is set
if edgetruncateopt eq 1 then begin
  ; Pad ends with edge values
   if hwidth0 gt 0 then newvec = [ 0*fltarr(hwidth0)+vector[0], newvec ]
   if hwidth1 gt 0 then newvec = [ newvec, 0*fltarr(hwidth1)+vector[n-1] ]
; If WRAP_EDGES is set
endif else if wrapedgesopt eq 1 then begin
  ; Pad ends with values from opposite end
   if hwidth0 gt 0 then newvec = [ vector[n-hwidth0:n-1], newvec ]
   if hwidth1 gt 0 then newvec = [ newvec, vector[0:hwidth1-1] ]
; Default method for handling edges
endif else begin
  ; Pad ends with NaNs
   if hwidth0 gt 0 then newvec = [ 0*fltarr(hwidth0)+nan, vector ]
   if hwidth1 gt 0 then newvec = [ newvec, 0*fltarr(hwidth1)+nan ]
endelse

; Iterate through all points
for i = 0L, n_out - 1 do begin
  ; Extract windowed segment
   temp = newvec[start_index+i*step:start_index+i*step+width-1]
  ; Take weighted average
   outvec[i] = total(filt*temp, nan=nanopt)/total(filt*finite(temp),nan=nanopt)
endfor

return, outvec

;***********************************************************************
; The End
end