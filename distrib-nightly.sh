#!/bin/sh

# This script compiles and uploads linux nightly builds (both x86 and x86_64 by
# default, unless skipped by $OHR_SKIP_X86 and $OHR_SKIP_X86_64) and also all
# platform-independent nightly files, like the plotdict.

# Scheduling this script to run automatically is equivalent to giving the other devs
# write access to your automatic build machine. Don't do it unless you trust them all.
# (which James fortunately does, and the build machine is reasonably sandboxed, so!)

# This script checks out two copies of the OHRRPGCE svn repository: one for building
# from, the other is kept clean and used for packaging the source.

UPLOAD_SERVER="james_paige@motherhamster.org"
UPLOAD_FOLDER="HamsterRepublic.com"
UPLOAD_DEST="$UPLOAD_SERVER:$UPLOAD_FOLDER"
TODAY=`date "+%Y-%m-%d"`

mkdir -p ~/src/nightly
cd ~/src/nightly

if [ ! -d ohrrpgce ] ; then
  echo nightly snapshot not found, checking out from svn...
  mkdir ohrrpgce
  svn checkout https://rpg.hamsterrepublic.com/source/wip ./ohrrpgce/wip
fi

cd ohrrpgce

echo removing old nightly source snapshot...
rm ohrrpgce-source-nightly.zip

echo zipping up new nightly snapshot
svn info wip > wip/svninfo.txt
zip -q -r ohrrpgce-source-nightly.zip wip -x "*/.svn/*"
ls -l ohrrpgce-source-nightly.zip

echo uploading new nightly source snapshot
scp -p ohrrpgce-source-nightly.zip $UPLOAD_DEST/ohrrpgce/nightly/

# This is duplicated in distrib-nightly-win[-wine].sh
echo uploading plotscripting docs
cd wip/docs
./update-html.sh
cd ../..
scp -p wip/docs/plotdict.xml $UPLOAD_DEST/ohrrpgce/docs/
scp -p wip/docs/htmlplot.xsl $UPLOAD_DEST/ohrrpgce/docs/
scp -p wip/docs/plotdictionary.html $UPLOAD_DEST/ohrrpgce/docs/


echo Now we go to build the linux nightlies

cd ..

if [ ! -d ohrrpgce-build ] ; then
  echo nightly snapshot not found, checking out from svn...
  mkdir ohrrpgce-build
  svn checkout https://rpg.hamsterrepublic.com/source/wip ./ohrrpgce-build/wip
fi

cd ohrrpgce-build/wip

svn cleanup
svn update

# Compile and create .bz2 and .deb files
./distrib.sh

mv distrib/ohrrpgce-linux-*-wip-x86.tar.bz2 distrib/ohrrpgce-linux-wip-x86.tar.bz2 &&
scp -p distrib/ohrrpgce-linux-wip-x86.tar.bz2 $UPLOAD_DEST/ohrrpgce/nightly/
mv distrib/ohrrpgce-linux-*-wip-x86_64.tar.bz2 distrib/ohrrpgce-linux-wip-x86_64.tar.bz2 &&
scp -p distrib/ohrrpgce-linux-wip-x86_64.tar.bz2 $UPLOAD_DEST/ohrrpgce/nightly/
rm distrib/ohrrpgce-linux-wip-*.tar.bz2

# ohrrpgce-player-linux-bin-minimal.zip is downloaded by the distrib menu
# (Leave out minimal x86_64 package for now, as it's not used)
mv distrib/ohrrpgce-player-linux-bin-minimal-*-wip-x86.zip distrib/ohrrpgce-player-linux-bin-minimal.zip &&
scp -p distrib/ohrrpgce-player-linux-bin-minimal.zip $UPLOAD_DEST/ohrrpgce/nightly/
rm distrib/ohrrpgce-player-linux-bin-minimal.zip

for arch in i386 amd64 ; do
  if [ -f distrib/ohrrpgce_*.wip-*_$arch.deb ] ; then
    # The deb packages are named ohrrpgce_$YYYY.$MM.$DD.$codename-$revision_$arch.deb,
    # so we need to delete the previous package from the same arch but different filename.
    ssh $UPLOAD_SERVER rm "$UPLOAD_FOLDER/ohrrpgce/nightly/ohrrpgce_*.wip-*_$arch.deb"
    scp -p distrib/ohrrpgce_*.wip-*_$arch.deb $UPLOAD_DEST/ohrrpgce/nightly/
    rm distrib/ohrrpgce_*_$arch.deb
  fi
done

scp -p IMPORTANT-nightly.txt $UPLOAD_DEST/ohrrpgce/nightly/
