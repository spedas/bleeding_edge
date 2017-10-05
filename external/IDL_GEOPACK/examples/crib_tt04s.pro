;+
;  crib_tt04s
;
; Purpose: demonstrates the use of the tt04s procedure.  This procedure
; is tplot based version of the Tsyganenko 2004 magnetic fields model
;
; Notes: Haje Korth's IDL/Geopack DLM must be installed for this
;        to work
;
;        Sometimes these routines can take a while to run.
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-07-06 11:33:15 -0700 (Mon, 06 Jul 2015) $
; $LastChangedRevision: 18020 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/examples/crib_tt04s.pro $
;-

;timespan, '2008-07-02'
timespan, '2010-02-02';date chosen at random

;load state data

thm_load_state, probe = 'b', coord = 'gsm'

;example values were taken from Tsyganenko's papers, they don't

;reflect the actual conditions at this time

tt04s, 'thb_state_pos',pdyn=2.0D,dsti=-30.0D,yimf=0.0D,zimf=-5.0D,$
w1=8.0D,w2=5.0D,w3=9.5D,w4=30.0D,w5=18.5D,w6=60.0D

;load fgm data for comparison

thm_load_fgm, probe = 'b', coord = 'gsm', level = 2

tplot_names

tplot, ['thb_state_pos_bt04s', 'thb_fgs_gsm']

stop

;this next example demonstrates the use of geopack_getw to generate

;the w parameters from physical parameters

;inputs are:

;solar wind density in cm^-3

;solar wind speed in km/s

;interplanetary magnetic field Bz

;if each input argument is an N element array it will produce an Nx6

;output

geopack_getw,5,350,-5,w

tt04s, 'thb_state_pos',pdyn=2.0D,dsti=-30.0D,yimf=0.0D,zimf=-5.0D,w1=w[$

0,0],w2=w[0,1],w3=w[0,2],w4=w[0,3],w5=w[0,4],w6=w[0,5]

;load fgm data for comparison

thm_load_fgm, probe = 'b', coord = 'gsm', level = 2

tplot_names

tplot, ['thb_state_pos_bt04s', 'thb_fgs_gsm']

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
tinterpol_mxn,'thb_state_pos_bt04s','thb_fgs_gsm',newname='thb_state_pos_bt04s'
;
;now translate magnetometer data into model aligned coordinates

;first we make the transformation matrix

fac_matrix_make, 'thb_state_pos_bt04s', other_dim = 'Xgse', newname = $

'mod_mat'

;then we rotate

tvector_rotate, 'mod_mat', 'thb_fgs_gsm'

tplot_names

;model field, measured field, measured field in model coordinates

tplot, ['thb_state_pos_bt04s', 'thb_fgs_gsm', 'thb_fgs_gsm_rot']

stop

;now substract model from the fgs data

;first interpolate the values onto the same grid

tinterpol_mxn,'thb_state_pos_bt04s','thb_fgs_gsm',newname='mod_interp'

;now subtract

dif_data,'thb_fgs_gsm','mod_interp',newname='fgs_dif'

;set it up so model and fgm data are on the same plot

get_data,'mod_interp',data=d1

get_data,'thb_fgs_gsm',data=d2,dlimits=dl

d = {x:d1.x,y:[[d1.y],[double(d2.y)]],v:d1.v}

str_element,/add_replace,dl,'colors',[dl.colors,dl.colors]

str_element,/add_replace,dl,'labels',[dl.labels,dl.labels]

dl.ytitle='fgs measured & model'

store_data,'mod_fgm',data=d,dlimits=dl

ylim,'fgs_dif',-400,1000

;to reset to autoscaling on the y axis type

;ylim,'fgs_dif',/default

;now plot

tplot,['mod_fgm','fgs_dif']

;tlimit,'2008-02-02/18:03:00','2008-02-02/17:48:05'

stop

;the ace & wind read procedures use the current tlimit to figure out

;what data range to read

;here is wind data parameter generation

;you may have to set the default download directory manually
;here are some examples:
;setenv,'ROOT_DATA_DIR=~/data' ;good for single user unix/linux system
;setenv,'ROOT_DATA_DIR=C:/Documents and Settings/YOURUSERNMAE/My Documents' ;example  if you don't want to use the default windows location (C:/data/ or E:/data/)

tlimit,/full


;load kyoto dst
kyoto_load_dst

;load wind data
wi_mfi_load

wi_3dp_load

stop
cotrans,'wi_h0_mfi_B3GSE','wi_b3gsm',/GSE2GSM

get_tsy_params,'kyoto_dst','wi_b3gsm','wi_3dp_k0_ion_density','wi_3dp_k0_ion_vel','T04s'

tt04s, 'thb_state_pos',parmod='t04s_par'

tplot, ['thb_state_pos_bt04s', 'thb_fgs_gsm']

stop

;ace parameter generation
;
ace_mfi_load
ace_swe_load

;load_ace_mag loads data in gse coords

cotrans,'ace_k0_mfi_BGSEc','ace_mag_Bgsm',/GSE2GSM

get_tsy_params,'kyoto_dst','ace_mag_Bgsm',$

'ace_k0_swe_Np','ace_k0_swe_Vp','T04s',/speed

tt04s, 'thb_state_pos',parmod='t04s_par'

tplot, ['thb_state_pos_bt04s', 'thb_fgs_gsm']

stop

;load omni data and use to generate model
;NOTE: you may want to degap and deflag the data(using tdegap and tdeflag)
;to remove gaps and flags in the tsyganemo parameter data, especially
;if you find that there are large gaps in the result  

omni_hro_load

store_data,'omni_imf',data=['OMNI_HRO_1min_BY_GSM','OMNI_HRO_1min_BZ_GSM']

get_tsy_params,'kyoto_dst','omni_imf',$

'OMNI_HRO_1min_proton_density','OMNI_HRO_1min_flow_speed','T04s',/speed,/imf_yz

tt04s, 'thb_state_pos',parmod='t04s_par'

tplot, ['thb_state_pos_bt04s', 'thb_fgs_gsm']

stop

;dipole tilt example
;add one degree to dipole tilt
;Can also add time varying tilts, or replace the default dipole tilt with a user defined value
tt04s, 'thb_state_pos',parmod='t04s_par',get_tilt='tilt_vals',add_tilt=1
tplot, ['thb_state_pos_bt04s', 'thb_fgs_gsm','tilt_vals']

stop

; The following examples show usage of option flags available in 
; the TS04 model for turning on/off various current systems; for more 
; details, see the TS04 paper:
;   Tsyganenko and Sitnov (2005), Modeling the dynamics of the inner 
;     magnetosphere during strong geomagnetic storms

; general option flag example
; generate the Birkeland field only (iopgen=3)
tt04s, 'thb_state_pos', parmod='t04s_par', iopgen=3

stop

; tail field flag example
; generate the field using only one of the tail field modes (mode 1)
tt04s, 'thb_state_pos', parmod='t04s_par', iopt=1

stop

; birkeland field flag example
; calculate the field without region 1 (modes 1 and 2) contributions
tt04s, 'thb_state_pos', parmod='t04s_par', iopb=2

stop
; ring current flag example
; geneate the field with only contributions from the symmetric 
; ring current (SRC)
tt04s, 'thb_state_pos', parmod='t04s_par', iopr=1

stop

end
