{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  alsa-lib,
  libjpeg,
  libtool,
  libxkbcommon,
  nss,
  nspr,
  udev,
  gtk3,
  libgbm,
  libusb1,
  unixODBC,
  libmysqlclient,
  qt5,
  xorg,
  cups,
  dbus,
  pango,
  libpulseaudio,
  libbsd,
  freetype,
  fontconfig,
  coreutils,
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
  ];

  buildInputs = [
    alsa-lib
    libjpeg
    libtool
    libxkbcommon
    nss
    nspr
    udev
    gtk3
    libgbm
    libusb1
    unixODBC
    qt5.qtbase
    xorg.libXdamage
    xorg.libXtst
    xorg.libXv
    xorg.libX11
    xorg.libXext
    xorg.libxcb
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXScrnSaver
    xorg.libXxf86vm
    libpulseaudio
    libbsd
    freetype
    fontconfig
  ];

  dontWrapQtApps = true;

  runtimeDependencies = [
    cups
    dbus
    pango
    libmysqlclient
  ];

  # Remove unneeded files and broken libs
  # Aligning with official package cleanup
  unpackPhase = ''
    dpkg-deb -x $src .

    # Remove standard unneeded directories
    rm -rf usr/share/{fonts,locale}
    rm -f usr/bin/misc
    rm -rf opt/kingsoft/wps-office/{desktops,INSTALL}

    # Remove problematic bundled libraries
    # Removing libstd++, libgcc_s, libnss, libdbus, libbz2, libjpeg to force system usage
    # Also removing broken plugins
    rm -f opt/kingsoft/wps-office/office6/lib{peony-wpsprint-menu-plugin,bz2,jpeg,stdc++,gcc_s,odbc*,nss*,dbus-1,ssl,crypto,freetype,fontconfig}.so*
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    cp -r opt $out
    cp -r usr/{bin,share} $out

    # Fixup paths in launchers
    for i in $out/bin/*; do
      substituteInPlace $i \
        --replace "/opt/kingsoft/wps-office" "$out/opt/kingsoft/wps-office"
      substituteInPlace $i \
        --replace-fail '[ $haveConf -eq 1 ] &&' '[ ! $currentMode ] ||'
    done

    # Fixup desktop files
    for i in $out/share/applications/*; do
      substituteInPlace $i \
        --replace "/usr/bin" "$out/bin" \
        --replace "/opt/kingsoft/wps-office" "$out/opt/kingsoft/wps-office"
    done

    runHook postInstall
  '';

  preFixup = ''
    # Official fixes
    if [ -f $out/opt/kingsoft/wps-office/office6/addons/cef/libcef.so ]; then
      patchelf --add-needed libudev.so.1 $out/opt/kingsoft/wps-office/office6/addons/cef/libcef.so
    fi

    # Fix mysql linkage if exists
    if [ -f $out/opt/kingsoft/wps-office/office6/libFontWatermark.so ]; then
      patchelf --replace-needed libmysqlclient.so.18 libmysqlclient.so $out/opt/kingsoft/wps-office/office6/libFontWatermark.so || true
      patchelf --add-rpath ${libmysqlclient}/lib/mariadb $out/opt/kingsoft/wps-office/office6/libFontWatermark.so || true
    fi
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
