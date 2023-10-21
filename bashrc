export LC_ALL=C

DESIRED="$HOME/sbts-bin"

for i in $DESIRED ; do
    if ! echo ":${PATH}:" | fgrep ":${i}:" > /dev/null ; then
        PATH="$i:$PATH"
    fi
done
