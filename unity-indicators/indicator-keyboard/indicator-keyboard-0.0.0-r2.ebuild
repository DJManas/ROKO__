# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
VALA_MIN_API_VERSION="0.22"
VALA_MAX_API_VERSION="0.22"

inherit gnome2-utils ubuntu-versionator vala autotools eutils

UURL="mirror://ubuntu/pool/main/i/${PN}"
URELEASE="trusty"
UVER_PREFIX="+14.04.20140403.1"

DESCRIPTION="Indicator keyboard used by the Unity desktop"
HOMEPAGE="https://launchpad.net/indicator-keyboard"
SRC_URI="${UURL}/${MY_P}${UVER_PREFIX}.orig.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
RESTRICT="mirror"

RDEPEND="dev-libs/libdbusmenu:=
	unity-base/bamf:=
	unity-indicators/ido:="
DEPEND="${RDEPEND}
	dev-libs/libappindicator
	dev-libs/libgee:0
	app-i18n/ibus
	dev-libs/libindicate-qt
	>=x11-libs/libnotify-0.7.5
	media-sound/pulseaudio
	net-misc/url-dispatcher
	>=dev-lang/vala-0.22.0
	>=app-i18n/ibus-1.5.0[vala]
	sys-apps/accountsservice[vala]"

S="${WORKDIR}/${PN}-${PV}${UVER_PREFIX}"
MAKEOPTS="${MAKEOPTS} -j1"

src_prepare() {
	vala_src_prepare
	export VALA_API_GEN="$VAPIGEN"

	# Make "Sound Settings" open gnome-control-center sound settings #
	# sed -e 's:sound-nua:sound:g' \
	#	-i src/service.vala

	# Make indicator start using XDG autostart #
	# sed -e '/NotShowIn=/d' \
	#	-i data/indicator-sound.desktop.in
	eautoreconf
}

src_configure() {
	econf
	# local mycmakeargs="${mycmakeargs}
	#	-DVALA_COMPILER=$VALAC
	#	-DVAPI_GEN=$VAPIGEN"
	# cmake-utils_src_configure
}

# src_install() {
#	cmake-utils_src_install

	# Remove upstart jobs as we use XDG autostart desktop files to spawn indicators #
#	rm -rf "${ED}usr/share/upstart"
#}

pkg_preinst() {
	gnome2_schemas_savelist
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_schemas_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_schemas_update
	gnome2_icon_cache_update
}
