;+
; Set of routines for downloading, reading, and
; plotting ACE EPAM data from the RTSW archive
; and the quicklook (updated throughout day).
; Intended for comparison/baseline study with STIS.
;
; Example call:
;  > ace_rtsw_epam_load, /quicklook, /tplot, cadence='5min'
;  > tplot, 'ace_*_epam_*_flux'
;
; Missing functionality:
; - Generalize ace_rtsw_load & ace_quicklook_read for any instrument
; - Preferred retrieval of Level 2 data once available from CDAweb/ASC
; - Mask keyword for errant data
;
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-11-05 18:25:21 -0800 (Wed, 05 Nov 2025) $
; $LastChangedRevision: 33833 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/ace_load.pro $

function ace_struct_template, instrument

  ; All lower case the instrument name:
  instrument = instrument.tolower()

  struct = {}

  if instrument.startswith('epam') then begin
    ; Electron energy is fixed across all times for EPAM
    elec_energy_range = [[38.0, 53.0], [175.0, 315.0]]
    elec_denergy = reform(elec_energy_range[1, *] - elec_energy_range[0, *])
    elec_energy = reform(elec_energy_range[0, *]) + elec_denergy/2

    ; Ion energy is fixed across all times for EPAM
    proton_energy_range = [[47.0, 68.0], [115.0, 195.0], [310.0, 580.0], [795.0, 1193.0], [1060.0, 1900.0]]
    proton_denergy = reform(proton_energy_range[1, *] - proton_energy_range[0, *])
    proton_energy = reform(proton_energy_range[0, *]) + proton_denergy/2

    ; Structure to contain EPAM information:
    ; - elec_energy: fixed
    ; - ion_energy
    ; # Units: Differential Flux particles/cm2-s-ster-MeV
    ; # Units: Anisotropy Index 0.0 - 2.0
    ; # Status(S): 0 = nominal, 4,6,7,8 = bad data, unable to process, 9 = no data
    ; # Missing data values: -1.00e+05, index = -1.00

    ; epam_struct, $
    struct = {time:0d, $
        time_unix: 0d, $
        elec_status: 0s, $
        elec_energy: elec_energy, $
        elec_denergy: elec_denergy, $
        elec_flux: replicate(!values.f_nan, 2),  $
        proton_status: 0s, $
        proton_energy: proton_energy, $
        proton_denergy: proton_denergy, $
        proton_flux: replicate(!values.f_nan, 5),$
        anisotropy: !values.f_nan,$
        quicklook: 0B,$
        rtsw: 0B}

  endif else if instrument.startswith('mag') then begin
    ; magnetometer. Header from data file:
    ; Magnetometer values are in GSM coordinates.
    ; Units: Bx, By, Bz, Bt in nT
    ; Units: Latitude  degrees +/-  90.0
    ; Units: Longitude degrees 0.0 - 360.0
    ; Status(S): 0 = nominal data, 1 to 8 = bad data record, 9 = no data
    ; Missing data values: -999.9
    ; Source: ACE Satellite - Magnetometer
    ; 1-minute averaged Real-time Interplanetary Magnetic Field Values 

    struct = {time:0d, $
        time_unix: 0d, $
        status: 0s, $
        vec: replicate(!values.f_nan, 3),$
        total: !values.f_nan, $
        lat: !values.f_nan, $
        long: !values.f_nan, $
        quicklook: 0B,$
        rtsw: 0B}

  endif else if instrument.startswith('swepam') then begin
    ; Units: Proton density p/cc
    ; Units: Bulk speed km/s
    ; Units: Ion tempeture degrees K
    ; Status(S): 0 = nominal data, 1 to 8 = bad data record, 9 = no data
    ; Missing data values: Density and Speed = -9999.9, Temp. = -1.00e+05
    ; Source: ACE Satellite - Solar Wind Electron Proton Alpha Monitor
    ; 1-minute averaged Real-time Bulk Parameters of the Solar Wind Plasma

    struct = {time:0d, $
        time_unix: 0d, $
        status: 0s, $
        proton_density: !values.f_nan, $
        bulk_velocity: !values.f_nan, $
        ion_temperature_K: !values.f_nan, $
        quicklook: 0B,$
        rtsw: 0B}

  endif else if instrument.startswith('sis') then begin
    ; solar isotope spectrometer. From data file:
    ; Units: proton flux p/cs2-sec-ster
    ; Status(S): 0 = nominal data, 1 to 8 = bad data record, 9 = no data
    ; Missing data values: -1.00e+05
    ; Source: ACE Satellite - Solar Isotope Spectrometer
    ; 5-minute averaged Real-time Integral Flux of High-energy Solar Protons
    struct = {time:0d, $
        time_unix: 0d, $
        status: 0s, $
        proton_over_10MeV_status: 0s, $
        proton_over_10MeV_flux: !values.f_nan, $
        proton_over_30MeV_status: 0s, $
        proton_over_30MeV_flux: !values.f_nan, $
        quicklook: 0B,$
        rtsw: 0B}

  endif else print, 'Not a valid instrument name for ACE, returning.'

  return,struct

