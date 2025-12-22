;+
; PROCEDURE:        get_po_orbit
;     
; PURPOSE:          Gets orbit data for the POLAR spacecraft and loads it
;                   into tplot structures.  Does not consider thrusters.
;     
; METHOD:           1) Extracts position and veloctity vectors from a POLAR
;                      CDF file.  The POLAR "master index file" must
;                      be in place for this step to work.
;                   2) Writes a temporary orbit file to be used as
;                      input to the orbit propagator.
;                   3) Calls the FAST orbit propagator, with the orbit
;                      file as input, to load POLAR orbit data into
;                      tplot structures (or save as a single structure).
;
; NOTE:             This procedure needs permission to create files in
;                   the current working directory.  The filenames will
;                   begin with "polar_" and should be deleted
;                   automatically.
;
; WARNING:          The POLAR spacecraft is equipped with thrusters.
;                   Calculated orbit parameters will be in error if
;                   the thrusters were fired between the initial
;                   reference time used by this procedure and the
;                   end of the requested propagation period.
;     
; PARAMETERS:     
;     
;   arg1            If keyword parameter 'time_array' is not set, then this
;                   parameter is the start time of the timespan over which
;                   orbit vectors are to be computed else it is the array
;                   of times for which orbit vectors are to be computed.
;     
;   arg2            if keyword parameter 'time_array' is not set, then this
;                   parameter is the end time of the timespan over which
;                   orbit vectors are to be computed, else it is not used.
;
; KEYWORDS:
;
;   time_array      If not set, then interpret the two positional
;                   parameters as the start time and end time of the 
;                   timespan over which orbit vectors are to computed.
;                   If set, interpret the first positional parameter
;                   as an array.
;
;   ALL             If not set, will get the following data:
;                       {x:time, y:orbit, ytitle:'ORBIT'}
;                       {x:time, y:pos, ytitle:'po_pos'}
;                       {x:time, y:alt, ytitle:'ALT'}
;                       {x:time, y:ilat, ytitle:'ILAT'}
;                       {x:time, y:ilng, ytitle:'ILNG'}
;                       {x:time, y:mlt, ytitle:'MLT'}
;                       {x:time, y:vel, ytitle:'po_vel'}
;                   If set, will get the quantities above, and also:
;                       {x:time, y:lat, ytitle:'LAT'}
;                       {x:time, y:lng, ytitle:'LNG'}
;                       {x:time, y:flat, ytitle:'FLAT'}
;                       {x:time, y:flng, ytitle:'FLNG'}
;                       {x:time, y:b, ytitle:'B_model'}
;                       {x:time, y:bfootprint, ytitle:'BFOOT'}
;
;   STATUS          The long integer return value of the
;                   OrbGetVectors() call in the orbitio library.
;                   There are about a dozen different status codes
;                   indicating the various possible error conditions.
;                   These status codes are shown in the include file
;                   $(workspace)/include/orbitlib.h (ORB_OK, ORB_EOF,
;                   etc).  The user should explicitly test that status
;                   equals 0 (ORB_OK = 0 signifies success) before
;                   using the returned data. Other miscellaneous errors
;                   may result in nonzero status also.
;   NO_STORE        If set, inhibits storage of orbit quantities in
;                   tplot structures. This is useful to avoid the
;                   overwriting of previously stored data.
;   STRUCTURE       A named variable into which a structure containing
;                   the requested orbit quantities will be returned.
;                   NOTE: As a side effect of using the FAST orbit
;                   propagator, the position and velocity tags in this
;                   structure will be FA_POS and FA_VEL, not PO_POS
;                   and PO_VEL as they should be.
;   DELTA_T         Spacing in seconds of the computed orbit vectors
;                   (default = 20 sec).  This keyword is ignored if
;                   time_array is set.
;
; CREATED:          97-8-20
;                   By J. Rauchleiba
;
; 
;-

pro get_po_orbit, intime1, intime2, $
       no_store=no_store, $
       structure=struc, $
       time_array=time_array, $
       ALL=all, $
       STATUS=status, $
       DELTA_T=delta_t

;; Epoch

if data_type(intime1) EQ 7 then t1=str_to_time(intime1) else t1=intime1
if keyword_set(intime2) $
  then if data_type(intime2) EQ 7 $
  then t2=str_to_time(intime2) else t2=intime2

start = t1(0)
if keyword_set(time_array) then endtime = t1(n_elements(t1)-1) else endtime=t2

;; Load a POLAR CDF containing the Epoch start time

cdfmastdir = getenv('POLAR_CDF_MAST_DIR')
if NOT keyword_set(cdfmastdir) then message, 'POLAR_CDF_MAST_DIR not set in env.'
masterfile = cdfmastdir + '/po_or_def_index'

;; loadallcdf bug prevents loading of first requested quantity

loadallcdf, /tplot, masterfile=masterfile, $
  time_range=[ time_to_str(start - 120d), time_to_str(start)], $
  cdfnames=['GSE_POS', 'GSE_VEL']
loadallcdf, /tplot, masterfile=masterfile, $
  time_range=[ time_to_str(start - 120d), time_to_str(start)], $
  cdfnames=['GSE_VEL', 'GSE_POS']

