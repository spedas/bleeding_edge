; @(#)fa_fields_spec.pro	1.1 07/15/97
;+
; FUNCTION: FA_FIELDS_SPEC
;       
;
; PURPOSE: A high level routine which produces FFT spectrum of 
;          time series data. 
;
; INPUT: 
;       dat         - A time series data structure. 
;
; KEYWORDS: 
;       store       : Store data as a tplot file. DEFAULT = 0
;       npts        : OPTIONAL. The number of points in FFT. 
;                     DEFAULT = 1024
;       nave        : OPTIONAL. The number FFTs to average.
;                     DEFAULT = 4
;       slide       : OPTIONAL. Overlap between FFTs. DEFAULT = 0.5
;       svy         : OPTIONAL. Ignores changes in the time axis due
;                     to varying sample rates.
;       db          : OPTIONAL. Specifies output to be in decibels
;                     (10*log10(units^2/Hz))
;       t_name      : OPTIONAL. A string array that sets the name of
;                     the data in TPLOT.
;       structure   : OPTIONAL. When the /STORE keyword is used, data
;                     is not returned by the function (saves
;                     memory). If both data and tplot variables are
;                     desired, use  STRUCTURE = <data name> to extract
;                     the data explicitly.
;       tags        : OPTIONAL. Specifies what tag names in the FFT to
;                     be used for the spectra. Othwerwise routine will
;                     grab all components.
;
; CALLING: result = fa_fields_spec(dat)
;
; OUTPUT: RESULT is a data structure simlar to SFA or DSP.
;
; SIDE EFFECTS: Need lots of memory.
;
; LIMITATIONS: Does NOT account for changing data rates. Be careful.
;
; INITIAL VERSION: REE 97-04-10
; MODIFICATION HISTORY: GTD 97-04-16
; Space Sciences Lab, UCBerkeley
; 
;-

function fa_fields_spec, dat, $
                         NPTS = npts, $
                         N_AVE = n_ave, $
                         SLIDE = slide, $
                         STORE = store, $
                         SVY = svy, $
                         DB = db, $
                         T_NAME = t_name, $
                         TAGS = tags, $
                         STRUCTURE = result

; Figure out how many data components there are.
; Extract user defined tags if specified.
dat_tags = strlowcase(tag_names(dat))
if not defined(tags) then begin
    tags = dat_tags
    data_spots = where(strmid(tags,0,4) eq 'comp', n_comp)
endif else begin
    n_comp=0
    data_spots=fltarr(n_elements(tags))
    for i = 0,n_elements(tags)-1 do begin
        data_spots(i) = where(dat_tags eq tags(i))
        if data_spots(i) GE 0 then n_comp = n_comp+1
    endfor
    if total(data_spots)/n_elements(data_spots) LT 0 then begin
        print,'FA_FIELDS_SPEC: Input tags not found in data structure'
        return,-1
    endif
    tags=dat_tags
    data_spots=reverse(data_spots(sort(data_spots)))
endelse

; FIRST SET UP KEYWORD DEFAULTS
; NPTS = number of time series points needed for each FFT.
; N_AVE = number of segments of NPTS data points to average together.
if not keyword_set(npts) then npts = 1024
if not keyword_set(n_ave) then n_ave = 4
if not keyword_set(slide) then slide = 0.5

; NTOT = total number time series points used for each spectra.
ntot = long(n_ave) * long(npts)

; BREAK THE DATA INTO BUFFERS
fa_fields_bufs, dat, ntot, buf_starts=strt, buf_ends=stop

if strt(0) EQ stop(0) then begin
    print, 'FA_FIELDS_SPEC: Unable to extract continuous buffers from'
    print, 'time series data - try changing N_AVE and NPTS to get a '
    print, 'smaller buffer size.'
    return,-1
endif

nbufs=n_elements(strt)
    
; ESTIMATE THE SIZE OF THE RESULT
  
all = total( (stop-strt) ) + nbufs    
num_ffts = long(all/(ntot *  slide))
num_freqs = npts/2+1.
time = dblarr(num_ffts)
fft_dat = fltarr(num_ffts,num_freqs)   
nfft = 0l
dt = fltarr(nbufs)

;
; SET UP RETURN
;
; FIRST ESTABLISH UNITS
;
units_name = '(' + dat.units_name + ')!E2!N/Hz'
conversion = 1.0
;IF dat.units_name EQ 'mV/m' then BEGIN
;    units_name = '(V/m)^2/Hz'
;    conversion = 1.e6
;ENDIF

; Define output data structure.
result =       {DATA_NAME: 	dat.data_name+'_FFT', 	 $
		VALID:		dat.valid, 		 $
		PROJECT_NAME:	dat.project_name,	 $
		UNITS_NAME:	units_name,		 $
		CALIBRATED:	dat.calibrated,		 $
		START_TIME:	dat.time(strt(0)),	 $
		END_TIME:	dat.time(stop(nbufs-1)), $
                YAXIS_UNITS:    'kHz' }
num_tags = n_elements(tag_names(result))

; *** START LOOP THROUGH COMPONENTS HERE ***
; ADD CODE LATER.

For j = 0,n_comp-1 do begin
    
    nfft=0
    FOR i = 0, nbufs-1 do BEGIN
        n_start = long(strt(i))
        n_stop = n_start + ntot - 1l
        dt(i) = dat.time(n_start+1) - dat.time(n_start)
        
        ; DO ALL FFTS
        WHILE (n_stop LE stop(i)) DO BEGIN            
            power_spec,dat.(data_spots(j))(n_start:n_stop), $
              n_ave=n_ave, npts=npts, sample = dt(i), freq, spec, /over
            fft_dat(nfft,*) = spec
            time(nfft) = dat.time((n_start+n_stop)/2)            
            nfft = nfft + 1l            
            n_start = n_start + long(ntot*slide)            
            n_stop = n_start + ntot - 1l
        ENDWHILE

; *** Put in case for change of dt here. ***
    
        norm_dt = median(dt)
        abnorm = where(dt ne norm_dt)    
        
    endfor
    add_str_element, result, tags(data_spots(j)) , $
      fft_dat(0:nfft-1,*)
endfor

add_str_element, result, 'TIME', time(0:nfft-1)
add_str_element, result, 'YAXIS', freq/1000
add_str_element, result, 'SIZE', size(result.(num_tags))

if keyword_set(dB) then begin
    for j=0,n_comp-1 do result.(num_tags+j) = $
      10*alog10(result.(num_tags+j))
endif

if keyword_set(store) or keyword_set(nodata) then begin 
    
    if not keyword_set(t_name) or n_elements(t_name) $
      NE n_comp then begin
        t_name = strarr(n_comp)
        for j=0, n_comp-1 do t_name(j) = 'Spec_' + $
          tags(data_spots(j))
    endif  
    print,t_name
    for j=0, n_comp-1 do begin
        store_data,t_name(j),data={x:result.time, $
                                y:result.(num_tags+j), $
                                v:result.yaxis, $
                                spec:1}
        options, t_name(j), 'ystyle', 1
        options, t_name(j), 'ytitle', 'Frequency (kHz)'
        if keyword_set(db) then options, t_name(j), 'ztitle', $
          '10log!I10!N(' + result.units_name + ')' else $
          options, t_name(j), 'zlog',1
    endfor
endif

if keyword_set(store) then begin
    return, 'Spec_Data'
endif else return, result

END
