;+
; PROCEDURE:
;
; anima_sumplot
;
; PURPOSE:
;
; The fastest CDF viewer in the west.  Saves a series of summary plots
; in memory for later rolodex-style viewing using the widget-based
; routine xinteranimate.
;
; USAGE:
;
; After invoking anima_sumplot, minimize the window until the
; procedure is ready to display all plots.  Three beeps means it is
; ready.  Restore the window and hit any key to start viewing.  Pause
; the animation, click on the frame slider, and then use the cursor
; keys to flip through the plots.  Pixmaps are purged from memory upon
; quitting.
;
; You can view eESA and iESA plots separately (qty='ees' or 'ies') or
; together (qty='esa').  The latter method will display eESA and iESA
; sequentially for each orbit.
;
; ACF and DCF may not be presented in tandem like the ESA plots.
; 
; You cannot change the plot interval of the static frames using
; tlimit.
;
; Note well the functionality of the ZOOM keyword.  It is very useful.
;
; INPUTS:
;
;    qty       A string: 'ees', 'ies', 'esa', 'tms', 'acf', 'dcf'
;
;    firstorb  The first orbit in the display sequence.
;
;    lastorb   The last orbit.
;
; KEYWORDS:
;
;    ZOOM      Set this keyword to check for two data collection
;              periods per orbit.  If two distinct intervals of data
;              are detected, the data is divided into two frames,
;              eliminating the gap.  An 'N' or 'S' will be placed in
;              the upper right corner of the frame depending on
;              whether the frame is the first or second in a pair.
;
;              Setting this keyword when viewing CDFs containing only
;              one data collection period wastes memory.  For this,
;              zoom is not recommended for orbits prior to 2493.
;
;              This keyword does not work when viewing ACF plots.
;
; CREATED:
;    
;    1997/7/17
;    by J. Rauchleiba
;-

; Subprocedure loads a CDF and plots the data
pro view, qty, orb, ERR=err

; Load the data
; TEAMS requires special handling on loading

err = 0
if qty EQ 'tms' then begin
    load_fa_k0_tms, /tplot, orbit=orb
endif else call_procedure, 'load_fa_k0_' + qty, orbit=orb
if !err NE 1 then begin
    print, 'Error message: ', !err_string
    err = -1
    return
endif

; Plot the data
; DCF requires special handling

if qty EQ 'dcf' then begin
    tplot, ['EX', 'EZ', 'BX', 'BY', 'BZ', 'S/C POTENTIAL', 'DENSITY'], $
      TITLE='DC Fields Orbit ' + strtrim(orb,2)
endif else call_procedure, 'plot_fa_k0_' + qty

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro anima_sumplot, qty, firstorb, lastorb, ZOOM=zoom

; Setup

if NOT keyword_set(lastorb) then lastorb=firstorb
pixwin = 1
xs = 800
ys = 800
if qty EQ 'esa' then begin
    if keyword_set(zoom) then fr_per_orb=4 else fr_per_orb=2
    nframes = (lastorb - firstorb + 1)*fr_per_orb
endif else if qty EQ 'tms' OR qty EQ 'dcf' OR qty EQ 'ees' OR qty EQ 'ies' $
  then begin
    if keyword_set(zoom) then fr_per_orb=2 else fr_per_orb=1
    nframes = (lastorb - firstorb + 1)*fr_per_orb
endif else begin
    nframes = lastorb - firstorb + 1
    fr_per_orb = 1
endelse

window, pixwin, /pixmap, xsize=xs, ysize=ys

xinteranimate, set=[xs, ys, nframes]

; Set the error handler

catch, errstat
if errstat NE 0 then begin
    print, 'Error index: ', errstat
    print, 'Error message: ', !err_string
    nframes = nframes - 1
endif

orb = firstorb
if qty EQ 'esa' then begin
    for i=0, (nframes - 1), fr_per_orb do begin
        catch, errstat
        if errstat NE 0 then begin
            print, !err_string
            nframes = nframes - fr_per_orb/2 ; Decrement iterations
            goto, IES           ; Try IESA for this orbit
        endif
        view, 'ees', orb, err=err
        if err EQ -1 then message, 'Loading error.'
        if keyword_set(zoom) then begin
            data_int = data_only('Je')
            if dimen1(data_int) EQ 2 then begin
                tlimit, data_int(0,0), data_int(1,0)
                xyouts, .75, .985, /norm, '(N)'
                xinteranimate, frame=i, window=pixwin
                tlimit, data_int(0,1), data_int(1,1)
                xyouts, .75, .985, /norm, '(S)'
                xinteranimate, frame=(i+1), window=pixwin
            endif else xinteranimate, frame=i, window=pixwin
        endif else xinteranimate, frame=i, window=pixwin
        IES: catch, errstat
        if errstat NE 0 then begin
            print, !err_string
            nframes = nframes - fr_per_orb/2 ; Decrement iterations
            goto, ENDESALOOP       ; Go to the next orbit
        endif
        view, 'ies', orb, err=err
        if err EQ -1 then message, 'Loading error.'
        if keyword_set(zoom) then begin 
            data_int = data_only('Ji')
            if dimen1(data_int) EQ 2 then begin
                tlimit, data_int(0,0), data_int(1,0)
                xyouts, .75, .985, /norm, '(N)'
                xinteranimate, frame=(i+2), window=pixwin
                tlimit, data_int(0,1), data_int(1,1)
                xyouts, .75, .985, /norm, '(S)'
                xinteranimate, frame=(i+3), window=pixwin
            endif else xinteranimate, frame=(i+2), window=pixwin
        endif else xinteranimate, frame=(i+1), window=pixwin	
        ENDESALOOP: orb = orb + 1
    endfor
