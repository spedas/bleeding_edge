;+
;PROCEDURE: 
;	MVN_SWIA_REGID
;PURPOSE: 
;	Routine to determine region of the Mars environment from SWIA and MAG data.
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_REGID
;INPUTS:
;KEYWORDS:
;	TR: Time range (uses current tplot if not set)
;	BDATA: Magnetic field data (needs to be in MSO )
;	FBDATA: Full resolution magnetic field data (any coordinate system, just for RMS)
;	PDATA: Position data (needs to be in MSO)
;	NOLOBE: Don't try to find lobe (allows us to skip B in MSO and save a lot of rotation time)
;OUTPUTS:
;	REGOUT: Tplot structure containing region IDs
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-04-21 12:37:59 -0700 (Tue, 21 Apr 2015) $
; $LastChangedRevision: 17384 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_regid.pro $
;
;-

pro mvn_swia_regid, tr = tr, bdata = bdata, fbdata = fbdata, pdata = pdata, regout, nolobe = nolobe


RM = 3397.

@tplot_com
common mvn_swia_data

if not keyword_set(bdata) then begin
	if keyword_set(nolobe) then bdata = 'mvn_B_1sec' else bdata = 'mvn_B_1sec_MAVEN_MSO'
endif

if not keyword_set(fbdata) then fbdata = 'mvn_B_full'
if not keyword_set(pdata) then pdata = 'MAVEN_POS_(MARS-MSO)'
if not keyword_set(tr) then tr = tplot_vars.options.trange


get_data,pdata,data = pos
get_data,fbdata,data = mag
get_data,bdata,data = lmag



w = where(swim.time_unix ge tr[0] and swim.time_unix le tr[1],nel)

time = swim[w].time_unix + 2.0 	; Center time

ux = interpol(pos.y[*,0],pos.x,time)
uy = interpol(pos.y[*,1],pos.x,time)
uz = interpol(pos.y[*,2],pos.x,time)
uyz = sqrt(uy^2 + uz^2)
alt = sqrt(ux^2+uy^2+uz^2)-RM


nmagint = floor(n_elements(mag.x)/128L)

mrx = fltarr(nmagint)
mry = fltarr(nmagint)
mrz = fltarr(nmagint)
mt = dblarr(nmagint)

for i = 0L,nmagint-1 do begin
	mt(i) = mean(mag.x[i*128:i*128+127],/nan,/double)
	mrx(i) = stddev(mag.y[i*128:i*128+127,0],/nan)
	mry(i) = stddev(mag.y[i*128:i*128+127,1],/nan)
	mrz(i) = stddev(mag.y[i*128:i*128+127,2],/nan)
endfor

nmag2 = floor(n_elements(lmag.x)/16L)
mrx2 = fltarr(nmag2)
mry2 = fltarr(nmag2)
mrz2 = fltarr(nmag2)
mt2 = fltarr(nmag2)

for i = 0L,nmag2-1 do begin
	mt2(i) = mean(lmag.x[i*16:i*16+15],/nan,/double)
	mrx2(i) = stddev(lmag.y[i*16:i*16+15,0],/nan)
	mry2(i) = stddev(lmag.y[i*16:i*16+15,1],/nan)
	mrz2(i) = stddev(lmag.y[i*16:i*16+15,2],/nan)
endfor


magx = interpol(lmag.y(*,0),lmag.x,time)
magy = interpol(lmag.y(*,1),lmag.x,time)
magz = interpol(lmag.y(*,2),lmag.x,time)
mag = sqrt(magx*magx+magy*magy+magz*magz)
magstd = interpol(sqrt(mrx*mrx+mry*mry+mrz*mrz),mt,time)
magstd2 = interpol(sqrt(mrx2*mrx2+mry2*mry2+mrz2*mrz2),mt2,time)

store_data,'magave',data = {x:time,y:[[magx],[magy],[magz]]}
store_data,'magstd',data = {x:time,y:magstd}
store_data,'magstd2',data= {x:time,y:magstd2}

regid = fltarr(nel)

temp = total(swim[w].temperature,1)/3
vel = sqrt(total(swim[w].velocity*swim[w].velocity,1))
dens = swim[w].density

w = where(vel gt 200 and (sqrt(temp)/vel lt 0.012 and magstd/mag lt 0.15) and alt gt 500)
regid(w) = 1	;Solar Wind

w = where(vel gt 200 and (sqrt(temp)/vel gt 0.015 or magstd/mag gt 0.25) and alt gt 300)
regid(w) = 2	;Sheath

w = where((vel lt 100 or dens lt 0.1) and magstd/mag lt 0.1 and mag gt 10 and alt lt 500)
regid(w) = 3	;Ionosphere

w = where((vel lt 100 or dens lt 0.1) and magstd/mag lt 0.1 and mag gt 10 and alt lt 250 and alt gt 140 and (ux gt 0 or uyz gt RM))
regid(w) = 4 ;Periapsis Dayside Ionosphere

w = where(vel lt 200 and magstd/mag lt 0.1 and abs(magx/mag) gt 0.9 and ux lt 0 and alt gt 300)
if not keyword_set(nolobe) then regid(w) = 5	;Tail Lobe

regout = {x:time,y:[[regid],[regid]],v:[0,1],spec:1}

store_data,'regid',data = regout,limits = {panel_size:0.1, no_interp:1}


end