;
;+
; NAME:
;
;       FFT_CONVOLUTION
;
; PURPOSE:
;
;		Computes the convolution of two or many 1D to 3D arrays by using the FFT.
;
; DESCRIPTION:
;
;		This function computes in one time the convolution of an array with
;		one or more convolution kernels, e.g. F*K1*K2*...Kn.
;		1 dimensional to 3 dimensional arrays are supported.
;
; CATEGORY:
;
;       Mathematics.
;
; CALLING SEQUENCE:
;
;		Result = FFT_CONVOLUTION(array, kernel, /DOUBLE)
;
; INPUTS:
;
;		Array: 1-D to 3-D array to be convolved.
;
;		Kernel: 1-D to 3-D array to be used as convolution kernel.
;				Kernel Must have the SAME SIZE as Array.
;				For multiple convolutions Kernel must have the dimension of Array + 1 and
;				must have one convolution kernel for each element of the Last dimension:
;				e.g.: for F(x,y)*K1(x,y)*K2(x,y) where F is of LX*LY size the kernel is
;				an array of [LX, LY, 2] in size.
;				The Kernel is always centered on the Array points to make convolution.
;
; KEYWORD PARAMETERS:
;
;		DOUBLE: if set uses the double precision for the FFT.
;
; MODIFICATION HISTORY:
;
;       Feb 2004 - 	Gianluca Li Causi & Massimo De Luca, INAF - Rome Astronomical Observatory
;					licausi@mporzio.astro.it
;					http://www.mporzio.astro.it/~licausi/
;
;-

FUNCTION FFT_Convolution, array_in, kernel_in, double=double

array = reform(array_in)
sa = size(array)
dim_array = sa[0]

IF dim_array GT 3 THEN Message, 'This routine only works with 1-D to 3-D arrays!'

kernel = reform(kernel_in)
sk = size(kernel)
dim_kernel = sk[0]

IF dim_kernel LT dim_array THEN Message, 'Kernel must have at least the dimension of the Array!'
IF dim_kernel GT (dim_array+1) THEN Message, 'Kernel must have no more than the dimension of the Array plus 1!'

IF dim_kernel EQ (dim_array+1) THEN nker = sk[dim_kernel] ELSE nker = 1


;Fourier transform:
result_fft = FFT(array, -1, double=double)
FOR i = 0, nker - 1 DO BEGIN
	CASE dim_array OF
		1: kernel_fft = FFT(kernel[*,i], -1, double=double)
		2: kernel_fft = FFT(kernel[*,*,i], -1, double=double)
		3: kernel_fft = FFT(kernel[*,*,*,i], -1, double=double)
	ENDCASE
	result_fft = result_fft * kernel_fft
ENDFOR

;Inverse Fourier transform:
result =  FLOAT(FFT(result_fft, 1, double=double)) * FLOAT(n_elements(kernel)/nker)^nker  ;the last term is required to keep the flux

;The convolved array must be shifted by (-sk[*] / 2 * nker) because of FFT definition:
CASE dim_array OF
	1: result = SHIFT(result, -sk[1]/2 * nker)
	2: result = SHIFT(result, -sk[1]/2 * nker, -sk[2]/2 * nker)
	3: result = SHIFT(result, -sk[1]/2 * nker, -sk[2]/2 * nker, -sk[3]/2 * nker)
ENDCASE


RETURN, result

END