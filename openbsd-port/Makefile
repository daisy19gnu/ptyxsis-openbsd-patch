# $OpenBSD$

COMMENT =	GTK4-based terminal emulator for GNOME

V =		49.3
DISTNAME =	ptyxis-${V}
PKGNAME =	ptyxis-${V}

CATEGORIES =	x11 x11/gnome

HOMEPAGE =	https://gitlab.gnome.org/chergert/ptyxis

MAINTAINER =	MINORI IKEDA <daisy19@gmail.com>

# GPLv3+
PERMIT_PACKAGE =	Yes

SITES =		https://gitlab.gnome.org/chergert/ptyxis/-/archive/${V}/

MODULES =	devel/meson \
		x11/gnome

MODGNOME_TOOLS =	desktop-file-utils gtk-update-icon-cache

BUILD_DEPENDS =	devel/gsettings-desktop-schemas \
		devel/gettext,-tools

LIB_DEPENDS =	devel/json-glib \
		x11/gnome/libadwaita>=1.6 \
		x11/gtk+4 \
		devel/vte3,-gtk4>=0.78

RUN_DEPENDS =	devel/gsettings-desktop-schemas

CONFIGURE_ARGS =	-Ddevelopment=false

.include <bsd.port.mk>
