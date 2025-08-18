;+
;PROCEDURE:   swe_rotate
;PURPOSE:
;  Rotates SWEA 3D or PAD look directions into any valid SPICE frame.
;
;USAGE:
;  swe_rotate, dat, frame=frame, result=result
;
;INPUTS:
;       dat:          A single or an array of SWEA 3D or PAD structures.
;                     See mvn_swe_get3d() and mvn_swe_getpad().
;
;KEYWORDS:
;       FRAME:        SPICE frame to rotate the look directions into.  Required.
;                     No default.  This must be a valid SPICE frame, although
;                     you can use minimum matching fragments (see mvn_frame_name).
;
;       RESULT:       A 3 x N x M array of vectors in the requested frame, where
;                     the first dimension is the 3 cartesian components (x,y,z),
;                     the second dimension is the number of times (N), and
;                     the third dimension is the number of look directions (M).
;                     Since this is a pure rotation, all vectors have unit length.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-10-21 13:08:06 -0700 (Wed, 21 Oct 2020) $
; $LastChangedRevision: 29265 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_rotate.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: swe_rotate.pro
;-
pro swe_rotate, dat, frame=to_frame, result=v_out

  @mvn_swe_com

  if (size(to_frame,/type) ne 7) then begin
    print,"%SWE_ROTATE: You must specify a frame."
    return
  endif
  to_frame = mvn_frame_name(to_frame[0], success=ok)
  if (not ok) then return
  from_frame = mvn_frame_name('swe')
  chk_frame = mvn_frame_name('spacecraft')

  str_element, dat, 'time', success=ok
  if (ok) then str_element, dat, 'theta', success=ok
  if (ok) then str_element, dat, 'phi', success=ok
  if (not ok) then begin
    print,"%SWE_ROTATE: unrecognized input data."
    return
  endif

  theta = reform(dat.theta[0,*]) * !dtor
  phi = reform(dat.phi[0,*]) * !dtor
  x = cos(theta)*cos(phi)
  y = cos(theta)*sin(phi)
  z = sin(theta)

  xsize = size(x)
  case xsize[0] of
     1  :  begin
            ndir = xsize[1]
            nsam = 1
           end
     2  :  begin
            ndir = xsize[1]
            nsam = xsize[2]
           end
    else : begin
             print,"%SWE_ROTATE: unexpected array dimensions"
             return
           end
  endcase

  v_swe = fltarr(3, nsam, ndir)
  v_swe[0,*,*] = transpose(x)
  v_swe[1,*,*] = transpose(y)
  v_swe[2,*,*] = transpose(z)
  v_out = v_swe

  print,"Rotating " + strtrim(string(ndir),2) + " look directions: "
  for i=0,(ndir-1) do begin
    print, i, format='(2x,i2,2x,$)'
    v_out[*,*,i] = spice_vector_rotate(v_swe[*,*,i], dat.time, from_frame, to_frame, check=chk_frame)
  endfor

  return

end
