;+
; NAME:
;     THM_LSP_GET_SPEC (PROCEDURE)
;
; PURPOSE:
;     Get the power spectrum density (PSD) of a given tplot variable. 
;
; CALLING SEQUENCE:
;     thm_lsp_get_spec, tvar, units = units, prefix = prefix, fftlen = fftlen, $
;        yrange = yrange
;
; ARGUMENTS:
;     tvar: (INPUT, REQUIRED) The name of a tplot variable to calculate the
;           PSD from.
;
; KEYWORDS:
;     units: (INPUT, OPTIONAL) A string of the units of the data in the tvar. By
;           default, it is obtained from dlim.data_att.units, or 'unknown' if
;           dlim.data_att.units is not available.
;     prefix: (INPUT, OPTIONAL) The prefix for tplot variables that contain the
;           resulting PSD. By default, prefix = tvar.
;     fftlen: (INPUT, OPTIONAL) The number of data points to FFT. By default, 
;           fftlen = 512.
;     yrange: (INPUT, OPTIONAL) The yrange for the spectra. By default, yrange =
;           [1, Nyquist] in units of Hz.
;     ufactor: (INPUT, OPTIONAL) A factor to convert units from one to another.
;     instr_resp: (INPUT, OPTIONAL) The instrument response as a function of
;           frequency. The number of elements of instr_resp should be the same
;           as (fftlen/2 + 1). By default, instr_resp = 1.
;     /checkenergy: (INPUT, OPTIONAL) If set, the ratios of time-domain energy to
;           freq-domain energy are stored into tplot variables. By default, no
;           such output is generated.
;     /phase: If set, phase will be calculated and saved into tplots.
;     /ft   : If set, the FFT of the input data will be saved.
;
; EXAMPLES:
;     See thm_crib_lsp_get_spec.pro which is typically located under
;     TDAS_DIR/idl/themis/examples.
;
; HISTORY:
;   2010-03-07: Created by Jianbao Tao (JBT), CU/LASP.
;   2012-07-26: JBT, SSL, UC Berkeley.
;               1. Removed the spectral averaging.
;               2. Added keywords *phase* and *ft* to output phase and FFT data.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-07-27 12:29:50 -0700 (Fri, 27 Jul 2012) $
; $LastChangedRevision: 10753 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/LASP/thm_lsp_get_spec.pro $
;-
;-

pro thm_lsp_get_spec, tvar, units = units, prefix = prefix, fftlen = fftlen, $
      yrange = yrange, ufactor = ufactor, instr_resp = instr_resp, $
      checkenergy = checkenergy, phase = phase, ft = ft

compile_opt idl2
; Check tvar.
; thm_lsp_checkarg_tvar, tvar, error, errmsg
; if error ne 0 then begin
;    print, 'THM_LSP_GET_PSD: ' + errmsg
;    print, 'Exiting...'
;    return
; endif

get_data, tvar, data=data, dlim = dlim

; Check units.
if ~keyword_set(units) then begin
   str_element, dlim, 'data_att', success = s0
   if ~s0 then units = 'unknown' else begin
      str_element, dlim.data_att, 'units', success = s1
      if ~s1 then units = 'unknown' else units = dlim.data_att.units
   endelse
endif
tmp1 = size(units, /type) ne 7
tmp2 = n_elements(units) ne 1
tmp = tmp1 + tmp2
if tmp ne 0 then begin
   print, 'THM_LSP_GET_PSD: ' + $
      'Valid units of the input tplot variable must be a string scalar. '+$
      'Exiting...'
   return
endif
units0 = units[0]

; Check ufactor.
if n_elements(ufactor) eq 0 then ufactor = 1d

; Check prefix.
if n_elements(prefix) eq 0 then pre = tvar else begin
   pre = prefix
   if size(pre, /type) ne 7 then pre = tvar
   if n_elements(pre) ne 1 then pre = tvar
   if pre ne prefix then begin
      print, 'THM_LSP_GET_PSD: ' + $
      'WARNING -- No valid prefix is given. The default prefix is used.'
   endif
endelse
pre = pre[0]

; Check fftlen.
wrongfftlen = 0
if n_elements(fftlen) ne 1 then begin
   wrongfftlen = 1
   fftlen = 512
endif
if size(fftlen, /type) lt 2 or size(fftlen, /type) gt 5 then begin
   wrongfftlen = 1
   fftlen = 512
