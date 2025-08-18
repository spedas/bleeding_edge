;+
;PROCEDURE:	minjmin
;PURPOSE:	
;	Returns average value of j lowest-value points in the arrage. Works like min.
;INPUT:		
;	arr:			multi-dimensional array
;KEYWORDS:
;     dimension:		dimension over which to find the min values (like in IDL min function)
;				If present and nonzero, result is a slice, and output has 1dim less than arr
;				If not present or zero, the min is found over the entire array and returns as scalar
;     jmin_points:	number of lowest value elements to average over (default=1, typical=3)
;
;CREATED BY: Vassilis
;VERSION:	1
;LAST MODIFICATION:  10/08/29
;MOD HISTORY:
;
;NOTES:
; Helper routine created to work with get_th?_pxxx.pro to remove ESA background contamination
; Idea is to average over a number of lowest count rate points to determine bgnd
; with improved statistics.
;
; $LastChangedBy: aaflores1 $
; $LastChangedDate: 2014-01-24 15:20:50 -0800 (Fri, 24 Jan 2014) $
; $LastChangedRevision: 14010 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/packet/minjmin.pro $
;- 
function minjmin,arr,dimension=dimension,jmin_points=jmin_points
;
if (keyword_set(jmin_points) eq 0) then jmin_points=1
dat_tmp=arr
out_tmp=0.
for j=0,jmin_points-1 do begin
  foo=max(dat_tmp,dimension=dimension,min=tmp,subscript_min=jtmp)
  dat_tmp[jtmp]=foo
  out_tmp=out_tmp+tmp
endfor
out_tmp=out_tmp/jmin_points ; averaged over lowest nbgnd_points values
return,out_tmp
end