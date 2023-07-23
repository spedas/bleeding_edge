;+
; NAME:
;	EXTREMA
;
; PURPOSE:
;	This function returns the locations of the local extrema in a 
;	given time series.
;
; CATEGORY:
;	Time Series Analysis
;
; CALLING SEQUENCE:
;	Result = EXTREMA( Data )
;
; INPUTS:
;	Data:  A vector of type integer or floating point.
;
; KEYWORD PARAMETERS:
;	FLAT:  If set, all locations along broad flat extrema are returned.
;		The default is for only the middle location to be returned.
;	ENDS:  If set, end points are always returned as extrema.  The default 
;		is to return the end points only if they lie outside the next 
;		minimum and maximum.
;
; OPTIONAL OUTPUTS:
;	MAXIMA:  Returns the locations of the maxima.
;	MINIMA:  Returns the locations of the minima.
;
; OUTPUTS:
;	Result:  Returns the locations of the extrema.
;
; PROCEDURE:
;	For each point, neighbouring values are compared to see if the given 
;	point is an extremum.
;
; EXAMPLE:
;	Define a vector.
;	  data = [1,2,3,2]
;	Find the local maxima.
;	  result = extrema( data )
;	The result should be [ 0, 2 ].
;
; MODIFICATION HISTORY:
; 	Written by:	Daithi A. Stone (stoned@atm.ox.ac.uk), 2003-10-09.
;-

;***********************************************************************

FUNCTION EXTREMA, $
	Data, $
	FLAT=flatopt, ENDS=endsopt, $
	MAXIMA=maxima, MINIMA=minima

;***********************************************************************
; Constants and Options

; Length of the time series
  nx = n_elements( data )

; We need to know if we need to use long integers for indices
if  size (nx,/type) eq 2 then begin
  idtype = 1
endif else begin
  idtype = 1l
endelse

; Pad data vector ends
x = [ data[0*idtype], data, data[nx-1] ]

; Set keyword options
flatopt = keyword_set( flatopt )
endsopt = keyword_set( endsopt )

; Initialise the vectors containing the locations of the maxima and minima.
; Note it is important to set the initial value to zero.
; The initial value will be removed later.
maxima = [ 0 ]
minima = [ 0 ]

;***********************************************************************
; Determine the Location of the Extrema

; Iterate through all non-end point values
for i = idtype, nx do begin

  ; Find left neighbouring value, or left edge of a flat section
  idleft = max( where( x[0*idtype:i-1] ne x[i] ) )
  ; Check for no left neighbour
  if idleft eq -1 then idleft = 0
  ; Find right neighbouring value, or right edge of a flat section
  idright = i + 1 + min( where( x[i+1:nx+1] ne x[i] ) )
  ; Check for no right neighbour
  if idright eq i then idright = nx + 1

  ; Determine if we actually want to take an extremum (FLAT option)
  check = 1
  if not( flatopt ) then begin
    if i ne ( idleft + idright ) / 2 then check = 0
  endif
  ; Check for extrema provided we want to do so
  if check then begin
    ; Check for minimum
    if ( x[i] le x[idleft] ) and ( x[i] le x[idright] ) then begin
      minima = [ minima, i - 1 ]
    endif else begin
      ; Check for non-minimum flat section
      if flatopt and ( x[i] eq x[i-1] ) and ( x[i] eq x[i+1] ) then begin
        minima = [ minima, i - 1 ]
      endif
    endelse
    ; Check for maximum
    if ( x[i] ge x[idleft] ) and ( x[i] ge x[idright] ) then begin
      maxima = [ maxima, i - 1 ]
    endif else begin
      ; Check for non-maximum flat section
      if flatopt and ( x[i] eq x[i-1] ) and ( x[i] eq x[i+1] ) then begin
        maxima = [ maxima, i - 1 ]
      endif
    endelse
  endif

endfor

; Count the number of maxima and minima (excluding initialising values)
nmaxima = n_elements( maxima ) - 1
nminima = n_elements( minima ) - 1

; Remove initialising values from maxima and minima vectors
maxima = maxima[1*idtype:nmaxima]
minima = minima[1*idtype:nminima]

; Check if we want to include "non-extreme" end points
if not( endsopt ) then begin
  ; Check for minimum at first point
  if ( minima[0*idtype] eq 0 ) and ( nminima gt 1 ) then begin
    ; Find neighbouring non-identical minimum
    id = min( where( data[minima] ne data[0*idtype] ) )
    ; Compare against that minimum
    if data[minima[0*idtype]] gt data[minima[id]] then begin
      ; Remove initial minimum
      id = min( where( data[minima] ne data[0*idtype] ) )
      minima = minima[id:nminima-1]
      nminima = n_elements( minima )
    endif
  endif
  ; Check for maximum at first point
  if ( maxima[0*idtype] eq 0 ) and ( nmaxima gt 1 ) then begin
    ; Find neighbouring non-identical maximum
    id = min( where( data[maxima] ne data[0*idtype] ) )
    ; Compare against that maximum
    if data[maxima[0*idtype]] lt data[maxima[id]] then begin
      ; Remove initial maximum
      id = min( where( data[maxima] ne data[0*idtype] ) )
      maxima = maxima[id:nmaxima-1]
      nmaxima = n_elements( maxima )
    endif
  endif
  ; Check for minimum at last point
  if ( minima[nminima-1] eq nx - 1 ) and ( nminima gt 1 ) then begin
    ; Find neighbouring non-identical minimum
    id = max( where( data[minima] ne data[nx-1] ) )
    ; Compare against that minimum
    if data[minima[nminima-1]] gt data[minima[id]] then begin
      ; Remove initial minimum
      id = max( where( data[minima] ne data[nx-1] ) )
      minima = minima[0*idtype:id]
      nminima = n_elements( minima )
    endif
  endif
  ; Check for maximum at last point
  if ( maxima[nmaxima-1] eq nx - 1 ) and ( nmaxima gt 1 ) then begin
    ; Find neighbouring non-identical maximum
    id = max( where( data[maxima] ne data[nx-1] ) )
    ; Compare against that maximum
    if data[maxima[nmaxima-1]] lt data[maxima[id]] then begin
      ; Remove initial maximum
      id = max( where( data[maxima] ne data[nx-1] ) )
      maxima = maxima[0*idtype:id]
      nmaxima = n_elements( maxima )
    endif
  endif
endif

; Define extrema output
extrema = [ minima, maxima ]
; Remove repeat values (can occur in flat areas)
check = 0
ctr = 0 * idtype
nextrema = n_elements( extrema )
while check eq 0 do begin
  id = where( extrema ne extrema[ctr], nid )
  if nid ne nextrema - 1 then begin
    extrema = extrema[[ctr,id]]
    nextrema = nid + 1
  endif
  ctr = ctr + 1
  if ctr ge nextrema - 1 then check = 1
endwhile
; Sort extrema locations
id = sort( extrema )
extrema = extrema[id]

;***********************************************************************
; The End

return, extrema
END