if !err NE 0 then begin
    print, 'Epoch not found in ', masterfile
    ;; Get last time indexed in masterfile
endif

;; Get intial time/data point from which to begin propagation

get_data, 'GSE_POS', data=gse_pos
get_data, 'GSE_VEL', data=gse_vel
dt = min(abs(gse_pos.x - (start-120d)), start_ref_ind)
start_ref = gse_pos.x(start_ref_ind)
if start_ref GT start then message, 'Initial time too late.'
gse_pos_pt = {x:start_ref, y:gse_pos.y(start_ref_ind, *)}
gse_vel_pt = {x:start_ref, y:gse_vel.y(start_ref_ind, *)}
store_data, 'GSE_POS_PT', data=gse_pos_pt
store_data, 'GSE_VEL_PT', data=gse_vel_pt

;; Convert position and velocity from GSE to GEI

coord_trans, 'GSE_POS_PT', 'GEI_POS', 'GSEGEI'
coord_trans, 'GSE_VEL_PT', 'GEI_VEL', 'GSEGEI'
get_data, 'GEI_POS', data=gei_pos
get_data, 'GEI_VEL', data=gei_vel

;; Delete stored quantities

store_data, 'TIME', /delete
store_data, 'GSE_POS', /delete
store_data, 'GSE_VEL', /delete
store_data, 'GSE_POS_PT', /delete
store_data, 'GSE_VEL_PT', /delete
store_data, 'GEI_POS', /delete
store_data, 'GEI_VEL', /delete

;; Get initial position and velocity vectors

position = [gei_pos.y(0,0), gei_pos.y(0,1), gei_pos.y(0,2)]
velocity = [gei_vel.y(0,0), gei_vel.y(0,1), gei_vel.y(0,2)]

;; Collect orbit file elements

;; Epoch
date_doy_sec, start_ref, year, doy, sec
time_of_day = (str_sep(time_to_str(start_ref, /msec), '/'))(1)
hdr_ver = '1.2'
hdr_sat = 'FAST'
hdr_year = strtrim(year, 2)
hdr_doy = strtrim(doy, 2)
hdr_time = time_of_day
hdr_epoch = hdr_year + ' ' + hdr_doy + ' ' + hdr_time
;; Placeholders
hdr_orb = '1'
hdr_axis = '0.0'
hdr_ecc = '0.0'
hdr_inc = '0.0'
hdr_node = '0.0'
hdr_aperigee = '0.0'
hdr_manomaly = '0.0'
;; Vector elements
hdr_t = '0'
hdr_x = strtrim(position(0), 2)
hdr_y = strtrim(position(1), 2)
hdr_z = strtrim(position(2), 2)
hdr_vx = strtrim(velocity(0), 2)
hdr_vy = strtrim(velocity(1), 2)
hdr_vz = strtrim(velocity(2), 2)

;; Write the orbit file

suffix = '.' + (str_sep(strtrim(randomu(seed),2), '.'))(1)
orbit_file = 'polar_orbit' + suffix
openw, orbfile_lun, /get_lun, orbit_file
printf, orbfile_lun, hdr_ver, hdr_sat, hdr_orb, hdr_epoch, $
  hdr_axis, hdr_ecc, hdr_inc, $
  hdr_node, hdr_aperigee, hdr_manomaly, $
  hdr_t, hdr_x, hdr_y, hdr_z, hdr_vx, hdr_vy, hdr_vz, $
  format='("FAST Orbit Data version ",A,/,' + $
  '"SATELLITE: ",A,/,' + $
  '"ORBIT: ",A,TR5,"EPOCH: ",A,/,' + $
  '"AXIS = ",A," ECC = ",A," INC = ",A,/,' + $
  '"NODE = ",A," APERIGEE = ",A,TR5,"MANOMALY = ",A,/,' + $
  '"TIME X     Y     Z     VX    VY    VZ",/,' + $
  'A," ",A," ",A," ",A," ",A," ",A," ",A)'
free_lun, orbfile_lun        

;; Generate warning

if keyword_set(time_array) then finish_ref = t1(n_elements(t1) - 1) $
else finish_ref = t2
print, 'CAUTION: Orbit parameters inaccurate if POLAR thrusters fired within propagation period.'
print, 'Propagation  start: ' + time_to_str(start_ref)
print, 'Propagation finish: ' + time_to_str(finish_ref)

;; Call get_fa_orbit with polar/fast hybrid orbit file

get_fa_orbit, ALL=all, t1, t2, TIME_ARRAY=time_array, no_store=no_store, $
  struc=struc, DELTA_T=delta_t, orbit_file=orbit_file, status=status

;; Rename quantities: "FA" -> "PO"
;; Can only rename tplot quantities, not structure elements

if NOT keyword_set(no_store) then begin
    get_data, 'fa_pos', data=po_pos
    get_data, 'fa_vel', data=po_vel
    store_data, 'po_pos', data=po_pos
    store_data, 'po_vel', data=po_vel
    store_data, /delete, 'fa_pos'
    store_data, /delete, 'fa_vel'
endif

;; Delete the orbit file

openr, /delete, del_orbit_file, /get_lun, orbit_file
free_lun, del_orbit_file


end
