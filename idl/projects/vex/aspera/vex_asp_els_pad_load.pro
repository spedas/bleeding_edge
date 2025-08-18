;+
;
;PROCEDURE:       VEX_ASP_ELS_PAD_LOAD
;
;PURPOSE:         Loads VEX/ASPERA-4/ELS Pitch angle distribution (PAD) data.
;
;INPUTS:          Time range to be loaded.
;
;KEYWORDS:
;
;     FILES:      Returns the array of file to be downloaded.
;
;      PATH:      Specifies the local path to load the data.
;
; NO_SERVER:      If set, only loading the local files.
;
;      SAVE:      If set, creating the CDF files.
;
;       CDF:      If set, loading the CDF files if available.
;
;      DATA:      Returns the loaded data.
;
;     TPLOT:      If set, creating tplot variables.
;
;       ELO:      Specifies the lower energy range to be used.
;                 Default is 30 < E (eV) < 50.
;
;       EHI:      Specifies the higher energy range to be used.
;                 Default is 100 < E (eV) < 300.
;
;      TAVG:      Specifies the time width to be averaged. Default is 32 sec.
;
;    MEDIAN:      If set, median is used to normalize the PAD data.
;
;  FILL_NAN:      Specifies the lowest quantity below which will be regarded as NAN.
;
;CREATED BY:      Takuya Hara on 2025-05-31.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2025-06-05 15:52:18 -0700 (Thu, 05 Jun 2025) $
; $LastChangedRevision: 33371 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_els_pad_load.pro $
;
;-
PRO vex_asp_els_pad_cdf, pad, trange=trange, file=file, path=path, verbose=verbose, save=save
  prefix = 'YYYY/MM/vex_asp_els_pad_YYYYMMDD'
  dnan = !values.d_nan
  nan  = !values.f_nan
  
  IF KEYWORD_SET(save) THEN BEGIN
     gatt = ORDEREDHASH()
     gatt['title']           = 'VEx ASPERA-4/ELS PAD data'
     gatt['project']         = 'VEx>Venus Express'
     gatt['discipline']      = 'Planetary Physics>Planetary Plasma Interactions'
     gatt['source_name']     = 'VEx>Venus Express'
     gatt['descriptor']      = 'ASPERA-4/ELS>Analyzer of Space Plasmas and Energetic Atmos - version 4/Electron Spectrometer'
     gatt['data_version']    = '00'
     gatt['logical_file_id'] = ' '
     gatt['logical_source']  = ' '
     gatt['logical_source_description'] = 'VEx ASPERA-4/ELS Pitch Angle Distributions'
     gatt['data_type']       = 'CAL>Calibrated'
     gatt['text']            = 'VEx ASPERA-4/ELS Pitch Angle Distributions'
     gatt['instrument_type'] = 'Plasma and Solar Wind'
     gatt['parents']         =  FILE_BASENAME(file)
     gatt['mission_group']   = 'VEx'
     gatt['pi_name']         = 'Shaosui Xu'
     gatt['pi_affiliation']  = 'UC Berkeley Space Sciences Laboratory'
     gatt['generated_by']    = 'Takuya Hara'
     gatt = gatt.tostruct()     

     pa = [5.:175:10.]
     unit = 's^3/(m^6 . sr)'
     fname = 'VExELSPADRG_YYYYDOY_Data.csv'

     st = pad.time()
     et = pad.end_time()
     dt = et - st

     mode = pad.mode()
     w = WHERE(mode EQ 0, nw)
     IF nw GT 0 THEN BEGIN
        time0 = st[w]
        delt0 = dt[w]
        data0 = TRANSPOSE(pad.data(w), [0, 2, 1])
        engy0 = pad.energy(w)
        engy0 = REFORM(engy0[0, *])

        store_data, 'pad0', data={x: time0, y: data0, v1: pa, v2: engy0}
        store_data, 'dt0', data={x: time0, y: delt0}

        tplot_add_cdf_structure, 'pad0'
        get_data, 'pad0', limits=s
        cdfi = s.cdf
        
        vars = cdfi.vars
        yatt = *vars.attrptr
        yatt.catdesc    = 'Array of Electrons pitch angle distribution (Mode = 0; 127 steps)' 
        yatt.fieldnam   =  yatt.catdesc
        yatt.units      =  unit
        yatt.fillval    = -3.4e38
        yatt.depend_0   = 'time0'
        yatt.depend_1   = 'pitch_angle'
        yatt.depend_2   = 'energy0'
        vars.attrptr    =  PTR_NEW(yatt)

        d0   = cdfi.depend_0
        d1   = cdfi.depend_1
        d2   = cdfi.depend_2

        d0.name           = 'time0'
        xatt = *d0.attrptr
        xatt.catdesc      = 'Array of Time (Mode = 0; 127 steps)'
        xatt.fieldnam     =  xatt.catdesc
        xatt.display_type = 'time_series'
        xatt.lablaxis     = 'Time'
        d0.attrptr        =  PTR_NEW(xatt)

        d1.name         = 'pitch_angle'
        v1att           = *d1.attrptr
        v1att.catdesc   = 'Pitch Angle'
        v1att.fieldnam  =  v1att.catdesc
        v1att.units     = 'degree'
        v1att.lablaxis  = 'deg'
        d1.attrptr      =  PTR_NEW(v1att)

        d2.name         = 'energy0'
        v2att           = *d2.attrptr
        v2att.catdesc   = 'Energy (Mode = 0; 127 steps)'
        v2att.fieldnam  =  v2att.catdesc
        v2att.units     = 'eV'
        v2att.lablaxis  = 'eV'
        d2.attrptr      =  PTR_NEW(v2att)

        cdfi = {vars: TEMPORARY(vars), depend_0: TEMPORARY(d0), depend_1: TEMPORARY(d1), depend_2: TEMPORARY(d2)}
        
        options, 'pad0', 'cdf', TEMPORARY(cdfi)
        append_array, tname, 'pad0'

        tplot_add_cdf_structure, 'dt0'
        get_data, 'dt0', limits=s
        cdfi = s.cdf
        vars = cdfi.vars
        yatt = *vars.attrptr
        yatt.catdesc    = 'Array of Observational duration (Mode = 0; 127 steps)'
        yatt.fieldnam   =  yatt.catdesc
        yatt.units      = 'sec'
        yatt.depend_0   = 'time0'
        vars.attrptr    =  PTR_NEW(yatt)
        cdfi.vars = TEMPORARY(vars)
        options, 'dt0', 'cdf', TEMPORARY(cdfi)
        append_array, tname, 'dt0'
     ENDIF
     undefine, w

     w = WHERE(mode EQ 1, nw)
     IF nw GT 0 THEN BEGIN
        time1 = st[w]
        delt1 = dt[w]
        data1 = TRANSPOSE(pad.data(w), [0, 2, 1])
        engy1 = pad.energy(w)
        engy1 = REFORM(engy1[0, *])

        store_data, 'pad1', data={x: time1, y: data1, v1: pa, v2: engy1}
        store_data, 'dt1', data={x: time1, y: delt1}

        tplot_add_cdf_structure, 'pad1'
        get_data, 'pad1', limits=s
        cdfi = s.cdf

        vars = cdfi.vars
        yatt = *vars.attrptr
        yatt.catdesc    = 'Array of Electrons pitch angle distribution (Mode = 1; 31 steps)'
        yatt.fieldnam   =  yatt.catdesc
        yatt.units      =  unit
        yatt.fillval    = -3.4e38
        yatt.depend_0   = 'time1'
        yatt.depend_1   = 'pitch_angle'
        yatt.depend_2   = 'energy1'
        vars.attrptr    =  PTR_NEW(yatt)

        d0   = cdfi.depend_0
        d1   = cdfi.depend_1
        d2   = cdfi.depend_2

        d0.name           = 'time1'
        xatt = *d0.attrptr
        xatt.catdesc      = 'Array of Time (Mode = 1; 31 steps)'
        xatt.fieldnam     =  xatt.catdesc
        xatt.display_type = 'time_series'
        xatt.lablaxis     = 'Time'
        d0.attrptr        =  PTR_NEW(xatt)

        d1.name         = 'pitch_angle'
        v1att           = *d1.attrptr
        v1att.catdesc   = 'Pitch Angle'
        v1att.fieldnam  =  v1att.catdesc
        v1att.units     = 'degree'
        v1att.lablaxis  = 'deg'
        d1.attrptr      =  PTR_NEW(v1att)

        d2.name         = 'energy1'
        v2att           = *d2.attrptr
        v2att.catdesc   = 'Energy (Mode = 1; 31 steps)'
        v2att.fieldnam  =  v2att.catdesc
        v2att.units     = 'eV'
        v2att.lablaxis  = 'eV'
        d2.attrptr      =  PTR_NEW(v2att)

        cdfi = {vars: TEMPORARY(vars), depend_0: TEMPORARY(d0), depend_1: TEMPORARY(d1), depend_2: TEMPORARY(d2)}

        options, 'pad1', 'cdf', TEMPORARY(cdfi)
        append_array, tname, 'pad1'

        tplot_add_cdf_structure, 'dt1'
        get_data, 'dt1', limits=s
        cdfi = s.cdf
        vars = cdfi.vars
        yatt = *vars.attrptr
        yatt.catdesc    = 'Array of Observational duration (Mode = 1; 31 steps)'
        yatt.fieldnam   =  yatt.catdesc
        yatt.units      = 'sec'
        yatt.depend_0   = 'time1'
        vars.attrptr    =  PTR_NEW(yatt)
        cdfi.vars = TEMPORARY(vars)
        options, 'dt1', 'cdf', TEMPORARY(cdfi)
        append_array, tname, 'dt1'
     ENDIF
     undefine, w

     w = WHERE(mode EQ 2, nw)
     IF nw GT 0 THEN BEGIN
        dprint, dlevel=2, verbose=verbose, 'Mode = 2 is appeared!'
        stop
     ENDIF
     undefine, w
     
     date = time_double(file, tformat=fname)
     cfile = path + 'cdf/' + time_string(date, tformat=prefix) + '.cdf'
     gatt.logical_file_id = FILE_BASENAME(cfile)
     ;undefine, pad

     file_mkdir2, FILE_DIRNAME(cfile)
     tplot2cdf, filename=TEMPORARY(cfile), compress=5, default=0, tvars=TEMPORARY(tname), g_attributes=gatt
     store_data, '*', /delete
  ENDIF ELSE BEGIN
     src = mvn_file_source()
     src.local_data_dir = path
     files = mvn_pfp_file_retrieve('cdf/' + prefix + '.cdf', trange=trange, /daily_names, /no_server, source=src, /valid_only)

     w = WHERE(files NE '', nfile)
     IF nfile GT 0 THEN files = files[w]
     
     IF nfile GT 0 THEN BEGIN
        cdfi = cdf_load_vars(files, /all)
        tags = cdfi.vars.name

        data = LIST()
        FOR i=0, 2 DO BEGIN
           w = strfilter(tags, 'pad' + roundst(i), /index)
           IF w GT 0 THEN BEGIN
              tdat = *cdfi.vars[w].dataptr
              ndat = dimen1(tdat)
              e = strfilter(tags, 'energy' + roundst(i), /index)
              ene = *cdfi.vars[e].dataptr
              dat = REPLICATE({time: dnan, end_time: dnan, data: REPLICATE(nan, [N_ELEMENTS(ene), 18]), energy: TEMPORARY(ene), mode: i}, ndat)
              
              t = strfilter(tags, (*(cdfi.vars[w].attrptr)).depend_0, /index)
              dat.time = time_double(*cdfi.vars[t].dataptr, /epoch)
              t = strfilter(tags, 'dt' + roundst(i), /index)
              dat.end_time = dat.time + *cdfi.vars[t].dataptr
              dat.data = TRANSPOSE(TEMPORARY(tdat))

              append_array, time, dat.time
              data.add, TEMPORARY(dat), /extract
           ENDIF
        ENDFOR
        t = SORT(time)
        pad = vex_asp_els_pad(data[t])
     ENDIF 
  ENDELSE
  RETURN
