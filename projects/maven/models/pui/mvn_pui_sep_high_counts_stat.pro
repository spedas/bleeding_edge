;20161116 Ali
;calculates and plots statistics for SEP high count rates
;uses output of the mvn_pui_sep_high_counts_load

pro mvn_pui_sep_high_counts_stat,poshist2d
restore

sephc=reform(data.sephc)
index1=where(sephc gt 0,count)
;index1=where(data.nsw ne 0,count)
data1=data[index1]

nsw=data1.nsw
vsw=transpose(data1.vsw)
mag=transpose(data1.mag)
pos=transpose(data1.pos)

usw=sqrt(total(vsw^2,2))
btot=sqrt(total(mag^2,2))

emotx=vsw[*,2]*mag[*,1]-vsw[*,1]*mag[*,2] ;Ex (km/s * nT)
emoty=vsw[*,0]*mag[*,2]-vsw[*,2]*mag[*,0] ;Ey (km/s * nT)
emotz=vsw[*,1]*mag[*,0]-vsw[*,0]*mag[*,1] ;Ez (km/s * nT)

emot=sqrt(emotx^2+emoty^2+emotz^2)

edotp=emoty*pos[*,1]+emotz*pos[*,2] ;E.P neglecting Ex, used to determine E hemisphere

;index1=where((sephc eq 20) or (sephc eq 24),count)
;index1=where(sephc gt -1) ;everything!
;index2=where(sephc[index1] lt 16) ;where Emotz is negative
index2=where(edotp lt 0,count2) ;where E.P is negative


;t0=time_double('14-12-1') ;start time
;times=dindgen(1350*711l,start=t0+32.,inc=64.) ;all times

;tcount=times[index1] ;times for sep high counts

;pos=transpose(spice_body_pos('MAVEN','MARS',frame='MSO',utc=tcount)) ;MAVEN position MSO (km)
;pos=transpose(spice_body_pos('MAVEN','MARS',frame='MSO',utc=times)) ;MAVEN position MSO (km)

rmars=3400. ;Mars radius (km)
posx=pos[*,0]/rmars
posy=pos[*,1]/rmars
posz=pos[*,2]/rmars

;p=plot3d(posx,posy,posz,'o',xtitle='x',ytitle='y',ztitle='z')

posr=sqrt(posy^2+posz^2) ;cylindrical radial distance
;posr(where(posz lt 0))*=-1;
posr(index2)*=-1 ;mirror those that have positive Emotz

if ~keyword_set (poshist2d) then poshist2d=hist_2d(posx,posr,bin1=.1,bin2=.1,min1=-3.,max1=3.,min2=-3.,max2=3.)
imx=.1*findgen(61)-3.
imy=.1*findgen(61)-3.

;g=image(poshist2d,imx,imy,rgb_table=colortable(0,/reverse),axis_style=2,margin=.2)
;c=colorbar(target=g,/orientation)
;mvn_pui_plot_mars_bow_shock
;p=plot(/o,posx,posr,'.')
hist=histogram(emot,binsize=100,locations=locations)
p=plot(1e-3*locations,float(hist)/float(count),/stair,/o,xtitle='Motional Electric Field (V/km)',xrange=[0,10],'r')
stop
end