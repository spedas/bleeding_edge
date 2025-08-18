
;+  
;NAME: 
; spd_ui_load_spedas_ascii_sub
;
;PURPOSE:
; display a dialog when importing ASCII data
;
;INPUT:
; ev - event structure from the main GUI
;  
;HISTORY:
;
;-----------------------------------------------------------------------------------
;
; sub routine for HELP dialog
;
pro spd_ui_load_spedas_ascii_display_help, ev, msgtext
  COMPILE_OPT idl2, hidden
  
  help_base = WIDGET_BASE(TITLE='HELP', /COLUMN, /ALIGN_CENTER, GROUP_LEADER=ev.top, /MODAL)
;  help_text = WIDGET_TEXT(help_base, VALUE=msgtext, XSIZE=50, YSIZE=20, /SCROLL)
  help_text = WIDGET_TEXT(help_base, VALUE=msgtext, XSIZE=60, YSIZE=30, /SCROLL)
  WIDGET_CONTROL, help_base, /REALIZE

end
;
; Event handler
;
pro spd_ui_load_spedas_ascii_sub_event, ev
  compile_opt idl2, hidden
    
  ; event handling
  WIDGET_CONTROL, ev.top, GET_UVALUE=val
  WIDGET_CONTROL, ev.id, GET_UVALUE=uval
  
  case uval of
    
    'browse':begin
      indir = file_dirname(routine_filepath())
      infile=dialog_pickfile(DIALOG_PARENT=ev.top, /MUST_EXIST, /READ, /FIX_FILTER, PATH=indir)
      if infile eq '' then return
      val['txt_infile'] = infile
      widget_control, widget_info(ev.top, FIND_BY_UNAME='txt_infile'), SET_VALUE=val['txt_infile']

    end
    
    'button_Cancel':begin
      val['success'] = !FALSE
      widget_control, ev.top, /DESTROY
    end  
    
    ; push OK Button
    'button_OK' : begin

      ; TODO :: validate input datas
      ; get Format Type
      WIDGET_CONTROL, widget_info(ev.top, FIND_BY_UNAME='list_FormatType'), GET_VALUE=getter_format_type
      val['format_type'] = getter_format_type[val['index_FormatType']]

      ; get Time Format
      ; if use Specify data
      if val['flag_TimeFormatSpecify'] eq !TRUE then begin
        WIDGET_CONTROL, WIDGET_INFO(ev.top, FIND_BY_UNAME='txt_TimeFormatSpecify'), GET_VALUE=getter_tformat
        val['tformat'] = getter_tformat[0]
      endif else begin
        WIDGET_CONTROL, WIDGET_INFO(ev.top, FIND_BY_UNAME='list_TimeFormat'), GET_VALUE=getter_tformat
        val['tformat'] = getter_tformat[val['index_TimeFormat']]
      endelse

      ; get Column No. of loaded data
      WIDGET_CONTROL, WIDGET_INFO(ev.top, FIND_BY_UNAME='txt_ColumnNoOfLoadedData'), GET_VALUE=getter_tvar_column
      val['tvar_column'] = getter_tvar_column[0]

      ; get Loaded data name
      WIDGET_CONTROL, WIDGET_INFO(ev.top, FIND_BY_UNAME='txt_LoadedDataName'), GET_VALUE=getter_tvarnames
      val['tvarnames'] = getter_tvarnames[0]

      ; get Delimiter
      WIDGET_CONTROL, WIDGET_INFO(ev.top, FIND_BY_UNAME='txt_Delimiter'), GET_VALUE=getter_delimiter
      val['delimiter'] = getter_delimiter[0]

      ; if Format Type = 1 then get Column No. of v_vector
      if val['flag_ColumnNoOfVvector'] eq !TRUE then begin
        WIDGET_CONTROL, WIDGET_INFO(ev.top, FIND_BY_UNAME='txt_ColumnNoOfVvector'), GET_VALUE=getter_v_column
        val['v_column'] = getter_v_column[0]
      endif

      ; if use Options
      if val['flag_header_Options'] eq !TRUE then begin
        ; get Number of lines to skip
        WIDGET_CONTROL, WIDGET_INFO(ev.top, FIND_BY_UNAME='txt_NumberOfLinesToSkip'), GET_VALUE=getter_data_start
        val['data_start'] = getter_data_start[0]
        ; get Comment symbol
        WIDGET_CONTROL, WIDGET_INFO(ev.top, FIND_BY_UNAME='txt_CommentSymbol'), GET_VALUE=getter_comment_symbol
        val['comment_symbol'] = getter_comment_symbol[0]
      endif else begin
        val['data_start'] = !NULL
        val['comment_symbol'] = !NULL
      endelse

      if val['flag_date_Options'] eq !TRUE then begin
        ; get Flag of Date&Time columns
        WIDGET_CONTROL, WIDGET_INFO(ev.top, FIND_BY_UNAME='txt_FlagOfDateAndTimeColumns'), GET_VALUE=getter_time_column
        val['time_column'] = getter_time_column[0]
        ; get Input of Date&Time
        WIDGET_CONTROL, WIDGET_INFO(ev.top, FIND_BY_UNAME='txt_InputOfDateAndTime'), GET_VALUE=getter_input_time
        val['input_time'] = getter_input_time[0]
      endif else begin
        val['time_column'] = !NULL
        val['input_time'] = !NULL
      endelse

      val['success'] = !TRUE
      ; close widget
      WIDGET_CONTROL, ev.top, /DESTROY

    end
    
    ; IF use Options
    'checkbutton_header_Options' : begin
      ;print, ev.select
      wb=!null
      wb = WIDGET_INFO(ev.top, FIND_BY_UNAME='opt_header_base')
      WIDGET_CONTROL, wb, SENSITIVE=ev.select
      if ev.select eq 1 then begin
        val['flag_header_Options'] = !TRUE
      endif else begin
        val['flag_header_Options'] = !FALSE
      endelse
    end
    
    ; IF use Options
    'checkbutton_date_Options' : begin
      ;print, ev.select
      wb=!null
      wb = WIDGET_INFO(ev.top, FIND_BY_UNAME='opt_date_base')
      WIDGET_CONTROL, wb, SENSITIVE=ev.select
      if ev.select eq 1 then begin
        val['flag_date_Options'] = !TRUE
      endif else begin
        val['flag_date_Options'] = !FALSE
      endelse
    end
    
    ; IF use Time Format Specify
    'checkbutton_TimeFormatSpecify' : begin
      wt = WIDGET_INFO(ev.top, FIND_BY_UNAME='txt_TimeFormatSpecify')
      wd = WIDGET_INFO(ev.top, FIND_BY_UNAME='list_TimeFormat')
      WIDGET_CONTROL, wt, SENSITIVE=ev.select
      WIDGET_CONTROL, wd, SENSITIVE=abs(ev.select -1)
      val['flag_TimeFormatSpecify'] = ev.select
    end
    ;
    ; For TPLOT_GUI option
    'checkbutton_tplot_Options':begin
      ;print, ev.select
      if ev.select eq 1 then begin
        val['flag_tplot_Options'] = !TRUE
      endif else begin
        val['flag_tplot_Options'] = !FALSE
      endelse
    end  
           
    ; push Column No. of leaded data help
    'help_ColumnNoOfLoadedData': begin
      msgtext = (val['help_text'])[uval]   
      spd_ui_load_spedas_ascii_display_help, ev, msgtext
    end
    
    ; push Column No. of v_vector help
    'help_ColumnNoOfVvector' : begin
      msgtext = (val['help_text'])[uval]
      spd_ui_load_spedas_ascii_display_help, ev, msgtext
    end
        
    ; push Delimiter help
    'help_Delimiter' : begin
      msgtext = (val['help_text'])[uval]
      spd_ui_load_spedas_ascii_display_help, ev, msgtext      
    end
    
    ; push Flag of Date&Time columns help
    'help_FlagOfDateAndTimeColumns' : begin
      msgtext = (val['help_text'])[uval]
      spd_ui_load_spedas_ascii_display_help, ev, msgtext
    end
    
    ; push Format Type help
    'help_FormatType' : begin
      msgtext = (val['help_text'])[uval]
      spd_ui_load_spedas_ascii_display_help, ev, msgtext
    end
    
    ; push Loaded data name help
    'help_LoadedDataName' : begin
      msgtext = (val['help_text'])[uval]
      spd_ui_load_spedas_ascii_display_help, ev, msgtext
    end
    
    ; push Time Format help
    'help_TimeFormat' : begin
      msgtext = (val['help_text'])[uval]
      spd_ui_load_spedas_ascii_display_help, ev, msgtext
    end
    
    ; select Format Type list
    'list_FormatType' : begin
      val["index_FormatType"] = ev.index
      wb = WIDGET_INFO(ev.top, FIND_BY_UNAME='base_ColumnNoOfVvector')
      ; if Format Type = 1 then Activate Column No. of v_vector
      if (ev.index) eq 1 then begin
        widget_control, wb, /SENSITIVE
        val['flag_ColumnNoOfVvector'] = !TRUE
      endif else begin
        widget_control, wb, SENSITIVE=0
        val['flag_ColumnNoOfVvector'] = !FALSE
      endelse
    end
    
    ; select Time Format list
    'list_TimeFormat' : begin
      val['index_TimeFormat'] = ev.index
    end
    ;
    'txt_ColumnNoOfLoadedData':begin
      WIDGET_CONTROL, ev.id, GET_VALUE=txtval
      val[uval] = txtval
    end
    ;
    'txt_ColumnNoOfVvector':begin
      WIDGET_CONTROL, ev.id, GET_VALUE=txtval
      val[uval] = txtval
    end
    ;
    'txt_CommentSymbol':begin
      WIDGET_CONTROL, ev.id, GET_VALUE=txtval
      val[uval] = txtval
    end
    ;
    'txt_Delimiter':begin
      WIDGET_CONTROL, ev.id, GET_VALUE=txtval
      val[uval] = txtval
    end
    ;
    'txt_FlagOfDateAndTimeColumns':begin
      WIDGET_CONTROL, ev.id, GET_VALUE=txtval
      val[uval] = txtval
    end
    ;
    'txt_infile':begin
      WIDGET_CONTROL, ev.id, GET_VALUE=infile
      val[uval] = infile
    end
    ;
    'txt_InputOfDateAndTime':begin
      WIDGET_CONTROL, ev.id, GET_VALUE=txtval
      val[uval] = txtval
    end
    ;
    'txt_LoadedDataName':begin
      WIDGET_CONTROL, ev.id, GET_VALUE=txtval
      val[uval] = txtval
    end
    ;
    'txt_NumberOfLinesToSkip':begin
      WIDGET_CONTROL, ev.id, GET_VALUE=txtval
      val[uval] = txtval
    end
    ;
    'txt_TimeFormatSpecify':begin
      WIDGET_CONTROL, ev.id, GET_VALUE=txtval
      val[uval] = txtval
    end
    ;
  endcase
  
