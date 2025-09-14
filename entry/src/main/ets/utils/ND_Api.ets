// refer document: https://music.aqzscn.cn/docs/notes/services/navidrome
import axios, { AxiosResponse } from '@ohos/axios'
import {ND_LoginResult, ND_Artist, ND_Song} from "./ND_Interface"


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
  _sort: "random" | "createdAt" | "max_year" | "play_count" | "play_date" | "title" | "album" | "rating" | string = "title"
) {
  try {
    const response: AxiosResponse =
      await axios.get<string, AxiosResponse<string>>(baseURL + "/api/song?" + `_start=${_start}&_end=${_end}&_order=${_order}&_sort=${_sort}}`, {
        headers:{
          "x-nd-authorization": `Bearer ${token}`,
          "x-nd-client-unique-id": id
        }
      })
    if (response?.data?.error) {
      console.error(`/navdirome_getSongs/ error:${JSON.stringify(response?.data?.error)}`)
      return null;
    } else {
      let results: Array<ND_Song> = response.data;
      return results;
    }
  } catch (error){
    console.error(`/navdirome_getSongs/ error:${JSON.stringify(error)}`)
    return null;
  }
}