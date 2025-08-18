;+
;PROCEDURE:   maven_orbit_makeeph
;PURPOSE:
;  Generates MAVEN spacecraft state vectors using the SPICE Icy toolkit.
;  The result is returned in a structure with the following tags:
;
;    T              Time (UTC): number of seconds since 1970-01-01
;    X              X position coordinate (km)
;    Y              Y position coordinate (km)
;    Z              Z position coordinate (km)
;    VX             X velocity component (km/s)
;    VY             Y velocity component (km/s)
;    VZ             Z velocity component (km/s)
;
;USAGE:
;  maven_orbit_makeeph, frame=frame, origin=origin, eph=eph
;INPUTS:
;
;KEYWORDS:
;       TSTEP:     Time step (seconds).  Default = 60.
;
;       EPH:       Named variable to hold the ephemeris structure.
;
;       FRAME:     Coordinate frame.  Type mvn_frame_name(/list) for a full list.
;
;       ORIGIN:    Origin of coordinate frame.  Can be "Mars", "Phobos", or
;                  "Deimos".  Default = "Mars".
;
;       TSTART:    Start time for output save file ephemeris.
;
;       TSTOP:     Stop time for output save file ephemeris.
;
;       MVN_SPK:   Include the specified spacecraft kernel(s) in the loadlist.  
;                  Full path and filename is required.  Used for the long-range 
;                  predict kernels, such as the design reference mission (DRM).
;
;       UNLOAD:    Unload all kernels (cspice_kclear) after completion.
;
;       RESET:     Unload all kernels (cspice_kclear) and start fresh.
;
;       STAT:      Return statistics of ephemeris coverage.  (Useful to determine
;                  the boundary between reconstructions and predictions.)
;
;       OBJECT:    By default, this routine uses the name 'MAVEN' (id = -202) for
;                  the spacecraft, which is the definition used by NAIF.  It is 
;                  possible for an ephemeris to use a non-standard object name/id.
;                  Use this keyword to override the default and specify the non-
;                  standard name or id.  Example: OBJECT='-200000'.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-07-05 13:14:34 -0700 (Thu, 05 Jul 2018) $
; $LastChangedRevision: 25439 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_makeeph.pro $
;
;CREATED BY:	David L. Mitchell  2014-10-13
;-
pro maven_orbit_makeeph, tstep=tstep, eph=eph, frame=frame, tstart=tstart, tstop=tstop, $
                         unload=unload, reset=reset, stat=stat, origin=origin, $
                         mvn_spk=mvn_spk, nomerge=nomerge, object=object

  common mvn_orbit_makeeph, kernels, tstart1, tstop1

; Initialize SPICE and load kernels (if needed)

  if keyword_set(reset) then begin
    cspice_kclear
    kernels = 0
    tstart1 = 0
    tstop1 = 0
  endif
  
  if keyword_set(nomerge) then domerge = 0 else domerge = 1

  if (size(kernels,/type) ne 7) then begin
  
    moi = time_double('2014-09-22/02:24:00')
    now = systime(/sec,/utc)
    oneday = 86400D
    twoweeks = 14D*oneday
    trange = [(moi - oneday), (now + twoweeks)]

    if (size(mvn_spk,/type) eq 7) then begin
      finfo = file_info(mvn_spk)
      indx = where(~finfo.exists, nbad)
      for i=0,(nbad-1) do print,"Kernel not found: ",mvn_spk[indx[i]]
      if (nbad gt 0L) then return
      kernels = mvn_spice_kernels(['STD','SCK','FRM'], trange=trange, /valid, verbose=-1)
      kernels = [kernels, mvn_spk]
      if (domerge) then begin
        spk = mvn_spice_kernels(['SPK'], trange=trange, /valid, verbose=-1)
        indx = where(file_basename(spk) ne 'maven_orb.bsp')
        spk = spk[indx]  ; don't include the short-range predicts
        kernels = [kernels, spk]
      endif
    endif else begin
      kernels = mvn_spice_kernels(['STD','SCK','FRM','SPK'], trange=trange, /valid, verbose=-1)
    endelse

    indx = where(kernels ne '', count)
    if (count gt 0) then kernels = kernels[indx] else return

    indx = uniq(kernels)
    kernels = kernels[indx] ; only one version of each kernel

    cspice_furnsh, kernels
    print," "
    print,"Kernels in use:"
    for i=0,(n_elements(kernels)-1) do print,file_basename(kernels[i]),format="(3x,a)"
    print," "

  endif

  if not keyword_set(tstep) then tstep = 60D else tstep = double(tstep)
  
  msg = strcompress("Time step: " + string(round(tstep),format='(i)') + " sec")
  print,msg
  print," "
  
  if not keyword_set(frame) then begin
    print,'You must specify a reference frame.'
    return
  endif

  frame = mvn_frame_name(frame[0], success=ok)
  if (not ok[0]) then return

  if (size(origin,/type) ne 7) then origin = 'Mars'
  origin = mvn_frame_name(origin)
  case strupcase(origin) of
    'IAU_MARS'   : center = 'Mars'
    'IAU_PHOBOS' : center = 'Phobos'
    'IAU_DEIMOS' : center = 'Deimos'
    else     : begin
                   print,'Unrecognized origin: ',origin
                   print,'Choices are: Mars, Phobos, Deimos.'
                   return
               end
  endcase
  
  print,"Reference frame: ",frame
  print,"Reference origin: ",center
  print," "

