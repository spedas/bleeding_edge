;+
; PRO ERG_COTRANS
;
; :Description:
;    To transform time series data from one coordinate to another. The supported coordinate 
;     systems are: SGA, SGI, DSI, J2000. Further transformation from J2000 to the 
;     geophysical coordinates (GEI, GSE, etc) can be processed by "cotrans". 
;     
;     The actual transformation is done by helper procedures, such as sga2sgi, sgi2dsi, 
;     and dsi2j2000. 
;     
;     
; :Params:
;   in_name: name of input tplot variable to be transformed 
;   out_name: name of output tplot variable in which the transformed data are stored. 
;             If not explicitly provided, out_name is automatically generated from 
;             "in_name" by replacing the 3-letter coordinate name with a new one. 
;             For example, if you runs erg_cotrans, 'xxxx_sgi', out_coord='sga', 
;             then the result is stored in a newly created tplot variable 'xxxx_sga'. 
;
; :Keywords:
;   in_coord: Set to explicitly give the coordinate system name for the input variable.
;             If not given, this routine tries to guess it from the name of the input 
;             tplot variable (in_name). 
;   out_coord: Set to explicitly give the coordinate system name for the output variable.
;              If not given, the coordinate system name is obtained from the variable name 
;              as done for in_coord. 
;
;     For both keywords, valid coordinate names are: 'sga', 'sgi', 'dsi', and 'j2000'
;     
; :Examples:
;
;   IDL> erg_cotrans, 'erg_mgf_mag_8sec_sgi', 'erg_mgf_mag_8sec_dsi' 
;   IDL> erg_cotrans, 'erg_att_sundir_j2000', in_coord='j2000', out_coord='dsi' 
;   IDL> erg_cotrans, 'erg_lepe_*_sga', out_coord='sgi' 
;
; :History:
; 2016/10/13: drafted
; 2017/07/12: modified to read L2 txt file for attitude.
;
; :Author: Tomo Hori, ISEE (tomo.hori at nagoya-u.jp)
;
;   $LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;   $LastChangedRevision: 27922 $
;
;-
;
; Helper procedures/functions
function get_suf_from_varname, in_name 
  nms = strsplit( in_name, '_', /ext ) 
  return, nms[ n_elements(nms)-1 ] 
end

pro erg_replace_coord_suffix, in_name, out_coord, out_name 

  nms = strsplit( in_name, '_', /ext )
  nms[ n_elements(nms)-1 ] = out_coord
  out_name = strjoin( nms, '_' )

end

pro erg_coord_trans, in_name, out_name, in_coord=in_coord, out_coord=out_coord, noload=noload

  ;the same coord is given: Do nothing or just copy the input variable with another name
  if in_coord eq out_coord then begin
    if in_name ne out_name then copy_data, in_name, out_name 
    return
  endif

  case (in_coord) of
    ;From SGA
    'sga': begin

      case (out_coord) of
        'sgi': begin
          sga2sgi, in_name, out_name, noload=noload
        end
        'dsi':begin ;sga --> sgi --> dsi
          erg_replace_coord_suffix, in_name, 'sgi', name_sgi
          sga2sgi, in_name, name_sgi, noload=noload
          sgi2dsi, name_sgi, out_name, noload=noload
        end
        'j2000':begin ;sga --> sgi --> dsi --> j2000
          erg_replace_coord_suffix, in_name, 'sgi', name_sgi
          sga2sgi, in_name, name_sgi, noload=noload
          erg_replace_coord_suffix, name_sgi, 'dsi', name_dsi
          sgi2dsi, name_sgi, name_dsi, noload=noload
          dsi2j2000, name_dsi, out_name, noload=noload
        end
      endcase

    end

    ;From SGI
    'sgi': begin

      case (out_coord) of
        'sga': begin ;sgi --> sga
          sga2sgi, in_name, out_name, /sgi2sga, noload=noload
        end
        'dsi':begin ;sgi --> dsi
          sgi2dsi, in_name, out_name, noload=noload
        end
        'j2000':begin ;sgi --> dsi --> j2000
          erg_replace_coord_suffix, in_name, 'dsi', name_dsi
          sgi2dsi, in_name, name_dsi, noload=noload
          dsi2j2000, name_dsi, out_name, noload=noload
        end
      endcase

    end

    ;From DSI
    'dsi': begin

      case (out_coord) of
        'sga': begin ;dsi --> sgi --> sga
          erg_replace_coord_suffix, in_name, 'sgi', name_sgi
          sgi2dsi, in_name, name_sgi, /dsi2sgi, noload=noload
          sga2sgi, name_sgi, out_name, /sgi2sga, noload=noload
        end
        'sgi':begin ;dsi --> sgi
          sgi2dsi, in_name, out_name, /dsi2sgi, noload=noload
        end
        'j2000':begin ;dsi --> j2000i
          dsi2j2000, in_name, out_name, noload=noload
        end
      endcase

    end

    ;From J2000
    'j2000': begin

      case (out_coord) of
        'sga': begin ;j2000 --> dsi --> sgi --> sga
          erg_replace_coord_suffix, in_name, 'dsi', name_dsi
          dsi2j2000, in_name, name_dsi, /j20002dsi, noload=noload
          erg_replace_coord_suffix, name_dsi, 'sgi', name_sgi
          sgi2dsi, name_dsi, name_sgi, /dsi2sgi, noload=noload
          sga2sgi, name_sgi, out_name, /sgi2sga, noload=noload
        end
        'sgi':begin ;j2000 --> dsi --> sgi
          erg_replace_coord_suffix, in_name, 'dsi', name_dsi
          dsi2j2000, in_name, name_dsi, /j20002dsi, noload=noload
          sgi2dsi, name_dsi, out_name, /dsi2sgi, noload=noload
        end
        'dsi':begin ;dsi --> j2000i
          dsi2j2000, in_name, out_name, /j20002dsi, noload=noload
        end
      endcase

    end

  endcase
  
  
  return
