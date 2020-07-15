;+
;Procedure: thm_load_sst2
;
;Purpose:  Loads THEMIS SST data
;
;WARNING: This routine is under development as part of the SST calibration process. Use at your own risk!
;
;
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, for this case, there is only
;          one option, the default value of 'sst', so this is a
;          placeholder should there be more that one data type. 'all'
;          can be passed in also, to get all variables.
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;Example:
;   thg_load_sst,/get_suppport_data,probe=['a', 'b']
;   
;Notes:
;  
;  Many of the standard keywords only work with L2 data.
;
;  When L1 data is loaded it is merged into a data structures stored
;  in tplot variables named: th?_ps??_data.
;  
;  These structures have the form:
;   X               DOUBLE    Array[27797]
;   Y               INT       Array[27797]
;   MDISTDAT        STRUCT    -> <Anonymous> Array[1]
;   
;   X is the time array for the data
;   Y is the index to the distribution type that is valid at each time.
;   D.Y will index MDISTDAT.DISTPTRS, although not all distptrs are guaranteed to be valid.(ie Not all distributions will be used in a given data set) 
;   
;  This modification replaces use of data_cache and common blocks for passing sst data between routines.   
;   
;Major Revisions:
; Written by Davin Larson, Dec 2006
; Updated to use thm_load_xxx by KRB, 2007-2-5
; Update removed to not use thm_load_xxx by DEL
; Updated to use new code from Davin by pcruce Jun 2010
; 
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2020-07-14 10:56:48 -0700 (Tue, 14 Jul 2020) $
; $LastChangedRevision: 28887 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_load_sst2.pro $
;-

