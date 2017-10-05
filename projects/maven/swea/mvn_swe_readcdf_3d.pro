;+
; NAME: 
;   MVN_SWE_READCDF_3D
; SYNTAX:
;   MVN_SWE_READCDF_3D, INFILE, STRUCTURE
; PURPOSE:
;   Routine to read CDF file from mvn_swe_makecdf_3d.pro
; INPUTS:
;   INFILE: CDF file name to read
;           (nominally created by mvn_swe_makecdf_3d.pro)
; OUTPUT:
;   STRUCTURE: IDL data structure
; KEYWORDS:
;   OUTFILE: Output file name
; HISTORY:
;   Created by Matt Fillingim
; VERSION:
;   $LastChangedBy: dmitchell $
;   $LastChangedDate: 2015-11-09 15:06:46 -0800 (Mon, 09 Nov 2015) $
;   $LastChangedRevision: 19323 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_readcdf_3d.pro $
;
;-

pro mvn_swe_readcdf_3d, infile, structure

  @mvn_swe_com

; initialize
  mvn_swe_init

  n_e  = swe_3d_struct.nenergy  ; 64 energies
  n_az = 16                     ; 16 azimuths
  n_el = 6                      ;  6 elevations
  n_a  = swe_3d_struct.nbins    ; 96 solid angles

  if (size(infile, /type) eq 0) then begin
    print, 'You must specify a file name.'
    return
  endif

  id = CDF_OPEN(infile)

; get length of data arrays (i.e., number of samples)

  CDF_VARGET, id, 'num_dists', nrec

; create template structure to fill

  structure = replicate(swe_3d_struct, nrec)

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
             data_name = 'SWEA 3D Survey'
             apid = 160B
           END
    'arc': BEGIN
             data_name = 'SWEA 3D Archive'
             apid = 161B
           END
    ELSE: BEGIN
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
  structure.delta_t = delta_t

; *** integ_t
; integ_t -- integration time per energy/angle bin -- fixed
; [From mvn_swe_get3d.pro]
; There are 7 deflection bins for each of 64 energy bins spanning 1.95 s
; (the first deflection bin is for settling and is discarded).

  integ_t = 1.95D/64.D/7.D ; = 0.00435... sec
  structure.integ_t = integ_t

; *** dt_arr and group
; dt_arr -- weighting array for summing bins ; [n_e, n_a]
; [From mvn_swe_get3d.pro]
; There are 80 angular bins to span 16 anodes (az) X 6 deflections (el).
; Adjacent anodes are summed at the largest upward and downward elevations,
; so that the 16 x 6 = 96 bins are reduced to 80. However, I will maintain
; 96 bins and duplicate data at the highest deflections.
; Then dt_arr is used to renormalize and effectively divide the counts
; evenly between each pair of duplicated bins

  dt_arr = fltarr(n_e, n_a, nrec)
  dt_arr[*,  0:15, *] = 2. ; adjacent anode (azimuth) bins summed
  dt_arr[*, 16:79, *] = 1. ; no summing for mid-elevations
  dt_arr[*, 80:95, *] = 2. ; adjacent anode (azimuth) bins summed

; Energy bins are summed according to the group parameter.
; first get group parameter

  CDF_VARGET, id, 'binning', binning, /ZVAR, rec_count = nrec
  binning = REFORM(binning) ; fix dimensions of array [1, nrec] --> [nrec]

; since binning = 2^group, group = log2(binning) = log(binning)/log(2)

  group = alog(binning)/alog(2.)
  for i=0L,(nrec-1) do dt_arr[*,*,i] = (2.^group[i])*dt_arr[*,*,i]

  structure.dt_arr = dt_arr
  structure.group = group

; *** nenergy
; nenergy -- number of energies = 64

  structure.nenergy = n_e

; *** energy
; energy -- energy sweep ; [n_e, n_a, nrec]

  CDF_VARGET, id, 'energy', tmp_energy, /ZVAR ; [64]
  energy = fltarr(n_e, n_a, nrec)
  for i=0L,(nrec-1) do energy[*,*,i] = tmp_energy # replicate(1.,n_a)
  structure.energy = energy

; *** denergy
; denergy - energy widths for each energy/angle bin ; [n_e, n_a]

  CDF_VARGET, id, 'de_over_e', tmp_de_over_e, /ZVAR ; [64]
  tmp_denergy = tmp_de_over_e*tmp_energy ; [64]
  denergy = tmp_denergy # replicate(1., n_a) ; [64, 96]
  structure.denergy = denergy

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
; eff -- MCP efficiency ; [n_e, n_a]
; we will define structure.eff[*, *] = 1.
; the only place structure.eff is used is in mvn_swe_convert_units.pro
; --> gf = data.gf*data.eff
; therefore, we can fold all of the eff and gf information into
; structure.gf (below) and set structure.eff = 1.

  structure.eff = replicate(1., n_e, n_a)

