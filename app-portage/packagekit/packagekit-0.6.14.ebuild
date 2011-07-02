# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils multilib python nsplugins
if [[ ${PV} = 9999 ]]; then
	inherit autotools git
fi

MY_PN="PackageKit"

DESCRIPTION="Manage packages in a secure way using a cross-distro and cross-architecture API"
HOMEPAGE="http://www.packagekit.org/"

if [[ ${PV} = 9999 ]]; then
	EGIT_REPO_URI="git://anongit.freedesktop.org/git/${PN}/${MY_PN}"
	KEYWORDS=""
	DEPEND=">=dev-util/gtk-doc-1.9"
	DOCS="AUTHORS MAINTAINERS NEWS README TODO"
else
	MY_P=${MY_PN}-${PV}
	SRC_URI="http://www.packagekit.org/releases/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~ppc ~x86"
	S="${WORKDIR}/${MY_P}"
	DOCS="AUTHORS ChangeLog MAINTAINERS NEWS README TODO"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="connman cron gtk +introspection networkmanager nls nsplugin pm-utils qt4 test udev"

CDEPEND="
	connman? ( net-misc/connman )
	gtk? ( dev-libs/dbus-glib
		media-libs/fontconfig
		>=x11-libs/gtk+-2.14.0:2
		>=x11-libs/gtk+-2.91.0:3
		x11-libs/pango )
	introspection? ( >=dev-libs/gobject-introspection-0.9.8 )
	networkmanager? ( >=net-misc/networkmanager-0.6.4 )
	nsplugin? ( dev-libs/dbus-glib
		dev-libs/glib:2
		dev-libs/nspr
		x11-libs/cairo
		>=x11-libs/gtk+-2.14.0:2
		>=x11-libs/gtk+-2.91.0:3
		x11-libs/pango )
	qt4? ( >=x11-libs/qt-core-4.4.0
		>=x11-libs/qt-dbus-4.4.0
		>=x11-libs/qt-sql-4.4.0 )
	udev? ( || ( >=sys-fs/udev-171[gudev]
		>=sys-fs/udev-145[extras] ) )
	dev-db/sqlite:3
	>=dev-libs/dbus-glib-0.74
	>=dev-libs/glib-2.22:2
	>=sys-apps/dbus-1.1.0
	>=sys-auth/polkit-0.97
"
RDEPEND="${CDEPEND}
	pm-utils? ( sys-power/pm-utils )
	>=app-portage/layman-1.2.3
	>=sys-apps/portage-2.2_rc39
	sys-auth/consolekit
"
# docbook-xml-dtd:4.2 needed for man page generation
DEPEND="${CDEPEND}
	nsplugin? ( >=net-libs/xulrunner-1.9.1 )
	test? ( qt4? ( dev-util/cppunit >=x11-libs/qt-gui-4.4.0 ) )
	app-text/docbook-xml-dtd:4.2
	dev-libs/libxslt
	>=dev-util/intltool-0.35.0
	dev-util/pkgconfig
	sys-devel/gettext"

# FIXME: tests are failing
# PackageKit:ERROR:pk-self-test.c:949:pk_test_control_get_properties_cb: assertion failed (text == "application/x-rpm;application/x-deb"): ("" == "application/x-rpm;application/x-deb")
RESTRICT="test"

# NOTES:
# doc is in the tarball and always installed
# using >=dbus-1.3.0 instead of >=dbus-1.1.1 because of a bug fixed in 1.3.0

# TODO:
# gettext is probably needed only if +nls but too long to fix
# +doc to install doc/website
# check if test? qt? ( really needs qt-gui)

# UPSTREAM:
# documentation/website with --enable-doc-install
# failing tests

pkg_setup() {
	python_set_active_version 2
}

src_prepare() {
	if [[ ${PV} = 9999 ]]; then
		gtkdocize || die
		intltoolize --force || die
		eautoreconf
	fi

	# prevent pyc/pyo generation
	ln -sfn $(type -P true) py-compile

	# allow building with >=glib-2.28.7:2 (fixed upstream in 0.6.15)
	sed -e 's:GLIB_CHECK_VERSION(2,28,7):GLIB_CHECK_VERSION(2,29,4):g' \
		-i src/pk-main.c || die "sed src/pk-main.c failed"
}

src_configure() {
	local myconf=""

	# localstatedir: for gentoo it's /var/lib but for $PN it's /var
	# dep-tracking,option-check,libtool-lock,strict,local: obvious reasons
	# gtk-doc: doc already built
	# command,debuginfo,gstreamer,service-packs: not supported by backend
	# managed: failing (see UPSTREAM in ebuild header)
	econf \
		${myconf} \
		--localstatedir=/var \
		--disable-dependency-tracking \
		--enable-libtool-lock \
		--disable-strict \
		--disable-local \
		--disable-gtk-doc \
		--disable-command-not-found \
		--disable-debuginfo-install \
		--disable-gstreamer-plugin \
		--disable-service-packs \
		--disable-static \
		--enable-man-pages \
		--disable-dummy \
		--enable-portage \
		--with-default-backend=portage \
		--with-security-framework=polkit \
		$(use_enable connman) \
		$(use_enable cron) \
		$(use_enable gtk gtk-module) \
		$(use_enable introspection) \
		$(use_enable networkmanager) \
		$(use_enable nls) \
		$(use_enable nsplugin browser-plugin) \
		$(use_enable pm-utils) \
		$(use_enable qt4 qt) \
		$(use_enable test tests) \
		$(use_enable udev device-rebind)
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	dodoc ${DOCS} || die "dodoc failed"

	if use nsplugin; then
		src_mv_plugins /usr/$(get_libdir)/mozilla/plugins
	fi

	ebegin "Removing .la files"
	find "${D}" -name '*.la' -exec rm -f '{}' + || die
	eend
}

pkg_postinst() {
	python_mod_optimize $(python_get_sitedir)/${PN}
}

pkg_prerm() {
	einfo "Removing downloaded files with ${MY_PN}..."
	[[ -d "${ROOT}"/var/cache/${MY_PN}/downloads/ ]] && \
		rm -rf /var/cache/PackageKit/downloads/*
}

pkg_postrm() {
	python_mod_cleanup /usr/$(get_libdir)/python*/site-packages/${PN}
}
