import { AbilityConstant, bundleManager, common, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppUtil, DialogUtil, LogUtil, RandomUtil, StrUtil } from '@pura/harmony-utils';
import { MMKV } from '@tencent/mmkv';
import { GlobalKey, GlobalThis } from '../common/GlobalThis';
import { PreferencesName } from '../common/PreferencesName';
import util from '@ohos.util';
import webview from '@ohos.web.webview';
import { PopViewUtils } from '../common/PopViewUtils';
import { WXApi, WXEventHandler } from '../common/WXApiEventHandlerImpl';
import { pushCommon, pushService } from '@kit.PushKit';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { EventHubUtils, EventName } from '../common/EventHubUtils';
import {
  aliyunPush,
  Channel,
  ExtensionNotification,
  IPushListener,
  PushDataType,
  PushMessage,
  PushNotification,
  PushNotificationHandler
} from '@aliyun/push';

import { notificationManager } from '@kit.NotificationKit';
import CalendarUtils from '../common/CalendarUtils';

const TAG: string = '[PublishOperation]';
const DOMAIN_NUMBER: number = 0xFF00;


export interface UrlObj {
  type: string
  url: string
  title: string
}


/**
 * 自定义的推送回调接口实现
 */
class MyPushListener implements IPushListener {
  onReceiveNotification(data: PushNotification | ExtensionNotification): boolean {
    LogUtil.info('0000000000000')

    if (data.type === PushDataType.Notification) {
      // 处理推送通知
    } else if (data.type === PushDataType.ExtensionNotification) {
      // 处理通知扩展消息
    }
    return false;
  }

  onShowNotification(data: PushNotification | ExtensionNotification): void {
    // 处理通知展示事件

    LogUtil.info('11111111111111')
  }

  onReceiveMessage(data: PushMessage): void {
    // 处理推送消息

    DialogUtil.showConfirmDialog({
      title: data.title,
      message: data.content,
      confirm: '好的'
    })

    LogUtil.info('22222222222222')

  }
}

/**
 * 自定义推送数据的处理类
 */
class MyPushNotificationHandler implements PushNotificationHandler {
  onClickNotification(data: PushNotification | PushMessage | ExtensionNotification, from: Channel): void {
    // 由用户点击通知拉起的页面，获取推送数据，处理业务逻辑

    LogUtil.info('3333333333333333')

  }

