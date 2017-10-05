;+
;PROCEDURE: 
;	MVN_SWIA_STACOMP
;PURPOSE: 
;	Routine to compare density and velocity from SWIA to STATIC
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_STACOMP, TYPE = TYPE, TRANGE = TRANGE
;INPUTS:
;KEYWORDS:
;	TYPE: STATIC data type to use for moments
;	TRANGE: time range to use
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-11-30 11:23:33 -0800 (Mon, 30 Nov 2015) $
; $LastChangedRevision: 19496 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_stacomp.pro $
;
;-

pro mvn_swia_stacomp, type = type, trange = trange, temperature = temperature

if not keyword_set(trange) then ctime,trange,npoints = 2
if not keyword_set(type) then type = 'd0'

get_4dt,'n_4d','mvn_sta_get_'+type,mass = [0.3,1.8],name = 'np', t1= trange(0),t2 = trange(1)
get_4dt,'n_4d','mvn_sta_get_'+type,mass = [1.8,2.5],name = 'na', t1= trange(0),t2 = trange(1)
get_4dt,'n_4d','mvn_sta_get_'+type,mass = [10,20],name = 'no', t1= trange(0),t2 = trange(1)
get_4dt,'n_4d','mvn_sta_get_'+type,mass = [20,40],name = 'no2', t1= trange(0),t2 = trange(1)
get_4dt,'v_4d','mvn_sta_get_'+type,mass = [0.3,1.8],name = 'vp', t1= trange(0),t2 = trange(1)
get_4dt,'v_4d','mvn_sta_get_'+type,mass = [1.5,2.5],name = 'va', t1= trange(0),t2 = trange(1)
get_4dt,'v_4d','mvn_sta_get_'+type,mass = [10,20],name = 'vo', t1= trange(0),t2 = trange(1)
get_4dt,'v_4d','mvn_sta_get_'+type,mass = [20,40],name = 'vo2', t1= trange(0),t2 = trange(1)


if keyword_set(temperature) then begin
	get_4dt,'t_4d','mvn_sta_get_'+type,mass = [0.3,1.8],name = 'tp', t1= trange(0),t2 = trange(1)
	get_4dt,'t_4d','mvn_sta_get_'+type,mass = [1.8,2.5],name = 'ta', t1= trange(0),t2 = trange(1)
	get_4dt,'t_4d','mvn_sta_get_'+type,mass = [10,20],name = 'to', t1= trange(0),t2 = trange(1)
	get_4dt,'t_4d','mvn_sta_get_'+type,mass = [20,40],name = 'to2', t1= trange(0),t2 = trange(1)
endif


get_data,'np',data = np
get_data,'na',data = na
get_data,'no',data = no
get_data,'no2',data = no2
get_data,'vp',data = vp
get_data,'va',data = va
get_data,'vo',data = vo
get_data,'vo2',data = vo2


ntot = np.y + na.y/sqrt(2) + no.y/sqrt(16) + no2.y/sqrt(32)
ftot = (np.y#replicate(1,3)) * vp.y + (na.y#replicate(1,3)) * va.y + (no.y#replicate(1,3)) * vo.y + (no2.y#replicate(1,3))*vo2.y

vtot = ftot/(ntot#replicate(1,3))

store_data,'nswista',data = {x:np.x,y:ntot}
store_data,'vswista',data = {x:np.x,y:vtot,v:[0,1,2]}

get_data,'mvn_sta_c6_E',data = sta

ts = sta.x
mspec = sta.y
en = sta.v
nts = n_elements(ts)


ospec = sta.y
o2spec = sta.y
pspec = sta.y

for i = 0,nts-1 do begin 
	dat = mvn_sta_get_c6(ts(i))
	dat = conv_units(dat,'eflux')
	for j = 0,31 do begin 
		w = where(dat.mass_arr(j,*) le 4)
		pspec(i,j) = total(dat.data(j,w))
		w = where(dat.mass_arr(j,*) gt 8 and dat.mass_arr(j,*) lt 24)
		ospec(i,j) = total(dat.data(j,w))
		w = where(dat.mass_arr(j,*) gt 24 and dat.mass_arr(j,*) lt 40)
		o2spec(i,j) = total(dat.data(j,w))
	endfor
endfor

store_data,'pspec',data = {x:ts,y:pspec,v:en,ylog:1,spec:1,zlog:1,no_interp:1,yrange:[1,1e4]}
store_data,'ospec',data = {x:ts,y:ospec,v:en,ylog:1,spec:1,zlog:1,no_interp:1,yrange:[1,1e4]}
store_data,'o2spec',data = {x:ts,y:o2spec,v:en,ylog:1,spec:1,zlog:1,no_interp:1,yrange:[1,1e4]}


end