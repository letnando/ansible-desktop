
.PHONY: help

# Shell that make should use
SHELL:=bash

# Ubuntu distro string
OS_VERSION_NAME := $(shell lsb_release -cs)

HOSTNAME = $(shell hostname)


# Allows user to specify private hostname in ".inventory file"
PRIVATE_INVENTORY = ".inventory"
ifeq ($(shell test -e $(PRIVATE_INVENTORY) && echo -n yes),yes)
	INVENTORY=$(PRIVATE_INVENTORY)
else
    INVENTORY = "inventory"
endif

# Both ANSIBLE commands need the "ansible_user" for the zsh role

# Main Ansible Playbook Command (prompts for password)
ANSIBLE=ansible-playbook personal_computer.yml -v -i $(INVENTORY) -l $(HOSTNAME) --ask-become-pass -e '{"ansible_user": "$(shell whoami)"}'

# Travis CI Ansible Playbook Command (doesn't prompt for password)
TRAVIS=travis
ifeq "$(HOSTNAME)" "$(TRAVIS)"
	ANSIBLE=ansible-playbook personal_computer.yml -v -i $(INVENTORY) -l $(HOSTNAME) -e '{"ansible_user": "$(shell whoami)"}'
endif

$(warning ANSIBLE is $(ANSIBLE))

# - to suppress if it doesn't exist
-include make.env

help:
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
# adds anything that has a double # comment to the phony help list
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ".:*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


setup_inventory_and_group_vars:
setup_inventory_and_group_vars:
	# Ensure chosen hostname is present in group_vars and .inventory folder
	bash scripts/setup_inventory_and_group_vars.sh

bootstrap-before-install:
bootstrap-before-install:
	# Apt Dependencies (removes apt ansible)
	bash scripts/before_install_apt_dependencies.sh

bootstrap-install:
bootstrap-install:
	# Python3 Dependencies (install python3 ansible)
	bash scripts/install_python3_dependencies.sh

bootstrap-before-script:
bootstrap-before-script:
	# Ensure "$$HOME/.local/bin" is part of PATH
	bash scripts/before_script_path_fix.sh
	# Source folder (to ensure initial setup loads this file)
	. /etc/profile

bootstrap: setup_inventory_and_group_vars bootstrap-before-install bootstrap-install bootstrap-before-script
bootstrap: ## Installs dependencies needed to run playbook

bootstrap-check:
bootstrap-check: ## Check that PATH and requirements are correct

	# Check that PATH and requirements are correct
	ansible --version | grep "python version"
	python3 -m pip list | grep psutil

check: DARGS?=
check: ## Checks personal-computer.yml playbook
	@$(ANSIBLE) --check

install: DARGS?=
install: ## Installs everything via personal-computer.yml playbook
	@$(ANSIBLE) --skip-tags="ticktick, nautilus-mounts"
	# ticktick doesn't work on fresh install for some reason
	# no planned test coverage to nautilus-mounts as it deals with file mounts

all: ## Does most eveything with Ansible and Make targets
all: bootstrap bootstrap-check install non-ansible

non-ansible:
non-ansible: ## Runs all non-ansible make targets for fresh install (all target)

	# No user input required
	make flameshot-keybindings

	# Dropping these as Ubuntu 20.04 defaults to Python3.8
	# make python-three-six-install
	# make python-three-six-supporting
	# make python-three-seven-install
	# make python-three-seven-supporting

	# Ubuntu 20.04 defaults
	make python-three-eight-install
	make python-three-eight-supporting

lint:  ## Lint the repo
lint:
	bash scripts/lint.sh

docs-develop:
docs-develop: ## setup pipenv to develop docs
	pipenv
	pipenv run python3 -m pip install -r requirements.txt
	pipenv shell
	# make docs-live

docs-live:
docs-live: ## create live docs
	bash scripts/docs-live.sh

zsh:
zsh: ## Install zsh and oh-my-zsh
	@$(ANSIBLE) --tags="zsh"

common:
common: ## Install Common apt packages
	@$(ANSIBLE) --tags="common"


cherrytree:
cherrytree: ## Install Cherrytree using snaps
	@$(ANSIBLE) --tags="common-snaps" -e '{"snaps_common": ["cherrytree"]}'

docker:
docker: ## Install Docker and Docker-Compose
	@$(ANSIBLE) --tags="docker"

kite:
kite: ## Install Kite, AI Autocomplete and Docs for Python
	bash scripts/install_kite.sh

	# VS Code Extension is `kiteco.kite`

jetbrains-mono:
jetbrains-mono: ## Install JetBrains Mono font
	@$(ANSIBLE) --tags="jetbrains-mono"

