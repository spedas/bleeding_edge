;+
;Procedure: LANL_SPA_LOAD
;
;Purpose:  Loads LANL SPA data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;Example:
;   lanl_spa_load,datatype='k0'
;Notes:
;  This routine is still in development.
; Author: Davin Larson
;
; $LastChangedBy: davin-win $
; $LastChangedDate: $
; $LastChangedRevision:  $
; $URL $
;-
pro lanl_spa_load,type,trange=trange, $
      verbose=verbose,downloadonly=downloadonly, $
      varformat=varformat,datatype=datatype, $
      probes=probes, no_download=no_download, no_update=no_update, $
      addmaster=addmaster,tplotnames=tn,source=source

if not keyword_set(datatype) then $
   datatype = 'sp'


if datatype eq 'sp' then begin
   if not keyword_set(probes) then probes = ['02','97','89','94','01']

   compress = 1

   if not keyword_set(source) then begin
      source = file_retrieve(/struct)
      source.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/misc/lanl/spa/'
      source.local_data_dir = root_data_dir() + '/misc/lanl/spa/'
      if file_test(/regular,source.local_data_dir+'.master') then   source.no_download = 1   ; Local directory IS the master directory
      if n_elements(verbose) ne 0 then source.verbose=verbose
   endif

   for p=0,n_elements(probes)-1 do begin
      probe = probes[p]

      case probe of
      '02':   pathformat = 'YYYY/YYYYMMDD_LANL-02A.sopaflux'
      '01':   pathformat = 'YYYY/YYYYMMDD_LANL-01A.sopaflux'
      '97':   pathformat = 'YYYY/YYYYMMDD_LANL-97A.sopaflux'
      '94':   pathformat = 'YYYY/YYYYMMDD_1994-084.sopaflux'
      '89':   pathformat = 'YYYY/YYYYMMDD_1989-046.sopaflux'
      else:   pathformat = ''
      endcase

      if not keyword_set(pathformat) then begin
          dprint,'Not a valid probe: ',probe
          continue
      endif
      if keyword_set(compress) then pathformat += '.gz'
      
      
      if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
      if keyword_set(no_update) && no_update ne 0 then source.no_update = 1
      
      relpathnames = file_dailynames(file_format=pathformat,trange=trange,times=times)
      files =  spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path = source.local_data_dir, $
                     no_download = source.no_download, no_update = source.no_update, /last_version, $
                     file_mode = '666'o, dir_mode = '777'o)
                     
      if keyword_set(downloadonly) then continue

      prefix = 'lanl_'+probe+'_'

      nfiles = n_elements(files)
      alldat=0
      for i=0,nfiles-1 do begin
          dprint,'Reading file: ',files[i],dlevel=2,verbose=source.verbose
          format = {time:0d,glat:0.,glon:0.,radius:0., $
              el_flux:fltarr(10),Pr_flux:fltarr(12) ,esp:fltarr(6) }

          dat = read_asc(files[i],format=format,header=hdr,nheader=1)
          if keyword_set(dat) then begin
            dat.time = dat.time * 3600d + times[i]
            append_array,alldat,dat
          endif
      endfor
      if probe eq '89' and keyword_set(alldat) then alldat.el_flux[9] /= 1000.
      if keyword_set(alldat) then begin
         hdrs = strsplit(hdr,/extract)
         el_labs = hdrs[4:13]
         pr_labs = hdrs[14:25]
         esp_labs = hdrs[26:31]
         el_nrgs0 = [50.,75.,105.,150.,225.,315.,500.,750.,1100.,1.5]*1000.
         el_nrgs1 = [75.,105.,150.,225.,315.,500.,750.,1100.,1.5,3.]*1000.
         el_nrgs = (el_nrgs0+el_nrgs1)/2.
         y_units = '#/cm2/s/st/eV'
         v_units = 'eV'
         store_data,prefix+'el_flux',data={x:alldat.time,y:transpose(alldat.el_flux/1000.),v:el_nrgs} , $
              dlim={labflag:-1,labels:el_labs,y_units:y_units,ysubtitle:'['+y_units+']',v_units:v_units,yrange:[1e-5,1e3],ylog:1,ystyle:1}

         pr_nrgs0 = [50.,75.,113.,170.,250.,400.,670.,1200.,1900.,3.1,5.0,7.7]*1000.
         pr_nrgs1 = [75.,113.,170.,250.,400.,670.,1200.,1900.,3100,5000,7700,50000.]*1000.
         pr_nrgs = (pr_nrgs0+pr_nrgs1)/2.
         store_data,prefix+'pr_flux',data={x:alldat.time,y:transpose(alldat.pr_flux/1000.),v:pr_nrgs},  $
              dlimit={labflag:-1,labels:pr_labs,y_units:y_units, ysubtitle:'['+y_units+']',v_units:v_units,yrange:[1e-5,1e3],ylog:1,ystyle:1}
         ;stop
         store_data,prefix+'pos_glat',data={x:alldat.time, y:alldat.glat}
         store_data,prefix+'pos_glon',data={x:alldat.time, y:alldat.glon}
         store_data,prefix+'pos_rad',data={x:alldat.time, y:alldat.radius}
         phiang = ((alldat.time/3600d/24d + .5d) mod 1) * 360.
         sphere_to_cart,alldat.radius,alldat.glat,alldat.glon+phiang,geex,geey,geez
         store_data,prefix+'pos_gee',data={x:alldat.time, y:[[geex],[geey],[geez]] }

     endif
  endfor

  if keyword_set(splitem) then begin
     split_vec,'lanl_??_el_flux'
     options,'lanl_02_??_flux_?',colors='b', labels='LANL 02',labflag=2
     options,'lanl_97_??_flux_?',colors='c', labels='LANL 97',labflag=2
     options,'lanl_89_??_flux_?',colors='g', labels='LANL 89',labflag=2
     options,'lanl_94_??_flux_?',colors='y', labels='LANL 94',labflag=2
     options,'lanl_01_??_flux_?',colors='r', labels='LANL 01',labflag=2

     store_data,'LANL_xx_el_flux_0',data=tnames('lanl_??_el_flux_0')
     store_data,'LANL_xx_el_flux_1',data=tnames('lanl_??_el_flux_1')
     store_data,'LANL_xx_el_flux_2',data=tnames('lanl_??_el_flux_2')
     store_data,'LANL_xx_el_flux_3',data=tnames('lanl_??_el_flux_3')
     store_data,'LANL_xx_el_flux_4',data=tnames('lanl_??_el_flux_4')


  endif



