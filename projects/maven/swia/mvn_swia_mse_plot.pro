;+
;PROCEDURE: 
;	MVN_SWIA_MSE_PLOT
;PURPOSE: 
;	Routine to plot any scalar or vector quantity in MSE
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MSE_PLOT
;INPUTS:
;KEYWORDS:
;	TR: Time range (uses current tplot if not set)
;	XRANGE, YRANGE, ZRANGE: Obvious
;	PRANGE: Color plot range for scalar plots
;	PLOG: Log scale color plots
;	LEN: Length to scale vectors to for vector plots
;	PDATA: Tplot variable for position data (defaults to MSO position)
;	IDATA: Tplot variable for IMF direction (defaults to 'bsw')
;	SDATA: Tplot variable for quantity to display
;	SINDEX: Vector component to plot as scalar (1-3, after rotation to MSE. If not given, produces vector plot)
;	NBX: Number of bins in x
;	NBY: Number of bins in y (or r for cylindrical)
;	NBZ: Number of bins in z
;	QNORM: Quantity to normalize plots by
;	QFILT: Quantity to filter plots by
;	QRANGE: Range of quantity to filter plots by
;	QF2: Second quantity to filter plots by
;	QR2: Range of second quantity to filter plots by
;	PLOTNORM: Plot histogram of event density (only works for scalar)
;	STDDEV: Plot standard deviation instead of average (only works for scalar)
;	ABERR: Aberrate both upstream velocity and plotted quantities
;	VDATA: Velocity data to do aberration correction (defaults to 'vsw')
;
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2017-04-18 07:46:43 -0700 (Tue, 18 Apr 2017) $
; $LastChangedRevision: 23174 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_mse_plot.pro $
;
;-

pro mvn_swia_mse_plot, tr = tr,xrange = xrange, yrange = yrange,zrange = zrange, pdata = pdata, idata = idata, sdata = sdata, sindex = sindex, nbx = nbx, nby = nby, nbz = nbz, prange = prange, len = len, plog = plog, qrange = qrange, qfilt = qfilt, qnorm = qnorm, plotnorm = plotnorm, stddev = stddev, aberr = aberr, vdata = vdata, qf2 = qf2, qr2 = qr2, binxy, binxz, binyz, bincyl, datagap = datagap


RM = 3397.

if not keyword_set(xrange) then xrange = [-1e4,1e4]
if not keyword_set(yrange) then yrange = [-1e4,1e4]
if not keyword_set(zrange) then zrange = [-1e4,1e4]
if not keyword_set(pdata) then pdata = 'MAVEN_POS_(MARS-MSO)'
if not keyword_set(idata) then idata = 'bsw'
if not keyword_set(vdata) then vdata = 'vsw'
if not keyword_set(sdata) then sdata = 'mvn_swim_density'
if not keyword_set(nbx) then nbx = 100
if not keyword_set(nby) then nby = 100
if not keyword_set(nbz) then nbz = 100
if not keyword_set(plog) then plog = 0
if not keyword_set(len) then len = 1

xrange = float(xrange)
yrange = float(yrange)
zrange = float(zrange)

rrange = [0,sqrt(max(abs(yrange))^2 + max(abs(zrange))^2)]

dx = (xrange[1]-xrange[0])/nbx
dy = (yrange[1]-yrange[0])/nby
dz = (zrange[1]-zrange[0])/nbz
dr = (rrange[1]-rrange[0])/nby


@tplot_com

if not keyword_set(tr) then tr = tplot_vars.options.trange

get_data,pdata,data = pos
get_data,idata,data = imf
get_data,sdata,data = plot
if keyword_set(qnorm) then get_data,qnorm,data = qn
if keyword_set(qfilt) then get_data,qfilt,data = qfd
if keyword_set(qf2) then get_data,qf2,data = qfd2

w = where(plot.x ge tr[0] and plot.x le tr[1],nel)

time = plot.x[w]

x = interpol(pos.y[*,0],pos.x,time)
y = interpol(pos.y[*,1],pos.x,time)
z = interpol(pos.y[*,2],pos.x,time)