  noPushData(): void {
    // 不是由用户点击通知拉的页面, 或者不是阿里云推送的数据

    LogUtil.info('4444444444444444')
  }
}

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.setup(windowStage);
    windowStage.loadContent("pages/MainWebPage", () => {
      window.getLastWindow(this.context).then((data: window.Window) => {
        PopViewUtils.setup(data.getUIContext())
      });
    })
  }

  setup(windowStage: window.WindowStage) {
    AppUtil.init(this.context);
    LogUtil.init(0x0001, 'JBS', true)
    MMKV.initialize(this.context.getApplicationContext())
    let mmkv = MMKV.defaultMMKV()

    // 沉浸式
    const mainWindow = windowStage.getMainWindowSync()
    mainWindow.setWindowLayoutFullScreen(true);
    mainWindow.setWindowSystemBarEnable(['status']);

    // Safe Area
    let area = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    AppStorage.setOrCreate<number>('safeAreaTop', px2vp(area.topRect.height))
    area = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
    AppStorage.setOrCreate<number>('safeAreaBottom', px2vp(area.bottomRect.height))

    // UUID
    const uuid = RandomUtil.generateRandomUUID(true);
    GlobalThis.getInstance().setValue(GlobalKey.uuid, uuid);
    mmkv.encodeString(PreferencesName.uuid, uuid)

    // Entry Config
    const configRawFile = this.context.resourceManager.getRawFileContentSync("entry_config.json")
    let configRawStr = util.TextDecoder.create('utf-8').decodeWithStream(configRawFile);
    let urlObjs = JSON.parse(configRawStr) as UrlObj[]
    GlobalThis.getInstance().setValue(GlobalKey.entryConfig, urlObjs)
    if (StrUtil.isEmpty(mmkv.decodeString(PreferencesName.baseUrl))) {
      const urlObj = urlObjs[0]
      mmkv.encodeString(PreferencesName.baseUrl, urlObj.url)
      mmkv.encodeString(PreferencesName.baseUrlType, urlObj.type)
    }

    // 加载Web引擎的动态库文件，以提高启动性能
    webview.WebviewController.initializeWebEngine()

    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
    bundleManager.getBundleInfoForSelf(bundleFlags, (err, data) => {
      if (!err) {
        const versionCode = data.versionCode
        GlobalThis.getInstance().setValue(GlobalKey.versionCode, versionCode)
        const versionName = data.versionName;
        GlobalThis.getInstance().setValue(GlobalKey.versionName, versionName)
      }
    })

    CalendarUtils.shared.setup(this.context)
  }

  onForeground(): void {

  }

  onBackground(): void {

  }

  async onCreate(want: Want, _launchParam: AbilityConstant.LaunchParam): Promise<void> {
    // 阿里云PUSH
    aliyunPush.init({
      appKey: '335507207',
      appSecret: '5511599a1a7848e580e69bca11e9afc9',
      context: this.context,
    })
    aliyunPush.setPushListener(new MyPushListener());
    aliyunPush.handleClickNotification(want, new MyPushNotificationHandler())

    await aliyunPush.register();
    const deviceId = aliyunPush.getDeviceId();

    const pushToken = await pushService.getToken();
    await aliyunPush.registerThirdToken(pushToken);
    aliyunPush.turnOnPushChannel()

    MMKV.defaultMMKV().encodeString(PreferencesName.pushKey, deviceId)

    LogUtil.info(`device id: ${deviceId}`)
    LogUtil.info(`push token: ${pushToken}`)

    // ************* 设置应用在前台时鸿蒙厂商通道的通知扩展消息接收接口 begin *************
    pushService.receiveMessage("IM", this, async (data: pushCommon.PushPayload) => {
      // 解析推送参数
      const extensionNotification: ExtensionNotification = await aliyunPush.parseExtensionPushData(data);
      // 这里根据获取的通知扩展消息参数进行业务处理

      AlertDialog.show({
        title: extensionNotification.title,
        message: extensionNotification.content
      })

      LogUtil.info('5555555555555555')

    })
    // ************* 设置应用在前台时鸿蒙厂商通道的通知扩展消息接收接口 end *************

    this.requestNPS()

    // 在EntryAbility中响应来自微信的回调
    this.handleWeChatCallIfNeed(want)
  }

  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    this.handleWeChatCallIfNeed(want)

    // 页面已经启动的场景
    aliyunPush.handleClickNotification(want, new MyPushNotificationHandler())
  }

  private handleWeChatCallIfNeed(want: Want) {
    this.handleUploadFile(want)
    WXApi.handleWant(want, WXEventHandler)
  }

  requestNPS() {
    let context = this.context;
    notificationManager.isNotificationEnabled().then((data: boolean) => {
      hilog.info(DOMAIN_NUMBER, TAG, "isNotificationEnabled success, data: " + JSON.stringify(data));
      if (!data) {
        notificationManager.requestEnableNotification(context).then(() => {
          hilog.info(DOMAIN_NUMBER, TAG, `[ANS] requestEnableNotification success`);
        }).catch((err: BusinessError) => {
          if (1600004 == err.code) {
            hilog.error(DOMAIN_NUMBER, TAG,
              `[ANS] requestEnableNotification refused, code is ${err.code}, message is ${err.message}`);
          } else {
            hilog.error(DOMAIN_NUMBER, TAG,
              `[ANS] requestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
          }
        });
      }
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `isNotificationEnabled fail, code is ${err.code}, message is ${err.message}`);
    });
  }

  private handleUploadFile(want: Want) {
    let uri = want.uri;
    if (uri == null || uri == undefined || StrUtil.isEmpty(uri)) {
      return;
    }
    try {
      let file = fs.openSync(uri, fs.OpenMode.READ_WRITE)
      const pathDir = AppUtil.getContext().filesDir;
      const newPath = pathDir + '/shared/'
      const newUrl = newPath + file.name
      const isExist = fs.accessSync(newPath)
      if (!isExist) {
        fs.mkdirSync(newPath)
      }
      fs.fsyncSync(file.fd)
      fs.copyFileSync(file.fd, newUrl)
      GlobalThis.getInstance().setValue(GlobalKey.shareFile, newUrl)
      GlobalThis.getInstance().setValue(GlobalKey.shareFileName, file.name)
      EventHubUtils.emit(EventName.FILE_UPLOAD)
      fs.close(file)
    } catch (err) {
      let error: BusinessError = err as BusinessError;
      LogUtil.error(`Failed to open file openSync, code: ${error.code}, message: ${error.message}`);
    }
  }
}
