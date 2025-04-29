let loadingDialogController: CustomDialogController | null

export enum LoadingState {
  loading,
  success,
  error,
  info,
  warn,
  toast,
  progress,
}

export interface LoadingSettings {
  /**
   * msg default is ''
   */
  msg?: string
  /**
   * alignment default is center
   */
  alignment?: DialogAlignment
  /**
   * offset default is （0，0）
   */
  offset?: Offset
  /**
   * tintColor, image & LoadingProgress color, default is white
   */
  tintColor?: ResourceColor
  /**
   * textColor default is white
   */
  textColor?: ResourceColor
  /**
   * hideDelay default is 2000 ms
   */
  hideDelay?: number
  /**
   * fontSize default is 16fp
   */
  fontSize?: number | string | Resource
  /**
   * backgroundColor default is #cc000000
   */
  backgroundColor?: ResourceColor
  /**
   * maskColor default is Transparent
   */
  maskColor?: ResourceColor
  /**
   * borderRadius default is 10
   */
  borderRadius?: Length | BorderRadiuses
  /**
   * success image 最好是svg格式
   */
  successSrc?: PixelMap | ResourceStr | DrawableDescriptor
  /**
   * failure image 最好是svg格式
   */
  failureSrc?: PixelMap | ResourceStr | DrawableDescriptor
  /**
   * info image 最好是svg格式
   */
  infoSrc?: PixelMap | ResourceStr | DrawableDescriptor
  /**
   * warn image 最好是svg格式
   */
  warnSrc?: PixelMap | ResourceStr | DrawableDescriptor
  /**
   * 点击弹框外部是否隐藏hud 默认是false
   */
  hideOnTouchOutside?: boolean
  /**
   * 系统返回时是否隐藏hud 默认是false
   */
  hideOnSystemBack?: boolean
}

@Component
export struct LoadingComponent {
  /**
   * 显示 loading hud
   * @param value 可不传
   */
  showLoading(value: string | LoadingSettings = ''): void {
    this.showDialog(value, LoadingState.loading)
  }

  /**
   * 显示 success hud
   * @param value 可不传
   */
  showSuccess(value: string | LoadingSettings = ''): void {
    this.showDialog(value, LoadingState.success)

    this.hideDialogDelay(value)
  }

  /**
   * 显示 failure hud
   * @param value 可不传
   */
  showFailure(value: string | LoadingSettings = ''): void {
    this.showDialog(value, LoadingState.error)

    this.hideDialogDelay(value)
  }

  /**
   * 显示 info hud
   * @param value 可不传
   */
  showInfo(value: string | LoadingSettings = ''): void {
    this.showDialog(value, LoadingState.info)

    this.hideDialogDelay(value)
  }

  /**
   * 显示 warn hud
   * @param value
   */
  showWarn(value: string | LoadingSettings = ''): void {
    this.showDialog(value, LoadingState.warn)

    this.hideDialogDelay(value)
  }

  /**
   * 显示 toast hud
   * @param value
   */
  showToast(value: string | LoadingSettings = ''): void {
    this.showDialog(value, LoadingState.toast)

    this.hideDialogDelay(value)
  }

