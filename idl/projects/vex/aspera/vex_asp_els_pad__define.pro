;+
;
;OBJECT:          VEX_ASP_ELS_PAD
;
;PURPOSE:         Object to handle the VEX/ASPERA-4/ELS pitch angle distribution (PAD) data.
;
;INPUTS:          
;
;KEYWORDS:
;
;CREATED BY:      Takuya Hara on 2025-05-30.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2025-06-05 15:52:18 -0700 (Thu, 05 Jun 2025) $
; $LastChangedRevision: 33371 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_els_pad__define.pro $
;
;-
FUNCTION vex_asp_els_pad::Init, item
  COMPILE_OPT IDL2
  IF ISA(item, 'LIST') THEN self.dat = item ELSE self.dat = LIST()
  RETURN, 1
END

PRO vex_asp_els_pad::add, item
  self.dat.add, item
  RETURN
END

FUNCTION vex_asp_els_pad::index, index
  IF undefined(index) THEN index = [0:N_ELEMENTS(self.dat)-1]
  RETURN, self.dat[index]
END 

FUNCTION vex_asp_els_pad::extract_field, tag, index=index, verbose=verbose
  data = self.dat
  tags = TAG_NAMES(data[0])
  i = strfilter(tags, tag.toupper(), /index)
  arr = data.map(LAMBDA(x,i:x.(i)), i)

  IF ~undefined(index) THEN arr = arr[index]
  RETURN, arr
END

FUNCTION vex_asp_els_pad::time, index, verbose=verbose;, module=module
  arr = self.extract_field('time', verbose=verbose)
  arr = arr.toarray()
  IF undefined(index) THEN index = [0:N_ELEMENTS(self.dat)-1]
  arr = arr[index]
;  data = self.dat[index]
;  IF SIZE(data, /type) EQ 8 THEN arr = data.time $
;  ELSE BEGIN
;     IF undefined(module) THEN module = 'python.mypy.vex_asp_els_pad'
;     pmod = python.import(module)
;     arr = pmod.extract_field(data, 'TIME')
;     arr = arr.toarray()
;  ENDELSE 
  RETURN, arr
END

FUNCTION vex_asp_els_pad::end_time, index, verbose=verbose;, module=module
  arr = self.extract_field('end_time', verbose=verbose)
  arr = arr.toarray()
  IF undefined(index) THEN index = [0:N_ELEMENTS(self.dat)-1]
  arr = arr[index]
;  data = self.dat[index]
;  IF SIZE(data, /type) EQ 8 THEN arr = data.end_time $
;  ELSE BEGIN
;     IF undefined(module) THEN module = 'python.mypy.vex_asp_els_pad'
;     pmod = python.import(module)
;     arr = pmod.extract_field(data, 'END_TIME')
;     arr = arr.toarray()
;  ENDELSE 
  RETURN, arr
END

FUNCTION vex_asp_els_pad::energy, index, verbose=verbose;, module=module
  data = self.extract_field('energy', verbose=verbose)
  IF undefined(index) THEN index = [0:N_ELEMENTS(self.dat)-1]
  data = data[index]
  
;  data = self.dat[index]
  
  IF ~ISA(data, 'LIST') THEN energy = data $
  ELSE BEGIN
     arr = data
     
;     IF undefined(module) THEN module = 'python.mypy.vex_asp_els_pad'
;     status = EXECUTE('pmod = python.import(module)')
;     arr = pmod.extract_field(data, 'ENERGY')
     
;     IF (status) THEN BEGIN
;        energy = pmod.pad_1d_array_list(arr)
;        energy = TRANSPOSE(energy)
;     ENDIF ELSE BEGIN
     nengy = arr.map(LAMBDA(x:N_ELEMENTS(x)))
     nengy = nengy.toarray()
     uengy = spd_uniq(nengy)
     IF N_ELEMENTS(uengy) GT 1 THEN BEGIN
        energy = REPLICATE(!values.f_nan, N_ELEMENTS(nengy), MAX(nengy))
        FOR i=0, N_ELEMENTS(uengy)-1 DO BEGIN
           w = WHERE(nengy EQ uengy[i], nw)
           IF nw GT 0 THEN energy[w, 0:uengy[i]-1] = (arr[w]).toarray()
        ENDFOR 
     ENDIF ELSE energy = arr.toarray()
;     ENDELSE 
  ENDELSE 
  RETURN, energy
END

FUNCTION vex_asp_els_pad::data, index, verbose=verbose;, module=module
  data = self.extract_field('data', verbose=verbose)
  IF undefined(index) THEN index = [0:N_ELEMENTS(self.dat)-1]
  data = data[index]
;  data = self.dat[index]
  
  IF ~ISA(data, 'LIST') THEN pad = data $
  ELSE BEGIN
     arr = data
     