psize = size(plot.y)
if psize[0] eq 1 then begin
	ptype = 'scalar'
	pq = plot.y[w]
endif else begin
	ptype = 'vector'
	pq = plot.y[w,0:2]
endelse

imft = imf.x
imfv = imf.y

if keyword_set(datagap) then begin
	makegap,datagap,imft,imfv
endif

imfx = interpol(imfv[*,0],imft,time)
imfy = interpol(imfv[*,1],imft,time)
imfz = interpol(imfv[*,2],imft,time)

if keyword_set(aberr) then begin
	get_data,vdata,data = vel
	vsw = interpol(vel.y,vel.x,time)
	vaberr = -24.0
	phi = atan(vaberr,vsw)
	xn = x*cos(phi)+y*sin(phi)
	yn = -x*sin(phi)+y*cos(phi)

	x = xn
	y = yn
endif


theta = atan(imfz,imfy)
xmse = x
ymse = y*cos(theta) + z*sin(theta)
zmse = -1*y*sin(theta) + z*cos(theta)

w = where(xmse ge xrange[0] and xmse le xrange[1] and ymse ge yrange[0] and ymse le yrange[1] and zmse ge zrange[0] and zmse le zrange[1],nel)

xmse = xmse[w]
ymse = ymse[w]
zmse = zmse[w]
time = time[w]
theta = theta[w]

if ptype eq 'vector' then begin
	if keyword_set(aberr) then begin
		pqxn = pq[w,0]*cos(phi)+pq[w,1]*sin(phi)
		pqyn = -1*pq[w,0]*sin(phi)+pq[w,1]*cos(phi)
		
		pq[w,0] = pqxn
		pq[w,1] = pqyn
	endif

	pqx = pq[w,0]
	pqy = pq[w,1]*cos(theta) + pq[w,2]*sin(theta)
	pqz = -1*pq[w,1]*sin(theta) + pq[w,2]*cos(theta)
	pq = pqx
	if keyword_set(sindex) then begin
		ptype = 'scalar'
		if sindex eq 1 then pq = pqx
		if sindex eq 2 then pq = pqy
		if sindex eq 3 then pq = pqz
	endif

endif else begin

	pq = pq[w]
endelse

if keyword_set(qnorm) then begin
	uqn = interpol(qn.y,qn.x,time)
	if ptype eq 'vector' then begin
		pqx = pqx/uqn
		pqy = pqy/uqn
		pqz = pqz/uqn
	endif 
	pq = pq/uqn
endif

if keyword_set(qfilt) then begin
	uqf = interpol(qfd.y,qfd.x,time)
	if not keyword_set(qrange) then qrange = [min(uqf),max(uqf)]
	w = where(uqf ge qrange[0] and uqf le qrange[1],nel)
	if ptype eq 'vector' then begin
		pqx = pqx[w]
		pqy = pqy[w]
		pqz = pqz[w]
	endif
	pq = pq[w]

	xmse = xmse[w]
	ymse = ymse[w]
	zmse = zmse[w]
	time = time[w]
endif

if keyword_set(qf2) then begin
	uqf = interpol(qfd2.y,qfd2.x,time)
	if not keyword_set(qr2) then qr2 = [min(uqf),max(uqf)]
	w = where(uqf ge qr2[0] and uqf le qr2[1],nel)
	if ptype eq 'vector' then begin
		pqx = pqx[w]
		pqy = pqy[w]
		pqz = pqz[w]
	endif
	pq = pq[w]

	xmse = xmse[w]
	ymse = ymse[w]
	zmse = zmse[w]
endif

binxy = fltarr(nbx,nby,3) 
binxy2 = fltarr(nbx,nby,3)
normxy = fltarr(nbx,nby)
binxz = fltarr(nbx,nbz,3)
binxz2 = fltarr(nbx,nbz,3)
normxz = fltarr(nbx,nbz)
bincyl = fltarr(nbx,nby,3)
bincyl2 = fltarr(nbx,nby,3)
normcyl = fltarr(nbx,nby)
binyz = fltarr(nby,nbz,3)
binyz2 = fltarr(nby,nbz,3)
normyz = fltarr(nby,nbz)

