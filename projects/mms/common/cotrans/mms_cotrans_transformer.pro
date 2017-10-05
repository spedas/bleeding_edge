;+
;Procedure:
;  mms_cotrans_transformer
;
;Purpose:
;  Helps simplify transformation logic code using a recursive formulation.
;  Rather than specifying the set of transformations for each combination of
;  in_coord & out_coord, this routine will perform only the nearest transformation
;  then make a recursive call to itself, with each call performing one additional
;  step in the chain.  This makes it so only neighboring coordinate transforms 
;  need be specified.
;
;  The set of possible transformations forms the following graph:
;            GSE<->AGSM
;             |
;     DMPA<->GSE<->GSM<->SM
;             |
;            GSE<->GEI<->GEO<->MAG
;                   |
;                  GEI<->J2000
;
;Input:
;  in_name:  name of variable to be transformed
;  out_name:  output name for transformed variable
;  in_coord:  coordinate system of the input
;  out_coord:  coordinate system of the output
;  
;  spinras:  name of spacecraft right ascension variable
;  spindec:  name of spacecraft declination variable 
;
;  ingnore_dlimits:  ignore variable metadata
;
;Output:
;  No explicit output, calls transformation routines and itself
;
;Notes:
;  - Modeled after thm_cotrans_transform_helper
;  
;  - the dmpa2dsl transformation is an identity 
;    transformation (dmpa is approximately the same as dsl; 
;    see the notes in the header of dmpa2gse for more info)
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-06-12 15:08:37 -0700 (Mon, 12 Jun 2017) $
;$LastChangedRevision: 23455 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/mms_cotrans_transformer.pro $
;-

pro mms_cotrans_transformer, $
  
          ; names and coords
          in_name, $
          out_name, $
          in_coord, $
          out_coord, $
          
          ; support data
          spinras, $
          spindec, $

          ; other
          ignore_dlimits=ignore_dlimits


  compile_opt idl2, hidden


; Final coordinate system reached
;------------------------------------------------
if in_coord eq out_coord then begin
  if in_name ne out_name then begin
    copy_data, in_name, out_name
  endif
  return
endif


; Execute next step in transformation tree
;------------------------------------------------
case in_coord of 

  ; DSL
  ;----------
  'dsl': begin
    case out_coord of 
      ;tbd
      else: begin
        dmpa2dsl, in_name, out_name, /dsl2dmpa, ignore_dlimits=ignore_dlimits
        recursive_in_coord = 'dmpa'
      endelse
    endcase
  end

  ; DMPA
  ;----------
  'dmpa': begin
    case out_coord of 
      'dsl': begin
        dmpa2dsl, in_name, out_name, ignore_dlimits=ignore_dlimits
        recursive_in_coord = 'dsl'
      end
      else: begin
        spd_cotrans_validate_transform, in_name, in_coord, out_coord
        dmpa2gse, in_name, spinras, spindec, out_name, ignore_dlimits=ignore_dlimits
        recursive_in_coord = 'gse'
      endelse
    endcase
  end

  ; GSE
  ;----------
  'gse': begin
    case out_coord of
      'dmpa': begin
        spd_cotrans_validate_transform, in_name, in_coord, out_coord
        dmpa2gse, /gse2dmpa, in_name, spinras, spindec, out_name, ignore_dlimits=ignore_dlimits
        recursive_in_coord = 'dmpa'
      end
      'sm': begin
        cotrans, in_name, out_name, /gse2gsm,ignore_dlimits=ignore_dlimits
        recursive_in_coord='gsm'
      end
      'gsm': begin
        cotrans, in_name, out_name, /gse2gsm,ignore_dlimits=ignore_dlimits
        recursive_in_coord='gsm'
      end
      'agsm': begin
        ; using a rotation angle of 4 degrees when transforming to aGSM coordinates in the GUI
        gse2agsm, in_name, out_name, rotation_angle = 4.0
        recursive_in_coord='agsm'
      end
      else: begin
        spd_cotrans_validate_transform, in_name, in_coord, out_coord
        cotrans, in_name, out_name, /gse2gei, ignore_dlimits=ignore_dlimits
        recursive_in_coord='gei'
      endelse
    endcase
  end

  ; AGSM
  ;----------
  'agsm': begin
    agsm2gse, in_name, out_name, rotation_angle = 4.0
    recursive_in_coord='gse'
  end

  ; SM
  ;----------
  'sm': begin
     cotrans, in_name, out_name, /sm2gsm, ignore_dlimits=ignore_dlimits
     recursive_in_coord='gsm'
  end

  ; GSM
  ;----------
  'gsm': begin
    case out_coord of
      'sm': begin
        cotrans, in_name, out_name, /gsm2sm, ignore_dlimits=ignore_dlimits
        recursive_in_coord='sm'
      end
      else: begin
        cotrans, in_name, out_name, /gsm2gse, ignore_dlimits=ignore_dlimits
        recursive_in_coord='gse'
      endelse
    endcase
  end

  ; GEI
  ;----------
  'gei': begin
    spd_cotrans_validate_transform, in_name, in_coord, out_coord
    case out_coord of
      'geo': begin
        cotrans, in_name, out_name, /gei2geo, ignore_dlimits=ignore_dlimits
        recursive_in_coord='geo'
      end
      'mag': begin
        cotrans, in_name, out_name, /gei2geo, ignore_dlimits=ignore_dlimits
        recursive_in_coord='geo'
      end
      'j2000': begin
        cotrans, in_name, out_name, /gei2j2000, ignore_dlimits=ignore_dlimits
        recursive_in_coord='j2000'
      end
      else: begin
        cotrans, in_name, out_name, /gei2gse, ignore_dlimits=ignore_dlimits
        recursive_in_coord='gse'
      endelse
    endcase
  end

  ; GEO
  ;----------
  'geo': begin 
    case out_coord of
      'mag': begin
        cotrans,in_name,out_name,/geo2mag,ignore_dlimits=ignore_dlimits
        recursive_in_coord='mag'            
        break
      end
      else: begin
        spd_cotrans_validate_transform, in_name, in_coord, out_coord
        cotrans,in_name,out_name,/geo2gei,ignore_dlimits=ignore_dlimits
        recursive_in_coord='gei'
        break
      end
    endcase 
  end

  ; MAG
  ;----------
  'mag': begin
      cotrans,in_name,out_name,/mag2geo,ignore_dlimits=ignore_dlimits
      recursive_in_coord='geo'
  end

  ; J2000
  ;----------
  'j2000': begin
      cotrans,in_name,out_name,/j20002gei,ignore_dlimits=ignore_dlimits
      recursive_in_coord='gei'
  end

  ; No known transformation
  ;---------------------------
  else: begin
    dprint, dlevel=0, sublevel=1, 'Unknown transformation: "'+ in_coord+'" to "'+out_coord+'"'
    recursive_in_coord = out_coord
  endelse

endcase


; Recurse
;   -if this was the final step then the next iteration will return
;------------------------------------------------
mms_cotrans_transformer,$
    out_name, $  ;don't create new vars as we iterate
    out_name, $
    recursive_in_coord, $  ;result of this iteration 
    out_coord, $
    spinras, $
    spindec, $
    ignore_dlimits=ignore_dlimits 
  
end