end
;
; main program
;
function spd_ui_load_spedas_ascii_sub, ev, DEBUG=debug
  COMPILE_OPT idl2, hidden

  ; define
  DEF_FORMATTYPE = ['0','1']
  DEF_TIMEFORMAT = [ $
    'YYYY-MM-DD / hh:mm:ss', $
    'YYYY MM DD hh mm ss', $
    'YYYY,MM,DD,hh,mm,ss', $
    'YYYYMMDD hhmmss', $
    'YYYY-MM-DD / hh:mm', $
    'YYYY MM DD hh mm', $
    'YYYY,MM,DD,hh,mm', $
    'yy MM DD hh mm ss', $
    'yy,MM,DD,hh,mm,ss', $
    'yy MM DD hh mm', $
    'yy,MM,DD,hh,mm'  $
    ]
  ;
  ; information for help messages  
  ;
  help_text = hash()
  help_text['help_FormatType'] = ['Format Type:',$
    ' ', $
    '0: Time series data shown as follows:', $
    '--------------------------------------------------------', $
    '2018-03-01 00:00:00 ydata1[0] ydata2[0] ...', $
    '2018-03-01 00:00:01 ydata1[1] ydata2[1] ...', $
    '2018-03-01 00:00:02 ydata1[2] ydata2[2] ...', $
    '    :         :       :        :        ...', $
    '--------------------------------------------------------', $
    'where ydata1, ydata2, ... are the column data.', $
    '                                                        ', $
    '1: Time series data that include more than one row data', $
    '   at the same time, shown as follows:', $
    '--------------------------------------------------------', $
    '2018-03-01 00:00:00 vdata[0] ydata1[0] ydata2[0] ...', $
    '2018-03-01 00:00:00 vdata[1] ydata1[1] ydata2[1] ...', $
    '    :         :       :        :         :       ...', $
    '2018-03-01 00:00:00 vdata[n] ydata1[n] ydata2[n] ...', $
    '2018-03-01 00:01:00 vdata[0] ydata1[n+1] ydata2[n+1] ...', $
    '2018-03-01 00:01:00 vdata[1] ydata1[n+2] ydata2[n+2] ...', $
    '    :         :       :        :         :       ...', $
    '--------------------------------------------------------', $
    'where ydata1, ydata2, ... are the column data,', $
    'and vdata repeats every time (e.g., altitude for ', $
    'atmosphere data, frequency for spectral data, and ', $
    'range for radar data).']
  help_text['help_TimeFormat'] = ['Time Format:', $
    ' ', $
    'A format string such as YYYY-MM-DD/hh:mm:ss (Default)', $
    '  the following tokens are recognized:', $
    '    YYYY  - 4 digit year', $
    '    yy    - 2 digit year (00-69 assumed to be 2000-2069,', $
    '                          70-99 assumed to be 1970-1999)', $
    '    MM    - 2 digit month', $
    '    DD    - 2 digit date', $
    '    hh    - 2 digit hour', $
    '    mm    - 2 digit minute', $
    '    ss    - 2 digit seconds', $
    '   .fff   - fractional seconds (can be repeated, ', $
    '                  e.g. .f,.ff,.fff,.ffff, etc...)', $
    '    MTH   - 3 character month', $
    '    DOY   - 3 character Day of Year', $
    '    TDIFF - 5 character, +hhmm or -hhmm different from UTC', $
    '                         (sign required)', $
    '    Time Format is case sensitive!']
  help_text['help_ColumnNoOfLoadedData'] = ['Column No. of loaded data:', $
    ' ', $
    'A scalar or a vector that identifies the column number', $
    'for output tplot variables. The number starts from 0 ', $
    'except for the columns of date&time.', $
    ' ', $
    'For example, both 0 and 0, 1, 2 are acceptable.']
  help_text['help_LoadedDataName'] = ['Loaded data name:', $
    ' ', $
    'A string or a string array for output tplot variable names.', $
    'This usually has the same number of element as that of ', $
    '"Column No. of loaded data".', $
    'For example, both tvar1 and tvar1, tvar2, tvar3 are acceptable.', $
    ' ', $
    'Exceptions:', $
    'When format_type=0, the input of "Column No. of loaded data"=0,1,2,3', $
    'and "Loaded data name"=tvar1 creates the variable "tvar1",', $
    'which includes four vectors.']
  help_text['help_Delimiter'] = ['Delimiter:', $
    ' ', $
    'A scalar string that identifies the end of a field.', $
    'One or more single characters are allowed.', $
    'For example, both "," and ",;/" are acceptable.', $
	'(The double quotation mark is not needed.)']
  help_text['help_ColumnNoOfVvector'] = ['Column No of v_vector', $
    ' ', $
    'A scalar that specifies the column number of vdata, ', $
    'where the vdata is used for the vertical axis when you ', $
	'plot the loaded data by clicking the "spec" button.']
  help_text['help_FlagOfDateAndTimeColumns'] = ['Flag of Date&Time columns:', $
    ' ', $
    'If this keyword is set, "Time Format" is not used.', $
    'A vector of 6 elements that shows the existence of', $
    'date&time data, (year, month, day, hour, minute, second),', $
	'in the ascii file.', $
    ' ', $
	'For example, if the data file includes the columns for', $
	'(hour minute second) only, then you can set ', $
	'"Flag of Date&Time columns"=0, 0, 0, 1, 1, 1 and', $
	'"Input of Date&Time"=2007, 3, 21, 0, 0, 0.']
  ; Widget master :: topbase
  if KEYWORD_SET(debug) then begin
    topbase = WIDGET_BASE(TITLE='Load SPEDAS ASCII')
  endif else begin
    topbase = WIDGET_BASE(TITLE='Load SPEDAS ASCII', GROUP_LEADER=ev.top, /MODAL)
  endelse
  
  base = WIDGET_BASE(topbase, /COLUMN)
  ;size of labels
  w_xs = 180
  
  ;
  ; file selection
  base1 = WIDGET_BASE(base, /ROW)
  ;base1_sub1 = widget_base(base1, XS=200, YS=100)
  wl1 = WIDGET_LABEL(base1, VALUE='Select File: ', XSIZE=80)
  wt1 = WIDGET_TEXT(base1, XSIZE=42, /ALL_EVENTS, /EDITABLE, $
    UVALUE='txt_infile', UNAME='txt_infile')
  wb1 = WIDGET_BUTTON(base1, VALUE='Browse', UVALUE='browse')
  
  ; Format Type *****
  base_FormatType = WIDGET_BASE(base, /ROW)
  namelabel_FormatType = WIDGET_LABEL(base_FormatType, VALUE='Format Type:', $
    XSIZE=w_xs, /ALIGN_LEFT)
  list_FormatType = WIDGET_DROPLIST(base_FormatType, $
    VALUE=DEF_FORMATTYPE, UVALUE='list_FormatType', UNAME='list_FormatType')
  help_FormatType = WIDGET_BUTTON(base_FormatType, VALUE=' ? ', UVALUE='help_FormatType')

  ; Time Format *****
  base_TimeFormat = WIDGET_BASE(base, /ROW, UNAME='base_TimeFormat')
  namelabel_TimeFormat = WIDGET_LABEL(base_TimeFormat, VALUE = 'Time Format:', $
    XSIZE=w_xs, /ALIGN_LEFT)
  list_TimeFormat = WIDGET_DROPLIST(base_TimeFormat, VALUE = DEF_TIMEFORMAT, $
    UVALUE='list_TimeFormat', UNAME='list_TimeFormat')
  help_TimeFormat = WIDGET_BUTTON(base_TimeFormat, VALUE=' ? ', UVALUE='help_TimeFormat')
  
  ; Time Format Specify *****
  base_TimeFormatSpecify = WIDGET_BASE(base, /ROW)
  base_checkbuttonTimeFormatSpecify = WIDGET_BASE(base_TimeFormatSpecify, /ROW, /NONEXCLUSIVE)
  checkbutton_TimeFormatSpecify = WIDGET_BUTTON(base_checkbuttonTimeFormatSpecify, $
    VALUE='Specify: ', UVALUE='checkbutton_TimeFormatSpecify', XSIZE=w_xs)
  txt_TimeFormatSpecify = WIDGET_TEXT(base_TimeFormatSpecify, VALUE='YYYY-MM-DD / hh:mm:ss.fff', $
    /EDITABLE, YSIZE=1, XSIZE=25, UNAME='txt_TimeFormatSpecify', UVALUE='txt_TimeFormatSpecify')
  
  ; Column No. of loaded data *****
  base_ColumnNoOfLoadedData = WIDGET_BASE(base, /ROW)
  namelabel_ColumnNoOfLoadedData = WIDGET_LABEL(base_ColumnNoOfLoadedData, $
    VALUE = 'Column No. of loaded data:', XSIZE=w_xs, /ALIGN_LEFT)
  txt_ColumnNoOfLoadedData = WIDGET_TEXT(base_ColumnNoOfLoadedData, value = '0', $
    UVALUE='txt_ColumnNoOfLoadedData', UNAME='txt_ColumnNoOfLoadedData', /EDITABLE, YSIZE=1, XSIZE=25)
  help_ColumnNoOfLoadedData = WIDGET_BUTTON(base_ColumnNoOfLoadedData, VALUE=' ? ', $
    UVALUE='help_ColumnNoOfLoadedData')

  ; Loaded data name *****
  base_LoadedDataName = WIDGET_BASE(base, /ROW)
  namelabel_LoadedDataName = WIDGET_LABEL(base_LoadedDataName, VALUE='Loaded data name:', XSIZE=w_xs, /ALIGN_LEFT)
  txt_LoadedDataName = WIDGET_TEXT(base_LoadedDataName, VALUE='tvar1', UVALUE='txt_LoadedDataName', $
    UNAME='txt_LoadedDataName', /EDITABLE, YSIZE=1, XSIZE=25)
  help_LoadedDataName = WIDGET_BUTTON(base_LoadedDataName, VALUE=' ? ', UVALUE='help_LoadedDataName')

  ; Delimiter *****
  base_Delimiter = WIDGET_BASE(base, /ROW)
  namelabel_Delimiter = WIDGET_LABEL(base_Delimiter, VALUE = 'Delimiter:', XSIZE=w_xs, /ALIGN_LEFT)
  txt_Delimiter = WIDGET_TEXT(base_Delimiter, value = string(32B), UVALUE='txt_Delimiter', $
    UNAME='txt_Delimiter', /EDITABLE, YSIZE=1, XSIZE=8)
  help_Delimiter = WIDGET_BUTTON(base_Delimiter, VALUE=' ? ', UVALUE='help_Delimiter')

  ; Column No. of v_vector *****
  base_ColumnNoOfVvector = WIDGET_BASE(base, /ROW, UNAME='base_ColumnNoOfVvector')
  namelabel_ColumnNoOfVvector = WIDGET_LABEL(base_ColumnNoOfVvector, $
    VALUE='Column No. of v_vector:', XSIZE=w_xs, /ALIGN_LEFT)
  txt_ColumnNoOfVvector = WIDGET_TEXT(base_ColumnNoOfVvector, VALUE='0', $
    UNAME='txt_ColumnNoOfVvector', UVALUE='txt_ColumnNoOfVvector', $
    /EDITABLE, YSIZE=1, XSIZE=8)
  help_ColumnNoOfVvector = WIDGET_BUTTON(base_ColumnNoOfVvector, $
    VALUE=' ? ', UVALUE='help_ColumnNoOfVvector')

  ; Options for header *****
  base_header_Options = WIDGET_BASE(base, /ROW, /NONEXCLUSIVE)
  checkbutton_header_Options = WIDGET_BUTTON(base_header_Options, $
    UVALUE='checkbutton_header_Options', VALUE='Options for Header')
  
  ; Options // Number of lines to skip *****
  opt_header_base = WIDGET_BASE(base, /COL, UNAME='opt_header_base')
  base_NumberOfLinesToSkip = WIDGET_BASE(opt_header_base, /ROW)
  namelabel_NumberOfLinesToSkip = WIDGET_LABEL(base_NumberOfLinesToSkip, $
    VALUE='Number of lines to skip:', XSIZE=w_xs, /ALIGN_LEFT)
  txt_NumberOfLinesToSkip = WIDGET_TEXT(base_NumberOfLinesToSkip, VALUE='0', $
    UVALUE='txt_NumberOfLinesToSkip', UNAME='txt_NumberOfLinesToSkip', $
    /EDITABLE, YSIZE=1, XSIZE=8)

  ; Options // Comment symbol *****
  base_CommentSymbol = WIDGET_BASE(opt_header_base, /ROW)
  namelabel_CommentSymbol = WIDGET_LABEL(base_CommentSymbol, $
    VALUE='Comment symbol:', XSIZE=w_xs, /ALIGN_LEFT)
  txt_CommentSymbol = WIDGET_TEXT(base_CommentSymbol, VALUE='', $
    UVALUE='txt_CommentSymbol', $
    UNAME='txt_CommentSymbol', /EDITABLE, YSIZE = 1, XSIZE=8)
  
  ; Options for Date&TIME *****
  base_date_Options = WIDGET_BASE(base, /ROW, /NONEXCLUSIVE)
  checkbutton_date_Options = WIDGET_BUTTON(base_date_Options, $
    UVALUE='checkbutton_date_Options', VALUE='Options for Date/Time')
  
  ; Options // Flag of Date&Time columns *****
  opt_date_base = WIDGET_BASE(base, /COL, UNAME='opt_date_base')
  base_FlagOfDateAndTimeColumns = WIDGET_BASE(opt_date_base, /ROW)
  namelabel_FlagOfDateAndTimeColumns = WIDGET_LABEL(base_FlagOfDateAndTimeColumns, $
    VALUE='Flag of Date/Time columns:', XSIZE=w_xs, /ALIGN_LEFT)
  txt_FlagOfDateAndTimeColumns = WIDGET_TEXT(base_FlagOfDateAndTimeColumns, $
    VALUE='1,1,1,1,1,1', UNAME='txt_FlagOfDateAndTimeColumns', $
    UVALUE='txt_FlagOfDateAndTimeColumns', /EDITABLE, YSIZE=1, XSIZE=25)
  help_FlagOfDateAndTimeColumns = WIDGET_BUTTON(base_FlagOfDateAndTimeColumns, VALUE=' ? ', $
    UVALUE='help_FlagOfDateAndTimeColumns')
  
  ; Options // Input of Date&Time *****
  base_InputOfDateAndTime = WIDGET_BASE(opt_date_base, /ROW)
  namelabel_InputOfDateAndTime = WIDGET_LABEL(base_InputOfDateAndTime, $
    VALUE='Input of Date/Time:', XSIZE=w_xs, /ALIGN_LEFT)
  txt_InputOfDateAndTime = WIDGET_TEXT(base_InputOfDateAndTime, VALUE='2007,3,21,0,0,0', $
    UNAME='txt_InputOfDateAndTime', UVALUE='txt_InputOfDateAndTime', /EDITABLE, YSIZE = 1, XSIZE=25)
    
