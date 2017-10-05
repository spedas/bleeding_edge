;+
;Procedure:	thm_esa_slice2d
;
;Purpose:	creates a 2-D slice of the 3-D ESA ion or electron distribution function.
;
;Call:		thm_esa_slice2d,sc,typ,current_time,timeinterval,[keywords]

;Keywords:	SPECIES: 'ion' or 'ele'
;           ROTATION: suggesting the x and y axis, which can be specified as the followings:
;             'BV': the x axis is V_para (to the magnetic field) and the bulk velocity is in the x-y plane. (DEFAULT)
;             'BE': the x axis is V_para (to the magnetic field) and the VxB direction is in the x-y plane.
;             'xy': the x axis is V_x and the y axis is V_y.
;             'xz': the x axis is V_x and the y axis is V_z.
;             'yz': the x axis is V_y and the y axis is V_z.
;             'perp': the x-y plane is perpendicular to the B field, while the x axis is the velocity projection on the plane.
;             'perp_xy': the x-y plane is perpendicular to the B field, while the x axis is the x projection on the plane.
;             'perp_xz': the x-y plane is perpendicular to the B field, while the x axis is the x projection on the plane.
;             'perp_yz': the x-y plane is perpendicular to the B field, while the x axis is the y projection on the plane.
;           ANGLE: the lower and upper angle limits of the slice selected to plot (DEFAULT [-20,20]).
;           THIRDDIRLIM: the velocity limits of the slice. Once activated, the ANGLE keyword would be invalid..
;           FILETYPE: 'png' or 'ps'. (DEFAULT 'png')
;           OUTPUTFILE: the name of the output file.
;			THEBDATA: specifies magnetic data to use.
;			FINISHED: makes the output publication quality when using ps (NOT WORKING WELL).
;			XRANGE: vector specifying the xrange
;			RANGE: vector specifying the color range
;			ERANGE: specifies the energy range to be used
;			UNITS: specifies the units ('eflux','df',etc.) (Def. is 'df')
;			NOZLOG: specifies a linear Z axis
;			POSITION: positions the plot using a 4-vector
;			NOFILL: doesn't fill the contour plot with colors
;			NLINES: says how many lines to use if using NOFILL (DEFAULT 60, MAX 60)
;			NOOLINES: suppresses the black contour lines
;			NUMOLINES: how many black contour lines (DEFAULT 20, MAX 60)
;           REMOVEZERO: removes the data with zero counts for plotting
;			SHOWDATA: plots all the data points over the contour
;			VEL: tplot variable containing the velocity data
;			     (default is calculated with v_3d)
;			NOGRID: forces no triangulation
;			NOSMOOTH: suppresses smoothing (IF NOT SET, DEFAULT IS SMOOTH)
;			NOSUN: suppresses the sun direction line
;			NOVELLINE: suppresses the velocity line
;           SUBTRACT: subtract the bulk velocity before plot
;			RESOLUTION: resolution of the mesh (DEFAULT 51)
;			RMBINS: removes the sun noise by cutting out certain bins
;			THETA: specifies the theta range for RMBINS (def 20)
;			PHI: specifies the phi range for RMBINS (def 40)
;			NR: removes background noise from ph using noise_remove
;			NOISELEVEL: background level in eflux
;			BOTTOM: level to set as min eflux for background. def. is 0.
;			SR, RS, RM2: removes the sun noise using subtraction
;				REQUIRES write_ph.doc to run
;			NLOW: used with rm2.  Sets bottom of eflux noise level
;				def. 1e4
;			M: marks the tplot at the current time
;			VEL2: takes a 3-vector velocity and puts it on the plot
;CREATED BY:		Arjun Raj
;EXAMPLES:  see the crib file: themis_cut_crib.pro
;REMARKS:		when calling with phb and rm2, use file='write_phb.doc'
;			also, set the noiselevel to 1e5.  This gives the best
;			results
;
;LAST EDITED BY XUZHI ZHOU 4-24-2008
;-

pro thm_esa_slice2d,sc,typ,current_time,timeinterval,species=species,rotation = rotation,$
    angle = angle,ThirdDirlim = ThirdDirlim,filetype = filetype,outputfile = outputfile,thebdata = thebdata,$
    finished = finished,xrange = xrange,range = range,erange = erange,units = units,nozlog = nozlog,$
    position = position,nofill = nofill,nlines = nlines,noolines = noolines,numolines = numolines,$
    removezero = removezero,showdata = showdata,vel=vel,nogrid=nogrid,nosmooth=nosmooth,nosun = nosun,$
    novelline = novelline,subtract = subtract,resolution = resolution,rmbins = rmbins,theta = theta,phi = phi,$
    nr = nr,noiselevel = noiselevel,bottom = bottom,sr = sr,rs = rs,rm2=rm2,nlow = nlow,m = m,vel2 = vel2,$
    phb = phb,filename = filename,_EXTRA = e

!p.charsize=1

if not keyword_set(filetype) then filetype='png'

if keyword_set(removezero) then leavezero=0 else leavezero=1

cross=0

if keyword_set(phb) then filename = 'write_phb.doc'

for i=0,timeinterval/3-1 do begin
  if species eq 'ion' then begin
    thedata2=CALL_FUNCTION('get_th'+sc+'_pei'+typ,current_time+i*3.0)
