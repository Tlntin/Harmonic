import {getPlaylists} from "../utils/Api"
import {Album, Artist, Song, StructuredLyric, Line, Playlist} from "../utils/Interface"
import { media } from '@kit.MediaKit';
import { avSession as AVSessionManager } from '@kit.AVSessionKit';
import createPlaylistBuilder from './dialogs/CreatePlaylist'
import {common, ConfigurationConstant} from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';


let deviceTypeInfo: string = deviceInfo.deviceType;

@Preview
@Component
export default struct MyProfile {
  @StorageLink('baseURL') baseURL: string = ''
  @StorageLink('username') username: string = ''
  @StorageLink('password') password: string = ''
  @StorageLink('songCount') songCount: number = 0
  @Consume salt: string
  @Consume version: string
  @Consume client: string
  @Consume auth: string
  @Consume getCoverUrl: string
  @Consume pageStack: NavPathStack
  @Consume startPlaying: boolean
  @Consume showSidebar: boolean
  @Consume serverStatus: boolean
  @Consume displayWidth: number
  @Consume showProgress: boolean
  @Consume needUpdate: boolean
  @Consume showLibrary: boolean
  @Consume album: Album
  @Consume ND_token: string
  @Consume ND_id: string
  @Consume artist: Artist | undefined
  @Consume nowPlayingSong: Song | undefined
  @Consume nowPlayingLyrics: StructuredLyric | undefined
  @Consume nowPlayingLyricsByGroup: Line[][]
  @Consume nowPlayingList: Song[]
  @Consume playlists: Playlist[]
  @Consume playlist: Playlist | undefined
  @Consume nowPlayingListOriginal: Song[]
  @Consume nowPlayingIndex: number
  @Consume starredSongs: Song[]
  @Consume isPlaying: boolean
  @Consume discs: Song[][]
  @Consume showMenu: boolean
  @Consume closePlay: boolean
  @Consume nowPage: number
  @Consume showPlay: boolean
  @Consume sidebarType: number
  @Consume longPressSong: Song | undefined
  @Consume avPlayer: media.AVPlayer | undefined
  @StorageLink('playMode') playMode: number = 0
  @StorageLink('theme') theme: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  @Consume session: AVSessionManager.AVSession | undefined
  @State themeIcon: Resource = $r('app.media.auto')
  private createPlaylist: CustomDialogController = new CustomDialogController({
    builder: createPlaylistBuilder(),
    width: 350,
    height: 310,
    backgroundColor: $r('app.color.start_window_background')
  })
  private context: common.UIAbilityContext | undefined = undefined;
  private uiContext: UIContext | undefined = undefined;

  async aboutToAppear() {
    this.showProgress = true
    // this.playlists = (await getPlaylists(this.baseURL, this.username, this.password)).sort((a, b) => {
    //   return Date.parse(b.changed) - Date.parse(a.changed);
    // })
    this.uiContext = this.getUIContext();
    if (!this.uiContext) {
      console.warn("no uiContext");
      return;
    }
    this.context = this.uiContext.getHostContext() as common.UIAbilityContext;
    this.showProgress = false;
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text("我的")
            .textAlign(TextAlign.Start)
            .width("100%")
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .padding({ left: 20, right: 20 })
          // Blank()
        }

