;+
;======================================================================
; MAVEN SWEA Crib
;
; Additional information for all procedures and functions can be
; displayed using doc_library.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-11-13 11:19:21 -0800 (Wed, 13 Nov 2024) $
; $LastChangedRevision: 32958 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_crib.pro $
;======================================================================
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
;           There is more than one way to do this.  The standard
;           method is to use mvn_spice_kernels and/or spice_kernel_load.
;           I wrote a wrapper for those routines that also checks for
;           and reports any coverage gaps.

mvn_swe_spice_init

;   Step 3: Create tplot variables to visualize the spacecraft location
;           and orientation.  Several panels are created, showing altitude,
;           longitude, latitude, solar zenith angle, local time, etc.
;           A color bar that indicates the spacecraft attitude along the orbit
;           is useful to identify periods of Sun-point, Earth-point, and the
;           various periapsis orientations.  Gaps in color show where the
;           spacecraft is reorienting, so be careful about changing fields
;           of view.

maven_orbit_tplot, /loadonly
mvn_attitude_bar

;           After this, you can plot snapshots of the orbit in three orthogonal
;           MSO planes.  Optionally plot the orbit in cylindrical coordinates 
;           (/CYL),  IAU_MARS coordinates (MARS=1 or MARS=2), etc.  Use 
;           doc_library to see all the options.  (Each keyword opens a separate
;           window.)  Press and hold the left mouse button and drag for a movie 
;           effect.

maven_orbit_snap

; Tired of remembering and setting the keywords for maven_orbit_snap?  You
; can set defaults that remain active for your entire session:

maven_orbit_options, {datum:'ell', mars=2, verbose:0, black:1}, /replace, /silent

; You can put this line in your idl_startup.pro.

; If you are planning on studying a few days scattered over a one month
; period, for example, it is more efficient to perform steps 1-3 for the
; entire month, and then load data within that month as needed.

;   Step 4: Load data.  You can use the timespan from Step 1, or you can
;           define a shorter timespan contained within it.  You can
;           and should load data from multiple instruments without 
;           repeating the first three steps.  For example:

timespan, smaller_time_range  ; optional
mvn_swe_load_l2, apid=['a2','a3','a4']
mvn_sta_l2_load, sta_apid=['c0','c6','ca','d0']

;           Note that you don't have to know anything about file names,
;           how to download the data, or where to put the data once you
;           have it.  You also don't need to explicitly check version
;           and revision numbers.  The software automatically checks for
;           for this and downloads the latest version/revision if needed.
;           All of this is done automatically based on the time span and
;           data type.  Same goes for SPICE.

;   Step 5: Create tplot variables and make a summary plot of the 
;           observations.  For convenience, you can load and display
;           SWIA, STATIC and/or LPW data alongside the SWEA data using
;           the /SWIA, /STATIC, and /LPW options.  But it's best for you
;           to load those data yourself according to the SWIA and STATIC
;           crib sheets.

mvn_swe_sciplot

;   Step 6: Get the spacecraft potential.  Potentials are mostly in
;           the range -20 to +10 Volts, but there are exceptions, such
;           as the very low density solar wind (potential > +10) and
;           the EUV shadow with high fluxes of energetic electrons 
;           (potential < -20).  If you are working with energies
;           anywhere near the spacecraft potential, this step is
;           critical -- ignoring it can give incorrect results!

mvn_scpot

;   Step 7+: Work with the data as you wish.  When you want to go to
;            a different time span, you must repeat steps 4-6, and
;            possibly steps 1-3.

; ESA-SPECIFIC INFORMATION:

