

pro thm_sst_load_mag,tplotnames,magname_format   ;,probe=probe,dist_name=dist_name,magname_format=magname_format

if not keyword_set(tplotnames) then tplotnames= 'th?_ps??_data'
if not keyword_set(magname_format) then magname_format = 'th?_fgs'

tpnames = tnames(tplotnames,n)
for i=0,n-1 do begin
   magname = magname_format
   strput, magname, strmid(tpnames[i],0,3)
   get_data,tpnames[i],ptr = dptr
   mdistdat = *dptr.mdistdat
   for j=0,n_elements(mdistdat.distptrs)-1 do begin
     if ptr_valid(mdistdat.distptrs[j])  then begin
        distdat = *(mdistdat.distptrs[j])
        if ptr_valid(distdat.times) eq 0 then continue
        magf = data_cut(magname,*distdat.times)
        if ptr_valid(distdat.magf) then *distdat.magf = magf else begin
          (*((*dptr.mdistdat).distptrs[j])).magf = ptr_new(magf,/no_copy)
;          *dptr.distdat = distdat
;          store_data,tpnames[i],data = dptr ; line not needed
        endelse
     endif
   endfor
endfor
end







pro thm_sst_load_extra,tplotnames

if not keyword_set(tplotnames) then tplotnames= 'th?_ps??_data'

tpnames = tnames(tplotnames,n)
for i=0,n-1 do begin
    format = strmid(tpnames[i],0,8)
    dprint,dlevel=3,'Getting ATTEN for: ',format
    times = thm_pdist(format,/times)
    n = n_elements(times)
    att = intarr(n)
    rate = fltarr(n)
    for j=0l,n-1 do begin
       dat = thm_pdist(format,index=j)
       rdat = conv_units(dat,'rate')
       rate[j] = total(rdat.data)
       att[j] = dat.atten
       dprint,dwait=5,j,n
    endfor
    store_data,format+'_rate',data={x:times,y:rate},dlim={ylog:1}
    store_data,format+'_atten',data={x:times,y:att},dlim={tplot_routine:'bitplot',colors:'rgrgrgrg',yrange:[-1,4]}
endfor
end




pro thm_sst_load_atten2,tplotnames

if not keyword_set(tplotnames) then tplotnames= 'th?_ps??_data'

tpnames = tnames(tplotnames,n)
for i=0,n-1 do begin
    format = strmid(tpnames[i],0,8)
    dprint,dlevel=3,'Getting ATTEN for: ',format
    times = thm_pdist(format,/times)
    n = n_elements(times)
    att = intarr(n)
    for j=0l,n-1 do begin
       dat = thm_pdist(format,index=j)
       att[j] = dat.atten
       dprint,dwait=5,j,n
    endfor
    store_data,format+'_atten',data={x:times,y:att},dlim={tplot_routine:'bitplot',colors:'rgrgrgrg',yrange:[-1,4]}
;   get_data,tpnames[i],ptr = dptr
;   mdistdat = *dptr.mdistdat
;   for j=0,n_elements(mdistdat.distptrs)-1 do begin
;     if ptr_valid(mdistdat.distptrs[j])  then begin
;        distdat = *(mdistdat.distptrs[j])
;        if ptr_valid(distdat.times) eq 0 then continue
;        magf = data_cut(magname,*distdat.times)
;        if ptr_valid(distdat.magf) then *distdat.magf = magf else begin
;          (*((*dptr.mdistdat).distptrs[j])).magf = ptr_new(magf,/no_copy)
;        endelse
;     endif
;   endfor
endfor
end



