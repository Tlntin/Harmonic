// refer document: https://music.aqzscn.cn/docs/notes/services/navidrome
import axios, { AxiosRequestHeaders, AxiosResponse } from '@ohos/axios'
import {ND_LoginResult, ND_Artist, ND_Song, ND_getSongsResult, ND_Playlist, ND_PlayListSong} from "./ND_Interface"


export async function ND_login(baseURL: string, username: string, passport: string): Promise<ND_LoginResult | null> {
  try {
    const response: AxiosResponse =
      await axios.post<string, AxiosResponse<string>>(baseURL + '/auth/login', {
        "username": username,
        "password": passport
      })
    //console.log(`/Navidrome login/ data: ${JSON.stringify(response.data)}`)
    if (response.data?.error) {
      console.error(`/==navdromeLogin/ error: ${JSON.stringify(response.data?.error)}`);
      return null;
    } else {
      let result: ND_LoginResult = response.data;
      return result;
    }
  } catch (error) {
    console.error(`/==navdromeLogin/ error: ${JSON.stringify(error)}`);
    return null
  }
}

export async function ND_keepAlive(baseURL: string, token: string, id: string) {
  try {
    const response: AxiosResponse =
      await axios.get<string, AxiosResponse<string>>(baseURL + "/api/keepalive/keepalive", {
        headers:{
          "x-nd-authorization": `Bearer ${token}`,
          "x-nd-client-unique-id": id
        }
      })
    if (response.data?.response === "ok") {
      return true;
    } else {
      return false;
    }
  } catch (error) {
    console.error(`/==navidromeKeepAlive/ error: ${JSON.stringify(error)}`)
    return false;
  }
}

export async function ND_getArtist(
  baseURL: string,
  token: string,
  id: string,
  _start: number,
  _end: number,
  _order: "ASC" | "DESC" = "ASC",
  _sort: "random" | "play_count" | "play_date" | "name" | "rating" | string = "name",
): Promise<Array<ND_Artist> | null>{
  try {
    let url = baseURL + "/api/artist?" + `_start=${_start}&_end=${_end}&_order=${_order}&_sort=${_sort}`
    console.info(`/navdirome_getArtist/ url: ${url}`)
    const response: AxiosResponse =
      await axios.get<string, AxiosResponse<string>>(url, {
        headers:{
          "x-nd-authorization": `Bearer ${token}`,
          "x-nd-client-unique-id": id
        }
      })
    // console.info(`/navdirome_getArtist/ data: ${JSON.stringify(response.data)}`)
    if (response?.data?.error) {
      console.error(`/navdirome_getArtist/ error:${JSON.stringify(response?.data?.error)}`)
      return null;
    } else {
      let result: Array<ND_Artist> = response.data;
      return result;
    }
  } catch (error){
    console.error(`/navdirome_getArtist/ error:${JSON.stringify(error)}`);
    return null
  }
}

export async function ND_getSongs(
  baseURL: string,
  token: string,
  id: string,
  _start: number,
  _end: number,
  _order: "DESC" | "ASC" = "ASC",
  _sort: "random" | "createdAt" | "max_year" | "play_count" | "play_date" | "title" | "album" | "rating" | string = "title",
  album_id?: string,
  starred?: boolean,
): Promise<ND_getSongsResult | null>{
  let url = baseURL + "/api/song?" + `_start=${_start}&_end=${_end}&_order=${_order}&_sort=${_sort}`
  if (album_id) {
    url += `&album_id=${album_id}`
  }
  if (starred) {
    url += `&starred=${starred}`
  }
  // console.log(`==/navdirome_getSongs/ url: ${url} id: ${id} token: ${token}`)
  try {
    const response: AxiosResponse =
      await axios.get<string, AxiosResponse<string>>(url, {
        headers:{
          "x-nd-authorization": `Bearer ${token}`,
          "x-nd-client-unique-id": id
        }
      })
    console.log(`==/navdirome_getSongs/ reponse head: ${JSON.stringify(response?.headers)}`)
    if (response?.data?.error) {
      console.error(`==/navdirome_getSongs/ error:${JSON.stringify(response?.data?.error)}`)
      return null;
    } else {
      const headers = response.headers as AxiosRequestHeaders;
      let songCountStr = headers?.get("x-total-count")
      let songCount = 0;
      if (songCountStr) {
        songCount = parseInt(String(songCountStr), 10)
      }
      console.log(`== song total conut is ${songCount}`);
      let songs: Array<ND_Song> = response.data;
      // console.log(`==/navdirome_getSongs/ songs: ${JSON.stringify(songs)}`)
      return {songs, songCount};
    }
  } catch (error){
    console.error(`/navdirome_getSongs/ error:${JSON.stringify(error)}`)
    return null;
  }
}