;    thedata2s=CALL_FUNCTION('thm_sst_psif',current_time+i*3.0,probe=sc)
  endif
  if species eq 'ele' then begin
    thedata2=CALL_FUNCTION('get_th'+sc+'_pee'+typ,current_time+i*3.0)
;    thedata2s=CALL_FUNCTION('thm_sst_psef',current_time+i*3.0,probe=sc)
  endif

  if i eq 0 then begin
    thedata3 = thedata2
;    thedata3s = thedata2s
  endif else begin
    thedata3 = [thedata3,thedata2]
;    thedata3s = [thedata3s,thedata2s]
  endelse

endfor
inumber=i-1

; %%% LOOP START HERE  %%%

for in=0,inumber do begin
thedata=thedata3(in)

bins_2d=fltarr(thedata.nenergy,thedata.nbins)
for i=0,thedata.nbins-1 do begin
;    bins_2d(*,i)=thedata.bins(i)
    bins_2d(*,i)=thedata.bins(*,i)
endfor

if keyword_set(rmbins) then begin
	dprint,  'Removing bins (thm_bin_remove)'
	thedata = thm_bin_remove(thedata,theta = theta,phi = phi)
endif ;else thedata = thedata2

if keyword_set(sr) then rm2 = 1
if keyword_set(rs) then rm2 = 1
if keyword_set(nofill) then noolines = 1

if keyword_set(rm2) then begin
	dprint,  'Removing bins (thm_bin_remove2)'
	leavezero = 1
	if not keyword_set(nosmooth) then nosmooth = 0
	;nr = 1
	load_ph,new,filename = filename
	thedata = thm_bin_remove2(thedata,theta = theta,phi = phi,new= new,nlow = nlow)
endif ;else thedata = thedata2


if keyword_set(nr) then begin
	dprint, 'Removing Noise'
;dprint,  noiselevel
	thedata = thm_noise_remove(thedata,nlevel = noiselevel,bottom = bottom)
	leavezero = 1
endif

if keyword_set(m) then $
	new_time,'cut2d',thedata.time

numperrow=4

;MODIFICATIONS TO MAKE COMMAND LINE SMALLER

if not keyword_set(ThirdDirLim) and not keyword_set(angle) then angle = [-20.,20.]

if not keyword_set(nozlog) then zlog = 1
if not keyword_set(nogrid) then grid = 1

if not keyword_set(nosmooth) then smooth = 1
if not keyword_set(noolines) then begin
	if keyword_set(numolines) then olines = numolines else olines = 20
	endif
if not keyword_set(subtract) then nosubtract = 1
if not keyword_set(nosun) then sundir = 1

if keyword_set(zlog) then dprint, 'zl'
if keyword_set(grid) then dprint, 'grid'
if keyword_set(cross) then dprint, 'cross'
if keyword_set(smooth) then dprint, 'smooth'
if keyword_set(olines) then dprint, 'olines'

if not keyword_set(units) then units = 'df'
if not keyword_set(nlines) then nlines = 60

if not keyword_set(rotation) then rotation='BV'


if filetype eq 'ps' then begin
    SET_PLOT, 'PS'
    DEVICE, FILENAME=outputfile+'.ps',/color,bits_per_pixel=8
endif

;END MODIFICATiONS


perpsym = byte(94)
perpsymbol = string(perpsym)

parasym = byte(47)
parasymbol = string(parasym) + string(parasym)



if keyword_set(finished) and units eq 'df' then thedata.data = thedata.data / 1000.  ;changing units to
									;s^-3 m^-6

;if keyword_set(finished) and keyword_set(plotlabel) and !d.name eq 'PS' then begin
;	device,/bold
;	xyouts, 0.0,.95,plotlabel+'!N!7',/normal
;endif


if !d.name eq 'PS' then loadct,39

if not keyword_set(resolution) then resolution = 51
if resolution mod 2 eq 0 then resolution = resolution + 1

oldplot = !p.multi

if keyword_set(cross) then begin ;and  !d.name ne 'PS' then begin
	!p.multi = [0,2,1]
	grid = 1
endif

;if not keyword_set(vel) then vel = 'v_3d_ph'

if not keyword_set(position) then begin
	x_size = !d.x_size & y_size = !d.y_size
	xsize = .77
	yoffset = 0.
	d=1.
	if keyword_set(cross) then begin
		yoffset = yoffset + .5
		xsize = xsize/2.+.13/1.5
		y_size = y_size/2.
		x_size = x_size/2.
		d = .5
		if y_size le x_size then $
			pos2 = [.13*d+.05,.03+.13*d,.05+.13*d + xsize * y_size/x_size,.13*d + xsize+.03] else $
			pos2 = [.13*d+.05,.03+.13*d,.05+.13*d + xsize,.13*d + xsize *x_size/y_size+.03]

	endif
	if y_size le x_size then $
		position = [.13*d+.05,.13*d+yoffset,.05+.13*d + xsize * y_size/x_size,.13*d + xsize + yoffset] else $
		position = [.13*d+.05,.13*d+yoffset,.05+.13*d + xsize,.13*d + xsize *x_size/y_size + yoffset]
endif else begin
	if not keyword_set(pos2) then begin
		pos2 = position
		pos2(0) = position(0)
		pos2(2) = position(2)
		pos2(3) = position(1)-.08
		pos2(1) = .1
	endif
endelse

;theonecnt = thedata
thedata = conv_units(thedata,units)


;stop

;thedata.data(*,120)=0


