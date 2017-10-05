;+
; NAME:
;   SPP_FLD_CDF_PUT_DEPEND
;
; PURPOSE:
;   Add support variables to a SPP FIELDS CDF file.
;   Some dimensional CDF variables (such as spectrograms) require additional
;   support data which are not directly specified in the data packet.  
;   For example, the frequencies of the RFS LFR and HFR spectra are not 
;   included in the LFR and HFR packets.  The XML definition of the packet
;   can optionally include a key (ADD_CDF_DEPEND_ROUTINE) which specifies
;   an IDL routine that adds the support variable to the CDF.
;
; CALLING SEQUENCE:
;   spp_fld_cdf_put_depend, fileid, idl_att = idl_att
;
; INPUTS:
;   FILEID: The file ID of the destination CDF file.
;   IDL_ATT: If set, contains the 'IDL_ATT' attributes returned from reading
;     the XML file defining the structure of the data to be stored in the CDF.
;     If this exists, and if it has a key ADD_CDF_DEPEND_ROUTINE, then the
;     defined routine is run and adds support variable(s) to the CDF.
;     If not, this routine has no effect.
;
; OUTPUTS:
;   No explicit outputs are returned.  After completion, the support data is
;   stored in the specified CDF file.
;
; EXAMPLE:
;   See call in SPP_FLD_MAKE_CDF_L1.
;
; CREATED BY:
;   pulupa
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2017-01-11 16:14:34 -0800 (Wed, 11 Jan 2017) $
; $LastChangedRevision: 22579 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_cdf_put_depend.pro $
;-
pro spp_fld_cdf_put_depend, fileid, idl_att = idl_att

  if n_elements(idl_att) EQ 0 then return
  
  if idl_att.HasKey('add_cdf_depend_routine') then begin
    
    call_procedure, idl_att['add_cdf_depend_routine'], fileid
    
  endif

end