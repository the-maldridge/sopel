#!/bin/sh

find_source_files() {
    find . -name '*.py' -size +0 -print | grep -ve './docs' -e './contrib' -e './conftest.py'
}
files=$(find_source_files)
# These are acceptable (for now). 128 and 127 should be removed eventually.
ignore='--ignore=E501,E128,E127'
# These ones are not acceptable. They should be removed as we fix them.
ignore=$ignore',E401,E251,E226,E126,E502,E302,W293,W291,E221,W391,E225,E121,E122,E261,E211,E231,E262,E271,E265,E111,E131,E713,'
# For now, go through all the checking stages and only die at the end
exit_code=0

if ! pep8 $ignore --filename=*.py $(find_source_files); then
    echo "ERROR: PEP8 does not pass."
    exit_code=1
fi

fail_coding=false
for file in $(find_source_files); do
    line=$(head -n 1 $file)
    if echo $line | grep -q '#!/usr/bin/env python'; then
        line=$(head -n 2 $file | tail -n 1)
    fi
    if ! echo $line | grep -q '# coding=utf8'; then
        echo $file
        fail_coding=true
    fi
done
if $fail_coding; then
    echo "ERROR: Above files do not have utf8 coding declared."
    exit_code=1
fi

# Find files which use the unicode type but (heuristically) don't make it py3
# safe
fail_py3_unicode=false
for file in $(find_source_files); do
    if grep -qle 'unicode(' -e 'class .*(unicode)' $file; then
        if ! grep -L 'unicode = str' $file; then
            fail_py3_unicode=true
        fi
    fi
done
if $fail_py3_unicode; then
    echo "ERROR: Above files use unicode() but do not make it safe for Python 3."
    exit_code=1
fi

fail_unicode_literals=false
for file in $files; do
    if ! grep -L 'from __future__ import unicode_literals' $file; then
        fail_unicode_literals=true
    fi
done
if $fail_unicode_literals; then
    echo "ERROR: Above files do not have unicode_literals import."
    exit_code=1
fi

exit $exit_code
