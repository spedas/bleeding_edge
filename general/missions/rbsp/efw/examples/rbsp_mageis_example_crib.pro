; RBSP MagEIS example crib

probe='a'

timespan,'2013-02-17',1

rbsp_load_mageis_l2,probe=probe,/get_mag_ephem

tplot,'*FEDO'

; switch to line plots
options,'*FEDO','spec',0
ylim,'*FEDO',1,2.e7,1
options,'*FEDO',ysubtitle='[cm!U-2!N s!U-1!N keV!U-1!N]'
options,'*FEDO','labflag',-1

tplot,'*FEDO'

; switch back to spec
options,'*FEDO','spec',1
ylim,'*FEDO',20,4000,1
zlim,'*FEDO',1,2.e7,1
options,'*FEDO',ztitle='[cm!U-2!N s!U-1!N keV!U-1!N]'
options,'*FEDO',ysubtitle='Energy [keV]'

tplot,'*FEDO'


end