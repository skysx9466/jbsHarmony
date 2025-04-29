import { router, window } from '@kit.ArkUI'

export enum GlobalKey {
  uuid = 'uuid',
  entryConfig = 'entryConfig',
  versionCode = 'versionCode',
  versionName = 'versionName',
  shareFile = 'shareFile',
  shareFileName = 'shareFileName'
}


export class GlobalThis {
  static WX_APP_ID = "wx89eed0f9ac661aaf"


  private static instance: GlobalThis
  private _values = new Map<string, object | string | number | Function>()

  private constructor() {}

  static getInstance(): GlobalThis {
    if (!GlobalThis.instance) {
      GlobalThis.instance = new GlobalThis()
    }
    return GlobalThis.instance
  }

  getValue(key: GlobalKey) {
    return this._values.get(key)
  }

  deleteValue(key: GlobalKey) {
    return this._values.delete(key)
  }

  setValue(key: GlobalKey, value: object | string | number | Function): void {
    this._values.set(key, value)
  }
}