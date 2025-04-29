import { pushCommon, RemoteNotificationExtensionAbility } from '@kit.PushKit';
import { aliyunPush, ExtensionNotification } from '@aliyun/push';
import { common } from '@kit.AbilityKit';
import { LogUtil } from '@pura/harmony-utils';

export default class SampleRemoteNotification extends RemoteNotificationExtensionAbility {
  async onReceiveMessage(remoteNotificationInfo: pushCommon.RemoteNotificationInfo): Promise<pushCommon.RemoteNotificationContent> {

    LogUtil.info('666666666666666666')

    // ************* 通知扩展消息处理 begin *************
    // 初始化推送参数，用于解析推送数据
    aliyunPush.init({
      appKey: '335507207',
      appSecret: '5511599a1a7848e580e69bca11e9afc9',
      context: this.context as common.Context,
    })

    // 调用parseExtensionPushData解析推送的参数
    const notification: ExtensionNotification = await aliyunPush.parseExtensionPushData(remoteNotificationInfo);

    // 这里可以获取通知扩展消息的参数进行业务处理

    // SDK提供辅助方法getRemoteNotificationContent构建返回值, 传参EntryAbility是本次通知点击要打开的Ability名称
    const result = aliyunPush.getPushHelper().getRemoteNotificationContent('EntryAbility', notification);
    return result;
    // 如果要修改通知的内容，可以返回想要修改的内容，wantAgent建议还是保留。如果不保留，后续就无法在用户点击时识别推送的参数，会丢失通知的点击数据
    // return {
    //   // 省略其它修改的字段，wantAgent建议还是使用getRemoteNotificationContent方法构造的参数。
    //   wantAgent: result.wantAgent
    // }
    // ************* 通知扩展消息处理 end *************
  }
}