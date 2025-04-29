import webview from '@ohos.web.webview';
import { CustomNavBarView } from '../common/CustomNavBarView';

export interface SubWebPageParams {
  title: string
  url: string
}

@Builder
export function SubWebPageBuilder() {
  SubWebPage()
}

@Preview
@Component
export struct SubWebPage {
  safeAreaTop = AppStorage.get('safeAreaTop') as number
  pathStack: NavPathStack = new NavPathStack()
  params?: SubWebPageParams
  controller = new webview.WebviewController();

  build() {
    NavDestination() {
      Column() {
        CustomNavBarView({ title: this.params?.title, pathStack: this.pathStack })
          .height(44 + this.safeAreaTop)
        Web({ src: this.params?.url, controller: this.controller })
          .width('100%')
          .layoutWeight(1)
          .domStorageAccess(true)
          .mixedMode(MixedMode.All)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      this.params = context.pathInfo.param as SubWebPageParams
    })
  }
}