;theonecnt = conv_units(theonecnt,'counts')
;for i = 0,theonecnt.nenergy-1 do theonecnt.data(i,*) = 1
;theonecnt = conv_units(theonecnt,units)
;if theonecnt.units_name eq 'Counts' then theonecnt.data(*,*) = 1.

;**********************************************
;bad_bins=where((thedata.dphi eq 0) or (thedata.dtheta eq 0) or $
;	((thedata.data(0,*) eq 0.) and (thedata.theta(0,*) eq 0.) and $
;	(thedata.phi(0,*) eq 180.)),n_bad)
;good_bins=where(((thedata.dphi ne 0) and (thedata.dtheta ne 0)) and not $
;	((thedata.data(0,*) eq 0.) and (thedata.theta(0,*) eq 0.) and $
;	(thedata.phi(0,*) eq 180.)),n_good)

;if n_bad ne 0 then print,'There are bad bins'


if thedata.valid ne 1 then begin
	dprint, 'Not valid data'
	return
endif

;bad120 = where(good_bins eq 120,count)
;if count eq 1 and thedata.data_name eq 'Pesa High' then begin
;	print, 'Fixing bad 120 bin'
;	if n_bad eq 0 then bad_bins = [120] else bad_bins = [bad_bins,120]
;	good_bins = good_bins(where(good_bins ne 120))
;	n_bad = n_bad + 1
;	n_good = n_good -1
;endif



;*****************************

;In order to find out how many particles there are at all the different locations,
;we must transform the data into cartesian coordinates.


totalx = fltarr(1) & totaly = fltarr(1) & totalz = fltarr(1)
ncounts = fltarr(1)

if not keyword_set(erange) then begin
	erange = [thedata.energy(thedata.nenergy-1,0),thedata.energy(0,0)]
	erange = [min(thedata.energy), max(thedata.energy)]
	eindex = indgen(thedata.nenergy)
endif else begin
	eindex = where(thedata.energy(*,0) ge erange(0) and thedata.energy(*,0) le erange(1))
	erange = [min(thedata.energy(eindex,0)),max(thedata.energy(eindex,0))]
endelse


;stop

mass = thedata.mass / 6.2508206e24

for i = 0, thedata.nenergy-1 do begin
	currbins = where(bins_2d(i,*) ne 0 and thedata.energy(i,*) le erange(1) and thedata.energy(i,*) ge erange(0) and finite(thedata.data(i,*)) eq 1,nbins)
	if nbins ne 0 then begin
;		print, i
		x = fltarr(nbins) & y = fltarr(nbins) & z = fltarr(nbins)
		sphere_to_cart,1,reform(thedata.theta(i,currbins)),reform(thedata.phi(i,currbins)),x,y,z
		totalx = [totalx, x * reform(sqrt(2*1.6e-19*thedata.energy(i,currbins)/mass))]
		totaly = [totaly, y * reform(sqrt(2*1.6e-19*thedata.energy(i,currbins)/mass))]
		totalz = [totalz, z * reform(sqrt(2*1.6e-19*thedata.energy(i,currbins)/mass))]

		ncounts = [ncounts,reform(thedata.data(i, currbins))]
	endif
endfor

totalx = totalx(1:*)
totaly = totaly(1:*)
totalz = totalz(1:*)
ncounts = ncounts(1:*)

if in eq 0 then begin
  ncounts_t = ncounts
endif else begin
  ncounts_t = ncounts_t+ncounts
endelse

endfor
ncounts=ncounts_t/(inumber+1)

;  %%%  LOOP ENDS HERE  %%%

;*****HERES SOMETHING NEW
;sto
newdata = {dir:fltarr(n_elements(totalx),3), n:fltarr(n_elements(totalx))}

newdata.dir(*,0) = totalx
newdata.dir(*,1) = totaly
newdata.dir(*,2) = totalz
newdata.n = ncounts

;stop


;**********************************************

;get the magnetic field into a variable

get_data,thebdata,data = mgf



;************EXPERIMENTAL INTERPOLATION FIX************
;get_data,thebdata,data = bdata
;index = where(bdata.x le thedata.time + 600 and bdata.x ge thedata.time - 600)
;store_data,thebdata+'cut',data={x:bdata.x(index),y:bdata.y(index,*)}
;********

store_data,'time',data = {x:thedata.time+thedata.integ_t*.5}
;dprint,  thedata.integ_t, ' Thedata.integ_t'
;interpolate,'time',thebdata+'cut','Bfield'
;get_data,'Bfield',data = mgf
;bfield = fltarr(3)
;bfield[0] = mgf.y(0,0)
;bfield[1] = mgf.y(0,1)
;bfield[2] = mgf.y(0,2)

bfield = thm_dat_avg(thebdata, thedata3(0).time, thedata.end_time)

;dprint,  'BFIELD is ',bfield

;dprint,  'All data interpolated to ' + time_string(mgf.x)



if keyword_set(nosubtract) then dprint, 'No velocity transform' else begin
	if keyword_set(vel) then print,'Velocity used for subtraction is '+vel else dprint,  'Velocity used for subtraction is V_3D'
endelse


if keyword_set(vel) then begin
	dprint, 'Using '+vel+' for velocity vector'

;	get_data,vel,data = dummy, index = theindex
;	if theindex eq 0 then begin
;		Print, 'Loading velocity data....'
;		get_3dt,'v_3d','ph',/nr,/rm2
;	endif

