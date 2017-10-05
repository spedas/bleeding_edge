;+
; NAME:
;   MVN_SWE_READCDF_PAD
; SYNTAX:
;   MVN_SWE_READCDF_PAD, INFILE, STRUCTURE
; PURPOSE:
;   Routine to read CDF file from mvn_swe_makecdf_pad.pro
; INPUTS:
;   INFILE: CDF file name to read
;           (nominally created by mvn_swe_makecdf_pad.pro)
; OUTPUT:
;   STRUCTURE: IDL data structure
; KEYWORDS:
;   OUTFILE: Output file name
; HISTORY:
;   Created by Matt Fillingim
; VERSION:
;   $LastChangedBy: dmitchell $
;   $LastChangedDate: 2015-11-09 15:06:23 -0800 (Mon, 09 Nov 2015) $
;   $LastChangedRevision: 19321 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_readcdf_pad.pro $
;
;-

pro mvn_swe_readcdf_pad, infile, structure

  @mvn_swe_com

; initialize
  mvn_swe_init

  n_e = swe_pad_struct.nenergy  ; 64 energies
  n_az = 16                     ; 16 azimuths
  n_el = 6                      ;  6 elevations
  n_a = swe_pad_struct.nbins    ; 16 pitch angles

  if (size(infile,/type) eq 0) then begin
    print, 'You must specify a file name.'
    return
  endif

  id = CDF_OPEN(infile)

; Get length of data arrays (i.e., number of samples)

  CDF_VARGET, id, 'num_dists', nrec

; Create structure template to fill

  structure = replicate(swe_pad_struct, nrec)

; from the top
; *** project_name

  structure.project_name = 'MAVEN'

; *** data_name and apid
; survey or archive data? get info from the filename

  pos = strpos(infile, 'mvn_swe_l2_', /reverse_search)
  if (pos eq -1) then begin
    print, 'Error: check filename convention'
    return
  endif

  tag = strmid(infile, pos+11 ,3) ; should be 'svy' or 'arc'

  CASE tag OF
    'svy': BEGIN
             data_name = 'SWEA PAD Survey'
             apid = 'A2'XB
           END
    'arc': BEGIN
             data_name = 'SWEA PAD Archive'
             apid = 'A3'XB
           END
    ELSE: BEGIN
            print, 'Error: check filename convention'
            return
          END
  ENDCASE

  structure.data_name = data_name
  structure.apid = apid

; *** units_name

  units_name = 'eflux'
  structure.units_name = units_name

; *** units_procedure

  units_procedure = 'mvn_swe_convert_units'
  structure.units_procedure = units_procedure

; *** met
; met -- time_met: mission elapsed time -> center of measurement period

  CDF_VARGET, id, 'time_met', met, /ZVAR, rec_count = nrec
  met = REFORM(met) ; fix dimensions of array [1, nrec] --> [nrec]
  structure.met = met

; *** time
; time -- time_unix: Unix time -> center of measurement period

  CDF_VARGET, id, 'time_unix', time, /ZVAR, rec_count = nrec
  time = REFORM(time) ; fix dimensions of array [1, nrec] --> [nrec]
  structure.time = time

; *** end_time
; end_time -- center time (time) + measurement period/2

  dt = 1.95D ; measurement span
  end_time = time + dt/2.D
  structure.end_time = end_time

; *** delta_t
; delta_t -- sample cadence; time between samples
;;; *** not quite correct -- some time jitter *** ;;;
;;; *** as good as it gets -- don't have access to the period *** ;;;

  delta_t = time - shift(time, 1)

; replace first element (large negative number) with a copy of 2nd
; assumes time between 1st and 2nd sample = time between 2nd and 3rd

  delta_t[0] = delta_t[1]
  structure.delta_t = delta_t

; *** integ_t
; integ_t -- integration time per energy/angle bin -- fixed
; [From mvn_swe_get3d.pro]
; There are 7 deflection bins for each of 64 energy bins spanning 1.95 s
; (the first deflection bin is for settling and is discarded).

  integ_t = 1.95D/64.D/7.D ; = 0.00435... sec
  structure.integ_t = integ_t

