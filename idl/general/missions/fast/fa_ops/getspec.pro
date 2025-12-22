;+
; NAME: GETSPEC
;
; PURPOSE: To compute some sort of frequency spectrum from a
;          uniformly sampled time series, after removing the mean
;          value and any linear trend. 
;
; CALLING SEQUENCE: getspec,t,x,f,s
; 
; INPUTS: T is an array of time tags for X. F is an array which, on
;         return, contains the frequencies corresponding to the
;         spectral estimates S. S has the same units as X by default,
;         this can be changed with keywords. 
;	
; KEYWORD PARAMETERS:
;   NOCONDITION: If set, prevents the removal of the mean and best
;                line from the time series data.
;
;       COMPLEX: If set, causes GETSPEC to return an S of type
;                complex, for use in cross-spectral analysis.  
;
;           PSD: If set, causes PWRSPC to return power spectral
;                density, i.e., the units of S will be [X]/sqrt(Hz).
;
;     NOHANNING: If set, prevents PWRSPC from applying a zero-tapering
;                window to the time series data. 
;
;       BINSIZE: If non-zero, causes PWRSPC to sum BINSIZE
;                near-neighbors of a preliminary spectrum into the
;                final spectrum S. This reduces the number of elements
;                of F and S, by a factor of approximately BINSIZE, and
;                also reduces the variance in the spectral estimates. 
;
; SIDE EFFECTS: PWRSPC is called, unless COMPLEX is set. 
;
; RESTRICTIONS: ??? don't know of any ???
;
; MODIFICATION HISTORY: slowly developed by Bill Peria, UCBerkeley
;                       Space Sciences Lab. This version
;                       released on 25-July-1996. 
;
;-
pro getspec, tp, xp, gnu, xs, nocondition=nocondition, complex = complex, $
             psd = psd, nohanning = nohanning,binsize = binsize

t = float(tp - tp(0))
x = xp
nx = n_elements(x)
nt = n_elements(t)
if (nx ne nt) then begin
    message,'data and time arrays must be the same length!',/continue
    return
endif


if not keyword_set(binsize) then begin
    bin = 1
endif else begin
    bin = binsize
endelse

if not(keyword_set(nocondition)) then begin
    mean = total(x)/float(nx)
    x = x - mean
    c = poly_fit(t,x,1,line,band,sigma)
    line = c(0) + c(1)*t
    if (sigma lt abs(line(nx-1)-line(0))) then begin ; it really looks
        x = x - line                                 ; like a line!
    endif
endif

if not (keyword_set(complex)) then begin
    pwrspc,t,x,gnu,xs,bin=bin,psd=psd,nohanning=nohanning
    xs = sqrt(xs)*sqrt(2.0)     ; convert power spectrum to amplitude
                                ; spectrum...
endif else begin
    nt = n_elements(t)
    bign = nt
    fbign = float(bign)
    k = [0,findgen(bign/2)+1]
    dt = float((t(bign-1)-t(0))/double(bign-1))
    fk = k/(bign*dt) 
    nfk = n_elements(fk)

    if not keyword_set(nohanning) then begin
        window = hanning(n_elements(x))
        xs = fft(x*window,1)
        wss = fbign*total(window^2)
        xs = fbign*xs/sqrt(wss)
    endif else begin
        xs = fft(x,1)
    endelse
    gnu = fk
    xs = xs(0:nfk-1)/fbign
endelse 

return
end




