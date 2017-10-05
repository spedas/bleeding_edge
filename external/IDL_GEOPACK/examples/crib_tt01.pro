;+
;  crib_tt01
;
; Purpose: demonstrates the use of the tt01 procedure.  This procedure
; is tplot based version of the Tsyganenko 2001 magnetic fields model
;
; Notes: Haje Korth's IDL/Geopack DLM must be installed for this
;        to work
;        Sometimes these routines can take a while to run.
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-12-16 17:16:12 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13685 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/examples/crib_tt01.pro $
;-

timespan, '2010-02-02'

;load state data

thm_load_state, probe = 'b', coord = 'gsm'

;calculate model field

;example values were taken from Tsyganenko's papers, they don't

;reflect the actual conditions at this time

tt01, 'thb_state_pos',pdyn=2.0D,dsti=-30.0D,yimf=0.0D,zimf=-5.0D,$
g1=6.0D,g2=10.0D

;load fgm data for comparison

thm_load_fgm, probe = 'b', coord = 'gsm', level = 2

tplot_names

tplot, ['thb_state_pos_bt01', 'thb_fgs_gsm']

stop

;you can also generate g values using a built in geopack function

;the arguments are solar wind velocity(km/s) interplanetary magnetic

;field y component(nT) interplanetary magnetic field z component(nT)

;if you pass in N length arrays for each of the arguments it will

;produce an Nx2 length output

geopack_getg,350,0,-5,g

tt01, 'thb_state_pos',pdyn=2.0D,dsti=-30.0D,yimf=0.0D,zimf=-5.0D,g1=g[$

0,0],g2=g[0,1]

;load fgm data for comparison

thm_load_fgm, probe = 'b', coord = 'gsm', level=2

tplot_names

tplot, ['thb_state_pos_bt01', 'thb_fgs_gsm']

;To properly match the elements of the model field and 'thb_fgs_gsm',
;We need to either (1) sort the input vectors, so that the tvector_rotate procedure can match rotations
;or (2) interpolate the model field on to the data

;Option 1: Sorting
;get_data,'thb_fgs_gsm',data=d ;get data
;sorted = uniq(d.x,bsort(d.x)) ;sort and remove duplication
;store_data,'thb_fgs_gsm',data={x:d.x[sorted],y:d.y[sorted,*]};store again

;Option 2: interpolation
;
tinterpol_mxn,'thb_state_pos_bt01','thb_fgs_gsm',newname='thb_state_pos_bt01'

;now translate magnetometer data into model aligned coordinates

;first we make the transformation matrix

fac_matrix_make, 'thb_state_pos_bt01', other_dim = 'Xgse', newname = $

'mod_mat'

;then we rotate

tvector_rotate, 'mod_mat', 'thb_fgs_gsm'

tplot_names

;model field, measured field, measured field in model coordinates

tplot, ['thb_state_pos_bt01', 'thb_fgs_gsm', 'thb_fgs_gsm_rot']

stop

;now substract model from the fgs data

;first interpolate the values onto the same grid

tinterpol_mxn,'thb_state_pos_bt01','thb_fgs_gsm',newname='mod_interp'

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

;tlimit,'2010-02-02/18:03:00','2010-02-02/17:48:05'

stop

;the ace & wind read procedures use the current tlimit to figure out

;what data range to read

;here is wind data parameter generation

;you may have to set the default download directory manually
;here are some examples:
;setenv,'ROOT_DATA_DIR=~/data' ;good for single user unix/linux system
;setenv,'ROOT_DATA_DIR=C:/Documents and Settings/YOURUSERNAME/My Documents' ;example  if you don't want to use the default windows location (C:/data/ or E:/data/)

tlimit,/full

;load dst
kyoto_load_dst

;load other solar wind params
wi_mfi_load
wi_3dp_load

cotrans,'wi_h0_mfi_B3GSE','wi_b3gsm',/GSE2GSM

get_tsy_params,'kyoto_dst','wi_b3gsm',$

'wi_3dp_k0_ion_density','wi_3dp_k0_ion_vel','T01'

tt01, 'thb_state_pos',parmod='t01_par'

tplot, ['thb_state_pos_bt01', 'thb_fgs_gsm']

stop

;now do the same thing with ace data

ace_mfi_load
ace_swe_load

;load_ace_mag loads data in gse coords

cotrans,'ace_k0_mfi_BGSEc','ace_mag_Bgsm',/GSE2GSM

get_tsy_params,'kyoto_dst','ace_mag_Bgsm',$

'ace_k0_swe_Np','ace_k0_swe_Vp','T01',/speed

tt01, 'thb_state_pos',parmod='t01_par'

tplot, ['thb_state_pos_bt01', 'thb_fgs_gsm']

stop

;omni example
;NOTE: you may want to degap and deflag the data(using tdegap and tdeflag)
;to remove gaps and flags in the tsyganemo parameter data, especially
;if you find that there are large gaps in the result  

omni_hro_load

store_data,'omni_imf',data=['OMNI_HRO_1min_BY_GSM','OMNI_HRO_1min_BZ_GSM']

get_tsy_params,'kyoto_dst','omni_imf',$

'OMNI_HRO_1min_proton_density','OMNI_HRO_1min_flow_speed','T01',/speed,/imf_yz

tt01, 'thb_state_pos',parmod='t01_par'

tplot, ['thb_state_pos_bt01', 'thb_fgs_gsm']

stop

;dipole tilt example
;add one degree to dipole tilt
;Can also add time varying tilts, or replace the default dipole tilt with a user defined value

tt01, 'thb_state_pos',pdyn=2.0D,dsti=-30.0D,yimf=0.0D,zimf=-5.0D,g1=g[$

0,0],g2=g[0,1],get_tilt='tilt_vals',add_tilt=1

tplot_names

tplot, ['thb_state_pos_bt01', 'thb_fgs_gsm','tilt_vals']


end
