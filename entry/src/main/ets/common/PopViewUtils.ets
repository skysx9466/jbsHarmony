import { ComponentContent, promptAction } from '@kit.ArkUI'

export class PopViewUtils {
  private constructor() {}
  private static context: UIContext
  private static popShare: PopViewUtils
  private componentContentList: ComponentContent<object>[] = new Array<ComponentContent<object>>()

  static setup(context: UIContext) {
    PopViewUtils.context = context
    if (!PopViewUtils.popShare) {
      PopViewUtils.popShare = new PopViewUtils()
    }
    return PopViewUtils.popShare
  }

  static showPopView<T extends object>(contentView: WrappedBuilder<[T]>, args: T,
    options?: promptAction.BaseDialogOptions) {
    if (PopViewUtils.context) {
      let prompt = PopViewUtils.context.getPromptAction()
      let componentContent = new ComponentContent(PopViewUtils.context, contentView, args)
      let customOptions: promptAction.BaseDialogOptions = {
        alignment: options?.alignment || DialogAlignment.Bottom,
        autoCancel: options?.autoCancel ?? true,
        transition: options?.transition,
        onWillDismiss: (action: DismissDialogAction) => {
          if (options?.onWillDismiss) {
            options.onWillDismiss(action)
          }else {
            action.dismiss()
          }
        },
        onDidAppear: () => {
          if (options?.onDidAppear) {
            options.onDidAppear()
          }
        },
        onDidDisappear: () => {
          if (options?.onDidDisappear) {
            options.onDidDisappear()
          }
          if (PopViewUtils.popShare.componentContentList.length > 0) {
            PopViewUtils.popShare.componentContentList.pop()
          }
        },
        onWillDisappear: () => {
          if (options?.onWillDisappear) {
            options.onWillDisappear()
          }
        }
      }
      prompt.openCustomDialog(componentContent, customOptions)
      PopViewUtils.popShare.componentContentList.push(componentContent)
    }
  }

  static closePopView() {
    if (PopViewUtils.context) {
      let prompt = PopViewUtils.context.getPromptAction()
      let comList = PopViewUtils.popShare.componentContentList
      let com = PopViewUtils.popShare.componentContentList[comList.length - 1]
      if (com) {
        prompt.closeCustomDialog(com)
        PopViewUtils.popShare.componentContentList.pop()
      }
    }
  }
}