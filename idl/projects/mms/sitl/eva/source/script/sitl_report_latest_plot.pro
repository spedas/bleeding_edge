PRO sitl_report_latest_plot, info,paramset,dir, noblowup=noblowup
  compile_opt idl2

  yyyy  = info.yyyy
  trange = info.trange
  pname = info.pname

  ; png file
  ;--------------
  thisDevice = !D.Name
  Set_Plot, 'Z'
  Erase
  Device, Set_Resolution=[1664,998],Set_Pixel_Depth=24, Decomposed=0
  spd_graphics_config
  ;---------------
  probes = ['1','2','3','4']
  pmax = n_elements(probes)
  pngsize = fltarr(pmax)

  for p=0,pmax-1 do begin
    eva_cmd_load,trange=trange,probes=probes[p],paramset=paramset,paramlist=paramlist, force=force
    dir_png = spd_addslash(dir)+'img/'+yyyy+'/'
    file_mkdir, dir_png
    imax = n_elements(paramlist)
    thislist = strarr(imax)
    for i=0,imax-1 do begin
      a = strsplit(paramlist[i],'*',/extract,count=count)
      case count of
        1: thislist[i] = paramlist[i]
        2: thislist[i] = a[0]+probes[p]+a[1]; if '*' is found
        else: stop
      endcase
    endfor

    ; var lab
    var_lab = ''
    tn=tnames('mms'+probes[p]+'_position_mlt',mmax)
    if (strlen(tn[0]) gt 0) and (mmax gt 0) then var_lab = [var_lab,tn[0]]
    tn=tnames('mms'+probes[p]+'_position_z',mmax)
    if (strlen(tn[0]) gt 0) and (mmax gt 0) then var_lab = [var_lab,tn[0]]
    tn=tnames('mms'+probes[p]+'_position_y',mmax)
    if (strlen(tn[0]) gt 0) and (mmax gt 0) then var_lab = [var_lab,tn[0]]
    tn=tnames('mms'+probes[p]+'_position_x',mmax)
    if (strlen(tn[0]) gt 0) and (mmax gt 0) then var_lab = [var_lab,tn[0]]
    var_lab = (n_elements(var_lab) gt 1) ? var_lab[1:*] : ''
    tplot_options, 'title','MMS '+probes[p]+'   (updated at '+time_string(systime(/seconds,/utc))+' UTC)'
    tplot,thislist, var_lab=var_lab
    if(info.evalstarttime gt 0)then begin
      timebar,mms_tai2unix(info.evalstarttime), linestyle = 2, thick = 2;,/transient
    endif
    write_png, dir_png+pname+'_mms'+probes[p]+'.png', tvrd(/true)
    finfo=file_info(dir_png+pname+'_mms'+probes[p]+'.png')
    pngsize[p] = finfo.SIZE
    tr = timerange() & dt = (tr[1]-tr[0])/3.d0 & tp = 60.d0
    if(~keyword_set(noblowup))then begin
      tlimit,-tp+tr[0]        ,tp+tr[0]+     dt & write_png, dir_png+pname+'_mms'+probes[p]+'_a.png',tvrd(/true)
      tlimit,-tp+tr[0]+     dt,tp+tr[0]+2.d0*dt & write_png, dir_png+pname+'_mms'+probes[p]+'_b.png',tvrd(/true)
      tlimit,-tp+tr[0]+2.d0*dt,tp+tr[0]+3.d0*dt & write_png, dir_png+pname+'_mms'+probes[p]+'_c.png',tvrd(/true)
    endif
  endfor
  result = max(pngsize,p,/nan)
  select = strtrim(string(probes[p]),2)
  ;-----------------
  set_plot, thisDevice
END
