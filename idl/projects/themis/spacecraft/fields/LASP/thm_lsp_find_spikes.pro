;+
;FUNCTION: THM_LSP_FIND_SPIKES
;
;           NOT FOR GENERAL USE. CALLED BY THM_EFI_REMOVE_SPIKES
;           ONLY FOR ISOLATED PARTICLE OR WAVE BURSTS
;           NOT FOR ENTIRE ORBIT.
;
;PURPOSE:
;    Remove the non-physical spiky signals in the efw data.
;
;INPUT:
;    t             -NEEDED. Time array
;    xx            -NEEDED. EFP data, DO NOT GIVE EFW DATA. Won't work.
;    per           -NEEDED. Spin period.
;
;KEYWORD:
;    nwin          -OPTIONAL. Number of points in spike search window. DFLT = 16
;    spikesig      -OPTIONAL. Sigma of spikes. DFLT = 5
;    sigmin        -OPTIONAL. Minimun of sigma. DFLT = 0 mV/m.
;
;OUTPUT:
;    tpks          RETURN VALUE. Time of peaks (mod spin per) + t0
;    Amp           Estimated amplitude of spikes. Helps remove_spikes.
;
;HISTORY:
;   2009-05-30: REE. Broke out to run with wave burst.
;-
function thm_lsp_find_spikes, t, xx, per, nwin=nwin, $
  spikesig=spikesig, sigmin=sigmin, talk=talk, Amp=Amp


IF not keyword_set(width) then width = 1.d-3 ; 1 ms

; SET UP TIME AND DATA
tt = t-t[0]
dt = tt[1:*]-tt[*]
mdt = median(dt)
x = xx

; CHECK KEYWORDS
if not keyword_set(nwin) then nwin = 16L
if not keyword_set(spikesig) then spikesig = 5.0d
if n_elements(sigmin) EQ 0 then sigmin = 0.01d

nwin = long(nwin)

; CALCULATE AVERAGE SIGNAL OVER PERIOD

phs      = tt/per
npps     = long(round(2.0d*per/mdt))    ; SET NUMBER OF POINTS PER SPIN AT ~2X DT
nspins   = ceil(max(phs))               ; NUMBER OF SPINS
ntot     = long(nspins) * long(npps)    ; NUMBER OF PHASE POINTS
phx      = dindgen(ntot)/npps
maxphs   = max(phs)
xp       = interpol([x,0,0], [phs, maxphs+mdt/per, maxphs+2*mdt/per], phx)
xr       = reform(xp, npps, nspins)
xe       = total(xr,2)/ nspins


if keyword_set(talk) then $
  plot, phx[0:npps-1], xe, xtit = 'Spin Phase (/2pi)', $
  title = 'Spin-Averaged Value', ytit = 'Amplitude'

; FIND SPIKES
;xel  = [xe(npps-nwin/2:npps-1), xe, xe(0:nwin/2-1)]
;xel2 = abs(xel-thm_lsp_median_smooth(xel,nwin))
;sig  = abs(xel2)/(stddev(xel2(nwin/2: npps+nwin/2-1))+sigmin)
;if keyword_set(nms) then sig = thm_lsp_median_smooth(sig,nms)
;if keyword_set(nms) then sig = smooth(sig,nms)
;sdum = sig                                 ; ISOLATE MAXIMUMS IN SIG
;FOR i= nwin/2-1, npps+nwin/2-1 DO BEGIN
;  smax = max(sdum(i-nwin/2+1:i+nwin/2))
;  if sdum(i) EQ smax then sig(i)=smax else sig(i) = 0
;ENDFOR
;sig  = sig(nwin/2: npps+nwin/2-1)
;ppk  = where(sig GE spikesig, nppk)


; NEW VERSION
xe3   = [xe, xe, xe]
Amp   = xe3-thm_lsp_median_smooth(xe3,nwin)
xe3s  = abs(Amp)
xe3sq = sqrt(smooth(xe3s*xe3s, npps/4+1))
sig   = xe3s/(xe3sq+sigmin)
sdum  = sig                                 
FOR i= nwin/2-1, 3*npps-nwin/2-1 DO BEGIN
  smax = max(sdum[i-nwin/2+1:i+nwin/2])
  if sdum[i] EQ smax then sig[i]=smax else sig[i] = 0
ENDFOR
sig   = sig[npps: 2*npps-1]
Amp   = Amp[npps: 2*npps-1]
ppk   = where(sig GE spikesig, nppk)


; CHECK PPK FOR ERRORS
IF nppk EQ 0 then BEGIN
  print, 'NO SPIKES FOUND'
  IF keyword_set(talk) then BEGIN
    xyouts, 0.25, 0.75, 'NO SPIKES FOUND', charsize=2, /normal
    wait, 1.0
  ENDIF 
  return, -1
ENDIF
IF nppk GT 4 THEN BEGIN
  print, 'TOO MANY SPIKES - CANNOT REMOVE'
  return, -1
ENDIF 

; PEAKS
tpks  = ppk*per/double(npps) + t[0]

IF keyword_set(talk) then BEGIN
  oplot, phx[ppk], xe[ppk], psym=6, col = 250
  xyouts, 0.25, 0.75, 'SPIKES', charsize=2, /normal
  wait, 0.25
ENDIF 

; ESTIMATE AMPLITUDES
Amp = Amp[ppk]

return, tpks

end