;	interpolate,'time',vel,'value'
;	get_data,'value',data = thevalue
;	thevel = 1000.* reform(thevalue.y)

	thevel = 1000. * thm_dat_avg(vel, thedata3(0).time, thedata.end_time)

;	print, thevel

	factor = 1.
endif else begin
	dprint,  'Calculating V with v_3d...'
	thevel = 1000. * v_3d(thedata)
	thevel = 0.01 * j_3d(thedata)/n_3d(thedata)
	for in=0,inumber do begin
	  if in eq 0 then begin
		flux=j_3d(thedata3(0))
		density=n_3d(thedata3(0))
	  endif else begin
	    flux=flux+j_3d(thedata3(in))
	    density=density+n_3d(thedata3(in))
	  endelse
	endfor
	thevel = 0.01 * flux/density
	factor = 1.
endelse


if not keyword_set(nosubtract) then begin
	newdata.dir(*,0) = newdata.dir(*,0) - thevel(0)*factor
	newdata.dir(*,1) = newdata.dir(*,1) - thevel(1)*factor
	newdata.dir(*,2) = newdata.dir(*,2) - thevel(2)*factor
endif else begin
	newdata.dir(*,0) = newdata.dir(*,0)
	newdata.dir(*,1) = newdata.dir(*,1)
	newdata.dir(*,2) = newdata.dir(*,2)
endelse





;**************NOW CONVERT TO THE DATA SET REQUIRED*****************


if rotation eq 'BV' then rot=thm_cal_rot(bfield,thevel)
if rotation eq 'BE' then rot=thm_cal_rot(bfield,crossp(bfield,thevel))
if rotation eq 'xy' then rot=thm_cal_rot([1,0,0],[0,1,0])
if rotation eq 'xz' then rot=thm_cal_rot([1,0,0],[0,0,1])
if rotation eq 'yz' then rot=thm_cal_rot([0,1,0],[0,0,1])
if rotation eq 'xvel' then rot=thm_cal_rot([1,0,0],thevel)
if rotation eq 'perp' then begin
    rot=thm_cal_rot(crossp(bfield,crossp(bfield,thevel)),crossp(bfield,thevel))
endif
if rotation eq 'perp_yz' then begin
    rot=thm_cal_rot(CROSSP(CROSSP(bfield,[0,1,0]),bfield),CROSSP(CROSSP(bfield,[0,0,1]),bfield))
endif
if rotation eq 'perp_xy' then begin
    rot=thm_cal_rot(CROSSP(CROSSP(bfield,[1,0,0]),bfield),CROSSP(CROSSP(bfield,[0,1,0]),bfield))
endif
if rotation eq 'perp_xz' then begin
    rot=thm_cal_rot(CROSSP(CROSSP(bfield,[1,0,0]),bfield),CROSSP(CROSSP(bfield,[0,0,1]),bfield))
endif

newdata.dir = newdata.dir#rot
factor = 1000.
;vperp = (newdata.dir(*,1)^2 + newdata.dir(*,2)^2)^.5*newdata.dir(*,1)/abs(newdata.dir(*,1))/factor
vperp = newdata.dir(*,1)/factor
vpara = newdata.dir(*,0)/factor
vperp2= newdata.dir(*,2)/factor
zdata = newdata.n

if keyword_set(ThirdDirlim) then angle = [-90.,90.]

	zmag = vperp2

	r = sqrt(vpara^2 + vperp^2+vperp2^2)

	eachangle = asin(zmag/r)
	angle1=min(angle)
	angle2=max(angle)

	index = where(eachangle/!dtor le angle2 and eachangle/!dtor ge angle1,count)
	if count ne 0 then begin
		vperp = vperp(index)
		vpara = vpara(index)
		vperp2=vperp2(index)
		zdata = zdata(index)
	endif else begin
		message,'NO DATA POINTS AT THAT ANGLE!'
		return
	endelse
	dprint,  'angle = ',angle

if keyword_set(ThirdDirlim) then begin
    third = vperp2
    index = where(third le max(ThirdDirlim) and third ge min(ThirdDirlim))
    if count ne 0 then begin
        vperp = vperp(index)
        vpara = vpara(index)
        vperp2=vperp2(index)
        zdata = zdata(index)
    endif
endif

;**********************

if keyword_set(sundir) then begin
	sund = [1,0,0]
	sund = sund#rot
	vperpsun = (sund(1)^2 + sund(2)^2)^.5*sund(1)/abs(sund(1))
	vparasun = sund(0)
endif

if not keyword_set(vel) then veldir = v_3d(thedata) else veldir = thevel/1000.
veldir = veldir#rot

;EXPERIMENTAL GET RID OF 0 THING*************
if not keyword_set(leavezero) then begin
	index = where(zdata ne 0)
	vperp = vperp(index)
	vpara = vpara(index)
	vperp2=vperp2(index)
	zdata = zdata(index)
endif else dprint,  'Zeros left in plot'

;MAKE SURE THERE ARE NO NEGATIVE VALUES!! ***********
index2 = where(zdata lt 0., count)
if count ne 0 then dprint, 'THERE ARE NEGATIVE DATA VALUES'

index = where(zdata ge 0,count)
if count ne 0 then begin
	vperp = vperp(index)
	vperp2= vperp2(index)
	vpara = vpara(index)
	zdata = zdata(index)
endif


;stop

vperp=vperp(sort(vpara))
zdata=zdata(sort(vpara))
vperp2=vperp2(sort(vpara))
vpara=vpara(sort(vpara))

