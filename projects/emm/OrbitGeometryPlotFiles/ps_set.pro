pro ps_set, mode, psfile, _EXTRA = e, HELPME = helpme
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ps_set.pro								;
;									;
; Routine sets (or unsets) the PS device for postscript plotting.	;
; Use "ps_set, -1" to close the PS device and open the X device		;
; Use "ps_set, 0"  to simply open the PS device				;
;									;
; Passed Variables							;
;	mode		-	Option number for output		;
;				default = 0				;
;	psfile		-	name of output postscript file		;
;				default = 'idl.ps'			;
;	_EXTRA		-	Keyword: extra device parameters	;
;  	HELPME		-	keyword: Prints a help screen		;
;									;
; Written by:		Dave Brain					;
; Last Modified: 	Oct 23, 1998	(Dave Brain)			;
;                       Jan 08, 2004                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; error catching
catch, error_status
IF error_status NE 0 THEN BEGIN
   print, '***Error within ps_set.pro***'
   print, '***Check parameters, source code***'
   print, '***Continuing***'
ENDIF

;Give help if requested.
IF keyword_set(helpme) THEN BEGIN
  print,'Routine sets (or unsets) the PS device for postscript plotting.'
  print,'  Use "ps_set, -1" to close the PS device and open the X device'
  print,'  Use "ps_set, 0"  to simply open the PS device'
  print,''
  print,'Syntax:'
  print,'ps_set, mode, psfile, _EXTRA = e, HELPME = helpme'
  print,''
  print,'  mode		-   Option number for output'
  print,'  		    default = 0	'
  print,'  psfile	-   name of output postscript file'
  print,'  		    default = ''idl.ps'' '
  print,'  _EXTRA	-   Keyword: extra device parameters'
  print,'  /HELPME	-   keyword: Prints a help screen instead of executing'
  return
ENDIF



IF n_params() EQ 0 THEN mode = 0		; set defaults
IF n_params() LT 2 THEN psfile = 'idl.ps'

psbool = 0 & ksbool = 0				; initialize booleans
IF !D.NAME EQ 'PS' THEN psbool = 1		; True if PS currently set
IF (psbool AND mode GE 0) and $
   (mode LE 12 OR $
    mode EQ 20 or mode EQ 21) THEN $	        ; If so, and trying to set to PS
   print, '***Device Warning***: ' + $		;  then warn user
          'PS already set .. continuing'	;  and continue
IF keyword_set(e) EQ 1 THEN ksbool = 1		; True if extra keywords passes

