SOSMAG data can be accessed using the ESA HAPI server https://swe.ssa.esa.int/hapi/

This HAPI server requires authentication in order to obtain a username and a password.

Unfortunately, during authentication this HAPI server also uses redirection, and for this to work correctly we need to set some CURL properties (CURLOPT_FOLLOWLOCATION, CURLOPT_UNRESTRICTED_AUTH). 

Currently (August 2023), IDL does not have a way to set these properties and as a result, accessing this HAPI server using IDL does not work. It works with other programming languages, for example with python or php. 