i1 = floor(xmse-xrange[0])/dx
i2 = floor(ymse-yrange[0])/dy
i3 = floor(zmse-zrange[0])/dz
i4 = floor(sqrt(ymse^2+zmse^2)-rrange[0])/dr

for i = 0,nel-1 do begin
	if finite(pq[i]) then begin
		binxy[i1[i],i2[i],0] = binxy[i1[i],i2[i],0] + pq[i]
		binxy2[i1[i],i2[i],0] = binxy2[i1[i],i2[i],0] + (pq[i])^2
		normxy[i1[i],i2[i]] = normxy[i1[i],i2[i]] + 1
		binxz[i1[i],i3[i],0] = binxz[i1[i],i3[i],0] + pq[i]
		binxz2[i1[i],i3[i],0] = binxz2[i1[i],i3[i],0] + (pq[i])^2
		normxz[i1[i],i3[i]] = normxz[i1[i],i3[i]] + 1
		bincyl[i1[i],i4[i],0] = bincyl[i1[i],i4[i],0] + pq[i]
		bincyl2[i1[i],i4[i],0] = bincyl2[i1[i],i4[i],0] + (pq[i])^2
		normcyl[i1[i],i4[i]] = normcyl[i1[i],i4[i]] + 1
		binyz[i2[i],i3[i],0] = binyz[i2[i],i3[i],0] + pq[i]
		binyz2[i2[i],i3[i],0] = binyz2[i2[i],i3[i],0] + (pq[i])^2
		normyz[i2[i],i3[i]] = normyz[i2[i],i3[i]] + 1

		if ptype eq 'vector' then begin
			binxy[i1[i],i2[i],1] = binxy[i1[i],i2[i],1] + pqy[i]
			binxz[i1[i],i3[i],1] = binxz[i1[i],i3[i],1] + pqy[i]
			bincyl[i1[i],i4[i],1] = bincyl[i1[i],i4[i],1] + (pqy[i]*ymse[i] + pqz[i]*zmse[i])/sqrt(ymse[i]^2+zmse[i]^2) 
			binyz[i2[i],i3[i],1] = binyz[i2[i],i3[i],1] + pqy[i]
			binxy[i1[i],i2[i],2] = binxy[i1[i],i2[i],2] + pqz[i]
			binxz[i1[i],i3[i],2] = binxz[i1[i],i3[i],2] + pqz[i]
			bincyl[i1[i],i4[i],2] = bincyl[i1[i],i4[i],2] + sqrt(pqy[i]^2 + pqz[i]^2) - ((pqy[i]*ymse[i])^2 + (pqz[i]*zmse[i])^2)/sqrt(ymse[i]^2+zmse[i]^2) 
			binyz[i2[i],i3[i],2] = binyz[i2[i],i3[i],2] + pqz[i]
		endif
	endif
endfor

binxy[*,*,0] = binxy[*,*,0]/(normxy>1)
binxz[*,*,0] = binxz[*,*,0]/(normxz>1)
bincyl[*,*,0] = bincyl[*,*,0]/(normcyl>1)
binyz[*,*,0] = binyz[*,*,0]/(normyz>1)
binxy2[*,*,0] = binxy2[*,*,0]/(normxy>1)
binxz2[*,*,0] = binxz2[*,*,0]/(normxz>1)
bincyl2[*,*,0] = bincyl2[*,*,0]/(normcyl>1)
binyz2[*,*,0] = binyz2[*,*,0]/(normyz>1)
binxy[*,*,1] = binxy[*,*,1]/(normxy>1)
binxz[*,*,1] = binxz[*,*,1]/(normxz>1)
bincyl[*,*,1] = bincyl[*,*,1]/(normcyl>1)
binyz[*,*,1] = binyz[*,*,1]/(normyz>1)
binxy[*,*,2] = binxy[*,*,2]/(normxy>1)
binxz[*,*,2] = binxz[*,*,2]/(normxz>1)
bincyl[*,*,2] = bincyl[*,*,2]/(normcyl>1)
binyz[*,*,2] = binyz[*,*,2]/(normyz>1)

