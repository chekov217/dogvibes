

# Introduction #

This product uses SPOTIFY(R) CORE but is not endorsed, certified or otherwise approved in any way by Spotify. Spotify is the registered trade mark of the Spotify Group

# Linux Installation #

This project has just started so beware of excessive tweaking. Since its start it has gotten much easier to install dogvibes.

These instructions apply for Ubuntu 9.04 and might have to be altered for other distributions. Don't forget to run in a context with appropriate permissions, e.g. sudo ;)

## Dependencies ##

Start with installing all dependencies and tools for building dogvibes remember to run as privileged user (i.e. sudo):

```
apt-get install subversion libglib2.0-dev autoconf \
libtool libxml2-dev liboil-dev libasound-dev python-gst0.10\
libexpat1-dev libsqlite3-dev python-tagpy python-sqlite python-cjson python-imaging \
python-twisted libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev \
gstreamer0.10-plugins-base gstreamer0.10-plugins-good gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly
```

For gentoo, use emerge instead. Get python-cjson from here and add it to a custom overlay and emerge: http://www.ebuildfind.net/application/python-cjson/

## Libspotify ##
  * Download and unpack latest version at http://developer.spotify.com/en/libspotify/overview/
  * Currently its 0.0.4
```
wget http://developer.spotify.com/download/libspotify/libspotify-0.0.4-linux6-i686.tar.gz
# use x86_64 if needed, see the site
tar -xvf libspotify-0.0.4-linux6-i686.tar.gz
cd libspotify-0.0.4-linux6-i686
make install prefix=/usr #run as privileged user (i.e. sudo)
ldconfig -v #run as privileged user (i.e. sudo)
```

## Fetch and install dogvibes code ##
  * Fetch the dogvibes code from googlecode.
  * Install gstreamer source.
```
svn checkout http://dogvibes.googlecode.com/svn/trunk/ dogvibes
cd dogvibes/gst-spot-src
autogen.sh --prefix=/usr
make install #run as privileged user (i.e. sudo)
```
  * Jump to section Start Dogvibes.

# Mac OS X Installation #

## Dependencies ##
This is quite heavy at the moment (500+Mb)
  * Install the latest Xcode from Apple
  * Install [MacPorts](http://www.macports.org/install.php) “dmg” disk images
  * sudo port install py26-gst-python py26-cjson py26-pil gst-plugins-good libvorbis py26-twisted
  * Test your installation with gst-launch:
> > `gst-launch audiotestsrc ! audioconvert ! osxaudiosink`
<a href='Hidden comment: 
== libopenspotify ==
* git clone git://github.com/noahwilliamsson/openspotify.git
* Change the following in openspotify/libopenspotify/Makefile:
```
-CFLAGS = -Wall -ggdb -I../include -fPIC -O2
-LDFLAGS = -lcrypto -lresolv -lz -lvorbisfile
+CFLAGS = -Wall -ggdb -I../include -I/opt/local/include -fPIC -O2
+LDFLAGS = -lcrypto -lresolv -lz -lvorbisfile -L/opt/local/lib
```
* sudo make prefix=/opt/local install
'></a>

## Libspotify ##
  * Download and unpack latest version at http://developer.spotify.com/en/libspotify/overview/
  * Currently its 0.0.4
```
wget http://developer.spotify.com/download/libspotify/libspotify-0.0.4-darwin.zip
unzip libspotify-0.0.4-darwin.zip
cd libspotify-0.0.4-darwin
cp libspotify.framework/Versions/0.0.4/libspotify /opt/local/lib/libspotify.so
mkdir -p /opt/local/include/libspotify
cp libspotify.framework/Headers/api.h /opt/local/include/libspotify/api.h
Copy libspotify.framework to /Library/Frameworks. Use Finder!
```

This version of libSystem.B.dynlib seems to miss symbol _bzero
```
nm /usr/lib/libSystem.B.dylib | grep bzero
00058bd0 T _bzero
otool -L /usr/lib/libSystem.B.dylib
/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 111.1.5)
```_

## gst-spot-src ##
  * Make sure your path has this order, PATH=/opt/local/bin:/usr/bin:/bin with opt/local first, so we use the newest tools for the job
```
cd ./gst-spot-src 
autogen.sh --prefix=/opt/local
sudo make install
```
# Start Dogvibes #
  * Change to directory where the dogvibes suite is located.
  * To set Spotify username/password you can user either environment variables (SPOTIFY\_USER=user SPOTIFY\_PASSWORD=pass) or edit the file 'dogvibes/src/config.py'
  * Start server.
```
cd <dogvibes root>/dogvibes/src
python2.6 ./dog.py
```
  * Steer your browser to `http://www.dogvibes.com/<username> `
  * or just start a local webserver and open `clients/dogbone/index.html`, use `python -m SimpleHTTPServer` in the `dogbone` directory to start a simple server.
  * Enjoy :)

# Clients #
  * Mobile browser: http://m.dogvibes.com
  * Desktop browser: http://www.dogvibes.com