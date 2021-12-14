# We bump this each release to fetch the latest stable GIRs
FROM fedora:34 AS fetch

RUN dnf install -y \
        NetworkManager-libnm-devel cairo-devel cheese-libs-devel \
        clutter-{gst3,gtk}-devel evince-devel folks-devel geoclue2-devel \
        geocode-glib-devel glib2-devel gnome-bluetooth-libs-devel \
        gnome-online-accounts-devel gnome-shell gobject-introspection-devel \
        gom-devel graphene-devel grilo-devel gsettings-desktop-schemas-devel \
        gsound-devel gspell-devel \
        gstreamer1-{,plugins-base-,plugins-bad-free-}devel gtk{2,3,4}-devel \
        gtksourceview{3,4}-devel gupnp-devel gupnp-dlna-devel harfbuzz-devel \
        ibus-devel keybinder3-devel libappindicator-gtk3-devel \
        libappstream-glib-devel libchamplain-devel libgcab1-devel \
        libgdata-devel libgda-devel libgudev-devel libgweather-devel \
        libgxps-devel libhandy1-devel libnotify-devel libpeas-devel \
        librsvg2-devel libsecret-devel libzapojit-devel mutter pango-devel \
        polkit-devel poppler-glib-devel rest-devel telepathy-glib-devel \
        tracker-devel udisks-devel upower-devel vte{,291}-devel && \
    dnf clean all && \
    rm -rf /var/cache/yum


# We build in fedora:33 for the ruby dependency
FROM fedora:33 AS build

# These are GIRs from the fetch step
COPY --from=fetch /usr/share/gir-1.0 /usr/share/gir-1.0
COPY --from=fetch /usr/share/gnome-shell /usr/share/gnome-shell
COPY --from=fetch /usr/lib64/mutter-8 /usr/lib64/mutter-8

# These are extra GIRs we can't install with dnf
COPY lib/docs/scrapers/gnome/girs/GtkosxApplication-1.0.gir /usr/share/gir-1.0/
COPY lib/docs/scrapers/gnome/girs/Tracker-2.0.gir /usr/share/gir-1.0/
COPY lib/docs/scrapers/gnome/girs/TrackerControl-2.0.gir /usr/share/gir-1.0/
COPY lib/docs/scrapers/gnome/girs/TrackerMiner-2.0.gir /usr/share/gir-1.0/
COPY lib/docs/scrapers/gnome/girs/Wp-0.3.gir /usr/share/gir-1.0/

COPY lib/docs/scrapers/gnome/girs/mutter-3 /usr/lib64/mutter-3
COPY lib/docs/scrapers/gnome/girs/mutter-4 /usr/lib64/mutter-4
COPY lib/docs/scrapers/gnome/girs/mutter-5 /usr/lib64/mutter-5
COPY lib/docs/scrapers/gnome/girs/mutter-6 /usr/lib64/mutter-6
COPY lib/docs/scrapers/gnome/girs/mutter-7 /usr/lib64/mutter-7

# Install devdocs dependencies
RUN dnf install -y glibc-langpack-en
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN dnf install -y 'dnf-command(builddep)' @development-tools bzip2 gcc-c++ && \
    dnf builddep -y ruby && \
    dnf install -y ruby rubygem-bundler ruby-devel python3-markdown \
                   gobject-introspection-devel && \
    dnf clean all && \
    rm -rf /var/cache/yum

# Install the devdocs application
COPY . /opt/devdocs/
WORKDIR /opt/devdocs

RUN bundle config set --local deployment 'true'
RUN bundle install

# Generate scrapers
RUN bundle exec thor gir:generate_all /usr/share/gir-1.0
RUN bundle exec thor gir:generate_all /usr/lib64/mutter-3
RUN bundle exec thor gir:generate_all /usr/lib64/mutter-4
RUN bundle exec thor gir:generate_all /usr/lib64/mutter-5
RUN bundle exec thor gir:generate_all /usr/lib64/mutter-6
RUN bundle exec thor gir:generate_all /usr/lib64/mutter-7
RUN bundle exec thor gir:generate_all /usr/lib64/mutter-8

# Some of the gnome-shell GIRs need extra include paths
RUN bundle exec thor gir:generate /usr/share/gnome-shell/Gvc-1.0.gir
RUN bundle exec thor gir:generate /usr/share/gnome-shell/Shell-0.1.gir --include /usr/lib64/mutter-8
RUN bundle exec thor gir:generate /usr/share/gnome-shell/St-1.0.gir --include /usr/lib64/mutter-8