function thm_sst_load_cdfivars,cdfi,thx,var
      distdat = {  $
          times: ptr_new()       ,$
          data:  ptr_new()    ,$
          magf:  ptr_new()  , $
          cnfg:  ptr_new()    ,$
          nspins:ptr_new()   , $
          atten: ptr_new()  , $
          emode: ptr_new()    ,$
          amode: ptr_new() ,   $
          dat3d: ptr_new(  ) $
       }
       vns = cdfi.vars.name
       varname = thx+'_'+var
       tptname = thx+'_p'+var
       distdat.times   = cdfi.vars[where(vns eq varname+'_time')].dataptr
       distdat.data    = cdfi.vars[where(vns eq varname)].dataptr
       distdat.nspins  = cdfi.vars[where(vns eq varname+'_nspins')].dataptr
       distdat.cnfg    = cdfi.vars[where(vns eq varname+'_config')].dataptr
       distdat.atten   = cdfi.vars[where(vns eq varname+'_atten')].dataptr
       distdat.dat3d   = ptr_new( thm_sst_dist3d_def(dformat=tptname) )
       return,distdat
end



function thm_sst_load_mergevars,var1,var2
     times = 0
     varn  = 0
     ind   = 0
     distptrs = ptr_new()
     if keyword_set(var1.times) then begin
          append_array,times,*var1.times
          append_array,varn,replicate(1,n_elements(*var1.times))
          append_array,ind,lindgen(n_elements(*var1.times))
          distptrs = [distptrs,ptr_new(var1)]
     endif
     if keyword_set(var2) && keyword_set(var2.times) then begin
          append_array,times,*var2.times
          append_array,varn,replicate(2,n_elements(*var2.times))
          append_array,ind,lindgen(n_elements(*var2.times))
          distptrs = [distptrs,ptr_new(var2)]
    endif

     s = sort(times)
     data = {times:times[s], varn:varn[s], index:ind[s], distptrs : distptrs }
     return,data
end




;pro thm_sst_load,probe=probe,type=type,all=all,files=files,trange=trange, $
;    verbose=verbose,burst=burst,probes=probes, $
;    source_options=source_options, $
;    version=ver

pro thm_sst_load,probe=probematch, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 varnames=varnames, valid_names = valid_names, files=files, $
                 source_options = source_options, $
                 progobj=progobj, varformat=varformat

if not keyword_set(source_options) then begin
   thm_init
   source_options = !themis
endif
my_themis = source_options
Result = DIALOG_MESSAGE("Test")
vb = keyword_set(verbose) ? verbose : 0
vb = vb > my_themis.verbose
dprint,dlevel=4,verbose=vb,'Start; $Id: thm_load_sst.pro 4072 2008-12-01 22:33:15Z jimm $'

vprobes = ['a','b','c','d','e'];,'f']
vlevels = ['l1','l2']
vdatatypes=['sst']

if keyword_set(valid_names) then begin
    probematch = vprobes
    level = vlevels
    datatype = vdatatypes
    return
endif

if n_elements(probematch) eq 1 then if probematch eq 'f' then vprobes = ['f']

;if not keyword_set(probematch) then probematch='*'
;probe = strfilter(vprobes, probematch ,delimiter=' ',/string)

if not keyword_set(probematch) then probematch=vprobes
probe=ssl_check_valid_name(strtrim(strlowcase(probematch),2),vprobes,/include_all)

if probe[0] eq '' then begin
  dprint, "Invalid probes selected.  Valid probes: 'a','b','c','d' or 'e'  (ie, probe='a')"
  return
end

;change Matt D. 6/29
;----------------------
vlevels_str='l1 l2'
deflevel='l1'
lvl = thm_valid_input(level,'Level',vinputs=vlevels_str,definput=deflevel,$
                        format="('l', I1)", verbose=0)

if lvl eq 'l2' then goto, LEVEL2FILELOAD
;----------------------


if not keyword_set(datatype) then datatype='*'
datatype = strfilter(vdatatypes, datatype ,delimiter=' ',/string)



addmaster=0

for s=0,n_elements(probe)-1 do begin
     thx = 'th'+ probe[s]

