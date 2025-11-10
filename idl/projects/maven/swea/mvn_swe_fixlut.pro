;+
;PROCEDURE:   mvn_swe_fixlut
;PURPOSE:
;  Make manual corrections to the LUT by selecting times on a tplot
;  window with the mouse.
;
;USAGE:
;  mvn_swe_fixlut
;
;INPUTS:
;       newlut:   LUT value to assign each selected SPEC.
;
;KEYWORDS:
;       RESULT:   Table number for each SPEC.
;
;       APPLY:    Insert corrected LUT into SWEA data structures and
;                 remake tplot panels.  If not set, then just update
;                 the tplot variable TABNUM.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-11-05 13:24:51 -0800 (Wed, 05 Nov 2025) $
; $LastChangedRevision: 33831 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_fixlut.pro $
;-
pro mvn_swe_fixlut, newlut, result=result, apply=apply

  @mvn_swe_com

; Get the current LUTs from tplot

  get_data,'TABNUM',data=lut,index=i
  if (i eq 0) then begin
    print, "Can't find LUT tplot variable: TABNUM"
    return
  endif

; Skip to apply if newlut is undefined and APPLY is set

  if ((n_elements(newlut) eq 0L) and keyword_set(apply)) then goto, apply

; Interactively change individual LUTs

  if (n_elements(newlut) eq 0L) then begin
    newlut = 5B
    read, newlut, prompt='Choose a new table number (1-9): ', format='(i1)'
  endif
  newlut = byte(newlut[0])

  if ((newlut lt 1B) or (newlut gt 9B)) then begin
    print,"Table number is out of range: ",newlut
    return
  endif

  ctime,t,panel='TABNUM',npoints=1,/silent
  if (size(t,/type) eq 2) then return
  keepgoing = 1

  while (keepgoing) do begin
    i = nn2(lut.x, t)
    lut.y[i] = newlut

    ctime,t,panel='TABNUM',npoints=1,/silent
    if (size(t,/type) eq 2) then keepgoing = 0
  endwhile

  result = lut.y

apply:

  if keyword_set(apply) then begin

; Insert new LUT information into data structures

    tspec = mvn_swe_engy.time

    delta_t = 1.95D/2D  ; start time to center time for PAD and 3D

    if (size(a0,/type) eq 8) then begin
      indx = nn2(tspec, (a0.time + delta_t))
      a0.lut = lut.y[indx]
    endif

    if (size(a1,/type) eq 8) then begin
      indx = nn2(tspec, (a1.time + delta_t))
      a1.lut = lut.y[indx]
    endif

    if (size(a2,/type) eq 8) then begin
      indx = nn2(tspec, (a2.time + delta_t))
      a2.lut = lut.y[indx]
    endif

    if (size(a3,/type) eq 8) then begin
      indx = nn2(tspec, (a3.time + delta_t))
      a3.lut = lut.y[indx]
    endif

; The PFDPU assigns a LUT value to each a4 packet.  However, the LUT can change
; while an a4 packet is being accumulated, so it doesn't make sense to update
; the LUT values for a4 packets.

    if (size(swe_3d,/type) eq 8) then begin
      indx = nn2(tspec, (swe_3d.time + delta_t))
      swe_3d.lut = lut.y[indx]
    endif

    if (size(swe_3d_arc,/type) eq 8) then begin
      indx = nn2(tspec, (swe_3d_arc.time + delta_t))
      swe_3d_arc.lut = lut.y[indx]
    endif

; Update the SPEC data and associated tplot panel

    mvn_swe_makespec, lut=lut.y, /tplot

  endif

; Always update the tplot panel (allows one to build up corrections)

  store_data,'TABNUM',data=lut
  tplot

end