        Row() {
          Column() {
            Image($r("app.media.ic_public_music"))
              .width(30)
            Text("全部音乐")
              .fontSize(16)
          }.onClick(async ()=>{
            this.pageStack.pushPathByName("Songs", null);
          })

          Column() {
            Image($r("app.media.ic_gallery_continuous_shooting"))
              .width(30)
            Text("全部专辑")
          }
          .onClick(async () => {
            this.pageStack.pushPathByName("Albums", null);
          })

          Column() {
            Image($r("app.media.ic_contacts_business_cards_filled"))
              .width(30)
            Text("艺术家")
          }.onClick(async ()=>{
            this.pageStack.pushPathByName("Artists", null);
          })
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 20 })
        .padding({
          left: 10,
          right: 10,
          top: 10,
          bottom: 10
        })
        .width("90%")
        .border({ width: 1, color: "#DCDCDC" })
        .borderRadius(10)

        Column() {
          Row() {
            Text("当前歌单")
              .padding({ left: 5, right: 5 })
              .fontSize(20)
            Blank()
            Button() {
              Image($r("app.media.ic_public_add"))
                .size({width: 20})
            }.backgroundColor(Color.Transparent)
            .width(40)
            .onClick(() => {
              this.createPlaylist.open()
            })
          }.width("100%")
          .padding({ top: 10, bottom: 10 })
          .align(Alignment.TopStart)

          List() {
            ForEach(this.playlists, (playlist: Playlist, index) => {
              ListItem() {
                Column() {
                  Row() {
                    Column() {
                      Text(playlist.name)
                        .fontSize(16)
                        .fontColor($r('app.color.font'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width("100%")
                        .textAlign(TextAlign.Start)
                      Text(`${playlist.songCount}首`)
                        .fontSize(12)
                        .fontColor("#C0C0C0")
                        .width("100%")
                        .textAlign(TextAlign.Start)
                    }.layoutWeight(7)
                    Blank().layoutWeight(4)
                    Image($r("app.media.ic_public_arrow_right"))
                      .size({ width: 30, height: 30 })
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .height('100%')
                  //.padding({ left: 20, right: 20 })
                  .onClick(() => {
                    this.playlist = playlist
                    this.pageStack.pushPathByName('PlaylistDetail', undefined);
                  })
                  Divider()
                    .width('90%')
                    .height(1)
                    .color($r('app.color.divider'))
                    .padding({bottom: 10})
                }
                .width("100%")
                .height(50)
              }
            })
          }
          .width('100%')
          .alignListItem(ListItemAlign.Center)
          .padding({ bottom: 10, left: 10, right: 10})
          .listDirection(Axis.Vertical)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Fade, {alwaysEnabled: false})
          .visibility(this.playlists.length > 0 && this.showProgress === false ? Visibility.Visible : Visibility.None)

          Column() {
            Text("没有歌单")
              .fontSize(32)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .visibility(this.playlists.length === 0 && this.showProgress === false ? Visibility.Visible : Visibility.None)
        }
        .width("90%")
        .margin({ top: 10 })
        .padding({
          left: 10,
          right: 10,
          top: 10,
          bottom: 10
        })
        .border({ width: 1, color: "#DCDCDC" })
        .borderRadius(10)

        Column() {
          Row() {
            Image(this.themeIcon)
              .size({ width: 30, height: 30 })
            Text("主题")
              .fontSize(20)
              .margin({ left: 10 })
            Blank()
            Image($r("app.media.ic_public_arrow_right"))
              .size({ width: 30, height: 30 })
          }.width("100%")
          .padding({ top: 10, bottom: 15 })
          .onClick(() => {
            if (this.theme === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
              this.theme = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
              this.themeIcon = $r('app.media.light')
            } else if (this.theme === 1) {
              this.theme = ConfigurationConstant.ColorMode.COLOR_MODE_DARK
              this.themeIcon = $r('app.media.dark')
            } else {
              this.theme = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
              this.themeIcon = $r('app.media.auto')
            }
            this.context?.getApplicationContext().setColorMode(this.theme)
          })
          Divider()
          Row() {
            Image($r("app.media.setting"))
              .size({ width: 30, height: 30 })
            Text("设置")
              .fontSize(20)
              .margin({ left: 10 })
            Blank()
            Image($r("app.media.ic_public_arrow_right"))
              .size({ width: 30, height: 30 })
          }.width("100%")
          .padding({ top: 10, bottom: 15 })
          .onClick(async () => {
            this.pageStack.pushPathByName("MySetting", null);
          })
          Divider()
          Row() {
            Image($r("app.media.ic_public_detail"))
              .size({ width: 30, height: 30 })
            Text("关于")
              .fontSize(20)
              .margin({ left: 10 })
            Blank()
            Image($r("app.media.ic_public_arrow_right"))
              .size({ width: 30, height: 30 })
          }.width("100%")
          .padding({ top: 15, bottom: 10 })
          .onClick(async()=>{
            this.pageStack.pushPathByName("About", null);
          })
        }
        .width("90%")
        .margin({ top: 10 })
        // .padding({left: 20, right: 20})
        .padding({
          left: 10,
          right: 10,
          top: 10,
          bottom: 10
        })
        .border({ width: 1, color: "#DCDCDC" })
        .borderRadius(10)
      }.width("100%")
      .height("100%")
    }
    .width("100%")
    .height("100%")
  }
}