endif
if wrongfftlen then $
      print, 'THM_LSP_GET_PSD: ' + $
      'WARNING -- No valid fftlen is given. The default fftlen (512) is used.'

; Check instr_resp
if n_elements(instr_resp) ne (fftlen/2 + 1L) then instr_resp = 1d

dt = median(data.x[1:*] - data.x)
tarr = data.x
dim = size(data.y,/dim)

nyquist = 0.5 / dt
if ~keyword_set(yrange) then yrange = [1d/(fftlen * dt), nyquist]

; Generate spectrum names
if n_elements(dim) eq 2 then ncomp = dim[1] else ncomp = 1
if ncomp eq 3 then begin
  name = pre + ['_xspec', '_yspec', '_zspec'] 
  name2 = pre + ['_xphase', '_yphase', '_zphase'] 
  name3 = pre + ['_xft', '_yft', '_zft'] 
endif else begin
   tmp = indgen(ncomp) + 1
   name = pre + '_'+string(tmp, for='(I0)') + 'spec'
   name3 = pre + '_'+string(tmp, for='(I0)') + 'ft'
endelse

; Some constants.
nslide = fftlen/2 ; Number of points to slide to next section.
time_units = 1.  ; [sec]
freq_units = 1.  ; [Hz]
data_units = 1.  ; whatever units of the input is.

; Determine the frequencies of the power spectrum.
df = 1. / (fftlen * dt)
nf = fftlen/2 + 1L
farr = dindgen(nf) * df
fftdata_units = data_units ; units of fft(data).
psd_units = fftdata_units^2 / df ; PSD units.

; Generate a Hann window for fft.
win = hanning(fftlen, /double) ; The Hann window.
wx = fftlen / total(win^2)  ; Factor to compensate the attenuation by windowing.

btrange = thm_jbt_get_btrange(tvar, nb=nb, tind=tind)

; Get the time stamps and frequency bins.
for ib = 0L, nb -1L do begin
   ista = tind[ib, 0]
   iend = tind[ib, 1]
   nt = iend - ista + 1L
   if nt lt fftlen then continue  ; Skip a burst shorter than fftlen*dt
   if n_elements(ibstart) eq 0 then ibstart = ib  ; ibstart: the index of the
                                                  ; first long-enough burst
   nsec = long((nt - fftlen) / nslide) + 1L
   tmptime = dindgen(nsec) * (dt * nslide) + tarr[nslide+ista]
;  tmpfreq = transpose(rebin(farr, nf, nsec))
   if n_elements(time) lt 1 then time = tmptime else time=[time,tmptime]
;  if n_elements(freq) lt 1 then freq = tmpfreq else freq=[freq, tmpfreq]
endfor
if n_elements(time) lt 1 then begin
   print, 'THM_LSP_GET_SPEC: ' + $
      'No continuous section is longer than a fftlen. No spectrum is stored.'
   print, 'Exiting...'
   return
endif

time_energy = time ; time_energy: energy in time domain
freq_energy = time ; freq_energy: energy in freq domain
tmpenergy = time ; for storing tmp energy

psdunits = '(' + units0 + ')^2 / Hz'
coord = cotrans_get_coord(tvar)
att = {units:psdunits, coord_sys:coord, data_type:'calibrated'}
att2 = {units:'degree', coord_sys:coord, data_type:'calibrated'} ; phase
att3 = {coord_sys:coord, data_type:'calibrated'} ; phase
ztitle = '(' + units0 + ')!E2!N / Hz'
ztitle2 = 'Phase [degree]'
dlim = {spec:1B, log:1B, data_att:att, ylog:1, zlog:1, $
        ztitle:ztitle, yrange:yrange, ysubtitle:'[Hz]'}
dlim2 = {spec:1B, log:1B, data_att:att2, ylog:1, zlog:1, $
        ztitle:ztitle2, yrange:yrange, ysubtitle:'[Hz]'}
dlim3 = {spec:1B, log:1B, data_att:att3}

