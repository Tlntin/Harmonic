import { curves} from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { ImageKnifeComponent } from '@ohos/imageknife'
import { media } from '@kit.MediaKit';
import { avSession as AVSessionManager } from '@kit.AVSessionKit';
import { Album, Artist, MusicFolder, Song, StructuredLyric, Line} from '../utils/Interface';
import { ND_Song } from '../utils/ND_Interface';
import {ND_keepAlive, ND_login} from "../utils/ND_Api";

let deviceTypeInfo: string = deviceInfo.deviceType;

@Component
export default struct Home {
  @StorageLink('baseURL') baseURL: string = ''
  @StorageLink('username') username: string = ''
  @StorageLink('password') password: string = ''
  @StorageLink('songCount') songCount: number = 0
  @StorageLink('playMode') playMode: number = 0
  @Consume salt: string;
  @Consume version: string;
  @Consume client: string;
  @Consume auth: string;
  @Consume getCoverUrl: string;
  @Consume recentSongs: ND_Song[]
  @Consume newestSongs: ND_Song[]
  @Consume frequentSongs: ND_Song[]
  @Consume starredAlbums: Album[]
  @Consume starredArtists: Artist[]
  @Consume randomAlbums: Album[]
  @Consume album: Album | undefined
  @Consume artist: Artist | undefined
  @Consume pageStack: NavPathStack
  @Consume startPlaying: boolean
  @Consume showSidebar: boolean
  @State coverSize: number = 320
  @State profileSize: number = 256
  @Consume searchContent: string
  @Consume showProgress: boolean
  @Consume sidebarType: number
  @Consume displayWidth: number
  @Consume needUpdate: boolean
  @Consume showLibrary: boolean
  @Consume libraryStates: Record<number, boolean>
  @Consume musicFolders: MusicFolder[]
  @Consume searchSongs: Song[]
  @Consume searchAlbums: Album[]
  @Consume searchArtists: Artist[];
  @Consume nowPlayingSong: ND_Song | undefined
  @Consume nowPlayingLyrics: StructuredLyric | undefined
  @Consume nowPlayingLyricsByGroup: Line[][]
  @Consume nowPlayingList: ND_Song[]
  @Consume nowPlayingListOriginal: ND_Song[]
  @Consume nowPlayingIndex: number
  @Consume avPlayer: media.AVPlayer | undefined
  @Consume isPlaying: boolean
  @Consume ND_token: string
  @Consume ND_id: string
  private recentSongsScroller: Scroller = new Scroller
  private newestSongsScroller: Scroller = new Scroller
  private frequentAlbumsScroller: Scroller = new Scroller
  private randomAlbumsScroller: Scroller = new Scroller
  private starredAlbumsScroller: Scroller = new Scroller
  private starredArtistsScroller: Scroller = new Scroller

  async loginOrKeepAlive() {
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
  }

