;+
; PROCEDURE: UCLA_MAG_DESPIN
;       
; PURPOSE: Orthogonalize and despin fluxgate magnetometer data.
;          Also return a smoothed spinning component, for use
;          in other magnetometer despinning routines.
;          Finally calculate measured-model field residuals, and return
;          data in several coordinate systems.
;
;          Currently uses IGRF field to determine spin-axis pointing.
;          Currently uses Housekeeping (AttitudeCtrl) data to determine 
;          spin-phase.
;          Eventually will include an over-ride to use definitive attitude and
;          spin-phase data when available.
;
;          Note that the routine calls get_fa_orbit, overwriting
;          any data stored from a previous call to get_fa_orbit.
;
; INPUT: 
;          SDT data quantities REQUIRED to be plotted:
;
;               Any AttitudeCtrl data quantity (e.g. SUN)
;
;               MagXDC, MagYDC, MagZDC or
;               MagX, MagY, MagZ or
;               Mag1dc_S, Mag2dc_S, Mag3dc_S
;
;               It is recommended that at least 20 minutes of data
;               are plotted in SDT, since the measured fields are fit to
;               model data.
;
;
; KEYWORDS:
;
;      OPTIONAL RETURNED DATA:
;          tw_mat    Named variable to store interim tweaker matrix
;          orbit     Named variable to store orbit number
;          spin_axis Named variable to store deduced spin axis RA/DEC
;          delta_phi Named variable to store deduced spin phase correction
;
;      OPTIONS FOR TPLOT DATA QUANTITIES:
;          not_rgb   If set color of vector components determined from color 
;                    table, otherwise forced to Red-Green-Blue
;          vec_cols  Three element array containing color indices for
;                    vector components (over-rides Red-Green-Blue),
;                    no effect if not_rgb set
;          labflag   Passed to the tplot options routine if set 
;                    [see tplot routines]
;
;      DATA PROCESSING OPTIONS (usually only set to diagnoze problems):
;          not_raw   If set force routine to use SDT-calibrated data
;          no_torq   If set do not calculate torquer values
;          query     If set query user about torquer coil and spin phase
;                    fixes
;          not_fdf   If set don't use in-code FDF predict for 
;                    attitude
;          old_igrf  If set use the IGRF model returned from get_orbit, 
;                    otherwise recalculate IGRF
;          no_patch  If set don't attempt to patch the eclipse spin phase data 
;          force_patch If set force the patch of the eclipse data
;                    (no_patch takes precedence)
;          no_spin_tone If set disable spin-tone harmonic removal
;
; OLD KEYWORDS:
;          (kept for compatibility with earlier versions - newer keywords over-ride 
;           in that these keywords are assumed to be set unless turned off by the
;           newer keywords)
;
;          useraw    If set force routine to use raw data (optional)
;          calctorq  If set attempts to calculate torquer values (optional)
;          no_query  If set don't query user about torquer coil and spin phase
;                    fixes (optional)
;          use_fdf   If set force use of in-code FDF predict for 
;                    attitude (optional)
;          use_rgb   If set force vector components to red-green-blue,
;                    otherwise determined from color table (optional)
;          default   If set use default options - useraw if data in SDT,
;                    calctorq, no_query, use_fdf, use_rgb (optional)
;
; CALLING: 
;
;          Simplest:
;          ucla_mag_despin
;
;          More detailed:
;          ucla_mag_despin,tw_mat=tw_mat,orbit=orbit,spin_axis=spin_axis,delta_phi=delta_phi,/query
;
; OUTPUT: 
;          tplot variables:
;
;           Basic Magnetometer data:
;          'Bx_sp'      Spinning spacecraft Bx (not smoothed, not deglitched)
;          'By_sp'      Spinning spacecraft By (not smoothed, not deglitched)
;          'Bz_sp'      Spinning spacecraft Bz (not smoothed, not deglitched)
;          'Bx_sc'      Despun Bx (in spin plane, to sun, smoothed, deglitched)
;          'By_sc'      Despun By (in spin plane, perp sun, smoothed, deglitched)
;          'Bz_sc'      Despun Bz (spin axis component, smoothed, deglitched)
;          'Bx_sp_sm'   Respun smoothed and deglitched Bx
;          'By_sp_sm'   Respun smoothed and deglitched By
;          'Bz_sp_sm'   Respun smoothed and deglitched Bz
;
;           Transformed data:
;          'B_gei'      Smoothed and deglitched field in GEI coordinates
;          'B_sm'       Smoothed and deglitched field in SM coordinates
;
;           Detrended data:
;          'dB_sc'      Detrended field in despun spacecraft coordinates
;          'dB_gei'     Detrended field in GEI coordinates
;          'dB_sm'      Detrended field in SM coordinates
;          'dB_fac'     Detrended field in field-aligned coordinates
;          'dB_fac_v'   Detrended field in field-aligned/spacecraft velocity 
;                       coordinates
;
;           Diagnostic data:
;          'MAG_FLAGS'  Data quality flag - see below
;          'spin_freq'  Fixed up spin frequency from housekeeping
;          'spin_phase' Fixed up spin phase from Housekeeping
;          'TORQ_X'     Torquer coil Bx (if torquers removed)
;          'TORQ_Y'     Torquer coil By (if torquers removed) 
;          'TORQ_Z'     Torquer coil Bz (if torquers removed)
;          'BX_DEL'     Bx values deleted through outlier rejection (if deglitched)
;          'BY_DEL'     By values deleted through outlier rejection (if deglitched)
;          'BZ_DEL'     Bz values deleted through outlier rejection (if deglitched)
;          'TW_ZX'      Time-varying tweaker matrix zx-coefficient
;          'TW_ZY'      Time-varying tweaker matrix zy-coefficient
;          'TW_YY'      Time-varying tweaker matrix yy-coefficient
;          'TW_YX'      Time-varying tweaker matrix yx-coefficient
;          'O_X         Time-varying x-sensor offset
;          'O_Y'        Time-varying y-sensor offset
;
;           Orbit quantities are also returned - orbit data obtained through
;           get_fa_orbit,t1,t2,/all,status=no_model,delta=1.,/definitive,/drag_prop
;           following orbit quantities stored:
;          'BFOOT','LAT','LNG','FLAT','FLNG','B_model','ORBIT','fa_pos', 
;          'ALT','ILAT','ILNG','MLT','fa_vel']
;
;           Coordinate transformations returned:
;          'despun_to_gei'
;          'gei_to_sm'
;          'gei_to_fac'
;          'gei_to_fac_v'
;
;           
;          'MAG_FLAGS' is data quality flag array:    
;                    0   good
;                    1   spin phase object set to zero
;                    2   in eclipse (using nadir table)
;                    4   spin phase data not smoothed
;                    8   spin phase data patched with nadir or MUE phase data
;                   16   Missing spin phase data
;           The flags are additive, and higher numbers are more serious.
;           Any magnetometer data with a flag >= 16 should be viewed with 
;           caution.
;
; DETAILED DESCRIPTION:
; 
;   UCLA_MAG_DESPIN does the following:
;   
;   1) Get spin phase from AttitudeCtrl quantities.
;
;   2) Get data from SDT (any of the mag data quantities, it knows
;   how to handle whichever one it gets). Interpolate high rate data 
;   (if not MAGDC). Re-register the data and back out the recursive 
;   filter (if not MAGDC).
;
;   3) Run an SVDFIT spin fit routine that computes DC, since and cosine 
;   coefficients. This process is SLOW - be patient.
;
;   4) Calculate torquer coil offsets
;   
;   5) Compute an interim coupling matrix plus offsets and orthogonalize the
;   data with this matrix.
;
;   6) Rerun the SVDFIT routine - it takes just as long as the first time -
;   to get "on the fly" tweaker coefficients. These on the fly coefficients
;   have outliers thrown out, and are smoothed and interpolated. A recursive
;   filter is insufficient to reject the outliers.
;
;   7) Remove spin-tone harmonics.
;   
;   8) Tweak up the data with "on the fly" tweaker coefficients.
;
;   9) Patch the spin phase data and smooth phase information.
;   
;   10) Despin the magnetometer data, without smoothing. Store in tplot
;   structures.
;
;   11) Get the model (IGRF) field, and fit spin axis data to model field
;   to get the first cut at spin-axis pointing. Calculate a despun_to_gei
;   transformation matrix.
;
;   12) 7-point smooth and deglitch magnetometer data, using residuals in
;   despun coordinates as basis for spike removal. Respin the deglitched 
;   and smoothed data, for possible use in other despinning routines.
;
;   13) Rotate spin plane data to minimize phase difference between model and
;   measured field.
;
;   14) Re-tweak spin-axis pointing through regression of all three measured 
;   field components. Recalculate despun_to_gei transformation. Re-tweak
;   the spin phase offset.
;
;   15) Calculate Delta-B's in despun spacecraft, GEI, SM, and field-aligned
;   coordinates (both magnetic meridian and velocity aligned). 
; 
;
; DEPENDENCIES:
;          (these routines are included in the file ucla_mag_lib.pro)
;          GET_MAG_TWEAK
;          GET_MAG_DQIS
;          GET_CAL_HISTORY
;          INTERP_MAG
;          FIX_MAGX
;          FIX_MAGY
;          FIX_MAGZ
;          SPIN_TONE_FIT
;          SPINBASE_MAG
;          GET_QUARTILES
;          TWEAKER_COEFF_FIT
;          RUNNING_TOTAL
;          OUTLIER_REJECTION
;          GET_TORQUER_MAG
;          FIX_UP_SPIN
;          GET_SUN_RA_DEC
;          INTERPOLATE_MATRIX
;          INTERPOLATE_PHASE
;          VECTOR_CROSS_PRODUCT
;          VECTOR_DOT_PRODUCT
;          SET_DIPOLE_ORIENT
;          TRANSFORM_VECTOR
;          SET_IGRF_COEFFICIENTS
;          CALCULATE_IGRF
;          GET_NEW_IGRF
;          GET_PHASE_FROM_ATTCTRL
;          PATCH_SPIN_PHASE
;
; INITIAL VERSION: R J Strangeway 97-04-28
; MODIFICATION HISTORY:
;     Use SPIN_TONE_FIT instead of RCE_LOOP2_RJS - RJS 4/30/97
;     changed to use BX for spin-period estimator - RJS 4/30/97
;     do mag field clean up before final smoother - RJS 5/2/97
;     change tplot variable names - RJS 5/7/97
;     Smooth before deglitch back in - RJS 5/9/97
;     Included check for zero length arrays in interp_mag - RJS 5/15/97
;     Fixed short integer arithmetic in outlier_rejection - RJS 5/21/97
;     Modified outlier_rejection to include weights, 
;         fixes perigee problems- RJS 7/18/97
;     Reduced 512 sps data to 128 sps in get_mag_tweak - RJS 7/19/97
;     Included TW_MAT keyword, for calibration - RJS 7/26/97
;     Modified get_mag_tweak to read MagDC.cal - RJS 7/26/97
;     Corrected update of offsets to occur before tweaker update - RJS 8/1/97
;     Changed diagnostic output in SPIN_TONE_FIT - RJS 9/6/97
;     Tested for Magnetometer DQIS before attempting to read - RJS 9/6/97
;     Use MAGDC as well as other quantities - RJS 9/6/97
;     Also return respun, smoothed, deglitched field - RJS 9/8/97
;     Return detrended field - RJS 9/9/97
;     Return orbit number and deduced spin axis orientation - RJS 9/9/97
;     Flag bad detrend - RJS 9/29/97
;     Include code version specifier to check library match - RJS 9/29/97 - V2.1
;     Included repair flag in get_fa_fields calls - RJS 12/5/97 - V2.2
;     Included torquer calculation - RJS 3/19/98 - V2.3
;     Fixed bug where tw_xy not used in recomputing fields from psuedo
;        sensor values - RJS 4/16/97 - V2.4
;     Reject bad spin period estimates - RJS 4/17/98 - V2.5
;
;     Major revison - RJS 5/12/98 - V3.0
;         Version 3.0 changes:
;           Included GET_TORQUER_MAG in the library
;           Added no_query and default keywords
;           Try to use raw magnetometer data if default set
;           Use housekeeping (AttitudeCtrl) data for spin phase
;           Added MAG_FLAGS as quality indicators
;           Use model fits to fix up spacecraft attitude
;           Return delta-B's in Spacecraft, GEI, SM and field-aligned
;              coordinates
;           Included FIX_UP_SPIN in the library
;           Included GET_SUN_RA_DEC in the library
;           Included INTERPOLATE_MATRIX in the library
;           Included INTERPOLATE_PHASE in the library
;           Included VECTOR_CROSS_PRODUCT in the library
;           Included VECTOR_DOT_PRODUCT in the library
;           Included SET_DIPOLE_ORIENT in the library
;           Included TRANSFORM_VECTOR in the library
;
;      Version 3.1 - Bug fixes and improvements of 3.0 - RJS 
;           Corrected and modified information message at end - 5/14/98
;           No longer interpolate MAG_FLAGS - not necessary and slow - 5/14/98
;           Fixed bug where final spin-axis tweak not applied - 5/17/98
;           Modified INTERPOLATE_PHASE to check both spin and phase for 
;               finite - 5/18/98
;           Final spin-axis fix before spin-phase adjustment - 5/18/98
;           Fixed bkeep error in deglitch (applying wrong phase) - 5/19/98
;           Added warning for large deviations from expected attitude - 5/20/98
;           Use in-code FDF predict to replace first spin-axis estimate
;              if deviation too large - 5/20/98
;           Revised outlier rejection to use relative value - RJS 6/11/98
;           Fixed bug in respinning data - RJS 6/11/98
;           Revised outlier rejection to use residual along model field,
;              previous schemes over reject - RJS 6/19/98
;           Modified GET_TORQUER_MAG to use piece-wise interpolation - 6/19/98
;
;      Version 3.2  - Bug fixes and improvements of 3.1 - RJS
;           Add a zero-crossing deglitcher to GET_MAG_TWEAK - RJS 6/11/98
;           Revised SPIN_TONE_FIT and SPINBASE_MAG to center fit interval
;              - RJS 6/16/98
;           Modified x/y correlation factor (0.04) in GET_TORQUER_MAG
;              - RJS 8/21/98
;           Modified OUTLIER_REJECTION to check for finite - RJS 8/27/98
;              - V3.2a
;           GET_CAL_HISTORY now echoes cal file ID - RJS 9/17/98 - V3.2b
;           Force spin_zero monotonic - RJS 10/1/98 - V3.2c
;           Updated  FDF in code FDF predict - RJS 10/7/98 - V3.2c
;           Modified SPIN_TONE_FIT to return fit - RJS 10/7/98 - V3.2c
;           Modified x/y upper scale factor (3.) in GET_TORQUER_MAG
;              - RJS 10/13/98 -V3.2c
;
;      Version 3.3 - Co-I release - RJS 03/27/99
;           Included use_fdf flag to force use of FDF predict for spin_axis
;               use_fdf is set for default
;           Corrected single eclipse point bug in FIX_UP_SPIN
;           Allowed is_sun to be passed into FIX_UP_SPIN in preparation for 
;               spin phase patch
;           Read the FDF predict from the calibration file - if available 
;               Read by GET_CAL_HISTORY and passed up via GET_MAG_TWEAK
;           Recalculate IGRF, included old_igrf keyword
;               Included GET_NEW_IGRF in the library
;               Included SET_IGRF_COEFFICIENTS in the library
;               Included CALCULATE_IGRF in the library
;
;      Version 3.3a - Improvements to 3.3
;           Double Right Ascension pass in attitude tweak - RJS 4/14/99
;           Include FDF predict in spin_axis structure - RJS 4/14/99
;           Warning for data after end of calibration file 
;              in GET_MAG_TWEAK - RJS 4/14/99
;           Warning/Danger messages for data acquired during P12S7V
;              anomaly, in GET_MAG_TWEAK - RJS 4/15/99
;           Interim (not definitive) calibration for orbits 
;              > 9936 hard-wired in GET_MAG_TWEAK - RJS 4/14/99 
;           No spline interpolation to model data in large
;              (> 60 s) data gaps - RJS 4/19/99
;
;      Version 3.3b - Bug fix
;           Fixed bug in INTERP_MAG, occurs when component does 
;              not change sign - RJS 5/18/99
;
;      Version 3.3c - Keyword addition
;           Added USE_RGB keyword to force red green blue for vectors
;              Allows for different color tables without affecting 
;              vector plot. Set by Default - RJS 5/27/99
;
;      Version 3.3d - Development version of nadir/sun phase patch - RJS 7/6/99
;           1) Force the Sun-phase data into the "OBJECT", takes
;              care off cases where nadir data is used in sunlight (!)
;              This cannot be turned off - applied when OBJECT NE 176
;           2) Recalculate nadir-phase-derived sun-phase from ephemeris
;              and FDF predict spin-axis
;           3) Included a NO_PATCH keyword to disable the eclipse phase patch
;           4) Rationalized keywords, so that a keyword not set is same 
;              as default
;                  NOT_RAW replaces USERAW
;                  NO_TORQ replaces CALCTORQ
;                  QUERY replaces NO_QUERY
;                  NOT_FDF replaces USE_FDF
;                  NOT_RGB replaces USE_RGB
;           5) Included FORCE_PATCH keyword, forcing patch of eclipse data 
;              even when data are good
;         This version has a major bug in the use of get_fa_orbit -
;         Fixed in version 3.3e
;
;      Version 3.3e - Bug fixes  RJS 7/14/99
;           1) Improved NOT_RAW switch - can use calibrated data, even
;              if NOT_RAW isn't set, but issues a warning
;           2) Force second call of GET_FA_ORBIT to force ephemeris data
;              to have same time range as magnetometer data
;
;      Version 3.3f - Clean up of V3.3e RJS 11/30/99
;           1) Truncate orbit data, rather than recall GET_FA_ORBIT
;           2) Sun phase determination and patches now in separate 
;              routines - GET_PHASE_FROM_ATTCTRL and PATCH_SPIN_PHASE
;           3) Replaced variable has_model with no_model for greater
;              readability of code
;
;      Version 3.4 - Interpolate calibration data - RJS 02/08/00
;           1) Revised GET_CAL_HISTORY to preassign storage and
;              determine reference orbits
;           2) Revised GET_MAG_TWEAK to use linear interpolation 
;              for coupling matrix, with constraint that one
;              coupling matrix applies for the whole orbit 
;
;      Version 3.5 - Spin-tone harmonic removal - RJS 06/10/00
;           Use "running average" of spin tone residuals to remove
;           spin-tone harmonics in the time domain.
;           Disabled with NO_SPIN_TONE
;           Under test at this version level.
;
;      Version 3.6 - Include John Bonnell changes - RJS and JB 09/20/00
;           1) Also store a velocity vector aligned delta-B
;           2) Pass vector colors via VEC_COLS=[3,4,6] (e.g)
;              to over-ride RGB default
;           3) Pass the LABFLAG keyword to the vector tplot quantities
;           Also included minor changes to version verification
;           Modifications to documentation
;           Included "non-documented" do_develop keyword
;
;      Version 3.7 - Attitude tweak adjustments - RJS 01/17/01
;           1) Revised diagnostic and timing output
;           2) Re-instated the second attitude tweak
;           3) Included an additional polynomial for the FDF
;              predict structure, returned via GET_CAL_HISTORY
;
;      Version 3.8 - Fix errors associated with large gaps - RJS 09/28/01
;           1) Bug Fix - array dimension mismatch on vector rotation
;           2) Disable torquer fix if over data gap
;           3) Improve attitude and spin-phase tweaks including large gaps
;
;      Version 3.8a - Bug Fix - RJS 11/26/01
;           Fix problems with marking data gaps - code incorrectly
;           handled multiple data gaps.
;
;-