nautilus-mounts:
nautilus-mounts: ## Setup for CIFS Network Mounts, with Nautilus Scripts
	@$(ANSIBLE) --tags="nautilus-mounts"

# python:
# python: ## Install Python 3.6 and 3.7, with extras
# 	@$(ANSIBLE) --tags="python"

python-three-six-install: ## Install python3.6 using apt (main install)
python-three-six-install:

	sudo apt-get update

	# Start by updating the packages list and installing the prerequisites:
	sudo apt install software-properties-common

	# install python3.6
	sudo apt update
	sudo apt install -y python3.6

	# python3 pip
	sudo apt install -y python3-pip

python-three-six-supporting: ## Install useful packages
python-three-six-supporting:

	# upgrade pip
	python3.6 -m pip install --user --upgrade pip
	-python3.6 -m pip install --upgrade keyrings.alt --user
	-python3.6 -m pip install --user --upgrade setuptools

	# python3 pytest
	sudo apt install -y python3-pytest

	# At this point, Python 3.6 is installed on your Ubuntu system and ready to be used.
	# You can verify it by typing:
	python3.6 --version
	python3.6 -m pip --version
	python3.6 -m pytest --version

	python3.6 -m pip install --user twine
	python3.6 -m pip install --user wheel
	python3.6 -m pip install --user flit
	python3.6 -m pip install --user cookiecutter
	python3.6 -m pip install --user pipenv
	python3.6 -m pip install --user pre-commit

python-three-seven-install: ## Install python3.7 using apt (main install)
python-three-seven-install:

	sudo apt-get update

	# Start by updating the packages list and installing the prerequisites:
	sudo apt install software-properties-common

	# Next, add the deadsnakes PPA to your sources list:
	# sudo add-apt-repository ppa:deadsnakes/ppa # not for 19.04
	# when prompted, press Enter to continue

	# Once the repository is enabled, install Python 3.7 with: (added libpython3.7-dev for pip installs)
	# - httptools wasn't installing correctly until adding it
	# - see: https://github.com/huge-success/sanic/issues/1503#issuecomment-469031275
	sudo apt update
	sudo apt install -y python3.7 libpython3.7-dev

	# At this point, Python 3.7 is installed on your Ubuntu system and ready to be used.
	# You can verify it by typing:
	python3.7 --version

python-three-seven-supporting: ## Install useful packages
python-three-seven-supporting:

	# python3 pip
	sudo apt install -y python3-pip

	# upgrade pip
	python3.7 -m pip install --user --upgrade pip
	-python3.7 -m pip install --upgrade keyrings.alt --user
	-python3.7 -m pip install --user --upgrade setuptools

	# python3 pytest
	sudo apt install -y python3-pytest

	# At this point, Python 3.7 is installed on your Ubuntu system and ready to be used.
	# You can verify it by typing:
	python3.7 --version
	python3.7 -m pip --version
	python3.7 -m pytest --version

	python3.7 -m pip install --user twine
	python3.7 -m pip install --user wheel
	python3.7 -m pip install --user flit
	python3.7 -m pip install --user cookiecutter
	python3.7 -m pip install --user pipenv
	python3.7 -m pip install --user pre-commit

python-three-eight-install: ## Install python3.8 using apt (main install)
python-three-eight-install:

	sudo apt-get update

	# Start by updating the packages list and installing the prerequisites:
	sudo apt install software-properties-common

	# Once the repository is enabled, install Python 3.8 with: (added libpython3.8-dev for pip installs)
	# - httptools wasn't installing correctly until adding it
	# - see: https://github.com/huge-success/sanic/issues/1503#issuecomment-469031275
	sudo apt update
	sudo apt install -y python3.8 libpython3.8-dev

	# At this point, Python 3.8 is installed on your Ubuntu system and ready to be used.
	# You can verify it by typing:
	python3.8 --version

python-three-eight-supporting: ## Install useful packages
python-three-eight-supporting:

	# python3 pip
	sudo apt install -y python3-pip

	# upgrade pip
	python3.8 -m pip install --user --upgrade pip
	-python3.8 -m pip install --upgrade keyrings.alt --user
	-python3.8 -m pip install --user --upgrade setuptools

	# python3 pytest
	sudo apt install -y python3-pytest

	# At this point, Python 3.7 is installed on your Ubuntu system and ready to be used.
	# You can verify it by typing:
	python3.8 --version
	python3.8 -m pip --version
	python3.8 -m pytest --version

	python3.8 -m pip install --user twine
	python3.8 -m pip install --user wheel
	python3.8 -m pip install --user flit
	python3.8 -m pip install --user cookiecutter
	python3.8 -m pip install --user pipenv
	python3.8 -m pip install --user pre-commit

common-snaps:
common-snaps: ## Install Common Snaps
	@$(ANSIBLE) --tags="common-snaps"

