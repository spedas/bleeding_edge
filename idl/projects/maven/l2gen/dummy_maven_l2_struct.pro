;+
Function dummy_maven_l2_struct, vars, only_1_time_array = only_1_time_array, $
                                instrument = instrument, _extra=_extra
; Takes an array of tplot variables, creates a dummy CDF master
; structure, inserts data, returns structure suitable for output.
; If you set the only_1_time_array keyword, then there will be only 1
; time_array, the instrument keyword also needs to be set, so that the
; time variable name is 'instrument_time' (e.g., instrument = 'swe_l2'
; will give a time variable name of 'swe_l2_time'. Otherwise, the time
; variable name will be 'L2_time').
;-

otp_struct = -1

If(keyword_set(instrument)) Then instr = instrument Else instr = 'L2'

;For each variable, I need a variable attributes structure;
var_attributes = {catdesc:'', display_type:'', fieldnam:'', $
                  fillval:!values.f_nan, format:'e13.6', $
                  units:'NA', depend_time:'', depend_epoch0:'', $
                  depend_0:'', depend_1:'NA', validmin:-1.0e38, $
                  validmax:1.0e+38, var_type:'data', $
                  coordinate_system:'sensor', $
                  property:'', scaletyp:'', lablaxis:'',$
;This last line needed for ISTP compliance
                  form_ptr:'', monoton:'', scalemin:'',scalemax:''}

;Attributes are different for time variables
timevar_attributes = {catdesc:'', fieldnam:'', $
                      fillval:!values.f_nan, format:'f12.8', $
                      units:'sec', validmin:0.0, $
                      validmax:5.0e9, var_type:'support_data', $
                      lablaxis:'UT'}

;yaxis vars are different too
yvar_attributes = {catdesc:'', fieldnam:'', $
                   fillval:!values.f_nan, format:'e13.6', $
                   units:'NA', depend_time:'', depend_epoch0:'', $
                   depend_0:'', validmin:-1.0e38, $
                   validmax:1.0e+38, var_type:'support_data', lablaxis:''}

;This is the generic structure for a variable
vars_struct = {name:'', num:0, is_zvar:1, datatype:'CDF_FLOAT', $
               type:4, numattr: -1, numelem: 1, recvary: 1b, $
               numrec:0L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
               attrptr:ptr_new()}

nv = n_elements(vars)
;Regular variables
vatt = replicate(var_attributes, nv)
vstr = replicate(vars_struct, nv)

;time variables
If(keyword_set(only_1_time_array)) Then Begin
    vtatt = timevar_attributes
Endif Else Begin
    vtatt = replicate(timevar_attributes, nv)
Endelse
vtstr = vstr

vtatt = replicate(timevar_attributes, nv)
vtstr = vstr

;Yaxis variables
vyatt = replicate(yvar_attributes, nv)
vystr = vstr

;checks for yaxis and data
has_yaxis = bytarr(nv)
has_data = bytarr(nv)

For j = 0, nv-1 Do Begin
;Not a whole lot of error checking here
    vj = tnames(vars[j])        ;be sure it's a string
    If(is_string(vj) Eq 0) Then Begin
        message, /info, 'No variable name: '+vars[j]
        continue
    Endif
    vj = vj[0]
    get_data, vars[j], data = d, dlimits = dl
    If(is_struct(d) Eq 0) Then Begin
        message, /info, 'Data not a structure: '+vars[j]
        continue
    Endif
    has_data[j] = 1
    dx = d.x
    dy = d.y
    ny = n_elements(d.y)

    vatt[j].catdesc = vj
    If(is_struct(dl) && tag_exist(dl, 'spec') && dl.spec Eq 1) Then $
      vatt[j].display_type = 'spectrogram' $
    Else vatt[j].display_type = 'time_series'
    vatt[j].fieldnam = vj
    If(is_struct(dl) && tag_exist(dl, 'data_att') && $
       tag_exist(dl.data_att, 'units')) Then vatt[j].units = dl.data_att.units

    If(keyword_set(only_1_time_array)) Then Begin
        vatt[j].depend_time = vj+'_time'
        vatt[j].depend_epoch0 = vj+'_epoch0'
        vatt[j].depend_0 = vj+'_epoch'
    Endif Else Begin
        vatt[j].depend_time = instr+'_time'
        vatt[j].depend_epoch0 = instr+'_epoch0'
        vatt[j].depend_0 = instr+'_epoch'
    Endelse

    If(tag_exist(d, 'v')) Then vatt[j].depend_1 = vj+'_yaxis'
    If(is_struct(dl) && tag_exist(dl, 'data_att') && $
       tag_exist(dl.data_att, 'coord_sys')) Then $
       vatt[j].coordinate_system = dl.data_att.coord_sys
    If(is_struct(dl) && tag_exist(dl, 'spec') && dl.spec Eq 1) Then $
      vatt[j].property = 'spectrogram' Else Begin
        If(ny Eq 1) Then vatt[j].property = 'scalar' $
        Else vatt[j].property = 'vector'
    Endelse
    If(is_struct(dl) && tag_exist(dl, 'log') && dl.log Eq 1) Then $
      vatt[j].scaletyp = 'log' Else vatt[j].scaletyp = 'linear'
    vatt[j].lablaxis = vj

