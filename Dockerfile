# We bump this each release to fetch the latest stable GIRs
FROM registry.fedoraproject.org/fedora:43 AS build

ENV LANG=C.UTF-8

RUN dnf install -y 'dnf-command(builddep)' @development-tools bzip2 gcc-c++ \
        python3-markdown-it-py \
        NetworkManager-libnm-devel cairo-devel colord{,-gtk,-gtk4}-devel \
        evince-devel flatpak-devel folks-devel gcr{,3}-devel \
        geoclue2-devel geocode-glib2-devel glib2-devel glycin-devel \
        gnome-autoar-devel gnome-bluetooth-libs-devel gnome-desktop{3,4}-devel \
        gnome-online-accounts-devel gnome-shell gobject-introspection-devel \
        gom-devel granite-devel graphene-devel grilo-devel \
        gsettings-desktop-schemas-devel gsound-devel gspell-devel \
        gstreamer1-{,plugins-base-,plugins-bad-free-}devel gtk{2,3,4}-devel \
        gtksourceview{3,4,5}-devel libgtop2-devel gupnp{,-dlna,-av}-devel \
        harfbuzz-devel ibus-devel javascriptcoregtk6.0-devel keybinder3-devel \
        libappindicator-gtk3-devel libadwaita-devel libappstream-glib-devel \
        libdex-devel libgcab1-devel libgdata-devel libgda-devel libgda5-devel \
        libgudev-devel libgweather4-devel libgxps-devel libhandy1-devel \
        libmanette-devel libnma{,-gtk4}-devel libnotify-devel libpanel-devel \
        libpeas{,1}-devel libportal{,-gtk3,-gtk4}-devel librsvg2-devel \
        libsecret-devel libshumate-devel libsoup{,3}-devel libspelling-devel \
        mutter pango-devel polkit-devel poppler-glib-devel rest{,0.7}-devel \
        telepathy-glib-devel tinysparql-devel udisks-devel upower-devel \
        vte{,291,291-gtk4}-devel webkit2gtk4.1-devel webkitgtk6.0 \
        wireplumber-devel && \
    dnf builddep -y gobject-introspection ruby && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# These are extra GIRs we can't install with dnf
