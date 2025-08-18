;+
;Routine to determine if sweep is one or two direction. Can also tell if sweep is bad.
;
;INPUTS:
;Vswp, Iswp: [128] length arrays containing the voltage and current data.
;
;
;RETURNS:
;structure containing:
;BiDir: 0: single; 1: double, 5: bad 
;BadSweep: 0: good; 1: bad
;Max, min of vswp and Iswp
;
;
;-
;


function mvn_lpw_prd_iv_sweep_info, vswp, iswp



;Dv; ignore outer 4 most points as these can act weird.
;Return:
;one of two direction
;bad sweep? (multiple changes in dv)
;max I, min I, max V, min V

miss = 5.
vtmp = vswp[0.+miss:127.-miss]  ;ignore end points

dv = vtmp[1:*]-vtmp[0:*]  ;derivative. Single sweep as max value < 0. Double sweep has max value > 0.
inds = where(dv gt 0., ninds) ;for a double sweep, half of the points are gt 0.

;A good sweep has vswp[0] >> vswp[63] (bi dir will turn around here, so vswp[0] = vswp[127]).
;A bad sweep tends to have vswp[0] < vswp[63].
if iswp[miss] gt iswp[63] then badsweep = 0. else badsweep = 1.

if badsweep eq 0. then begin
    if ninds ge (64. - miss - 5.) then bidir = 1. else bidir = 0.  ;bidir = 0: single; 1: double sweeps. Half of points should be in inds if double.
endif else bidir = 5
  
SwpInfo = {BiDir    :   bidir , $
           BadSweep :   badsweep , $
           MaxV     :   max(vswp), $
           MinV     :   min(vswp), $
           MaxI     :   max(Iswp), $
           MinI     :   min(Iswp)}
           
return, SwpInfo


end






           

