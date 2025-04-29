import { webview } from '@kit.ArkWeb'
import { SubWebPageParams } from './SubWebPage'
import { AppUtil, DialogUtil, LogUtil, StrUtil, ToastUtil } from '@pura/harmony-utils'
import { MMKV } from '@tencent/mmkv'
import call from '@ohos.telephony.call'
import * as wxopensdk from '@tencent/wechat_open_sdk'
import { image } from '@kit.ImageKit'
import { WXApi } from '../common/WXApiEventHandlerImpl'
import { common } from '@kit.AbilityKit'
import { GlobalKey, GlobalThis } from '../common/GlobalThis'
import { PreferencesName } from '../common/PreferencesName'
import { EventHubUtils, EventName } from '../common/EventHubUtils'
import fs from '@ohos.file.fs';
import { FileUpload } from '../common/FileUpload'
import { notificationManager } from '@kit.NotificationKit'
import FileManager from '../common/FileManager'
import { uniformTypeDescriptor } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit'
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit'
import CalendarUtils, { EventObj } from '../common/CalendarUtils'

class NativeBridge {
  safeAreaTop: number = AppStorage.get('safeAreaTop') as number
  safeAreaBottom: number = AppStorage.get('safeAreaBottom') as number
  topBackgroundColor: ResourceColor = Color.White
  pathStack!: NavPathStack

  openNewVC(title: string, url: string) {
    this.pathStack.pushPathByName('SubWebPage', {
      title: title,
      url: url
    } as SubWebPageParams)
  }

  setCacheData(key: string, value: string) {
    let mmkv = MMKV.defaultMMKV()
    mmkv.encodeString(key, value)
  }

  getCacheData(key: string): string {
    let mmkv = MMKV.defaultMMKV()
    return mmkv.decodeString(key) ?? ''
  }

  delCacheData(key: string) {
    let mmkv = MMKV.defaultMMKV()
    mmkv.removeValueForKey(key)
  }

  // 推送设备id
  getDeviceId(): string {
    return MMKV.defaultMMKV().decodeString(PreferencesName.pushKey) ?? ''
  }

  // 浏览器打开页面
  openBrowser(url: string) {
    let context = AppUtil.getContext()
    context.openLink(url)
  }

