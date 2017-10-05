;Downsample tplot quantities
;
;
;tname = name of tplot quantity. Can be a size [n] or [n,x]
;sr = new sample rate (S/sec)
;nochange - set if you'd like to overwrite the original tplot variable name
;			Otherwise newname = oldname + '_DS'
;suffix = appended to end of tname. Defaults to 'tname_DS'
;
;win -> apply a hanning window
;ptswin -> number of points on edge of plot for hanning window to go from zero
;			to unity (see hanning_stretch.pro)
;
;Created by Aaron Breneman  10-29-2012
;	Modified: 2012-12-11 : Added anti-aliasing filter
;			  2012-12-14 : Added zero-padding. Greatly improves performance



pro rbsp_downsample,tnames,sr,nochange=nochange,suffix=suffix,win=win,ptswin=ptswin

if ~keyword_set(suffix) then suffix = '_DS'
if ~keyword_set(sr) then sr=1
if ~keyword_set(ptswin) then ptswin = 100.


tn = tnames(tnames)

for j=0,n_elements(tn)-1 do begin


	get_data,tn[j],data=dat,dlimits=dlim,limits=lim
	
	if is_struct(dat) then begin



		;window data
;		if keyword_set(win) then begin
;			han = hanning_stretch(n_elements(dat.x),ptswin)
;;			store_data,'han',data={x:dat.x,y:han}
;;			store_data,'times',data={x:dat.x,y:dat.x-dat.x[0]}
;			dat.y = dat.y * han
;		endif

		;get new times at cadence of "sr"		
		t0 = min(dat.x)
		t1 = max(dat.x)
		newt = dindgen((t1-t0)*sr)/sr + t0
	
		;Test to see if variable is a [n] or [n,x] element array
		tst = size(dat.y,/n_dimensions)
		tst2 = size(dat.y,/dimensions)


		;new Nyquist freq after downsampling will be:
		nyq_new = sr/2.

		;time b/t samples
		dt = dat.x[1]-dat.x[0]


		N = n_elements(dat.x)
		num = lindgen(n_elements(dat.x)/2.)

		;Current range of frequencies in signal is:			
		fcurrent = num/(N*dt)

		;Freqs that will result in aliasing
		badfreqs = where(fcurrent gt nyq_new)
		;Negative freqs that will result in aliasing
		badfreqs_n = reverse(N/2-badfreqs) + N/2


		;Stuff for zero-padding. Greatly speeds up the FFT
		factor = alog(N)/alog(2)
		n_pad_factor = floor(2d^(ceil(factor))) - N
		zero_arr = replicate(0,n_pad_factor)


		if tst eq 1 then begin
		
			;zero pad
			dat_tmp = [dat.y,zero_arr]

		
			;Bandpass original signal to keep freqs only at or below
			;this new Nyquist freq
						
			tmp = fft(dat_tmp)


			;Remove positive freqs that will be aliased
			if badfreqs[0] ne -1 then tmp[badfreqs] = 0.
			
			;Remove negative freqs that will be aliased			
			if badfreqs[0] ne -1 then tmp[badfreqs_n] = 0.


			newsignal = real_part(fft(tmp,1))
			newsignal = newsignal[0:n_elements(newsignal)-n_pad_factor-1]
		
				
			;Interpolate to lower sample rate
			dat2 = interpol(newsignal,dat.x,newt)
		
		
		endif

		


		
		if tst gt 1 then begin					

			dat2 = reform(dblarr(n_elements(newt),tst2[1]))	
			win = hanning(n_elements(dat.x))

			for b=0,tst2[1]-1 do begin


				;zero pad		
				dat_tmp = [dat.y[*,b],zero_arr]


				;Bandpass original signal to keep freqs only at or below
				;this new Nyquist freq
		
				tmp = fft(dat_tmp)
	
	
				;Remove positive freqs that will be aliased
				if badfreqs[0] ne -1 then tmp[badfreqs] = 0.

				;Remove negative freqs that will be aliased			
				if badfreqs[0] ne -1 then tmp[badfreqs_n] = 0.


				newsignal = real_part(fft(tmp,1))
				newsignal = newsignal[0:n_elements(newsignal)-n_pad_factor-1]

				;Interpolate to lower sample rate
				dat2[*,b] = interpol(newsignal,dat.x,newt)
		

			endfor
		endif	
		
		

		
		if ~keyword_set(nochange) then store_data,tn[j]+suffix,data={x:newt,y:dat2},dlimits=dlim,limits=lim $
		else store_data,tn[j],data={x:newt,y:dat2},dlimits=dlim,limits=lim
		
	endif

endfor


end

