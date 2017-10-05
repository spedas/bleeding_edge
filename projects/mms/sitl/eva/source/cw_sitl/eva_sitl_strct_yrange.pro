; The yrange of tplot-variables 'mms_stlm_output_fom' and 'mms_stlm_fomstr' are
; defined in "eva_sitl_struct_update" by calling the procedure below.
;
; Then, when highlighting (i.e, in eva_sitl_highlight), this procedure is
; called again to retrieve the yrange.
; 
PRO eva_sitl_strct_yrange, tpv, yrange=yrange
  compile_opt idl2
  
  get_data,tpv,data=S,lim=lim,dl=dl; S should be an array of strings
  sz=size(S,/type)
  
  case sz of
    7:begin
        Dyt = 0.
        imax = n_elements(S)
        for i=0,imax-1 do begin
          if (strpos(S[i],'zero') eq -1) then begin
            get_data,S[i],data=D
            Dyt = [Dyt, D.y]
          endif
        endfor
      end
    8:begin
        Dyt = S.y
      end
    else:begin
      stop
      print, 'EVA: ', sz
      message,"Something is wrong"
      end
  endcase
  ;////////////////////////////////////
  Dymax = max(Dyt,/nan)*1.1 < 255.
  ;////////////////////////////////////
  yrange = [0.,Dymax]
  ylim,tpv, yrange
END