  // 分享文件到微信
  shareToWeChatFile(fileName: string, url: string) {
    FileManager.downloadFile(fileName, url).then((filePath) => {
      let utdTypeId = ''
      try {
        utdTypeId = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(`.${filePath.split('.').pop()}`)
      } catch (err) {
        let error: BusinessError = err as BusinessError;
        LogUtil.error(`getUniformDataTypeByFilenameExtension failed, code: ${error.code}, message: ${error.message}`);
      }
      if (StrUtil.isEmpty(utdTypeId)) {
        ToastUtil.showToast('该文件类型不支持分享')
      }
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath),
        title: 'J博士-附件分享'
      })
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let context = getContext(this) as common.UIAbilityContext;
      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL,
      }).then(() => {
        LogUtil.info('ShareController show success.');
      }).catch((error: BusinessError) => {
        LogUtil.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
      });
    })
  }

  // 分享链接到微信
  async shareLinkToWeChat(title: string, url: string) {
    const webpageObject = new wxopensdk.WXWebpageObject()
    webpageObject.webpageUrl = url

    const mediaMessage = new wxopensdk.WXMediaMessage()
    mediaMessage.mediaObject = webpageObject
    mediaMessage.title = title
    mediaMessage.description = 'J博士-舆情监控'

    const thumbData = await getContext(this).resourceManager.getMediaContent($r("app.media.icon80"))
    const thumbPixel = image.createImageSource(thumbData.buffer).createPixelMapSync()
    const thumbBuffer = await image.createImagePacker().packToData(thumbPixel, { format: "image/png", quality: 100 })
    mediaMessage.thumbData = new Uint8Array(thumbBuffer)

    const req = new wxopensdk.SendMessageToWXReq()
    req.callbackAbility = "EntryAbility"
    req.scene = wxopensdk.SendMessageToWXReq.WXSceneSession
    req.message = mediaMessage

    WXApi.sendReq(getContext(this) as common.UIAbilityContext, req)
  }

  // 拨打电话
  makingPhoneCalls(phoneNum: string) {
    DialogUtil.showDialog({
      title: '拨打电话',
      message: phoneNum,
      buttons: ['取消', '拨打'],
      onAction: (index) => {
        if (index == -2) {
          call.makeCall(phoneNum)
        }
      }
    })
  }

  // 设置顶部状态栏信息
  setSafeAreaOptions(foregroundColor: string, backgroundColor: string, height: number) {
    if (backgroundColor.length > 0) {
      this.topBackgroundColor = backgroundColor
    }
    if (foregroundColor.length > 0) {
      AppUtil.getWindowStage().getMainWindow((e, w) => {
        w.setWindowSystemBarProperties({
          statusBarContentColor: foregroundColor
        })
      })
    }
    if (height >= 0) {
      this.safeAreaTop = height
    }
  }

  // 获取顶部安全区域高度
  getSafeAreaHeight(): number {
    return this.safeAreaTop
  }

  // 上传文件
  uploadFile(apiUrl: string, fileName: string, authorization: string, dataJson: string,
    result: (jsonStr: string) => void) {
    const fileUpload = new FileUpload()
    fileUpload.upload(apiUrl, fileName, authorization, dataJson).then((data) => {
      LogUtil.info('上传结束')
      LogUtil.info(data)
      result(data)
    })
  }

  // 设置Badge
  setIconBadge(number: number) {
    notificationManager.setBadgeNumber(number)
  }

  // 登录
  login() {
    const token = MMKV.defaultMMKV().decodeString(PreferencesName.pushKey) ?? ''
    webController.runJavaScript("setDeviceId('" + token + "')")
  }

  // 创建日程记录 （时间yyyy-MM-dd HH:mm:ss）
  async creatCalendar(title: string, startTime: string, endTime: string, alarmTime: number,
    success: (eventId: string) => void) {
    CalendarUtils.shared.creatCalendar(title, startTime, endTime, alarmTime).then((eventId) => {
      if (StrUtil.isNotEmpty(eventId)) {
        success(eventId ?? '');
      }
    }).catch((error: BusinessError) => {
      LogUtil.error(`* Failed to create calendar. Code: ${error.code}, message: ${error.message}`);
    })
  }

  // 获取日程记录
  async getCalendar(eventId: string, success: (eventData: EventObj) => void) {
    CalendarUtils.shared.getCalendar(eventId).then((data) => {
      if (data) {
        success(data);
      }
    }).catch((error: BusinessError) => {
      LogUtil.error(`* Failed to get calendar. Code: ${error.code}, message: ${error.message}`);
    })
  }

  // 修改日程记录
  async updateCalendar(eventId: string, title: string, startTime: string, endTime: string, alarmTime: number,
    success: (eventId: string) => void) {
    if (StrUtil.isEmpty(eventId)) {
      return;
    }
    CalendarUtils.shared.updateCalendar(eventId, title, startTime, endTime, alarmTime).then((eventId) => {
      if (StrUtil.isNotEmpty(eventId)) {
        success(eventId ?? '');
      }
    }).catch((error: BusinessError) => {
      LogUtil.error(`* Failed to update calendar. Code: ${error.code}, message: ${error.message}`);
    })
  }

  // 删除日程记录
  async deleteCalendar(eventId: string) {
    if (StrUtil.isEmpty(eventId)) {
      return;
    }
    CalendarUtils.shared.deleteCalendar(eventId);
  }
}

const webController: webview.WebviewController = new webview.WebviewController();

@Entry
@Component
struct MainWebPage {
  pathStack: NavPathStack = new NavPathStack()
  @State nativeInstance: NativeBridge = new NativeBridge()
  @State launchTag: number = 0
  url: string = ''

