import { Artist } from '../utils/Interface'
import {ND_Artist} from "../utils/ND_Interface";
import { curves } from '@kit.ArkUI'
import { ImageKnifeComponent } from '@ohos/imageknife'
import { ND_getArtist, ND_login, ND_keepAlive } from '../utils/ND_Api';


@Builder
export function ArtistsBuilder() {
  Artists()
}

@Component
export default struct Artists {
  @StorageLink('baseURL') baseURL: string = ''
  @StorageLink('username') username: string = ''
  @StorageLink('password') password: string = ''
  @Consume salt: string
  @Consume version: string
  @Consume client: string
  @Consume auth: string
  @Consume getCoverUrl: string
  @Consume artists: ND_Artist[]
  @Consume pageStack: NavPathStack
  @Consume startPlaying: boolean
  @Consume showSidebar: boolean
  @Consume artist: Artist | undefined
  @Consume serverStatus: boolean
  @Consume displayWidth: number
  @Consume showProgress: boolean
  @Consume needUpdate: boolean
  @Consume showLibrary: boolean
  @Consume ND_token: string
  @Consume ND_id: string
  @State profileSize: number = 256


  async loadArtists() {
    // load more data
    let newArtists = await ND_getArtist(
      this.baseURL,
      this.ND_token,
      this.ND_id,
      this.artists.length,
      this.artists.length + 100,
    );
    if (newArtists) {
      this.artists.push(...newArtists);
    }
  }

  async aboutToAppear() {
    this.needUpdate = !this.needUpdate;
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
    // load data
    await this.loadArtists();
  }

  build() {
    NavDestination() {
      Column() {
        Grid() {
          ForEach(this.artists, (artist: ND_Artist, index) => {
            GridItem() {
              Button({ type: ButtonType.Normal }) {
                Column() {
                  ImageKnifeComponent({
                    imageKnifeOption: {
                      // loadSrc:this.baseURL + this.getCoverUrl + this.auth + `&id=${artist.id}&size=${this.profileSize}`,
                      loadSrc: artist.largeImageUrl ?? $rawfile('noprofile.jpg'),
                      placeholderSrc: $rawfile('noprofile.jpg'),
                      errorholderSrc:$rawfile('noprofile.jpg') ,
                      objectFit: ImageFit.Cover
                    }
                  })
                    .width('100%')
                    .aspectRatio(1)
                    .borderRadius(10000)
                    .margin({ top: 10, left: 10, right: 10 })
                  Text(artist.name)
                    .width('100%')
                    .fontSize(16)
                    .fontColor($r('app.color.font'))
                    .margin(10)
                    .maxLines(1)
                    .textAlign(TextAlign.Center)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .height('auto')
              }
              .width('100%')
              .height('auto')
              .margin({ bottom: this.startPlaying === true && index === this.artists.length - 1 ? 85 : 0 })
              .animation({ curve: curves.springMotion(0.6, 1) })
              .borderRadius(10)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                // 兼容旧数据，后面全部替换为新接口
                this.artist = {
                  id: artist.id,
                  name: artist.name,
                  coverArt: "",
                  albumCount: artist.albumCount,
                  artistImageUrl: artist.largeImageUrl ?? "",
                }
                this.pageStack.pushPathByName('ArtistDetail', undefined);
              })
            }
          })
        }
        .width('100%')
        .height('100%')
        .columnsTemplate(this.displayWidth > 1400 ? "1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr" :
          (this.displayWidth > 1200 ? "1fr 1fr 1fr 1fr 1fr 1fr 1fr" :
            (this.displayWidth > 1000 ? "1fr 1fr 1fr 1fr 1fr 1fr" : (this.displayWidth > 800 ? "1fr 1fr 1fr 1fr 1fr" :
              (this.displayWidth > 400 ? "1fr 1fr 1fr 1fr" : "1fr 1fr 1fr")))))
        .columnsGap(0)
        .rowsGap(0)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Fade, { alwaysEnabled: false })
        .padding({ left: 10, right: 10, bottom: 10 })
        .visibility(this.artists.length > 0 && this.showProgress === false ? Visibility.Visible : Visibility.None)
        .onReachEnd(async ()=>{
          await this.loadArtists();
        })

        Column() {
          Text("没有艺术家")
            .fontSize(32)
            .fontColor($r('app.color.font'))
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 160 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.artists.length === 0 && this.showProgress === false ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')
    }
    .width("100%")
    .height("100%")
    .title("艺术家")
    .padding({top: 40})
  }
}