;     format = sc+'l1/sst/YYYY/'+sc+'_l1_sst_YYYYMMDD_v01.cdf'   ; Won't work! for sst
     relpathnames = file_dailynames(thx+'/l1/sst/',dir='YYYY/',thx+'_l1_sst_','_v01.cdf',trange=trange,addmaster=addmaster)
     files = spd_download(remote_file=relpathnames, _extra=my_themis ) ;, nowait=downloadonly)

     if keyword_set(downloadonly) or my_themis.downloadonly then continue

     cdfi = cdf_load_vars(files,/all,verbose=vb)
     if not keyword_set(cdfi) then begin
        continue
     endif

     usedptrs = ptr_new()

     psir_006  = thm_sst_load_cdfivars(cdfi,thx,'sir_006')
     psir_001  = thm_sst_load_cdfivars(cdfi,thx,'sir_001')
     data = thm_sst_load_mergevars(psir_001,psir_006)         ;     merge data:
     store_data,thx+'_psir_data',data={x:data.times, y:data.varn, mdistdat:data}
     usedptrs = [usedptrs,ptr_extract(data)]

     psif_128  = thm_sst_load_cdfivars(cdfi,thx,'sif_128')
     psif_064  = thm_sst_load_cdfivars(cdfi,thx,'sif_064')
     data = thm_sst_load_mergevars(psif_064,psif_128)         ;     merge data:
     store_data,thx+'_psif_data',data={x:data.times, y:data.varn, mdistdat:data}
     usedptrs = [usedptrs,ptr_extract(data)]

     pser_006  = thm_sst_load_cdfivars(cdfi,thx,'ser_006')
     pser_001  = thm_sst_load_cdfivars(cdfi,thx,'ser_001')
     data = thm_sst_load_mergevars(pser_001,pser_006)         ;     merge data:
     store_data,thx+'_pser_data',data={x:data.times, y:data.varn, mdistdat:data}
     usedptrs = [usedptrs,ptr_extract(data)]

     pseb_064  = thm_sst_load_cdfivars(cdfi,thx,'seb_064')
     data = thm_sst_load_mergevars(pseb_064)         ;     merge data:
     store_data,thx+'_pseb_data',data={x:data.times, y:data.varn, mdistdat:data}
     usedptrs = [usedptrs,ptr_extract(data)]

     psef_128  = thm_sst_load_cdfivars(cdfi,thx,'sef_128')
     psef_064  = thm_sst_load_cdfivars(cdfi,thx,'sef_064')
     data = thm_sst_load_mergevars(psef_064,psef_128)         ;     merge data:
     y = data.varn
     store_data,thx+'_psef_data',data={x:data.times, y:y, mdistdat:data}
     usedptrs = [usedptrs,ptr_extract(data)]


     ptr_free,ptr_extract(cdfi,except=usedptrs)

endfor


return


;change Matt D. 6/29
;----------------------

LEVEL2FILELOAD:

  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end
  if not keyword_set(suffix) then suffix = ''

  vlevels_str = 'l1 l2'
  deflevel = 'l2'
  lvl = thm_valid_input(level,'Level',vinputs=vlevels_str,definput=deflevel,$
                        format="('l', I1)", verbose=0)
  if lvl eq '' then return

  vL2datatypes='psif_en_eflux psef_en_eflux'
  datatype='*'

  thm_load_xxx,sname=probe, datatype=datatype, trange=trange, $
               level=level, verbose=verbose, downloadonly=downloadonly, $
               relpathnames_all=relpathnames_all, no_download=no_download, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               get_support_data=get_support_data, $
               varnames=varnames, valid_names = valid_names, files=files, $
               vsnames = 'a b c d e', $
               type_sname = 'probe', $
               vdatatypes = 'sst', $
               file_vdatatypes = 'sst', $
               vlevels = vlevels_str, $
               vL2datatypes = vL2datatypes, $
               vL2coord = '', $
               deflevel = deflevel, $
               version = 'v01', $
               relpath_funct = 'thm_load_sst_relpath', $
               post_process_proc=post_process_proc, $
               delete_support_data=delete_support_data, $
               proc_type=type, coord=coord, suffix=suffix, $
               progobj=progobj,$
               varformat=varformat

  ylim,'*en_eflux*',0,0,1
  zlim,'*en_eflux*',0,0,1

;----------------------


end











