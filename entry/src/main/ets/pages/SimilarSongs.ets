import { curves } from '@kit.ArkUI';
import { media } from '@kit.MediaKit';
import { avSession as AVSessionManager } from '@kit.AVSessionKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { PromptAction } from '@kit.ArkUI';
// import { ImageKnifeComponent } from '@ohos/imageknife'
// old api
import { getLyrics, getSimilarSongs} from '../utils/Api';
import { Line, MusicFolder, StructuredLyric, Song} from '../utils/Interface';
import {ND_Song} from "../utils/ND_Interface"
import {song2ND_Song} from "../utils/OtherAPI"


let deviceTypeInfo: string = deviceInfo.deviceType;

@Builder
export function SimilarSongsBuilder() {
  SimilarSongs()
}

@Component
export default struct SimilarSongs {
  @StorageLink('baseURL') baseURL: string = ''
  @StorageLink('username') username: string = ''
  @StorageLink('password') password: string = ''
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
  @Consume showPlay: boolean
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
  // @Consume ND_token: string
  // @Consume ND_id: string
  private  promptAction: PromptAction | null = null;
  @State similarSongs: Song[] = [];


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

  getNowPlayingIndex(song: Song | ND_Song, list: ND_Song[]) {
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

  async loadSimilarSongs(count: number = 50) {
    console.log(`==prepare to getSimilarSongs== `);
    this.similarSongs = [];
    if (this.nowPlayingSong) {
      this.showProgress = true;
      let result = await getSimilarSongs(this.baseURL, this.username, this.password, this.nowPlayingSong?.id, count)
      console.log("==prepare to getSimilarSongs ok==");
      console.log(`==getSimilarSongs result: ${JSON.stringify(result)}==`);
      this.showProgress = false;
      if (result) {
        for (let song of result) {
          if (song.id != this.nowPlayingSong?.id) {
            this.similarSongs.push(song);
          }
        }
      } else {
        this.promptAction?.showToast({ message: "获取相似歌曲失败，请检查网络" })
      }
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
    // this.needUpdate = !this.needUpdate
    this.promptAction = this.getUIContext().getPromptAction();
    await this.loadSimilarSongs();
    this.showProgress = false;
  }

  build() {
    NavDestination() {
      Column() {
        Column() {
          LoadingProgress()
            .width("100%")
            .height(80)
            .color($r('app.color.font'))
            .margin({ bottom: 160 })
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .visibility(this.showProgress === true ? Visibility.Visible : Visibility.None)

        Scroll() {
          Column() {
            Column() {
              ForEach(this.similarSongs, (song: Song, index) => {
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
                  this.nowPlayingSong = song2ND_Song(song);
                  let tempLyrics = await getLyrics(this.baseURL, this.username, this.password, song.id);
                  if (tempLyrics) {
                    this.nowPlayingLyrics = tempLyrics;
                  }
                  if (this.nowPlayingLyrics !== undefined) {
                    this.groupLyrics()
                  }
                  let tempList = this.similarSongs.slice()
                  for (let tempSong of tempList) {
                    this.nowPlayingListOriginal.push(song2ND_Song(tempSong));
                  }
                  if (this.playMode === AVSessionManager.LoopMode.LOOP_MODE_SHUFFLE) {
                    this.nowPlayingList = this.shuffleList(this.nowPlayingListOriginal.slice())
                  } else {
                    this.nowPlayingList = this.nowPlayingListOriginal.slice()
                  }
                  this.getNowPlayingIndex(song, this.nowPlayingList)
                  this.avPlayer!.url = this.baseURL + '/rest/stream' + this.auth + `&id=${song.id}&format=raw`;
                  this.getUIContext()?.animateTo({
                    duration: 600,
                    curve: Curve.Friction
                  }, () => {
                    this.showPlay = true
                  })
                })
                .gesture(
                  LongPressGesture()
                    .onAction(async (event: GestureEvent) => {
                      this.longPressSong = song2ND_Song(song)
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
            .padding({ bottom: this.similarSongs.length > 0 ? 0 : 10 })
            .visibility(this.similarSongs.length > 0 ? Visibility.Visible : Visibility.None)

            Column() {
              Text("没有相似歌曲")
                .fontSize(32)
                .fontColor($r('app.color.font'))
            }
            .width('100%')
            .height('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .padding({ bottom: 160 })
            .visibility(this.similarSongs.length === 0 && this.showProgress === false ? Visibility.Visible : Visibility.None)
          }
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Fade, { alwaysEnabled: false })
        .align(Alignment.Top)
        // .margin({ bottom: this.startPlaying === true ? 55 : 0 })

      }
      .width('100%')
      .height('100%')
    }.width("100%")
    .height("100%")
    .title(this.showProgress?`相似歌曲`:`相似歌曲（${this.similarSongs.length}首）`)
    .padding({top: 40})
    .onReady(async (context: NavDestinationContext)=>{
      this.pageStack = context.pathStack;
    })
  }
}