;+
;NAME: 
;    spd_ui_plugin_manager
;
;PURPOSE:
;    Interface for SPEDAS plugins
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-10-11 16:59:54 -0700 (Tue, 11 Oct 2016) $
;$LastChangedRevision: 22089 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_plugin_manager__define.pro $
;-

pro spd_ui_plugin_manager::Cleanup
    ptr_free, self.plugin_menus
    ptr_free, self.plugin_file_config_panels
    ptr_free, self.plugin_load_data_panels
    ptr_free, self.plugin_about_pages
    ptr_free, self.data_proc_plugins
end

;+
; NAME: 
;     addAboutPlugin
;     
; PURPOSE: 
;     Add an about page with information on the plugin. For example, the "rules of the road"
;     statement, developer credits, acknowledgements, etc.
;     
; INPUT: 
;     mission name: name of the mission to add to the load data panel
;     procedure name: name of the procedure containing the load data panel widget for this mission
;     panel title: title of the load data panel
;-
pro spd_ui_plugin_manager::addAboutPlugin, mission_name, text_file
    plugin_struct = [{mission_name: mission_name, text_file: text_file}]
    if ptr_valid(self.plugin_about_pages) then begin
        append_array, (*self.plugin_about_pages), plugin_struct
    endif else self.plugin_about_pages = ptr_new(plugin_struct)
end 

;+
; NAME: 
;     getAboutPlugins
;     
; PURPOSE: 
;     returns an array of structures, one struct for each plugin's about page
;     
;
;-
function spd_ui_plugin_manager::getAboutPlugins
    if ptr_valid(self.plugin_about_pages) then begin
        return, *self.plugin_about_pages
    endif else return, 0
end


;+
; NAME: 
;     addLoadDataPanel
;     
; PURPOSE: 
;     Add a panel to the load data window
;     
; INPUT: 
;     mission name: name of the mission to add to the load data panel
;     procedure name: name of the procedure containing the load data panel widget for this mission
;     panel title: title of the load data panel
;-
pro spd_ui_plugin_manager::addLoadDataPanel, mission_name, procedure_name, panel_title
    plugin_struct = [{mission_name: mission_name, procedure_name: procedure_name, panel_title: panel_title}]
    if ptr_valid(self.plugin_load_data_panels) then begin
        append_array, (*self.plugin_load_data_panels), plugin_struct
    endif else self.plugin_load_data_panels = ptr_new(plugin_struct)
end 

;+
; NAME: 
;     getLoadDataPanels
;     
; PURPOSE: 
;     returns an array of structures, one struct for each load data panel
;     
; OUTPUT:
;
;-
function spd_ui_plugin_manager::getLoadDataPanels
    if ptr_valid(self.plugin_load_data_panels) then begin
        return, *self.plugin_load_data_panels
    endif else return, 0
end

;+
; NAME: 
;     addFileConfigPanel
;     
; PURPOSE: 
;     Add a panel to the file configuration window
;     
; INPUT: 
;    mission name: name of the mission
;    procedure name: name of the procedure containing the file config widget
;-   
pro spd_ui_plugin_manager::addFileConfigPanel, mission_name, procedure_name
    plugin_struct = [{mission_name: mission_name, procedure_name: procedure_name}]
    if ptr_valid(self.plugin_file_config_panels) then begin
        append_array, (*self.plugin_file_config_panels), plugin_struct
    endif else self.plugin_file_config_panels = ptr_new(plugin_struct)
end

;+
; NAME: 
;     getFileConfigPanels
;     
; PURPOSE: 
;     returns an array of structures, one struct for each file config panel
;     
; OUTPUT:
; 
;-
function spd_ui_plugin_manager::getFileConfigPanels
    if ptr_valid(self.plugin_file_config_panels) then begin
        return, *self.plugin_file_config_panels
    endif else return, 0
end

;+
; NAME: 
;     addPluginMenu
;     
; PURPOSE: 
;     Add a menu item to the "Plugins" menu in the GUI
;     
; INPUT: 
;    item: menu item text
;    procedure: name of the procedure containing the widget to open when the user selects this menu item
;    location: 
; 
;-   
pro spd_ui_plugin_manager::addPluginMenu, item, procedure, location
    plugin_struct = [{item: item, procedure: procedure, location: location}]
    
    if ptr_valid(self.plugin_menus) eq 1 then begin
        append_array, (*self.plugin_menus), plugin_struct
    endif else self.plugin_menus = ptr_new(plugin_struct)
end

;+
; NAME: 
;     getPluginMenus
;     
; PURPOSE: 
;     returns an array of structures, one for each plugin menu
;
;-   
function spd_ui_plugin_manager::getPluginMenus
    if ptr_valid(self.plugin_menus) then begin
        return, *self.plugin_menus
    endif else return, 0
end

;+
; NAME:
;    addDataProcessingPlugin
; 
; PURPOSE: 
;     add a new plugin to the "More..." menu in the data processing panel
;   
;-
pro spd_ui_plugin_manager::addDataProcessingPlugin, item, procedure, location
    plugin_struct = [{item: item, procedure: procedure, location: location}]
    if ptr_valid(self.data_proc_plugins) eq 1 then begin
        append_array, (*self.data_proc_plugins), plugin_struct
    endif else self.data_proc_plugins = ptr_new(plugin_struct)