# Build docsets
#
# Intentionally omitted:
# dbus10, dbusglib10, fontconfig20, freetype220, gdkpixdata20, gl10, libxml220,
#   win3210, xfixes40, xft20, xlib20, xrandr13
RUN for docset in appindicator301 appstreamglib10 atk10 atspi20 cairo10 \
        cally10 cally8 camel12 champlain012 cheese30 clutter10 clutter8 \
        cluttergdk10 cluttergst30 clutterx1110 clutterx118 cogl10 cogl20 cogl8 \
        coglpango10 coglpango20 coglpango8 dbusmenu04 ebook12 ebookcontacts12 \
        edataserver12 edataserverui12 evincedocument30 evinceview30 folks06 \
        folksdummy06 folkseds06 folkstelepathy06 gcab10 gck1 gcr3 gcrui3 \
        gda50 gdata00 gdesktopenums30 gdk20 gdk30 gdk40 gdkpixbuf20 gdkx1120 \
        gdkx1130 gdkx1140 gee08 geoclue20 geocodeglib10 gio20 girepository20 \
        glib20 gmodule20 gnomebluetooth10 goa10 gobject20 gom10 graphene10 \
        grl03 grlnet03 grlpls03 gsk40 gsound10 gspell1 gssdp10 gst10 \
        gstallocators10 gstapp10 gstaudio10 gstbadaudio10 gstbase10 gstcheck10 \
        gstcodecs10 gstcontroller10 gstgl10 gstinsertbin10 gstmpegts10 \
        gstnet10 gstpbutils10 gstplayer10 gstrtp10 gstrtsp10 gstsdp10 gsttag10 \
        gstvideo10 gstvulkan10 gstwebrtc10 gtk20 gtk30 gtk40 gtkchamplain012 \
        gtkclutter10 gtkosxapplication10 gtksource30 gtksource40 gudev10 \
        gupnp10 gupnpdlna20 gupnpdlnagst20 gvc10 gweather30 gxps01 handy1 \
        ibus10 javascriptcore40 json10 keybinder30 meta8 nm10 notify07 pango10 \
        pangocairo10 pangoft210 pangoxft10 peas10 peasgtk10 polkit10 \
        polkitagent10 poppler018 rest07 restextras07 rsvg20 secret1 shell01 \
        soup24 soupgnome24 st10 telepathyglib012 tracker20 tracker30 \
        trackercontrol20 trackerminer20 upowerglib10 vte00 vte291 webkit240 \
        webkit2webextension40 wp03 zpj00 \
        cally3 clutter3 clutterx113 cogl3 coglpango3 meta3 \
        cally4 clutter4 clutterx114 cogl4 coglpango4 meta4 \
        cally5 clutter5 clutterx115 cogl5 coglpango5 meta5 \
        cally6 clutter6 clutterx116 cogl6 coglpango6 meta6 \
        cally7 clutter7 clutterx117 cogl7 coglpango7 meta7; \
      do echo $docset; bundle exec thor docs:generate $docset --force; done


# We deploy in ruby:2.7.3-alpine for size
#
# Changes from Dockerfile-alpine:
# - Ruby 2.6.0 -> 2.7.3
# - Copy from the build-stage image instead of the current dir
# - Update bundler CLI usage
# - The css and javascript docsets don't resolve and have been removed
# - User permission fixes
FROM docker.io/library/ruby:2.7.3-alpine

ENV LANG=C.UTF-8
ENV ENABLE_SERVICE_WORKER=true

WORKDIR /devdocs

COPY --from=build /opt/devdocs /devdocs

RUN apk --update add nodejs build-base libstdc++ gzip git zlib-dev && \
    gem install bundler && \
    bundle config set system 'true' && \
    bundle config set without 'test' && \
    bundle install && \
    thor assets:compile && \
    apk del gzip build-base git zlib-dev && \
    rm -rf /var/cache/apk/* /tmp ~/.gem /root/.bundle/cache \
    /usr/local/bundle/cache /usr/lib/node_modules

RUN adduser -D -h /devdocs -s /bin/bash -G root -u 1000 rbuser
RUN chmod -R 775 /devdocs
RUN chown -R rbuser:root /devdocs
EXPOSE 9292
CMD bundle exec rackup -o 0.0.0.0

