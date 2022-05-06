;+
;PROCEDURE:   swe_3d_stitch
;PURPOSE:
;  Constructs 3D spectra from A0 and A1 packets.  Depending on the group parameter,
;  1, 2, or 4 packets are needed to make one 3D.  The packets comprising one 3D
;  should be generated very close in time; however, they are time tagged with
;  millisec resolution, so there's a possibility that frames will have slightly
;  different time tags.  This routine requires that they be created within 0.3 sec.
;
;  The packets comprising a 3D must all be present, but they need not come in
;  sequential order, as long as they are created within 0.3 seconds of each other.
;  The PFDPU is known to occasionally write packets out of sequential order.
;
;USAGE:
;  swe_3d_stitch
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-05-05 12:57:25 -0700 (Thu, 05 May 2022) $
; $LastChangedRevision: 30799 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_3d_stitch.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;FILE: swe_3d_stitch.pro
;-
pro swe_3d_stitch

  @mvn_swe_com

  dtmax = 0.3D

  ddd = {time   : 0D            , $
         met    : 0D            , $
         n_e    : 0             , $
         group  : 0B            , $
         period : 0B            , $
         npkt   : 0B            , $
         lut    : 0B            , $
         data   : fltarr(80,64) , $
         var    : fltarr(80,64)    }

  if (size(a0,/type) eq 8) then begin
    npkt = n_elements(a0)

    e0 = a0.e0                     ; frame counter
    istart = where(e0 eq 0, n3d)   ; indices of lead frames

    tframe = a0.time               ; time tags of all frames
    tstart = tframe[istart]        ; time tags of lead frames
  
    swe_3d = replicate(ddd, n3d)
    swe_3d.time = a0[istart].time
    swe_3d.met = a0[istart].met
    swe_3d.group = a0[istart].group
    swe_3d.period = a0[istart].period
    swe_3d.npkt = a0[istart].npkt
    swe_3d.lut = a0[istart].lut
    swe_3d.n_e = swe_ne[swe_3d.group]

    nframes = swe_3d.n_e/16        ; number of A0 packets per 3D spectrum
    iend = istart + nframes - 1
    
    for i=0L,(n3d-1L) do begin
      if ((istart[i]+nframes[i]) le npkt) then begin
        dt = abs(tframe[istart[i]:iend[i]] - tstart[i])
        indx = where(dt gt dtmax, count)   ; allow frames to be created within a brief period
        if (count eq 0L) then begin
          iframe = e0[istart[i]:iend[i]]  ; all frames must be present, but they can be out of order
          if (n_elements(uniq(iframe,sort(iframe))) eq nframes[i]) then begin
            for j=0,(nframes[i]-1) do begin
              k = iframe[j]*16
              swe_3d[i].data[*,k:(k+15)] = a0[istart[i]+iframe[j]].data
              swe_3d[i].var[*,k:(k+15)] = a0[istart[i]+iframe[j]].var
            endfor
          endif else print,"A0 missing frame(s): ",istart[i],"  ",time_string(tstart[i])
        endif else print,"A0 frames have different time tags: ",istart[i],"  ",time_string(tstart[i])
      endif else print,"A0 not enough frames left: ",istart[i],"  ",time_string(tstart[i])
    endfor

  endif

  if (size(a1,/type) eq 8) then begin
    npkt = n_elements(a1)

    e0 = a1.e0                     ; frame counter
    istart = where(e0 eq 0, n3d)   ; indices of lead frames

    tframe = a1.time               ; time tags of all frames
    tstart = tframe[istart]        ; time tags of lead frames
  
    swe_3d_arc = replicate(ddd, n3d)
    swe_3d_arc.time = a1[istart].time
    swe_3d_arc.met = a1[istart].met
    swe_3d_arc.group = a1[istart].group
    swe_3d_arc.period = a1[istart].period
    swe_3d_arc.npkt = a1[istart].npkt
    swe_3d_arc.lut = a1[istart].lut
    swe_3d_arc.n_e = swe_ne[swe_3d_arc.group]

    nframes = swe_3d_arc.n_e/16    ; number of A1 packets per 3D spectrum
    iend = istart + nframes - 1

    for i=0L,(n3d-1L) do begin
      if ((istart[i]+nframes[i]) le npkt) then begin
        dt = abs(tframe[istart[i]:iend[i]] - tstart[i])
        indx = where(dt gt dtmax, count)   ; allow frames to be created within a brief period
        if (count eq 0L) then begin
          iframe = e0[istart[i]:iend[i]]  ; all frames must be present, but they can be out of order
          if (n_elements(uniq(iframe,sort(iframe))) eq nframes[i]) then begin
            for j=0,(nframes[i]-1) do begin
              k = iframe[j]*16
              swe_3d_arc[i].data[*,k:(k+15)] = a1[istart[i]+iframe[j]].data
              swe_3d_arc[i].var[*,k:(k+15)] = a1[istart[i]+iframe[j]].var
            endfor
          endif else print,"A1 missing frame(s): ",istart[i],"  ",time_string(tstart[i])
        endif else print,"A1 frames have different time tags: ",istart[i],"  ",time_string(tstart[i])
      endif else print,"A1 not enough frames left: ",istart[i],"  ",time_string(tstart[i])
    endfor

  endif
  
  return

end
