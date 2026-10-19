;+
;FUNCTION:
;  thm_asi_dedup_gz
;
;PURPOSE:
;  Some archive trees (notably the stream2 keogram products)
;  contain BOTH an uncompressed file and its gzipped twin (e.g.
;  ..._full-keogram.pgm and ..._full-keogram.pgm.gz), and the data
;  distribution API lists both. Downloading/reading both wastes transfer
;  and duplicates every data record. This function reduces a list of URLs
;  or file paths to one entry per logical file, PREFERRING the .gz
;  variant; entries that only exist uncompressed (it happens: e.g. atha
;  2008-02-10 ut14 hourly keogram) are kept as-is.
;
;INPUT:
;  files: string array of URLs or paths
;
;OUTPUT:
;  Filtered string array (original order preserved).
;-
function thm_asi_dedup_gz, files

  compile_opt idl2

  n = n_elements(files)
  if n eq 0 then return, files

  ; accept LIST input (json_parse output) as well as string arrays
  farr = strarr(n)
  for i = 0l, n - 1 do farr[i] = files[i]
  files = farr
  if n eq 1 then return, files

  base = file_basename(files)
  isgz = strmatch(base, '*.gz')
  key = base
  for i = 0l, n - 1 do $
    if isgz[i] then key[i] = strmid(base[i], 0, strlen(base[i]) - 3)

  keep = bytarr(n)
  su = sort(key)
  u = uniq(key[su])
  gstart = 0l
  for g = 0l, n_elements(u) - 1 do begin
    grp = su[gstart : u[g]]
    wg = where(isgz[grp], ng)
    if ng gt 0 then keep[grp[wg[0]]] = 1b else keep[grp[0]] = 1b
    gstart = u[g] + 1
  endfor

  return, files[where(keep)]
end
