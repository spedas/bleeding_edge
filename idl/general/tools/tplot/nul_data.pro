;+
;$LastChangedBy: ali $
;$LastChangedDate: 2023-03-13 12:37:21 -0700 (Mon, 13 Mar 2023) $
;$LastChangedRevision: 31623 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/nul_data.pro $

;PROCEDURE: nul_data
;PURPOSE: Null out a range of tplot data.
;-

pro nul_data,tpnames,times=times,varname=vnames,appname=appname,no_verify=no_verify

  if not keyword_set(times) then begin
    print,'Pick start and end times of data to nulify'
    ctime,/silent,times,y,vname=vnames,npoints=2
    if n_elements(vnames) ne 2 then return
    if vnames[0] ne vnames[1] then return
    vnames=vnames[0]
  endif

  if keyword_set(tpnames) then vnames=tpnames
  tnams = tnames(vnames,dtype=dtype)

  if not keyword_set(no_verify) then begin
    print, 'Do you really want to NULL the following data quantities:'
    print,tnams
    print, 'in the following time periods:'
    print,time_string(times)
    ans='n'
    read,ans,prompt='? '
    if (strlowcase(ans) ne 'y') && (strlowcase(ans) ne 'yes') then return
    print,'ok'
  endif

  if dimen1(times) ne 2 then message,'Time must have at least 2 elements'

  for i=0,n_elements(tnams)-1 do begin

    vname = tnams[i]
    if dtype[i] ne 1 then continue;
    get_data,vname,data=d, dlimits = dl
    if size(/type,d) ne 8 then continue

    nd2 = dimen2(times)
    for ns=0,nd2-1 do begin
      t = time_double(times[*,ns])

      w = where(d.x gt t[0] and d.x lt t[1],c)
      if c ne 0 then begin
        if ndimen(d.y) eq 1 then d.y[w] = !values.f_nan
        if ndimen(d.y) eq 2 then d.y[w,*] = !values.f_nan
      endif

    endfor

    if keyword_set(appname) then vname=vname+appname

    store_data,vname,data=d, dlimits=dl

  endfor

  return
end
