;Procedure: THM_LOAD_SST
;
;Purpose:  Loads THEMIS SST data
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
;Notes:
; Written by Davin Larson, Dec 2006
; Updated to use thm_load_xxx by KRB, 2007-2-5
; Update removed to not use thm_load_xxx by DEL
;
; $LastChangedBy:davin-win $
; $LastChangedDate:2007-06-29 13:02:49 -0700 (Fri, 29 Jun 2007) $
; $LastChangedRevision:946 $
; $URL:svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/themis/spacecraft/particles/SST/thm_load_sst_old.pro $
;-
pro thm_load_sst_old,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data, $
                 varnames=varnames, valid_names = valid_names, files=files, $
                 progobj=progobj

thm_init

vb = keyword_set(verbose) ? verbose : 0
vb = vb > !themis.verbose

vprobes = ['a','b','c','d','e'];,'f']
vlevels = ['l1','l2']
vdatatypes=['sst']

if keyword_set(valid_names) then begin
    probe = vprobes
    level = vlevels
    datatype = vdatatypes
    return
endif

if not keyword_set(probe) then probe='*'
probe = strfilter(vprobes, probe ,delimiter=' ',/string)

if not keyword_set(datatype) then datatype='*'
datatype = strfilter(vdatatypes, datatype ,delimiter=' ',/string)

if not keyword_set(level) then level='*'
level = strfilter(vdatatypes, level ,delimiter=' ',/string)

addmaster=0

for s=0,n_elements(probe)-1 do begin
     sc = 'th'+ probe[s]

     if vb ge 4 then print,ptrace(),'pathformat: ',pathformat

;     format = sc+'l1/sst/YYYY/'+sc+'_l1_sst_YYYYMMDD_v01.cdf'   ; Won't work!
     relpathnames = file_dailynames(sc+'/l1/sst/',dir='YYYY/',sc+'_l1_sst_','_v01.cdf',trange=trange,addmaster=addmaster)
     files = spd_download(remote_file=relpathnames, _extra=!themis, progobj = progobj)

     if vb ge 4 then print,ptrace(),'files: ',files

     if keyword_set(downloadonly) then continue

     if arg_present(cdf_data) then begin
        cdf_data = cdf_load_vars(files,varnames=varnames,verbose=vb,/all)
        return
     endif

     suf='_raw'
     cdf2tplot,file=files,all=all,suffix=suf,verbose=vb,  $     ; load data into tplot variables
        get_support_data=get_support_data,varnames=varnames,tplotnames=tplotnames


     options,tplotnames,/default,code_id='$Id: $',/no_interp
     specs = '*064_raw *001_raw'
     ylim,specs,0,17
     zlim,specs,1,1,1
;     options,tplotnames,

     for i=0,n_elements(tplotnames)-1 do begin
        options,tplotnames[i],/default,ytitle=strjoin(strsplit(tplotnames[i],'_',/extract),'!c')
     endfor



endfor

end








;
;
;thm_init
;
;vb = keyword_set(verbose) ? verbose : 0
;
;
;sst_valid_names = [ 'sst' ]
;if arg_present( valid_names) then begin
;  valid_names = sst_valid_names
;  message, /info, string( strjoin( sst_valid_names, ','), format = '( "Valid names:",X,A,".")')
;  return
;endif
;
;if not keyword_set(scs) then scs = ['a','b','c','d','e']
;
;for s=0,n_elements(scs)-1 do begin
;     sc = 'th'+scs[s]
;;     format = sc+'l1/sst/YYYY/'+sc+'_l1_sst_YYYYMMDD_v01.cdf'   ; Won't work!
;     relpathnames = file_dailynames(sc+'/l1/sst/',dir='YYYY/',sc+'_l1_sst_','_v01.cdf',trange=trange,/addmaster)
;     if vb ge 4 then print,rname,'relpath=',transpose(relpathnames)
;     files = file_retrieve(relpathnames, _extra=!themis )
;     if keyword_set(downloadonly) then continue
;     cdf2tplot,file=files,all=all,verbose=verbose ,get_support=get_support    ; load data into tplot variables
;
;endfor
;
;end