uni2=uniq(vpara)
uni1=[0,uni2(0:n_elements(uni2)-2)+1]

kk=0
for i=0,n_elements(uni2)-1 do begin
    vperpi=vperp(uni1(i):uni2(i))
    vparai=vpara(uni1(i):uni2(i))
    zdatai=zdata(uni1(i):uni2(i))

    vparai=vparai(sort(vperpi))
    zdatai=zdatai(sort(vperpi))
	vperpi=vperpi(sort(vperpi))

	index2=uniq(vperpi)
	if n_elements(index2) eq 1 then begin
	    index1=0
	endif else begin
	    index1=[0,index2(0:n_elements(index2)-2)+1]
	endelse

    for j=0,n_elements(index2)-1 do begin
        vperp(kk)=vperpi(index1(j))
        vpara(kk)=vparai(index1(j))
        if index1(j) eq index2(j) then begin
            zdata(kk)=zdatai(index1(j))
        endif else begin
            zdata_moment=moment(zdatai(index1(j):index2(j)))
            zdata(kk)=zdata_moment(0)
        endelse
        kk=kk+1
    endfor
endfor
vperp=vperp(0:kk-1)
vpara=vpara(0:kk-1)
zdata=zdata(0:kk-1)


;******************NOW TO PLOT THE DATA********************

if not keyword_set(xrange) then begin
	themax = max(abs([vperp,vpara]))
	xrange = [-1*themax,themax]
endif else themax = max(abs(xrange))


if not keyword_set(range) then begin
	if not keyword_set(xrange) then begin
		maximum = max(zdata)
		minimum = min(zdata(where(zdata ne 0)))
	endif else begin
		maximum = max(zdata(where(abs(vperp) le themax and abs(vpara) le themax)))
		minimum = min(zdata(where(zdata ne 0 and abs(vperp) le themax and abs(vpara) le themax)))
	endelse
endif else begin
	maximum = range(1)
	minimum = range(0)
endelse



if keyword_set(zlog) then $
	thelevels = 10.^(indgen(nlines)/float(nlines)*(alog10(maximum) - alog10(minimum)) + alog10(minimum)) $
else $
	thelevels = (indgen(nlines)/float(nlines)*(maximum-minimum)+minimum)
;**********EXTRA STUFF FOR THE CONTOUR LINE OVERPLOTS************
if keyword_set(olines) then begin
	if keyword_set(zlog) then $
		thelevels2 = 10.^(indgen(olines)/float(olines)*(alog10(maximum) - alog10(minimum)) + alog10(minimum)) $
	else $
		thelevels2 = (indgen(olines)/float(olines)*(maximum-minimum)+minimum)

endif
;**********END EXTRA STUFF FOR LINE OVERPLOTS (MORE LATER)*************************************


thecolors = round((indgen(nlines)+1)*(!d.table_size-9)/nlines)+7

if not keyword_set(nofill) then fill = 1 else fill = 0

if not keyword_set(finished) then begin
	    if rotation eq 'BV' then begin
	        xtitle = 'V Para (km/sec)'
	        ytitle = 'V Perp (km/sec)'
	    endif
	    if rotation eq 'xy' then begin
	        xtitle = 'Vx (km/sec)'
	        ytitle = 'Vy (km/sec)'
	    endif
	    if rotation eq 'xz' then begin
	        xtitle = 'Vx (km/sec)'
	        ytitle = 'Vz (km/sec)'
	    endif
	    if rotation eq 'yz' then begin
	        xtitle = 'Vy (km/sec)'
	        ytitle = 'Vz (km/sec)'
	    endif
	    if rotation eq 'xvel' then begin
	        xtitle = 'Vx (km/sec)'
	        ytitle = 'Vyz (km/sec)'
	    endif
endif else begin
		xtitle = 'V!19!D'+parasymbol+'!N!7 (km/sec)'
		ytitle = 'V!19!D'+perpsymbol+'!N!7 (km/sec)'
endelse


if keyword_set(grid) then begin
;stop
	x= findgen(resolution)/(resolution-1)*(xrange(1)-xrange(0)) + xrange(0)
	spacing = (xrange(1)-xrange(0))/(resolution-1)
	triangulate,vpara,vperp,tr,b

; test
tr1=tr(0,*)
tr2=tr(1,*)
tr3=tr(2,*)
index = where((vpara(tr1)+vpara(tr2)+vpara(tr3))^2+(vperp(tr1)+vperp(tr2)+vperp(tr3))^2 gt min(vpara^2+vperp^2), count)
if count ne 0 then begin
    tr=tr(*,index)
endif


	thesurf = trigrid(vpara,vperp,zdata,tr,[spacing,spacing], [xrange(0),xrange(0),xrange(1),xrange(1)],xgrid = xg,ygrid = yg )
	if keyword_set(smooth) then thesurf = smooth(thesurf,3)
	if n_elements(xg) mod 2 ne 1 then dprint, 'The line plots are invalid',n_elements(xg)
	;dprint, n_elements(xg)
;**************************************************
;********EXPERIMENTAL THINGS HERE************
;stop

if keyword_set(logplot) then begin

	vpara2 = vpara
	vperp2 = vperp

	magnitude = .5 * alog(vpara^2 + vperp^2)

	vpara2 = vpara / sqrt(vpara^2 + vperp^2)
	vperp2 = vperp / sqrt(vpara^2 + vperp^2)

	vpara2 = vpara2 * magnitude
	vperp2 = vperp2 * magnitude

