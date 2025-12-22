;+
; FUNCTION: FA_FIELDS_FFT, dat, store=store, npts=npts, nave=nave, slide=slide,
;                          tags=tags, dt=dt
;       
;
; PURPOSE: A high level routine which produces FFT spectrum of 
;          time series data. 
;
; INPUT: 
;       dat -         A time series data structure. 
;
; KEYWORDS: 
;       store -       NOT WORKING. Store data as a tplot file.  DEFAULT = 0
;       npts -        OPTIONAL. The number of points in FFT.    DEFAULT = 1024
;       nave -        OPTIONAL. The number FFTs to average.     DEFAULT = 4
;       slide -       OPTIONAL. Overlap between FFTs.           DEFAULT = 0.5
;
; CALLING: result = fa_fields_fft(dat)
;
; OUTPUT: RESULT is a data structure simlar to SFA or DSP.
;
; SIDE EFFECTS: Need lots of memory.
;
; INITIAL VERSION: REE 97-04-10
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
function fa_fields_fft, dat, store=store, npts=npts, nave=nave, slide=slide, $
                        tags=tags, dt=dt 

; FIRST SET UP KEYWORD DEFAULTS
if not keyword_set(npts) then npts = 1024
if not keyword_set(nave) then nave = 4
if not keyword_set(slide) then slide = 0.5

ntot = long(nave) * long(npts)

;
; CHECK WHICH COMPONENTS.
;
tagl = strlowcase(tag_names(dat))
IF not keyword_set(tags) then BEGIN
    list = where(strmid(tagl,0,4) eq 'comp',ntags) 
    IF ntags eq 0 then BEGIN
        print,'FA_FIELDS_HSBMCAL: STOPPED.'
        print,'Cannot find comp*.'
        return, -1
    ENDIF
    tags = tagl(list)
ENDIF ELSE BEGIN
    IF (missing_tags(dat,tags,absent=absent) gt 0) then BEGIN
        print,'FA_FIELDS_HSBMCAL: STOPPED.'
        print,'Missing tags!.'
        return, -1
    ENDIF
    ntags = n_elements(tags)
ENDELSE     

; BERAK THE DATA INTO BUFFERS
fa_fields_bufs, dat, ntot, buf_starts=strt, buf_ends=stop
nbufs=n_elements(strt)
;nbufs=1
;strt=[0L]
;stop=[n_elements(dat.comp1)-1L]

; ESTIMATE THE SIZE OF THE RESULT

all = total( (stop-strt) ) + nbufs
num_ffts = all / (ntot * slide)
num_freqs = npts/2 + 1.

fft_dat = fltarr(num_ffts, num_freqs)
time   = dblarr(num_ffts)
nfft = 0l

;
; SET UP RETURN
;
; FIRST ESTABLISH UNITS
;
units_name = '(' + dat.units_name + ')^2/Hz'
conversion = 1.0
IF dat.units_name EQ 'mV/m' then BEGIN
    units_name = '(V/m)^2/Hz'
    conversion = 1.e6
ENDIF

print,conversion

result =       {DATA_NAME: 	dat.data_name+'_FFT', 	$
		VALID:		dat.valid, 		$
		PROJECT_NAME:	dat.project_name,	$
		UNITS_NAME:	units_name,		$
		CALIBRATED:	dat.calibrated,		$
		START_TIME:	dat.time(strt(0)),	$
		END_TIME:	dat.time(stop(nbufs-1)),$
                YAXIS_UNITS:    'kHz' }

;
; *** START LOOP THROUGH COMPONENTS HERE ***
; 

; added status information - RJS 4/14/98

FOR j = 0, ntags-1 DO BEGIN

    frac=10
    print,''
    print,'Estimate ',num_ffts,' FFTs'

    nfft = 0l
    tag_num = where(tagl eq tags(j), better_be_one)

    FOR i = 0, nbufs-1 do BEGIN

        n1 = long(strt(i))
        n2 = n1 + ntot - 1l
        if not keyword_set(dt) then dt = dat.time(n1+1) - dat.time(n1)

        ; DO ALL FFTS
        WHILE (n2 LE stop(i)) DO BEGIN
            n_ave=nave
            power_spec,dat.(tag_num(0))(n1:n2), n_ave=n_ave, npts=npts, $
                            sample = dt, freq, spec, /over
            fft_dat(nfft,*) = spec/conversion
;            time(nfft) = dat.time(n1)
            time(nfft) = .5d0*(dat.time(n1)+dat.time(n2)) ; RJS modification
            if (nfft eq 0L) then print,0,format='(/i4,"%",$)'

            if nfft gt .01*frac*(num_ffts-1) and frac lt 100 then begin 
                 print,frac,format='(i4,"%",$)'
                 frac=frac+10
            endif
            nfft = nfft + 1l
            n1 = n1 + long(ntot*slide)
            n2 = n1 + ntot - 1l
        ENDWHILE

    ; *** Put in case for change of dt here. ***

    ENDFOR

    print,100,format='(i4,"%"/)'

    add_str_element, result, tags(j), fft_dat(0:nfft-1,*)
    IF j EQ ntags-1 then  BEGIN
        add_str_element, result, 'TIME', time(0:nfft-1)
        add_str_element, result, 'YAXIS', freq/1000.
;        add_str_element, result, 'SIZE', size(result.(tags(0)))
    ENDIF


ENDFOR

return, result
END