CASE mode OF
  -1: IF psbool THEN BEGIN			; Close PS, set to 'X'
         device, /close
	 set_plot, 'X'
	 print, 'Device: PS closed .. X set'
      ENDIF ELSE BEGIN
         print, '***Device Warning***: ' + $
	        'X already set .. continuing'
      ENDELSE
   0: BEGIN					; Set to PS, no frills
	 set_plot, 'ps'
	 IF ksbool THEN device, _EXTRA = e
         print, 'Device: PS set'
      END
   1: BEGIN
         set_plot, 'ps'
         device, 		$		; portrait, inches
            /inches, 		$
	    /portrait,		$
            xsize = 6.5, 	$
	    ysize = 8.0, 	$
	    xoffset = 1.0, 	$
	    yoffset = 1.5,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
   2: BEGIN
         set_plot, 'ps'
         device, 		$		; landscape, inches
            /inches, 		$
	    /landscape, 	$
            xsize = 8.0, 	$
	    ysize = 6.5, 	$
	    xoffset = 1.0, 	$
	    yoffset = 9.5,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
   3: BEGIN
         set_plot, 'ps'
         device, 		$		; landscape, cm
            /landscape, 	$		; times font
            xsize = 25., 	$
	    ysize = 18.,	$
	    xoffset = 1.5, 	$
	    yoffset = 27.5,	$
	    filename = psfile, 	$
	    /times,     	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
   4: BEGIN
         set_plot, 'ps'
         device, 		$		; landscape large, inches
            /inches, 		$		; times font
	    /landscape, 	$
            xsize = 10.5, 	$
	    ysize = 8.0, 	$
	    xoffset = 0.25, 	$
	    yoffset = 10.75,	$
	    filename = psfile, 	$
	    /times,     	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
   5: BEGIN
         set_plot, 'ps'
         device, 		$		; portrait large, inches
            /inches, 		$
	    /portrait,		$
            xsize = 8.0, 	$
	    ysize = 10.5, 	$
	    xoffset = 0.25, 	$
	    yoffset = 0.25,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
   6: BEGIN
         set_plot, 'ps'
         device, 		$		; portrait, cm
	    /portrait,		$
            xsize = 18.0, 	$
	    ysize = 24.0, 	$
	    xoffset = 1.75, 	$
	    yoffset = 2.0,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
   7: BEGIN
         set_plot, 'ps'
         device, 		$		; landscape large, cm
	    /landscape,		$
            xsize = 25.0, 	$		; ( 8.5" -> 21.59 cm)
	    ysize = 20.0, 	$		; (11.0" -> 27.94 cm)
	    xoffset =  0.80, 	$
	    yoffset = 26.50,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
   8: BEGIN
         set_plot, 'ps'
         device, 		$		; landscape large, inches
            /inches, 		$
	    /landscape, 	$
            xsize = 10.5, 	$
	    ysize = 8.0, 	$
	    xoffset = 0.25, 	$
	    yoffset = 10.75,	$
	    filename = psfile, 	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  10: BEGIN
         set_plot, 'ps'
         device, 		$		; portrait, cm, thesis
	    /portrait,		$
            xsize = 18.0, 	$
	    ysize = 25.0, 	$
	    xoffset = 1.47, 	$
	    yoffset = 1.795,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  11: BEGIN
         set_plot, 'ps'
         device, 		$		; landscape large, cm, thesis
	    /landscape,		$
            xsize = 25.0, 	$		; ( 8.5" -> 21.59 cm)
	    ysize = 18.0, 	$		; (11.0" -> 27.94 cm)
	    xoffset =  1.795, 	$
	    yoffset = 26.47,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  12: BEGIN                                     ; Square - movie capture
         set_plot, 'ps'
         device, 		$
            xsize = 15.0, 	$
	    ysize = 15.0, 	$
	    xoffset =  2.97, 	$
	    yoffset = 6.795,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  13: BEGIN                                     ; Square - large portrait
         set_plot, 'ps'
         device, 		$
	    /inches,	    	$
	    /portrait,		$
            xsize = 7.5, 	$
	    ysize = 7.5, 	$
	    xoffset = 0.5, 	$
	    yoffset = 1.75,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  20: BEGIN
         set_plot, 'ps'
         device, 		$		; portrait, inches
            /inches, 		$
	    /portrait,		$
            xsize = 5.5, 	$
	    ysize = 7.5, 	$
	    xoffset = 1.5, 	$
	    yoffset = 1.75,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  21: BEGIN
         set_plot, 'ps'
         device, 		$		; landscape, inches
            /inches, 		$
	    /landscape, 	$
            xsize = 7.5, 	$
	    ysize = 5.5, 	$
	    xoffset = 1.5, 	$
	    yoffset = 9.25,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  31: BEGIN
         set_plot, 'ps'
         device, 		$		; AGU 1-column
	    /portrait,		$
            xsize = 8.4, 	$
	    xoffset = 6.6, 	$
	    ;ysize = 23.7, 	$
	    ;yoffset = 1.75,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  32: BEGIN
         set_plot, 'ps'
         device, 		$		; AGU 2-column
	    /portrait,		$
            xsize = 16.9, 	$
	    xoffset = 2.3, 	$
	    ;ysize = 23.7, 	$
	    ;yoffset = 1.75,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  33: BEGIN
         set_plot, 'ps'
         device, 		$		; Nature 1-column
	    /portrait,		$
            xsize = 8.6, 	$
	    xoffset = 6.495, 	$
	    ;ysize = 23.7, 	$
	    ;yoffset = 1.75,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  34: BEGIN
         set_plot, 'ps'
         device, 		$		; Nature 2-column
	    /portrait,		$
            xsize = 17.8, 	$
	    xoffset = 1.895, 	$
	    ;ysize = 23.7, 	$
	    ;yoffset = 1.75,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  40: BEGIN
         set_plot, 'ps'
         device, 		$		; Nature 1-column
	    /inches,            $
            /portrait,		$
            xsize = 44, 	$
	    xoffset = 1.895, 	$
	    ysize = 8.5, 	$
	    yoffset = 1.75,	$
	    filename = psfile,	$
	    _EXTRA = e
	 print, 'Device: PS set'
      END
  50: BEGIN
         set_plot, 'ps'
         device, 		$		; MAVEN orbgeom browseplot
            /portrait,		$
            /encapsulated,      $
            /color,             $
            bits=8,             $
            xsize = 45, 	$
            ysize = 18,         $
	    filename = psfile,	$
            _EXTRA = e
         !p.font = 7
	 print, 'Device: PS set'
      END
ELSE: BEGIN					; If invalid mode, warn user
         set_plot, 'ps'				;  and set to PS...no frills
	 IF ksbool THEN device, _EXTRA = e
	 print, '***Device Warning***: ' + $
	        'Invalid mode .. PS set'
      END
ENDCASE

end
