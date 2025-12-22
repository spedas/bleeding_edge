;+
; PROCEDURE:
; 	 FAST_FIELDS_BATCH
;
; DESCRIPTION:
;
;	This is the fast idl batch processing file, for fields summary
;	plots.  It is used to
;	produce plots for day to day production runs.  It is meant to
;	called from sdt.
;	Sdt would wait till this batch script is complete and then exit.
;	   
;	
; CALLING SEQUENCE:
;
; 	idl fast_fields_batch
;
; REVISION HISTORY:
;
;	@(#)fast_fields_batch.pro	1.3 24 Jul 1996
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Aug '96
;-

@startup

; get directory we will run in

dir = getenv ('IDLOUTDIR')
if strlen (dir) gt 0 then cd, dir

; fields summary plots

fast_fields_summary, /bw
  
; done

exit
