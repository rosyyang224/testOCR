#!/bin/bash

echo "Creating virtual environment..."
python3 -m venv .venv
source .venv/bin/activate
pip install -r pyenv/requirements.txt

echo "Python env ready!"
echo ""
echo "In Xcode, set:"
echo "PYTHON_LIBRARY=$(python3 -c 'import sysconfig; print(sysconfig.get_config_var(\"LIBDIR\") + \"/libpython3.12.dylib\")')"
echo "PYTHONPATH=$(python3 -c 'import site; print(site.getsitepackages()[0])')"
