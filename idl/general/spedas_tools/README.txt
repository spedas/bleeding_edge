This directory contains tools that were originally developed for
SPEDAS, yet are self-contained and useful enough to justify 
putting them into the "general" directory, where they'll be 
available for use in other programs without requiring the
rest of the SPEDAS code.

SPEDAS developers:  Please ensure that any code in this directory
is self-contained enough to compile and run with only the "general"
directory on the IDL path.  Code should be as backward-compatible
as possible with older IDL versions.   Please do not include any
bulky data or documentation files in this directory.

non-SPEDAS developers:  Please consult jwl@ssl.berkeley.edu, or
other SPEDAS developers, before adding or changing anything
in this directory.  Other SPEDAS code depends on these tools,
and any changes must undergo rigorous QA testing before being
released.
