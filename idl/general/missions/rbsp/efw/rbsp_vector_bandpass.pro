;+
;*****************************************************************************************
;
;  FUNCTION :   vector_bandpass.pro
;  PURPOSE  :   This program does a bandpass filter on the input data using IDL's
;                 built-in FFT.PRO routine.  The data is first padded with zeroes
;                 to ensure the number of elements remains an integer power of 2.
;                 The user defines the input vector array of data, the sample rate, 
;                 and frequency range(s) before running the program, then tells the 
;                 program whether a low-pass (i.e. only return low frequency 
;                 signals), high-pass, or middle frequency bandpass filter.  The 
;                 program eliminates the postitive AND negative frequency bins in 
;                 frequency space to ensure symmetry before performing the inverse 
;                 FFT on the data.
;
;  CALLED BY:   NA
;
;  CALLS: 
;               power_of_2.pro
;
;  REQUIRES:    NA
;
;  INPUT:
;               DAT    :  [N,3]-Array of magnetic or electric field data
;               SR     :  Scalar defining the sample rate (mHz, Hz, kHz, etc. doesn't
;                           matter as long as everything is consistent)
;               LF     :  Scalar defining the low frequency cutoff (Default = 0)
;                          [Note:  MUST be same units as SR]
;               HF     :  Scalar defining the high frequency cutoff (Default = Nyquist)
;                          [Note:  MUST have same units as SR AND LF]
;
;  EXAMPLES: 
;                 htr_mfi2tplot,DATE=date
;                 get_data,'WIND_B3_HTR(GSE,nT)',DATA=mag
;                 magf  = mag.Y
;                 tt    = mag.X                        ; -Unix time (s since 01/01/1970)
;                 nt    = N_ELEMENTS(tx)
;                 evl   = MAX(tt,/NAN) - MIN(tt,/NAN)  ; -Event length (s)
;                 nsps  = ((nt - 1L)/evl)              ; -Approx Sample Rate (Hz)
;                 lfmf1 = vector_bandpass(magf,nsps,15d-2,15d-1,/LOWF)
;
;  KEYWORDS:  
;               LOWF   :  If set, program returns low-pass filtered data with freqs
;                           below LF
;               MIDF   :  If set, program returns bandpass filtered data with freqs
;                           between LF and HF  **[Default]**
;               HIGHF  :  If set, program returns high-pass filtered data with freqs
;                           above HF
;
;   CHANGED:  1)  Fixed Low Freq. bandpass to get rid of artificial 
;                   zero frequency bin created by FFT calc.  [01/14/2009   v1.0.1]
;             2)  Fixed case where NaN's are in data         [01/18/2009   v1.0.2]
;             3)  Changed program my_power_of_2.pro to power_of_2.pro
;                   and renamed                              [08/10/2009   v2.0.0]
;
;   CREATED:  12/30/2009
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/10/2009   v2.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION rbsp_vector_bandpass,dat,srt,lf,hf,LOWF=lowf,MIDF=midf,HIGHF=highf

d   = REFORM(dat)
no  = N_ELEMENTS(d[*,0])
;-----------------------------------------------------------------------------------------
; -Get rid of any NaN's so FFT can actually work
;-----------------------------------------------------------------------------------------
bbx = WHERE(FINITE(d[*,0]) EQ 0,bx,COMPLEMENT=ggx)
bby = WHERE(FINITE(d[*,1]) EQ 0,by,COMPLEMENT=ggy)
bbz = WHERE(FINITE(d[*,2]) EQ 0,bz,COMPLEMENT=ggz)
IF (bx GT 0L) THEN d[bbx,0] = 0d0
IF (by GT 0L) THEN d[bby,1] = 0d0
IF (bz GT 0L) THEN d[bbz,2] = 0d0
;-----------------------------------------------------------------------------------------
; -Pad data with zeros to change no => 2^m  {m = integer}
;-----------------------------------------------------------------------------------------
d2x = power_of_2(d[*,0])
d2y = power_of_2(d[*,1])
d2z = power_of_2(d[*,2])
d2  = [[d2x],[d2y],[d2z]]
nd  = N_ELEMENTS(d2x)
n_m = nd/2L + 1L  ; -mid point element
;-----------------------------------------------------------------------------------------
; -Calc FFT frequencies
;-----------------------------------------------------------------------------------------
sr             = srt*1d0
frn            = nd - n_m
frel           = LINDGEN(frn) + n_m   ; -Elements for negative frequencies
fft_freq       = LINDGEN(nd)
fft_freq[frel] = (n_m - nd) + DINDGEN(n_m - 2L)
fft_freq       = fft_freq*(sr/nd)
;-----------------------------------------------------------------------------------------
; -Determine relevant elements of FFT arrays
;-----------------------------------------------------------------------------------------
lfc1   = lf*1d0
hfc1   = hf*1d0

