;+
; PROCEEDURE: FF_MAGFIX, mag, Bphase, filt=filt, freq=freq, max_chi = max_chi
;       
; PURPOSE: Performs a crude fix to the mag data. Essentially filters
;          spiky noise and trows away spin tone on Z component.
;          Before calling this routine: 
;          (1) Get 'MagDC'.
;
; INPUT: 
;       mag -         REQUIRED. 'MagDC' data structure.
;       phs -         OPTIONAL. Bphase interpolated to MagDC.
;
;
; KEYWORDS: 
;       filt   -      Filter cof for tweak values. DEFAULT = 0.1
;       freq   -      Percent Nyquist to filter data.
;       max_chi -     Maximum reduced chi-square of fit yielding usable tweak
;                     values.  DEFAULT = 1.0
;
; CALLING: 
;       ff_magfix,mag
;
; OUTPUT: mag.comp3 altered.
;
; INITIAL VERSION: REE 97-04-10
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
pro ff_magfix, mag, Bphase, filt=filt, freq=freq, max_chi=max_chi

two_pi = 2.d*!dpi

; START BY CHECKING INPUTS.
IF data_type(mag) NE 8 then BEGIN
    print, "FF_MAGFIX: STOPPED!"
    print, "Need to give mag data."
    return
ENDIF

; CHECK PHS.
npts = n_elements(Bphase)
IF npts NE mag.npts then BEGIN
    phase = fa_fields_phase()
    fa_fields_combine, mag, phase, result=Bphase, /interp, delt=1000.
ENDIF

npts = n_elements(Bphase)
IF npts NE mag.npts then BEGIN
    print, "FF_MAGFIX: STOPPED!"
    print, "Cannot get Bphase"
    return
ENDIF

if mag.ncomp ne 10 then begin
    add_str_element, mag, 'comp4', fltarr(mag.npts)
    add_str_element, mag, 'comp5', fltarr(mag.npts)
    add_str_element, mag, 'comp6', fltarr(mag.npts)
    add_str_element, mag, 'comp7', fltarr(mag.npts)
    add_str_element, mag, 'comp8', fltarr(mag.npts)
    add_str_element, mag, 'comp9', fltarr(mag.npts)
    add_str_element, mag, 'comp10', fltarr(mag.npts)
    mag.ncomp = 10
end

; SETUP CONSTANTS.
if not keyword_set(filt) then filt = 0.1
if not keyword_set(max_chi) then max_chi = 1.0
old_tweaky =0.0
old_tweakx =0.0
tweakx = 0.0
tweaky = 0.0


; ISOLATE ONE SPIN PERIOD
strt = 0l
stop = where(Bphase GT (Bphase(strt) + two_pi) )
stop = long(stop(0)-1l)
npts = long(stop - strt + 1)
first = 1
; DO THE SPIN TONE REMOVAL
WHILE (stop LT mag.npts AND stop gt 0) DO BEGIN

    Bx = mag.comp1(strt:stop) 
    By = mag.comp2(strt:stop) 
    Bz = mag.comp3(strt:stop)
    
                                ; Establish tweak cofs. only fit whole spins
                                ; with constant dt.
    
    if ((total(mag.time(strt+1:stop)-mag.time(strt:stop-1))/(npts-1)) $
        eq (mag.time(strt+1)-mag.time(strt)) AND npts GT 20 AND $
        (Bphase(stop)-Bphase(strt)) GT 9.*!dpi/10. ) then begin

        a = fltarr(npts, 4)
        a(*, 0) = 1
        a(*, 1) = findgen(npts)
        a(*, 2) = Bx
        a(*, 3) = By

        svd, a, w, u, v
        svbksb, u,w,v,Bz,coeff
        
;calculate chi square 
        chisqr = total((a#coeff-Bz)^2)/npts
        mag.comp4(strt:stop) = coeff(0)
        mag.comp5(strt:stop) = coeff(1)*npts
        mag.comp6(strt:stop) = coeff(2)
        mag.comp7(strt:stop) = coeff(3)
        mag.comp8(strt:stop) = chisqr

        if (chisqr lt max_chi) then begin 
            tweakx = coeff(2)
            tweaky = coeff(3)

            if (first) then begin
                old_tweakx = tweakx
                old_tweaky = tweaky
                first = 0
            endif

            tweakx = tweakx*filt + (1.0-filt)*old_tweakx
            tweaky = tweaky*filt + (1.0-filt)*old_tweaky
            old_tweakx = tweakx
            old_tweaky = tweaky
        endif

    endif else begin
        mag.comp4(strt:stop) = !values.f_nan
        mag.comp5(strt:stop) = !values.f_nan
        mag.comp6(strt:stop) = !values.f_nan
        mag.comp7(strt:stop) = !values.f_nan
        mag.comp8(strt:stop) = !values.f_nan
    endelse

    mag.comp9(strt:stop) = tweakx
    mag.comp10(strt:stop) = tweaky


                                ; Subtract off spin tone.
    mag.comp3(strt:stop) = Bz - Bx*tweakx - By*tweaky

                                ; Set up for next spin period.
    strt = long(stop + 1l)
    stop = where(Bphase GT (Bphase(strt) + two_pi) )
    stop = long(stop(0)-1l)
    npts = long(stop - strt + 1)

ENDWHILE

; LOCATE GAPS LARGER THAN ONE PERIOD.
;if not keyword_set(freq) then freq = 0.10
;fa_fields_filter,mag,[0.0,freq],tags=['comp3'], /nan, /mag

;fa_fields_bufs, mag,10, buf_starts=strt, buf_ends=stop
;nbufs = n_elements(strt)
;temp = mag
;comp3 = mag.comp3
;mag.comp3 = !values.f_nan

;FOR i = 0l, nbufs-1 do BEGIN
;    dt = mag.time(strt(i) + 1) - mag.time(strt(i))
;    f = freq/(2.0*dt)
;    temp.comp3 = comp3
;    fa_fields_filter,temp,[0.0,f],tags=['comp3'],/nan   
;    mag.comp3(strt(i):stop(i)) = temp.comp3(strt(i):stop(i))
;ENDFOR

return
END





