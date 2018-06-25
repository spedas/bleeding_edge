;+
; Batch File: THM_CRIB_COTRANS
;
; Purpose:  Demonstrate how to use thm_cotrans and cotrans.
; Examples will be shown for both tplot variables and array data.
;
; Calling Sequence:
; .run thm_crib_cotrans, or using cut-and-paste.
;
; Arguements:
;   None.
;
; Notes:
; None.
; 
; See Also:
;    examples/advanced/thm_crib_fac.pro (field aligned coordinate systems)
;    examples/advanced/thm_crib_mva.pro (minimum variance coordinate systems)
;    examples/advanced/thm_crib_rxy.pro (radial position coordinate systems)
;    examples/advanced/thm_crib_slp_sse.pro (selenocentric coordinate systems)
;    
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-06-08 14:29:18 -0700 (Fri, 08 Jun 2018) $
; $LastChangedRevision: 25338 $
; $URL $
;-


;*********************************************************************
;  This section demonstrates that J2000 -> GEI -> J2000
;  gives small errors ( e-16 ) for the unit vector
;*********************************************************************

coord1='j2000' & coord2 = 'gei'
ex = [ 1.0d, 0.0d, 0.0d ]
t1 = time_double('2000-01-01') + dindgen(1441)*60
t2 = time_double('2004-04-01') + dindgen(1441)*60
t3 = time_double('2008-08-01') + dindgen(1441)*60
store_data, 'ex', data={x:[t1,t2,t3], y:rebin(transpose(ex), 1441*3, 3)}
spd_cotrans, 'ex', 'ex_other', in_coord=coord1, out_coord=coord2
spd_cotrans, 'ex_other', 'ex2', in_coord=coord2, out_coord=coord1
get_data, 'ex', 0, ex1  &  get_data, 'ex2', 0, ex2

print, 'J2000 -> GEI -> J2000 error:', minmax( ex2-ex1 )

stop

;*********************************************************************
;  Load THEMIS data
;*********************************************************************

; Start with a clean slate
del_data,'*'

thm_init

; Set the time frame
timespan,'2007-06-23'

; Load some state and fgm data for use with cotrans
thm_load_state,probe='a', /get_support_data      
thm_load_fgm,lev=1,probe=['a'],/get_support_data,type='raw', suffix='_raw'
thm_cal_fgm,probe=['a'],datatype='fg?',in_suffix='_raw', out_suffix='_ssl'

; To check the coordinate system of the downloaded data you can extract
; the data from the tplot variable
get_data, 'tha_state_pos', data=d, dlimits=dl, limits=l
help, d, /struc
help, dl, /struc
help, dl.data_att, /struc

; Plot fgm data
tplot_options, 'title', 'THEMIS FGM Examples'
tplot, ['tha_fgl_raw', 'tha_fgl_ssl']

print, 'Type .c to continue'
stop


;*******************************************************************
;  This section shows how to use thm_cotrans with tplot variables
;*******************************************************************

; Convert fgm from ssl to dsl coordinates
; Note: thm_contrans accepts probe and datatype keywords:
thm_cotrans,probe=['a'],datatype='fg?',in_suffix='_ssl', out_suffix='_dsl', out_coord='dsl'

; Convert fgm dsl to gse coordinates
; Note: thm_cotrans can also work directly with tplot names:
thm_cotrans,'tha_fg?',in_suf='_dsl',out_suf='_gse', out_c='gse'

; Convert fgm gse to gsm coordinates
; Note: you can also specify output tplot names:
thm_cotrans,'tha_fgl_gse','tha_fgl_gsm', out_c='gsm'

; thm_cotrans also handles updating the tplot variables coordinate system 
get_data, 'tha_fgl_dsl', data=d, dlimits=dl, limits=l
help, d, /struc
help, dl, /struc
help, dl.data_att, /struc
print, 'Above is an example of the updated tplot variable coordinate sytem 
print, ' ' 

; This shows a list of supported coordinate systems for thm_cotrans
coordSysObj = obj_new('thm_ui_coordinate_systems')
print, 'Supported coordinate systems:  '
print, coordSysObj->makeCoordSysList()
print, ' '

; Plot results
tplot, ['tha_fgl_raw', 'tha_fgl_ssl', 'tha_fgl_dsl', 'tha_fgl_gse','tha_fgl_gsm']

print, 'Here is a plot of the fgl conversions.'
print, 'Type .c to continue'
print, ' '
stop

;*********************************************************************
;  This section demonstrates how to use cotrans with tplot variables
;*********************************************************************

; Now we transform the coordinates
cotrans,'tha_state_pos','tha_state_pos_gse',/gei2gse
cotrans,'tha_state_vel','tha_state_vel_gse',/gei2gse

tplot_names
print,'We just transformed to gse'
print,'Heres a list of our coordinate transformed variables'

tplot,['tha_state_pos_gse','tha_state_vel_gse']

print,'Heres a plot of our coordinate transformed variables'
stop

;****************************************************************
; This section shows how to use cotrans with array data
;****************************************************************

; Extract the data from the tplot variables
get_data, 'tha_state_pos_gse', data=pos_gse, dlimit=dl_gse, limit=l_gse
help, d, /struc
help, dl, /struc
help, dl.data_att, /struc

; Convert array data from gse 2 geo coordinates
; Note: there is no direct conversion from gse 2 geo so we will
; first have to convert to gei and then to geo (available conversions
; are described in the header section of cotrans.pro
cotrans, pos_gse.y, pos_gei, pos_gse.x, /gse2gei
; Note: the transformed data pos_geo is returned as an nx3 array
; the time is the same as pos_gse.x
help, pos_gei
cotrans, pos_gei, pos_geo, pos_gse.x, /gei2geo

; And then convert geo 2 mag
cotrans, pos_geo, pos_mag, pos_gse.x, /geo2mag

; Plot the results
window, xsize=750, ysize=750
plot, pos_geo[*,0], pos_geo[*,1], xtitle='x-pos', ytitle='y-pos', $
      subtitle='[Red-GEO, Blue-MAG, Green-GEI, Purple=GSE]', title='GSE 2 GEI 2 GEO 2 MAG Conversions'
oplot, pos_geo[*,0], pos_geo[*,1], color=250
oplot, pos_mag[*,0], pos_mag[*,1], color=90
oplot, pos_gei[*,0], pos_gei[*,1], color=150
oplot, pos_gse.y[*,0], pos_gse.y[*,1], color=30

print, 'This is a plot of the coordinate transforms using cotrans with array data'
stop

;****************************************************************
; Many THEMIS load routines can automatically generate
; Your desired output coordinates
;****************************************************************

thm_load_fgm,probe='a',coord='mag'
thm_load_efi,probe='a',coord='gei'
thm_load_fit,probe='a',coord='gsm'
;etc...

print,'Data loaded and transformed automatically'
stop


END
