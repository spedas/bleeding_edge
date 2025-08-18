;+
; this script downloads MMS files and saves the MD5 hashes for comparison with pySPEDAS
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-09-04 11:44:22 -0700 (Wed, 04 Sep 2019) $
; $LastChangedRevision: 27721 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/validation/mms_save_file_hashes_script.pro $
;-

mms_init, local_data_dir='/Users/eric/data/mms_validation_data/'

undefine, filehashes
undefine, all_files

probes = [1, 2]

; fast survey
tranges = [['2015-10-1', '2015-10-3'], $
  ['2016-10-1', '2016-10-3'], $
  ['2017-10-1', '2017-10-3'], $
  ['2018-10-1', '2018-10-3']]

for time_idx=0, n_elements(tranges[0, *])-1 do begin
  mms_load_fgm, trange=(tranges[*, time_idx]), cdf_filenames=fn, probes=probes, /download_only
  append_array, all_files, fn
  mms_load_scm, trange=(tranges[*, time_idx]), cdf_filenames=fn, probes=probes, /download_only
  append_array, all_files, fn
  mms_load_fpi, trange=(tranges[*, time_idx]), datatype=['des-moms', 'dis-moms'], cdf_filenames=fn, probes=probes, /download_only
  append_array, all_files, fn
  mms_load_hpca, trange=(tranges[*, time_idx]), cdf_filenames=fn, probes=probes, /download_only
  append_array, all_files, fn
  mms_load_edi, trange=(tranges[*, time_idx]), cdf_filenames=fn, probes=probes, /download_only
  append_array, all_files, fn
  mms_load_dsp, trange=(tranges[*, time_idx]), cdf_filenames=fn, data_rate='fast', datatype='swd', level='l2', probes=probes, /download_only
  append_array, all_files, fn
  mms_load_aspoc, trange=(tranges[*, time_idx]), cdf_filenames=fn, probes=probes, /download_only
  append_array, all_files, fn
  mms_load_edp, trange=(tranges[*, time_idx]), cdf_filenames=fn, probes=probes, /download_only
  append_array, all_files, fn
  mms_load_eis, trange=(tranges[*, time_idx]), cdf_filenames=fn, datatype=['extof', 'phxtof'], probes=probes, /download_only
  append_array, all_files, fn
  mms_load_feeps, trange=(tranges[*, time_idx]), cdf_filenames=fn, probes=probes, /download_only
  append_array, all_files, fn
  mms_load_mec, trange=(tranges[*, time_idx]), cdf_filenames=fn, probes=probes, /download_only
  append_array, all_files, fn
endfor

for file_idx=0, n_elements(all_files)-1 do begin
  spawn, 'md5 ' + all_files[file_idx], filehash
  append_array, filehashes, filehash
endfor

write_csv, 'mms_cdf_file_hashes.csv', filehashes
stop
end