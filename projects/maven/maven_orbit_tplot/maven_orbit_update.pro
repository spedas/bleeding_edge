;+
;PROCEDURE:   maven_orbit_update
;PURPOSE:
;  Updates the "current" spacecraft ephemeris using SPICE. 
;
;USAGE:
;  maven_orbit_update
;
;INPUTS:
;
;KEYWORDS:
;       TSTEP:    Ephemeris time step (sec).  Default = 60 sec.
;
;       REBUILD:  Normally, months containing only reconstructed kernels are not
;                 updated.  Set this keyword to rebuild the entire database.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-11-18 15:35:55 -0800 (Sun, 18 Nov 2018) $
; $LastChangedRevision: 26145 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_update.pro $
;
;CREATED BY:	David L. Mitchell  2014-10-13
;-
pro maven_orbit_update, tstep=tstep, rebuild=rebuild

; First month is Sep 2014 -> moi on 2014-09-22/02:24:00

  month0 = replicate(time_struct('2014-09-01'),2)
  month0.month = month0.month + [0,1]

  if not keyword_set(tstep) then tstep = 60D
  path = root_data_dir() + 'maven/anc/spice/sav/'
  mroot = path + 'maven_spacecraft_mso_'
  groot = path + 'maven_spacecraft_geo_'

; Generate and process ephemeris in MSO frame

  maven_orbit_makeeph, tstep=tstep, frame='mso', eph=eph, /reset, stat=stat
  
  tmin = min(eph.t, max=tmax)
  
  k = where(stat.name eq 'maven_orb_rec.bsp',nk)
  if (nk gt 0) then trec = stat[k[0]].trange[1] else trec = 0D
  if keyword_set(rebuild) then trec = 0D
  
  dmonth = 0
  trange = time_double(month0)
  mlist = ['']
  
  while(trange[0] lt tmax) do begin
    indx = where((eph.t ge trange[0]) and (eph.t lt trange[1]), count)
    if (count gt 0L) then begin
      maven_mso = temporary(eph[indx])
      if (max(maven_mso.t) gt trec) then begin
        tstr = time_struct(trange[0])
        yyyy = string(tstr.year, format='(i4.4)')
        mm = string(tstr.month, format='(i2.2)')
        mname = mroot + yyyy + mm + '.tmp'
        save, maven_mso, file=mname
        mlist = [mlist, mname]
      endif
    endif
    
    dmonth++
    trange = month0
    trange.month = month0.month + dmonth
    trange = time_double(trange)    
  endwhile

; Generate and process ephemeris in IAU_MARS frame

  maven_orbit_makeeph, tstep=tstep, frame='geo', eph=eph, /unload

  tmin = min(eph.t, max=tmax)
  
  dmonth = 0
  trange = time_double(month0)
  glist = ['']
  
  while(trange[0] lt tmax) do begin
    indx = where((eph.t ge trange[0]) and (eph.t lt trange[1]), count)
    if (count gt 0L) then begin
      maven_geo = temporary(eph[indx])
      if (max(maven_geo.t) gt trec) then begin
        tstr = time_struct(trange[0])
        yyyy = string(tstr.year, format='(i4.4)')
        mm = string(tstr.month, format='(i2.2)')
        gname = groot + yyyy + mm + '.tmp'
        save, maven_geo, file=gname
        glist = [glist, gname]
      endif
    endif
    
    dmonth++
    trange = month0
    trange.month = month0.month + dmonth
    trange = time_double(trange)    
  endwhile

; Rename the temporary files.  This happens very fast, to make it highly
; unlikely that someone will request an ephemeris during the time when the
; MSO ephemeris been updated but the corresponding GEO ephemeris hasn't.

  nfiles = n_elements(mlist) - 1

  if (nfiles gt 0) then begin
    mlist = mlist[1:*]
    glist = glist[1:*]
    msave = file_dirname(mlist) + '/' + file_basename(mlist, '.tmp') + '.sav'
    gsave = file_dirname(glist) + '/' + file_basename(glist, '.tmp') + '.sav'

    for i=0,(nfiles-1) do begin
      file_move, mlist[i], msave[i], /overwrite
      file_move, glist[i], gsave[i], /overwrite
    endfor
  endif

end
