import { BusinessError, request } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { AppUtil, LogUtil, StrUtil, ToastUtil } from '@pura/harmony-utils';
import { LoadingDialogManager } from './LoadingDialog';



export default class FileManager {
  static downloadFile(fileName: string, url: string): Promise<string> {
    return new Promise((resolve, reject) => {
      if (url == null || url == undefined || StrUtil.isEmpty(url)) {
        reject();
      }

      const context = AppUtil.getContext()
      const newPath = context.filesDir + '/download/'
      const filePath = newPath + fileName
      const isPathExist = fs.accessSync(newPath)

      if (!isPathExist) {
        fs.mkdirSync(newPath)
      }

      const isFileExist = fs.accessSync(filePath)
      if (isFileExist) {
        fs.unlinkSync(filePath)
      }

      LoadingDialogManager.instance().showLoading({ msg: '加载中...', hideOnTouchOutside: true })
      request.downloadFile(context, {
        url: url,
        filePath: filePath
      }).then((data: request.DownloadTask) => {
        let downloadTask: request.DownloadTask = data

        downloadTask.on('complete', () => {
          console.info('download complete')
          LoadingDialogManager.instance().hide()
          resolve(filePath)
        })
        downloadTask.on('progress', (receivedSize: number, totalSize: number) => {
          LogUtil.info(`download progress:  receivedSize: ${receivedSize} / totalSize: ${totalSize}`)
        })
        downloadTask.on('fail', () => {
          console.info('download task fail')
          reject();
        })

      }).catch((err: BusinessError) => {
        LogUtil.error(`downLoadFileTask failed, code is ${err.code}, message is ${err.message}`)
        reject();
      });

    })
  }
}