end

;+
; NAME: 
;     getDataProcessingPlugins
;     
; PURPOSE: 
;     returns an array of structures, one for each data processing plugin
;
;-    
function spd_ui_plugin_manager::getDataProcessingPlugins
    if ptr_valid(self.data_proc_plugins) then begin
        return, *self.data_proc_plugins
    endif else return, 0
end

;+
; NAME: 
;     parseConfig
;     
; PURPOSE: 
;     parses a SPEDAS configuration file (.txt)
;
;-  
function spd_ui_plugin_manager::parseConfig, filename
    mission_name = ''
    file_template = { VERSION: 1.0, $
                 DATASTART: 0, $
                 DELIMITER: 58b, $
                 MISSINGVALUE: '', $
                 COMMENTSYMBOL: ";", $
                 FIELDCOUNT: 2, $
                 FIELDTYPES: [7, 7], $
                 FIELDNAMES: ['type', 'info'], $
                 FIELDLOCATIONS: [0, 10], $
                 FIELDGROUPS: [0, 1] $
                 }
    
    ; make sure this is a valid ascii file
    test_ascii = query_ascii(filename)
    if test_ascii ne 1 then return, 0

    plugin_data = read_ascii(filename, template=file_template, count=num_items)
    
    for plugin_idx = 0, n_elements(plugin_data.type)-1 do begin
        plugin_type = plugin_data.type[plugin_idx]
        plugin_info = plugin_data.info[plugin_idx]
        info_components = strsplit(plugin_info, ',', /extract)
        case plugin_type of
            'project': begin
                ; project definition
                mission_name = info_components[0]
            end
            'load_data': begin
                ; plugin has a load data panel
                if n_elements(info_components) eq 2 then begin
                    self->addLoadDataPanel, mission_name, info_components[0], info_components[1]
                endif else if n_elements(info_components) eq 1 then begin
                    self->addLoadDataPanel, mission_name, info_components[0], '' ; use mission name for tab/panel title
                endif else begin
                    dprint, dlevel = 0, 'Not enough arguments to add the Load Data panel for ' + filename
                endelse
            end
            'menu': begin
                ; plugin has a menu item
                if n_elements(info_components) eq 3 then begin
                    self->addPluginMenu, info_components[2], info_components[0], info_components[1]
                endif else begin
                    dprint, dlevel = 0, 'Not enough arguments to add plugin item to the "Plugins" menu. '
                endelse
            end
            'config': begin
                ; plugin has a config panel
                self->addFileConfigPanel, mission_name, info_components[0]
            end
            'data_processing': begin
                ; found a data processing plugin
                if n_elements(info_components) eq 3 then begin
                    self->addDataProcessingPlugin, info_components[2], info_components[0], info_components[1]
                endif else begin
                    dprint, dlevel = 0, 'Not enough arguments to add plugin item to the "Data Processing" panel'
                endelse
            end
            'about': begin
                ; found an "about" page for the plugin
                if n_elements(info_components) eq 1 then begin
                    self->addAboutPlugin, mission_name, info_components[0]
                endif else begin
                    dprint, dlevel = 0, 'Not enough arguments to add plugin''s About Page to the GUI'
                endelse
            end
            else: dprint, dlevel = 0, 'Error loading plugin, unknown plugin type: ' + string(plugin_type)
        endcase
    endfor
    return, 1
end

function spd_ui_plugin_manager::loadSaveFile, save_file
    catch, error_status
    if error_status ne 0 then return, 0
    result = file_test(save_file, /read)
    if result then begin
      restore, save_file 
      return, 1
    endif 
    return, 0
end

function spd_ui_plugin_manager::init
    getpluginpath, path
    if ~undefined(path) then begin
        ; find any save files in the plugins directory
        ;    (this is useful for adding new plugins to 
        ;     the VM releases that can't compile routines)
        plugin_sav_files = file_search(path, '*.sav')        
        for sav_idx = 0, n_elements(plugin_sav_files)-1 do begin
            if plugin_sav_files[sav_idx] eq '' then continue 
            if self->loadSaveFile(plugin_sav_files[sav_idx]) ne 1 then begin
                dprint, dlevel = 0, 'Error loading the save file at: ' + plugin_sav_files[sav_idx]
                ; throw an error dialog too, since we're probably in the VM here
                sa_error = error_message('Error loading the save file at: ' + plugin_sav_files[sav_idx], /error)
            endif
        endfor
        
        ; find the plugin files
        plugin_files = file_search(path, '*.txt')
        
        ; load the plugin files
        for plugin_idx = 0, n_elements(plugin_files)-1 do begin
            if self->parseConfig(plugin_files[plugin_idx]) ne 1 then begin
                dprint, dlevel = 0, 'Error parsing the configuration file: ' + plugin_files[plugin_idx]
            endif
        endfor
        
    endif
    return, 1
end

pro spd_ui_plugin_manager__define
    compile_opt idl2
    state = { SPD_UI_PLUGIN_MANAGER, $
        plugin_menus: ptr_new(), $
        plugin_file_config_panels: ptr_new(), $
        plugin_load_data_panels: ptr_new(), $
        plugin_about_pages: ptr_new(), $
        data_proc_plugins: ptr_new() $
    }
end