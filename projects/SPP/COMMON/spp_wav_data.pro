;Ali: February 2020
; $LastChangedBy: ali $
; $LastChangedDate: 2023-08-17 18:52:32 -0700 (Thu, 17 Aug 2023) $
; $LastChangedRevision: 32023 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_wav_data.pro $
; $ID: $

;no keyword set: loads daily 1min resolution files (default: fairly fast for use for up to a few days timerange)
;/month: loads monthly 1min resolution files (used for longer than a few days timerange)
;/hires: loads daily  1sec resolution files (loads faster than /hourly below, since needs to load only 1 file per day)
;/hourly: loads hourly 1sec resolution files (24 files per day)
;/hourly,/hires: loads hourly full-resolution files (only recommended for short timespans, since file sizes can be huge!)
;the below keywords are typically only run by Ali to generate the wavelet files:
;/genhourly: generates hourly full-resolution and 1sec files.
;/gendaily: generates daily 1sec and 1min files from the hourly 1sec files.
;/genmonthly: generates monthly 1min files from the daily 1min files.
;/generate: runs the code with the above 3 keywords set in succession.

pro spp_wav_data,trange=trange,types=types,hires=hires,hourly=hourly,monthly=monthly,yearly=yearly,$
  genhourly=genhourly,gendaily=gendaily,genmonthly=genmonthly,genyearly=genyearly,generate=generate

  t1=systime(1)

  if keyword_set(generate) then begin
    spp_wav_data,/genhourly
    spp_wav_data,/gendaily
    spp_wav_data,/genmonthly
    spp_wav_data,/genyearly
    dprint,'Finished everything in '+strtrim(systime(1)-t1,2)+' seconds on '+systime()
    return
  endif

  dir='/disks/data/psp/data/sci/'
  path='psp/data/sci/sweap/.wav/$TYPE$/YYYY/MM/DD/psp_fld_l2_$TYPE$_YYYYMMDD'
  if keyword_set(genyearly) then monthly=1
  if keyword_set(monthly) then path='psp/data/sci/sweap/.wav/$TYPE$_1sec/YYYY/MM/psp_fld_l2_$TYPE$_YYYYMM'
  if keyword_set(yearly) then path='psp/data/sci/sweap/.wav/$TYPE$_1sec/YYYY/psp_fld_l2_$TYPE$_YYYY'
  cdfpath='psp/data/sci/fields/staging/l2/$TYPE$/YYYY/MM/psp_fld_l2_$TYPE$_YYYYMMDDhh_v??.cdf'
  cdfpath='psp/data/sci/fields/l2/$TYPE$/YYYY/MM/psp_fld_l2_$TYPE$_YYYYMMDDhh_v??.cdf'
  if keyword_set(monthly) || keyword_set(yearly) then lowresstr='' else lowresstr='_1sec'
  if keyword_set(hourly) || keyword_set(gendaily) then begin
    path=path+'hh'
    if keyword_set(hires) then lowresstr=''
  endif else if ~keyword_set(hires) then path=path+'_1min'
  alltypes=['mag_SC','dfb_wf_dvdc','dfb_wf_scm']
  if ~keyword_set(types) then types=alltypes
  tpnames=orderedhash(alltypes,['mag_SC','dfb_wf_dVdc_sensor','dfb_wf_scm_hg_sensor'])
  colors=orderedhash(alltypes,['bgr','br','br'])
  cotres=orderedhash(alltypes,['b','g','r'])
  subs=orderedhash(alltypes,[0,5,4])
  rotate=orderedhash(alltypes,[1,0,0])
  prange=orderedhash(alltypes,[24,24,1.1])
  zlim=orderedhash('mag_SC',[2e-3,50],'dfb_wf_dvdc',[1e-8,1e-4],'dfb_wf_scm',[1e-5,1])
  labels=orderedhash('mag_SC',['Bx','By','Bz'],'dfb_wf_dvdc',['dV12','dV34'],'dfb_wf_scm',['By','Bz'])
  dims=orderedhash('mag_SC',[0:2],'dfb_wf_dvdc',[0:1],'dfb_wf_scm',[1:2])

  foreach type,types do begin

    tpname0='psp_fld_l2_'+tpnames[type]
    tpname=tpname0+'_1hr'+['_tres(Hz)','','_wv_pow','_wv_pol_par','_wv_pol_perp']

    if keyword_set(genhourly) then begin
      ;fileall=file_search(dir+'fields/staging/l2/mag_SC/????/??/psp_fld_l2_mag_SC_??????????_v01.cdf')
      pathformat=str_sub(cdfpath,'$TYPE$',type)
      files=spp_file_retrieve(pathformat,trange=trange,/last_version,/valid_only,/hourly)
      for i=0,n_elements(files)-1 do begin
        del_data,[tpname0,tpname]
        if (file_info(files[i])).size eq 0 then continue
        cdf2tplot,files[i]
        get_data,tpname0,time,b,lim=lim,dlim=dlim
        options,dlim,colors=colors[type],labels=labels[type],max_points=10000,labflag=-1,ystyle=3
        t=time/3600
        t0=fix(min(t),type=14) ;hours
        for hr=0,5 do begin
          w=where(t ge t0+hr and t lt t0+hr+1,/null)
          if keyword_set(w) then begin
            del_data,tpname
            store_data,tpname[1],time[w],b[w,dims[type],0],dlim=dlim
            tres_data,tpname[1],/freq
            options,/default,tpname[0],labels=type,colors=cotres[type]
            if n_elements(w) gt 2l^16 then resolution=8 else resolution=0
            wav_data,tpname[1],/kol,rotate=rotate[type],max=2l^24,resolution=resolution,prange=[0,prange[type]]
            options,tpname[2],/default,zrange=zlim[type]
            options,tpname[2:4],/default,ystyle=3,zstyle=3
            options,tpname,'yrange',/default
            if (t0+hr) mod 24 lt 10 then zero='0' else zero=''
            ;tplotname=dir+'sweap/.wav/'+files[i].substring(40,-11)+zero+strtrim((t0+hr) mod 24,2) ;monthly directories
            tplotname=dir+'sweap/.wav/'+files[i].substring(-51-2*subs[type],-37-subs[type])+files[i].substring(-12,-11)+files[i].substring(-37-subs[type],-11)+zero+strtrim((t0+hr) mod 24,2) ;daily
            tplot_save,tpname,filename=tplotname ;full hourly
            foreach tpname1,tpname do begin
              get_data,tpname1,ptr=ptr,dat=dat
              if ~keyword_set(ptr) then continue ;necessary b/c for small field samples or for parallel polarization for dvdc and scm, there's no corresponding wavelet
              *ptr.y=average_hist2(dat.y,dat.x,centertime=*ptr.x,binsize=1.,/nan)
            endforeach
            filename=str_sub(tplotname,type,type+'_1sec')
            tplot_save,tpname,filename=filename ;1sec hourly
          endif
        endfor
      endfor
      continue
    endif

    pathformat=str_sub(path+'.tplot','$TYPE$',type+lowresstr)

    if keyword_set(gendaily) then begin
      trange=timerange(trange)
      res=24l*3600l ;1day seconds
      tres=fix(trange/res,type=14)
      for i=0,tres[1]-tres[0]-1 do begin
        del_data,tpname
        tr=res*(tres[0]+[i,i+1])
        files=spp_file_retrieve(pathformat,trange=tr,/last_version,/valid_only,/hourly)
        if ~keyword_set(files) then continue
        tplot_restore,filenames=files,/verbose,/append,/sort
        filename=files[0].substring(0,-9)
        tplot_save,tpname,filename=filename ;1sec daily
        foreach tpname1,tpname do begin
          get_data,tpname1,ptr=ptr,dat=dat
          if ~keyword_set(ptr) then continue ;necessary b/c for small field samples or for parallel polarization for dvdc and scm, there's no corresponding wavelet
          *ptr.y=average_hist2(dat.y,dat.x,centertime=*ptr.x,binsize=60.,/nan)
          if tag_exist(ptr,'v') && size(*ptr.v,/n_dim) eq 2 then *ptr.v=average_hist2(dat.v,dat.x,binsize=60.,/nan)
        endforeach
        filename=filename+'_1min'
        tplot_save,tpname,filename=filename ;1min daily
      endfor
      continue
    endif

    if keyword_set(genmonthly) then begin
      trange=timerange(trange)
      tmonth=time_double(time_string(trange,tformat='YYYY-MM'))
      res=32.*24.*3600. ;just over 1month seconds
      tmonth0=tmonth[0]
      while tmonth0 le tmonth[1] do begin
        del_data,tpname
        tmonth1=time_double(time_string(tmonth0+res,tformat='YYYY-MM'))
        files=spp_file_retrieve(pathformat,trange=[tmonth0,tmonth1],/last_version,/valid_only,/hourly)
        tmonth0=tmonth1
        if ~keyword_set(files) then continue
        tplot_restore,filenames=files,/verbose,/append,/sort
        filename=files[0].substring(0,-46-subs[type])+'psp_fld_l2_'+type+time_string(tmonth0-10.,tformat='_YYYYMM')+'_1min'
        tplot_save,tpname,filename=filename ;1min monthly
      endwhile
      continue
    endif

    if keyword_set(genyearly) then begin
      trange=timerange(trange)
      tmonth=time_double(time_string(trange,tformat='YYYY'))
      res=370.*24.*3600. ;just over 1year seconds
      tmonth0=tmonth[0]
      while tmonth0 le tmonth[1] do begin
        del_data,tpname
        tmonth1=time_double(time_string(tmonth0+res,tformat='YYYY'))
        files=spp_file_retrieve(pathformat,trange=[tmonth0,tmonth1],/last_version,/valid_only,/hourly)
        tmonth0=tmonth1
        if ~keyword_set(files) then continue
        tplot_restore,filenames=files,/verbose,/append,/sort
        filename=files[0].substring(0,-39-subs[type])+'psp_fld_l2_'+type+time_string(tmonth0-10.,tformat='_YYYY')+'_1min'
        tplot_save,tpname,filename=filename ;1min monthly
      endwhile
      continue
    endif

    files=spp_file_retrieve(pathformat,trange=trange,/last_version,/valid_only,/hourly)
    if ~keyword_set(files) then begin
      dprint,'no tplot files found for the selected time range with format: '+pathformat
      continue
    endif

    if n_elements(files) gt 1 then del_data,tpname
    tplot_restore,filenames=files,/verbose,append=keyword_set(n_elements(files)-1),/sort

  endforeach
  dprint,'Finished in '+strtrim(systime(1)-t1,2)+' seconds on '+systime()
end