;CONVERT BACK AS A CHECK
;magnitude = exp(sqrt(vpara2^2 + vperp2^2) )
;vpara3 = vpara2 / sqrt(vpara2^2 + vperp2^2)
;vperp3 = vperp2 / sqrt(vpara2^2 + vperp2^2)
;vpara4 = vpara3 * magnitude
;vperp4 = vperp3 * magnitude

	xrangeold = xrange

	xrange(0) = -alog(abs(xrange(0)))
	xrange(1) = alog(xrange(1))

;stop


	x= findgen(resolution)/(resolution-1)*(xrange(1)-xrange(0)) + xrange(0)
	spacing = (xrange(1)-xrange(0))/(resolution-1)
	triangulate,vpara2,vperp2,tr,b
	thesurf = trigrid(vpara2,vperp2,zdata,tr,[spacing,spacing], [xrange(0),xrange(0),xrange(1),xrange(1)],xgrid = xg,ygrid = yg )
	if keyword_set(smooth) then thesurf = smooth(thesurf,3)
	if n_elements(xg) mod 2 ne 1 then dprint, 'The line plots are invalid',n_elements(xg)
	;dprint, n_elements(xg)

	xrange = xrangeold

	indexminus = where(xg lt 0.)
	indexplus = where(xg gt 0.)

	xg(indexminus) = -exp(abs(xg(indexminus)))
	xg(indexplus) = exp(xg(indexplus))
	yg(indexminus) = -exp(abs(yg(indexminus)))
	yg(indexplus) = exp(yg(indexplus))

endif
;stop
;********************************************************
;********************************************************

 ;thedata.data_name+' '+time_string(thedata.time)
	timetitle = thedata.data_name+' '+time_string(thedata3(0).time) + '->' + strmid(time_string(thedata.end_time),11,8)
	;if keyword_set(finished) and keyword_set(plotlabel) then timetitle = '!B
	;if keyword_set(finished) and keyword_set(plotlabel) then timetitle = '!B
	contour,thesurf,xg,yg,$
		/closed,levels=thelevels,c_color = thecolors,fill=fill,$
		title = timetitle, $
		ystyle = 1,$
		ticklen = -0.01,$
		xstyle = 1,$
		xrange = xrange,$
		yrange = xrange,$
		xtitle = xtitle,$
		ytitle = ytitle,position = position
	if keyword_set(olines) then begin
		if !d.name eq 'PS' then somecol = !p.color else somecol = 0
		contour, thesurf,xg,yg,/closed,levels = thelevels2,ystyle = 1+4, $
			xstyle = 1+4,xrange = xrange, yrange = xrange, ticklen = 0,/noerase,position = position,col = somecol
	endif
endif else begin
	contour,zdata,vpara,vperp,/irregular,$
		/closed,levels=thelevels,c_color = thecolors,fill=fill,$
		title = timetitle, $
		ystyle = 1,$
		ticklen = -0.01,$
		xstyle = 1,$
		xrange = xrange,$
		yrange = xrange,$
		xtitle = xtitle,$
		ytitle = ytitle,position = position
	if keyword_set(olines) then begin
		if !d.name eq 'PS' then somecol = !p.color else somecol = 0
		contour, zdata,vpara,vperp,/irregular,/closed, levels = thelevels2, $
			ystyle = 1+4, xstyle = 1+4, ticklen = 0, xrange = xrange, yrange = xrange, position=position,/noerase, col = somecol
	endif
endelse

if not keyword_set(cut_para) then cut_para = 0.
if not keyword_set(cut_perp) then cut_perp = 0.

if keyword_set(cut_bulk_vel) then begin
cut_para= veldir(0)
cut_perp= veldir(1)
endif

;oplot, vpara, vperp, PSYM=1

oplot,[cut_para,cut_para],xrange,linestyle = 2,thick = 2
oplot,xrange,[cut_perp,cut_perp],linestyle = 2,thick = 2
;oplot,[0,0],xrange,linestyle = 1
;oplot,xrange,[0,0],linestyle = 1

if keyword_set(sundir) then oplot,[0,vparasun*max(xrange)],[0,vperpsun*max(xrange)]

if keyword_set(vel2) then begin

;	stop
	vel2 = vel2#rot
	vperpvel2 = (vel2(1)^2 + vel2(2)^2)^.5*vel2(1)/abs(vel2(1))
	vparavel2 = vel2(0)

	bbbb=findgen(36)*(!pi*2/32.)
	usersym,1.5*cos(bbbb),1.5*sin(bbbb),/fill

;	oplot,[vparavel2],[vperpvel2],psym = 8,col= !d.table_size - 10,symsize =1
	oplot,[vparavel2],[vperpvel2],psym = 8,col= 2,symsize =1
endif


if not keyword_set(novelline) then oplot,[0,veldir(0)],[0,veldir(1)],col= !d.table_size-9


	circy=sin(findgen(360)*!dtor)*sqrt(2.*1.6e-19*erange(0)/mass)/1000.
	circx=cos(findgen(360)*!dtor)*sqrt(2.*1.6e-19*erange(0)/mass)/1000.  ;sqrt(2*1.6e-19*energy(i)/mass)
	oplot,circx,circy,thick = 2

	circy=sin(findgen(360)*!dtor)*sqrt(2.*1.6e-19*erange(1)/mass)/1000.
	circx=cos(findgen(360)*!dtor)*sqrt(2.*1.6e-19*erange(1)/mass)/1000.  ;sqrt(2*1.6e-19*energy(i)/mass)
	oplot,circx,circy,thick = 2

