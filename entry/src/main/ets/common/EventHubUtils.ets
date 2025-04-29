import common from '@ohos.app.ability.common';
import { AppUtil } from '@pura/harmony-utils';

export enum EventName {
  FILE_UPLOAD = 'file_upload'
}

export class EventHubUtils {
  static emit(name: EventName) {
    const context: common.UIAbilityContext = AppUtil.getContext()
    context.eventHub.emit(name)
  }

  static on(name: EventName, callBack: Function) {
    const context: common.UIAbilityContext = AppUtil.getContext()
    context.eventHub.on(name, callBack)
  }

  static off(name: EventName, callBack?: Function) {
    const context: common.UIAbilityContext = AppUtil.getContext()
    context.eventHub.off(name, callBack)
  }
}