@ucla_mag_lib

pro ucla_mag_despin, $
tw_mat=tw_mat,orbit=orbit,spin_axis=spin_axis,delta_phi=delta_phi, $
not_rgb=not_rgb,vec_cols=vec_cols,labflag=labflag, $
not_raw=not_raw,no_torq=no_torq,query=query,not_fdf=not_fdf,old_igrf=old_igrf, $
no_patch=no_patch,force_patch=force_patch,no_spin_tone=no_spin_tone, $
useraw=useraw,calctorq=calctorq,no_query=no_query,use_fdf=use_fdf, $
use_rgb=use_rgb, default=default, $
do_develop=do_develop

; options/revisions to be added later:
;  1)  Patch nadir data - improve phase corrections at eclipse entry/exit
;  2)  Nutation?
;  3)  Speed up routines using Bob Ergun's mag field routines
;  4)  Use definitive attitude and spin phase if available
;  5)  Revise coefficient fitting routine
;  6)  Turn off/on diagnostic messages
;  7)  Improve error handling - check for finite
;  8)  Suppress/select tplot returns
;  9)  turn on/off deglitching
;  10) Final Box-car smoother width
;  11) Improve the deglitcher/smoother

; store version in common block

common ucla_mag_code,code_version,lib_version
code_version='3.8a'

; use a version number ending in '_d' if there is code that is only
; used if develop is true - the '_d' will be stripped off if develop
; is false

; following two flags should be set to 0 for Co-I release

timer = 0 ; set to 0 to disable timing info, 1 to enable timing info
develop = 0; set to 0 to disable development options, 1 to enable

; note that the (undocumented) do_develop keyword allows for the
; possibility of additional restriction on development code
; (code sections can be implemented to require both develop and
; do_develop to be set). 

if (not develop) then begin
  ll=strpos(code_version,'_d')
  if (ll ge 0) then code_version=strmid(code_version,0,ll)
endif

clock_time = systime(1)
last_clock = clock_time

print,''
print,'Starting UCLA_MAG_DESPIN, version ',code_version
print,''

; set up options - first parse old keywords 

if keyword_set(useraw) then useraw = 1 else useraw = 0
if keyword_set(calctorq) then calctorq = 1 else calctorq = 0
if keyword_set(no_query) then no_query = 1 else no_query = 0
if keyword_set(use_fdf) then use_fdf = 1 else use_fdf = 0
if keyword_set(old_igrf) then old_igrf = 1 else old_igrf = 0
if keyword_set(use_rgb) then use_rgb = 1 else use_rgb = 0
if keyword_set(no_patch) then no_patch = 1 else no_patch = 0
if keyword_set(force_patch) then force_patch = 1 else force_patch = 0

if keyword_set(useraw) then begin
   print,''
   print,'No longer need to use USE_RAW keyword, set automatically'
   print,''
endif
if keyword_set(calctorq) then begin
   print,''
   print,'No longer need to use CALCTORQ keyword, set automatically'
   print,''
endif
if keyword_set(no_query) then begin
   print,''
   print,'No longer need to use NO_QUERY keyword, set automatically'
   print,''
endif
if keyword_set(use_fdf) then begin
   print,''
   print,'No longer need to use USE_FDF keyword, set automatically'
   print,''
endif
if keyword_set(USE_RGB) then begin
   print,''
   print,'No longer need to use USE_RGB keyword, set automatically'
   print,''
endif

has_mag=get_mag_dqis()

if keyword_set(default) then default = 1 else default = 0
if (default) then begin
   print,''
   print,'No longer need to use DEFAULT keyword, set automatically'
   print,''
   calctorq=1
   no_query=1
   useraw=0
   use_fdf=1
   old_igrf=0
   use_rgb=1
   if (has_mag.magxyz) then useraw=1
   if (has_mag.mag1dc and has_mag.mag2dc and has_mag.mag3dc) then useraw = 1
endif


; now parse new keywords

if (keyword_set(not_raw) and has_mag.magdc) then useraw=0 else begin
   if (has_mag.magxyz or (has_mag.mag1dc and has_mag.mag2dc and has_mag.mag3dc)) then begin
      useraw = 1
   endif else begin
      print,''
      print,'UCLA_MAG_DESPIN - WARNING'
      print,'  Forced to use calibrated data  -'
      print,'  UCLA_MAG_DESPIN works better with uncalibrated data'
      print,'  either:   Mag1dc_S, Mag2dc_s, Mag3dc_S'
      print,'  or:       MagX, MagY, MagZ'
      print,''
      useraw=0
   endelse
endelse

if (keyword_set(no_torq)) then calctorq = 0 else calctorq = 1
if (keyword_set(query)) then no_query = 0 else no_query = 1
if (keyword_set(not_fdf)) then use_fdf = 0 else use_fdf = 1
if (keyword_set(not_rgb)) then use_rgb = 0 else use_rgb = 1

debug=1
if (no_query) then debug = 0

no_store_old=1
if (develop) then no_store_old=0

rem_spin_har=1
if (keyword_set(no_spin_tone)) then rem_spin_har=0

