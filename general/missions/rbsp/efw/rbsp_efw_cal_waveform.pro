;+
; NAME:
;   rbsp_efw_cal_waveform (procedure)
;
; PURPOSE:
;   Calibrate EFW waveform data.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_efw_cal_waveform, probe = probe, datatype = datatype, $
;     trange = trange, get_support_data = get_support_data, $
;     coord = coord, no_adc = no_adc, $
;     tper = tper, tphase = tphase
;
; ARGUMENTS:
;
; KEYWORDS:
;   probe: (In, optional) RBSP spacecraft names, either 'a', or 'b', or 
;         ['a', 'b']. The default is ['a', 'b']
;   datatype: (In, optional) A string scalar of data types that acceptable to 
;         *rbsp_load_efw_waveform*.
;   trange: (In, optional) Time range for performing the calibration. By
;         default, trange = timerange()
;   /get_support_data: If set, offsets in spin-plane components are stored in a
;         tplot variable with format '*_uvw_offset'.
;   coord: (In, optional) If set to 'uvw', despinning will not be performed.
;   /no_adc: If set, ADC-to-physical units is ignored.
;   tper: (In, optional) Tplot name of spin period data. By default, 
;         tper = pertvar. If tper is set, pertvar = tper.
;   tphase: (In, optional) Tplot name of spin phase data. By default, 
;         tphase = 'rbsp' + strlowcase(sc[0]) + '_spinphase'
;         Note: tper and and tphase are mostly used for using eclipse-corrected
;         spin data.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-08-07: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-06: JBT, SSL/UCB.
;         1. Added despinning capability.
;   2012-11-12: JBT, SSL/UCB.
;         1. Added esvy and vsvy cleaning.
;   2013-06-21: JBT, SSL/UCB.
;         1. Added instrument response deconvolution for eb1.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2013-06-21 13:31:17 -0700 (Fri, 21 Jun 2013) $
; $LastChangedRevision: 12569 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_cal_waveform.pro $
;
;-

pro rbsp_efw_cal_waveform, probe = probe, datatype = datatype, $
  trange = trange, get_support_data = get_support_data, $
  coord = coord, no_adc = no_adc, no_deconvol = no_deconvol, $
  tper = tper, tphase = tphase, noclean = noclean

compile_opt idl2

dprint,verbose=verbose,dlevel=4,'$Id: rbsp_efw_cal_waveform.pro 12569 2013-06-21 20:31:17Z jianbao_tao $'

if ~keyword_set(trange) then trange = timerange()
if size(coord, /type) ne 7 then coord = 'dsc'

cp0 = rbsp_efw_get_cal_params(trange[0])

; vprobes = ['a','b']
; vlevels = ['l1','l2']
; vdatatypes=['esvy', 'vsvy', 'magsvy', 'eb1', 'vb1', 'mscb1', 'eb2', 
;             'vb2', 'mscb2']

case strlowcase(probe) of
  'a': cp = cp0.a
  'b': cp = cp0.b
  else: dprint, 'Invalid probe name. Calibration aborted.'
endcase

boom_length = cp.boom_length
boom_shorting_factor = cp.boom_shorting_factor

rbspx = 'rbsp' + probe[0]

tvar = rbspx + '_efw_' + datatype[0]
get_data, tvar, data = data, dlim = dlim
new_y = double(data.y)

; Check if dlim has data_att.
; str_element, dlim, 'data_att', success = s
; if s eq 0 then begin
;   str_element, dlim, 'data_att', {coord_sys:'uvw', units:'ADC'}, /add
; endif

