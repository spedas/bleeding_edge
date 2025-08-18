; This program controls the history of all the changes made to the FOMstr.
; Usually called immediately after 'sppeva_sitl_tplot_update' (After the "Edit"
; button is pressed.)
;
PRO sppeva_sitl_stack
  vvv = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr')
  get_data,vvv,data=D,lim=lim,dl=dl
  if n_tags(dl) gt 0 then begin
    case !SPPEVA.COM.MODE of
      'FLD':begin
        !SPPEVA.STACK.FLD_LIST.Add, dl.FOMstr
        !SPPEVA.STACK.FLD_I += 1
        end
      'SWP':begin
        !SPPEVA.STACK.SWP_LIST.Add, dl.FOMstr
        !SPPEVA.STACK.SWP_I += 1
        end
       else:message,"Something is wrong.'
    endcase
  endif
END