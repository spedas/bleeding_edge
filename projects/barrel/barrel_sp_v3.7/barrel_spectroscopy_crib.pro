pro barrel_spectroscopy_crib

;Examples of how to use the master spectroscopy routine for different
;options as to:
;1) Slow vs. medium spectrum
;2) Method of selecting time intervals (by hand or graphically)
;3) Method of subtracting background (model vs. time intervals)
;4) Fitting function (exp,mono,file(s)) 

;Using bkg time intervals.
;Using exponential spectrum (default method=1, model=1).
;Using slow (32s) spectra (/slow flag = 1 as default))
barrel_spectroscopy,spectest1,'2013-01-17/00:50:00',9.,'1G',/slow,$
  numbkg=2,fitrange=[80.,2500.],saveme='spectest1.sav',systematic_error_frac=0.1

;Specify src and bkg time intervals by hand (currently both must be
;done the same way):
barrel_spectroscopy,spectest1,'2013-01-17/00:50:00',9.,'1G',/slow,$
  numbkg=2,fitrange=[80.,2500.],starttimes='2013-01-17/02:40:00',$
  endtimes='2013-01-17/03:15:00',$
  startbkgs=['2013-01-17/01:20:00','2013-01-17/07:00:00'],$
  endbkgs=['2013-01-17/02:00:00','2013-01-17/09:00:00'],$
  saveme='spectest2.sav',systematic_error_frac=0.1

;Switch to background model instead:
barrel_spectroscopy,spectest1,'2013-01-17/00:50:00',9.,'1G',/slow,$
  bkgmethod=2,fitrange=[80.,2500.],saveme='spectest3.sav',systematic_error_frac=0.1

;Using medium (4s) spectra and background model, with source time
;interval prespecified, and default fit range:
barrel_spectroscopy,spectest1,'2013-01-17/00:50:00',9.,'1G',$
  bkgmethod=2,starttimes='2013-01-17/02:40:00',$
  endtimes='2013-01-17/03:15:00',$
  saveme='spectest4.sav',systematic_error_frac=0.1

;Now use spectrum from file "sample_spec_bpl.txt", broken power law (method=2):
barrel_spectroscopy,spectest1,'2013-01-17/00:50:00',9.,'1G',$
  bkgmethod=2,method=2,modlfile='sample_spec_bpl.txt',$
  starttimes='2013-01-17/02:40:00',$
  endtimes='2013-01-17/03:15:00',$
  saveme='spectest5.sav',systematic_error_frac=0.1

;Now use spectra from two files to be fit as combination (method3):
barrel_spectroscopy,spectest1,'2013-01-17/00:50:00',9.,'1G',$
  bkgmethod=2,method=3,modlfile='sample_spec_gau.txt',$
  secondmodlfile='sample_spec_gau2.txt',$
  starttimes='2013-01-17/02:40:00',$
  endtimes='2013-01-17/03:15:00',$
  saveme='spectest6.sav',systematic_error_frac=0.1

;a softer time interval (must use slow spectra to capture it!):
barrel_spectroscopy,spectest1,'2013-01-15/05:00:00',5.,'1G',/slow,$
   numbkg=1,fitrange=[60.,2500.],saveme='spectest7.sav',systematic_error_frac=0.1

end
