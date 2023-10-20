export LC_ALL=C

DESIRED="$HOME/sbts-bin"

for i in $DESIRED ; do
    if ! echo ":${PATH}:" | fgrep ":${i}:" > /dev/null ; then
        PATH="$i:$PATH"
    fi
done

localize_event() {
    (. ~/virtualenvs/sbts/bin/activate ; python3 ~/sbts-bin/localize_event.py $*)
}
