;+
; PROCEDURE:
; 	 FAST_I_BATCH
;
; DESCRIPTION:
;
;	This is the fast idl batch processing file for ion and electron summary
;	plots. 
;	It is meant to be called from sdt.
;	Sdt would wait till this batch script is complete and then exit.
;	   
;	
; CALLING SEQUENCE:
;
; 	idl fast_i_batch
;
; REVISION HISTORY:
;
;	@(#)fast_batch.pro	1.3 24 Jul 1996
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   July '96
;-

@startup.pro

;get directory we will run in

dir = getenv ('IDLOUTDIR')
if strlen(dir) gt 0 then cd, dir

; iesa summary plots

fast_if_summary,/bw,/k0

; eesa summary plots

fast_ef_summary,/bw,/k0

; done

exit
