;+
; NAME:
;   SPP_FLD_CDF_PUT_METADATA
;
; PURPOSE:
;   Add metadata to a SPP FIELDS CDF file.
;   This includes general metadata which applies for all SPP data products
;   as well as file-specific attributes from the XML files which define
;   the data items.  Variable attributes are created as well.
;
; CALLING SEQUENCE:
;   spp_fld_cdf_put_metadata, fileid, filename, cdf_atts
;
; INPUTS:
;   FILEID: The file ID of the destination CDF file.
;   FILENAME: The name of the CDF file.
;   CDF_ATTS: File-specific CDF attributes, read from the XML file which
;     defines the data product.
;   
; OUTPUTS:
;   No explicit outputs are returned.  After completion, the data in the
;   input IDL hash is stored in the specified CDF file.;
;
; EXAMPLE:
;   See call in SPP_FLD_MAKE_CDF_L1.
;
; CREATED BY:
;   pulupa
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2018-05-08 15:00:03 -0700 (Tue, 08 May 2018) $
; $LastChangedRevision: 25182 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_cdf_put_metadata.pro $
;-

pro spp_fld_cdf_put_metadata, fileid, filename, cdf_atts

  ; Create attributes for CDF metadata

  dummy = cdf_attcreate(fileid,'Title',/global_scope)
  dummy = cdf_attcreate(fileid,'Project',/global_scope)
  dummy = cdf_attcreate(fileid,'Discipline',/global_scope)
  dummy = cdf_attcreate(fileid,'Source_name',/global_scope)
  dummy = cdf_attcreate(fileid,'Descriptor',/global_scope)
  dummy = cdf_attcreate(fileid,'Data_type',/global_scope)
  dummy = cdf_attcreate(fileid,'Data_version',/global_scope)
  dummy = cdf_attcreate(fileid,'TEXT',/global_scope)
  dummy = cdf_attcreate(fileid,'Mods',/global_scope)
  dummy = cdf_attcreate(fileid,'Logical_file_id',/global_scope)
  dummy = cdf_attcreate(fileid,'Logical_source',/global_scope)
  dummy = cdf_attcreate(fileid,'Logical_source_description',/global_scope)
  dummy = cdf_attcreate(fileid,'PI_name',/global_scope)
  dummy = cdf_attcreate(fileid,'PI_affiliation',/global_scope)
  dummy = cdf_attcreate(fileid,'Instrument_type',/global_scope)
  dummy = cdf_attcreate(fileid,'Mission_group',/global_scope)
  dummy = cdf_attcreate(fileid,'Parents',/global_scope)
  dummy = cdf_attcreate(fileid,'Dependencies',/global_scope)

; TODO: Place this information in an XML file along with the data definitions?

  ; Add CDF metadata which is general for all PSP data products

  cdf_attput, fileid, 'Project', 0, 'PSP'
  cdf_attput, fileid, 'Discipline', 0, 'Solar Physics>Heliospheric Physics'
  cdf_attput, fileid, 'Discipline', 1, 'Space Physics>Interplanetary Studies'
  cdf_attput, fileid, 'Source_name', 0, 'SPP>Solar Probe Plus'
  cdf_attput, fileid, 'PI_name', 0,'Stuart D. Bale (bale@ssl.berkeley.edu)'
  cdf_attput, fileid, 'PI_affiliation', 0, 'UC Berkeley Space Sciences Laboratory'
  cdf_attput, fileid, 'Instrument_type', 0, 'Electric Fields (space)'
  cdf_attput, fileid, 'Instrument_type', 1, 'Magnetic Fields (space)'
  cdf_attput, fileid, 'Mission_group', 0, 'PSP'

  cdf_attput, fileid, 'Logical_file_id', 0, filename

  ; Add file-specific CDF metadata (read from the XML file)

  foreach att, cdf_atts, attname do $
    cdf_attput, fileid, attname, 0, att

  ; Create CDF variable attributes

  dummy = cdf_attcreate(fileid,'FIELDNAM',/variable_scope)
  dummy = cdf_attcreate(fileid,'MONOTON',/variable_scope)
  dummy = cdf_attcreate(fileid,'FORMAT',/variable_scope)
  dummy = cdf_attcreate(fileid,'FORM_PTR',/variable_scope)
  dummy = cdf_attcreate(fileid,'LABLAXIS',/variable_scope)
  dummy = cdf_attcreate(fileid,'VAR_TYPE',/variable_scope)
  dummy = cdf_attcreate(fileid,'FILLVAL',/variable_scope)
  dummy = cdf_attcreate(fileid,'DEPEND_0',/variable_scope)
  dummy = cdf_attcreate(fileid,'DEPEND_1',/variable_scope)
  dummy = cdf_attcreate(fileid,'DEPEND_2',/variable_scope)
  dummy = cdf_attcreate(fileid,'DEPEND_3',/variable_scope)
  dummy = cdf_attcreate(fileid,'DISPLAY_TYPE',/variable_scope)
  dummy = cdf_attcreate(fileid,'VALIDMIN',/variable_scope)
  dummy = cdf_attcreate(fileid,'VALIDMAX',/variable_scope)
  dummy = cdf_attcreate(fileid,'SCALEMIN',/variable_scope)
  dummy = cdf_attcreate(fileid,'SCALEMAX',/variable_scope)
  dummy = cdf_attcreate(fileid,'UNITS',/variable_scope)
  dummy = cdf_attcreate(fileid,'CATDESC',/variable_scope)
  dummy = cdf_attcreate(fileid,'VAR_SPARSERECORDS',/variable_scope)
  dummy = cdf_attcreate(fileid,'DATA_TYPE',/variable_scope)

end