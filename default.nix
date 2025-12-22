{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-core,
  libbsd,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libglvnd,
  libtool,
  libuuid,
  libxcb,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  xorg,
  zlib,
  qt5,
  libusb1,
  libpulseaudio,
  bzip2,
}:

let
  version = "12.1.2.23578";

  sources = {
    x86_64-linux = fetchurl {
      url = "https://pubwps-wps365-obs.wpscdn.cn/download/Linux/23578/wps-office_12.1.2.23578.AK.preread.sw_542884_amd64.deb";
      sha256 = "1v01d96amyb847y6ffhivbzxnmra2n2qclmq26pwzqhj0lasxd6g";
    };
    aarch64-linux = fetchurl {
      url = "https://pubwps-wps365-obs.wpscdn.cn/download/Linux/23578/wps-office_12.1.2.23578.AK.preread.sw_542882_arm64.deb";
      sha256 = "0b6mwn4xh1cchvcsh9sijx5xrk1bb3dhs3zsc38s9vxgdhsx74a9";
    };
  };

  src =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported architecture: ${stdenv.hostPlatform.system}");

in
stdenv.mkDerivation {
  pname = "wps-office-365";
  inherit version;
  inherit src;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    qt5.wrapQtAppsHook
  ];

  buildInputs = [
    alsa-lib
    at-spi2-core
    libbsd
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libglvnd
    libtool
    libuuid
    libxcb
    libxkbcommon
    mesa
    nspr
    nss
    pango
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXScrnSaver
    xorg.libXtst
    xorg.libXv
    zlib
    libusb1
    libpulseaudio
    bzip2
  ];

  runtimeDependencies = [
    libbsd
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libmysqlclient.so.18"
    "libpeony.so.3"
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r opt/kingsoft/wps-office/* $out/

    # Fixup path in wps executable scripts
    # The deb often puts binaries in /opt/kingsoft/wps-office/office6
    # and scripts in /usr/bin. We need to handle this.

    # Check structure
    ls -R $out

    # Remove broken bundled libraries that we provide
    rm -f $out/office6/libbz2.so*

    # Usually the deb installs specific launch scripts.
    # Wps 365 structure might be slighty different from standard community version.

    mkdir -p $out/bin

    # Link main executables
    # Adjust valid executables based on extracted content
    for app in wps wpp et pdf; do
      if [ -f "$out/office6/$app" ]; then
        ln -s $out/office6/$app $out/bin/$app
      fi
    done

    # Copy icons and desktop files if they exist in usr/share
    if [ -d usr/share ]; then
      cp -r usr/share $out/
    fi

    # Fix desktop files
    if [ -d $out/share/applications ]; then
      substituteInPlace $out/share/applications/*.desktop \
        --replace "/opt/kingsoft/wps-office" "$out" \
        --replace "/usr/bin" "$out/bin"
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "WPS Office 365";
    homepage = "https://www.wps.cn";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    license = licenses.unfree;
    maintainers = with maintainers; [ ];
  };
}
