using Gst;
using GConf;

[DBus (name = "com.Dogvibes.Dogvibes")]
public class Dogvibes : GLib.Object {
  /* list of all sources */
  public static GLib.List<Source> sources;

  /* list of all speakers */
  public static GLib.List<Speaker> speakers;

  construct {
    /* create lists of speakers and sources */
    sources = new GLib.List<Source> ();
    speakers = new GLib.List<Speaker> ();

    /* initiate all sources */
    sources.append (new SpotifySource ());
    sources.append (new FileSource ());
    sources.append (new RadioSource ());

    /* initiate all speakers */
    speakers.append (new DeviceSpeaker ("devicesource"));
    speakers.append (new FakeSpeaker ("fakesource"));
    speakers.append (new ApexSpeaker ("apexsource", "192.168.0.1"));
  }

  public static weak GLib.List<Source> get_sources () {
    return sources;
  }

  public static weak GLib.List<Speaker> get_speakers () {
    return speakers;
  }


  public string[] search (string query) {
    GLib.List<Track> tracks = new GLib.List<Track> ();

    foreach (Source source in sources) {
      foreach (Track track in source.search (query)) {
        //stdout.printf("%s - %s [%s]\n",
        //              track.artist, track.name, track.uri);
        /* Tried to do this with concat but I ended up in an eternal loop... */
        tracks.append(track);
      }
    }

    int i = 0;
    string[] uris = new string[tracks.length ()];
    foreach (Track track in tracks) {
      uris[i] = track.uri;
      i++;
    }

    return uris;
  }
}

[DBus (name = "com.Dogvibes.Amp")]
public class Amp : GLib.Object {
  /* the amp pipeline */
  private Pipeline pipeline = null;

  /* the amp pipline bus */
  private Bus bus = null;

  /* sources */
  private weak Source source;

  /* speakers */
  private weak Speaker speaker;

  /* elements */
  private Element src = null;
  private weak Element sink = null;
  private Element tee = null;
  private Element decodebin = null;
  private Element spotify = null;

  /* playqueue */
  GLib.List<Track> playqueue;
  int playqueue_position;

  /* ugly hack waiting for mr fuck up */
  private bool spotify_in_use;

  weak GLib.List<Source> sources;
  weak GLib.List<Speaker> speakers;

  construct {
    sources = Dogvibes.get_sources ();
    speakers = Dogvibes.get_speakers ();

    source = sources.nth_data (0);
    spotify = ((SingleSource) source).get_src ();

    /* initiate the pipeline */
    pipeline = (Pipeline) new Pipeline ("dogvibes");

    /* create the tee */
    tee = ElementFactory.make ("tee", "tee");
    pipeline.add (tee);

    /* get pipline bus */
    bus = pipeline.get_bus ();
    bus.add_signal_watch ();
    bus.message += pipeline_eos;

    /* initiate play queue */
    playqueue = new GLib.List<Track> ();
    playqueue_position = 0;
  }

  /*** Public D-Bus API ***/

  public void connect_speaker (int nbr) {
    if (!speaker_exists (nbr)) {
      stdout.printf ("Speaker %d does not exist\n", nbr);
      return;
    }

    speaker = speakers.nth_data (nbr);

    if (pipeline.get_by_name (speaker.name) == null) {
      State state;
      State pending;
      pipeline.get_state (out state, out pending, 0);
      pipeline.set_state (State.NULL);
      sink = speaker.get_speaker ();
      pipeline.add (sink);
      tee.link (sink);
      pipeline.set_state (state);
    } else {
      stdout.printf ("Speaker already connected\n");
    }
  }

  public void disconnect_speaker (int nbr) {
    if (!speaker_exists (nbr)) {
      stdout.printf ("Speaker %d does not exist\n", nbr);
      return;
    }

    speaker = speakers.nth_data (nbr);

    if (pipeline.get_by_name (speaker.name) != null) {
      State state;
      State pending;
      pipeline.get_state (out state, out pending, 0);
      pipeline.set_state (State.NULL);
      Element rm = pipeline.get_by_name (speaker.name);
      pipeline.remove (rm);
      tee.unlink (rm);
      pipeline.set_state (state);
    } else {
      stdout.printf ("Speaker not connected\n");
    }
  }

  public string[] get_all_tracks_in_queue () {
    var builder = new StringBuilder ();
    foreach (Track item in playqueue) {
      builder.append (item.uri);
      builder.append (" ");
    }
    stdout.printf ("Play queue length %u\n", playqueue.length ());
    return builder.str.split (" ");
  }

