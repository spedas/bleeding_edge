function mvn_orbql_plotposn, $
		CENTER = center, RELCENTER = relcenter, $
		INDENT = indent, RELINDENT = relindent, $
		SIZE = size,     RELSIZE = relsize, $
                RESET = reset, $
		WINSIZE = winsize, $
		REGION = region
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;mvn_orbql_plotposn.pro							;
;									;
; Function sets system variable !p.position based on user input about 	;
;  the length of the axes and location of the center of the plot 	;
;  window.  The result is a 6-element array containing the size of the	;
;  plot window in cm, and !p.position (a 4-element vector).	  	;
;									;
; Notes: 								;
;	Set the device BEFORE this procedure or it will calculate for 	;
;	 the default.							;
;	Function centers coordinate axes unless otherwise specified	;
;									;
; Passed Variables							;
; 	CENTER	        -	keyword: 2-element array with x and y	;
;				   location of the center of the 	;
;				   region enclosed by the coordinate 	;
;				   axes, in cm				;
;	INDENT		-	keyword: 2-element array with x and y	;
;				   distance from bottom left corner of	;
;				   axes to edge of plot window, in cm	;
;	SIZE		-	keyword: 2-element array with width and	;
;				   height of axes, in cm		;
;	RELSIZE		-	keyword: 2-element array with width and	;
;				   height of axes, expressed as 	;
;				   fraction of plot window		;
;	RELINDENT	-	keyword: 2-element array with x and y	;
;				   distance from bottom left corner of	;
;				   axes to edge of plot window,  	;
;				   expressed as fraction of plot window ;
; 	RELCENTER	-	keyword: 2-element array with x and y	;
;				   location of the center of the 	;
;				   region enclosed by the coordinate 	;
;				   axes, expressed as fraction of       ;
;                                  plot window			        ;
;	WINSIZE		-	keyword: Set to return size of plot	;
;				   window, in cm, without setting	;
;				   !p.position				;
;									;
; Called Routines:							;
;									;
; Written by:		Jack Connerney					;
; Last Modified: 	Jan 06, 2004    (Dave Brain)                    ;
;                        changed name from plotwin.pro to plotposn.pro  ;
;                        changed keywords to more intuitive names       ;
;                        added RESET keyword                            ;
;                       Feb 1, 1999	(Dave Brain)			;
;			   changed to a function			;
;			   added options:				;
;				1. Center axes in window		;
;				2. Indent axes from bottom left		;
;				3. Specify window size in cm		;
;				4. Specify window size as fraction of	;
;					plot window			;
;				5. Ask for size of plot window, in cm	;
;			Oct 14, 1998	(Dave Brain...comments)		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; !p.position=0                 ; i don't know why i put this here, so commented it out

; x_pix and y_pix are pixels per cm for x and y respectively
x_pix = !d.x_px_cm
y_pix = !d.y_px_cm


; x_size and y_size are number of pixels across drawable surface of medium
x_size = !d.x_vsize
y_size = !d.y_vsize

; calculate size of window
windowsize = [ x_size/float(x_pix), y_size/float(y_pix) ]


; if /winsize set, then return
IF keyword_set(winsize) THEN $
   IF keyword_set(region) THEN $
      RETURN, [windowsize, !p.region] $
   ELSE $
      RETURN, [windowsize, !p.position]

; Reset appropriate array before overwriting
!p.region = [0,0,0,0]
!p.position = [0,0,0,0]

; if /reset set, then return
IF keyword_set(reset) THEN BEGIN
   ans = mvn_orbql_plotposn(/winsize)
   RETURN, ans
ENDIF

; Set size of axes
IF n_elements(size) NE 0 THEN BEGIN
   width = size[0] * x_pix
   height = size[1] * y_pix
ENDIF ELSE $
IF n_elements(relsize) NE 0 THEN BEGIN
   width = x_size * relsize[0]
   height = y_size * relsize[1]
ENDIF

; find center of axes within plot window
xcen = x_size/2.
ycen = y_size/2.
IF n_elements(center) NE 0 THEN BEGIN
   xcen = center[0] * x_pix
   ycen = center[1] * y_pix
ENDIF
IF n_elements(relcenter) NE 0 THEN BEGIN
   xcen = x_size * relcenter[0]
   ycen = y_size * relcenter[1]
ENDIF
IF n_elements(indent) NE 0 THEN BEGIN
   xcen = indent[0] * x_pix + width/2.
   ycen = indent[1] * y_pix + height/2.
ENDIF
IF n_elements(relindent) NE 0 THEN BEGIN
   xcen = relindent[0] * x_size + width/2.
   ycen = relindent[1] * y_size + height/2.
ENDIF


; vector	= [x0,y0,x1,y1] normalized vector for !p.position
vector = fltarr(4)
vector[0] = (xcen - width/2.) / float(x_size)
vector[2] = (xcen + width/2.) / float(x_size)
vector[1] = (ycen - height/2.) / float(y_size)
vector[3] = (ycen + height/2.) / float(y_size)

; set !p.position
   IF keyword_set(region) THEN !p.region = vector ELSE !p.position = vector

; return info
   IF keyword_set(region) THEN $
      RETURN, [windowsize, !p.region] $
   ELSE $
      RETURN, [windowsize, !p.position]


end