chat-clients:
chat-clients: ## Install Chat Client Snaps
	@$(ANSIBLE) --tags="chat-clients"

development-tools:
development-tools: ## Install VS Code, Postman, and Sublime Text Snaps
	@$(ANSIBLE) --tags="development-tools"

web-browsers:
web-browsers: ## Installs web-browsers as snaps
	@$(ANSIBLE) --tags="web-browsers"

peek:
peek: ## Install Peek (GIF Screen Recorder) using a Flatpak
	@$(ANSIBLE) --tags="flatpak" -e '{"flatpak_applications": ["com.uploadedlobster.peek"]}'

timeshift:
timeshift: ## Install Timeshift (Backup Utility) using a PPA and apt
	@$(ANSIBLE) --tags="timeshift"

flameshot:
flameshot: ## Install Flameshot 0.6.0 Screenshot Tool and Create Custom GNOME Keybindings
	@$(ANSIBLE) --tags="flameshot"

flameshot-keybindings: ## Install Flameshot and Update gnome keybindings
flameshot-keybindings:
	# For whatever reason, I bricked my GNOME session trying this with ansible
	# so for now, I'm just going to chain this to the new machine script
	# and leave it as a make target

	# Update gnome keybindings
	# source: https://askubuntu.com/a/1116076

	gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "[]"
	gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/']"
	gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/ name 'flameshot'
	gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/ command '/usr/bin/flameshot gui'
	gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/ binding 'Print'

github-cli:
github-cli: ## Install GitHub CLI deb, directly from GitHub Release
	@$(ANSIBLE) --tags="github-cli"

# gnome-boxes:
# gnome-boxes: ## Install GNOME Boxes, using Flatpak
# 	@$(ANSIBLE) --tags="flatpak,gnome-boxes"

gnome-extensions:
gnome-extensions: ## Install GNOME Extensions
	@$(ANSIBLE) --tags="gnome-extensions"

gnome-keybindings:
gnome-keybindings: ## Set my GNOME Keybindings
	@$(ANSIBLE) --tags="gnome-keybindings"

gnome-themes:
gnome-themes: ## Install and Set GNOME Theme, Icons, and Cursor
	@$(ANSIBLE) --tags="gnome-themes"

gnome-preferences:
gnome-preferences: ## Set GNOME Preferences
	@$(ANSIBLE) --tags="gnome-preferences"

gtk3-icon-browser: ## Launch the GTK Icon Browser
gtk3-icon-browser:
	# https://askubuntu.com/questions/695796/view-list-of-all-available-unique-icons-with-their-names-and-thumbnail/695958
	# sudo apt-get install -y gtk-3-examples
	# Installs in gnome-preferences role
	@gtk3-icon-browser &

nordvpn:
nordvpn: ## Install Peek (GIF Screen Recorder) using a PPA and apt
	@$(ANSIBLE) --tags="nordvpn"

stacer:
stacer: ## Install Stacer (Material System Utility)
	@$(ANSIBLE) --tags="stacer"

flatpak:
flatpak: ## Install Peek (GIF Screen Recorder) using a PPA and apt
	@$(ANSIBLE) --tags="flatpak"

steam: flatpak
steam: ## Install Steam, using Flatpak
	@$(ANSIBLE) --tags="flatpak" -e '{"flatpak_applications": ["com.valvesoftware.Steam"]}'

evolution:
evolution: ## Install Evolution Email/Calendar/Tasks Client, using Flatpak
	@$(ANSIBLE) --tags="flatpak,evolution-remove-apt" -e '{"flatpak_applications": ["org.gnome.Evolution"]}'

protonmail-bridge:
protonmail-bridge: ## Install Protonmail Bridge Deb from their website
	@$(ANSIBLE) --tags="protonmail-bridge"

tresorit: ## Install Tresorit
tresorit:
	wget -O ~/Downloads/tresorit_installer.run https://installerstorage.blob.core.windows.net/public/install/tresorit_installer.run
	chmod +x ~/Downloads/tresorit_installer.run
	$(echo $0) ~/Downloads/tresorit_installer.run

libreoffice:
libreoffice: ## Install LibreOffice Office Suite, using Flatpak
	@$(ANSIBLE) --tags="flatpak,libreoffice-remove-apt" -e '{"flatpak_applications": ["org.libreoffice.LibreOffice"]}'

yarn:
yarn: ## Installs Yarn (and Nodejs)
	# This role takes care of $$PATH
	@$(ANSIBLE) --tags="yarn"

ticktick:
ticktick: ## Installs TickTick using yarn global Nativefier
	@$(ANSIBLE) --tags="ticktick"


.DEFAULT_GOAL := help
