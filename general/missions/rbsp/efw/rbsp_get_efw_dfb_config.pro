;+
; NAME:
;   rbsp_get_efw_dfb_config (function)
;
; PURPOSE:
;   Decode the EFW DFB Config byte 
;
; CALLING SEQUENCE:
;   result = rbsp_get_efw_dfb_config(config_byte)
;
; ARGUMENTS:
;   config_byte: (Input, required) Integer or array of integers containing the DFB config byte
;
; KEYWORDS:
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2013-04-03: Created by Peter Schroeder (PCS), SSL, UC Berkley.
;
;
; Version:
;
; $LastChangedBy: peters $
; $LastChangedDate: 2013-04-08 10:45:51 -0700 (Mon, 08 Apr 2013) $
; $LastChangedRevision: 11983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_get_efw_dfb_config.pro $
;-


function rbsp_get_efw_dfb_config,config_byte

;empty dfb_config structure
dfb_config = { valid:1, $ ; 1 or 0, depending upon whether the dfb_config_code lookup was successful.
  spec_config:{ $
    valid:1, $ ;depending upon whether there's a SPEC config properly defined (prob. always 1).
    spec_ncad:3, $
    spec_navg:3, $
    spec_enable:[ 1, 1, 1, 1, 1, 1, 1], $
    spec_src: replicate('unk',7) }, $
  xspec_config:{ $
    valid:1, $ ;depending upon whether there's a XSPEC config properly defined (prob. always 1).
    xspec_ncad:3, $ ; has to be the same as spec_ncad.
    xspec_navg:2, $ ; has to be <= NCAD.
    xspec_enable:[ 1, 1, 1], $
    xspec_src1: replicate('unk',3), $
    xspec_src2: replicate('unk',3) } $
}

number_of_bytes = n_elements(config_byte)

dfb_config_array = replicate(dfb_config, number_of_bytes)

;default is nonvalid dfb configuration
dfb_config_array[*].valid = 0
dfb_config_array[*].spec_config.valid = 0
dfb_config_array[*].xspec_config.valid = 0

;config_byte is not an integer so invalid
if size(/type, config_byte[0]) ne 2 then begin
   print, 'config_byte must be an integer'
   return, dfb_config_array
endif

;now for config_byte of 00x
index_0 = where(config_byte eq 0, num_index_0)
if num_index_0 ne 0 then begin
   dfb_config_array[index_0].valid = 1
   dfb_config_array[index_0].spec_config.valid = 1
   dfb_config_array[index_0].spec_config.spec_ncad = 5
   dfb_config_array[index_0].spec_config.spec_navg = 3
   dfb_config_array[index_0].spec_config.spec_enable = replicate(1, 7)
   dfb_config_array[index_0].spec_config.spec_src = ['E12AC','E56AC','SCMU','SCMV','SCMW','V1AC','V2AC']
   dfb_config_array[index_0].xspec_config.valid = 1
   dfb_config_array[index_0].xspec_config.xspec_ncad = 5
   dfb_config_array[index_0].xspec_config.xspec_navg = 3
   dfb_config_array[index_0].xspec_config.xspec_enable = [1, 0, 0]
   dfb_config_array[index_0].xspec_config.xspec_src1 = ['SCMW','V1AC','unk']
   dfb_config_array[index_0].xspec_config.xspec_src2 = ['E12AC','V2AC','unk']
endif

;now for config_byte of 01x
index_1 = where(config_byte eq 1, num_index_1)
if num_index_1 ne 0 then begin
   dfb_config_array[index_1].valid = 1
   dfb_config_array[index_1].spec_config.valid = 1
   dfb_config_array[index_1].spec_config.spec_ncad = 5
   dfb_config_array[index_1].spec_config.spec_navg = 3
   dfb_config_array[index_1].spec_config.spec_enable = replicate(1, 7)
   dfb_config_array[index_1].spec_config.spec_src = ['E12AC','E56AC','SCMU','SCMV','SCMW','V1AC','V2AC']
   dfb_config_array[index_1].xspec_config.valid = 1
   dfb_config_array[index_1].xspec_config.xspec_ncad = 5
   dfb_config_array[index_1].xspec_config.xspec_navg = 3
   dfb_config_array[index_1].xspec_config.xspec_enable = [1, 0, 0]
   dfb_config_array[index_1].xspec_config.xspec_src1 = ['SCMW','V1AC','unk']
   dfb_config_array[index_1].xspec_config.xspec_src2 = ['E12AC','V2AC','unk']
endif

return, dfb_config_array

end

