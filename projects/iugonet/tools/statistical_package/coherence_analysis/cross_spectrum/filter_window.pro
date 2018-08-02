;+
; NAME:
; filter_window
;
; PURPOSE:
; This function returns a desired filter window of desired width.
;
; CATEGORY:
; Time Series Analysis
;
; CALLING SEQUENCE:
; Result = filter_window([Width],[Window])
;
; OPTIONAL INPUTS:
; Width:  The width of the filter window, of type integer.
; Window:  A string containing the name of the smoothing window to 
;   return.  Options are 'boxcar', 'gaussian', 'hanning', 
;   'triangle'.  The default is a boxcar window.
;
; KEYWORD PARAMETERS:
; BOXCAR:  Sets the output to a boxcar window.  This is the default.  
;   If set to a value, it replaces Width (obsolete option).
; DIMENSION:  The dimension of the filter, of type integer.  The default 
;   is 1.
; TRIANGLE:  Sets the output to a triangle window.  The default is a 
;   boxcar window. If set to a value, it replaces Width (obsolete 
;   option).
;
; OUTPUTS:
; Result:  Returns the desired filter window.
;
; PROCEDURE:
; This function builds a filter of the desired shape and width, and then 
; normalises it.
;
; EXAMPLE:
; Define a two dimensional boxcar window of width 5.
;   result = filter_window( 5, 'boxcar', dimension=2 )
; result should be a 5x5 matrix with 0.04 for all entries.
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

function filter_window, $
  Width, $
  Window, $
  DIMENSION=dim, $
  BOXCAR=boxcarw, TRIANGLE=trianglew

;***********************************************************************
; Constants and Options

; Set Window to 'boxcar' or 'triangle' if it has not been set already
; (carry-over from an old method)
if not(keyword_set(window)) then begin
  ; If TRIANGLE is set
  if keyword_set(trianglew) then begin
     window = 'triangle'
  ; If BOXCAR is set (the default)
  endif else begin
     window = 'boxcar'
  endelse
endif
; Convert Window to lower case characters
window = strlowcase(window)

; Window width.
; If it has been specified in BOXCAR or TRIANGLE (old method)
if not(keyword_set(width)) then begin
  ; If it has been specified in BOXCAR
  if keyword_set(boxcarw) then width = boxcarw
  ; If it has been specified in TRIANGLE
  if keyword_set(trianglew) then width = trianglew
endif
; Make sure it is integer
width = round(width)

; If DIMENSION is not set, set it to 1
if not(keyword_set(dim)) then dim = 1

; Initialise output vector.
; We start with a one dimensional filter and extend later to other dimensions
; if desired.
filt = fltarr(width)

;***********************************************************************
; Create a Boxcar Filter

if window eq 'boxcar' then begin
   filt[*] = 1.
endif

;***********************************************************************
; Create a Gaussian Filter

if window eq 'gaussian' then begin
  ; Create a Gaussian filter with standard deviation width/8
  if width eq 1 then begin
     filt[*] = 1.
  endif else begin
     filt = exp(-(findgen(width)-(width-1.)/2)^2/(2.*((width-1.)/8.)^2))
  endelse
endif

;***********************************************************************
; Create a Hanning Filter

if window eq 'hanning' then begin
  ; Create a Hanning filter
   filt[*] = (hanning(width+1))[1:width]
endif

;***********************************************************************
; Create a Triangle Filter

if window eq 'triangle' then begin
  ; Determine half the width
   halfwidth = (width+1)/2
  ; Create an ascending vector of length half width
   z = (findgen(halfwidth)+1.)/halfwidth
  ; Build the filter by joining the ascending vector with its reverse
   filt[0:halfwidth-1] = z
   filt[width-halfwidth:width-1] = reverse(z)
endif

;***********************************************************************
; Extending Dimensions and Normalising

; If higher dimensional filter is requested
if dim gt 1 then begin
  ; Total size of new output array
   nfilt = (0l+width)^dim
  ; Initialise new output array
   filtndim = 1.+fltarr(nfilt)
  ; Iterate through array entries
  for i = 0l, nfilt-1 do begin
    ; Initialise a value for the entry
     val = 1.
    ; Copy the current entry position
     pos = i
    ; Iterate through dimensions
     for j = 0, dim-1 do begin
      ; An expression for the number of elements in the lesser dimensions
        nlessdim = width^(dim-1-j)
      ; Determine the position within the dim-1-j'th dimension
        dimpos = floor((1.*pos)/nlessdim)
      ; Multiply the dimpos'th value in filt with the current filtndim value
        filtndim[i] = filtndim[i]*filt[dimpos]
      ; Remove this dimension from our position in order to look at the next 
      ; smallest dimension
        pos = pos-dimpos*nlessdim
     endfor
  endfor
  ; Copy new output over old output
  filt = temporary(filtndim)
  ; Reform to an array
  filt = reform(filt,width+intarr(dim))
endif

; Normalise the integral to unity
filt = filt/total(filt)

return, filt
;***********************************************************************
;The End
END