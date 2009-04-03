'OHRRPGCE - util.bi
'(C) Copyright 1997-2006 James Paige and Hamster Republic Productions
'Please read LICENSE.txt for GPL License details and disclaimer of liability
'See README.txt for code docs and apologies for crappyness of this code ;)
'Auto-generated by MAKEBI from util.bas

#IFNDEF UTIL_BI
#DEFINE UTIL_BI

declare function bound overload (byval n AS INTEGER, byval lowest AS INTEGER, byval highest AS INTEGER) AS INTEGER
declare function bound overload (byval n as double, byval lowest as double, byval highest as double) as double
declare function large (byval n1 AS INTEGER, byval n2 AS INTEGER) AS INTEGER
declare function loopvar (byval var AS INTEGER, byval min AS INTEGER, byval max AS INTEGER, byval inc AS INTEGER) AS INTEGER
declare function small (byval n1 AS INTEGER, byval n2 AS INTEGER) AS INTEGER
declare function trimpath (filename as string) as string
declare function trimfilename (filename as string) as string
declare function trimextension (filename as string) as string
declare function justextension (filename as string) as string
declare function anycase (filename as string) as string
declare sub touchfile (filename as string)
declare function rotascii (s as string, o as integer) as string
declare function escape_string(s as string, chars as string) as string
declare function sign_string(n as integer, neg_str as string, zero_str as string, pos_str as string) as string
declare function zero_default(n as integer, zerocaption AS STRING="default", displayoffset AS INTEGER = 0) as string
declare Function wordwrap(Byval inp as string, byval width as integer, byval sep as string = chr(10)) as string
declare sub split(byval in as string, ret() as string, sep as string = chr(10))
declare function textwidth(byval z as string) as integer
declare sub str_array_append (array() AS STRING, s AS STRING)

'also appears in udts.bi
#ifndef Stack
TYPE Stack
  pos as integer ptr
  bottom as integer ptr
  size as integer
END TYPE
#endif

declare sub createstack (st as Stack)
declare sub destroystack (st as Stack)
declare sub checkoverflow (st as Stack, byval amount as integer = 1)
#define pushs(stack, datum) *(stack).pos = (datum) : (stack).pos += 1
#define pops(stack, var) (stack).pos -= 1 : (var) = *(stack).pos
'read from a stack offset from the last push (eg. 0 is last int pushed, -1 is previous)
#define reads(stack, off) stack.pos[(off) - 1]
#define checkunderflow(stack, amount) ((stack).pos - (amount) < (stack).bottom)


#ENDIF