w = where(normxy eq 0)
binxy[w] = !values.d_nan
binxy[w+1L*nbx*nby] = !values.d_nan
binxy[w+2L*nbx*nby] = !values.d_nan
w = where(normxz eq 0)
binxz[w] = !values.d_nan
binxz[w+1L*nbx*nbz] = !values.d_nan
binxz[w+2L*nbx*nbz] = !values.d_nan
w = where(normyz eq 0)
binyz[w] = !values.d_nan
binyz[w+1L*nby*nbz] = !values.d_nan
binyz[w+2L*nby*nbz] = !values.d_nan
w = where(normcyl eq 0)
bincyl[w] = !values.d_nan
bincyl[w+1L*nbx*nby] = !values.d_nan
bincyl[w+2L*nbx*nby] = !values.d_nan


stdxy = sqrt(binxy2-binxy^2)
stdxz = sqrt(binxz2-binxz^2)
stdcyl = sqrt(bincyl2-bincyl^2)
stdyz = sqrt(binyz2-binyz^2)


if not keyword_set(prange) then prange = [min(bincyl,/nan),max(bincyl,/nan)]
xp = xrange[0]+findgen(nbx)*dx + dx/2.
yp = yrange[0]+findgen(nby)*dy + dy/2.
zp = zrange[0]+findgen(nbz)*dz + dz/2.
rp = rrange[0]+findgen(nby)*dr + dr/2.


; Mars shock parameters from Dave Mitchell's code

  R_m = 3389.9D
  x0  = 0.600
  psi = 1.026
  L   = 2.081

; Mars MPB parameters from Dave Mitchell's code

  x0_p1  = 0.640
  psi_p1 = 0.770
  L_p1   = 1.080

  x0_p2  = 1.600
  psi_p2 = 1.009
  L_p2   = 0.528

; Shock conic

      phi = (-150. + findgen(301))*!dtor
      rho = L/(1. + psi*cos(phi))

      xshock = 3376*[x0 + rho*cos(phi)]
      yshock = 3376*rho*sin(phi)

; MPB conic

      phi = (-160. + findgen(160))*!dtor

      rho = L_p1/(1. + psi_p1*cos(phi))
      x1 = x0_p1 + rho*cos(phi)
      y1 = rho*sin(phi)

      rho = L_p2/(1. + psi_p2*cos(phi))
      x2 = x0_p2 + rho*cos(phi)
      y2 = rho*sin(phi)

      indx = where(x1 ge 0)
      jndx = where(x2 lt 0)
      xpileup = [x2[jndx], x1[indx]]
      ypileup = [y2[jndx], y1[indx]]

      phi = findgen(161)*!dtor

      rho = L_p1/(1. + psi_p1*cos(phi))
      x1 = x0_p1 + rho*cos(phi)
      y1 = rho*sin(phi)

      rho = L_p2/(1. + psi_p2*cos(phi))
      x2 = x0_p2 + rho*cos(phi)
      y2 = rho*sin(phi)

      indx = where(x1 ge 0)
      jndx = where(x2 lt 0)
      xpileup = 3376*[xpileup, x1[indx], x2[jndx]]
      ypileup = 3376*[ypileup, y1[indx], y2[jndx]]



ang = findgen(360)*!pi/180

