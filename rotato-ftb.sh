#!/bin/bash
REPO="http://www.boylecraft.net/mindcrack"
MODPACK="Ultimate"
export PATH=./bin:$PATH
uname=$( uname )
if test "$uname" = "Windows_NT"; then
	# Windows
	FTB_CFG="$APPDATA/ftblauncher/ftblaunch.cfg"
elif test "$uname" = "Darwin"; then
	# Mac
	FTB_CFG="$HOME/Library/Application Support/ftblauncher/ftblaunch.cfg"
elif test "$uname" = "Linux"; then
	# Linux
	FTB_CFG="$HOME/.ftblauncher/ftblaunch.cfg"
else
	echo "I don't know what the hell OS you're using." && exit
fi
# Parse config file and get a usable directory in both Linux/OSX and Windows
# this is such a hack but it works
MC_BASE=$( sed -n 's/^installPath=\(.*\)$/\1/p' "$FTB_CFG" | sed 's/\\\([^\\]\)/\1/g' )
test "$MC_BASE" = "" && echo "There was a problem finding/parsing your ftblaunch.cfg." && exit

MC_JARS="$MC_BASE/$MODPACK/instMods"
MC_MODS="$MC_BASE/$MODPACK/minecraft/mods"

function get_list() {
	curl -f -s $REPO/$1
	if test $? != 0; then
		echo "Error retrieving file $1" 1>&2
		return 1
	fi
}
function process_list() {
	DESTDIR="$1"
	mkdir -p "$DESTDIR" 2>/dev/null
	while read FILE; do
		DEST="$DESTDIR/$( basename "$FILE" )"
		get_file "$FILE" "$DEST"
	done
}
function get_file() {
	FILE="$1"
	DEST="$2"
	echo "Downloading $FILE"
	curl -f -k -# "$FILE" -o ./tempfile &&\
	mv -f ./tempfile "$DEST" &&\
	echo "Saved to $DEST" && echo && return 0
	echo
	return 1
}

REMOVE_LIST=$( get_list mods_deprecated.txt )
for FILE in $REMOVE_LIST; do mv "$MC_MODS/$FILE" "$MC_MODS/$FILE.disabled"; done
get_list mods_forge.txt | process_list "$MC_MODS"
get_list mods_jar.txt   | process_list "$MC_JARS"
echo "$REPO/Recipes.cfg" | process_list "$MC_BASE/$MODPACK/minecraft/config/GregTech"

# super dodgy REI Minimap points conversion
REI_FILE="$MC_BASE/Mindcrack/minecraft/mods/rei_minimap/minecraft.denofsyn.com.DIM0.points"
VOXELMAP_FILE="$MC_BASE/VoxelMods/voxelMap/minecraft.denofsyn.com.points"
[ -e "$REI_FILE" ] && echo "Converting points..." && sed 's/^\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\).*$/name:\1,x:\2,z:\4,y:\3,enabled:\5,red:0.5,green:0.3,blue:0.3,suffix:,world:,dimensions:-1#0#/' "$REI_FILE" >> "$VOXELMAP_FILE" && mv "$REI_FILE" "$REI_FILE".processed

echo "All done! Press a key." && read
