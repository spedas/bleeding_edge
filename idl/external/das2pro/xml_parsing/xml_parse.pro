;+
;Procedure: xml_parse
;
;Purpose: Converts xml to ordered hash array
;
;Note: 'xml_parse' function name is introduced in IDL 8.6 version.
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2019-08-19 13:48:54 -0700 (Mon, 19 Aug 2019) $
;$LastChangedRevision: 27621 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2pro/xml_parsing/xml_parse.pro $
;-

function xml_parse, s
  t = obj_new('das_xml_to_orderhash')
  t->ParseFile, s, /xml_string
  return, t->getHash()
end