;;This routine takes one tplot_data name and generates a count rate variable from it.  This is useful as measure of SST saturation and is used to create a data quality flag
pro thm_load_sst2_count_rate,tplotname,suffix
 
   if tnames(tplotname) eq '' then return
   
   ;get a stem to construct the name of output tvar
   if strlen(tplotname) le 8 then return
   
   stem = strmid(tplotname,0,8)
   species = strmid(stem,7,1)
  
   get_data,tplotname,data=d
   
   if ~is_struct(d) then return
  
   count_dat = dblarr(n_elements(d.x))
   ones = dblarr(n_elements(d.x))+1
   md = d.mdistdat
   
   for i = 0,n_elements(md.distptrs)-1 do begin
   
     if ~ptr_valid(md.distptrs[i]) then continue
   
     idx = where(md.varn eq i,c)
     
     if c eq 0 then continue
     
     data = thm_part_decomp16(*(*md.distptrs[i]).data)
     data_dim = dimen(data)
     integ_t = (*(*d.mdistdat.distptrs[i]).dat3d).integ_t

     if n_elements(data_dim) eq 2 then begin ;only one angle
       counts = total(data[*,0:11],2)/integ_t[0]
       count_dat[idx] = counts
     endif else begin ;3 dims, assumed
       integ_t = reform(integ_t[0,*]) 
       counts = total(data[*,0:11,*],2)/(ones[idx]#integ_t)
       count_dat[idx] = max(counts,dim=2)
     endelse
   endfor
  
   out_name = stem+'_count_rate'+suffix
   store_data,out_name,data={x:d.x,y:count_dat}
   options,out_name,yrange=[0,5e4] 
  
end

pro thm_load_sst2_mag,tplotnames,magname_format   ;,probe=probe,dist_name=dist_name,magname_format=magname_format

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

function thm_load_sst2_relpath, sname=probe, filetype=ft, $
                               level=lvl, trange=trange, $
                               addmaster=addmaster, _extra=_extra

  relpath = 'th'+probe+'/'+lvl+'/'+ ft+'/'
  prefix = 'th'+probe+'_'+lvl+'_'+ft+'_'
  dir = 'YYYY/'
  ending = '_v01.cdf'

  return, file_dailynames(relpath, prefix, ending, dir=dir, $
                          trange = trange,addmaster=addmaster)
end

pro thm_load_sst2_extra,tplotnames

if not keyword_set(tplotnames) then tplotnames= 'th?_ps??_data'

tpnames = tnames(tplotnames,n)
for i=0,n-1 do begin
    format = strmid(tpnames[i],0,8)
    dprint,dlevel=3,'Getting ATTEN for: ',format
    times = thm_part_dist2(format,/times)
    n = n_elements(times)
    att = intarr(n)
    rate = fltarr(n)
    for j=0l,n-1 do begin
       dat = thm_part_dist2(format,index=j)
       rdat = conv_units(dat,'rate')
       rate[j] = total(rdat.data)
       att[j] = dat.atten
       dprint,dwait=5,j,n
    endfor
    store_data,format+'_rate',data={x:times,y:rate},dlim={ylog:1}
    store_data,format+'_atten',data={x:times,y:att},dlim={tplot_routine:'bitplot',colors:'rgrgrgrg',yrange:[-1,4]}
endfor
end

pro thm_load_sst2_atten2,tplotnames

if not keyword_set(tplotnames) then tplotnames= 'th?_ps??_data'

tpnames = tnames(tplotnames,n)
for i=0,n-1 do begin
    format = strmid(tpnames[i],0,8)
    dprint,dlevel=3,'Getting ATTEN for: ',format
    times = thm_part_dist2(format,/times)
    n = n_elements(times)
    att = intarr(n)
    for j=0l,n-1 do begin
       dat = thm_part_dist2(format,index=j)
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



function thm_load_sst2_cdfivars,cdfi,thx,var
      distdat = {  $
          times: ptr_new(),$
          data:  ptr_new(),$
          magf:  ptr_new(), $
          cnfg:  ptr_new(),$
          nspins:ptr_new(), $
          edphi: ptr_new(), $
          atten: ptr_new(), $
          emode: ptr_new(),$
          amode: ptr_new(),   $
          dat3d: ptr_new(), $
          cal_params:ptr_new() $
       }
       
       vns = cdfi.vars.name
       varname = thx+'_'+var
       tptname = thx+'_p'+var
       
       distdat.times   = cdfi.vars[where(vns eq varname+'_time')].dataptr
       distdat.data    = cdfi.vars[where(vns eq varname)].dataptr
       distdat.nspins  = cdfi.vars[where(vns eq varname+'_nspins')].dataptr
       distdat.cnfg    = cdfi.vars[where(vns eq varname+'_config')].dataptr
       distdat.atten   = cdfi.vars[where(vns eq varname+'_atten')].dataptr
       distdat.dat3d   = ptr_new( thm_sst_dist3d_def2(dformat=tptname) )
       distdat.cal_params  = ptr_new( thm_sst_read_calib_params(thx,strlowcase(strmid(var,1,1)),'f'))
   
       return,distdat
end


function thm_load_sst2_mergevars,var1,var2
     times = 0
     varn  = 0
     ind   = 0
     distptrs = ptr_new()
     if keyword_set(var1.times) then begin
          append_array,times,*var1.times
          append_array,varn,replicate(1,n_elements(*var1.times))
          append_array,ind,lindgen(n_elements(*var1.times))
          distptrs = [distptrs,ptr_new(var1)]
     endif else begin
         distptrs = [distptrs,ptr_new()]
     endelse
     
     if keyword_set(var2) && keyword_set(var2.times) then begin
          append_array,times,*var2.times
          append_array,varn,replicate(2,n_elements(*var2.times))
          append_array,ind,lindgen(n_elements(*var2.times))
          distptrs = [distptrs,ptr_new(var2)]
     endif
     if ~keyword_set(times) then return,0
     s = sort(times)
     data = {times:times[s], varn:varn[s], index:ind[s], distptrs : distptrs }
     return,{x:data.times, y:data.varn, mdistdat:data}
end

;logic to clip data after merge was unreliable, replaced with a version that does clipping prior to merge
;mutates parent structure
pro thm_load_sst2_time_clip,distdat,tr=tr

  if ~keyword_set(tr) then return
  if ~ptr_valid(distdat.times) then return
  
  index=where(*distdat.times ge tr[0] and *distdat.times lt tr[1],c)
  if c eq 0 then begin
    distdat.times=ptr_new()
    distdat.data=ptr_new()
    distdat.nspins=ptr_new()
    distdat.cnfg=ptr_new()
    distdat.atten=ptr_new()
  endif else begin
    *distdat.times=(*distdat.times)[index]
    
    if ndimen(*distdat.data) eq 1 then begin
      *distdat.data=(*distdat.data)[index]
    endif else if ndimen(*distdat.data) eq 2 then begin
      *distdat.data=(*distdat.data)[index,*]
    endif else begin ;assumes only other valid dimensionality is 3
      *distdat.data=(*distdat.data)[index,*,*]
    endelse 
    
    *distdat.nspins  = (*distdat.nspins)[index]
    *distdat.cnfg    = (*distdat.cnfg)[index]
    *distdat.atten   = (*distdat.atten)[index]
  endelse

end

pro thm_load_sst2,probe=probematch, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 varnames=varnames, valid_names = valid_names, files=files, $
                 source_options = source_options, $
                 progobj=progobj, varformat=varformat,$
                 use_eclipse_corrections=use_eclipse_corrections, $
                 suffix=suffix,$ ;suffix keyword only works for L2 data
                 no_time_clip=no_time_clip
                 


if not keyword_set(source_options) then begin
   thm_init
   source_options = !themis
endif
my_themis = source_options

vb = keyword_set(verbose) ? verbose : 0
vb = vb > my_themis.verbose
dprint,dlevel=4,verbose=vb,'Start; $Id: thm_load_sst2.pro 28887 2020-07-14 17:56:48Z jimm $'

vprobes = ['a','b','c','d','e'];,'f']
vlevels = ['l1','l2']
vdatatypes=['psif','psef','psib','pseb','psir','pser']

