'OHRRPGCE - relump.bi
'(C) Copyright 1997-2006 James Paige and Hamster Republic Productions
'Please read LICENSE.txt for GPL License details and disclaimer of liability
'See README.txt for code docs and apologies for crappyness of this code ;)
'Auto-generated by MAKEBI from relump.bas

#IFNDEF RELUMP_BI
#DEFINE RELUMP_BI

declare function editstr$ (stri$, key$, cur, max, number)
declare sub fatalerror (e$)
declare sub forcewd (wd$)
declare function getcurdir$
declare function readkey$
declare sub readscatter (s$, lhold, array(), start)
declare function rightafter$ (s$, d$)
declare function rotascii$ (s$, o)
declare sub xbload (f$, array(), e$)
declare function readbit (bb() as integer, byval w as integer, byval b as integer)  as integer
declare sub setbit (bb() as integer, byval w as integer, byval b as integer, byval v as integer)
declare sub array2str (arr() as integer, byval o as integer, s$)
declare function isfile (n$) as integer
declare function isdir (sdir$) as integer
declare function matchmask(match as string, mask as string) as integer
declare sub fixorder (f$)
declare sub copyfile (s$, d$, buf() as integer)
declare sub findfiles (fmask$, byval attrib, outfile$, buf())
declare sub lumpfiles (listf$, lump$, path$, buffer())

#ENDIF