endif




if datatype eq 'k0' then begin
   if not keyword_set(probes) then probes = ['97','89','94']
   istp_init
   if not keyword_set(source) then source = !istp
   for p=0,n_elements(probes)-1 do begin
      probe = probes[p]


      dprint,dlevel=2,verbose=source.verbose,'Loading LANL ',probe,' SPA data'

   ;if datatype eq 'k0'  then begin
      case probe of
      '97':   pathformat = 'lanl/97_spa/YYYY/l7_k0_spa_YYYYMMDD_v01.cdf'
      '94':   pathformat = 'lanl/94_spa/YYYY/l4_k0_spa_YYYYMMDD_v01.cdf'
      '91':   pathformat = 'lanl/91_spa/YYYY/l1_k0_spa_YYYYMMDD_v01.cdf'
      '90':   pathformat = 'lanl/90_spa/YYYY/l0_k0_spa_YYYYMMDD_v01.cdf'
      '89':   pathformat = 'lanl/89_spa/YYYY/l9_k0_spa_YYYYMMDD_v01.cdf'
      else:   pathformat = ''
      endcase
;endif

      if not keyword_set(pathformat) then begin
          dprint,'Not a valid probe: ',probe
          return
      endif
      
      if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
      if keyword_set(no_update) && no_update ne 0 then source.no_update = 1

      relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)
      files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path = source.local_data_dir, $
        no_download = source.no_download, no_update = source.no_update, /last_version, $
        file_mode = '666'o, dir_mode = '777'o)
        
      if keyword_set(downloadonly) then continue

      if not keyword_set(varformat) then begin
         varformat = '*'
         varformat = 'spa_?_fl*x sc_loc'
      endif

     prefix = 'lanl_'+probe+'_'
      cdf2tplot,file=files,varformat=varformat,verbose=source.verbose,prefix=prefix ,tplotnames=tn    ; load data into tplot variables

; Set options for specific variables

      dprint,dlevel=3,'tplotnames: ',tn

 ;     del_data,strfilter(tn,'*PB5')

      options,/def,strfilter(tn,'*fl*x'),/ylog,colors='br'
      options,/def,strfilter(tn,'*sc_loc'),colors='bgr'
   endfor
endif





end
