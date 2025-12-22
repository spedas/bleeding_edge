;+
; FUNCTION: files_exist, file_spec_list
;
; PURPOSE:
;     returns array of strings corresponding to input array of file specs
;
; INPUTS:
;     file_spec_list:
;         either a single file spec, or an array of file specs, where by file spec
;         is meant the file specification required by the findfile program.
;
; OUTPUTS:
;     return value:
;         empty string if there are no files, else an array of strings naming
;         the files that exist.
;       
; CREATED BY: Vince Saba
;
; VERSION: @(#)files_exist.pro	1.2 10/23/98
;-

function files_exist, file_spec_list

if not defined(file_spec_list) then return,''

spec=expand_path(file_spec_list(0))
result = findfile(spec)
n = n_elements(file_spec_list)
if n gt 1 then begin
    for i = 1, n - 1 do begin
	spec = expand_path(file_spec_list(i))
        next = findfile(spec)
        if next(0) ne '' then result = [result, next]
    endfor
endif

return, result
end

