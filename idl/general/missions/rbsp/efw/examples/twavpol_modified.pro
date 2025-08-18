;+
;
; NAME:twavpol
;
;PURPOSE:To perform polarisation analysis of three orthogonal component time
;         series data, using tplot variables.
;
;EXAMPLE: twavpol,'in_data',prefix='in_data',freqline=fl
;
;INPUTS: tvarname: the name of the tplot variable upon which it will
;operate
;
;prefix(optional): the prefix to be assigned to the tplot variables that will be
;output, defaults to tvarname
;
;
;       Subroutine assumes data are in righthanded fieldaligned
;	coordinate system with Z pointing the direction
;       of the ambient magnetic field.
;
;Keywords:
;  nopfft(optional) = Number of points in FFT
;
;  steplength(optional) = The amount of overlap between successive FFT intervals
;
;  bin_freq (optional): No. of bins in frequency domain
;
;OUTPUTS:
;          error(optional): named variable in which to return the
;          error state of this procedure call. 1 = success, 0 = failure
;
;          freqline(optional): assign a named variable to this keyword
;          to store the frequencies of each y-index
;
;         timeline(optional): assign a named variable to this keyword
;         to store the times of each x-index
;
;The program outputs five spectral results derived from the
;         fourier transform of the covariance matrix (spectral matrix)
;This version stores these outputs as tplot variables with the
;specified prefix
;         These are follows:
;
;         Wave power: On a linear scale, at this stage no units
;
;         Degree of Polarisation:
;		This is similar to a measure of coherency between the input
;		signals, however unlike coherency it is invariant under
;		coordinate transformation and can detect pure state waves
;		which may exist in one channel only.100% indicates a pure
;		state wave. Less than 70% indicates noise. For more
;		information see J. C. Samson and J. V. Olson 'Some comments
;		on the description of the polarization states
;		of waves' Geophys. J. R. Astr. Soc. (1980) v61 115-130
;
;   Wavenormal Angle:
;     The angle between the direction of minimum variance
;     calculated from the complex off diagonal elements of the
;     spectral matrix and the Z direction of the input ac field data.
;     for magnetic field data in field aligned coordinates this is the
;     wavenormal angle assuming a plane wave. See:
;     Means, J. D. (1972), Use of the three-dimensional covariance
;     matrix in analyzing the polarization properties of plane waves,
;     J. Geophys. Res., 77(28), 5551-5559,
;     doi:10.1029/JA077i028p05551.
;
;   Ellipticity:
;     The ratio (minor axis)/(major axis) of the ellipse transcribed
;     by the field variations of the components transverse to the
;     Z direction (Samson and Olson, 1980). The sign indicates
;     the direction of rotation of the field vector in the plane (cf.
;     Means, (1972)).
;     Negative signs refer to left-handed rotation about the Z
;     direction. In the field aligned coordinate system these signs
;     refer to plasma waves of left and right handed polarization.
;
;         Helicity:Similar to Ellipticity except defined in terms of the
;	direction of minimum variance instead of Z. Stricltly the Helicity
;	is defined in terms of the wavenormal direction or k.
;	However since from single point observations the
;	sense of k cannot be determined,  helicity here is
;	simply the ratio of the minor to major axis transverse to the
;       minimum variance direction without sign.
;
;NOTES:
;1. Although the input is in the form of a tplot variable, the
;output is currently in the form of arrays
;
;2. -If one component is an order of magnitude or more  greater than
;	the other two then the polarisation results saturate and erroneously
;	indicate high degrees of polarisation at all times and
;	frequencies.
;
;3. Time series should be eyeballed before running the program.
;	 For time series containing very rapid changes or spikes
;	 the usual problems with Fourier analysis arise.
;	 Care should be taken in evaluating degree of polarisation results.
;
;4. For meaningful results there should be significant wave power at the
;	 frequency where the polarisation approaches
;	 100%. Remembercomparing two straight lines yields 100% polarisation.
;
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2020-05-21 20:36:46 -0700 (Thu, 21 May 2020) $
; $LastChangedRevision: 28720 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/twavpol_modified.pro $
;-
pro twavpol_modified,tvarname,prefix = prefix, error=error, freqline = freqline, timeline = timeline,$
nopfft=nopfft,steplength=steplength, bin_freq=bin_freq

  error=0

  if not keyword_set(bin_freq) then dprint,'By default bin_freq = 3. (frequency averaging)'
  if not keyword_set(bin_freq) then bin_freq = 3 else bin_freq = bin_freq

  if not keyword_set(tvarname) then begin
    dprint, 'tvarname must be set'
    return
  endif

  if not keyword_set(prefix) then prefix = tvarname

  var_names = tnames(tvarname)

  if(var_names[0] eq '') then begin
    dprint, 'No valid tplot_variables match tvarname'
    return
  endif

  get_data,tvarname,data=d

  dimx = size(/dim,d.x)
  dimy = size(/dim,d.y)

  if dimx[0] ne dimy[0] then begin
     dprint,'Number of time elements does not match number of magnetic field elements in tvarname'
     return
  endif

  if n_elements(dimy) ne 2 then begin
     dprint,'Data component of tvarname must be a 2 dimensional array'
     return
  endif

  if dimy[1] ne 3 then begin
     dprint,'Dimension 2 of data component of tvarname must have 3 elements'
     return
  endif

