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
; $LastChangedDate: 2025-10-27 22:44:19 -0700 (Mon, 27 Oct 2025) $
; $LastChangedRevision: 33799 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/ace_rtsw_epam_load.pro $

; Structure to contain EPAM information:
; - elec_energy: fixed
; - ion_energy
; # Units: Differential Flux particles/cm2-s-ster-MeV
; # Units: Anisotropy Index 0.0 - 2.0
; # Status(S): 0 = nominal, 4,6,7,8 = bad data, unable to process, 9 = no data
; # Missing data values: -1.00e+05, index = -1.00

function epam_struct_template

  ; Electron energy is fixed across all times for EPAM
  elec_energy_range = [[38.0, 53.0], [175.0, 315.0]]
  elec_denergy = reform(elec_energy_range[1, *] - elec_energy_range[0, *])
  elec_energy = reform(elec_energy_range[0, *]) + elec_denergy/2

  ; Ion energy is fixed across all times for EPAM
  proton_energy_range = [[47.0, 68.0], [115.0, 195.0], [310.0, 580.0], [795.0, 1193.0], [1060.0, 1900.0]]
  proton_denergy = reform(proton_energy_range[1, *] - proton_energy_range[0, *])
  proton_energy = reform(proton_energy_range[0, *]) + proton_denergy/2

  ; epam_struct, $
  epam_struct = {time:0d, $
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

  return,epam_struct

end

;
; Downloads and stores preliminary ACE data from the ACE Real time Solar Wind (RTSW)
; data archive on the ACE Science Center.
; Available instrument + cadences:
; - EPAM: 5 min, 1 hr
; - SWEPAM: 1 min, 1 hr
; - MAG: 1 min, 1 hr
; - SIS: 5 min, 1 hr
;

pro ace_rtsw_load, instrument, epam_struct, trange=trange, cadence=cadence, ext=ext, download=download


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
  n_skippedlines = 18
  epam_template = epam_struct_template()
  line = ''

  for i=0, nfiles - 1 do begin
    ; open EPAM file, count # lines and read
    file_i = files[i]
    openr, lun, file_i,/get_lun
    nlines = file_lines(file_i)
    nd = nlines - n_skippedlines

    epam_struct_i = replicate(epam_template, nd)

    for j=0, nlines - 1 do begin
      readf, lun, line
      if j lt n_skippedlines then continue
      reads, line, year, month, day, hhmm, julday, sec_day, elec_status, elec0, elec1,$
        proton_status, proton0, proton1, proton2, proton3, proton4, anis_index
      index = j - n_skippedlines

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
      epam_struct_j = epam_struct_i[index]
      epam_struct_j.time = time_unix
      epam_struct_j.time_unix = time_unix
      ; convert the flux from particles/cm2-s-ster-MeV --> particles/cm2-s-ster-keV
      ; which is the common unit for SEP fluxes from MAVEN SEP or SWFO/STIS
      epam_struct_j.elec_flux = [elec0, elec1] * 1e-3
      epam_struct_j.proton_flux = [proton0, proton1, proton2, proton3, proton4] * 1e-3

      ; Additional fields available in RTSW that are not in the quicklook:
      ; elec_status, proton_status, anisotropy, and RTSW bit:
      epam_struct_j.elec_status = elec_status
      epam_struct_j.proton_status = proton_status
      epam_struct_j.rtsw = 1B
      epam_struct_j.anisotropy = anis_index

      epam_struct_i[index] = epam_struct_j
    endfor
    free_lun, lun

    if i eq 0 then epam_struct = epam_struct_i else epam_struct = [epam_struct, epam_struct_i]


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

epam_struct = epam_struct_template()
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


pro ace_epam_tplot, epam_struct, prefix=prefix

  if ~keyword_set(prefix) then prefix = 'ace_epam'
  prefix = prefix + '_'

  ; Parameters for a spectra plot with a logarithmic y and z axes
  ; with a spec range of 10^-2 to 10^3 and y range of 10-600 keV
  dl = {spec: 1, ylog: 1, zrange: [1e-2, 1e3], zlog: 1}
  l = {ystyle: 1, ylog: 1, yrange: [10, 6000]}
  time = epam_struct.time_unix

  store_data, prefix + 'elec_status', $
      data={x: time, y: epam_struct.elec_status}, dl={psym: 2}
  store_data, prefix + 'elec_flux', $
      data={x: time, v: transpose(epam_struct.elec_energy),$
            y: transpose(epam_struct.elec_flux)}, dl=dl, limits=l
  store_data, prefix + 'proton_status', $
      data={x: time, y: epam_struct.proton_status}, dl={psym: 2}
  store_data, prefix + 'proton_flux', $
      data={x: time, v: transpose(epam_struct.proton_energy),$
            y: transpose(epam_struct.proton_flux)}, dl=dl, limits=l

end


pro ace_rtsw_epam_load, download=download, tplot=tplot, quicklook=quicklook,$
   trange=trange, cadence=cadence, ext=ext



  if keyword_set(quicklook) then begin
    ace_quicklook_read, epam_ql
    if keyword_set(tplot) then ace_epam_tplot, epam_ql, prefix='ace_ql_epam'
  endif

  ace_rtsw_load, 'epam', epam_rtsw, trange=trange, cadence=cadence, ext=ext, download=download
  if keyword_set(tplot) then ace_epam_tplot, epam_rtsw, prefix='ace_rtsw_epam'


end