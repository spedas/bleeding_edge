;+
;  thm_fft_freq_bins
;-
;+
;	Procedure:
;		thm_fft_freq_bins
;
;	Purpose:
;		Given the sampling rate and number of bins, return the center frequencies
;	of the FFT spectral estimate bins.
;
;	Calling Sequence:
;	thm_fft_freq_bins, rate=rate, nbins=nbins, cent_freq=cent_freq

;	Arguements:
;		rate	STRING, '8k' or '16k', indicating that the source sampling rate is 8192 or 16384 samp/s.
;		nbins	INT, 16, 32, or 64; number of frequency bins in the FFT spectral estimate.
;
;	Outputs:
;		cent_freq	FLOAT[ nbins], center frequencies of bins in Hz.
;
;	Notes:
;	-- none.
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2012-01-26 16:43:03 -0800 (Thu, 26 Jan 2012) $
; $LastChangedRevision: 9624 $
; $URL $
;-

pro thm_fft_freq_bins, rate=rate, nbins=nbins, cent_freq=cent_freq

;
; 16384 samp/s FFT table, 2048-pt FFT, 64 bins.

fft_16k_64bin_start_freq = [ $
	-4., 4., 12., 20., 28., 36., 44., 52., $
	60.,	68.,	76.,	84.,	92.,	100., 108., 116., $
	124.,	140.,	156.,	172.,	188.,	204.,	220.,	236., $
	252.,	284.,	316.,	348.,	380.,	412.,	444.,	476., $
	508.,	572.,	636.,	700.,	764.,	828.,	892.,	956., $
	1020.,	1148.,	1276.,	1404.,	1532.,	1660.,	1788.,	1916., $
	2044.,	2300.,	2556.,	2812.,	3068.,	3324.,	3580.,	3836., $
	4092.,	4604.,	5116.,	5628.,	6140.,	6652.,	7164.,	7676. ]

fft_16k_64bin_df = fft_16k_64bin_start_freq[ 1:*] - fft_16k_64bin_start_freq[ 0:*]
fft_16k_64bin_df = [ fft_16k_64bin_df, fft_16k_64bin_df[ 62L]]
fft_16k_64bin_cent_freq = fft_16k_64bin_start_freq + 0.5*fft_16k_64bin_df


; 8192 samp/s., FFT table, 1024-pt FFT, 64 bins.
fft_8k_64bin_start_freq = [ $
	 -4.,	4.,	12.,	20.,	28.,	36.,	44.,	52., $
	60.,	68.,	76.,	84.,	92.,	100.,	108.,	116., $
	124.,	132.,	140.,	148.,	156.,	164.,	172.,	180., $
	188.,	196.,	204.,	212.,	220.,	228.,	236.,	244., $
	252.,	284.,	316.,	348.,	380.,	412.,	444.,	476., $
	508.,	572.,	636.,	700.,	764.,	828.,	892.,	956., $
	1020.,	1148.,	1276.,	1404.,	1532.,	1660.,	1788.,	1916., $
	2044.,	2300.,	2556.,	2812.,	3068.,	3324.,	3580.,	3836. ]
fft_8k_64bin_df = fft_8k_64bin_start_freq[ 1:*] - fft_8k_64bin_start_freq[ 0:*]
fft_8k_64bin_df = [ fft_8k_64bin_df, fft_8k_64bin_df[ 62L]]
fft_8k_64bin_cent_freq = fft_8k_64bin_start_freq + 0.5*fft_8k_64bin_df


; 16384 samp/s FFT table, 2048-Point, 32 bins.
fft_16k_32bin_start_freq = [ -4.,	12.,	28.,	44., $
	60.,	76.,	92.,	108., $
	124.,	156.,	188.,	220., $
	252.,	316.,	380.,	444., $
	508.,	636.,	764.,	892., $
	1020.,	1276.,	1532.,	1788., $
	2044.,	2556.,	3068.,	3580., $
	4092.,	5116.,	6140.,	7164. ]
fft_16k_32bin_df = fft_16k_32bin_start_freq[ 1:*] - fft_16k_32bin_start_freq[ 0:*]
fft_16k_32bin_df = [ fft_16k_32bin_df, fft_16k_32bin_df[ 30L]]
fft_16k_32bin_cent_freq = fft_16k_32bin_start_freq + 0.5*fft_16k_32bin_df


; 8192 samp/s FFT table: 1024 point, 32 bins.
fft_8k_32bin_start_freq = [ -4.,	12.,	28.,	44., $
	60.,	76.,	92.,	108., $
	124.,	140.,	156.,	172., $
	188.,	204.,	220.,	236., $
	252.,	316.,	380.,	444., $
	508.,	636.,	764.,	892., $
	1020.,	1276.,	1532.,	1788., $
	2044.,	2556.,	3068.,	3580. ]
fft_8k_32bin_df = fft_8k_32bin_start_freq[ 1:*] - fft_8k_32bin_start_freq[ 0:*]
fft_8k_32bin_df = [ fft_8k_32bin_df, fft_8k_32bin_df[ 30L]]
fft_8k_32bin_cent_freq = fft_8k_32bin_start_freq + 0.5*fft_8k_32bin_df

; 16 ks/s FFT table: 2048 Point, 16 bins.
fft_16k_16bin_start_freq = [ -4.,	28., $
	60.,	92., $
	124.,	188., $
	252.,	380., $
	508.,	764., $
	1020.,	1532., $
	2044.,	3068., $
	4092.,	6140. ]
fft_16k_16bin_df = fft_16k_16bin_start_freq[ 1:*] - fft_16k_16bin_start_freq[ 0:*]
fft_16k_16bin_df = [ fft_16k_16bin_df, fft_16k_16bin_df[ 14L]]
fft_16k_16bin_cent_freq = fft_16k_16bin_start_freq + 0.5*fft_16k_16bin_df

; 8 ks/s FFT table: 1024 point, 16 bins.
fft_8k_16bin_start_freq = [ -4.,	28., $
	60.,	92., $
	124.,	156., $
	188.,	220., $
	252.,	380., $
	508.,	764., $
	1020.,	1532., $
	2044.,	3068. ]
fft_8k_16bin_df = fft_8k_16bin_start_freq[ 1:*] - fft_8k_16bin_start_freq[ 0:*]
fft_8k_16bin_df = [ fft_8k_16bin_df, fft_8k_16bin_df[ 14L]]
fft_8k_16bin_cent_freq = fft_8k_16bin_start_freq + 0.5*fft_8k_16bin_df

fft_cent_freq = { $
	fft_16k:{ nf16:fft_16k_16bin_cent_freq, nf32:fft_16k_32bin_cent_freq, nf64:fft_16k_64bin_cent_freq}, $
	fft_8k:{ nf16:fft_8k_16bin_cent_freq, nf32:fft_8k_32bin_cent_freq, nf64:fft_8k_64bin_cent_freq} }

case strupcase( rate) of
	'16K':	r = 0
	'8K':	r = 1
	else:	begin
		dprint, string( rate, format='("invalid rate string,",A)')
		cent_freq = !values.f_nan
		return
	end
endcase

case nbins of
	16:	b = 0
	32:	b = 1
	64:	b = 2
	else:	begin
		dprint, string( nbins, format='("invalid nbins value,",I)')
		cent_freq = !values.f_nan
		return
	end
endcase

cent_freq = fft_cent_freq.(r).(b)

return
end