; *** dt_arr and group
; dt_arr -- weighting array for summing bins ; [n_e, n_az]
; There are 16 anodes (az) X 6 deflections (el). PAD data use the magnetic
; field to calculate the optimal deflection bin for each of the 16 anode
; bins in order to provide the best pitch angle coverage.  There is no
; summing of angle bins, even at the highest deflections (as in the 3D's).
; So for each energy bin, there is a 16x1 (az, el) array. The final array
; dimensions are then 64 energies X 16 anodes X 1 deflector bin per anode,
; or 64x16, for short.

;dt_arr = fltarr(n_e, n_az, nrec)

  dt_arr = replicate(1., n_e, n_az, nrec)

; Energy bins are summed according to the group parameter.
; first get group parameter

  CDF_VARGET, id, 'binning', binning, /ZVAR, rec_count = nrec
  binning = REFORM(binning) ; fix dimensions of array [1, nrec] --> [nrec]

; since binning = 2^group, group = log2(binning) = log(binning)/log(2)

  group = alog(binning)/alog(2.)

  for i=0l,(nrec-1) do dt_arr[*, *, i] = (2.^group[i])*dt_arr[*,*,i]

  structure.dt_arr = dt_arr
  structure.group = group

; *** nenergy
; nenergy -- number of energies = 64

  structure.nenergy = n_e ; fixed

; *** energy
; energy -- energy sweep ; [n_e, n_az, nrec]

  CDF_VARGET, id, 'energy', tmp_energy, /ZVAR ; [64]
  energy = fltarr(n_e, n_az, nrec)
  for i = 0l, nrec-1 do energy[*,*,i] = tmp_energy # replicate(1.,n_az)

  structure.energy = energy

; *** denergy
; denergy - energy widths for each energy/angle bin ; [n_e, n_az]

  CDF_VARGET, id, 'de_over_e', tmp_de_over_e, /ZVAR ; [64]
  tmp_denergy = tmp_de_over_e*tmp_energy ; [64]
  denergy = tmp_denergy # replicate(1., n_az) ; [64, 96]
  structure.denergy = denergy

; *** eff
; eff -- MCP efficiency ; [n_e, n_az]
; we will define structure.eff[*, *] = 1.
; the only place structure.eff is used is in mvn_swe_convert_units.pro
; --> gf = data.gf*data.eff
; therefore, we can fold all of the eff and gf information into
; structure.gf (below) and set structure.eff = 1.

  structure.eff = replicate(1., n_e, n_az)

; *** nbins
; nbins -- number of angle bins (always 16: one pitch angle bin for every
;          azimuth bin)

  structure.nbins = n_az

; *** pa
; pa -- pitch angle ; [n_e, n_az, nrec]

  CDF_VARGET, id, 'pa', pa, /ZVAR, rec_count = nrec ; [64, 16, nrec]
  structure.pa = pa*!dtor     ; pa degrees --> radians

; *** dpa
; dpa -- pitch angle width ; [n_e, n_az, nrec]

  CDF_VARGET, id, 'd_pa', dpa, /ZVAR, rec_count = nrec ; [64, 16, nrec]
  structure.dpa = dpa*!dtor   ; d_pa in degrees --> dpa in radians

; Magnetic field azimuth and elevation

  CDF_VARGET, id, 'b_azim', Baz, /ZVAR, rec_count = nrec
  structure.Baz = reform(Baz)*!dtor   ; b_azim in degrees --> Baz in radians

  CDF_VARGET, id, 'b_elev', bel, /ZVAR, rec_count = nrec
  structure.Bel = reform(Bel)*!dtor   ; b_elev in degrees --> Bel in radians

; let us assume a priori that the energy sweep table is either 5 or 6
; (according to DM - not backward compatible to earlier tables)
; *** energy sweep constant over CDF file (energy --> NOVARY) ***
; need this to reconstruct deflection angle (theta) --> swp.theta

  if (size(swe_hsk,/type) ne 8) then begin

    mvn_swe_sweep, result=swp5, tabnum=5
    mvn_swe_sweep, result=swp6, tabnum=6

; which is it?

    diff = 0.01
    if (abs(total(tmp_energy - swp5.e)) lt diff) then begin
      tabnum = 5
      swp = swp5
    endif else begin
      tabnum = 6
      swp = swp6
    endelse

; Once we know the sweep table, we can determine the calibration factors

    mvn_swe_calib, tabnum=tabnum

  endif

; *** gf
; gf -- geometric factor per energy/angle bin
; reconstruct gf*eff (eff = 1.)

  CDF_VARGET, id, 'geom_factor', geom_factor, /ZVAR ; integer
  CDF_VARGET, id, 'g_engy', g_engy, /ZVAR ; [64]
  CDF_VARGET, id, 'g_pa', g_pa, /ZVAR, rec_count = nrec ; [64, 16, nrec]

  gf_engy = geom_factor*(g_engy # replicate(1., n_az))
  gfe = fltarr(n_e, n_az, nrec)
  for i=0l,(nrec-1) do gfe[*,*,i] = gf_engy*g_pa[*,*,i]

  structure.gf = gfe

; *** dtc
; dtc -- dead time correction

  CDF_VARGET, id, 'counts', counts, /ZVAR, rec_count = nrec ; [64, 16, nrec]
  rate = counts/(integ_t*dt_arr) ; raw count rate ; [64, 16, nrec]
  dtc = 1. - rate*swe_dead
  indx = where(dtc lt swe_min_dtc, count) ; maximum deadtime correction
  if (count gt 0l) then dtc[indx] = !values.f_nan

  structure.dtc = dtc

; *** mass
; mass -- electron rest mass [eV/(km/s)^2]  (from swe_com)

  structure.mass = mass_e

; *** sc_pot
; sc_pot -- spacecraft potential
;   This is a place holder to be filled in by LPW or SWEA data
;   (see mvn_swe_sc_pot for details).

  structure.sc_pot = 0.

; *** magf
; magf -- magnetic field (placeholder to be filled in by mvn_swe_addmag)

  structure.magf = [0.,0.,0.]

; *** v_flow
; v_flow -- bulk flow velocity (placeholder to be filled in by SWIA/STATIC)

  structure.v_flow = [0.,0.,0.]

; *** bkg
; bkg -- background (placeholder to be filled in later)
;   This is typically the signal in highest energy channels, but not always.
;   In units of energy flux or count rate, the background should be constant
;   as a function of energy.

  structure.bkg = 0.

; *** data
; data -- data in units of differential energy flux

  CDF_VARGET, id, 'diff_en_fluxes', data, /ZVAR, rec_count = nrec ; [16, 16, nrec]
  structure.data = data

; *** variance
; recompress the raw counts to 8-bit value, use this to index devar (swe_com)

  x = alog(counts > 1.)/alog(2.)
  i = floor(x)
  j = floor((2.^(x - i) - 1.)*16.)
  k = (i - 3)*16 + j
  indx = where(counts lt 32., cnt)
  if (cnt gt 0L) then k[indx] = round(counts[indx])
  var = devar[k]

; in units of counts - want in units of energy flux (data)
; from mvn_swe_convert_units
; input: 'COUNTS' : scale = 1D
; output: 'EFLUX' : scale = scale * 1D/(dtc * dt * dt_arr * gf)
;                   where dt = integ_t ; gf = gf*eff ; eff = 1
;scale = 1.D/(dtc*integ_t*dt_arr*gfe) ; gfe only [64, 16]

  scale = 1.D/(dtc*integ_t*dt_arr*structure.gf) ; want [64, 16, nrec]
  var = var*(scale*scale)
  structure.var = var

; *** chksum and valid

  structure.chksum = swe_chksum[0]
  structure.valid = 1B

; finis!
CDF_CLOSE, id

end