  async aboutToAppear() {
    // no songs, need get data
    if (this.recentSongs.length === 0 && this.frequentSongs.length === 0 && this.newestSongs.length === 0) {
      this.needUpdate = true;
    }
    await this.loginOrKeepAlive();
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

  async playSong(song: ND_Song) {
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
    this.nowPlayingListOriginal = this.recentSongs.slice()
    if (this.playMode === AVSessionManager.LoopMode.LOOP_MODE_SHUFFLE) {
      this.nowPlayingList = this.shuffleList(this.nowPlayingListOriginal.slice())
    } else {
      this.nowPlayingList = this.nowPlayingListOriginal.slice()
    }
    this.getNowPlayingIndex(song, this.nowPlayingList)
    this.avPlayer!.url = this.baseURL + '/rest/stream' + this.auth + `&id=${song.id}&format=raw`;
  }

  build() {
    Scroll() {
      Column() {
        Text("首页")
          .textAlign(TextAlign.Start)
          .width("100%")
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          // .margin({ top: 40 })
          .padding({ left: 20, right: 20 })

        Row() {
          Search({value: this.searchContent, placeholder: "搜索歌曲/专辑/艺人"})
            .width("100%")
            .height(this.displayWidth > 1400 ? 50 : 40)
            .layoutWeight(1)
            .border({width: 1})
            .borderRadius(10)
            .margin({ left: 20, right: 20 })
            .searchIcon({
              size: 0
            })
            .searchButton("搜索", {
              fontSize: this.displayWidth > 1400 ? 20 : 18,
              fontColor: $r('app.color.font'),
              autoDisable: true
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
            .onChange((tempContent)=>{
              this.searchContent = tempContent;
            })
            .enterKeyType(EnterKeyType.Search)
            .onSubmit(async()=>{
              if (this.searchContent.length > 0) {
                this.pageStack.pushPathByName("Search", JSON.stringify({
                  searchContent: this.searchContent,
                }))
              }
            })
        }
        .padding({top: 20})
        .backgroundColor(Color.Transparent)
        // .margin({ top: 10 })

        Column() {
          Row() {
            Text("最近播放")
              .fontSize(20)
              .fontColor($r('app.color.font'))
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Start)
              .margin({ bottom: 5 })

            Row() {
              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .margin({ right: 10 })
              .onClick(() => {
                this.recentSongsScroller.scrollPage({
                  next: false,
                  animation: true
                })
              })

              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.recentSongsScroller.scrollPage({
                  next: true,
                  animation: true
                })
              })
            }
            .visibility(deviceTypeInfo === '2in1' ? Visibility.Visible : Visibility.None)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 10})
          .margin({ top: 10 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Bottom)

          List({ scroller: this.recentSongsScroller }) {
            ForEach(this.recentSongs, (song: ND_Song, index) => {
              ListItem() {
                Button({ type: ButtonType.Normal }) {
                  Column() {
                    ImageKnifeComponent({
                      imageKnifeOption: {
                        loadSrc:this.baseURL + this.getCoverUrl + this.auth + `&id=${song.id}&size=${this.coverSize}`,
                        placeholderSrc: $rawfile('nocover.png'),
                        errorholderSrc:$rawfile('nocover.png') ,
                        objectFit: ImageFit.Contain,
                        border:{radius: 10}
                      }
                    })
                      .height('50%')
                      .aspectRatio(1)
                      .margin(10)

                    Text(`${song.title}`)
                      .fontSize(16)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(`${song.artist}`)
                      .fontSize(16)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('auto')
                  .height('100%')
                }
                .width('auto')
                .height('100%')
                .margin({ left: index === 0 ? 10 : 0, right: index === this.recentSongs!.length - 1 ? 10 : 0 })
                .padding(10)
                .animation({ curve: curves.springMotion(0.6, 1) })
                .borderRadius(10)
                .backgroundColor(Color.Transparent)
                .onClick(async () => {
                  this.playSong(song);
                })
              }
            })
          }
          .width('100%')
          .height('100%')
          .layoutWeight(1)
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .height(this.displayWidth > 1400 ? 270 : 230)
        .visibility(this.showProgress === true || this.recentSongs.length === 0 ? Visibility.None :
        Visibility.Visible)

        Column() {
          Row() {
            Text("最近添加")
              .fontSize(20)
              .fontColor($r('app.color.font'))
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Start)
              .margin({ bottom: 5 })

            Row() {
              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .margin({ right: 10 })
              .onClick(() => {
                this.newestSongsScroller.scrollPage({
                  next: false,
                  animation: true
                })
              })

              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.newestSongsScroller.scrollPage({
                  next: true,
                  animation: true
                })
              })
            }
            .visibility(deviceTypeInfo === '2in1' ? Visibility.Visible : Visibility.None)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20})
          .margin({ top: 10 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Bottom)

          List({ scroller: this.newestSongsScroller }) {
            ForEach(this.newestSongs, (song: ND_Song, index) => {
              ListItem() {
                  Button({ type: ButtonType.Normal }) {
                    Column() {
                      ImageKnifeComponent({
                        imageKnifeOption: {
                          loadSrc: this.baseURL + this.getCoverUrl + this.auth +
                            `&id=${song.id}&size=${this.coverSize}`,
                          placeholderSrc: $rawfile('nocover.png'),
                          errorholderSrc: $rawfile('nocover.png'),
                          objectFit: ImageFit.Contain,
                          border:{radius: 10}
                        }
                      })
                        .height('70%')
                        .aspectRatio(1)
                        .margin(10)
                      Column() {
                        Text(`${song.title}`)
                          .fontSize(14)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .textAlign(TextAlign.Start)
                          .fontWeight(FontWeight.Medium)
                          .width("100%")

                        Text(`${song.artist}`)
                          .fontSize(14)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .textAlign(TextAlign.Start)
                          .fontWeight(FontWeight.Medium)
                          .width("100%")
                      }
                      .padding({ bottom: 2})
                      .width(120)
                    }
                    .width('auto')
                    .height('100%')
                  }
                  .width('auto')
                  .layoutWeight(4)
                  .margin({ left: index === 0 ? 10 : 0, right: index === this.newestSongs!.length - 1 ? 10 : 0 })
                  .animation({ curve: curves.springMotion(0.6, 1) })
                  .borderRadius(10)
                  .backgroundColor(Color.Transparent)
                  .onClick(async() => {
                    await this.playSong(song);
                  })
              }
            })
          }
          .width('100%')
          .height('100%')
          .layoutWeight(1)
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .height(this.displayWidth > 1400 ? 290 : 250)
        .visibility(this.showProgress === true || this.newestSongs.length === 0 ? Visibility.None :
        Visibility.Visible)

        Column() {
          Row() {
            Text("最常播放")
              .fontSize(20)
              .fontColor($r('app.color.font'))
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Start)
              .margin({ bottom: 5 })

            Row() {
              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .margin({ right: 10 })
              .onClick(() => {
                this.frequentAlbumsScroller.scrollPage({
                  next: false,
                  animation: true
                })
              })

              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.frequentAlbumsScroller.scrollPage({
                  next: true,
                  animation: true
                })
              })
            }
            .visibility(deviceTypeInfo === '2in1' ? Visibility.Visible : Visibility.None)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20})
          .margin({ top: 10 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Bottom)

          List({ scroller: this.frequentAlbumsScroller }) {
            ForEach(this.frequentSongs, (song: ND_Song, index) => {
              ListItem() {
                  Button({ type: ButtonType.Normal }) {
                    Column() {
                      ImageKnifeComponent({
                        imageKnifeOption: {
                          loadSrc: this.baseURL + this.getCoverUrl + this.auth +
                            `&id=${song.id}&size=${this.coverSize}`,
                          placeholderSrc: $rawfile('nocover.png'),
                          errorholderSrc: $rawfile('nocover.png'),
                          objectFit: ImageFit.Contain,
                          border:{radius: 10}
                        }
                      })
                        .height('70%')
                        .aspectRatio(1)
                        .margin(10)
                      Column() {
                        Text(`${song.title}`)
                          .fontSize(14)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .textAlign(TextAlign.Start)
                          .fontWeight(FontWeight.Medium)
                          .width("100%")

                        Text(`${song.artist}`)
                          .fontSize(14)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .textAlign(TextAlign.Start)
                          .fontWeight(FontWeight.Medium)
                          .width("100%")
                      }
                      .padding({ bottom: 2})
                      .width(120)
                    }
                    .width('auto')
                    .height('100%')
                  }
                  .width('auto')
                  .layoutWeight(4)
                  .margin({ left: index === 0 ? 10 : 0, right: index === this.frequentSongs!.length - 1 ? 10 : 0 })
                  .animation({ curve: curves.springMotion(0.6, 1) })
                  .borderRadius(10)
                  .backgroundColor(Color.Transparent)
                  .onClick(async () => {
                    await this.playSong(song);
                  })
              }
            })
          }
          .width('100%')
          .height('100%')
          .layoutWeight(1)
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .height(this.displayWidth > 1400 ? 290 : 250)
        .visibility(this.showProgress === true || this.frequentSongs.length === 0 ? Visibility.None :
        Visibility.Visible)

        Column() {
          Row() {
            Text("随机专辑")
              .fontSize(20)
              .fontColor($r('app.color.font'))
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Start)
              .margin({ bottom: 5 })

            Row() {
              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .margin({ right: 10 })
              .onClick(() => {
                this.randomAlbumsScroller.scrollPage({
                  next: false,
                  animation: true
                })
              })

              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.randomAlbumsScroller.scrollPage({
                  next: true,
                  animation: true
                })
              })
            }
            .visibility(deviceTypeInfo === '2in1' ? Visibility.Visible : Visibility.None)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20})
          .margin({ top: 10 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Bottom)

          List({ scroller: this.randomAlbumsScroller }) {
            ForEach(this.randomAlbums, (album: Album, index) => {
              ListItem() {
                Button({ type: ButtonType.Normal }) {
                  Column() {
                    ImageKnifeComponent({
                      imageKnifeOption: {
                        loadSrc:this.baseURL + this.getCoverUrl + this.auth + `&id=${album.id}&size=${this.coverSize}`,
                        placeholderSrc: $rawfile('nocover.png'),
                        errorholderSrc: $rawfile('nocover.png'),
                        objectFit: ImageFit.Contain,
                        border:{radius: 10}
                      }
                    })
                      .height('70%')
                      .aspectRatio(1)
                      .margin(10)
                    Column() {
                      Text(`${album.title}`)
                        .fontSize(14)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .textAlign(TextAlign.Center)
                        .fontWeight(FontWeight.Medium)
                        .width("100%")
                    }.width(150)

                  }
                  .width('auto')
                  .height('100%')
                }
                .width('auto')
                .height('100%')
                .margin({ left: index === 0 ? 10 : 0, right: index === this.randomAlbums!.length - 1 ? 10 : 0 })
                .animation({ curve: curves.springMotion(0.6, 1) })
                .borderRadius(10)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.album = album
                  this.pageStack.pushPathByName('AlbumDetail', undefined);
                })
              }
            })
          }
          .width('100%')
          .height('100%')
          .layoutWeight(1)
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .height(this.displayWidth > 1400 ? 270 : 230)
        .visibility(this.showProgress === true || this.randomAlbums.length === 0 ? Visibility.None :
        Visibility.Visible)

        Column() {
          Row() {
            Text("收藏专辑")
              .fontSize(20)
              .fontColor($r('app.color.font'))
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Start)
              .margin({ bottom: 5 })

            Row() {
              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .margin({ right: 10 })
              .onClick(() => {
                this.starredAlbumsScroller.scrollPage({
                  next: false,
                  animation: true
                })
              })

              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.starredAlbumsScroller.scrollPage({
                  next: true,
                  animation: true
                })
              })
            }
            .visibility(deviceTypeInfo === '2in1' ? Visibility.Visible : Visibility.None)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20})
          .margin({ top: 10 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Bottom)

          List({ scroller: this.starredAlbumsScroller }) {
            ForEach(this.starredAlbums, (album: Album, index) => {
              ListItem() {
                Button({ type: ButtonType.Normal }) {
                  Column() {
                    ImageKnifeComponent({
                      imageKnifeOption: {
                        loadSrc:this.baseURL + this.getCoverUrl + this.auth + `&id=${album.id}&size=${this.coverSize}`,
                        placeholderSrc: $rawfile('nocover.png'),
                        errorholderSrc:$rawfile('nocover.png') ,
                        objectFit: ImageFit.Contain,
                        border:{radius: 10}
                      }
                    })
                      .height('100%')
                      .aspectRatio(1)
                      .margin(10)
                  }
                  .width('auto')
                  .height('100%')
                }
                .width('auto')
                .height('100%')
                .margin({ left: index === 0 ? 10 : 0, right: index === this.starredAlbums!.length - 1 ? 10 : 0 })
                .animation({ curve: curves.springMotion(0.6, 1) })
                .borderRadius(10)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.album = album
                  this.pageStack.pushPathByName('AlbumDetail', undefined);
                })
              }
            })
          }
          .width('100%')
          .height('100%')
          .layoutWeight(1)
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .height(this.displayWidth > 1400 ? 250 : 210)
        .visibility(this.showProgress === true || this.starredAlbums.length === 0 ? Visibility.None :
        Visibility.Visible)

        Column() {
          Row() {
            Text("收藏艺术家")
              .fontSize(20)
              .fontColor($r('app.color.font'))
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Start)
              .margin({ bottom: 5 })

            Row() {
              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .margin({ right: 10 })
              .onClick(() => {
                this.starredArtistsScroller.scrollPage({
                  next: false,
                  animation: true
                })
              })

              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(28)
                  .fontColor([$r('app.color.font')])
              }
              .width(30)
              .height(30)
              .borderRadius(5)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.starredArtistsScroller.scrollPage({
                  next: true,
                  animation: true
                })
              })
            }
            .visibility(deviceTypeInfo === '2in1' ? Visibility.Visible : Visibility.None)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20})
          .margin({ top: 10 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Bottom)

          List({ scroller: this.starredArtistsScroller }) {
            ForEach(this.starredArtists, (artist: Artist, index) => {
              ListItem() {
                Button({ type: ButtonType.Normal }) {
                  Column() {
                    ImageKnifeComponent({
                      imageKnifeOption: {
                        loadSrc:this.baseURL + this.getCoverUrl + this.auth + `&id=${artist.id}&size=${this.profileSize}`,
                        placeholderSrc: $rawfile('noprofile.jpg'),
                        errorholderSrc:$rawfile('noprofile.jpg') ,
                        objectFit: ImageFit.Cover
                      }
                    })
                      .height('100%')
                      .layoutWeight(1)
                      .aspectRatio(1)
                      .borderRadius(100)
                      .margin(10)
                    Text(artist.name)
                      .width('100%')
                      .fontSize(16)
                      .fontColor($r('app.color.font'))
                      .margin({ bottom: 10, left: 10, right: 10 })
                      .maxLines(1)
                      .textAlign(TextAlign.Center)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .height('100%')
                }
                .width(this.displayWidth > 1400 ? 160 : 124)
                .height('100%')
                .margin({ left: index === 0 ? 10 : 0, right: index === this.starredArtists!.length - 1 ? 10 : 0 })
                .animation({ curve: curves.springMotion(0.6, 1) })
                .borderRadius(10)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.artist = artist
                  this.pageStack.pushPathByName('ArtistDetail', undefined);
                })
              }
            })
          }
          .width('100%')
          .height('100%')
          .layoutWeight(1)
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .height(this.displayWidth > 1400 ? 230 : 195)
        .visibility(this.showProgress === true || this.starredArtists.length === 0 ? Visibility.None :
        Visibility.Visible)

        Column() {
          Text("什么都没有")
            .fontSize(32)
            .fontColor($r('app.color.font'))
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 160 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.starredArtists.length === 0 && this.starredAlbums.length === 0 &&
          this.frequentSongs.length === 0 && this.newestSongs.length === 0 && this.recentSongs.length === 0 &&
          this.showProgress === false ? Visibility.Visible : Visibility.None)
      }
      .padding({ bottom: this.startPlaying === true ? 95 : 10 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Fade, { alwaysEnabled: false })
    .align(Alignment.Top)
  }
}