;     IF undefined(module) THEN module = 'python.mypy.vex_asp_els_pad'
;     status = EXECUTE('pmod = python.import(module)')
;     arr = pmod.extract_field(data, 'DATA')

;     IF (status) THEN BEGIN
;        pad = pmod.pad_2d_array_list(arr)
;        pad = TRANSPOSE(pad, [2, 0, 1])
;     ENDIF ELSE BEGIN
     nengy = arr.map(LAMBDA(x:dimen1(x)))      
     nengy = nengy.toarray()
     uengy = spd_uniq(nengy)
     IF N_ELEMENTS(uengy) GT 1 THEN BEGIN
        pad = REPLICATE(!values.f_nan, N_ELEMENTS(nengy), MAX(nengy), 18)
        FOR i=0, N_ELEMENTS(uengy)-1 DO BEGIN
           w = WHERE(nengy EQ uengy[i], nw)
           IF nw GT 0 THEN pad[w, 0:uengy[i]-1, *] = (arr[w]).toarray()
        ENDFOR
     ENDIF ELSE pad = arr.toarray()
;     ENDELSE 
  ENDELSE 
  RETURN, pad
END 

FUNCTION vex_asp_els_pad::mode, index, verbose=verbose;, module=module
  arr = self.extract_field('mode', verbose=verbose)
  arr = arr.toarray()
  IF undefined(index) THEN index = [0:N_ELEMENTS(self.dat)-1]
  arr = arr[index]
;  data = self.dat[index]
;  IF SIZE(data, /type) EQ 8 THEN arr = data.mode $
;  ELSE BEGIN
;     IF undefined(module) THEN module = 'python.mypy.vex_asp_els_pad'
;     pmod = python.import(module)
;     arr = pmod.extract_field(data, 'MODE')
;     arr = arr.toarray()
;  ENDELSE 
  RETURN, arr
END

PRO vex_asp_els_pad::cleanup
  obj_destroy, self.dat
END

FUNCTION vex_asp_els_pad::conv_units, iunit, ounit, index=index, verbose=verbose, fill_nan=fill_nan
  c = 2.99792458D5              ; velocity of light [km/s]
  mass = (5.10998910D5)/(c*c)   ; electron rest mass [eV/(km/s)^2]
  m_conv = 2D5/(mass*mass)      ; mass conversion factor (flux to distribution function)
  
  data = self.data(index)
  IF iunit.toupper() EQ 'DF' THEN data *= 1.e3 ; 1/(m^3-(m/s)^3) -> 1/(cm^3-(km/s)^3)
  IF ~undefined(fill_nan) THEN BEGIN
     w = WHERE(data LE FLOAT(fill_nan), nw)
     IF nw GT 0 THEN data[w] = !values.f_nan
  ENDIF 

  energy = self.energy(index)

  IF ndimen(energy) EQ 2 THEN energy = REBIN(energy, dimen1(energy), dimen2(energy), 18, /sample) $
  ELSE energy = REBIN(energy, dimen1(energy), 18, /sample)
  
  CASE ounit.toupper() OF
     'FLUX' : scale = 1.
     'EFLUX': scale = energy
     'DF'   : scale = 1./(energy * m_conv)
     'DF1'  : scale = 1./(energy * m_conv) * 1.e15
     ELSE: BEGIN
        dprint, dlevel=2, verbose=verbose, 'Cannot convert to units of ' + ounit.toupper()
        RETURN, s
     END
  ENDCASE 

  CASE iunit.toupper() OF
     'FLUX' : scale = scale
     'EFLUX': scale = scale/energy
     'DF'   : scale = scale * energy * 2./mass/mass*1e5
     'DF1'  : scale = scale * energy * 2./mass/mass*1e5 * 1.e-15
     ENDCASE

  data = data * scale
  RETURN, data
END 

PRO vex_asp_els_pad::convert_units, pad, iunit, ounit, index=index, verbose=verbose
  COMPILE_OPT IDL2
  IF undefined(iunit) THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No input unit name found.'
     RETURN
  ENDIF
  IF undefined(ounit) THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No output unit name found.'
     RETURN
  ENDIF

  pad = self.conv_units(iunit, ounit, index=index, verbose=verbose)
END

