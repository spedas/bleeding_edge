;+
;FUNCTION: THM_LSP_REMOVE_SPIN_EPOCH, t, x, per, talk=talk
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
;    x             -NEEDED. Data
;    per           -NEEDED. Spin period.
;
;KEYWORDS:
;    talk          -OPTIONAL. Provides diagnostic plots.
;
;HISTORY:
;   2008-11-08: Created by Jianbao Tao at LASP@CU-Boulder.
;   2008-11-10: The head comment was added.
;   2009-03-30: REE. Rewrite to test epoch analysis.
;-

function thm_lsp_remove_spin_epoch, t, x, per, talk=talk

; CALCULATE AVERAGE SIGNAL OVER PERIOD
tt = t-t(0)
dt = t(1:*)-t(*)
mdt = median(dt)
phs      = tt/per
npps     = long(round(2.0d*per/mdt))    ; SET NUMBER OF POINTS PER SPIN AT ~2X DT
nspins   = ceil(max(phs))         ; NUMBER OF SPINS
ntot     = long(nspins) * long(npps)          ; NUMBER OF PHASE POINTS
phx      = dindgen(ntot)/npps
xp       = interpol(x, phs, phx)
xr       = reform(xp, npps, nspins)
xe       = total(xr,2)/ nspins
xe       = xe - total(xe)/npps


if keyword_set(talk) then $
  plot, phx(0:npps-1), xe, xtit = 'Spin Phase (/2pi)', $
  title = 'Spin-Averaged Value', ytit = 'Amplitude'

; REPLICATE SPIN
for i    = 0, nspins-1 do xr(*,i) = xe
xp       = reform(xr, ntot)
tp       = phx*per
xx       = interpol(xp, tp, tt)
xx       = x - xx

return, xx

end