support_suffix = '_sst_part_tmp'

if keyword_set(valid_names) then begin
    probematch = vprobes
    level = vlevels
    datatype = vdatatypes
    return
endif

if ~keyword_set(suffix) then begin
  suffix = ''
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

vlevels_str='l1 l2'
deflevel='l1'
lvl = thm_valid_input(level,'Level',vinputs=vlevels_str,definput=deflevel,$
                        format="('l', I1)", verbose=0)

if lvl ne 'l2' then begin
;----------------------

  if not keyword_set(datatype) then datatype='*'
  ;prevent any accidental mutation in the parent
  datatype_cpy = strfilter(vdatatypes, datatype ,delimiter=' ',/string) 
  
  addmaster=0
  for s=0,n_elements(probe)-1 do begin
  
       tn_pre_proc = tnames(create_time=cn_pre_proc)
       
       thx = 'th'+ probe[s]
  
  ;     format = sc+'l1/sst/YYYY/'+sc+'_l1_sst_YYYYMMDD_v01.cdf'   ; Won't work! for sst
       relpathnames = file_dailynames(thx+'/l1/sst/',dir='YYYY/',thx+'_l1_sst_','_v01.cdf',trange=trange,addmaster=addmaster)
       files = spd_download(remote_file=relpathnames, _extra=my_themis ) ;, nowait=downloadonly)
  
       if keyword_set(downloadonly) or my_themis.downloadonly then continue
  
       cdfi = cdf_load_vars(files,/all,verbose=vb)
       if not keyword_set(cdfi) then begin
          continue
       endif
  
     ; determine clipping range   
     if ~keyword_set(no_time_clip) then begin
       If (keyword_set(trange) && n_elements(trange) Eq 2) then begin
         tr = timerange(trange) 
       endif else begin
         tr = timerange()
       endelse
     endif

     ; Load support data and initialize spin model
     thm_load_state, probe=probe[s], trange=tr, suffix=support_suffix, $
                  /get_support_data
  
     usedptrs = ptr_new()
     
     ; ensure eclipse corrections flag is set when storing state of last load
     eclipse = undefined(use_eclipse_corrections) ? 0:use_eclipse_corrections
     
     if in_set(datatype_cpy,'psir') then begin
       psir_006  = thm_load_sst2_cdfivars(cdfi,thx,'sir_006')
       thm_load_sst2_time_clip,psir_006,tr=tr
       thm_sst_add_spindata2, psir_006, use_eclipse_corrections=use_eclipse_corrections
       
       psir_001  = thm_load_sst2_cdfivars(cdfi,thx,'sir_001')
       thm_load_sst2_time_clip,psir_001,tr=tr
       thm_sst_add_spindata2, psir_001, use_eclipse_corrections=use_eclipse_corrections
       
       data = thm_load_sst2_mergevars(psir_001,psir_006)         ;     merge data:
       store_data,thx+'_psir_data',data=data   ;{x:data.times, y:data.varn, mdistdat:data}
       usedptrs = [usedptrs,ptr_extract(data)]
       
       ;set time range - use requested range regardless of clipping
       thm_part_trange, probe, 'psir', set={trange:timerange(trange),eclipse:eclipse}, /sst_cal
     endif

     if in_set(datatype_cpy,'psif') then begin

       psif_128  = thm_load_sst2_cdfivars(cdfi,thx,'sif_128')
       if ptr_valid(psif_128.times) then begin
         dprint,'Found unexpected 128 angle data for PSIF.  Data is being discarded.',dlevel=-5
         psif_128.times = ptr_new()
       endif
       thm_load_sst2_time_clip,psif_128,tr=tr
       thm_sst_add_spindata2, psif_128, use_eclipse_corrections=use_eclipse_corrections
     
       psif_064  = thm_load_sst2_cdfivars(cdfi,thx,'sif_064')
       if ~is_struct(*psif_064.dat3d) then begin
         dprint,'Error loading sst struct.  Please see error log.',dlevel=0
         return
       endif
       thm_load_sst2_time_clip,psif_064,tr=tr
       thm_sst_add_spindata2, psif_064, use_eclipse_corrections=use_eclipse_corrections
       
       data = thm_load_sst2_mergevars(psif_064,psif_128)         ;     merge data:
       store_data,thx+'_psif_data',data=data  ;{x:data.times, y:data.varn, mdistdat:data}
       usedptrs = [usedptrs,ptr_extract(data)]
       
       ;set time range - use requested range regardless of clipping
       thm_part_trange, probe, 'psif', set={trange:timerange(trange),eclipse:eclipse}, /sst_cal
     endif

     if in_set(datatype_cpy,'pser') then begin

       pser_006  = thm_load_sst2_cdfivars(cdfi,thx,'ser_006')
       thm_load_sst2_time_clip,pser_006,tr=tr
       thm_sst_add_spindata2, pser_006, use_eclipse_corrections=use_eclipse_corrections
       
       pser_001  = thm_load_sst2_cdfivars(cdfi,thx,'ser_001')
       thm_load_sst2_time_clip,pser_001,tr=tr
       thm_sst_add_spindata2, pser_001, use_eclipse_corrections=use_eclipse_corrections
       
       data = thm_load_sst2_mergevars(pser_001,pser_006)         ;     merge data:
       store_data,thx+'_pser_data',data=data  ;{x:data.times, y:data.varn, mdistdat:data}
       usedptrs = [usedptrs,ptr_extract(data)]
       
       ;set time range - use requested range regardless of clipping
       thm_part_trange, probe, 'pser', set={trange:timerange(trange),eclipse:eclipse}, /sst_cal
     endif

     if in_set(datatype_cpy,'pseb') then begin

       pseb_064  = thm_load_sst2_cdfivars(cdfi,thx,'seb_064')            ;bp
       if ~is_struct(*pseb_064.dat3d) then begin
         dprint,'Error loading sst struct.  Please see error log.',dlevel=0
         return
       endif
       thm_load_sst2_time_clip,pseb_064,tr=tr 
       thm_sst_add_spindata2, pseb_064, use_eclipse_corrections=use_eclipse_corrections
       data = thm_load_sst2_mergevars(pseb_064)         ;     merge data:
       store_data,thx+'_pseb_data',data=data  ;{x:data.times, y:data.varn, mdistdat:data}
       usedptrs = [usedptrs,ptr_extract(data)]
       
       ;set time range - use requested range regardless of clipping
       thm_part_trange, probe, 'pseb', set={trange:timerange(trange),eclipse:eclipse}, /sst_cal
     endif
     
     if in_set(datatype_cpy,'psef') then begin 

       psef_128  = thm_load_sst2_cdfivars(cdfi,thx,'sef_128')
       if ptr_valid(psef_128.times) then begin
         dprint,'Found unexpected 128 angle data for PSEF.  Data is being discarded.',dlevel=-5
         psef_128.times = ptr_new()
       endif
       thm_load_sst2_time_clip,psef_128,tr=tr
       thm_sst_add_spindata2, psef_128, use_eclipse_corrections=use_eclipse_corrections
        
       psef_064  = thm_load_sst2_cdfivars(cdfi,thx,'sef_064')
       if ~is_struct(*psef_064.dat3d) then begin
         dprint,'Error loading sst struct.  Please see error log.',dlevel=0
         return
       endif
       thm_load_sst2_time_clip,psef_064,tr=tr
       thm_sst_add_spindata2, psef_064, use_eclipse_corrections=use_eclipse_corrections
       
       data = thm_load_sst2_mergevars(psef_064,psef_128)         ;     merge data:
       store_data,thx+'_psef_data',data=data  ;{x:data.times, y:y, mdistdat:data}
       usedptrs = [usedptrs,ptr_extract(data)]
       
       ;set time range - use requested range regardless of clipping
       thm_part_trange, probe, 'psef', set={trange:timerange(trange),eclipse:eclipse}, /sst_cal
     endif

     ptr_free,ptr_extract(cdfi,except=usedptrs)
     
     ;remove temporary state variables
     store_data, '*' + support_suffix, /delete
     
     ;determine new or modified tplot variables
     spd_ui_cleanup_tplot,tn_pre_proc,create=cn_pre_proc,new=tplotnames
           
     ;clip new variables and generate rate variable
     for i = 0, n_elements(tplotnames)-1 do begin
       if tnames(tplotnames[i]) eq '' then continue
       thm_load_sst2_count_rate,tplotnames[i],suffix
     endfor
  
  endfor
  
endif else begin

  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end

  vlevels_str = 'l1 l2'
  deflevel = 'l2'
  lvl = thm_valid_input(level,'Level',vinputs=vlevels_str,definput=deflevel,$
                        format="('l', I1)", verbose=0)
  if lvl eq '' then return

  vL2datatypes='psif_en_eflux psef_en_eflux'
  datatype='*'

  thm_load_xxx,sname=probematch, datatype=datatype, trange=trange, $
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
               relpath_funct = 'thm_load_sst2_relpath', $
               post_process_proc=post_process_proc, $
               delete_support_data=delete_support_data, $
               proc_type=type, coord=coord, suffix=suffix, $
               progobj=progobj,$
               varformat=varformat,$
               no_time_clip=no_time_clip

  ylim,'*en_eflux*',0,0,1
  zlim,'*en_eflux*',0,0,1


;----------------------

endelse

 ;free any dangling pointers
 if double(!version.release) lt 8.0d then heap_gc

end











