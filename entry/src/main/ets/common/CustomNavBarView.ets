@Preview
@Component
export struct CustomNavBarView {
  @State title: string = ''
  @BuilderParam menusBuilder?: () => void
  pathStack?: NavPathStack
  backCallBack?: () => void
  bgColor: ResourceColor = Color.White
  showStyle: 'light' | 'dark' = 'light'

  build() {
    Column() {
      Blank()
        .layoutWeight(1)
      RelativeContainer() {
        Image(this.showStyle == 'light' ? $r('app.media.arrow_back') : $r('app.media.arrow_back2'))
          .objectFit(ImageFit.Contain)
          .width(44)
          .height('100%')
          .padding(9)
          .alignRules({
            left: { anchor: '__container__', align: HorizontalAlign.Start },
            center: { anchor: '__container__', align: VerticalAlign.Center },
          })
          .onClick(() => {
            if (this.backCallBack) {
              this.backCallBack()
            } else if (this.pathStack) {
              this.pathStack.pop()
            }
          })
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.showStyle == 'light' ? Color.Black : Color.White)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
        Row() {
          if (this.menusBuilder) {
            this.menusBuilder()
          }
        }
        .height('100%')
        .alignRules({
          right: { anchor: '__container__', align: HorizontalAlign.End },
          center: { anchor: '__container__', align: VerticalAlign.Center },
        })
      }
      .width('100%')
      .height(44)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bgColor)
  }
}