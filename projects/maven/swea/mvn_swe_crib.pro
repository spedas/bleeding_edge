;--------------------------------------------------------------------
; MAVEN SWEA Crib
;
; Additional information for all procedures and functions can be
; displayed using doc_library.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-09-13 16:15:33 -0700 (Wed, 13 Sep 2017) $
; $LastChangedRevision: 23961 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_crib.pro $
;--------------------------------------------------------------------
;

; BASIC OUTLINE FOR WORKING WITH PFP DATA.
;
; There is a basic approach you should follow when working with any 
; of the PFP data products.
;
;   Step 1: Set the time span.  Different syntaxes (syntaxi? syntaxae?)
;           are possible.  Two common ones are:

timespan, 'yyyy-mm-dd/hh:mm:ss', number_of_days
timespan, ['yyyy-mm-dd/hh:mm:ss', 'yyyy-mm-dd/hh:mm:ss']

;           Typically, one omits the '/hh:mm:ss' part.

;   Step 2: Initialize SPICE.  This uses the time span from Step 1.

mvn_spice_load, /download

;   Step 3: Load data.  This uses the time span from Step 1.  You can
;           and should load data from multiple instruments without 
;           repeating the first two steps.  For example:

mvn_swe_load_l2, /spec, /pad
mvn_sta_l2_load, sta_apid=['c0','c6','ca','d0']

;           Note that you don't have to know anything about file names,
;           how to download the data, or where to put the data once you
;           have it.  All of this is done automatically based on the
;           time span and data type.  Same goes for SPICE.

;   Step 4: Get the spacecraft potential.  Potentials are mostly in
;           the range -20 to +10 Volts, but there are exceptions, such
;           as the very low density solar wind (potential > +10) and
;           the EUV shadow with high fluxes of energetic electrons 
;           (potential < -20).  If you are working with energies
;           anywhere near the spacecraft potential, this step is
;           critical -- ignoring it can give incorrect results!

mvn_scpot

;   Step 5+: Work with the data as you wish.  When you want to go to
;            a different time span, you must repeat steps 1-4.

; SWEA-SPECIFIC INFORMATION:
;
; General note: All SWEA procedures have their own documentation, 
; describing how to call them and what the options are.  There are
; many more options than are listed in this help file.  To list the
; documentation for routine_name.pro:

doc_library, 'routine_name'

; Load SWEA L0 data into a common block

mvn_swe_load_l0

; Load SWEA L2 data into a common block
;   Data loaded from L2 are identical to data loaded from L0 (by design).
;   L2 data load quickly but consume about 6 times more RAM.  A full day
;   of L2 survey data can consume ~4 GB of RAM.  Add burst data to this
;   and ~8 GB are needed.  So, you may need to manage RAM, depending on
;   your hardware.
;
;   All SWEA routines automatically detect which type of data are loaded 
;   and work the same.  L2 data are loaded using the same methods as L0:

mvn_swe_load_l2

; To conserve RAM, you can load individual data products over different
; time ranges.  Make sure to use the NOERASE option, so that you don't 
; reinitialize the common block with each call.
;
; (I recommend that you load burst data in this way.)

mvn_swe_load_l2, /spec         ; load SPEC survey data over the full range

smaller_trange = ['2014-12-10/10','2014-12-10/12']
mvn_swe_load_l2, smaller_trange, /pad, /noerase          ; PAD survey data
mvn_swe_load_l2, smaller_trange, /pad, /burst, /noerase  ; PAD burst data

; Summary plot.  Loads ephemeris data and includes a panel for spacecraft
; altitude (default is aerodetic).  Orbit numbers appear along the time
; axis.
;
;   Many optional keywords for plotting additional panels.
;   Use doc_library for details.

mvn_swe_sciplot, /sun, /sc_pot

; Determine the direction of the Sun in SWEA coordinates
;   Requires SPICE.  There are several instances when the S/C
;   Z axis is not pointing at the Sun (some periapsis modes,
;   comm passes, MAG rolls).  When the sensor head is illuminated,
;   increased photoelectron background can occur.  This routine
;   also calculates the direction of the Sun in spacecraft
;   coordinates -- useful to identify pointing modes and times
;   when the spacecraft is communicating with Earth.

mvn_sundir, frame='swea', /polar, pans=pans