case strlowcase(datatype[0]) of
  'vsvy': begin
      ; Convert ADC counts into physical units
      gain = cp.ADC_gain_VDC
      offset = cp.ADC_offset_VDC
      for i = 0, 5 do new_y[*,i] =  (data.y[*,i] - offset[i]) * gain[i]
      new_data = {x:data.x, y:new_y[*,0:5]}
      dlim.data_att.units = 'V'
      labels = ['V1', 'V2', 'V3', 'V4', 'V5', 'V6']
      colors = [1, 2, 3, 4, 5, 6]
      ysubtitle = '[V]'
    end
  'vb1': begin
      ; Convert ADC counts into physical units
      gain = cp.ADC_gain_VDC
      offset = cp.ADC_offset_VDC
      for i = 0, 5 do new_y[*,i] =  (data.y[*,i] - offset[i]) * gain[i]
      new_data = {x:data.x, y:new_y[*,0:5]}
      dlim.data_att.units = 'V'
      labels = ['V1', 'V2', 'V3', 'V4', 'V5', 'V6']
      colors = [1, 2, 3, 4, 5, 6]
      ysubtitle = '[V]'
    end
  'vb2': begin
      ; Convert ADC counts into physical units
      gain = cp.ADC_gain_VAC
      offset = cp.ADC_offset_VAC
      for i = 0, 5 do new_y[*,i] =  (data.y[*,i] - offset[i]) * gain[i]
      new_data = {x:data.x, y:new_y[*,0:5]}
      dlim.data_att.units = 'V'
      labels = ['V1', 'V2', 'V3', 'V4', 'V5', 'V6']
      colors = [1, 2, 3, 4, 5, 6]
      ysubtitle = '[V]'
    end
  'esvy': begin
      ; Convert ADC counts into physical units
      gain = cp.ADC_gain_EDC
      offset = cp.ADC_offset_EDC
      for i = 0, 2 do new_y[*,i] = (data.y[*,i] - offset[i]) * gain[i] $
                      / (boom_length[i] * boom_shorting_factor[i]) * 1000d
      new_data = {x:data.x, y:new_y[*,0:2]}
      dlim.data_att.units = 'mV/m'
      str_element, dlim, 'data_att.boom_shorting_factor', $
        boom_shorting_factor, /add
      str_element, dlim, 'data_att.boom_length', $
        boom_length, /add
      labels = ['E12 (U)', 'E34 (V)', 'E56 (W)']
      colors = [2, 4, 6]
      ysubtitle = '[mV/m]'
    end
  'eb1': begin
      ; Convert ADC counts into physical units
      gain = cp.ADC_gain_EDC
      offset = cp.ADC_offset_EDC
      for i = 0, 2 do new_y[*,i] = (data.y[*,i] - offset[i]) * gain[i] $
                      / (boom_length[i] * boom_shorting_factor[i]) * 1000d
      new_data = {x:data.x, y:new_y[*,0:2]}
      ; Remove instrument responses.
      if ~keyword_set(no_deconvol) then $
        new_data = rbsp_efw_deconvol_inst_resp(new_data, probe[0], 'eb1')

      dlim.data_att.units = 'mV/m'
      str_element, dlim, 'data_att.boom_shorting_factor', $
        boom_shorting_factor, /add
      str_element, dlim, 'data_att.boom_length', $
        boom_length, /add
      labels = ['E12 (U)', 'E34 (V)', 'E56 (W)']
      colors = [2, 4, 6]
      ysubtitle = '[mV/m]'
    end
  'eb2': begin
      ; Convert ADC counts into physical units
      gain = cp.ADC_gain_EAC
      offset = cp.ADC_offset_EAC
      for i = 0, 2 do new_y[*,i] = (data.y[*,i] - offset[i]) * gain[i] $
                      / (boom_length[i] * boom_shorting_factor[i]) * 1000d
      new_data = {x:data.x, y:new_y[*,0:2]}
      if ~keyword_set(no_deconvol) then $
        new_data = rbsp_efw_deconvol_inst_resp(new_data, probe[0], 'eb2')
      dlim.data_att.units = 'mV/m'
      str_element, dlim, 'data_att.boom_shorting_factor', $
        boom_shorting_factor, /add
      str_element, dlim, 'data_att.boom_length', $
        boom_length, /add
      labels = ['E12 (U)', 'E34 (V)', 'E56 (W)']
      colors = [2, 4, 6]
      ysubtitle = '[mV/m]'
    end
  'magsvy': begin
      ; Convert ADC counts into physical units
      data = {x:data.x, y:double(data.y)}
      rangetvar = tvar + '_magsvy_mag_range'
      validtvar = tvar + '_magsvy_mag_valid'
      get_data, rangetvar, data = rdata
      get_data, validtvar, data = vdata
      t_cadence = median(rdata.x[1:*] - rdata.x)
      ;-- Mark NaNs to invalid data.
      ind = where(vdata.y ne 1, nind)
      if nind gt 0 then begin
        for ii = 0L, nind - 1L do begin
          itmp = ind[ii]
          tsta = vdata.x[itmp]
          tend = tsta + t_cadence
          ind_tmp = where(data.x ge tsta and data.x lt tend, nind_tmp)
          if nind_tmp gt 0 then data.y[ind_tmp,*] = !values.f_nan
        endfor
      endif
      ;-- Use appropriate gain and offset based on mag_range
      i_last = uniq(rdata.y)
      if n_elements(i_last) eq 1 then begin
        i_range = rdata.y[0]
        gain = cp.ADC_gain_MAG[i_range, *]
        offset = cp.ADC_offset_MAG[i_range, *]
        for i = 0, 2 do new_y[*,i] = (data.y[*,i] - offset[i]) * gain[i]
      endif else begin
        for ii = 0L, n_elements(i_last)-1 do begin
          if ii eq 0 then tsta = rdata.x[0] $
            else tsta = tend
          tend = rdata.x[i_last[ii]] + t_cadence
          ind_tmp = where(data.x ge tsta and data.x lt tend, nind_tmp)
          if nind_tmp gt 0 then begin
            i_range = rdata.y[i_last[ii]]
            gain = cp.ADC_gain_MAG[i_range, *]
            offset = cp.ADC_offset_MAG[i_range, *]
            for i = 0, 2 do $
              new_y[ind_tmp,i] = (data.y[ind_tmp,i] - offset[i]) * gain[i]
          endif
        endfor
      endelse
      new_data = {x:data.x, y:new_y[*,0:2]}
      dlim.data_att.units = 'nT'
      labels = ['Bu', 'Bv', 'Bw']
      colors = [2, 4, 6]
      ysubtitle = '[nT]'
