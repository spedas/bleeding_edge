; The purpose of this routine is to make images of ultraviolet
; emission as seen by the EMM EMUS instrument, including in the form
; of tplot variables for convenient comparison with MAVEN in situ data

; AUTHOR: Robert Lillis (rlillis@Berkeley.edu). Please contact Rob for
; any questions. 

; PAPER AUTHORSHIP: Any MAVEN team members using this routine/data should
; offer coauthorship to:
;      Hessa Al Matroushi
;      Justin Deighan
;      Greg Holsclaw
;      Rob Lillis

; KEYWORDS:
;      MAVEN:  set this keyword to plot the orbit and ground track of
;      maven both during the observation but also for a time
;      (determined by the keyword 'buffer'" before and
;      after. NOTE: NOT WORKING YET

;      MEX: same as above, except for Mars Express. NOTE: NOT WORKING YET!

;      BUFFER: time before and after the image for which we want to
;      plot the trajectory of either MAVEN or MEX

;      SATELLITE: set this keyword so the image appears as it wld from
;      the perspective of the spacecraft.

;      HAMMER: set this keyword to use the hammer mapping projection

;      CYLINDRICAL: set this keyword to use a cylindrical
;      (i.e. rectangular) projection.

;      WV_RANGE: a 2xN-element array with the minimum and maximum
;      wavelength (nm) over which to integrate the emission, 
;      e.g. wv_range = [[97.5, 100.5], [129.0, 132.0], [134.5, 137.5]]

;      EMISSION: a string or N-element array of strings specifying which
;      specific emission feature to plot. Full list:
;          Ar I 104.8 singlet
;          Ar I 106.6 singlet
;          H I 102.6 singlet / O I 102.7 multiplet
;          O I 104.0 triplet
;          O I 115.2 singlet
;          CO (C-X) Hopfield-Birge bands
;          CO (B-X) Hopfield-Birge bands
;          C I 127.7 multiplet
;          C I 132.9 multiplet
;          C I 156.1 multiplet
;          C I 160.3 multiplet
;          C I 165.7 multiplet
;          C II 133.5 multiplet
;          C II 152.9 multiplet
;          H I 121.6 singlet
;          N I 120.0 triplet
;          N I 149.3 multiplet
;          O I 130.4 triplet (these are BRIGHTEST NIGHTSIDE AURORA)
;          O I 135.6 doublet
;          N2 (a-X) Lyman-Birge-Hopfield bands
;          CO 4PG Solar Fluorescent scattering
;          CO 4PG vv CO2 + e
;          CO 4PG vv0 CO2 + e
;          CO 4PG vv CO + e
;          CO 4PG vv0 CO + e
;          CO 4PG Si IV 1394
;          CO 4PG C IV 1548
;          CO 4PG O I 1304
;          CO 4PG H I 1216


;      COLOR_TABLE: N-element integer array specifying which color
;      tables are desired for which bands

;      BRIGHTNESS_RANGE: 2xN-element float array specifying the minimum
;      and maximum  brightness (Rayleighs) of the color bar.

;      ZLOG: N-element byte array where 0 means a linear brightness
;      scale and 1 means log brightness scale

;      OUTPUT_FILE: the name of a IDL .sav file containing 'DISK'
;      structure listed below as an output keyword

;      OUTPUT_DIRECTORY: a string containing the name of a local
;      directory where all JPEG's and the output file will be placed

;      JPEG: if this keyword is set, then JPEG's are saved for
;      all of the images.
;
;      PLOT: this is an array of indices, for which of the specified
;      emissions or wavelength ranges you wish to be plotted.

;      DLAT_OUTPUT = resolution of geographic map of brightness
;      
;      LOCAL_PATH:  Directory where files are kept. Note this directory
;      must have the same structure as the file source kept on
;      AWS:
;      https://mdhkq4bfae.execute-api.eu-west-1.amazonaws.com/prod/science-files-metadata?"
;      NOTE: The default will work fine for people working on the UC
;      Berkeley SSL network. A similar copy of the directory exists at
;      LASP.

;      AWS Questions: please direct all data repository/AWS questions
;      to Timothy Plummer (Timothy.plummer@LASP.Colorado.edu)
;      
; OUTPUT KEYWORDS:

;      DISK: a 3xM-element array of structures containing all the relevant
;      information for the wavelength ranges or emissions requested
;      during the time range. 3 is the maximum number of swaths per
;      observation set and M is the number observation sets within the
;      time range

; the keywords for MAVEN and Mars Express are for when we want to
; record the locations of MAVEN and Mars Express during the
; integration time of the image

; the satellite, cylindrical, and hammer keywords refer to the projections

pro emm_emus_examine_disk, time_range, MAVEN = MAVEN, MEX = MEX, $
                           satellite = satellite, hammer = hammer, $
                           cylindrical = cylindrical, $
                           wv_range = wv_range, emission = emission, $
                           local_path = local_path, color_table = color_table, $
                           brightness_range = brightness_range, zlog =zlog, $
                           output_file = output_file, $
                           output_directory = output_directory, $
                           disk = disk, buffer = buffer, jpeg = jpeg, $
                           dlat_output = dlat_output, l3 = l3, l2b =l2b,$
                           roi = roi, save = save, record_by_hand = record_by_hand, $
                           mode = mode, plot = plot, binning_int = binning_int,$
                           binning_pix = binning_pix



  if keyword_set (wv_range) and keyword_set (emission) then message, $
     'must choose either wavelength ranges or emission features, NOT BOTH'

  if not keyword_set (color_table) then color_table = [1, 2, 8]

  if n_elements (color_table) lt n_elements (emission) then message, $
     'Color_table must have at least as many elements as emission'

  if not keyword_set (dlat_output) then dlat_output = 1.0
  nelon_map = round (360.0/dlat_output)
  nlat_map = round (180.0/dlat_output)

  If not keyword_set (brightness_range) then   brightness_range = $
     [[5, 50], [2, 20], [0, 500]]
  if not keyword_set (zlog) then zlog = [1, 1, 0]

  If not keyword_set (output_directory) and keyword_set (jpeg) then message,  $
     'Must define output directory to save JPEGS to'
  
  if keyword_set (l3) eq 0 and keyword_set (l2b) eq 0 then message, 'must set either l3 or l2b keyword'


; time before and after the image for which we want to plot the
; trajectory of MAVEN or MARS EXPRESS.
; THIS FEATURE DOESN'T WORK YET!!
  If not keyword_set (buffer) then buffer = 3600

; Need to define the wavelength array to interpolate each to
  dwv = 0.5                     ; nanometers
  Wavelength_min = 82.5
  wavelength_max = 201.5
  nwv= round (wavelength_max - wavelength_min)/dwv
  wavelength_array =  wavelength_min +dwv*findgen (nwv)

; number of emissions to study
  if keyword_set (emission) then nb = n_elements (emission) else nb = $
     n_elements (wv_range [0,*])
  
; make a string representing each emission or wavelength range
  if keyword_set (emission) then bands = emission else begin
     bands = strarr (nb)
     for k = 0, nb-1 do bands [k] = $
        roundst (wv_range [0, k],dec = -1) + ' to ' + $
        roundst (wv_range [1, k],dec = -1) + ' nm'
  endelse
  
; NOTE: the path below will work for anyone working on the SSL
; network. Others will need to clone the AWS directory mentioned the
; commented section above the code. A copy of this directory exists at LASP
  if not keyword_set (local_path) then local_path = '/disks/hope/data/emm/data/'
  
; retrieve the file names from the requested time range, as well as
; the indices for each image set within the returned array of
; filenames, for each of the three kinds of disc scans

  if keyword_set (l2b) then level = 'l2b'
  if keyword_set (l3) then level = 'l3disk'

;  if not keyword_set (mode)

  os2 = emm_file_retrieve (time_range,level = level, mode = 'os2', local_path = $
                           local_path)
;  print, 'OS2 complete'
  os1 = emm_file_retrieve (time_range,level = level, mode = 'os1', local_path = $
                           local_path)
                                ; print, 'OS1 complete'
  osr = emm_file_retrieve (time_range,level = level, mode = 'osr', local_path = $
                           local_path)
  osp = emm_file_retrieve (time_range,level = level, mode = 'osp', local_path = $
                           local_path)
                                ;print, 'OSr complete'
  staring = emm_file_retrieve (time_range,level = level, mode = 'EMU042', local_path = $
                           local_path)
  
; collate the three different kinds of scans together
  all_files = ''
  file_indices = replicate (-1, 3, 1)
  ;file = {indices: file_indices}
  ;temp = file; need this for once below
  times = ''
  UNIX_times = ''
  mode = ''

 
; NOTE: the order of the next three if statements matters!
; NOTE: ADD OSP!!!
  if size (os1,/type) eq 8 then begin
     all_files = [all_files,os1.directory +os1.files]
     nos1= n_elements (os1.times)
     file_indices = [[file_indices], [os1.file_indices]]
     times = [times, os1.times]
     UNIX_times = [UNIX_times, OS1.UNIX_times]
     mode = [mode, replicate ('os1',nos1)]
  endif else begin
     nos1 = 0
  endelse

  
  if size (os2,/type) eq 8 then begin
     nos2= n_elements (os2.times)
     all_files = [all_files,os2.directory +os2.files]
                                ; to make sure the file_indices arrays are correct
     add = Max (file_indices) +1
; elements of the OS2 file_indices that are already -1 should stay
; that way. So define a temporary file_indices array
     tmp_file_indices = OS2.file_indices
     Good = where (tmp_file_indices ge 0)
     TMP_file_indices [good] += add
     ;file = [file, replicate (temp, nos2)]
    ; file [1+nos1:*].indices = TMP_file_indices
     file_indices = [[file_indices],[TMP_file_indices]]
     times = [times, os2.times]
     UNIX_times = [UNIX_times, OS2.UNIX_times]
     mode = [mode, replicate ('os2',nos2)]
  endif

  if size (osr,/type) eq 8 then begin
     nosr= n_elements (osr.times)
     all_files = [all_files,osr.directory +osr.files]
     add  = max (file_indices) +1
; do the same for OSR as we did above for OS2
     tmp_file_indices = OSr.file_indices
     Good = where (tmp_file_indices ge 0)
     TMP_file_indices [good] += add
     file_indices = [[file_indices],[TMP_file_indices]]
     times = [times, osr.times]
     UNIX_times = [UNIX_times, OSr.UNIX_times]
     mode = [mode, replicate ('osr',nosr)]
  endif
  
  If size (staring,/type) eq 8 then begin
; NOTE: for now, let's not include the staring observations
 ; if 3 eq 5 then begin
     nstaring= n_elements (staring.times)
     all_files = [all_files,staring.directory +staring.files]
     add  = max (file_indices) +1
; do the same for STARING as we did above for OS2
     tmp_file_indices = Staring.file_indices
     Good = where (tmp_file_indices ge 0)
     TMP_file_indices [good] += add
     file_indices = [[file_indices],[TMP_file_indices]]
     times = [times, staring.times]
     UNIX_times = [UNIX_times, Staring.UNIX_times]
     mode = [mode, replicate ('staring',nstaring)]
  endif

  
  If size (osp,/type) eq 8 then begin
; NOTE: for now, let's not include the osp observations
 ; if 3 eq 5 then begin
     nosp= n_elements (osp.times)
     all_files = [all_files,osp.directory +osp.files]
     add  = max (file_indices) +1
; do the same for OSP as we did above for OS2
     tmp_file_indices = Osp.file_indices
     Good = where (tmp_file_indices ge 0)
     TMP_file_indices [good] += add
     file_indices = [[file_indices],[TMP_file_indices]]
     times = [times, osp.times]
     UNIX_times = [UNIX_times, Osp.UNIX_times]
     mode = [mode, replicate ('osp',nosp)]
  endif

  if n_elements (all_files) eq 1 then begin
     print, 'No valid files for this time range!'
     return
  endif

  
; get rid of the first dummy element of the files array
  all_files = all_files [1:*]
  file_indices = file_indices [*, 1:*]
  set_count = n_elements (file_indices [0,*])
  mode = mode[1:*]
  times = times[1:*]
  UNIX_times = UNIX_times [1:*]

; Need to make sure file_indices has two dimensions
  ndim = size (file_indices,/n_dimension)
  If ndim eq 1 then file_indices = reform (file_indices, 3, 1)
; keep track of every pixel separately
;# of photon integrations as slit moves across the disk
  nint_Max = 260              
; number of pixels along the slit. Usually 128, sometimes 192
  NPIX_Max = 192              
; maximum number of swaths across the disc within one observation sequence
  max_swaths = 3
; middle plus the four corners of the pixel
  nc = 5                        

; define a structure, one element for each swath
  disk = {files: '', $
          date_String: '', $
          mode: '', $
          time:dblarr (nint_max)*sqrt (-7.2), $
          bmag:fltarr (nint_max, npix_max)*sqrt (-7.2), $
          br:fltarr (nint_max, npix_max)*sqrt (-7.2), $
          belev:fltarr (nint_max, npix_max)*sqrt (-7.2), $ 
          local_time:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
          mrh:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $ ,$
          sza:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
          ea:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
          pa:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
          latss:fltarr (nint_max)*sqrt (-7.2), $
          elonss:fltarr (nint_max)*sqrt (-7.2), $
          elon:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
          lat:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
          bands:bands,$
          Rad:fltarr (nint_max, npix_max, nb)*sqrt (-7.2), $
          drad_rand:fltarr (nint_max, npix_max, nb)*sqrt (-7.2), $; random error
          drad:fltarr (nint_max, npix_max, nb)*sqrt (-7.2), $; total error
          sc_alt:fltarr (nint_max)*sqrt (-7.2), $
          SC_pos: fltarr(3, nint_max)*sqrt (-7.2), $ ; MSO
          elon_ssc:fltarr (nint_max)*sqrt (-7.2), $
          lat_ssc:fltarr (nint_max)*sqrt (-7.2), $
          lat_MSO_look:fltarr (nint_max, npix_max, nc)*sqrt (-7.2), $
          elon_MSO_look:fltarr (nint_max, npix_max, nc)*sqrt (-7.2),$
          MAVEN_pos_Geo: fltarr(3,nint_max)*sqrt (-7.2), $
          MEX_pos_GeO: fltarr(3,nint_max)*sqrt (-7.2), $
          MAVEN_pos_MSO: fltarr(3,nint_max)*sqrt (-7.2), $
          MEX_pos_MSO: fltarr(3,nint_max)*sqrt (-7.2), $
          maplon:0.5*dlat_output + dlat_output*findgen (nelon_map), $
          maplat:-90.0+ 0.5*dlat_output + dlat_output*findgen (nlat_map), $
          brightness_map: FLTarr (nb,nelon_map, nlat_map)}

  if keyword_set (roi) then begin
; maximum number of regions of interest
     nroi= 5
; Max number of pixels in each ROI
     max_pixels_roi = 10000L
     brightness_roi = fltarr (nb, nroi, max_pixels_ROI)*sqrt (-7.2)
     disk = create_struct (disk, 'roi', brightness_ROI)
  endif

; if examining level 3 products, then add those
  if keyword_set (l3) then begin
     nsp= 2                     ; O and CO retrievals
     column_density = fltarr (nint_max, npix_max, nsp)*sqrt (-7.2)
     Disk = create_struct (disk, 'colden_string',  ['O_CO2', 'CO_CO2'],'colden',column_density)
  endif

; add tags for the average brightness in map form
  
  disk = replicate (Disk, set_count, max_swaths)

; load up crustal magnetic field model from Langlais [2019]
;  Langlais_file = '/home/rlillis/work/data/spherical_harmonic_models/Langlais2018/Langlais2018_150km_0.25deg.sav'
;  restore, Langlais_file
;  nelon_Langlais = n_elements (Langlais.Elon)
;  nlat_Langlais = n_elements (Langlais.lat)
  
; NOTE: this link will need to be updated for anyone outside SSL network.
  restore,'/home/rlillis/work/data/spherical_harmonic_models/Morschhauser_spc_dlat0.5_delon0.5_dalt10.sav'
  Altitude = 300.0              ; kilometers to plot the crustal field
  altitude_index = value_locate (Morschhauser.altitude, altitude)
  bradius = reform (Morschhauser.b[0, altitude_index,*,*])
  btheta = reform (Morschhauser.b[1, altitude_index,*,*])
  bphi = reform (Morschhauser.b[2, altitude_index,*,*])
  nelon_Morschhauser = n_elements (Morschhauser.longitude)
  nlat_Morschhauser = n_elements (Morschhauser.latitude)

  If not keyword_set (output_file) then begin
     Print, 'Output_file keyword not set. Disk information will not be saved.'
  endif
                                ;Disk_file = '~/work/emm/emus/data/aurora_' + $
                                ;              time_string (time_range [0], tformat = 'YYYY-MM-DD') + '_to_' + $
                                ;              time_string (time_range [1], tformat = 'YYYY-MM-DD') + '.sav'
                                ;if file_test (aurora_file) then goto, here

  
  
  if keyword_set (MAVEN) or keyword_set (MEX) then begin
     dt= 10.0                   ; seconds
     time_range = time_double (time_range)
     t_total = time_double (time_range [1]) - time_double (time_range [0])
     nt = round (T_total/dt)
     time_range [1] = time_range [0] + dt*nt
     Times = array (time_range [0], time_range [1],nt)

     et = time_ephemeris(times)
     
; load up MAVEN position for this entire time
     if keyword_set (maven) then begin
        maven_kernels = mvn_spice_kernels(trange = time_range,/load, $
                                          ['STD','SCK','FRM','IK','SPK']) 
        
        objects = ['MAVEN_SC_BUS','MAVEN', 'MARS']
        time_valid = spice_valid_times(et,object=objects) 
        printdat,check_objects,time_valid
        ind = where(time_valid ne 0,nind)
        if ind[0] eq -1 then begin
           print, 'SPICE kernels are missing for all the requested times.'
           return
        endif 
        
        MAVEN_position_GEO = spice_body_pos('MAVEN','MARS',utc=times,$
                                            et=et,frame='IAU_MARS',check_objects='MAVEN')
        MAVEN_position_MSO = spice_body_pos('MAVEN','MARS',utc=times,$
                                            et=et,frame='MAVEN_MSO',check_objects='MAVEN')

        cart2latlong, MAVEN_position_Geo [0,*], MAVEN_position_Geo [1,*], $
                      MAVEN_position_Geo [2,*], r_MAVEN,lat_MAVEN, elon_MAVEN
     endif

     if keyword_set (mex) then begin
        mex_kernels = mex_spice_kernels(trange = time_range,/load, $
                                        ['SCK','FRM','IK','SPK']) 
        
        MEX_position_GEO = spice_body_pos('MARS EXPRESS','MARS',utc=times,$
                                          et=et,frame='IAU_MARS',check_objects='MARS EXPRESS')
        MEX_position_MSO = spice_body_pos('MARS EXPRESS','MARS',utc=times,$
                                          et=et,frame='MAVEN_MSO',check_objects='MARS EXPRESS')

        cart2latlong, MEX_position_Geo [0,*], MEX_position_Geo [1,*], $
                      MEX_position_Geo [2,*], r_MEX,lat_MEX, elon_MEX
     endif
  endif

; we want to look at these in time order
  
  order = sort (UNIX_times[file_indices[0,*]])
  file_indices = file_indices [*, order]


; Need to make sure file_indices has two dimensions
  ndim = size (file_indices,/n_dimension)
  If ndim eq 1 then file_indices = reform (file_indices, 3, 1)

  
  for p = 0, set_count-1 do begin
; because -1 is used for times when there is no second or third swath
     n_swath = 3;n_elements (where (file_indices [*, p] ge 0))
     for l = 0,n_swath-1 do begin
        if file_indices [l,p] eq -1 then continue
        if not file_test (all_files [file_indices [l, p]]) then continue
        Disk [p, l].files= all_files [file_indices [l, p]]
        Disk [p, l].date_string = times [file_indices [l, p]]
        disk [p, l].mode = mode [file_indices [l, p]]
        print, times [file_indices [l, p]]
     endfor
  endfor
  
  
; loop through each of the observation sets
  for p = 0, set_count-1 do begin
     Print, p
     !p.charsize = 2.5
     n_swath = 3;n_elements (where (file_indices [*, p] ge 0))
     for l = 0,n_swath-1 do begin
        print, l
        if file_indices [l,p] eq -1 then continue
        
        if not file_test (all_files [file_indices [l, p]]) then continue
        Disk [p, l].files= all_files [file_indices [l, p]]
        Disk [p, l].date_string = times [file_indices [l, p]]
        
        print, times [file_indices [l, p]]
                                ;Data = iuvs_read_fits (all_files
                                ;[file_indices[l,p]])
        
                                ;fits_read, all_files [file_indices[l,p]], data,header,group_par
        FOV_geom = mrdfits(all_files [file_indices[l,p]],'FOV_GEOM')
        SC_geom = mrdfits(all_files [file_indices[l,p]],'SC_GEOM')
        tim = mrdfits(all_files [file_indices[l,p]],'TIME')
        emiss = mrdfits (all_files [file_indices [l,p]], 'EMISS')
        if keyword_set (emission) then begin
           emission_indices = intarr (nb)
           for k = 0, nb-1 do begin
              emission_indices [k] = where (emiss.name eq emission [k])
              if emission_indices [k] eq -1 then message, 'Emission keyword must consist of a string or string array from the list of emissions shown in the comments at the top of this routine source code.'
           Endfor
        endif
        wv = mrdfits(all_files [file_indices[l,p]],'WAVELENGTH')
        nw = n_elements (wv.wavelength_l2a [*, 0])
        cal = mrdfits(all_files [file_indices[l,p]],'CAL')
        
        
; in case you want to do binning.  If the binning keywords are not
; specified, then there is no binning     
        
        emm_emus_binning, FOV_geom, SC_geom, tim, emiss, cal, FOV_binned, SC_binned, Tim_binned, emiss_binned, cal_binned,$
                       binning_int = binning_int, binning_pix = binning_pix
        fov_geom = fov_binned
        sc_geom = SC_binned
        tim = tim_binned
        emiss = emiss_binned
        cal= cal_binned
  

        if keyword_set (l3) then cd = mrdfits (all_files [file_indices [l,p]], 'COLUMN_DENSITY')
        print, all_files [file_indices [l, p]]
        
; instead of plotting with respect to RA and DEC, more intuitive to
; plot in terms of MSO coordinates
        cart2latlong, FOV_geom.VEC_MSO [*,*, 0], $
                      FOV_geom.VEC_MSO [*,*, 1],$
                      FOV_geom.VEC_MSO [*,*, 2],$
                      radius, MSO_lat, MSO_elon
        nint = n_elements (FOV_geom)                 ; number of integrations
        npix = n_elements (FOV_geom[0].ra [*, 0])    ; number of pixels
        print, p, l
        if nint eq 0 then begin
           
           print, 'No calibrated data for this swath'
           continue
        endif
        
        
        
        disk [p, l].lat_MSO_look[0:nint -1,0:npix-1,*] = transpose (MSO_LAT, [2, 0, 1])
        disk [p, l].elon_MSO_look[0:nint -1,0:npix-1,*] = transpose (MSO_ELON, [2, 0, 1])
        
        

        disk [p, l].sc_ALT [0:nint -1] = sc_geom.sc_alt
        disk [p, l].elon_ssc [0:nint -1] = sc_geom.sub_sc_lon
        disk [p, l].lat_ssc [0:nint -1] = sc_geom.sub_sc_lat

        disk [p, l].Elonss [0:nint -1] = sc_geom.sub_solar_lon
        disk [p, l].latss [0:nint -1] = sc_geom.sub_solar_lat
        
        disk [p, l].sc_pos[*, 0:nint -1] =sc_geom.v_SC_POS_MSO
        
        disk [p, l].time[0:nint-1] = time_double (tim.time_UTC,$
                                                  tformat = 'YYYY-MM-DDThh:mm:ss.fff')
        
        disk [p, l].sza [0:nint-1,0:npix-1,*] = $
           transpose (reform (fov_geom.solar_z_angle), [2, 0, 1])
        
        disk [p, l].ea[0:nint-1,0:npix-1,*] = $
           transpose (reform (fov_geom.emission_angle), [2, 0, 1])
         disk [p, l].pa[0:nint-1,0:npix-1,*] = $
           transpose (reform (fov_geom.phase_angle), [2, 0, 1])
        
        disk [p, l].local_time[0:nint-1,0:npix-1] = $
           transpose(reform (fov_geom.local_time[*,0,*]))
        
        disk [p, l].lat[0:nint-1,0:npix-1,*] = $
           transpose (reform (fov_geom.lat), [2, 0, 1])
        disk [p, l].elon[0:nint-1,0:npix-1,*] = $
           transpose (reform (fov_geom.lon), [2, 0, 1])
        
        disk [p, l].mrh[0:nint-1,0:npix-1,*] = $
           transpose (reform (fov_geom.mrh_alt), [2, 0, 1])
        
        
; calculate MAVEN and Mars express positions
        if keyword_set (MAVEN) then begin
           for k=0, 2 do begin
              disk [p, l].MAVEN_POS_Geo [k,0:nint-1] = $
                 interpol (MAVEN_position_Geo[k,*], times, $
                           disk [p, l].time[0:nint-1],/nan,/spline)
              disk [p, l].MAVEN_POS_MSO [k,0:nint-1] = $
                 interpol (MAVEN_position_MSO[k,*], times, $
                           disk [p, l].time[0:nint-1],/nan,/spline)
           endfor
        endif
        if keyword_set (MEX) then begin
           for k = 0, 2 do begin
              disk [p, l].MEX_POS_Geo [k,0:nint-1] = $
                 interpol (MEX_position_Geo[k,*], times, $
                           disk [p, l].time[0:nint-1],/nan,/spline)
              disk [p, l].MEX_POS_MSO [k,0:nint-1] = $
                 interpol (MEX_position_MSO[k,*], times, $
                           disk [p, l].time[0:nint-1],/nan,/spline)
           endfor
        endif

; values of crustal magnetic field
        fractional_indices_longitude = $
           interpol (findgen (nelon_Morschhauser), $
                     Morschhauser.longitude,disk [p, l].elon[0:nint-1,0:npix-1,0])
        fractional_indices_latitude = $
           interpol (findgen (nlat_Morschhauser), $
                     Morschhauser.latitude,disk [p, l].lat[0: nint -1,0:npix -1,0])
        disk [p, l].br[0:nint-1,0:npix-1] = $
           interpolate(bradius, $
                       fractional_indices_longitude, fractional_indices_latitude)
        disk [p, l].bmag[0:nint-1,0:npix-1] = $
           interpolate(sqrt(bradius^2 + $
                            btheta^2 + $
                            bphi^2), $
                       fractional_indices_longitude, fractional_indices_latitude)
        disk [p, l].belev[0:nint-1,0:npix-1] = $
           interpolate(asin(bradius/sqrt(bradius^2 + btheta^2 + bphi^2))/!dtor, $
                       fractional_indices_longitude, fractional_indices_latitude)
        
        band_radiance = fltarr (nint, npix_max,nb) 
        
; if you want to examine a single fitted emission feature(s)
        if keyword_set (emission) then begin
           for j = 0, nint-1 do begin 
              for K = 0, nb-1 do begin 
                 disk [p, l].rad [j,0:npix -1, k] = emiss[emission_indices [k]].radiance[j,*]
              endfor
           endfor
           
; if you don't want to examine an emission feature, define a set of wavelengths
        endif else begin
           for j = 0, nint-1 do begin 
              for i = 0, npix-1 do begin 
; find the wavelength indices
                 wv_indices = value_locate (wv.wavelength_L2A[*,i], WV_range)
                 for K = 0, nb-1 do begin       
                    rad_rand =  emm_int_simple (wv.wavelength_l2a[wv_indices [0, k]+1: wv_indices [1, k], i], $
                                   cal[j].radiance [wv_indices [0, k]+1: wv_indices [1, k],i], $
                                   df = cal[j].rad_err_rand[wv_indices [0, k]+1: wv_indices [1, k],i], $
                                   error = error)   
                     
                    disk [p, l].drad_rand [j,i, k] = error
                    disk [p, l].rad[j,i, k] = rad_rand
                    band_radiance [j, i,k] = $
                       emm_int_simple (wv.wavelength_l2a [wv_indices [0, k]+1: wv_indices [1, k], i], $
                                   cal[j].radiance [wv_indices [0, k]+1: wv_indices [1, k],i], $
                                   df = sqrt(cal[j].rad_err_rand[wv_indices [0, k]+1: wv_indices [1, k],i]^2 + $
                                             cal[j].rad_err_sys[wv_indices [0, k]+1: wv_indices [1, k],i]^2), $
                                   error = error)      
                   
                    disk [p, l].drad [j,i, k] = error
                 endfor
               ;  if band_radiance [J, i, 3] gt 5.0 then stop
; some diagnostic plots              
                 if 5 eq 3 then begin 
                    Print, i, j, rad_Cal [ p, l, j, i, 1]
                    plot, wv.wavelength_l2A, cal [j].radiance [*, i], $
                          xtitle = 'wavelength, nm', ytitle = 'radiance, R/nm',$
                          /ylog,  yrange = [1e-2, 1e4]
                    oplot, wavelength_array, radiance [i, j,*], color = 2  
                 endif  
              endfor
           endfor
        endelse
; assign the level III retrieved quantities
        if keyword_set (l3) then begin
           O_index = where (CD.id eq 'O/CO2')
           CO_index = where (CD.id eq 'CO/CO2')
           for j = 0, nint-1 do begin
              disk [p, l].colden [j,0: npix -1, 0] = CD [O_index].value[j,*]
              disk [p, l].colden [j,0: npix -1, 1] = CD [CO_index].value[j,*]
           endfor
        endif


; more diagnostic plots in case you want to see just the raw pixel locations     
        if 5 eq 3 then begin
          band_index = 1
           loadct2, 8
           scatter_specplot,disk[p, l].elon_MSO_look[0: nint -1,*, 0], $
                            disk[p, l].lat_MSO_look[0: nint -1,*, 0], $
                            disk[p, l].rad_cal [0: nint -1,*, Band_index],$
                            xtitle= 'MSO longitude, Degrees', $
                            ytitle= 'MSO latitude, Degrees', $
                            ztitle= 'Rayleighs', psy= 6,symsize = 0.27,thick=2, $      
                            xr = xr,title = bands [band_index],$
                            /iso, zr =[0.1, 300],/zlog, $
                            yr = yr,/ystyle,/Xstyle, zstyle = 1
         scatter_specmap,disk [p, l].elon [0: nint -1,*, 0], $
                           disk [p, l].lat [0: nint -1,*, 0], $
                           disk[p, l].rad_cal [0: nint -1,*, Band_index],$
                           zrange = [2, 20],/iso
        endif

        
; pixel zero of the detector is outside of our slits so it should
; always be put to zero
        Disk [p, l].rad [j, 0,*] = 0.0 ;
        obs_string = times[file_indices [l,p]] +' Sw '+string(l, format = '(I1)')+ ' '
        
     endfor
     
; OKAY, NOW WE HAVE ISOLATED THE EMISSIONS WE WANT.
; NOW TIME TO MAKE IMAGES     
                                ;emus_map_disk_maven_orbit,Disk [p, *], bands_wanted = [1], radiance_range = $
                                ;                          [[2.0, 50.0], [0, 10.0]],zlog=1, Color_Table = [8, 3], $
                                ;                          mode = mode[file_indices [*,p]], $
                                ;                          MAVEN = MAVEN, MEX = MEX

; we want to make a gridded geographic map regardless. NOTE: need to
; use the JPEG keyword if you want to make JPEG's
     
     if keyword_set (plot) then emm_emu_map_disk, Disk [p, *], bands_wanted = plot, zrange = $
        brightness_range,zlog=zlog, $
        Color_Table = color_table, /no_crustal,$
        mode = mode[file_indices [*,p]],/cylindrical, $
        nxmap = nelon_map,nymap = nlat_map, $
        mean_brightness_map = mean_brightness_map, $
        stitched_brightness_map = stitched_brightness_map
    
; look at regions of interest
     ;stop
     
     ;image = bytscl(reform (alog10 (mean_brightness_map [0,*,*, 0])),/nan, $
     ;              min = 0, max = 2)
     ;xroi, Image, statistics = roi
     
     
     for l = 0,n_swath-1 do begin & $
        if file_indices [l, p] eq -1 or keyword_set (plot) eq 0 then continue & $
        Disk [p, l].brightness_map = reform (mean_brightness_map[*,*,*, l]) & $
     endfor
     
    ; specplot, disk [p, 0].maplon, disk [p, 0].maplat, reform (disk [p, 0].brightness_map[0,*,*])

; If you additionally want to make perspective maps with the hammer or
; satellite projections
     
     If keyword_set (hammer) or keyword_set (satellite)  then begin
        emm_emu_map_disk, Disk [p, *], bands_wanted = plot, zrange = $
                          brightness_range,zlog=zlog, $
                          Color_Table = color_table, $
                          mode = mode[file_indices [*,p]], hammer = hammer, $
                          satellite = satellite, output_directory = output_directory, $
                          jpeg = jpeg
        
     endif
     
                                ;            bands [1] +'.jpeg'
                                ;if p mod 10 eq 0 then save, Disk, file = Disk_file
     if p eq set_count -1 and keyword_set (output_file) then begin
    
        save, disk, file =   output_file
     endif
  endfor

end

