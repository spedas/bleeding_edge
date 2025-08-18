; BEGIN gainantlib.f
;
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0XX
; |                                                                    |
; |                        Roproc_Wave                                 |
; | Modules pour utiliser la fonction complexe decrivant le gain des   |
; | antennes sous la forme gainant(f,ix,dircal,fe) exprimee en V/nT    |
; | et dependant de la frequence, de la composante, du satellite et de |
; | la frequence d'echantillonnage.                                    |
; |                                                                    |
; |            P. Robert, CNRS/CETP, Septembre 2000                    |
; |                                                                    |
; |  Modification pour compatibilite avec les donnees sol de la        |
; |  station mobile (conjugaison avec les donnees GEOS)                |
; |                                                                    |
; |            P. Robert, CNRS/CETP, Janvier 2002                      |
; |                                                                    |
; |  Revisions successives:                                            |
; |                             revu Avril   2002 (intro DSP)          |
; |                             revu Janvier 2003 (generalisation)     |
; |                             revu Juillet 2003 (Nbp quelconque)     |
; |                             revu Janvier 2004 (separation nbr/hbr) |
; |                             revu Octobre 2006 (retrait datasetlib) |
; |                                                                    |
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0XX
;
;
;
;     XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0XX
;
;


Pro thm_scm_r_califile, pathfil, ncal, freq, P
  COMPILE_OPT HIDDEN
;
;     ------------------------------------------------------------------
; *   Objet  : lecture du fichier des gains complexes
; *   Classe : traitements Roproc_Wave
; *   Auteur : P. Robert, CETP, Sept 2000
;     ------------------------------------------------------------------
;

  freq = fltarr(3, 1000)
  P = complexarr(3, 1000)
  ncal = intarr(3)
;
;
;
; *** ouverture du fichier de calibration
;
  dprint, dlevel=4,  '------------------------------------------------------------'
  dprint, dlevel=4,  'gainant:'
  dprint, dlevel=4,  'file to open :'
  dprint, dlevel=4,  pathfil
;
  If(strlen(file_search(pathfil)) eq 0) Then Begin
    dprint,  '*** gainantlib/r_califile: No calibration file'
    dprint,  pathfil
    dprint,  '*** job aborted ;'
    dprint,  '***/ THE FOLLOWING PATH MAY BE WRONG:'
    dprint,  '"',pathfil,'"'
    message, 'R_CALIFILE *** ABORTED ; BAD PATH FOR CALIFILE      ***'
    Return
  Endif

  openr, ifcal, pathfil, /get_lun
  dprint, dlevel=4,  'reading calibration file...'
;
; *** skip the header
;
  ligne = strarr(1)
  readf, ifcal, ligne
  dprint, dlevel=4,  ligne
;
  For i = 1, 18 Do readf, ifcal, ligne
;
; *   Should now be positioned just be for the first  "# This is the ..."
;
  ic = 0
;
; *** read the 3 components
;
  readf, ifcal, ligne
  if(strmid(ligne, 0, 10) ne '# This is ') then begin
    dprint,  '*** r_califile: bad file structure'
    dprint,  '***/ THE LINE', ligne
    dprint,  '***/ SHOULD BE: ''# This is the...'''
    free_lun, ifcal
    dprint,  '*** ABORTED ; BAD FILE STRUCTURE         ***'
  endif
;
  while (strmid(ligne, 0, 3) ne 'END')  do begin
;
     dprint, dlevel=4,  ligne
;
     on_ioerror, readerror
     readf, ifcal, ligne
     dprint, dlevel=4,  ligne
     readf, ifcal, ligne
     dprint, dlevel=4,  ligne
;
     ic = ic+1
     ncal[ic-1] = 0

     readf, ifcal, ligne

     while (strmid(ligne, 0, 10) ne '# This is ' && $
            strmid(ligne, 0, 3) ne 'END') do begin
        ncal[ic-1] = ncal[ic-1]+1
        i = ncal[ic-1]-1
        
        reads, ligne, rfreq, rPreal, rPimag
        freq[ic-1, i] = rfreq 
        P[ic-1, i] = complex(rPreal, rPimag)
        
        readf, ifcal, ligne
     endwhile
  endwhile

  dprint, dlevel=4,  ligne
  dprint, dlevel=4,  'calibration file is read.'
  dprint, dlevel=4,  'Number of data points: Nx,Ny,Nz=', ncal[0:ic-1]
  free_lun, ifcal
  return

  readerror: dprint,   '*** ABORTED ; Input data have a bad format ***'
  dprint,  '*** r_califile: abnormal end of file'
  dprint,  '***/ LAST LINE SHOULD BE: ''END'''
  dprint,  '***/ BUT LAST LINE IS: ', ligne
  free_lun, ifcal

end

;
;     XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0XX
;
Function thm_scm_gainant_vec, f, ix, pathfil0, fe, init=init, $
                              dfb_dig=k_dfb_dig, dfb_butter=k_butter, $
                              gainant=k_gainant