; *** nbins
; nbins -- number of solid angle bins

  structure.nbins = n_a

; *** theta
; theta -- elevation angle

  CDF_VARGET, id, 'elev', elev, /ZVAR ; [64, 6]

; change dimensions [64, 6] --> [64, 96]

  theta = fltarr(n_e, n_a)
  for i=0L,(n_a-1) do theta[*,i] = elev[*,i/16]
  structure.theta = theta

; *** dtheta
; dtheta -- elevation angle width
; [following mvn_swe_calib.pro]
; for each energy step, just make the bins touch with no gaps
; assume this is not a function of angle; a function of energy only
; [this is what mvn_swe_calib.pro also assumes]

  delev = median(elev - shift(elev, 0, 1), dimension=2) ; [n_e]
  dtheta = delev # replicate(1., n_a) ; [n_e, n_a]
  structure.dtheta = dtheta

; *** phi and dphi
; phi -- azimuth angle
; dphi -- azimuth angle width

  CDF_VARGET, id, 'azim', azim, /ZVAR

; change dimensions [16] --> [64, 96]
; phi and dphi are fixed w.r.t. energy

  dazim = (shift(azim, -1) - shift(azim, 1))/2.
  dazim[[0, n_az-1]] = dazim[[0, n_az-1]] + 180.

  phi = fltarr(n_e, n_a)
  dphi = fltarr(n_e, n_a)
  for i=0L,(n_a-1) do begin
    k = i mod 16
    phi[*,i] = azim[k]
    dphi[*,i] = dazim[k]
  endfor

  structure.phi = phi
  structure.dphi = dphi

; *** domega
; domega -- solid angle

  structure.domega = (2.*!dtor)*dphi*cos(theta*!dtor)*sin(dtheta*!dtor/2.)

; *** gf
; gf -- geometric factor per energy/angle bin
; reconstruct gf*eff (eff = 1.)

  CDF_VARGET, id, 'geom_factor', geom_factor, /ZVAR ; integer
  CDF_VARGET, id, 'g_engy', g_engy, /ZVAR ; [64]
  CDF_VARGET, id, 'g_elev', g_elev, /ZVAR ; [64, 6]
  CDF_VARGET, id, 'g_azim', g_azim, /ZVAR ; [16]

  gfe = fltarr(n_e, n_a)
  for i=0L,(n_a-1) do gfe[*,i] = geom_factor*g_engy*g_elev[*,i/16]*g_azim[i mod 16]

; average the first and last 16 bins (top and bottom elevation angles)

  i = 2*indgen(8)
  i = [i, i+80]
  gfe[*,i]   = (gfe[*,i] + gfe[*,i+1])/2.
  gfe[*,i+1] =  gfe[*,i]

; geometric factor and efficiency are constant as a function of time within a day

  for i=0L,(nrec-1L) do structure[i].gf = gfe

; *** dtc
; dtc -- dead time correction

  CDF_VARGET, id, 'counts', counts, /ZVAR, rec_count = nrec ; [64, 96, nrec]
  counts = REFORM(counts, 64, 96, nrec)
  rate = counts/(integ_t*dt_arr) ; raw count rate ; [64, 96, nrec]
  dtc = 1. - rate*swe_dead
  ndx = where(dtc lt swe_min_dtc, count)
  if (count gt 0L) then dtc[ndx] = !values.f_nan
  structure.dtc = dtc

; *** mass
; mass -- electron rest mass [eV/(km/s)^2]

  structure.mass = mass_e

; *** sc_pot
; sc_pot -- spacecraft potential
;   This is a place holder to be filled in by LPW or SWEA data
;   (see mvn_swe_sc_pot for details).

  structure.sc_pot = 0.

; *** magf
; magf -- magnetic field (place holder to be filled in by mvn_swe_addmag)

  structure.magf = [0.,0.,0.]

; *** v_flow
; v_flow -- bulk flow velocity (place holder to be filled in by SWIA/STATIC)

  structure.v_flow = [0.,0.,0.]

; *** bkg
; bkg -- background (placeholder to be filled in later)
;   This is typically the signal in highest energy channels, but not always.
;   In units of energy flux or count rate, the background should be constant
;   as a function of energy.

  structure.bkg = 0.

; *** data
; data -- data in units of differential energy flux

  CDF_VARGET, id, 'diff_en_fluxes', data, /ZVAR, rec_count = nrec

; reform dimensions [64, 16, 6, nrec] --> [64, 96, nrec]

  structure.data = reform(data, 64, 96, nrec)

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
