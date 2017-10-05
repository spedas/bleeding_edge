;+
; NAME:
;     CONVOLVE_GAUSSIAN_1D
;
; PURPOSE:
; Routine convolves scalar or vector field to a given resolution
; with a Gaussian kernel
;
; CATEGORY:
; Data Processing
;
; CALLING SEQUENCE:
; convolve_gaussian_1d,resol,tarr,varrin,varrout
;
; INPUTS:
; resol - desired time resolution in seconds
; tarr - time array (1D, double, seconds)
; varrin - input field - 1D or mD array (ntimepoints,m)
;
; KEYWORDS: none
;
; PARAMETERS:   eps - truncate Gaussian at this height
;     ni - initial length of transform is 2^ni (adjusted depending on data)
;     ndump - initial length of leakage-dumping tail (adjusted by code)
;
; OUTPUTS:
; varrout - output array of the same dimensions that varrin
;
; DEPENDENCIES: None - can be used alone.
;
; MODIFICATION HISTORY:
; Written by: Vladimir Kondratovich 2008/10/10.
;-
;
; THE CODE BEGINS:

pro convolve_gaussian_1d,resol,tarr,varrin,varrout
pi=3.14159265358D
eps=0.0001
ni=4
ndump=10

hw=0.5*resol

ntin=n_elements(tarr)
trel=tarr-tarr(0)
lhst=-0.5*(trel/hw)^2
rhst=alog(sqrt(2*pi)*hw*eps)
ind=where(lhst ge rhst,nbgauss)

if nbgauss lt ntin then begin
   svin=size(varrin)
   ndim=svin(0)
   if ndim eq 1 then begin
      nvec=1
      secdim=n_elements(varrin)
   endif else begin
      nvec=svin(2)
      secdim=svin(1)
   endelse
   nin=secdim
   if nin ne ntin then begin
      print,'Error: Lengths of time array and signal array differ. gaussconv exits.'
      return
   endif
   varrout=fltarr(secdim,nvec)
   for i=0,nvec-1 do begin
      if nvec eq 1 then varrinn=varrin else varrinn=reform(varrin(*,i))
      nadd=nbgauss
      vaddr=fltarr(nadd)+varrinn(nin-1)
      vaddl=fltarr(nadd)+varrinn(0)
      nwork=nin+2*nadd+ndump+0L
   
      n=ni
      while 2.D^n lt nwork do n=n+1
      ntot=long(round(2.D^n))
      ndumpeff=ntot-nin-2*nadd
      vdumpeff=varrinn(nin-1)+(varrinn(0)-varrinn(nin-1))*(lindgen(ndumpeff)+1.D)/(ndumpeff+1.D)
      vtofft=[varrinn,vaddr,vdumpeff,reverse(vaddl)]

      tmax=trel(ntin-1)
      delavt=tmax/(ntin-1.)
      delnu=1./(delavt*ntot)
      coeff=2*(pi*hw*delnu)^2
      harm=dindgen(ntot)

      fft1=FFT(vtofft,/DOUBLE)
      fft2=EXP(-coeff*harm^2)>EXP(-coeff*(ntot-harm)^2)
      fcon=fft1*fft2
      con=FFT(fcon,/INVERSE)
      vcon=DOUBLE(con(0:nin-1))
      if nvec eq 1 then varrout=vcon else varrout(*,i)=vcon
   endfor
endif else begin
   print,'Bell curve is broader than the signal base.'
   print,'The meaning of convolution is unclear in this case.'
   print,'gaussconv quits, convolution aborted.'
   varrout=varrin
   return
endelse

end