COPY lib/docs/scrapers/gnome/girs/*.gir /usr/share/gir-1.0/
COPY lib/docs/scrapers/gnome/girs/mutter-3 /usr/lib64/mutter-3
COPY lib/docs/scrapers/gnome/girs/mutter-4 /usr/lib64/mutter-4
COPY lib/docs/scrapers/gnome/girs/mutter-5 /usr/lib64/mutter-5
COPY lib/docs/scrapers/gnome/girs/mutter-6 /usr/lib64/mutter-6
COPY lib/docs/scrapers/gnome/girs/mutter-7 /usr/lib64/mutter-7
COPY lib/docs/scrapers/gnome/girs/mutter-8 /usr/lib64/mutter-8
COPY lib/docs/scrapers/gnome/girs/mutter-9 /usr/lib64/mutter-9
COPY lib/docs/scrapers/gnome/girs/mutter-10 /usr/lib64/mutter-10
COPY lib/docs/scrapers/gnome/girs/mutter-11 /usr/lib64/mutter-11
COPY lib/docs/scrapers/gnome/girs/mutter-12 /usr/lib64/mutter-12
COPY lib/docs/scrapers/gnome/girs/mutter-13 /usr/lib64/mutter-13
COPY lib/docs/scrapers/gnome/girs/mutter-14 /usr/lib64/mutter-14
COPY lib/docs/scrapers/gnome/girs/mutter-15 /usr/lib64/mutter-15
COPY lib/docs/scrapers/gnome/girs/mutter-16 /usr/lib64/mutter-16
COPY lib/docs/scrapers/gnome/girs/mutter-17 /usr/lib64/mutter-17

# Install the latest gobject-introspection
RUN git clone https://gitlab.gnome.org/GNOME/gobject-introspection.git \
        --branch main \
        --depth=1 \
        --recurse-submodules \
        /opt/gobject-introspection && \
    cd /opt/gobject-introspection && \
    meson setup -Ddoctool=enabled _build && \
    meson compile -C _build && \
    meson install -C _build
ENV G_IR_DOC_TOOL=/usr/local/bin/g-ir-doc-tool

# Install ruby-3.2.2
RUN curl -Os http://ftp.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz && \
    tar -xvzf ruby-3.2.2.tar.gz && \
    cd ruby-3.2.2 && \
    ./configure --prefix=/usr/local && \
    make && \
    make install

# Install the devdocs application
COPY . /opt/devdocs/
WORKDIR /opt/devdocs

RUN bundle config set --local deployment 'true' && \
    bundle install

# JavaScript/TypeScript, Jasmine, CSS
RUN bundle exec thor docs:download css javascript jasmine typescript

# GJS documentation
RUN git clone https://gitlab.gnome.org/GNOME/gjs.git && \
    cd gjs/doc/ && \
    mkdir -p /opt/devdocs/docs/gjs && \
    find . -type f -name "*.md" -exec sh -c "markdown-it {} > /opt/devdocs/docs/gjs/{}" \;
RUN bundle exec thor docs:generate gjs_scraper --force --debug

# Generate scrapers
RUN bundle exec thor gir:generate_all /usr/share/gir-1.0 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-3 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-4 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-5 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-6 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-7 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-8 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-9 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-10 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-11 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-12 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-13 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-14 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-15 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-16 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-17

# Build docsets
#
# Intentionally omitted:
# dbus10, dbusglib10, fontconfig20, freetype220, gdkpixdata20, gl10, gmodule20,
#   libxml220, win3210, xfixes40, xft20, xlib20, xrandr13
RUN echo adw1 appindicator301 appstreamglib10 atk10 atspi20 cairo10 \
        camel12 colord10 colorhug10 colordgtk10 dbusmenu04 dex1 ebook12 \
        ebookcontacts12 ecal20 edatabook12 edatacal20 edataserver12 \
        edataserverui12 edataserverui410 evincedocument30 evinceview30 \
        flatpak10 folks07 folksdummy07 folkseds07 folkstelepathy07 gcab10 gck1 \
        gck2 gcr3 gcr4 gcrui3 gda50 gda60 gdata00 gdesktopenums30 gdk20 gdk30 \
        gdk40 gdkpixbuf20 gdkx1120 gdkx1130 gdkx1140 gee08 geoclue20 \
        geocodeglib10 geocodeglib20 gio20 giounix20 girepository20 \
        girepository30 glib20 glibunix20 gly1 gly2 gnomeautoar01 \
        gnomeautoargtk01 gnomebluetooth10 gnomebluetooth30 gnomebg40 \
        gnomedesktop30 gnomedesktop40 gnomerr40 goa10 gobject20 gom10 \
        granite10 graphene10 grl03 grlnet03 grlpls03 gsk40 gsound10 gspell1 \
        gssdp12 gssdp16 gst10 gstallocators10 gstapp10 gstaudio10 \
        gstbadaudio10 gstbase10 gstcheck10 gstcodecs10 gstcontroller10 gstgl10 \
        gstinsertbin10 gstmpegts10 gstnet1 gstpbutils10 gstplayer10 gstrtp10 \
        gstrtsp10 gstsdp10 gsttag10 gstvideo10 gstvulkan10 gstwebrtc10 \
        gtk20 gtk30 gtk40 gtkosxapplication10 gtksource30 gtksource4 \
        gtksource5 gtop20 gudev10 gupnp12 gupnp16 gupnpav10 gupnpdlna20 \
        gupnpdlnagst20 gupnpigd16 gvc10 gweather30 gweather40 gxps01 handy1 \
        ibus10 javascriptcore40 javascriptcore50 javascriptcore60 json10 \
        keybinder30 manette02 nm10 nma10 nma410 notify07 panel1 pango10 \
        pangocairo10 pangoft210 pangoxft10 peas10 peasgtk10 peas2 polkit10 \
        polkitagent10 poppler018 rest07 rest10 restextras07 restextras10 \
        rsvg20 secret1 shumate10 snapd2 soup24 soup30 soupgnome24 spelling1 \
        telepathyglib012 tracker20 tracker30 trackercontrol20 trackerminer20 \
        tsparql30 upowerglib10 vte00 vte291 vte391 webkit240 webkit241 \
        webkit250 webkit60 webkit2webextension40 webkit2webextension41 \
        webkit2webextension50 webkitwebprocessextension60 wp04 wp05 \
        xdp10 xdpgtk310 xdpgtk410 \
        cally3 clutter3 clutterx113 cogl3 coglpango3 meta3 \
        cally4 clutter4 clutterx114 cogl4 coglpango4 meta4 \
        cally5 clutter5 clutterx115 cogl5 coglpango5 meta5 \
        cally6 clutter6 clutterx116 cogl6 coglpango6 meta6 \
        cally7 clutter7 clutterx117 cogl7 coglpango7 meta7 \
        cally8 clutter8 clutterx118 cogl8 coglpango8 meta8 \
        cally9 clutter9 cogl9 coglpango9 meta9 shell9 st9 \
        cally10 clutter10 cogl10 coglpango10 meta10 shell10 st10 \
        cally11 clutter11 cogl11 coglpango11 meta11 shell11 st11 \
        cally12 clutter12 cogl12 coglpango12 meta12 shell12 st12 \
        cally13 clutter13 cogl13 coglpango13 meta13 mtk13 shell13 st13 \
        cally14 clutter14 cogl14 coglpango14 meta14 mtk14 shell14 st14 \
        clutter15 cogl15 coglpango15 meta15 mtk15 shell15 st15 \
        clutter16 cogl16 meta16 mtk16 shell16 st16 \
        clutter17 cogl17 meta17 mtk17 shell17 st17 \
        | tr ' ' '\n' | xargs -L1 -P$(nproc) bundle exec thor docs:generate --force

# Changes from Dockerfile-alpine:
# - Copy from the "build" stage instead of the current dir
# - Update `bundler config` usage
# - Remove `thor docs:download --all` (performed in "build" stage)
# - Remove `thor assets:compile` until we run in production mode (TODO)
# - Fix permissions for "rbuser"
FROM docker.io/library/ruby:3.2.2

ENV LANG=C.UTF-8
ENV ENABLE_SERVICE_WORKER=true

WORKDIR /devdocs

COPY --from=build /opt/devdocs /devdocs

RUN apt update && \
    apt-get install -y nodejs build-essential libstdc++6 gzip git zlib1g-dev libcurl4-openssl-dev && \
    gem install bundler && \
    bundle config set system 'true' && \
    bundle config set without 'test' && \
    bundle install && \
    apt remove build-essential git zlib1g-dev -y && \
    apt autoremove -y && \
    rm -rf /var/cache/apt/* /tmp ~/.gem /root/.bundle/cache \
    /usr/local/bundle/cache /usr/lib/node_modules

# Fix permissions for "rbuser"
RUN adduser --disabled-password --home /devdocs --shell /bin/bash --ingroup root --uid 1000 rbuser && \
    chmod -R 775 /devdocs && \
    chown -R rbuser:root /devdocs

EXPOSE 9292
CMD bundle exec rackup -o 0.0.0.0

