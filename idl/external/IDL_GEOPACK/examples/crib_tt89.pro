;+
;  crib_tt89
;
; Purpose: demonstrates the use of the tt89 procedure.  This procedure
; is tplot based version of the Tsyganenko 89 magnetic fields model
;
; Notes: Haje Korth's IDL/Geopack DLM must be installed for this
;        to work
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-12-16 17:16:12 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13685 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/examples/crib_tt89.pro $
;-

timespan, '2007-03-23'

;load state data

thm_load_state, probe = 'b', coord = 'gsm'

;calculate model field

tt89, 'thb_state_pos'

;load fgm data for comparison

thm_load_fgm, probe = 'b', coord = 'gsm', level = 2

tplot_names

tplot, ['thb_state_pos_bt89', 'thb_fgs_gsm']

stop

;To properly match the elements of the model field and 'thb_fgs_gsm',
;We need to either (1) sort the input vectors, so that the tvector_rotate procedure can match rotations
;or (2) interpolate the model field on to the data

;Option 1: Sorting
;get_data,'thb_fgs_gsm',data=d ;get data
;sorted = uniq(d.x,bsort(d.x)) ;sort and remove duplication
;store_data,'thb_fgs_gsm',data={x:d.x[sorted],y:d.y[sorted,*]};store again

;Option 2: interpolation
;
tinterpol_mxn,'thb_state_pos_bt89','thb_fgs_gsm',newname='thb_state_pos_bt89'


;now translate magnetometer data into model aligned coordinates

;first we make the transformation matrix

fac_matrix_make, 'thb_state_pos_bt89', other_dim = 'Xgse', newname = $

'mod_mat'

;then we rotate

tvector_rotate, 'mod_mat', 'thb_fgs_gsm'

tplot_names

;model field, measured field, measured field in model coordinates

tplot, ['thb_state_pos_bt89', 'thb_fgs_gsm', 'thb_fgs_gsm_rot']

stop

;now substract model from the fgs data

;first interpolate the values onto the same grid

tinterpol_mxn,'thb_state_pos_bt89','thb_fgs_gsm',newname='mod_interp'

;now subtract

dif_data,'thb_fgs_gsm','mod_interp',newname='fgs_dif'

;set it up so model and fgm data are on the same plot

get_data,'mod_interp',data=d1

get_data,'thb_fgs_gsm',data=d2,dlimits=dl

d = {x:d1.x,y:[[d1.y],[double(d2.y)]],v:d1.v}

str_element,/add_replace,dl,'colors',[dl.colors,dl.colors]

str_element,/add_replace,dl,'labels',[dl.labels,dl.labels]

store_data,'mod_fgm',data=d,dlimits=dl

ylim,'fgs_dif',-400,1000

;to reset to autoscaling on the y axis type

;ylim,'fgs_dif',/default

;now plot

tplot,['mod_fgm','fgs_dif']

tlimit,'2007-03-23/18:03:00','2007-03-23/17:48:05'

stop

;dipole tilt example
;add one degree to dipole tilt
;Can also add time varying tilts, or replace the default dipole tilt with a user defined value
tt89, 'thb_state_pos',kp=2.0,get_tilt='tilt_vals',add_tilt=1
tplot, ['thb_state_pos_bt96', 'thb_fgs_gsm','tilt_vals']

end