END 

PRO vex_asp_els_pad_load, itime, files=files, path=path, verbose=verbose, no_server=no_server, save=save, cdf=cdf, data=pad, $
                          tplot=tplot, elo=elo, ehi=ehi, tavg=tavg, median=med, fill_nan=fill_nan

  IF undefined(itime) THEN get_timespan, trange $
  ELSE trange = itime
  IF is_string(trange) THEN trange = time_double(trange)

  rpath = 'https://pds-ppi.igpp.ucla.edu/data/vex-aspera4-els-pad/data_pad/'  
  IF undefined(path) THEN lpath = root_data_dir() + 'vex/aspera/els/pad/' ELSE lpath = path

  IF KEYWORD_SET(cdf) THEN vex_asp_els_pad_cdf, pad, trange=trange, path=lpath $
  ELSE BEGIN
     prefix = 'YYYY/VExELSPADRG_YYYYDOY_????' + ['.csv', '.txt']
     source = mvn_file_source(remote_data_dir=rpath, local_data_dir=lpath)
     files  = mvn_pfp_spd_download(prefix[0], source=source, trange=trange, /valid_only, /daily_names, /last_version, no_server=no_server)
     ;mfile  = mvn_pfp_spd_download(prefix[1], source=source, trange=trange, /valid_only, /daily_names, /last_version)
     ;subdirs = rpath + spd_uniq(time_string(trange, tformat='YYYY/')) + '*'
     ;spd_download_expand, subdirs, ssl_verify_peer=0, ssl_verify_host=0

     w = WHERE(files NE '', nfile)
     IF nfile EQ 0 THEN BEGIN
        dprint, dlevel=2, verbose=verbose, 'No remote data files found.'
        RETURN
     ENDIF ELSE files = files[w]
     ;w = WHERE(mfile NE '', nfile)
     ;IF nfile EQ 0 THEN BEGIN
     ;   dprint, dlevel=2, verbose=verbose, 'No remote mode files found.'
     ;   RETURN
     ;ENDIF ELSE mfile = mfile[w]

     ;pad = LIST()
     pad = vex_asp_els_pad()
     FOR i=0, nfile-1 DO BEGIN
        dprint, dlevel=2, verbose=verbose, 'Reading ' + files[i]
        OPENR, unit, files[i], /get_lun
        data = STRARR(FILE_LINES(files[i]))
        READF, unit, data
        FREE_LUN, unit

        data = data[3:*]
        data = STRSPLIT(data, ',', /extract)
        data = data.toarray()
        
        ts = time_double(data[*, 0], tformat='YYYY-DOYThh:mm:ss.fff')
        te = time_double(data[*, 1], tformat='YYYY-DOYThh:mm:ss.fff')
        
        stime = spd_uniq(ts)
        etime = spd_uniq(te)
        index = nn2(stime, ts)
        
        FOR j=0L, N_ELEMENTS(stime)-1 DO BEGIN
           ind = WHERE(index EQ j, nind)
           CASE nind OF
              127: mode = 0
              31:  mode = 1
              1:   mode = 2
              ELSE: mode = -1
           ENDCASE 
           pad.add, {time: stime[j], end_time: etime[j], data: REFORM(FLOAT(data[ind, 5:*])), energy: REFORM(FLOAT(data[ind, 3])), mode: TEMPORARY(mode)} ;, edx: REFORM(FLOAT(data[ind, 2]))}
        ENDFOR
     
        IF KEYWORD_SET(save) THEN BEGIN
           vex_asp_els_pad_cdf, pad, file=FILE_BASENAME(files[i]), verbose=verbose, path=lpath, /save
           undefine, pad
           IF i EQ nfile-1 THEN RETURN
           pad = vex_asp_els_pad()
        ENDIF 
     ENDFOR
  ENDELSE 
  
  IF KEYWORD_SET(tplot) THEN BEGIN
     IF undefined(elo) THEN elo = [30., 50.]
     IF undefined(ehi) THEN ehi = [100., 300.]
     IF undefined(tavg) THEN tavg = 32.d0
     
     prefix = 'vex_asp_els_pad'
     mode = pad.mode()
     m = spd_uniq(mode)
     pa = [5.:175.:10.]
     
     FOR i=0, N_ELEMENTS(m)-1 DO BEGIN
        w = WHERE(mode EQ m[i], nw)
        IF nw GT 0 THEN BEGIN
           time = 0.5d0 * (pad.time(w) + pad.end_time(w))
           data = pad.conv_units('DF', 'EFLUX', index=w, verbose=verbose, fill_nan=fill_nan)
           engy = pad.energy(w)
           engy = REBIN(engy, dimen1(engy), dimen2(engy), 18, /sample)

           tdat = data
