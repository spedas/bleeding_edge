;+
;FUNCTION:   mvn_frame_name
;PURPOSE:
;  Expands a MAVEN frame name fragment to the full frame name
;  recognized by SPICE.  You can omit the leading 'MAVEN_' or
;  'IAU_' from the fragment.  Case folded minimum matching is 
;  performed.  For example, all of the following are expanded
;  to 'MAVEN_STATIC': 'maVEn_st', 'sta', 'St'.
;
;  Simply returns the input if the fragment is not recognized
;  or ambiguous.
;
;USAGE:
;  spice_frame = mvn_frame_name(frame)
;
;INPUTS:
;       frame:    Sring scalar or array of MAVEN frame name fragments.
;
;KEYWORDS:
;     SUCCESS:    An array of integers with the same number of elements
;                 as frame:
;                     0 = match not found or ambiguous
;                     1 = unique match found
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-07-06 14:44:45 -0700 (Thu, 06 Jul 2017) $
; $LastChangedRevision: 23560 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_frame_name.pro $
;
;CREATED BY:    David L. Mitchell
;-
function mvn_frame_name, frame, success=success

  common mvn_frame_list, mvn_flist

  if (size(mvn_flist,/type) ne 7) then begin
    mvn_flist = ['MARS','PHOBOS','DEIMOS','SPACECRAFT','APP','STATIC',$
                 'SWIA','SWEA','MAG1','MAG2','EUV','SEP1','SEP2',$
                 'IUVS_LIMB','IUVS_NADIR','NGIMS','MSO','SSO','MME_2000']
  endif
  flist = mvn_flist

  nframe = n_elements(frame)
  success = replicate(0, nframe)
  if (size(frame,/type) ne 7) then begin
    print, "Input must be of type string."
    return, frame
  endif
  ftest = frame

; Strip off leading "MAVEN_" or "IAU_", if they exist

  i = where(strcmp(ftest, 'MAVEN_', 6, /fold), count)
  if (count gt 0) then ftest[i] = strmid(ftest[i],6)

  i = where(strcmp(ftest, 'IAU_', 4, /fold), count)
  if (count gt 0) then ftest[i] = strmid(ftest[i],4)

; Case folded minimum matching for the remainder of the fragment

  ffull = ['IAU_'+flist[0:2], 'MAVEN_'+flist[3:*]]

  for j=0,(nframe-1) do begin
    i = strmatch(flist, ftest[j]+'*', /fold)
    case (total(i)) of
       0   : print, "Frame not recognized: ", frame[j]
       1   : begin
               frame[j] = (ffull[where(i eq 1)])[0]
               success[j] = 1
             end
      else : print, "Frame ambiguous: ", frame[j]
    endcase
  endfor

  return, frame

end
