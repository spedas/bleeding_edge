;+
;  crib_tt96
;
; Purpose: demonstrates the use of the tt96 procedure.  This procedure
; is tplot based version of the Tsyganenko 96 magnetic fields model
;
; Notes: Haje Korth's IDL/Geopack DLM must be installed for this
;        to work
;        Sometimes these routines can take a while to run.
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-12-16 17:16:12 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13685 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/examples/crib_tt96.pro $
;-

;timespan, '2008-07-02'
timespan, '2010-02-02';date chosen at random

;load state data

thm_load_state, probe = 'b', coord = 'gsm'

;calculate model field

;example values were pulled from Tsyganenko's papers

tt96, 'thb_state_pos',pdyn=2.0D,dsti=-30.0D,yimf=0.0D,zimf=-5.0D

;load fgm data for comparison

thm_load_fgm, probe = 'b', coord = 'gsm', level = 2

tplot_names

tplot, ['thb_state_pos_bt96', 'thb_fgs_gsm']

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
tinterpol_mxn,'thb_state_pos_bt96','thb_fgs_gsm',newname='thb_state_pos_bt96'

;now translate magnetometer data into model aligned coordinates

;first we make the transformation matrix

fac_matrix_make, 'thb_state_pos_bt96', other_dim = 'Xgse', newname = $

'mod_mat'

;then we rotate

tvector_rotate, 'mod_mat', 'thb_fgs_gsm'

tplot_names

;model field, measured field, measured field in model coordinates

tplot, ['thb_state_pos_bt96', 'thb_fgs_gsm', 'thb_fgs_gsm_rot']

stop

;now substract model from the fgs data

;first interpolate the values onto the same grid

tinterpol_mxn,'thb_state_pos_bt96','thb_fgs_gsm',newname='mod_interp'

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

;tlimit,'2008-02-02/18:03:00','2008-02-02/17:48:05'


stop

;demonstrates model using auto parameter generation

;the ace & wind read procedures use the current tlimit to figure out

;what data range to read

;here is wind data parameter generation

;you may have to set the default download directory manually
;here are some examples:
;setenv,'ROOT_DATA_DIR=~/data' ;good for single user unix/linux system
;setenv,'ROOT_DATA_DIR=C:/Documents and Settings/YOURUSERNAME/My Documents' ;example  if you don't want to use the default windows location (C:/data/ or E:/data/)

tlimit,/full

;load kyoto dst
kyoto_load_dst

;load wind data

wi_mfi_load
wi_3dp_load

cotrans,'wi_h0_mfi_B3GSE','wi_b3gsm',/GSE2GSM

get_tsy_params,'kyoto_dst','wi_b3gsm',$

'wi_3dp_k0_ion_density','wi_3dp_k0_ion_vel','T96'

tt96, 'thb_state_pos',parmod='t96_par'

tplot, ['thb_state_pos_bt96', 'thb_fgs_gsm']

stop

;now do the same thing with ace data

ace_mfi_load
ace_swe_load

;load_ace_mag loads data in gse coords

cotrans,'ace_k0_mfi_BGSEc','ace_mag_Bgsm',/GSE2GSM

get_tsy_params,'kyoto_dst','ace_mag_Bgsm',$

'ace_k0_swe_Np','ace_k0_swe_Vp','T96',/speed

tt96, 'thb_state_pos',parmod='t96_par'

tplot, ['thb_state_pos_bt96', 'thb_fgs_gsm']

stop

;omni data example
;NOTE: you may want to degap and deflag the data(using tdegap and tdeflag)
;to remove gaps and flags in the tsyganemo parameter data, especially
;if you find that there are large gaps in the result  

omni_hro_load

store_data,'omni_imf',data=['OMNI_HRO_1min_BY_GSM','OMNI_HRO_1min_BZ_GSM']

get_tsy_params,'kyoto_dst','omni_imf',$

'OMNI_HRO_1min_proton_density','OMNI_HRO_1min_flow_speed','T96',/speed,/imf_yz

tt96, 'thb_state_pos',parmod='t96_par'

tplot, ['thb_state_pos_bt96', 'thb_fgs_gsm']

stop

;dipole tilt example
;add one degree to dipole tilt
;Can also add time varying tilts, or replace the default dipole tilt with a user defined value
tt96, 'thb_state_pos',pdyn=2.0D,dsti=-30.0D,yimf=0.0D,zimf=-5.0D,get_tilt='tilt_vals',add_tilt=1
tplot, ['thb_state_pos_bt96', 'thb_fgs_gsm','tilt_vals']

end

