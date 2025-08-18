;+
;
;FUNCTION:        SPICE_MK_READ
;
;PURPOSE:         Reads the meta-kernel file.
;
;INPUTS:          The file name of the SPICE meta-kernel (mk).
;
;OUTPUTS:         Returns the string array of file names of SPICE/kernels to be loaded.
;                 
;KEYWORDS:
;
;    REMOTE:      Specifies the remote server path.
;
;    TRANGE:      Returns the time range in which they likely cover, 
;                 inferred from the file name.
;
;   TFORMAT:      Default is 'YYYYMMDD'.
;
;      LAST:      Default is 1. Loads the latest version.
;
;    SOURCE:      Provides a structure that contains information
;                 pertinent to the location (and downloading) of SPICE data files.
;
; NO_SERVER:      If set, not to download from the remote server.
;                 Synonym for "no_download".
;
;CREATED BY:      Takuya Hara on 2022-06-16.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2023-06-09 15:27:54 -0700 (Fri, 09 Jun 2023) $
; $LastChangedRevision: 31892 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_mk_read.pro $
;
;-
FUNCTION spice_mk_read, file, local_data_dir=lpath, remote_data_dir=rpath, verbose=verbose, kernels_trange=trange, tformat=tformat, $
                        last_version=last_version, source=source, no_download=no_download, no_server=noserver, success=success

  success = 1
  version = !version.release
  IF FLOAT(version) LT 8.4 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'It cannot use on the IDL version older than 8.4.'
     success = 0
     RETURN, ''
  ENDIF 

  naif = spice_file_source(last_version=last_version)
  IF undefined(source) THEN source = naif
  IF KEYWORD_SET(no_download) OR KEYWORD_SET(no_server) THEN source.no_server = 1
  IF ~undefined(lpath) THEN source.local_data_dir = lpath
  
  IF ~undefined(rpath) THEN BEGIN
     source.remote_data_dir = rpath

     mk = spd_download_plus(remote_file=file, remote_path=source.remote_data_dir, local_path=source.local_data_dir, $
                            last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
  ENDIF ELSE mk = source.local_data_dir + file

  IF FILE_TEST(mk[0]) THEN BEGIN
     OPENR, unit, mk[0], /get_lun
     kernels = STRARR(FILE_LINES(mk[0]))
     READF, unit, kernels
     FREE_LUN, unit

     w = WHERE(kernels.contains('$KERNELS') EQ 1, nfile)
     IF nfile GT 0 THEN kernels = kernels[w]
     kernels = kernels.compress()
     kernels = kernels.extract("'+[[:alnum:][:punct:]]+'")
     kernels = kernels.substring(1, -2)

     IF undefined(rpath) THEN path = ((mk[0]).split('mk/'))[0] $
     ELSE path = source.remote_data_dir + (file.split('mk/'))[0]

     kernels = kernels.replace('$KERNELS/', path)
  ENDIF 

  IF undefined(tformat) THEN tformat = 'YYYYMMDD'
  trange = ORDEREDHASH()

  FOR i=0, nfile-1 DO BEGIN
     fname = FILE_BASENAME(kernels[i])
     fname = (fname.split('[.]'))[0] ; Removing the extension.
     fname = STRSPLIT(fname, '_', /extract)

     w = WHERE((fname.matches('^ *-?[0-9]+ *$') EQ 1) AND (fname.strlen() EQ tformat.strlen()), nw)
     IF nw GT 0 THEN BEGIN
        times = time_double(fname[w], tformat=tformat)
        v = WHERE(times GT 0., nv)
        IF nv GT 0 THEN trange[i] = TEMPORARY(times[v])
     ENDIF 
  ENDFOR 

  RETURN, kernels
END
