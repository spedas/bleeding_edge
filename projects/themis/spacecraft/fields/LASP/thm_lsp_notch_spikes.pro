;+
;FUNCTION: THM_LSP_NOTCH_SPIKES
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
;    x             -NEEDED. Data
;    per           -NEEDED. Spin period.
;    tpks          -NEEDED. Phase of spikes.
;
;KEYWORD:
;    nfit          -OPTIONAL. Number of points in the fit window. DFLT = 16 (256 for wave)
;    fit           -OPTIONAL. If set, will perform a Gauss fit.
;    Amp           -OPTIONAL. Estimated amplitudes. Same number of elements as tpks. 
;    Diagnose      -OPTIONAL. Plots fits and notchs. 
;    Talk          -OPTIONAL. Indicates number of fits and notchs. 
;
;HISTORY:
;   2009-05-30: REE. Broke out to run with wave burst.
;-

function thm_lsp_notch_spikes, t, xx, per, tpks, nfit=nfit, Amp=Amp, fit=fit, $
                               talk=talk, diagnose=diagnose, wt=wt

; SET UP DATA
tt   = t-t[0]
dt   = t[1:*]-t[*]
mdt  = median(dt)
x    = xx

; CHECK KEYWORDS
if not keyword_set(wt)   then wt     = 0.0
if not keyword_set(nfit) then nfit   = round(1.0/mdt/32) > 16
nfit = long(nfit)

; PEAKS
tpeaks  = tpks - t[0]
tpeaks  = tpeaks - floor(tpeaks/per)*per

; CREATE NOTCHED INDEX FOR POLYFIT
xind    = lindgen(nfit+1)
nind    = where( (xind GE 3*nfit/8) AND (xind LE 5*nfit/8))
xind    = where( (xind LT 3*nfit/8) OR  (xind GT 5*nfit/8))
gfits   = 0
ntchs   = 0

; NOTCH SPIKES
FOR j = 0, n_elements(tpks)-1 DO BEGIN

  tspike = tpeaks(j)
  icent  = round(tspike/mdt)
  istart = (icent - nfit/2)
  IF istart LT 0 then BEGIN ; DON'T BOTHER WITH SPIKES AT EDGES
    tspike = tspike + per
    icent  = round(tspike/mdt)
    istart = (icent - nfit/2)
  ENDIF
  iend   = (icent + nfit/2)
  
  ; SET UP CRITERIA FOR GOOD FIT
  Ampmax   = 25.0  ; mV/m
  Ampmin   = -25.0 ; mV/m  
  IF n_elements(Amp) EQ  n_elements(tpks) then BEGIN
    Ampmax   = 0.0
    Ampmin   = 0.0
    if Amp[j] GE 0.0 then Ampmax = Amp[j]*10.0 else Ampmin = Amp[j]*10.0
  ENDIF
  Centmax  = nfit/16 + 1
  Centmin  = -Centmax
  Widthmax = 8.00d-3  ; IN SECONDS
  Widthmin = 0.25d-3  ; IN SECONDS
  Chimax   = 2.0      ; Chisq
  
  
  ; NEXT LOOP
  WHILE iend LT n_elements(x)-1 DO BEGIN
    xwin  = x[istart:iend]
    twin  = tt[istart:iend] - tt[istart]
    notch = 1
    if keyword_set(diagnose) then plot, twin, xwin
     
    ; DO POLY/GAUSS FIT
    IF keyword_set(fit) then BEGIN
      A    = poly_fit(twin[xind], xwin[xind], 1)     
      xfit = xwin - poly(twin, A)
      dum  = gaussfit(twin, xfit, G, chisq=chisq, nterms=3)
      fcent = round(G[1]/mdt) - nfit/2
      ; TEST IF G IS IN RANGE
      IF (G[0] LT Ampmax)  AND (G[0] GT Ampmin)   AND (fcent LT Centmax)  AND $
         (G[1] GT Centmin) AND (G[2] LT Widthmax) AND (G[2] GT Widthmin) AND $
         (chisq LT chimax) then BEGIN
        gfits = gfits + 1
        xwin = xwin - G[0]*exp(-(((twin-G[1])/G[2])^2)/2.0d )
        ; DIAGNOSTIC PLOTS
        IF keyword_set(diagnose) then BEGIN
          oplot, twin, poly(twin, A), col = 2
          oplot, twin, xfit, col = 4        
          oplot, twin, G[0]*exp(-(((twin-G[1])/G[2])^2)/2.0d ), col = 6
          oplot, twin, xwin, col = 1
          wait, wt
        ENDIF
        notch = 0      
      ENDIF
    ENDIF
       
    ; NOTCH
    IF keyword_set(notch) then BEGIN
      A = ladfit(twin, xwin)
      xwin(nind) = poly(twin(nind), A)      
      ; DIAGNOSTIC PLOTS
      IF keyword_set(diagnose) then BEGIN
        oplot, twin, poly(twin, A), col = 2
        oplot, twin, xwin, col = 1
        wait, wt
      ENDIF
      ntchs = ntchs + 1
    ENDIF
     
    ; RESET X      
    x[istart:iend] = xwin
    tspike = tspike + per
    icent  = round(tspike/mdt)
    istart = (icent - nfit/2)
    iend   = (icent + nfit/2)
  ENDWHILE
ENDFOR  

IF keyword_Set(talk) then BEGIN
  if keyword_set(fit) then $
    print, gfits, ' SPIKES REMOVED (GOOD FITS)', ntchs,  ' SPIKES NOTCHED (FAILED FITS)' else $
    print, ntchs, ' SPIKES NOTCHED' 
ENDIF

return, x
end    