for icom = 0L, ncomp-1L do begin
   psdname = name[icom]
   for ib = 0L, nb-1L do begin
      ista = tind[ib, 0]
      iend = tind[ib, 1]
      nt = iend - ista + 1L
      if nt lt fftlen then continue
      nsec = long((nt - fftlen) / nslide) + 1L
      dat = data.y[ista:iend, icom]
      tmppsd = dblarr(nf, nsec)
      if keyword_set(phase) then tmpphase = dblarr(nf, nsec)
      if keyword_set(ft) then tmpft = dcomplexarr(nf, nsec)
      tmp_tenergy = dblarr(nsec) ; energy in time domain
      tmp_fenergy = dblarr(nsec) ; energy in freq domain
      for isec = 0L, nsec - 1 do begin
      ;  print, ''
      ;  print, '# ', isec + 1, ' out of ', nsec
         iista = isec * nslide
         iiend = iista + fftlen - 1L
         xdat = dat[iista:iiend]
         tmp_tenergy[isec] = total(xdat)
         fx = fft(xdat * win)
         sqrfx = real_part(fx * conj(fx))

         ; Get phase
         if keyword_set(phase) then $
           tmpphase[*,isec] = (atan(fx,/phase) * 180. / !pi)[0:nf-1]

         ; Save Fourier transform
         if keyword_set(ft) then tmpft[*,isec] = fx[0:nf-1]

         ; Get PSD.
         tmppsd[0,isec] = sqrfx[0]
         tmppsd[1:fftlen/2-1,isec] = sqrfx[1:fftlen/2-1] + $
               reverse(sqrfx[fftlen/2+1:fftlen-1])
         tmppsd[fftlen/2,isec] = sqrfx[fftlen/2]
         tmppsd[*,isec] = tmppsd[*,isec] * wx / (instr_resp^2)
         
         ; Get energy.
      ;  wx = total(xdat^2) / total((xdat*win)^2)
         tmp_tenergy[isec] = total(xdat^2) * dt
         tmp_fenergy[isec] = total(sqrfx) * psd_units * wx
      endfor
      ; Average tmppsd.
;       xpsd = tmppsd
;       if nsec eq 1 then xpsd = transpose(xpsd) else begin
;          if nsec eq 2 then begin
;             xpsd[*,0] = (tmppsd[*,0] + tmppsd[*,1]*0.5) / 1.5
;             xpsd[*,nsec-1] = (tmppsd[*,nsec-1] + tmppsd[*,nsec-2]*0.5) / 1.5
;             xpsd = transpose(xpsd)
;          endif else begin
;             xpsd[*,0] = (tmppsd[*,0] + tmppsd[*,1]*0.5) / 1.5
;             xpsd[*,nsec-1] = (tmppsd[*,nsec-1] + tmppsd[*,nsec-2]*0.5) / 1.5
;             for isec = 1L, nsec - 2 do begin
;                xpsd[*,isec] = (total(tmppsd[*,isec-1:isec+1], 2) + $
;                      tmppsd[*,isec])/4.
;             endfor
;             xpsd = transpose(xpsd)
;          endelse
;       endelse
      xpsd = transpose(tmppsd)
      if keyword_set(phase) then xphase = transpose(tmpphase)
      if keyword_set(ft) then xft = transpose(tmpft)

      if ib eq ibstart then begin
        psd=xpsd 
        if keyword_set(phase) then phase_all = xphase
        if keyword_set(ft) then ft_all = xft
        tenergy = tmp_tenergy
        fenergy = tmp_fenergy
      endif else begin
        psd=[psd, xpsd]
        if keyword_set(phase) then phase_all = [phase_all, xphase]
        if keyword_set(ft) then ft_all = [ft_all, xft]
        tenergy = [tenergy, tmp_tenergy]
        fenergy = [fenergy, tmp_fenergy]
      endelse
   endfor
   psd = psd * psd_units * ufactor
   store_data, psdname, data={x:time, y:psd, v:farr}, dlim=dlim
   options, psdname, ystyle = 1

   if keyword_set(phase) then begin
     phasename = name2[icom]
     store_data, phasename, data = {x:time, y:phase_all, v:farr}, dlim = dlim2
     options, phasename, ystyle = 1
   endif

   if keyword_set(ft) then begin
     ftname = name3[icom]
     store_data, ftname, data = {x:time, y:ft_all, v:farr}, dlim = dlim3
     options, ftname, ystyle = 1
   endif

   if keyword_set(checkenergy) then begin
      store_data, psdname + '_checkenergy', data = {x:time, y:fenergy / tenergy}
      options, psdname + '_checkenergy', yrange=[0.5, 1.5], ystyle=1
   endif
endfor

end

