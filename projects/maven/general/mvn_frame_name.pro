;+
;FUNCTION:   mvn_frame_name
;PURPOSE:
;  Expands a MAVEN frame name fragment to the full frame name
;  recognized by SPICE.  You can omit the leading 'MAVEN_' or
;  'IAU_' from the fragment.  Case folded minimum matching is 
;  performed.  For example, all of the following are expanded
;  to 'MAVEN_STATIC': 'maVEn_st', 'sta', 'St'.
;
;  'GEO' is accepted as a synonym for 'MARS'.
;
;  Simply returns the input if the fragment is not recognized
;  or ambiguous.
;
;USAGE:
;  spice_frame = mvn_frame_name(frame)
;
;INPUTS:
;       frame:    String scalar or array of MAVEN frame name fragments.
;                 If no frame is provided, keyword LIST is set.
;
;KEYWORDS:
;     SUCCESS:    An array of integers with the same number of elements
;                 as frame:
;                     0 = match not found or ambiguous
;                     1 = unique match found
;
;     RESET:      Refresh the list of frame names.
;
;     LIST:       Print a list of frame names and exit.  Returns the
;                 null string.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-03-23 14:07:56 -0700 (Tue, 23 Mar 2021) $
; $LastChangedRevision: 29812 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_frame_name.pro $
;
;CREATED BY:    David L. Mitchell
;-
function mvn_frame_name, frame, success=success, reset=reset, list=list

  common mvn_frame_list, mvn_flist

  if (keyword_set(reset) or (size(mvn_flist,/type) ne 7)) then begin
    mvn_flist = ['MARS','GEO','PHOBOS','DEIMOS','SPACECRAFT','APP','STATIC',$
                 'SWIA','SWEA','MAG1','MAG2','EUV','SEP1','SEP2',$
                 'IUVS_LIMB','IUVS_NADIR','NGIMS','MSO','SSO','MME_2000']
  endif
  flist = mvn_flist
  ffull = ['IAU_'+flist[0:3], 'MAVEN_'+flist[4:*]]

  nframe = n_elements(frame)
  if (keyword_set(list) or (nframe eq 0)) then begin
    for i=0,(n_elements(ffull)-1) do print,"  ",ffull[i]
    return, ''
  endif

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

; Accept "GEO" as a synonym for "MARS"

  i = where(strcmp(frame, 'IAU_GEO', 7, /fold), count)
  if (count gt 0) then frame[i] = 'IAU_MARS'

  return, frame

end
