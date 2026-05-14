#!/bin/bash

print_help()
{
echo """Elaine's Desktop Integrator
A tool for integrating those pesky, AppImages and loose executables into the GNOME launcher.

-h, --help              Print this help.
-n, --name <NAME>       Define name of application
-e, --exec <PATH>       Define path to main executable.
-i, --icon <ICON>       Define path to icon.
-k, --kwords <KWORDS>   Define keywords, a ;-delimited string of terms searchable by GNOME launcher.
-l, --local             Include this argument if the application's executable must be run locally. A startup script will be created.
--clean                 Delete all created files before exiting."""

exit 0
}

assert_is_absolute()
{
SEARCH="$(echo $1 | grep -i ^/)"
if [[ $? -ne 0 ]]; then
  echo "ERROR: Expected absolute path: $1"
fi
}

assert_not_directory()
{
DESC="$(file $1 | grep -i directory)"
if [[ $? -eq 0 ]]; then
  echo "ERROR: Expected a file, but '$1' is a directory."
fi
}

assert_file_does_not_exist()
{
ls $1 2>/dev/null
if test $? -eq 0; then
  echo "ERROR: File already exists at: $1"
fi
}

POSITIONAL_ARGS=()

if [[ $# -eq 0 ]]; then
  print_help
fi

LOCAL=0

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      print_help
      ;;
    --clean)
      CLEAN=1
      shift
      ;;
    -n|--name)
      NAME="$2"
      shift; shift
      ;;
    -e|--exec)
      assert_is_absolute "$2"
      assert_not_directory "$2"
      EXECUTABLE="$2"
      shift; shift
      ;;
    -i|--icon)
      assert_is_absolute "$2"
      assert_not_directory "$2"
      ICON="$2"
      shift; shift
      ;;
    -k|--kwords)
      KEYWORDS="$2"
      shift; shift
      ;;
    -l|--local)
      LOCAL=1
      shift
      ;;
    -*|--*)
      echo "ERROR: unknown option: $1"
      ;;
    *)
      echo "ERROR: Positional arguments not accepted: $1"
      ;;
  esac
done

APP_PATH="$HOME/.local/share/applications"
BIN_PATH="$HOME/.local/bin"
FILES_CREATED=()

EXEC_FILE="${BIN_PATH}/$(basename $EXECUTABLE)"
if [[ $LOCAL -eq 0 ]]; then
  assert_file_does_not_exist "$EXEC_FILE"
  echo "Creating link to file: $EXECUTABLE at $EXEC_FILE"
  ln -s "$EXECUTABLE" "$EXEC_FILE"
  FILES_CREATED+=("$EXEC_FILE")
else
  EXEC_FILE+=".sh"
  assert_file_does_not_exist "$EXEC_FILE"
  echo "Creating startup file: $EXEC_FILE pointing to $EXECUTABLE"
  echo "#!/bin/bash"                    >  "$EXEC_FILE"
  echo "cd $(dirname $EXECUTABLE)"      >> "$EXEC_FILE"
  echo "./$(basename $EXECUTABLE)"      >> "$EXEC_FILE"
  chmod +x "$EXEC_FILE"
  FILES_CREATED+=("$EXEC_FILE")
fi

DESKTOP_FILE="${APP_PATH}/$(basename $EXECUTABLE).desktop"
assert_file_does_not_exist "$DESKTOP_FILE"
echo "Creating file: $DESKTOP_FILE"
touch "$DESKTOP_FILE"
echo "[Desktop Entry]"          >  "$DESKTOP_FILE"
echo "Name=$NAME"               >> "$DESKTOP_FILE"
echo "Type=Application"         >> "$DESKTOP_FILE"
echo "Terminal=false"           >> "$DESKTOP_FILE"
echo "Exec=$EXEC_FILE"          >> "$DESKTOP_FILE"
echo "Icon=$ICON"               >> "$DESKTOP_FILE"
echo "Keywords=$KEYWORDS"       >> "$DESKTOP_FILE"
FILES_CREATED+=("$DESKTOP_FILE")

if [[ "$CLEAN" ]]; then
  for FILE in "${FILES_CREATED[@]}"; do
    echo "Deleting file: $FILE"
    rm "$FILE"
  done
fi

exit 0
