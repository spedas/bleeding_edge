;+
;NAME: SIMPLE_GAPS
;
;DESCRIPTION:
; Find indices into an array such that when filtered on these
; indices the resulting array has no more than one NaN value
; in a row.  The resulting array will not have a NaN in
; the first or last element of the array, only as an in-between element.
; 
; Used in psp_dyplot to support properly iterating over data gaps when
; plotting confidence intervals in piecewise fashion.
; 
; Expects data to be a 1D array.
;     
;INPUT:
; DATA:   1D array to reference for non finite values
;
;OUTPUTS:
; KEEP:   Integer array of indices to use to filter the data array.
;
;EXAMPLE:
;   d = [6,4, !values.f_NaN, !values.f_NaN, 3, 1]
;   simple_gaps, d, keep_index = keep
;   d[keep]
;     --> [6,4, NaN, 3, 1]
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2020-10-27 12:50:05 -0700 (Tue, 27 Oct 2020) $
; $LastChangedRevision: 29302 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/L3i/misc/simple_gaps.pro $
;-

function simple_gaps, data
  compile_opt idl2

  keep = where(finite(data),/NULL,COMPLEMENT=nans)
  
  diff = nans - shift(nans,1)
  keep = [keep, nans[0], nans[where(diff gt 1, /NULL)]]
  keep = keep[sort(keep)]
  
  if keep[0] eq 0 then keep = keep[1:*]
  if ~finite(data[keep[-1]]) then keep = keep[0:-2]
  return, keep
end