lowf1  = WHERE(ABS(fft_freq) LE lfc1 AND ABS(fft_freq) GT 0d0,lf1,COMPLEMENT=other_mh)
midf1  = WHERE(ABS(fft_freq) GT lfc1 AND ABS(fft_freq) LE hfc1,mf1,COMPLEMENT=other_lh)
highf1 = WHERE(ABS(fft_freq) GT hfc1,hf1,COMPLEMENT=other_lm)

IF KEYWORD_SET(lowf) THEN lowf1 = 1 ELSE lowf1 = 0
IF KEYWORD_SET(midf) THEN midf1 = 1 ELSE midf1 = 0
IF KEYWORD_SET(highf) THEN highf1 = 1 ELSE highf1 = 0

check  = [KEYWORD_SET(lowf1),KEYWORD_SET(midf1),KEYWORD_SET(highf1)]
gcheck = WHERE(check GT 0,gch,COMPLEMENT=bcheck,NCOMPLEMENT=bch)

gelems = {T0:other_mh,T1:other_lh,T2:other_lm}
IF (gch EQ 1L) THEN BEGIN
  other = gelems.(gcheck[0])
ENDIF ELSE BEGIN ; -Default setting b/c user entered too many keywords
  other = other_lh
ENDELSE

;-----------------------------------------------------------------------------------------
; -Window data
;-----------------------------------------------------------------------------------------

window = hanning_stretch(n_elements(d2x),n_elements(d2x)/8L-2L)


;-----------------------------------------------------------------------------------------
; -Calc FFT
;-----------------------------------------------------------------------------------------
tempx = FFT(window*d2x,/DOUBLE)
tempy = FFT(window*d2y,/DOUBLE)
tempz = FFT(window*d2z,/DOUBLE)

templx = tempx
temply = tempy
templz = tempz
;-----------------------------------------------------------------------------------------
; -Get rid of unwanted frequencies
;-----------------------------------------------------------------------------------------
templx[other]  = DCOMPLEX(0d0)  ; -Get rid of unwanted frequencies [mid and high]
temply[other]  = DCOMPLEX(0d0)
templz[other]  = DCOMPLEX(0d0)
;-----------------------------------------------------------------------------------------
; -Calc Inverse FFT
;-----------------------------------------------------------------------------------------
rplx = REAL_PART(FFT(templx,1,/DOUBLE))
rply = REAL_PART(FFT(temply,1,/DOUBLE))
rplz = REAL_PART(FFT(templz,1,/DOUBLE))
;-----------------------------------------------------------------------------------------
; -Keep only useful data [i.e. get rid of the zero-padded elements]
;-----------------------------------------------------------------------------------------
filtered = [[rplx[0:(no-1L)]],[rply[0:(no-1L)]],[rplz[0:(no-1L)]]]
IF (bx GT 0L) THEN filtered[bbx,0] = !VALUES.D_NAN
IF (by GT 0L) THEN filtered[bby,1] = !VALUES.D_NAN
IF (bz GT 0L) THEN filtered[bbz,2] = !VALUES.D_NAN

RETURN,filtered
END
