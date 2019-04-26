;+
;Procedure:
;  spd_download_expand
;
;Purpose:
;  Check remote host for requested files and apply wildcards
;  by downloading and parsing remote index file.
;
;Calling Sequence:
;  spd_download_extract, url, last_version=last_version
;
;Input:
;  url:  String array of URLs to remote files.
;  last_version:  Flag to only use the last file in a lexically sorted list 
;                 when wildcards result in multiple matches. 
;
;Output:
;  url:  String array of matching remote files or empty string if no matches are found.
;
;Notes:
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2019-04-25 15:32:56 -0700 (Thu, 25 Apr 2019) $
;$LastChangedRevision: 27093 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_download_expand.pro $
;
;-

pro spd_download_expand, url, last_version=last_version, ssl_verify_peer=ssl_verify_peer, ssl_verify_host=ssl_verify_host, _extra=_extra

    compile_opt idl2, hidden


;find instances of wildcards
wild = stregex(url, '[]*?[]',/bool)

;no need to query if there are no wildcards
if total(wild) eq 0 then return

;find remote urls vs. local paths
remote = stregex(url, '^(http|ftp)s?://', /bool) 

;differentiate the two different search types
remote_idx = where(wild and remote, n_remote)
local_idx = where(wild and ~remote, n_local)


;Search remote files
;------------------------------------
if n_remote gt 0 then begin

  ;split URLs into base and filename
  url_base = (stregex(url[remote_idx], '(^.*/)[^/]*$',/subexpr,/extract))[1,*]
  filenames = (stregex(url[remote_idx], '/([^/]*$)',/subexpr,/extract))[1,*]
  
  ;get and loop over unique bases
  ;  -minimizes number of times the server is contacted
  unique_bases = url_base[uniq(url_base, sort(url_base))]
  
  for i=0, n_elements(unique_bases)-1 do begin
    
    ;download index file for current base
    current = spd_download_file(url=unique_bases[i], /string_array, ssl_verify_peer=ssl_verify_peer, ssl_verify_host=ssl_verify_host, /disable_cdfcheck, _extra=_extra)
    
    ;extract URLs from index file
    links = spd_download_extract(current,/relative,/normal,no_parent=unique_bases[i])
  
    ;perform searches for this base by looping over its instances
    base_idx = where(url_base eq unique_bases[i], n_bases) 
  
    for k=0, n_bases-1 do begin
  
      ;compare retrieved list with requested file pattern
      matches = where( strmatch(links, filenames[base_idx[k]], /fold_case), n_matches)
  
      if n_matches eq 0 then continue
  
      ;use last in lexically sorted list if requested
      if keyword_set(last_version) then begin
        matches = matches[ (sort(links[matches]))[n_matches-1] ]
      endif
  
      ;aggregate matches
      all_matches = array_concat( unique_bases[i] + links[matches], all_matches)
  
    endfor
  
  endfor

endif


;Search local files
;------------------------------------
for i=0, n_local-1 do begin

  ;search for this file pattern
  matches = file_search(url[local_idx[i]], count=n_matches)

  if n_matches eq 0 then continue

  ;use last in lexically sorted list if requested
  if keyword_set(last_version) then begin
    matches = matches[n_matches-1 > 0]
  endif

  ;aggregate matches
  all_matches = array_concat(matches, all_matches) 

endfor


;Recombine with non-wildcard requests and return
;------------------------------------
regular_idx = where(~wild, n_regular)

if n_regular gt 0 then begin
  all_matches = array_concat(url[regular_idx], all_matches)
endif

;replace input with aggregated results
if undefined(all_matches) then begin
  url = ''
endif else begin
  url = all_matches
endelse


end