;****
;;backup
;;d2 = d
;;nopfft = 1024
;;steplength = nopfft/2

;boo = where(d.y eq 0.)
;if boo[0] ne -1 then d.y[boo] = !values.f_nan

;;stop

;t = d.x[0:20000] - d.x[0]
;d1 = 100.*d.y[0:20000,0]
;d2 = 100.*d.y[0:20000,1]
;d3 = 100.*d.y[0:20000,2]

;  wavpol, t, d1,d2,d3, timeline, freqline,$
;   powspec, degpol, waveangle, elliptict, helict, pspec3, nopfft=nopfft,steplength=steplength,bin_freq=0;bin_freq

;print,total(powspec,/nan)
;print,total(elliptict,/nan)

;nopfft_adj = nopfft

;***tmp
;nopoints = 2000.
;nopfft = 1024.
;steplength = nopfft

nopoints = n_elements(d.x)
nosteps=(nopoints-nopfft)/steplength


;;-adjust the FFT size so that there are at least 10 time bins
;while nosteps lt 10 do begin
;  nopfft /= 2.
;  steplength /= 2.
;  nosteps=(nopoints-nopfft)/steplength
;endwhile

;Warning - don't set bin_freq to 1 b/c degpol will always be = 1.


wavpol, d.x, d.y[*, 0], d.y[*, 1], d.y[*, 2], timeline, freqline,$
 powspec, degpol, waveangle, elliptict, helict, pspec3, nopfft=nopfft,steplength=steplength,bin_freq=bin_freq

  if KEYWORD_SET(powspec) then store_data, prefix+'_powspec', data = {x:timeline, y:powspec, v:freqline}, dlimits = {spec:1B}

  if KEYWORD_SET(degpol) then store_data, prefix+'_degpol', data = {x:timeline, y:degpol, v:freqline}, dlimits = {spec:1B}

  if KEYWORD_SET(waveangle) then store_data, prefix+'_waveangle', data = {x:timeline, y:waveangle, v:freqline}, dlimits = {spec:1B}

  if KEYWORD_SET(elliptict) then store_data, prefix+'_elliptict', data = {x:timeline, y:elliptict, v:freqline}, dlimits = {spec:1B}

  if KEYWORD_SET(helict) then store_data, prefix+'_helict', data = {x:timeline, y:helict, v:freqline}, dlimits = {spec:1B}

  if KEYWORD_SET(pspec3) then store_data, prefix+'_pspec3', data = {x:timeline, y:pspec3, v:freqline}, dlimits = {spec:1B}

  error=1

;stop
end