end




; ; Loads Level-2 data of ACE EPAM

; pro ace_epam_l2_load, trange=trange, cadence=cadence, ext=ext, download=download

; end

;
; Downloads and stores preliminary ACE data from the ACE Real time Solar Wind (RTSW)
; data archive on the ACE Science Center.
; Available instrument + cadences:
; - EPAM: 5 min, 1 hr
; - SWEPAM: 1 min, 1 hr
; - MAG: 1 min, 1 hr
; - SIS: 5 min, 1 hr
;

pro ace_rtsw_load, instrument, data_struct, trange=trange, cadence=cadence, ext=ext, download=download


  if ~keyword_set(ext) then ext = 'txt'
  if ~keyword_set(cadence) then cadence = '1h'

  ; All lower case the instrument name:
  instrument = instrument.tolower()
  cadence = strmid(cadence, 0, 2)

  ; Generate the RTSW filename:
  if cadence.startswith('1h') then begin
    fname = 'YYYYMM_ace_' + instrument +'_1h.txt'
  endif else begin
    ; return if any errant cadences supplied:
    case instrument of
      'epam': if ~cadence.startswith('5m') then return
      'swepam': if ~cadence.startswith('1m') then return
      'mag': if ~cadence.startswith('1m') then return
      'sis': if ~cadence.startswith('5m') then return
    endcase
    fname = 'YYYYMMDD_ace_' + instrument +'_' + cadence + '.txt'

  endelse

  ; Construct the file names for the time range:
  fname_daily = file_dailynames(file_format=fname,trange=tr,addmaster=addmaster, /unique)
  ; Download file.
  remote_path = "https://izw1.caltech.edu/ACE/ASC/DATA/RTSW/"
  psource = file_retrieve(/default_structure,local_data_dir=local_data_dir)
  files = spd_download_plus(remote_file=fname_daily, remote_path=remote_path,$
                            local_path=local_data_dir + 'ace/rtsw/',$
                            url_username='SRL', url_password='ForthRules', /last_version)
  nfiles = n_elements(files)
  ; print, files

  case instrument of
    'epam': n_skippedlines = 18
    'swepam': n_skippedlines = 18
    'mag': n_skippedlines = 20
    'sis': n_skippedlines = 16
  endcase

  ; EPAM weirdly has a difference between hourly and other cadence files
  if instrument.startswith('epam') and cadence.startswith('1h') then n_skippedlines = 17

  
  template = ace_struct_template(instrument)
  line = ''

  for i=0, nfiles - 1 do begin
    ; open file, count # lines and read
    file_i = files[i]
    openr, lun, file_i,/get_lun
    nlines = file_lines(file_i)
    nd = nlines - n_skippedlines

    struct_i = replicate(template, nd)

    for j=0, nlines - 1 do begin
      readf, lun, line
      if j lt n_skippedlines then continue

      ; line differs for each file:
      case instrument of
        'epam': reads, line, year, month, day, hhmm, julday, sec_day, elec_status, elec0, elec1,$
                  proton_status, proton0, proton1, proton2, proton3, proton4, anis_index
        'swepam': reads, line, year, month, day, hhmm, julday, sec_day, status, den, vel, temp
        'mag': reads, line, year, month, day, hhmm, julday, sec_day, status, bx, by, bz, bt, lat, lon
        'sis': reads, line, year, month, day, hhmm, julday, sec_day,$
                  proton_10MeV_status, proton_10MeV, proton_30MeV_status, proton_30MeV
      endcase

      t_struct = time_struct(0D)
      t_struct.year = year
      t_struct.month = month
      t_struct.date = day
      h = floor(hhmm/100)  ; HHMM is read as a float:
      t_struct.hour = h
      t_struct.min = hhmm - h*100
      t_struct.sec = 0

      time_unix = time_double(t_struct)

      ; Add struct components:
      index = j - n_skippedlines
      struct_j = struct_i[index]
      struct_j.time = time_unix
      struct_j.time_unix = time_unix
      struct_j.rtsw = 1B
      if instrument.startswith('epam') then begin
        ; convert the flux from particles/cm2-s-ster-MeV --> particles/cm2-s-ster-keV
        ; which is the common unit for SEP fluxes from MAVEN SEP or SWFO/STIS
        if elec_status eq 0 then struct_j.elec_flux = [elec0, elec1] * 1e-3
        if proton_status eq 0 then struct_j.proton_flux = [proton0, proton1, proton2, proton3, proton4] * 1e-3
        ; Additional fields available in RTSW that are not in the quicklook:
        ; elec_status, proton_status, anisotropy, and RTSW bit:
        struct_j.elec_status = elec_status
        struct_j.proton_status = proton_status
        struct_j.anisotropy = anis_index
      endif else if instrument.startswith('swepam') then begin
        struct_j.status = status
        if vel gt 0 then begin
          struct_j.proton_density = den
          struct_j.bulk_velocity = vel
          struct_j.ion_temperature_K = temp
        endif

      endif else if instrument.startswith('mag') then begin
        struct_j.status = status
        if status eq 0 then begin
          struct_j.vec[0] = bx
          struct_j.vec[1] = by
          struct_j.vec[2] = bz
          struct_j.total = bt
          struct_j.lat = lat
          struct_j.long = lon
        endif
      endif else if instrument.startswith('sis') then begin

        struct_j.proton_over_10MeV_status = proton_10MeV_status
        if proton_10MeV_status eq 0 then struct_j.proton_over_10MeV_flux = proton_10MeV
        struct_j.proton_over_30MeV_status = proton_30MeV_status
        if proton_30MeV_status eq 0 then struct_j.proton_over_30MeV_flux = proton_30MeV

      endif

      struct_i[index] = struct_j
    endfor
    free_lun, lun

    if i eq 0 then data_struct = struct_i else data_struct = [data_struct, struct_i]


  endfor


