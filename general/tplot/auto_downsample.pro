;+
;NAME:
; auto_downsample
;PURPOSE:
; Downsamples spectral data to fit a given array and interpolates back
; to the original. For specplot.pro in cases where there is a time
; variation faster than the time resolution of device pixels. Not
; done if n_elements(x_out) > n_elements(x_in)/2, or if dx_out/dx_in
; is less than 2.0.
;CALLING SEQUENCE:
; spec_out = auto_downsample(spec_in, x_in, x_out)
;INPUT:
; spec_in = a spectrogram, ntimesXnchannels, or nxXny
; x_in = x coordinate for input
; x_out = x coordinate for output, the default is to use this for
;         scaling, an interpolate the result back to x_in, the x_out
;         coordinates are not overwritten
;KEYWORDS:
; downsample_interp2out = if set, then do not interpolate back to the
;                            input coordinates, but to the output coordinates
;HISTORY:
; 31-aug-2018, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-03-18 11:26:36 -0700 (Mon, 18 Mar 2019) $
; $LastChangedRevision: 26846 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/auto_downsample.pro $
;-
Function auto_downsample, spec_in, x_in, x_out, $
                          downsample_interp2out = downsample_interp2out

  nx_in = n_elements(x_in)
  nx_out = n_elements(x_out)
  If(nx_out Gt nx_in/2) Then Begin
     dprint, dlevel = 4, 'nx_out > nx_in/2, no downsample'
     Return, spec_in
  Endif

;an implicit assumption here is that both x_in and x_out are uniform grids
  dx_out = x_out[1]-x_out[0]
  dx_in = x_in[1]-x_in[0]

  scale = dx_out/dx_in
  If(scale Lt 2.0) Then Begin
     dprint, dlevel = 4, 'dx_in/dx_out > 1/2, no downsample'
     Return, spec_in
  Endif

  nx_new = ceil(nx_in/scale)
;use histogram with reverse indices
  xxx = histogram(x_in, min = x_in[0], max = x_in[nx_in-1], nbins = nx_new, $
                  locations=yyy, reverse_i = rii)
  ny = n_elements(spec_in[0, *])
  spec_new = replicate(spec_in[0], nx_new, ny)
;Average in each bin
  For j = 0, nx_new-1 Do Begin
     If(rii[j] Ne rii[j+1]) Then Begin
        ss = rii[rii[j]:rii[j+1]-1]
        If(ny Eq 1) Then spec_new[j] = total(spec_in[ss]) $
        Else spec_new[j, *] = mean(spec_in[ss, *], dim=1, /nan)
     Endif
  Endfor
;Need bin mipoints, fixed last point, 2019-03-18, jmm
  yyy = [yyy, 2.0*yyy[nx_new-1]-yyy[nx_new-2]]
  x_new = 0.5*(yyy[1:*]+yyy)

;New spectrum is sort of the same as a spectrum on x_out, but not
;quite, interploate back using interp.pro
  If(keyword_set(downsample_interp2out)) Then Begin
     spec_out = interp(spec_new, x_new, x_out, $
                       /no_check_monotonic, /ignore_nan, /no_extrap)
  Endif Else Begin
     spec_out = interp(spec_new, x_new, x_in, $
                       /no_check_monotonic, /ignore_nan, /no_extrap)
  Endelse

  Return, spec_out
End
