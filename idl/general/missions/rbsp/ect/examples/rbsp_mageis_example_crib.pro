; RBSP MagEIS example crib

probe='a b'

timespan,'2012-11-11',1

rbsp_load_mageis_l2,probe=probe,/get_mag_ephem

;'*FESA': electron differential fluxes averaged over one spin.
;'*FPSA':ion differential fluxes averaged over one spin.
tplot,'*FESA'

; switch to line plots
options,'*FESA','spec',0
ylim,'*FESA',1,2.e7,1
options,'*FESA',ysubtitle='[cm!U-2!N s!U-1!N keV!U-1!N]'
options,'*FESA','labflag',-1

tplot,'*FESA'

; switch back to spec
options,'*FESA','spec',1
ylim,'*FESA',20,4000,1
zlim,'*FESA',1,2.e7,1
options,'*FESA',ztitle='[cm!U-2!N s!U-1!N keV!U-1!N]'
options,'*FESA',ysubtitle='Energy [keV]'

tplot,'*FESA'

end