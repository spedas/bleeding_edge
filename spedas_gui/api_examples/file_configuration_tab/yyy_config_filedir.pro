;+
;Function: yyy_config_filedir.pro
;Purpose: Get the applications user directory for SPEDAS data analysis software
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/api_examples/file_configuration_tab/yyy_config_filedir.pro $
;-
Function yyy_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
                'the SPEDAS Data Analysis Software']

  Return, app_user_dir('yyy', 'yyy Configuration Process', $
                       'yyy_config', $
                       'yyy configuration Directory', $
                       readme_txt, 1, /restrict_os)

End
