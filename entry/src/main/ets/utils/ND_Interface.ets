import {StructuredLyric, Line} from "./Interface"

export interface ND_LoginResult {
  id: string,
  isAdmin: boolean,
  name: string,
  subsonicSalt: string,
  subsonicToken: string,
  token: string,
  username: string,
}

export interface ND_ArtistPerformer {
  songCount: number,
  albumCount: number,
  size: number
}

export interface  ND_ArtistStats {
  performer?: ND_ArtistPerformer,
  composer?: ND_ArtistPerformer,
  lyricist?: ND_ArtistPerformer,
  albumartist?: ND_ArtistPerformer,
  artist?: ND_ArtistPerformer,
  maincredit?: ND_ArtistPerformer

}

export interface ND_Artist {
  id: string,
  name: string,
  orderArtistName?: string,
  stats: ND_Artist,
  size: number,
  albumCount: number,
  songCount: number,
  largeImageUrl?: string,
  externalUrl?: string,
  externalInfoUpdatedAt: string,
  missing: boolean,
  createdAt: string,
  updatedAt: string,
}

export interface ND_Participant {
  id: string,
  name: string,
  missing: boolean,
}

export interface ND_Song_Participants {
  albumartist: Array<ND_Participant>,
  artist: Array<ND_Participant>
}

export interface ND_Song {
  bookmarkPosition: number,
  id: string,
  libraryId: 1,
  libraryPath: string,
  libraryName: string,
  folderId: string,
  path: string,
  title: string,
  album: string,
  artistId: string,
  artist: string,
  albumArtistId: string,
  albumArtist: string,
  albumId: string,
  hasCoverArt: boolean,
  trackNumber: number,
  discNumber: number,
  starred?: boolean;
  year: number,
  date: string,
  originalYear: number,
  releaseYear: string,
  size: number,
  suffix: string,
  duration: number,
  bitRate: number,
  sampleRate: number,
  bitDepth: number,
  channels: number,
  genre: string,
  orderTitle: string,
  orderAlbumName: string,
  orderArtistName: string,
  orderAlbumArtistName: string,
  compilation: boolean,
  lyrics: string,
  explicitStatus: string,
  rgAlbumGain: null | number,
  rgAlbumPeak: null | number,
  rgTrackGain: null | number,
  rgTrackPeak: null | number,
  participants: ND_Song_Participants,
  missing: boolean,
  birthTime: string,
  createdAt: string,
  updatedAt: string,
}

export interface ND_getSongsResult {
  songs: ND_Song[],
  songCount: number
}

export interface SaveState {
  nowPlayingSong: ND_Song | undefined;
  nowPlayingLyrics: StructuredLyric | undefined;
  nowPlayingLyricsByGroup: Line[][];
  nowPlayingList: ND_Song[];
  nowPlayingListOriginal: ND_Song[];
  nowPlayingIndex: number;
  lyricsIndex: number;
  startPlaying: boolean;
  isPlaying: boolean;
  nowPlayedTime: number;
}