;           v = WHERE(tdat LT 0., nv)
;           IF nv GT 0 THEN tdat[v] = !values.f_nan
           v = WHERE(engy LT elo[0] OR engy GE elo[1], nv)
           IF nv GT 0 THEN tdat[v] = !values.f_nan

           IF ~undefined(tavg) THEN BEGIN
              tdat2 = time_average(time, tdat, resolution=tavg, newtime=time2)
              tarr = TEMPORARY(time2)
              tdat = TEMPORARY(tdat2)
           ENDIF ELSE tarr = time
           
           datl = MEAN(tdat, dim=2, /nan)
           norm = REPLICATE(1., 18) ## MEAN(datl, dim=2, /nan)
           IF KEYWORD_SET(med) THEN norm = REPLICATE(1., 18) ## MEDIAN(datl, dim=2, /even)
           er   = roundst(elo[0]) + '-' + roundst(elo[1]) + ' eV'
           store_data, prefix + '_LE' + roundst(m[i]), data={x: tarr, y: datl/norm, v: pa}, $
                       dlim={spec: 1, no_interp: 1, ztitle: 'Norm. EFLUX', ytitle: 'VEX/ASP-4/ELS', ysubtitle: 'PA [deg]!C' + er, $
                             yticks: 6, yminor: 3, extend_y_edges: 1, constant: 90., const_line: 2};, datagap: 10.d0}
           ylim, prefix + '_LE' + roundst(m[i]), 0., 180., 0., /def
           zlim, prefix + '_LE' + roundst(m[i]), 0.5, 1.5, 0., /def

           tdat = data
