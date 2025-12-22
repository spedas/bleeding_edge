;+
;FUNCTION:	get_tms_ang
;
;INPUT:		NONE
;
;PURPOSE:	Select teams survey or himass angle bins.
;
;KEYWORDS:	None
;
;CALLING SEQUENCE:
;		  bins = fast_tms_ang()
;
;CREATED BY:	Li Tang 	11/5/96		Univ. of New Hampshire
;						Space Physics Lab
;						tang@teams.sr.unh.edu
;-

FUNCTION	get_tms_ang
@startup

	PRINT, ' '
	PRINT, ' '
	READ, i, PROMPT = 'Please enter 1 for TEAMS survey angle map; 2 for TEAMS himass angle map: '

	IF i EQ 1 THEN BEGIN
	   dat = get_fa_tsp(0, /st)
	   IF dat.valid NE 1 THEN dat = get_fa_tsh(0, /st)
	   IF dat.valid NE 1 THEN BEGIN
	      PRINT, 'No TEAMS survey data found.'
	      RETURN, REPLICATE(0, 64)
	   ENDIF
	   dat.data(*,0) = 100.		;make sure dat contains none 0 counts
	ENDIF ELSE IF i EQ 2 THEN BEGIN
	   dat = get_fa_th_3d(0, /st)
	   IF dat.valid NE 1 THEN BEGIN
	      PRINT, 'No TEAMS himass data found.'
	      RETURN, REPLICATE(0, 16)
	   ENDIF
	   dat.data(*,0) = 1000.	;make sure dat contains none 0 counts
	ENDIF ELSE BEGIN
	   PRINT, 'Sorry, no such angle map you setected. Quit.'
	   RETURN, 0
	ENDELSE

	PRINT, ' '
	PRINT,' Please select angles:'
        edit3dbins,dat,bins
   
  RETURN, bins

END
