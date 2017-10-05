;+
;FUNCTION:	thm_energy_to_ebin(dat,en)
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;	en:	real,fltarr,	real or float array of energy values
;KEYWORD:
;	BIN	int,intarr	optional, angle bins corresponding to "en"
;				used when energies depend upon angle bin
;PURPOSE:
;	Returns the energy bin numbers in "dat.energy" nearest to "en"
;
;CREATED BY:
;	J.McFadden
;LAST MODIFICATION:
;	96-4-22		J.McFadden
; 2014-06-30: Adding thm prefix to differentiate from identically named FAST routines
; 
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-06-30 18:58:14 -0700 (Mon, 30 Jun 2014) $
;$LastChangedRevision: 15492 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/packet/functions/thm_energy_to_ebin.pro $
;-
function thm_energy_to_ebin,dat,en,BIN=bin2
  
  if dat.valid eq 0 then begin
    dprint, 'Invalid Data'
    return, !values.f_nan
  endif
  
  if keyword_set(bin2) then bin=bin2
  
  endim=dimen1(en)
  if endim eq 0 then begin
    if not keyword_set(bin2) then bin=0
    energy=reform(dat.energy[*,bin])
    tmp=min((energy-en)^2,ebin)
    return,ebin
  endif else begin
    ebin=intarr(endim)
    if not keyword_set(bin2) then bin=intarr(endim)
    for a=0,endim-1 do begin
      if n_elements(dat.energy[*,0]) eq 1 then $
        energy=dat.energy[*,bin[a]] $
      else $
        energy = reform(dat.energy[*,bin[a]])
      tmp=min((energy-en[a])^2,eb)
      ebin[a]=eb
    endfor
    return,ebin
  endelse
  
end