thetitle = units_string(thedata.units_name)

if keyword_set(plotlabel) then xyouts, 0.05,.95,plotlabel+'!N!7',/normal,charsize = 1.5


;if keyword_set(zlog) then thetitle = thetitle + ' (log)'

draw_color_scale,range=[minimum,maximum],log = zlog,yticks=10,title =thetitle


if keyword_set(showdata) then oplot,vpara,vperp,psym=1

if cross eq 1 then begin
	n_elem = n_elements(thesurf(*,0))



	if not keyword_set(cut_perp) then perpval = n_elem/2 else begin
		ind = where(xg ge cut_perp)
		if (xg(ind(0)) - cut_perp) le (cut_perp - xg(ind(0)-1) ) then perpval = ind(0) else perpval = ind(0)-1
	endelse

	if not keyword_set(cut_para) then paraval = n_elem/2 else begin
		ind = where(xg ge cut_para)
		if (xg(ind(0)) - cut_para) le (cut_para - xg(ind(0)-1) ) then paraval = ind(0) else paraval = ind(0)-1
	endelse

;	if keyword_set(zlog) then thetitle = thetitle + ' (log)'

		xtitle = 'Velocity (km/sec)'
		vore = 'V'


;HERE COMES SOME NEW COLOR STUFF
	if !d.name eq 'PS' then thecolors = round((indgen(4)+1)*(!d.table_size-9)/4)+7 else begin
		thecolors=indgen(4)
		thecolors = thecolors + 3
	endelse

	if keyword_set(double) then begin
		;first plot vpara on the + side
		plot,xg,[reverse(thesurf(n_elem/2:*,perpval)),thesurf(n_elem/2+1:*,perpval)],$
			xstyle = 1, ystyle =1,$
			xrange = xrange,yrange = [minimum,maximum],ylog = zlog, $
			title = 'Cross Sections',xtitle = xtitle,ytitle = thetitle,$
			position = pos2
		;overplot vpara on the minus side
		oplot,xg,[thesurf(0:n_elem/2,perpval),reverse(thesurf(0:n_elem/2-1,perpval))],color = thecolors(0)
		;now vperp on the + side
		oplot,xg,[reverse(reform(thesurf(paraval,n_elem/2+1:*))),reform(thesurf(paraval,n_elem/2:*))],color = thecolors(1)
		;and now vper on the - side
		oplot,xg,[reform(thesurf(paraval,0:n_elem/2)),reverse(reform(thesurf(paraval,0:n_elem/2-1)))],color = thecolors(2)
	endif else begin
		if not keyword_set(loglines) then begin
			;stop
			;first plot vpara on the + side
			plot,xg(n_elem/2:*),thesurf(n_elem/2:*,perpval),$
				xstyle = 1, ystyle =1,$
				xrange = xrange,yrange = [minimum,maximum],ylog = zlog, $
				title = 'Cross Sections',xtitle = xtitle,ytitle = thetitle,$
				position = pos2
			;overplot vpara on the minus side
			oplot,xg(0:n_elem/2),thesurf(0:n_elem/2,perpval),color = thecolors(0)
			;now vperp on the + side
			oplot,xg(n_elem/2:*),reform(thesurf(paraval,n_elem/2:*)),color = thecolors(1)
			;and now vper on the - side
			oplot,xg(0:n_elem/2),reform(thesurf(paraval,0:n_elem/2)),color = thecolors(2)
		endif else begin
			;*****PUT IN LOGLINES STUFF HERE********
;********EXPERIMENTAL THINGS HERE************
;stop

if not keyword_set(oldlog) then begin

vpara2 = vpara
vperp2 = vperp

magnitude = .5 * alog(vpara^2 + vperp^2)

vpara2 = vpara / sqrt(vpara^2 + vperp^2)
vperp2 = vperp / sqrt(vpara^2 + vperp^2)

vpara2 = vpara2 * magnitude
vperp2 = vperp2 * magnitude

;CONVERT BACK AS A CHECK
;magnitude = exp(sqrt(vpara2^2 + vperp2^2) )
;vpara3 = vpara2 / sqrt(vpara2^2 + vperp2^2)
;vperp3 = vperp2 / sqrt(vpara2^2 + vperp2^2)
;vpara4 = vpara3 * magnitude
;vperp4 = vperp3 * magnitude

xrangeold = xrange

xrange(0) = -alog(abs(xrange(0)))
xrange(1) = alog(xrange(1))

;stop


	x= findgen(resolution)/(resolution-1)*(xrange(1)-xrange(0)) + xrange(0)
	spacing = (xrange(1)-xrange(0))/(resolution-1)
	triangulate,vpara2,vperp2,tr,b
	thesurf = trigrid(vpara2,vperp2,zdata,tr,[spacing,spacing], [xrange(0),xrange(0),xrange(1),xrange(1)],xgrid = xg,ygrid = yg )
	if keyword_set(smooth) then thesurf = smooth(thesurf,3)
	if n_elements(xg) mod 2 ne 1 then dprint, 'The line plots are invalid',n_elements(xg)
	;dprint, n_elements(xg)

xrange = xrangeold

indexminus = where(xg lt 0.)
indexplus = where(xg gt 0.)

