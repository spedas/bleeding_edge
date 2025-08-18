;+
;
; PROCEDURE: rbsp_load_rbspice
;
; PURPOSE:  Loads RBSP RBSPICE data.
;
; KEYWORDS:
;     probe:              RBSP spacecraft indicator [Options: 'a' (default), 'b']
;     trange:             (Optional) Time range of interest  (2 element array); if not set, the default is to prompt the user
;     datatype:           RBSPICE data type ['EBR','ESRHELT','ESRLEHT','IBR','ISBR','ISRHELT','TOFxEH' (default),'TOFxEIon','TOFxEnonH','TOFxPHHHELT','TOFxPHHLEHT'],
;                         but change for different data levels.
;     level:              data level ['l1','l2','l3' (default),'l3pap']
;     downloadonly:       download file but don't read it or load tplot variables
;     get_support_data:   when set this routine will load any support data;
;                         support data (such as energy range, PA range, etc.) is specified in the CDF file
;     time_clip:          clip the data to the requested time range; note that if you
;                         do not use this keyword, you may load a longer time range than requested
;     varformat:          should be a string (wildcards accepted) that will match the CDF variables
;                         that should be loaded into tplot variables
;     files:              named varible for output of pathnames of local files
;     verbose:            set to enable useful outputs for debugging
;
;
; EXAMPLE:
;
;		   rbsp_load_rbspice, probe='b', level='l3', datatype='TOFxEH', trange=['2015-10-01/12:00','2015-10-01/18:00'], /time_clip, /get_support_data
;
; REVISION HISTORY:
;     + ?,?                         : Original from rbsp_load_emfisis.pro
;     + 2013-03, K. Min             : ?
;     + 2014-04, K. Keika           : ?
;     + 2016-12-08, I. Cohen        :defined L3 and L3PAP datatypes; added trange to rbsp_load_rbspice_read call; added omni-directional calculation and spin-averaging through calls to separate routines
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-03 08:56:11 -0800 (Fri, 03 Mar 2017) $
;$LastChangedRevision: 22905 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/rbspice/rbsp_load_rbspice.pro $
;-

