import { AbilityStage, appRecovery, Want } from "@kit.AbilityKit";

export class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    appRecovery.enableAppRecovery(
      appRecovery.RestartFlag.ALWAYS_RESTART
    );
    let want: Want = {
      bundleName: 'com.axlr.jbs',
      abilityName: "EntryAbility" // 需要拉起的Ability
    }
    appRecovery.setRestartWant(want)
  }
}