end

;; Reads the "expedited" ACE EPAM Browse data. This data is updated within minutes of
; receipt of Level 0 data to the Ace Science Center.

pro ace_quicklook_read, epam_struct

  ; file_retrieve doesn't work for https, but
  ; spd does
  quicklook_url = 'https://izw1.caltech.edu/ACE/ASC/DATA/epam_browse/EPAM_quicklook.txt'
  psource = file_retrieve(/default_structure,local_data_dir=local_data_dir)
  files = spd_download_plus(remote_file=quicklook_url,$
                            local_path=local_data_dir + 'ace/', /last_version)
  ; paths = spd_download(remote_file=epam_quicklook_url, local_path='/Users/rjolitz/Desktop/EPAM/')

  openr, lun, files[0],/get_lun
  nlines = file_lines(files[0])
  n_skippedlines = 12

  N = nlines - n_skippedlines

  line = ''

  epam_struct = ace_struct_template('epam')
  epam_struct = replicate(epam_struct, N )

  for i=0, nlines - 1 do begin
      readf, lun, line
      if i lt n_skippedlines then continue
      ; print, i, s
      ; stop
      index = i - n_skippedlines

      epam_struct_i = epam_struct[index]

      ; Get the data index:

      ; split line into components:
      ; 2025 297 00 01 20   3.524E+03   3.274E+01   5.941E+03   2.596E+01   2.019E+00   4.573E-01   9.163E-02
      reads, line, y, doy, hh, mm, ss, elec0, elec1, proton0, proton1, proton2, proton3, proton4

      t_struct = time_struct(0D)
      t_struct.year = y
      t_struct.doy = doy
      t_struct.hour = hh
      t_struct.min = mm
      t_struct.sec = ss
      doy_to_month_date, y, doy, month, date
      t_struct.month = month
      t_struct.date = date
      time_unix = time_double(t_struct)

      ; Add struct components:
      epam_struct_i.time = time_unix
      epam_struct_i.time_unix = time_unix
      ; convert the flux from particles/cm2-s-ster-MeV --> particles/cm2-s-ster-keV
      ; which is the common unit for SEP fluxes from MAVEN SEP or SWFO/STIS
      epam_struct_i.elec_flux = [elec0, elec1] * 1e-3
      epam_struct_i.proton_flux = [proton0, proton1, proton2, proton3, proton4] * 1e-3
      epam_struct_i.quicklook = 1B

      epam_struct[index] = epam_struct_i

  endfor
  free_lun, lun

