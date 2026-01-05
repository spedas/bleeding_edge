;+
;
;PROCEDURE:       MEX_ASP_IMA_ENE_THETA
;
;PURPOSE:         
;                 Reads MEX/ASPERA-3 (IMA) Energy-Polar angle table.
;
;INPUTS:          time and polar angle indices.
;
;KEYWORDS:
;
;CREATED BY:      Takuya Hara on 2018-01-23.
;
;LAST MODIFICATION:
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-01-01 12:17:28 -0800 (Thu, 01 Jan 2026) $
; $LastChangedRevision: 33942 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_ima_ene_theta.pro $
;
;-
PRO mex_asp_ima_ene_theta, time, polar, opidx=opidx, energy=energy, theta=theta, enoise=enoise, verbose=verbose, fast=fast, psa=psa
  nan = !values.f_nan
  ldir = root_data_dir() + 'mex/aspera/ima/calib/'
  file_mkdir2, ldir

  ndat = N_ELEMENTS(time)

  mtime = ['2003-06-02', '2006-01', '2007-10', '2010', '2013', '2015', '2017']
  mtime = time_double(mtime)

  trange = minmax(time)
  date = time_double(time_intervals(trange=trange, /daily_res, tformat='YYYY-MM-DD'))
  phase = FIX(INTERP(FINDGEN(N_ELEMENTS(mtime)), mtime, time_double(date))) < (N_ELEMENTS(mtime)-1)
  phase = STRING(phase, '(I0)')

  w = WHERE(phase EQ '0', nw, complement=v, ncomplement=nv)
  IF nw GT 0 THEN phase[w] = ''
  IF nv GT 0 THEN phase[v] = '-EXT' + phase[v]

  IF undefined(psa) THEN pflg = 1 ELSE pflg = FIX(psa)

  IF (pflg) THEN BEGIN
     pdir = 'MEX-M-ASPERA3-2-EDR-IMA-EXT5-V1.0/' 
     rpath = 'https://archives.esac.esa.int/psa/ftp/MARS-EXPRESS/ASPERA-3/' + pdir + 'CALIB/'
  ENDIF ELSE rpath = 'https://pds-geosciences.wustl.edu/mex/mex-m-aspera3-2-edr-ima-ext7-v1/mexasp_2107/calib/'
  
  mtime = ['2003-06-02/17:45', '2007-03-21/18:20', '2007-03-21/19:21', $
           '2007-04-03/21:00', '2007-04-04/03:00', '2007-04-30/19:05', $
           '2009-10-27/15:00', '2009-10-28/15:00', '2009-11-16/11:00'];, '2013-12-16/11:00']

  mtime = time_double(mtime)
  ntime = N_ELEMENTS(mtime) + 1
  pname = STRING(INDGEN(ntime)+1, '(I0)')
  pname[-1] = '9H'

  p = FIX(INTERP(FINDGEN(N_ELEMENTS(mtime)), mtime, time_double(time))) < (N_ELEMENTS(mtime)-1)
  w = WHERE(opidx GT 63, nw)
  IF nw GT 0 THEN BEGIN
     p[w] = 9
  ENDIF 
  phase = pname[p]

  uphase = phase[UNIQ(phase, SORT(phase))]
  puniq  = p[UNIQ(p, SORT(p))]
  nphase = N_ELEMENTS(uphase)

  FOR i=0, nphase-1 DO BEGIN
     rfile = 'IMA_ENERGY' + uphase[i] + '.TAB'
     IF ~(pflg) THEN rfile = rfile.tolower()
     append_array, file, FILE_SEARCH(ldir, rfile, count=nfile)
     IF nfile EQ 0 THEN file[-1] = spd_download(remote_path=rpath, remote_file=rfile, local_path=ldir, ftp_connection_mode=1-pflg) 
     undefine, nfile
  ENDFOR 

  nenergy = 96
  nbins   = 16
  nmass   = 32
  
  etable = FLTARR(ntime, nenergy)         ; Energy Table
  ntable = FLTARR(ntime, nenergy)         ; Energy Step Noise Table
  ttable  = FLTARR(ntime, nenergy, nbins) ; Polar Angle (theta) Table
  etable[*] = nan
  ntable[*] = nan
  ttable[*] = nan
  FOR i=0, nphase-1 DO BEGIN
     dprint, dlevel=2, verbose=verbose, 'Reading ' + file[i] + '.'
     OPENR, unit, file[i], /get_lun
     data = STRARR(FILE_LINES(file[i]))
     READF, unit, data
     FREE_LUN, unit

     data = STRSPLIT(data, ' ', /extract)
     data = data.toarray()
     nene = N_ELEMENTS(data[*, 0])
     npol = N_ELEMENTS(data[0, 3:*])

     etable[puniq[i], 0:nene-1]    = TRANSPOSE(FLOAT(data[*, 1]))
     ntable[puniq[i], 0:nene-1]    = TRANSPOSE(FLOAT(data[*, 2]))
     ttable[puniq[i], 0:nene-1, 0:npol-1] = FLOAT(data[*, 3:*])
  ENDFOR 

  energy = etable[p, *]
  enoise = ntable[p, *]
  theta = energy
  theta[*] = 0.

  ttable = ttable[p, *, *]
  FOR j=0, 15 DO BEGIN
     w = WHERE(polar EQ j, nw)
     IF nw GT 0 THEN theta[w, *] = ttable[w, *, j]
     undefine, w, nw
  ENDFOR

  IF KEYWORD_SET(fast) THEN BEGIN
     energy = TRANSPOSE(TEMPORARY(energy))
     theta = TRANSPOSE(TEMPORARY(theta))
     enoise = TRANSPOSE(TEMPORARY(enoise))
  ENDIF ELSE BEGIN
     energy = REBIN(TEMPORARY(energy), ndat, nenergy, nbins, nmass, /sample)
     theta = REBIN(TEMPORARY(theta), ndat, nenergy, nbins, nmass, /sample)
     enoise = REBIN(TEMPORARY(enoise), ndat, nenergy, nbins, nmass, /sample)
     
     energy = TRANSPOSE(TEMPORARY(energy), [1, 2, 3, 0])
     theta  = TRANSPOSE(TEMPORARY(theta), [1, 2, 3, 0])
     enoise = TRANSPOSE(TEMPORARY(enoise), [1, 2, 3, 0])
  ENDELSE 
  ;;; It seems that "theta" is defined as the looking direction rather than
  ;;; the ions moving direction. Therefore, changing its sign.
  theta *= -1.
  RETURN
END
