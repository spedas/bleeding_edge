;$LastChangedBy: ali $
;$LastChangedDate: 2023-03-13 12:37:21 -0700 (Mon, 13 Mar 2023) $
;$LastChangedRevision: 31623 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/misc/fill_nan.pro $

function fill_nan,data,intfill=intfill,realfill=realfill

  if n_elements(intfill) eq 0 then intfill=0
  if n_elements(realfill) eq 0 then realfill=!values.f_nan
  dt = size(/type,data)
  if dt eq 0 then return,data
  rdat = data
  case dt of
    1:  rdat[*] = intfill
    2:  rdat[*] = intfill
    3:  rdat[*] = intfill
    12: rdat[*] = intfill
    13: rdat[*] = intfill
    14: rdat[*] = intfill
    15: rdat[*] = intfill
    4:  rdat[*] = realfill
    5:  rdat[*] = realfill
    6:  rdat[*] = realfill
    7:  rdat[*] = ''
    8:  begin
      n = n_tags(rdat)
      for i=0,n-1 do rdat.(i) = fill_nan(rdat.(i),intfill=intfill,realfill=realfill)
    end
    9:  rdat[*] = realfill
    10: rdat[*] = ptr_new()
    else:  dprint,'Data type not implemented: ',dt
  endcase
  return,rdat
end

