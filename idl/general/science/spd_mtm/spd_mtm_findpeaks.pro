;+
; :Description:
;   Find significant enhancements in the gamma and F test.
; 
; :Params:
;   INPUTS:
;        spec.ff - Fourier frequencies
;       spec.raw - adaptive multitaper PSD
;      spec.back - best PSD background among the probed ones
;      spec.conf - confidence threshold values for the PSD (gamma test)
;     spec.ftest - values of the F test
;     spec.fconf - confidence threshold values for the F statistic (F test)
;       par.conf - confidence thresholds percentages
;      par.nfreq - number of frequencies
;         par.df - frequency resolution (after padding), it corresponds to
;                  the Rayleigh frequency for no padding (padding = 1)
;         par.NW - time-halfbandwidth product
;       par.fray - Rayleigh frequency: fray = 1/(npts*dt)
;  ipar.peakproc - array[4] referring to 'gt', 'ft', 'gft', and 'gftm'
;                  1 (0) peaks according to this procedure are (not) saved
;   ipar.allpkwd - keyword /allpeakwidth is selected (1) or not (0)
;     
;   OUTPUTS:
;       peak.          
;           .ff    Fourier frequencies
;           .pkdf  for each peak selection method and confidence level 
;                  a value greater than zero at a specific frequency
;                  indicate the occurence of a signal at that frequency:
;                  peak.pkdf[#peakproc, #conf, #freq]
;                  'gamma test' -> peak.pkdf[0,*,*] contains the badwidth
;                  of the PSD enhancements at the identified frequencies
;                  'F test', 'gft', and 'gftm' -> peak.pkdf[1:3,*,*]
;                  is equal to par.df at the identified frequencies
;                         
; :Author:
;     Simone Di Matteo, Ph.D.
;     8800 Greenbelt Rd
;     Greenbelt, MD 20771 USA
;     E-mail: simone.dimatteo@nasa.gov  
;-
;*****************************************************************************;
;                                                                             ;
;   Copyright (c) 2020, by Simone Di Matteo                                   ;
;                                                                             ;
;   Licensed under the Apache License, Version 2.0 (the "License");           ;
;   you may not use this file except in compliance with the License.          ;
;   See the NOTICE file distributed with this work for additional             ;
;   information regarding copyright ownership.                                ;
;   You may obtain a copy of the License at                                   ;
;                                                                             ;
;       http://www.apache.org/licenses/LICENSE-2.0                            ;
;                                                                             ;
;   Unless required by applicable law or agreed to in writing, software       ;
;   distributed under the License is distributed on an "AS IS" BASIS,         ;
;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  ;
;   See the License for the specific language governing permissions and       ;
;   limitations under the License.                                            ;
;                                                                             ;
;*****************************************************************************;
;
pro spd_mtm_findpeaks, spec=spec, par=par, ipar=ipar, peak=peak

; allocate output array
npeakproc = n_elements(ipar.peakproc)
nconf = n_elements(par.conf)
pkdf = make_array(npeakproc, nconf, par.nfreq, /double, value=0)
;
; define the output structure
peak={ff:spec.ff, pkdf:pkdf}

if (total(ipar.peakproc) gt 0) then begin
  
  ; ratio of raw and background spectra (gamma values)
  gamma0 =  spec.raw/spec.back

  ;
  ; probe each procedure
  ;
  ; GAMMA TEST
  if (ipar.peakproc[0] eq 1) OR $
     (ipar.peakproc[2] eq 1) OR $
     (ipar.peakproc[3] eq 1) then begin
    ;
    ; initialize a vector for peaks identification
    ind_gt = make_array(nconf, par.nfreq, 1, /integer, value=0)
    ;
    ; interpolation of the frequency vector
    int_step = 2.0d ; interpolation step
    leng_f = par.nfreq*int_step - int_step + 1.0d
    ffi=dindgen(leng_f)*(par.df/int_step)
    ;
    ; define the bandwidth of the spectral window
    halfbndwdth = par.NW * par.fray
    hbnd = halfbndwdth/par.df
    ; df depends on padding, if padding=1 then df=fray and hbnd=NW
    ; spectral window main lobe bandwidth: 2B=2*NW*fray
    bnd = fix(int_step*hbnd)
    ;
    ; probe for each confidence level
    for k = 0,(nconf-1) do begin
      ;
      gind = double(gamma0 gt spec.conf[k]) ; gamma indices
      ;
      ; to avoid indetermination between peaks with odd and even points
      ; we interpolate the data to have all of them with odd points
      gindi = interpol(gind,spec.ff,ffi) ; gamma indices interpolated
      gindi(where(gindi lt 1 and gindi gt 0)) = 0.0d
      gindi = [gindi, 0]
      ;
      ;
      if ipar.allpkwd eq 1 then begin
        ; accept all peak width, even at boundaries
        pks_ind = where(-ts_diff(gindi,1) eq -1)
        cum_gindi = total([gindi, 0], /cumulative)
        pks_bnd = -ts_diff( [0, cum_gindi[pks_ind] ] , 1)
        greaterB = where(pks_bnd gt 0, /null)
      endif else begin
        ; sift according to peak width, only greater than B
        pks_ind = where(-ts_diff(gindi,1) eq -1)
        cum_gindi = total([gindi, 0], /cumulative)
        pks_bnd = -ts_diff( [0, cum_gindi[pks_ind] ] , 1)
        greaterB = where(pks_bnd ge bnd, /null)
      endelse
      ;
      if greaterB ne !null then begin
        pks_ind = pks_ind[greaterB]
        pks_bnd = pks_bnd[greaterB]
        ;
        ; find center of the enhancements
        wdth_gind = fix(pks_bnd/2.0d)
        maxs_gind = pks_ind - wdth_gind
        ;
        ; select the center of each interval
        for h=0,n_elements(maxs_gind)-1 do begin
          ;
          ; peak position
          pkp = maxs_gind[h]
          ;
          ; identify frequency associated to each peak
          if (2*fix(pkp/2.0d) eq pkp) then begin
            ;
            ; if even, it is centered on the original frequency vector
            pkp0 = pkp/int_step
          endif else begin
            ;
            ; if odd choose the frequency center with the maximum psd value
            pkp1 = (pkp-1.0d)/int_step
            pkp2 = (pkp+1.0d)/int_step
            if (gamma0[pkp1] gt gamma0[pkp2]) then pkp0=pkp1 else pkp0=pkp2
          endelse
          ;
          ; determine error defined as the width of the enhancement
          ninterval = pks_bnd[h]
          ;
          ; define on the original frequency vector
          hinterval = fix(ninterval/2.0d) ; half interval in the interpolated frequency vector
          pkp_beg = (pkp-hinterval)/int_step
          if pkp_beg lt 0 then pkp_beg = 0
          pkp_end = (pkp+hinterval)/int_step
          if pkp_end gt par.nfreq-1 then pkp_end = par.nfreq-1
          ind_gt[k, pkp_beg:pkp_end] = h+1
          if (ipar.peakproc[0] eq 1) then pkdf[0, k, pkp0] = ninterval*(par.df/int_step)
        endfor
      endif
    endfor
  endif
  
  ;
  ; FTEST
  if (ipar.peakproc[1] eq 1) then begin
    ;
    ; probe for each confidence level
    for k = 0,(nconf-1) do begin
      ; only F-test local peaks
      ft = spec.ftest
      deriv = ft - shift(ft,1)
      ind_ft = where(deriv ge 0 and shift(deriv,-1) lt 0 and $
        (ft gt spec.fconf[k]), /null )
      pkdf[1, k, ind_ft] = par.df
    endfor
  endif
  
  ;
  ; GAMMA + F TEST
  if (ipar.peakproc[2] eq 1) then begin
    ;
    ; probe for each confidence level
    for k = 0,(nconf-1) do begin
      ; only F-test local peaks
      ft = spec.ftest
      deriv = ft - shift(ft,1)
      ind_ft = (deriv ge 0 and shift(deriv,-1) lt 0 and ft gt spec.fconf[k])
      ind_gft = where( (ind_gt[k,*]*ind_ft) ge 1, /null)
      pkdf[2, k, ind_gft] = par.df
    endfor
  endif
  
  ;
  ; GAMMA + F TEST: only maximum F value
  if (ipar.peakproc[3] eq 1) then begin
    ;
    ; probe for each confidence level
    for k = 0,(nconf-1) do begin
      ; only F-test local peaks
      ft = spec.ftest
      deriv = ft - shift(ft,1)
      ind_ft = (deriv ge 0 and shift(deriv,-1) lt 0 and ft gt spec.fconf[k])
      for h = 0,max(ind_gt[k,*])-1 do begin
        ind_gft = where( (ind_gt[k,*]*ind_ft) eq h+1.d, /null)
        if ind_gft ne !null then begin
          ;
          ; maximum in the ftest
          gamma_gftm = max(spec.ftest[ind_gft], pos_gftm)
          ind_gftm = ind_gft(pos_gftm)
          pkdf[3, k, ind_gftm] = par.df
        endif
      endfor
    endfor
  endif
  
  ;
  ; assign values to the output structure
  peak.pkdf = pkdf

endif else message, 'Peak procedure not defined. No peaks selected.', /continue

end