end


pro ace_rtsw_tplot, data_struct, instrument, prefix=prefix

  if ~keyword_set(prefix) then prefix = 'ace'
  prefix = prefix + '_' + instrument + '_'

  ; Parameters for a spectra plot with a logarithmic y and z axes
  ; with a spec range of 10^-2 to 10^3 and y range of 10-600 keV
  dl = {spec: 1, ylog: 1, zrange: [1e-2, 1e3], zlog: 1}
  l = {ystyle: 1, ylog: 1, yrange: [10, 6000]}
  time = data_struct.time_unix

  xyz_dl = {labflag: -1, labels:['Bx','By','Bz'],colors:'bgr'}

  if instrument.startswith('epam') then begin
    store_data, prefix + 'elec_status', $
        data={x: time, y: data_struct.elec_status}, dl={psym: 2}
    store_data, prefix + 'elec_flux', $
        data={x: time, v: transpose(data_struct.elec_energy),$
              y: transpose(data_struct.elec_flux)}, dl=dl, limits=l
    store_data, prefix + 'proton_status', $
        data={x: time, y: data_struct.proton_status}, dl={psym: 2}
    store_data, prefix + 'proton_flux', $
        data={x: time, v: transpose(data_struct.proton_energy),$
              y: transpose(data_struct.proton_flux)}, dl=dl, limits=l
  endif else if instrument.startswith('swepam') then begin
    store_data, prefix + 'status', data={x: time, y: data_struct.status}, dl={psym: 2}
    store_data, prefix + 'proton_density', $
        data={x: time, y: data_struct.proton_density}, dl={ylog: 1}
    store_data, prefix + 'bulk_velocity', $
        data={x: time, y: data_struct.bulk_velocity}, dl={ylim: [0, 1000]}
    store_data, prefix + 'ion_temperature', $
        data={x: time, y: data_struct.ion_temperature_K}

  endif else if instrument.startswith('mag') then begin

    store_data, prefix + 'status', data={x: time, y: data_struct.status}, dl={psym: 2}
    store_data, prefix + 'B', $
        data={x: time, y: transpose(data_struct.vec)}, dl=xyz_dl
    store_data, prefix + 'Btot', data={x: time, y: data_struct.total}
    store_data, prefix + 'latitude', data={x: time, y: data_struct.lat}
    store_data, prefix + 'longitude', data={x: time, y: data_struct.long}

  endif else if instrument.startswith('sis') then begin

    store_data, prefix + '>10MeV_status', data={x: time, y: data_struct.proton_over_10MeV_status}, dl={psym: 2}
    store_data, prefix + '>10MeV_pflux', data={x: time, y: data_struct.proton_over_10MeV_flux}
    store_data, prefix + '>30MeV_status', data={x: time, y: data_struct.proton_over_30MeV_status}, dl={psym: 2}
    store_data, prefix + '>30MeV_pflux', data={x: time, y: data_struct.proton_over_30MeV_flux}

  endif

end


pro ace_load, download=download, tplot=tplot, quicklook=quicklook,$
   trange=trange, cadence=cadence, ext=ext

  instruments = ['mag', 'sis', 'epam', 'swepam']
  cadence = ['1m', '5m', '5m', '1m']

  for i=0, n_elements(instruments) - 1 do begin

    ; to be fixed for non epam:
    if keyword_set(quicklook) then begin
      ace_quicklook_read, epam_ql
      if keyword_set(tplot) then ace_epam_tplot, epam_ql, prefix='ace_ql_epam'
    endif

    ace_rtsw_load, instruments[i], struct_rtsw, trange=trange,$
      cadence=cadence[i], ext=ext, download=download

    if keyword_set(tplot) then ace_rtsw_tplot, struct_rtsw, instruments[i], prefix='ace_rtsw'

  endfor


end