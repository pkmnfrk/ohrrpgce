REM pass 'nightly' as first argument to build nightlies instead of releases

set SCONS_ARGS = debug=0 gengcc=1

REM default locations for required programs
SET ISCC="C:\Program Files\Inno Setup 5\iscc.exe"
SET SVN="C:\Program Files\Subversion\bin\svn.exe"

REM In case we need the 32 bit versions on a 64 bit system...
IF EXIST %ISCC% GOTO NOX86ISCC
SET ISCC="C:\Program Files (x86)\Inno Setup 5\iscc.exe"
:NOX86ISCC
IF EXIST %SVN% GOTO NOX86SVN
SET SVN="C:\Program Files (x86)\Subversion\bin\svn.exe"
:NOX86SVN

REM Also support the Sliksvn install location
IF EXIST %SVN% GOTO NOSLIKSVN
SET SVN="C:\Program Files\Sliksvn\bin\svn.exe"
:NOSLIKSVN
IF EXIST %SVN% GOTO NOSLIKSVNX86
SET SVN="C:\Program Files (x86)\Sliksvn\bin\svn.exe"
:NOSLIKSVNX86

ECHO Verifying support programs...
IF NOT EXIST support\cp.exe GOTO NOSUPPORT
IF NOT EXIST support\zip.exe GOTO NOSUPPORT
IF NOT EXIST %ISCC% GOTO NOINNO
REM This checks whether euc is in the PATH (as required by scons)
for %%X in (euc.exe) do set EUC=%%~$PATH:X
IF NOT EXIST "%EUC%" GOTO NOEUPHORIA

IF NOT EXIST tmpdist GOTO SKIPDELTMPDIST
RMDIR /S /Q tmpdist
:SKIPDELTMPDIST
MKDIR tmpdist

REM ------------------------------------------
ECHO Building executables...

del game.exe custom.exe relump.exe unlump.exe hspeak.exe

ECHO   Windows executables...
CALL scons game custom hspeak unlump.exe relump.exe %SCONS_ARGS%
IF NOT EXIST game.exe GOTO NOEXE
IF NOT EXIST custom.exe GOTO NOEXE
IF NOT EXIST unlump.exe GOTO NOEXE
IF NOT EXIST relump.exe GOTO NOEXE
IF NOT EXIST hspeak.exe GOTO NOEXE

ECHO   Lumping Vikings of Midgard
IF NOT EXIST vikings.rpg GOTO SKIPDELVIKING
DEL vikings.rpg
:SKIPDELVIKING
relump vikings\vikings.rpgdir vikings.rpg > NUL
IF NOT EXIST vikings.rpg GOTO NORPG

REM ------------------------------------------
ECHO Erasing old distrib files ...

IF NOT EXIST distrib\ohrrpgce-minimal.zip GOTO DONEDELMINIMAL
del distrib\ohrrpgce-minimal.zip
:DONEDELMINIMAL
IF NOT EXIST distrib\ohrrpgce.zip GOTO DONEDELCUSTOM
del distrib\ohrrpgce.zip
:DONEDELCUSTOM
IF NOT EXIST distrib\ohrrpgce-win-installer.exe GOTO DONEDELINSTALL
del distrib\ohrrpgce-win-installer.exe
:DONEDELINSTALL

REM ------------------------------------------
ECHO Packaging minimalist ohrrpgce-minimal.zip ...
del tmpdist\*.???
support\cp game.exe tmpdist
support\cp custom.exe tmpdist
support\cp hspeak.exe tmpdist
support\cp plotscr.hsd tmpdist
support\cp scancode.hsi tmpdist
support\cp README-game.txt tmpdist
support\cp README-custom.txt tmpdist
support\cp IMPORTANT-nightly.txt tmpdist
support\cp LICENSE-binary.txt tmpdist
support\cp whatsnew.txt tmpdist
support\cp SDL.dll tmpdist
support\cp SDL_mixer.dll tmpdist
support\cp gfx_directx.dll tmpdist
REM wget.exe needed to download everything else (unzip is downloaded as an .exe)
mkdir tmpdist\support
support\cp support\wget.exe tmpdist\support
support\cp -r data tmpdist\data
support\cp -r ohrhelp tmpdist\ohrhelp
mkdir tmpdist\docs
support\cp docs\*.URL tmpdist\docs
support\cp docs\plotdictionary.html tmpdist\docs
support\cp docs\more-docs.txt tmpdist\docs

cd tmpdist
..\support\zip -9 -q -r ..\distrib\ohrrpgce-minimal.zip *.*
cd ..

rmdir /s /q tmpdist
mkdir tmpdist
cd tmpdist
..\support\unzip -q ..\distrib\ohrrpgce-minimal.zip game.exe
cd ..
IF NOT EXIST tmpdist\game.exe GOTO SANITYFAIL
del tmpdist\game.exe

