;+
; PROCEDURE:
;       kgy_file_retrieve
; PURPOSE:
;       Retrieve data and label files
; CALLING SEQUENCE:
;       files = kgy_file_retrieve('pbf/LEVEL1_VER1_DB/YYYYMMDD/PBF1_C_YYYYMMDD_*_I.DAT*',/daily_names,/valid_only,/last_version)
; INPUTS:
;       PUBLIC: use publicly available data
;       pathnames: String or string array with partial path to the remote file.
;       (will be appended to local_data_dir)
; KEYWORDS:
;       DAILY_NAMES : resolution (in days) for generating file names.
;                     YYYY, yy, MM, DD,  hh,  mm, ss, .f, DOY, DOW, TDIFF are special characters that will be substituted with the appropriate date/time field
;                     Be especially careful of extensions that begin with '.f' since these will be translated into a fractional second.
;                     See "time_string"  TFORMAT keyword for more info.
;       TRANGE : two element vector containing start and end times (UNIX_TIME or UT string).  if not present then timerange() is called to obtain the limits.
;       SOURCE:  alternate file source.   Default is whatever is return by the function:  ppi_file_source()    (see "ppi_file_source" for more info)
;       FILES:  if provided these will be passed through as output.
;       VALID_ONLY:  Set to 1 to prevent non existent files from being returned.
;       CREATE_DIR:  Generates a filename and creates the directories needed to create the file without errors.  Will not check for file on remote server.
;
; KEYWORDS Passed on to "FILE_RETRIEVE":
;       LAST_VERSION : [0,1]  if set then only the last matching file is returned.  (Default is 1)
;       VALID_ONLY:  [0,1]   If set then only existing files are returned. (Default is defined by source keyword)
;       VERBOSE:  set verbosity level (2 is typical)
; LIMITATIONS:
;       Beware of file pathnames that include the character sequences: YY,  MM, DD, hh, mm, ss, .f  since these can be retranslated to the time
; CREATED BY:
;       Yuki Harada on 2015-07-05
;       Mostly copied from 'mvn_pfp_file_retrieve'
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-10-07 11:58:34 -0700 (Fri, 07 Oct 2016) $
; $LastChangedRevision: 22067 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/general/kgy_file_retrieve.pro $
;-

function kgy_file_retrieve,pathname,trange=trange,verbose=verbose,source=src,files=files,last_version=last_version,valid_only=valid_only,no_update=no_update,create_dir=create_dir,daily_names=daily_names,hourly_names=hourly_names,resolution=res,shiftres=shiftres,no_server=no_server,no_download=no_download,_extra=_extra,public=public,skipoddhours=skipoddhours, datasuf=datasuf

tstart = systime(1)

if keyword_set(public) then daily_names = 1

if not keyword_set(shiftres) then shiftres =0
if keyword_set(daily_names) then begin 
   res = round(24*3600L * daily_names)
   sres= round(24*3600L * shiftres)
endif

if keyword_set(hourly_names) then begin
   res = round(3600L * hourly_names)
   sres= round(3600L * shiftres)
endif

source = kgy_file_source(src,verbose=verbose,public=public,no_server=no_server,valid_only=valid_only,last_version=last_version,no_update=no_update,_extra=_extra)

dprint,dlevel=5,verbose=verbose,phelp=1,source   ; display the options

if ~keyword_set(files) then begin

   if keyword_set(res) then begin
      tr = timerange(trange)
      str = (tr-sres)/res
      dtr = (ceil(str[1]) - floor(str[0]) )  > 1 ; must have at least one file
      times = res * (floor(str[0]) + lindgen(dtr))+sres
      pathnames = time_string(times,tformat=pathname)
      pathnames = pathnames[uniq(pathnames)] ; Remove duplicate filenames - assumes they are sorted

      if keyword_set(skipoddhours) then begin
         hh = long(time_string(times,tf='hh'))
         w = where( ~(hh mod 2) , nw ) ;- only even hours
         if nw gt 0 then pathnames = pathnames[w]
      endif

      ;;; get public data from the Kaguya data archive
      if keyword_set(public) then begin
         if ~keyword_set(datasuf) then datasuf = ['.dat','.gz','','.cdf']
         suf = '.dat'
         dirs = source.local_data_dir+time_string(times,tf='YYYY/MM/')
         file_mkdir2,dirs,_extra=source
         for i=0,n_elements(pathnames)-1 do begin
            f = ''
            for isuf=0,n_elements(datasuf)-1 do f = [f,file_search(dirs[i]+pathnames[i]+datasuf[isuf])] ;- search existing data files
            if total(strlen(f)) eq 0 then begin ;- don't check updates, TBD
               outtar = dirs[i]+'out.tar'
               if file_test(outtar) then file_delete,outtar ;- delete old temp file, if exists

               ;;; download files using IDLnetURL (IDL 6.4+)
               ourl = OBJ_NEW('IDLnetUrl')
               proxy = getenv('http_proxy')
               if proxy ne '' then begin
                  pp = parse_url(proxy)
                  ourl->setproperty,proxy_hostname=pp.host,proxy_prot=pp.port
               endif
               s = execute('out = ourl->get(filename=outtar,url=source.remote_data_dir+pathnames[i])')
               if s then dprint,'downloaded '+out+' for '+pathnames[i]
               obj_destroy,ourl

               ;;; untar files
               if file_test(outtar) then begin
                  if tag_exist(source,'file_mode') then file_chmod,outtar,source.file_mode
                  if float(!version.release) ge 8.3 then begin
                     dprint,'file_untar '+outtar
                     s = execute('file_untar,outtar,dirs[i]')
                  endif else begin
                     untarcmd = 'tar xvf '+outtar+' -C '+dirs[i] ;- doesn't work in Windows?
                     dprint,'untar cmd: '+untarcmd
                     s = execute('spawn,untarcmd')
                  endelse
                  outfiles = file_search(dirs[i]+pathnames[i]+'*')
                  if ~s then dprint,'untar failed: '+outtar
                  if s then if tag_exist(source,'file_mode') and total(file_test(outfiles)) then file_chmod,outfiles,source.file_mode
                  file_delete,outtar
               endif
            endif
            for isuf=0,n_elements(datasuf)-1 do begin
               f = file_search(dirs[i]+pathnames[i]+datasuf[isuf])
               if total(strlen(f)) gt 0 then suf = datasuf[isuf]
            endfor
         endfor
         pathnames = time_string(times,tf='YYYY/MM/') + pathnames + suf
         source.no_server = 1
      endif

   endif else  pathnames = pathname

   if keyword_set(create_dir) then begin
      files = source.local_data_dir + pathnames
      file_mkdir2,file_dirname( files ),_extra=source
      return,files
   endif

   files = file_retrieve(pathnames,_extra=source)
   dprint,dlevel=4,verbose=verbose,systime(1)-tstart,' seconds to retrieve ',n_elements(files),' files'

endif
return,files


end
