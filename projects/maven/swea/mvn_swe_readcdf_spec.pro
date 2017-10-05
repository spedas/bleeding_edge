;+
; NAME: 
;   MVN_SWE_READCDF_SPEC
; SYNTAX:
;	MVN_SWE_READCDF_SPEC, INFILE, STRUCTURE
; PURPOSE:
;	Routine to read CDF file from mvn_swe_makecdf_spec.pro
; INPUTS:
;   INFILE: CDF file name to read
;           (nominally created by mvn_swe_makecdf_spec.pro)
; OUTPUT:
;   STRUCTURE: IDL data structure
; KEYWORDS:
;   OUTFILE: Output file name
; HISTORY:
;   Created by Matt Fillingim
; VERSION:
;   $LastChangedBy: dmitchell $
;   $LastChangedDate: 2015-11-09 15:06:32 -0800 (Mon, 09 Nov 2015) $
;   $LastChangedRevision: 19322 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_readcdf_spec.pro $
;
;-

pro mvn_swe_readcdf_spec, infile, structure

  @mvn_swe_com

; initialize
  mvn_swe_init

  n_e = swe_engy_struct.nenergy

  if (size(infile, /type) eq 0) then begin
    print, 'You must specify a file name.'
    return
  endif

  id = CDF_OPEN(infile)

; get length of data arrays (i.e., number of samples)

  CDF_VARGET, id, 'num_spec', nrec

; create structure template to fill

  structure = replicate(swe_engy_struct, nrec)

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
             data_name = 'SWEA SPEC Survey'
             apid = 'A4'XB
           END
    'arc': BEGIN
             data_name = 'SWEA SPEC Archive'
             apid = 'A5'XB
           END
  ELSE:   BEGIN
            print, 'Error: check filename convention'
            return
          END
  ENDCASE

  structure.data_name = data_name
  structure.apid = apid

; *** units_name

  structure.units_name = 'eflux'

; *** units_procedure

  structure.units_procedure = 'mvn_swe_convert_units'

; *** met
; met -- time_met: mission elapsed time -> center of measurement period

  CDF_VARGET, id, 'time_met', met, /ZVAR, rec_count = nrec
  structure.met = reform(met)

; *** time
; time -- time_unix: Unix time -> center of measurement period

  CDF_VARGET, id, 'time_unix', time, /ZVAR, rec_count = nrec
  time = reform(time)
  structure.time = time

; *** end_time
; end_time -- center time (time) + measurement period/2

  dt = 1.95D ; measurement span
  end_time = time + dt/2.D
  structure.end_time = end_time

; *** delta_t
; delta_t -- sample cadence; time between samples

  delta_t = time - shift(time, 1)
  delta_t[0] = delta_t[1]

;; there appears to be a glitch whenever delta_t changes
;; look for changes in delta_t
;delta_delta_t = delta_t - shift(delta_t, 1)
;delta_delta_t[0] = delta_delta_t[1]
;ndx = where(abs(delta_delta_t) gt gt 0.5, n_ndx) ; some small number
;; should come in pairs of two
;if (n_ndx gt 0) then for i = 0, n_ndx/2 - 1 do $
;  delta_t[ndx[2*i]:ndx[2*i+1]] = delta_t[ndx[2*i] + 2]

  structure.delta_t = delta_t

; *** integ_t
; integ_t -- integration time per energy/angle bin -- fixed
; [From mvn_swe_get3d.pro]
; There are 7 deflection bins for each of 64 energy bins spanning 1.95 s
; (the first deflection bin is for settling and is discarded).

  integ_t = 1.95D/64.D/7.D ; = 0.00435... sec
  structure.integ_t = integ_t

; *** dt_arr
; dt_arr -- weighting array for summing bins ; [n_e]
; include information from num_accum --> period
; multiply by dsf --> weight_factor

  CDF_VARGET, id, 'num_accum', tmp_num_accum, /ZVAR, rec_count = nrec ; nrec]
  CDF_VARGET, id, 'weight_factor', tmp_dsf, /ZVAR
  dt_arr0 = 16.*6.*tmp_dsf ; sum over azimuth and elevation bins
  dt_arr = replicate(dt_arr0, n_e) # tmp_num_accum ; [n_e, nrec]
  structure.dt_arr = dt_arr

; *** nenergy
; nenergy -- number of energies = 64

  structure.nenergy = n_e

; *** energy
; energy -- energy sweep ; [n_e]

  CDF_VARGET, id, 'energy', tmp_energy, /ZVAR ; [64]
  structure.energy = tmp_energy

; *** denergy
; denergy - energy widths for each energy/angle bin ; [n_e]

  CDF_VARGET, id, 'de_over_e', tmp_de_over_e, /ZVAR ; [64]
  tmp_denergy = tmp_de_over_e*tmp_energy ; [64]
  structure.denergy = tmp_denergy

; let us assume a priori that the energy sweep table is either 5 or 6
; (according to DM - not backward compatible to earlier tables)
; *** energy sweep constant over CDF file (energy --> NOVARY) ***

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

; *** eff
; eff -- MCP efficiency ; [n_e]
; we will define structure.eff[*] = 1.
; the only place structure.eff is used is in mvn_swe_convert_units.pro
; --> gf = data.gf*data.eff
; therefore, we can fold all of the eff and gf information into
; structure.gf (below) and set structure.eff = 1.

  structure.eff = replicate(1., n_e)

; *** gf
; gf -- geometric factor per energy/angle bin
; reconstruct gf*eff (eff = 1.)

  CDF_VARGET, id, 'geom_factor', geom_factor, /ZVAR ; integer
  CDF_VARGET, id, 'g_engy', g_engy, /ZVAR ; [64]

  gfe = geom_factor*g_engy
  structure.gf = gfe

; *** dtc
; dtc -- dead time correction

  CDF_VARGET, id, 'counts', counts, /ZVAR, rec_count = nrec ; [64, nrec]
  rate = counts/(integ_t*dt_arr) ; raw count rate ; [64, nrec]
  dtc = 1. - rate*swe_dead
  ndx = where(dtc lt swe_min_dtc, count)
  if (count gt 0L) then dtc[ndx] = !values.f_nan
  structure.dtc = dtc

; *** mass
; mass -- electron rest mass [eV/(km/s)^2]

  structure.mass = mass_e

; *** sc_pot
; sc_pot -- spacecraft potential (place holder to be filled in by LPW or SWEA;
;           see mvn_swe_sc_pot for details)

  structure.sc_pot = 0.

; *** magf
; magf -- magnetic field (place holder to be filled in by mvn_swe_addmag)

  structure.magf = [0.,0.,0.]

; *** bkg
; bkg -- background (place holder to be filled in later)
;   This is typically the signal in highest energy channels, but not always.
;   In units of energy flux or count rate, the background should be constant
;   as a function of energy.

  structure.bkg = 0.

; *** data
; data -- data in units of differential energy flux

  CDF_VARGET, id, 'diff_en_fluxes', data, /ZVAR, rec_count = nrec
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

  scale = 1D/(dtc*integ_t*dt_arr*structure.gf)
  var = var*(scale*scale)
  structure.var = var

; *** chksum and valid (chksum is determined by mvn_swe_calib, above)

  structure.chksum = swe_chksum[0]
  structure.valid = 1B

; finis!
CDF_CLOSE, id

end
