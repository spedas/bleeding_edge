;+
;FUNCTION:   swe_pad32hz_unpack
;PURPOSE:
;  Expands a high time resolution PAD structure into 64 single-energy
;  PAD structures, with appropriate timing, magnetic field data, and
;  pitch angle mapping.
;
;USAGE:
;  pad32hz = swe_pad32hz_unpack(pad)
;
;INPUTS:
;       pad:          Array of 64-energy PAD structures with sweep
;                     tables > 6.  (Tables <= 6 are ignored.)
;
;OUTPUT:
;       pad32Hz:      Array of single-energy PAD structures with
;                     high time resolution.
;
;KEYWORDS:
;       none
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-03 11:53:01 -0700 (Tue, 03 Jun 2025) $
; $LastChangedRevision: 33360 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_pad32hz_unpack.pro $
;
;CREATED BY:	David L. Mitchell  2019-03-01
;-
function swe_pad32hz_unpack, pad

  @mvn_swe_com

  indx = where(pad.lut gt 6, npad)
  if (npad eq 0) then begin
    print, "No 32-Hz PAD data."
    return, 0
  endif

  get_data, 'mvn_B_full', index=i
  if (i eq 0) then begin
    print, "You must load 32-Hz MAG data first."
    print, "For L1, MAG and SWEA data must use the same SCLK kernel."
    return, 0
  endif

  cret = string(13b)
  msg = "Mapping pitch angle: "
  if (npad gt 10) then begin
    tenpct = round(float(npad)/10.)
    print,cret,msg,0,"% ",format='(a,a,i3,a,$)'
  endif else tenpct = 2L*npad

  fpad = mvn_swe_padmap_32hz(pad[indx[0]], fbdata='mvn_B_full', verbose=0)
  fpad = replicate(fpad,npad)
  for i=1,(npad-1) do begin
    fpad[i] = mvn_swe_padmap_32hz(pad[indx[i]], fbdata='mvn_B_full', verbose=0)
    if (~(i mod tenpct)) then begin
      pct = 10*(i/tenpct)
      print,cret,msg,pct,"% ",format='(a,a,i3,a,$)'
    endif
  endfor
  if (npad gt 10) then print,cret,msg,100,"% ",format='(a,a,i3,a)'

; Define arrays for single-energy pad

  pad32hz = pad[indx[0]]
  str_element, pad32hz, 'dt_arr', fpad[0].dt_arr[0,*], /add
  str_element, pad32hz, 'energy', fpad[0].energy[0,*], /add
  str_element, pad32hz, 'denergy', fpad[0].denergy[0,*], /add
  str_element, pad32hz, 'eff', fpad[0].eff[0,*], /add
  str_element, pad32hz, 'pa', fpad[0].pa[0,*], /add
  str_element, pad32hz, 'dpa', fpad[0].dpa[0,*], /add
  str_element, pad32hz, 'pa_min', fpad[0].pa_min[0,*], /add
  str_element, pad32hz, 'pa_max', fpad[0].pa_max[0,*], /add
  str_element, pad32hz, 'theta', fpad[0].theta[0,*], /add
  str_element, pad32hz, 'dtheta', fpad[0].dtheta[0,*], /add
  str_element, pad32hz, 'phi', fpad[0].phi[0,*], /add
  str_element, pad32hz, 'dphi', fpad[0].dphi[0,*], /add
  str_element, pad32hz, 'domega', fpad[0].domega[0,*], /add
  str_element, pad32hz, 'gf', fpad[0].gf[0,*], /add
  str_element, pad32hz, 'dtc', fpad[0].dtc[0,*], /add
  str_element, pad32hz, 'bkg', fpad[0].bkg[0,*], /add
  str_element, pad32hz, 'data', fpad[0].data[0,*], /add
  str_element, pad32hz, 'valid', fpad[0].valid[0,*], /add
  str_element, pad32hz, 'var', fpad[0].var[0,*], /add

; Repackage 64-energy pads into single-energy pads

  npts = npad*64L
  if (npad gt 1) then order = [1,0,2] else order = [1,0]
  pad32hz = replicate(pad32hz, npts)
  pad32hz.dt_arr = reform(transpose(fpad.dt_arr,order),1,16,npts)
  pad32hz.energy = reform(transpose(fpad.energy,order),1,16,npts)
  pad32hz.denergy = reform(transpose(fpad.denergy,order),1,16,npts)
  pad32hz.eff = reform(transpose(fpad.eff,order),1,16,npts)
  pad32hz.pa = reform(transpose(fpad.pa,order),1,16,npts)
  pad32hz.dpa = reform(transpose(fpad.dpa,order),1,16,npts)
  pad32hz.pa_min = reform(transpose(fpad.pa_min,order),1,16,npts)
  pad32hz.pa_max = reform(transpose(fpad.pa_max,order),1,16,npts)
  pad32hz.theta = reform(transpose(fpad.theta,order),1,16,npts)
  pad32hz.dtheta = reform(transpose(fpad.dtheta,order),1,16,npts)
  pad32hz.phi = reform(transpose(fpad.phi,order),1,16,npts)
  pad32hz.dphi = reform(transpose(fpad.dphi,order),1,16,npts)
  pad32hz.domega = reform(transpose(fpad.domega,order),1,16,npts)
  pad32hz.gf = reform(transpose(fpad.gf,order),1,16,npts)
  pad32hz.dtc = reform(transpose(fpad.dtc,order),1,16,npts)
  pad32hz.bkg = reform(transpose(fpad.bkg,order),1,16,npts)
  pad32hz.data = reform(transpose(fpad.data,order),1,16,npts)
  pad32hz.valid = reform(transpose(fpad.valid,order),1,16,npts)
  pad32hz.var = reform(transpose(fpad.var,order),1,16,npts)

  dt = 1.95D/64D
  pad32hz.time = reform(fpad.ftime, npts)
  pad32hz.end_time = pad32hz.time + (dt/2D)
  pad32hz.delta_t = dt
  pad32hz.lut = byte(reform(replicate(1B, 64) # fpad.lut, npts))
  pad32hz.nenergy = 1
  pad32hz.baz = reform(fpad.fbaz, npts)
  pad32hz.bel = reform(fpad.fbel, npts)

  mvn_swe_magdir, pad32hz.time, iBaz, jBel, reform(fpad.fbaz, npts), $
                  reform(fpad.fbel, npts), /inverse
  for i=0L,(npts-1L) do pad32hz[i].iaz = fix((indgen(16) + iBaz[i]/16) mod 16)
  for i=0L,(npts-1L) do pad32hz[i].jel = swe_padlut[*,jBel[i]]
  pad32hz.k3d = pad32hz.jel*16 + pad32hz.iaz

  pad32hz.magf = reform(transpose(fpad.fmagf,order),3,npts)

  pad32hz.data_name = pad32hz[0].data_name + ' Hires'

  return, pad32hz

end
