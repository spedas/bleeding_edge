;+
;Procedure:
;  spd_pgs_clip_spec
;
;Purpose:
;  Place NaNs in areas of a spectrogram that are beyond
;  the requested limits.
;
;Input:
;  y: spectrogram y axis
;  z: spectrogram data
;  range: The initial range limit applied to the data along an axis
;         where that axis now serves as the spectrogram's y axis.
;         (e.g. phi=[0,180] for a phi spectrogram)
;
;Output:
;  NaNs applied to out of range data in Z
;
;Notes:
;  
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-01-04 15:09:48 -0800 (Mon, 04 Jan 2016) $
;$LastChangedRevision: 19671 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_clip_spec.pro $
;-
pro spd_pgs_clip_spec, y=y, z=z, range=range

    compile_opt idl2, hidden

  if ~keyword_set(y) || ~keyword_set(z) || ~keyword_set(range) then begin
    return
  endif

  ;find where y axis is outside the specified range
  if range[0] gt range[1] then begin
    ;use different logic when min > max (phi only, for now)
    idx = where(y lt range[0] and y gt range[1],n)
  endif else begin
    idx = where(y lt range[0] or y gt range[1],n)
  endelse
  
  if n gt 0 then begin
    if dimen2(y) gt 1 then begin
      z[idx] = !values.f_nan
    endif else begin
      z[idx,*] = !values.f_nan
    endelse
  endif
  
end