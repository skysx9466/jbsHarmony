import * as wxopensdk from '@tencent/wechat_open_sdk';
import { Log } from '@tencent/wechat_open_sdk';
import { GlobalThis } from './GlobalThis';

export const WXApi = wxopensdk.WXAPIFactory.createWXAPI(GlobalThis.WX_APP_ID)
export type OnWXReq = (req: wxopensdk.BaseReq) => void
export type OnWXResp = (req: wxopensdk.BaseResp) => void
const kTag = "WXApiEventHandlerImpl"

class WXApiEventHandlerImpl implements wxopensdk.WXApiEventHandler {
  private onReqCallbacks: Map<OnWXReq, OnWXReq> = new Map
  private onRespCallbacks: Map<OnWXResp, OnWXResp> = new Map

  registerOnWXReqCallback(on: OnWXReq) {
    this.onReqCallbacks.set(on, on)
  }
  unregisterOnWXReqCallback(on: OnWXReq) {
    this.onReqCallbacks.delete(on)
  }

  registerOnWXRespCallback(on: OnWXResp) {
    this.onRespCallbacks.set(on, on)
  }
  unregisterOnWXRespCallback(on: OnWXResp) {
    this.onRespCallbacks.delete(on)
  }

  onReq(req: wxopensdk.BaseReq): void {
    Log.i(kTag, "onReq:%s", JSON.stringify(req))
    this.onReqCallbacks.forEach((on) => {
      on(req)
    })
  }

  onResp(resp: wxopensdk.BaseResp): void {
    Log.i(kTag, "onResp:%s", JSON.stringify(resp))
    this.onRespCallbacks.forEach((on) => {
      on(resp)
    })
  }
}

export const WXEventHandler = new WXApiEventHandlerImpl
