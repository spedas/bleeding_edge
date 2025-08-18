;+
; NAME:
;    SEGMENT_TEST.PRO
;
; PURPOSE:
;    Check a spinmodel segment structure to ensure that the model parameters
;    b and c are consistent with the start and end times and
;    spin counts
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   segment_test,probe,segment,result
;
;  INPUTS:
;    probe: A single character probe letter (only used in output messages).
;    segment: A spinmodel_segment structure.
;
;  OUTPUTS:
;    result: 0 for failure, 1 for success
;
;  KEYWORDS:
;    None.
;
;  PROCEDURE:
;    Calls segment_interp_t to get spin count and spin phase at
;       segment start/end times.
;    Calls segment_interp_n to get sun pulse times of segment
;       start/end counts.
;    Cross check results of segment_interp_t and segment_interp_n,
;       verifying that interp_t and interp_n results are consistent
;       within modest tolerances (100 usec for times, 0.1 deg for
;       phase angles).
;    Check maxgap field against 4-hour threshold; large gaps are
;       likely a result of missing data.
;
;  EXAMPLE:
;    mptr=spinmodel_get_ptr('a')
;    sptr=(*mptr).segs_ptr
;    segment_test,'a',(*sptr)[0],result
;
;Written by: Jim Lewis (jwl@ssl.berkeley.edu)
;Change Date: 2007-10-08
;-

pro segment_test,probe,segment,result
  t1 = segment.t1
  t2 = segment.t2
  c1 = segment.c1
  c2 = segment.c2
  phi1 = c1*360.0D
  phi2 = c2*360.0D

  segment_interp_t,segment,t1,n1,tlast1,spinphase1,spinper1,eclipse_delta_phi1
  test_phi1 = n1*360.0D + spinphase1
  segment_interp_t,segment,t2,n2,tlast2,spinphase2,spinper2,eclipse_delta_phi2
  test_phi2 = n2*360.0D + spinphase2
  
  segment_interp_n,segment,c1,test_t1,spinper1
  segment_interp_n,segment,c2,test_t2,spinper2

  err1 = abs(phi1-test_phi1)
  err2 = abs(phi2-test_phi2)
  err3 = abs(t1-test_t1)
  err4 = abs(t2-test_t2)
  if ((err1 GT 0.1) OR (err2 GT 0.1) OR (err3 GT 0.0001) OR (err4 GT 0.0001)) then begin
     dprint,'FAIL: Model ',probe,' contains a bad segment:'
     segment_print,segment
     dprint,'n1=',n1,' spinphase1=',spinphase1,' n2=',n2,' spinphase2=',spinphase2
     dprint,'Expected phi1=',phi1,' phi2=',phi2
     dprint,'Got phi1=',test_phi1,' phi2=',test_phi2
     dprint,'Error values: phi1=',err1,' phi2=',err2,' t1=',err3,' t2=',err4
     result = 0
  endif else if (segment.maxgap GT 4.0D*60.0D*60.0D) then begin
     dprint,'FAIL: Model ',probe,' contains a gap longer than 4 hours.'
     segment_print,segment
     result = 0
  endif else result=1
end