;+
;     ------------------------------------------------------------------
; *   Purpose: Return complex gain of antenna ix at frequency f from pathfil0
; *   Classe : traitements Roproc_Wave
; *   Auteur : P. Robert, CETP, Sept 2000; mod. Janv. 2002, Janv. 2004
; *   Comment: You must give the full path to the gain file.
;     ------------------------------------------------------------------
;Inputs:
;  f      array of frequencies at which antenna gain is desired.
;  ix     antenna number: 1, 2, or 3.
;  pathfil0 full path name to antenna gain file.
;  fe     sample rate (frequence d'echantillonnage)
;Keywords: 
;  init:  Initialize common block.  No gains are read or returned. 
;         Force antenna gain file to be re-read on next 
;         call.  Set gainant, dfb_dig and butter parameters for subsequent calls
;         based on keywords to init call.
;  gainant: if set when called with /init, use antenna gain from file in result
;         of subsequent calls.  Otherwise, use gain of complex(1.0, 0.0).  
;         Useful when determining antenna response from internal SCM calibration
;         signal.
;  dfb_dig: if set when called with /init, include response of the DFB digital 
;         filter in result of subsequent calls.
;  dfb_butter: if set when called with /init, include response of the DFB
;         4kHz 4-pole Butterworth analog filter in the result of subsequent 
;         calls.
;Example:
;  void = thm_scm_gainant_vec(/init, gainant=gainant, $
;                             dfb_butter=dfb_butter, dfb_dig=dfb_dig)
;  thm_scm_modpha, thm_scm_gainant_vec(fs, 1, calfile, fe), rfsx, phafsx
;
;      dimension freq(3,1000),P(3,1000),ncal(3)
;      character(len=*) :: pathfil
;      character(len=255), save :: pathfilp
;
;      save icall
;      save freq,P
;      save ncal
;
;      data icall /0/
;      data pathfilp /' '/
;Use a common for saved variables
  common gainant_private, icall, pathfilp, freq, P, ncal, gainant,dfb_dig,butter

  if keyword_set(init) then begin 
     icall = 0l
     dfb_dig = keyword_set(k_dfb_dig)
     butter = keyword_set(k_butter)
     gainant = keyword_set(k_gainant)
     return, 0
  endif
;
; *** test redibitoires
;
  if(ix lt 1 or ix gt 3) then begin 
     dprint,  '*** ABORTED ; BAD IX   ***'
     Return, -1
  endif

  iix = ix - 1  ; IDL indexes begin at 0 rather than 1

;
; *** Read the calibration file
;
  If(size(icall, /type) Eq 0) Then icall = 0l
  If(n_elements(pathfilp) Eq 0) Then pathfilp = ''
  icall = icall+1
  pathfil = strtrim(pathfil0, 2)
  if(icall eq 1 || pathfil ne pathfilp) then begin
     thm_scm_r_califile, pathfil, ncal, freq, P
     If(total(freq) Eq 0) Then return, -1
     pathfilp = pathfil
  endif


; *** take absolute value: handle negative f  
  myf = float(abs(f))

; *** test if f is greater than Nyquest frequency for fe
;
  gtny = where(myf gt fe/2.0, ngtny)
  if ngtny gt 0 then begin
     dprint,  '*** ABORTED ; F > FE/2 ***'
     return, -1
  endif

;
; *** return values for first or last frequency in table if f is out of range
;
  flow = where(myf le freq[iix, 0], nflow)
  if(nflow gt 0) then myf[flow] = freq[iix, 0]

  fmacal = freq[iix, ncal[iix]-1]
  
  fhigh = where(myf ge fmacal, nfhigh) 
  if (nfhigh gt 0) then myf[fhigh] = fmacal
     

  if(fe gt 2.0*fmacal) then begin
     dprint,  '***/ FE=', fe
     dprint,  '***/ FMAX IN TABLE =', fmacal
     dprint,  '    impossible ;'
     dprint,  'premature termination'
     dprint,  'GAINANT *** ABORTED ; FE > FMAX CAL              ***'
     return, -1
  endif

;
; *** Interpolation based on table of frequency 
;
  if gainant then begin 
     dprint, dlevel=4,  '*** antenna freq. response'
     s = interpol(P[iix,0:ncal[iix]-1],freq[iix,0:ncal[iix]-1],myf)
     take_conj = where(f lt 0, n_take_conj)
     if n_take_conj gt 0 then s[take_conj] = conj(s[take_conj])
  endif else s = complexarr(n_elements(f)) + complex(1.0, 0.0)

  if dfb_dig then begin
     dprint, dlevel=4,  '*** DFB Digital Filter Freq. response'
     s *= abs(thm_dfb_dig_filter_resp(f, fe))
  endif
  
  if butter then begin
     dprint, dlevel=4,  '*** DFB Butterworth Filter Freq. response'
     s *= butterworth_filter_resp(f, 4096.0, 4)
  endif

  return, s
end
; END gainantlib.f
