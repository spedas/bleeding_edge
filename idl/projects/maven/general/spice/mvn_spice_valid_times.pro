;+
;
;FUNCTION:        MVN_SPICE_VALID_TIMES
;
;PURPOSE:         
;                 Checks whether the currently loaded SPICE/kernels are valid for the specified time.
;
;INPUTS:
;     tvar:       Time or time array to be checked.
;
;KEYWORDS:
;     TOLERANCE:  Maximum time difference between input time and nearest valid SPICE coverage.
;                 Default = 120 sec.
;
;     SPKONLY:    Consider only SPK kernels.  Any missing CK information is ignored.
;                 Useful when spacecraft orientation is not needed.
;
;     BUSONLY:    Consider only C kernels for the spacecraft bus.  Any missing CK information
;                 for the APP is ignored.  Useful for instruments not mounted on the APP.
;
;CREATED BY:      Takuya Hara on 2018-07-11.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2021-01-17 18:28:37 -0800 (Sun, 17 Jan 2021) $
; $LastChangedRevision: 29607 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_spice_valid_times.pro $
;
;-
FUNCTION mvn_spice_valid_times, tvar, verbose=verbose, tolerance=tol, spkonly=spkonly, busonly=busonly
  status = 0 ; invalid
  IF SIZE(tol, /type) EQ 0 THEN tol = 120.d0
  spkonly = keyword_set(spkonly)
  busonly = keyword_set(busonly) or spkonly

  IF SIZE(tvar, /type) EQ 0 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'You must supply a time or time array to be checked.'
     RETURN, status
  ENDIF ELSE BEGIN
     time = tvar
     IF SIZE(time, /type) EQ 7 THEN time = time_double(time)
     ntime = N_ELEMENTS(time)
     IF ntime GT 1 THEN pflg = 1 ELSE pflg = 0
  ENDELSE 

  test = spice_test('*')
  IF (N_ELEMENTS(test) EQ 1 AND test[0] EQ '') THEN $
     dprint, dlevel=2, verbose=verbose, 'SPICE/kernels should be loaded at first.' $
  ELSE BEGIN
     info = spice_kernel_info(/use_cache)
     w = WHERE(info.type EQ 'CK' AND STRMATCH(FILE_BASENAME(info.filename), 'mvn_swea*.bc') EQ 0, nw)
     IF nw GT 0 THEN ck = info[w]
    
     w = WHERE(info.type EQ 'SPK' AND STRMATCH(FILE_BASENAME(info.filename), 'maven_orb*.bsp') EQ 1, nw)
     IF nw GT 0 THEN spk = info[w]

     undefine, w, nw, info
     IF SIZE(ck, /type) NE 0 THEN append_array, info, ck
     IF SIZE(spk, /type) NE 0 THEN append_array, info, spk
     kernels = info.filename
     objects = info.obj_name  ; keep track of the s/c bus and APP gimbals separately
;    kernels = kernels[UNIQ(kernels, SORT(kernels))] ; UNIQ can discard info about multiple objects
     nk = N_ELEMENTS(kernels)

     valid = INTARR(nk, ntime)
     FOR i=0, nk-1 DO BEGIN
        t = WHERE(STRMATCH(info.filename, kernels[i]) EQ 1, nt)
        checks = INTARR(ntime, nt)

        FOR j=0, nt-1 DO BEGIN
           index = INTERPOL([0., 1.], time_double(info[t[j]].trange) + [1.d0, -1.d0]*tol, time)

           w = WHERE(index GE 0. AND index LE 1., nw, complement=v, ncomplement=nv)
           IF nw GT 0 THEN checks[w, j] = 1
           IF nv GT 0 THEN checks[v, j] = 0
           undefine, w, v, nw, nv
        ENDFOR 

        IF SIZE(checks, /n_dimension) EQ 2 THEN checks = TOTAL(checks, 2)
        w = WHERE(checks GT 0, nw)
        IF nw GT 0 THEN valid[i, w] = 1
        undefine, w, nw
     ENDFOR 

; If an object is covered by multiple kernels, then only one of these kernels needs to be
; valid at any given time (modification below by DLM).

     IF nk GT 1 THEN BEGIN
       w = where(objects eq 'MAVEN_SC_BUS', nw)
       if (nw gt 1) then valid[w,*] = replicate(1,nw) # max(valid[w,*],dim=1)  ; only one need be valid
       if (spkonly) then if (nw gt 0) then valid[w,*] = 1                      ; ignore C kernels entirely
       w = where(objects eq 'MAVEN_APP_OG', nw)
       if (nw gt 1) then valid[w,*] = replicate(1,nw) # max(valid[w,*],dim=1)  ; only one need be valid
       if (busonly) then if (nw gt 0) then valid[w,*] = 1                      ; ignore APP
       w = where(objects eq 'MAVEN_APP_IG', nw)
       if (nw gt 1) then valid[w,*] = replicate(1,nw) # max(valid[w,*],dim=1)  ; only one need be valid
       if (busonly) then if (nw gt 0) then valid[w,*] = 1                      ; ignore APP

       w = where(objects eq 'MAVEN', nw)
       if (nw gt 1) then valid[w,*] = replicate(1,nw) # max(valid[w,*],dim=1)  ; only one need be valid

       valid = PRODUCT(valid, 1)  ; all kernels must be valid or ignored at any given time
     ENDIF
     w = WHERE(valid EQ 0, nw, complement=v, ncomplement=nv)
     IF (pflg) THEN BEGIN
        status = INTARR(ntime)
        IF nv GT 0 THEN status[v] = 1
     ENDIF ELSE IF nw EQ 0 THEN status = 1 ; valid
  ENDELSE
  RETURN, status
END
