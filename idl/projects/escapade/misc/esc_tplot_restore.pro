;+
;
;PROCEDURE:       ESC_TPLOT_RESTORE
;
;PURPOSE:         Restores tplot data, limits, name handles, options, and settings.
;                 All usage is basically idential to the original 'tplot_restore';
;                 however, it can process much faster than when tplot_restore, /append. 
;
;INPUTS:          
;KEYWORDS:
;
; FILENAMES:      File name or array of filenames to create.
;                 If no file name is chosen and "all" keyword is not set,
;                 it will look for and restore a file called saved.tplot.
;
;       ALL:      Restores all *.tplot files in the current directory (or directory specified by "directory" keyword).
;
; DIRECTORY:      Specifies a directory other than the currecnt working dir for loading all tplot files.
;
;    APPEND:      Append saved data to existing tplot variables.
;
;      SORT:      Sort data by time after loading in.
;
; GET_TVARS:      Load tplot_vars structure (the structure containing tplot options and settings
;                 even if such a structure already exists in the current session.
;                 The default is to only load these if no such structure currently exists in the session.
;
; RESTORED_VARNAME: Returns the tplot variable names for the restored data.
;
;TPLOT_NAME:      IF the (array of) tplot name(s) is set, it can only restore the user specified tplot(s).
;
;CREATED BY:      Takuya Hara (ESCAPADE-SDOC) on 2024-05-08.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2024-11-20 15:29:23 -0800 (Wed, 20 Nov 2024) $
; $LastChangedRevision: 32971 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/misc/esc_tplot_restore.pro $
;
;-
PRO esc_tplot_restore, filenames=filenames, all=all, append=append, sort=sort,$
                       get_tvars=get_tvars, verbose=verbose, restored_varnames=restored_varnames, $
                       directory=directory, tplot_name=tplot_name, misc=mflg

  COMPILE_OPT IDL2
  @tplot_com.pro

  tplot_quant__define
  IF KEYWORD_SET(directory) AND ~KEYWORD_SET(all) THEN BEGIN
     dprint, dlevel=0, 'Warning: directory keyword only used when /all keyword set'
  ENDIF
  IF KEYWORD_SET(directory) THEN BEGIN
     ; First check for a slash
     n = N_ELEMENTS(directory)
     IF (n EQ 0) THEN dirslash = '/' ELSE BEGIN
        dirslash = directory
        FOR j=0, n-1 DO BEGIN
           temp_string = STRTRIM(directory[j], 2)
           ll = STRMID(temp_string, STRLEN(temp_string)-1, 1)
           IF (ll NE '/' AND ll NE '\') THEN temp_string = temp_string + '/'
           dirslash[j] = TEMPORARY(temp_string)
        ENDFOR 
     ENDELSE
     restore_dir = dirslash
  ENDIF ELSE restore_dir = ''

  IF KEYWORD_SET(all) THEN filenames = FILE_SEARCH(restore_dir + '*.tplot')
  IF SIZE(/type, filenames) NE 7 THEN filenames = 'saved.tplot'
  IF undefined(mflg) THEN mflg = 0
  
  n = N_ELEMENTS(filenames)
  restored_varnames = ''
  FOR i=0L, n[0]-1L DO BEGIN
     fi = FILE_INFO(filenames[i])
     IF fi.exists EQ 0 THEN BEGIN
        dprint, dlevel=1, 'File ' + filenames[i] + ' Does not exist! Skipping.'
        CONTINUE
     ENDIF
     dprint, dlevel=2, 'Restoring tplot file ' + file_info_string(filenames[i])
     RESTORE, filenames[i], /relaxed

     IF KEYWORD_SET(tv) THEN BEGIN
        chkverb = WHERE(TAG_NAMES(tv.options) EQ 'VERBOSE', verbosethere)
        IF NOT verbosethere THEN BEGIN
           optstruct = tv.options
           setstruct = tv.settings
           newopt = CREATE_STRUCT(optstruct, 'VERBOSE', 0)
           tv = 0
           tv = {options: newopt, settings: setstruct}
           optstruct = 0
           setstruct = 0
           newopt = 0
        ENDIF 
     ENDIF 

     IF (N_ELEMENTS(tplot_vars) EQ 0) OR KEYWORD_SET(get_tvars) THEN $
        IF KEYWORD_SET(tv) THEN tplot_vars = tv

     IF KEYWORD_SET(dq) THEN BEGIN
        IF ~undefined(tplot_name) THEN BEGIN
           FOR j=0L, N_ELEMENTS(tplot_name)-1L DO append_array, index, TRANSPOSE((dq.name).matches(tplot_name[j]))
           index = TOTAL(index, 1)
           w = WHERE(TEMPORARY(index) GT 0, nw)
           IF nw GT 0 THEN dq = dq[w]
        ENDIF 

        FOR j=0L, N_ELEMENTS(dq.name)-1L DO BEGIN
           thisdq = dq[j]
           dprint, dlevel=3, 'The tplot variable ' + thisdq.name + ' is being restored.'
           restored_varnames = [restored_varnames, thisdq.name]

           names = STRSPLIT(thisdq.name, '.')

           IF KEYWORD_SET(append) THEN BEGIN
              get_data, thisdq.name, ptr=olddata
              IF is_struct(olddata) && (~PTR_VALID(olddata.x) || ~PTR_VALID(olddata.y)) THEN BEGIN
                 dprint, dlevel=1, 'Invalid pointer to existing tplot variable (' + thisdq.name + '); Skipping...'
                 CONTINUE
              ENDIF 
           ENDIF 

           IF KEYWORD_SET(append) AND is_struct(olddata) THEN BEGIN ; olddata needs to be a structure, jmm, 2021-10-19
              IF undefined(nan) THEN IF SIZE(*olddata.y, /type) EQ 5 THEN nan = !values.d_nan ELSE nan = !values.f_nan
              IF KEYWORD_SET(*thisdq.dh) THEN BEGIN
                 IF thisdq.dtype EQ 1 THEN BEGIN
                    IF PTR_VALID((*thisdq.dh).y) THEN BEGIN
                       ; check y dimensions prior to appending, jmm, 2019-11-22
                       n1 = SIZE(*olddata.y, /n_dimen)
                       n2 = SIZE(*(*thisdq.dh).y, /n_dimen)
                       s1 = SIZE(*olddata.y, /dimen)
                       s2 = SIZE(*(*thisdq.dh).y, /dimen)
                       IF N_ELEMENTS(s1) EQ 2 THEN s12 = s1[1] > s2[1]
                       IF (n1 NE n2) || (N_ELEMENTS(s1) GT 2 && ~ARRAY_EQUAL(s1[1:*], s2[1:*])) THEN BEGIN
                          dprint, dlevel=1, 'Variable '+ thisdq.name + ' Y size mismatch; not appended'
                          CONTINUE
                       ENDIF 

                       IF tag_exist(olddata, 'tplot_restore', /quiet) THEN newy = (*olddata.tplot_restore).y ELSE newy = PTR_NEW(list())
                       IF N_ELEMENTS(s1) EQ 2 && s1[1] NE s2[1] THEN BEGIN
                          dprint, dlevel=3, 'Variable ' + thisdq.name + ' Y size mismatch; matching sizes!'
                          oldy = REPLICATE(nan, [s1[0], s12])
                          nevy = REPLICATE(nan, [s2[0], s12])
                          oldy[*, 0:s1[1]-1] = *olddata.y
                          nevy[*, 0:s2[1]-1] = *(*thisdq.dh).y

                          IF N_ELEMENTS(*newy) EQ 0 THEN (*newy).add, oldy $
                          ELSE BEGIN
                             (*newy)[-1] = TEMPORARY(oldy)
                             FOR k=0, N_ELEMENTS(*newy)-2 DO BEGIN
                                oldy = REPLICATE(nan, dimen1((*newy)[k]), s12)
                                oldy[*, 0:dimen2((*newy)[k])-1] = (*newy)[k]
                                (*newy)[k] = TEMPORARY(oldy)
                             ENDFOR 
                          ENDELSE 
                          (*newy).add, nevy
                       ENDIF ELSE BEGIN
                          IF N_ELEMENTS(*newy) EQ 0 THEN (*newy).add, *olddata.y
                          (*newy).add, *(*thisdq.dh).y
                       ENDELSE 
                    ENDIF ELSE (*newy).add, *olddata.y

                    olddy = PTR_NEW()
                    str_element, olddata, 'dy', olddy
                    IF PTR_VALID(olddy) THEN BEGIN
                       n1 = SIZE(*olddata.dy, /n_dimen)
                       n2 = SIZE(*(*thisdq.dh).dy, /n_dimen)
                       s1 = SIZE(*olddata.dy, /dimen)
                       s2 = SIZE(*(*thisdq.dh).dy, /dimen)
                       IF N_ELEMENTS(s1) EQ 2 THEN s12 = s1[1] > s2[1]
                       IF (n1 NE n2) || (N_ELEMENTS(s1) GT 2 && ~ARRAY_EQUAL(s1[1:*], s2[1:*])) THEN BEGIN
                          dprint, dlevel=1, 'Variable ' + thisdq.name + ' DY size mismatch; not appended'
                          CONTINUE
                       ENDIF 

                       IF tag_exist(olddata, 'tplot_restore', /quiet) THEN newdy = (*olddata.tplot_restore).dy ELSE newdy = PTR_NEW(list())

                       IF N_ELEMENTS(s1) EQ 2 && s1[1] NE s2[1] THEN BEGIN
                          dprint, dlevel=3, 'Variable ' + thisdq.name + ' DY size mismatch; matching sizes!'
                          olddy = REPLICATE(nan, [s1[0], s12])
                          nevdy = REPLICATE(nan, [s2[0], s12])
                          olddy[*, 0:s1[1]-1] = *olddata.dy
                          nevdy[*, 0:s2[1]-1] = *(*thisdq.dh).dy

                          IF N_ELEMENTS(*newdy) EQ 0 THEN (*newdy).add, olddy $
                          ELSE BEGIN
                             (*newdy)[-1] = TEMPORARY(olddy)
                             FOR k=0, N_ELEMENTS(*newdy)-2 DO BEGIN
                                olddy = REPLICATE(nan, dimen1((*newdy)[k]), s12)
                                olddy[*, 0:dimen2((*newdy)[k])-1] = (*newdy)[k]
                                (*newdy)[k] = TEMPORARY(olddy)
                             ENDFOR
                          ENDELSE
                          (*newdy).add, nevdy
                       ENDIF ELSE BEGIN
                          IF N_ELEMENTS(*newdy) EQ 0 THEN (*newdy).add, *olddata.dy
                          (*newdy).add, *(*thisdq.dh).dy
                       ENDELSE
                    ENDIF 

                    IF tag_exist(olddata, 'tplot_restore', /quiet) THEN newx = (*olddata.tplot_restore).x ELSE newx = PTR_NEW(list())              
                    IF PTR_VALID((*thisdq.dh).x) THEN BEGIN
                       IF N_ELEMENTS(*newx) EQ 0 THEN *newx.add, *olddata.x
                       *newx.add, *(*thisdq.dh).x
                    ENDIF ELSE *newx.add, *olddata.x

                    oldv = PTR_NEW()
                    str_element, olddata, 'v', oldv
                    IF PTR_VALID(oldv) THEN BEGIN
                       ;;  V tag is present
                       IF tag_exist(olddata, 'tplot_restore', /quiet) THEN newv = (*olddata.tplot_restore).v ELSE newv = PTR_NEW(list())
                       IF ndimen(*oldv) EQ 1 THEN BEGIN
                          ;;  1D --> no need to append
                          IF ~ARRAY_EQUAL(oldv, (*thisdq.dh).v) THEN BEGIN
                             oldw = REPLICATE(nan, [s1[0], s12])
                             nevv = REPLICATE(nan, [s2[0], s12])
                             oldw[*, 0:s1[1]-1] = REPLICATE(1., s1[0]) # (*oldv)
                             IF ndimen(*(*thisdq.dh).v) EQ 1 THEN *(*thisdq.dh).v = REPLICATE(1., s2[0]) # (*(*thisdq.dh).v)
                             nevv[*, 0:s2[1]-1] = *(*thisdq.dh).v
                             IF N_ELEMENTS(*newv) EQ 0 THEN (*newv).add, oldw
                             (*newv).add, nevv                    
                          ENDIF ELSE *newv[-1] = *oldv
                       ENDIF ELSE BEGIN
                          ;;  2D --> need to append (if present)
                          IF (struct_value((*thisdq.dh), 'v')) THEN BEGIN
                             ;;  present --> append
                             IF ndimen(*(*thisdq.dh).v) EQ 1 THEN *(*thisdq.dh).v = REPLICATE(1., s2[0]) # (*(*thisdq.dh).v)
                             IF s1[1] NE s2[1] THEN BEGIN
                                oldw = REPLICATE(nan, [s1[0], s12])
                                nevv = REPLICATE(nan, [s2[0], s12])
                                oldw[*, 0:s1[1]-1] = *oldv
                                nevv[*, 0:s2[1]-1] = *(*thisdq.dh).v

                                IF N_ELEMENTS(*newv) EQ 0 THEN (*newv).add, oldw $
                                ELSE BEGIN
                                   (*newv)[-1] = TEMPORARY(oldw)
                                   FOR k=0, N_ELEMENTS(*newv)-2 DO BEGIN
                                      oldw = REPLICATE(nan, dimen1((*newv)[k]), s12)
                                      oldw[*, 0:dimen2((*newv)[k])-1] = (*newv)[k]
                                      (*newv)[k] = TEMPORARY(oldw)
                                   ENDFOR
                                ENDELSE
                                (*newv).add, nevv
                             ENDIF ELSE BEGIN
                                IF N_ELEMENTS(*newv) EQ 0 THEN (*newv).add, *oldv
                                (*newv).add, *(*thisdq.dh).v                    
                             ENDELSE 
                          ENDIF ELSE BEGIN
                             ;;  not present --> replicate old to make dimensions correct???
                             szdox = SIZE(*olddata.x, /dimensions)
                             szdnx = SIZE(*newx, /dimensions)
                             szdo  = SIZE(*oldv, /dimensions)
                             dumb  = MAKE_ARRAY(szdnx[0], szdo[1], type=SIZE(*oldv, /type))
                             avgo  = TOTAL(*oldv, 1, /nan) / TOTAL(FINITE(*oldv), 1, /nan)
                             dumb[0L:(szdox[0] - 1L), *] = *oldv
                             FOR kk=0L, szdo[1]-1L DO dumb[szdox[0]:(szdnx[0]-1L), kk] = avgo[kk]
                             (*newv)[-1] = dumb
                          ENDELSE
                       ENDELSE

                       IF (struct_value((*thisdq.dh), 'v')) THEN PTR_FREE, (*thisdq.dh).v
                       newdata = {x: TEMPORARY(newx), y: TEMPORARY(newy), v: TEMPORARY(newv)}
                       IF ~undefined(newdy) THEN str_element, newdata, 'dy', TEMPORARY(newdy), /add
                    ENDIF ELSE BEGIN
                    ;;  V tag is not present --> Only X and Y tags should be present
                       newdata = {x: TEMPORARY(newx), y: TEMPORARY(newy)}
                       IF ~undefined(newdy) THEN str_element, newdata, 'dy', TEMPORARY(newdy), /add
                    ENDELSE 

                    IF (mflg) THEN BEGIN
                       extract_tags, misc, olddata, except=['x', 'y', 'v', 'dy', 'tplot_restore']
                       w = WHERE( ~(TAG_NAMES(misc)).contains('_IND'), nw)
                       IF nw GT 0 THEN BEGIN
                          dattags = TAG_NAMES(misc)
                          dattags = dattags[w]
                          FOR k=0, N_ELEMENTS(dattags)-1 DO BEGIN
                             IF tag_exist(olddata, 'tplot_restore', /quiet) THEN str_element, (*olddata.tplot_restore), dattags[k], newm ELSE newm = PTR_NEW(list())
                             str_element, olddata, dattags[k], oldm
                             str_element, (*thisdq.dh), dattags[k], thim

                             IF s1[1] NE s2[1] THEN BEGIN
                                IF (*oldm).tname EQ 'DOUBLE' THEN nans = !values.d_nan ELSE nans = !values.f_nan
                                toldm = REPLICATE(nans, [s1[0], s12])
                                tthim = REPLICATE(nans, [s2[0], s12])
                                toldm[*, 0:s1[1]-1] = *oldm
                                tthim[*, 0:s2[1]-1] = *thim
                                *oldm = TEMPORARY(toldm)
                                *thim = TEMPORARY(tthim)
                                IF N_ELEMENTS(*newm) EQ 0 THEN (*newm).add, TEMPORARY(*oldm) $
                                ELSE BEGIN
                                   (*newm)[-1] = TEMPORARY(*oldm)
                                   FOR kk=0, N_ELEMENTS(*newm)-2 DO BEGIN
                                      oldm = REPLICATE(nans, dimen1((*newm)[kk]), s12)
                                      oldm[*, 0:dimen2((*newm)[kk])-1] = (*newm)[kk]
                                      (*newm)[kk] = TEMPORARY(oldm)
                                   ENDFOR
                                ENDELSE
                                (*newm).add, TEMPORARY(*thim)
                             ENDIF ELSE BEGIN
                                IF N_ELEMENTS(*newm) EQ 0 THEN (*newm).add, TEMPORARY(*oldm)
                                (*newm).add, TEMPORARY(*thim)
                             ENDELSE 
                             str_element, newdata, dattags[k], TEMPORARY(newm), /add
                          ENDFOR
                       ENDIF
                       misc = 0
                    ENDIF

                    olddata = 0
                 ENDIF ELSE BEGIN
                    ; I expect that this section is obsolete... (T. Hara)
                    newdata = olddata
                    dattags = TAG_NAMES(olddata)
                    FOR k=0, N_ELEMENTS(dattags)-1 DO BEGIN
                       str_element, *thisdq.dh, dattags[k], foo
                       foo = *foo
                       str_element, newdata, dattags[k], [*olddata[k], foo], /add
                    ENDFOR
                 ENDELSE 

                 dattags = TAG_NAMES(newdata)
                 IF i NE n[0]-1L THEN BEGIN
                    str_element, newdata, 'tplot_restore', newdata, /add
                    FOR k=0, N_ELEMENTS(dattags)-1 DO str_element, newdata, dattags[k], PTR_NEW((*newdata.(k))[-1]), /add_replace
                 ENDIF ELSE FOR k=0, N_ELEMENTS(dattags)-1 DO str_element, newdata, dattags[k], PTR_NEW((*newdata.(k)).toarray(/dim)), /add_replace

                 store_data, verbose=verbose, thisdq.name, data=TEMPORARY(newdata)
              ENDIF
           ENDIF ELSE BEGIN
              store_data, verbose=verbose, thisdq.name, data=*thisdq.dh, limit=*thisdq.lh, dlimit=*thisdq.dl, /nostrsw
              dprint, dlevel=3, 'The tplot variable ' + thisdq.name + ' has been restored.'
           ENDELSE 
           IF KEYWORD_SET(sort) THEN tplot_sort, thisdq.name
        ENDFOR 
        PTR_FREE, dq.dh, dq.dl, dq.lh
     ENDIF 
     dq = 0
     tv = 0
  ENDFOR

  IF (N_ELEMENTS(restored_varnames) GT 1) THEN restored_varnames = restored_varnames[1:*]

  RETURN
END 
