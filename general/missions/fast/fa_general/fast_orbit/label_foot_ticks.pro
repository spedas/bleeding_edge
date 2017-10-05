;+
; PROCEDURE:
;
;    label_foot_ticks
;
; PURPOSE:
;
;    Keeps track of parasites on the pedal area of the body.  Adds
;    timeticks and text labels to a path plotted on a map of the
;    earth.  The latitudes and longitudes, as well as the
;    corresponding time array, must be passed through keywords.  This
;    procedure was written for plot_fa_crossing.pro.
;
; KEYWORDS:
;
;    TIME_ARRAY The time array corresponding to the FLAT and FLNG
;               arrays.
;    LATITUDE   The latitude array.
;    LONGITUDE  The longitude array.
;    LATLIM     The absolute value of lattitude above which (below in
;               S. hem.) to confine timeticks on the plot. Default is
;               45 degrees.
;    INTERVAL   The interval in seconds on which ticks are marked.
;               Default is 300 sec.
;    COLOR      The color of the labels
;
; CREATED:
;
;    BY         J.Rauchleiba
;    DATE       97-9-12
;-
pro label_foot_ticks, $
         TIME_ARRAY=clock, $
         LATITUDE=Flat, $
         LONGITUDE=Flng, $
         LATLIM=latlim, $
         INTERVAL=interval, $
         COLOR=color

if NOT keyword_set(latlim) then latlim=45
if NOT keyword_set(interval) then interval=300.d
interval = double(interval)
black = 0
if n_elements(color) EQ 1 then col_tags=color else col_tags=!d.n_colors

; ADD TIME TICKS, LABELS TO PATH
; N. polar region
; all points in N40 may not be adjacent, as when FAST in S. hem.

N40 = where(Flat GE latlim)	; indices of data points >= interval deg N
if N40(0) NE -1 then begin	; if there are points above interval deg N
	ticktime = dblarr(24)	; array to hold times of each tick
	ticklat = fltarr(24)	; array to hold lattitudes of each tick
	ticklng = fltarr(24)	; array to hold longitudes of each tick
	;get index to data point nearest an "interval" mark within 1st 26 pts
	if n_elements(N40) GT 25 then begin
		;subind is an index to a subarray of the data
		rem = min( clock(N40(0:25)) MOD interval, subind )
	endif else subind = 0
	firstind = N40(0) + subind
	tickind = firstind	; Index of data point where 1st tick will be
	p = 0			; Initialize to first tick mark
	; Make lat, lng, time arrays holding info for each tickmark
	repeat begin
		ticktime(p) = clock(tickind)
		ticklat(p) = Flat(tickind)
		ticklng(p) = Flng(tickind)
		p = p + 1
		;get index of point nearest first point plus p times interval
		dt = min(abs((clock(firstind) + p*interval) - clock),tickind)
	endrep until (Flat(tickind) LT latlim) OR (p EQ 24) OR (dt GT .1*interval)
	ticktime = ticktime(where(ticktime NE 0)) ; trim zero elements
	ticklat = ticklat(where(ticktime NE 0))
	ticklng = ticklng(where(ticktime NE 0))
	nticks = n_elements(ticktime)
        oplot, ticklng, ticklat, psym=1, symsize=1.8, color = black
        lab_st_en = convert_coord([ticklng(0), ticklng(nticks-1)], $
                                  [ticklat(0), ticklat(nticks-1)], /to_norm)
        if lab_st_en(0,0) LE lab_st_en(0,1) then begin
            lab_st_al = 1.0
            lab_en_al = 0.0
        endif else begin
            lab_st_al = 0.0
            lab_en_al = 1.0
        endelse
        xyouts, ticklng(0), ticklat(0), $
          strmid(time_to_str(ticktime(0)),11,8), $
          color=col_tags, align=lab_st_al
        xyouts, ticklng(nticks-1), ticklat(nticks-1), $
          strmid(time_to_str(ticktime(nticks-1)),11,8), $
          color=col_tags, align=lab_en_al
endif
	
; S. polar region

S40 = where(Flat LE -latlim)	; indices of data points <= -interval deg N
if S40(0) NE -1 then begin	; if there are points below -interval deg N
	ticktime = dblarr(24)	; array to hold times of each tick
	ticklat = fltarr(24)	; array to hold lattitudes of each tick
	ticklng = fltarr(24)	; array to hold longitudes of each tick
	;get index to data point nearest an "interval" mark within 1st 26 pts
	if n_elements(S40) GT 25 then begin
		;subind is an index to a subarray of the data
		rem = min( clock(S40(0:25)) MOD interval, subind)
	endif else subind = 0
	firstind = S40(0) + subind
	tickind = firstind	; Index of data point where 1st tick will be
	p = 0			; Initialize to first tick mark
	; Make lat, lng, time arrays to hold info for each tickmark
	repeat begin
		ticktime(p) = clock(tickind)
		ticklat(p) = Flat(tickind)
		ticklng(p) = Flng(tickind)
		p = p + 1
		dt = min(abs((clock(firstind) + p*interval) - clock),tickind)
	endrep until (Flat(tickind) GT -latlim) OR (p EQ 24)
	ticktime = ticktime(where(ticktime NE 0)) ; trim zero elements
	ticklat = ticklat(where(ticktime NE 0))
	ticklng = ticklng(where(ticktime NE 0))
	nticks = n_elements(ticktime)
        oplot, ticklng, ticklat, psym=1, symsize=1.8, color = black
        lab_st_en = convert_coord([ticklng(0), ticklng(nticks-1)], $
                                  [ticklat(0), ticklat(nticks-1)], /to_norm)
        if lab_st_en(0,0) LE lab_st_en(0,1) then begin
            lab_st_al = 1.0
            lab_en_al = 0.0
        endif else begin
            lab_st_al = 0.0
            lab_en_al = 1.0
        endelse        
	xyouts, ticklng(0), ticklat(0), $
          strmid(time_to_str(ticktime(0)),11,8), $
          color=col_tags, align=lab_en_al
	xyouts, ticklng(nticks-1), ticklat(nticks-1), $
          strmid(time_to_str(ticktime(nticks-1)),11,8), $
          color=col_tags, align=lab_en_al
endif


end
