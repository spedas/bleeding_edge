
;+
;
;
;INPUTS:
;- unix_in: a double precision array in UNIX time, of the times you want to know if the MAVEN is in Mars shadow or not. NOTE:
;           this array must be the same array you used to obtain maven position, from mvn_lpw_anc_spacecraft.
;
;OUTPUTS:
;tplot variable containing shadow information for MAVEN:
;- mvn_lpw_anc_mvn_mars_shadow, 1=in shadow, 0=sunlit
;
;-
;

pro mvn_lpw_anc_boom_mars_shadow, unix_in

proname = 'mvn_lpw_anc_boom_mars_shadow'

tnames = tnames()  ;list of tplot variables in memory

if total(strmatch(tnames, 'mvn_lpw_anc_mvn_pos_mso')) eq 0. then begin
      print, proname, ": #### WARNING #### : maven position information not found. Please run mvn_lpw_anc_spacecraft first. Skipping."
      retall  
endif

;To first order, take the MSO radius. If this is <Mars radius, and X < 0, we are in shadow. Do we want to do it more accurately as Mars is not
;a sphere? Not sure how to get Mars' radius as a function of latitude though.

get_data, 'mvn_lpw_anc_mvn_pos_mso', data=dd1, dlimit=dlimit2, limit=limit2

shadow_flag = dd1.flag  ;flag info on when we have kernel coverage.

nele_in = n_elements(unix_in)
nele = n_elements(dd1.x)

if nele_in ne nele then begin
    print, proname, ": ### WARNING ### : input UNIX time array must be the same array as that used to obtain MAVEN position from"
    print, "mvn_lpw_anc_spacecraft.pro (it is currently a different length). Skipping."
    retall
endif

rmars = 3376.  ;km
dd1.y = dd1.y*rmars  ;convert to km
radius = sqrt(dd1.y[*,1]^2 + dd1.y[*,2]^2)  ;'radius' of MAVEN in y-z plane.

shadow = fltarr(nele)

for aa = 0, nele-1 do if (dd1.y[aa,0] lt 0.) and (radius[aa] lt rmars) then shadow[aa] = 1.  ;1 means shadow, 0 means sunlit

;Store as tplot var:
;------------------------------------
dlimit2.Product_name = 'mvn_lpw_anc_boom_mvn_mars_shadow'
dlimit2.x_catdesc = 'Timestamps for each data point, in UNIX time.'
dlimit2.y_catdesc = 'Description of whether the MAVEN spacecraft is in the shadow of Mars or not. 1 means in shadow, 0 means in sunlight.'
;dlimit2.v_catdesc = 'test dlimit file, v'
dlimit2.dy_catdesc = 'Error on the data.'
;dlimit2.dv_catdesc = 'test dlimit file, dv'
dlimit2.flag_catdesc = 'Flag equals 1 when no SPICE times available.'
dlimit2.x_Var_notes = 'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.'
dlimit2.y_Var_notes = 'Shadow based on MAVEN position in the MSO coordinate frame. Radius of Mars taken to be '+strtrim(rmars,2)+'km.'
;dlimit2.v_Var_notes = 'Frequency bins'
dlimit2.dy_Var_notes = 'Not used.'
;dlimit2.dv_Var_notes = 'Error on frequency'
dlimit2.flag_Var_notes = '0 = no flag: SPICE times available; 1 = flag: no SPICE times available.'
dlimit2.xFieldnam = 'x: More information'
dlimit2.yFieldnam = 'y: More information'
;dlimit2.vFieldnam = 'v: More information'
dlimit2.dyFieldnam = 'dy: Not used.'
;dlimit2.dvFieldnam = 'dv: More information'
dlimit2.flagFieldnam = 'flag: based off of SPICE ck and spk kernel coverage.'

dlimit2.scalemax = 1.
dlimit2.ysubtitle='[1:shadow,0:sunlit]'
limit2.ytitle = 'MAVEN shadow'
limit2.yrange=[-1., 2.]
limit2.labels=''
limit2.colors = 0.
;------------------------------------
store_data, 'mvn_lpw_anc_boom_mvn_mars_shadow', data={x: unix_in, y: shadow, flag:shadow_flag}, dlimit=dlimit2, limit=limit2
options, 'mvn_lpw_anc_boom_mvn_mars_shadow', labels=''

end