FUNCTION vex_asp_els_pad::get, time, unit=unit, index=index, verbose=verbose, fill_nan=fill_nan
  pa = [5.:175.:10.]
  c = !const.c * 1.d-3          ; km/s
  IF undefined(unit) THEN unit = 'df'

  IF undefined(time) THEN ctime, t $
  ELSE t = time
  IF is_string(t) THEN t = time_double(t)

  times = 0.5d0 * (self.time() + self.end_time())
  IF N_ELEMENTS(t) EQ 1 THEN BEGIN
     n = nn2(times, t)
     data = self.dat[n]
     IF unit.tolower() NE 'df' THEN str_element, data, 'data', self.conv_units('df', unit, index=n, verbose=verbose, fill_nan=fill_nan), /add_replace
  ENDIF ELSE BEGIN
     w = WHERE(times GE MIN(t) AND times LE MAX(t), nw)
     IF nw EQ 0 THEN BEGIN
        dprint, dlevel=2, verbose=verbose, 'No data found in the specified time range.'
        RETURN, 0
     ENDIF ELSE BEGIN
        IF nw EQ 1 THEN BEGIN
           data = self.dat[w]
           IF unit.tolower() NE 'df' THEN str_element, data, 'data', self.conv_units('df', unit, index=w, verbose=verbose, fill_nan=fill_nan), /add_replace
        ENDIF ELSE BEGIN
           modes = self.mode(w)
           IF N_ELEMENTS(spd_uniq(modes)) GT 1 THEN BEGIN
              dprint, dlevel=2, verbose=verbose, 'Multiple energy sweep modes are included in the specified time range.'
              RETURN, 0
           ENDIF
           str_element, data, 'mode', spd_uniq(modes), /add
           str_element, data, 'time', MIN(self.time(w)), /add
           str_element, data, 'end_time', MAX(self.end_time(w)), /add
           str_element, data, 'energy', MEAN(self.energy(w), /dim), /add

           IF unit.tolower() NE 'df' THEN tdat = self.conv_units('df', unit, index=w, verbose=verbose, fill_nan=fill_nan) ELSE tdat = self.data(w)
           ;v = WHERE(tdat LT 0., nv)
           ;IF nv GT 0 THEN tdat[v] = !values.f_nan
           dprint, dlevel=2, verbose=verbose, 'Averaging data in the specified time range.'
           str_element, data, 'data', MEAN(TEMPORARY(tdat), /dim, /nan), /add
        ENDELSE
     ENDELSE 
  ENDELSE 

  pad = {project_name: 'VEx', data_name: 'ASPERA-4/ELS PAD', units_name: unit.tolower()}
  extract_tags, pad, data, tags=['time', 'end_time']
  str_element, pad, 'delta_t', (data.end_time - data.time), /add
  str_element, pad, 'nenergy', FIX(N_ELEMENTS(data.energy)), /add
  str_element, pad, 'energy', REBIN(data.energy, pad.nenergy, 18, /sample), /add
  str_element, pad, 'nbins', 18, /add
  str_element, pad, 'pa', TRANSPOSE(REBIN(pa, pad.nbins, pad.nenergy, /sample)), /add
  str_element, pad, 'mass', (5.10998910D5)/(c*c), /add
  str_element, pad, 'mode', data.mode, /add
  str_element, pad, 'data', data.data, /add
  RETURN, pad
END 

PRO vex_asp_els_pad::snap, pad, time=time, verbose=verbose, median=med, window=window, charsize=chsz, limits=lim
  IF undefined(pad) THEN pad = self.get(time, verbose=verbose)
  IF undefined(window) THEN wnum = 1 ELSE wnum = FIX(window)
  IF undefined(chsz) THEN chsz = 1.3
  pa = pad.pa
  engy = pad.energy
  dat = pad.data
  unit = pad.units_name

  w = WHERE(dat LT 0., nw)
  IF nw GT 0 THEN dat[w] = !values.f_nan
  
  norm = REPLICATE(1., 18) ## MEAN(dat, dim=2, /nan)
  IF KEYWORD_SET(med) THEN norm = REPLICATE(1., 18) ## MEDIAN(dat, dim=2, /even)

  tit = time_string(pad.time) + ' -> ' + time_string(pad.end_time)
  
  dlim = {xstyle: 1, ystyle: 1, no_interp: 1, charsize: chsz, xrange: [1., 20.e3], yrange: [0., 180.], extend_y_edges: 1, $
          xtitle: 'Energy [eV]', ytitle: 'PA [deg]', yticks: 6, yminor: 3, xlog: 1, zrange: [0.5, 1.5], zstyle: 1, ztitle: 'Norm. ' + unit.toupper(), $
          xmargin: [10., 10.], ymargin: [4., 3.], title: tit}
  extract_tags, plim, dlim
  extract_tags, plim, lim

  engy = REFORM(engy[*, 0])
  pa   = REFORM(pa[0, *])
  IF !d.name EQ 'X' THEN wi, wnum, wsize=[600, 500]
  specplot, engy, pa, dat/norm, lim=plim
  RETURN
END

PRO vex_asp_els_pad__define
  COMPILE_OPT IDL2
  void = {vex_asp_els_pad, dat: OBJ_NEW()}
END
