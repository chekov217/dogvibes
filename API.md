# Introduction #

There are two options if you want to control the Dogvibes server:
  * HMTL
  * WebSocket

Both methods yields the same results, however using WebSocket is strongly recommended since communication will be quicker and allows for push updates. The HTML method only supports pulling data from the server, i.e. no status updates will be pushed to the client. If the current server state needs to be known (which is mostly the case several times every second), status retrieval is done by an request. Instead when using WebSockets, status updates are pushed to all the connected clients when the state of the server is changed, e.g. someone adds a track to a playlist or pauses the music. Some actions, such as fetching cover art or listing a playlist, doesn't change the server state, thus will not push an update.


# Details #

The commands are structured as paths like this:

> `/dogvibes/search?query=Oasis`

Return values are structured as [JSON](http://www.json.org/) like this:

> `{"result": [{"album": "Oasis", "duration": 389227, "artist": "Soundscapes - Relaxing Music", "uri": "spotify:track:2OBKFZCMYmA2uMfDYNBIds", "title": "Oasis"}, {"album": "Stop The Clocks", "duration": 258000, "artist": "Oasis", "uri": "spotify:track:06UfBBDISthj1ZJAtX4xjj", "title": "Wonderwall"}], "error": 0}`

On the top level of the structure there is always the field _error_ which can be one of the following:
  * 0 (OK): The command was executed without any errors
  * 1 (NoSuchMethod): The specified method doesn't exist
  * 2 (ParameterMissing): A required parameter was omitted from the request
  * 3 (ValueError): Well-formatted request, but the result might not be what was intended. This can arise for example when adding a track to a playlist that doesn't exists

# Commands #

_This section is just a test. Needs some nice formatting before adding more commands_

## AMP commands ##

| **Command** | **Description** | **Parameter(s)** | **Parameter description** |
|:------------|:----------------|:-----------------|:--------------------------|
| /getStatus  | Returns the servers current status | -                | -                         |
| /nextTrack  | Plays the next track in the play queue | -                | -                         |
| /previousTrack | Plays the previouse track in the play queue | -                | -                         |
| /play       | Start playing music if there are tracks in the play queue | -                | -                         |
| /pause      | Pause music     | -                | -                         |
| /playTrack  | Plays a specifik track in the play queue | nbr              | Track number              |
| /seek       | Seeks to a position in the song currently playing | mseconds         | Position in milliseconds  |
| /setVolume  | Set the playback volume | level            | number between 0 - 1      |
| /queue      | Adds a track to the play queue | uri              | Track URI                 |
| /remove     | Remove track from play queue | nbr              | Track ID                  |
| /getAllTracksInQueue | Get all tracks in the play queue | -                | -                         |
| /getPlayedMilliSeconds | Get number of milliseconds played in the current song | -                | -                         |

## Dogvibes Commands ##
| **Command** | **Description** | **Parameter(s)** | **Parameter description** |
|:------------|:----------------|:-----------------|:--------------------------|
| /getAllPlaylists | Get all playlists | -                | -                         |
| /getAllTracksInPlaylist | Get all tracks in a playlist | playlist\_id     | Playlist ID               |
| /createPlaylist | Create a new playlist | name             | New playlist name         |
| /removePlaylist | Remove a playlist | id               | Playlist ID               |
| /addTrackToPlaylist | Adds a track to a playlist | playlist\_id     | Playlist ID               |
|             |                 | uri              | Track URI                 |
| /removeTrackFromPlaylist | Remove a track from a playlist | playlist\_id     | Playlist ID               |
|             |                 | nbr              | Track ID number in playlist |
| /search     | Search for a track | query            | Query string              |
| /getAlbumArt | Returns an album art image | uri              | Track URI                 |
|             |                 | size             | Album art size in pixels  |

## New API Draft ##

```
GET /dogvibes/playlists
GET /dogvibes/speakers
POST /dogvibes/search?query

POST /playlist/{id}/set?id
POST /playlist?name
GET /playlist/{id}
POST /amp/{id}/queue/set?id
POST /amp/{id}/queue/add?uri&index
POST /amp/{id}/queue/move?id&position
GET /amp/{id}/queue

POST /amp/{id}/control/next
POST /amp/{id}/control/previous
POST /amp/{id}/control/play
POST /amp/{id}/control/stop
POST /amp/{id}/control/pause
{GET,POST} /amp/{id}/control/position?msec

{GET,POST} /amp/{id}/volume
GET /amp/{id}/status
```

## Alternate new API draft ##

```
<username>.getPlaylists
<username>.getSpeakers
<username>.getAmps
<username>.search?query

amp.getQueue
amp.getController
amp.getEvents

playlist.new?name
playlist.activate?track
playlist.get
playlist.remove
playlist.removeTrack?track

queue.activate?track
queue.add?uri&index
queue.move?id&position

controller.next
controller.previous
controller.play
controller.stop
controller.pause
controller.getPosition
controller.setPosition?msec
controller.getVolume
controller.setVolume?value
```

### Objects ###

(USERNAME)
```
  id: <string>
```

Amp:
```
  id: <string>
```

Controller:
```
  id: <string>
```

Playlist:
```
  id: <string>
  name: <string>
```

Track:
```
  id: <string>
  name: <string>
  artist: <string>
  duration <int> (ms)
```

## The Simple API Draft ##

```
/search?q=<...>
/playlists
/playlists/{id}
/playlists/{id}?name=<...>
/enqueue?uri=<...>
/queue/{id}?pos=<...>  # moveTrack
/queue  # getAllTracksInQueue

/next
/previous
/play
/stop
/pause
/position  # getPosition
/position?ms=<...>

/volume  # getVolume
/volume?level=<...>  # setVolume
/status

/vote?uri=<...>
/unvote?uri=<...>

/users

```

Responses shall be configurable to be in production mode, i.e. slimmed down to as few bytes as possible.


### WebSocket events ###

Fields are:
  * event: type of event
  * data: new data to update the UI with
  * user: if a user was responsible for the change, this field is present

```
{ event: { name: 'playlist', data: { name: 'Favourites', tracks: [...] }}}
{ event: { name: 'playlists', data: [ 'Favourites', 'Jazz', '80s' ] }}
{ event: { name: 'time', data: 130000 }}
{ event: { name: 'volume', data: <track> }}
{ event: { name: 'trackUpdated', data: <track>, user: 'Musungen' }}
{ event: { name: 'login', data: 'Musungen' }}
...
```