REM ------------------------------------------
ECHO Packaging ohrrpgce.zip ...
del tmpdist\*.???
support\cp game.exe tmpdist
support\cp custom.exe tmpdist
support\cp hspeak.exe tmpdist
support\cp README-game.txt tmpdist
support\cp README-custom.txt tmpdist
support\cp IMPORTANT-nightly.txt tmpdist
support\cp whatsnew.txt tmpdist
support\cp LICENSE.txt tmpdist
support\cp LICENSE-binary.txt tmpdist
support\cp plotscr.hsd tmpdist
support\cp scancode.hsi tmpdist
support\cp gfx_directx.dll tmpdist
support\cp SDL.dll tmpdist
support\cp SDL_mixer.dll tmpdist
support\cp -r data tmpdist\data
support\cp -r ohrhelp tmpdist\ohrhelp
mkdir tmpdist\docs
support\cp docs\FAQ.URL tmpdist\docs
support\cp docs\HOWTO.URL tmpdist\docs
support\cp docs\*.html tmpdist\docs
support\cp docs\plotdict.xml tmpdist\docs
support\cp docs\htmlplot.xsl tmpdist\docs
support\cp docs\more-docs.txt tmpdist\docs
mkdir tmpdist\support
support\cp support\madplay.exe tmpdist\support
support\cp support\LICENSE-madplay.txt tmpdist\support
support\cp support\oggenc.exe tmpdist\support
support\cp support\LICENSE-oggenc.txt tmpdist\support
support\cp support\wget.exe tmpdist\support
support\cp support\wget.hlp tmpdist\support
support\cp support\zip.exe tmpdist\support
support\cp support\unzip.exe tmpdist\support
support\cp support\rcedit.exe tmpdist\support
support\cp support\LICENSE-rcedit.txt tmpdist\support
support\cp relump.exe tmpdist\support
support\cp unlump.exe tmpdist\support
support\cp vikings.rpg tmpdist
support\cp -r "vikings\Vikings script files" "tmpdist\Vikings script files"
support\cp "vikings\README-vikings.txt" tmpdist
support\cp -r import tmpdist\import

cd tmpdist
..\support\zip -9 -q -r ..\distrib\ohrrpgce.zip *.* -x *.svn*
cd ..

del tmpdist\*.???
cd tmpdist
..\support\unzip -q ..\distrib\ohrrpgce.zip custom.exe
cd ..
IF NOT EXIST tmpdist\custom.exe GOTO SANITYFAIL
del tmpdist\custom.exe

REM ------------------------------------------
ECHO Packaging ohrrpgce-win-installer.exe ...
echo InfoBeforeFile=IMPORTANT-nightly.txt > iextratxt.txt
IF "%1"=="nightly" GOTO LEAVEWARNTXT
echo. > iextratxt.txt
:LEAVEWARNTXT

%ISCC% /Q /Odistrib /Fohrrpgce-win-installer ohrrpgce.iss
del iextratxt.txt
IF NOT EXIST distrib\ohrrpgce-win-installer.exe GOTO SANITYFAIL

REM ------------------------------------------
ECHO Packaging source snapshot zip ...
IF NOT EXIST %SVN% GOTO NOSVN
IF NOT EXIST support\grep.exe GOTO NOSUPPORT
IF NOT EXIST support\sed.exe GOTO NOSUPPORT
CALL distver.bat
RMDIR /s /q tmpdist
MKDIR tmpdist
CD tmpdist
%SVN% info .. | ..\support\grep "^URL:" | ..\support\sed s/"^URL: "/"SET REPOSITORY="/ > svnrepo.bat
CALL svnrepo.bat
ECHO   Checkout...
%SVN% co -q %REPOSITORY%
%SVN% info %OHRVERCODE% > %OHRVERCODE%/svninfo.txt
del svnrepo.bat
ECHO   Zip...
..\support\zip -q -r ..\distrib\ohrrpgce-source.zip *.*
cd ..

REM ------------------------------------------
ECHO Cleaning up...
rmdir /s /q tmpdist

REM ------------------------------------------
ECHO Rename results...
ECHO %OHRVERDATE%-%OHRVERCODE%
move distrib\ohrrpgce-minimal.zip distrib\ohrrpgce-minimal-%OHRVERDATE%-%OHRVERCODE%.zip
move distrib\ohrrpgce.zip distrib\ohrrpgce-%OHRVERDATE%-%OHRVERCODE%.zip
move distrib\ohrrpgce-win-installer.exe distrib\ohrrpgce-win-installer-%OHRVERDATE%-%OHRVERCODE%.exe
move distrib\ohrrpgce-source.zip distrib\ohrrpgce-source-%OHRVERDATE%-%OHRVERCODE%.zip

REM ------------------------------------------
ECHO Done.
GOTO DONE

REM ------------------------------------------
:NOSUPPORT
ECHO ERROR: Support files are missing, unable to continue.
GOTO DONE

:NOINNO
ECHO ERROR: Innosetup 5 is missing, unable to continue.
ECHO Default location: %ISCC%
ECHO Download from http://www.jrsoftware.org/isdl.php
GOTO DONE

:NOSVN
ECHO ERROR: SVN (Subversion) is missing, unable to continue.
ECHO Default location: %SVN%
ECHO Download from http://subversion.tigris.org/
GOTO DONE

:NOEUPHORIA
ECHO ERROR: Euphoria is missing (not in the PATH), unable to continue.
ECHO Download from http://www.OpenEuphoria.com/
GOTO DONE

:NOEXE
ECHO ERROR: An executable failed to build, unable to continue.
GOTO DONE

:NORPG
ECHO ERROR: Failed to relump vikings of midgard
GOTO DONE

:SANITYFAIL
ECHO ERROR: Sanity test failed, distribution files are incomplete!
GOTO DONE

REM ------------------------------------------
:DONE
