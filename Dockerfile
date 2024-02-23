# We bump this each release to fetch the latest stable GIRs
FROM registry.fedoraproject.org/fedora:40 AS build

ENV LANG=C.UTF-8

RUN dnf install -y 'dnf-command(builddep)' @development-tools bzip2 gcc-c++ \
        NetworkManager-libnm-devel cairo-devel colord{,-gtk,-gtk4}-devel \
        evince-devel flatpak-devel folks-devel gcr{,3}-devel \
        geoclue2-devel geocode-glib2-devel glib2-devel gnome-autoar-devel \
        gnome-bluetooth-libs-devel gnome-desktop{3,4}-devel \
        gnome-online-accounts-devel gnome-shell gobject-introspection-devel \
        gom-devel granite-devel graphene-devel grilo-devel \
        gsettings-desktop-schemas-devel gsound-devel gspell-devel \
        gstreamer1-{,plugins-base-,plugins-bad-free-}devel gtk{2,3,4}-devel \
        gtksourceview{3,4,5}-devel libgtop2-devel gupnp{,-dlna,-av}-devel \
        harfbuzz-devel ibus-devel javascriptcoregtk6.0-devel keybinder3-devel \
        libappindicator-gtk3-devel libadwaita-devel libappstream-glib-devel \
        libgcab1-devel libgdata-devel libgda-devel libgda5-devel \
        libgudev-devel libgweather4-devel libgxps-devel libhandy1-devel \
        libmanette-devel libnma{,-gtk4}-devel libnotify-devel libpanel-devel \
        libpeas-devel libportal{,-gtk3,-gtk4}-devel librsvg2-devel \
        libsecret-devel libshumate-devel libsoup{,3}-devel mutter pango-devel \
        polkit-devel poppler-glib-devel rest{,0.7}-devel telepathy-glib-devel \
        tracker-devel udisks-devel upower-devel vte{,291,291-gtk4}-devel \
        webkit2gtk{4.0,4.1}-devel webkitgtk6.0 wireplumber-devel && \
    dnf builddep -y ruby && \
    dnf install -y --allowerasing openssl1.1-devel python3-pip && \
    pip3 install -I Markdown==3.3.7 && \
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
RUN bundle exec thor docs:generate gjs_scraper --force

# Generate scrapers
RUN bundle exec thor gir:generate_all /usr/share/gir-1.0 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-3 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-4 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-5 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-6 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-7 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-8 && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-9 --include /usr/share/gnome-shell && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-10 --include /usr/share/gnome-shell && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-11 --include /usr/share/gnome-shell && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-12 --include /usr/share/gnome-shell && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-13 --include /usr/share/gnome-shell && \
    bundle exec thor gir:generate_all /usr/lib64/mutter-14

# The GNOME Shell GIRs need to include the current mutter GIRs
RUN bundle exec thor gir:generate /usr/share/gnome-shell/Gvc-1.0.gir
RUN bundle exec thor gir:generate /usr/share/gnome-shell/Shell-14.gir --include /usr/lib64/mutter-14
RUN bundle exec thor gir:generate /usr/share/gnome-shell/St-14.gir --include /usr/lib64/mutter-14

# Build docsets
#
# Intentionally omitted:
# dbus10, dbusglib10, fontconfig20, freetype220, gdkpixdata20, gl10, gmodule20,
#   libxml220, win3210, xfixes40, xft20, xlib20, xrandr13
RUN echo adw1 appindicator301 appstreamglib10 atk10 atspi20 cairo10 \
        camel12 colord10 colorhug10 colordgtk10 dbusmenu04 ebook12 \
        ebookcontacts12 ecal20 edatabook12 edatacal20 edataserver12 \
        edataserverui12 edataserverui410 evincedocument30 evinceview30 \
        flatpak10 folks07 folksdummy07 folkseds07 folkstelepathy07 gcab10 gck1 \
        gck2 gcr3 gcr4 gcrui3 gda50 gda60 gdata00 gdesktopenums30 gdk20 gdk30 \
        gdk40 gdkpixbuf20 gdkx1120 gdkx1130 gdkx1140 gee08 geoclue20 \
        geocodeglib10 geocodeglib20 gio20 girepository20 glib20 gnomeautoar01 \
        gnomeautoargtk01 gnomebluetooth10 gnomebluetooth30 gnomebg40 \
        gnomedesktop30  gnomedesktop40 gnomerr40 goa10 gobject20 gom10 \
        granite10 graphene10 grl03 grlnet03 grlpls03 gsk40 gsound10 gspell1 \
        gssdp12 gssdp16 gst10 gstallocators10 gstapp10 gstaudio10 \
        gstbadaudio10 gstbase10 gstcheck10 gstcodecs10 gstcontroller10 gstgl10 \
        gstinsertbin10 gstmpegts10 gstnet10 gstpbutils10 gstplayer10 gstrtp10 \
        gstrtsp10 gstsdp10 gsttag10 gstvideo10 gstvulkan10 gstwebrtc10 gtk20 \
        gtk30 gtk40 gtkosxapplication10 gtksource30 gtksource4 gtksource5 \
        gtop20 gudev10 gupnp12 gupnp16 gupnpav10 gupnpdlna20 gupnpdlnagst20 \
        gupnpigd16 gvc10 gweather30 gweather40 gxps01 handy1 ibus10 \
        javascriptcore40 javascriptcore50 javascriptcore60 json10 keybinder30 \
        manette02 nm10 nma10 nma410 notify07 panel1 pango10 pangocairo10 \
        pangoft210 pangoxft10 peas10 peasgtk10 polkit10 polkitagent10 \
        poppler018 rest07 rest10 restextras07 restextras10 rsvg20 secret1 \
        shumate10 snapd2 soup24 soup30 soupgnome24 telepathyglib012 tracker20 \
        tracker30 trackercontrol20 trackerminer20 upowerglib10 vte00 vte291 \
        vte391 webkit240 webkit241 webkit250 webkit60 webkit2webextension40 \
        webkit2webextension41 webkit2webextension50 \
        webkitwebprocessextension60 wp04 xdp10 xdpgtk310 xdpgtk410 \
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
        | tr ' ' '\n' | xargs -L1 -P$(nproc) bundle exec thor docs:generate --force

# We deploy in ruby:3.2.2-alpine for size
#
# Changes from Dockerfile-alpine:
# - Copy from the "build" stage instead of the current dir
# - Update `bundler config` usage
# - Remove `thor docs:download --all` (performed in "build" stage)
# - Remove `thor assets:compile` until we run in production mode (TODO)
# - Fix permissions for "rbuser"
FROM docker.io/library/ruby:3.2.2-alpine

ENV LANG=C.UTF-8
ENV ENABLE_SERVICE_WORKER=true

WORKDIR /devdocs

COPY --from=build /opt/devdocs /devdocs

RUN apk --update add nodejs build-base libstdc++ gzip git zlib-dev libcurl && \
    gem install bundler && \
    bundle config set system 'true' && \
    bundle config set without 'test' && \
    bundle install && \
    apk del gzip build-base git zlib-dev && \
    rm -rf /var/cache/apk/* /tmp ~/.gem /root/.bundle/cache \
    /usr/local/bundle/cache /usr/lib/node_modules

# Fix permissions for "rbuser"
RUN adduser -D -h /devdocs -s /bin/bash -G root -u 1000 rbuser && \
    chmod -R 775 /devdocs && \
    chown -R rbuser:root /devdocs

EXPOSE 9292
CMD bundle exec rackup -o 0.0.0.0