pro rbsp_load_rbspice,probe=probe, trange=trange, datatype=datatype, $
    level=level, downloadonly=downloadonly, get_support_data=get_support_data, $
    time_clip = time_clip, varformat=varformat, files=files, verbose=verbose

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Initialize RBSPICE SPEDAS environment
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  rbsp_rbspice_init 
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Define valid keyword options
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  vb = keyword_set(verbose) ? verbose : 0
  vb = vb > !rbsp_rbspice.verbose
  
  ; Valid names
  vprobe = ['a','b']
  vlevels = ['l1','l2','l3','l4']
  vdatatypesl1 = ['TOFxEH','TOFxEnonH','TOFxPHHHELT']
  vdatatypesl2 = ['TOFxEH','TOFxEnonH','TOFxPHHHELT']
  vdatatypesl3 = ['TOFxEH','TOFxEnonH','TOFxPHHHELT']
  vdatatypesl3pap = [''] ; L3PAP data is not yet supported
  vdatatypesl4 = [''] ; L4 data is not yet supported
  
  vdatatypes = [vdatatypesl1,vdatatypesl2,vdatatypesl3,vdatatypesl3pap,vdatatypesl4]
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Set the default keyword values
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  if undefined(probe) then probe = 'a'
  if undefined(datatype) then datatype = 'TOFxEH'
  if undefined(level) then level = 'l3'
  if undefined(varformat) and undefined(get_support_data) then get_support_data = 1 ; turn on support data by default, need the spin variable for spin averaging
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Level-dependent process. Result is saved into LEV_STR struct
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  lev_str = -1
  case level of
  'l1':begin
      str_element,lev_str,'level','1',/add
      str_element,lev_str,'datatypes',strfilter(vdatatypesl1, datatype ,delimiter=' ',/string,/FOLD_CASE),/add
      end
  'l2':begin
      str_element,lev_str,'level','2',/add
      str_element,lev_str,'datatypes',strfilter(vdatatypesl2, datatype ,delimiter=' ',/string,/FOLD_CASE),/add
      end
  'l3':begin
      str_element,lev_str,'level','3',/add
      str_element,lev_str,'datatypes',strfilter(vdatatypesl3, datatype ,delimiter=' ',/string,/FOLD_CASE),/add
      end
  'l3pap':begin
      str_element,lev_str,'level','3pap',/add
      str_element,lev_str,'datatypes',strfilter(vdatatypesl3pap, datatype ,delimiter=' ',/string,/FOLD_CASE),/add
      end
  ;'l4':begin
  ;    str_element,lev_str,'level','4',/add
  ;    str_element,lev_str,'datatypes',strfilter(vdatatypesl4, datatype ,delimiter=' ',/string,/FOLD_CASE),/add
  ;    end
  else: begin
      message,'Invalid data level selected',/continue
      return
      end
  endcase
  str_element,lev_str,'probe',probe,/add
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Iteration through all combinations
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  addmaster=0
  probe_colors = ['m','b']
  ; --> ATTENTION
  ; RBSPICE data URL is unusual. There should be a better way to deal with this.
  rbsp_rbspice_local = !rbsp_rbspice
  rootformatv = strsplit(rbsp_rbspice_local.remote_data_dir,'?',/extract,/preserve_null)
  localformatv = strsplit(rbsp_rbspice_local.local_data_dir,'?',/extract,/preserve_null)
  ; <--

  ; Probe iteration
  for iprobe=0,n_elements(lev_str.probe)-1 do begin ; Loop probe
      rx = lev_str.probe[iprobe] ; either a or b
      rbspx = 'rbsp'+rx

      ; Datatype iteration
      for idtype=0,n_elements(lev_str.datatypes)-1 do begin ; Loop datatypes
          dtype = lev_str.datatypes[idtype]
          if dtype eq '' then continue

          ;Set the filename template
          filename = 'rbsp-'+rx+'-rbspice_lev-'+lev_str.level+'_'+dtype+'_YYYYMMDD_v*.cdf'
          parent = 'Level_'+lev_str.level+'/'+dtype+'/YYYY'
          pathformat = parent+'/'+filename
          ;print,pathformat
  
          ; --> ATTENTION
          ; RBSPICE data URL is unusual. There should be a better way to deal with this.
          rbsp_rbspice_local.remote_data_dir = strjoin( rootformatv,rx )
          rbsp_rbspice_local.local_data_dir = strjoin( localformatv,rx )
          ; <--
  
          ; Take advantage of TDAS data management system
          relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)
          ;     if vb ge 4 then printdat,/pgmtrace,relpathnames
          dprint,dlevel=3,verbose=verbose,relpathnames,/phelp
          
          files = spd_download(remote_file=relpathnames, remote_path=rbsp_rbspice_local.remote_data_dir, $
            local_path = rbsp_rbspice_local.local_data_dir)
            
          ;printdat,files
          
          ; Check if DOWNLOADONLY is set
          if keyword_set(!rbsp_rbspice.downloadonly) or keyword_set(downloadonly) then continue
          
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          ; From here, retrieve data from CDF and preprocess them appropriately
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          
          ; TPLOT name pattern
          suffix=''
          prefix = rbspx + '_rbspice_l'+lev_str.level+'_'+dtype+'_'
  
          ; MMS version of cdf2tplot is required
          mms_cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suffix,verbose=vb, $
              tplotnames=tns,/convert_int1_to_int2,get_support_data=get_support_data ; load data into tplot variables
          
          if (keyword_set(trange) && n_elements(trange) eq 2) then tr = timerange(trange) else tr = timerange()
          tplotnames = tnames(prefix+'*')
  
          ; time clip the data
          if ~undefined(tr) && ~undefined(tplotnames) then begin
            if (n_elements(tr) eq 2) and (tplotnames[0] ne '') and ~undefined(time_clip) then begin
              time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
            endif
          endif
          ; Add energy channel energy values to primary data variable, create variables for individual telescopes, and set appropriate tplot options
          rbsp_load_rbspice_read, level=level, probe=probe, datatype=dtype, trange=trange

          ; Calculate omni-directional variable
          rbsp_rbspice_omni, probe=probe, datatype=dtype, tplotnames = tplotnames, level=level

          ; Calculate spin-averaged variable
          rbsp_rbspice_spin_avg, probe=probe, datatype = datatype, tplotnames = tplotnames, level=level
  
      endfor ; End datatypes
  endfor ; End probe
  
end