endif else if qty EQ 'ees' then begin
    for i=0, (nframes - 1), fr_per_orb do begin
        catch, errstat
        if errstat NE 0 then begin
            print, !err_string
            nframes = nframes - fr_per_orb ; Decrement iterations
            goto, ENDEESLOOP           ; Try IESA for this orbit
        endif
        view, 'ees', orb, err=err
        if err EQ -1 then message, 'Loading error.'
        if keyword_set(zoom) then begin
            data_int = data_only('Je')
            if dimen1(data_int) EQ 2 then begin
                tlimit, data_int(0,0), data_int(1,0)
                xyouts, .75, .985, /norm, '(N)'
                xinteranimate, frame=i, window=pixwin
                tlimit, data_int(0,1), data_int(1,1)
                xyouts, .75, .985, /norm, '(S)'
                xinteranimate, frame=(i+1), window=pixwin
            endif else xinteranimate, frame=i, window=pixwin
        endif else xinteranimate, frame=i, window=pixwin
        ENDEESLOOP: orb = orb + 1
    endfor
endif else if qty EQ 'ies' then begin
    for i=0, (nframes - 1), fr_per_orb do begin
        catch, errstat
        if errstat NE 0 then begin
            print, !err_string
            nframes = nframes - fr_per_orb ; Decrement iterations
            goto, ENDIESLOOP
        endif
        view, 'ies', orb, err=err
        if err EQ -1 then message, 'Loading error.'
        if keyword_set(zoom) then begin
            data_int = data_only('Ji')
            if dimen1(data_int) EQ 2 then begin
                tlimit, data_int(0,0), data_int(1,0)
                xyouts, .75, .985, /norm, '(N)'
                xinteranimate, frame=i, window=pixwin
                tlimit, data_int(0,1), data_int(1,1)
                xyouts, .75, .985, /norm, '(S)'
                xinteranimate, frame=(i+1), window=pixwin
            endif else xinteranimate, frame=i, window=pixwin
        endif else xinteranimate, frame=i, window=pixwin
        ENDIESLOOP: orb = orb + 1
    endfor
endif else if qty EQ 'tms' then begin
    for i=0, (nframes - 1), fr_per_orb do begin
        catch, errstat
        if errstat NE 0 then begin
            print, !err_string
            nframes = nframes - fr_per_orb
            goto, ENDTMSLOOP
        endif
        view, 'tms', orb, err=err
        if err EQ -1 then message, 'Loading error.'
        if keyword_set(zoom) then begin
            get_data, 'H+', data=protons
            dummy_d = protons.y(*,0)
            dummy_t = protons.x
            store_data, 'dummy', data={x:dummy_t, y:dummy_d}
            data_int = data_only('dummy')
            if dimen1(data_int) EQ 2 then begin
                tlimit, data_int(0,0), data_int(1,0)
                xyouts, .75, .985, /norm, '(N)'
                xinteranimate, frame=i, window=pixwin
                tlimit, data_int(0,1), data_int(1,1)
                xyouts, .75, .985, /norm, '(S)'
                xinteranimate, frame=(i+1), window=pixwin
            endif else xinteranimate, frame=i, window=pixwin
        endif else xinteranimate, frame=i, window=pixwin
        ENDTMSLOOP: orb = orb + 1
    endfor
endif else if qty EQ 'dcf' then begin
    for i=0, (nframes - 1), fr_per_orb do begin
        catch, errstat
        if errstat NE 0 then begin
            print, !err_string
            nframes = nframes - fr_per_orb
            goto, ENDDCFLOOP
        endif
        view, 'dcf', orb, err=err
        if err EQ -1 then message, 'Loading error.'
        if keyword_set(zoom) then begin
            data_int = data_only('EX')
            if dimen1(data_int) EQ 2 then begin
                tlimit, data_int(0,0), data_int(1,0)
                xyouts, .75, .985, /norm, '(N)'
                xinteranimate, frame=i, window=pixwin
                tlimit, data_int(0,1), data_int(1,1)
                xyouts, .75, .985, /norm, '(S)'
                xinteranimate, frame=(i+1), window=pixwin
            endif else xinteranimate, frame=i, window=pixwin
        endif else xinteranimate, frame=i, window=pixwin
        ENDDCFLOOP: orb = orb + 1
    endfor
endif else begin
   for i=0, (nframes - 1), fr_per_orb do begin		; One plot per orbit
	catch, errstat
	if errstat NE 0 then begin
		print, !err_string
		nframes = nframes - fr_per_orb
		goto, ENDLOOP2
	endif
	view, qty, orb, err=err
        if err EQ -1 then message, 'Loading error.'
	xinteranimate, frame=i, window=pixwin
   ENDLOOP2: orb = orb + 1
   endfor
endelse

for beep=0, 3 do print, string(7B)
print, "Ready to display plots.  Hit any key to continue"
dummy = get_kbrd(1)

xinteranimate

end