;  base_tplot_Options = WIDGET_BASE(base, /ROW, /NONEXCLUSIVE)
;  checkbutton_tplot_Options = WIDGET_BUTTON(base_tplot_Options, $
;    UVALUE='checkbutton_tplot_Options', VALUE='Use TPLOT_GUI')
  
  ; OK Button *****
  base_OK = WIDGET_BASE(base, /ROW, /ALIGN_CENTER)
  button_OK = WIDGET_BUTTON(base_OK, UVALUE='button_OK', VALUE='  OK  ')
  button_Cancel = WIDGET_BUTTON(base_OK, UVALUE='button_Cancel', VALUE='Cancel')
  
  ; ********************
  ; control active / nonactive
  index_FormatType = 0
  index_TimeFormat = 0
  
  ; widget status setting
  status = hash()
  status['help_text'] = help_text
  status['index_FormatType'] = index_FormatType
  status['index_TimeFormat'] = index_TimeFormat
  status['flag_TimeFormatSpecify'] = !FALSE
  status['flag_ColumnNoOfVvector'] = !FALSE
  status['flag_header_Options'] = !FALSE
  status['flag_date_Options'] = !FALSE
  ;status['flag_tplot_Options'] = !TRUE
  
  ; Set initial state for GUI
  ; Time Format Specify ***
  WIDGET_CONTROL, txt_TimeFormatSpecify, SENSITIVE=status['flag_TimeFormatSpecify']
  ; Column No. of v_vector *****
  WIDGET_CONTROL, base_ColumnNoOfVvector, SENSITIVE=status['flag_ColumnNoOfVvector']
  
  WIDGET_CONTROL, checkbutton_header_Options, SET_BUTTON=status['flag_header_Options']
  WIDGET_CONTROL, opt_header_base, SENSITIVE=status['flag_header_Options']
  WIDGET_CONTROL, checkbutton_date_Options, SET_BUTTON=status['flag_date_Options']
  WIDGET_CONTROL, opt_date_base, SENSITIVE=status['flag_date_Options']
  ;WIDGET_CONTROL, checkbutton_tplot_Options, SET_BUTTON=status['flag_tplot_Options']
  ;
  ;
  status['txt_TimeFormatSpecify'] = !NULL

  ; return values
  status['success'] = !FALSE
  status['txt_infile'] = !NULL
  status['format_type'] = !NULL
  status['tformat'] = !NULL
  status['tvar_column'] = !NULL
  status['tvarnames'] = !NULL
  status['delimiter'] = !NULL
  status['data_start'] = !NULL
  status['comment_symbol'] = !NULL
  status['v_column'] = !NULL
  status['vvec'] = !NULL
  status['time_column'] = !NULL
  status['input_time'] = !NULL
    
  WIDGET_CONTROL, topbase, SET_UVALUE=status
    
  ; exec Load ASCII File 
  WIDGET_CONTROL, topbase, /REALIZE
  XMANAGER, 'spd_ui_load_spedas_ascii_sub', topbase
  
  ; make return hash
  ret_hash = hash()
  ret_hash['success'] = status['success']
  ret_hash['infile'] = status['txt_infile']
  
  if status['format_type'] ne !null then begin
    ret_hash['format_type'] = long(status['format_type'])
  endif else begin
    ret_hash['format_type'] = status['format_type']
  endelse
  
  ret_hash['tformat']= status['tformat']
  
  if status['tvar_column'] ne !NULL then begin
    pos = strpos(status['tvar_column'], ',')
    if pos ne -1 then begin
      ret_hash['tvar_column'] = long(strsplit(status['tvar_column'], ',', /EXTRACT))
    endif else begin
      ret_hash['tvar_column'] = long(status['tvar_column'])
    endelse
  endif else begin
    ret_hash['tvar_column']= status['tvar_column']
  endelse
  
  if status['tvarnames'] ne !null then begin
    pos = strpos(status['tvarnames'], ',')
    if pos ne -1 then begin
      ret_hash['tvarnames'] = strsplit(status['tvarnames'], ',', /EXTRACT)
    endif else begin
