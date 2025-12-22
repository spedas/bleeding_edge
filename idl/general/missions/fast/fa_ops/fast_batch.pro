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
dir = getenv ('IDLOUTDIR')
if strlen (dir) gt 0 then cd, dir

; eesa summary plots

fast_ef_summary,/bw,/k0

; iesa summary plots

fast_if_summary,/bw,/k0

; teams summary plots

fast_t_summary,/bw,/k0

; fields summary plots

fast_fields_summary,/bw

; done

exit
