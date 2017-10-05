
;+
;Procedure:
;  spd_find_file
;
;Purpose:
;  Check for the existence of a file in the current path.
;
;Calling Sequence:
;  bool = spd_find_file(file_name)
;
;Input:
;  name: (string) Name of file including type appendix
;
;Output:
;  Return Value: (bool) true if one or more copies of the file found in your path, false if not
;
;Notes:
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2015-01-12 12:57:20 -0800 (Mon, 12 Jan 2015) $
;$LastChangedRevision: 16646 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_find_file.pro $
;
;-
function spd_find_file, name

    compile_opt idl2, hidden

  idl_path_dirs = strsplit(!path, path_sep(/search_path), /extract)

  file_path = file_search( idl_path_dirs + path_sep() + name )

  if n_elements(file_path) eq 1 and file_path[0] eq '' then begin
    return, 0b
  endif else begin
    return, 1b
  endelse

end