import axios, { AxiosError, AxiosProgressEvent, AxiosResponse, FormData } from "@ohos/axios";
import { AppUtil, DeviceUtil, LogUtil } from "@pura/harmony-utils";
import { MMKV } from "@tencent/mmkv";
import { GlobalKey, GlobalThis } from "./GlobalThis";
import { PreferencesName } from "./PreferencesName";
import fs from '@ohos.file.fs';

export class FileUpload {
  async upload(url: string, fileName: string, authorization: string, dataJson: String): Promise<string> {
    return new Promise((resolve, reject) => {

      const pathDir = AppUtil.getContext().filesDir;
      const furl = pathDir + '/shared/' + fileName
      const isExist = fs.accessSync(furl)
      if (!isExist) {
        LogUtil.info('File Upload faile: ', furl)
        return
      }

      let header: Record<string, string> = {
        "Authorization": authorization,
        'Content-Type': 'multipart/form-data',
        'udid': MMKV.defaultMMKV().decodeString(PreferencesName.uuid) ?? '',
        'brand': DeviceUtil.getBrand(),
        'os-name': DeviceUtil.getOsFullName(),
        'display-version': DeviceUtil.getDisplayVersion(),
        'sdk-version': String(DeviceUtil.getSdkApiVersion()),
      }
      let formData = new FormData()
      formData.append("file", furl, { filename: fileName });
      formData.set('fileName', fileName)
      formData.set('dataJson', dataJson)
      axios<object, AxiosResponse<object>, FormData>({
        url: url,
        data: formData,
        method: 'post',
        headers: header,
        responseType: 'object',
        context: getContext(this),
        onUploadProgress: (progressEvent: AxiosProgressEvent) => {
          const i = progressEvent && progressEvent.loaded && progressEvent.total ? (Math.ceil(progressEvent.loaded / progressEvent.total * 100) + '%') : '0%'
          LogUtil.info(`上传进度 ${i}`)
        }
      }).then((resp: AxiosResponse) => {
        const status = resp.status
        resolve(JSON.stringify(resp.data))
      }).catch((err: AxiosError) => {

      })
    });
  }
}