;      void = execute('tmp_tvarnames ='+"'"+status['tvarnames']+"'")
;      status['tvarnames'] = tmp_tvarnames
      ret_hash['tvarnames'] = status['tvarnames']
    endelse
  endif else begin
    ret_hash['tvarnames']=status['tvarnames']
  endelse
  
  ret_hash['delimiter']= status['delimiter']
  
  if status['data_start'] ne !null then begin
    ret_hash['data_start']= long(status['data_start'])
  endif else begin
    ret_hash['data_start']= status['data_start']
  endelse
  
  ret_hash['comment_symbol']= status['comment_symbol']
  ret_hash['v_column']= status['v_column']
  ret_hash['vvec']= status['vvec']
  
  if status['time_column'] ne !null then begin
    pos = strpos(status['time_column'], ',')
    if pos ne -1 then begin
      ret_hash['time_column'] = long(strsplit(status['time_column'],',',/EXTRACT))
    endif else begin
      ret_hash['time_column'] = long(status['time_column'])
    endelse
  endif else begin
    ret_hash['time_column'] = status['time_column']
  endelse

  if status['input_time'] ne !null then begin
    pos = strpos(status['input_time'], ',')
    if pos ne -1 then begin
      ret_hash['input_time'] = long(strsplit(status['input_time'], ',', /EXTRACT))
    endif else begin
      ret_hash['input_time'] = long(status['input_time'])
    endelse
  endif else begin
    ret_hash['input_time'] = status['input_time']
  endelse
  
  ;ret_hash['flag_tplot_Options'] = status['flag_tplot_Options'] 
  
  return, ret_hash
  
end
;
; for testing dialog
;
pro test_spd_ui_load_spedas_ascii_sub
  COMPILE_OPT idl2, hidden
  
  ret = spd_ui_load_spedas_ascii_sub(/DEBUG)
  ;help, ret['time_column']
  ;help, ret['tvarnames']
  print, ret
  print, 'completed'

end