  build() {
    Navigation(this.pathStack) {
      Stack() {
        Column() {
          Blank()
            .backgroundColor(this.nativeInstance.topBackgroundColor)
            .height(this.nativeInstance.safeAreaTop)
          Web({
            // src: $rawfile('test.html'),
            src: this.url,
            controller: webController
          })
            .mixedMode(MixedMode.All)
            .domStorageAccess(true)
            .width('100%')
            .layoutWeight(1)
            .javaScriptProxy({
              object: this.nativeInstance,
              name: 'nativeInstance',
              methodList: [
                'openNewVC',
                'setCacheData',
                'getCacheData',
                'delCacheData',
                'getDeviceId',
                'openBrowser',
                'setSafeAreaOptions',
                'getSafeAreaHeight',
                'login',
                'shareToWeChatFile',
                'setIconBadge'
              ],
              controller: webController,
              asyncMethodList: [
                'makingPhoneCalls',
                'shareLinkToWeChat',
                'uploadFile',
                'creatCalendar',
                'getCalendar',
                'updateCalendar',
                'deleteCalendar'
              ],
            })
            .onAlert((e) => {
              DialogUtil.showConfirmDialog({
                title: "温馨提示",
                message: e.message,
                confirm: '好的'
              })
              return false
            })
            .onPageEnd(() => {
              webController.runJavaScript("var platform = 'HarmonyOS'; var version = '" +
              GlobalThis.getInstance().getValue(GlobalKey.versionCode) + "';")
              this.launchTag += 1
            })
        }
        .padding({ bottom: this.nativeInstance.safeAreaBottom })

        if (this.launchTag < 2) {
          Column() {
            Row() {
              Row() {
                Text('切换版本')
                  .fontSize(15)
                  .fontColor("#0959F7")
                  .margin({ right: 12 })
              }
              .padding(6)
              .onClick(() => {
                this.pathStack.pushPathByName('SettingPage', null)
              })
            }
            .justifyContent(FlexAlign.End)
            .width('100%')
            .padding({ top: this.nativeInstance.safeAreaTop })

            Image($r('app.media.launch'))
              .width('100%')
              .layoutWeight(1)
              .objectFit(ImageFit.Contain)
          }
          .width('100%')
          .height('100%')
          .backgroundColor(Color.White)
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .hideToolBar(true)
  }

  aboutToAppear() {
    webview.WebviewController.setWebDebuggingAccess(true);
    this.nativeInstance.pathStack = this.pathStack
    let mmkv = MMKV.defaultMMKV()
    const baseUrl = mmkv.decodeString(PreferencesName.baseUrl) ?? ''
    const token = MMKV.defaultMMKV().decodeString(PreferencesName.pushKey) ?? ''

    const fileUrl = GlobalThis.getInstance().getValue(GlobalKey.shareFile) as string
    const fileName = GlobalThis.getInstance().getValue(GlobalKey.shareFileName) as string
    if (StrUtil.isNotNull(fileUrl) && StrUtil.isNotNull(fileName)) {
      this.url = baseUrl + "/mobile/WeChatHome/?param={'deviceId':'" + token + "', 'fileName':'" + fileName + "'}"
      GlobalThis.getInstance().deleteValue(GlobalKey.shareFile)
      GlobalThis.getInstance().deleteValue(GlobalKey.shareFileName)
    } else {
      // this.url = baseUrl + "?deviceId=" + deviceId + "&loginToken=" + token
      this.url = baseUrl + "/?param={'deviceId':'" + token + "'}"
    }
    LogUtil.info('初始化打开:', this.url)

    setTimeout(() => {
      this.launchTag += 1
    }, 2500)

    EventHubUtils.on(EventName.FILE_UPLOAD, () => {
      const fileUrl = GlobalThis.getInstance().getValue(GlobalKey.shareFile) as string
      const fileName = GlobalThis.getInstance().getValue(GlobalKey.shareFileName) as string
      if (StrUtil.isNotNull(fileUrl) && StrUtil.isNotNull(fileName)) {
        this.url = baseUrl + "/mobile/WeChatHome/?param={'deviceId':'" + token + "', 'fileName':'" + fileName + "'}"
        GlobalThis.getInstance().deleteValue(GlobalKey.shareFile)
        GlobalThis.getInstance().deleteValue(GlobalKey.shareFileName)
        LogUtil.info('自动跳转打开:', this.url)
        webController.loadUrl(this.url)
      }
    })
  }
}