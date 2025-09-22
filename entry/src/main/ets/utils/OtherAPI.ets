import {Song} from "./Interface"
import {ND_Song} from "./ND_Interface"

export function song2ND_Song(song: Song): ND_Song{
  return {
    id: song.id,
    title: song.title,
    album: song.album,
    albumId: song.albumId,
    artist: song.artist,
    artistId: song.artistId,
    trackNumber: song.track,
    year: song.year,
    genre: song.genre,
    size: song.size,
    duration: song.duration,
    bitRate: song.bitRate,
    suffix: song.suffix,
    path: song.path,
    sampleRate: song.samplingRate,
    channels: song.channelCount,
    createdAt: song.created,
    rgTrackGain: song.replayGain?.trackGain,
    rgTrackPeak: song.replayGain?.trackPeak,
    rgAlbumPeak: song.replayGain?.albumPeak,
  }
}
