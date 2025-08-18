;+
;PROCEDURE:	
;	MVN_SWIA_ALFVEN_TEST
;PURPOSE:	
;	Use Alfven wave test to check density calibration 
;
;INPUT:		
;
;KEYWORDS:
;	BDATA: tplot variable for the magnetic field (needs to be same frame as velocity)
;	NDATA: tplot variable for the (uncalibrated) ion density
;	VDATA: tplot variable for the velocity (needs to be same frame as mag field)
;	TDATA: tplot variable for the temperature (needs to be in magnetic field coords.)
;	TRANGE: time range to do minimum variance (will prompt to choose if not set)
;	ALPHA: If set, try to do anisotropy correction
;
;AUTHOR:	J. Halekas	
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-05-08 13:38:59 -0700 (Fri, 08 May 2015) $
; $LastChangedRevision: 17535 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_alfven_test.pro $
;
;-

pro mvn_swia_alfven_test, bdata = bdata, vdata = vdata, tdata = tdata, ndata = ndata, trange = trange, alpha = alpha

if not keyword_set(bdata) then bdata = 'mvn_B_1sec_MAVEN_MSO'
if not keyword_set(ndata) then ndata = 'nproton'
if not keyword_set(vdata) then vdata = 'mvn_swim_velocity_mso'
if not keyword_set(tdata) then tdata = 'tproton'

if not keyword_set(trange) then ctime,trange,npoints = 2

get_data,bdata,data = bb
get_data,vdata,data  = vel
get_data,tdata,data = temp
get_data,ndata,data = dens

w= where(vel.x ge trange(0) and vel.x le trange(1))
time = vel.x[w]

bx = interpol(bb.y[*,0],bb.x,time)
by = interpol(bb.y[*,1],bb.x,time)
bz = interpol(bb.y[*,2],bb.x,time)
bmag = sqrt(bx*bx+by*by+bz*bz)

vx = interpol(vel.y[*,0],vel.x,time)
vy = interpol(vel.y[*,1],vel.x,time)
vz = interpol(vel.y[*,2],vel.x,time)

tx = interpol(temp.y[*,0],temp.x,time)
ty = interpol(temp.y[*,1],temp.x,time)
tz = interpol(temp.y[*,2],temp.x,time)

nn = interpol(dens.y,dens.x,time)

rc1 = correlate(vy-mean(vy,/nan),by-mean(by,/nan))

if keyword_set(alpha) then begin

	alpha = nn*1e6*(tz-(tx+ty)/2)*1.6e-19*4*!pi*1e-7/(bmag*bmag*1e-18)
	alpha = alpha*2 ;fudge for electrons
	print,mean(alpha)
endif else begin
	alpha = 0.
	alpha = 0.
endelse


vsign = sign(rc1)

rms = fltarr(300)

for i = 1,300 do begin
	un = nn*float(i)/100.
	
	vxth = vsign*bx*1d-9*sqrt((1-alpha)/(4*!pi*1e-7*un*1.67e-27*1e6))/1e3
	vyth = vsign*by*1d-9*sqrt((1-alpha)/(4*!pi*1e-7*un*1.67e-27*1e6))/1e3
	vzth = vsign*bz*1d-9*sqrt((1-alpha)/(4*!pi*1e-7*un*1.67e-27*1e6))/1e3

	mvx = mean(vxth,/nan)
	mvy = mean(vyth,/nan)
	mvz = mean(vzth,/nan)

	vxth = vxth-mvx+mean(vx,/nan)
	vyth = vyth-mvy+mean(vy,/nan)
	vzth = vzth-mvz+mean(vz,/nan)

	rms[i-1] = sqrt(total(((vx-vxth-mean(vx,/nan)+mvx)^2 + (vy-vyth-mean(vy,/nan)+mvy)^2 + (vz-vzth-mean(vz,/nan)+mvz)^2)))

endfor

minr = min(rms,mini)

un = nn*float(mini+1)/100.

print,(mini+1)/100.

vxth = vsign*bx*1d-9*sqrt((1-alpha)/(4*!pi*1e-7*un*1.67e-27*1e6))/1e3
vyth = vsign*by*1d-9*sqrt((1-alpha)/(4*!pi*1e-7*un*1.67e-27*1e6))/1e3
vzth = vsign*bz*1d-9*sqrt((1-alpha)/(4*!pi*1e-7*un*1.67e-27*1e6))/1e3

vxth = vxth-mean(vxth)+mean(vx)
vyth = vyth-mean(vyth)+mean(vy)
vzth = vzth-mean(vzth)+mean(vz)

store_data,'vth',data = {x:time,y:[[vxth],[vyth],[vzth]]}


un = nn

vxth = vsign*bx*1d-9*sqrt((1-alpha)/(4*!pi*1e-7*un*1.67e-27*1e6))/1e3
vyth = vsign*by*1d-9*sqrt((1-alpha)/(4*!pi*1e-7*un*1.67e-27*1e6))/1e3
vzth = vsign*bz*1d-9*sqrt((1-alpha)/(4*!pi*1e-7*un*1.67e-27*1e6))/1e3

vxth = vxth-mean(vxth)+mean(vx)
vyth = vyth-mean(vyth)+mean(vy)
vzth = vzth-mean(vzth)+mean(vz)

store_data,'vth1',data = {x:time,y:[[vxth],[vyth],[vzth]]}


end