; Determine the RAM direction in spacecraft coordinates
;   Requires SPICE.  The RAM direction is calculated with respect to
;   the IAU_MARS frame (planetocentric, body-fixed).
;
;   Use keyword FRAME to calculate the RAM direction in any MAVEN 
;   frame recognized by SPICE.  (Keyword APP is shorthand for 
;   FRAME='MAVEN_APP'.)

mvn_ramdir, pans=pans

; Estimate electron density and temperature from fitting the core to
; a Maxwell-Boltzmann distribution and taking a moment over energies
; above the core to estimate the contribution from the halo.  This 
; corrects for scattered electrons.

mvn_swe_n1d, /mb, pans=pans

; Estimate electron density and temperature from 1D moments.  Works in
; the post-shock region, where the distribution is not Maxwellian.  
; No correction for scattered electrons.  (This is the default for 
; key parameters.)

mvn_swe_n1d, /mom, pans=pans

; Resample the pitch angle distributions for a nicer plot.  SWEA measures
; the 0-180-degree pitch angle range twice.  This procedure averages these
; two independent measurements and oversamples.  Spacecraft blockage is 
; masked automatically (by default).

mvn_swe_pad_resample, nbins=128., erange=[100., 150.], /norm, /mask, /silent

; Calculate pitch angle distributions from 3D distributions

mvn_swe_pad_resample, nbins=128., erange=[100., 150.], /norm, /mask, $
                     /ddd, /map3d, /silent

; Load resampled PAD data from pre-calculated IDL save/restore files into
; a TPLOT variable.  (Much faster than above, but may use L1 MAG data, and
; there are no options.)

mvn_swe_pad_restore

; Snapshots selected by the cursor in the tplot window
;   Return data by keyword (ddd, pad, spec) at the last place clicked
;   Use keyword SUM to sum data between two clicks.  (Careful with
;   changing magnetic field.)  The structure element "var" (variance)
;   keeps track of counting statistics, including digitization noise.
;   Set the BURST keyword to show burst data instead of survey data.

swe_engy_snap,/mom,/fixy,spec=spec
swe_pad_snap,energy=130,pad=pad
swe_3d_snap,/spec,/symdir,energy=130,ddd=ddd,smo=[5,1,1]

;
; Get 3D, PAD, or SPEC data at a specified time or array of times.
;   Use keyword ALL to get all 3D/PAD distributions bounded by
;   the input time array.  Use keyword SUM to average all
;   distributions bounded by the input time array.  Set the BURST
;   keyword to get burst data instead of survey data.  (You have
;   to load burst data first.  See above.)

ddd = mvn_swe_get3d(time, units='eflux')
pad = mvn_swe_getpad(time)
spec = mvn_swe_getspec(time)

; Data can be converted to several different units:
;
;   'counts' : raw counts
;   'rate'   : raw count rate
;   'crate'  : count rate, corrected for dead time
;   'flux'   : 1/(cm2-sec-ster-eV)
;   'eflux'  ; eV/(cm2-sec-ster-eV)
;   'df'     ; distribution function: cm-3 (km/s)-3
;
; In most cases, the default is 'eflux'.  You can set units as
; in the example above, or you can change units at any time by:

mvn_swe_convert_units, data, units

; If you have loaded spacecraft potentials, then you can get 
; and/or plot corrected data (in the plasma frame, far from the
; spacecraft) like this:

ddd = mvn_swe_get3d(time, units='eflux', /shiftpot)
pad = mvn_swe_getpad(time, /shiftpot)
spec = mvn_swe_getspec(time, /shiftpot)

swe_engy_snap,/mom,/fixy,spec=spec,/shiftpot
swe_pad_snap,energy=130,pad=pad,/shiftpot
swe_3d_snap,/spec,/symdir,energy=130,ddd=ddd,smo=[5,1,1],/shiftpot

;
; Visualizing the orbit and spacecraft location

; Load the spacecraft ephemeris from MOI to the current date plus
; a few weeks into the future.  Uses reconstructed ephemeris data
; as much as possible, then predicts as far as NAIF provides them.
; Use the LOADONLY keyword to load the ephemeris into TPLOT without
; resetting the time range.
;
; Ephemeris data are updated daily at 3:30 am Pacific.

maven_orbit_tplot,/loadonly

; Plot snapshots of the orbit in three orthogonal MSO planes.
; Optionally plot the orbit in cylintrical coordinates (/CYL),
; IAU_MARS coordinates (MARS=1 or MARS=2), etc.  Use doc_library 
; to see all the options. (Each keyword opens a separate window.)
; Press and hold the left mouse button and drag for a movie effect.

maven_orbit_snap