xg(indexminus) = -exp(abs(xg(indexminus)))
xg(indexplus) = exp(xg(indexplus))

endif
;stop
;********************************************************
			;stop
			;plot,xg,[reverse(thesurf(n_elem/2:*,perpval)),thesurf(n_elem/2+1:*,perpval)],$
			plot,xg(n_elem/2:*),thesurf(n_elem/2:*,perpval),$
				xstyle = 1, ystyle =1,$
				xrange = [min(thedata.energy(*,0)),xrange[1]],yrange = [minimum,maximum],ylog = zlog,/xlog, $
				title = 'Cross Sections',xtitle = xtitle,ytitle = thetitle,$
				position = pos2
			;vpara on the minus side
			oplot,xg(n_elem/2:*), reverse(thesurf(0:n_elem/2, perpval)), color = thecolors(0)
			;vperp on the + side
			oplot,xg(n_elem/2:*), reform(thesurf(paraval,n_elem/2:*)),color = thecolors(1)
			;vperp on the - side
			oplot,xg(n_elem/2:*), reverse(reform(thesurf(paraval, 0:n_elem/2))), color = thecolors(2)


		endelse
	endelse



	;put a dotted line
	oplot,[0,0],[minimum,maximum],linestyle = 1
		oplot,[sqrt(2.*1.6e-19*erange(0)/mass)/1000.,sqrt(2.*1.6e-19*erange(0)/mass)/1000.],[minimum,maximum],linestyle = 5
		oplot,-[sqrt(2.*1.6e-19*erange(0)/mass)/1000.,sqrt(2.*1.6e-19*erange(0)/mass)/1000.],[minimum,maximum],linestyle = 5
		oplot,[sqrt(2.*1.6e-19*erange(1)/mass)/1000.,sqrt(2.*1.6e-19*erange(1)/mass)/1000.],[minimum,maximum],linestyle = 5
		oplot,-[sqrt(2.*1.6e-19*erange(1)/mass)/1000.,sqrt(2.*1.6e-19*erange(1)/mass)/1000.],[minimum,maximum],linestyle = 5
		if keyword_set(onecnt) then begin
			oplot,sqrt(2.*1.6e-19*theonecnt.energy(*,0)/mass)/1000.,theonecnt.data(*,0),color = thecolors(3),linestyle = 3
			oplot,-sqrt(2.*1.6e-19*theonecnt.energy(*,0)/mass)/1000.,theonecnt.data(*,0),color = thecolors(3),linestyle = 3
		endif

	;now put the titles on the side of the graph
	positions = -findgen(5)*(pos2(3)-pos2(1))/5 + pos2(3)-.03
	xyouts,pos2(2) + .03,positions(0),vore+' para (+ side)',/norm,charsize = 1.01;.5
	xyouts,pos2(2) + .03,positions(1),vore+' para (- side)',/norm,color = thecolors(0),charsize = 1.01;.5
	xyouts,pos2(2) + .03,positions(2),vore+' perp (+ side)',/norm,color = thecolors(1),charsize = 1.01;.5
	xyouts,pos2(2) + .03,positions(3),vore+' perp (- side)',/norm,color = thecolors(2),charsize = 1.01;.5
	if keyword_set(onecnt) then xyouts,pos2(2) + .03,positions(4),'One count',/norm,color = thecolors(3),charsize = .5
endif

;stop


if keyword_set(outfile) then begin
	openw, thefile, outfile, /get_lun
	printf, thefile, time_string(thedata.time)

	if not keyword_set(cut_perp) then perpval = n_elem/2 else begin
		ind = where(xg ge cut_perp)
		if (xg(ind(0)) - cut_perp) le (cut_perp - xg(ind(0)-1) ) then perpval = ind(0) else perpval = ind(0)-1
	endelse

	if not keyword_set(cut_para) then paraval = n_elem/2 else begin
		ind = where(xg ge cut_para)
		if (xg(ind(0)) - cut_para) le (cut_para - xg(ind(0)-1) ) then paraval = ind(0) else paraval = ind(0)-1
	endelse


	filedata = fltarr(3,n_elements(xg))

	filedata(0,*) = xg
	filedata(1,*) = thesurf(*,perpval)
	filedata(2,*) = thesurf(paraval,*)

	printf, thefile, filedata
	close,/all

endif

;********EXTRA PART*********

;	if not keyword_set(cut_perp) then perpval = n_elem/2 else begin
;		ind = where(xg ge cut_perp)
;		if (xg(ind(0)) - cut_perp) le (cut_perp - xg(ind(0)-1) ) then perpval = ind(0) else perpval = ind(0)-1
;	endelse

;	if not keyword_set(cut_para) then paraval = n_elem/2 else begin
;		ind = where(xg ge cut_para)
;		if (xg(ind(0)) - cut_para) le (cut_para - xg(ind(0)-1) ) then paraval = ind(0) else paraval = ind(0)-1
;	endelse


;	filedata = fltarr(3,n_elements(xg))

;	filedata(0,*) = xg
;	filedata(1,*) = thesurf(*,perpval)
;	filedata(2,*) = thesurf(paraval,*)
;outcuts = filedata

;********END EXTRA PART*******

if filetype eq 'ps' then begin
    DEVICE, /CLOSE
endif

if !d.name ne 'PS' then !p.multi = oldplot

if filetype eq 'png' then begin
  makepng, outputfile
endif

end