;           v = WHERE(tdat LT 0., nv)
;           IF nv GT 0 THEN tdat[v] = !values.f_nan
           v = WHERE(engy LT ehi[0] OR engy GE ehi[1], nv)
           IF nv GT 0 THEN tdat[v] = !values.f_nan

           IF ~undefined(tavg) THEN BEGIN
              tdat2 = time_average(time, tdat, resolution=tavg, newtime=time2)
              tarr = TEMPORARY(time2)
              tdat = TEMPORARY(tdat2)
           ENDIF ELSE tarr = time
           
           dath = MEAN(tdat, dim=2, /nan)
           norm = REPLICATE(1., 18) ## MEAN(dath, dim=2, /nan)
           IF KEYWORD_SET(med) THEN norm = REPLICATE(1., 18) ## MEDIAN(dath, dim=2, /even)
           er   = roundst(ehi[0]) + '-' + roundst(ehi[1]) + ' eV'
           store_data, prefix + '_HE' + roundst(m[i]), data={x: tarr, y: dath/norm, v: pa}, $
                       dlim={spec: 1, no_interp: 1, ztitle: 'Norm. EFLUX', ytitle: 'VEX/ASP-4/ELS', ysubtitle: 'PA [deg]!C' + er, $
                             yticks: 6, yminor: 3, extend_y_edges: 1, constant: 90., const_line: 2};, datagap: 10.d0}
           ylim, prefix + '_HE' + roundst(m[i]), 0., 180., 0., /def
           zlim, prefix + '_HE' + roundst(m[i]), 0.5, 1.5, 0., /def
        ENDIF 
     ENDFOR

     store_data, prefix + '_LE', data=tnames(prefix + '_LE*')
     store_data, prefix + '_HE', data=tnames(prefix + '_HE*')
     ylim, prefix + ['_LE', '_HE'], 0., 180., 0., /def
  ENDIF 

  RETURN
END 
