pro repath,except=except
sourcedir = getenv('IDL_PATH')
if not keyword_set(sourcedir) then sourcedir = pref_get('IDL_PATH')
sourcedirs = expand_path(sourcedir,/array)  ; get array of all subdirs
ok = strpos(sourcedirs,'SCCS') lt 0         ; ignore all SCCS directories
for i = 0 , n_elements(except) -1 do $
  ok = ok and (strpos(sourcedirs,except[i]) lt 0)
ind = where( ok ,c)
if c gt 0 then begin
  sourcedirs = sourcedirs[ind]
  !path = sourcedirs[0]
  for j=1,c-1 do !path = !path+path_sep(/search_path)+sourcedirs[j]
endif
end