  /**
   * 显示 progress hud
   * @param value 可不传
   * @param progress 取值 0 ~ 100
   */
  showProgress(value: string | LoadingSettings = '', progress: number = 0): void {
    this.hide()
    let alignment: DialogAlignment
    let offset: Offset
    let maskColor: ResourceColor
    let hideOnTouchOutside: boolean = false
    let hideOnSystemBack: boolean = false
    if (typeof value == 'string') {
      alignment = loadingDialogGlobalSettings.alignment
      offset = loadingDialogGlobalSettings.offset
      maskColor = loadingDialogGlobalSettings.maskColor
    } else {
      alignment = value.alignment ?? loadingDialogGlobalSettings.alignment
      offset = value.offset ?? loadingDialogGlobalSettings.offset
      maskColor = value.maskColor ?? loadingDialogGlobalSettings.maskColor
      hideOnTouchOutside = value.hideOnTouchOutside ?? loadingDialogGlobalSettings.hideOnTouchOutside
      hideOnSystemBack = value.hideOnSystemBack ?? loadingDialogGlobalSettings.hideOnSystemBack
    }
    loadingDialogController = new CustomDialogController({
      builder: LoadingDialogView({
        value: value,
        state: LoadingState.progress,
        progress: progress
      }),
      alignment: alignment,
      offset: offset,
      autoCancel: false,
      customStyle: true,
      maskColor: maskColor,
      onWillDismiss: (action: DismissDialogAction) => {
        if (action.reason == DismissReason.PRESS_BACK && hideOnSystemBack) {
          action.dismiss()
        } else if (action.reason == DismissReason.TOUCH_OUTSIDE && hideOnTouchOutside) {
          action.dismiss()
        }
      },
      openAnimation: {
        duration: 0,
        delay: 0
      },
      closeAnimation: {
        duration: 0,
        delay: 0
      }
    })
    loadingDialogController?.open()
  }

  /**
   * 隐藏 hud
   */
  hide(): void {
    if (loadingDialogController) {
      loadingDialogController?.close()
      loadingDialogController = null
    }
  }

  setGlobalSettings(configs: (settings: LoadingDialogGlobalSettings) => void): void {
    configs(loadingDialogGlobalSettings)
  }

  private showDialog(value: string | LoadingSettings = '', state: LoadingState): void {
    this.hide()
    let alignment: DialogAlignment
    let offset: Offset
    let maskColor: ResourceColor
    let hideOnTouchOutside: boolean = false
    let hideOnSystemBack: boolean = false
    if (typeof value == 'string') {
      alignment = loadingDialogGlobalSettings.alignment
      offset = loadingDialogGlobalSettings.offset
      maskColor = loadingDialogGlobalSettings.maskColor
    } else {
      alignment = value.alignment ?? loadingDialogGlobalSettings.alignment
      offset = value.offset ?? loadingDialogGlobalSettings.offset
      maskColor = value.maskColor ?? loadingDialogGlobalSettings.maskColor
      hideOnTouchOutside = value.hideOnTouchOutside ?? loadingDialogGlobalSettings.hideOnTouchOutside
      hideOnSystemBack = value.hideOnSystemBack ?? loadingDialogGlobalSettings.hideOnSystemBack
    }
    loadingDialogController = new CustomDialogController({
      builder: LoadingDialogView({
        value: value,
        state: state
      }),
      alignment: alignment,
      offset: offset,
      autoCancel: hideOnTouchOutside,
      customStyle: true,
      maskColor: maskColor,
      onWillDismiss: (action: DismissDialogAction) => {
        if (action.reason == DismissReason.PRESS_BACK && hideOnSystemBack) {
          action.dismiss()
        } else if (action.reason == DismissReason.TOUCH_OUTSIDE && hideOnTouchOutside) {
          action.dismiss()
        }
      }
    })
    loadingDialogController?.open()
  }

  hideDialogDelay(value: string | LoadingSettings = ''): void {
    let hideDelay: number
    if (typeof value == 'string') {
      hideDelay = loadingDialogGlobalSettings.hideDelay
    } else {
      hideDelay = value.hideDelay ?? loadingDialogGlobalSettings.hideDelay
    }
    setTimeout(() => {
      this.hide()
    }, hideDelay)
  }

  build() {
  }
}

@CustomDialog
struct LoadingDialogView {
  controller: CustomDialogController
  value: string | LoadingSettings = ''
  state: LoadingState = LoadingState.loading
  progress: number = 0
  private msg: string = ''
  private settings?: LoadingSettings

  aboutToAppear(): void {
    if (typeof this.value == 'string') {
      this.msg = this.value
    } else {
      this.msg = this.value.msg ?? loadingDialogGlobalSettings.msg
      this.settings = this.value
    }
  }

