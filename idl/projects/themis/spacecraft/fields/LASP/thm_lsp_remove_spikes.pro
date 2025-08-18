;+
;PRO: THM_LSP_REMOVE_SPIKES
;
;           NOT FOR GENERAL USE. 
;           ONLY FOR ISOLATED PARTICLE OR WAVE BURSTS
;           NOT FOR ENTIRE ORBIT.
;
;PURPOSE:
;    Remove the non-physical spiky signals in the efw data.
;
;INPUT:
;    t             -NEEDED. Time array
;    Ex, Ey, Ez    -NEEDED. Data. Leave blank or set to zero to skip.
;    per           -NEEDED. Spin period.
;    Efp           -NEEDED for wave burst. Not needed for particle burst.
;
;KEYWORD:
;    nwin          -OPTIONAL. Number of points in spike search window. DFLT = 16
;    spikesig      -OPTIONAL. Sigma of spikes. DFLT = 5
;    sigmin        -OPTIONAL. Minimun of sigma. DFLT = 0 mV/m.
;    nfit          -OPTIONAL. Number of points in the fit window. DFLT = 16
;    fit           -OPTIONAL. If set, will fit spikes to Gaussian. DFLT = 0
;
;HISTORY:
;   2009-05-12: REE. Complete rewrite for wave burst.
;
; VERSION:
; $LastChangedBy$
; $LastChangedDate$
; $LastChangedRevision$
; $URL$
;-

pro thm_lsp_remove_spikes, t, Ex, Ey, Ez, per, Efp=Efp, nwin=nwin, $
              spikesig=spikesig, sigmin=sigmin, nfit=nfit, fit=fit, $
              talk=talk, diagnose=diagnose, wt=wt


; START WITH WAVE BURST REMOVE
IF keyword_set(Efp) THEN BEGIN

  ; FIND THE CORECT PARTICLE BURST
  thm_lsp_find_burst, Efp, t(n_elements(t)/2), istart=istart, iend=iend
  IF istart LT 0 then BEGIN
    print, 'THM_LSP_REMOVE_SPIKES: No EFP data available during wave burst.' 
    print, 'THM_LSP_REMOVE_SPIKES: Cannot remove spikes for this burst.'
    return
  ENDIF

  ; BREAK OUT PARTICLE BURST DATA
  tpb  = Efp.x(istart:iend)
  Efpx = Efp.y(istart:iend, 0)
  Efpy = Efp.y(istart:iend, 1)
  Efpz = Efp.y(istart:iend, 2)

ENDIF ELSE BEGIN ; DO PARTICLE BURST
  tpb = t
  if keyword_set(Ex) then Efpx = Ex
  if keyword_set(Ey) then Efpy = Ey
  if keyword_set(Ez) then Efpz = Ez
ENDELSE
  
; REMOVE SPIKES IN EX
IF keyword_set(Ex) THEN BEGIN
;   if keyword_set(talk) then print, 'Removing spikes in Ex:'  
  print, 'Removing spikes in Ex...'  
  tpks = thm_lsp_find_spikes(tpb, Efpx, per, talk=talk, sigmin=sigmin, $
                             nwin=nwin, spikesig=spikesig, Amp=Amp)
  if (tpks(0) GE 0) then Ex = thm_lsp_notch_spikes(t, Ex, per, tpks,  $
                        nfit=nfit, Amp=Amp, fit=fit, wt=wt, talk=talk, $
                        diagnose=diagnose)  
ENDIF
  
; REMOVE SPIKES IN EY
IF keyword_set(Ey) THEN BEGIN
;   if keyword_set(talk) then print, 'Removing spikes in Ey.'  
  print, 'Removing spikes in Ey...'  
  tpks = thm_lsp_find_spikes(tpb, Efpy, per, talk=talk, sigmin=sigmin, $
                             nwin=nwin, spikesig=spikesig, Amp=Amp)
  if (tpks(0) GE 0) then Ey = thm_lsp_notch_spikes(t, Ey, per, tpks,  $
                         nfit=nfit, Amp=Amp, fit=fit, wt=wt, talk=talk, $
                         diagnose=diagnose) 
ENDIF
   
; REMOVE SPIKES IN EZ
IF keyword_set(Ez) THEN BEGIN
;   if keyword_set(talk) then print, 'Removing spikes in Ez.'  
  print, 'Removing spikes in Ez...'  
  tpks = thm_lsp_find_spikes(tpb, Efpz, per, talk=talk, sigmin=sigmin, $
                             nwin=nwin, spikesig=spikesig, Amp=Amp)
  if (tpks(0) GE 0) then Ez = thm_lsp_notch_spikes(t, Ez, per, tpks,  $
                         nfit=nfit, Amp=Amp, fit=fit, wt=wt, talk=talk, $
                         diagnose=diagnose) 
ENDIF

return
end
