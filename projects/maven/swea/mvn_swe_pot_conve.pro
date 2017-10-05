;+
;PROCEDURE:
;   mvn_swe_pot_conve
;
;PURPOSE:
;   correct for potential and then convert to SWEA original resolution
;
;AUTHOR:
;   Shaosui Xu
;
;CALLING SEQUENCE:
;   
;
;INPUTS:
;   
;   INEN: The energy array corresponding to the input energy spectrum
;   
;   INSPEC: Input electron energy spectrum
;   
;   
;   POT: Specify the potential to be corrected
;
;KEYWORDS:
;
;   none
;
;OUTPUTS:
;
;   OUTEN: The energy array corresponding to the input energy spectrum, 
;          currently set to be SWEA energy resolution
;         
;   OUTSPEC: The converted energy spectrum
;
; $LastChangedBy: xussui_lap $
; $LastChangedDate: 2016-06-22 17:23:44 -0700 (Wed, 22 Jun 2016) $
; $LastChangedRevision: 21353 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_pot_conve.pro $
;
;CREATED BY:    Shaosui Xu  06-22-16
;-

Pro mvn_swe_pot_conve, inEn, inspec, outEn, outspec, pot
    ; correct for potential and then convert to SWEA original resolution

    outEn=[4627.50,4118.51,3665.50,3262.32,2903.48,2584.12,2299.88,2046.91,1821.77,1621.38,1443.04,$
        1284.32,1143.05,1017.32,905.424,805.833,717.197,638.310,568.100,505.613,449.999,400.502,$
        356.449,317.242,282.348,251.291,223.651,199.051,177.157,157.671,140.328,124.893,111.155,$
        98.9290,88.0475,78.3628,69.7435,62.0721,55.2446,49.1681,43.7599,38.9466,34.6627,30.8501,$
        27.4568,24.4367,21.7488,19.3566,17.2275,15.3326,13.6461,12.1451,10.8092,9.62030,8.56213,$
        7.62036,6.78217,6.03617,5.37223,4.78132,4.25541,3.78734,3.37076,3.00000]
    outEn=double(outEn)
    nOE=n_elements(outEn)
    outspec = fltarr(nOE)

    ;oversampling the input spectra
    emax=max(inEn,min=emin)
    emax=30
    indxe = where(inEn ge emax,complement=inc,cts)
    dE=0.25 & Nee=(emax-emin)/dE
    Elow=emax-findgen(Nee+1)*dE
    inflx1=10^(interpol(alog10(inspec[inc]),inEn[inc],Elow))
    Etemp = [inEn[indxe],Elow]
    inflx = [inspec[indxe],inflx1]
    dee = Etemp
    dee[0:cts-1] = Etemp[0:cts-1]*0.167
    dee[cts:n_elements(Etemp)-1]=dE

    phase=inflx/(Etemp^2)
    Etemp=Etemp[*]-pot;?????????
    inE=where(Etemp ge 0,cts)
    Etemp=Etemp[inE]
    inflx=phase[inE]*Etemp^2

    fwhm=0.167/(2.*sqrt(2*alog(2)))

    for j=0, nOE-1 do begin
        nrm = exp(-0.5*((Etemp-outEn[j])/(fwhm*outEn[j]))^2)/(fwhm*outEn[j]*sqrt(2.*!pi))
        outspec[j] = total(inflx*nrm*dEE[inE])
        ;print,total(nrm*dE),outEn[j]
    endfor

    rev=0
    if rev eq 1 then begin
        phase=outspec[*]/outEn[*]^2
        Etemp=outEn[*]+pot
        outEn=Etemp
        outspec[*]=phase*Etemp^2
        inE=where(outEn ge 0)
        outEn=outEn[inE]
        outspec=outspec[inE]
    endif

    ;if n_elements(where(outspec eq outspec)) gt 10 and pot le -10 then stop
    return
end