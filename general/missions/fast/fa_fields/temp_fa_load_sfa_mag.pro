;+
;PURPOSE:
; Temporary program to load FAST MAG SFA files created from Level0
; data via SDT.
;CALLING SEQUENCE:
; temp_fa_load_sfa_mag, filename
;INPUT:
; filename = file to input, full path please
;OUTPUT:
; tplot variables:
; fa_SfaAve_Mag3AC_Data  - this is the data variable, THIS IS THE ONLY
;                         T-PLOTTABLE variable
; fa_Sdt_Cdf_MDim_Sizes_by_Record - data size of the frequency variable
; fa_MinMaxVals_Dim_1_SubDim_1_1 - min and max values of the frequency
;                               bands, units are kHz, and a quality
;                               value for each band. THis variable is
;                               used to create the 'v' tag in the data variable.
; fa_Data_MinMax_Offset_Dim_1_SubDim_1_1 - The variable:
;                                       Data_MinMax_Offset contains,
;                                       for each data array, the
;                                       record offset into the
;                                       corresponding MinMaxVals
;                                       variable for each dimension
;                                       and sub-dimension.  Note that
;                                       the number of records is given
;                                       by the size of the dimension
;                                       from the
;                                       Sdt_Cdf_MDim_Sizes_by_Record
;                                       variable.
; fa_DimensionDescription_Dim_1_SubDim_1_1 - a string denoting the
;                                         frequency variable
;KEYWORDS; 
; frequency_binning = if set, thie will bin this number of
;                     frequency bins together, use frequency_binning =
;                     4 to compare with online ACF_K0 files. THis adds
;                     another variable, with "_bin"+frequency_binvalue
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2020-04-15 15:51:41 -0700 (Wed, 15 Apr 2020) $
;$LastChangedRevision: 28585 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_fields/temp_fa_load_sfa_mag.pro $
Pro temp_fa_load_sfa_mag, filename, _extra=_extra, $
                          frequency_binning = frequency_binning

;for plotting purposes
  fa_init
;create tplot variables using cdf2tplot
;extract data type from filename
  bfile = file_basename(filename, '.cdf')
  ttp = strsplit(bfile, '_', /extract)
  nttp = n_elements(ttp)
  datatype = ttp[nttp-1]
  data_var = 'SfaAve_'+datatype+'_Data'
  If(is_string(tnames(data_var))) Then del_data, data_var
  cdf2tplot, files = filename, /all, /smex
  If(~is_string(tnames(data_var))) Then Begin
     dprint, 'No data in file: '+filename
     Return
  Endif
;Here we have data, but need to add
;the frequency to the data variable
  get_data, data_var, data = d
  If(~is_struct(d)) Then Begin
     dprint, 'No data in file: '+filename
     Return
  Endif
;Get frequency values
  get_data, 'MinMaxVals_Dim_1_SubDim_1_1', data = v
  If(~is_struct(v)) Then Begin
     dprint, 'No Frequency data in file: '+filename
     Return
  Endif
  vmid = 0.5*(v.y[*,0]+v.y[*,1])
  store_data,data_var,data = {x:d.x, y:d.y, v:vmid}
  If(Keyword_set(frequency_binning)) Then Begin
     nperbin  = frequency_binning
     v0 = v.y[*,0] & v1 = v.y[*,1]
     dy = d.y
;only keep bins Gt 0
     ok = where(v0 Gt 10)
     v0 = v0[ok] & v1 = v1[ok]
     dy = dy[*, ok]
;only keep full bins
     nbins = n_elements(v0)/nperbin
     v0 = v0[0:nbins*nperbin-1]
     v1 = v1[0:nbins*nperbin-1]
     nx = n_elements(d.x)
     dy = dy[*, 0:nbins*nperbin-1]
     dy = reform(dy, nx, nperbin, nbins)
;total in log space
     dynew = total(alog10(dy), 2)/nperbin
     dynew = 10.0^dynew
     ssnew = lindgen(nbins)*nperbin
     v0new = v0[ssnew] & v1new = v1[ssnew+nperbin-1]
     vmidnew = 0.5*(v0new+v1new)
     binvar = 'fa_'+data_var+'bin'+strcompress(/remove_all, string(nperbin))
     store_data, binvar, data = {x:d.x, y:dynew, v:vmidnew}
     options, binvar, 'spec', 1
     options, binvar, 'zlog', 1
     options, binvar, 'zsubtitle', 'nT^2/Hz'
     options, binvar, 'ytitle', 'fa_SfaAve_'+datatype
     options, binvar, 'ysubtitle', 'Khz'
  Endif
;copy the data variables, so that they are not overwritten
;then delete the input variables
  copy_data, data_var, 'fa_'+data_var
  store_data, data_var, /delete
  copy_data, 'Sdt_Cdf_MDim_Sizes_by_Record', $
             'fa_'+datatype+'_Sdt_Cdf_MDim_Sizes_by_Record'
  store_data, 'Sdt_Cdf_MDim_Sizes_by_Record', /delete
  copy_data, 'MinMaxVals_Dim_1_SubDim_1_1', $
             'fa_'+datatype+'_MinMaxVals_Dim_1_SubDim_1_1'
  store_data, 'MinMaxVals_Dim_1_SubDim_1_1', /delete
  copy_data, 'Data_MinMax_Offset_Dim_1_SubDim_1_1', $
             'fa_'+datatype+'_Data_MinMax_Offset_Dim_1_SubDim_1_1'
  store_data, 'Data_MinMax_Offset_Dim_1_SubDim_1_1', /delete
  copy_data, 'DimensionDescription_Dim_1_SubDim_1_1', $
             'fa_'+datatype+'_DimensionDescription_Dim_1_SubDim_1_1'
  store_data, 'DimensionDescription_Dim_1_SubDim_1_1', /delete

;plot options
  options, 'fa_'+data_var, 'spec', 1
  options, 'fa_'+data_var, 'zlog', 1
  options, 'fa_'+data_var, 'zsubtitle', 'nT^2/Hz'
  options, 'fa_'+data_var, 'ytitle', 'fa_SfaAve_'+datatype
  options, 'fa_'+data_var, 'ysubtitle', 'Khz'
  Return
End

  