export async function ND_getSong(
  baseURL: string,
  token: string,
  id: string,
  song_id: number
) {
  try {
    const response: AxiosResponse =
      await axios.get<string, AxiosResponse<string>>(baseURL + `/api/song/${song_id}`, {
        headers:{
          "x-nd-authorization": `Bearer ${token}`,
          "x-nd-client-unique-id": id
        }
      })
    if (response?.data?.error) {
      console.error(`/navdirome_getSong/ error:${JSON.stringify(response?.data?.error)}`)
      return null;
    } else {
      let result: ND_Song = response.data;
      return result;
    }
  } catch (error){
    console.error(`/navdirome_getSongs/ error:${JSON.stringify(error)}`)
    return null;
  }
}

export async function ND_getPlayList(
  baseURL: string,
  token: string,
  id: string,
  _start: number = 0,
  _end: number = 0,
  _order: "DESC" | "ASC" = "ASC",
  _sort: "id" = "id"
) {
  let url = baseURL + `/api/playlist?_start=${_start}&_end=${_end}&_order=${_order}&_sort=${_sort}`;
  try {
    const response: AxiosResponse =
      await axios.get<string, AxiosResponse<string>>(url, {
        headers:{
          "x-nd-authorization": `Bearer ${token}`,
          "x-nd-client-unique-id": id
        }
      })
    if (response?.data?.error) {
      console.error(`/navdirome_getPlayList/ error:${JSON.stringify(response?.data?.error)}`)
      return null;
    } else {
      let result: Array<ND_Playlist> = response.data;
      return result;
    }
  } catch (error){
    console.error(`/navdirome_getPlayList/ error:${JSON.stringify(error)}`)
    return null;
  }
}


export async function ND_getPlayListTracks(
  baseURL: string,
  token: string,
  id: string,
  playListID: string,
  _start: number = 0,
  _end: number = 0,
  _order: "DESC" | "ASC" = "ASC",
  _sort: "id" = "id"
):Promise<ND_PlayListSong[] | null>{
  let url = baseURL + `/api/playlist/${playListID}/tracks?_start=${_start}&_end=${_end}&_order=${_order}&_sort=${_sort}`;
  // console.info(`/ND_getPlayListTracks url: ${url}, token: ${token}, id: ${id}/`)
  try {
    const response: AxiosResponse =
      await axios.get<string, AxiosResponse<string>>(url, {
        headers:{
          "x-nd-authorization": `Bearer ${token}`,
          "x-nd-client-unique-id": id
        }
      })
    if (response?.data?.error) {
      console.error(`==/ND_getPlayListTracks/ error:${JSON.stringify(response?.data?.error)}`)
      return null;
    } else {
      const headers = response.headers as AxiosRequestHeaders;
      let songCountStr = headers?.get("x-total-count")
      let songCount = 0;
      if (songCountStr) {
        songCount = parseInt(String(songCountStr), 10)
      }
      // console.log(`== /ND_getPlayListTracks/ total conut is ${songCount}`);
      let songs: Array<ND_PlayListSong> = response.data;
      // console.log(`==/ND_getPlayListTracks/ songs: ${JSON.stringify(songs)}`)
      return songs;
    }
  } catch (error){
    console.error(`/ND_getPlayListTracks/ error:${JSON.stringify(error)}`)
    return null;
  }
}