  public void get_connected_source () {
	  stdout.printf("NOT IMPLEMENTED \n");
  }

  public void get_connected_speakers () {
	  stdout.printf("NOT IMPLEMENTED \n");
  }

  public void get_available_speakers () {
	  stdout.printf("NOT IMPLEMENTED \n");
  }

  public void next_track () {
    change_track (playqueue_position + 1);
  }

  public void pause () {
    pipeline.set_state (State.PAUSED);
  }

  public void play () {
    Track track;
    track = (Track) playqueue.nth_data (playqueue_position);
    play_only_if_null (track);
  }

  public void play_track (int tracknbr) {
    change_track (tracknbr);
  }

  public void previous_track () {
    change_track (playqueue_position - 1);
  }

  public void queue (string uri) {
    Track track = new Track ();
    track.uri = uri;
    track.artist = "Mim";
    playqueue.append (track);
  }

  public void resume () {
    pipeline.set_state (State.PLAYING);
  }

  public void stop () {
    pipeline.set_state (State.NULL);
  }

  /*** State change functions ***/

  private void pad_added (Element dec, Pad pad) {
    stdout.printf ("Found suitable plugins lets add the speaker\n");
    /* FIXME the speaker and the tee should not be added to the pipeline here */
    pad.link (tee.get_pad("sink"));
    tee.set_state (State.PAUSED);
  }

  /*** Private helper functions ***/

  private void change_track (int tracknbr) {
    State pending;
    State state;
    Track track;

    if (tracknbr > (playqueue.length () - 1)) {
      stdout.printf ("Track number %d is to larges play queue is %u long\n", tracknbr, playqueue.length ());
      return;
    }

    if (tracknbr == playqueue_position) {
      /* Do nothing we are at the correct position */
      return;
    }

    if (tracknbr < 0) {
      tracknbr = 0;
    }

    playqueue_position = tracknbr;
    track = (Track) playqueue.nth_data (playqueue_position);

    pipeline.get_state (out state, out pending, 0);
    pipeline.set_state (State.NULL);
    play_only_if_null (track);
    pipeline.set_state (state);
  }


  private void pipeline_eos (Gst.Bus bus, Gst.Message mes) {
    if (mes.type == Gst.MessageType.EOS) {
      next_track ();
    }
  }

  private void play_only_if_null (Track track) {
    State state;
    State pending;
    pipeline.get_state (out state, out pending, 0);

    if (state != State.NULL) {
      pipeline.set_state (State.PLAYING);
      return;
    }

    /* waiting for mr fuckup to complete his task */
    if (src != null) {
      pipeline.remove (src);
      if (!spotify_in_use) {
        stdout.printf("Removed a decodebin\n");
        pipeline.remove (decodebin);
      }
    }

    /* waiting for mr fuckup to complete his task */
    if (track.uri.substring (0,7) == "spotify") {
      src = spotify;
      ((SingleSource) source).set_track (track);
      pipeline.add (spotify);
      spotify.link (tee);
      spotify_in_use = true;
    } else {
      src = Element.make_from_uri (URIType.SRC, track.uri , "source");
      decodebin = ElementFactory.make ("decodebin2" , "decodebin2");
      decodebin.pad_added += pad_added;
      pipeline.add_many (src, decodebin);
      src.link (decodebin);
      spotify_in_use = false;
    }
    pipeline.set_state (State.PLAYING);
  }

  private bool speaker_exists (int nbr) {
    if (nbr > (speakers.length () - 1)) {
      stdout.printf ("Speaker %d does not exist\n", nbr);
      return false;
    } else {
      return true;
    }
  }
}

public void main (string[] args) {
  var loop = new MainLoop (null, false);
  Gst.init (ref args);

  try {
    /* register DBus session */
    var conn = DBus.Bus.get (DBus.BusType. SYSTEM);
    dynamic DBus.Object bus = conn.get_object ("org.freedesktop.DBus",
                                               "/org/freedesktop/DBus",
                                               "org.freedesktop.DBus");
    uint request_name_result = bus.request_name ("com.Dogvibes", (uint) 0);

    if (request_name_result == DBus.RequestNameReply.PRIMARY_OWNER) {
      /* register dogvibes server */
      var dogvibes = new Dogvibes ();
      conn.register_object ("/com/dogvibes/dogvibes", dogvibes);

      /* register amplifier */
      var amp = new Amp ();
      conn.register_object ("/com/dogvibes/amp/0", amp);
      loop.run ();
    }
  } catch (GLib.Error e) {
    stderr.printf ("Oops: %s\n", e.message);
  }
}
