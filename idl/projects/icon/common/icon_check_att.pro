;+
;NAME:
;   icon_check_att
;
;PURPOSE:
;   Check attributes
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2019-02-01 15:04:50 -0800 (Fri, 01 Feb 2019) $
;$LastChangedRevision: 26540 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/common/icon_check_att.pro $
;
;-------------------------------------------------------------------

pro icon_check_att, var, gdims, var_dim, replaced, depend_only=depend_only
  sample_cdf = ['catdesc','Display_type','Fieldnam','FillVal','Format','LablAxis', $
    'Scaletyp','Units','validmin','validmax','var_type']
  depend_cdf = 'depend_'
  sample_cdf_time = ['time_base','time_scale']

  ;    stop

  if(~keyword_set(depend_only)) then begin
    for j=0,10 do begin
      if(~tag_exist(var, sample_cdf[j],index=v_index)) then begin
        case j of
          1: Begin
            s = size(*var.dataptr,/n_dimensions)
            if(s le 1) then add_value = 'time_series'
            if(s eq 2) then add_value = 'spectrogram'
            if(s gt 2) then add_value = 'spectrogram'
          end
          3: Begin
            t = size(*var.dataptr,/type)
            case t of
              1: add_value = 255b
              2: add_value = -999
              3: add_value = -999l
              4: add_value = !values.F_NAN
              5: add_value = !values.d_nan
              7: add_value = "I'M A FILL VALUE SINCE I WASN'T GIVEN IN THE ORIGINAL NETCDF FILE"
              12: add_value = 65535U
              13: add_value = 65535UL
              14: add_value = 4294967295LL
              15: add_value = 4294967295ULL
              else: stop
            endcase
          end
          6: add_value = 'linear'
          8: add_value = min(*var.dataptr)
          9: add_value = max(*var.dataptr)
          else:add_value = "" ;"THIS WASN'T IN THE ORIGINAL NETCDF FILE.  I ADDED THIS TO MAKE SPEDAS WORK!"
        endcase
        str_element,var,sample_cdf[j],add_value,/add_rep
        ;      stop
      endif else begin
        type_check = size(var.(v_index),/type)
        ;        stop
        if(type_check eq 1) then str_element,var,sample_cdf[j],string(var.(v_index)),/add_rep
      endelse
    endfor
  endif

  Dim_test =  where(strmatch(tag_names(gdims),var.name,/fold_case) eq 1,/null)
  if(dim_test eq !NULL && replaced ne !NULL) then begin
    for i = 0,n_elements(var_dim)-1 do begin
      add_depend = depend_cdf+strcompress(string(i),/remove_all)
      ;  if(~tag_exist(var,add_depend)) then begin
      Ind_r = where(replaced[*,0] eq var_dim[i],/null)
      str_element,var,add_depend,gdims.(replaced[ind_r,1]).name,/add_rep
      ; endif
      ;      stop

      ;      if(where(strmatch(tag_names(var),'depend_?',/fold_case) eq 1,/null) eq !null) then begin
      ;
      ;      endif
      ;    ind_0 = where(var_dim eq 0,/null)
      ;    ind_n = where(var_dim ne 0,/null)
      ;    if(ind_0 ne !NULL) then str_element,var,depend_cdf[0],gdims.(var_dim[ind_0]).name,/add_rep
      ;    for i=0,n_elements(ind_n)-1 do begin
      ;      str_element,var,depend_cdf[i+1],gdims.(var_dim[ind_n[i]]).name,/add_rep
    endfor
  endif

  ;stop
  if(~keyword_set(depend_only)) then begin
    if(strmatch(var.name, 'Epoch',/FOLD_CASE)) then begin
     ; if(~tag_exist(var, sample_cdf_time[0])) then str_element,var,sample_cdf_time[0], $
     ;   "THIS WASN'T IN THE ORIGINAL NETCDF FILE.  I ADDED THIS TO MAKE SPEDAS WORK!",/add_rep
     ; if(~tag_exist(var, sample_cdf_time[1])) then str_element,var,sample_cdf_time[1], $
     ;   "THIS WASN'T IN THE ORIGINAL NETCDF FILE.  I ADDED THIS TO MAKE SPEDAS WORK!",/add_rep
    endif
  endif
end