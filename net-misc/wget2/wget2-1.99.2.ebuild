# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="GNU Wget2 is a file and recursive website downloader"
HOMEPAGE="https://gitlab.com/gnuwget/wget2"
SRC_URI="mirror://gnu/wget/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0/0" # subslot = libwget.so version
KEYWORDS="~amd64 ~x86"

IUSE="brotli bzip2 doc +gnutls gpgme +http2 idn libressl lzma openssl pcre psl +ssl test valgrind xattr zlib"

REQUIRED_USE="valgrind? ( test )"

RDEPEND="
	brotli? ( app-arch/brotli )
	bzip2? ( app-arch/bzip2 )
	!gnutls? ( dev-libs/libgcrypt:= )
	ssl? (
		gnutls? ( net-libs/gnutls )
		!gnutls? (
			libressl? ( dev-libs/libressl:0= )
			!libressl? ( dev-libs/openssl:0= )
		)
	)
	gpgme? (
		app-crypt/gpgme
		dev-libs/libassuan
		dev-libs/libgpg-error
	)
	http2? ( net-libs/nghttp2 )
	idn? ( net-dns/libidn2:= )
	lzma? ( app-arch/xz-utils )
	pcre? ( dev-libs/libpcre2 )
	psl? ( net-libs/libpsl )
	xattr? ( sys-apps/attr )
	zlib? ( sys-libs/zlib )
"

# man pages require app-text/pandoc which requires lots of haskell stuff
DEPEND="
	${RDEPEND}
	doc? ( app-doc/doxygen )
	valgrind? ( dev-util/valgrind )
"

src_prepare() {
	default

	# Upstream attempts to be "smart" by calling ldconfig in
	# install-exec-hook
	sed '/^install-exec-hook:/,+2d' -i Makefile.in || die
}

src_configure() {
	local ssl_impl="$(usex ssl $(usex gnutls gnutls openssl) none)"

	local myeconfargs=(
		--with-plugin-support
		--with-ssl="${ssl_impl}"
		--without-libidn
		--without-libmicrohttpd
		$(use_enable doc)
		$(use_enable valgrind valgrind-tests)
		$(use_enable xattr)
		$(use_with brotli brotlidec)
		$(use_with bzip2)
		$(use_with gpgme)
		$(use_with http2 libnghttp2)
		$(use_with idn libidn2)
		$(use_with lzma)
		$(use_with pcre libpcre2)
		$(use_with psl libpsl)
		$(use_with zlib)
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	default

	doman docs/man/man{1/*.1,3/*.3}

	find "${ED}" -type f \( -name "*.a" -o -name "*.la" \) -delete || die
	rm "${ED}"/usr/bin/${PN}_noinstall || die
}
