;+
;PROCEDURE:  edit3dbins_reform,dat,bins
;PURPOSE:   wrapper for edit3dbins, Interactive procedure to produce a
;bin array for selectively turning angle bins on and off.  Works on a
;3d structure with phi, theta dimensioned separately, so that the data
;array in the structure is (nenergy, nphi, ntheta), rather than
;(nenergy, nbins) as in the typical 3d data structure.
;INPUT:
;   dat:  3d data structure.  (will not be altered, bin flags are not set)
;   bins:  a named variable in which to return the results, dimensions
;          (nphi, ntheta), not (nbins)
;KEYWORDS:
;   NTHETA: number of theta bins, if not set, obtain from
;           the data structure
;   NPHI: number of phi bins, if not set, obtain from
;           the data structure
;   Note that if ntheta*nphi is not equal to data.nbins, then
;   edit3dbins is called directly. This may resuly in unpredictable results.
;   EBINS:     Specifies energy bins to plot.
;   SUM_EBINS: Specifies how many bins to sum, starting with EBINS.  If
;              SUM_EBINS is a scalar, that number of bins is summed for
;              each bin in EBINS.  If SUM_EBINS is an array, then each
;              array element will hold the number of bins to sum starting
;              at each bin in EBINS.  In the array case, EBINS and SUM_EBINS
;              must have the same number of elements.
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
pro edit3dbins_reform, dat, bins, lat, lon, $
                       ntheta = ntheta, $
                       nphi = nphi, $
                       spectra= spectralim, $
                       EBINS=ebins,         $
                       SUM_EBINS=sum_ebins, $
                       tbins=tbins, $
                       classic=classic,$
                       log=log

; We expect dat to be a structure (type=8). If no times are selected, dat
; could be 0 (not a structure), so we need to check its type first.
  print, 'AAA'

  if (size(dat,/type) NE 8) then begin
     dprint, 'Invalid data'
     return
  endif

; Now that we're sure it's a structure, check whether it's flagged as valid.
  if(dat.valid eq 0) then begin
     dprint, 'Invalid data'
     return
  endif

;Now only do anything if dat.data is 3-d, otherwise just pass through
;to edit3dbins
  szd = size(dat.data)
  If(szd[0] Eq 3) Then Begin
     nenergy = szd[1]
     nphi0 = szd[2]
     ntheta0 = szd[3]
     If(keyword_set(nphi)) Then nph = nphi $
     Else nph = nphi0
     If(keyword_set(ntheta)) Then nth = ntheta $
     Else nth = ntheta0
     If(nth*nph Eq dat.nbins) Then Begin
;reform the structure
        dat1 = reform_3d_struct(dat)
;call edit3dbins
        edit3dbins, dat1, bins1, lat, lon, $
        spectra= spectralim, $
        EBINS=ebins,         $
        SUM_EBINS=sum_ebins, $
        tbins=tbins, $
        classic=classic,$
        log=log
;reform output
        bins = reform(bins1, nph, nth)
        undefine, dat1 ;to free up memory, since this may be called many times
     Endif Else Begin
        dprint, 'ntheta*nphi NE nbins, Calling edit3dbins, Good luck...'
        goto, use_edit3dbins
     Endelse
  Endif Else Begin
     use_edit3dbins:
     edit3dbins, dat, bins, lat, lon, $
     spectra= spectralim, $
     EBINS=ebins,         $
     SUM_EBINS=sum_ebins, $
     tbins=tbins, $
     classic=classic,$
     log=log
  Endelse
  Return
End