  build() {
    Column({ space: 10 }) {
      if (this.state == LoadingState.loading) {
        LoadingProgress()
          .color(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('54vp')
          .height('54vp')
      } else if (this.state == LoadingState.success) {
        Image(this.settings?.successSrc ?? loadingDialogGlobalSettings.successSrc)
          .fillColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('44vp')
          .height('44vp')
      } else if (this.state == LoadingState.error) {
        Image(this.settings?.failureSrc ?? loadingDialogGlobalSettings.failureSrc)
          .fillColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('44vp')
          .height('44vp')
      } else if (this.state == LoadingState.info) {
        Image(this.settings?.infoSrc ?? loadingDialogGlobalSettings.infoSrc)
          .fillColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('44vp')
          .height('44vp')
      } else if (this.state == LoadingState.warn) {
        Image(this.settings?.warnSrc ?? loadingDialogGlobalSettings.warnSrc)
          .fillColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
          .width('44vp')
          .height('44vp')
      } else if (this.state == LoadingState.progress) {
        Stack() {
          Progress({ value: this.progress, total: 100, type: ProgressType.Ring })
            .width('100%')
            .height('100%')
            .color(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
            .backgroundColor("#4dffffff")
            .style({
              strokeWidth: 5,
              enableSmoothEffect: false,
            })

          Text(`${this.progress}%`)
            .width('100%')
            .height('100%')
            .fontSize('14fp')
            .fontColor(this.settings?.tintColor ?? loadingDialogGlobalSettings.tintColor)
            .textAlign(TextAlign.Center)
        }
        .width('54vp')
        .height('54vp')
      }

      if (this.msg != '') {
        Text(this.msg)
          .fontColor(this.settings?.textColor ?? loadingDialogGlobalSettings.textColor)
          .textAlign(TextAlign.Center)
          .fontSize(this.settings?.fontSize ?? loadingDialogGlobalSettings.fontSize)
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .constraintSize({
      minWidth: '80vp'
    })
    .padding(12)
    .margin(30)
    .backgroundColor(this.settings?.backgroundColor ?? loadingDialogGlobalSettings.backgroundColor)
    .borderRadius(this.settings?.borderRadius ?? loadingDialogGlobalSettings.borderRadius)
  }
}


export class LoadingDialogManager {
  static dialog: LoadingComponent

  private constructor() {
  }

  static instance(): LoadingComponent {
    if (LoadingDialogManager.dialog == undefined) {
      LoadingDialogManager.dialog = new LoadingComponent()
    }
    return LoadingDialogManager.dialog
  }

  static setup() {
    LoadingDialogManager.dialog = new LoadingComponent()
  }

  static showSuccess(value: string): void {
    LoadingDialogManager.instance().showSuccess(value)
  }

  static showToast(value: string): void {
    LoadingDialogManager.instance().showToast(value)
  }
}

export class LoadingDialogGlobalSettings {
  msg: string = ''
  alignment: DialogAlignment = DialogAlignment.Center
  offset: Offset = { dx: 0, dy: 0 }
  tintColor: ResourceColor = Color.White
  textColor: ResourceColor = Color.White
  hideDelay: number = 1600
  fontSize: number | string | Resource = '14fp'
  backgroundColor: ResourceColor = '#CC000000'
  maskColor: ResourceColor = '#00000000'
  borderRadius: Length | BorderRadiuses = 10
  successSrc: PixelMap | ResourceStr | DrawableDescriptor = $r('app.media.loading_success')
  failureSrc: PixelMap | ResourceStr | DrawableDescriptor = $r('app.media.loading_error')
  infoSrc: PixelMap | ResourceStr | DrawableDescriptor = $r('app.media.loading_info')
  warnSrc: PixelMap | ResourceStr | DrawableDescriptor = $r('app.media.loading_warn')
  hideOnTouchOutside: boolean = false
  hideOnSystemBack: boolean = false
}

let loadingDialogGlobalSettings = new LoadingDialogGlobalSettings()