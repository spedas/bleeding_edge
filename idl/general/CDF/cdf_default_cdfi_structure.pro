;+
;PURPOSE: 
; Number of functions that generate default structures for CDF files
; This file is designed for developers
; 
; Please use TPLOT_ADD_CDF_STRUCTURE instead
; 
;CREATED BY:
;  Alexander Drozdov
; 
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-02-12 12:13:23 -0800 (Mon, 12 Feb 2018) $
; $LastChangedRevision: 24690 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/cdf_default_cdfi_structure.pro $
;-

function cdf_default_inq_structure
  ;   Basic parameters are requred by cdf_save_vars
  ;   CDFI.INQ.DECODING = 'HOST_DECODING' (can be network or host)
  ;   CDFI.INQ.ENCODING = 'NETWORK_ENCODING' (can be network or host)
  ;   CDFI.INQ.MAJORITY = 'COL_MAJOR' (can be row or column)
  inq = {$
    DECODING:'HOST_DECODING',$
    ENCODING:'HOST_ENCODING',$
    MAJORITY:'COL_MAJOR'$
  }
  return, inq
end

function cdf_default_g_attributes_structure
  g_attributes ={$
    Data_type: 'tplot',$
    Data_version: '1',$ 
    Descriptor:'tplot',$
    Discipline: 'Space Physics',$
    Instrument_type: 'tplot',$
    Logical_file_id:'',$ 
    Logical_source: 'tplot',$
    Logical_source_description:'cdf generated from tplot variable',$
    Mission_group: 'SPEDAS',$
    PI_affiliation: 'undefined',$
    PI_name: 'undefined',$
    Project:'SPEDAS',$
    Source_name:'SPEDAS',$
    TEXT: 'none'$
  }
  return, g_attributes
end

function cdf_default_attr_structure
attr = {$
  CATDESC:'none',$
  ;DEPEND_0:'',$
  ;DEPEND_1:'',$
  ;DEPEND_2:'',$
  ;DEPEND_3:'',$
  DISPLAY_TYPE:'undefined',$
  FIELDNAM:'none',$   
  FORMAT:'undefined',$
  LABLAXIS:'undefined',$  
  UNITS:'undefined',$  
  VAR_TYPE:'undefined'$
  ; FILLVAL:'undefined',$  ; idl-type dependent
  ; VALIDMIN:'undefined',$ ; idl-type dependent
  ; VALIDMAX:'undefined',$ ; idl-type dependent
  ; LABL_PTR_1:'',$
  ; LABL_PTR_2:'',$
  ; LABL_PTR_3:'',$
}
return, attr
end

function cdf_default_vars_structure
  vars = {$
    NAME:'',$      ; name of the variable
    NUM:0,$
    IS_ZVAR:0,$
    DATATYPE:'',$  ; type of data
    TYPE:0,$       ; CDF type type 
    NUMATTR:-1,$
    NUMELEM:0,$
    RECVARY:1b,$   ; is the variable time varying 
    NUMREC:01,$
    NDIMEN:0,$     ; number of dimentions
    D:lonarr(6),$  ; potential potential variable size
    DATAPTR:ptr_new(),$
    ATTRPTR:ptr_new(cdf_default_attr_structure())$
  }
  return, vars
end

function cdf_default_cdfi_structure
  ;   CDFI.FILENAME = Name of the CDF file
  ;   CDFI.INQ = A structure with information about the file
  ;   CDFI.g_atttributes = A structure, CDF global attributes
  ;   CDFI.NV = Number of variables
  ;   CDFI.VARS = AN array of CDFI.NV structures, one for each zvariable:

  cdfi = {FILENAME:'',$
    INQ: cdf_default_inq_structure(),$
    g_attributes: cdf_default_g_attributes_structure(),$
    NV: 0$
    ; VARS: array of vars
  }
  return, cdfi
end