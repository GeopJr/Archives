.PHONY: all install uninstall build test potfiles
PREFIX ?= /usr

offline ?=
use_libsoup ?=
# Remove the devel headerbar style:
# make release=1
release ?=

all: build

update_bundle:
	valac $(if $(offline),--define=OFFLINE,) $(if $(use_libsoup),--define=USE_LIBSOUP,) --target-glib=2.74 --pkg gtk4 $(if $(offline),,--pkg libarchive) $(if $(use_libsoup),,--pkg libsoup-3.0) --pkg webkitgtk-6.0 update-bundle.vala && ./update-bundle

build:
	meson setup builddir --prefix=$(PREFIX)
	meson configure builddir -Ddevel=$(if $(release),false,true)
	meson compile -C builddir

install:
	meson install -C builddir

uninstall:
	sudo ninja uninstall -C builddir

test:
	ninja test -C builddir

potfiles:
	find ./ -not -path '*/.*' -type f -name "*.in" | sort > po/POTFILES
	echo "" >> po/POTFILES
	find ./ -not -path '*/.*' -type f -name "*.ui" -exec grep -l "translatable=\"yes\"" {} \; | sort >> po/POTFILES
	echo "" >> po/POTFILES
	find ./ -not -path '*/.*' -type f -name "*.vala" -exec grep -l "_(\"\|ngettext" {} \; | sort >> po/POTFILES
