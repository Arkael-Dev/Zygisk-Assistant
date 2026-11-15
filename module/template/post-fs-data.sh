MODPATH="${0%/*}"
. "$MODPATH/common_func.sh"
alog "post-fs-data (mode=$MODE)"
[ "$MODE" = "perapp" ] || sh "$MODPATH/apply.sh" early
sh "$MODPATH/apply.sh" appsync
