;+
; PROCEDURE:
; 	 FAST_BATCH
;
; DESCRIPTION:
;
;	This is the fast idl batch processing file for electron summary
;	plots.  It is meant to called from sdt.  
;	Sdt would wait till this batch script is complete and then exit.
;	   
;	
; CALLING SEQUENCE:
;
; 	idl fast_e_batch
;
; REVISION HISTORY:
;
;	@(#)fast_e_batch.pro	1.2 08/15/96
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Aug '96
;-

@startup

; get directory we will run in

dir = getenv ('IDLOUTDIR')
if strlen (dir) gt 0 then   cd, dir

; teams summary plots

fast_t_summary,/bw,/k0

; done

exit
