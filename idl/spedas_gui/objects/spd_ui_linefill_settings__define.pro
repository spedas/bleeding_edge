;+
;NAME: 
; spd_ui_linefill_settings__define
;
;PURPOSE:  
; spd_ui_linefill_settings is an object that holds the settings needed 
; to describe a shaded area between 2 traces. The spd_ui_panel object field 
; 'traceFillSettings' is a container holding objects of this type.
;
;CALLING SEQUENCE:
; lineFillSettings = Obj_New("SPD_UI_LINEFILL_SETTINGS")
;
; REQUIRED INPUT:
; none
;
;KEYWORDS:
; dataX1             string naming X component of line 1
; dataY1             string naming Y component of line 1
; dataX2             string naming X component of line 2
; dataY2             string naming Y component of line 2
; FillColor          int array describing color of shading
; Opacity            float between 0 and 1 describing opacity of shaded area.
; nosave             will not save a copy on startup
;
;OUTPUT:
; spd_ui_linefill_settings object reference
;
;METHODS:
; Copy
; Save
; Reset
;
;NOTES:
;  Methods: GetProperty,SetProperty,GetAll,SetAll are managed automatically using the parent class
;  spd_ui_getset.  You can still call these methods when using objects of type spd_ui_linefill_settings.
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-11-20 12:50:10 -0800 (Mon, 20 Nov 2017) $
; $LastChangedRevision: 24322 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_linefill_settings__define.pro $
;-----------------------------------------------------------------------------------

FUNCTION SPD_UI_LINEFILL_SETTINGS::Copy

	out = Obj_New("SPD_UI_LINEFILL_SETTINGS",/nosave)
	selfClass = Obj_Class(self)
	outClass = Obj_Class(out)
	IF selfClass NE outClass THEN BEGIN
		dprint,  'Object classes not identical'
		RETURN, 1
	END
	Struct_Assign, self, out
	RETURN, out

	END ;--------------------------------------------------------------------------------

PRO SPD_UI_LINEFILL_SETTINGS::Save

	copy = self->copy()
	if ptr_valid(self.origsettings) then begin
		ptr_free,self.origsettings
	endif
	self.origsettings = ptr_new(copy->getall())

	END ;--------------------------------------------------------------------------------

PRO SPD_UI_LINEFILL_SETTINGS::Reset

	if ptr_valid(self.origsettings) then begin
		self->setall,*self.origsettings
		self->save
	endif

	END ;--------------------------------------------------------------------------------

FUNCTION SPD_UI_LINEFILL_SETTINGS::Init, $
						dataX1=dataX1,               $ ; string x component of line 1
						dataY1=dataY1,               $ ; string y component of line 1
						dataX2=dataX2,               $ ; string x component of line 2
						dataY2=dataY2,               $ ; string y component of line 2
						FillColor=fillcolor,         $ ; int array for color [r,g,b]
						Opacity=opacity,             $ ; fill opacity
						nosave=nosave                  ; will not save copy on startup
						
	Catch, theError
	IF theError NE 0 THEN BEGIN
	   Catch, /Cancel
	   ok = Error_Message(Traceback=Keyword_Set(debug))
	   RETURN, 0
	ENDIF
  
	; Check that all parameters have values
	IF N_Elements(dataX1) EQ 0 THEN dataX1 = ''
	IF N_Elements(dataY1) EQ 0 THEN dataY1 = '' 
	IF N_Elements(dataX2) EQ 0 THEN dataX2 = ''
	IF N_Elements(dataY2) EQ 0 THEN dataY2 = ''
	IF N_Elements(fillcolor) EQ 0 THEN fillcolor = [0,0,0]
	IF n_elements(opacity) eq 0 then opacity = 1D
	opacity = (opacity gt 1) ? 1 : (opacity lt 0) ? 0 : opacity

  ; Set all parameters
	self.dataX1 = dataX1
	self.dataY1 = dataY1
	self.dataX2 = dataX2
	self.dataY2 = dataY2
	self.fillcolor = fillcolor
	self.opacity = opacity
 
	if ~keyword_set(nosave) then begin      
		self->save
	endif 
  
	RETURN, 1
                 
END ;--------------------------------------------------------------------------------

PRO SPD_UI_LINEFILL_SETTINGS__DEFINE

   struct = { SPD_UI_LINEFILL_SETTINGS, $

			; Identify lines to fill
			dataX1 : '',             $ ; string naming x component of line 1
			dataY1 : '',             $ ; string naming y component of line 1
			dataX2 : '',             $ ; string naming x component of line 2
			dataY2 : '',             $ ; string naming y component of line 2            
                 
			; Fill Properties
			fillcolor : [0,0,0],    $ ; line color
			opacity   : 0D,         $ ; how opaque is the line 
              
			;Original Settings
			origsettings: ptr_New(),   $ ;pointer to original settings in case of reset
			INHERITS SPD_UI_READWRITE, $ ; generalized read/write methods
			inherits spd_ui_getset     $ ;generalized getProperty,setProperty,getAll,setAll methods
                     
}

END
