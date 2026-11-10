# Build static sphinx

1. Create a Python virtual environment

```shell
mkdir -p sphinx-static; cd sphinx-static
python3 -m venv .venv
```

2. Install Sphinx with the Addons that you want

```shell
. .venv/bin/activate
pip install -U sphinx furo myst-parser rinohtype
```

3. Install **pyinstaller** and **staticx**

```shell

sudo apt install patchelf
pip install -U pyinstaller staticx

```

4. Run this command to generate the program


```shell
pyinstaller --onefile --name sphinx \
  --collect-all sphinx \
  --collect-all myst_parser \
  --collect-all furo \
  --copy-metadata rinohtype \
  --collect-all rinohtype \
  --collect-all rinoh \
  --collect-all sphinx_basic_ng \
  --collect-all pygments \
  --collect-all a11y_pygments \
  --collect-all rinoh_typeface_texgyreheros \
  --collect-all rinoh_typeface_texgyrecursor \
  --collect-all rinoh_typeface_texgyrepagella \
  --collect-all rinoh_typeface_dejavuserif \
  launcher.py

```

5. Make it static

```
staticx dist/sphinx dist/sphinx.static
```

