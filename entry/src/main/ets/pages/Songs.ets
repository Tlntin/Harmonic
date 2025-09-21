import { curves } from '@kit.ArkUI';
import { media } from '@kit.MediaKit';
import { avSession as AVSessionManager } from '@kit.AVSessionKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { PromptAction } from '@kit.ArkUI';
// import { ImageKnifeComponent } from '@ohos/imageknife'
// old api
// import { getLyrics} from '../utils/Api';
import { Line, MusicFolder, StructuredLyric} from '../utils/Interface';
// new api
import {ND_getSongs, ND_login, ND_keepAlive} from "../utils/ND_Api"
import {ND_Song} from "../utils/ND_Interface"


let deviceTypeInfo: string = deviceInfo.deviceType;

@Builder
export function SongsBuilder() {
  Songs()
}

@Component
export default struct Songs {
  @StorageLink('baseURL') baseURL: string = ''
  @StorageLink('username') username: string = ''
  @StorageLink('password') password: string = ''
  @StorageLink('songCount') songCount: number = 0
  @Consume salt: string
  @Consume version: string
  @Consume client: string
  @Consume auth: string
  @Consume getCoverUrl: string
  // @Consume searchSongs: Song[]
  @Consume nowPlayingSong: ND_Song | undefined
  @Consume nowPlayingLyrics: StructuredLyric | undefined
  @Consume nowPlayingLyricsByGroup: Line[][]
  @Consume nowPlayingList: ND_Song[]
  @Consume nowPlayingListOriginal: ND_Song[]
  @Consume nowPlayingIndex: number
  @Consume isPlaying: boolean
  @Consume startPlaying: boolean
  @Consume showSidebar: boolean
  @Consume serverStatus: boolean
  @Consume showMenu: boolean
  @Consume longPressSong: ND_Song | undefined
  @Consume sleepTime: number
  @Consume selectedIndex: number
  @Consume showProgress: boolean
  @Consume avPlayer: media.AVPlayer | undefined
  @Consume pageStack: NavPathStack
  @StorageLink('playMode') playMode: number = 0
  @Consume session: AVSessionManager.AVSession | undefined
  @State coverSize: number = 256
  @State profileSize: number = 256
  @Consume displayWidth: number
  @Consume sidebarType: number
  @Consume needUpdate: boolean
  @Consume showLibrary: boolean
  @Consume musicFolders: MusicFolder[]
  @Consume libraryStates: Record<number, boolean>
  @Consume ND_token: string
  @Consume ND_id: string
  private  promptAction: PromptAction | null = null;
  @State searchContent: string = ""
  @State songs: ND_Song[] = [];
  @State songOrder: "DESC" | "ASC" = "ASC";
  @State songSort: "random" | "createdAt" | "max_year" | "play_count" | "play_date" | "title" | "album" | "rating" | string = "title";
  @State sortEn2Zh: Map<string, string> = new Map([
    ["title", "标题"],
    ["random", "随机"],
    ["createdAt", "创建时间"],
    ["play_date", "播放时间"],
    ["max_year", "年份"],
    ["play_count", "播放次数"],
    ["album", "专辑"],
    ["rating", "评分"]
  ]);
  @State sortZh2En: Map<string, string> = new Map([
    ["标题", "title"],
    ["随机", "random"],
    ["创建时间", "createdAt"],
    ["播放时间", "play_date"],
    ["年份", "max_year"],
    ["播放次数", "play_count"],
    ["专辑", "album"],
    ["评分", "rating"]
  ]);
  @State orderEn2Zh: Map<string, string> = new Map([
    ["ASC", "正序"],
    ["DESC", "倒序"]
  ]);
  @State orderZh2En: Map<string, string> = new Map([
    ["正序", "ASC"],
    ["倒序", "DESC"]
  ]);

  genSortMenu(sortEn: "random" | "createdAt" | "max_year" | "play_count" | "play_date" | "title" | "album" | "rating" | string): ()=>void {
    return async()=>{
      if (this.songSort != sortEn || this.songSort == "random") {
        await this.loadSongs(100, this.songOrder, sortEn, true);
      }
      this.songSort = sortEn;
    }
  }

  genOrderMenu(orderEn: "DESC" | "ASC"): ()=>void {
    return async()=>{
      if (this.songOrder != orderEn || this.songSort == "random") {
        await this.loadSongs(100, orderEn, this.songSort, true);
      }
      this.songOrder = orderEn;
    }
  }