;The attributes go in the vars_struct
    vstr[j].attrptr = ptr_new(vatt[j])
    vstr[j].name = vj
    vstr[j].num = n_elements(dx)
    vstr[j].datatype = idl2cdftype(dy)
    vstr[j].type = size(dy, /type)
    vstr[j].d[0] = ny
    vstr[j].dataptr = ptr_new(dy)

;Now do a time variable
    If(~keyword_set(only_1_time_array)) Then Begin
        vtatt[j].catdesc = vj+'_time'
        vtatt[j].fieldnam = vj+'_time'

        vtstr[j].attrptr = ptr_new(vtatt[j])
        vtstr[j].name = vj+'_time'
        vtstr[j].num = n_elements(dx)
        vtstr[j].datatype = 'CDF_DOUBLE'
        vtstr[j].type = 5
        vtstr[j].dataptr = ptr_new(dx)
    Endif Else Begin
        If(j Eq 0) Then Begin
            vtatt[j].catdesc = instr+'_time'
            vtatt[j].fieldnam = instr+'_time'

            vtstr[j].attrptr = ptr_new(vtatt[j])
            vtstr[j].name = vj+'_time'
            vtstr[j].num = n_elements(dx)
            vtstr[j].datatype = 'CDF_DOUBLE'
            vtstr[j].type = 5
            vtstr[j].dataptr = ptr_new(dx)
        Endif
    Endelse
;Now a yaxis variable, if necessary
    If(tag_exist(d, 'v')) Then Begin
        has_yaxis[j] = 1
        dv = d.v
;Attributes
        vyatt[j].catdesc = vj+'_yaxis'
        vyatt[j].fieldnam = vj+'_yaxis'
        vyatt[j].depend_time = vj+'_time'
        vyatt[j].depend_epoch0 = vj+'_epoch0'
        vyatt[j].depend_0 = vj+'_epoch'
        vyatt[j].lablaxis = vj+'_yaxis'

;vars_struct
        vystr[j].name = vj+'_yaxis'
        vystr[j].num = n_elements(dx)
        vstr[j].datatype = idl2cdftype(dv)
        vystr[j].type = size(dv, /type)
        vystr[j].ndimen = 1
        vystr[j].d[0] = ny
        vystr[j].dataptr = ptr_new(dv)
        vystr[j].attrptr = ptr_new(vyatt[j])
    Endif
Endfor

keep_data = where(has_data Eq 1, vc)
If(vc Gt 0) Then Begin
    keep_yaxis = where(has_yaxis Eq 1, nkeep)
    If(nkeep Gt 0) Then Begin
        vystr = vystr[keep_yaxis]
        allvars = [vstr[keep_data], vtstr[keep_data], vystr]
    Endif Else allvars = [vstr[keep_data], vtstr[keep_data]]
    nvars = n_elements(allvars)

;global attributes:
    global_att = {project:'MAVEN', $
                  descriptor:'Test L2 CDF file', $
                  source_name: '', $
                  discipline:'', $
                  data_type:'', $
                  data_version:'',$
                  pi_name:'' , $
                  pi_affiliation:'' , $
                  text:'' , $
                  instrument_type:'' , $
                  mission_group:'' , $
                  logical_file_id:'',$
                  logical_source:'' , $
                  logical_source_description:'' , $
                 }

    natts = n_tags(global_att)+n_tags(variable_attributes)

    inq = {ndims:0l, decoding:'HOST_DECODING', $
           encoding:'NETWORK_ENCODING', $
           majority:'ROW_MAJOR', maxrec:-1,$
           nvars:0, nzvars:nvars, natts:natts, dim:lonarr(1)}
    otp_struct = {filename:'', g_attributes:global_att, inq:inq, nv:nvars, vars:allvars}
Endif Else Begin
    message, /info, 'No Non-composite tplot variables'
    otp_struct = 1
Endelse

Return, otp_struct
End

