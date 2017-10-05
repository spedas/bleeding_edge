;+
;PROCEDURE: 
;	MVN_SWIA_PLOT_ORB_WHISK
;PURPOSE: 
;	Routine to plot whiskers of any quantity (default: magnetic field) on the orbit
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_PLOT_ORB_WHISK
;INPUTS:
;KEYWORDS:
;	TR: Time range (uses current tplot if not set)
;	FREQ: How much to decimate the whisker quantity
;	XRANGE, YRANGE, ZRANGE: Obvious
;	LEN: Whisker length (multiplied by whisker magnitude)
;	BNORM: Normalize by length of whisker (otherwise all have same length)
;	PDATA: Tplot variable for position data (defaults to MSO position)
;	BDATA: Tplot variable for whisker data (defaults to MSO B)
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-07-15 06:58:10 -0700 (Wed, 15 Jul 2015) $
; $LastChangedRevision: 18133 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_plot_orb_whisk.pro $
;
;-

pro mvn_swia_plot_orb_whisk, tr = tr,freq = freq,xrange = xrange, yrange = yrange,zrange = zrange, len = len, bnorm = bnorm, pdata = pdata, bdata = bdata


RM = 3397.

if not keyword_set(freq) then freq = 1
if not keyword_set(xrange) then xrange = [-8e3,8e3]
if not keyword_set(yrange) then yrange = [-8e3,8e3]
if not keyword_set(zrange) then zrange = [-8e3,8e3]
if not keyword_set(pdata) then pdata = 'MAVEN_POS_(MARS-MSO)'
if not keyword_set(bdata) then bdata = 'mvn_B_1sec_MAVEN_MSO'
if not keyword_set(len) then len = 1000

@tplot_com

if not keyword_set(tr) then tr = tplot_vars.options.trange

get_data,pdata,data = pos
get_data,bdata,data = mag


w = where(mag.x ge tr[0] and mag.x le tr[1],nel)

time = mag.x[w]

magx = interpol(mag.y[*,0],mag.x,time)
magy = interpol(mag.y[*,1],mag.x,time)
magz = interpol(mag.y[*,2],mag.x,time)
xart = interpol(pos.y[*,0],pos.x,time)
yart = interpol(pos.y[*,1],pos.x,time)
zart = interpol(pos.y[*,2],pos.x,time)


mag = sqrt(magx*magx+magy*magy+magz*magz)
if not keyword_set(bnorm) then begin
	magx = magx/mag
	magy = magy/mag
	magz = magz/mag
	mag = mag*0.0+1
endif

window,0
ang = findgen(360)*!pi/180
plot,/iso,RM*cos(ang),RM*sin(ang),thick = 2,xrange = xrange, yrange = yrange,xtitle = 'X (km)',ytitle = 'Y (km)',charsize=2

if not keyword_set(len) then delta = findgen(5000)*20-50000. else delta = findgen(100)*len/99

for i = 0,nel-1,freq do begin

	oplot,xart[i]+magx[i]*delta,yart[i]+magy[i]*delta, color = magz[i]/mag[i]*125 + 125
	
endfor
oplot,xart,yart,thick = 2
xyouts,xart[0],yart[0],time_string(time[0])
xyouts,xart[nel-1],yart[nel-1],time_string(time[nel-1])

window,2
ang = findgen(360)*!pi/180
plot,/iso,RM*cos(ang),RM*sin(ang),thick = 2,xrange = xrange, yrange = zrange,xtitle = 'X (km)',ytitle = 'Z (km)',charsize=2


for i = 0,nel-1,freq do begin

	oplot,xart[i]+magx[i]*delta,zart[i]+magz[i]*delta, color = magy[i]/mag[i]*125 + 125
	
endfor
oplot,xart,zart,thick = 2
xyouts,xart[0],zart[0],time_string(time[0])
xyouts,xart[nel-1],zart[nel-1],time_string(time[nel-1])



window,3
ang = findgen(360)*!pi/180
plot,/iso,RM*cos(ang),RM*sin(ang),thick = 2,xrange = yrange, yrange = zrange,xtitle = 'Y (km)',ytitle = 'Z (km)',charsize=2


for i = 0,nel-1,freq do begin

	oplot,yart[i]+magy[i]*delta,zart[i]+magz[i]*delta, color = magx[i]/mag[i]*125 + 125
	
endfor
oplot,yart,zart,thick = 2
xyouts,yart[0],zart[0],time_string(time[0])
xyouts,yart[nel-1],zart[nel-1],time_string(time[nel-1])





end