; Every time you work with ESA data (SWEA, SWIA, STATIC), you should ask
; yourself:
;
;    AM I MISSING AN IMPORTANT PART OF THE DISTRIBUTION FUNCTION?
;
; The ESA's have blind spots in both angle and energy, so they can't
; measure the entire electron or ion distribution function.  The ESA's
; are mounted onto the spacecraft so that their fields of view span the
; important part of the distribution function much of the time.  For
; example, when the spacecraft is pointed at the Sun, SWIA is oriented so
; that the Sun direction is centered within its field of view.  In this 
; orientation, SWIA can measure the upstream solar wind beam within its 
; high-resolution "sweet spot".  SWIA can also measure the heated and 
; deflected solar wind in the post-shock region most of the time.  
; Similarly, during a periapsis pass, STATIC is oriented to capture the 
; RAM ion beam in the center of its field of view, while the deflectors 
; are used to measure the beam width in one dimension.  Watch out for 
; times when the spacecraft is pointed at the Earth (usually for 
; communications) or when the spacecraft is reorienting between orbit 
; segments.  During these times, the fields of view are not optimized 
; for science.
;
; Finite energy ranges also play a role.  SWIA does not measure below 25 eV,
; so it cannot measure cold, low-energy ions, which can dominate the 
; distribution function close to the planet and in the wake.  STATIC is 
; designed to measure down to tenths of an eV, but spacecraft charging can 
; affect whether or not STATIC can measure low-energy ions.  The spacecraft 
; charges negative in the ionosphere and in the optical shadow behind the 
; planet, so STATIC can measure down to zero energy.  But in the sunlit 
; region immediately outside the optical shadow, the spacecraft charges 
; positive, which prevents STATIC from detecting any low-energy population.
; STATIC has four energy sweep tables (pickup, conic, ram, CO2) that are
; optimized for different altitude ranges.  At sweep table transitions, 
; the high energy part of the distribution is often clipped when the energy
; range shrinks to measure colder plasma.  Beware of times in the ionosphere
; when the spacecraft charges more negative than about -5 Volts.  Large
; negative spacecraft potentials render STATIC's electrostatic attenuator
; ineffective, resulting in saturation.  (Large negative potentials at high
; altitudes, where the density is low, are not a problem.)
;
; SWEA measures from 3 eV to 4.6 keV.  Outside the ionosphere and in 
; sunlight, the spacecraft charges positive, allowing SWEA to measure down
; to zero energy.  However, in the ionosphere, the main population of thermal 
; electrons is well below SWEA's minimum energy, so that SWEA measures only
; primary photoelectrons (a few percent of the total density).  Thermal
; ionospheric electrons are measured by LPW.

; SWEA-SPECIFIC INFORMATION:
;
; General note: All SWEA procedures have their own documentation, 
; describing how to call them and what the options are.  There are
; many more options than are listed in this help file.  To list the
; documentation for routine_name.pro:

doc_library, 'routine_name'

; SWEA Data Products and APID's (hexadecimal):
;
;    APID    Product Name      Product Description
;  ---------------------------------------------------------------------------
;     28     housekeeping      internal voltages and temperatures (L0 only)
;     a0       svy3d           3D distributions (64E x 16A x 6D), survey
;     a1       arc3d           3D distributions (64E x 16A x 6D), archive
;     a2       svypad          PAD distributions (64E x 16P), survey
;     a3       arcpad          PAD distributions (64E x 16P), archive
;     a4       svyspec         SPEC distributions (64E), survey
;     a5       arcspec         never used
;     a6       fast hsk        high-rate voltages and temperatures (L0 only)
;  ---------------------------------------------------------------------------

; Load SWEA L0 data into a common block.
;   The advantages of loading from L0 are a smaller RAM footprint and 
;   access to instrument housekeeping.

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

; This will load all available APID's, both survey and burst.  If you
; have lots of RAM, you should do this.  To conserve RAM, you can load 
; individual data products over different time ranges.  Make sure to use
; the NOERASE option, so that you don't reinitialize the common block 
; with each call.
;

mvn_swe_load_l2, apid=['a4']        ; load SPEC survey data over the full range

smaller_trange = ['2014-12-10/10','2014-12-10/15'] ; spans at least one orbit
mvn_swe_load_l2, smaller_trange, apid=['a2','a3'], /noerase ; PAD survey and burst

; SWEA QUALITY FLAGS

