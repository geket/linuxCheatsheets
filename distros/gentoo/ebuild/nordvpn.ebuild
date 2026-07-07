# Copyright 1999-2025 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg-utils tmpfiles systemd

MY_PV=$(ver_rs 3 '-')

DESCRIPTION="NordVPN native client"
HOMEPAGE="https://nordvpn.com"
SRC_URI="amd64? ( https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/nordvpn_${MY_PV}_amd64.deb )
	arm64? ( https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/nordvpn_${MY_PV}_arm64.deb )"

LICENSE="NordVPN"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

# TODO: verify that list of RDEPEND is complete
RDEPEND="net-misc/networkmanager
		net-vpn/networkmanager-openvpn
		dev-libs/libxml2
		net-dns/libidn2
		app-misc/ca-certificates
		sys-process/procps
		net-firewall/iptables
		sys-apps/iproute2
		acct-group/nordvpn"


RESTRICT="strip"
S="${WORKDIR}"

src_unpack() {
	# Unpack Debian package containing application's files
	unpack_deb ${A}
	gzip "${S}"/usr/share/doc/nordvpn/changelog.Debian.gz -d
	gzip "${S}"/usr/share/man/man1/nordvpn.1.gz -d
}

# In my instance I had to replace src_install() with this. Emerge would not compile otherwise
# Remove all of the lines after the closing } bracket of src_install as well
src_install() {
    cd "${S}"

    # OpenRC init script
    newinitd "${FILESDIR}/nordvpn-r1.initd" ${PN}

    # Logrotate
    insinto /etc/logrotate.d
    newins "${FILESDIR}/logrotate" nordvpn

    # Main binaries
    into /usr
    dobin usr/bin/nordvpn
    dosbin usr/sbin/nordvpnd

    # NordVPN private libraries + permissions
    insinto /usr/lib/
    doins -r usr/lib/nordvpn

    fowners root:nordvpn /usr/lib/nordvpn/norduserd
    fperms 0550 /usr/lib/nordvpn/norduserd

    fowners root:nordvpn /usr/lib/nordvpn/nordfileshare
    fperms 0550 /usr/lib/nordvpn/nordfileshare

    fowners root:nordvpn /usr/lib/nordvpn/openvpn
    fperms 0550 /usr/lib/nordvpn/openvpn
}
