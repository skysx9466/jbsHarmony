import webview from '@ohos.web.webview';
import { it } from '@ohos/hypium';
import { MMKV } from '@tencent/mmkv';
import { CustomNavBarView } from '../common/CustomNavBarView';
import { GlobalKey, GlobalThis } from '../common/GlobalThis';
import { PreferencesName } from '../common/PreferencesName';
import { UrlObj } from '../entryability/EntryAbility';
import { appRecovery } from '@kit.AbilityKit';
import { Font } from '@ohos.arkui.UIContext';

@Builder
export function SettingPageBuilder() {
  SettingPage()
}

@Preview
@Component
export struct SettingPage {
  safeAreaTop: number = AppStorage.get('safeAreaTop') as number
  safeAreaBottom: number = AppStorage.get('safeAreaBottom') as number
  pathStack: NavPathStack = new NavPathStack()
  @State baseUrl: string = ''
  @State urlType: string = ''
  @State urlCustom: string = ''

  build() {
    NavDestination() {
      Column() {
        CustomNavBarView({ title: '版本设置', pathStack: this.pathStack })
          .height(44 + this.safeAreaTop)
        Column() {
          ForEach(GlobalThis.getInstance().getValue(GlobalKey.entryConfig) as UrlObj[], (item: UrlObj) => {
            Column({ space: 6 }) {
              Row() {
                Text(item.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Blank().layoutWeight(1)
                Image(item.type == this.urlType ? $r('app.media.selected2') : $r('app.media.selected'))
                  .padding(10)
                  .width(35)
                  .height(35)
              }
              .padding({ left: 20, right: 20 })

              Row() {
                if (item.type == 'base_url_custom') {
                  TextInput({ placeholder: '请输入自定义域名地址', text: this.urlCustom })
                    .fontSize(15)
                    .fontColor(Color.Black)
                    .placeholderFont({ size: 15 })
                    .padding({ left: 12, right: 12 })
                    .height(40)
                    .borderRadius(6)
                    .borderWidth(1)
                    .borderColor('#EEEEEE')
                    .clip(true)
                    .backgroundColor($r('app.color.clear'))
                    .enterKeyType(EnterKeyType.Done)
                    .onChange((value) => {
                      this.urlCustom = value
                    })
                } else {
                  Text(item.url)
                    .fontSize(15)
                    .width('100%')
                    .textAlign(TextAlign.Start)
                    .padding(12)
                    .borderRadius(6)
                    .clip(true)
                    .backgroundColor('#F2F2F2')
                }
              }
              .padding({ left: 20, right: 20 })
            }
            .padding({ top: 15, bottom: 15 })
            .borderColor(item.type == this.urlType ? $r('app.color.link') : $r('app.color.gray_line'))
            .borderRadius(8)
            .borderWidth(1)
            .margin({ left: 20, right: 20, top: 15 })
            .onClick(() => {
              if (this.urlType != item.type) {
                this.urlType = item.type
                if (item.type == 'base_url_custom') {
                  this.baseUrl = this.urlCustom
                } else {
                  this.baseUrl = item.url
                }
              }
            })
          })
        }
        .width('100%')
        .layoutWeight(1)

        Row() {
          Text('确定')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.link'))
            .borderRadius(8)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              if (this.urlType == 'base_url_custom') {
                this.baseUrl = this.urlCustom
              }
              const mmkv = MMKV.defaultMMKV()
              mmkv.encodeString(PreferencesName.baseUrl, this.baseUrl)
              mmkv.encodeString(PreferencesName.baseUrlType, this.urlType)
              mmkv.encodeString(PreferencesName.baseUrlCustom, this.urlCustom)
              appRecovery.restartApp();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: this.safeAreaBottom })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      const mmkv = MMKV.defaultMMKV()
      this.pathStack = context.pathStack
      this.baseUrl = mmkv.decodeString(PreferencesName.baseUrl) ?? ''
      this.urlType = mmkv.decodeString(PreferencesName.baseUrlType) ?? ''
      this.urlCustom = mmkv.decodeString(PreferencesName.baseUrlCustom) ?? ''
    })
  }
}