; Starting in December 2018, a small fraction (< 0.01 %) of spectra exhibited 
; reduced signal at energies below ~25 eV.  This occurred sporadically for 
; individual spectra surrounded by normal spectra before and after, indicating 
; that the instrument recovers quickly.  The anomaly rate increased to 0.04 % in 
; January 2019, and then to ~1 % in February/March 2019.  By analyzing instrument
; housekeeping, we found that the occurrence rate of the anomaly is highly 
; correlated with the analyzer temperature, as measured by a thermistor mounted 
; on the anode board.  Higher temperatures increase the likelihood of the anomaly 
; occurring.  In an attempt to suppress the anomaly, SWEA’s operating temperature
; was reduced on May 1, 2019.  This effectively reduced the anomaly rate to < 0.01 %
; for six months.  Even at the lower operating temperature, the anomaly reappeared 
; in late November 2019, and has been present ever since.  In early 2020, the 
; anomaly rate was ~15% and increased to ~30% by mid-2022.  It has remained stable 
; at ~30% since then.
;
; With an anomaly rate of 30%, there are ~10^4 anomalous spectra per day, far too 
; many to flag manually.  Software was designed to automatically identify anomalous
; spectra by cluster analysis of the signal in two energy ranges (3-6 and 6-12 eV).
; The algorithm is highly accurate when the flux is steady, as in the solar wind 
; and the ionosphere.  Identification of the anomaly in the magnetosheath and tail 
; is more difficult because the flux can be highly variable.  In addition, post-shock
; electron distributions in the sheath generate significant fluxes of secondary 
; electrons at energies below 30 eV.  These secondary electrons are produced inside 
; the instrument and thus are not suppressed by the anomaly.  Consequently, no attempt 
; was made to identify anomalous spectra with high accuracy in the sheath and tail.  
; Instead, a quality flag was defined to take on three values: 0 = the spectrum is 
; affected by the anomaly; 1 = unknown; 2 = the spectrum is not affected by the 
; anomaly.  This quality flag should be used as a guide, not as a definitive 
; indicator.  The accuracy is high enough in the solar wind and ionosphere that 
; routines that use quality filtering can be used to perform automated calculations 
; with good accuracy.
;
; For detailed work on individual events, you will have to exercise judgement.  
; With experience, you may discover that you can identify anomalous spectra better
; than the automated algorithm can.  You can edit quality flags with:

mvn_swe_edit_quality

; This is an interactive program that allows you change the quality level for 
; individual spectra by clicking on them in a tplot window.  After this, filtering
; will be more effective.  Use caution!  Sometimes even humans have trouble
; confidently identifying anomalous spectra.  (Your edits will NOT be saved into 
; the quality database.)

; As of Version 5, the SWEA L2 data include quality flags.  Quality flags are also
; provided when loading data from L0.  The SWEA code has been updated to recognize 
; and use the quality flags.  You can set the minimum quality level for processing 
; (QLEVEL) when calculating moments and estimating the spacecraft potential.


; ACCESSING OBSERVING GEOMETRY

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
;   the rotating IAU_MARS frame (planetocentric, body-fixed).
;
;   Use keyword FRAME to calculate the RAM direction in any MAVEN 
;   frame recognized by SPICE.  See mvn_frame_name() for a list.

mvn_ramdir, pans=pans


; ELECTRON DENSITY AND KINETIC TEMPERATURE

; Estimate electron density and temperature from fitting the core to
; a Maxwell-Boltzmann distribution and taking a moment over energies
; above the core to estimate the contribution from the halo.  Remove
; secondary electrons before fitting.  Filter out known anomalous
; spectra (QLEVEL=1).

mvn_swe_n1d, /mb, pans=pans, /secondary, qlevel=1

; Estimate electron density and temperature from 1D moments.

mvn_swe_n1d, /mom, pans=pans, /secondary, qlevel=1

; Some notes for interpreting electron density and temperature calculations:
;
;   (1) The calculated density is only for the part of the distribution
;       function measured by SWEA.  When the spacecraft potential is
;       positive, as in the solar wind, SWEA can measure to zero energy
;       and thus measures nearly all of the distribution function.
;       Typically, the contribution from electrons with energy > 4.6 keV
;       is negligible.  In the ionosphere, most of the distribution is
;       below SWEA's minimum energy of 3 eV, so SWEA measures only a
;       small fraction of the total density.  In the magnetotail, the 
;       spacecraft charges negative and repels the low-energy portion
;       of the distribution.  Again, SWEA measures only a fraction of 
;       the total density.  Always ask yourself: "Am I missing an
;       important part of the distribution?"
;
;   (2) Correction for the spacecraft potential is critical for 
;       calculating electron density.  The largest source of uncertainty
;       typically propagates from the spacecraft potential estimate.
;
;   (3) In the solar wind, secondary electron contamination is small but
;       not negligible, typically affecting the density and temperature
;       moments by ~10%.  In the sheath, secondary electron contamination
;       is more pronounced, affecting the moments by ~25%.  You will not
;       get good moments in the sheath unless you correct for spacecraft
;       potential AND remove secondary contamination.
;
;   (4) SWEA is cross-calibrated against SWIA, so the electron density is
;       not independent of the ion density.  If the ion and electron density
;       do not appear to agree, it is likely a field-of-view or energy range
;       issue for one or both instruments.
;
;   (5) Temperature fits and moments are best thought of as kinetic
;       temperature.  In the solar wind, the core is often well fit with
;       a bi-Maxwellian, with different temperatures parallel and perpen-
;       dicular to the magnetic field.  The post-shock and ionospheric
;       distributions are not Maxwellian.

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

; SNAPSHOTS SELECTED BY THE MOUSE IN THE TPLOT WINDOW

