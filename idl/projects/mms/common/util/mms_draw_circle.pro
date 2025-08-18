;+
; PROCEDURE:
;         mms_draw_circle
;
; PURPOSE:
;         Draws (and fills in) a circle
; 
; NOTES:
;         Taken from mms_fpi_dist_slice_comparison_crib, 8/26/16
;         
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-08-26 09:12:48 -0700 (Fri, 26 Aug 2016) $
; $LastChangedRevision: 21731 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/mms_draw_circle.pro $
;-

pro mms_draw_circle,x0,y0,r=r,fill=fill,_extra=extra
  if n_elements(r) eq 0. then r = 1.
  if n_elements(x0) eq 0. then x0 = 0.
  if n_elements(y0) eq 0. then y0 = 0.
  n = 101
  a = indgen(n)/float(n-1)*2*!pi
  oplot, x0 + r*cos(a), y0 + r*sin(a),_extra=extra
  if keyword_set(fill)then polyfill,  x0 + r*cos(a), y0 + r*sin(a),_extra=extra
end