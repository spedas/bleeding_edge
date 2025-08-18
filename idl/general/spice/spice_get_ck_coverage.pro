;The purpose of this procedure is to display the time coverage intervals of different NAIF objects contained within the file.  
;It requires as input a CK file and a SCLK file

pro spice_get_ck_coverage, ck_file, sclk_file

      SPICEFALSE = 0B
      MAXIV      = 1000
      WINSIZ     = 2 * MAXIV
      TIMLEN     = 51
      MAXOBJ     = 1000
      
      ;;
      ;; Local variables
      ;;
      cover = cspice_celld( WINSIZ )
      ids   = cspice_celli( MAXOBJ )

      ;;
      ;; Load a standard kernel set.
      ;;
      ;cspice_furnsh, 'standard.tm'
      cspice_furnsh, SCLK_file

      ;;
      ;; Find the set of objects in the CK file. 
      ;;
      cspice_ckobj, CK_file, ids

      ;; We want to display the coverage for each object. Loop over
      ;; the contents of the ID code set, find the coverage for
      ;; each item in the set, and display the coverage.
      ;;
      for i=0, cspice_card( ids ) - 1 do begin
      
         ;;
         ;;  Find the coverage window for the current object, 'i'.
         ;;  Empty the coverage window each time 
         ;;  so we don't include data for the previous object.
         ;;
         obj = ids.base[ ids.data + i ]
         cspice_scard, 0L, cover
         cspice_ckcov, CK_file, obj,  SPICEFALSE, 'INTERVAL', 0.D, 'TDB', cover 

         ;;
         ;; Get the number of intervals in the coverage window.
         ;;
         niv = cspice_wncard( cover )

         ;;
         ;; Display a simple banner.
         ;;
         print, '========================================'
         print, 'Coverage for object:', obj

         ;;
         ;; Convert the coverage interval start and stop times to TDB
         ;; calendar strings.
         ;;
         for j=0, niv-1 do begin
         
            ;;
            ;; Get the endpoints of the jth interval.
            ;;
            cspice_wnfetd, cover, j, b, e

            ;;
            ;; Convert the endpoints to TDB calendar
            ;; format time strings and display them.
            ;; Pass the endpoints in an array, [b,e],
            ;; so cspice_timout returns an array of time 
            ;; strings.
            ;;
            cspice_timout, [b,e], $ 
                           'YYYY MON DD HR:MN:SC.### (TDB) ::TDB',  $
                           TIMLEN ,$
                           timstr 

            print, 'Interval: ', j
            print, 'Start   : ', timstr[0]
            print, 'Stop    : ', timstr[1]
            print

         
        endfor

    endfor
end
    