;   Tplot variables with two independent variables (time and some other
;   parameter) are often displayed as color spectrograms, where the Y
;   axis is the second independent variable and color represents the
;   dependent variable (Z).  Sometimes, the color scale does not 
;   accurately portray the variation in Z, or it is difficult to tell
;   whether a color gradient is significant.  For SWEA, energy spectra
;   and pitch angle distributions are often shown in this way.
;
;   If you want to have a better sense of the significance of color
;   variations, then you can use SWEA snapshot programs that display
;   data at a particular time (or time range) as line plots with error
;   bars.  Time averaging helps to shrink the error bars, but this
;   comes at the cost of reduced time resolution.  For PAD data, you
;   should be careful to average over times when the magnetic field
;   direction remains roughly constant, to avoid pitch angle smearing.
;
;   IF YOU ARE GOING TO INTERPRET SOME COLOR GRADIENT IN A SPECTROGRAM,
;   BE SURE TO LOOK AT SNAPSHOTS TO CONFIRM THE FEATURE IS SIGNIFICANT.
;   THIS IS PARTICULARLY IMPORTANT FOR PAD SPECTROGRAMS.
;
;   You can return data by keyword (ddd, pad, spec) at the last place
;   clicked.  Use keyword SUM to sum data between two clicks.  (Careful
;   with changing magnetic field.)  The structure element var (variance)
;   keeps track of counting statistics, including digitization noise.
;   Remove secondary electron contamination with keyword SECONDARY.
;   Set the BURST keyword to show burst data instead of survey data.
;   Filter out known anomalous spectra with keyword QLEVEL.

swe_engy_snap, /mom, /fixy, /secondary, spec=spec, qlevel=1
swe_pad_snap, energy=120, /secondary, pad=pad, qlevel=1
swe_3d_snap, /spec, /symdir, energy=120, ddd=ddd, smo=[5,1,1], qlevel=1

; For the PAD snapshots, setting keyword ENERGY produces a cut of the 
; energy-pitch angle data at the specified energy.  You will see two 
; groups of "plus" symbols, where the horizontal error bar shows the 
; pitch angle range spanned by the bin, and the vertical error bar shows
; the statistical uncertainty.  There are two groups of symbols because
; SWEA measures the 0-180-deg pitch angle distribution twice, once for 
; each half of the detector.  This way you can check for the statistical
; significance of pitch angle features, and you can verify gyrotropy.  For
; electrons, angular distributions in the plasma frame are nearly always
; gyrotropic, meaning that the flux is constant as a function of 
; gyro-phase.  If you think you've discovered non-gyrotropic electrons or
; some never-before-seen pitch angle distribution, then you're probably 
; looking at an instrumental effect.  Please contact us (see below).

; Tired of remembering and setting all of the keywords for the SWEA
; snapshot programs?  You can set defaults that remain active for
; your entire session:

swe_snap_options, {wscale:1.4, energy:120, resample:1, norm:1, maxrerr:0.9, spec:45, dir:1}, $
   /replace, /silent

; You can put this line into your idl_startup.pro to set up custom defaults
; for yourself.

; There is a generic tplot snapshot program with less functionality, but it
; works on any tplot variable with two independent variables (time and some 
; other parameter) and one dependent variable.

tsnap, var, [keyword=value, ...]

; I WANT NUMBERS NOT PLOTS!  HOW DO I GET NUMBERS?

; Get 3D, PAD, or SPEC data at a specified time or array of times.
;   Use keyword ALL to get all 3D/PAD distributions bounded by
;   the input time array.  Use keyword SUM to average all
;   distributions bounded by the input time array.  Set the BURST
;   keyword to get burst data instead of survey data.  (You have
;   to load burst data first.  See above.)  Filter out known
;   anomalous spectra using keyword QLEVEL.

ddd = mvn_swe_get3d(time, units='eflux', qlevel=1)
pad = mvn_swe_getpad(time, qlevel=1)
spec = mvn_swe_getspec(time, qlevel=1)

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

ddd = mvn_swe_get3d(time, units='eflux', /shiftpot, qlevel=1)
pad = mvn_swe_getpad(time, /shiftpot, qlevel=1)
spec = mvn_swe_getspec(time, /shiftpot, qlevel=1)

swe_engy_snap, /mom, /fixy, /secondary, spec=spec, /shiftpot, qlevel=1
swe_pad_snap, energy=130, /secondary, pad=pad, /shiftpot, qlevel=1
swe_3d_snap, /spec, /symdir, energy=130, ddd=ddd, smo=[5,1,1], /shiftpot, qlevel=1

