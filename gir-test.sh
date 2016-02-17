#!/bin/sh
if [ -n "$1" ];  then
	mawk -W interactive -f ../funcs.awk -f gir.awk -f gir-test.awk -f gir-tests/$1.awk
else
	for f in gir-tests/*awk; do
		echo "Testing $f"
		mawk -W interactive -f ../funcs.awk -f gir.awk -f gir-test.awk -f $f
		echo "################################################################################"
	done
fi