if ptype eq 'scalar' then begin
	if keyword_set(plotnorm) then begin
		bincyl[*,*,0] = normcyl
		binxy[*,*,0] = normxy
		binxz[*,*,0] = normxz
		binyz[*,*,0] = normyz
	endif
	if keyword_set(stddev) then begin
		binxy = stdxy
		binxz = stdxz
		binyz = stdyz
		bincyl = stdcyl
	endif
	
	window,0,xsize = 600,ysize = 600
	specplot,xp,yp,binxy[*,*,0],limits = {xrange:xrange,yrange:yrange,xstyle:1,ystyle:1,zrange:prange,zlog:plog,no_interp:1,xtitle:'X [km]',ytitle:'Y [km]',position:[0.15,0.15,0.9,0.9],charsize:1.5}
	plots,RM*cos(ang),RM*sin(ang),thick = 2
	oplot,xshock,yshock,linestyle = 2,thick = 2
	oplot,xpileup,ypileup,linestyle = 2,thick = 2

	window,1,xsize = 600,ysize = 600
	specplot,xp,zp,binxz[*,*,0],limits = {xrange:xrange,yrange:zrange,xstyle:1,ystyle:1,zrange:prange,zlog:plog,no_interp:1,xtitle:'X [km]',ytitle:'Z [km]',position:[0.15,0.15,0.9,0.9],charsize:1.5}
	plots,RM*cos(ang),RM*sin(ang),thick = 2
	oplot,xshock,yshock,linestyle = 2,thick = 2
	oplot,xpileup,ypileup,linestyle = 2,thick = 2

	window,2,xsize = 840,ysize = 600
	specplot,xp,rp,bincyl[*,*,0],limits = {xrange:xrange,yrange:rrange,xstyle:1,ystyle:1,zrange:prange,zlog:plog,no_interp:1,xtitle:'X [km]',ytitle:'R_YZ [km]',position:[0.15,0.15,0.9,0.9],charsize:1.5}
	oplot,RM*cos(ang),RM*sin(ang),thick = 2
	oplot,xshock,yshock,linestyle = 2,thick = 2
	oplot,xpileup,ypileup,linestyle = 2,thick = 2

	window,3,xsize = 600,ysize = 600
	specplot,yp,zp,binyz[*,*,0],limits = {xrange:yrange,yrange:zrange,xstyle:1,ystyle:1,zrange:prange,zlog:plog,no_interp:1,xtitle:'Y [km]',ytitle:'Z [km]',position:[0.15,0.15,0.9,0.9],charsize:1.5}
	plots,RM*cos(ang),RM*sin(ang),thick = 2
	
endif else begin
	w = where(1-finite(binxy),nw)
	if nw gt 0 then binxy(w) = 1e10
	w = where(1-finite(binxz),nw)
	if nw gt 0 then binxz(w) = 1e10
	w = where(1-finite(binyz),nw)
	if nw gt 0 then binyz(w) = 1e10
	w = where(1-finite(bincyl),nw)
	if nw gt 0 then bincyl(w) = 1e10
	
	window,0,xsize = 600,ysize = 600
	velovect,binxy[*,*,0],binxy[*,*,1],xp,yp,xrange = xrange, yrange = yrange, xtitle = 'X [km]',ytitle = 'Y [km]', len = len, dots = 0,missing = 1e9,charsize = 1.5, thick = 1.5
	plots,RM*cos(ang),RM*sin(ang),thick = 2
	oplot,xshock,yshock,linestyle = 2,thick = 2
	oplot,xpileup,ypileup,linestyle = 2,thick = 2

	window,1,xsize = 600,ysize = 600
	velovect,binxz[*,*,0],binxz[*,*,2],xp,zp,xrange = xrange, yrange = zrange, xtitle = 'X [km]',ytitle = 'Z [km]', len = len, dots = 0,missing = 1e9,charsize = 1.5, thick = 1.5
	plots,RM*cos(ang),RM*sin(ang),thick = 2
	oplot,xshock,yshock,linestyle = 2,thick = 2
	oplot,xpileup,ypileup,linestyle = 2,thick = 2

	window,2,xsize = 840,ysize = 600
	velovect,bincyl[*,*,0],bincyl[*,*,1],xp,rp,xrange = xrange, yrange = rrange, xtitle = 'X [km]',ytitle = 'R_YZ [km]', title = 'In Plane', len = len, dots = 0, missing=1e9, charsize = 1.5, thick =1.5
	oplot,RM*cos(ang),RM*sin(ang),thick = 2
	oplot,xshock,yshock,linestyle = 2,thick = 2
	oplot,xpileup,ypileup,linestyle = 2,thick = 2

	window,3,xsize = 600,ysize = 600
	velovect,binyz[*,*,1],binyz[*,*,2],yp,zp,xrange = yrange, yrange = zrange, xtitle = 'Y [km]',ytitle = 'Z [km]', len = len, dots = 0,missing=1e9, charsize = 1.5, thick = 1.5
	plots,RM*cos(ang),RM*sin(ang),thick = 1,5
endelse

end