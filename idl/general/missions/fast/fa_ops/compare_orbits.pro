;+
; PROCEDURE:      compare_orbits
;               
; PURPOSE:        Propagates multiple orbits.  Used to compare evolution
;                 of nearby orbits.
;               
; INPUTS:         Accepts any of three classes of input:
;
;                 DEFAULT           KEPLER               VECTOR
;                 -------           ------               ------
;                 apogee            semi-major axis        X
;                 perigee           eccentricity           Y
;                 inclination       inclination            Z
;                 ascending node    ascending node         VX
;                 arg of perigee    arg of perigee         VY
;                 mean anomaly      mean anomaly           VZ
;
;                 Input is received through ASCII files or interactive
;                 prompting.  See INPUT_FILES keyword. Set
;                 KEPLER_INPUT or VECTOR_INPUT to use a parameter set
;                 other than the default.  The only difference between
;                 the default and Keplerian sets is that apogee and
;                 perigee are traded for semi-major axis and
;                 eccentricity.
;
;                 Apogee and perigee are in kilometers relative to the
;                 Earth's surface.  Semi-major axis is in kilometers.
;                 Inclination, ascending node, argument of perigee,
;                 and mean anomaly are all in degrees.  Position and
;                 velocity are in Geocentric Equatorial Inertial (GEI)
;                 kilometers.
;
; OUTPUTS:        Files containing position and velocity vectors (in
;                 GEI km) over the requested timespan.  There will be
;                 one file for each orbit requested. See OUTPUT_FILES
;                 keyword.
;
;                 Also, unless the NO_STORE keyword is set, all
;                 quantities available from get_fa_orbit.pro will be
;                 stored in tplot structures with numbered suffixes
;                 appended to their names.  (This process must have
;                 permission to create files in the current
;                 directory.)
;
; ARGUMENTS:      
;
; (none)
;
;
; KEYWORDS:
;
; KEPLER_INPUT    Set this keyword if inputs are Keplerian orbit elements.
; VECTOR_INPUT    Set this keyword if inputs are position and velocity vectors.
; NO_STORE        Disables storage of tplot structures.
; NO_FILES        Disables writing of propagated vectors to ASCII files.
; DURATION        The orbits will be propagated DURATION seconds.
; DELTA_T         Spacing in seconds of computed orbit vectors (default=20s).
; REFERENCE       Set this to a string or double float time.  It will
;                 be used as the starting point for the propagation.
;                 Since time is arbitrary and has no bearing on the
;                 calculation, this keyword is optional and defaults
;                 to '2000-1-1/00:00:00.000'.
;
; OUTPUT_FILES    Set this to a scalar string to be used for constructing
;                 the names of the output files.  An index number will
;                 be appended to the name to designate which orbit the
;                 file corresponds to.  The default is 'propagation.n'
;
;                 The output files will contain a one-line header
;                 followed by rows containing the following fields:
;                 TIME     X     Y     Z     VX     VY     VZ
;                 (Position and velocity are in GEI km.)
;
; INPUT_FILES     Scalar string or string array.  Set this keyword to the
;                 names of files containing the input parameters.  The
;                 wildcard character `*' is acceptible.  There should
;                 be one file for each orbit to be propagated.  There
;                 are three possible file formats, described below.
;
;                 (If this keyword is unset, the user will be prompted
;                 interactively for the input parameters.)
;
;                 Default File Format:
;
;                 With the KEPLER_INPUT and VECTOR_INPUT keywords both
;                 unset, the input files should be similar to the
;                 following:
;
;                 ; Orbital elements
;                 Apogee: 4179.70
;                 Perigee: 352.270
;                 Inclination: 82.9672945710076
;                 Ascending Node: 178.334008234324
;                 Arg of Perigee: 161.781356303097
;                 Mean Anomaly: 207.607698658954
;                 
;                 CAUTION: It is the order of the entries that matters
;                 -- not the labels.  The labels are totally arbitrary
;                 and optional, included for the user's sake.  The
;                 colon delimits the label from the value.  Empty
;                 lines and those beginning with `;' are ignored.
;
;                 Apogee and perigee are in kilometers relative to
;                 Earth's surface.  Inclination, ascending node,
;                 argument of perigee, and mean anomaly are in
;                 degrees.
;
;                 Keplerian File Format:
;
;                 With the KEPLER_INPUT keyword set, the input files
;                 should be similar to this:
;
;                 ; Keplerian elements
;                 Semi-major axis: 8644.08502992716
;                 Eccentricity: 0.221390443436394
;                 Inclination: 82.9672945710076
;                 Ascending Node: 178.334008234324
;                 Arg of Perigee: 161.781356303097
;                 Mean Anomaly: 207.607698658954
;
;                 Vector File Format:
; 
;                 This file should contain two lines.  The first
;                 consists of the position vector elements delimited
;                 by whitespace, the second consists of the velocity
;                 vector elements.  Both vectors are in Geocentric
;                 Equatorial Inertial (GEI) kilometers.  Empty lines
;                 and those beginning with `;' are ignored.
;
;                 ; Initial position and velocity vectors
;                 -5507.04834742092  -3977.33940791809   1.16138517269934e-05
;                 0.998998200041123  -0.546989517973328  8.35870064323739
;
;-

pro compare_orbits, $
           KEPLER_INPUT=kin, $
           VECTOR_INPUT=vin, $
           DURATION=duration, $
           DELTA_T=delta_t, $
           REFERENCE=reference, $
           INPUT_FILES=input_files, $           
           OUTPUT_FILES=output_files, $
           NO_STORE=no_store, $
           NO_FILES=no_files

;; Check output options

if keyword_set(no_store) AND keyword_set(no_files) $
  then message, 'Setting NO_STORE and NO_FILES results in trivial calculation.'

if NOT keyword_set(output_files) then output_files='propagation'

;; Get input type: default, Kepler, or vector.
;; Simple conversions of one another, "default" and Kepler inputs follow
;; the same basic path.

if NOT keyword_set(kin) AND NOT keyword_set(vin) then begin
    default = 1
    kin = 1
endif else default = 0

;; Format reference time and duration

if keyword_set(reference) then begin
    if data_type(reference) EQ 7 then ref = str_to_time(reference) $
    else ref = reference
endif else ref = str_to_time('2000-1-1/00:00:00.000')

if keyword_set(duration) then duration = double(duration) $
  else message, 'Must set DURATION'

if keyword_set(delta_t) then delta_t = double(delta_t)

;; If no input files, query user for parameters.
;; Otherwise, read parameters from the input files.
;; The variable n_orbits will be set regardless of input method.

if n_elements(input_files) EQ 0 then begin
    n_orbits = 0
    read, prompt='Enter number of orbits to propagate: ', n_orbits
    if keyword_set(kin) then begin
        ;; Initialze the keplerian element arrays
        apogee = dblarr(n_orbits)
        perigee = dblarr(n_orbits)
        inc = dblarr(n_orbits)
        node = dblarr(n_orbits)
        aperigee = dblarr(n_orbits)
        manomaly = dblarr(n_orbits)
        ;; Fill the arrays with values
        for i=0, (n_orbits - 1) do begin
            print, 'Enter Keplerian elements for orbit ' + strtrim((i+1), 2)
            ;; Catch bad input
            catch, errstat
            if errstat NE 0 then begin
                print, !err_string
                print, 'Please re-enter values for this orbit'
            endif
            if keyword_set(default) then begin
                read, prompt='  Apogee (km): ', apogee_tmp
                read, prompt='  Perigee (km): ', perigee_tmp
            endif else begin
                read, prompt='  Semi-major axis (km): ', apogee_tmp
                read, prompt='  Eccentricity: ', perigee_tmp
            endelse
            read, prompt='  Inclination (deg): ', inc_tmp
            read, prompt='  Ascending Node (deg): ', node_tmp
            read, prompt='  Arg of Perigee (deg): ', aperigee_tmp
            read, prompt='  Mean Anomaly (deg): ', manomaly_tmp
            catch, /cancel
            apogee(i) = apogee_tmp
            perigee(i) = perigee_tmp
            inc(i) = inc_tmp
            node(i) = node_tmp
            aperigee(i) = aperigee_tmp
            manomaly(i) = manomaly_tmp
        endfor
    endif else if keyword_set(vin) then begin
        ;; Initialize vector arrays
        position = dblarr(3, n_orbits)
        velocity = dblarr(3, n_orbits)
        pos_tmp = dblarr(3)
        vel_tmp = dblarr(3)
        ;; Fill vector arrays with values
        for i=0, (n_orbits - 1) do begin
            print, 'Enter vector elements for orbit ' + strtrim((i+1), 2)
            ;; Catch bad input
            catch, errstat
            if errstat NE 0 then begin
                print, !err_string
                print, 'Please re-enter values for this orbit'
            endif
            read, prompt='  Position (GEI km): ', pos_tmp
            read, prompt='  Velocity (GEI km): ', vel_tmp
            catch, /cancel
            position(*,i) = pos_tmp
            velocity(*,i) = vel_tmp
        endfor
    endif
endif else begin
    ;; Make sure input files exist
    for f=0, (n_elements(input_files) - 1) do begin
        fnames_tmp = findfile(input_files(f), count=f_count)
        if f_count GT 0 then begin
            if f EQ 0 then found_files = fnames_tmp $
            else found_files = [found_files, fnames_tmp]
        endif else message, 'No files found for file spec: ' + input_files(f)
    endfor
    n_orbits = n_elements(found_files)
    print, 'Found ' + strtrim(n_orbits, 2) + ' input files'
    ;; Read the files
    if keyword_set(kin) then begin
        ;; Initialize Keplerian orbit element arrays
        apogee = dblarr(n_orbits)
        perigee = dblarr(n_orbits)
        inc = dblarr(n_orbits)
        node = dblarr(n_orbits)
        aperigee = dblarr(n_orbits)
        manomaly = dblarr(n_orbits)
        ;; Loop through each file
        for i=0, (n_orbits - 1) do begin
            print, 'Reading file: ' + found_files(i)
            openr, /get_lun, unit, found_files(i)
            qty_ind = 0
            while NOT eof(unit) do begin
                ;; Read and parse line
                line = ''
                readf, unit, line
                line = strcompress(line, /remove_all)
                char1 = strmid(line, 0, 1)
                ;; Ignore empty and commented lines
                if strlen(line) NE 0 AND char1 NE ';' then begin
                    fields = str_sep(line, ':')
                    n_fields = n_elements(fields)
                    value = double(fields(n_fields - 1))
                    ;; Assign the corresponding Keplerian element
                    case qty_ind of
                        0: apogee(i) = value
                        1: perigee(i) = value
                        2: inc(i) = value
                        3: node(i) = value
                        4: aperigee(i) = value
                        5: manomaly(i) = value
                        else: message, 'Too many lines in ' + found_files(i)
                    endcase
                    ;; Only increment if valid line
                    qty_ind = qty_ind + 1
                endif
            endwhile
            ;; Close file and make sure all elements received a value
            free_lun, unit
            if qty_ind NE 6 then message, 'Too few lines in ' + found_files(i)
        endfor
    endif else if keyword_set(vin) then begin
        position = dblarr(3, n_orbits)
        velocity = dblarr(3, n_orbits)
        pos_tmp = dblarr(3)
        vel_tmp = dblarr(3)
        ;; Loop through each file
        for i=0, (n_orbits - 1) do begin
            print, 'Reading file: ' + found_files(i)
            openr, /get_lun, unit, found_files(i)
            qty_ind = 0
            while NOT eof(unit) do begin
                ;; Read line
                line = ''
                readf, unit, line
                compressed_line = strcompress(line, /remove_all)
                char1 = strmid(compressed_line, 0, 1)
                ;; Ignore empty and commented lines
                if strlen(compressed_line) NE 0 AND char1 NE ';' then begin
                    if qty_ind EQ 0 then begin
                        reads, line, pos_tmp
                        position(*,i) = pos_tmp
                    endif else if qty_ind EQ 1 then begin
                        reads, line, vel_tmp
                        velocity(*,i) = vel_tmp
                    endif else message, 'Too many lines in ' + found_files(i)
                    ;; Only increment if valid line
                    qty_ind = qty_ind + 1
                endif
            endwhile
            ;; Close file and make sure all elements received a value
            free_lun, unit
            if qty_ind NE 2 then message, 'Too few lines in ' + found_files(i)
        endfor
    endif
endelse

;; Display all assigned values

if keyword_set(kin) then begin
    if keyword_set(default) then begin
        orb_elem1_tag = 'APOGEES: '
        orb_elem2_tag = 'PERIGEES: '
    endif else begin
        orb_elem1_tag = 'SEMI-MAJOR AXES: '
        orb_elem2_tag = 'ECCENTRICITIES: '
    endelse
    print, orb_elem1_tag, apogee, $
      format='(A20, '+strtrim(n_elements(apogee),2)+'(F))'
    print, orb_elem2_tag, perigee, $
      format='(A20, '+strtrim(n_elements(perigee),2)+'(F))'
    print, 'INCLINATIONS: ', inc, $
      format='(A20, '+strtrim(n_elements(inc),2)+'(F))'
    print, 'ASC NODES: ', node, $
      format='(A20, '+strtrim(n_elements(node),2)+'(F))'
    print, 'ARGS of PERIGEE: ', aperigee, $
      format='(A20, '+strtrim(n_elements(aperigee),2)+'(F))'
    print, 'MEAN ANOMALIES: ', manomaly, $
      format='(A20, '+strtrim(n_elements(manomaly),2)+'(F))'
endif else if keyword_set(vin) then begin
    print, position, format='("POSITIONS: ",/, 3(F))'
    print, velocity, format='("VELOCITIES: ",/, 3(F))'
endif

;; Now that all input has been assigned,
;; write an orbit file and propagate the orbits

for i=0, (n_orbits - 1) do begin
    
    ;; Depending on the type of input, write an orbit file for input
    ;; to get_fa_orbit.pro
    
    suffix = '.' + (str_sep(strtrim(randomu(seed),2), '.'))(1)
    orbit_file = 'orb_tmp' + suffix
    
    if keyword_set(kin) then begin
        
        ;; Collect orbit file header elements
        
        date_doy_sec, ref, year, doy, sec
        time = (str_sep(time_to_str(ref, /msec), '/'))(1)
        hdr_ver = '1.2'
        hdr_sat = 'FAST'
        hdr_year = strtrim(year, 2)
        hdr_doy = strtrim(doy, 2)
        hdr_time = time
        hdr_epoch = hdr_year + ' ' + hdr_doy + ' ' + hdr_time
        hdr_orb = '1'
        ;; If default unset, then apogee and perigee are actually axis
        ;; and eccentricity.  Otherwise, do the conversion.
        if keyword_set(default) then begin
            Re = 6378.1d
            hdr_axis = strtrim(0.5d*(apogee(i) + perigee(i) + 2*Re), 2)
            hdr_ecc = strtrim((apogee(i) - perigee(i)) / $
                              (apogee(i) + perigee(i) + 2*Re), 2)
        endif else begin
            hdr_axis = strtrim(apogee(i), 2)
            hdr_ecc = strtrim(perigee(i), 2)
        endelse
        hdr_inc = strtrim(inc(i), 2)
        hdr_node = strtrim(node(i), 2)
        hdr_aperigee = strtrim(aperigee(i), 2)
        hdr_manomaly = strtrim(manomaly(i), 2)
        
        ;; Write the orbit file
        
        openw, orbfile_lun, /get_lun, orbit_file
        printf, orbfile_lun, hdr_ver, hdr_sat, hdr_orb, hdr_epoch, $
          hdr_axis, hdr_ecc, hdr_inc, $
          hdr_node, hdr_aperigee, hdr_manomaly, $
          format='("FAST Orbit Data version ",A,/,' + $
          '"SATELLITE: ",A,/,' + $
          '"ORBIT: ",A,TR5,"EPOCH: ",A,/,' + $
          '"AXIS = ",A," ECC = ",A," INC = ",A,/,' + $
          '"NODE = ",A," APERIGEE = ",A,TR5,"MANOMALY = ",A)'
        free_lun, orbfile_lun
        
    endif else if keyword_set(vin) then begin
        
        ;;;; Section commented because FDF orbit file unnecessary
        ;;
        ;;;; Write the temporary FDF orbit file
        ;;
        ;;fdf_tmp = 'FDF_tmp' + suffix
        ;;pos_tmp = position(*,i)
        ;;vel_tmp = velocity(*,i)
        ;;fdfstat = fdf_orb_write(pos=pos_tmp, vel=vel_tmp, $
        ;;                        epoch=ref, file=fdf_tmp)
        ;;;; Call orbgen to write the orbit file for get_fa_orbit
        ;;
        ;;print, 'Calling orbgen to produce orbit file...'
        ;;spawn, ['orbgen','-d','300','-f','-n','1',fdf_tmp,orbit_file], /noshell
        ;;result = findfile(orbit_file, count=count)
        ;;if count NE 1 then message, 'orbgen did not produce orbit file.'
        ;;
        ;;;; Remove the FDF tmp file
        ;;
        ;;openr, /delete, del_fdf_tmp, /get_lun, fdf_tmp
        ;;free_lun, del_fdf_tmp
        
        
        ;; Collect header and vector elements.
        ;; The orbitio library reads vector elements from orbit file when
        ;; possible, only using the header elements when necessary.
        
        date_doy_sec, ref, year, doy, sec
        time = (str_sep(time_to_str(ref, /msec), '/'))(1)
        hdr_ver = '1.2'
        hdr_sat = 'FAST'
        hdr_year = strtrim(year, 2)
        hdr_doy = strtrim(doy, 2)
        hdr_time = time
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
        hdr_x = strtrim(position(0,i), 2)
        hdr_y = strtrim(position(1,i), 2)
        hdr_z = strtrim(position(2,i), 2)
        hdr_vx = strtrim(velocity(0,i), 2)
        hdr_vy = strtrim(velocity(1,i), 2)
        hdr_vz = strtrim(velocity(2,i), 2)
        
        ;; Write the orbit file
        
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
          '"TIME X Y Z VX VY VZ",/,' + $
          'A," ",A," ",A," ",A," ",A," ",A," ",A)'
        free_lun, orbfile_lun        
        
    endif
    
    ;; Now that orbit file is written, call get_fa_orbit to propagate
    ;; orbit.  Addition of 1ms to reference time ensures get_fa_orbit
    ;; does not think time requested < orbit file epoch.
    
    get_fa_orbit, ref + .001d, ref + duration, delta_t=delta_t, $
      /all, /drag_prop, /no_store, struc=orbit_data, $
      orbit_file=orbit_file, status=status
    if status NE 0 then message, 'Error in get_fa_orbit.pro'
    
    ;; Remove the orbit file
    
    openr, /delete, del_orbit_file, /get_lun, orbit_file
    free_lun, del_orbit_file
    
    ;; Store the data in tplot structures if desired
    
    if NOT keyword_set(no_store) then begin
        pnames = tag_names(orbit_data)
        n_pnames = n_tags(orbit_data)
        ;; Remove 'FA' from quantities and append index
        labeled_pnames = pnames
        labeled_pnames(where(labeled_pnames EQ 'FA_POS')) = 'POS'
        labeled_pnames(where(labeled_pnames EQ 'FA_VEL')) = 'VEL'
        labeled_pnames = labeled_pnames + '_' + strtrim((i+1),2)
        ;; TIME is zeroth parameter
        str_element, orbit_data, pnames(0), value=time_array
        ;; Loop through and store ALL output quantities (except TIME)
        for p=1, (n_pnames - 1) do begin
            str_element, orbit_data, pnames(p), value=value_tmp
            store_data, labeled_pnames(p), $
              data={x:time_array, y:value_tmp, ytitle:labeled_pnames(p)}
        endfor
    endif
    
    ;; Write the calculated orbit vectors to files if desired
    
    if NOT keyword_set(no_files) then begin
        ;; Open the output file and write to it
        out_fname = output_files + '.' + strtrim((i+1),2)
        openw, out_fname_lun, /get_lun, out_fname
        n_pts = n_elements(orbit_data.time)
        ;; Header fields are 25 chars (only right-justifiable)
        printf, out_fname_lun, format='(A,A22,5A25)', $
          'TIME', 'X', 'Y', 'Z', 'VX', 'VY', 'VZ'
        ;; Data
        for t=0, (n_pts -1) do begin
            printf, out_fname_lun, format='(E,7D)', orbit_data.time(t), $
              orbit_data.fa_pos(t,*), orbit_data.fa_vel(t,*)
        endfor
        free_lun, out_fname_lun
    endif
        
endfor



end

