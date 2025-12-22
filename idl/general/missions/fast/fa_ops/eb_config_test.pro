;+
; PROCEDURE:
; 	 FAST_BATCH
;
; DESCRIPTION:
;
;	This is the fast idl batch processing file.  It is used to
;	produce plots for day to day production runs.  It is meant to
;	called from sdt.  It runs as the main procedure calling the
;	routines which produce plots for the various instruments.
;	Sdt would wait till this batch script is complete and then exit.
;	   
;	
; CALLING SEQUENCE:
;
; 	idl fast_batch
;
; REVISION HISTORY:
;
;	@(#)fast_batch.pro	1.6 11/11/96
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   July '96
;-

@startup.pro
;dir = getenv ('IDLOUTDIR')
;if strlen (dir) gt 0 then cd, dir

;Test to see if the IDL program runs

eb_config_test_pls

; done

exit