;
; VISUALIZING THE ORBIT AND SPACECRAFT LOCATION OVER THE MISSION.
;
; Load the spacecraft ephemeris from MOI to the current date plus
; a few weeks into the future.  Uses reconstructed ephemeris data
; as much as possible, then predicts as far as NAIF provides them.
; Use the LOADONLY keyword to load the ephemeris into TPLOT without
; resetting the time range.  Warning: this routine will reinitialize
; SPICE, so you should do it in a separate instance of IDL.
;
; Ephemeris data are updated daily at 3:30 am Pacific.

maven_orbit_tplot, /mission, /loadonly

;
; VISUALIZING THE ORBIT FAR INTO THE FUTURE.
;
; Ephemeris predicts are available that extend to the nominal end
; of mission at the end of 2031.  This is useful for long-range
; planning.  Warning: this routine will reinitialize SPICE, so you
; should do it in a separate instance of IDL.

maven_orbit_predict

; After this, you can use maven_orbit_snap as usual.  The overall
; orbit evolution (its orientation in the MSO frame as a function of
; time) is reasonably well predicted.  However, the time of periapsis
; becomes highly uncertain just a few weeks into the future.  Note
; that the predicts make assumptions about atmospheric variability and 
; orbit maintainence maneuvers that may or may not occur as planned.
; Inability to predict the atmospheric density is the main source
; of uncertainty.

;
; ESTIMATING THE PENETRATING PARTICLE BACKGROUND
;
; Protons with energies above ~20 MeV and electrons with energies above
; ~2 MeV can penetrate the instrument housing and internal walls to pass
; through the MCP, where they can trigger electron cascades and generate
; counts.  In addition, electrons below 2 MeV scatter off atoms in the
; instrument walls and emit bremsstrahlung radiation at x-ray energies
; (typically 10-30 keV).  These x-rays penetrate internal walls to impact 
; the MCP and generate counts.  Finally, radioactive decay of potassium-40
; (half-life: 1.3 Gy) in the MCP glass emits electrons and positrons that
; can also contribute background counts.
;
; Galactic Cosmic Rays (GCRs, dominated by H+ and He++) are essentially
; isotropic and peak near 1 GeV.  They easily pass through the instrument 
; and the entire spacecraft, resulting in a background count rate of 
; several counts per second summed over all anodes.  The GCR background 
; varies by a factor of two over the 11-year solar cycle, but should be 
; essentially constant over time scales of days to weeks.
;
; SEP events are episodic, but can increase the penetrating particle 
; background by orders of magnitude for days.  SEP events can contain 
; both energetic ions and electrons.  In addition, SEP events often have
; an electron population below 5 keV that SWEA measures normally.  Thus,
; during SEP events, the 1-5-keV count rate can result from five sources: 
; (1) < 5 keV electrons, (2) bremsstrahlung x-rays, (3) > 2 MeV electrons, 
; (4) > 20 MeV protons, and (5) radioactive decay of potassium-40 in the
; MCP glass. 
;
; If you are analyzing SWEA data at energies above ~1 keV, then you may 
; want to consider subtracting this background.  During SEP events, this
; may be difficult because of the presence of 1-5-keV electrons; however,
; during quiet times, when the background is dominated by GCR's, the 
; recommended approach is to use mvn_swe_background.  The header of that 
; program contains instructions on how to use it.
;
; Because of the stochastic nature of the data, subtracting background
; can result in negative values.  You'll have to decide what to do in 
; this case.

mvn_swe_background

;
; I HAVE QUESTIONS AND/OR I NEED HELP WITH ....
;
; If you have questions about the instrument or how to work with and
; interpret SWEA data, please contact us:
;
;   Dave Mitchell - SWEA Lead        - davem@berkeley.edu
;   Shaosui Xu    - SWEA Deputy Lead - shaosui.xu@berkeley.edu
;
; Before contacting us, please read over this crib sheet first.  Answers
; to some questions about SWEA IDL software can be found using doc_library,
; as described above.  If you're still stuck, send us an email.  If you're
; at SSL, feel free to stop by.

; If any of the SWEA IDL code crashes or otherwise causes problems, then 
; send us an email.  It is very helpful to cut and paste details of the 
; IDL session into your email -- the commands that lead up to the problem,
; along with any output and error messages that result.  It's ideal if you
; can recreate the problem from a fresh instance of IDL.  If we can 
; reproduce the problem, we are much more likely to be able to fix it.
; If we can't reproduce the problem, that points to a configuration issue.
; Either way, we get to the bottom of your issue faster.

;-
