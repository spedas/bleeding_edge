;+
; FUNCTION:
;         spd_read_current_version
;
; PURPOSE:
;         Reads and returns the current revision # from the file svn_version_info.txt
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-11-17 13:19:52 -0800 (Fri, 17 Nov 2017) $
;$LastChangedRevision: 24305 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_read_current_version.pro $
;-

function spd_read_current_version
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    dprint, dlevel=0, 'Error while searching for current version #; are you running a current copy of the bleeding edge zip?'
    return, -1
  endif

  get_rt_path, path
  if strlowcase(!version.os_family) eq 'windows' then path = strjoin(strsplit(path, '\', /extract), '/')
  vpath = strjoin((strsplit(path, '/', /extract))[0:n_elements(strsplit(path, '/', /extract))-3], '/')
  if strlowcase(!version.os_family) ne 'windows' then vpath = '/' + vpath
  vtemplate = {version: 1.0, $
              datastart: 7, $
              delimiter: 0b, $
              missingvalue: !values.f_nan, $
              commentsymbol: '!', $
              fieldcount: [4, 10], $
              fieldtypes: [7, 7, 7, 3, 7, 7, 7, 3, 7, 3, 7, 3, 7, 7], $
              fieldnames: ['FIELD01', 'FIELD02', 'FIELD03', 'FIELD04', 'FIELD05', 'FIELD06', 'FIELD07', 'FIELD08', 'FIELD09', 'FIELD10', 'FIELD11', 'FIELD12', 'FIELD13', 'FIELD14'], $
              fieldlocations: [0, 5, 13, 18, 0, 5, 13, 19, 30, 39, 45, 51, 54, 58], $
              fieldgroups: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]}
  data = read_ascii(vpath+'/svn_version_info.txt', template = vtemplate)
  return, strcompress(/rem, string((data.field04)[0]))
end