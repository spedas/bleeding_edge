;+
;PROCEDURE:   mvn_sclk_test
;PURPOSE:
;  Compares MET to UNIX time conversions for multiple SCLK kernels.
;  Calculates the error incurred when different versions of the SCLK 
;  kernel are used to convert MET to UNIX time.
;
;USAGE:
;  mvn_sclk_test
;
;INPUTS:
;
;KEYWORDS:
;       VER:      Integer array indicating the SCLK versions to process.  
;                 Default is to analyze the latest six versions.
;
;       TRUNC:    If set, then for each kernel only process times up to the 
;                 release date of the next kernel.
;
;       YLIM:     Set the vertical plot limits.  Default = [0.001,10]
;
;       RESULT:   Named variable to hold the result.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-09-16 15:37:49 -0700 (Wed, 16 Sep 2015) $
; $LastChangedRevision: 18810 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_sclk_test.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_sclk_test, ver=ver, trunc=trunc, ylim=yrange, result=result

  if (not spice_test(verbose=-1)) then begin
    print,"You do not have SPICE installed."
    return
  endif
  
  ymin = 0.001
  ymax = 10.
  if (n_elements(yrange) gt 1) then ymin = min(yrange, max=ymax)

; Get a list of valid SCLK kernels to process

  spath = root_data_dir() + 'misc/spice/naif/MAVEN/kernels/sclk/'
  sck = file_basename(file_search(spath+'*.tsc'))
  nsck = n_elements(sck)
  if (nsck eq 0L) then begin
    print,"No kernels found in: ",spath
    return
  endif

  maxver = fix(strmid(sck[nsck-1],8,5,/reverse))

  if not keyword_set(ver) then ver = maxver - indgen(6) $
                          else ver = reverse(ver[sort(ver)])

  nver = n_elements(ver)
  sck = strarr(nver)
  ctime = dblarr(nver)
  
  for i=0,(nver-1) do begin
    sck[i] = spath + 'MVN_SCLKSCET.' + string(ver[i],format='(i5.5)') + '.tsc'
    finfo = file_info(sck[i])
    if (~finfo.exists) then print,"File not found: ",file_basename(sck[i]) $
                       else ctime[i] = finfo.ctime
  endfor
  
  indx = where(ctime gt 0D, nver)
  if (nver eq 0) then return
  
  ver = ver[indx]
  sck = sck[indx]
  ctime = ctime[indx]

; Generate MET values, one per hour, spanning the time range covered by
; the sck kernels.

  t0 = min(ctime) - 30D*86400D
  t1 = max(ctime) + 30D*86400D
  nmet = ceil((t1 - t0)/3600D)

  toff = time_double('1984-11-14/12') - time_double('2014-11-15')
  met = 3600D*dindgen(nmet) + (t0 + toff)
  time = dblarr(nmet,nver)

; Convert MET to UNIX time for each SCLK kernel

  tls = spice_standard_kernels(verbose=-1)

  for i=0,(nver-1) do begin
    cspice_kclear
    spice_kernel_load, [tls,sck[i]], verbose=-1
    time[*,i] = mvn_spc_met_to_unixtime(met,/correct)
    print,file_basename(sck[i])
  endfor

; Calculate differences between time conversions

  dt = time
  for i=0L,(nmet-1L) do for j=0,(nver-1) do dt[i,j] = abs(time[i,j] - time[i,0])
  
  if keyword_set(trunc) then begin
    for j=1,(nver-1) do begin
      i = where(time[*,j] gt ctime[j-1], count)
      if (count gt 0L) then dt[i,j] = !values.d_nan
    endfor
  endif

; Plot the result

  cols = (indgen(nver) mod 6) + 1
  tvar = 'mvn_sclk_dt'

  store_data,tvar,data={x:time[*,0], y:abs(dt), v:ver}
  ylim,tvar,ymin,ymax,1
  options,tvar,'ytitle','Delta UNIX Time (sec)'
  options,tvar,'colors',cols
  options,tvar,'labels',string(ver,format='(i2.2)')
  options,tvar,'labflag',1
  options,tvar,'yticklen',1
  options,tvar,'ygridstyle',0

  tplot_options,'title','MVN_SCLKSCET.000??.tsc'
  timespan,minmax(time,/nan)
  tplot,tvar

  timebar,ctime,color=cols,line=1
  timebar,(1./32.),/data,var=tvar,line=2
  
  result = {tls   : tls       , $
            sclk  : sck       , $
            ctime : ctime     , $
            time  : time[*,0] , $
            dt    : dt        , $
            color : cols         }

  return

end