bell = string("07b)
no_model = -1
rgb=[6,4,2]
if keyword_set(vec_cols) then if (n_elements(vec_cols) eq 3) then rgb=vec_cols

last_clock = systime(1)

; STEP 1

; get spin phase data from AttitudeCtrl

phase_data = get_phase_from_attctrl(debug = (debug and develop))
if (n_tags(phase_data) eq 0) then return

; STEPS 2 and 3

; get magnetometer data

get_mag_tweak,pseudo,mag,spinfit,tw,ofst,useraw=useraw,fdf_predict=fdf_predict
if n_tags(pseudo) eq 0 then begin
   print,''
   print,'FAILED TO GET MAGNETOMETER DATA'
   print,''
   tw_mat=0
   return
endif

if (develop) then help,fdf_predict,/st

if (n_elements(lib_version) eq 0) then lib_version=''
code_version_chk=code_version
if (develop) then begin
  ll=strpos(code_version,'_d')
  if (ll ge 0) then code_version_chk=strmid(code_version,0,ll)
endif

if (code_version ne lib_version) then begin
    if (code_version_chk eq lib_version) then begin
       print,''
       print,'NOTE - Calling program and library version mismatch'
       print,'       You appear to be running a development version'
       print,'       Calling version: ',code_version
       print,'       Library version: ',lib_version
       print,''
    endif else begin
       print,''
       print,'WARNING - Calling program and library version mismatch'
       print,'          You may want to install the correct versions'
       print,'          Calling version: ',code_version
       print,'          Library version: ',lib_version
       if (debug) then begin
         ans=''
         read,ans,prompt='Continue? '
       endif else ans='Y'
       print,''
       if (ans ne 'Y' and ans ne 'y') then return
    endelse
endif

next_clock = systime(1)
if (timer) then print, $
   string("13b)+'Getting magnetometer data [STEPS 1-3] took ', $
   next_clock-last_clock,' seconds'
last_clock=next_clock

print,''
print,'Setting up spin-tone tweaker matrix coefficients'
print,''

; compute mag_y spin tone tweaker coefficients

ar21=median(spinfit.by_bx)
ph21=median(spinfit.phase_by)

tw_01=-ar21*cos(ph21)
tw_11=1./ar21

; compute mag_z spin tone tweaker coefficients

ar31=median(spinfit.bz_bx)
ph31=median(spinfit.phase_bz)

tw_02=-ar31*cos(ph31)
tw_12=ar31*sin(ph31)

; STEP 4

; if calctorq set calculate torquer offsets - this is still under development

has_torq=0
if (calctorq ne 0) then begin

   print,''
   print,'Calculating torquer coil offsets'
   print,''

   has_torq=get_torquer_mag(spinfit,mag,tw,torquer,debug=debug)

   if (has_torq) then begin

          print,''
          print,'  tplot,[''TORQ_X'',''TORQ_Y'',''TORQ_Z'']'
          print,'  to see offsets applied'
          print,''

; remove dc coupling terms

          torquer.z=torquer.z/tw(2,2)
          torquer.y=torquer.y/tw(1,1)-tw(2,1)*torquer.z
          torquer.x=torquer.x/tw(0,0)-tw(2,0)*torquer.z


          next_clock = systime(1)
          if (timer) then print, $
              string("13b)+'Getting torquer coil offsets [STEP 4] took ', $
              next_clock-last_clock,' seconds'
          last_clock=next_clock

   endif

endif

; STEP 5

; compute dc tweaker coefficients

; throw out extrema

print,''
print,'Setting up DC coupling tweaker matrix'
print,''

z_q=get_quartiles(spinfit.bz_dc)
y_q=get_quartiles(spinfit.by_dc)
x_q=get_quartiles(spinfit.bx_dc)
zl = 5.*z_q(0)+z_q(1)-5.*z_q(2)
zh = 5.*z_q(2)+z_q(1)-5.*z_q(0)
yl = 5.*y_q(0)+y_q(1)-5.*y_q(2)
yh = 5.*y_q(2)+y_q(1)-5.*y_q(0)
xl = 5.*x_q(0)+x_q(1)-5.*x_q(2)
xh = 5.*x_q(2)+x_q(1)-5.*x_q(0)

; do not reject on spin-axis data any more

;b = where (spinfit.bz_dc ge zl and spinfit.bz_dc le zh and spinfit.by_dc ge yl and spinfit.by_dc le yh and spinfit.bx_dc ge xl and spinfit.bx_dc le xh)
b = where (spinfit.by_dc ge yl and spinfit.by_dc le yh and spinfit.bx_dc ge xl and spinfit.bx_dc le xh)

nb = n_elements(b)
ns = n_elements(spinfit.bz_dc)

if (nb lt .9 *ns) then print,'WARNING: Thrown out more than 10% of the data'

bx_dc = spinfit.bx_dc(b)
by_dc = spinfit.by_dc(b)
bz_dc = spinfit.bz_dc(b)

; mag-x dc tweaker and offset

; linear regression

wt=fltarr(n_elements(bz_dc))+1.
xf=fltarr(1,n_elements(bz_dc))+bz_dc
yf=0.
a0=0.
x_s = regress(xf,bx_dc,wt,yf,a0,/relative_weight)

tw_20 = -x_s(0)
o_0 = a0

; mag-y dc tweaker and offset

wt=fltarr(n_elements(bz_dc))+1.
xf=fltarr(1,n_elements(bz_dc))+bz_dc
yf=0.
a0=0.
x_s = regress(xf,by_dc,wt,yf,a0,/relative_weight)

tw_21 = -x_s(0)
o_1 = a0

; get interim tweaker matrix

; NOTE ARRAYS CONFORM TO IDL NOTATION
; i.e., if there are N points per mag component, then
; BB = [[magx],[magy],[magz]] is an array with N columns, and 3 rows
; and BB(i,j) refers to column i, row j
; Furthermore, the rotation is performed as BBNEW = BB#TW
; i.e., BBNEW(i,j) = BB(i,k)*TW(k,j), summed over k
; (Hence the reverse notation in setting up the components of TW)

;tw(0,0) = tw_xx
;tw(0,1) = tw_yx
;tw(0,2) = tw_zx
;tw(1,0) = tw_xy
;tw(1,1) = tw_yy
;tw(1,2) = tw_zy
;tw(2,0) = tw_xz
;tw(2,1) = tw_yz
;tw(2,2) = tw_zz

; Tweaker Gain Matrix and offset

print,''
print,'In calculating new coupling matrix it is assumed that the '
print,'following tweaker matrix is a first order correction for'
print,'off-diagonal terms'
print,' '

tw_00=1.
tw_22=1.
o_2 = 0.

tw_new = dblarr(3,3)
tw_new(0,0) = tw_00
tw_new(0,1) = tw_01
tw_new(0,2) = tw_02
tw_new(1,0) = 0.d0
tw_new(1,1) = tw_11
tw_new(1,2) = tw_12
tw_new(2,0) = tw_20
tw_new(2,1) = tw_21
tw_new(2,2) = tw_22

ofst_new = dblarr(3)
ofst_new(0)=o_0
ofst_new(1)=o_1
ofst_new(2)=o_2

print,tw_new(*,0),format="(f9.6,3x,f9.6,3x,f9.6)
print,tw_new(*,1),format="(f9.6,3x,f9.6,3x,f9.6)
print,tw_new(*,2),format="(f9.6,3x,f9.6,3x,f9.6)
print,''


; New gain matrix and offsets

ofst_new = ofst_new + ofst#tw_new
tw_new = tw#tw_new

; rotate x-y terms so that tw_new(1,0) = 0. - DISABLED 9/7/97 (RJS)

;tww = sqrt(tw_new(0,0)^2 + tw_new(1,0)^2)
;tw_n01 = (tw_new(0,0)*tw_new(0,1) + tw_new(1,1)*tw_new(1,0))/tww
;tw_n11 = (tw_new(0,0)*tw_new(1,1) - tw_new(0,1)*tw_new(1,0))/tww
;tw_new(0,0) = tww
;tw_new(1,0) = 0.
;tw_new(0,1) = tw_n01
;tw_new(1,1) = tw_n11


; recompute magnetic field data from pseudo coordinates

magx_=pseudo.x
magy_=pseudo.y
magz_=pseudo.z

if (has_torq ne 0) then begin

   magx_=magx_-torquer.x
   magy_=magy_-torquer.y
   magz_=magz_-torquer.z

endif

magx=tw_new(0,0)*magx_+tw_new(1,0)*magy_+tw_new(2,0)*magz_ - ofst_new(0)
magy=tw_new(0,1)*magx_+tw_new(1,1)*magy_+tw_new(2,1)*magz_ - ofst_new(1)
magz=tw_new(0,2)*magx_+tw_new(1,2)*magy_+tw_new(2,2)*magz_ - ofst_new(2)

; store tweaker coefficients

tw_mat = {t:mag.t(0),tw_new:tw_new,ofst_new:ofst_new}

; STEP 6

; recompute spin tone terms

print,''
print,'Computing "on-the-fly" Tweaker Coefficients - Be Patient'
print,''
BB = [[magx],[magy],[magz]]
time=mag.t-mag.t(0)
spin_tone_fit,BB,time,coef,tspin,ttag,bfit=bfit

; STEP 7

; development of spin harmonic remover - still needs checking
; might want to use a scheme that reflects different data rates
; Orbit 5154 is a good test case - the harmonic removal is worse
; than leaving alone for parts of the orbit.

print,''
print,'Removing Spin-tone harmonics - under development'
print,''
 
if (develop) then store_data,'BDATA',data={x:mag.t,y:BB}
if (develop) then store_data,'BFIT',data={x:mag.t,y:bfit}

if (rem_spin_har) then begin

  last_clock_rem = systime(1)

  res=BB-bfit

  phs=atan(bfit(*,1),bfit(*,0))
  mag_chk=sqrt(bfit(*,1)^2+bfit(*,0)^2)

  nwindow = 5000L
  nfix = 1000L
  nsmooth=101

  fix_res = res-res

  for n = 0L,n_elements(phs),nfix do begin
    n1 = n-(nwindow-nfix)/2
    n2 = n+(nwindow+nfix)/2
    if (n1 lt 0) then n1 = 0
    if (n2 gt n_elements(phs)-1L) then n2 = n_elements(phs)-1L
    n3=n+nfix
    if (n3 gt n_elements(phs)-1L) then n3 = n_elements(phs)-1L

    chk_chk=median(mag_chk(n1:n2),/even)
    bkeep = where (mag_chk(n1:n2) lt 1.5*chk_chk, nkeep)
    if (nkeep gt 0) then begin
      bs=sort(phs(bkeep+n1))
      for m=0,2 do begin
         tmp=res(bkeep+n1,m)
         res_ch=median(abs(tmp),/even)*10.
         bf = where (abs(tmp) gt res_ch,nf)
         if (nf gt 0) then tmp(bf)=0.
         res_sm=smooth([tmp(bs),tmp(bs)],nsmooth)
         res_sm(0:nsmooth)=res_sm(nkeep:nkeep+nsmooth)
         tmp_res=fltarr(n2-n1+1L)
         tmp_res(bkeep(bs))=res_sm(0:nkeep-1L)
         fix_res(n:n3,m)=tmp_res(n-n1:n3-n1)
      endfor
    endif
  endfor

  if (develop) then store_data,'BFIX',data={x:mag.t,y:fix_res}

  magx=magx-fix_res(*,0)
  magy=magy-fix_res(*,1)
  magz=magz-fix_res(*,2)
  fix_res=0

   next_clock_rem = systime(1)
   if (timer) then print, $
      string("13b)+'Spin-tone harmonic removal took ', $
      next_clock_rem-last_clock_rem,' seconds'

endif


; apply a spin period filter (allow 10% range in spin period)
; added by RJ Strangeway 4/17/98

bgood= where (tspin gt .9*median(tspin) and tspin lt 1.1*median(tspin),ngood)
n_est=n_elements (tspin)
if ( ngood lt .5*n_est) then begin
   print,''
   print,'DANGER - more than 50% of the data have bad spin period estimates'
   print,'         These data have been deleted from the spin fit estimators'
   print,'         Proceed at your own risk'
   print,''
endif
if ( ngood lt .9*n_est) then begin
   print,''
   print,'WARNING - more than 10% of the data have bad spin period estimates'
   print,'          These data have been deleted from the spin fit estimators'
   print,'          Check data carefully'
   print,''
endif

checkfit = {bspin:reform(coef(0,bgood)),bz_dc:reform(coef(1,bgood)), $
            by_bx:reform(coef(2,bgood)),phase_by:reform(coef(3,bgood)), $
            bz_bx:reform(coef(4,bgood)),phase_bz:reform(coef(5,bgood)), $
            bx_dc:reform(coef(6,bgood)),by_dc:reform(coef(7,bgood)), $
            nsamp:reform(coef(8,bgood)),time:ttag(bgood)+mag.t(0), $
            spin:tspin}

; center the time tags

checkfit.time=checkfit.time+checkfit.spin

; temporary: tplot store of checkfit values - nutation?

;store_data,'CHECK_BXDC',data={x:checkfit.time,y:checkfit.bx_dc}
;store_data,'CHECK_BYDC',data={x:checkfit.time,y:checkfit.by_dc}
;store_data,'CHECK_BZDC',data={x:checkfit.time,y:checkfit.bz_dc}
;store_data,'CHECK_BYBX',data={x:checkfit.time,y:checkfit.by_bx}
;store_data,'CHECK_BZBX',data={x:checkfit.time,y:checkfit.bz_bx}
;store_data,'CHECK_BYPH',data={x:checkfit.time,y:checkfit.phase_by}
;store_data,'CHECK_BZPH',data={x:checkfit.time,y:checkfit.phase_bz}

; STEP 8

; get spin-tone tweakers and offsets

print,''
print,'Final fix with on the fly tweakers'
print,''

tw_zx = tweaker_coeff_fit(-checkfit.bz_bx*cos(checkfit.phase_bz),checkfit.time,mag.t)
tw_zy = tweaker_coeff_fit( checkfit.bz_bx*sin(checkfit.phase_bz),checkfit.time,mag.t)

magz_ = magz + tw_zx*magx + tw_zy*magy

tw_yy = tweaker_coeff_fit(1./checkfit.by_bx,checkfit.time,mag.t)
tw_yx = tweaker_coeff_fit(-checkfit.by_bx*cos(checkfit.phase_by),checkfit.time,mag.t)
o_y = tweaker_coeff_fit(checkfit.by_dc,checkfit.time,mag.t)

magy_ = tw_yy*magy + tw_yx*magx - o_y

o_x = tweaker_coeff_fit(checkfit.bx_dc,checkfit.time,mag.t)

magx_ = magx - o_x

; store as a tplot structures - 7 point smooth on despun

store_data,'Bx_sp',data={x:mag.t,y:magx_}
options,'Bx_sp','ytitle','Bx!C!C(nT)'
options,'Bx_sp','ynozero',1
ylim,'Bx_sp',-10000,10000

store_data,'By_sp',data={x:mag.t,y:magy_}
options,'By_sp','ytitle','By!C!C(nT)'
options,'By_sp','ynozero',1
ylim,'By_sp',-10000,10000

store_data,'Bz_sp',data={x:mag.t,y:magz_}
options,'Bz_sp','ytitle','Bz!C!C(nT)'
options,'Bz_sp','ynozero',1
ylim,'Bz_sp',-3000,3000

next_clock = systime(1)
if (timer) then print, $
   string("13b)+'Time-varying tweak of magnetometer data [STEPS 5-8] took ', $
   next_clock-last_clock,' seconds'
last_clock=next_clock
last_clock_tmp=next_clock

; release memory

pseudo=0.
magx_=0.
magy_=0.
magz_=0.
magx=0.
magy=0.
magz=0.

print,''
print,'Despinning the magnetometer data'
print,''

; STEP 9

; get spin phase from housekeeping

get_data,'Bx_sp',data=bx_sp
get_data,'By_sp',data=by_sp
get_data,'Bz_sp',data=bz_sp

bx_sc=bx_sp
by_sc=by_sp
bz_sc=bz_sp

; force patch of the nadir data - get orbit and attitude predict

print,''
print,'Getting orbit data'
print,''

; for backwards compatability set orbit data tags

orbit_tags = ['BFOOT','LAT','LNG','FLAT','FLNG','B_model','ORBIT','fa_pos', $
              'ALT','ILAT','ILNG','MLT','fa_vel','B_model_old','Delta_B_model']

nn = n_elements(phase_data.nadir_zero)-1L
t1 = phase_data.nadir_zero(0)
t2 = phase_data.nadir_zero(nn)
if (t1 gt bz_sc.x(0)) then t1 = bz_sc.x(0)
if (t1 gt phase_data.spin_zero(0)) then t1 = phase_data.spin_zero(0)
nbz = n_elements(bz_sc.x)-1L
if (t2 lt bz_sc.x(nbz)) then t2 = bz_sc.x(nbz)
ns = n_elements(phase_data.spin_zero)-1L
if (t2 lt phase_data.spin_zero(ns)) then t2 = phase_data.spin_zero(ns)
get_fa_orbit,t1,t2,/all,status=no_model,delta=1.,/definitive,/drag_prop
if (old_igrf eq 0) then get_new_igrf,no_store_old=no_store_old

next_clock = systime(1)
if (timer) then print, $
   string("13b)+'Getting orbit data took ', $
   next_clock-last_clock_tmp,' seconds'
   last_clock_tmp=next_clock

; fit to predict data - does not include sun-avoidance
; fit parameters determined 10/7/98

fdfpre_ref = str_to_time('1996-08-26/22:00:00')
fdfpre_last = str_to_time('1998-11-02/00:00:00')
fdfpre_ref_ra = -93.936501d0
fdfpre_trend = -5.3924476d-06

fdfpre_dec = -10.5100d0

tref=.5d0*(t1+t2)

; if fdf_predict is a structure, then fdf predict obtained from cal file

if (n_tags(fdf_predict) gt 0) then begin
   fdfpre_ref = fdf_predict.ref_time
   fdfpre_last = fdf_predict.last_time
   fdfpre_ref_ra = fdf_predict.ref_ra
   fdfpre_trend = fdf_predict.trend_ra
   fdfpre_dec = fdf_predict.ref_dec
endif 

if (tref lt fdfpre_ref or tref gt fdfpre_last) then begin
    print,''
    print,'CAUTION - time interval out of range of FDF predict in UCLA_MAG_DESPIN'
    print,''
endif

exp_ra = (fdfpre_ref_ra + (tref-fdfpre_ref)*fdfpre_trend) mod 360.d0
if (n_tags(fdf_predict) gt 0) then begin
   btag=where(tag_names(fdf_predict) eq 'SECOND_RA', ntag)
   if (ntag gt 0) then $
     exp_ra = (exp_ra + fdf_predict.second_ra*(tref-fdfpre_ref)^2) mod 360.d0
   if (develop) then print,'FDF_PRE SECOND: ',exp_ra
   btag=where(tag_names(fdf_predict) eq 'POLY', ntag)
   if (ntag gt 0) then begin
     bord = where(fdf_predict.poly ne 0.,nord)
     if (nord gt 0) then begin
       nordmx = max(bord)
       if (develop) then print,'FDF_PRE POLY NORDMX: ',nordmx
       tmp_ra=0.d0
       for n = nordmx,0,-1 do begin
          tmp_ra=fdf_predict.poly[n]+(tref-fdfpre_ref)*tmp_ra
       endfor
       exp_ra=(exp_ra+tmp_ra) mod 360.d0
       if (develop) then print,'FDF_PRE POLY: ',exp_ra
     endif
   endif
endif
if (exp_ra lt -180.d0) then exp_ra = exp_ra+360.d0
if (exp_ra gt 180.d0) then exp_ra = exp_ra-360.d0

exp_dec=fdfpre_dec

; patch the spin phase data - note using corrected RA & DEC doesn't help eclipse

spin_phase = patch_spin_phase(phase_data,exp_ra,exp_dec, $
no_patch=no_patch,force_patch=force_patch,no_model=no_model,no_query=no_query)
         
;  force spin_zero monotonic 

spin_zero=phase_data.spin_zero
spin_per=phase_data.spin_per
is_sun=phase_data.is_sun
patch=phase_data.patch
nadir_zero=phase_data.nadir_zero

bfin = where (finite(spin_per) ne 0, nfin)
if (nfin gt 0) then begin
   spin_zero=spin_zero(bfin)
   spin_phase=spin_phase(bfin)
   spin_per=spin_per(bfin)
   is_sun=is_sun(bfin)
   patch=patch(bfin)
   nadir_zero=nadir_zero(bfin)

   bn = where (spin_zero(1:*) - spin_zero(0:*) gt 0.d0, nb)
   while (nb ne (n_elements(spin_zero)-1L)) do begin
      spin_zero=spin_zero([0,bn+1])
      spin_per=spin_per([0,bn+1])
      is_sun=is_sun([0,bn+1])
      patch=patch([0,bn+1])
      spin_phase=spin_phase([0,bn+1])
      bn = where (spin_zero(1:*) - spin_zero(0:*) gt 0.d0, nb)
   endwhile

endif


next_clock = systime(1)
if (timer) then print, $
   string("13b)+'Patching spin phase took ', $
   next_clock-last_clock_tmp,' seconds'
last_clock_tmp=next_clock

frq={x:spin_zero,y:360.d0/spin_per}
phs={x:spin_zero,y:spin_phase}

fix_up_spin,frq,phs,time_error=time_error,flags=flags,debug=debug,no_query=no_query,is_sun=is_sun

flags = flags + 8*patch

mag_flags={x:frq.x,y:flags}

; check for bad spin data

bbad = where (mag_flags.y ge 16, nbad)

if (nbad gt 0) then mag_flags.x(bbad)=nadir_zero(bbad)

next_clock = systime(1)
if (timer) then print, $
   string("13b)+'Fixing spin phase took ', $
   next_clock-last_clock_tmp,' seconds'
last_clock_tmp=next_clock
if (timer) then print, $
   string("13b)+'Patching and smoothing spin phase [STEP 9] took ', $
   next_clock-last_clock,' seconds'
last_clock=next_clock

; interpolate the phase

phs_int = interpolate_phase(phs,frq,bz_sp)

next_clock = systime(1)
if (timer) then print, $
   string("13b)+'Interpolating spin phase took ', $
   next_clock-last_clock_tmp,' seconds'
last_clock_tmp=next_clock

; store flags

nf = n_elements(flags)-1L
nn= 0L
nm=n_elements(bz_sp.x)
m_sort=sort(bz_sp.x-bz_sp.x(0))
f_sort=sort(frq.x-frq.x(0))


blow = where (bz_sp.x(m_sort) lt frq.x(f_sort(0)), nlow)
if (nlow gt 0) then begin
   t1=bz_sp.x(m_sort(blow(0)))
   t2=bz_sp.x(m_sort(blow(nlow-1L)))
   mag_flags={x:[t1,t2,mag_flags.x],y:[16,16,mag_flags.y]}
endif

bhi = where (bz_sp.x(m_sort) gt frq.x(f_sort(nf)), nhi)
if (nhi gt 0) then begin
   t1=bz_sp.x(m_sort(bhi(0)))
   t2=bz_sp.x(m_sort(bhi(nhi-1L)))
   mag_flags={x:[mag_flags.x,t1,t2],y:[mag_flags.y,16,16]}
endif

if (nlow+nhi gt nm/10) then begin
   print,bell
   print,'UCLA_MAG_DESPIN - check MAG_FLAGS, spin phase data missing'
   print,''
endif

next_clock = systime(1)
if (timer) then print, $
   string("13b)+'Storing data quality flags took ', $
   next_clock-last_clock_tmp,' seconds'
last_clock_tmp=next_clock

; STEP 10

; despin the magnetometer data 

cos_v = cos(phs_int.y*!dpi/180.d0)
sin_v = sin(phs_int.y*!dpi/180.d0)

bx_sc.y = bx_sp.y*cos_v - by_sp.y*sin_v
by_sc.y = by_sp.y*cos_v + bx_sp.y*sin_v

; also despin the spin harmonic fix

if (rem_spin_har and develop) then begin

  get_data,'BFIX',data=fix_res
  store_data,'BFIX',/delete
  tmp_res = fix_res.y(*,0)
  fix_res.y(*,0) = fix_res.y(*,0)*cos_v - fix_res.y(*,1)*sin_v
  fix_res.y(*,1) = fix_res.y(*,1)*cos_v + tmp_res*sin_v
  store_data,'BFIX',data=fix_res
  fix_res=0

endif

next_clock = systime(1)
if (timer) then print, $
   string("13b)+'Despinning magnetometer data took ', $
   next_clock-last_clock_tmp,' seconds'
last_clock_tmp=next_clock

; put back into tplot structures

store_data,'Bx_sc',data=bx_sc
options,'Bx_sc','ytitle','Bx_sc!C!C(nT)'
options,'Bx_sc','ynozero',1

store_data,'By_sc',data=by_sc
options,'By_sc','ytitle','By_sc!C!C(nT)'
options,'By_sc','ynozero',1

store_data,'Bz_sc',data=bz_sc
options,'Bz_sc','ytitle','Bz_sc!C!C(nT)'
options,'Bz_sc','ynozero',1

; place holders - store non-detrended as tplot structures

store_data,'Bx_sp_sm',data=bx_sp
store_data,'By_sp_sm',data=by_sp
store_data,'Bz_sp_sm',data=bz_sp

bx_sp=0.
by_sp=0.
bz_sp=0.

data={x:bx_sc.x,y:[[bx_sc.y],[by_sc.y],[bz_sc.y]]}

store_data,'B_gei',data=data
store_data,'B_sm',data=data
store_data,'dB_sc',data=data
store_data,'dB_gei',data=data
store_data,'dB_sm',data=data
store_data,'dB_fac',data=data
store_data,'dB_fac_v',data=data

; diagnostic data

store_data,'MAG_FLAGS',data=mag_flags
options,'MAG_FLAGS','ytitle','MAG_FLAGS'
ylim,'MAG_FLAGS',0,32
mag_flags=0

store_data,'spin_freq',data=frq
options,'spin_freq','ytitle','Spin_Freq!C!C(deg/s)'
options,'spin_freq','ynozero',1

store_data,'spin_phase',data=phs
options,'spin_phase','ytitle','Spin_Phase!C!C(deg)'
options,'spin_phase','ynozero',1

; torquer coeffcients

if (has_torq ne 0) then begin

   store_data,'TORQ_X',data={x:torquer.t,y:torquer.x}
   options,'TORQ_X','ytitle','Torquer Bx!C!C(pseudo-nT)'
   options,'TORQ_X','ynozero',1
   store_data,'TORQ_Y',data={x:torquer.t,y:torquer.y}
   options,'TORQ_Y','ytitle','Torquer By!C!C(pseudo-nT)'
   options,'TORQ_Y','ynozero',1
   store_data,'TORQ_Z',data={x:torquer.t,y:torquer.z}
   options,'TORQ_Z','ytitle','Torquer Bz!C!C(pseudo-nT)'
   options,'TORQ_Z','ynozero',1

   torquer=0.

endif

; safety check - deleted data - place holder

store_data,'BX_DEL',data=bx_sc
store_data,'BY_DEL',data=by_sc
store_data,'BZ_DEL',data=bz_sc

if (rem_spin_har and develop) then begin
  get_data,'BFIX',data=fix_res
  store_data,'BFIX',/delete
  store_data,'BFIX',data=fix_res
  fix_res=0
  options,'BFIX','ytitle','Bfix - harmonic!C!C(nT)'
  options,'BFIX','labels',['x','y','z']
  if (use_rgb) then options,'BFIX','colors',rgb
  if keyword_set(labflag) then options,'BFIX','labflag',labflag
endif

; tweaker coefficients

store_data,'TW_ZX',data={x:mag.t,y:tw_zx}
options,'TW_ZX','ytitle','TW_ZX'
options,'TW_ZX','ynozero',1
;ylim,'TW_ZX',-0.001,0.001
tw_zx=0.

store_data,'TW_ZY',data={x:mag.t,y:tw_zy}
options,'TW_ZY','ytitle','TW_ZY'
options,'TW_ZY','ynozero',1
;ylim,'TW_ZY',-0.001,0.001
tw_zy=0.

store_data,'TW_YY',data={x:mag.t,y:tw_yy}
options,'TW_YY','ytitle','TW_YY'
options,'TW_YY','ynozero',1
;ylim,'TW_YY',.999,1.001
tw_yy=0.

store_data,'TW_YX',data={x:mag.t,y:tw_yx}
options,'TW_YX','ytitle','TW_YX'
options,'TW_YX','ynozero',1
;ylim,'TW_YX',-0.001,0.001
tw_yx=0.

; offsets

store_data,'O_X',data={x:mag.t,y:o_x}
options,'O_X','ytitle','O_X'
options,'O_X','ynozero',1
;ylim,'O_X',-100,100
o_x=0.

store_data,'O_Y',data={x:mag.t,y:o_y}
options,'O_Y','ytitle','O_Y'
options,'O_Y','ynozero',1
;ylim,'O_Y',-100,100
o_y=0.

next_clock = systime(1)
if (timer) then print, $
   string("13b)+'Storing of tplot variables took ', $
   next_clock-last_clock_tmp,' seconds'
last_clock_tmp=next_clock
if (timer) then print, $
   string("13b)+'Magnetometer interim despin and tplot store [STEP 10] took ', $
   next_clock-last_clock,' seconds'
last_clock=next_clock

; STEP 11

; Detrend Magnetometer data

t1 = bz_sc.x(0)
t2 = bz_sc.x(n_elements(bz_sc.x)-1)

if (no_model eq 0) then begin

; delete and restore previously stored orbit quantities for backwards compatability 
; for safety sake also clip orbit data based on magnetometer time intervals
  
   @tplot_com
   dqs = data_quants

   norbqs = n_elements(orbit_tags)
   for nn = 0,norbqs-1L do begin
      bmtch = where (dqs.name eq orbit_tags(nn), nmtch)
      if (nmtch gt 0) then begin
         get_data,orbit_tags(nn),data=temp
         store_data,orbit_tags(nn),/delete
         borbkp = where (temp.x ge t1 and temp.x le t2, norbkp)
         if (norbkp gt t2-t1-10.) then begin
            nts = n_elements(temp.x)
            ndims = n_elements(temp.y)/nts
            if (ndims gt 1) then begin 
               temp={x:temp.x(borbkp),y:temp.y(borbkp,*),ytitle:temp.ytitle}
            endif else begin
               temp={x:temp.x(borbkp),y:temp.y(borbkp),ytitle:temp.ytitle}
            endelse
            store_data,orbit_tags(nn),data=temp
         endif else no_model = 1
      endif
   endfor

endif

if (no_model ne 0) then begin

   print,''
   print,'Getting orbit data'
   print,''
   get_fa_orbit,t1,t2,/all,status=no_model,delta=1.,/definitive,/drag_prop
   if (old_igrf eq 0) then get_new_igrf,no_store_old=no_store_old

endif

if no_model eq 0 then begin

    print,''
    print,'Calculating Spin-axis pointing from model field'
    print,''

    get_data,'ORBIT',data=orb
    nn = n_elements(orb.y)/2
    orbit = orb.y(nn)
    orb=0
    get_data,'B_model',data=bm
    bmark = where (finite (bm.x) eq 1)

;   check for large data gaps
;   V3.8a bug fix - delete entries outside of for loop

    delt=bz_sc.x(1:*)-bz_sc.x(0:*)
    bbig = where (delt ge 60.d0,nbig)
    if (nbig gt 0) then begin
       print,bell
       print,'WARNING - LARGE DATA GAP - Attitude tweak should be verified'
       print,''
       btmp=bm
       for n=0,nbig-1L do begin
          bdel = where (bm.x gt bz_sc.x(bbig(n)) and  $
                        bm.x lt bz_sc.x(bbig(n)+1),ndel)
          if (ndel gt 0) then btmp.x(bdel)=!values.d_nan
       endfor
       bmark = where (finite (btmp.x) eq 1)
       bm={x:btmp.x(bmark),y:btmp.y(bmark,*)}
    endif

;   force bm to same range as data

    bkp = where (bm.x ge bz_sc.x(0) and bm.x le bz_sc.x(n_elements(bz_sc.x)-1L), nkp)
    if (nkp le 0) then begin
       print,''
       print,'UCLA_MAG_DESPIN - FAILED TO GET MODEL FIELD (!!!)'
       print,''
       return
    endif else begin
       bm = {x:bm.x(bkp),y:bm.y(bkp,*)}
    endelse

;   outlier reject spin-axis data

    wt =bz_sc.x(1:*)-bz_sc.x(0:*)
    b=where (wt lt .26)
    wtmx=max(wt(b))
    b=where (wt gt wtmx, nb)
    if (nb gt 0) then wt(b)=wtmx
    wt=[wt,wtmx]/wtmx
    good_bz=outlier_rejection(bz_sc.y,wt=wt)
    bz=bz_sc.y(good_bz)
    tz=bz_sc.x(good_bz)
    y2=spl_init(tz-tz(0),bz,/double)
    bz_sc_dec = spl_interp(tz-tz(0),bz,y2,bm.x-tz(0),/double)

;   regress, with additional outlier reject - back in 5/19/98

    wt=fltarr(n_elements(bz_sc_dec))+1.
    x_s = regress(transpose(bm.y),bz_sc_dec,wt,zf,z0,sigma, $
    ftest,r,rmul,/relative_weight)
    avg = moment(bz_sc_dec-zf,sdev=sdev)
    bdel = where (abs(bz_sc_dec-zf-avg(0)) gt 5.*sdev, ndel)
    if (ndel ne 0) then begin
      wt(bdel)=0.
      x_s = regress(transpose(bm.y),bz_sc_dec,wt,zf,z0,sigma, $
      ftest,r,rmul,/relative_weight)
    endif

;   replaced previous code with ladfit 5/17/98 
;   ladfit commented out 5/19/89

;   because I expect declination near zero, do x and y fits first

;    bzz=bz_sc_dec
;    ft0=ladfit(bm.y(*,0),bzz,/double)
;    bzz=bzz-ft0(1)*bm.y(*,0)-ft0(0)
;    ft1=ladfit(bm.y(*,1),bzz,/double)
;    bzz=bzz-ft1(1)*bm.y(*,1)-ft1(0)
;    ft2=ladfit(bm.y(*,2),bzz,/double)
;    bzz=bzz-ft2(1)*bm.y(*,2)-ft2(0)
;    x_s=[ft0(1),ft1(1),ft2(1)]

    ra = atan(x_s(1),x_s(0))*180.d0/!dpi
    dec = asin(x_s(2)/sqrt(x_s(0)^2+x_s(1)^2+x_s(2)^2))*180.d0/!dpi
    ra_f = ra
    dec_f = dec
    spin_axis={ra:ra,dec:dec}


    if (use_fdf) then begin
       print,''
       print,'Forced to use FDF predict, spin axis RA & DEC: ',exp_ra,exp_dec
       ra = exp_ra
       dec = exp_dec
       spin_axis.ra = ra
       spin_axis.dec = dec
    endif else begin
       dev_ra = spin_axis.ra - exp_ra
       if (dev_ra gt 180.d0) then dev_ra = dev_ra-360.d0
       if (dev_ra lt -180.d0) then dev_ra = dev_ra+360.d0
       dev_dec = spin_axis.dec-exp_dec

       print,''
       print,'Calculated spin axis RA & DEC: ',spin_axis
       print,'Expected spin axis RA & DEC: ',exp_ra,exp_dec
;
;      If deviation from predicted greater than 1 degree then test 
;      to see if predict gives a better first cut
;
       if (abs(dev_ra) gt 1.d0 or abs(dev_dec) gt 1.d0) then begin
          print, $
          'WARNING - more than one degree deviation from expected values'
          the_sc = dblarr(n_elements(bm.x))+(90.d0 - exp_dec)*!dpi/180.d0
          phi_sc = dblarr(n_elements(bm.x))+(exp_ra)*!dpi/180.d0
          sc_z = [[sin(the_sc)*cos(phi_sc)],[sin(the_sc)*sin(phi_sc)],[cos(the_sc)]]
          bm_sc_z = vector_dot_product(bm.y,sc_z)
          fdf_res = total(abs(bm_sc_z-bz_sc_dec))/n_elements(bm_sc_z)
          the_sc = dblarr(n_elements(bm.x))+(90.d0 - spin_axis.dec)*!dpi/180.d0
          phi_sc = dblarr(n_elements(bm.x))+(spin_axis.ra)*!dpi/180.d0
          sc_z = [[sin(the_sc)*cos(phi_sc)],[sin(the_sc)*sin(phi_sc)],[cos(the_sc)]]
          bm_sc_z = vector_dot_product(bm.y,sc_z)
          fit_res = total(abs(bm_sc_z-bz_sc_dec))/n_elements(bm_sc_z)
          if (fit_res gt fdf_res) then begin
              print,'          using FDF predict as first estimate'
              ra = exp_ra
              dec = exp_dec
              spin_axis.ra = ra
              spin_axis.dec = dec
          endif
       endif
    endelse
    print,''

 ;   get model field along spin-axis

    the_sc = dblarr(n_elements(bm.x))+(90.d0 - spin_axis.dec)*!dpi/180.d0
    phi_sc = dblarr(n_elements(bm.x))+(spin_axis.ra)*!dpi/180.d0

    sc_z = [[sin(the_sc)*cos(phi_sc)],[sin(the_sc)*sin(phi_sc)],[cos(the_sc)]]
 
    bm_sc_z = vector_dot_product(bm.y,sc_z)

    next_clock = systime(1)
    if (timer) then print, $
        string("13b)+'Initial determination of spin-axis pointing took ', $
        next_clock-last_clock_tmp,' seconds'
    last_clock_tmp=next_clock


;   Tweak of spin-axis pointing

    print,''
    print,'Tweak of spin-axis pointing'
    print,''

    y2=spl_init(bz_sc.x-bz_sc.x(0),bz_sc.y,/double)

;   check for bad spline, if so don't tweak

    bc= where (finite(y2) eq 0, nbc)

    if (nbc gt 0) then begin

       print,''
       print,'BAD SPLINE OF SPIN-AXIS DATA - No attitude tweak'
       print,''
 
    endif else begin

       bz_sc_dec = spl_interp(bz_sc.x-bz_sc.x(0),bz_sc.y,y2,bm.x-bz_sc.x(0),/double)

;      remember that declination is a latitude angle

       term1 = bm_sc_z
       csth = cos((90.-spin_axis.dec)*!pi/180.)
       snth = sin((90.-spin_axis.dec)*!pi/180.)
       csph = cos(spin_axis.ra*!pi/180.)
       snph = sin(spin_axis.ra*!pi/180.)
       term2 = bm.y(*,0)*csth*csph + bm.y(*,1)*csth*snph - bm.y(*,2)*snth
       term3 = bm.y(*,1)*snth*csph - bm.y(*,0)*snth*snph
 
;      perform regression, using absolute residual as figure of merit

;      1st Right Ascension pass

       res3 = bz_sc_dec - term1
       ft=ladfit(term3,res3,/double)
       a3=ft(0)
       b3=ft(1)

;      Declination pass

       res2=res3-b3*term3
       ft=ladfit(term2,res2,/double)
       a2=ft(0)
       b2=ft(1)

;      2nd Right Ascension pass

       res3 = res3 - b2*term2
       ft=ladfit(term3,res3,/double)
       a3=ft(0)
       b3=ft(1)

       dthe_sc = b2*180.d0/!dpi
       dphi_sc = b3*180.d0/!dpi
 
       print,''
       print,'Spin axis right ascension increase: ',dphi_sc
       print,'Spin axis declination increase: ',-dthe_sc
       if (no_query eq 0) then begin

          !p.multi=[0,1,2]
          b=where(finite(term2)) 
          v1=min(term2(b),max=v2)
          ff=[a2+b2*v1,a2+b2*v2]   
          ff_mn=min(ff,max=ff_mx)
          df=ff_mx-ff_mn
          ff_mn=ff_mn-2.*df
          ff_mx=ff_mx+2.*df
          rr_mn=min(res2(b),max=rr_mx)
          if (rr_mn lt ff_mn) then rr_mn=ff_mn
          if (rr_mx gt ff_mx) then rr_mx=ff_mx
          plot,term2,res2,xtitle='Declination Term (nT)',ytitle='residual (nT)', $
          psym=3, yrange=[rr_mn,rr_mx]
          b=where(finite(term2)) 
          v1=min(term2(b),max=v2)
          oplot,[v1,v2],ff

          b=where(finite(term3)) 
          v1=min(term3(b),max=v2)
          ff=[a3+b3*v1,a3+b3*v2]
          ff_mn=min(ff,max=ff_mx)
          df=ff_mx-ff_mn
          ff_mn=ff_mn-2.*df
          ff_mx=ff_mx+2.*df
          rr_mn=min(res3(b),max=rr_mx)
          if (rr_mn lt ff_mn) then rr_mn=ff_mn
          if (rr_mx gt ff_mx) then rr_mx=ff_mx
          plot,term3,res3,xtitle='Right Ascension Term (nT)',ytitle='residual (nT)', $
          psym=3, yrange=[rr_mn,rr_mx]
          oplot,[v1,v2],ff
 
          !p.multi=0
  
          print,bell
          ans = ''
          read, ans, prompt="Are these delta's reasonable? "

       endif else ans='Y'

       print,''
       if ans eq 'N' or ans eq 'n' then begin
          dthe_sc = 0.
          dphi_sc = 0.
       endif

    endelse

    spin_axis.ra = spin_axis.ra + dphi_sc
    spin_axis.dec = spin_axis.dec - dthe_sc
    ra=spin_axis.ra
    dec=spin_axis.dec

    dev_ra = ra - exp_ra
    if (dev_ra gt 180.d0) then dev_ra = dev_ra-360.d0
    if (dev_ra lt -180.d0) then dev_ra = dev_ra+360.d0
    dev_dec = dec-exp_dec

    print,''
    print,'Interim spin-axis RA & DEC: ',spin_axis
    print,'Expected spin axis RA & DEC: ',exp_ra,exp_dec
    if (abs(dev_ra) gt 1.d0 or abs(dev_dec) gt 1.d0) then print, $
    'WARNING - more than one degree deviation - check results'+bell
    print,''
    print,'Constructing sc_to_gei rotation matrix'
    print,''

    spin_axis={ra:ra,dec:dec,ra_f:ra_f,dec_f:dec_f,ra_fdf:exp_ra,dec_fdf:exp_dec,ra_d:dphi_sc,dec_d:-dthe_sc}
 
;   reconstruct sc_to_gei

    get_data,'B_model',data=bm  ; re-read model - V3.8

    the_sc = dblarr(n_elements(bm.x))+(90.d0 - spin_axis.dec)*!dpi/180.d0
    phi_sc = dblarr(n_elements(bm.x))+(spin_axis.ra)*!dpi/180.d0

    sc_z = [[sin(the_sc)*cos(phi_sc)],[sin(the_sc)*sin(phi_sc)],[cos(the_sc)]]
 
    the_sun=get_sun_ra_dec(bm.x)
    the_sc = (90.d0 - the_sun.dec)*!dpi/180.d0
    phi_sc = the_sun.ra*!dpi/180.d0
    sun_gei = [[sin(the_sc)*cos(phi_sc)],[sin(the_sc)*sin(phi_sc)],[cos(the_sc)]]
 
    sc_y = vector_cross_product(sc_z,sun_gei)
    sc_y_abs = sqrt(vector_dot_product(sc_y,sc_y))
    sc_y = sc_y/[[sc_y_abs],[sc_y_abs],[sc_y_abs]]

    sc_x = vector_cross_product(sc_y,sc_z)

    sc_to_gei = {x:bm.x, $
                 y:[[[sc_x(*,0)],[sc_x(*,1)],[sc_x(*,2)]], $
                   [[sc_y(*,0)],[sc_y(*,1)],[sc_y(*,2)]], $
                   [[sc_z(*,0)],[sc_z(*,1)],[sc_z(*,2)]]]}

    store_data,'despun_to_gei',data=sc_to_gei
    options,'despun_to_gei','ytitle','despun_to_gei'

    next_clock = systime(1)
    if (timer) then print, $
        string("13b)+'Recalculating despun_to_gei [STEP 11] took ', $
        next_clock-last_clock,' seconds'
    last_clock=next_clock
    last_clock_tmp=next_clock

;   STEP 12

    print,''
    print,'Rotating model field to spacecraft coordinates'
    print,''

    bm_sc=bm.y
    n_b = n_elements(bm.y(*,0))

    get_data,'despun_to_gei',data=sc_to_gei
    bm_sc = transform_vector(sc_to_gei.y,bm.y,/inverse)

;   interpolate model to data - perform outlier rejection

    print,''
    print,'Interpolating model field and rejecting outliers'
    print,''

    b=where(finite(bm_sc(*,0)))
    y2=spl_init(bm.x(b)-bm.x(0),bm_sc(b,0),/double)
    bmx_int=spl_interp(bm.x(b)-bm.x(0),bm_sc(b,0),y2,bz_sc.x-bm.x(0),/double)

    b=where(finite(bm_sc(*,1)))
    y2=spl_init(bm.x(b)-bm.x(0),bm_sc(b,1),/double)
    bmy_int=spl_interp(bm.x(b)-bm.x(0),bm_sc(b,1),y2,bz_sc.x-bm.x(0),/double)

    y2=spl_init(bm.x-bm.x(0),bm_sc(*,2),/double)
    bmz_int=spl_interp(bm.x-bm.x(0),bm_sc(*,2),y2,bz_sc.x-bm.x(0),/double)

    ; 7 point smooth here

    bx_sc.y = smooth(bx_sc.y,7,/edge)
    by_sc.y = smooth(by_sc.y,7,/edge)
    bz_sc.y = smooth(bz_sc.y,7,/edge)


    ; also 7 point smooth the spin harmonic fix

    if (rem_spin_har and develop) then begin

       get_data,'BFIX',data=fix_res
       fix_res.y(*,0) = smooth(fix_res.y(*,0),7,/edge)
       fix_res.y(*,1) = smooth(fix_res.y(*,1),7,/edge)
       fix_res.y(*,2) = smooth(fix_res.y(*,2),7,/edge)
       store_data,'BFIX',data=fix_res
       fix_res=0

    endif

;   delete outliers based on 5 sigma reject residual field
;   normalized to model field (RJS 6/10/98)
;   Using residual along model (RJS 6/19/98)
;   this is under test

    del_flag=intarr(n_elements(bx_sc.x))

    db=(bx_sc.y*bmx_int + by_sc.y*bmy_int + bz_sc.y*bmz_int)/ $
       (bmx_int^2+bmy_int^2+bmz_int^2) - 1.d0

    wt=bz_sc.x(1:*)-bz_sc.x(0:*)
    b=where (wt lt .26)
    wtmx=max(wt(b))
    b=where (wt gt wtmx, nb)
    if (nb gt 0) then wt(b)=wtmx
    wt=[wt,wtmx]/wtmx

    bb=outlier_rejection(db,wt=wt)
    bbb=outlier_rejection(db(bb),wt=wt(bb))
    bb=bb(bbb)

    del_flag(bb)=del_flag(bb)+1

    bdel = where (del_flag lt 1, number_del)
    bkeep = where (del_flag eq 1, nkeep)

    if (number_del gt 0) then begin

      bx_del={x:bx_sc.x(bdel),y:bx_sc.y(bdel)}
      by_del={x:by_sc.x(bdel),y:by_sc.y(bdel)}
      bz_del={x:bz_sc.x(bdel),y:bz_sc.y(bdel)}
  
      store_data,'BX_DEL',data=bx_del
      options,'BX_DEL','ytitle','Bx_del!C!C(nT)'
      options,'BX_DEL','ynozero',1
      options,'BX_DEL','psym',3

      store_data,'BY_DEL',data=by_del
      options,'BY_DEL','ytitle','By_del!C!C(nT)'
      options,'BY_DEL','ynozero',1
      options,'BY_DEL','psym',3

      store_data,'BZ_DEL',data=bz_del
      options,'BZ_DEL','ytitle','Bz_del!C!C(nT)'
      options,'BZ_DEL','ynozero',1
      options,'BZ_DEL','psym',3

;      bx_sc.y(bdel)=!values.d_nan
;      by_sc.y(bdel)=!values.d_nan
;      bz_sc.y(bdel)=!values.d_nan

    endif else begin

      bx_del=0.
      by_del=0.
      bz_del=0.
      store_data,'BX_DEL',/delete
      store_data,'BY_DEL',/delete
      store_data,'BZ_DEL',/delete

    endelse

    if (nkeep lt .9d0*n_elements(bx_sc.x)) then begin
        print,''
        print,'UCLA_MAG_DESPIN - WARNING - Rejected more than 10% of the data'
        print,''
    endif

    bx_sc={x:bx_sc.x(bkeep),y:bx_sc.y(bkeep)}
    by_sc={x:by_sc.x(bkeep),y:by_sc.y(bkeep)}
    bz_sc={x:bz_sc.x(bkeep),y:bz_sc.y(bkeep)}
    bmx_int=bmx_int(bkeep)
    bmy_int=bmy_int(bkeep)
    bmz_int=bmz_int(bkeep)

    store_data,'Bx_sc',data=bx_sc
    store_data,'By_sc',data=by_sc
    store_data,'Bz_sc',data=bz_sc

;   also delete points from the "BFIX" data
 
    if (rem_spin_har and number_del gt 0 and develop) then begin

       get_data,'BFIX',data=fix_res
       store_data,'BFIX',data={x:fix_res.x(bkeep),y:fix_res.y(bkeep,*)}
       fix_res=0

    endif

;   respin data

    cos_v = cos(phs_int.y(bkeep)*!dpi/180.d0)
    sin_v = sin(phs_int.y(bkeep)*!dpi/180.d0)

    bkeep=lindgen(n_elements(bmx_int))

    bx_sp=bx_sc
    by_sp=by_sc
    bx_sp.y = bx_sc.y*cos_v + by_sc.y*sin_v
    by_sp.y = by_sc.y*cos_v - bx_sc.y*sin_v
    store_data,'Bx_sp_sm',data=bx_sp
    options,'Bx_sp_sm','ytitle'
    options,'Bx_sp_sm','ytitle','Bx_sp_sm!C!C(nT)'
    options,'Bx_sp_sm','ynozero',1
    store_data,'By_sp_sm',data=by_sp
    options,'By_sp_sm','ytitle','By_sp_sm!C!C(nT)'
    options,'By_sp_sm','ynozero',1
    store_data,'Bz_sp_sm',data=bz_sc
    options,'Bz_sp_sm','ytitle','Bz_sp_sm!C!C(nT)'
    options,'Bz_sp_sm','ynozero',1

    bx_sp=0.
    by_sp=0.

    next_clock = systime(1)
    if (timer) then print, $
        string("13b)+'Smoothing and respinning magnetometer data [STEP 12] took ', $
        next_clock-last_clock,' seconds'
    last_clock=next_clock
    last_clock_tmp=next_clock

;   STEP 13

;   rotate spin plane data to minimize phase difference

    print,''
    print,'Calculating spin plane rotation'
    print,''

    phi_m = atan(bmy_int,bmx_int)*180.d0/!dpi
    phi_b = atan(by_sc.y,bx_sc.y)*180.d0/!dpi
    dphi = phi_b-phi_m
    b = where (dphi gt 180.,nb)
    if (nb gt 0) then dphi(b)=dphi(b)-360.
    b = where (dphi lt -180.,nb)
    if (nb gt 0) then dphi(b)=dphi(b)+360.

    y2=spl_init(bz_sc.x(bkeep)-bz_sc.x(0),dphi(bkeep),/double)

;   check for bad spline, if so don't fix

    bc= where (finite(y2) eq 0, nbc)

    delta_phi=0.d0

    if (nbc gt 0) then begin

       print,''
       print,' BAD SPLINE OF SPIN-PLANE DATA - No Phase Fix Applied'
       print,''

    endif else begin

;      rotate the spin plane data

       dphi_dec = spl_interp(bz_sc.x(bkeep)-bz_sc.x(0),dphi(bkeep),y2,bm.x-bz_sc.x(0),/double)
       dphi_new = double(median(dphi_dec))

       if (no_query eq 0) then begin

          dp_mn = min(dphi_dec,max=dp_mx)
          if (dp_mx-dp_mn gt 10.*abs(dphi_new)) then begin
              dp_mn=-5.*abs(dphi_new)
              dp_mx= 5.*abs(dphi_new)
          endif

          plot,bx_sc.x-bx_sc.x(0),dphi,xtitle='Time (sec)', $
          ytitle='Dphi (deg)',psym=3, yrange=[dp_mn,dp_mx] 
          oplot,[0.,bx_sc.x(n_elements(bx_sc.x)-1L)-bx_sc.x(0)], $
          [dphi_new,dphi_new]

          print,''
          print,'Spin plane sensor phase decrease: ',dphi_new
          print,bell
          ans = ''
          read, ans, prompt='Is this decrease reasonable? '
       endif else begin
          ans='Y'
       endelse
       if ans ne 'N' and ans ne 'n' then begin

          print,''
          print,'Rotating spin plane data by angle: ',dphi_new
          if (abs(dphi_new) gt 2.d0) then print, $
          'WARNING - more than two degree deviation - check results'
          print,''

;         rotate data back by dphi_new

          delta_phi=dphi_new

          cs=cos(dphi_new*!dpi/180.d0)
          sn=sin(dphi_new*!dpi/180.d0)

          bx=bx_sc.y
          by=by_sc.y
          bx_sc.y = bx*cs+by*sn
          by_sc.y = by*cs-bx*sn

          store_data,'Bx_sc',data=bx_sc
          store_data,'By_sc',data=by_sc

       endif

    endelse

    next_clock = systime(1)
    if (timer) then print, $
        string("13b)+'Initial spin phase adjustment [STEP 13] took ', $
        next_clock-last_clock,' seconds'
    last_clock=next_clock
    last_clock_tmp=next_clock

;   STEP 14

;   Final attitude adjustments
;   for safety's sake, assume first tweak wasn't done

    print,''
    print,'Final attitude adjustments'
    print,''

    get_data,'B_model',data=bm    
    the_sun=get_sun_ra_dec(bm.x)
    the_sc = (90.d0 - the_sun.dec)*!dpi/180.d0
    phi_sc = the_sun.ra*!dpi/180.d0
    sun_gei = [[sin(the_sc)*cos(phi_sc)],[sin(the_sc)*sin(phi_sc)],[cos(the_sc)]]

;   clip model to data range

    bmark = where (finite (bm.x) eq 1)
    bm_clp = bm

;   check for large data gaps
;   V3.8a bug fix - delete entries outside of for loop

    delt=bz_sc.x(1:*)-bz_sc.x(0:*)
    bbig = where (delt ge 60.d0,nbig)
    if (nbig gt 0) then begin
       btmp=bm_clp
       for n=0,nbig-1L do begin
          bdel = where (bm_clp.x gt bz_sc.x(bbig(n)) and  $
                        bm_clp.x lt bz_sc.x(bbig(n)+1),ndel)
          if (ndel gt 0) then btmp.x(bdel)=!values.d_nan
       endfor
       bmark = where (finite (btmp.x) eq 1)
       bm_clp={x:btmp.x(bmark),y:btmp.y(bmark,*)}
    endif

;   force bm_clp to same range as data

    bkp = where (bm_clp.x ge bz_sc.x(0) and bm_clp.x le bz_sc.x(n_elements(bz_sc.x)-1L), nkp)
    if (nkp le 0) then begin
       print,''
       print,'UCLA_MAG_DESPIN - FAILED TO GET MODEL FIELD (!!!)'
       print,''
       return
    endif else begin
       bm_clp = {x:bm_clp.x(bkp),y:bm_clp.y(bkp,*)}
    endelse
    bkp=bmark[bkp]

;   Tweak spin-axis

;   check for bad spline, if so don't tweak

    bfin= where (finite(bz_sc.y), nfin)
    nbc=1
    if (nfin gt 0) then begin 
       y2=spl_init(bz_sc.x[bfin]-bz_sc.x[0],bz_sc.y[bfin],/double) 
       bc= where (finite(y2) eq 0, nbc)
    endif
    if (nbc gt 0) then begin

       print,''
       print,'BAD SPLINE OF SPIN-AXIS DATA - No final spin-axis tweak'
       print,''
 
    endif else begin


       bz_sc_dec = spl_interp(bz_sc.x[bfin]-bz_sc.x[0],bz_sc.y[bfin],y2,bm_clp.x-bz_sc.x[0],/double)
       csth = cos((90.-spin_axis.dec)*!pi/180.)
       snth = sin((90.-spin_axis.dec)*!pi/180.)
       csph = cos(spin_axis.ra*!pi/180.)
       snph = sin(spin_axis.ra*!pi/180.)
       term1 = bm_clp.y[*,0]*snth*csph + bm_clp.y[*,1]*snth*snph + bm_clp.y[*,2]*csth
       term2 = bm_clp.y[*,0]*csth*csph + bm_clp.y[*,1]*csth*snph - bm_clp.y[*,2]*snth
       term3 = bm_clp.y[*,1]*snth*csph - bm_clp.y[*,0]*snth*snph

;      perform regression, using absolute residual as figure of merit

       res3 = bz_sc_dec - term1
       ft=ladfit(term3,res3,/double)
       a3=ft(0)
       b3=ft(1)

       res2=res3-b3*term3
       ft=ladfit(term2,res2,/double)
       a2=ft(0)
       b2=ft(1)

       dthe_sc = b2*180.d0/!dpi
       dphi_sc = b3*180.d0/!dpi

       print,''
       print,'Additional spin axis right ascension increase: ',dphi_sc

       if (no_query eq 0) then begin   
           b=where(finite(term3)) 
           v1=min(term3(b),max=v2)
           ff=[a3+b3*v1,a3+b3*v2]
           ff_mn=min(ff,max=ff_mx)
           df=ff_mx-ff_mn
           ff_mn=ff_mn-2.*df
           ff_mx=ff_mx+2.*df
           rr_mn=min(res3(b),max=rr_mx)
           if (rr_mn lt ff_mn) then rr_mn=ff_mn
           if (rr_mx gt ff_mx) then rr_mx=ff_mx
           plot,term3,res3,xtitle='Right Ascension Term (nT)',ytitle='residual (nT)', $
           psym=3, yrange=[rr_mn,rr_mx]
           oplot,[v1,v2],ff
           print,bell
           ans = ''
           read, ans, prompt="Apply Right Ascension Correction? "
           if (ans eq 'n' or ans eq 'N') then dphi_sc=0.
       endif
 
       print,''
       print,'Additional spin axis declination increase: ',-dthe_sc

       if (no_query eq 0) then begin   
           b=where(finite(term2)) 
           v1=min(term2(b),max=v2)
           ff=[a2+b2*v1,a2+b2*v2]   
           ff_mn=min(ff,max=ff_mx)
           df=ff_mx-ff_mn
           ff_mn=ff_mn-2.*df
           ff_mx=ff_mx+2.*df
           rr_mn=min(res2(b),max=rr_mx)
           if (rr_mn lt ff_mn) then rr_mn=ff_mn
           if (rr_mx gt ff_mx) then rr_mx=ff_mx
           plot,term2,res2,xtitle='Declination Term (nT)',ytitle='residual (nT)', $
           psym=3, yrange=[rr_mn,rr_mx]
           b=where(finite(term2)) 
           v1=min(term2(b),max=v2)
           oplot,[v1,v2],ff
           print,bell
           ans = ''
           read, ans, prompt="Apply Declination Correction? "
           if (ans eq 'n' or ans eq 'N') then dthe_sc=0.
       endif

       if (dthe_sc ne 0. and dphi_sc ne 0.) then begin

;      modify spin_axis

            tags=tag_names(spin_axis)
            spin_axis.ra = spin_axis.ra+dphi_sc
            spin_axis.dec = spin_axis.dec-dthe_sc
            nm = where (tags eq 'RA_D', nmm)
            if (nmm gt 0) then spin_axis.(nm(0))=spin_axis.(nm(0))+dphi_sc
            nm = where (tags eq 'DEC_D', nmm)
            if (nmm gt 0) then spin_axis.(nm(0))=spin_axis.(nm(0))-dthe_sc
            dec_ra=abs(spin_axis.ra-exp_ra)

;           reconstruct sc_to_gei

            the_sc = dblarr(n_elements(the_sun.time))+(90.d0 - spin_axis.dec)*!dpi/180.d0
            phi_sc = dblarr(n_elements(the_sun.time))+(spin_axis.ra)*!dpi/180.d0
            sc_z = [[sin(the_sc)*cos(phi_sc)],[sin(the_sc)*sin(phi_sc)],[cos(the_sc)]] 
            sc_y = vector_cross_product(sc_z,sun_gei)
            sc_y_abs = sqrt(vector_dot_product(sc_y,sc_y))
            sc_y = sc_y/[[sc_y_abs],[sc_y_abs],[sc_y_abs]]
            sc_x = vector_cross_product(sc_y,sc_z)
            sc_to_gei = {x:bm.x, $
                         y:[[[sc_x(*,0)],[sc_x(*,1)],[sc_x(*,2)]], $
                           [[sc_y(*,0)],[sc_y(*,1)],[sc_y(*,2)]], $
                           [[sc_z(*,0)],[sc_z(*,1)],[sc_z(*,2)]]]}
            store_data,'despun_to_gei',data=sc_to_gei
            options,'despun_to_gei','ytitle','despun_to_gei'

;           interpolate model to data

            bm_sc = transform_vector(sc_to_gei.y,bm.y,/inverse)
            b=where(finite(bm_sc(*,0)))
            y2=spl_init(bm.x(b)-bm.x(0),bm_sc(b,0),/double)
            bmx_int=spl_interp(bm.x(b)-bm.x(0),bm_sc(b,0),y2,bz_sc.x-bm.x(0),/double)
            b=where(finite(bm_sc(*,1)))
            y2=spl_init(bm.x(b)-bm.x(0),bm_sc(b,1),/double)
            bmy_int=spl_interp(bm.x(b)-bm.x(0),bm_sc(b,1),y2,bz_sc.x-bm.x(0),/double)
            b=where(finite(bm_sc(*,1)))
            y2=spl_init(bm.x-bm.x(0),bm_sc(*,2),/double)
            bmz_int=spl_interp(bm.x-bm.x(0),bm_sc(*,2),y2,bz_sc.x-bm.x(0),/double)

        endif

    endelse       

;   Tweak spin phase

    get_data,'despun_to_gei',data=sc_to_gei
    bm_sc=transform_vector(sc_to_gei.y,bm.y,/inverse)

    b=where(finite(bx_sc.y))
    y2=spl_init(bx_sc.x[b]-bx_sc.x[0],bx_sc.y[b],/double)
    dbx_sc_dec = spl_interp(bx_sc.x[b]-bx_sc.x[0],bx_sc.y[b],y2,bm_clp.x-bx_sc.x[0],/double)-bm_sc[bkp,0]
    b=where(finite(by_sc.y))
    y2=spl_init(by_sc.x[b]-by_sc.x[0],by_sc.y[b],/double)
    dby_sc_dec = spl_interp(by_sc.x[b]-by_sc.x[0],by_sc.y[b],y2,bm_clp.x-by_sc.x[0],/double)-bm_sc[bkp,1]
    b=where(finite(bz_sc.y))
    y2=spl_init(bz_sc.x[b]-bz_sc.x[0],bz_sc.y[b],/double)
    dbz_sc_dec = spl_interp(bz_sc.x[b]-bz_sc.x[0],bz_sc.y[b],y2,bm_clp.x-bz_sc.x[0],/double)-bm_sc[bkp,2]

    theta = (dby_sc_dec*bm_sc(bkp,0)-dbx_sc_dec*bm_sc(bkp,1))/(bm_sc(bkp,0)*bm_sc(bkp,0)+bm_sc(bkp,1)*bm_sc(bkp,1))
    keep = outlier_rejection(theta)

    theta_keep = theta(keep)
    theta_corr = median(theta_keep,/even)
    print,''
    print,'Additional spin phase correction: ',theta_corr*180./!pi

    if (no_query eq 0) then begin   
       th_mn = min(theta_keep*180./!pi,max=th_mx)
       if (th_mx-th_mn gt 10.*abs(theta_corr*180./!pi)) then begin
          th_mn=-5.*abs(theta_corr*180./!pi)
          th_mx= 5.*abs(theta_corr*180./!pi)
       endif

       plot,bm_clp.x[keep]-bm_clp.x(0),theta_keep*180./!pi,xtitle='Time (sec)', $
       ytitle='Delta theta (deg)',psym=3, yrange=[th_mn,th_mx] 
       oplot,!x.crange,[theta_corr*180./!pi,theta_corr*180./!pi]

       print,bell
       ans = ''
       read, ans, prompt="Apply Spin Phase Correction? "
       if (ans eq 'n' or ans eq 'N') then theta_corr=0.
    endif

    if (theta_corr ne 0.) then begin
       delta_phi=delta_phi+theta_corr*180./!pi
       bxt=bx_sc.y*cos(theta_corr) + by_sc.y*sin(theta_corr)
       byt=by_sc.y*cos(theta_corr) - bx_sc.y*sin(theta_corr)
       store_data,'Bx_sc',data={x:bx_sc.x,y:bxt}
       store_data,'By_sc',data={x:by_sc.x,y:byt}
       bx_sc.y=bxt
       by_sc.y=byt
    endif

    print,''
    print,'Final spin-axis RA & DEC: ',spin_axis.ra,spin_axis.dec
    print,'Expected spin axis RA & DEC: ',exp_ra,exp_dec
    if (abs(spin_axis.ra-exp_ra) gt 1.d0 or abs(spin_axis.dec-exp_dec) gt 1.d0) then $
    print,'WARNING - more than one degree deviation - check results'+bell
    print,''
    print,'Final spin phase correction: ',delta_phi
    print,''

    next_clock = systime(1)
    if (timer) then print, $
        string("13b)+'Final attitude corrections [STEP 14] took ', $
        next_clock-last_clock,' seconds'
    last_clock=next_clock
    last_clock_tmp=next_clock

;   STEP 15

;   Get delta-B's in spacecraft coordinates

    print,''
    print,"Getting Delta-B's in spacecraft coordinates"
    print,''

    store_data,'dB_sc', $
    data={x:bz_sc.x,y:[[bx_sc.y-bmx_int],[by_sc.y-bmy_int],[bz_sc.y-bmz_int]]}
    options,'dB_sc','labels',['x','y','z']
    options,'dB_sc','ytitle','dB_sc!C!C(nT)'
    options,'dB_sc','ynozero',1
    if (use_rgb) then options,'dB_sc','colors',rgb
    if keyword_set(labflag) then options,'dB_sc','labflag',labflag

    next_clock = systime(1)
    if (timer) then print, $
        string("13b)+"Getting Delta-B's in spacecraft coordinates took ", $
        next_clock-last_clock_tmp,' seconds'
    last_clock_tmp=next_clock

;   from now only need deltas and measured

    bmx_int=0.
    bmy_int=0.
    bmz_int=0.

    get_data,'dB_sc',data=db_sc

    print,''
    print,"Getting Delta-B's in GEI coordinates"
    print,''

    b_gei={x:bx_sc.x,y:[[bx_sc.y],[by_sc.y],[bz_sc.y]]}
    b_sc=b_gei
    sc_to_gei_int = interpolate_matrix(sc_to_gei,b_sc)

    b_gei.y = transform_vector(sc_to_gei_int.y,b_sc.y)
    store_data,'B_gei',data=b_gei
    options,'B_gei','ytitle','B_gei!C!C(nT)'
    options,'B_gei','ynozero',1
    options,'B_gei','labels',['x','y','z']
    if (use_rgb) then options,'B_gei','colors',rgb
    if keyword_set(labflag) then options,'B_gei','labflag',labflag

    b_sc=0.

    db_gei=db_sc
    db_gei.y = transform_vector(sc_to_gei_int.y,db_sc.y)
    store_data,'dB_gei',data=db_gei
    options,'dB_gei','ytitle','dB_gei!C!C(nT)'
    options,'dB_gei','ynozero',1
    options,'dB_gei','labels',['x','y','z']
    if (use_rgb) then options,'dB_gei','colors',rgb
    if keyword_set(labflag) then options,'dB_gei','labflag',labflag

    db_sc=0.

    next_clock = systime(1)
    if (timer) then print, $
        string("13b)+"Getting Delta-B's in GEI coordinates took ", $
        next_clock-last_clock_tmp,' seconds'
    last_clock_tmp=next_clock

    print,''
    print,"Getting Delta-B's in SM coordinates"
    print,''

    tref=.5d0*(the_sun.time(0)+the_sun.time(n_elements(the_sun.time)-1L))
    igrf_dip=set_dipole_orient(tref)
    cs=cos(the_sun.gst*!dpi/180.)
    sn=sin(the_sun.gst*!dpi/180.)
    dip_x_gei=igrf_dip.x*cs-igrf_dip.y*sn
    dip_y_gei=igrf_dip.x*sn+igrf_dip.y*cs
    dip_z_gei=dblarr(n_elements(the_sun.time))+igrf_dip.z

    z_unit=[[dip_x_gei],[dip_y_gei],[dip_z_gei]]

    y_vec = vector_cross_product(z_unit,sun_gei)
    y_mag = sqrt(vector_dot_product(y_vec,y_vec))
    y_unit = [[y_vec(*,0)/y_mag],[y_vec(*,1)/y_mag],[y_vec(*,2)/y_mag]]

    x_unit = vector_cross_product(y_unit,z_unit)
    
    tmp=dblarr(n_elements(x_unit(*,0)),3,3)
    tmp(*,*,0) = x_unit
    tmp(*,*,1) = y_unit
    tmp(*,*,2) = z_unit

    gei_to_sm = {x:bm.x,y:tmp}
    n_b=n_elements(x_unit(*,0))
    for i=0l,n_b-1l do gei_to_sm.y(i,*,*) = transpose(gei_to_sm.y(i,*,*))
    store_data,'gei_to_sm',data=gei_to_sm
    options,'gei_to_sm','ytitle','gei_to_sm'
    tmp=0.

    gei_to_sm_int = interpolate_matrix(gei_to_sm,db_gei)

;   rotate and store data

    b_sm=b_gei
    b_sm.y = transform_vector(gei_to_sm_int.y,b_gei.y)
    store_data,'B_sm',data=b_sm
    options,'B_sm','ytitle','B_sm!C!C(nT)'
    options,'B_sm','labels',['x','y','z']
    if (use_rgb) then options,'B_sm','colors',rgb
    if keyword_set(labflag) then options,'B_sm','labflag',labflag

    b_sm=0.

    db_sm=db_gei
    db_sm.y = transform_vector(gei_to_sm_int.y,db_gei.y)
    store_data,'dB_sm',data=db_sm
    options,'dB_sm','ytitle','dB_sm!C!C(nT)'
    options,'dB_sm','labels',['x','y','z']
    if (use_rgb) then options,'dB_sm','colors',rgb
    if keyword_set(labflag) then options,'dB_sm','labflag',labflag

    db_sm=0.

    next_clock = systime(1)
    if (timer) then print, $
        string("13b)+"Getting Delta-B's in SM coordinates took ", $
        next_clock-last_clock_tmp,' seconds'
    last_clock_tmp=next_clock

    print,''
    print,"Getting Delta-B's in field-aligned coordinates"
    print,''

    get_data,'fa_pos',data=fa_pos
;   fa_pos_gei={x:fa_pos.x(bmark),y:fa_pos.y(bmark,*)} ; don't use bmark - V3.8
    fa_pos_gei=fa_pos

    B_mag = sqrt(vector_dot_product(bm.y,bm.y))
    b_unit = [[bm.y(*,0)/B_mag],[bm.y(*,1)/B_mag],[bm.y(*,2)/B_mag]]

    r_mag = sqrt(vector_dot_product(fa_pos_gei.y,fa_pos_gei.y))
    r_unit = [[fa_pos_gei.y(*,0)/r_mag],[fa_pos_gei.y(*,1)/r_mag],[fa_pos_gei.y(*,2)/r_mag]]

    e_vec = vector_cross_product(b_unit,r_unit)
    e_mag = sqrt(vector_dot_product(e_vec,e_vec))
    e_unit = [[e_vec(*,0)/e_mag],[e_vec(*,1)/e_mag],[e_vec(*,2)/e_mag]]

    n_unit = vector_cross_product(e_unit,b_unit)

;   Field-aligned coordinates defined as: 
;   z-along B, y-east (BxR), x-nominally out

    tmp=dblarr(n_elements(b_unit(*,0)),3,3)
    tmp(*,*,0) = n_unit
    tmp(*,*,1) = e_unit
    tmp(*,*,2) = b_unit

    gei_to_fac = {x:bm.x,y:tmp}
    n_b=n_elements(b_unit(*,0))
    for i=0l,n_b-1l do gei_to_fac.y(i,*,*) = transpose(gei_to_fac.y(i,*,*))
    store_data,'gei_to_fac',data=gei_to_fac
    options,'gei_to_fac','ytitle','gei_to_fac'
    tmp=0.

    gei_to_fac_int = interpolate_matrix(gei_to_fac,db_gei)

;   rotate and store data

    db_fac=db_gei
    db_fac.y = transform_vector(gei_to_fac_int.y,db_gei.y)
    store_data,'dB_fac',data=db_fac
    options,'dB_fac','ytitle','dB_fac!C!C(nT)'
    options,'dB_fac','labels',['o','e','b']
    if (use_rgb) then options,'dB_fac','colors',rgb
    if keyword_set(labflag) then options,'dB_fac','labflag',labflag

    db_fac=0.

    next_clock = systime(1)
    if (timer) then print, $
        string("13b)+"Getting Delta-B's in field-aligned coordinates took ", $
        next_clock-last_clock_tmp,' seconds'
    last_clock_tmp=next_clock

;   delta-b's in velocity vector-ordered FAC's
;   Code courtesy of John Bonnell plus slight modifications

    print,''
    print,"Getting Delta-B's in field-aligned, velocity-based coordinates"
    print,''

    get_data,'fa_vel',data=fa_vel
;   fa_vel_gei={x:fa_vel.x[bmark],y:fa_vel.y[bmark,*]} ; don't use bmark - V3.8
    fa_vel_gei=fa_vel    

; uses b_mag and b_unit from previous calculations in dB_fac.
;    B_mag = sqrt(vector_dot_product(bm.y,bm.y))
;    b_unit = [[bm.y(*,0)/B_mag],[bm.y(*,1)/B_mag],[bm.y(*,2)/B_mag]]

    v_mag = sqrt(vector_dot_product(fa_vel_gei.y,fa_vel_gei.y))
    v_unit = [ $
               [fa_vel_gei.y[*,0]/v_mag], $
               [fa_vel_gei.y[*,1]/v_mag], $
               [fa_vel_gei.y[*,2]/v_mag] $
             ]

    c_vec = vector_cross_product(b_unit,v_unit)
    c_mag = sqrt(vector_dot_product(c_vec,c_vec))
    c_unit = [[c_vec[*,0]/c_mag],[c_vec[*,1]/c_mag],[c_vec[*,2]/c_mag]]

    a_unit = vector_cross_product(c_unit,b_unit)

;   Field-aligned velocity-based coordinates defined as: 
;   z-along B, y-cross track (BxV), x-along track ((BxV)xB).

    tmp=dblarr(n_elements(b_unit[*,0]),3,3)
    tmp[*,*,0] = a_unit
    tmp[*,*,1] = c_unit
    tmp[*,*,2] = b_unit

    gei_to_fac_v = {x:bm.x,y:tmp}
    n_b=n_elements(b_unit[*,0])
    for i=0L,n_b-1L do $
      gei_to_fac_v.y[i,*,*] = transpose(gei_to_fac_v.y[i,*,*])
    store_data,'gei_to_fac_v',data=gei_to_fac_v
    options,'gei_to_fac_v','ytitle','gei_to_fac_v'
    tmp=0.

    gei_to_fac_v_int = interpolate_matrix(gei_to_fac_v,db_gei)

;   rotate and store data

    db_fac_v=db_gei
    db_fac_v.y = transform_vector(gei_to_fac_v_int.y,db_gei.y)
    store_data,'dB_fac_v',data=db_fac_v
    options,'dB_fac_v','ytitle','dB_fac_v!C!C(nT)'
    options,'dB_fac_v','labels',['v ((BxV)xB)','p (BxV)','b']
    if (use_rgb) then options,'dB_fac_v','colors',rgb
    if keyword_set(labflag) then options,'dB_fac_v','labflag',labflag

    db_fac_v=0.

    next_clock = systime(1)
    if (timer) then print, $
      string("13b) + $
      "Getting Delta-B's in field-aligned, velocity-based coordinates took ", $
        next_clock-last_clock_tmp,' seconds'
    last_clock_tmp=next_clock

endif else begin

; delete the place-holders

    print,''
    print,'No orbit data - measured field not detrended'
    print,''

    store_data,'Bx_sp_sm',/delete
    store_data,'By_sp_sm',/delete
    store_data,'Bz_sp_sm',/delete
    store_data,'B_gei',/delete
    store_data,'B_sm',/delete
    store_data,'dB_sc',/delete
    store_data,'dB_gei',/delete
    store_data,'dB_sm',/delete
    store_data,'dB_fac',/delete
    store_data,'dB_fac_v',/delete
    store_data,'BX_DEL',/delete
    store_data,'BY_DEL',/delete
    store_data,'BZ_DEL',/delete

    orbit=0
    spin_axis=0.

endelse

next_clock = systime(1)
if (timer) then print, $
   string("13b) + $
   "Transforming and storing magnetometer data [STEP 15] took ", $
    next_clock-last_clock,' seconds'

print,''
print,'ucla_mag_despin all done, despun magnetometer data now stored as tplot data'
print,''
print,"tplot,['Bx_sp','By_sp','Bz_sp']   ; plot spinning spacecraft field"
print,"     ; 'Bx_sp'    Spinning spacecraft Bx (not smoothed, not deglitched)"
print,"     ; 'By_sp'    Spinning spacecraft By (not smoothed, not deglitched)"
print,"     ; 'Bz_sp'    Spinning spacecraft Bz (not smoothed, not deglitched)"
print,"tplot,['Bx_sc','By_sc','Bz_sc']   ; plot despun field"
print,"     ; 'Bx_sc  '  Despun Bx (in spin plane, to sun, smoothed, deglitched)"
print,"     ; 'By_sc  '  Despun By (in spin plane, perp sun, smoothed, deglitched)"
print,"     ; 'Bz_sc  '  Despun Bz (spin axis component, smoothed, deglitched)"
diag_message = "tplot,['Bx_sc','By_sc','Bz_sc'"
if no_model eq 0 then begin
    print,"tplot,['Bx_sp_sm','By_sp_sm','Bz_sp_sm']   ; plot respun smoothed field"
    print,"     ; 'Bx_sp_sm' Respun smoothed and deglitched Bx"
    print,"     ; 'By_sp_sm' Respun smoothed and deglitched By"
    print,"     ; 'Bz_sp_sm' Respun smoothed and deglitched Bz"
    print,"tplot,['dB_sc']             ; plot detrended field in despun spacecraft coordinates"
    print,"tplot,['B_gei','dB_gei']    ; plot detrended field in GEI coordinates"
    print,"tplot,['B_sm','dB_sm']      ; plot detrended field in SM coordinates"
    print,"tplot,['dB_fac','dB_fac_v'] ; plot detrended field in field-aligned coordinates"
    diag_message = "tplot,['dB_sc'"
endif
if (rem_spin_har and develop) then diag_message=diag_message+",'BFIX'"
if (has_torq) then diag_message=diag_message+",'TORQ_Z'"
if (number_del gt 0) then diag_message=diag_message+",'BZ_DEL'"
print,diag_message+",'MAG_FLAGS']  ; plot diagnostics"
print,''


if (timer) then print, $
   "UCLA_MAG_DESPIN took ", $
   systime(1)-clock_time,' seconds'+string("13b)

return

end