; Get the time range spanned by the spacecraft SPK kernels

  maxiv = 1000
  winsiz = 2 * maxiv
  timlen = 51
  maxobj = 1000
  
  cover = cspice_celld(winsiz)
  ids   = cspice_celli(maxobj)

  indx = where(stregex(kernels,'trj_',/boolean) or stregex(kernels,'maven_orb',/boolean), nspk)
  if (nspk eq 0) then begin
    print,"No SPK kernels!"
    return
  endif
  
  maven_spk = kernels[indx]
  
  stat = replicate({name:'', trange:[0D,0D]}, nspk)

  estart = [0D]
  estop = [0D]

  for k=0,(nspk-1) do begin
    cspice_spkobj, maven_spk[k], ids
    
    stat[k].name = file_basename(maven_spk[k])
    tsp = [0D]

    for i=0, cspice_card(ids) - 1 do begin
      obj = ids.base[ids.data + i]
      cspice_scard, 0L, cover
      cspice_spkcov, maven_spk[k], obj, cover
      
      cspice_bodc2n, obj, name, found
      if (~found) then name = 'UNKNOWN'
      print,"Object : ",obj,"  ",name

      niv = cspice_wncard(cover)
    
      for j=0, niv-1 do begin
        cspice_wnfetd, cover, j, b, e
        cspice_timout, [b,e], "YYYY-MM-DD/HR:MN:SC.###", timlen, timstr
        tr = time_double(timstr[0:1])
        estart = [estart, tr[0]]
        estop = [estop, tr[1]]
        print,i,j,timstr[0:1],format='(i3,2x,i3,2x,a23,3x,a23)'
        tsp = [tsp, tr]
      endfor
    endfor
    
    stat[k].trange = minmax(tsp[1:*])
  endfor
  
  estart = min(time_double(estart[1L:*]))
  estop = max(time_double(estop[1L:*]))

  print, "Spacecraft SPK start time: ", time_string(estart)
  print, "Spacecraft SPK stop  time: ", time_string(estop)
  print, "Number of intervals: ",niv,format='(a,i)'

; Get time range for generating ephemeris

  if not keyword_set(tstart) then begin
    if not keyword_set(tstart1) then tstart = moi - oneday $
                                else tstart = tstart1
  endif
  tstart = time_double(tstart) > estart
  
  if not keyword_set(tstop) then begin
    if not keyword_set(tstop1) then tstop = estop $
                               else tstop = tstop1
  endif
  tstop = time_double(tstop) < estop
  
  trange = [tstart,tstop]
  tstart1 = tstart
  tstop1 = tstop

; Define ephemeris structure 

  npts = floor((tstop - tstart)/tstep) + 1L
  
  eph = {t  : 0D , $
         x  : 0D , $
         y  : 0D , $
         z  : 0D , $
         vx : 0D , $
         vy : 0D , $
         vz : 0D    }
  
  eph = replicate(eph,npts)

  eph.t = tstart + tstep*dindgen(npts)
  timestr = time_string(eph.t,prec=3)

; Convert UTC to ET (TDB seconds past J2000)

  cspice_str2et, timestr, et

; Generate the ephemeris centered on Mars (or Phobos or Deimos) without 
; aberration correction

  if (size(object,/type) eq 0) then object = 'MAVEN'
  cspice_spkezr, object, et, frame, 'NONE', center, state, ltime

; Package the result

  eph.x = reform(state[0,*])
  eph.y = reform(state[1,*])
  eph.z = reform(state[2,*])

  eph.vx = reform(state[3,*])
  eph.vy = reform(state[4,*])
  eph.vz = reform(state[5,*])

; Clean up

  if keyword_set(unload) then cspice_kclear

  return

end
