pro mvn_orbql_overlay_map, z, sz1, sz2, true=true
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; overlay_map.pro								;
;									;
; Routine displays a 2-D image in a pre-existing plot window, assuming	;
;  that the coordinate axes of the window are already established and	;
;  correspond to the coordinate axes of the image			;
; 									;
; Notes:								;
;	Can handle display to 'X' and 'PS' devices (algorithm is 	;
;		different, per IDL 5.1 manual entry on overlaying 	;
;		image and contour plots)				;
;	Assumes that bounds of plot window match bounds of image (i.e.	;
;		x and y match the plot window exactly)			;
;									;
; Passed Variables							;
;	z	-	2-D image to be displayed			;
;       sz1     -       (vestigial) used to be xdim                     ;
;       sz2     -       (vestigial) used to be ydim                     ;
;									;
; Written by:		Dave Brain (blatantly borrowed from M.Kaiser)	;
; Last Modified: 	Oct 19, 1998	(Dave Brain)			;
;                       Jan 06, 2004 - automatically determine size     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Calculate dimensions of image
sz = size(z)
dim = sz[0]
IF dim NE 2 THEN BEGIN
   print, 'Image not 2-D ... returning from overlay.pro'
   RETURN
ENDIF
xdim = sz[1]
ydim = sz[2]

IF !D.NAME EQ 'Z' or !D.NAME eq 'X' THEN BEGIN			; If the device doesn't have
						;  scalable pixels, then scale
						;  scale the image to fit the
						;  display

   xpix = !x.window * !d.x_vsize 		; Calculate size of plot
   ypix = !y.window * !d.y_vsize 		;  window, in device pixels
   sx = xpix[1] - xpix[0] + 1
   sy = ypix[1] - ypix[0] + 1
   
   tv, poly_2d( z, 			$	; Display linearly stretched 
                [[0,0], [xdim/sx,0]], 	$	;  image, stretched in x by
                [[0,ydim/sy], [0,0]], 	$	;  sx/xdim, and by sy/ydim in 
		0, 			$	;  y.  Use nearest neighbor
		sx, 			$	;  interpolation, and force
		sy		    ), 	$	;  output to sx columns,
       xpix[0], ypix[0]				;  and sy rows.  The lower left
						;  coordinate of the displayed
						;  image should coincide with
						;  the lower left coordinate of
						;  the plot window.
ENDIF

IF !D.NAME EQ 'PS' THEN BEGIN			; If the device has scalable
						;  pixels then do nothing
						;  to the image before 
						;  overlaying

   xstart = !x.window[0] 			; Normalized coordinates of
   ystart = !y.window[0] 			;  lower left corner
   
   xsize  = !x.window[1] - xstart		; Size of plot window, in 
   ysize  = !y.window[1] - ystart		;  normalized coordinates
   
   tv, z, 				$	; Display image, starting in 
       xstart, ystart, 			$	;  the lower left corner, and
       xsize=xsize, ysize=ysize,	$	;  stretching the width and
      /norm					;  height of the displayed 
      						;  image.  Use normalized
						;  coordinates.

ENDIF

end
