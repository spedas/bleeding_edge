;+  interpolate flux or counts between two binning vectors
;
; INPUT: oldBins is a list of bin edges. It contains n>=2 unique
;            elements sorted in ascending order
;        newBins is a list of bin edges. It contains m>=2 unique
;            elements sorted in ascending order
;        oldVals is a list of n-1 values associated to
;            oldBins, the values to interpolate. That is,
;            oldVals[i] is associated with the bin having edges
;            (oldBins[i], oldBins[i+1]).
;        flux set means oldVals are counts/binWidth, not counts
;
; OUTPUT: returns a list of m-1 interpolated values associated to
;            newBins
;
; METHOD: traverse both bin lists once. For each old bin
;            there are 4 possibilities:
;               a) old bin precedes current new bin
;               b) new bin precedes the current old bin
;               c) old bin overlaps new bin, extends beyond
;               d) old bin overlaps new bin, does not extend beyond
; CALLS: none
;
; NOTES: 1. algorithm is simple linear interpolation.
;        2. The interpolated vector might contain less
;            information than the input vector. Exchanging oldBins
;            and newBins is not an inverse function for brl_rebin().
;        3. Difference between FLUX=0 and FLUX=1: suppose
;            the old and new binning schemes have the same
;            total range. Then FLUX=0 preserves the sum of
;            oldVals, and would be used when oldVals represents
;            counts in each bin, whereas FLUX=1 preserves the dot
;            product of oldVals and the (n-1 length) vector of
;            differences between successive oldBin entries---used
;            when oldVals has counts divided by bin width.
;
; WARNING: since this might be called repeatedly with only
;            oldVals changing, error-checking is minimal. The
;            calling routine is responsible for error-checking.
;
; REVISION HISTORY:
;        works, not much testing mm/Jul 2012
;	 22Oct2012: corrected normalization for flux eq 0
;        01Jan2013: calculates array lengths n&m automatically (DMS)
;-
function brl_rebin,oldVals,oldBins,newBins,FLUX=flux

  n=n_elements(oldBins)
  m=n_elements(newBins)
  if (n lt 2 or m lt 2) then $
    message,"length(s) violation: "+strtrim(n)+", "+strtrim(m)
  result=fltarr(m-1)
  oldLo=oldBins[0]
  oldHi=oldBins[1]
  newLo=newBins[0]
  newHi=newBins[1]
  newIndex=0
  oldIndex=0
  total=0.

  while (1) do begin
;    DEBUG****print,oldIndex,oldLo,oldHi,newIndex,newLo,newHi,total
    if (oldHi le newLo) then begin
      oldIndex += 1
      if (oldIndex ge n-1) then return,result
      oldLo=oldHi
      oldHi=oldBins[oldIndex+1]
      continue
    endif
    if (newHi le oldLo) then begin
      if keyword_set(flux) then $
        result[newIndex]=total/(newHi-newLo) $
      else $
        result[newIndex]=total/(oldHi-oldLo)
      total=0.
      newIndex += 1
      if (newIndex ge m-1) then return,result
      newLo=newHi
      newHi=newBins[newIndex+1]
      continue
    endif
    if (newHi lt oldHi) then begin
      total += (newHi-(oldLo>newLo))*oldVals[oldIndex]
      if keyword_set(flux) then $
        result[newIndex]=total/(newHi-newLo) $
      else $
        result[newIndex]=total/(oldHi-oldLo)
      total = 0.
      newIndex += 1
      if (newIndex ge m-1) then return,result
      newLo=newHi
      newHi=newBins[newIndex+1]
      continue
    endif else begin
      total += (oldHi-(oldLo>newLo))*oldVals[oldIndex]
      oldIndex += 1
      if (oldIndex ge n-1) then begin
        if keyword_set(flux) then $
          result[newIndex]=total/(newHi-newLo) $
        else $
          result[newIndex]=total/(oldHi-oldLo)
        return,result
      endif
      oldLo=oldHi
      oldHi=oldBins[oldIndex+1]
    endelse
  endwhile
end
