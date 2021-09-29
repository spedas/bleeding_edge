;+
;PROCEDURE:   mvn_swe_makefpad
;PURPOSE:
;  Constructs Hires PAD data structures from raw data.
;
;USAGE:
;  mvn_swe_makefpad
;
;INPUTS:
;
;KEYWORDS:
;
;       UNITS:    Convert data to these units.  Default = 'eflux'.
;
;       TPLOT:    Make tplot variables.
;
;       MERGE:    If TPLOT is set, then create normal-resolution
;                 PAD spectrograms at the same energies and merge
;                 with the high-resolution data.  Set this keyword
;                 to the desired time range, or just set it to 1 
;                 and the routine will choose a reasonable time 
;                 range that encompasses all the hires data.
;
;       PANS:     Returns names of any tplot variables.
;
;       PFILE:    Name of an IDL save file containing the hires PAD
;                 data structures: swe_fpad, swe_fpad_arc.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-08-10 08:53:12 -0700 (Tue, 10 Aug 2021) $
; $LastChangedRevision: 30194 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_makefpad.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_makespec.pro
;-
pro mvn_swe_makefpad, units=units, tplot=tplot, merge=merge, pans=pans, pfile=pfile

  @mvn_swe_com

  if (size(units,/type) ne 7) then units = 'eflux'
  pans = ''

  delta_t = 1.95D/2D

; Try to restore hires data from a save file

  ok = 0
  if (size(pfile,/type) eq 7) then begin
    finfo = file_info(pfile)
    if (finfo.exists) then begin
      print,"Restoring: ",file_basename(pfile)
      swe_fpad = 0
      swe_fpad_arc = 0
      restore, pfile
      if (size(swe_fpad,/type) eq 8) then ok = 1
    endif else begin
      print,"File not found: ",file_basename(pfile)
    endelse
  endif

; If necessary, calculate hires data from L0

  if (not ok) then begin
    if (size(a2,/type) eq 8) then begin
      indx = where(a2.lut gt 6B, count)
      if (count gt 0) then begin
        print,"Survey data ... "
        swe_fpad = mvn_swe_getpad(a2[indx].time + delta_t, units=units)
        swe_fpad = swe_pad32hz_unpack(swe_fpad)
      endif
      doa2 = 1
    endif else doa2 = 0

    if (size(a3,/type) eq 8) then begin
      indx = where(a3.lut gt 6B, count)
      if (count gt 0) then begin
        print,"Burst data ... "
        swe_fpad_arc = mvn_swe_getpad(a3[indx].time + delta_t, units=units, /burst)
        swe_fpad_arc = swe_pad32hz_unpack(swe_fpad_arc)
      endif
      doa3 = 1
   endif else doa3 = 0
  endif

; Make tplot variables with merged lores and hires pad data

  if keyword_set(tplot) then begin
    e50 = 49.168077D
    e200 = 199.05093D

    pname = 'swe_pad_resample_32hz_200eV'
    mvn_swe_pad_resample,nbins=128,erange=e200,/tplot,/norm,/mask,/silent,$
                         tabnum=7,/burst,pans=pname
    options,pname,'x_no_interp',1
    options,pname,'datagap',4D
    pans = [pname]

    pname = 'swe_pad_resample_32hz_50eV'
    mvn_swe_pad_resample,nbins=128,erange=e50,/tplot,/norm,/mask,/silent,$
                         tabnum=8,/burst,pans=pname
    options,pname,'x_no_interp',1
    options,pname,'datagap',4D
    pans = [pans, pname]

    if keyword_set(merge) then begin
      if (n_elements(merge) gt 1) then begin
        tsp = minmax(time_double(merge))
      endif else begin
        two_hours = 2D*3600D
        tsp = minmax(swe_fpad.time)
        tsp = tsp + [-two_hours, two_hours]
      endelse

      pname = 'swe_pad_resample_50eV'
      mvn_swe_pad_resample,tsp,nbins=128,erange=e50,/tplot,/norm,/mask,/silent,$
                           tabnum=5,pans=pname
      options,pname,'x_no_interp',1
      options,pname,'datagap',4D

      pname = 'swe_pad_resample_200eV'
      mvn_swe_pad_resample,tsp,nbins=128,erange=e200,/tplot,/norm,/mask,/silent,$
                           tabnum=5,pans=pname
      options,pname,'x_no_interp',1
      options,pname,'datagap',4D

      get_data,'swe_pad_resample_200eV',data=lores,dlim=dlim
      get_data,'swe_pad_resample_32hz_200eV',data=hires,dlim=dlim

      dt = hires.x - shift(hires.x, 1)
      dt[0] = 1D
      indx = where(dt gt 0.5, count)
      if (count gt 0L) then begin
        hires.y[indx,*] = !values.f_nan
        hires.y[((indx-1L) > 0L),*] = !values.f_nan
      endif

      yhi = hires.y
      nlo = n_elements(lores.x)
      nhi = n_elements(hires.x)
      ntot = nlo + nhi
      x = [lores.x, hires.x]
      y = fltarr(ntot,128)
      y[0L:(nlo-1L),*] = lores.y
      y[nlo:(ntot-1L),*] = yhi
      v = fltarr(ntot,128)
      v[0L:(nlo-1L),*] = lores.v
      v[nlo:(ntot-1L),*] = hires.v

      indx = sort(x)
      x = x[indx]
      y = y[indx,*]
      v = v[indx,*]
      pname = 'swe_pad_resample_200eV_merge'
      store_data,pname,data={x:x, y:y, v:v},dlim=dlim
      options,pname,'ztitle','Norm'
      options,pname,'x_no_interp',1
      options,pname,'datagap',4D
      pans = [pname]

      get_data,'swe_pad_resample_50eV',data=lores,dlim=dlim
      get_data,'swe_pad_resample_32hz_50eV',data=hires,dlim=dlim

      dt = hires.x - shift(hires.x, 1)
      dt[0] = 1D
      indx = where(dt gt 0.5, count)
      if (count gt 0L) then begin
        hires.y[indx,*] = !values.f_nan
        hires.y[((indx-1L) > 0L),*] = !values.f_nan
      endif

      yhi = hires.y
      nlo = n_elements(lores.x)
      nhi = n_elements(hires.x)
      ntot = nlo + nhi
      x = [lores.x, hires.x]
      y = fltarr(ntot,128)
      y[0L:(nlo-1L),*] = lores.y
      y[nlo:(ntot-1L),*] = yhi
      v = fltarr(ntot,128)
      v[0L:(nlo-1L),*] = lores.v
      v[nlo:(ntot-1L),*] = hires.v

      indx = sort(x)
      x = x[indx]
      y = y[indx,*]
      v = v[indx,*]
      pname = 'swe_pad_resample_50eV_merge'
      store_data,pname,data={x:x, y:y, v:v},dlim=dlim
      options,pname,'ztitle','Norm'
      options,pname,'x_no_interp',1
      options,pname,'datagap',4D
      pans = [pans, pname]
    endif
  endif

  return

end
