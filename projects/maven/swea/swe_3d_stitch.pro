;+
;PROCEDURE:   swe_3d_stitch
;PURPOSE:
;  Constructs 3D spectrograms from A0 packets.  Depending on the group parameter,
;  1, 2, or 4 A0 packets are needed to make one 3D.
;
;USAGE:
;  swe_3d_stitch
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-04-25 20:07:01 -0700 (Mon, 25 Apr 2016) $
; $LastChangedRevision: 20924 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_3d_stitch.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;FILE: swe_3d_stitch.pro
;-
pro swe_3d_stitch

  @mvn_swe_com

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
    
    for i=0L,(n3d-1L) do begin
      if ((istart[i]+nframes[i]) le npkt) then begin
        dt = where(tframe[istart[i]:(istart[i]+nframes[i]-1)] ne tstart[i],count)
        tmsg = time_string(tstart[i])
        if (count eq 0L) then begin
          for j=0,(nframes[i]-1) do begin
            if (e0[istart[i]+j] eq j) then begin
              k = j*16
              swe_3d[i].data[*,k:(k+15)] = a0[istart[i]+j].data
              swe_3d[i].var[*,k:(k+15)] = a0[istart[i]+j].var
            endif else print,"A0 frame out of order: ",istart[i] + j,"  ",j,"  ",nframes[i],"  ",tmsg
          endfor
        endif else print,"A0 frames have different time tags: ",istart[i],"  ",tmsg
      endif else print,"A0 not enough frames left: ",istart[i],"  ",tmsg
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
    
    for i=0L,(n3d-1L) do begin
      if ((istart[i]+nframes[i]) le npkt) then begin
        dt = where(tframe[istart[i]:(istart[i]+nframes[i]-1)] ne tstart[i],count)
        tmsg = time_string(tstart[i])
        if (count eq 0L) then begin
          for j=0,(nframes[i]-1) do begin
            if (e0[istart[i]+j] eq j) then begin
              k = j*16
              swe_3d_arc[i].data[*,k:(k+15)] = a1[istart[i]+j].data
              swe_3d_arc[i].var[*,k:(k+15)] = a1[istart[i]+j].var
            endif else print,"A1 frame out of order: ",istart[i] + j,"  ",j,"  ",nframes[i],"  ",tmsg
          endfor
        endif else print,"A1 frames have different time tags: ",istart[i],"  ",tmsg
      endif else print,"A1 not enough frames left: ",istart[i],"  ",tmsg
    endfor

  endif
  
  return

end
