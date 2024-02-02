## [venv](https://docs.python.org/3/library/venv.html)
```bash
python -m venv "$HOME/.venv"

source "$HOME.venv/bin/activate"

source "$HOME.venv/bin/deactivate"
```

## [Miniconda3](https://docs.conda.io/en/latest/miniconda.html)
```bash
conda init zsh # powershell

conda env list
conda create -n <venv_name> python=3.10
conda activate <venv_name>

conda deactivate
conda remove --name <venv_name> --all
```

## Requirements File
### Create Requirements File
`pip freeze > requirements.txt`

### Create Requirements File After Development
```bash
pip install pipreqs
pipreqs <ProjectLocation>
```

### Installing Python Packages From a Requirements File
`pip install -r requirements.txt`

### Maintain Requirements File
```bash
#  check for missing dependencies
pip check

# outdated packages
pip list --outdated

## upgrade all packages
# Windows powershell
# pip freeze | %{$_.split('==')[0]} | %{pip install -U $_}
pip list --outdated | %{$_.split(' ')[0]} | ?{$_ -notmatch "^-|^package|^warning|^error"} | %{pip install -U $_}
# Linux & macOS
# pip freeze | cut -d= -f1 | xargs -r -n1 pip install -U
pip list --outdated | grep -Eiv "^-|^package|^warning|^error" | cut -d" " -f1 | xargs -r -n1 pip install -U

# upgrade the required package 
pip install -U <PackageName>
pip install -U -r requirements.txt

# update the requirements file
pip freeze > requirements.txt
```