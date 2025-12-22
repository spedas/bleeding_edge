; fa_fields_cross.pro ver 1.1
;+
; FUNCTION: FA_FIELDS_CROSS
;       
;
; PURPOSE: A high level routine which produces FFT spectrum of 
;          time series data. Result is a spectrogram as a function of
;          time.  
;
; INPUT: 
;       dat1        : A time series data structure. 
;       dat2        : A second time series data structure.
;
; KEYWORDS: 
;       store       : Store data as a tplot file. DEFAULT = 0
;       npts        : OPTIONAL. The number of points in each FFT. 
;                     DEFAULT = 1024
;       nave        : OPTIONAL. The number FFTs to average.
;                     DEFAULT = 4
;       dt          : OPTIONAL. For time series data with different
;                     time axes, this is the maximum time difference
;                     allowable between two points before they are
;                     time aligned. See FA_FIELDS_COMBINE for more
;                     info. Ignored when CHAN2 is not used.
;       slide       : OPTIONAL. Overlap between FFTs. DEFAULT = 0.5
;       svy         : OPTIONAL. Ignores changes in the time axis due
;                     to varying sample rates. (Not working yet.)
;       structure   : OPTIONAL. When using /STORE, the output to the
;                     user is a string (no actual data) in order to
;                     save memory. If both stored tplot data and
;                     explicit user-level data are desired, set the
;                     structure keyword to a data name when using
;                     /STORE.  
;       tags        : OPTIONAL. An array of strings designating the
;                     two tag names in DAT1 that should be used in the
;                     cross-spectra. If CHAN2 is specified, the first
;                     tag name corresponds to the DAT1 tag to be used,
;                     and the second tag name corresponds to the tag
;                     within CHAN2 to be used.
;       talk        : OPTIONAL. Tells user some useful info during
;                     processing. 
;
;
; CALLING: result = fa_fields_cross(dat)
;
; EXAMPLE: You have COMP1, COMP2 in a structure DAT:
;          result = FA_FIELDS_CROSS(DAT) 
;          Two structures DAT1 and DAT2:
;          result = FA_FIELDS_CROSS(DAT1,chan2=DAT2)
;          Tag names other than 'COMP1': Takes elements of TAGS -
;          result = FA_FIELDS_CROSS(DAT1, chan2=DAT2, tags=['data1','data2']
;
;
; OUTPUT: RESULT is a data structure simlar to SFA or DSP. Function
;         returns -1 on some errors.
;
; SIDE EFFECTS: May need lots of memory.
;
; INITIAL VERSION: ver 1.0 GTD 04-16-97
; MODIFICATION HISTORY: v1.1 GTD 07-21-97
; Space Sciences Lab, UC Berkeley
; 
;-

function fa_fields_cross, dat1, $
                          chan2 = dat2, $
                          NPTS = npts, $
                          N_AVE = n_ave, $
                          SLIDE = slide, $
                          STORE = store, $
                          DT = dt, $
                          TAGS = tags, $
                          SVY = svy, $
                          STRUCTURE = result, $
                          TALK = talk

; FIRST SET UP KEYWORD DEFAULTS
; NPTS = number of time series points needed for each FFT.
; N_AVE = number of segments of NPTS data points to average together.
if not keyword_set(npts) then npts = 1024
if not keyword_set(n_ave) then n_ave = 4
if not keyword_set(slide) then slide = 0.5

; NTOT = total number time series points used for each spectra.
ntot = long(n_ave) * long(npts)

if not defined(dat2) then begin
    dat_tags = strlowcase(tag_names(dat1))
    if not defined(tags) then begin
        tags = dat_tags
        data_spots = where(strmid(tags,0,4) eq 'comp', n_comp)
          ; Warn user if fewer than 2 components are found.
        if n_comp LE 1 then begin
            print, 'FA_FIELDS_CROSS: Insufficient number of '
            print,  'COMPs found in the input data. Specify tags '
            print, 'or add second channel.'
            return,-1
        endif
        n_comp=2
        data_spots = data_spots(0:1)
    endif else begin
        tags = strlowercase(tags)
        if n_elements(tags) LT 2 then begin
            print,'FA_FIELDS_CROSS: Insufficient number of tags '
            print, 'provided'
            return,-1
        endif
        data_spots=fltarr(2)
        n_comp=0
        for i = 0,1 do begin                
            data_spots(i) = where(dat_tags eq tags(i))
            if data_spots(i) GE 0 then n_comp = n_comp+1
        endfor
        if n_comp LE 1  then begin
            print,'FA_FIELDS_CROSS:  One or more tags not found.'
            return,-1
        endif
        tags=dat_tags
        data_spots=reverse(data_spots(sort(data_spots)))
        ; Take first two components if more than one is found.
        data_spots = data_spots(0:1)
    endelse
    t_dat2 = dat1
endif else begin
    data_spots = fltarr(2)
    if not defined(tags) then begin
        dat1_tag = 'comp1'
        dat2_tag = 'comp1'
    endif else begin
        dat1_tag = tags(0)
        dat2_tag = tags(1)
    endelse
    tags_1 = strlowcase(tag_names(dat1))
    tags_2 = strlowcase(tag_names(dat2))
    data_spots_1 = where(strmid(tags_1,0,5) eq dat1_tag, n_comp_1)
    ; Take first occurence of DAT1_TAG in channel 1
    data_spots(0) = data_spots_1(0)
    data_spots_2 = where(strmid(tags_2,0,5) eq dat2_tag, n_comp_2)
    ; Take first occurence of DAT2_TAG in channel 2
    data_spots(1) = data_spots_2(0)
    if (data_spots(0) LT 0) or (data_spots(1)) LT 0 then begin
        print,'FA_FIELDS_CROSS: Components not found in one of the '
        print, 'input channels.'
        return,-1
    endif
    dt = 0.5*median(dat1.time(1:100) - dat2.time(0:99))
    if keyword_set(TALK) then begin
        print,'FA_FIELDS_CROSS: Max allowable DT ' + $
          'for FA_FIELDS_COMBINE:'
        print,'DT = '+strcompress(string(dt), /remove_all)+' sec'
    endif
    ; Combine time axis of each data series into a single axis.
    fa_fields_combine, dat1, dat2, result = t_dat2, delt_t = dt    
endelse

; BREAK THE DATA INTO BUFFERS. Procedure uses the time axis of the
; first data series as the default.

fa_fields_bufs, dat1, totpts, buf_starts=strt, buf_ends=stop, $
  delta_t = dt
nbufs=n_elements(strt)

; ESTIMATE THE SIZE OF THE RESULT
all = total( (stop-strt) ) + nbufs
num_ffts = long(all/(ntot * slide))
num_freqs = npts/2+1.

coh_dat = fltarr(num_ffts,num_freqs)
phase_dat = coh_dat
time = dblarr(num_ffts)

;
; SET UP RETURN
;
; FIRST ESTABLISH UNITS
;
units_name = '(' + dat1.units_name + ')!E2!N/Hz'


result =       {DATA_NAME: 	dat1.data_name+'_FFT', 	  $
                VALID:		dat1.valid, 		  $
                PROJECT_NAME:	dat1.project_name,	  $
                UNITS_NAME:	units_name,		  $
                CALIBRATED:	dat1.calibrated,	  $
                START_TIME:	dat1.time(strt(0)),	  $
                END_TIME:	dat1.time(stop(nbufs-1)), $
                YAXIS_UNITS:    'kHz' }

num_tags = n_elements(tag_names(result))
nfft = 0l
dt = fltarr(nbufs)

FOR i = 0, nbufs-1 do BEGIN
    n_start = long(strt(i))
    n_stop = n_start + ntot - 1l
    dt(i) = dat1.time(n_start+1) - dat1.time(n_start)
    ; DO ALL FFTS
    WHILE (n_stop LE stop(i)) DO BEGIN
        if not defined(dat2) then begin
            cross_spec,dat1.(data_spots(0))(n_start:n_stop), $
              dat1.(data_spots(1))(n_start:n_stop), n_ave=n_ave, $
              npts=npts, sample = dt(i), coh, phase, freq, $
              /overlap
        endif else begin
            cross_spec,dat1.(data_spots(0))(n_start:n_stop), $
              t_dat2(n_start:n_stop), n_ave=n_ave, $
              npts=npts, sample = dt(i), coh, phase, freq, $
              /overlap
        endelse
        coh_dat(nfft,*) = coh
        phase_dat(nfft,*) = phase
        time(nfft) = dat1.time((n_start+n_stop)/2)
        nfft = nfft + 1l
        n_start = n_start + long(ntot*slide)
        n_stop = n_start + ntot - 1l  
    ENDWHILE
    
; *** Put in case for change of dt here. ***

    norm_dt = median(dt)
    abnorm = where(dt ne norm_dt)
    
ENDFOR

add_str_element, result, 'TIME', time(0:nfft-1)
add_str_element, result, 'YAXIS', freq/1000
add_str_element, result, 'COMP1', coh_dat(0:nfft-1,*)
add_str_element, result, 'COMP2', phase_dat(0:nfft-1,*)
add_str_element, result, 'SIZE', size(result.comp1)

if keyword_set(store) or keyword_set(nodata) then begin 
    store_data,'Coherence', data={x:result.time, $
                                  y:result.comp1, $
                                  v:result.yaxis, $
                                  spec:1}
    store_data,'Phase', data = {x:result.time, $
                                y:result.comp2, $
                                v:result.yaxis, $
                                spec:1}
    options,'Coherence','ystyle',1
    options,'Coherence','zrange',[0,1]
    options,'Coherence','ztitle','Coherence'
    options,'Coherence','ytitle','Frequency (kHz)'
    options,'Phase','ystyle',1
    options,'Phase','ztitle','Phase (rad)'
    options,'Phase','ytitle','Frequency (kHz)'
endif

if keyword_set(store) then begin
    return,'Cross Spec'    
endif else return, result

END