end


;;;; Main routine for coordinate transformation ;;;;; 
pro erg_cotrans, $
  in_name, $   ;tplot variable(s) to be transformed
  out_name, $ ;tplot variable name(s) in which the result(s) is stored
  in_coord=in_coord, $;coord. system of the input. If not given, the code sees coord_sys attribute
  out_coord=out_coord, $ ;coord. system of the result
  out_suffix=out_suffix, $ ;(optional, not implemented yet) 
  noload=noload  ;No data file is newly loaded if set

  ;Definition of the suffixes for coordinate system name
  valid_suffixes = strsplit( 'sga sgi dsi j2000', /ext )


  ;Check the arguments and keywords

  ;Number of arguments
  npar = n_params()
  if npar eq 0 then return
  if npar eq 1 then out_name = '' ;Only in_name is given 
  
  ;Does at least one input variable exist? If so, obtain the number of valid variables 
  if ( tnames(in_name) )[0] eq '' then return
  idx = where( tnames(in_name) ne '', in_name_num ) 
  in_name = tnames( in_name[ idx ] )
  
  ;Check in_coord and out_coord
  if undefined( in_coord ) then in_suf = '' else begin
    in_suf = ssl_check_valid_name( in_coord, valid_suffixes )
  endelse
  if undefined( out_coord ) then out_suf = '' else begin
    out_suf = ssl_check_valid_name( out_coord, valid_suffixes )
  endelse

  ;A simple case in which a given variable is converted to the resultant variable.
  if in_name_num eq 1 then begin
    
    if in_suf eq '' then begin ;Find the coord. suffix from the variable name
      in_suf = ssl_check_valid_name( get_suf_from_varname( in_name), valid_suffixes )
      if in_suf eq '' then message, 'Cannot get a valid coord. suffix of input variable.'
    endif
    
    if n_elements(out_name) eq 1 and out_name ne '' then begin ;out_name is given as a single string
      if out_suf eq '' then begin ;Find the coord. suffix from the variable name
        out_suf = ssl_check_valid_name( get_suf_from_varname( out_name ), valid_suffixes )
        if out_suf eq '' then message, 'Cannot get a valid coord. suffix of output variable'
      endif
    endif else begin ; out_name is not given or contains more then one string --> ignored
      if out_suf eq '' then message, 'Both out_name and out_coord are given!'
      erg_replace_coord_suffix, in_name, out_suf, out_name 
    endelse
    erg_coord_trans, in_name, out_name, in_coord=in_suf, out_coord=out_suf, noload=noload

    return
  endif
  
  ;A case in which multiple input names are given as multiple strings or a string with wildcards
  if in_name_num gt 1 then begin
    ;If multiple input variables are given, out_name is ignored and in/out_coord are necessary
    if out_suf eq '' then message, 'out_coord is not properly given.'
    
    for i=0, n_elements(in_name)-1 do begin
      
      inname = in_name[i] 
      if in_suf eq '' then begin ;Find the coord. suffix from the variable name
        in_suf = ssl_check_valid_name( get_suf_from_varname( inname), valid_suffixes )
        if in_suf eq '' then message, 'Cannot get a valid coord. suffix of input variable.'
      endif
      
      erg_cotrans, inname, in_coord=in_suf, out_coord=out_suf, noload=noload 
      
    endfor
    
    return
  endif
  
  
  











  return
end