;       stop
    end
  'mscb1': begin
      ; Convert ADC counts into physical units
      gain = cp.ADC_gain_MSC
      offset = cp.ADC_offset_MSC
      for i = 0, 2 do new_y[*,i] = (data.y[*,i] - offset[i]) * gain[i]
      new_data = {x:data.x, y:new_y[*,0:2]}
      if ~keyword_set(no_deconvol) then $
        new_data = rbsp_efw_deconvol_inst_resp(new_data, probe[0], 'mscb1')
      ; Correct phase
      dlim.data_att.units = 'nT'
      labels = ['Bu', 'Bv', 'Bw']
      colors = [2, 4, 6]
      ysubtitle = '[nT]'
    end
  'mscb2': begin
      ; Convert ADC counts into physical units
      gain = cp.ADC_gain_MSC
      offset = cp.ADC_offset_MSC
      for i = 0, 2 do new_y[*,i] = (data.y[*,i] - offset[i]) * gain[i]
      new_data = {x:data.x, y:new_y[*,0:2]}
;       stop
      if ~keyword_set(no_deconvol) then $
        new_data = rbsp_efw_deconvol_inst_resp(new_data, probe[0], 'mscb2')
;       stop
      dlim.data_att.units = 'nT'
      labels = ['Bu', 'Bv', 'Bw']
      colors = [2, 4, 6]
      ysubtitle = '[nT]'
    end
  else: begin
      print, ''
      dprint, 'Invalid datatype. Calibration aborted.'
      print, ''
      return
    end
endcase

; Update dlim
; str_element, dlim, 'cdf', /delete
; str_element, dlim, 'code_id', /delete

; newname = tvar + '_' + strlowcase(dlim.data_att.coord_sys)
newname = tvar
options, newname, labels = labels, colors = colors, $
  ysubtitle = ysubtitle, labflag = 1

if ~keyword_set(no_adc) then begin
  tspan = timerange()
  ind = where(new_data.x ge tspan[0] and new_data.x le tspan[1])
  new_data = {x:new_data.x[ind], y:new_data.y[ind,*]}
  store_data, newname, data = new_data, dlim = dlim
endif

dtype = strlowcase(datatype[0])
sc = probe[0]
rbx = 'rbsp' + strlowcase(sc) + '_'

; tplot, newname, title = newname
; stop

; Skip de-spinning.
if strcmp(coord, 'uvw', /fold) then begin
  dprint, 'No despinning. '
  return
endif


; Despin data
; tplot, rbx + 'efw_esvy'
; stop

case dtype of
  'esvy': begin
      tvar = newname
      offset_name = rbx + dtype + '_uvw_offset'
      rbsp_despin, sc, tvar, /uvw, newname = tvar, no_axial = 1, $
        tper = tper, tphase = tphase, $
        offset_name = offset_name
      if ~keyword_set(get_support_data) then begin
        store_data, offset_name, /del
      endif
      options, tvar, labels = ['Ex DSC', 'Ey DSC', 'Ez DSC'] 
    end
  'eb1': begin
      tvar = newname
      offset_name = rbx + dtype + '_uvw_offset'
      rbsp_despin, sc, tvar, /uvw, newname = tvar, no_axial = 1, $
        tper = tper, tphase = tphase, $
        offset_name = offset_name
      if ~keyword_set(get_support_data) then begin
        store_data, offset_name, /del
      endif
    end
  'eb2': begin
      tvar = newname
      offset_name = rbx + dtype + '_uvw_offset'
      rbsp_despin, sc, tvar, /uvw, newname = tvar, no_axial = 1, $
        tper = tper, tphase = tphase, $
        offset_name = offset_name, /no_offset_remove
      if ~keyword_set(get_support_data) then begin
        store_data, offset_name, /del
      endif
    end
  'mscb1': begin
      tvar = newname
      offset_name = rbx + dtype + '_uvw_offset'
      rbsp_despin, sc, tvar, /uvw, newname = tvar, no_axial = 1, $
        tper = tper, tphase = tphase, $
        offset_name = offset_name, /no_offset_remove
      if ~keyword_set(get_support_data) then begin
        store_data, offset_name, /del
      endif
    end
  'mscb2': begin
      tvar = newname
      offset_name = rbx + dtype + '_uvw_offset'
      rbsp_despin, sc, tvar, /uvw, newname = tvar, no_axial = 1, $
        tper = tper, tphase = tphase, $
        offset_name = offset_name, /no_offset_remove
      if ~keyword_set(get_support_data) then begin
        store_data, offset_name, /del
      endif
    end
  else: begin
      dprint, 'Not vector data. No despinning...'
    end
endcase

if ~keyword_set(noclean) then begin
  if strcmp(dtype, 'esvy', /fold) then rbsp_efw_clean_esvy, rbx + 'efw_esvy'
  if strcmp(dtype, 'vsvy', /fold) then rbsp_efw_clean_vsvy, rbx + 'efw_vsvy'
endif



end