  groupLyrics() {
    this.nowPlayingLyricsByGroup = []
    let index = -1
    for (let line of this.nowPlayingLyrics!.line) {
      if (this.nowPlayingLyricsByGroup.length === 0 || line.start !== this.nowPlayingLyricsByGroup[index][0].start) {
        index++
        this.nowPlayingLyricsByGroup.push([])
        this.nowPlayingLyricsByGroup[index].push(line)
      } else {
        this.nowPlayingLyricsByGroup[index].push(line)
      }
    }
  }

  getNowPlayingIndex(song: ND_Song, list: ND_Song[]) {
    for (let index = 0; index < list.length; index++) {
      if (list[index].id === song.id) {
        this.nowPlayingIndex = index
        break;
      }
    }
  }

  shuffleList<T>(array: T[]): T[] {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      let temp = array[i];
      array[i] = array[j];
      array[j] = temp;
    }
    return array;
  }

  async loadSongs(
    count: number = 100,
    songOrder: "DESC" | "ASC" = "ASC",
    songSort: "random" | "createdAt" | "max_year" | "play_count" | "play_date" | "title" | "album" | "rating" | string = "title",
    clear_data: boolean = false,
  ) {
    this.showProgress = true;
    console.log(`==prepare to get songs== songOrder=${songOrder}&songSort=${songSort}`);
    if (clear_data) {
      this.songs = [];
    }
    console.log(`song size=${this.songs.length}`);
    let result = await ND_getSongs(
      this.baseURL, this.ND_token, this.ND_id, this.songs.length, this.songs.length + count, songOrder, songSort
    );
    console.log("==prepare to songs ok==");
    this.showProgress = false;
    if (result) {
      let tempSongs = result.songs;
      this.songCount = result.songCount;
      this.songs.push(...tempSongs);
    } else {
      this.promptAction?.showToast({message: "获取歌曲失败，请检查网络"})
    }
  }

  formatTime(seconds: number) {
    let hours = Math.floor(seconds / 3600);
    let minutes = Math.floor((seconds % 3600) / 60);
    let secs = Math.floor(seconds % 60);

    if (hours > 0) {
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    } else {
      return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
  }

  async aboutToAppear() {
    this.showProgress = true;
    this.needUpdate = !this.needUpdate
    this.promptAction = this.getUIContext().getPromptAction();
    // login or keep-alive
    // keep-alive
    let needLogin = false;
    if (this.ND_token.length > 0 && this.ND_id.length > 0) {
      let result = await ND_keepAlive(this.baseURL, this.ND_token, this.ND_id);
      // may be is expired
      if (!result) {
        needLogin = true;
      }
    } else {
      needLogin = true;
    }
    // login
    if (needLogin) {
      let result = await ND_login(this.baseURL, this.username, this.password);
      if (result) {
        this.ND_token = result.token;
        this.ND_id = result.id;
      } else {
        this.getUIContext().showAlertDialog({message: "登录失败，请检查网络或者账户密码"})
      }
    }
    await this.loadSongs();
    this.showProgress = false;
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Search({value: this.searchContent})
            .width("100%")
            .height(this.displayWidth > 1400 ? 50 : 40)
            .layoutWeight(1)
            .borderRadius(10)
            .borderWidth(1)
            .margin({ left: 20, right: 20 })
            // .searchIcon({
            //   size: 0
            // })
            .searchButton("搜索", {
              fontSize: this.displayWidth > 1400 ? 20 : 18,
              fontColor: $r('app.color.font'),
              autoDisable: true,

            })
            .searchIcon(
              {src: $r("app.media.ic_public_search")}
            )
            .placeholderColor($r('app.color.font_secondary'))
            .placeholderFont({
              size: this.displayWidth > 1400 ? 22 : 20
            })
            .fontColor($r('app.color.font'))
            .textFont({
              size: this.displayWidth > 1400 ? 22 : 20
            })
            .caretStyle({
              color: $r('app.color.font_secondary')
            })
            .enterKeyType(EnterKeyType.Search)
            //.padding({ bottom: 15 })
            .onSubmit(async (searchContent: string, event: SubmitEvent) => {
              this.getUIContext().showAlertDialog({message: "功能待开发"})
            })
        }
        Row() {
          Text("排序方式：")
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
          Text(this.sortEn2Zh.get(this.songSort))
            .border({width: 1})
            .padding({left: 10, right: 10})
            // .margin({left: 10, right: 10})
            .fontSize(16)
            .borderRadius(5)
            .bindMenu([
              {value: "标题", action: this.genSortMenu("title")},
              {value: "随机", action: this.genSortMenu("random")},
              {value: "创建时间", action: this.genSortMenu("createdAt")},
              {value: "播放时间", action: this.genSortMenu("play_date")},
              {value: "年份", action: this.genSortMenu("max_year")},
              {value: "播放次数", action: this.genSortMenu("play_count")},
              {value: "专辑", action: this.genSortMenu("album")},
              {value: "评分", action: this.genSortMenu("rating")},
            ])

          Text(this.orderEn2Zh.get(this.songOrder))
            .border({width: 1})
            .padding({left: 10, right: 10})
            .margin({left: 10})
            .fontSize(16)
            .borderRadius(5)
            .bindMenu([
              {value: "顺序", action: this.genOrderMenu("ASC")},
              {value: "倒序", action: this.genOrderMenu("DESC")},
            ])
        }
        .margin({ top: 15, bottom: 5 })
        .padding({ left: 20 })
        .width('100%')
        Scroll() {
          Column() {
            Column() {
              ForEach(this.songs, (song: ND_Song, index) => {
                Button({ type: ButtonType.Normal }) {
                  Row() {
                    Column() {
                      // Text(`${index + 1}`)
                      //   .fontSize(10)
                      //   .layoutWeight(1)
                      Text(song.title)
                        .fontSize(18)
                        .fontColor($r('app.color.font'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(song.artist + " - " + song.album)
                        .fontSize(15)
                        .fontColor($r('app.color.font_secondary'))
                        .margin({ top: 5 })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .layoutWeight(7)
                    .margin({ left: 2 })
                    .alignItems(HorizontalAlign.Start)

                    Column() {
                      Text(this.formatTime(song.duration))
                        .fontSize(18)
                        .fontColor($r('app.color.font'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(`${song.suffix} | ${song.bitRate}kbps`)
                        .fontSize(12)
                        .fontColor($r('app.color.font_secondary'))
                        .margin({ top: 5 })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .layoutWeight(3)
                    .margin({ left: 2 })
                    .alignItems(HorizontalAlign.End)
                  }
                  .width('100%')
                  .height('100%')
                  .padding({ right: 15 })
                }
                .width('100%')
                .height(80)
                .borderRadius(10)
                .backgroundColor(Color.Transparent)
                .padding({ left: 20, right: 20 })
                .animation({ curve: curves.springMotion(0.6, 1) })
                .onClick(async () => {
                  this.startPlaying = true
                  await this.avPlayer!.reset()
                  this.isPlaying = true
                  this.nowPlayingSong = song
                  if (song.lyrics.length > 0) {
                    let temp_lyrics: StructuredLyric[] = JSON.parse(song.lyrics)
                    this.nowPlayingLyrics = temp_lyrics[0];
                  }
                  if (this.nowPlayingLyrics !== undefined) {
                    this.groupLyrics()
                  }
                  this.nowPlayingListOriginal = this.songs.slice()
                  if (this.playMode === AVSessionManager.LoopMode.LOOP_MODE_SHUFFLE) {
                    this.nowPlayingList = this.shuffleList(this.nowPlayingListOriginal.slice())
                  } else {
                    this.nowPlayingList = this.nowPlayingListOriginal.slice()
                  }
                  this.getNowPlayingIndex(song, this.nowPlayingList)
                  this.avPlayer!.url = this.baseURL + '/rest/stream' + this.auth + `&id=${song.id}&format=raw`;
                })
                .gesture(
                  LongPressGesture()
                    .onAction(async (event: GestureEvent) => {
                      this.longPressSong = song
                      this.showMenu = true
                      // let tmp_song: Song | undefined =
                      //   await getSong(this.baseURL, this.username, this.password, this.longPressSong!.id)
                      // if (tmp_song !== undefined && tmp_song.starred !== undefined) {
                      //   this.longPressSong!.starred = tmp_song.starred
                      // }
                      this.longPressSong!.starred = true;
                    })
                )
              })
            }
            .width('100%')
            .padding({ bottom: this.songs.length > 0 ? 0 : 10 })
            .visibility(this.songs.length > 0 ? Visibility.Visible : Visibility.None)

            Column() {
              Text("没有歌曲")
                .fontSize(32)
                .fontColor($r('app.color.font'))
            }
            .width('100%')
            .height('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .padding({ bottom: 160 })
            .visibility(this.songs.length === 0 && this.showProgress === false ? Visibility.Visible : Visibility.None)
          }
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Fade, { alwaysEnabled: false })
        .align(Alignment.Top)
        .margin({ bottom: this.startPlaying === true ? 55 : 0 })
        .onReachEnd(async ()=>{
          this.showProgress = true;
          await this.loadSongs();
          this.showProgress = false;
        })
      }
      .width('100%')
      .height('100%')
    }.width("100%")
    .height("100%")
    .title(`歌曲（总数${this.songCount}）`)
    .padding({top: 40})
    .onReady(async (context: NavDestinationContext)=>{
      this.pageStack = context.pathStack;
    })
  }
}